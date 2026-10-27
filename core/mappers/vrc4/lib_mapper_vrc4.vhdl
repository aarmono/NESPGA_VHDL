library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;
use work.lib_vrc_irq.all;

-- Boards built around the Konami VRC2 or VRC4 (21, 22, 23, 25). The VRC4
-- is the VRC2 with a PRG swap mode, single screen mirroring, a ninth CHR
-- bank bit and an IRQ counter. The boards differ in which two CPU address
-- lines are wired to the A0 and A1 inputs of the chip, which select the
-- register written at each 4KB of 0x8000-0xFFFF.
--
-- iNES mappers 21, 23 and 25 each stand for two wirings, which do not
-- overlap, so the chip sees the OR of both pairs of lines. Those boards are
-- taken to be VRC4. A submapper in an NES 2.0 header selects one wiring and
-- the chip.
--
-- Every board has PRG RAM at 0x6000. The VRC2 has a 1-bit latch there in
-- place of RAM on boards without it, and the VRC4 a PRG RAM enable in bit 0
-- of 0x9002, but some games read the latch back, which RAM does as well, so
-- neither is emulated, as in Mesen
--
-- To add a board, add its mapper number to is_vrc4_mapper and give it an
-- arm in get_vrc4_board with its wiring from vrc_board, or from
-- vrc4_ines_board for an iNES number that stands for two wirings. A quirk
-- beyond the wiring and the chip, like the CHR shift of the VRC2a, needs a
-- field in vrc4_board_t, a parameter of vrc_board and its use in
-- cycle_mapper_vrc4 or the functions it calls
package lib_mapper_vrc4 is

    -- CPU A7-A0
    subtype vrc4_lines_t is std_logic_vector(7 downto 0);

    type vrc4_board_t is record
        -- The CPU address lines whose OR drives A0 and A1 of the chip
        a0        : vrc4_lines_t;
        a1        : vrc4_lines_t;
        -- The chip is a VRC4 rather than a VRC2
        vrc4      : boolean;
        -- VRC2a (22) drops the low bit of the CHR banks
        chr_shift : boolean;
    end record;

    -- The mapper number is that of a board built around the VRC2 or VRC4
    function is_vrc4_mapper(mapper_num : mapper_num_t) return boolean;

    function get_vrc4_board(config : cart_config_t) return vrc4_board_t;

    subtype prg_bank_t is unsigned(4 downto 0);

    -- 4 low bits, written at even registers, and 5 high bits, written at
    -- odd registers. The VRC2 has 4 high bits
    subtype chr_bank_t is unsigned(8 downto 0);
    type chr_bank_arr_t is array(0 to 7) of chr_bank_t;

    type mapper_vrc4_reg_t is record
        -- The bank at 0x8000, or at 0xC000 in swap mode
        prg_bank_0 : prg_bank_t;
        -- The bank at 0xA000
        prg_bank_1 : prg_bank_t;
        -- The second to last bank is at 0x8000 and prg_bank_0 at 0xC000
        prg_swap   : boolean;

        chr_banks  : chr_bank_arr_t;

        mirror     : mirror_t;
    end record;

    constant RESET_MAPPER_VRC4_REG : mapper_vrc4_reg_t :=
    (
        prg_bank_0 => (others => '0'),
        prg_bank_1 => (others => '0'),
        prg_swap => false,

        chr_banks => (others => (others => '0')),

        mirror => MIRROR_VERT
    );

    -- The IRQ counter is shared with the VRC6 and VRC7 and kept by the
    -- cartridge, which makes irq_write to it
    type mapper_vrc4_out_t is record
        reg       : mapper_vrc4_reg_t;
        cart      : cart_out_t;
        irq_write : vrc_irq_write_t;
    end record;

    function cycle_mapper_vrc4
    (
        reg      : mapper_vrc4_reg_t;
        board    : vrc4_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_vrc4_out_t;

end package lib_mapper_vrc4;


package body lib_mapper_vrc4 is

    function is_vrc4_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"015" | x"016" | x"017" | x"019" => return true;
            when others => return false;
        end case;
    end;

    -- A board with A0 and A1 of the chip wired to the CPU address lines
    -- in a0 and a1
    function vrc_board
    (
        a0        : natural;
        a1        : natural;
        vrc4      : boolean;
        chr_shift : boolean := false
    )
    return vrc4_board_t
    is
        variable ret : vrc4_board_t;
    begin
        ret.a0 := (others => '0');
        ret.a1 := (others => '0');
        ret.a0(a0) := '1';
        ret.a1(a1) := '1';
        ret.vrc4 := vrc4;
        ret.chr_shift := chr_shift;

        return ret;
    end;

    -- A VRC4 board of an iNES header, wired both ways at once
    function vrc4_ines_board
    (
        a0_0 : natural;
        a1_0 : natural;
        a0_1 : natural;
        a1_1 : natural
    )
    return vrc4_board_t
    is
        variable ret : vrc4_board_t;
    begin
        ret := vrc_board(a0_0, a1_0, true);
        ret.a0(a0_1) := '1';
        ret.a1(a1_1) := '1';

        return ret;
    end;

    function get_vrc4_board(config : cart_config_t) return vrc4_board_t
    is
    begin
        case config.mapper_num is
            -- 21: VRC4a (submapper 1) and VRC4c (submapper 2)
            when x"015" =>
                case config.submapper_num is
                    when x"1" => return vrc_board(1, 2, true);
                    when x"2" => return vrc_board(6, 7, true);
                    when others => return vrc4_ines_board(1, 2, 6, 7);
                end case;
            -- 22: VRC2a
            when x"016" =>
                return vrc_board(1, 0, false, chr_shift => true);
            -- 23: VRC4f (submapper 1), VRC4e (submapper 2) and VRC2b
            -- (submapper 3)
            when x"017" =>
                case config.submapper_num is
                    when x"1" => return vrc_board(0, 1, true);
                    when x"2" => return vrc_board(2, 3, true);
                    when x"3" => return vrc_board(0, 1, false);
                    when others => return vrc4_ines_board(0, 1, 2, 3);
                end case;
            -- 25: VRC4b (submapper 1), VRC4d (submapper 2) and VRC2c
            -- (submapper 3)
            when others =>
                case config.submapper_num is
                    when x"1" => return vrc_board(1, 0, true);
                    when x"2" => return vrc_board(3, 2, true);
                    when x"3" => return vrc_board(1, 0, false);
                    when others => return vrc4_ines_board(1, 0, 3, 2);
                end case;
        end case;
    end;

    -- The mirroring written to 0x9000. The VRC2 has only bit 0
    function get_mirror(data : data_t; vrc4 : boolean) return mirror_t
    is
    begin
        if not vrc4
        then
            return get_hv_single_screen_mirror('0' & data(0));
        end if;
        return get_hv_single_screen_mirror(data(1 downto 0));
    end;

    function write_chr_bank
    (
        bank : chr_bank_t;
        high : boolean;
        vrc4 : boolean;
        data : data_t
    )
    return chr_bank_t
    is
        variable ret : chr_bank_t;
    begin
        ret := bank;

        if not high
        then
            ret(3 downto 0) := unsigned(data(3 downto 0));
        else
            ret(8 downto 4) := unsigned(data(4 downto 0));
            if not vrc4
            then
                ret(8) := '0';
            end if;
        end if;

        return ret;
    end;

    function cycle_write
    (
        reg      : mapper_vrc4_reg_t;
        board    : vrc4_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_vrc4_reg_t
    is
        variable ret : mapper_vrc4_reg_t;
        variable a0 : boolean;
        variable a1 : boolean;
        variable chr_idx : natural range 0 to 7;
    begin
        ret := reg;

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            a0 := not is_zero(cart_in.cpu.prg_bus.address(7 downto 0) and
                              board.a0);
            a1 := not is_zero(cart_in.cpu.prg_bus.address(7 downto 0) and
                              board.a1);

            case cart_in.cpu.prg_bus.address(14 downto 12) is
                when "000" =>
                    ret.prg_bank_0 :=
                        unsigned(cart_in.cpu.data(prg_bank_t'range));
                -- The VRC2 has the mirroring at all four registers, the VRC4
                -- at 0x9000 and 0x9001 and the swap mode at 0x9002 and, as
                -- in Mesen, 0x9003, where the VRC4 has an output that no
                -- Konami board uses
                when "001" =>
                    if not a1 or not board.vrc4
                    then
                        ret.mirror := get_mirror(cart_in.cpu.data, board.vrc4);
                    else
                        ret.prg_swap := cart_in.cpu.data(1) = '1';
                    end if;
                when "010" =>
                    ret.prg_bank_1 :=
                        unsigned(cart_in.cpu.data(prg_bank_t'range));
                -- The IRQ registers. See get_irq_write
                when "111" =>
                -- 0xB000-0xEFFF: two registers for each CHR bank, which
                -- A1 selects
                when others =>
                    chr_idx :=
                        to_integer(cart_in.cpu.prg_bus.address(14 downto 12) &
                                   to_std_logic(a1)) - 6;
                    ret.chr_banks(chr_idx) :=
                        write_chr_bank(reg.chr_banks(chr_idx),
                                       a0,
                                       board.vrc4,
                                       cart_in.cpu.data);
            end case;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_vrc4_reg_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
    begin
        case window is
            -- 0xA000-0xBFFF
            when "01" =>
                return resize(reg.prg_bank_1, prg_bank_8kb_t'length);
            -- 0xE000-0xFFFF is the last bank
            when "11" =>
                return x"FF";
            -- Swap mode swaps 0x8000-0x9FFF and 0xC000-0xDFFF
            when others =>
                if (window(1) = '1') = reg.prg_swap
                then
                    return resize(reg.prg_bank_0, prg_bank_8kb_t'length);
                else
                    -- The second to last bank
                    return x"FE";
                end if;
        end case;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_vrc4_reg_t;
        board  : vrc4_board_t;
        window : chr_window_t
    )
    return chr_bank_1kb_t
    is
        variable bank : chr_bank_t;
    begin
        bank := reg.chr_banks(to_integer(std_logic_vector(window)));

        if board.chr_shift
        then
            return resize(bank(8 downto 1), chr_bank_1kb_t'length);
        else
            return resize(bank, chr_bank_1kb_t'length);
        end if;
    end;

    -- 0xF000-0xF003: the low and high nibbles of the latch, the control
    -- and the acknowledge. The VRC2 has no IRQ registers, so its counter
    -- stays disabled
    function get_irq_write
    (
        board    : vrc4_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return vrc_irq_write_t
    is
        variable a0 : boolean;
        variable a1 : boolean;
    begin
        if board.vrc4 and
           is_rom_write(cart_in.cpu, clk_sync) and
           cart_in.cpu.prg_bus.address(14 downto 12) = "111"
        then
            a0 := not is_zero(cart_in.cpu.prg_bus.address(7 downto 0) and
                              board.a0);
            a1 := not is_zero(cart_in.cpu.prg_bus.address(7 downto 0) and
                              board.a1);

            if not a1
            then
                if a0
                then
                    return VRC_IRQ_LATCH_HIGH;
                else
                    return VRC_IRQ_LATCH_LOW;
                end if;
            elsif not a0
            then
                return VRC_IRQ_CONTROL;
            else
                return VRC_IRQ_ACK;
            end if;
        end if;

        return VRC_IRQ_NO_WRITE;
    end;

    function cycle_mapper_vrc4
    (
        reg      : mapper_vrc4_reg_t;
        board    : vrc4_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_vrc4_out_t
    is
        variable ret : mapper_vrc4_out_t;
        variable banks : cart_banks_t;
    begin
        ret.reg := cycle_write(reg, board, clk_sync, cart_in);
        ret.irq_write := get_irq_write(board, clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle
        banks := default_banks(config);
        banks.prg_ram := true;
        banks.prg := get_prg_bank(ret.reg, get_prg_window(cart_in.cpu));
        banks.chr := get_chr_bank(ret.reg, board, get_chr_window(cart_in.ppu));
        banks.mirror := ret.reg.mirror;

        ret.cart := map_cart(config, cart_in, banks);

        return ret;
    end;

end package body;
