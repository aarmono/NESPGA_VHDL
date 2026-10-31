library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_mem_bus_types.all;
use work.file_bus_types.all;
use work.simulation.all;

-- Copies a file from an SD card model, or a flash model, into the SDRAM
-- model through sdram_rom, then performs random accesses paced by the real
-- NES clock enables: reads of the file, checked against the file, and
-- writes and reads of a RAM window above it, checked against what was
-- written. With REQUIRE_INES and EXPECT_NO_HEADER, the file is instead
-- expected not to start with an iNES header, so loading must stop without
-- completing.
entity sdram_rom_bench is
generic
(
    NES_FILEPATH   : string;
    NES_FILE_BYTES : positive;
    NUM_WINDOWS    : positive := 100_000;

    USE_SD_CARD      : boolean := true;
    SD_HIGH_CAPACITY : boolean := true;
    SD_VERSION_1     : boolean := false;
    SD_START_BLOCK   : natural := 0;

    REQUIRE_INES     : boolean := false;
    EXPECT_NO_HEADER : boolean := false
);
end sdram_rom_bench;

architecture behavioral of sdram_rom_bench is

    signal clk_50   : std_logic;
    signal clk_dram : std_logic;

    signal loading   : boolean;
    signal no_header : boolean;

    signal load_valid : boolean;
    signal load_data  : data_t;
    signal load_ready : boolean;

    signal ppu_en : boolean;

    signal cart_mem_bus   : cart_mem_bus_t := CART_MEM_BUS_IDLE;
    signal cart_mem_wdata : data_t := (others => '-');
    signal cart_mem_data  : data_t;
    signal ref_bus        : file_bus_t := FILE_BUS_IDLE;
    signal ref_data       : data_t;

    -- The RAM window is small so that most reads of it are of an address
    -- that has been written. It is at the start of the upper half of the
    -- cartridge memory bus, where the cartridge RAMs are
    constant RAM_BYTES : positive := 256;

    type ram_t is array(0 to RAM_BYTES - 1) of data_t;
    type ram_valid_t is array(0 to RAM_BYTES - 1) of boolean;

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
    generic map
    (
        REQUIRE_INES => REQUIRE_INES
    )
    port map
    (
        clk => clk_50,
        reset => false,

        loading => loading,
        no_header => no_header,

        load_valid => load_valid,
        load_data => load_data,
        load_ready => load_ready,

        ppu_clk_en => ppu_en,
        cart_mem_bus => cart_mem_bus,
        data_to_cart_mem => cart_mem_wdata,
        data_from_cart_mem => cart_mem_data,

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

            stop => not loading or no_header,
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

            stop => not loading or no_header,
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
        wait until not loading or no_header;
        if no_header
        then
            assert EXPECT_NO_HEADER
                report "No iNES header found at " & time'image(now)
                severity failure;
            -- The load must stay stopped
            wait for 1 ms;
            assert loading and no_header
                report "Load continued after no iNES header was found"
                severity failure;
            report "PASS: stopped at a stream without an iNES header at " &
                   time'image(now - 1 ms);
            std.env.finish;
        end if;
        assert not EXPECT_NO_HEADER
            report "Loaded a stream without an iNES header"
            severity failure;
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
        file_bus_1 => ref_bus,
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

    -- Like the NES core, change the cartridge memory bus right after each PPU
    -- clock enable and consume the data at the next one
    process(clk_50)
        variable seed1     : positive := 1;
        variable seed2     : positive := 2;
        variable rand      : real;
        variable rom_addr  : unsigned(cart_mem_addr_t'range);
        variable ram_idx   : natural range 0 to RAM_BYTES - 1 := 0;
        variable ram       : ram_t;
        variable ram_valid : ram_valid_t := (others => false);
        variable expected  : data_t;
        variable check     : boolean;
        variable windows   : natural := 0;
        variable reads     : natural := 0;
        variable writes    : natural := 0;
        variable errors    : natural := 0;
    begin
    if rising_edge(clk_50) and ppu_en
    then
        check := false;
        if is_bus_read(ref_bus)
        then
            check := true;
            expected := ref_data;
        elsif is_bus_read(cart_mem_bus) and ram_valid(ram_idx)
        then
            check := true;
            expected := ram(ram_idx);
        elsif is_bus_write(cart_mem_bus)
        then
            writes := writes + 1;
            ram(ram_idx) := cart_mem_wdata;
            ram_valid(ram_idx) := true;
        end if;

        if check
        then
            reads := reads + 1;
            if cart_mem_data /= expected
            then
                errors := errors + 1;
                report "Mismatch at " &
                       integer'image(
                           to_integer(cart_mem_bus.address)) &
                       ": expected " & to_hstring(expected) &
                       " got " & to_hstring(cart_mem_data)
                    severity error;
            end if;
        end if;

        windows := windows + 1;
        if windows = NUM_WINDOWS
        then
            assert errors = 0
                report integer'image(errors) & " read errors"
                severity failure;
            report "PASS: " & integer'image(reads) & " reads and " &
                   integer'image(writes) & " writes in " &
                   integer'image(windows) & " PPU cycles";
            std.env.finish;
        end if;

        cart_mem_bus <= CART_MEM_BUS_IDLE;
        cart_mem_wdata <= (others => '-');
        ref_bus <= FILE_BUS_IDLE;

        uniform(seed1, seed2, rand);
        if rand < 0.45
        then
            uniform(seed1, seed2, rand);
            rom_addr := to_unsigned(integer(floor(rand * real(NES_FILE_BYTES))),
                                    cart_mem_addr_t'length);
            cart_mem_bus <= bus_read(rom_addr);
            ref_bus <= bus_read(rom_addr(file_addr_t'range));
        elsif rand < 0.75
        then
            uniform(seed1, seed2, rand);
            ram_idx := integer(floor(rand * real(RAM_BYTES)));
            uniform(seed1, seed2, rand);
            if rand < 0.5
            then
                cart_mem_bus <= bus_write(to_unsigned(
                    CART_RAM_BASE + ram_idx, cart_mem_addr_t'length));
                uniform(seed1, seed2, rand);
                cart_mem_wdata <= to_std_logic_vector(
                    integer(floor(rand * 256.0)), data_t'length);
            else
                cart_mem_bus <= bus_read(to_unsigned(
                    CART_RAM_BASE + ram_idx, cart_mem_addr_t'length));
            end if;
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
