library IEEE;
use IEEE.std_logic_1164.all;
use work.cart_types.all;
use work.lib_mapper_003.all;

-- CNROM
entity mapper_003 is
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
end mapper_003;

architecture behavioral of mapper_003 is

    signal reg      : mapper_003_reg_t := RESET_MAPPER_003_REG;
    signal reg_next : mapper_003_reg_t;

begin

    process(clk)
    begin
    -- double-IF is required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= RESET_MAPPER_003_REG;
        else
            reg <= reg_next;
        end if;
    end if;
    end if;
    end process;

    process(all)
        variable v_out : mapper_003_out_t;
    begin
        v_out := cycle_mapper_003(reg, config, clk_sync, cart_in);

        reg_next <= v_out.reg;
        cart_out <= v_out.cart;
    end process;

end behavioral;
