library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cart_types.all;

-- The cartridge, built as the board given by the mapper number of the ROM
-- file. Every supported board is instantiated and the board in use is
-- selected at run time. Its ports are the same as those of each board, which
-- also has an enable that is set only for the board in use.
--
-- To add a board, add it to board_t and get_board, declare and instantiate
-- it with an enable of its own, and select its outputs below
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
        case mapper_num is
            when x"000" | x"002" | x"003" | x"007" | x"00B" | x"022" | x"042" =>
                return BOARD_LATCH;
            when x"001" => return BOARD_MMC1;
            when x"009" | x"00A" => return BOARD_MMC2;
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
        enable   : in boolean;

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
        enable   : in boolean;

        config   : in cart_config_t;

        cart_in  : in cart_in_t;
        cart_out : out cart_out_t
    );
    end component;

    component mapper_mmc2 is
    port
    (
        clk      : in std_logic;
        clk_en   : in boolean;
        clk_sync : in boolean;
        reset    : in boolean;
        enable   : in boolean;

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
        enable   : in boolean;

        config   : in cart_config_t;

        cart_in  : in cart_in_t;
        cart_out : out cart_out_t
    );
    end component;

    signal board : board_t;

    signal board_config : cart_config_t;

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
    board_config <= set_rom_masks(config);

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

    latch : mapper_latch
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        enable => latch_en,
        config => board_config,
        cart_in => cart_in,
        cart_out => latch_out
    );

    mmc1 : mapper_001
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        enable => mmc1_en,
        config => board_config,
        cart_in => cart_in,
        cart_out => mmc1_out
    );

    mmc2 : mapper_mmc2
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        enable => mmc2_en,
        config => board_config,
        cart_in => cart_in,
        cart_out => mmc2_out
    );

    mmc3 : mapper_mmc3
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        enable => mmc3_en,
        config => board_config,
        cart_in => cart_in,
        cart_out => mmc3_out
    );

end behavioral;
