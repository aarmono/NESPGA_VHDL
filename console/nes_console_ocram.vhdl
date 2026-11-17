library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.ciram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.perhipherals.all;
use work.perhipheral_types.all;
use work.cart_connector_types.all;

-- Variant of nes_console with its RAMs on chip
entity nes_console_ocram is
generic
(
    -- Vendor of the on-chip RAMs. See syncram_sp
    VENDOR       : vendor_t := VENDOR_ALTERA;
    -- See clk_en
    CLK_FREQ     : positive := 50_000_000;
    CPU_FREQ_NUM : positive := 39_375_000;
    CPU_FREQ_DEN : positive := 22;
    -- See nes_console
    POWER_UP_MODE : power_up_mode_t := POWER_UP_ZERO;
    POWER_UP_SEED : natural := 0;
    -- See clk_en
    INVERT_CYCLE_PARITY : boolean := false
);
port
(
    clk   : in std_logic;
    reset : in boolean;
    -- See nes_console
    soft_reset : in boolean := false;
    famicom    : in boolean := false;

    nes_running : out boolean;

    -- See nes_console
    stretch        : in boolean := false;
    run            : in boolean := true;
    waiting_to_run : out boolean;
    ppu_start      : out ppu_position_t;

    cpu_clk_en : out boolean;
    ppu_clk_en : out boolean;
    -- See nes_console
    clk_sync   : out boolean;
    -- The clock enable of the RAMs that are accessed once per PPU cycle, for
    -- the cartridge's on-chip RAMs too
    ppu_ram_en : out boolean;

    pixel_bus : out pixel_bus_t;
    audio     : out mixed_audio_t;

    joy_strobe : out std_logic;

    joy_1_clk  : out std_logic;
    joy_1_data : in joy_data_t := JOY_DATA_IDLE;

    joy_2_clk  : out std_logic;
    joy_2_data : in joy_data_t := JOY_DATA_IDLE;

    -- See nes_console
    cart_cpu_in  : out cart_cpu_in_t;
    cart_cpu_out : in cart_cpu_out_t;
    cpu_data_bus : out data_t;
    cart_ppu_in  : out cart_ppu_in_t;
    cart_ppu_out : in cart_ppu_out_t;
    cart_audio   : in cart_audio_t := 0;

    power_up_start : in boolean := true;

    power_up_ready : out boolean;
    power_up_data  : out power_up_data_t
);
end nes_console_ocram;

architecture behavioral of nes_console_ocram is

    signal sig_cpu_ram_en : boolean;
    signal sig_ppu_ram_en : boolean;

    signal prg_ram_bus : ram_bus_t;
    signal oam_bus     : oam_bus_t;
    signal sec_oam_bus : sec_oam_bus_t;
    signal palette_bus : palette_bus_t;
    signal ciram_bus   : ciram_bus_t;

    signal data_to_prg_ram   : data_t;
    signal data_from_prg_ram : data_t;
    signal data_to_oam       : data_t;
    signal data_from_oam     : data_t;
    signal data_to_sec_oam   : data_t;
    signal data_from_sec_oam : data_t;
    signal data_to_palette   : pixel_t;
    signal data_from_palette : pixel_t;
    signal data_from_ciram   : data_t;
    signal data_to_ciram     : data_t;

begin

    ppu_ram_en <= sig_ppu_ram_en;

    sys : entity work.nes_console(behavioral)
    generic map
    (
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
        run => run,
        waiting_to_run => waiting_to_run,
        ppu_start => ppu_start,

        cpu_clk_en => cpu_clk_en,
        ppu_clk_en => ppu_clk_en,
        clk_sync => clk_sync,

        cpu_ram_en => sig_cpu_ram_en,
        ppu_ram_en => sig_ppu_ram_en,

        prg_ram_bus => prg_ram_bus,
        data_to_prg_ram => data_to_prg_ram,
        data_from_prg_ram => data_from_prg_ram,

        oam_bus => oam_bus,
        data_to_oam => data_to_oam,
        data_from_oam => data_from_oam,

        sec_oam_bus => sec_oam_bus,
        data_to_sec_oam => data_to_sec_oam,
        data_from_sec_oam => data_from_sec_oam,

        palette_bus => palette_bus,
        data_to_palette => data_to_palette,
        data_from_palette => data_from_palette,

        ciram_bus => ciram_bus,
        data_to_ciram => data_to_ciram,
        data_from_ciram => data_from_ciram,

        pixel_bus => pixel_bus,
        audio => audio,

        joy_strobe => joy_strobe,

        joy_1_clk => joy_1_clk,
        joy_1_data => joy_1_data,

        joy_2_clk => joy_2_clk,
        joy_2_data => joy_2_data,

        cart_cpu_in => cart_cpu_in,
        cart_cpu_out => cart_cpu_out,
        cpu_data_bus => cpu_data_bus,
        cart_ppu_in => cart_ppu_in,
        cart_ppu_out => cart_ppu_out,
        cart_audio => cart_audio,

        power_up_start => power_up_start,

        power_up_ready => power_up_ready,
        power_up_data => power_up_data
    );

    prg_ram : syncram_sp
    generic map
    (
        VENDOR => VENDOR,
        ADDR_BITS => ram_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk,
        clk_en => sig_cpu_ram_en,

        address => prg_ram_bus.address,
        read => prg_ram_bus.read,
        write => prg_ram_bus.write,

        data_in => data_to_prg_ram,
        data_out => data_from_prg_ram
    );

    ciram : syncram_sp
    generic map
    (
        VENDOR => VENDOR,
        ADDR_BITS => ciram_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk,
        clk_en => sig_ppu_ram_en,

        address => ciram_bus.address,
        read => ciram_bus.read,
        write => ciram_bus.write,

        data_in => data_to_ciram,
        data_out => data_from_ciram
    );

    oam : syncram_sp
    generic map
    (
        VENDOR => VENDOR,
        ADDR_BITS => oam_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk,
        clk_en => sig_ppu_ram_en,

        address => oam_bus.address,
        read => oam_bus.read,
        write => oam_bus.write,

        data_in => data_to_oam,
        data_out => data_from_oam
    );

    sec_oam : syncram_sp
    generic map
    (
        VENDOR => VENDOR,
        ADDR_BITS => sec_oam_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk,
        clk_en => sig_ppu_ram_en,

        address => sec_oam_bus.address,
        read => sec_oam_bus.read,
        write => sec_oam_bus.write,

        data_in => data_to_sec_oam,
        data_out => data_from_sec_oam
    );

    palette : syncram_sp
    generic map
    (
        VENDOR => VENDOR,
        ADDR_BITS => palette_addr_t'length,
        DATA_BITS => pixel_t'length
    )
    port map
    (
        clk => clk,
        clk_en => sig_ppu_ram_en,

        address => palette_bus.address,
        read => palette_bus.read,
        write => palette_bus.write,

        data_in => data_to_palette,
        data_out => data_from_palette
    );

end behavioral;
