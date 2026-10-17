library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.file_bus_types.all;

-- Serves the NES file bus out of SDRAM instead of flash.
--
-- After reset the first LOAD_BYTES of flash are copied into SDRAM while
-- loading is true, during which the NES must be held in reset. Once loading
-- is complete each PPU cycle gets one SDRAM slot, started START_DELAY clocks
-- after ppu_clk_en. The file bus address is sampled when the slot starts, so
-- it must be stable from then until the next ppu_clk_en, and the read data is
-- ready well before that.
entity sdram_rom is
generic
(
    CLK_FREQ   : positive := 50_000_000;
    LOAD_BYTES : positive := 2**file_addr_t'length;
    -- Clocks to wait after changing the flash address before sampling data
    FLASH_READ_CLKS : positive := 8;
    -- Clocks after ppu_clk_en until the file bus address is sampled
    START_DELAY : positive := 2
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    loading : out boolean;

    flash_bus       : out file_bus_t;
    data_from_flash : in data_t;

    ppu_clk_en     : in boolean;
    file_bus       : in file_bus_t;
    data_from_file : out data_t;

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
end sdram_rom;

architecture behavioral of sdram_rom is

    subtype sdram_addr_t is std_logic_vector(22 downto 0);
    subtype load_addr_t is natural range 0 to LOAD_BYTES - 1;
    subtype flash_wait_t is natural range 0 to FLASH_READ_CLKS;

    type state_t is
    (
        STATE_INIT,
        STATE_COPY,
        STATE_RUN
    );

    type reg_t is record
        state      : state_t;
        load_addr  : load_addr_t;
        flash_wait : flash_wait_t;
        ppu_delay  : boolean_array(START_DELAY - 1 downto 0);
    end record;

    constant RESET_REG : reg_t :=
    (
        state => STATE_INIT,
        load_addr => 0,
        flash_wait => FLASH_READ_CLKS,
        ppu_delay => (others => false)
    );

    signal reg    : reg_t := RESET_REG;
    signal reg_in : reg_t;

    signal sdram_ready : boolean;
    signal sdram_idle  : boolean;
    signal start       : boolean;
    signal read        : boolean;
    signal write       : boolean;
    signal address     : sdram_addr_t;

begin

    loading <= reg.state /= STATE_RUN;

    ctrl : entity work.sdram_ctrl(behavioral)
    generic map
    (
        CLK_FREQ => CLK_FREQ
    )
    port map
    (
        clk => clk,
        reset => reset,

        ready => sdram_ready,
        idle => sdram_idle,

        start => start,
        read => read,
        write => write,
        address => address,
        data_in => data_from_flash,
        data_out => data_from_file,

        dram_addr => dram_addr,
        dram_ba => dram_ba,
        dram_cs_n => dram_cs_n,
        dram_ras_n => dram_ras_n,
        dram_cas_n => dram_cas_n,
        dram_we_n => dram_we_n,
        dram_cke => dram_cke,
        dram_ldqm => dram_ldqm,
        dram_udqm => dram_udqm,
        dram_dq => dram_dq
    );

    process(all)
        variable v_reg : reg_t;
    begin
        v_reg := reg;

        v_reg.ppu_delay := shift_left(reg.ppu_delay, ppu_clk_en);

        flash_bus <= FILE_BUS_IDLE;
        start <= false;
        read <= false;
        write <= false;
        address <= (others => '-');

        case reg.state is
            when STATE_INIT =>
                if sdram_ready
                then
                    v_reg.state := STATE_COPY;
                end if;
            when STATE_COPY =>
                flash_bus <= bus_read(to_unsigned(reg.load_addr,
                                                  file_addr_t'length));
                address <= std_logic_vector(
                    to_unsigned(reg.load_addr, sdram_addr_t'length));

                if reg.flash_wait /= 0
                then
                    v_reg.flash_wait := reg.flash_wait - 1;
                elsif sdram_idle
                then
                    start <= true;
                    write <= true;

                    v_reg.flash_wait := FLASH_READ_CLKS;
                    if reg.load_addr = load_addr_t'high
                    then
                        v_reg.state := STATE_RUN;
                    else
                        v_reg.load_addr := reg.load_addr + 1;
                    end if;
                end if;
            when STATE_RUN =>
                start <= reg.ppu_delay(reg.ppu_delay'high);
                read <= is_bus_read(file_bus);
                address <= resize(file_bus.address, sdram_addr_t'length);
        end case;

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

    -- pragma translate_off
    -- Check the assumptions that make one fixed slot per PPU cycle work: the
    -- slot is never started while the previous one is still running, and
    -- the file bus does not change between the start of the slot and the
    -- PPU clock enable at which the data is consumed
    process(clk)
        variable slot_bus : file_bus_t := FILE_BUS_IDLE;
    begin
    if rising_edge(clk)
    then
        if reg.state = STATE_RUN and not reset
        then
            if start
            then
                assert sdram_idle
                    report "sdram_rom: slot started while SDRAM busy"
                    severity error;
                slot_bus := file_bus;
            elsif is_bus_read(slot_bus)
            then
                assert file_bus = slot_bus
                    report "sdram_rom: file bus changed during SDRAM read"
                    severity error;
            end if;

            if ppu_clk_en
            then
                slot_bus := FILE_BUS_IDLE;
            end if;
        end if;
    end if;
    end process;
    -- pragma translate_on

end behavioral;
