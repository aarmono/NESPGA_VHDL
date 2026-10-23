library IEEE;
use IEEE.std_logic_1164.all;
use work.nes_types.all;
use work.cart_types.all;
use work.lib_mapper_mmc5.all;

-- Nintendo MMC5 boards: EKROM, ELROM, ETROM and EWROM
entity mapper_mmc5 is
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
end mapper_mmc5;

architecture behavioral of mapper_mmc5 is

    signal reg      : mapper_mmc5_reg_t := RESET_MAPPER_MMC5_REG;
    signal reg_next : mapper_mmc5_reg_t;

begin

    process(clk)
    begin
    -- double-IF is required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= RESET_MAPPER_MMC5_REG;
        else
            reg <= reg_next;
        end if;
    end if;
    end if;
    end process;

    process(all)
        variable v_out : mapper_mmc5_out_t;
    begin
        -- A board that is not in use holds its registers, so it does not
        -- need to be simulated
        if enable
        then
            v_out := cycle_mapper_mmc5(reg, config, clk_sync, cart_in);

            reg_next <= v_out.reg;
            cart_out <= v_out.cart;
        else
            reg_next <= reg;
            cart_out <= CART_OUT_IDLE;
        end if;
    end process;

end behavioral;
