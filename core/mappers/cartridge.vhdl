library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cart_types.all;

-- The cartridge, built as the board given by the mapper number of the ROM
-- file. Every supported board is instantiated and the board in use is
-- selected at run time. Its ports are the same as those of each board.
--
-- To add a board, add it to board_t and get_board, instantiate it and select
-- its outputs below
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
        BOARD_NROM,
        BOARD_MMC1,
        BOARD_UXROM,
        BOARD_CNROM,
        BOARD_MMC3,
        BOARD_GXROM
    );

    function get_board(mapper_num : mapper_num_t) return board_t
    is
    begin
        case mapper_num is
            when x"000" => return BOARD_NROM;
            when x"001" => return BOARD_MMC1;
            when x"002" => return BOARD_UXROM;
            when x"003" => return BOARD_CNROM;
            when x"004" => return BOARD_MMC3;
            when x"042" => return BOARD_GXROM;
            when others => return BOARD_NONE;
        end case;
    end;

    signal board : board_t;

    -- Boards that are not in use see an idle bus, so they do not need to be
    -- simulated
    signal nrom_in  : cart_in_t;
    signal mmc1_in  : cart_in_t;
    signal uxrom_in : cart_in_t;
    signal cnrom_in : cart_in_t;
    signal mmc3_in  : cart_in_t;
    signal gxrom_in : cart_in_t;

    signal nrom_out  : cart_out_t;
    signal mmc1_out  : cart_out_t;
    signal uxrom_out : cart_out_t;
    signal cnrom_out : cart_out_t;
    signal mmc3_out  : cart_out_t;
    signal gxrom_out : cart_out_t;

begin

    board <= get_board(config.mapper_num);

    assert reset or board /= BOARD_NONE
        report "Mapper not supported: " &
               integer'image(to_integer(unsigned(config.mapper_num)))
        severity failure;

    nrom_in  <= cart_in when board = BOARD_NROM  else CART_IN_IDLE;
    mmc1_in  <= cart_in when board = BOARD_MMC1  else CART_IN_IDLE;
    uxrom_in <= cart_in when board = BOARD_UXROM else CART_IN_IDLE;
    cnrom_in <= cart_in when board = BOARD_CNROM else CART_IN_IDLE;
    mmc3_in  <= cart_in when board = BOARD_MMC3  else CART_IN_IDLE;
    gxrom_in <= cart_in when board = BOARD_GXROM else CART_IN_IDLE;

    with board select cart_out <=
        nrom_out      when BOARD_NROM,
        mmc1_out      when BOARD_MMC1,
        uxrom_out     when BOARD_UXROM,
        cnrom_out     when BOARD_CNROM,
        mmc3_out      when BOARD_MMC3,
        gxrom_out     when BOARD_GXROM,
        CART_OUT_IDLE when BOARD_NONE;

    nrom : entity work.mapper_000
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => config,
        cart_in => nrom_in,
        cart_out => nrom_out
    );

    mmc1 : entity work.mapper_001
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => config,
        cart_in => mmc1_in,
        cart_out => mmc1_out
    );

    uxrom : entity work.mapper_002
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => config,
        cart_in => uxrom_in,
        cart_out => uxrom_out
    );

    cnrom : entity work.mapper_003
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => config,
        cart_in => cnrom_in,
        cart_out => cnrom_out
    );

    mmc3 : entity work.mapper_004
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => config,
        cart_in => mmc3_in,
        cart_out => mmc3_out
    );

    gxrom : entity work.mapper_066
    port map
    (
        clk => clk,
        clk_en => clk_en,
        clk_sync => clk_sync,
        reset => reset,
        config => config,
        cart_in => gxrom_in,
        cart_out => gxrom_out
    );

end behavioral;
