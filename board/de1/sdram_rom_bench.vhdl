library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.nes_types.all;
use work.file_bus_types.all;
use work.simulation.all;

-- Copies a file from an SD card model, or a flash model, into the SDRAM
-- model through sdram_rom, then performs random reads paced by the real NES
-- clock enables and checks the data against the file.
entity sdram_rom_bench is
generic
(
    NES_FILEPATH   : string;
    NES_FILE_BYTES : positive;
    NUM_WINDOWS    : positive := 100_000;

    USE_SD_CARD      : boolean := true;
    SD_HIGH_CAPACITY : boolean := true;
    SD_VERSION_1     : boolean := false;
    SD_START_BLOCK   : natural := 0
);
end sdram_rom_bench;

architecture behavioral of sdram_rom_bench is

    signal clk_50   : std_logic;
    signal clk_dram : std_logic;

    signal loading : boolean;

    signal load_valid : boolean;
    signal load_data  : data_t;
    signal load_ready : boolean;

    signal ppu_en : boolean;

    signal file_bus  : file_bus_t := FILE_BUS_IDLE;
    signal file_data : data_t;
    signal ref_data  : data_t;

    signal dram_addr  : std_logic_vector(11 downto 0);
    signal dram_ba    : std_logic_vector(1 downto 0);
    signal dram_cs_n  : std_logic;
    signal dram_ras_n : std_logic;
    signal dram_cas_n : std_logic;
    signal dram_we_n  : std_logic;
    signal dram_cke   : std_logic;
    signal dram_ldqm  : std_logic;
    signal dram_udqm  : std_logic;
    signal dram_dq    : std_logic_vector(15 downto 0);

begin

    dut : entity work.sdram_rom(behavioral)
    port map
    (
        clk => clk_50,
        reset => false,

        loading => loading,

        load_valid => load_valid,
        load_data => load_data,
        load_ready => load_ready,

        ppu_clk_en => ppu_en,
        file_bus => file_bus,
        data_from_file => file_data,

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

    dram : entity work.sdram(behavioral)
    port map
    (
        clk => clk_dram,
        cke => dram_cke,
        cs_n => dram_cs_n,
        ras_n => dram_ras_n,
        cas_n => dram_cas_n,
        we_n => dram_we_n,
        ba => dram_ba,
        addr => dram_addr,
        ldqm => dram_ldqm,
        udqm => dram_udqm,
        dq => dram_dq
    );

    gen_sd_card : if USE_SD_CARD generate
        signal sd_error : boolean;
        signal sd_clk   : std_logic;
        signal sd_cs_n  : std_logic;
        signal sd_mosi  : std_logic;
        signal sd_miso  : std_logic;
    begin
        reader : entity work.sd_reader(behavioral)
        generic map
        (
            START_BLOCK => SD_START_BLOCK
        )
        port map
        (
            clk => clk_50,
            reset => false,

            failed => sd_error,

            stop => not loading,
            data => load_data,
            valid => load_valid,
            ready => load_ready,

            sd_clk => sd_clk,
            sd_cs_n => sd_cs_n,
            sd_mosi => sd_mosi,
            sd_miso => sd_miso
        );

        card : entity work.sd_card(behavioral)
        generic map
        (
            FILEPATH => NES_FILEPATH,
            FILE_BYTES => NES_FILE_BYTES,
            START_BLOCK => SD_START_BLOCK,
            HIGH_CAPACITY => SD_HIGH_CAPACITY,
            VERSION_1 => SD_VERSION_1
        )
        port map
        (
            sck => sd_clk,
            cs_n => sd_cs_n,
            mosi => sd_mosi,
            miso => sd_miso
        );

        -- Pull up on the board
        sd_miso <= 'H';

        assert not sd_error
            report "SD card error"
            severity failure;
    else generate
        signal flash_bus  : file_bus_t;
        signal flash_data : data_t;
    begin
        reader : entity work.flash_stream(behavioral)
        port map
        (
            clk => clk_50,
            reset => false,

            flash_bus => flash_bus,
            data_from_flash => flash_data,

            stop => not loading,
            data => load_data,
            valid => load_valid,
            ready => load_ready
        );

        flash : file_memory
        generic map
        (
            FILEPATH => NES_FILEPATH,
            MEM_BYTES => NES_FILE_BYTES,
            READ_DELAY => 110 ns
        )
        port map
        (
            file_bus_1 => flash_bus,
            data_from_file_1 => flash_data
        );
    end generate;

    process
    begin
        wait until not loading;
        report "Loaded in " & time'image(now);
        wait;
    end process;

    reference : file_memory
    generic map
    (
        FILEPATH => NES_FILEPATH,
        MEM_BYTES => NES_FILE_BYTES
    )
    port map
    (
        file_bus_1 => file_bus,
        data_from_file_1 => ref_data
    );

    nes_clk_en : entity work.clk_en(behavioral)
    port map
    (
        clk => clk_50,
        reset => loading,

        cpu_en => open,
        ppu_en => ppu_en,
        nsf_en => open,

        cpu_ram_en => open,
        ppu_ram_en => open,

        ppu_sync => open,
        odd_cpu_cycle => open
    );

    -- Like the NES core, change the file bus right after each PPU clock
    -- enable and consume the data at the next one
    process(clk_50)
        variable seed1   : positive := 1;
        variable seed2   : positive := 2;
        variable rand    : real;
        variable windows : natural := 0;
        variable reads   : natural := 0;
        variable errors  : natural := 0;
    begin
    if rising_edge(clk_50) and ppu_en
    then
        if is_bus_read(file_bus)
        then
            reads := reads + 1;
            if file_data /= ref_data
            then
                errors := errors + 1;
                report "Mismatch at " &
                       integer'image(to_integer(unsigned(file_bus.address))) &
                       ": expected " & to_hstring(ref_data) &
                       " got " & to_hstring(file_data)
                    severity error;
            end if;
        end if;

        windows := windows + 1;
        if windows = NUM_WINDOWS
        then
            assert errors = 0
                report integer'image(errors) & " read errors"
                severity failure;
            report "PASS: " & integer'image(reads) & " reads in " &
                   integer'image(windows) & " PPU cycles";
            std.env.finish;
        end if;

        uniform(seed1, seed2, rand);
        if rand < 0.75
        then
            uniform(seed1, seed2, rand);
            file_bus <= bus_read(to_unsigned(
                integer(floor(rand * real(NES_FILE_BYTES))),
                file_addr_t'length));
        else
            file_bus <= FILE_BUS_IDLE;
        end if;
    end if;
    end process;

    clk_50mhz_gen : clock
    generic map
    (
        PERIOD => 20 ns,
        OFFSET => 20 ns
    )
    port map
    (
        clk => clk_50,
        done => false
    );

    -- The SDRAM clock leads the system clock, like CLOCK_WE on the board
    clk_dram_gen : clock
    generic map
    (
        PERIOD => 20 ns,
        OFFSET => 18 ns
    )
    port map
    (
        clk => clk_dram,
        done => false
    );

end behavioral;
