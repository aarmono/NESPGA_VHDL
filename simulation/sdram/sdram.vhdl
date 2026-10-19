library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Behavioral model of a 4 bank x 4096 row x 256 column x 16 bit SDR SDRAM,
-- like the 8 MB part on the DE1. Only the features sdram_ctrl uses are
-- modeled: burst length 1 and no auto precharge. The initialization
-- sequence, command timing and refresh interval are checked against the
-- generics and violations are reported with severity error.
--
-- The defaults are the worst case of the -7 and -8 speed grades of the
-- IS42S16400 at CAS latency 2. Its datasheet has no separate tRFC, an auto
-- refresh takes tRC. tOH is derated from 3.0 ns to 2.5 ns to match NES.sdc
entity sdram is
generic
(
    T_INIT : time := 200 us;
    T_RCD  : time := 20 ns;
    T_RAS  : time := 50 ns;
    T_RP   : time := 20 ns;
    T_RC   : time := 70 ns;
    T_RFC  : time := 70 ns;
    T_WR   : time := 20 ns;
    T_MRD_CLKS : positive := 2;
    -- Clock to data out, and data out hold after the following clock
    T_AC   : time := 6 ns;
    T_OH   : time := 2.5 ns;
    -- Longest allowed gap between refreshes: up to 8 refreshes may be
    -- postponed past the 64 ms / 4096 row average interval
    T_REF_MAX : time := 9 * 15625 ns;
    INIT_REFRESHES : positive := 8
);
port
(
    clk   : in std_logic;
    cke   : in std_logic;
    cs_n  : in std_logic;
    ras_n : in std_logic;
    cas_n : in std_logic;
    we_n  : in std_logic;
    ba    : in std_logic_vector(1 downto 0);
    addr  : in std_logic_vector(11 downto 0);
    ldqm  : in std_logic;
    udqm  : in std_logic;
    dq    : inout std_logic_vector(15 downto 0)
);
end sdram;

architecture behavioral of sdram is

    subtype word_t is std_logic_vector(15 downto 0);
    type mem_t is array(0 to 2**22-1) of word_t;
    type mem_ptr_t is access mem_t;

    type bank_times_t is array(0 to 3) of time;
    type bank_flags_t is array(0 to 3) of boolean;
    type bank_rows_t is array(0 to 3) of natural;

begin

    process
        variable mem : mem_ptr_t := new mem_t;

        variable first_clk : time := -1 ns;
        variable last_clk  : time := 0 ns;
        variable t_ck      : time := 0 ns;

        variable bank_open : bank_flags_t := (others => false);
        variable bank_row  : bank_rows_t := (others => 0);
        variable last_act  : bank_times_t := (others => -1 sec);
        variable last_pre  : bank_times_t := (others => -1 sec);
        variable last_wr   : bank_times_t := (others => -1 sec);
        variable last_ref  : time := -1 sec;
        variable mode_clk  : natural := 0;
        variable clk_count : natural := 0;

        variable precharged : boolean := false;
        variable init_refs  : natural := 0;
        variable mode_set   : boolean := false;
        variable cas_lat    : natural := 2;
        variable ref_late   : boolean := false;

        variable b    : natural;
        variable idx  : natural;
        variable word : word_t;

        procedure check(cond : boolean; msg : string) is
        begin
            assert cond report "sdram: " & msg severity error;
        end;

        procedure check_bank_ready(bnk : natural; cmd : string) is
        begin
            check(not bank_open(bnk), cmd & " to open bank");
            check(now - last_pre(bnk) >= T_RP, cmd & " tRP violation");
            check(now - last_act(bnk) >= T_RC, cmd & " tRC violation");
            check(now - last_ref >= T_RFC, cmd & " tRFC violation");
        end;

    begin
        dq <= (others => 'Z');

        loop
            wait until rising_edge(clk);

            if first_clk < 0 ns
            then
                first_clk := now;
            end if;
            t_ck := now - last_clk;
            last_clk := now;
            clk_count := clk_count + 1;

            if mode_set and not ref_late and now - last_ref > T_REF_MAX
            then
                check(false, "refresh interval exceeded");
                ref_late := true;
            end if;

            if cke = '1' and cs_n = '0' and
               not (ras_n = '1' and cas_n = '1' and we_n = '1')
            then
                b := to_integer(unsigned(ba));
                check(now - first_clk >= T_INIT,
                      "command before power up delay");

                if ras_n = '0' and cas_n = '1' and we_n = '1'
                then
                    -- ACTIVE
                    check(mode_set, "ACTIVE before mode register set");
                    check_bank_ready(b, "ACTIVE");
                    check(clk_count - mode_clk >= T_MRD_CLKS,
                          "ACTIVE tMRD violation");
                    bank_open(b) := true;
                    bank_row(b) := to_integer(unsigned(addr));
                    last_act(b) := now;
                elsif ras_n = '1' and cas_n = '0'
                then
                    -- READ or WRITE
                    check(bank_open(b), "READ/WRITE to closed bank");
                    check(now - last_act(b) >= T_RCD,
                          "READ/WRITE tRCD violation");
                    check(addr(10) = '0', "auto precharge is not modeled");
                    idx := b * 2**20 + bank_row(b) * 2**8 +
                           to_integer(unsigned(addr(7 downto 0)));

                    if we_n = '0'
                    then
                        word := mem(idx);
                        if ldqm = '0'
                        then
                            check(not is_x(dq(7 downto 0)),
                                  "WRITE of undefined low byte");
                            word(7 downto 0) := dq(7 downto 0);
                        end if;
                        if udqm = '0'
                        then
                            check(not is_x(dq(15 downto 8)),
                                  "WRITE of undefined high byte");
                            word(15 downto 8) := dq(15 downto 8);
                        end if;
                        mem(idx) := word;
                        last_wr(b) := now;
                    else
                        word := mem(idx);
                        if ldqm = '1'
                        then
                            word(7 downto 0) := (others => 'Z');
                        end if;
                        if udqm = '1'
                        then
                            word(15 downto 8) := (others => 'Z');
                        end if;
                        dq <= transport
                            word after (cas_lat - 1) * t_ck + T_AC,
                            (others => 'Z') after cas_lat * t_ck + T_OH;
                    end if;
                elsif ras_n = '0' and cas_n = '1' and we_n = '0'
                then
                    -- PRECHARGE
                    for i in bank_open'range
                    loop
                        if (addr(10) = '1' or i = b) and bank_open(i)
                        then
                            check(now - last_act(i) >= T_RAS,
                                  "PRECHARGE tRAS violation");
                            check(now - last_wr(i) >= T_WR,
                                  "PRECHARGE tWR violation");
                            bank_open(i) := false;
                        end if;
                        if addr(10) = '1' or i = b
                        then
                            last_pre(i) := now;
                        end if;
                    end loop;
                    if addr(10) = '1'
                    then
                        precharged := true;
                    end if;
                elsif ras_n = '0' and cas_n = '0' and we_n = '1'
                then
                    -- AUTO REFRESH
                    check(precharged, "REFRESH before initial precharge");
                    for i in bank_open'range
                    loop
                        check_bank_ready(i, "REFRESH");
                    end loop;
                    last_ref := now;
                    ref_late := false;
                    init_refs := init_refs + 1;
                elsif ras_n = '0' and cas_n = '0' and we_n = '0'
                then
                    -- LOAD MODE REGISTER
                    check(init_refs >= INIT_REFRESHES,
                          "mode register set before initial refreshes");
                    for i in bank_open'range
                    loop
                        check_bank_ready(i, "LOAD MODE");
                    end loop;
                    check(addr(2 downto 0) = "000",
                          "only burst length 1 is modeled");
                    cas_lat := to_integer(unsigned(addr(6 downto 4)));
                    check(cas_lat = 2 or cas_lat = 3,
                          "invalid CAS latency");
                    mode_clk := clk_count;
                    mode_set := true;
                elsif ras_n = '1' and cas_n = '1' and we_n = '0'
                then
                    check(false, "BURST TERMINATE is not modeled");
                end if;
            end if;
        end loop;
    end process;

end behavioral;
