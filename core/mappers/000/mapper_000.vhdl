library IEEE;
use IEEE.std_logic_1164.all;
use work.cart_types.all;
use work.lib_mapper_000.all;

-- NROM
entity mapper_000 is
port
(
    clk      : in std_logic;
    clk_en   : in boolean;
    clk_sync : in boolean;
    reset    : in boolean;

    config   : in cart_config_t;

    cart_in  : in cart_in_t;
    cart_out : out cart_out_t
);
end mapper_000;

architecture behavioral of mapper_000 is
begin

    -- NROM has no registers
    cart_out <= cycle_mapper_000(config, cart_in);

end behavioral;
