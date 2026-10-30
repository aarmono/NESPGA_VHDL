library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.cart_types.all;
use work.cart_mem_bus_types.all;
use work.perhipheral_types.all;
use work.binary_io.all;
use work.simulation.all;

-- Runs sd_menu and sdram_rom on an SD card model, with this process in the
-- place of the CPU, paced by the real NES clock enables.
--
-- With a card holding a filesystem (see simulation/sd_card/fat_image.py),
-- the loader must enter menu mode. Blocks are then read through the
-- registers and checked against the image, the extent table is written to
-- the buffer and read back, and the file is launched. Once it is loaded,
-- random reads of the cartridge memory bus are checked against ROM_FILEPATH,
-- and the registers must be gone. With DROP_LAST_EXTENT, the launch must
-- fail instead.
--
-- With RAW, the card holds an iNES file from block 0, which must be loaded
-- without menu mode.
entity sd_menu_bench is
generic
(
    IMAGE_FILEPATH   : string;
    IMAGE_BYTES      : positive;
    ROM_FILEPATH     : string;
    ROM_BYTES        : positive;
    EXTENTS_FILEPATH : string := "";

    RAW              : boolean := false;
    DROP_LAST_EXTENT : boolean := false;
    NUM_READS        : positive := 50_000;

    SD_HIGH_CAPACITY : boolean := true
);
end sd_menu_bench;

architecture behavioral of sd_menu_bench is

    constant BLOCK_BYTES : positive := 512;

    type bytes_t is array(natural range <>) of data_t;
    type bytes_ptr_t is access bytes_t;

    signal clk_50   : std_logic;
    signal clk_dram : std_logic;

    signal cpu_en : boolean;
    signal ppu_en : boolean;

    -- This process stands in for the menu, which runs on the NES
    signal in_menu   : boolean := false;
    -- Like nes_de1, the NES is held in reset while a file is loaded, so its
    -- clock enables do not start SDRAM slots during the load
    signal nes_reset : boolean;

    signal board_cpu_in  : cart_cpu_in_t :=
    (
        prg_bus => (address => (others => '0'), read => false, write => false),
        romsel => false,
        data => (others => '0')
    );
    signal board_cpu_out : cart_cpu_out_t;

    signal loading     : boolean;
    signal no_header   : boolean;
    signal rom_restart : boolean;

    signal load_valid : boolean;
    signal load_data  : data_t;
    signal load_ready : boolean;

    signal sd_failed     : boolean;
    signal launch_failed : boolean;

    signal cart_mem_bus  : cart_mem_bus_t := CART_MEM_BUS_IDLE;
    signal cart_mem_data : data_t;

    signal sd_clk  : std_logic;
    signal sd_cs_n : std_logic;
    signal sd_mosi : std_logic;
    signal sd_miso : std_logic;

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

    impure function read_file(path : string; size : natural)
    return bytes_ptr_t
    is
        file f : byte_file_t;
        variable ret : bytes_ptr_t := new bytes_t(0 to size - 1);
    begin
        byte_fopen(f, path, read_mode);
        for i in ret'range
        loop
            if byte_feof(f)
            then
                ret(i) := x"00";
            else
                ret(i) := byte_fread(f);
            end if;
        end loop;
        byte_fclose(f);
        return ret;
    end;

    function cpu_access(addr : natural; write : boolean; data : data_t)
    return cart_cpu_in_t
    is
        variable ret : cart_cpu_in_t;
    begin
        ret.prg_bus.address := to_std_logic_vector(addr mod 2**15, 15);
        ret.prg_bus.read := not write;
        ret.prg_bus.write := write;
        ret.romsel := addr >= 16#8000#;
        ret.data := data;
        return ret;
    end;

begin

    dut : entity work.sd_menu(behavioral)
    generic map
    (
        VENDOR => VENDOR_SIM
    )
    port map
    (
        clk => clk_50,
        reset => false,

        cpu_clk_en => cpu_en,
        board_cpu_in => board_cpu_in,
        board_cpu_out => board_cpu_out,

        rom_loading => loading,
        rom_no_header => no_header,
        rom_restart => rom_restart,

        load_valid => load_valid,
        load_data => load_data,
        load_ready => load_ready,

        sd_failed => sd_failed,
        launch_failed => launch_failed,

        sd_clk => sd_clk,
        sd_cs_n => sd_cs_n,
        sd_mosi => sd_mosi,
        sd_miso => sd_miso
    );

    rom : entity work.sdram_rom(behavioral)
    generic map
    (
        REQUIRE_INES => true
    )
    port map
    (
        clk => clk_50,
        reset => false,

        restart => rom_restart,

        loading => loading,
        no_header => no_header,

        load_valid => load_valid,
        load_data => load_data,
        load_ready => load_ready,

        ppu_clk_en => ppu_en,
        cart_mem_bus => cart_mem_bus,
        data_to_cart_mem => (others => '-'),
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

    card : entity work.sd_card(behavioral)
    generic map
    (
        FILEPATH => IMAGE_FILEPATH,
        FILE_BYTES => IMAGE_BYTES,
        HIGH_CAPACITY => SD_HIGH_CAPACITY
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

    assert not sd_failed
        report "SD card error"
        severity failure;

    nes_reset <= loading and not in_menu;

    nes_clk_en : entity work.clk_en(behavioral)
    port map
    (
        clk => clk_50,
        reset => nes_reset,

        cpu_en => cpu_en,
        ppu_en => ppu_en,
        nsf_en => open,

        cpu_ram_en => open,
        ppu_ram_en => open,

        ppu_sync => open,
        odd_cpu_cycle => open
    );

    process
        variable image   : bytes_ptr_t;
        variable rom_file : bytes_ptr_t;
        variable extents : bytes_ptr_t;
        variable data    : data_t;
        variable oe      : boolean;
        variable errors  : natural := 0;
        variable last    : natural;
        variable first   : natural;
        variable seed1   : positive := 1;
        variable seed2   : positive := 2;
        variable rand    : real;
        variable addr    : natural;
        variable expected : data_t;

        -- One CPU cycle. The bus changes after a CPU clock enable and is
        -- taken at the next, like the bus of the NES
        procedure cpu_cycle(a : natural; write : boolean; wdata : data_t)
        is
        begin
            board_cpu_in <= cpu_access(a, write, wdata);
            wait until rising_edge(clk_50) and cpu_en;
            oe := board_cpu_out.data_oe;
            data := board_cpu_out.data;
            assert board_cpu_out.data_float = x"00" and not board_cpu_out.irq
                report "Board floated data bits or raised IRQ"
                severity failure;
            board_cpu_in.prg_bus.read <= false;
            board_cpu_in.prg_bus.write <= false;
            board_cpu_in.romsel <= false;
        end;

        procedure cpu_read(a : natural)
        is
        begin
            cpu_cycle(a, false, x"00");
        end;

        procedure cpu_write(a : natural; wdata : data_t)
        is
        begin
            cpu_cycle(a, true, wdata);
            assert not oe
                report "Board drove the data bus during a write"
                severity failure;
        end;

        procedure wait_ready
        is
        begin
            loop
                cpu_read(16#5200#);
                assert oe
                    report "Status not readable in menu mode"
                    severity failure;
                assert data(6) = '0'
                    report "Status shows a card failure"
                    severity failure;
                exit when data(7) = '0';
            end loop;
        end;

        procedure read_block(blk : natural)
        is
            variable v_blk : std_logic_vector(31 downto 0);
        begin
            v_blk := to_std_logic_vector(blk, 32);
            for i in 0 to 3
            loop
                cpu_write(16#5200#, v_blk(8 * i + 7 downto 8 * i));
            end loop;
            cpu_write(16#5204#, x"00");
            cpu_read(16#5200#);
            assert data(7) = '1'
                report "Status not busy after a read command"
                severity failure;
            wait_ready;

            for i in 0 to BLOCK_BYTES - 1
            loop
                -- Use a mirror for the second half
                cpu_read(16#5000# + i + (i / 256) * 16#0400#);
                assert oe
                    report "Buffer not readable in menu mode"
                    severity failure;
                if data /= image(blk * BLOCK_BYTES + i)
                then
                    errors := errors + 1;
                    report "Block " & integer'image(blk) & " byte " &
                           integer'image(i) & ": expected " &
                           to_hstring(image(blk * BLOCK_BYTES + i)) &
                           " got " & to_hstring(data)
                        severity error;
                end if;
            end loop;
            report "Read block " & integer'image(blk) & " at " &
                   time'image(now);
        end;

    begin
        image := read_file(IMAGE_FILEPATH, IMAGE_BYTES);
        rom_file := read_file(ROM_FILEPATH, ROM_BYTES);

        if RAW
        then
            wait until not loading or no_header;
            assert not no_header
                report "No iNES header on a raw card"
                severity failure;
            report "Raw file loaded at " & time'image(now);
        else
            wait until no_header;
            report "No iNES header at " & time'image(now);
            in_menu <= true;
            wait until rising_edge(clk_50) and cpu_en;

            -- Menu mode starts once the reader has finished the block
            loop
                cpu_read(16#5204#);
                exit when oe;
            end loop;
            report "Menu mode at " & time'image(now);

            -- The NES's own addresses are left alone
            cpu_read(16#4020#);
            assert not oe report "Board drove 0x4020" severity failure;
            cpu_read(16#6000#);
            assert not oe report "Board drove 0x6000" severity failure;
            cpu_read(16#D000#);
            assert not oe report "Board drove 0xD000" severity failure;

            read_block(0);
            read_block(1);
            read_block(IMAGE_BYTES / BLOCK_BYTES - 1);

            extents := read_file(EXTENTS_FILEPATH, BLOCK_BYTES);
            -- The first block of the file
            first := to_integer(extents(3) & extents(2) &
                                extents(1) & extents(0));
            read_block(first);

            if DROP_LAST_EXTENT
            then
                last := 0;
                while last < 63 and
                      (extents(8 * last + 8 + 4) /= x"00" or
                       extents(8 * last + 8 + 5) /= x"00")
                loop
                    last := last + 1;
                end loop;
                for i in 0 to 7
                loop
                    extents(8 * last + i) := x"00";
                end loop;
            end if;

            for i in 0 to BLOCK_BYTES - 1
            loop
                cpu_write(16#5000# + i, extents(i));
            end loop;
            for i in 0 to BLOCK_BYTES - 1
            loop
                cpu_read(16#5000# + i);
                assert data = extents(i)
                    report "Buffer byte " & integer'image(i) &
                           " read back " & to_hstring(data) &
                           ", expected " & to_hstring(extents(i))
                    severity failure;
            end loop;

            assert errors = 0
                report integer'image(errors) & " block read errors"
                severity failure;

            cpu_write(16#5205#, x"00");
            in_menu <= false;
            report "Launched at " & time'image(now);

            wait until rising_edge(clk_50);
            wait until rising_edge(clk_50);
            assert loading report "Launch did not restart the load"
                severity failure;

            wait until not loading or launch_failed;
            if DROP_LAST_EXTENT
            then
                assert launch_failed and loading
                    report "Launch without the last extent did not fail"
                    severity failure;
                wait for 100 us;
                assert launch_failed and loading
                    report "Launch failure did not hold"
                    severity failure;
                report "PASS: launch failed when the extents ran out at " &
                       time'image(now - 100 us);
                std.env.finish;
            end if;
            assert not launch_failed
                report "Launch failed"
                severity failure;
            report "File loaded at " & time'image(now);
        end if;

        -- The registers are only there in menu mode
        cpu_read(16#5200#);
        assert not oe report "Registers after loading" severity failure;
        cpu_read(16#5000#);
        assert not oe report "Buffer after loading" severity failure;

        -- Like the NES core, change the cartridge memory bus right after
        -- each PPU clock enable and consume the data at the next one
        for i in 1 to NUM_READS
        loop
            uniform(seed1, seed2, rand);
            addr := integer(floor(rand * real(ROM_BYTES)));
            cart_mem_bus <= bus_read(to_unsigned(addr,
                                                 cart_mem_addr_t'length));
            wait until rising_edge(clk_50) and ppu_en;
            wait until rising_edge(clk_50) and ppu_en;
            expected := rom_file(addr);
            if cart_mem_data /= expected
            then
                errors := errors + 1;
                report "ROM byte " & integer'image(addr) & ": expected " &
                       to_hstring(expected) & " got " &
                       to_hstring(cart_mem_data)
                    severity error;
            end if;
        end loop;

        assert errors = 0
            report integer'image(errors) & " ROM read errors"
            severity failure;
        report "PASS: " & integer'image(NUM_READS) & " ROM reads at " &
               time'image(now);
        std.env.finish;
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
