library IEEE;
use IEEE.std_logic_1164.all;
use work.cart_types.all;
use work.lib_mapper_mmc1.all;

-- MMC1 boards: SxROM and NES-EVENT
entity mapper_mmc1 is
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
end mapper_mmc1;

architecture behavioral of mapper_mmc1 is

    signal board : mmc1_board_t;

    signal reg      : mapper_mmc1_reg_t := RESET_MAPPER_MMC1_REG;
    signal reg_next : mapper_mmc1_reg_t;

begin

    board <= get_mmc1_board(config);

    process(clk)
    begin
    -- double-IF is required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= get_reset_mmc1_reg(board);
        else
            reg <= reg_next;
        end if;
    end if;
    end if;
    end process;

    process(all)
        variable v_out : mapper_mmc1_out_t;
    begin
        -- A board that is not in use holds its registers, so it does not
        -- need to be simulated
        if enable
        then
            v_out := cycle_mapper_mmc1(reg, board, config, clk_sync, cart_in);

            reg_next <= v_out.reg;
            cart_out <= v_out.cart;
        else
            reg_next <= reg;
            cart_out <= CART_OUT_IDLE;
        end if;
    end process;

end behavioral;
