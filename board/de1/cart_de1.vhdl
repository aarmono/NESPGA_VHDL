library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.perhipherals.all;
use work.perhipheral_types.all;
use work.cart_mem_bus_types.all;
use work.cart_connector_types.all;
use work.cart_pin_types.all;
use work.cart.all;

-- The emulated cartridge on a DE1 of its own, for the cartridge slot of a
-- real console (or of nes_de1 with USE_CART_SLOT): cart_edge turns the pins of
-- the cartridge connector into what cart_system runs on, and the ROM file
-- is loaded from the SD card into SDRAM, as nes_de1 does it.
--
-- A console doesn't wait for its cartridge, and the connector has no reset.
-- The ROM file takes far longer to load than the console's own reset, and
-- the cartridge's RAMs are filled on the CPU cycles the console's M2 gives
-- after that. Until READY the cartridge answers nothing, so the console
-- must be held in reset, or reset again, once it is.
entity cart_de1 is
generic
(
    POWER_UP_MODE : power_up_mode_t := POWER_UP_RANDOM;
    -- See power_up_fill
    POWER_UP_SEED : natural := 0;
    -- The nominal clocks in a dot of the console. See cart_edge
    DOT_CLOCKS    : positive := 9;
    -- See sdram_rom
    ROM_START_DELAY : positive := 2
);
port
(
    CLOCK_50 : in std_logic;
    CLOCK_WE : in std_logic;
    RESET_N  : in std_logic;

    -- The cartridge has loaded its ROM file and filled its RAMs
    READY     : out std_logic;
    -- The ROM file is being loaded
    LOADING   : out std_logic;
    -- The SD card couldn't be read
    SD_FAILED : out std_logic;

    DRAM_ADDR  : out std_logic_vector(11 downto 0);
    DRAM_BA_0  : out std_logic;
    DRAM_BA_1  : out std_logic;
    DRAM_CAS_N : out std_logic;
    DRAM_CKE   : out std_logic;
    DRAM_CLK   : out std_logic;
    DRAM_CS_N  : out std_logic;
    DRAM_DQ    : inout std_logic_vector(15 downto 0);
    DRAM_LDQM  : out std_logic;
    DRAM_UDQM  : out std_logic;
    DRAM_RAS_N : out std_logic;
    DRAM_WE_N  : out std_logic;

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

    signal cart_loaded : boolean;
    signal cart_ready  : boolean;

    signal power_up_ready : boolean;
    signal power_up_data  : cart_power_up_data_t;
    signal power_up_step  : boolean;

    signal cart_mem_bus       : cart_mem_bus_t;
    signal data_to_cart_mem   : data_t;
    signal data_from_cart_mem : data_t;

    signal dram_ba : std_logic_vector(1 downto 0);

    signal rom_loading : boolean;
    signal sd_error    : boolean;

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
    SD_FAILED <= to_std_logic(sd_error);

    DRAM_BA_0 <= dram_ba(0);
    DRAM_BA_1 <= dram_ba(1);

    -- CLOCK_WE leads CLOCK_50 by about 2 ns, which compensates for the
    -- clock output delay to the SDRAM
    DRAM_CLK <= CLOCK_WE;

    edge : cart_edge
    generic map
    (
        DOT_CLOCKS => DOT_CLOCKS
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

    -- The cartridge has the power up fill to itself. Its data steps on the
    -- CPU cycles of the fill, which starts once the header is loaded
    fill : power_up_fill
    generic map
    (
        MODE => POWER_UP_MODE,
        DATA_BITS => cart_power_up_data_t'length,
        SEED => POWER_UP_SEED
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
        USE_EXT_CART_RAM => true
    )
    port map
    (
        clk => CLOCK_50,
        reset => cart_reset,

        cpu_en => cpu_en,
        ppu_en => ppu_en,
        clk_sync => clk_sync,
        ram_en => ram_en,

        power_up_ready => power_up_ready,
        power_up_data => power_up_data,

        loaded => cart_loaded,
        ready => cart_ready,

        cpu_in => cpu_in,
        cpu_out => cpu_out,
        ppu_in => ppu_in,
        ppu_out => ppu_out,
        audio => open,

        cart_mem_bus => cart_mem_bus,
        data_to_cart_mem => data_to_cart_mem,
        data_from_cart_mem => data_from_cart_mem
    );

    rom : entity work.sdram_rom(behavioral)
    generic map
    (
        START_DELAY => ROM_START_DELAY
    )
    port map
    (
        clk => CLOCK_50,
        reset => reset_50,

        loading => rom_loading,
        no_header => open,

        load_valid => load_valid,
        load_data => load_data,
        load_ready => load_ready,

        ppu_clk_en => ppu_en,
        cart_mem_bus => cart_mem_bus,
        data_to_cart_mem => data_to_cart_mem,
        data_from_cart_mem => data_from_cart_mem,

        dram_addr => DRAM_ADDR,
        dram_ba => dram_ba,
        dram_cs_n => DRAM_CS_N,
        dram_ras_n => DRAM_RAS_N,
        dram_cas_n => DRAM_CAS_N,
        dram_we_n => DRAM_WE_N,
        dram_cke => DRAM_CKE,
        dram_ldqm => DRAM_LDQM,
        dram_udqm => DRAM_UDQM,
        dram_dq => DRAM_DQ
    );

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

end behavioral;
