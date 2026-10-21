library IEEE;
use IEEE.std_logic_1164.all;
use work.cart_types.all;
use work.lib_mapper_mmc3.all;

-- MMC3 boards: TxROM, NES-QJ, TxSROM and TQROM
entity mapper_mmc3 is
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
end mapper_mmc3;

architecture behavioral of mapper_mmc3 is

    signal board : mmc3_board_t;

    signal reg      : mapper_mmc3_reg_t := RESET_MAPPER_MMC3_REG;
    signal reg_next : mapper_mmc3_reg_t;

begin

    board <= get_mmc3_board(config);

    process(clk)
    begin
    -- double-IF is required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= RESET_MAPPER_MMC3_REG;
        else
            reg <= reg_next;
        end if;
    end if;
    end if;
    end process;

    process(all)
        variable v_out : mapper_mmc3_out_t;
    begin
        v_out := cycle_mapper_mmc3(reg, board, config, clk_sync, cart_in);

        reg_next <= v_out.reg;
        cart_out <= v_out.cart;
    end process;

end behavioral;
