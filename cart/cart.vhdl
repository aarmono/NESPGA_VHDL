library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.perhipheral_types.all;
use work.cart_mem_bus_types.all;
use work.chip_ram_bus_types.all;
use work.opll_bus_types.all;
use work.cart_connector_types.all;
use work.cart_types.all;

-- The components of the cartridge subsystem, for use outside of it
package cart is

    -- The cartridge with its memories on buses. See cart_system
    component cart_system is
    generic
    (
        CART_BOARDS : board_set_t := ALL_BOARDS
    );
    port
    (
        clk      : in std_logic;
        reset    : in boolean;

        cpu_en   : in boolean;
        ppu_en   : in boolean;
        clk_sync : in boolean;

        keep_prg_ram  : in boolean := false;

        power_up_ready : in boolean;
        power_up_data  : in power_up_data_t;

        loaded : out boolean;
        ready  : out boolean;

        cpu_in  : in  cart_cpu_in_t;
        cpu_out : out cart_cpu_out_t;
        ppu_in  : in  cart_ppu_in_t;
        ppu_out : out cart_ppu_out_t;
        audio   : out cart_audio_t;

        cart_mem_bus       : out cart_mem_bus_t;
        data_to_cart_mem   : out data_t;
        data_from_cart_mem : in data_t;

        chip_ram_bus       : out chip_ram_bus_t;
        data_to_chip_ram   : out data_t;
        data_from_chip_ram : in data_t;

        opll_ram_bus       : out opll_ram_bus_t;
        data_to_opll_ram   : out opll_ram_data_t;
        data_from_opll_ram : in opll_ram_data_t
    );
    end component cart_system;

    -- Variant of cart_system with on-chip RAMs. See cart_system_ocram
    component cart_system_ocram is
    generic
    (
        USE_EXT_CART_RAM : boolean := false;
        VENDOR           : vendor_t := VENDOR_ALTERA;
        CART_BOARDS      : board_set_t := ALL_BOARDS
    );
    port
    (
        clk      : in std_logic;
        reset    : in boolean;

        cpu_en   : in boolean;
        ppu_en   : in boolean;
        clk_sync : in boolean;
        ram_en   : in boolean;

        keep_prg_ram  : in boolean := false;

        power_up_ready : in boolean;
        power_up_data  : in power_up_data_t;

        loaded : out boolean;
        ready  : out boolean;

        cpu_in  : in  cart_cpu_in_t;
        cpu_out : out cart_cpu_out_t;
        ppu_in  : in  cart_ppu_in_t;
        ppu_out : out cart_ppu_out_t;
        audio   : out cart_audio_t;

        cart_mem_bus       : out cart_mem_bus_t;
        data_to_cart_mem   : out data_t;
        data_from_cart_mem : in data_t
    );
    end component cart_system_ocram;

end cart;

package body cart is

end package body;
