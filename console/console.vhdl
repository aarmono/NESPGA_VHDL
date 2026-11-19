library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.perhipheral_types.all;
use work.cart_connector_types.all;
use work.cart_pin_types.all;

-- The components of the console subsystem, for use outside of it
package console is

    -- Variant of nes_console with its RAMs on chip. See nes_console_ocram
    component nes_console_ocram is
    generic
    (
        VENDOR       : vendor_t := VENDOR_ALTERA;
        CLK_FREQ     : positive := 50_000_000;
        CPU_FREQ_NUM : positive := 39_375_000;
        CPU_FREQ_DEN : positive := 22;
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
        cpu_data_bus : out data_t;
        cart_ppu_in  : out cart_ppu_in_t;
        cart_ppu_out : in cart_ppu_out_t;
        cart_audio   : in cart_audio_t := 0;

        power_up_ready : in boolean := true;
        power_up_data  : in console_power_up_data_t := (others => '0');
        power_up_step  : out boolean
    );
    end component nes_console_ocram;

    -- The cartridge connector on pins, for a real cartridge. See cart_slot
    component cart_slot is
    generic
    (
        M2_LOW_CLOCKS    : positive := 10;
        PRECHARGE_CLOCKS : natural := 3;
        ALE_CLOCKS       : positive := 4
    );
    port
    (
        clk    : in std_logic;
        reset  : in boolean;

        cpu_en : in boolean;
        ppu_en : in boolean;

        cpu_in       : in  cart_cpu_in_t;
        cpu_out      : out cart_cpu_out_t;
        cpu_data_bus : in  data_t;
        ppu_in       : in  cart_ppu_in_t;
        ppu_out      : out cart_ppu_out_t;

        pins_out : out cart_console_pins_t;
        pins_in  : in  cart_board_pins_t
    );
    end component cart_slot;

end console;

package body console is

end package body;
