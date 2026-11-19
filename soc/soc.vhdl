library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cart_mem_bus_types.all;
use work.nes_types.all;
use work.perhipheral_types.all;
use work.cart_connector_types.all;
use work.cart_types.all;

package soc is
    
    -- The NES. See nes_soc_ocram
    component nes_soc_ocram is
    generic
    (
        USE_EXT_CART_RAM : boolean := false;
        VENDOR           : vendor_t := VENDOR_ALTERA;
        CLK_FREQ         : positive := 50_000_000;
        CPU_FREQ_NUM     : positive := 39_375_000;
        CPU_FREQ_DEN     : positive := 22;
        CART_BOARDS      : board_set_t := ALL_BOARDS;
        POWER_UP_MODE    : power_up_mode_t := POWER_UP_ZERO;
        POWER_UP_SEED    : natural := 0;
        INVERT_CYCLE_PARITY : boolean := false
    );
    port
    (
        clk   : in std_logic;
        reset : in boolean;
        -- The reset button
        soft_reset : in boolean := false;
        -- Reset leaves PRG RAM alone, as it holds a save
        keep_prg_ram : in boolean := false;
        -- Run as a Famicom rather than a front loading NES
        famicom : in boolean := false;

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

        board_cpu_in  : out cart_cpu_in_t;
        board_cpu_out : in cart_cpu_out_t := CART_CPU_OUT_IDLE;
        board_ppu_in  : out cart_ppu_in_t
    );
    end component nes_soc_ocram;

end soc;

package body soc is

end package body;