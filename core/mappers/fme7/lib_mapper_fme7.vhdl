library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;
use work.lib_sunsoft_5b_audio.all;
use work.lib_irq_counter.all;

-- Boards built around the Sunsoft FME-7, 5A or 5B (69): JLROM and JSROM.
-- The CPU writes a command number to 0x8000 and its parameter to 0xA000.
-- There are eight 1KB CHR ROM banks and four 8KB PRG banks, the first of
-- which is at 0x6000 and holds PRG ROM or PRG RAM, and a 16-bit counter of
-- CPU cycles that raises an IRQ. The 5B adds audio, whose registers are
-- selected at 0xC000 and written at 0xE000. It is built only with
-- BOARD_SUNSOFT_5B, since the boards cannot tell the chips apart
package lib_mapper_fme7 is

    -- The mapper number is that of a board built around the FME-7
    function is_fme7_mapper(mapper_num : mapper_num_t) return boolean;

    subtype command_t is natural range 0 to 15;

    -- The FME-7 has 6 bits of PRG bank. The 5A and 5B have 5, but no game
    -- for them has PRG ROM large enough for the difference to matter
    subtype prg_bank_t is unsigned(5 downto 0);
    -- The banks at 0x6000, 0x8000, 0xA000 and 0xC000, set by commands 0x8
    -- to 0xB. 0xE000 has the last bank
    type prg_bank_arr_t is array(0 to 3) of prg_bank_t;

    subtype chr_bank_t is unsigned(7 downto 0);
    type chr_bank_arr_t is array(0 to 7) of chr_bank_t;

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
        irq              : boolean;

        audio            : s5b_audio_t;
    end record;

    constant RESET_MAPPER_FME7_REG : mapper_fme7_reg_t :=
    (
        command => 0,

        prg_banks => (others => (others => '0')),
        prg_ram_select => false,
        prg_ram_enable => false,

        chr_banks => (others => (others => '0')),

        mirror => MIRROR_VERT,

        irq_enable => false,
        irq_count_enable => false,
        irq => false,

        audio => RESET_S5B_AUDIO
    );

    -- The counter is kept by the cartridge, and irq_counter is what the
    -- board does to it
    type mapper_fme7_out_t is record
        reg         : mapper_fme7_reg_t;
        cart        : cart_out_t;
        irq_counter : irq_counter_op_t;
    end record;

    -- The audio of the 5B is built when sunsoft_5b is set. irq_count is the
    -- count of the counter
    function cycle_mapper_fme7
    (
        reg        : mapper_fme7_reg_t;
        irq_count  : irq_counter_value_t;
        sunsoft_5b : boolean;
        config     : cart_config_t;
        clk_sync   : boolean;
        cart_in    : cart_in_t
    )
    return mapper_fme7_out_t;

end package lib_mapper_fme7;


package body lib_mapper_fme7 is

    function is_fme7_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        return mapper_num = x"045";
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

        case reg.command is
            when 0 to 7 =>
                ret.chr_banks(reg.command) := unsigned(data);
            when 8 to 11 =>
                ret.prg_banks(reg.command - 8) :=
                    unsigned(data(prg_bank_t'range));

                if reg.command = 8
                then
                    ret.prg_ram_select := data(6) = '1';
                    ret.prg_ram_enable := data(7) = '1';
                end if;
            when 12 =>
                ret.mirror := get_hv_single_screen_mirror(data(1 downto 0));
            when 13 =>
                ret.irq_enable := data(0) = '1';
                ret.irq_count_enable := data(7) = '1';
                -- Acknowledges the IRQ
                ret.irq := false;
            -- The counter. See get_irq_counter_op
            when 14 to 15 =>
        end case;

        return ret;
    end;

    function cycle_write
    (
        reg        : mapper_fme7_reg_t;
        sunsoft_5b : boolean;
        clk_sync   : boolean;
        cart_in    : cart_in_t
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
                    ret.command := to_integer(cart_in.cpu.data(3 downto 0));
                when "01" =>
                    ret := write_parameter(reg, cart_in.cpu.data);
                when "10" =>
                    if sunsoft_5b
                    then
                        ret.audio := write_s5b_select(reg.audio,
                                                      cart_in.cpu.data);
                    end if;
                when others =>
                    if sunsoft_5b
                    then
                        ret.audio := write_s5b_data(reg.audio,
                                                    cart_in.cpu.data);
                    end if;
            end case;
        end if;

        return ret;
    end;

    -- The counter is decremented every CPU cycle while it is enabled, and
    -- raises an IRQ when it wraps from 0 to 0xFFFF. The IRQ stays raised
    -- until it is acknowledged
    function cycle_irq
    (
        reg       : mapper_fme7_reg_t;
        irq_count : irq_counter_value_t;
        clk_sync  : boolean
    )
    return mapper_fme7_reg_t
    is
        variable ret : mapper_fme7_reg_t;
    begin
        ret := reg;

        if clk_sync and reg.irq_count_enable and irq_count = 0
        then
            ret.irq := reg.irq or reg.irq_enable;
        end if;

        return ret;
    end;

    -- The clock of the counter, and the parameters of commands 0xE and 0xF,
    -- its low and high bytes
    function get_irq_counter_op
    (
        reg      : mapper_fme7_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return irq_counter_op_t
    is
        variable ret : irq_counter_op_t;
    begin
        ret := IRQ_COUNTER_IDLE;
        ret.clock := clk_sync and reg.irq_count_enable;

        if is_rom_write(cart_in.cpu, clk_sync) and
           cart_in.cpu.prg_bus.address(14 downto 13) = "01"
        then
            case reg.command is
                when 14 => ret.write := IRQ_COUNTER_COUNT_LOW;
                when 15 => ret.write := IRQ_COUNTER_COUNT_HIGH;
                when others =>
            end case;
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
        variable idx : natural range 0 to 3;
    begin
        idx := to_integer(std_logic_vector(window));
        if not romsel
        then
            return resize(reg.prg_banks(0), prg_bank_8kb_t'length);
        elsif idx = 3
        then
            return (others => '1');
        else
            return resize(reg.prg_banks(idx + 1), prg_bank_8kb_t'length);
        end if;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_fme7_reg_t;
        window : chr_window_t
    )
    return chr_bank_1kb_t
    is
    begin
        return resize(reg.chr_banks(to_integer(std_logic_vector(window))),
                      chr_bank_1kb_t'length);
    end;

    function cycle_mapper_fme7
    (
        reg        : mapper_fme7_reg_t;
        irq_count  : irq_counter_value_t;
        sunsoft_5b : boolean;
        config     : cart_config_t;
        clk_sync   : boolean;
        cart_in    : cart_in_t
    )
    return mapper_fme7_out_t
    is
        variable ret : mapper_fme7_out_t;
        variable banks : cart_banks_t;
    begin
        -- The counter and the audio are clocked before the write of the CPU
        -- cycle, so a write to them or to the IRQ control is not undone by
        -- the clock
        ret.reg := cycle_irq(reg, irq_count, clk_sync);
        ret.irq_counter := get_irq_counter_op(reg, clk_sync, cart_in);
        if sunsoft_5b
        then
            ret.reg.audio := cycle_s5b_audio(reg.audio, clk_sync);
        end if;
        ret.reg := cycle_write(ret.reg, sunsoft_5b, clk_sync, cart_in);

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
        banks.chr := get_chr_bank(ret.reg, get_chr_window(cart_in.ppu));
        banks.mirror := ret.reg.mirror;

        ret.cart := map_cart(config, cart_in, banks);

        ret.cart.cpu.irq := reg.irq;
        if sunsoft_5b
        then
            ret.cart.audio := get_s5b_audio_level(reg.audio);
        end if;

        return ret;
    end;

end package body;
