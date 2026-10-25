library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.cart_mem_bus_types.all;
use work.chr_bus_types.all;
use work.chr_ram_bus_types.all;
use work.cart_types.all;

-- Boards built from discrete logic: one or more latches that hold bits of
-- the data the CPU writes, or of the address it writes to, wired to the high
-- address lines of the ROMs and to CIRAM A10. They differ only in where the
-- latches are written, which bits they hold and what those bits are wired
-- to, so each board is a row in a table chosen by the mapper number at run
-- time.
--
-- Each bit of a latch is wired on its own: it is written at one of a few
-- shared address regions with a bit of the data or of the address, or holds
-- a constant. Bits of the same latch can be written at different regions,
-- for a bank number split over two registers
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
        -- 0x8000-0xFFFF, A0 clear and set
        LATCH_ADDR_ROM_EVEN,
        LATCH_ADDR_ROM_ODD,
        -- 0x8000-0xBFFF
        LATCH_ADDR_8000,
        -- 0x8000-0x9FFF
        LATCH_ADDR_8000_9FFF,
        -- 0x9000-0x9FFF
        LATCH_ADDR_9000,
        -- 0xC000-0xFFFF
        LATCH_ADDR_C000,
        -- 0x6000-0x7FFF
        LATCH_ADDR_6000,
        -- 0x4100-0x5FFF with A8 set: 0x4100-0x41FF, 0x4300-0x43FF, ...
        LATCH_ADDR_4100,
        LATCH_ADDR_7FFD,
        LATCH_ADDR_7FFE,
        LATCH_ADDR_7FFF
    );

    -- What a bit of a latch is written with: a constant, a bit of the data
    -- the CPU writes or a bit of the address it writes to
    type latch_src_t is
    (
        SRC_0, SRC_1,
        SRC_D0, SRC_D1, SRC_D2, SRC_D3, SRC_D4, SRC_D5, SRC_D6, SRC_D7,
        SRC_A0, SRC_A1, SRC_A2, SRC_A3, SRC_A4, SRC_A5, SRC_A6, SRC_A7,
        SRC_A8, SRC_A9, SRC_A10, SRC_A11, SRC_A12, SRC_A13, SRC_A14
    );

    type latch_srcs_t is array(natural range <>) of latch_src_t;

    -- A bit of a latch, written at addr with src, inverted when inv. A bit
    -- that is never written (LATCH_ADDR_NONE) holds the constant src. On
    -- reset the latches hold what a write of 0 to 0x8000 would give them
    type latch_bit_t is record
        addr : latch_addr_t;
        src  : latch_src_t;
        inv  : boolean;
    end record;

    type latch_bits_t is array(natural range <>) of latch_bit_t;

    subtype latch_t is latch_bits_t(latch_value_t'range);

    type latch_id_t is
    (
        LATCH_PRG,
        LATCH_CHR_0,
        LATCH_CHR_1,
        LATCH_PRG_MODE,
        LATCH_MIRROR,
        -- CHR is disabled while any bit is set: the PPU reads open bus and
        -- its writes are ignored
        LATCH_CHR_DISABLE,
        -- CHR RAM ignores writes while any bit is set
        LATCH_CHR_PROTECT
    );

    type latches_t is array(latch_id_t) of latch_t;

    type latch_prg_mode_t is
    (
        -- LATCH_PRG selects a 32KB bank at 0x8000
        PRG_32KB,
        -- LATCH_PRG selects a 16KB bank at 0x8000. 0xC000 holds it with the
        -- bits of prg_fixed set: the last bank, or the last of an outer
        -- bank
        PRG_16KB_FIXED_LAST,
        -- LATCH_PRG selects a 16KB bank at 0xC000. 0x8000 holds the first
        -- bank
        PRG_16KB_HIGH_FIXED_FIRST,
        -- LATCH_PRG selects a 16KB bank at 0xC000. 0x8000 holds it with
        -- the bits of prg_fixed set
        PRG_16KB_HIGH_FIXED_LAST,
        -- LATCH_PRG selects a 16KB bank at 0xC000. 0x8000 holds it with
        -- bit 0 clear
        PRG_16KB_HIGH_EVEN_LOW,
        -- LATCH_PRG selects a 16KB bank. When any bit of LATCH_PRG_MODE is
        -- set it is at both 0x8000 and 0xC000, otherwise its bit 0 is
        -- dropped and it selects a 32KB bank at 0x8000
        PRG_16KB_OR_32KB,
        -- Modes of NROM and UNROM, selected by the bits of LATCH_PRG_MODE.
        -- When bit 1 is set LATCH_PRG selects a 16KB bank at both 0x8000
        -- and 0xC000, or with bit 0 set its bit 0 is dropped and it selects
        -- a 32KB bank. When bit 1 is clear LATCH_PRG selects a 16KB bank at
        -- 0x8000, with its bit 0 clear if bit 0 is set. 0xC000 holds the
        -- bank with the bits of prg_fixed set when bit 2 is set, otherwise
        -- with the bits of prg_fixed_clear clear
        PRG_NROM_OR_UNROM
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
        MIRROR_SINGLE,
        -- Fixed until bit 1 of LATCH_MIRROR is set, then single screen
        -- mirroring selected by bit 0
        MIRROR_FIXED_OR_SINGLE,
        -- Bit 0 of LATCH_MIRROR selects horizontal ('0') or vertical ('1')
        -- mirroring
        MIRROR_HV,
        -- Bit 0 of LATCH_MIRROR selects vertical ('0') or horizontal ('1')
        -- mirroring
        MIRROR_VH,
        -- The four nametables are in the last 8KB of CHR RAM, which is
        -- not banked
        MIRROR_CHR_RAM
    );

    type latch_board_t is record
        prg_mode     : latch_prg_mode_t;
        -- The bits of LATCH_PRG set and cleared for the fixed bank of the
        -- PRG modes that have one
        prg_fixed       : latch_value_t;
        prg_fixed_clear : latch_value_t;
        chr_mode     : latch_chr_mode_t;
        mirror_mode  : latch_mirror_mode_t;
        prg_ram      : boolean;
        -- PRG ROM is in 512KB chips, in the four sockets selected by bits
        -- 7-6 of the 8KB bank, and socket 2 is empty: the CPU reads open
        -- bus there. The ROM file holds the chip of socket 3 after those of
        -- sockets 0 and 1
        prg_no_socket_2 : boolean;
        -- CHR is disabled for the first two reads of it after reset
        chr_reads_disable : boolean;
        -- The board can disable CHR or write protect CHR RAM. Set from the
        -- latches, so that the boards that cannot skip the checks
        chr_disable  : boolean;
        chr_protect  : boolean;
        -- Reads at 0x6000-0x7FFF with A4 clear have D7 set, the other bits
        -- are open bus
        d7_6000      : boolean;
        -- Four 4-bit RAMs at 0x5800-0x5803, mirrored up to 0x5FFF. The
        -- high bits read open bus
        nibble_ram   : boolean;
        -- The mask of the CHR RAM address when the header is iNES, which
        -- gives no size. Some boards have more than the default 8KB
        chr_ram_mask : chr_ram_addr_t;
        latches      : latches_t;
    end record;

    -- The mapper number is that of a board in the table
    function is_latch_mapper(mapper_num : mapper_num_t) return boolean;

    -- The row of the table for the board of the ROM file
    function get_latch_board(config : cart_config_t) return latch_board_t;

    -- The mask of the CHR RAM address for the board of an iNES ROM file,
    -- whose header gives no RAM size
    function get_latch_ines_chr_ram_mask
    (
        config : cart_config_t
    )
    return chr_ram_addr_t;

    type latch_regs_t is array(latch_id_t) of latch_value_t;

    subtype latch_chr_reads_t is natural range 0 to 2;

    subtype latch_nibble_t is unsigned(3 downto 0);
    type latch_nibble_ram_t is array(0 to 3) of latch_nibble_t;

    type mapper_latch_reg_t is record
        latches   : latch_regs_t;
        -- Reads of CHR since reset, for chr_reads_disable
        chr_reads : latch_chr_reads_t;
        ram       : latch_nibble_ram_t;
    end record;

    constant RESET_MAPPER_LATCH_REG : mapper_latch_reg_t :=
    (
        latches => (others => (others => '0')),
        chr_reads => 0,
        ram => (others => (others => '0'))
    );

    -- The latches as a write of 0 to 0x8000 leaves them. The bits that are
    -- never written hold their constants
    function get_reset_latch_reg
    (
        board : latch_board_t
    )
    return mapper_latch_reg_t;

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

    -- The masks of the CHR RAM address for boards with more than 8KB
    constant CHR_RAM_16KB_MASK : chr_ram_addr_t := x"3FFF";
    constant CHR_RAM_32KB_MASK : chr_ram_addr_t := x"7FFF";

    -- A bit that is never written, so it always holds 0
    constant BIT_NONE : latch_bit_t :=
    (
        addr => LATCH_ADDR_NONE,
        src => SRC_0,
        inv => false
    );

    -- A latch that is never written
    constant LATCH_NONE : latch_t := (others => BIT_NONE);

    -- The sources of data bits hi downto lo
    function data_bits(hi : natural; lo : natural) return latch_srcs_t
    is
        variable ret : latch_srcs_t(0 to hi - lo);
    begin
        for i in ret'range
        loop
            ret(i) := latch_src_t'val(latch_src_t'pos(SRC_D0) + hi - i);
        end loop;
        return ret;
    end;

    -- The sources of address bits hi downto lo
    function addr_bits(hi : natural; lo : natural) return latch_srcs_t
    is
        variable ret : latch_srcs_t(0 to hi - lo);
    begin
        for i in ret'range
        loop
            ret(i) := latch_src_t'val(latch_src_t'pos(SRC_A0) + hi - i);
        end loop;
        return ret;
    end;

    -- Bits written at addr from srcs, given most significant first. Bits
    -- written at different addresses are concatenated with &
    function bits(addr : latch_addr_t; srcs : latch_srcs_t) return latch_bits_t
    is
        variable s : latch_srcs_t(0 to srcs'length - 1) := srcs;
        variable ret : latch_bits_t(s'range);
    begin
        for i in s'range
        loop
            ret(i) := (addr => addr, src => s(i), inv => false);
        end loop;
        return ret;
    end;

    function bits(addr : latch_addr_t; src : latch_src_t) return latch_bits_t
    is
    begin
        return bits(addr, latch_srcs_t'(0 => src));
    end;

    -- The bits inverted
    function inv(b : latch_bits_t) return latch_bits_t
    is
        variable ret : latch_bits_t(b'range);
    begin
        ret := b;
        for i in ret'range
        loop
            ret(i).inv := not ret(i).inv;
        end loop;
        return ret;
    end;

    -- A latch of the bits, the last at bit 0. The bits above them are 0
    function to_latch(b : latch_bits_t) return latch_t
    is
        variable v : latch_bits_t(0 to b'length - 1) := b;
        variable ret : latch_t;
    begin
        ret := LATCH_NONE;
        for i in v'range
        loop
            ret(v'high - i) := v(i);
        end loop;
        return ret;
    end;

    function latch(addr : latch_addr_t; srcs : latch_srcs_t) return latch_t
    is
    begin
        return to_latch(bits(addr, srcs));
    end;

    function latch(addr : latch_addr_t; src : latch_src_t) return latch_t
    is
    begin
        return to_latch(bits(addr, src));
    end;

    -- A latch of data bits hi downto lo, written at addr
    function latch
    (
        addr : latch_addr_t;
        hi   : natural;
        lo   : natural
    )
    return latch_t
    is
    begin
        return latch(addr, data_bits(hi, lo));
    end;

    -- Latches written at 0x8000-0xFFFF
    function rom_latch(srcs : latch_srcs_t) return latch_t
    is
    begin
        return latch(LATCH_ADDR_ROM, srcs);
    end;

    function rom_latch(src : latch_src_t) return latch_t
    is
    begin
        return latch(LATCH_ADDR_ROM, src);
    end;

    function rom_latch(hi : natural; lo : natural) return latch_t
    is
    begin
        return latch(LATCH_ADDR_ROM, hi, lo);
    end;

    -- A latch of address bits hi downto lo, written at 0x8000-0xFFFF
    function rom_addr_latch(hi : natural; lo : natural) return latch_t
    is
    begin
        return rom_latch(addr_bits(hi, lo));
    end;

    -- A latch whose bit 0 is always set
    constant LATCH_ONE : latch_t := to_latch(bits(LATCH_ADDR_NONE, SRC_1));

    function is_latch_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"000" | x"002" | x"003" | x"007" | x"00B" | x"00D" |
                 x"01E" | x"022" | x"03A" | x"03D" | x"03E" | x"042" |
                 x"046" | x"047" | x"04E" | x"04F" | x"057" | x"059" |
                 x"05D" | x"05E" | x"061" | x"065" | x"08C" | x"092" |
                 x"098" | x"0B4" | x"0B8" | x"0B9" | x"0C8" | x"0C9" |
                 x"0CA" | x"0CB" | x"0D4" | x"0D5" | x"0D6" | x"0E1" |
                 x"0E2" | x"0E3" | x"0E4" | x"0E7" | x"0E8" | x"0F2" |
                 x"0FF" => return true;
            when others => return false;
        end case;
    end;

    function get_latch_board(config : cart_config_t) return latch_board_t
    is
        variable ret : latch_board_t;
        variable addr : latch_addr_t;
        variable no_submapper : boolean;
    begin
        ret.prg_mode := PRG_32KB;
        ret.prg_fixed := (others => '1');
        ret.prg_fixed_clear := (others => '0');
        ret.chr_mode := CHR_8KB;
        ret.mirror_mode := MIRROR_FIXED;
        ret.prg_ram := false;
        ret.prg_no_socket_2 := false;
        ret.chr_reads_disable := false;
        ret.d7_6000 := false;
        ret.nibble_ram := false;
        ret.chr_ram_mask := DEFAULT_RAM_MASK;
        ret.latches := (others => LATCH_NONE);

        -- Before submappers, the four-screen bit of the header marked the
        -- variant of a few boards
        no_submapper := config.submapper_num = x"0";

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
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_D4);
            -- Color Dreams
            when x"00B" =>
                ret.latches(LATCH_PRG) := rom_latch(1, 0);
                ret.latches(LATCH_CHR_0) := rom_latch(7, 4);
            -- CPROM: the first 4KB of CHR RAM is fixed at 0x0000
            when x"00D" =>
                ret.chr_mode := CHR_4KB;
                ret.chr_ram_mask := CHR_RAM_16KB_MASK;
                ret.latches(LATCH_CHR_1) := rom_latch(1, 0);
            -- UNROM 512. Without the battery bit (flash), submapper 0 has
            -- bus conflicts, like submapper 2, so the latch is written at
            -- any ROM address. The flash boards and submappers 1, 3 and 4
            -- write it at 0xC000-0xFFFF: the flash commands of the first
            -- two and the LEDs of submapper 4, none of which are emulated,
            -- are at 0x8000-0xBFFF
            when x"01E" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.chr_ram_mask := CHR_RAM_32KB_MASK;
                if (config.submapper_num = x"0" and not config.battery) or
                   config.submapper_num = x"2"
                then
                    addr := LATCH_ADDR_ROM;
                else
                    addr := LATCH_ADDR_C000;
                end if;
                ret.latches(LATCH_PRG) := latch(addr, 4, 0);
                ret.latches(LATCH_CHR_0) := latch(addr, 6, 5);
                ret.latches(LATCH_MIRROR) := latch(addr, SRC_D7);

                -- Submapper 3 switches between horizontal and vertical
                -- mirroring. The others use bits 3 and 0 of byte 6 of the
                -- header: 1 and 0 for switchable single screen mirroring,
                -- 1 and 1 for nametables in CHR RAM. Otherwise mirroring is
                -- fixed and bit 7 of the latch is not connected
                if config.submapper_num = x"3"
                then
                    ret.mirror_mode := MIRROR_HV;
                elsif config.mirror_pads = "10"
                then
                    ret.mirror_mode := MIRROR_SINGLE;
                elsif config.mirror_pads = "11"
                then
                    ret.mirror_mode := MIRROR_CHR_RAM;
                end if;
            -- BNROM (submapper 2) and NINA-001 (submapper 1). Without a
            -- submapper, only NINA-001 has more than 8KB of CHR ROM
            when x"022" =>
                if config.submapper_num = x"1" or
                   (config.submapper_num = x"0" and
                    config.chr_rom_8kb_blocks > 1)
                then
                    ret.chr_mode := CHR_4KB;
                    ret.prg_ram := true;
                    ret.latches(LATCH_PRG) := latch(LATCH_ADDR_7FFD, SRC_D0);
                    ret.latches(LATCH_CHR_0) := latch(LATCH_ADDR_7FFE, 3, 0);
                    ret.latches(LATCH_CHR_1) := latch(LATCH_ADDR_7FFF, 3, 0);
                else
                    ret.latches(LATCH_PRG) := rom_latch(7, 0);
                end if;
            -- NROM-128/256 multicarts (58, and its duplicate 213)
            when x"03A" | x"0D5" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.latches(LATCH_PRG) := rom_addr_latch(2, 0);
                ret.latches(LATCH_PRG_MODE) := rom_latch(SRC_A6);
                ret.latches(LATCH_CHR_0) := rom_addr_latch(5, 3);
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A7);
            -- NTDEC 0324, BS-N032 (submapper 1) and GS-2017 (CHR RAM)
            -- multicarts
            when x"03D" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.latches(LATCH_PRG) := rom_latch(addr_bits(3, 0) & SRC_A5);
                ret.latches(LATCH_PRG_MODE) := rom_latch(SRC_A4);
                if config.submapper_num = x"1"
                then
                    ret.latches(LATCH_CHR_0) :=
                        rom_latch(addr_bits(11, 8) & SRC_A6);
                else
                    ret.latches(LATCH_CHR_0) := rom_addr_latch(11, 8);
                end if;
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A7);
            -- Super 700-in-1
            when x"03E" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.latches(LATCH_PRG) :=
                    rom_latch(SRC_A6 & addr_bits(13, 8));
                ret.latches(LATCH_PRG_MODE) := rom_latch(SRC_A5);
                ret.latches(LATCH_CHR_0) :=
                    rom_latch(addr_bits(4, 0) & data_bits(1, 0));
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A7);
            -- GxROM
            when x"042" =>
                ret.latches(LATCH_PRG) := rom_latch(5, 4);
                ret.latches(LATCH_CHR_0) := rom_latch(1, 0);
            -- Bandai (70), and Bandai with single screen mirroring (152),
            -- which was marked by the four-screen bit before it had a
            -- number of its own
            when x"046" | x"098" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.latches(LATCH_CHR_0) := rom_latch(3, 0);
                if config.mapper_num = x"098" or
                   (no_submapper and config.mirror_pads(1) = '1')
                then
                    ret.mirror_mode := MIRROR_SINGLE;
                    ret.latches(LATCH_PRG) := rom_latch(6, 4);
                    ret.latches(LATCH_MIRROR) := rom_latch(SRC_D7);
                else
                    ret.latches(LATCH_PRG) := rom_latch(7, 4);
                end if;
            -- Camerica/Codemasters. The bank is written at 0xC000-0xFFFF.
            -- Fire Hawk (submapper 1) selects single screen mirroring at
            -- 0x8000-0x9FFF. Without a submapper the mirroring is fixed
            -- until 0x9000-0x9FFF is written, which only Fire Hawk does:
            -- others write 0x8000 at startup
            when x"047" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.latches(LATCH_PRG) := latch(LATCH_ADDR_C000, 3, 0);
                if config.submapper_num = x"1"
                then
                    ret.mirror_mode := MIRROR_SINGLE;
                    ret.latches(LATCH_MIRROR) :=
                        latch(LATCH_ADDR_8000_9FFF, SRC_D4);
                else
                    ret.mirror_mode := MIRROR_FIXED_OR_SINGLE;
                    ret.latches(LATCH_MIRROR) :=
                        latch(LATCH_ADDR_9000, SRC_1 & SRC_D4);
                end if;
            -- Holy Diver (submapper 3) and Uchuusen - Cosmo Carrier
            -- (submapper 1). Bit 3 selects horizontal or vertical
            -- mirroring on the first and the nametable on the second.
            -- Without a submapper, the four-screen bit marks Holy Diver
            when x"04E" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.latches(LATCH_PRG) := rom_latch(2, 0);
                ret.latches(LATCH_CHR_0) := rom_latch(7, 4);
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_D3);
                if config.submapper_num = x"3" or
                   (no_submapper and config.mirror_pads(1) = '1')
                then
                    ret.mirror_mode := MIRROR_HV;
                else
                    ret.mirror_mode := MIRROR_SINGLE;
                end if;
            -- NINA-03/06 (79) and Sachen 3015 (146)
            when x"04F" | x"092" =>
                ret.latches(LATCH_PRG) := latch(LATCH_ADDR_4100, SRC_D3);
                ret.latches(LATCH_CHR_0) := latch(LATCH_ADDR_4100, 2, 0);
            -- J87: the CHR bank has its bits swapped
            when x"057" =>
                ret.latches(LATCH_CHR_0) :=
                    latch(LATCH_ADDR_6000, SRC_D0 & SRC_D1);
            -- Sunsoft-2 on the Sunsoft-3 board
            when x"059" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.mirror_mode := MIRROR_SINGLE;
                ret.latches(LATCH_PRG) := rom_latch(6, 4);
                ret.latches(LATCH_CHR_0) := rom_latch(SRC_D7 & data_bits(2, 0));
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_D3);
            -- Sunsoft-2 on the Sunsoft-3R board. Bit 0 clear disables CHR
            -- RAM
            when x"05D" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.latches(LATCH_PRG) := rom_latch(6, 4);
                ret.latches(LATCH_CHR_DISABLE) :=
                    to_latch(inv(bits(LATCH_ADDR_ROM, SRC_D0)));
            -- UN1ROM
            when x"05E" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.latches(LATCH_PRG) := rom_latch(4, 2);
            -- Irem TAM-S1
            when x"061" =>
                ret.prg_mode := PRG_16KB_HIGH_FIXED_LAST;
                ret.mirror_mode := MIRROR_HV;
                ret.latches(LATCH_PRG) := latch(LATCH_ADDR_8000, 4, 0);
                ret.latches(LATCH_MIRROR) := latch(LATCH_ADDR_8000, SRC_D7);
            -- J87 dumped with the CHR bits in order
            when x"065" =>
                ret.latches(LATCH_CHR_0) := latch(LATCH_ADDR_6000, 7, 0);
            -- Jaleco JF-11/JF-14
            when x"08C" =>
                ret.latches(LATCH_PRG) := latch(LATCH_ADDR_6000, 5, 4);
                ret.latches(LATCH_CHR_0) := latch(LATCH_ADDR_6000, 3, 0);
            -- UNROM with the first bank fixed
            when x"0B4" =>
                ret.prg_mode := PRG_16KB_HIGH_FIXED_FIRST;
                ret.latches(LATCH_PRG) := rom_latch(2, 0);
            -- Sunsoft-1: the high bit of the bank at 0x1000 is always set
            when x"0B8" =>
                ret.chr_mode := CHR_4KB;
                ret.latches(LATCH_CHR_0) := latch(LATCH_ADDR_6000, 2, 0);
                ret.latches(LATCH_CHR_1) :=
                    to_latch(bits(LATCH_ADDR_NONE, SRC_1) &
                             bits(LATCH_ADDR_6000, data_bits(5, 4)));
            -- CNROM with copy protection: CHR ROM is enabled only when bits
            -- 1-0 match the value given by submappers 4-7. Otherwise
            -- CHR ROM is disabled for the first two reads after reset,
            -- which works with all known games
            when x"0B9" =>
                case config.submapper_num is
                    when x"4" =>
                        ret.latches(LATCH_CHR_DISABLE) :=
                            rom_latch(data_bits(1, 0));
                    when x"5" =>
                        ret.latches(LATCH_CHR_DISABLE) :=
                            to_latch(bits(LATCH_ADDR_ROM, SRC_D1) &
                                     inv(bits(LATCH_ADDR_ROM, SRC_D0)));
                    when x"6" =>
                        ret.latches(LATCH_CHR_DISABLE) :=
                            to_latch(inv(bits(LATCH_ADDR_ROM, SRC_D1)) &
                                     bits(LATCH_ADDR_ROM, SRC_D0));
                    when x"7" =>
                        ret.latches(LATCH_CHR_DISABLE) :=
                            to_latch(inv(bits(LATCH_ADDR_ROM,
                                              data_bits(1, 0))));
                    when others =>
                        ret.chr_reads_disable := true;
                end case;
            -- NROM-128 multicarts. Submapper 1 has one bank bit fewer
            when x"0C8" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.latches(LATCH_PRG_MODE) := LATCH_ONE;
                if config.submapper_num = x"1"
                then
                    ret.latches(LATCH_PRG) := rom_addr_latch(2, 0);
                    ret.latches(LATCH_CHR_0) := rom_addr_latch(2, 0);
                    ret.latches(LATCH_MIRROR) := rom_latch(SRC_A2);
                else
                    ret.latches(LATCH_PRG) := rom_addr_latch(3, 0);
                    ret.latches(LATCH_CHR_0) := rom_addr_latch(3, 0);
                    ret.latches(LATCH_MIRROR) := rom_latch(SRC_A3);
                end if;
            -- NROM-256 multicarts
            when x"0C9" =>
                ret.latches(LATCH_PRG) := rom_addr_latch(7, 0);
                ret.latches(LATCH_CHR_0) := rom_addr_latch(7, 0);
            -- 150-in-1: 32KB banks only when A3 and A0 are both set
            when x"0CA" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.latches(LATCH_PRG) := rom_addr_latch(3, 1);
                ret.latches(LATCH_PRG_MODE) :=
                    to_latch(inv(bits(LATCH_ADDR_ROM, SRC_A3 & SRC_A0)));
                ret.latches(LATCH_CHR_0) := rom_addr_latch(3, 1);
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A0);
            -- 35-in-1
            when x"0CB" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.latches(LATCH_PRG) := rom_latch(7, 2);
                ret.latches(LATCH_PRG_MODE) := LATCH_ONE;
                ret.latches(LATCH_CHR_0) := rom_latch(1, 0);
            -- Super HiK 300-in-1
            when x"0D4" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.d7_6000 := true;
                ret.latches(LATCH_PRG) := rom_addr_latch(2, 0);
                ret.latches(LATCH_PRG_MODE) :=
                    to_latch(inv(bits(LATCH_ADDR_ROM, SRC_A14)));
                ret.latches(LATCH_CHR_0) := rom_addr_latch(2, 0);
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A3);
            -- Super Gun 20-in-1
            when x"0D6" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.latches(LATCH_PRG) := rom_addr_latch(3, 2);
                ret.latches(LATCH_PRG_MODE) := LATCH_ONE;
                ret.latches(LATCH_CHR_0) := rom_addr_latch(1, 0);
            -- ET-4310 and K-1010 multicarts (225, and its duplicate 255).
            -- A14 is the high bit of both banks
            when x"0E1" | x"0FF" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.nibble_ram := true;
                ret.latches(LATCH_PRG) :=
                    rom_latch(SRC_A14 & addr_bits(11, 6));
                ret.latches(LATCH_PRG_MODE) := rom_latch(SRC_A12);
                ret.latches(LATCH_CHR_0) :=
                    rom_latch(SRC_A14 & addr_bits(5, 0));
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A13);
            -- 42-in-1 and 76-in-1: registers at even and odd addresses
            when x"0E2" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_HV;
                ret.latches(LATCH_PRG) :=
                    to_latch(bits(LATCH_ADDR_ROM_ODD, SRC_D0) &
                             bits(LATCH_ADDR_ROM_EVEN,
                                  SRC_D7 & data_bits(4, 0)));
                ret.latches(LATCH_PRG_MODE) :=
                    latch(LATCH_ADDR_ROM_EVEN, SRC_D5);
                ret.latches(LATCH_MIRROR) := latch(LATCH_ADDR_ROM_EVEN, SRC_D6);
                ret.latches(LATCH_CHR_PROTECT) :=
                    latch(LATCH_ADDR_ROM_ODD, SRC_D1);
            -- 810449-C-A1 (227) and 43272 (242) multicarts: NROM and UNROM
            -- modes, with CHR RAM write protected in the NROM modes. The
            -- variants used by Chinese RPGs have battery-backed PRG RAM and
            -- only the NROM modes. The solder pads that replace the low
            -- address lines of PRG ROM, and the second PRG ROM chip of
            -- 640KB 242 boards, are not emulated
            when x"0E3" | x"0F2" =>
                ret.prg_mode := PRG_NROM_OR_UNROM;
                ret.mirror_mode := MIRROR_VH;
                ret.prg_fixed := x"07";
                ret.prg_fixed_clear := x"07";
                if config.mapper_num = x"0E3"
                then
                    ret.latches(LATCH_PRG) :=
                        rom_latch(SRC_A8 & addr_bits(6, 2));
                    -- Clearing the inner bank also clears the outer bank
                    -- below A19
                    if config.submapper_num = x"2"
                    then
                        ret.prg_fixed_clear := x"1F";
                    end if;
                else
                    ret.latches(LATCH_PRG) := rom_addr_latch(6, 2);
                end if;
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A1);
                if config.battery
                then
                    ret.prg_ram := true;
                    ret.latches(LATCH_PRG_MODE) :=
                        to_latch(bits(LATCH_ADDR_NONE, SRC_1) &
                                 bits(LATCH_ADDR_ROM, SRC_A0));
                else
                    ret.latches(LATCH_PRG_MODE) :=
                        rom_latch(SRC_A9 & SRC_A7 & SRC_A0);
                    ret.latches(LATCH_CHR_PROTECT) := rom_latch(SRC_A7);
                end if;
            -- Action 52 and Cheetah Men II. The latch holds most of the
            -- address written and two bits of the data. Action 52 has three
            -- 512KB chips of PRG ROM
            when x"0E4" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.prg_no_socket_2 := config.prg_rom_16kb_blocks = 96;
                ret.latches(LATCH_PRG) := rom_addr_latch(12, 6);
                ret.latches(LATCH_PRG_MODE) := rom_latch(SRC_A5);
                ret.latches(LATCH_CHR_0) :=
                    rom_latch(addr_bits(3, 0) & data_bits(1, 0));
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A13);
            -- 20-in-1
            when x"0E7" =>
                ret.prg_mode := PRG_16KB_HIGH_EVEN_LOW;
                ret.mirror_mode := MIRROR_VH;
                ret.latches(LATCH_PRG) := rom_latch(addr_bits(4, 1) & SRC_A5);
                ret.latches(LATCH_MIRROR) := rom_latch(SRC_A7);
            -- Camerica Quattro: a 64KB outer bank written at 0x8000-0xBFFF,
            -- whose bits are swapped on the Aladdin Deck Enhancer
            -- (submapper 1), and a 16KB inner bank at 0xC000-0xFFFF
            when x"0E8" =>
                ret.prg_mode := PRG_16KB_FIXED_LAST;
                ret.prg_fixed := x"03";
                if config.submapper_num = x"1"
                then
                    ret.latches(LATCH_PRG) :=
                        to_latch(bits(LATCH_ADDR_8000, SRC_D3 & SRC_D4) &
                                 bits(LATCH_ADDR_C000, data_bits(1, 0)));
                else
                    ret.latches(LATCH_PRG) :=
                        to_latch(bits(LATCH_ADDR_8000, data_bits(4, 3)) &
                                 bits(LATCH_ADDR_C000, data_bits(1, 0)));
                end if;
            when others =>
        end case;

        ret.chr_disable := ret.chr_reads_disable or
                           ret.latches(LATCH_CHR_DISABLE) /= LATCH_NONE;
        ret.chr_protect := ret.latches(LATCH_CHR_PROTECT) /= LATCH_NONE;

        return ret;
    end;

    function get_latch_ines_chr_ram_mask
    (
        config : cart_config_t
    )
    return chr_ram_addr_t
    is
    begin
        return get_latch_board(config).chr_ram_mask;
    end;

    function get_reset_latch_reg
    (
        board : latch_board_t
    )
    return mapper_latch_reg_t
    is
        variable ret : mapper_latch_reg_t;
        variable wiring : latch_bit_t;
    begin
        ret := RESET_MAPPER_LATCH_REG;
        for i in latch_id_t
        loop
            for b in latch_value_t'range
            loop
                wiring := board.latches(i)(b);
                ret.latches(i)(b) :=
                    to_std_logic((wiring.addr = LATCH_ADDR_NONE and
                                  wiring.src = SRC_1) xor wiring.inv);
            end loop;
        end loop;
        return ret;
    end;

    type latch_addrs_active_t is array(latch_addr_t) of boolean;

    -- The latch addresses the CPU accesses
    function get_latch_addrs(cpu_in : cart_cpu_in_t) return latch_addrs_active_t
    is
        variable ret : latch_addrs_active_t;
        variable addr : prg_addr_t;
    begin
        addr := cpu_in.prg_bus.address;

        ret(LATCH_ADDR_NONE) := false;
        ret(LATCH_ADDR_ROM) := cpu_in.romsel;
        ret(LATCH_ADDR_ROM_EVEN) := cpu_in.romsel and addr(0) = '0';
        ret(LATCH_ADDR_ROM_ODD) := cpu_in.romsel and addr(0) = '1';
        ret(LATCH_ADDR_8000) := cpu_in.romsel and addr(14) = '0';
        ret(LATCH_ADDR_8000_9FFF) :=
            cpu_in.romsel and addr(14 downto 13) = "00";
        ret(LATCH_ADDR_9000) := cpu_in.romsel and addr(14 downto 12) = "001";
        ret(LATCH_ADDR_C000) := cpu_in.romsel and addr(14) = '1';
        ret(LATCH_ADDR_6000) := is_prg_ram_window(cpu_in);
        ret(LATCH_ADDR_4100) := not cpu_in.romsel and
                                addr(14 downto 13) = "10" and addr(8) = '1';
        ret(LATCH_ADDR_7FFD) := is_low_addr(cpu_in, "111" & x"FFD");
        ret(LATCH_ADDR_7FFE) := is_low_addr(cpu_in, "111" & x"FFE");
        ret(LATCH_ADDR_7FFF) := is_low_addr(cpu_in, "111" & x"FFF");

        return ret;
    end;

    type latch_src_values_t is array(latch_src_t) of std_logic;

    -- The value of each source of a latch bit for a CPU write
    function get_latch_srcs(cpu_in : cart_cpu_in_t) return latch_src_values_t
    is
        variable ret : latch_src_values_t;
    begin
        ret(SRC_0) := '0';
        ret(SRC_1) := '1';
        for i in data_t'range
        loop
            ret(latch_src_t'val(latch_src_t'pos(SRC_D0) + i)) :=
                cpu_in.data(i);
        end loop;
        for i in 0 to 14
        loop
            ret(latch_src_t'val(latch_src_t'pos(SRC_A0) + i)) :=
                cpu_in.prg_bus.address(i);
        end loop;
        return ret;
    end;

    -- The latches with the bits the CPU writes this cycle
    function write_latches
    (
        regs   : latch_regs_t;
        board  : latch_board_t;
        cpu_in : cart_cpu_in_t
    )
    return latch_regs_t
    is
        variable ret : latch_regs_t;
        variable addrs : latch_addrs_active_t;
        variable srcs : latch_src_values_t;
        variable wiring : latch_bit_t;
    begin
        ret := regs;
        addrs := get_latch_addrs(cpu_in);
        srcs := get_latch_srcs(cpu_in);

        for i in latch_id_t
        loop
            for b in latch_value_t'range
            loop
                wiring := board.latches(i)(b);
                if addrs(wiring.addr)
                then
                    ret(i)(b) := srcs(wiring.src) xor to_std_logic(wiring.inv);
                end if;
            end loop;
        end loop;

        return ret;
    end;

    -- The value with the bits of mask set or cleared. Loops, since the
    -- logical operators of numeric_std are slow to simulate
    function set_bits(value : latch_value_t; mask : latch_value_t)
    return latch_value_t
    is
        variable ret : latch_value_t;
    begin
        ret := value;
        for i in ret'range
        loop
            if mask(i) = '1'
            then
                ret(i) := '1';
            end if;
        end loop;
        return ret;
    end;

    function clear_bits(value : latch_value_t; mask : latch_value_t)
    return latch_value_t
    is
        variable ret : latch_value_t;
    begin
        ret := value;
        for i in ret'range
        loop
            if mask(i) = '1'
            then
                ret(i) := '0';
            end if;
        end loop;
        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        regs   : latch_regs_t;
        board  : latch_board_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable bank : latch_value_t;
        variable mode : latch_value_t;
    begin
        bank := regs(LATCH_PRG);
        mode := regs(LATCH_PRG_MODE);

        case board.prg_mode is
            when PRG_32KB =>
                return resize(bank & window, prg_bank_8kb_t'length);
            when PRG_16KB_FIXED_LAST =>
                if window(1) = '1'
                then
                    bank := set_bits(bank, board.prg_fixed);
                end if;
            when PRG_16KB_HIGH_FIXED_FIRST =>
                if window(1) = '0'
                then
                    bank := (others => '0');
                end if;
            when PRG_16KB_HIGH_FIXED_LAST =>
                if window(1) = '0'
                then
                    bank := set_bits(bank, board.prg_fixed);
                end if;
            when PRG_16KB_HIGH_EVEN_LOW =>
                bank(0) := bank(0) and window(1);
            when PRG_16KB_OR_32KB =>
                if is_zero(mode)
                then
                    bank(0) := window(1);
                end if;
            when PRG_NROM_OR_UNROM =>
                if mode(1) = '1'
                then
                    if mode(0) = '1'
                    then
                        bank(0) := window(1);
                    end if;
                elsif window(1) = '0'
                then
                    bank(0) := bank(0) and not mode(0);
                elsif mode(2) = '1'
                then
                    bank := set_bits(bank, board.prg_fixed);
                else
                    bank := clear_bits(bank, board.prg_fixed_clear);
                end if;
        end case;

        return resize(bank & window(0), prg_bank_8kb_t'length);
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        regs   : latch_regs_t;
        mode   : latch_chr_mode_t;
        window : chr_window_t
    )
    return chr_bank_1kb_t
    is
        variable bank : latch_value_t;
    begin
        case mode is
            when CHR_8KB =>
                return resize(regs(LATCH_CHR_0) & window,
                              chr_bank_1kb_t'length);
            when CHR_4KB =>
                if window(2) = '0'
                then
                    bank := regs(LATCH_CHR_0);
                else
                    bank := regs(LATCH_CHR_1);
                end if;
                return resize(bank & window(1 downto 0),
                              chr_bank_1kb_t'length);
        end case;
    end;

    function get_mirror
    (
        regs   : latch_regs_t;
        mode   : latch_mirror_mode_t;
        config : cart_config_t
    )
    return mirror_t
    is
        variable reg : latch_value_t;
    begin
        reg := regs(LATCH_MIRROR);

        case mode is
            when MIRROR_FIXED | MIRROR_CHR_RAM =>
                return config.mirror;
            when MIRROR_SINGLE =>
                return get_single_screen_mirror(reg(0));
            when MIRROR_FIXED_OR_SINGLE =>
                if reg(1) = '1'
                then
                    return get_single_screen_mirror(reg(0));
                else
                    return config.mirror;
                end if;
            when MIRROR_HV =>
                return get_hv_mirror(not reg(0));
            when MIRROR_VH =>
                return get_hv_mirror(reg(0));
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
        variable chr_window : chr_window_t;
        variable prg_open_bus : boolean;
        variable chr_access : boolean;
        variable chr_disabled : boolean;
        variable cpu_addr : prg_addr_t;
        variable ram_addr : natural range latch_nibble_ram_t'range;
    begin
        ret.reg := reg;
        banks := default_banks(config);
        cpu_addr := cart_in.cpu.prg_bus.address;

        if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
        then
            ret.reg.latches := write_latches(reg.latches, board, cart_in.cpu);
        end if;

        -- The PPU sees the latches written by the CPU this cycle
        banks.prg := get_prg_bank(ret.reg.latches, board,
                                  get_prg_window(cart_in.cpu));

        -- The ROM file holds the chip of socket 3 where that of the empty
        -- socket 2 would be
        prg_open_bus := false;
        if board.prg_no_socket_2
        then
            case banks.prg(7 downto 6) is
                when "10" => prg_open_bus := true;
                when "11" => banks.prg(6) := '0';
                when others =>
            end case;
        end if;

        chr_window := get_chr_window(cart_in.ppu);
        if board.mirror_mode = MIRROR_CHR_RAM and
           cart_in.ppu.chr_bus.address(13) = '1'
        then
            banks.nt_chr := true;
            banks.chr := resize("11" & chr_window, chr_bank_1kb_t'length);
        else
            banks.chr := get_chr_bank(ret.reg.latches, board.chr_mode,
                                      chr_window);
        end if;

        banks.mirror := get_mirror(ret.reg.latches, board.mirror_mode, config);

        banks.prg_ram := board.prg_ram;

        ret.cart := map_cart(config, cart_in, banks);

        if prg_open_bus and cart_in.cpu.romsel
        then
            ret.cart.cpu := CART_CPU_OUT_IDLE;
            ret.cart.mem.prg_rom_bus := CART_MEM_BUS_IDLE;
        end if;

        if board.d7_6000 and
           is_bus_read(cart_in.cpu.prg_bus) and
           is_prg_ram_window(cart_in.cpu) and
           cpu_addr(4) = '0'
        then
            ret.cart.cpu.data := x"80";
            ret.cart.cpu.data_oe := true;
            ret.cart.cpu.data_float := x"7F";
        end if;

        if board.nibble_ram and
           not cart_in.cpu.romsel and
           cpu_addr(14 downto 11) = "1011"
        then
            ram_addr := to_integer(unsigned(cpu_addr(1 downto 0)));
            if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
            then
                ret.reg.ram(ram_addr) := unsigned(cart_in.cpu.data(3 downto 0));
            elsif is_bus_read(cart_in.cpu.prg_bus)
            then
                ret.cart.cpu.data :=
                    "0000" & std_logic_vector(reg.ram(ram_addr));
                ret.cart.cpu.data_oe := true;
                ret.cart.cpu.data_float := x"F0";
            end if;
        end if;

        -- A disabled CHR chip leaves the bus to the low byte of the
        -- address, which the PPU leaves on it, with D0 pulled up
        if board.chr_disable
        then
            chr_access := is_bus_active(cart_in.ppu.chr_bus) and
                          cart_in.ppu.chr_bus.address(13) = '0';
            chr_disabled :=
                not is_zero(ret.reg.latches(LATCH_CHR_DISABLE)) or
                (board.chr_reads_disable and reg.chr_reads < 2);
            if chr_access and chr_disabled
            then
                ret.cart.mem.chr_rom_bus := CART_MEM_BUS_IDLE;
                ret.cart.mem.chr_ram_bus := CHR_RAM_BUS_IDLE;
                ret.cart.ppu.data :=
                    cart_in.ppu.chr_bus.address(data_t'range) or x"01";
                ret.cart.ppu.data_oe := true;
            end if;

            if chr_access and cart_in.ppu.ale and
               is_bus_read(cart_in.ppu.chr_bus) and
               reg.chr_reads < latch_chr_reads_t'high
            then
                ret.reg.chr_reads := reg.chr_reads + 1;
            end if;
        end if;

        if board.chr_protect and
           not is_zero(ret.reg.latches(LATCH_CHR_PROTECT))
        then
            ret.cart.mem.chr_ram_bus.write := false;
        end if;

        return ret;
    end;

end package body;
