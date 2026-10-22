library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

-- Boards built around the Sunsoft FME-7, 5A or 5B (69): JLROM and JSROM.
-- The CPU writes a command number to 0x8000 and its parameter to 0xA000.
-- There are eight 1KB CHR ROM banks and four 8KB PRG banks, the first of
-- which is at 0x6000 and holds PRG ROM or PRG RAM, and a 16-bit counter of
-- CPU cycles that raises an IRQ. The audio of the 5B is not emulated
package lib_mapper_fme7 is

    -- The mapper number is that of a board built around the FME-7
    function is_fme7_mapper(mapper_num : mapper_num_t) return boolean;

    subtype command_t is unsigned(3 downto 0);

    -- The FME-7 has 6 bits of PRG bank. The 5A and 5B have 5, but no game
    -- for them has PRG ROM large enough for the difference to matter
    subtype prg_bank_t is unsigned(5 downto 0);
    -- The banks at 0x6000, 0x8000, 0xA000 and 0xC000, set by commands 0x8
    -- to 0xB. 0xE000 has the last bank
    type prg_bank_arr_t is array(0 to 3) of prg_bank_t;

    subtype chr_bank_t is unsigned(7 downto 0);
    type chr_bank_arr_t is array(0 to 7) of chr_bank_t;

    subtype irq_count_t is natural range 0 to 2**16-1;

    type mapper_fme7_reg_t is record
        command   : command_t;

        prg_banks : prg_bank_arr_t;
        -- 0x6000 has PRG RAM rather than PRG ROM
        prg_ram_select : boolean;
        -- PRG RAM is enabled. When it is selected but not enabled, the CPU
        -- reads open bus at 0x6000
        prg_ram_enable : boolean;

        chr_banks : chr_bank_arr_t;

        mirror    : mirror_t;

        -- An IRQ is raised when the counter wraps
        irq_enable       : boolean;
        -- The counter is decremented every CPU cycle
        irq_count_enable : boolean;
        irq_count        : irq_count_t;
        irq              : boolean;
    end record;

    constant RESET_MAPPER_FME7_REG : mapper_fme7_reg_t :=
    (
        command => (others => '0'),

        prg_banks => (others => (others => '0')),
        prg_ram_select => false,
        prg_ram_enable => false,

        chr_banks => (others => (others => '0')),

        mirror => MIRROR_VERT,

        irq_enable => false,
        irq_count_enable => false,
        irq_count => 0,
        irq => false
    );

    type mapper_fme7_out_t is record
        reg  : mapper_fme7_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_fme7
    (
        reg      : mapper_fme7_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_fme7_out_t;

end package lib_mapper_fme7;


package body lib_mapper_fme7 is

    function is_fme7_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        return mapper_num = x"045";
    end;

    -- The mirroring selected by the parameter of command 0xC
    function get_mirror(data : data_t) return mirror_t
    is
    begin
        case data(1 downto 0) is
            when "00" => return MIRROR_VERT;
            when "01" => return MIRROR_HORZ;
            when "10" => return MIRROR_A;
            when others => return MIRROR_B;
        end case;
    end;

    -- The parameter of the command in the command register
    function write_parameter
    (
        reg  : mapper_fme7_reg_t;
        data : data_t
    )
    return mapper_fme7_reg_t
    is
        variable ret : mapper_fme7_reg_t;
    begin
        ret := reg;

        case to_integer(reg.command) is
            when 0 to 7 =>
                ret.chr_banks(to_integer(reg.command(2 downto 0))) :=
                    unsigned(data);
            when 8 to 11 =>
                ret.prg_banks(to_integer(reg.command(1 downto 0))) :=
                    unsigned(data(prg_bank_t'range));

                if reg.command(1 downto 0) = "00"
                then
                    ret.prg_ram_select := data(6) = '1';
                    ret.prg_ram_enable := data(7) = '1';
                end if;
            when 12 =>
                ret.mirror := get_mirror(data);
            when 13 =>
                ret.irq_enable := data(0) = '1';
                ret.irq_count_enable := data(7) = '1';
                -- Acknowledges the IRQ
                ret.irq := false;
            when 14 =>
                ret.irq_count := set_bits(reg.irq_count, 0, data);
            when others =>
                ret.irq_count := set_bits(reg.irq_count, 8, data);
        end case;

        return ret;
    end;

    function cycle_write
    (
        reg      : mapper_fme7_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_fme7_reg_t
    is
        variable ret : mapper_fme7_reg_t;
    begin
        ret := reg;

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            case cart_in.cpu.prg_bus.address(14 downto 13) is
                when "00" =>
                    ret.command := unsigned(cart_in.cpu.data(command_t'range));
                when "01" =>
                    ret := write_parameter(reg, cart_in.cpu.data);
                -- The audio registers of the 5B
                when others =>
                    null;
            end case;
        end if;

        return ret;
    end;

    -- The counter is decremented every CPU cycle while it is enabled, and
    -- raises an IRQ when it wraps from 0 to 0xFFFF. The IRQ stays raised
    -- until it is acknowledged
    function cycle_irq
    (
        reg      : mapper_fme7_reg_t;
        clk_sync : boolean
    )
    return mapper_fme7_reg_t
    is
        variable ret : mapper_fme7_reg_t;
    begin
        ret := reg;

        if clk_sync and reg.irq_count_enable
        then
            if reg.irq_count = 0
            then
                ret.irq_count := irq_count_t'high;
                ret.irq := reg.irq or reg.irq_enable;
            else
                ret.irq_count := reg.irq_count - 1;
            end if;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address, or at 0x6000
    function get_prg_bank
    (
        reg    : mapper_fme7_reg_t;
        romsel : boolean;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
    begin
        if not romsel
        then
            return resize(reg.prg_banks(0), prg_bank_8kb_t'length);
        elsif window = "11"
        then
            return (others => '1');
        else
            return resize(reg.prg_banks(to_integer(window) + 1),
                          prg_bank_8kb_t'length);
        end if;
    end;

    function cycle_mapper_fme7
    (
        reg      : mapper_fme7_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_fme7_out_t
    is
        variable ret : mapper_fme7_out_t;
        variable banks : cart_banks_t;
    begin
        -- The counter is clocked before the write of the CPU cycle, so a
        -- write to it or to the IRQ control is not undone by the clock
        ret.reg := cycle_write(cycle_irq(reg, clk_sync), clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle
        banks := default_banks(config);
        banks.prg_ram := ret.reg.prg_ram_select and ret.reg.prg_ram_enable;
        banks.prg_rom_6000 := not ret.reg.prg_ram_select;
        -- The bank number is put out for PRG RAM too, so a board with more
        -- than 8KB of PRG RAM can bank it
        banks.prg_ram_bank := resize(ret.reg.prg_banks(0),
                                     prg_ram_bank_8kb_t'length);
        banks.prg := get_prg_bank(ret.reg,
                                  cart_in.cpu.romsel,
                                  get_prg_window(cart_in.cpu));
        banks.chr :=
            resize(ret.reg.chr_banks(to_integer(get_chr_window(cart_in.ppu))),
                   chr_bank_1kb_t'length);
        banks.mirror := ret.reg.mirror;

        ret.cart := map_cart(config, cart_in, banks);

        ret.cart.cpu.irq := reg.irq;

        return ret;
    end;

end package body;
