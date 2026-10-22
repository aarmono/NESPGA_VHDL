library IEEE;
use IEEE.std_logic_1164.all;
use work.cart_types.all;
use work.lib_mapper_vrc6.all;

-- Konami VRC6 boards: VRC6a and VRC6b
entity mapper_vrc6 is
port
(
    clk      : in std_logic;
    clk_en   : in boolean;
    clk_sync : in boolean;
    reset    : in boolean;
    -- The board is the one in the cartridge
    enable   : in boolean;

    config   : in cart_config_t;

    cart_in  : in cart_in_t;
    cart_out : out cart_out_t
);
end mapper_vrc6;

architecture behavioral of mapper_vrc6 is

    constant RESET_MAPPER_VRC6_REG : mapper_vrc6_reg_t := get_reset_vrc6_reg;

    signal reg      : mapper_vrc6_reg_t := RESET_MAPPER_VRC6_REG;
    signal reg_next : mapper_vrc6_reg_t;

begin

    process(clk)
    begin
    -- double-IF is required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= RESET_MAPPER_VRC6_REG;
        else
            reg <= reg_next;
        end if;
    end if;
    end if;
    end process;

    process(all)
        variable v_out : mapper_vrc6_out_t;
    begin
        -- A board that is not in use holds its registers, so it does not
        -- need to be simulated
        if enable
        then
            v_out := cycle_mapper_vrc6(reg, config, clk_sync, cart_in);

            reg_next <= v_out.reg;
            cart_out <= v_out.cart;
        else
            reg_next <= reg;
            cart_out <= CART_OUT_IDLE;
        end if;
    end process;

end behavioral;
