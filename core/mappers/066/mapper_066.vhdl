library IEEE;
use IEEE.std_logic_1164.all;
use work.cart_types.all;
use work.lib_mapper_066.all;

-- GxROM
entity mapper_066 is
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
end mapper_066;

architecture behavioral of mapper_066 is

    signal reg      : mapper_066_reg_t := RESET_MAPPER_066_REG;
    signal reg_next : mapper_066_reg_t;

begin

    process(clk)
    begin
    -- double-IF is required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= RESET_MAPPER_066_REG;
        else
            reg <= reg_next;
        end if;
    end if;
    end if;
    end process;

    process(all)
        variable v_out : mapper_066_out_t;
    begin
        v_out := cycle_mapper_066(reg, config, clk_sync, cart_in);

        reg_next <= v_out.reg;
        cart_out <= v_out.cart;
    end process;

end behavioral;
