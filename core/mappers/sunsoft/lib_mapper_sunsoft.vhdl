library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.cart_mem_bus_types.all;
use work.cart_types.all;
use work.lib_irq_counter.all;

-- Boards with a 16KB PRG ROM bank at 0x8000, the last bank fixed at 0xC000,
-- and eight registers at 0x8000-0xFFFF selected by CPU A14-A12, the last of
-- them the PRG bank. All but the Sunsoft-4 have an IRQ counter of CPU
-- cycles. The board is chosen by the mapper number at run time.
--
-- The Sunsoft-3 (67) and Sunsoft-4 (68) have four 2KB CHR ROM banks and the
-- same mirroring register. The Sunsoft-3 also decodes A11: its registers are
-- at 0x8800, 0x9800, ... (A11 set), and a write with A11 clear acknowledges
-- the IRQ (nesdev; Mesen and Nestopia acknowledge it at 0xD800 instead). Its
-- 16-bit counter is written directly, high byte first, and counts down,
-- raising the IRQ and stopping when it wraps from 0 to 0xFFFF.
--
-- The Sunsoft-4 has PRG RAM with an enable, and can map CHR ROM to the
-- nametables: two 1KB banks in the last 128KB of CHR ROM take the place of
-- the two pages of CIRAM. On the Sunsoft Dual Cartridge System of
-- Nantettatte!! Baseball, bit 3 of the PRG bank clear selects the ROM of the
-- sub-cartridge, which the ROM file holds after the 128KB of the cartridge.
-- It reads open bus once a licensing timer of SUNSOFT_4_DCS_TIMEOUT CPU
-- cycles runs out, which a write to 0x6000-0x7FFF with PRG RAM disabled
-- restarts.
--
-- The Konami VRC3 (73) has 8KB of CHR RAM, PRG RAM, mirroring by solder pads
-- and a 16-bit counter that counts up from a reload value, or only its low
-- 8 bits do, raising the IRQ when it wraps.
--
-- To add a board, add it to sunsoft_board_t, get_sunsoft_board and its
-- mapper number to is_sunsoft_mapper
package lib_mapper_sunsoft is

    type sunsoft_board_t is
    (
        SUNSOFT_3,
        SUNSOFT_4,
        -- Sunsoft-4 on the Sunsoft Dual Cartridge System: NES 2.0 submapper
        -- 1, or, as in Mesen, an iNES ROM file with more than 128KB of PRG
        -- ROM
        SUNSOFT_4_DCS,
        VRC3
    );

    -- The mapper number is that of a board in the family
    function is_sunsoft_mapper(mapper_num : mapper_num_t) return boolean;

    function get_sunsoft_board(config : cart_config_t) return sunsoft_board_t;

    -- 16KB PRG ROM bank
    subtype prg_bank_t is unsigned(3 downto 0);
    -- 2KB CHR ROM banks at 0x0000, 0x0800, 0x1000 and 0x1800
    subtype chr_bank_t is unsigned(7 downto 0);
    type chr_bank_arr_t is array(0 to 3) of chr_bank_t;
    -- The 1KB CHR ROM banks of the Sunsoft-4 that stand in for the two
    -- pages of CIRAM, in the last 128KB of CHR ROM
    subtype nt_bank_t is unsigned(6 downto 0);
    type nt_bank_arr_t is array(0 to 1) of nt_bank_t;

    -- The CPU cycles the sub-cartridge ROM of the Sunsoft Dual Cartridge
    -- System can be read after a write to 0x6000-0x7FFF. Nantettatte!!
    -- Baseball checks that it is between 107516 and 107575 (nesdev)
    constant SUNSOFT_4_DCS_TIMEOUT : natural := 1024 * 105;
    subtype dcs_timer_t is natural range 0 to SUNSOFT_4_DCS_TIMEOUT;

    type mapper_sunsoft_reg_t is record
        prg_bank  : prg_bank_t;
        chr_banks : chr_bank_arr_t;

        -- Sunsoft-3 and Sunsoft-4
        mirror    : mirror_t;

        -- Sunsoft-4: the nametables are in CHR ROM, in nt_banks
        nt_chr    : boolean;
        nt_banks  : nt_bank_arr_t;
        prg_ram_enable : boolean;
        -- Sunsoft Dual Cartridge System: the CPU cycles left until the
        -- sub-cartridge ROM reads open bus
        dcs_timer : dcs_timer_t;

        -- Sunsoft-3: the counter counts. VRC3: the E bit of 0xC000
        irq_enable : boolean;
        irq        : boolean;
        -- Sunsoft-3: the next write to 0xC800 sets the low byte of the count
        irq_low    : boolean;
        -- VRC3: the A bit of 0xC000, which 0xD000 copies to irq_enable, and
        -- the M bit, with which only the low 8 bits count
        irq_enable_on_ack : boolean;
        irq_8bit   : boolean;
    end record;

    -- The power on state is not known. The mirroring is that of a mirroring
    -- register of 0
    constant RESET_MAPPER_SUNSOFT_REG : mapper_sunsoft_reg_t :=
    (
        prg_bank => (others => '0'),
        chr_banks => (others => (others => '0')),

        mirror => MIRROR_VERT,

        nt_chr => false,
        nt_banks => (others => (others => '0')),
        prg_ram_enable => false,
        dcs_timer => 0,

        irq_enable => false,
        irq => false,
        irq_low => false,
        irq_enable_on_ack => false,
        irq_8bit => false
    );

    -- The counter, and the reload value of the VRC3 as the latch, are kept
    -- by the cartridge, and irq_counter is what the board does to them. The
    -- VRC3 keeps them inverted, so they count down
    type mapper_sunsoft_out_t is record
        reg         : mapper_sunsoft_reg_t;
        cart        : cart_out_t;
        irq_counter : irq_counter_op_t;
    end record;

    -- irq_count is the count of the counter
    function cycle_mapper_sunsoft
    (
        reg       : mapper_sunsoft_reg_t;
        irq_count : irq_counter_value_t;
        board     : sunsoft_board_t;
        config    : cart_config_t;
        clk_sync  : boolean;
        cart_in   : cart_in_t
    )
    return mapper_sunsoft_out_t;

end package lib_mapper_sunsoft;


package body lib_mapper_sunsoft is

    function is_sunsoft_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"043" | x"044" | x"049" => return true;
            when others => return false;
        end case;
    end;

    function get_sunsoft_board(config : cart_config_t) return sunsoft_board_t
    is
    begin
        case config.mapper_num is
            when x"043" =>
                return SUNSOFT_3;
            when x"049" =>
                return VRC3;
            when others =>
                if config.submapper_num = x"1" or
                   (not config.nes2 and config.prg_rom_16kb_blocks > 8)
                then
                    return SUNSOFT_4_DCS;
                else
                    return SUNSOFT_4;
                end if;
        end case;
    end;

    function is_sunsoft_4(board : sunsoft_board_t) return boolean
    is
    begin
        return board = SUNSOFT_4 or board = SUNSOFT_4_DCS;
    end;

    -- The registers are selected by CPU A14-A12
    function cycle_write
    (
        reg      : mapper_sunsoft_reg_t;
        board    : sunsoft_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_sunsoft_reg_t
    is
        variable ret : mapper_sunsoft_reg_t;
        variable addr : prg_addr_t;
        variable data : data_t;
        variable idx : natural range 0 to 7;
    begin
        ret := reg;
        addr := cart_in.cpu.prg_bus.address;
        data := cart_in.cpu.data;
        idx := to_integer(addr(14 downto 12));

        -- The licensing timer restarts on a write to 0x6000-0x7FFF with PRG
        -- RAM disabled
        if board = SUNSOFT_4_DCS and
           is_prg_ram_window(cart_in.cpu) and
           is_bus_write(cart_in.cpu.prg_bus) and
           clk_sync and
           not reg.prg_ram_enable
        then
            ret.dcs_timer := SUNSOFT_4_DCS_TIMEOUT;
        end if;

        if not is_rom_write(cart_in.cpu, clk_sync)
        then
            return ret;
        end if;

        if board = SUNSOFT_3 and addr(11) = '0'
        then
            ret.irq := false;
            return ret;
        end if;

        case idx is
            -- VRC3: the nibbles of the reload value. See get_irq_counter_op
            when 0 to 3 =>
                if board /= VRC3
                then
                    ret.chr_banks(idx) := unsigned(data);
                end if;
            -- Sunsoft-3: the count. VRC3: the control, which reloads the
            -- counter when it enables it
            when 4 =>
                case board is
                    when SUNSOFT_3 =>
                        ret.irq_low := not reg.irq_low;
                    when VRC3 =>
                        ret.irq_enable_on_ack := data(0) = '1';
                        ret.irq_enable := data(1) = '1';
                        ret.irq_8bit := data(2) = '1';
                        ret.irq := false;
                    when others =>
                        ret.nt_banks(0) := unsigned(data(6 downto 0));
                end case;
            when 5 =>
                case board is
                    -- Does not acknowledge the IRQ
                    when SUNSOFT_3 =>
                        ret.irq_enable := data(4) = '1';
                        ret.irq_low := false;
                    when VRC3 =>
                        ret.irq_enable := reg.irq_enable_on_ack;
                        ret.irq := false;
                    when others =>
                        ret.nt_banks(1) := unsigned(data(6 downto 0));
                end case;
            when 6 =>
                ret.mirror := get_hv_single_screen_mirror(data(1 downto 0));
                ret.nt_chr := is_sunsoft_4(board) and data(4) = '1';
            when 7 =>
                if board = VRC3
                then
                    ret.prg_bank := '0' & unsigned(data(2 downto 0));
                else
                    ret.prg_bank := unsigned(data(3 downto 0));
                end if;
                ret.prg_ram_enable := data(4) = '1';
        end case;

        return ret;
    end;

    -- The counter of the Sunsoft-3 counts down while enabled. When it wraps
    -- from 0 it raises the IRQ and stops. The counter of the VRC3 counts up
    -- while enabled. When it wraps it raises the IRQ and is reloaded. With
    -- only the low 8 bits counting, only they wrap and are reloaded. Its
    -- count is kept inverted, so it wraps from 0
    function cycle_irq
    (
        reg       : mapper_sunsoft_reg_t;
        irq_count : irq_counter_value_t;
        board     : sunsoft_board_t;
        clk_sync  : boolean
    )
    return mapper_sunsoft_reg_t
    is
        variable ret : mapper_sunsoft_reg_t;
        variable wraps : boolean;
    begin
        ret := reg;

        if reg.irq_8bit
        then
            wraps := get_bits(irq_count, 7, 0) = 0;
        else
            wraps := irq_count = 0;
        end if;

        if clk_sync and reg.irq_enable and wraps
        then
            ret.irq := true;
            if board = SUNSOFT_3
            then
                ret.irq_enable := false;
            end if;
        end if;

        return ret;
    end;

    -- The clock of the counter, and the writes to it: the Sunsoft-3 writes
    -- the high and low bytes of the count in turn at 0xC800, and the VRC3
    -- the nibbles of the reload value at 0x8000-0xB000 and reloads the
    -- counter with a write to 0xC000 that enables it
    function get_irq_counter_op
    (
        reg      : mapper_sunsoft_reg_t;
        board    : sunsoft_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return irq_counter_op_t
    is
        variable ret : irq_counter_op_t;
        variable addr : prg_addr_t;
    begin
        addr := cart_in.cpu.prg_bus.address;

        ret := IRQ_COUNTER_IDLE;
        ret.clock := clk_sync and reg.irq_enable;
        ret.reload := board = VRC3;
        ret.low_byte := board = VRC3 and reg.irq_8bit;
        ret.invert := board = VRC3;

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            case board is
                when SUNSOFT_3 =>
                    if addr(14 downto 11) = "1001"
                    then
                        if reg.irq_low
                        then
                            ret.write := IRQ_COUNTER_COUNT_LOW;
                        else
                            ret.write := IRQ_COUNTER_COUNT_HIGH;
                        end if;
                    end if;
                when VRC3 =>
                    case addr(14 downto 12) is
                        when "000" => ret.write := IRQ_COUNTER_LATCH_0;
                        when "001" => ret.write := IRQ_COUNTER_LATCH_1;
                        when "010" => ret.write := IRQ_COUNTER_LATCH_2;
                        when "011" => ret.write := IRQ_COUNTER_LATCH_3;
                        when "100" =>
                            if cart_in.cpu.data(1) = '1'
                            then
                                ret.write := IRQ_COUNTER_LOAD;
                            end if;
                        when others =>
                    end case;
                when SUNSOFT_4 | SUNSOFT_4_DCS =>
            end case;
        end if;

        return ret;
    end;

    -- The 16KB blocks of the sub-cartridge ROM of the Sunsoft Dual Cartridge
    -- System, after the 128KB of the cartridge, as a mask of the bank
    function get_dcs_bank_mask(config : cart_config_t)
        return unsigned
    is
        variable blocks : rom_blocks_t;
    begin
        blocks := config.prg_rom_16kb_blocks - 8;
        if blocks <= 1
        then
            return "000";
        elsif blocks <= 2
        then
            return "001";
        elsif blocks <= 4
        then
            return "011";
        else
            return "111";
        end if;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_sunsoft_reg_t;
        board  : sunsoft_board_t;
        config : cart_config_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable bank : prg_bank_t;
    begin
        if board = SUNSOFT_4_DCS
        then
            -- The fixed bank is the last of the cartridge ROM
            if window(1) = '1'
            then
                bank := x"7";
            elsif reg.prg_bank(3) = '0'
            then
                bank := '1' & (reg.prg_bank(2 downto 0) and
                               get_dcs_bank_mask(config));
            else
                bank := '0' & reg.prg_bank(2 downto 0);
            end if;
            return resize(bank & window(0), prg_bank_8kb_t'length);
        elsif window(1) = '1'
        then
            return "1111111" & window(0);
        else
            return resize(reg.prg_bank & window(0), prg_bank_8kb_t'length);
        end if;
    end;

    -- The 1KB CHR bank of the PPU address. The nametables of the Sunsoft-4
    -- in CHR ROM are selected by the CIRAM page the mirroring gives
    function get_chr_bank
    (
        reg     : mapper_sunsoft_reg_t;
        cart_in : cart_in_t
    )
    return chr_bank_1kb_t
    is
        variable addr : chr_addr_t;
        variable window : chr_window_t;
        variable page : natural range nt_bank_arr_t'range;
    begin
        addr := cart_in.ppu.chr_bus.address;
        window := get_chr_window(cart_in.ppu);

        if addr(13) = '1'
        then
            if get_ciram_a10(reg.mirror, addr) = '1'
            then
                page := 1;
            else
                page := 0;
            end if;
            return resize('1' & reg.nt_banks(page), chr_bank_1kb_t'length);
        else
            return resize(reg.chr_banks(to_integer(window(2 downto 1))) &
                          window(0),
                          chr_bank_1kb_t'length);
        end if;
    end;

    function cycle_mapper_sunsoft
    (
        reg       : mapper_sunsoft_reg_t;
        irq_count : irq_counter_value_t;
        board     : sunsoft_board_t;
        config    : cart_config_t;
        clk_sync  : boolean;
        cart_in   : cart_in_t
    )
    return mapper_sunsoft_out_t
    is
        variable ret : mapper_sunsoft_out_t;
        variable banks : cart_banks_t;
        variable window : prg_window_t;
    begin
        -- The counters are clocked before the write of the CPU cycle, so a
        -- write to them is not undone by the clock
        ret.reg := reg;
        ret.irq_counter := IRQ_COUNTER_IDLE;
        case board is
            when SUNSOFT_3 | VRC3 =>
                ret.reg := cycle_irq(ret.reg, irq_count, board, clk_sync);
                ret.irq_counter := get_irq_counter_op(reg,
                                                      board,
                                                      clk_sync,
                                                      cart_in);
            when SUNSOFT_4_DCS =>
                if clk_sync and reg.dcs_timer /= 0
                then
                    ret.reg.dcs_timer := reg.dcs_timer - 1;
                end if;
            when SUNSOFT_4 =>
        end case;
        ret.reg := cycle_write(ret.reg, board, clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle. The CPU
        -- does not: a register write is not a read of PRG ROM or RAM, and
        -- not forwarding it keeps the CPU data bus out of the PRG address
        banks := default_banks(config);
        window := get_prg_window(cart_in.cpu);
        banks.prg := get_prg_bank(reg, board, config, window);
        case board is
            when SUNSOFT_3 =>
            when VRC3 =>
                banks.prg_ram := true;
            when SUNSOFT_4 | SUNSOFT_4_DCS =>
                banks.prg_ram := reg.prg_ram_enable;
        end case;

        if board = VRC3
        then
            -- 8KB of CHR RAM, not banked
            banks.chr := resize(get_chr_window(cart_in.ppu),
                                chr_bank_1kb_t'length);
        else
            banks.chr := get_chr_bank(ret.reg, cart_in);
            banks.mirror := ret.reg.mirror;
            banks.nt_chr := ret.reg.nt_chr;
        end if;

        ret.cart := map_cart(config, cart_in, banks);

        -- The sub-cartridge ROM reads open bus once the timer runs out
        if board = SUNSOFT_4_DCS and
           cart_in.cpu.romsel and
           window(1) = '0' and
           reg.prg_bank(3) = '0' and
           reg.dcs_timer = 0
        then
            ret.cart.cpu := CART_CPU_OUT_IDLE;
            ret.cart.mem.prg_rom_bus := CART_MEM_BUS_IDLE;
        end if;

        ret.cart.cpu.irq := reg.irq;

        return ret;
    end;

end package body;
