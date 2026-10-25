library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.prg_ram_bus_types.all;
use work.chip_ram_bus_types.all;
use work.cart_types.all;
use work.lib_n163_audio.all;

-- Boards built around the Namco 163 (19) and the Namco 175 and 340 (210),
-- which are cut-down versions of it. Each register takes 0x800 bytes of the
-- address space. All three have three 8KB PRG ROM banks at 0x8000-0xDFFF
-- (0xE000-0xF7FF), the last bank fixed at 0xE000, and eight 1KB CHR ROM
-- banks (0x8000-0xBFFF).
--
-- The 163 maps the nametables in 1KB pages too (0xC000-0xDFFF), where pages
-- 0xE0-0xFF are the pages of CIRAM, which can also be mapped to the pattern
-- tables as CHR RAM unless 0xE800 makes them CHR ROM. It has 128 bytes of
-- RAM inside the chip, accessed through 0xF800 (address) and 0x4800 (data),
-- which hold the registers and waveforms of its audio, a 15-bit counter of
-- CPU cycles at 0x5000-0x5FFF that raises an IRQ, and write protection of
-- the PRG RAM in 2KB windows at 0xF800. The 175 has an enable for its PRG
-- RAM at 0xC000 and the mirroring of the header. The 340 has no PRG RAM and
-- the mirroring at 0xE000.
--
-- A header that does not say which chip the board has (iNES, or NES 2.0
-- mapper 210 submapper 0) gets the chip told from the registers the game
-- writes, as in Mesen: many 210 games are given mapper 19 in iNES headers
package lib_mapper_n163 is

    type n163_chip_t is
    (
        NAMCO_163,
        NAMCO_175,
        NAMCO_340,
        -- Not yet told apart. Neither the PRG RAM nor the registers of the
        -- 163 are there, and the mirroring is that of the header
        NAMCO_UNKNOWN
    );

    type n163_board_t is record
        -- The chip at reset
        chip   : n163_chip_t;
        -- The chip is told from the registers the game writes
        detect : boolean;
        -- The mirroring of the header, which the nametable pages give at
        -- reset
        mirror : mirror_t;
    end record;

    -- The mapper number is that of a board built around one of the chips
    function is_n163_mapper(mapper_num : mapper_num_t) return boolean;

    function get_n163_board(config : cart_config_t) return n163_board_t;

    subtype prg_bank_t is unsigned(5 downto 0);
    -- The banks at 0x8000, 0xA000 and 0xC000
    type prg_bank_arr_t is array(0 to 2) of prg_bank_t;

    -- The 1KB pages of the pattern tables (0-7) and nametables (8-11)
    type chr_reg_arr_t is array(0 to 11) of data_t;

    subtype chip_ram_idx_t is natural range 0 to 2**chip_ram_addr_t'length-1;

    -- The IRQ counter, with the enable in bit 15
    subtype irq_count_t is natural range 0 to 2**16-1;

    type mapper_n163_reg_t is record
        chip           : n163_chip_t;
        -- The game wrote to 0x6000-0x7FFF, where the 340 has nothing, so
        -- the chip is not told to be the 340
        not_340        : boolean;

        prg_banks      : prg_bank_arr_t;
        chr_regs       : chr_reg_arr_t;
        -- 0xE800 bits 6 and 7: pages 0xE0-0xFF at 0x0000 and 0x1000 are CHR
        -- ROM rather than CIRAM
        chr_rom_low    : boolean;
        chr_rom_high   : boolean;
        -- The mirroring of the 340
        mirror         : mirror_t;
        -- 0xF800 on the 163. On the 175, 0xC000, whose bit 0 enables the
        -- PRG RAM
        prg_ram_protect : data_t;

        -- The address of the chip RAM accessed through 0x4800, which is
        -- incremented after each access when ram_increment is set
        ram_addr       : chip_ram_idx_t;
        ram_increment  : boolean;

        irq_count      : irq_count_t;
        irq            : boolean;

        audio          : n163_audio_t;
    end record;

    -- The registers as they are at reset. The nametables are in the pages
    -- of CIRAM that give the mirroring of the header
    function get_reset_n163_reg(board : n163_board_t) return mapper_n163_reg_t;

    constant RESET_MAPPER_N163_REG : mapper_n163_reg_t :=
    (
        chip => NAMCO_163,
        not_340 => false,

        prg_banks => (others => (others => '0')),
        chr_regs => (others => (others => '0')),
        chr_rom_low => false,
        chr_rom_high => false,
        mirror => MIRROR_HORZ,
        prg_ram_protect => (others => '0'),

        ram_addr => 0,
        ram_increment => false,

        irq_count => 0,
        irq => false,

        audio => RESET_N163_AUDIO
    );

    type mapper_n163_out_t is record
        reg  : mapper_n163_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_n163
    (
        reg      : mapper_n163_reg_t;
        board    : n163_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_n163_out_t;

end package lib_mapper_n163;


package body lib_mapper_n163 is

    function is_n163_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"013" | x"0D2" => return true;
            when others => return false;
        end case;
    end;

    function get_n163_board(config : cart_config_t) return n163_board_t
    is
        variable ret : n163_board_t;
    begin
        ret.mirror := config.mirror;

        if config.mapper_num = x"013"
        then
            ret.chip := NAMCO_163;
            ret.detect := not config.nes2;
        elsif config.nes2 and config.submapper_num = x"1"
        then
            ret.chip := NAMCO_175;
            ret.detect := false;
        elsif config.nes2 and config.submapper_num = x"2"
        then
            ret.chip := NAMCO_340;
            ret.detect := false;
        else
            ret.chip := NAMCO_UNKNOWN;
            ret.detect := true;
        end if;

        return ret;
    end;

    function get_reset_n163_reg(board : n163_board_t) return mapper_n163_reg_t
    is
        variable ret : mapper_n163_reg_t;
        variable addr : chr_addr_t;
    begin
        ret := RESET_MAPPER_N163_REG;
        ret.chip := board.chip;
        ret.mirror := board.mirror;

        for i in 0 to 3
        loop
            addr := to_std_logic_vector(16#2000# + 16#400# * i,
                                        chr_addr_t'length);
            ret.chr_regs(8 + i) := "1110000" & get_ciram_a10(board.mirror,
                                                             addr);
        end loop;

        return ret;
    end;

    -- The game wrote a register that only chip has, or that only chip has
    -- with what was written. The chip is never told to be the 340 once the
    -- game has written to 0x6000-0x7FFF
    function detect_chip
    (
        reg   : mapper_n163_reg_t;
        board : n163_board_t;
        chip  : n163_chip_t
    )
    return mapper_n163_reg_t
    is
        variable ret : mapper_n163_reg_t;
    begin
        ret := reg;

        if board.detect and (not reg.not_340 or chip /= NAMCO_340)
        then
            ret.chip := chip;
        end if;

        return ret;
    end;

    -- The mirroring of the 340 in bits 7-6 of 0xE000. nesdev and Nestopia
    -- give 2 as one screen B and 3 as horizontal; Mesen swaps them
    function get_340_mirror(data : data_t) return mirror_t
    is
    begin
        case data(7 downto 6) is
            when "00" => return MIRROR_A;
            when "01" => return MIRROR_VERT;
            when "10" => return MIRROR_B;
            when others => return MIRROR_HORZ;
        end case;
    end;

    -- The CPU writes 0x8000-0xFFFF
    function write_rom_reg
    (
        reg   : mapper_n163_reg_t;
        board : n163_board_t;
        idx   : natural;
        data  : data_t
    )
    return mapper_n163_reg_t
    is
        variable ret : mapper_n163_reg_t;
    begin
        ret := reg;

        case idx is
            when 0 to 7 =>
                ret.chr_regs(idx) := data;
            -- 0xC000: a nametable page on the 163, the PRG RAM enable on
            -- the 175
            when 8 =>
                if reg.chip /= NAMCO_163
                then
                    ret := detect_chip(ret, board, NAMCO_175);
                end if;

                if ret.chip = NAMCO_175
                then
                    ret.prg_ram_protect := data;
                else
                    ret.chr_regs(idx) := data;
                end if;
            when 9 to 11 =>
                ret := detect_chip(ret, board, NAMCO_163);
                ret.chr_regs(idx) := data;
            -- 0xE000: bit 6 disables the audio of the 163, and bits 7-6 are
            -- the mirroring of the 340
            when 12 =>
                if data(7) = '1' or
                   (data(6) = '1' and reg.chip /= NAMCO_163)
                then
                    ret := detect_chip(ret, board, NAMCO_340);
                end if;

                ret.prg_banks(0) := unsigned(data(prg_bank_t'range));
                if ret.chip = NAMCO_340
                then
                    ret.mirror := get_340_mirror(data);
                elsif ret.chip = NAMCO_163
                then
                    ret.audio.disable := data(6) = '1';
                end if;
            when 13 =>
                ret.prg_banks(1) := unsigned(data(prg_bank_t'range));
                if reg.chip = NAMCO_163
                then
                    ret.chr_rom_low := data(6) = '1';
                    ret.chr_rom_high := data(7) = '1';
                end if;
            when 14 =>
                ret.prg_banks(2) := unsigned(data(prg_bank_t'range));
            -- 0xF800: the PRG RAM write protection and chip RAM address
            when others =>
                ret := detect_chip(ret, board, NAMCO_163);
                if ret.chip = NAMCO_163
                then
                    ret.prg_ram_protect := data;
                    ret.ram_addr := to_integer(data(6 downto 0));
                    ret.ram_increment := data(7) = '1';
                end if;
        end case;

        return ret;
    end;

    -- The index of the register of a CPU access to 0x4000-0x5FFF: 9 for
    -- the chip RAM data (0x4800), 10 and 11 for the IRQ counter (0x5000,
    -- 0x5800). The 175 and 340 have none of these
    function get_low_reg_idx(cpu_in : cart_cpu_in_t) return natural
    is
    begin
        if cpu_in.romsel or cpu_in.prg_bus.address(14 downto 13) /= "10"
        then
            return 0;
        else
            return to_integer(cpu_in.prg_bus.address(12 downto 11)) + 8;
        end if;
    end;

    -- The chip RAM address after an access through 0x4800
    function next_ram_addr(reg : mapper_n163_reg_t) return chip_ram_idx_t
    is
    begin
        if reg.ram_increment
        then
            return wrap(reg.ram_addr + 1, chip_ram_idx_t'high);
        else
            return reg.ram_addr;
        end if;
    end;

    function cycle_write
    (
        reg      : mapper_n163_reg_t;
        board    : n163_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_n163_reg_t
    is
        variable ret : mapper_n163_reg_t;
        variable cpu_in : cart_cpu_in_t;
        variable data : data_t;
        variable low_idx : natural range 0 to 11;
    begin
        ret := reg;
        cpu_in := cart_in.cpu;
        data := cpu_in.data;

        if not clk_sync or not is_bus_active(cpu_in.prg_bus)
        then
            return ret;
        end if;

        if is_bus_write(cpu_in.prg_bus)
        then
            if cpu_in.romsel
            then
                ret := write_rom_reg(reg,
                                     board,
                                     to_integer(cpu_in.prg_bus.address(14 downto 11)),
                                     data);
            elsif is_prg_ram_window(cpu_in)
            then
                if board.detect
                then
                    ret.not_340 := true;
                    if reg.chip = NAMCO_340
                    then
                        ret.chip := NAMCO_UNKNOWN;
                    end if;
                end if;
            else
                low_idx := get_low_reg_idx(cpu_in);
                if low_idx >= 9
                then
                    ret := detect_chip(ret, board, NAMCO_163);
                end if;

                if ret.chip = NAMCO_163
                then
                    case low_idx is
                        when 9 =>
                            ret.audio := write_n163_ram(ret.audio,
                                                        to_std_logic_vector(reg.ram_addr,
                                                                            chip_ram_addr_t'length),
                                                        data);
                            ret.ram_addr := next_ram_addr(reg);
                        -- Writing the counter acknowledges the IRQ
                        when 10 =>
                            ret.irq_count := set_bits(reg.irq_count, 0, data);
                            ret.irq := false;
                        when 11 =>
                            ret.irq_count := set_bits(reg.irq_count, 8, data);
                            ret.irq := false;
                        when others =>
                            null;
                    end case;
                end if;
            end if;
        elsif reg.chip = NAMCO_163 and get_low_reg_idx(cpu_in) = 9
        then
            ret.ram_addr := next_ram_addr(reg);
        end if;

        return ret;
    end;

    -- While enabled, the counter counts CPU cycles up to 0x7FFF, where it
    -- raises an IRQ and stops
    function cycle_irq
    (
        reg      : mapper_n163_reg_t;
        clk_sync : boolean
    )
    return mapper_n163_reg_t
    is
        variable ret : mapper_n163_reg_t;
    begin
        ret := reg;

        if clk_sync and reg.irq_count >= 16#8000# and
           reg.irq_count /= irq_count_t'high
        then
            ret.irq_count := reg.irq_count + 1;
            if ret.irq_count = irq_count_t'high
            then
                ret.irq := true;
            end if;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_n163_reg_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable idx : natural range 0 to 3;
    begin
        idx := to_integer(std_logic_vector(window));
        if idx = 3
        then
            return (others => '1');
        else
            return resize(reg.prg_banks(idx), prg_bank_8kb_t'length);
        end if;
    end;

    -- The banks of a PPU access. On the 163, pages 0xE0-0xFF are the pages
    -- of CIRAM, for the nametables and, unless 0xE800 says otherwise, the
    -- pattern tables. The 175 and 340 map only the pattern tables, and the
    -- 175 has the mirroring of the header that banks has
    function get_chr_banks
    (
        reg     : mapper_n163_reg_t;
        cart_in : cart_in_t;
        banks   : cart_banks_t
    )
    return cart_banks_t
    is
        variable ret : cart_banks_t;
        variable addr : chr_addr_t;
        variable page : data_t;
        variable ciram : boolean;
    begin
        ret := banks;
        addr := cart_in.ppu.chr_bus.address;

        if addr(13) = '0'
        then
            page := reg.chr_regs(to_integer(get_chr_window(cart_in.ppu)));
            if addr(12) = '0'
            then
                ciram := not reg.chr_rom_low;
            else
                ciram := not reg.chr_rom_high;
            end if;
        else
            page := reg.chr_regs(8 + to_integer(addr(11 downto 10)));
            ciram := true;
        end if;

        ret.chr := resize(unsigned(page), chr_bank_1kb_t'length);

        case reg.chip is
            when NAMCO_163 =>
                if ciram and page(7 downto 5) = "111"
                then
                    ret.ciram := true;
                    ret.mirror := get_single_screen_mirror(page(0));
                else
                    ret.nt_chr := addr(13) = '1';
                end if;
            when NAMCO_340 =>
                ret.mirror := reg.mirror;
            when NAMCO_175 | NAMCO_UNKNOWN =>
                null;
        end case;

        return ret;
    end;

    -- The PRG RAM is enabled, and on the 163 can only be written in the 2KB
    -- windows that 0xF800 leaves unprotected when its high nibble is 4
    function protect_prg_ram
    (
        reg      : mapper_n163_reg_t;
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable window : natural range 0 to 3;
    begin
        ret := cart_out;
        window := to_integer(cart_in.cpu.prg_bus.address(12 downto 11));

        if reg.prg_ram_protect(7 downto 4) /= "0100" or
           reg.prg_ram_protect(window) = '1'
        then
            ret.mem.prg_ram_bus.write := false;
        end if;

        return ret;
    end;

    -- The CPU accesses the chip RAM in the sync cycle, and the audio in the
    -- other PPU cycles. chip is the chip as told by this cycle's write, which
    -- can be the write to 0x4800 that tells it
    function map_chip_ram
    (
        reg      : mapper_n163_reg_t;
        chip     : n163_chip_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable cpu_in : cart_cpu_in_t;
        variable addr : chip_ram_addr_t;
    begin
        ret := cart_out;
        cpu_in := cart_in.cpu;

        if clk_sync
        then
            if chip = NAMCO_163 and get_low_reg_idx(cpu_in) = 9 and
               is_bus_active(cpu_in.prg_bus)
            then
                addr := to_std_logic_vector(reg.ram_addr,
                                            chip_ram_addr_t'length);
                if is_bus_write(cpu_in.prg_bus)
                then
                    ret.mem.chip_ram_bus := bus_write(addr);
                    ret.mem.data_to_chip_ram := cpu_in.data;
                else
                    ret.mem.chip_ram_bus := bus_read(addr);
                end if;
            end if;
        elsif reg.chip = NAMCO_163
        then
            ret.mem.chip_ram_bus := get_n163_ram_bus(reg.audio);
            if is_bus_write(ret.mem.chip_ram_bus)
            then
                ret.mem.data_to_chip_ram := get_n163_ram_data(reg.audio);
            end if;
        end if;

        return ret;
    end;

    -- The CPU reads the registers of the 163 at 0x4800-0x5FFF
    function read_reg
    (
        reg      : mapper_n163_reg_t;
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
    begin
        ret := cart_out;

        if reg.chip = NAMCO_163 and is_bus_read(cart_in.cpu.prg_bus)
        then
            case get_low_reg_idx(cart_in.cpu) is
                when 9 =>
                    ret.cpu.data := cart_in.mem.data_from_chip_ram;
                    ret.cpu.data_oe := true;
                when 10 =>
                    ret.cpu.data := to_std_logic_vector(get_bits(reg.irq_count, 7, 0),
                                                        data_t'length);
                    ret.cpu.data_oe := true;
                when 11 =>
                    ret.cpu.data := to_std_logic_vector(get_bits(reg.irq_count, 15, 8),
                                                        data_t'length);
                    ret.cpu.data_oe := true;
                when others =>
                    null;
            end case;
        end if;

        return ret;
    end;

    function cycle_mapper_n163
    (
        reg      : mapper_n163_reg_t;
        board    : n163_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_n163_out_t
    is
        variable ret : mapper_n163_out_t;
        variable banks : cart_banks_t;
    begin
        -- The IRQ counter and the audio are clocked before the write of the
        -- CPU cycle, so a write is not undone by the clock
        ret.reg := cycle_irq(reg, clk_sync);
        if reg.chip = NAMCO_163
        then
            ret.reg.audio := cycle_n163_audio(reg.audio,
                                              clk_sync,
                                              cart_in.mem.data_from_chip_ram);
        end if;
        ret.reg := cycle_write(ret.reg, board, clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle
        banks := default_banks(config);
        banks.prg := get_prg_bank(ret.reg, get_prg_window(cart_in.cpu));
        case ret.reg.chip is
            when NAMCO_163 =>
                banks.prg_ram := true;
            when NAMCO_175 =>
                banks.prg_ram := ret.reg.prg_ram_protect(0) = '1';
            when NAMCO_340 | NAMCO_UNKNOWN =>
                banks.prg_ram := false;
        end case;
        banks := get_chr_banks(ret.reg, cart_in, banks);

        ret.cart := map_cart(config, cart_in, banks);
        if ret.reg.chip = NAMCO_163
        then
            ret.cart := protect_prg_ram(ret.reg, cart_in, ret.cart);
        end if;
        -- The chip RAM is accessed at the address before this cycle's
        -- access moves it
        ret.cart := map_chip_ram(reg,
                                 ret.reg.chip,
                                 clk_sync,
                                 cart_in,
                                 ret.cart);
        ret.cart := read_reg(reg, cart_in, ret.cart);

        ret.cart.cpu.irq := reg.irq;
        ret.cart.audio := get_n163_audio_level(reg.audio);

        return ret;
    end;

end package body;
