library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

-- Streams the contents of an SD card, starting at START_BLOCK, over SPI.
--
-- After reset the card is initialized (CMD0, CMD8, ACMD41, CMD58, CMD16) at
-- INIT_SCK_FREQ and then read one 512 byte block at a time with CMD17 at
-- SCK_FREQ. Both standard capacity (byte addressed) and high capacity
-- (block addressed) cards are supported.
--
-- Each received byte is presented on data with valid true until it is taken
-- by a clock where ready is also true. The card clock is paused until then,
-- so the consumer may take as long as it likes. Once stop is true the rest
-- of the current block is read and discarded and the card is deselected, so
-- that it is left in a state where it can be initialized again after a
-- reset.
--
-- If the card does not respond as expected failed becomes true and the
-- reader stops until the next reset.
--
-- MISO is registered and sampled on the clock before the falling edge of
-- SCK, so there is at least SCK_FREQ / 2 periods minus one clock between
-- the card changing MISO and it being sampled. SCK_FREQ must be no more than
-- CLK_FREQ / 4 so that this is at least one clock.
entity sd_reader is
generic
(
    CLK_FREQ      : positive := 50_000_000;
    INIT_SCK_FREQ : positive := 400_000;
    SCK_FREQ      : positive := 12_500_000;

    START_BLOCK : natural := 0;

    -- Time to wait after reset before talking to the card
    POWER_UP_US : natural := 1000;
    -- Time allowed for the card to finish initializing, and for each block
    -- read to start
    TIMEOUT_MS  : positive := 1000;
    -- CMD0 is retried, which lets a card that was left part way through a
    -- block read finish sending it and then be reset
    CMD0_TRIES  : positive := 64
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    failed : out boolean;

    stop  : in boolean;
    data  : out std_logic_vector(7 downto 0);
    valid : out boolean;
    ready : in boolean;

    sd_clk  : out std_logic;
    sd_cs_n : out std_logic;
    sd_mosi : out std_logic;
    sd_miso : in std_logic
);
end sd_reader;

architecture behavioral of sd_reader is

    constant INIT_HALF_CLKS : positive :=
        (CLK_FREQ + 2 * INIT_SCK_FREQ - 1) / (2 * INIT_SCK_FREQ);
    constant HALF_CLKS : positive :=
        (CLK_FREQ + 2 * SCK_FREQ - 1) / (2 * SCK_FREQ);

    constant POWER_UP_CLKS : natural := POWER_UP_US * (CLK_FREQ / 1_000_000);
    constant TIMEOUT_CLKS  : positive := TIMEOUT_MS * (CLK_FREQ / 1_000);

    -- Bytes of 0xFF clocked with CS high before the first command. At least
    -- 74 clocks are required
    constant WAKE_BYTES : positive := 10;
    -- Bytes polled for a command response. The card responds within 8
    constant NCR_BYTES  : positive := 16;
    constant BLOCK_BYTES : positive := 512;

    subtype div_t is natural range 0 to INIT_HALF_CLKS - 1;
    subtype timer_t is natural range 0 to max(POWER_UP_CLKS, TIMEOUT_CLKS);
    subtype count_t is natural range 0 to BLOCK_BYTES - 1;
    subtype block_t is natural range 0 to 2**23 - 1;
    subtype byte_t is std_logic_vector(7 downto 0);
    subtype frame_t is std_logic_vector(47 downto 0);

    type state_t is
    (
        ST_POWER_UP,
        -- Clock WAKE_BYTES with CS high
        ST_WAKE,
        -- Send the command in frame
        ST_CMD,
        -- Poll for the R1 response
        ST_RESP,
        -- Read the 4 bytes after R1 in an R3 or R7 response
        ST_RESP_EXTRA,
        -- Poll for the data token
        ST_TOKEN,
        ST_DATA,
        ST_CRC,
        -- Clock one byte with CS high, then send cmd
        ST_DESELECT,
        ST_DONE,
        ST_ERROR
    );

    type cmd_t is
    (
        CMD_GO_IDLE,
        CMD_SEND_IF_COND,
        CMD_APP,
        CMD_APP_SEND_OP_COND,
        CMD_READ_OCR,
        CMD_SET_BLOCKLEN,
        CMD_READ_BLOCK
    );

    type reg_t is record
        state : state_t;
        cmd   : cmd_t;
        frame : frame_t;
        count : count_t;
        tries : natural range 0 to CMD0_TRIES;
        timer : timer_t;

        -- Card is version 2.00 or later and accepted CMD8
        v2         : boolean;
        -- Card is high capacity and is addressed in blocks
        block_addr : boolean;
        blk        : block_t;

        r1    : byte_t;
        extra : std_logic_vector(31 downto 0);

        -- Byte transfer
        busy  : boolean;
        fast  : boolean;
        div   : div_t;
        bits  : natural range 0 to 7;
        shift : byte_t;

        -- SPI pins
        sck  : std_logic;
        cs_n : std_logic;
        mosi : std_logic;
        miso : std_logic;
    end record;

    constant RESET_REG : reg_t :=
    (
        state => ST_POWER_UP,
        cmd => CMD_GO_IDLE,
        frame => (others => '1'),
        count => 0,
        tries => 0,
        timer => POWER_UP_CLKS,

        v2 => false,
        block_addr => false,
        blk => START_BLOCK,

        r1 => (others => '1'),
        extra => (others => '1'),

        busy => false,
        fast => false,
        div => 0,
        bits => 0,
        shift => (others => '1'),

        sck => '0',
        cs_n => '1',
        mosi => '1',
        miso => '1'
    );

    signal reg    : reg_t := RESET_REG;
    signal reg_in : reg_t;

    -- Start clocking a byte out on MOSI and in from MISO. The received byte
    -- is in shift once busy is false again
    procedure start_byte(v : inout reg_t; tx : in byte_t)
    is
    begin
        v.busy := true;
        v.bits := 0;
        v.shift := tx;
        v.mosi := tx(7);
        if v.fast
        then
            v.div := HALF_CLKS - 1;
        else
            v.div := INIT_HALF_CLKS - 1;
        end if;
    end;

    -- Select the card and start sending cmd, preceded by one byte of 0xFF
    procedure start_cmd(v : inout reg_t; cmd : in cmd_t)
    is
        variable index : natural range 0 to 63;
        variable arg   : std_logic_vector(31 downto 0);
        -- Only CMD0 and CMD8 are checked before the CRC is disabled
        variable crc   : std_logic_vector(6 downto 0);
    begin
        arg := (others => '0');
        crc := (others => '1');
        case cmd is
            when CMD_GO_IDLE =>
                index := 0;
                crc := "1001010";
            when CMD_SEND_IF_COND =>
                -- 2.7-3.6V and check pattern 0xAA
                index := 8;
                arg := x"000001AA";
                crc := "1000011";
            when CMD_APP =>
                index := 55;
            when CMD_APP_SEND_OP_COND =>
                index := 41;
                -- HCS: the host supports high capacity cards
                if v.v2
                then
                    arg(30) := '1';
                end if;
            when CMD_READ_OCR =>
                index := 58;
            when CMD_SET_BLOCKLEN =>
                index := 16;
                arg := std_logic_vector(to_unsigned(BLOCK_BYTES, 32));
            when CMD_READ_BLOCK =>
                index := 17;
                if v.block_addr
                then
                    arg := std_logic_vector(to_unsigned(v.blk, 32));
                else
                    arg := std_logic_vector(to_unsigned(v.blk, 23)) &
                           "000000000";
                end if;
        end case;

        v.cmd := cmd;
        v.frame := "01" & std_logic_vector(to_unsigned(index, 6)) &
                   arg & crc & "1";
        v.count := 0;
        v.cs_n := '0';
        v.state := ST_CMD;
        start_byte(v, x"FF");
    end;

    -- Deselect the card for one byte and then send cmd
    procedure deselect(v : inout reg_t; cmd : in cmd_t)
    is
    begin
        v.cmd := cmd;
        v.cs_n := '1';
        v.state := ST_DESELECT;
        start_byte(v, x"FF");
    end;

    procedure fail(v : inout reg_t)
    is
    begin
        v.cs_n := '1';
        v.mosi := '1';
        v.state := ST_ERROR;
    end;

begin

    sd_clk  <= reg.sck;
    sd_cs_n <= reg.cs_n;
    sd_mosi <= reg.mosi;

    failed <= reg.state = ST_ERROR;
    data  <= reg.shift;
    valid <= reg.state = ST_DATA and not reg.busy and not stop;

    process(all)
        variable v_reg : reg_t;
        variable v_resp_done : boolean;
    begin
        v_reg := reg;
        v_resp_done := false;

        v_reg.miso := to_x01(sd_miso);

        if reg.timer /= 0
        then
            v_reg.timer := reg.timer - 1;
        end if;

        -- Byte transfer, SPI mode 0. MOSI changes on the falling edge of
        -- SCK and MISO is sampled just before it
        if reg.busy
        then
            if reg.div /= 0
            then
                v_reg.div := reg.div - 1;
            else
                if reg.fast
                then
                    v_reg.div := HALF_CLKS - 1;
                else
                    v_reg.div := INIT_HALF_CLKS - 1;
                end if;

                if reg.sck = '0'
                then
                    v_reg.sck := '1';
                else
                    v_reg.sck := '0';
                    v_reg.shift := reg.shift(6 downto 0) & reg.miso;
                    if reg.bits = 7
                    then
                        v_reg.busy := false;
                        v_reg.mosi := '1';
                    else
                        v_reg.bits := reg.bits + 1;
                        v_reg.mosi := reg.shift(6);
                    end if;
                end if;
            end if;
        else
            case reg.state is
                when ST_POWER_UP =>
                    if reg.timer = 0
                    then
                        v_reg.count := 0;
                        v_reg.state := ST_WAKE;
                        start_byte(v_reg, x"FF");
                    end if;
                when ST_WAKE =>
                    if reg.count = WAKE_BYTES - 1
                    then
                        start_cmd(v_reg, CMD_GO_IDLE);
                    else
                        v_reg.count := reg.count + 1;
                        start_byte(v_reg, x"FF");
                    end if;
                when ST_CMD =>
                    if reg.count = 6
                    then
                        v_reg.count := 0;
                        v_reg.state := ST_RESP;
                        start_byte(v_reg, x"FF");
                    else
                        v_reg.count := reg.count + 1;
                        v_reg.frame := reg.frame(39 downto 0) & x"FF";
                        start_byte(v_reg, reg.frame(47 downto 40));
                    end if;
                when ST_RESP =>
                    if reg.shift(7) = '0' or reg.count = NCR_BYTES - 1
                    then
                        -- A timeout leaves r1 as 0xFF, which every
                        -- command treats as a failure
                        v_reg.r1 := reg.shift;
                        if reg.cmd = CMD_SEND_IF_COND or reg.cmd = CMD_READ_OCR
                        then
                            v_reg.count := 0;
                            v_reg.state := ST_RESP_EXTRA;
                            start_byte(v_reg, x"FF");
                        else
                            v_resp_done := true;
                        end if;
                    else
                        v_reg.count := reg.count + 1;
                        start_byte(v_reg, x"FF");
                    end if;
                when ST_RESP_EXTRA =>
                    v_reg.extra := reg.extra(23 downto 0) & reg.shift;
                    if reg.count = 3
                    then
                        v_resp_done := true;
                    else
                        v_reg.count := reg.count + 1;
                        start_byte(v_reg, x"FF");
                    end if;
                when ST_TOKEN =>
                    if reg.shift = x"FE"
                    then
                        v_reg.count := 0;
                        v_reg.state := ST_DATA;
                        start_byte(v_reg, x"FF");
                    elsif reg.shift /= x"FF" or reg.timer = 0
                    then
                        -- Data error token, or no response
                        fail(v_reg);
                    else
                        start_byte(v_reg, x"FF");
                    end if;
                when ST_DATA =>
                    if ready or stop
                    then
                        if reg.count = BLOCK_BYTES - 1
                        then
                            v_reg.count := 0;
                            v_reg.state := ST_CRC;
                        else
                            v_reg.count := reg.count + 1;
                        end if;
                        start_byte(v_reg, x"FF");
                    end if;
                when ST_CRC =>
                    if reg.count = 1
                    then
                        if reg.blk /= block_t'high
                        then
                            v_reg.blk := reg.blk + 1;
                        end if;
                        deselect(v_reg, CMD_READ_BLOCK);
                    else
                        v_reg.count := reg.count + 1;
                        start_byte(v_reg, x"FF");
                    end if;
                when ST_DESELECT =>
                    if stop
                    then
                        v_reg.state := ST_DONE;
                    else
                        start_cmd(v_reg, reg.cmd);
                    end if;
                when ST_DONE | ST_ERROR =>
                    null;
            end case;
        end if;

        if v_resp_done
        then
            case reg.cmd is
                when CMD_GO_IDLE =>
                    if v_reg.r1 = x"01"
                    then
                        deselect(v_reg, CMD_SEND_IF_COND);
                    elsif reg.tries = CMD0_TRIES - 1
                    then
                        fail(v_reg);
                    else
                        v_reg.tries := reg.tries + 1;
                        deselect(v_reg, CMD_GO_IDLE);
                    end if;
                when CMD_SEND_IF_COND =>
                    -- Version 1 cards reject CMD8 as an illegal command
                    v_reg.timer := TIMEOUT_CLKS;
                    if v_reg.r1 = x"01" and v_reg.extra(11 downto 0) = x"1AA"
                    then
                        v_reg.v2 := true;
                        deselect(v_reg, CMD_APP);
                    elsif v_reg.r1 = x"05"
                    then
                        v_reg.v2 := false;
                        deselect(v_reg, CMD_APP);
                    else
                        fail(v_reg);
                    end if;
                when CMD_APP =>
                    if v_reg.r1(7 downto 1) = "0000000"
                    then
                        deselect(v_reg, CMD_APP_SEND_OP_COND);
                    else
                        fail(v_reg);
                    end if;
                when CMD_APP_SEND_OP_COND =>
                    if v_reg.r1 = x"00"
                    then
                        if reg.v2
                        then
                            deselect(v_reg, CMD_READ_OCR);
                        else
                            deselect(v_reg, CMD_SET_BLOCKLEN);
                        end if;
                    elsif v_reg.r1 = x"01" and reg.timer /= 0
                    then
                        -- Still initializing
                        deselect(v_reg, CMD_APP);
                    else
                        fail(v_reg);
                    end if;
                when CMD_READ_OCR =>
                    if v_reg.r1 = x"00"
                    then
                        -- CCS
                        v_reg.block_addr := v_reg.extra(30) = '1';
                        if v_reg.block_addr
                        then
                            v_reg.fast := true;
                            deselect(v_reg, CMD_READ_BLOCK);
                        else
                            deselect(v_reg, CMD_SET_BLOCKLEN);
                        end if;
                    else
                        fail(v_reg);
                    end if;
                when CMD_SET_BLOCKLEN =>
                    if v_reg.r1 = x"00"
                    then
                        v_reg.fast := true;
                        deselect(v_reg, CMD_READ_BLOCK);
                    else
                        fail(v_reg);
                    end if;
                when CMD_READ_BLOCK =>
                    if v_reg.r1 = x"00"
                    then
                        -- Keep the card selected and wait for the data
                        v_reg.timer := TIMEOUT_CLKS;
                        v_reg.state := ST_TOKEN;
                        start_byte(v_reg, x"FF");
                    else
                        fail(v_reg);
                    end if;
            end case;
        end if;

        reg_in <= v_reg;
    end process;

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= reg_in;
        end if;
    end if;
    end process;

end behavioral;
