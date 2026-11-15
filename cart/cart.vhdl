library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.opll_bus_types.all;
use work.cart_types.all;

-- The components of the cartridge subsystem, for use outside of it
package cart is

    -- The cartridge, built as the board given by the mapper number of the
    -- ROM file
    component cartridge is
    generic
    (
        -- The boards to build. See board_set_t
        CART_BOARDS : board_set_t := ALL_BOARDS
    );
    port
    (
        clk      : in std_logic;
        clk_en   : in boolean;
        clk_sync : in boolean;
        reset    : in boolean;

        config   : in cart_config_t;

        cart_in  : in cart_in_t;
        cart_out : out cart_out_t;

        -- The memories of the VRC7 audio
        opll_mem_out       : out opll_mem_out_t;
        data_from_opll_ram : in opll_ram_data_t
    );
    end component cartridge;

end cart;

package body cart is

end package body;
