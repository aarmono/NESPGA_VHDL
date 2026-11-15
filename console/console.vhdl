library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.perhipheral_types.all;
use work.ram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.ciram_bus_types.all;
use work.cart_connector_types.all;

-- The components of the console subsystem, for use outside of it
package console is

    -- The console with its RAMs on buses. See nes_console
    component nes_console is
    generic
    (
        CLK_FREQ     : positive := 50_000_000;
        CPU_FREQ_NUM : positive := 39_375_000;
        CPU_FREQ_DEN : positive := 22;
        POWER_UP_MODE : power_up_mode_t := POWER_UP_ZERO;
        POWER_UP_SEED : natural := 0;
        INVERT_CYCLE_PARITY : boolean := false
    );
    port
    (
        clk   : in std_logic;
        reset : in boolean;
        soft_reset : in boolean := false;
        famicom    : in boolean := false;

        nes_running : out boolean;

        stretch        : in boolean := false;
        run            : in boolean := true;
        waiting_to_run : out boolean;
        ppu_start      : out ppu_position_t;

        cpu_clk_en : out boolean;
        ppu_clk_en : out boolean;
        clk_sync   : out boolean;

        cpu_ram_en : out boolean;
        ppu_ram_en : out boolean;

        prg_ram_bus       : out ram_bus_t;
        data_to_prg_ram   : out data_t;
        data_from_prg_ram : in data_t;

        oam_bus       : out oam_bus_t;
        data_to_oam   : out data_t;
        data_from_oam : in data_t;

        sec_oam_bus       : out sec_oam_bus_t;
        data_to_sec_oam   : out data_t;
        data_from_sec_oam : in data_t;

        palette_bus       : out palette_bus_t;
        data_to_palette   : out pixel_t;
        data_from_palette : in pixel_t;

        ciram_bus       : out ciram_bus_t;
        data_to_ciram   : out data_t;
        data_from_ciram : in data_t;

        pixel_bus : out pixel_bus_t;
        audio     : out mixed_audio_t;

        joy_strobe : out std_logic;

        joy_1_clk  : out std_logic;
        joy_1_data : in joy_data_t := JOY_DATA_IDLE;

        joy_2_clk  : out std_logic;
        joy_2_data : in joy_data_t := JOY_DATA_IDLE;

        cart_cpu_in  : out cart_cpu_in_t;
        cart_cpu_out : in cart_cpu_out_t;
        cart_ppu_in  : out cart_ppu_in_t;
        cart_ppu_out : in cart_ppu_out_t;
        cart_audio   : in cart_audio_t := 0;

        cart_reset  : out boolean := true;
        cart_loaded : in boolean;
        cart_ready  : in boolean;

        power_up_ready : out boolean;
        power_up_data  : out power_up_data_t
    );
    end component nes_console;

    -- Variant of nes_console with its RAMs on chip. See nes_console_ocram
    component nes_console_ocram is
    generic
    (
        VENDOR       : vendor_t := VENDOR_ALTERA;
        CLK_FREQ     : positive := 50_000_000;
        CPU_FREQ_NUM : positive := 39_375_000;
        CPU_FREQ_DEN : positive := 22;
        POWER_UP_MODE : power_up_mode_t := POWER_UP_ZERO;
        POWER_UP_SEED : natural := 0;
        INVERT_CYCLE_PARITY : boolean := false
    );
    port
    (
        clk   : in std_logic;
        reset : in boolean;
        soft_reset : in boolean := false;
        famicom    : in boolean := false;

        nes_running : out boolean;

        stretch        : in boolean := false;
        run            : in boolean := true;
        waiting_to_run : out boolean;
        ppu_start      : out ppu_position_t;

        cpu_clk_en : out boolean;
        ppu_clk_en : out boolean;
        clk_sync   : out boolean;
        ppu_ram_en : out boolean;

        pixel_bus : out pixel_bus_t;
        audio     : out mixed_audio_t;

        joy_strobe : out std_logic;

        joy_1_clk  : out std_logic;
        joy_1_data : in joy_data_t := JOY_DATA_IDLE;

        joy_2_clk  : out std_logic;
        joy_2_data : in joy_data_t := JOY_DATA_IDLE;

        cart_cpu_in  : out cart_cpu_in_t;
        cart_cpu_out : in cart_cpu_out_t;
        cart_ppu_in  : out cart_ppu_in_t;
        cart_ppu_out : in cart_ppu_out_t;
        cart_audio   : in cart_audio_t := 0;

        cart_reset  : out boolean := true;
        cart_loaded : in boolean;
        cart_ready  : in boolean;

        power_up_ready : out boolean;
        power_up_data  : out power_up_data_t
    );
    end component nes_console_ocram;

end console;

package body console is

end package body;
