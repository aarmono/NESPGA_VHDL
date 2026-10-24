library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.cart_mem_bus_types.all;
use work.chr_ram_bus_types.all;
use work.cart_types.all;

-- Boards built from discrete logic: one or more latches that hold bits of
-- the data the CPU writes, or of the address it writes to, wired to the high
-- address lines of the ROMs and to CIRAM A10. They differ only in where the
-- latches are written, which bits they hold and what those bits are wired
-- to, so each board is a row in a table chosen by the mapper number at run
-- time.
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
        -- 0xC000-0xFFFF
        LATCH_ADDR_C000,
        LATCH_ADDR_7FFD,
        LATCH_ADDR_7FFE,
        LATCH_ADDR_7FFF
    );

    -- A latch written by the CPU at addr. It holds bits of the CPU address
    -- above bits of the data: the address shifted right by addr_shift and
    -- masked by addr_mask, above the data shifted right by data_shift and
    -- masked by data_mask, which is data_width bits wide
    type latch_t is record
        addr       : latch_addr_t;
        addr_shift : natural range 0 to prg_addr_t'length - 1;
        addr_mask  : latch_value_t;
        data_shift : natural range 0 to 7;
        data_mask  : latch_value_t;
        data_width : natural range 0 to latch_value_t'length;
    end record;

    type latch_id_t is
    (
        LATCH_PRG,
        LATCH_CHR_0,
        LATCH_CHR_1,
        LATCH_PRG_MODE,
        LATCH_MIRROR
    );

    type latches_t is array(latch_id_t) of latch_t;

    type latch_prg_mode_t is
    (
        -- LATCH_PRG selects a 32KB bank at 0x8000
        PRG_32KB,
        -- LATCH_PRG selects a 16KB bank at 0x8000. 0xC000 holds the last
        -- bank
        PRG_16KB_FIXED_LAST,
        -- LATCH_PRG selects a 16KB bank. When bit 0 of LATCH_PRG_MODE is
        -- set it is at both 0x8000 and 0xC000, otherwise its bit 0 is
        -- dropped and it selects a 32KB bank at 0x8000
        PRG_16KB_OR_32KB
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
        chr_mode     : latch_chr_mode_t;
        mirror_mode  : latch_mirror_mode_t;
        prg_ram      : boolean;
        -- PRG ROM is in 512KB chips, in the four sockets selected by bits
        -- 7-6 of the 8KB bank, and socket 2 is empty: the CPU reads open
        -- bus there. The ROM file holds the chip of socket 3 after those of
        -- sockets 0 and 1
        prg_no_socket_2 : boolean;
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

    -- The masks of the CHR RAM address for boards with more than 8KB
    constant CHR_RAM_16KB_MASK : chr_ram_addr_t := x"3FFF";
    constant CHR_RAM_32KB_MASK : chr_ram_addr_t := x"7FFF";

    -- A latch that is never written, so it always holds 0
    constant LATCH_NONE : latch_t :=
    (
        addr => LATCH_ADDR_NONE,
        addr_shift => 0,
        addr_mask => (others => '0'),
        data_shift => 0,
        data_mask => (others => '0'),
        data_width => 0
    );

    -- The mask of bits hi downto lo, shifted down to bit 0. There are none
    -- when hi is one below lo
    function get_bits_mask(hi : integer; lo : natural) return latch_value_t
    is
    begin
        return to_unsigned(2**(hi - lo + 1) - 1, latch_value_t'length);
    end;

    -- A latch of CPU address bits addr_hi downto addr_lo above data bits
    -- data_hi downto data_lo, written at addr. A range whose hi is one below
    -- its lo has no bits
    function latch
    (
        addr    : latch_addr_t;
        addr_hi : integer;
        addr_lo : natural;
        data_hi : integer;
        data_lo : natural
    )
    return latch_t
    is
    begin
        return
        (
            addr => addr,
            addr_shift => addr_lo,
            addr_mask => get_bits_mask(addr_hi, addr_lo),
            data_shift => data_lo,
            data_mask => get_bits_mask(data_hi, data_lo),
            data_width => data_hi - data_lo + 1
        );
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
        return latch(addr, -1, 0, hi, lo);
    end;

    -- A latch of data bits hi downto lo, written at 0x8000-0xFFFF
    function rom_latch(hi : natural; lo : natural) return latch_t
    is
    begin
        return latch(LATCH_ADDR_ROM, hi, lo);
    end;

    -- A latch of the bits hi downto lo of the address written, at
    -- 0x8000-0xFFFF
    function rom_addr_latch(hi : natural; lo : natural) return latch_t
    is
    begin
        return latch(LATCH_ADDR_ROM, hi, lo, -1, 0);
    end;

    function is_latch_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"000" | x"002" | x"003" | x"007" | x"00B" | x"00D" |
                 x"01E" | x"022" | x"042" | x"0E4" => return true;
            when others => return false;
        end case;
    end;

    function get_latch_board(config : cart_config_t) return latch_board_t
    is
        variable ret : latch_board_t;
        variable addr : latch_addr_t;
    begin
        ret.prg_mode := PRG_32KB;
        ret.chr_mode := CHR_8KB;
        ret.mirror_mode := MIRROR_FIXED;
        ret.prg_ram := false;
        ret.prg_no_socket_2 := false;
        ret.chr_ram_mask := DEFAULT_RAM_MASK;
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
                ret.latches(LATCH_MIRROR) := latch(addr, 7, 7);

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
            -- Action 52 and Cheetah Men II. The latch holds most of the
            -- address written and two bits of the data. Action 52 has three
            -- 512KB chips of PRG ROM
            when x"0E4" =>
                ret.prg_mode := PRG_16KB_OR_32KB;
                ret.mirror_mode := MIRROR_VH;
                ret.prg_no_socket_2 := config.prg_rom_16kb_blocks = 96;
                ret.latches(LATCH_PRG) := rom_addr_latch(12, 6);
                ret.latches(LATCH_PRG_MODE) := rom_addr_latch(5, 5);
                ret.latches(LATCH_CHR_0) :=
                    latch(LATCH_ADDR_ROM, 3, 0, 1, 0);
                ret.latches(LATCH_MIRROR) := rom_addr_latch(13, 13);
            when others =>
        end case;

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

    function is_latch_addr
    (
        addr   : latch_addr_t;
        cpu_in : cart_cpu_in_t
    )
    return boolean
    is
    begin
        case addr is
            when LATCH_ADDR_NONE =>
                return false;
            when LATCH_ADDR_ROM =>
                return cpu_in.romsel;
            when LATCH_ADDR_C000 =>
                return cpu_in.romsel and cpu_in.prg_bus.address(14) = '1';
            when LATCH_ADDR_7FFD =>
                return is_low_addr(cpu_in, "111" & x"FFD");
            when LATCH_ADDR_7FFE =>
                return is_low_addr(cpu_in, "111" & x"FFE");
            when LATCH_ADDR_7FFF =>
                return is_low_addr(cpu_in, "111" & x"FFF");
        end case;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_latch_reg_t;
        mode   : latch_prg_mode_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable bank : latch_value_t;
    begin
        case mode is
            when PRG_32KB =>
                return resize(reg(LATCH_PRG) & window, prg_bank_8kb_t'length);
            when PRG_16KB_FIXED_LAST =>
                if window(1) = '0'
                then
                    bank := reg(LATCH_PRG);
                else
                    bank := (others => '1');
                end if;
                return resize(bank & window(0), prg_bank_8kb_t'length);
            when PRG_16KB_OR_32KB =>
                bank := reg(LATCH_PRG);
                if reg(LATCH_PRG_MODE)(0) = '0'
                then
                    bank(0) := window(1);
                end if;
                return resize(bank & window(0), prg_bank_8kb_t'length);
        end case;
    end;

    -- The value the CPU writes to a latch
    function get_latch_value
    (
        wiring : latch_t;
        cpu_in : cart_cpu_in_t
    )
    return latch_value_t
    is
        variable addr : latch_value_t;
        variable data : latch_value_t;
    begin
        addr := resize(shift_right(unsigned(cpu_in.prg_bus.address),
                                   wiring.addr_shift),
                       latch_value_t'length) and
                wiring.addr_mask;
        data := shift_right(unsigned(cpu_in.data), wiring.data_shift) and
                wiring.data_mask;

        return shift_left(addr, wiring.data_width) or data;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_latch_reg_t;
        mode   : latch_chr_mode_t;
        window : chr_window_t
    )
    return chr_bank_1kb_t
    is
        variable bank : latch_value_t;
    begin
        case mode is
            when CHR_8KB =>
                return resize(reg(LATCH_CHR_0) & window,
                              chr_bank_1kb_t'length);
            when CHR_4KB =>
                if window(2) = '0'
                then
                    bank := reg(LATCH_CHR_0);
                else
                    bank := reg(LATCH_CHR_1);
                end if;
                return resize(bank & window(1 downto 0),
                              chr_bank_1kb_t'length);
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
    begin
        ret.reg := reg;
        banks := default_banks(config);

        if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
        then
            for i in latch_id_t
            loop
                if is_latch_addr(board.latches(i).addr, cart_in.cpu)
                then
                    ret.reg(i) := get_latch_value(board.latches(i),
                                                  cart_in.cpu);
                end if;
            end loop;
        end if;

        -- The PPU sees the latches written by the CPU this cycle
        banks.prg := get_prg_bank(ret.reg, board.prg_mode,
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
            banks.chr := get_chr_bank(ret.reg, board.chr_mode, chr_window);
        end if;

        case board.mirror_mode is
            when MIRROR_FIXED | MIRROR_CHR_RAM =>
            when MIRROR_SINGLE =>
                banks.mirror :=
                    get_single_screen_mirror(ret.reg(LATCH_MIRROR)(0));
            when MIRROR_HV =>
                banks.mirror := get_hv_mirror(not ret.reg(LATCH_MIRROR)(0));
            when MIRROR_VH =>
                banks.mirror := get_hv_mirror(ret.reg(LATCH_MIRROR)(0));
        end case;

        banks.prg_ram := board.prg_ram;

        ret.cart := map_cart(config, cart_in, banks);

        if prg_open_bus and cart_in.cpu.romsel
        then
            ret.cart.cpu := CART_CPU_OUT_IDLE;
            ret.cart.mem.prg_rom_bus := CART_MEM_BUS_IDLE;
        end if;

        return ret;
    end;

end package body;
