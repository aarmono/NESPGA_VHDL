library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.cart_types.all;

-- Boards built around the Jaleco SS 88006 (18). The chip sees only CPU A0,
-- A1 and A12-A14 and D0-D3, so each register is a nibble and the bank
-- numbers are written in two halves, the low nibble at the even address and
-- the high nibble at the odd one. There are three 8KB PRG ROM banks with the
-- last bank fixed at 0xE000, eight 1KB CHR ROM banks, 8KB of PRG RAM with an
-- enable and a write enable, and a 16-bit counter of CPU cycles, which can
-- count with only its low 4, 8 or 12 bits, that raises an IRQ.
--
-- Some boards have a uPD7756C ADPCM chip, started through 0xF003, whose
-- samples are in the ROM of the chip and not in the ROM file. It is not
-- emulated
package lib_mapper_ss88006 is

    -- The mapper number is that of a board built around the SS 88006
    function is_ss88006_mapper(mapper_num : mapper_num_t) return boolean;

    -- The PRG banks at 0x8000, 0xA000 and 0xC000. 0xE000 has the last bank
    subtype prg_bank_t is unsigned(5 downto 0);
    type prg_bank_arr_t is array(0 to 2) of prg_bank_t;

    subtype chr_bank_t is unsigned(7 downto 0);
    type chr_bank_arr_t is array(0 to 7) of chr_bank_t;

    -- The counter and its reload value are kept as nibbles, least
    -- significant first, as the chip counts them
    subtype irq_nibble_t is natural range 0 to 15;
    type irq_nibble_arr_t is array(0 to 3) of irq_nibble_t;
    -- The number of low nibbles of the counter that count
    subtype irq_width_t is natural range 1 to 4;

    type mapper_ss88006_reg_t is record
        prg_banks : prg_bank_arr_t;
        chr_banks : chr_bank_arr_t;

        -- PRG RAM is enabled. Otherwise the CPU reads open bus at 0x6000
        prg_ram_enable : boolean;
        prg_ram_write  : boolean;

        mirror    : mirror_t;

        irq_reload : irq_nibble_arr_t;
        irq_count  : irq_nibble_arr_t;
        irq_width  : irq_width_t;
        -- The counter is decremented every CPU cycle
        irq_enable : boolean;
        irq        : boolean;
    end record;

    -- The power on state is not known. PRG RAM is enabled, so a game that
    -- never writes 0x9002 can use it
    constant RESET_MAPPER_SS88006_REG : mapper_ss88006_reg_t :=
    (
        prg_banks => (others => (others => '0')),
        chr_banks => (others => (others => '0')),

        prg_ram_enable => true,
        prg_ram_write => true,

        mirror => MIRROR_HORZ,

        irq_reload => (others => 0),
        irq_count => (others => 0),
        irq_width => 4,
        irq_enable => false,
        irq => false
    );

    type mapper_ss88006_out_t is record
        reg  : mapper_ss88006_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_ss88006
    (
        reg      : mapper_ss88006_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_ss88006_out_t;

end package lib_mapper_ss88006;


package body lib_mapper_ss88006 is

    function is_ss88006_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        return mapper_num = x"012";
    end;

    -- Mirroring 0 is horizontal, 1 vertical, 2 one screen A and 3 one
    -- screen B
    function get_mirror(mode : std_logic_vector(1 downto 0)) return mirror_t
    is
    begin
        if mode(1) = '0'
        then
            return get_hv_mirror(not mode(0));
        else
            return get_single_screen_mirror(mode(0));
        end if;
    end;

    -- The low ('0') or high ('1') nibble of a bank number
    function set_nibble
    (
        bank : unsigned;
        upper : std_logic;
        data : data_t
    )
    return unsigned
    is
        variable ret : unsigned(bank'length - 1 downto 0);
    begin
        ret := bank;
        if upper = '0'
        then
            ret(3 downto 0) := unsigned(data(3 downto 0));
        else
            ret(ret'high downto 4) := unsigned(data(ret'high - 4 downto 0));
        end if;

        return ret;
    end;

    -- The width of the counter from bits 3-1 of 0xF001, of which the
    -- highest set wins: 4 bits for bit 3, 8 for bit 2, 12 for bit 1 and 16
    -- for none
    function get_irq_width(data : data_t) return irq_width_t
    is
    begin
        if data(3) = '1'
        then
            return 1;
        elsif data(2) = '1'
        then
            return 2;
        elsif data(1) = '1'
        then
            return 3;
        else
            return 4;
        end if;
    end;

    -- The registers are selected by CPU A14-A12 and A1, and A0 selects the
    -- nibble of a bank number
    function cycle_write
    (
        reg      : mapper_ss88006_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_ss88006_reg_t
    is
        variable ret : mapper_ss88006_reg_t;
        variable addr : prg_addr_t;
        variable data : data_t;
        -- The pair of registers, 0 for 0x8000/1, 1 for 0x8002/3, 2 for
        -- 0x9000/1 and so on
        variable pair : natural range 0 to 15;
        variable irq_idx : natural range 0 to 3;
    begin
        ret := reg;
        addr := cart_in.cpu.prg_bus.address;
        data := cart_in.cpu.data;
        pair := to_integer(addr(14 downto 12) & addr(1));
        irq_idx := to_integer(addr(1 downto 0));

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            case pair is
                when 0 to 2 =>
                    ret.prg_banks(pair) :=
                        set_nibble(reg.prg_banks(pair), addr(0), data);
                when 3 =>
                    if addr(0) = '0'
                    then
                        ret.prg_ram_enable := data(0) = '1';
                        ret.prg_ram_write := data(1) = '1';
                    end if;
                when 4 to 11 =>
                    ret.chr_banks(pair - 4) :=
                        set_nibble(reg.chr_banks(pair - 4), addr(0), data);
                when 12 | 13 =>
                    ret.irq_reload(irq_idx) :=
                        to_integer(data(3 downto 0));
                when 14 =>
                    if addr(0) = '0'
                    then
                        -- The full 16 bits are reloaded whatever the width
                        ret.irq_count := reg.irq_reload;
                    else
                        ret.irq_enable := data(0) = '1';
                        ret.irq_width := get_irq_width(data);
                    end if;
                    -- Both acknowledge the IRQ
                    ret.irq := false;
                when 15 =>
                    -- 0xF003, the ADPCM chip, is not emulated
                    if addr(0) = '0'
                    then
                        ret.mirror := get_mirror(data(1 downto 0));
                    end if;
            end case;
        end if;

        return ret;
    end;

    -- The counter is decremented every CPU cycle while it is enabled. The
    -- borrow of each nibble goes to the next one, except that the borrow of
    -- the highest nibble of the width raises an IRQ instead, so the nibbles
    -- above the width keep their value. The IRQ stays raised until it is
    -- acknowledged
    function cycle_irq
    (
        reg      : mapper_ss88006_reg_t;
        clk_sync : boolean
    )
    return mapper_ss88006_reg_t
    is
        variable ret : mapper_ss88006_reg_t;
        variable borrow : boolean;
    begin
        ret := reg;

        if clk_sync and reg.irq_enable
        then
            borrow := true;
            for i in irq_nibble_arr_t'range
            loop
                if borrow and i < reg.irq_width
                then
                    borrow := reg.irq_count(i) = 0;
                    if borrow
                    then
                        ret.irq_count(i) := irq_nibble_t'high;
                    else
                        ret.irq_count(i) := reg.irq_count(i) - 1;
                    end if;
                end if;
            end loop;

            ret.irq := reg.irq or borrow;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_ss88006_reg_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable idx : natural range 0 to 3;
    begin
        idx := to_integer(window);
        if idx = 3
        then
            return (others => '1');
        else
            return resize(reg.prg_banks(idx), prg_bank_8kb_t'length);
        end if;
    end;

    function cycle_mapper_ss88006
    (
        reg      : mapper_ss88006_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_ss88006_out_t
    is
        variable ret : mapper_ss88006_out_t;
        variable banks : cart_banks_t;
    begin
        -- The counter is clocked before the write of the CPU cycle, so a
        -- write to it or to the IRQ control is not undone by the clock
        ret.reg := cycle_irq(reg, clk_sync);
        ret.reg := cycle_write(ret.reg, clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle
        banks := default_banks(config);
        banks.prg_ram := ret.reg.prg_ram_enable;
        banks.prg := get_prg_bank(ret.reg, get_prg_window(cart_in.cpu));
        banks.chr := resize(ret.reg.chr_banks(
                                to_integer(get_chr_window(cart_in.ppu))),
                            chr_bank_1kb_t'length);
        banks.mirror := ret.reg.mirror;

        ret.cart := map_cart(config, cart_in, banks);
        if not ret.reg.prg_ram_write
        then
            ret.cart.mem.prg_ram_bus.write := false;
        end if;

        ret.cart.cpu.irq := reg.irq;

        return ret;
    end;

end package body;
