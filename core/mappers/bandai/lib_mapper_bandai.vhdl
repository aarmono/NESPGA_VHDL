library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.chip_ram_bus_types.all;
use work.cart_types.all;
use work.lib_bandai_eeprom.all;
use work.lib_irq_counter.all;

-- Boards built around the Bandai FCG-1, FCG-2 or LZ93D50 (16, 153, 157,
-- 159). Registers 0-7 are 1KB CHR ROM banks, 8 the 16KB PRG ROM bank at
-- 0x8000 (0xC000 has the last), 9 the mirroring, A-C a 16-bit counter of
-- CPU cycles that raises an IRQ, and D, on the LZ93D50, the lines of a
-- serial EEPROM, which the CPU reads back at 0x6000-0x7FFF.
--
-- The FCG-1/2 decodes the registers at 0x6000-0x7FFF and its counter is
-- written directly. The LZ93D50 decodes them at 0x8000-0xFFFF and its
-- counter is written through a latch, copied to it by register A. iNES
-- mapper 16 stands for both, so each address range acts as its own chip,
-- as nesdev says to.
--
-- 153 has 8KB of PRG RAM in place of the EEPROM, enabled by bit 5 of
-- register D, and 157 (the Datach) an X24C02 in the base unit and, on
-- Battle Rush, an X24C01 on the cartridge, whose SCL is bit 3 of the CHR
-- banks. Both have 8KB of unbanked CHR RAM, and the PPU address lines that
-- select the CHR bank register are PPU A10 and A11 alone, so the bank that
-- drives PRG A18 (153) or SCL (157) is the one the PPU's last access
-- selected. The barcode reader of the Datach is not emulated: it reads 0.
--
-- The EEPROMs are kept in the chip RAM, the X24C02 at 0x000-0x0FF and the
-- X24C01 at 0x100-0x17F
package lib_mapper_bandai is

    -- The mapper number is that of a board built around a Bandai FCG chip
    function is_bandai_mapper(mapper_num : mapper_num_t) return boolean;

    type bandai_board_t is record
        -- The registers are at 0x6000-0x7FFF, with the counter of the
        -- FCG-1/2
        fcg       : boolean;
        -- The registers are at 0x8000-0xFFFF, with the counter of the
        -- LZ93D50
        lz93d50   : boolean;
        -- The board has an X24C02 or an X24C01 on register D
        x24c02    : boolean;
        x24c01    : boolean;
        -- The X24C01 has its SCL on the CHR banks (157)
        datach    : boolean;
        -- The board has PRG RAM and the CHR banks drive PRG A18 (153)
        prg_ram   : boolean;
    end record;

    function get_bandai_board(config : cart_config_t) return bandai_board_t;

    type chr_reg_arr_t is array(0 to 7) of data_t;

    subtype prg_bank_t is unsigned(3 downto 0);
    subtype chr_reg_idx_t is natural range 0 to 3;

    type mapper_bandai_reg_t is record
        chr_regs   : chr_reg_arr_t;
        prg_bank   : prg_bank_t;
        mirror     : mirror_t;

        irq_enable : boolean;
        irq        : boolean;

        prg_ram_enable : boolean;
        -- PPU A11-A10 of the last PPU access
        ppu_reg_idx : chr_reg_idx_t;

        -- SDA written to register D, which the EEPROMs share
        sda        : std_logic;
        x24c02     : eeprom_t;
        x24c01     : eeprom_t;
    end record;

    -- PRG RAM is enabled at power on, as in Mesen
    constant RESET_MAPPER_BANDAI_REG : mapper_bandai_reg_t :=
    (
        chr_regs => (others => (others => '0')),
        prg_bank => (others => '0'),
        mirror => MIRROR_VERT,

        irq_enable => false,
        irq => false,

        prg_ram_enable => true,
        ppu_reg_idx => 0,

        sda => '0',
        x24c02 => RESET_EEPROM,
        x24c01 => RESET_EEPROM
    );

    -- The counter and its latch are kept by the cartridge, and irq_counter
    -- is what the board does to them
    type mapper_bandai_out_t is record
        reg         : mapper_bandai_reg_t;
        cart        : cart_out_t;
        irq_counter : irq_counter_op_t;
    end record;

    -- irq_count is the count of the counter
    function cycle_mapper_bandai
    (
        reg       : mapper_bandai_reg_t;
        irq_count : irq_counter_value_t;
        board     : bandai_board_t;
        config    : cart_config_t;
        clk_sync  : boolean;
        cart_in   : cart_in_t
    )
    return mapper_bandai_out_t;

end package lib_mapper_bandai;


package body lib_mapper_bandai is

    function is_bandai_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        return mapper_num = x"010" or
               mapper_num = x"099" or
               mapper_num = x"09D" or
               mapper_num = x"09F";
    end;

    function bandai_board
    (
        fcg     : boolean := false;
        lz93d50 : boolean := true;
        x24c02  : boolean := false;
        x24c01  : boolean := false;
        datach  : boolean := false;
        prg_ram : boolean := false
    )
    return bandai_board_t
    is
    begin
        return
        (
            fcg => fcg,
            lz93d50 => lz93d50,
            x24c02 => x24c02,
            x24c01 => x24c01,
            datach => datach,
            prg_ram => prg_ram
        );
    end;

    -- 153
    function prg_ram_board return bandai_board_t
    is
    begin
        return bandai_board(prg_ram => true);
    end;

    -- 157. An NES 2.0 header gives 128 bytes of PRG RAM for the X24C01
    -- on the cartridge. With an iNES header it is assumed, as in Mesen
    function datach_board(config : cart_config_t) return bandai_board_t
    is
    begin
        return bandai_board(x24c02 => true,
                            x24c01 => not config.nes2 or
                                      config.prg_ram_mask = x"007F",
                            datach => true);
    end;

    -- 159
    function x24c01_board return bandai_board_t
    is
    begin
        return bandai_board(x24c01 => true);
    end;

    function get_bandai_board(config : cart_config_t) return bandai_board_t
    is
    begin
        case config.mapper_num is
            when x"099" =>
                return prg_ram_board;
            when x"09D" =>
                return datach_board(config);
            when x"09F" =>
                return x24c01_board;
            -- 16. Submapper 4 is the FCG-1/2 and 5 the LZ93D50, with an
            -- X24C02 if the header gives 256 bytes of PRG RAM. 1-3 are the
            -- boards of 159, 157 and 153, before those had numbers
            when others =>
                case config.submapper_num is
                    when x"1" =>
                        return x24c01_board;
                    when x"2" =>
                        return datach_board(config);
                    when x"3" =>
                        return prg_ram_board;
                    when x"4" =>
                        return bandai_board(fcg => true, lz93d50 => false);
                    when x"5" =>
                        return bandai_board(x24c02 => config.prg_ram_mask =
                                                      x"00FF");
                    when others =>
                        return bandai_board(fcg => true, x24c02 => true);
                end case;
        end case;
    end;

    -- The register written in the window of a chip of the board, or none
    function get_reg_idx
    (
        board  : bandai_board_t;
        cpu_in : cart_cpu_in_t
    )
    return integer
    is
    begin
        if (board.fcg and is_prg_ram_window(cpu_in)) or
           (board.lz93d50 and cpu_in.romsel)
        then
            return to_integer(cpu_in.prg_bus.address(3 downto 0));
        else
            return -1;
        end if;
    end;

    function write_reg
    (
        reg  : mapper_bandai_reg_t;
        idx  : natural;
        -- The write is to the LZ93D50
        lz   : boolean;
        data : data_t
    )
    return mapper_bandai_reg_t
    is
        variable ret : mapper_bandai_reg_t;
    begin
        ret := reg;

        case idx is
            when 0 to 7 =>
                ret.chr_regs(idx) := data;
            when 8 =>
                ret.prg_bank := unsigned(data(prg_bank_t'range));
            when 9 =>
                ret.mirror := get_hv_single_screen_mirror(data(1 downto 0));
            -- Acknowledges the IRQ. The counter is written by
            -- get_irq_counter_op
            when 10 =>
                ret.irq_enable := data(0) = '1';
                ret.irq := false;
            -- The EEPROM lines are stepped by cycle_eeproms
            when 13 =>
                if lz
                then
                    ret.prg_ram_enable := data(5) = '1';
                    ret.sda := data(6);
                end if;
            when others =>
                null;
        end case;

        return ret;
    end;

    function cycle_write
    (
        reg      : mapper_bandai_reg_t;
        board    : bandai_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_bandai_reg_t
    is
        variable idx : integer;
    begin
        idx := get_reg_idx(board, cart_in.cpu);
        if clk_sync and is_bus_write(cart_in.cpu.prg_bus) and idx >= 0
        then
            return write_reg(reg, idx, cart_in.cpu.romsel, cart_in.cpu.data);
        else
            return reg;
        end if;
    end;

    -- The counter is decremented every CPU cycle while it is enabled, and
    -- raises an IRQ when it is decremented from 0, which wraps it. The IRQ
    -- stays raised until it is acknowledged
    function cycle_irq
    (
        reg       : mapper_bandai_reg_t;
        irq_count : irq_counter_value_t;
        clk_sync  : boolean
    )
    return mapper_bandai_reg_t
    is
        variable ret : mapper_bandai_reg_t;
    begin
        ret := reg;

        if clk_sync and reg.irq_enable and irq_count = 0
        then
            ret.irq := true;
        end if;

        return ret;
    end;

    -- The clock of the counter, and the writes to it. The LZ93D50 writes
    -- the latch at registers B and C and loads the counter from it at
    -- register A. The FCG writes the counter at registers B and C
    function get_irq_counter_op
    (
        reg      : mapper_bandai_reg_t;
        board    : bandai_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return irq_counter_op_t
    is
        variable ret : irq_counter_op_t;
        variable lz : boolean;
    begin
        ret := IRQ_COUNTER_IDLE;
        ret.clock := clk_sync and reg.irq_enable;

        lz := cart_in.cpu.romsel;
        if clk_sync and is_bus_write(cart_in.cpu.prg_bus)
        then
            case get_reg_idx(board, cart_in.cpu) is
                when 10 =>
                    if lz
                    then
                        ret.write := IRQ_COUNTER_LOAD;
                    end if;
                when 11 =>
                    if lz
                    then
                        ret.write := IRQ_COUNTER_LATCH_LOW;
                    else
                        ret.write := IRQ_COUNTER_COUNT_LOW;
                    end if;
                when 12 =>
                    if lz
                    then
                        ret.write := IRQ_COUNTER_LATCH_HIGH;
                    else
                        ret.write := IRQ_COUNTER_COUNT_HIGH;
                    end if;
                when others =>
            end case;
        end if;

        return ret;
    end;

    -- The CHR bank register the PPU's last access selects
    function get_ppu_reg(reg : mapper_bandai_reg_t) return data_t
    is
    begin
        return reg.chr_regs(reg.ppu_reg_idx);
    end;

    type eeprom_cycle_t is record
        reg      : mapper_bandai_reg_t;
        cart     : cart_out_t;
    end record;

    function eeprom_ram_bus
    (
        step     : eeprom_step_t;
        eeprom   : eeprom_t;
        base     : std_logic_vector;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable addr : chip_ram_addr_t;
    begin
        ret := cart_out;
        addr := base & eeprom.addr(chip_ram_addr_t'length - base'length - 1
                                   downto 0);

        if step.write
        then
            ret.mem.chip_ram_bus := bus_write(addr);
            ret.mem.data_to_chip_ram := eeprom.data;
        elsif step.read
        then
            ret.mem.chip_ram_bus := bus_read(addr);
        end if;

        return ret;
    end;

    -- Steps the EEPROMs on the lines of register D, written by the CPU
    -- this cycle, and the X24C01 of the Datach on its SCL from the CHR
    -- banks. reg is after this cycle's write and PPU access
    function cycle_eeproms
    (
        reg      : mapper_bandai_reg_t;
        board    : bandai_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return eeprom_cycle_t
    is
        variable ret : eeprom_cycle_t;
        variable step : eeprom_step_t;
        variable reg_d_write : boolean;
        variable scl : std_logic;
    begin
        ret.reg := reg;
        ret.cart := cart_out;

        reg_d_write := clk_sync and
                       is_bus_write(cart_in.cpu.prg_bus) and
                       cart_in.cpu.romsel and
                       get_reg_idx(board, cart_in.cpu) = 13;

        if reg_d_write and board.x24c02
        then
            step := step_eeprom(reg.x24c02,
                                X24C02,
                                cart_in.cpu.data(5),
                                cart_in.cpu.data(6),
                                cart_in.mem.data_from_chip_ram);
            ret.reg.x24c02 := step.eeprom;
            ret.cart := eeprom_ram_bus(step, reg.x24c02, "0", ret.cart);
        end if;

        if board.x24c01
        then
            if board.datach
            then
                scl := get_ppu_reg(reg)(3);
            else
                scl := cart_in.cpu.data(5);
            end if;

            -- The X24C01 of the Datach has the X24C02 on the chip RAM bus
            -- if both access it, which the game avoids
            if (board.datach and
                (scl /= reg.x24c01.scl or reg.sda /= reg.x24c01.sda)) or
               (not board.datach and reg_d_write)
            then
                step := step_eeprom(reg.x24c01,
                                    X24C01,
                                    scl,
                                    reg.sda,
                                    cart_in.mem.data_from_chip_ram);
                ret.reg.x24c01 := step.eeprom;
                if not is_bus_active(ret.cart.mem.chip_ram_bus)
                then
                    ret.cart := eeprom_ram_bus(step,
                                               reg.x24c01,
                                               "10",
                                               ret.cart);
                end if;
            end if;
        end if;

        return ret;
    end;

    -- The CPU reads the EEPROMs at 0x6000-0x7FFF in bit 4, and the barcode
    -- reader of the Datach in bit 3. The other bits are open bus. The
    -- EEPROMs pull SDA low together; a board without one reads 0, as in
    -- Mesen
    function read_eeprom
    (
        reg      : mapper_bandai_reg_t;
        board    : bandai_board_t;
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable sda : std_logic;
    begin
        ret := cart_out;

        if board.lz93d50 and
           not board.prg_ram and
           is_bus_read(cart_in.cpu.prg_bus) and
           is_prg_ram_window(cart_in.cpu)
        then
            sda := to_std_logic(board.x24c02 or board.x24c01);
            if board.x24c02
            then
                sda := sda and reg.x24c02.output;
            end if;
            if board.x24c01
            then
                sda := sda and reg.x24c01.output;
            end if;

            ret.cpu.data := (4 => sda, others => '0');
            ret.cpu.data_oe := true;
            ret.cpu.data_float := x"E7";
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address. 0xC000 has the
    -- last 16KB of the 256KB outer bank, which only 153 has
    function get_prg_bank
    (
        reg    : mapper_bandai_reg_t;
        board  : bandai_board_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable bank : unsigned(4 downto 0);
    begin
        if window(1) = '1'
        then
            bank(prg_bank_t'range) := (others => '1');
        else
            bank(prg_bank_t'range) := reg.prg_bank;
        end if;

        if board.prg_ram
        then
            bank(4) := get_ppu_reg(reg)(0);
        else
            bank(4) := '0';
        end if;

        return resize(bank & window(0), prg_bank_8kb_t'length);
    end;

    function cycle_mapper_bandai
    (
        reg       : mapper_bandai_reg_t;
        irq_count : irq_counter_value_t;
        board     : bandai_board_t;
        config    : cart_config_t;
        clk_sync  : boolean;
        cart_in   : cart_in_t
    )
    return mapper_bandai_out_t
    is
        variable ret : mapper_bandai_out_t;
        variable banks : cart_banks_t;
        variable window : chr_window_t;
        variable eeproms : eeprom_cycle_t;
    begin
        -- The counter is clocked before the write of the CPU cycle, so a
        -- write to it or to the IRQ control is not undone by the clock
        ret.reg := cycle_write(cycle_irq(reg, irq_count, clk_sync),
                               board,
                               clk_sync,
                               cart_in);
        ret.irq_counter := get_irq_counter_op(reg, board, clk_sync, cart_in);

        if is_bus_active(cart_in.ppu.chr_bus)
        then
            ret.reg.ppu_reg_idx :=
                to_integer(cart_in.ppu.chr_bus.address(11 downto 10));
        end if;

        -- The PPU sees the registers written by the CPU this cycle
        window := get_chr_window(cart_in.ppu);
        banks := default_banks(config);
        banks.prg := get_prg_bank(ret.reg, board, get_prg_window(cart_in.cpu));
        if banks.chr_ram
        then
            banks.chr := resize(window, chr_bank_1kb_t'length);
        else
            banks.chr := resize(unsigned(ret.reg.chr_regs(to_integer(window))),
                                chr_bank_1kb_t'length);
        end if;
        banks.mirror := ret.reg.mirror;
        banks.prg_ram := board.prg_ram and ret.reg.prg_ram_enable;

        ret.cart := map_cart(config, cart_in, banks);
        ret.cart := read_eeprom(reg, board, cart_in, ret.cart);

        if board.x24c02 or board.x24c01
        then
            eeproms := cycle_eeproms(ret.reg,
                                     board,
                                     clk_sync,
                                     cart_in,
                                     ret.cart);
            ret.reg := eeproms.reg;
            ret.cart := eeproms.cart;
        end if;

        ret.cart.cpu.irq := reg.irq;

        return ret;
    end;

end package body;
