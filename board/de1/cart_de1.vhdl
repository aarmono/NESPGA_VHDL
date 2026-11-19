library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.perhipherals.all;
use work.perhipheral_types.all;
use work.cart_mem_bus_types.all;
use work.cart_connector_types.all;
use work.cart_types.all;
use work.cart_pin_types.all;
use work.cart.all;
use work.de1_types.all;

-- The emulated cartridge on a DE1 of its own, for the cartridge slot of a
-- real console (or of nes_de1 with ROM_CART_SLOT): cart_edge turns the pins of
-- the cartridge connector into what cart_system runs on, and the ROM file
-- is loaded from the SD card into the SRAM, which serves the cartridge's
-- accesses as the console makes them (see sram_rom). On the DE1 the ROM
-- file is at most 256 KB.
--
-- A console doesn't wait for its cartridge, and the connector has no reset.
-- The ROM file takes far longer to load than the console's own reset, and
-- the cartridge's RAMs are filled on the CPU cycles the console's M2 gives
-- after that. Until READY the console is answered by cart_boot_stub, which
-- keeps its CPU in a loop and then starts the game as from reset. That
-- needs the FPGA to be configured before the console's reset ends: if it
-- isn't, the console must be reset once it is.
--
-- With USE_SD_MENU the card holds a FAT filesystem and the SD menu chooses
-- the ROM file, as with nes_de1's ROM_SD_MENU (see sd_menu). The cartridge
-- can't reset the console, so what holds the NES in reset there is the boot
-- stub here: it answers the console again from a launch, or the return to
-- the menu, until the next ROM file is ready, which then starts in a console
-- that has not been reset. The buttons that return to the menu are read off
-- the CPU's buses (see cart_joy_snoop), and the menu's Famicom option does
-- nothing, since it is the console's.
entity cart_de1 is
generic
(
    POWER_UP_MODE : power_up_mode_t := POWER_UP_RANDOM;
    -- See sram_rom. The DE1's SRAM has 18 address bits
    SRAM_ADDR_BITS   : positive := 18;
    -- The card holds a filesystem, and the SD menu loads ROM files from it
    USE_SD_MENU      : boolean := false;
    -- How long Start and Select are held to return to the SD menu. See
    -- sd_menu
    RETURN_HOLD_MS   : positive := 2000
);
port
(
    CLOCK_50 : in std_logic;
    RESET_N  : in std_logic;

    -- The cartridge has loaded its ROM file and filled its RAMs
    READY     : out std_logic;
    -- The ROM file is being loaded
    LOADING   : out std_logic;
    -- The SD card couldn't be read, the ROM file is too large, or the SD
    -- menu couldn't launch a file
    LOAD_FAILED : out std_logic;

    SRAM_ADDR : out std_logic_vector(SRAM_ADDR_BITS - 1 downto 0);
    SRAM_DQ   : inout std_logic_vector(15 downto 0);
    SRAM_CE_N : out std_logic;
    SRAM_OE_N : out std_logic;
    SRAM_WE_N : out std_logic;
    SRAM_LB_N : out std_logic;
    SRAM_UB_N : out std_logic;

    -- SD card in SPI mode
    SD_DAT  : in std_logic;
    SD_DAT3 : out std_logic;
    SD_CMD  : out std_logic;
    SD_CLK  : out std_logic;

    -- The cartridge connector. See cart_edge. The board level shifts the
    -- pins and makes the data buses: CART_CPU_DATA and CART_PPU_DATA are
    -- the buses as read, and the cartridge drives them where the output
    -- enables of CART_PINS_OUT say
    CART_PINS_IN  : in cart_console_pins_t;
    CART_CPU_DATA : in data_t;
    CART_PPU_DATA : in data_t;
    CART_PINS_OUT : out cart_board_drive_t
);
end cart_de1;

architecture behavioral of cart_de1 is

    -- RESET_N synchronized: asserted asynchronously and released
    -- synchronously
    signal reset_sync : std_logic_vector(1 downto 0) := (others => '0');
    signal reset_50   : boolean;
    signal cart_reset : boolean;

    signal cpu_en   : boolean;
    signal ppu_en   : boolean;
    signal clk_sync : boolean;
    signal ram_en   : boolean;

    signal cpu_in  : cart_cpu_in_t;
    signal cpu_out : cart_cpu_out_t;
    signal ppu_in  : cart_ppu_in_t;
    signal ppu_out : cart_ppu_out_t;

    -- What the cartridge answers, which the console gets after the SD menu
    -- and the stub
    signal cart_cpu_out  : cart_cpu_out_t;
    signal cart_ppu_out  : cart_ppu_out_t;
    signal board_cpu_out : cart_cpu_out_t;
    signal menu_cpu_out  : cart_cpu_out_t;

    signal cart_loaded : boolean;
    signal cart_ready  : boolean;
    signal stub_ready  : boolean;

    signal power_up_ready : boolean;
    signal power_up_data  : cart_power_up_data_t;
    signal power_up_step  : boolean;

    -- The PRG channel as the cartridge asks, and as the SRAM sees it
    signal cart_prg_mem_bus  : cart_mem_bus_t;
    signal prg_mem_bus       : cart_mem_bus_t;
    signal data_to_prg_mem   : data_t;
    signal data_from_prg_mem : data_t;
    signal chr_mem_bus       : cart_mem_bus_t;
    signal data_to_chr_mem   : data_t;
    signal data_from_chr_mem : data_t;

    signal rom_loading   : boolean;
    signal rom_too_large : boolean;
    signal rom_no_header : boolean;
    signal rom_refused   : boolean;
    signal rom_restart   : boolean;
    signal sd_error      : boolean;
    signal launch_error  : boolean;
    signal keep_prg_ram  : boolean;

    signal load_valid : boolean;
    signal load_data  : data_t;
    signal load_ready : boolean;

begin

    process(CLOCK_50, RESET_N)
    begin
    if RESET_N = '0'
    then
        reset_sync <= (others => '1');
    elsif rising_edge(CLOCK_50)
    then
        reset_sync <= reset_sync(0) & '0';
    end if;
    end process;

    reset_50 <= reset_sync(1) = '1';
    cart_reset <= reset_50 or rom_loading;

    READY <= to_std_logic(cart_ready);
    LOADING <= to_std_logic(rom_loading);
    LOAD_FAILED <= to_std_logic(sd_error or rom_too_large or launch_error);

    -- The stub answers from the clock after a restart, which is within the
    -- CPU cycle after the write that launched
    stub_ready <= cart_ready and not rom_loading;

    -- A file that doesn't fit is refused like one with no header
    rom_refused <= rom_no_header or rom_too_large;

    menu_cpu_out <= merge_cart_cpu_out(cart_cpu_out, board_cpu_out);

    edge : cart_edge
    generic map
    (
        -- A dot of the console is about 186 ns: 9 clocks of CLOCK_50
        DOT_CLOCKS => 9
    )
    port map
    (
        clk => CLOCK_50,
        reset => reset_50,

        pins_in => CART_PINS_IN,
        cpu_data_bus => CART_CPU_DATA,
        ppu_data_bus => CART_PPU_DATA,
        pins_out => CART_PINS_OUT,

        cpu_en => cpu_en,
        ppu_en => ppu_en,
        clk_sync => clk_sync,
        ram_en => ram_en,

        cpu_in => cpu_in,
        cpu_out => cpu_out,
        ppu_in => ppu_in,
        ppu_out => ppu_out
    );

    stub : cart_boot_stub
    port map
    (
        clk => CLOCK_50,
        reset => reset_50,

        cpu_en => cpu_en,
        ready => stub_ready,
        active => open,

        cpu_in => cpu_in,
        ppu_in => ppu_in,

        cart_cpu_out => menu_cpu_out,
        cart_ppu_out => cart_ppu_out,

        cpu_out => cpu_out,
        ppu_out => ppu_out
    );

    -- The cartridge has the power up fill to itself. Its data steps on the
    -- CPU cycles of the fill, which starts once the header is loaded
    fill : power_up_fill
    generic map
    (
        MODE => POWER_UP_MODE,
        DATA_BITS => cart_power_up_data_t'length
    )
    port map
    (
        clk => CLOCK_50,
        enable => cart_reset,
        step => power_up_step,
        ready => power_up_ready,
        data => power_up_data
    );

    power_up_step <= cpu_en and cart_loaded and not cart_ready;

    cart_sys : cart_system_ocram
    generic map
    (
        CART_MEM => CART_MEM_SPLIT
    )
    port map
    (
        clk => CLOCK_50,
        reset => cart_reset,

        cpu_en => cpu_en,
        ppu_en => ppu_en,
        clk_sync => clk_sync,
        ram_en => ram_en,

        keep_prg_ram => keep_prg_ram,

        power_up_ready => power_up_ready,
        power_up_data => power_up_data,

        loaded => cart_loaded,
        ready => cart_ready,

        cpu_in => cpu_in,
        cpu_out => cart_cpu_out,
        ppu_in => ppu_in,
        ppu_out => cart_ppu_out,
        audio => open,

        cart_mem_bus => open,
        data_to_cart_mem => open,

        prg_mem_bus => cart_prg_mem_bus,
        data_to_prg_mem => data_to_prg_mem,
        data_from_prg_mem => data_from_prg_mem,

        chr_mem_bus => chr_mem_bus,
        data_to_chr_mem => data_to_chr_mem,
        data_from_chr_mem => data_from_chr_mem
    );

    rom : sram_rom
    generic map
    (
        ADDR_BITS => SRAM_ADDR_BITS,
        REQUIRE_INES => USE_SD_MENU
    )
    port map
    (
        clk => CLOCK_50,
        reset => reset_50,

        restart => rom_restart,

        loading => rom_loading,
        too_large => rom_too_large,
        no_header => rom_no_header,

        load_valid => load_valid,
        load_data => load_data,
        load_ready => load_ready,

        prg_mem_bus => prg_mem_bus,
        data_to_prg_mem => data_to_prg_mem,
        data_from_prg_mem => data_from_prg_mem,

        chr_mem_bus => chr_mem_bus,
        data_to_chr_mem => data_to_chr_mem,
        data_from_chr_mem => data_from_chr_mem,

        sram_addr => SRAM_ADDR,
        sram_dq => SRAM_DQ,
        sram_ce_n => SRAM_CE_N,
        sram_oe_n => SRAM_OE_N,
        sram_we_n => SRAM_WE_N,
        sram_lb_n => SRAM_LB_N,
        sram_ub_n => SRAM_UB_N
    );

    gen_sd_menu : if USE_SD_MENU generate
        signal buttons : std_logic_vector(7 downto 0);
    begin
        joy : cart_joy_snoop
        port map
        (
            clk => CLOCK_50,
            reset => reset_50,

            cpu_en => cpu_en,
            cpu_in => cpu_in,

            buttons => buttons
        );

        sd : entity work.sd_menu(behavioral)
        generic map
        (
            RETURN_HOLD_MS => RETURN_HOLD_MS
        )
        port map
        (
            clk => CLOCK_50,
            reset => reset_50,

            cpu_clk_en => cpu_en,
            board_cpu_in => cpu_in,
            board_cpu_out => board_cpu_out,

            buttons => buttons,

            keep_prg_ram => keep_prg_ram,
            famicom => open,

            cart_mem_bus_in => cart_prg_mem_bus,
            cart_mem_bus_out => prg_mem_bus,

            rom_loading => rom_loading,
            rom_no_header => rom_refused,
            rom_restart => rom_restart,

            load_valid => load_valid,
            load_data => load_data,
            load_ready => load_ready,

            sd_failed => sd_error,
            launch_failed => launch_error,

            sd_clk => SD_CLK,
            sd_cs_n => SD_DAT3,
            sd_mosi => SD_CMD,
            sd_miso => SD_DAT
        );
    end generate;

    -- Without the menu, the ROM file at the start of the card is loaded
    -- once
    gen_no_menu : if not USE_SD_MENU generate
    begin
        rom_restart <= false;
        launch_error <= false;
        keep_prg_ram <= false;
        board_cpu_out <= CART_CPU_OUT_IDLE;
        prg_mem_bus <= cart_prg_mem_bus;

        sd : entity work.sd_reader(behavioral)
        port map
        (
            clk => CLOCK_50,
            reset => reset_50,

            failed => sd_error,

            req_ready => open,

            stop => not rom_loading,
            data => load_data,
            offset => open,
            valid => load_valid,
            ready => load_ready,

            sd_clk => SD_CLK,
            sd_cs_n => SD_DAT3,
            sd_mosi => SD_CMD,
            sd_miso => SD_DAT
        );
    end generate;

end behavioral;
