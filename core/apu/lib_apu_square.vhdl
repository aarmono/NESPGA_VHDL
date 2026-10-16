library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_apu_length.all;
use work.lib_apu_envelope.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_square is

    -- Sweep Unit
    
    subtype sweep_divider_t is unsigned(2 downto 0);
    subtype sweep_count_t is unsigned(2 downto 0);
    subtype sweep_period_t is natural range 0 to 2**11-1;
    subtype sweep_tgt_period_t is natural range 0 to 2**12-1;
    subtype sweep_shift_t is natural range 0 to 7;
    subtype sweep_incr_t is natural range 0 to 1;

    type sweep_t is record
        divider   : sweep_divider_t;
        div_count : sweep_count_t;
        period    : sweep_period_t;
        enable    : boolean;
        negate    : boolean;
        reset     : boolean;
        shift     : sweep_shift_t;
    end record;

    constant RESET_SWEEP : sweep_t :=
    (
        divider => (others => '0'),
        div_count => (others => '0'),
        period => 0,
        enable => false,
        negate => false,
        reset => false,
        shift => 0
    );

    function enable_output
    (
        sweep : sweep_t;
        incr : sweep_incr_t
    )
    return boolean;

    function next_sweep
    (
        cur_val : sweep_t;
        incr  : sweep_incr_t
    )
    return sweep_t;

    function shift_period
    (
        sweep : sweep_t;
        incr  : sweep_incr_t
    )
    return sweep_tgt_period_t;
    
    function sweep_valid
    (
        cur_period    : sweep_period_t;
        target_period : sweep_tgt_period_t
    )
    return boolean;

    function write_reg_0(val : sweep_t; reg : data_t) return sweep_t;

    function write_reg_1(val : sweep_t; reg : data_t) return sweep_t;

    function write_reg_2
    (
        val : sweep_t;
        reg : std_logic_vector(2 downto 0)
    )
    return sweep_t;

    -- Sequencer
    
    subtype square_seq_timer_t is natural range 0 to 2**12-1;
    subtype square_seq_cycle_t is natural range 0 to 7;
    subtype square_seq_duty_t is std_logic_vector(1 downto 0);
    
    type square_seq_t is record
        timer : square_seq_timer_t;
        cycle : square_seq_cycle_t;
        duty  : square_seq_duty_t;
    end record;

    constant RESET_SQUARE_SEQ : square_seq_t :=
    (
        timer => 0,
        cycle => 0,
        duty => (others => '0')
    );
    
    function square_timer_from_period
    (
        period : sweep_period_t
    )
    return square_seq_timer_t;

    function enable_output(seq : square_seq_t) return boolean;

    function next_square_seq
    (
        cur_val : square_seq_t;
        period  : sweep_period_t
    )
    return square_seq_t;

    function write_reg
    (
        val : square_seq_t;
        reg : std_logic_vector(1 downto 0)
    )
    return square_seq_t;

    function reload
    (
        val    : square_seq_t;
        period : sweep_period_t
    )
    return square_seq_t;

    type square_t is record
        envelope : envelope_t;
        sweep    : sweep_t;
        seq      : square_seq_t;
        length   : length_t;
    end record;

    constant RESET_SQUARE : square_t :=
    (
        envelope => RESET_ENVELOPE,
        sweep => RESET_SWEEP,
        seq => RESET_SQUARE_SEQ,
        length => RESET_LENGTH
    );

    function get_audio
    (
        square : square_t;
        incr   : sweep_incr_t
    )
    return audio_t;

    function next_square
    (
        cur_val         : square_t;
        update_envelope : boolean;
        update_length   : boolean;
        incr            : sweep_incr_t
    )
    return square_t;

    function write_reg_0(val : square_t; reg : data_t) return square_t;

    function write_reg_1(val : square_t; reg : data_t) return square_t;

    function write_reg_2(val : square_t; reg : data_t) return square_t;

    function write_reg_3
    (
        val           : square_t;
        reg           : data_t;
        update_length : boolean
    )
    return square_t;

    function write_reg_4(val : square_t; reg : std_logic) return square_t;

    function get_status(val : square_t) return std_logic;

end lib_apu_square;

package body lib_apu_square is

    -- Sweep Unit {

    -- shift_period function {
    function shift_period
    (
        sweep : sweep_t;
        incr  : sweep_incr_t
    )
    return sweep_tgt_period_t
    is
        variable shift_res : sweep_period_t;
        variable result : sweep_tgt_period_t;
    begin
        -- The channel's period is first shifted right by shift bits
        shift_res := shift_right(sweep.period, sweep.shift);
        -- If negate is set, the shifted value's bits are inverted and
        -- on the second square channel the inverted value is incremented
        -- by 1
        if sweep.negate
        then
            shift_res := wrap(invert(shift_res, sweep_period_t'high) + incr,
                              sweep_period_t'high);
        end if;

        result := sweep.period + shift_res;
        -- In particular, if the negate flag is false, the shift count is
        -- zero, and the current period is at least $400, the target period
        -- will be large enough to mute the channel.
        
        -- We interpret this as the MSB being an overflow bit set if ths MSB of
        -- the target period is high and the negate bit isn't set
        if sweep.negate
        then
            result := wrap(result, sweep_period_t'high);
        end if;
        -- The resulting value is added with the channel's current
        -- period, yielding the final result
        return result;
    end;

    -- enable_output function {
    function enable_output
    (
        sweep : sweep_t;
        incr  : sweep_incr_t
    )
    return boolean
    is
        variable shift_val : sweep_tgt_period_t;
    begin
        shift_val := shift_period(sweep, incr);
        -- When the channel's period is less than 8 or the result of the shifter is
        -- greater than $7FF, the channel's DAC receives 0
        return sweep_valid(sweep.period, shift_val);
    end;

    -- next_sweep function {
    function next_sweep
    (
        cur_val : sweep_t;
        incr    : sweep_incr_t
    )
    return sweep_t
    is
        variable next_val : sweep_t;
        variable shift_val : sweep_tgt_period_t;
        variable reset_div_count : sweep_count_t;
    begin
        next_val := cur_val;
        shift_val := shift_period(cur_val, incr);
        -- The divider's period is P + 1 half-frames
        reset_div_count := cur_val.divider;
        -- When the sweep unit is clocked, the divider is first clocked
        -- and if there was a write to the sweep register since the
        -- last sweep clock, the divider is reset.
        --
        -- When the channel's period is less than 8 or the result
        -- of the shifter is greater than 0x7FF, the sweep unit doesn't
        -- change the channel's period.
        -- 
        -- Otherwise, if the sweep unit is enabled and the shift count
        -- is greater than 0, when the divider outputs a clock,
        -- the channel's period is updated with the result of the shifter
        if is_zero(cur_val.div_count)
        then
            next_val.reset := false;
            next_val.div_count := reset_div_count;
            if cur_val.enable and
               cur_val.shift /= 0 and
               sweep_valid(cur_val.period, shift_val)
            then
                next_val.period := wrap(shift_val, sweep_period_t'high);
            end if;
        elsif cur_val.reset
        then
            next_val.reset := false;
            next_val.div_count := reset_div_count;
        else
            next_val.div_count := cur_val.div_count - "1";
        end if;

        return next_val;
    end;
    
    -- sweep_valid function {
    function sweep_valid
    (
        cur_period    : sweep_period_t;
        target_period : sweep_tgt_period_t
    )
    return boolean
    is
    begin
        -- When the channel's period is less than 8 or the result of the
        -- shifter is greater than $7FF, the channel's DAC receives 0 and
        -- the sweep unit doesn't change the channel's period.
        return cur_period >= 8 and target_period <= 16#7FF#;
    end;
    -- }

    -- write_reg_0 function {
    function write_reg_0(val : sweep_t; reg : data_t) return sweep_t
    is
        variable ret : sweep_t;
    begin
        ret := val;
        ret.enable := reg(7) = '1';
        ret.divider := unsigned(reg(6 downto 4));
        ret.negate := reg(3) = '1';
        ret.shift := to_integer(reg(2 downto 0));

        return ret;
    end;

    -- write_reg_1 function {
    function write_reg_1(val : sweep_t; reg : data_t) return sweep_t
    is
        variable ret : sweep_t;
    begin
        ret := val;
        ret.period := set_bits(ret.period, 0, reg);

        return ret;
    end;

    -- write_reg_2 function {
    function write_reg_2
    (
        val : sweep_t;
        reg : std_logic_vector(2 downto 0)
    )
    return sweep_t
    is
        variable ret : sweep_t;
    begin
        ret := val;
        ret.period := set_bits(ret.period, 8, reg);
        ret.reset := true;

        return ret;
    end;

    function enable_output(seq : square_seq_t) return boolean
    is
    begin
        case seq.duty is
            when "00" => return seq.cycle = 1;
            when "01" => return seq.cycle >= 1 and seq.cycle <= 2;
            when "10" => return seq.cycle >= 1 and seq.cycle <= 4;
            when "11" => return not (seq.cycle >= 1 and seq.cycle <= 2);
            when others => return false;
        end case;
    end;
    
    function square_timer_from_period
    (
        period : sweep_period_t
    )
    return square_seq_timer_t
    is
    begin
        -- The divider's period is P + 1 half-frames
        return period * 2;
    end;

    function reload
    (
        val    : square_seq_t;
        period : sweep_period_t
    )
    return square_seq_t
    is
        variable ret : square_seq_t;
    begin
        ret := val;
        ret.timer := square_timer_from_period(period);
        ret.cycle := 0;

        return ret;
    end;

    function next_square_seq
    (
        cur_val : square_seq_t;
        period  : sweep_period_t
    )
    return square_seq_t
    is
        variable next_val : square_seq_t;
    begin
        next_val := cur_val;
        if cur_val.timer = 0
        then
            next_val.timer := square_timer_from_period(period);
            next_val.cycle := wrap(cur_val.cycle + 1, square_seq_cycle_t'high);
        else
            next_val.timer := cur_val.timer - 1;
        end if;

        return next_val;
    end;

    function write_reg
    (
        val : square_seq_t;
        reg : std_logic_vector(1 downto 0)
    )
    return square_seq_t
    is
        variable ret : square_seq_t;
    begin
        ret := val;
        ret.duty := reg;

        return ret;
    end;

    function get_audio
    (
        square : square_t;
        incr   : sweep_incr_t
    )
    return audio_t
    is
    begin
        if enable_output(square.sweep, incr) and
           enable_output(square.seq) and
           enable_output(square.length)
        then
            return get_audio(square.envelope);
        else
            return 0;
        end if;
    end;

    -- get_status function
    function get_status(val : square_t) return std_logic
    is
    begin
        return to_std_logic(not is_zero(val.length));
    end;

    function next_square
    (
        cur_val         : square_t;
        update_envelope : boolean;
        update_length   : boolean;
        incr            : sweep_incr_t
    )
    return square_t
    is
        variable next_val : square_t;
    begin
        next_val := cur_val;
        if update_length
        then
            next_val.sweep := next_sweep(cur_val.sweep, incr);
            next_val.length := next_length(cur_val.length);
        end if;

        -- Period calculated by sweep module is fed into 
        -- sequencer when it needs to be reloaded
        next_val.seq := next_square_seq(cur_val.seq,
                                        next_val.sweep.period);

        if update_envelope
        then
            next_val.envelope := next_envelope(cur_val.envelope);
        end if;

        return next_val;
    end;

    function write_reg_0(val : square_t; reg : data_t) return square_t
    is
        variable ret : square_t;
    begin
        ret := val;
        ret.seq := write_reg(val.seq, reg(7 downto 6));
        ret.envelope := write_reg(val.envelope, reg(5 downto 0));
        ret.length := write_reg_0(val.length, reg(5));

        return ret;
    end;

    function write_reg_1(val : square_t; reg : data_t) return square_t
    is
        variable ret : square_t;
    begin
        ret := val;
        ret.sweep := write_reg_0(val.sweep, reg);

        return ret;
    end;

    function write_reg_2(val : square_t; reg : data_t) return square_t
    is
        variable ret : square_t;
    begin
        ret := val;
        ret.sweep := write_reg_1(val.sweep, reg);

        return ret;
    end;

    function write_reg_3
    (
        val           : square_t;
        reg           : data_t;
        update_length : boolean
    )
    return square_t
    is
        variable ret : square_t;
    begin
        ret := val;
        ret.length := write_reg_1(val.length, reg(7 downto 3), update_length);
        ret.sweep := write_reg_2(val.sweep, reg(2 downto 0));
        -- Writes to fourth register reset envelope and force reload
        -- of sequencer period
        ret.envelope := reload(val.envelope);
        ret.seq := reload(val.seq, ret.sweep.period);

        return ret;
    end;

    function write_reg_4(val : square_t; reg : std_logic) return square_t
    is
        variable ret : square_t;
    begin
        ret := val;
        ret.length := write_reg_2(val.length, reg);

        return ret;
    end;

end package body;