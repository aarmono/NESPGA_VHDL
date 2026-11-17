library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.cart_mem_bus_types.all;
use work.perhipheral_types.all;
use work.cart_connector_types.all;
use work.cart_types.all;
use work.console.all;
use work.cart.all;

-- The NES, joining the console and the cartridge with their RAMs on chip.
-- See nes_console_ocram and cart_system_ocram
entity nes_soc_ocram is
generic
(
    -- See cart_system_ocram
    USE_EXT_CART_RAM : boolean := false;
    -- Vendor of the on-chip RAMs. See syncram_sp
    VENDOR           : vendor_t := VENDOR_ALTERA;
    -- See clk_en
    CLK_FREQ         : positive := 50_000_000;
    CPU_FREQ_NUM     : positive := 39_375_000;
    CPU_FREQ_DEN     : positive := 22;
    -- See cart_system
    CART_BOARDS      : board_set_t := ALL_BOARDS;
    -- See nes_console
    POWER_UP_MODE    : power_up_mode_t := POWER_UP_ZERO;
    -- See nes_console
    POWER_UP_SEED    : natural := 0;
    -- See clk_en
    INVERT_CYCLE_PARITY : boolean := false
);
port
(
    clk   : in std_logic;
    reset : in boolean;
    -- See nes_console
    soft_reset   : in boolean := false;
    -- See cart_system
    keep_prg_ram : in boolean := false;
    -- See nes_console
    famicom      : in boolean := false;

    nes_running : out boolean;

    -- See nes_console
    stretch        : in boolean := false;
    run            : in boolean := true;
    waiting_to_run : out boolean;
    ppu_start      : out ppu_position_t;

    cpu_clk_en : out boolean;
    ppu_clk_en : out boolean;
    
    cart_mem_bus       : out cart_mem_bus_t;
    data_to_cart_mem   : out data_t;
    data_from_cart_mem : in data_t;

    pixel_bus : out pixel_bus_t;
    audio     : out mixed_audio_t;

    joy_strobe : out std_logic;

    joy_1_clk  : out std_logic;
    joy_1_data : in joy_data_t := JOY_DATA_IDLE;

    joy_2_clk  : out std_logic;
    joy_2_data : in joy_data_t := JOY_DATA_IDLE;

    -- The CPU side of the cartridge connector, as the cartridge sees it, for
    -- the board to decode too. Like the CPU bus, it is only valid at
    -- cpu_clk_en
    board_cpu_in  : out cart_cpu_in_t;
    -- The board's side of the same connector. When it drives the data bus it
    -- answers the read instead of the cartridge. Its IRQ is ORed with the
    -- cartridge's, as /IRQ is shared
    board_cpu_out : in cart_cpu_out_t := CART_CPU_OUT_IDLE;
    -- The PPU side of the cartridge connector, as the cartridge sees it.
    -- Only valid at ppu_clk_en. For nes_bench to check its timing
    board_ppu_in  : out cart_ppu_in_t
);
end nes_soc_ocram;

architecture behavioral of nes_soc_ocram is

    signal sig_cpu_clk_en : boolean;
    signal sig_ppu_clk_en : boolean;
    signal clk_sync       : boolean;
    signal ppu_ram_en     : boolean;

    signal cart_cpu_in     : cart_cpu_in_t;
    signal cart_cpu_out    : cart_cpu_out_t;
    signal console_cpu_out : cart_cpu_out_t;
    signal cart_ppu_in     : cart_ppu_in_t;
    signal cart_ppu_out    : cart_ppu_out_t;
    signal cart_audio      : cart_audio_t;

    signal console_run     : boolean;
    signal console_waiting : boolean;

    signal cart_loaded    : boolean;
    signal cart_ready     : boolean;
    signal power_up_ready : boolean;
    signal power_up_data  : power_up_data_t;

begin

    cpu_clk_en <= sig_cpu_clk_en;
    ppu_clk_en <= sig_ppu_clk_en;

    -- The NES leaves reset once both have filled their RAMs. The cartridge
    -- can take longer, and the board isn't told the NES is waiting for it
    -- until then
    console_run <= run and cart_ready;
    waiting_to_run <= console_waiting and cart_ready;

    console_sys : nes_console_ocram
    generic map
    (
        VENDOR => VENDOR,
        CLK_FREQ => CLK_FREQ,
        CPU_FREQ_NUM => CPU_FREQ_NUM,
        CPU_FREQ_DEN => CPU_FREQ_DEN,
        POWER_UP_MODE => POWER_UP_MODE,
        POWER_UP_SEED => POWER_UP_SEED,
        INVERT_CYCLE_PARITY => INVERT_CYCLE_PARITY
    )
    port map
    (
        clk => clk,
        reset => reset,
        soft_reset => soft_reset,
        famicom => famicom,

        nes_running => nes_running,

        stretch => stretch,
        run => console_run,
        waiting_to_run => console_waiting,
        ppu_start => ppu_start,

        cpu_clk_en => sig_cpu_clk_en,
        ppu_clk_en => sig_ppu_clk_en,
        clk_sync => clk_sync,
        ppu_ram_en => ppu_ram_en,

        pixel_bus => pixel_bus,
        audio => audio,

        joy_strobe => joy_strobe,

        joy_1_clk => joy_1_clk,
        joy_1_data => joy_1_data,

        joy_2_clk => joy_2_clk,
        joy_2_data => joy_2_data,

        cart_cpu_in => cart_cpu_in,
        cart_cpu_out => console_cpu_out,
        cart_ppu_in => cart_ppu_in,
        cart_ppu_out => cart_ppu_out,
        cart_audio => cart_audio,

        -- The console starts its fill once the cartridge has loaded its
        -- header, which is when the cartridge starts its own
        power_up_start => cart_loaded,

        power_up_ready => power_up_ready,
        power_up_data => power_up_data
    );

    cart_sys : cart_system_ocram
    generic map
    (
        USE_EXT_CART_RAM => USE_EXT_CART_RAM,
        VENDOR => VENDOR,
        CART_BOARDS => CART_BOARDS
    )
    port map
    (
        clk => clk,
        reset => reset,

        cpu_en => sig_cpu_clk_en,
        ppu_en => sig_ppu_clk_en,
        clk_sync => clk_sync,
        ram_en => ppu_ram_en,

        keep_prg_ram => keep_prg_ram,

        power_up_ready => power_up_ready,
        power_up_data => power_up_data,

        loaded => cart_loaded,
        ready => cart_ready,

        cpu_in => cart_cpu_in,
        cpu_out => cart_cpu_out,
        ppu_in => cart_ppu_in,
        ppu_out => cart_ppu_out,
        audio => cart_audio,

        cart_mem_bus => cart_mem_bus,
        data_to_cart_mem => data_to_cart_mem,
        data_from_cart_mem => data_from_cart_mem
    );

    board_cpu_in <= cart_cpu_in;
    board_ppu_in <= cart_ppu_in;

    console_cpu_out <= merge_cart_cpu_out(cart_cpu_out, board_cpu_out);

end behavioral;
