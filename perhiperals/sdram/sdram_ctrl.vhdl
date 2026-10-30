library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

-- Byte-wide controller for the 4 bank x 4096 row x 256 column x 16 bit
-- SDRAM on the DE1 (8 MB).
--
-- Accesses are performed in fixed-length slots. Each start pulse runs one
-- complete closed-page sequence: ACTIVE, READ or WRITE, PRECHARGE, and then
-- an AUTO REFRESH if one is due. The slot always takes SLOT_CLKS clocks
-- whether or not an access or refresh is performed, so a requester that
-- pulses start at most once every SLOT_CLKS clocks gets a fixed read latency
-- without any handshaking, and refresh never delays an access. Refreshes are
-- only issued inside slots, so start must be pulsed regularly (with or
-- without an access) for refresh to keep up.
--
-- Timeline of a slot, in clocks after the edge at which start is sampled
-- (at 50 MHz with the default timing):
--
--   0  ACTIVE registered (sampled by the SDRAM at 1)
--   1  READ/WRITE registered
--   3  PRECHARGE registered
--   4  read data sampled from the DQ pins
--   4  AUTO REFRESH registered, if due
--   5  data_out updated
--   8  next start may be sampled
entity sdram_ctrl is
generic
(
    CLK_FREQ    : positive := 50_000_000;
    CAS_LATENCY : positive range 2 to 3 := 2;

    -- Power up delay before the initialization sequence
    T_INIT_US : natural := 200;

    -- Timing parameters in ns. The defaults are the worst case of the -7
    -- and -8 speed grades of the IS42S16400 on the DE1. Its datasheet has
    -- no separate tRFC, an auto refresh takes tRC
    T_RCD  : natural := 20;
    T_RAS  : natural := 50;
    T_RP   : natural := 20;
    T_RC   : natural := 70;
    T_RFC  : natural := 70;
    -- Average refresh interval. 64 ms / 4096 rows is 15.625 us
    T_REFI : natural := 15_000;

    -- Timing parameters in clocks
    T_WR_CLKS  : positive := 2;
    T_MRD_CLKS : positive := 2;

    INIT_REFRESHES : positive := 8
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    -- True once the initialization sequence has completed
    ready : out boolean;
    -- True when start will be accepted
    idle  : out boolean;

    start    : in boolean;
    read     : in boolean;
    write    : in boolean;
    -- Byte address and write data, sampled with start
    address  : in std_logic_vector(22 downto 0);
    data_in  : in std_logic_vector(7 downto 0);
    -- Read data, held until the next read completes
    data_out : out std_logic_vector(7 downto 0);

    dram_addr  : out std_logic_vector(11 downto 0);
    dram_ba    : out std_logic_vector(1 downto 0);
    dram_cs_n  : out std_logic;
    dram_ras_n : out std_logic;
    dram_cas_n : out std_logic;
    dram_we_n  : out std_logic;
    dram_cke   : out std_logic;
    dram_ldqm  : out std_logic;
    dram_udqm  : out std_logic;
    dram_dq    : inout std_logic_vector(15 downto 0)
);
end sdram_ctrl;

architecture behavioral of sdram_ctrl is

    function to_clks(ns : natural) return natural
    is
    begin
        return (ns * (CLK_FREQ / 1_000) + 999_999) / 1_000_000;
    end;

    constant INIT_CLKS : natural := T_INIT_US * (CLK_FREQ / 1_000_000);
    constant RCD_CLKS  : positive := max(1, to_clks(T_RCD));
    constant RAS_CLKS  : positive := max(1, to_clks(T_RAS));
    constant RP_CLKS   : positive := max(1, to_clks(T_RP));
    constant RC_CLKS   : positive := max(1, to_clks(T_RC));
    constant RFC_CLKS  : positive := max(1, to_clks(T_RFC));
    constant REFI_CLKS : positive := max(1, to_clks(T_REFI));

    -- Slot schedule: the clock, relative to the edge start is sampled at,
    -- at which each command is registered onto the SDRAM pins. The SDRAM
    -- samples each command one clock later
    constant ACT_AT : natural := 0;
    constant RW_AT  : natural := ACT_AT + RCD_CLKS;
    constant PRE_AT : natural := max(ACT_AT + RAS_CLKS, RW_AT + T_WR_CLKS);
    -- Read data is on the pins CAS_LATENCY clocks after the SDRAM samples
    -- the READ command
    constant CAP_AT : natural := RW_AT + 1 + CAS_LATENCY;
    constant OUT_AT : natural := CAP_AT + 1;
    constant REF_AT : natural := max(PRE_AT + RP_CLKS, ACT_AT + RC_CLKS);
    constant SLOT_CLKS : positive := max(REF_AT + RFC_CLKS, OUT_AT + 1);

    subtype slot_count_t is natural range 0 to SLOT_CLKS;
    subtype wait_count_t is natural range 0 to max(INIT_CLKS, REFI_CLKS);
    subtype refresh_count_t is natural range 0 to 15;

    type cmd_t is record
        cs_n  : std_logic;
        ras_n : std_logic;
        cas_n : std_logic;
        we_n  : std_logic;
    end record;

    constant CMD_NOP       : cmd_t := ('0', '1', '1', '1');
    constant CMD_ACTIVE    : cmd_t := ('0', '0', '1', '1');
    constant CMD_READ      : cmd_t := ('0', '1', '0', '1');
    constant CMD_WRITE     : cmd_t := ('0', '1', '0', '0');
    constant CMD_PRECHARGE : cmd_t := ('0', '0', '1', '0');
    constant CMD_REFRESH   : cmd_t := ('0', '0', '0', '1');
    constant CMD_MODE      : cmd_t := ('0', '0', '0', '0');

    -- Burst length 1, sequential, programmed CAS latency
    constant MODE_REG : std_logic_vector(11 downto 0) :=
        "00000" &
        to_std_logic_vector(CAS_LATENCY, 3) &
        "0000";

    type init_state_t is
    (
        INIT_POWER_UP,
        INIT_PRECHARGE,
        INIT_REFRESH,
        INIT_MODE,
        INIT_DONE
    );

    type reg_t is record
        init_state : init_state_t;
        init_wait  : wait_count_t;
        init_refs  : natural range 0 to INIT_REFRESHES;

        refi_count  : wait_count_t;
        refs_due    : refresh_count_t;

        active     : boolean;
        slot_count : slot_count_t;
        do_read    : boolean;
        do_write   : boolean;
        do_refresh : boolean;
        bank       : std_logic_vector(1 downto 0);
        row        : std_logic_vector(11 downto 0);
        col        : std_logic_vector(7 downto 0);
        high_byte  : boolean;
        wr_data    : std_logic_vector(7 downto 0);

        -- SDRAM pins. Kept in registers so they can be placed in the I/O
        -- cells
        cmd   : cmd_t;
        addr  : std_logic_vector(11 downto 0);
        ba    : std_logic_vector(1 downto 0);
        dqm   : std_logic_vector(1 downto 0);
        dq    : std_logic_vector(15 downto 0);
        dq_oe : boolean;

        dq_in    : std_logic_vector(15 downto 0);
        data_out : std_logic_vector(7 downto 0);
    end record;

    constant RESET_REG : reg_t :=
    (
        init_state => INIT_POWER_UP,
        init_wait => INIT_CLKS,
        init_refs => 0,

        refi_count => REFI_CLKS,
        refs_due => 0,

        active => false,
        slot_count => 0,
        do_read => false,
        do_write => false,
        do_refresh => false,
        bank => (others => '0'),
        row => (others => '0'),
        col => (others => '0'),
        high_byte => false,
        wr_data => (others => '0'),

        cmd => CMD_NOP,
        addr => (others => '0'),
        ba => (others => '0'),
        dqm => (others => '1'),
        dq => (others => '0'),
        dq_oe => false,

        dq_in => (others => '0'),
        data_out => (others => '0')
    );

    type ctrl_in_t is record
        start   : boolean;
        read    : boolean;
        write   : boolean;
        address : std_logic_vector(22 downto 0);
        data_in : std_logic_vector(7 downto 0);
        dq      : std_logic_vector(15 downto 0);
    end record;

    function cycle_sdram(reg : reg_t; ctrl_in : ctrl_in_t) return reg_t
    is
        variable ret : reg_t;
        variable refreshed : boolean;
    begin
        ret := reg;
        refreshed := false;

        ret.cmd := CMD_NOP;
        ret.dqm := "00";
        ret.dq_oe := false;
        ret.dq_in := ctrl_in.dq;

        case reg.init_state is
            when INIT_POWER_UP =>
                ret.dqm := "11";
                if reg.init_wait = 0
                then
                    ret.cmd := CMD_PRECHARGE;
                    ret.addr(10) := '1';
                    ret.init_wait := RP_CLKS - 1;
                    ret.init_state := INIT_PRECHARGE;
                else
                    ret.init_wait := reg.init_wait - 1;
                end if;
            when INIT_PRECHARGE | INIT_REFRESH =>
                ret.dqm := "11";
                if reg.init_wait /= 0
                then
                    ret.init_wait := reg.init_wait - 1;
                elsif reg.init_refs = INIT_REFRESHES
                then
                    ret.cmd := CMD_MODE;
                    ret.ba := "00";
                    ret.addr := MODE_REG;
                    ret.init_wait := T_MRD_CLKS - 1;
                    ret.init_state := INIT_MODE;
                else
                    ret.cmd := CMD_REFRESH;
                    ret.init_refs := reg.init_refs + 1;
                    ret.init_wait := RFC_CLKS - 1;
                    ret.init_state := INIT_REFRESH;
                end if;
            when INIT_MODE =>
                ret.dqm := "11";
                if reg.init_wait = 0
                then
                    ret.init_state := INIT_DONE;
                else
                    ret.init_wait := reg.init_wait - 1;
                end if;
            when INIT_DONE =>
                if reg.active
                then
                    if reg.slot_count = RW_AT and (reg.do_read or reg.do_write)
                    then
                        if reg.do_write
                        then
                            ret.cmd := CMD_WRITE;
                            ret.dq := reg.wr_data & reg.wr_data;
                            ret.dq_oe := true;
                            -- DQM high masks the byte which is not written
                            if reg.high_byte
                            then
                                ret.dqm := "01";
                            else
                                ret.dqm := "10";
                            end if;
                        else
                            ret.cmd := CMD_READ;
                        end if;
                        ret.ba := reg.bank;
                        -- A10 low disables auto precharge
                        ret.addr := "0000" & reg.col;
                    end if;

                    if reg.slot_count = PRE_AT and (reg.do_read or reg.do_write)
                    then
                        ret.cmd := CMD_PRECHARGE;
                        ret.addr(10) := '1';
                    end if;

                    if reg.slot_count = OUT_AT and reg.do_read
                    then
                        if reg.high_byte
                        then
                            ret.data_out := reg.dq_in(15 downto 8);
                        else
                            ret.data_out := reg.dq_in(7 downto 0);
                        end if;
                    end if;

                    if reg.slot_count = REF_AT and reg.do_refresh
                    then
                        ret.cmd := CMD_REFRESH;
                        refreshed := true;
                    end if;

                    if reg.slot_count = SLOT_CLKS - 1
                    then
                        ret.active := false;
                    end if;
                    ret.slot_count := reg.slot_count + 1;
                elsif ctrl_in.start
                then
                    assert not (ctrl_in.read and ctrl_in.write)
                        report "sdram_ctrl: read and write both requested"
                        severity failure;

                    ret.active := true;
                    ret.slot_count := ACT_AT + 1;
                    ret.do_read := ctrl_in.read;
                    ret.do_write := ctrl_in.write;
                    ret.do_refresh := reg.refs_due /= 0;
                    ret.bank := ctrl_in.address(22 downto 21);
                    ret.row := ctrl_in.address(20 downto 9);
                    ret.col := ctrl_in.address(8 downto 1);
                    ret.high_byte := ctrl_in.address(0) = '1';
                    ret.wr_data := ctrl_in.data_in;

                    if ctrl_in.read or ctrl_in.write
                    then
                        ret.cmd := CMD_ACTIVE;
                        ret.ba := ctrl_in.address(22 downto 21);
                        ret.addr := ctrl_in.address(20 downto 9);
                    end if;
                end if;

                -- Count up the refreshes owed. They are paid back one per
                -- slot, so there is plenty of headroom as long as slots are
                -- started much more often than T_REFI
                if reg.refi_count = 0
                then
                    ret.refi_count := REFI_CLKS - 1;
                    if not refreshed
                    then
                        assert reg.refs_due /= refresh_count_t'high
                            report "sdram_ctrl: refresh overflow"
                            severity failure;
                        ret.refs_due := reg.refs_due + 1;
                    end if;
                else
                    ret.refi_count := reg.refi_count - 1;
                    if refreshed
                    then
                        ret.refs_due := reg.refs_due - 1;
                    end if;
                end if;
        end case;

        return ret;
    end;

    signal reg : reg_t := RESET_REG;

begin

    dram_cs_n  <= reg.cmd.cs_n;
    dram_ras_n <= reg.cmd.ras_n;
    dram_cas_n <= reg.cmd.cas_n;
    dram_we_n  <= reg.cmd.we_n;
    dram_cke   <= '1';
    dram_addr  <= reg.addr;
    dram_ba    <= reg.ba;
    dram_ldqm  <= reg.dqm(0);
    dram_udqm  <= reg.dqm(1);
    dram_dq    <= reg.dq when reg.dq_oe else (others => 'Z');

    ready    <= reg.init_state = INIT_DONE;
    idle     <= reg.init_state = INIT_DONE and not reg.active;
    data_out <= reg.data_out;

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= cycle_sdram(reg, (start => start,
                                     read => read,
                                     write => write,
                                     address => address,
                                     data_in => data_in,
                                     dq => dram_dq));
        end if;
    end if;
    end process;

end behavioral;
