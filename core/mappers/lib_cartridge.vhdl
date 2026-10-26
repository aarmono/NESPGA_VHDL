library IEEE;
use IEEE.std_logic_1164.all;
use work.nes_types.all;
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
use work.lib_mapper_action53.all;
use work.lib_mapper_bandai.all;
use work.lib_mapper_ss88006.all;
use work.lib_mapper_taito.all;

-- The cartridge, built as the board given by the mapper number of the ROM
-- file. The registers of every supported board are kept and the board in use
-- is selected at run time. Boards that are not in use hold their registers.
--
-- To add a board, add it to board_t (and NES_BOARDS, if it was not sold on
-- NES carts), get_board, cart_reg_t and, if it has a board type of its own,
-- cart_boards_t. Then cycle it in cycle_cartridge and write its registers in
-- the cartridge entity
package lib_cartridge is

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
        bandai       : bandai_board_t;
        taito        : taito_board_t;
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
        action53 : mapper_action53_reg_t;
        bandai : mapper_bandai_reg_t;
        ss88006 : mapper_ss88006_reg_t;
        taito : mapper_taito_reg_t;
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
        n163 => RESET_MAPPER_N163_REG,
        action53 => RESET_MAPPER_ACTION53_REG,
        bandai => RESET_MAPPER_BANDAI_REG,
        ss88006 => RESET_MAPPER_SS88006_REG,
        taito => RESET_MAPPER_TAITO_REG
    );

    type cart_cycle_out_t is record
        reg  : cart_reg_t;
        cart : cart_out_t;
    end record;

    -- Only the boards in built are cycled
    function cycle_cartridge
    (
        reg      : cart_reg_t;
        boards   : cart_boards_t;
        built    : board_set_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return cart_cycle_out_t;

    -- The config with the RAM sizes of its board when the header is iNES,
    -- which gives none. Boards that need more than the default size say how
    -- much here
    function set_ines_ram_masks(config : cart_config_t) return cart_config_t;

    -- What the PRG RAM and chip RAM of the board hold at power on. The
    -- console zeroes them unless the board needs otherwise
    function get_save_ram_fill(config : cart_config_t) return data_t;

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
        elsif is_action53_mapper(mapper_num)
        then
            return BOARD_ACTION53;
        elsif is_bandai_mapper(mapper_num)
        then
            return BOARD_BANDAI;
        elsif is_ss88006_mapper(mapper_num)
        then
            return BOARD_SS88006;
        elsif is_taito_mapper(mapper_num)
        then
            return BOARD_TAITO;
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
            n163 => get_n163_board(config),
            bandai => get_bandai_board(config),
            taito => get_taito_board(config)
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
        ret.taito := get_reset_taito_reg(boards.taito);

        return ret;
    end;

    function cycle_cartridge
    (
        reg      : cart_reg_t;
        boards   : cart_boards_t;
        built    : board_set_t;
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
        variable action53_out : mapper_action53_out_t;
        variable bandai_out : mapper_bandai_out_t;
        variable ss88006_out : mapper_ss88006_out_t;
        variable taito_out : mapper_taito_out_t;
    begin
        ret.reg := reg;
        ret.cart := CART_OUT_IDLE;

        -- A board left out of the build is never cycled, so neither its
        -- logic nor its registers are built
        case boards.board is
            when BOARD_LATCH =>
                if built(BOARD_LATCH)
                then
                    latch_out := cycle_mapper_latch(reg.latch,
                                                    boards.latch,
                                                    config,
                                                    clk_sync,
                                                    cart_in);
                    ret.reg.latch := latch_out.reg;
                    ret.cart := latch_out.cart;
                end if;
            when BOARD_MMC1 =>
                if built(BOARD_MMC1)
                then
                    mmc1_out := cycle_mapper_mmc1(reg.mmc1,
                                                  boards.mmc1,
                                                  boards.mmc1_prg_ram,
                                                  config,
                                                  clk_sync,
                                                  cart_in);
                    ret.reg.mmc1 := mmc1_out.reg;
                    ret.cart := mmc1_out.cart;
                end if;
            when BOARD_MMC2 =>
                if built(BOARD_MMC2)
                then
                    mmc2_out := cycle_mapper_mmc2(reg.mmc2,
                                                  boards.mmc2,
                                                  config,
                                                  clk_sync,
                                                  cart_in);
                    ret.reg.mmc2 := mmc2_out.reg;
                    ret.cart := mmc2_out.cart;
                end if;
            when BOARD_MMC3 =>
                if built(BOARD_MMC3)
                then
                    mmc3_out := cycle_mapper_mmc3(reg.mmc3,
                                                  boards.mmc3,
                                                  config,
                                                  clk_sync,
                                                  cart_in);
                    ret.reg.mmc3 := mmc3_out.reg;
                    ret.cart := mmc3_out.cart;
                end if;
            when BOARD_FME7 =>
                if built(BOARD_FME7)
                then
                    fme7_out := cycle_mapper_fme7(reg.fme7,
                                                  built(BOARD_SUNSOFT_5B),
                                                  config,
                                                  clk_sync,
                                                  cart_in);
                    ret.reg.fme7 := fme7_out.reg;
                    ret.cart := fme7_out.cart;
                end if;
            when BOARD_VRC4 =>
                if built(BOARD_VRC4)
                then
                    vrc4_out := cycle_mapper_vrc4(reg.vrc4,
                                                  boards.vrc4,
                                                  config,
                                                  clk_sync,
                                                  cart_in);
                    ret.reg.vrc4 := vrc4_out.reg;
                    ret.cart := vrc4_out.cart;
                end if;
            when BOARD_VRC6 =>
                if built(BOARD_VRC6)
                then
                    vrc6_out := cycle_mapper_vrc6(reg.vrc6,
                                                  boards.vrc6,
                                                  config,
                                                  clk_sync,
                                                  cart_in);
                    ret.reg.vrc6 := vrc6_out.reg;
                    ret.cart := vrc6_out.cart;
                end if;
            when BOARD_MMC5 =>
                if built(BOARD_MMC5)
                then
                    mmc5_out := cycle_mapper_mmc5(reg.mmc5,
                                                  built(BOARD_MMC5_AUDIO),
                                                  config,
                                                  clk_sync,
                                                  cart_in);
                    ret.reg.mmc5 := mmc5_out.reg;
                    ret.cart := mmc5_out.cart;
                end if;
            when BOARD_N163 =>
                if built(BOARD_N163)
                then
                    n163_out := cycle_mapper_n163(reg.n163,
                                                  boards.n163,
                                                  config,
                                                  clk_sync,
                                                  cart_in);
                    ret.reg.n163 := n163_out.reg;
                    ret.cart := n163_out.cart;
                end if;
            when BOARD_ACTION53 =>
                if built(BOARD_ACTION53)
                then
                    action53_out := cycle_mapper_action53(reg.action53,
                                                          config,
                                                          clk_sync,
                                                          cart_in);
                    ret.reg.action53 := action53_out.reg;
                    ret.cart := action53_out.cart;
                end if;
            when BOARD_BANDAI =>
                if built(BOARD_BANDAI)
                then
                    bandai_out := cycle_mapper_bandai(reg.bandai,
                                                      boards.bandai,
                                                      config,
                                                      clk_sync,
                                                      cart_in);
                    ret.reg.bandai := bandai_out.reg;
                    ret.cart := bandai_out.cart;
                end if;
            when BOARD_SS88006 =>
                if built(BOARD_SS88006)
                then
                    ss88006_out := cycle_mapper_ss88006(reg.ss88006,
                                                        config,
                                                        clk_sync,
                                                        cart_in);
                    ret.reg.ss88006 := ss88006_out.reg;
                    ret.cart := ss88006_out.cart;
                end if;
            when BOARD_TAITO =>
                if built(BOARD_TAITO)
                then
                    taito_out := cycle_mapper_taito(reg.taito,
                                                    boards.taito,
                                                    config,
                                                    clk_sync,
                                                    cart_in);
                    ret.reg.taito := taito_out.reg;
                    ret.cart := taito_out.cart;
                end if;
            when BOARD_NONE | BOARD_SUNSOFT_5B | BOARD_MMC5_AUDIO =>
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
        elsif is_action53_mapper(config.mapper_num)
        then
            ret.chr_ram_mask := ACTION53_INES_CHR_RAM_MASK;
        elsif is_taito_mapper(config.mapper_num) and
              get_taito_board(config) = TAITO_X1_005
        then
            ret.prg_ram_mask := TAITO_X1_005_INES_PRG_RAM_MASK;
        end if;

        return ret;
    end;

    -- Famicom Jump II (153) hangs if its PRG RAM holds zeroes, and the
    -- EEPROMs of the other Bandai boards are blank, so these are filled
    -- with ones, as a blank EEPROM is
    function get_save_ram_fill(config : cart_config_t) return data_t
    is
    begin
        if is_bandai_mapper(config.mapper_num)
        then
            return x"FF";
        else
            return x"00";
        end if;
    end;

end package body;
