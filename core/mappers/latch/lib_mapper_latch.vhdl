library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.cart_types.all;

-- Boards built from discrete logic: one or more latches that hold bits of
-- the data the CPU writes, wired to the high address lines of the ROMs and to
-- CIRAM A10. They differ only in where the latches are written, which data
-- bits they hold and what those bits are wired to, so each board is a row in
-- a table chosen by the mapper number at run time.
--
-- To add a board, add its mapper number to is_latch_mapper and its row to
-- get_latch_board
package lib_mapper_latch is

    subtype latch_value_t is unsigned(7 downto 0);

    -- The addresses where the CPU writes a latch. Each is decoded once and
    -- shared by the boards, which is much smaller than a decoder of any
    -- address for each latch
    type latch_addr_t is
    (
        LATCH_ADDR_NONE,
        -- 0x8000-0xFFFF
        LATCH_ADDR_ROM,
        LATCH_ADDR_7FFD,
        LATCH_ADDR_7FFE,
        LATCH_ADDR_7FFF
    );

    -- A latch written by the CPU at addr. It holds the data shifted right by
    -- shift and masked by mask
    type latch_t is record
        addr  : latch_addr_t;
        shift : natural range 0 to 7;
        mask  : latch_value_t;
    end record;

    type latch_id_t is
    (
        LATCH_PRG,
        LATCH_CHR_0,
        LATCH_CHR_1,
        LATCH_MIRROR
    );

    type latches_t is array(latch_id_t) of latch_t;

    type latch_prg_mode_t is
    (
        -- LATCH_PRG selects a 32KB bank at 0x8000
        PRG_32KB,
        -- LATCH_PRG selects a 16KB bank at 0x8000. 0xC000 holds the last
        -- bank
        PRG_16KB_FIXED_LAST
    );

    type latch_chr_mode_t is
    (
        -- LATCH_CHR_0 selects an 8KB bank at 0x0000
        CHR_8KB,
        -- LATCH_CHR_0 and LATCH_CHR_1 select 4KB banks at 0x0000 and 0x1000
        CHR_4KB
    );

    type latch_mirror_mode_t is
    (
        -- Mirroring is set by solder pads, given by the header of the ROM
        -- file
        MIRROR_FIXED,
        -- Bit 0 of LATCH_MIRROR selects the nametable for single screen
        -- mirroring
        MIRROR_SINGLE
    );

    type latch_board_t is record
        prg_mode    : latch_prg_mode_t;
        chr_mode    : latch_chr_mode_t;
        mirror_mode : latch_mirror_mode_t;
        prg_ram     : boolean;
        latches     : latches_t;
    end record;

    -- The mapper number is that of a board in the table
    function is_latch_mapper(mapper_num : mapper_num_t) return boolean;

    -- The row of the table for the board of the ROM file
    function get_latch_board(config : cart_config_t) return latch_board_t;

    type mapper_latch_reg_t is array(latch_id_t) of latch_value_t;

    constant RESET_MAPPER_LATCH_REG : mapper_latch_reg_t :=
        (others => (others => '0'));

    type mapper_latch_out_t is record
        reg  : mapper_latch_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_latch
    (
        reg      : mapper_latch_reg_t;
        board    : latch_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_latch_out_t;

end package lib_mapper_latch;


package body lib_mapper_latch is

    -- A latch that is never written, so it always holds 0
    constant LATCH_NONE : latch_t :=
    (
        addr => LATCH_ADDR_NONE,
        shift => 0,
        mask => (others => '0')
    );

    -- A latch of data bits hi downto lo, written at addr
    function latch
    (
        addr : latch_addr_t;
        hi   : natural;
        lo   : natural
    )
    return latch_t
    is
        variable ret : latch_t;
    begin
        ret.addr := addr;
        ret.shift := lo;
        ret.mask := to_unsigned(2**(hi - lo + 1) - 1, latch_value_t'length);

        return ret;
    end;

    -- A latch of data bits hi downto lo, written at 0x8000-0xFFFF
    function rom_latch(hi : natural; lo : natural) return latch_t
    is
    begin
        return latch(LATCH_ADDR_ROM, hi, lo);
    end;

    function is_latch_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"000" | x"002" | x"003" | x"007" | x"00B" | x"022" |
                 x"042" => return true;
            when others => return false;
        end case;
    end;

    function get_latch_board(config : cart_config_t) return latch_board_t
    is
        variable ret : latch_board_t;
    begin
        ret.prg_mode := PRG_32KB;
        ret.chr_mode := CHR_8KB;
        ret.mirror_mode := MIRROR_FIXED;
        ret.prg_ram := false;
        ret.latches := (others => LATCH_NONE);

        case config.mapper_num is
            -- NROM
            when x"000" =>
                -- Family BASIC has PRG RAM
                ret.prg_ram := true;
            -- UxROM
            when x"002" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.latches(LATCH_PRG) := rom_latch(7, 0);
            -- CNROM
            when x"003" =>
                ret.latches(LATCH_CHR_0) := rom_latch(7, 0);
            -- AxROM
            when x"007" =>
                ret.mirror_mode := MIRROR_SINGLE;
                ret.latches(LATCH_PRG) := rom_latch(3, 0);
                ret.latches(LATCH_MIRROR) := rom_latch(4, 4);
            -- Color Dreams
            when x"00B" =>
                ret.latches(LATCH_PRG) := rom_latch(1, 0);
                ret.latches(LATCH_CHR_0) := rom_latch(7, 4);
            -- BNROM (submapper 2) and NINA-001 (submapper 1). Without a
            -- submapper, only NINA-001 has more than 8KB of CHR ROM
            when x"022" =>
                if config.submapper_num = x"1" or
                   (config.submapper_num = x"0" and
                    config.chr_rom_8kb_blocks > 1)
                then
                    ret.chr_mode := CHR_4KB;
                    ret.prg_ram := true;
                    ret.latches(LATCH_PRG) := latch(LATCH_ADDR_7FFD, 0, 0);
                    ret.latches(LATCH_CHR_0) := latch(LATCH_ADDR_7FFE, 3, 0);
                    ret.latches(LATCH_CHR_1) := latch(LATCH_ADDR_7FFF, 3, 0);
                else
                    ret.latches(LATCH_PRG) := rom_latch(7, 0);
                end if;
            -- GxROM
            when x"042" =>
                ret.latches(LATCH_PRG) := rom_latch(5, 4);
                ret.latches(LATCH_CHR_0) := rom_latch(1, 0);
            when others =>
        end case;

        return ret;
    end;

    function is_latch_addr
    (
        addr   : latch_addr_t;
        cpu_in : cart_cpu_in_t
    )
    return boolean
    is
        variable a : std_logic_vector(14 downto 0);
    begin
        a := cpu_in.prg_bus.address;

        case addr is
            when LATCH_ADDR_NONE =>
                return false;
            when LATCH_ADDR_ROM =>
                return cpu_in.romsel;
            when LATCH_ADDR_7FFD =>
                return not cpu_in.romsel and a = "111" & x"FFD";
            when LATCH_ADDR_7FFE =>
                return not cpu_in.romsel and a = "111" & x"FFE";
            when LATCH_ADDR_7FFF =>
                return not cpu_in.romsel and a = "111" & x"FFF";
        end case;
    end;

    function cycle_mapper_latch
    (
        reg      : mapper_latch_reg_t;
        board    : latch_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_latch_out_t
    is
        variable ret : mapper_latch_out_t;
        variable banks : cart_banks_t;
        variable prg_window : prg_window_t;
        variable chr_window : chr_window_t;
        variable prg_bank : latch_value_t;
        variable chr_bank : latch_value_t;
    begin
        ret.reg := reg;
        banks := default_banks(config);

        if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
        then
            for i in latch_id_t
            loop
                if is_latch_addr(board.latches(i).addr, cart_in.cpu)
                then
                    ret.reg(i) := shift_right(unsigned(cart_in.cpu.data),
                                              board.latches(i).shift) and
                                  board.latches(i).mask;
                end if;
            end loop;
        end if;

        -- The PPU sees the latches written by the CPU this cycle
        prg_window := get_prg_window(cart_in.cpu);
        case board.prg_mode is
            when PRG_32KB =>
                banks.prg := resize(ret.reg(LATCH_PRG) & prg_window,
                                    prg_bank_8kb_t'length);
            when PRG_16KB_FIXED_LAST =>
                if prg_window(1) = '0'
                then
                    prg_bank := ret.reg(LATCH_PRG);
                else
                    prg_bank := (others => '1');
                end if;
                banks.prg := resize(prg_bank & prg_window(0),
                                    prg_bank_8kb_t'length);
        end case;

        chr_window := get_chr_window(cart_in.ppu);
        case board.chr_mode is
            when CHR_8KB =>
                banks.chr := resize(ret.reg(LATCH_CHR_0) & chr_window,
                                    chr_bank_1kb_t'length);
            when CHR_4KB =>
                if chr_window(2) = '0'
                then
                    chr_bank := ret.reg(LATCH_CHR_0);
                else
                    chr_bank := ret.reg(LATCH_CHR_1);
                end if;
                banks.chr := resize(chr_bank & chr_window(1 downto 0),
                                    chr_bank_1kb_t'length);
        end case;

        if board.mirror_mode = MIRROR_SINGLE
        then
            banks.mirror := get_single_screen_mirror(ret.reg(LATCH_MIRROR)(0));
        end if;

        banks.prg_ram := board.prg_ram;

        ret.cart := map_cart(config, cart_in, banks);

        return ret;
    end;

end package body;
