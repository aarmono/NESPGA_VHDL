library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cart_types.all;
use work.lib_cartridge.all;

-- The cartridge, built as the board given by the mapper number of the ROM
-- file. The boards are cycled by lib_cartridge
entity cartridge is
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
    cart_out : out cart_out_t
);
    -- Quartus builds the small multipliers of the boards' audio (volume
    -- and level scaling) from LEs unless told otherwise, and there are
    -- plenty of multiplier blocks to spare
    attribute multstyle : string;
    attribute multstyle of cartridge : entity is "dsp";
end cartridge;

architecture behavioral of cartridge is

    signal boards : cart_boards_t;

    signal reg : cart_reg_t := RESET_CART_REG;

begin

    boards <= get_cart_boards(config);

    assert reset or CART_BOARDS(boards.board)
        report "Mapper not supported: " &
               integer'image(to_integer(unsigned(config.mapper_num)))
        severity failure;

    -- Only the registers of the board in use are written, since writing
    -- those of every board is slow to simulate
    process(clk)
        variable v_out : cart_cycle_out_t;
    begin
    -- double-IF is required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= get_reset_cart_reg(boards);
        else
            v_out := cycle_cartridge(reg,
                                     boards,
                                     CART_BOARDS,
                                     config,
                                     clk_sync,
                                     cart_in);

            case boards.board is
                when BOARD_LATCH => reg.latch <= v_out.reg.latch;
                when BOARD_MMC1 => reg.mmc1 <= v_out.reg.mmc1;
                when BOARD_MMC2 => reg.mmc2 <= v_out.reg.mmc2;
                when BOARD_MMC3 => reg.mmc3 <= v_out.reg.mmc3;
                when BOARD_FME7 => reg.fme7 <= v_out.reg.fme7;
                when BOARD_VRC4 => reg.vrc4 <= v_out.reg.vrc4;
                when BOARD_VRC6 => reg.vrc6 <= v_out.reg.vrc6;
                when BOARD_MMC5 => reg.mmc5 <= v_out.reg.mmc5;
                when BOARD_N163 => reg.n163 <= v_out.reg.n163;
                when BOARD_ACTION53 => reg.action53 <= v_out.reg.action53;
                when BOARD_BANDAI => reg.bandai <= v_out.reg.bandai;
                when BOARD_NONE =>
            end case;
        end if;
    end if;
    end if;
    end process;

    process(all)
        variable v_out : cart_cycle_out_t;
    begin
        v_out := cycle_cartridge(reg,
                                 boards,
                                 CART_BOARDS,
                                 config,
                                 clk_sync,
                                 cart_in);

        cart_out <= v_out.cart;
    end process;

end behavioral;
