library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cart_types.all;
use work.lib_mapper_latch.all;
use work.lib_mapper_mmc1.all;
use work.lib_mapper_mmc2.all;
use work.lib_mapper_mmc3.all;

-- The cartridge, built as the board given by the mapper number of the ROM
-- file. Every supported board is instantiated and the board in use is
-- selected at run time. Its ports are the same as those of each board, which
-- also has an enable that is set only for the board in use.
--
-- To add a board, add it to board_t and get_board, instantiate it with an
-- enable of its own, and select its outputs below
entity cartridge is
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
end cartridge;

architecture behavioral of cartridge is

    type board_t is
    (
        BOARD_NONE,
        BOARD_LATCH,
        BOARD_MMC1,
        BOARD_MMC2,
        BOARD_MMC3
    );

    function get_board(mapper_num : mapper_num_t) return board_t
    is
    begin
        if is_latch_mapper(mapper_num)
        then
            return BOARD_LATCH;
        elsif is_mmc1_mapper(mapper_num)
        then
            return BOARD_MMC1;
        elsif is_mmc2_mapper(mapper_num)
        then
            return BOARD_MMC2;
        elsif is_mmc3_mapper(mapper_num)
        then
            return BOARD_MMC3;
        else
            return BOARD_NONE;
        end if;
    end;

    signal board : board_t;

    -- Boards that are not in use are disabled, so they do not need to be
    -- simulated
    signal latch_en : boolean;
    signal mmc1_en  : boolean;
    signal mmc2_en  : boolean;
    signal mmc3_en  : boolean;

    signal latch_out : cart_out_t;
    signal mmc1_out  : cart_out_t;
    signal mmc2_out  : cart_out_t;
    signal mmc3_out  : cart_out_t;

begin

    board <= get_board(config.mapper_num);

    assert reset or board /= BOARD_NONE
        report "Mapper not supported: " &
               integer'image(to_integer(unsigned(config.mapper_num)))
        severity failure;

    latch_en <= board = BOARD_LATCH;
    mmc1_en  <= board = BOARD_MMC1;
    mmc2_en  <= board = BOARD_MMC2;
    mmc3_en  <= board = BOARD_MMC3;

    with board select cart_out <=
        latch_out     when BOARD_LATCH,
        mmc1_out      when BOARD_MMC1,
        mmc2_out      when BOARD_MMC2,
        mmc3_out      when BOARD_MMC3,
        CART_OUT_IDLE when BOARD_NONE;

    latch : entity work.mapper_latch(behavioral)
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        enable => latch_en,
        config => config,
        cart_in => cart_in,
        cart_out => latch_out
    );

    mmc1 : entity work.mapper_mmc1(behavioral)
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        enable => mmc1_en,
        config => config,
        cart_in => cart_in,
        cart_out => mmc1_out
    );

    mmc2 : entity work.mapper_mmc2(behavioral)
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        enable => mmc2_en,
        config => config,
        cart_in => cart_in,
        cart_out => mmc2_out
    );

    mmc3 : entity work.mapper_mmc3(behavioral)
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        enable => mmc3_en,
        config => config,
        cart_in => cart_in,
        cart_out => mmc3_out
    );

end behavioral;
