library IEEE;
use IEEE.std_logic_1164.all;
use work.cart_types.all;
use work.lib_mapper_latch.all;
use work.lib_mapper_mmc1.all;
use work.lib_mapper_mmc2.all;
use work.lib_mapper_mmc3.all;
use work.lib_mapper_fme7.all;
use work.lib_mapper_vrc4.all;
use work.lib_mapper_vrc6.all;
use work.lib_mapper_mmc5.all;
use work.lib_mapper_n163.all;

-- The cartridge, built as the board given by the mapper number of the ROM
-- file. The registers of every supported board are kept and the board in use
-- is selected at run time. Boards that are not in use hold their registers.
--
-- To add a board, add it to board_t, get_board, cart_reg_t and, if it has
-- a board type of its own, cart_boards_t. Then cycle it in cycle_cartridge
-- and write its registers in the cartridge entity
package lib_cartridge is

    type board_t is
    (
        BOARD_NONE,
        BOARD_LATCH,
        BOARD_MMC1,
        BOARD_MMC2,
        BOARD_MMC3,
        BOARD_FME7,
        BOARD_VRC4,
        BOARD_VRC6,
        BOARD_MMC5,
        BOARD_N163
    );

    -- The board in use and how it is wired, decoded from the config
    type cart_boards_t is record
        board        : board_t;
        latch        : latch_board_t;
        mmc1         : mmc1_board_t;
        mmc1_prg_ram : mmc1_prg_ram_t;
        mmc2         : mmc2_board_t;
        mmc3         : mmc3_board_t;
        vrc4         : vrc4_board_t;
        vrc6         : vrc6_board_t;
        n163         : n163_board_t;
    end record;

    function get_cart_boards(config : cart_config_t) return cart_boards_t;

    type cart_reg_t is record
        latch : mapper_latch_reg_t;
        mmc1  : mapper_mmc1_reg_t;
        mmc2  : mapper_mmc2_reg_t;
        mmc3  : mapper_mmc3_reg_t;
        fme7  : mapper_fme7_reg_t;
        vrc4  : mapper_vrc4_reg_t;
        vrc6  : mapper_vrc6_reg_t;
        mmc5  : mapper_mmc5_reg_t;
        n163  : mapper_n163_reg_t;
    end record;

    function get_reset_cart_reg(boards : cart_boards_t) return cart_reg_t;

    constant RESET_CART_REG : cart_reg_t :=
    (
        latch => RESET_MAPPER_LATCH_REG,
        mmc1 => RESET_MAPPER_MMC1_REG,
        mmc2 => RESET_MAPPER_MMC2_REG,
        mmc3 => RESET_MAPPER_MMC3_REG,
        fme7 => RESET_MAPPER_FME7_REG,
        vrc4 => RESET_MAPPER_VRC4_REG,
        vrc6 => get_reset_vrc6_reg,
        mmc5 => RESET_MAPPER_MMC5_REG,
        n163 => RESET_MAPPER_N163_REG
    );

    type cart_cycle_out_t is record
        reg  : cart_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_cartridge
    (
        reg      : cart_reg_t;
        boards   : cart_boards_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return cart_cycle_out_t;

    -- The config with the RAM sizes of its board when the header is iNES,
    -- which gives none. Boards that need more than the default size say how
    -- much here
    function set_ines_ram_masks(config : cart_config_t) return cart_config_t;

end package lib_cartridge;


package body lib_cartridge is

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
        elsif is_fme7_mapper(mapper_num)
        then
            return BOARD_FME7;
        elsif is_vrc4_mapper(mapper_num)
        then
            return BOARD_VRC4;
        elsif is_vrc6_mapper(mapper_num)
        then
            return BOARD_VRC6;
        elsif is_mmc5_mapper(mapper_num)
        then
            return BOARD_MMC5;
        elsif is_n163_mapper(mapper_num)
        then
            return BOARD_N163;
        else
            return BOARD_NONE;
        end if;
    end;

    function get_cart_boards(config : cart_config_t) return cart_boards_t
    is
    begin
        return
        (
            board => get_board(config.mapper_num),
            latch => get_latch_board(config),
            mmc1 => get_mmc1_board(config),
            mmc1_prg_ram => get_mmc1_prg_ram(config),
            mmc2 => get_mmc2_board(config),
            mmc3 => get_mmc3_board(config),
            vrc4 => get_vrc4_board(config),
            vrc6 => get_vrc6_board(config),
            n163 => get_n163_board(config)
        );
    end;

    function get_reset_cart_reg(boards : cart_boards_t) return cart_reg_t
    is
        variable ret : cart_reg_t;
    begin
        ret := RESET_CART_REG;
        ret.latch := get_reset_latch_reg(boards.latch);
        ret.mmc1 := get_reset_mmc1_reg(boards.mmc1);
        ret.n163 := get_reset_n163_reg(boards.n163);

        return ret;
    end;

    function cycle_cartridge
    (
        reg      : cart_reg_t;
        boards   : cart_boards_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return cart_cycle_out_t
    is
        variable ret : cart_cycle_out_t;

        variable latch_out : mapper_latch_out_t;
        variable mmc1_out  : mapper_mmc1_out_t;
        variable mmc2_out  : mapper_mmc2_out_t;
        variable mmc3_out  : mapper_mmc3_out_t;
        variable fme7_out  : mapper_fme7_out_t;
        variable vrc4_out  : mapper_vrc4_out_t;
        variable vrc6_out  : mapper_vrc6_out_t;
        variable mmc5_out  : mapper_mmc5_out_t;
        variable n163_out  : mapper_n163_out_t;
    begin
        ret.reg := reg;
        ret.cart := CART_OUT_IDLE;

        case boards.board is
            when BOARD_LATCH =>
                latch_out := cycle_mapper_latch(reg.latch,
                                                boards.latch,
                                                config,
                                                clk_sync,
                                                cart_in);
                ret.reg.latch := latch_out.reg;
                ret.cart := latch_out.cart;
            when BOARD_MMC1 =>
                mmc1_out := cycle_mapper_mmc1(reg.mmc1,
                                              boards.mmc1,
                                              boards.mmc1_prg_ram,
                                              config,
                                              clk_sync,
                                              cart_in);
                ret.reg.mmc1 := mmc1_out.reg;
                ret.cart := mmc1_out.cart;
            when BOARD_MMC2 =>
                mmc2_out := cycle_mapper_mmc2(reg.mmc2,
                                              boards.mmc2,
                                              config,
                                              clk_sync,
                                              cart_in);
                ret.reg.mmc2 := mmc2_out.reg;
                ret.cart := mmc2_out.cart;
            when BOARD_MMC3 =>
                mmc3_out := cycle_mapper_mmc3(reg.mmc3,
                                              boards.mmc3,
                                              config,
                                              clk_sync,
                                              cart_in);
                ret.reg.mmc3 := mmc3_out.reg;
                ret.cart := mmc3_out.cart;
            when BOARD_FME7 =>
                fme7_out := cycle_mapper_fme7(reg.fme7,
                                              config,
                                              clk_sync,
                                              cart_in);
                ret.reg.fme7 := fme7_out.reg;
                ret.cart := fme7_out.cart;
            when BOARD_VRC4 =>
                vrc4_out := cycle_mapper_vrc4(reg.vrc4,
                                              boards.vrc4,
                                              config,
                                              clk_sync,
                                              cart_in);
                ret.reg.vrc4 := vrc4_out.reg;
                ret.cart := vrc4_out.cart;
            when BOARD_VRC6 =>
                vrc6_out := cycle_mapper_vrc6(reg.vrc6,
                                              boards.vrc6,
                                              config,
                                              clk_sync,
                                              cart_in);
                ret.reg.vrc6 := vrc6_out.reg;
                ret.cart := vrc6_out.cart;
            when BOARD_MMC5 =>
                mmc5_out := cycle_mapper_mmc5(reg.mmc5,
                                              config,
                                              clk_sync,
                                              cart_in);
                ret.reg.mmc5 := mmc5_out.reg;
                ret.cart := mmc5_out.cart;
            when BOARD_N163 =>
                n163_out := cycle_mapper_n163(reg.n163,
                                              boards.n163,
                                              config,
                                              clk_sync,
                                              cart_in);
                ret.reg.n163 := n163_out.reg;
                ret.cart := n163_out.cart;
            when BOARD_NONE =>
        end case;

        return ret;
    end;

    function set_ines_ram_masks(config : cart_config_t) return cart_config_t
    is
        variable ret : cart_config_t;
    begin
        ret := config;

        if is_latch_mapper(config.mapper_num)
        then
            ret.chr_ram_mask := get_latch_ines_chr_ram_mask(config);
        elsif is_mmc1_mapper(config.mapper_num)
        then
            ret.prg_ram_mask := get_mmc1_ines_prg_ram_mask(config);
        elsif is_mmc5_mapper(config.mapper_num)
        then
            ret.prg_ram_mask := MMC5_INES_PRG_RAM_MASK;
        end if;

        return ret;
    end;

end package body;
