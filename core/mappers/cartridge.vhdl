library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cart_types.all;

-- The cartridge, built as the board given by the mapper number of the ROM
-- file. Every supported board is instantiated and the board in use is
-- selected at run time. Its ports are the same as those of each board.
--
-- To add a board, add it to board_t and get_board, declare and instantiate
-- it, and select its outputs below
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
        BOARD_MMC3
    );

    function get_board(mapper_num : mapper_num_t) return board_t
    is
    begin
        case mapper_num is
            when x"000" | x"002" | x"003" | x"007" | x"00B" | x"022" | x"042" =>
                return BOARD_LATCH;
            when x"001" => return BOARD_MMC1;
            when x"004" | x"02F" | x"04C" | x"058" | x"05F" | x"076" | x"077" |
                 x"09A" | x"0CE" =>
                return BOARD_MMC3;
            when others => return BOARD_NONE;
        end case;
    end;

    component mapper_latch is
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
    end component;

    component mapper_001 is
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
    end component;

    component mapper_mmc3 is
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
    end component;

    signal board : board_t;

    signal board_config : cart_config_t;

    -- Boards that are not in use see an idle bus, so they do not need to be
    -- simulated
    signal latch_in : cart_in_t;
    signal mmc1_in  : cart_in_t;
    signal mmc3_in  : cart_in_t;

    signal latch_out : cart_out_t;
    signal mmc1_out  : cart_out_t;
    signal mmc3_out  : cart_out_t;

begin

    board <= get_board(config.mapper_num);
    board_config <= set_rom_masks(config);

    assert reset or board /= BOARD_NONE
        report "Mapper not supported: " &
               integer'image(to_integer(unsigned(config.mapper_num)))
        severity failure;

    latch_in <= cart_in when board = BOARD_LATCH else CART_IN_IDLE;
    mmc1_in  <= cart_in when board = BOARD_MMC1  else CART_IN_IDLE;
    mmc3_in  <= cart_in when board = BOARD_MMC3  else CART_IN_IDLE;

    with board select cart_out <=
        latch_out     when BOARD_LATCH,
        mmc1_out      when BOARD_MMC1,
        mmc3_out      when BOARD_MMC3,
        CART_OUT_IDLE when BOARD_NONE;

    latch : mapper_latch
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => board_config,
        cart_in => latch_in,
        cart_out => latch_out
    );

    mmc1 : mapper_001
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => board_config,
        cart_in => mmc1_in,
        cart_out => mmc1_out
    );

    mmc3 : mapper_mmc3
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => board_config,
        cart_in => mmc3_in,
        cart_out => mmc3_out
    );

end behavioral;
