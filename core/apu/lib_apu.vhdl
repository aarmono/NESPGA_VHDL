library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;
use work.apu_bus_types.all;
use work.utilities.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu is

    -- Sequencer

    subtype frame_seq_div_t is unsigned(12 downto 0);
    subtype frame_seq_step_t is unsigned(2 downto 0);

    type frame_seq_t is record
        divider     : frame_seq_div_t;
        mode_5      : boolean;
        irq_disable : boolean;
        step        : frame_seq_step_t;
    end record;

    constant RESET_FRAME_SEQ : frame_seq_t :=
    (
      divider => (others => '0'),
      mode_5 => false,
      irq_disable => false,
      step => (others => '0')
    );

    function update_envelope(seq : frame_seq_t) return boolean;

    function update_length(seq : frame_seq_t) return boolean;

    function irq(seq : frame_seq_t) return boolean;

    function next_sequence(cur_val : frame_seq_t) return frame_seq_t;

    function write_reg
    (
        val : frame_seq_t;
        reg : std_logic_vector(1 downto 0)
    )
    return frame_seq_t;

    constant DIV_START : frame_seq_div_t :=
        to_unsigned(7456, frame_seq_div_t'length);

    -- Envelope
    
    subtype envelope_count_t is unsigned(3 downto 0);
    subtype envelope_divider_t is unsigned(3 downto 0);
    subtype envelope_period_t is unsigned(3 downto 0);
    
    type envelope_t is record
        reset    : boolean;
        loop_env : boolean;
        disable  : boolean;
        count    : envelope_count_t;
        divider  : envelope_divider_t;
        period   : envelope_period_t;
    end record;

    constant RESET_ENVELOPE : envelope_t :=
    (
        reset => false,
        loop_env => false,
        disable => false,
        count => (others => '0'),
        divider => (others => '0'),
        period => (others => '0')
    );

    function audio(envelope : envelope_t) return audio_t;

    function next_envelope(cur_val : envelope_t) return envelope_t;

    function write_reg
    (
        val : envelope_t;
        reg : std_logic_vector(5 downto 0)
    )
    return envelope_t;

    function reload(val : envelope_t) return envelope_t;

    -- Length Counter
    
    subtype length_count_t is unsigned(7 downto 0);
    subtype length_idx_t is std_logic_vector(4 downto 0);
    
    type length_t is record
        count  : length_count_t;
        halt   : boolean;
        enable : boolean;
    end record;

    constant RESET_LENGTH : length_t :=
    (
        count => (others => '0'),
        halt => false,
        enable => false
    );

    function get_length_val
    (
        idx : length_idx_t
    )
    return length_count_t;

    function enable_output(length : length_t) return boolean;

    function next_length(cur_val : length_t) return length_t;

    function is_zero(val : length_t) return boolean;

    -- Linear Counter {
    
    subtype linear_count_t is unsigned(6 downto 0);
    
    type linear_t is record
        halt       : boolean;
        control    : boolean;
        count      : linear_count_t;
        reload_val : linear_count_t;
    end record;

    constant RESET_LINEAR : linear_t :=
    (
        halt => false,
        control => false,
        count => (others => '0'),
        reload_val => (others => '0')
    );

    function enable_output(linear : linear_t) return boolean;

    function next_linear(cur_val : linear_t) return linear_t;

    function write_reg(val : linear_t; reg : data_t) return linear_t;

    -- Triangle Channel

    -- Triangle Sequencer
    
    subtype triangle_seq_val_t is unsigned(3 downto 0);
    
    type triangle_seq_t is record
        value      : triangle_seq_val_t;
        descending : boolean;
    end record;

    constant RESET_TRIANGLE_SEQ : triangle_seq_t :=
    (
        value => (others => '1'),
        descending => true
    );

    function next_triangle_seq(cur_val : triangle_seq_t) return triangle_seq_t;
    
    subtype triangle_count_t is unsigned(10 downto 0);

    type triangle_t is record
        count  : triangle_count_t;
        period : triangle_count_t;
        linear : linear_t;
        length : length_t;
        seq    : triangle_seq_t;
    end record;

    constant RESET_TRIANGLE : triangle_t :=
    (
        count => (others => '0'),
        period => (others => '0'),
        linear => RESET_LINEAR,
        length => RESET_LENGTH,
        seq => RESET_TRIANGLE_SEQ
    );

    function audio(triangle : triangle_t) return audio_t;

    function next_triangle
    (
        cur_val       : triangle_t;
        update_linear : boolean;
        update_length : boolean
    )
    return triangle_t;

    function write_reg_0(val : triangle_t; reg : data_t) return triangle_t;

    function write_reg_1(val : triangle_t; reg : data_t) return triangle_t;

    function write_reg_2(val : triangle_t; reg : data_t) return triangle_t;

    function write_reg_3(val : triangle_t; reg : std_logic) return triangle_t;

    function get_status(val : triangle_t) return std_logic;

    -- Square Channel

    -- Sweep Unit
    
    subtype sweep_divider_t is unsigned(2 downto 0);
    subtype sweep_count_t is unsigned(3 downto 0);
    subtype sweep_period_t is unsigned(10 downto 0);
    subtype sweep_tgt_period_t is unsigned(11 downto 0);
    subtype sweep_shift_t is unsigned(2 downto 0);
    subtype sweep_incr_t is unsigned(0 downto 0);

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
        period => (others => '0'),
        enable => false,
        negate => false,
        reset => false,
        shift => (others => '0')
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
    
    subtype square_seq_timer_t is unsigned(11 downto 0);
    subtype square_seq_cycle_t is unsigned(2 downto 0);
    subtype square_seq_duty_t is std_logic_vector(1 downto 0);
    
    type square_seq_t is record
        timer : square_seq_timer_t;
        cycle : square_seq_cycle_t;
        duty  : square_seq_duty_t;
    end record;

    constant RESET_SQUARE_SEQ : square_seq_t :=
    (
        timer => (others => '0'),
        cycle => (others => '0'),
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

    function audio
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

    function write_reg_3(val : square_t; reg : data_t) return square_t;

    function write_reg_4(val : square_t; reg : std_logic) return square_t;

    function get_status(val : square_t) return std_logic;

    -- Noise Channel

    -- Random Shifter

    subtype random_idx_t is std_logic_vector(3 downto 0);
    subtype random_count_t is unsigned(11 downto 0);
    subtype random_shift_t is std_logic_vector(14 downto 0);

    type random_t is record
        period_idx : random_idx_t;
        count      : random_count_t;
        short_mode : boolean;
        shift      : random_shift_t;
    end record;

    constant RESET_RANDOM : random_t :=
    (
        period_idx => (others => '0'),
        count => (others => '0'),
        short_mode => false,
        shift => b"000_0000_0000_0001"
    );

    function enable_output(val : random_t) return boolean;

    function get_random_period
    (
        idx : random_idx_t
    )
    return random_count_t;

    function next_random(cur_val : random_t) return random_t;

    function write_reg(val : random_t; reg : data_t) return random_t;

    type noise_t is record
        envelope : envelope_t;
        random   : random_t;
        length   : length_t;
    end record;

    constant RESET_NOISE : noise_t :=
    (
        envelope => RESET_ENVELOPE,
        random => RESET_RANDOM,
        length => RESET_LENGTH
    );

    function audio(noise : noise_t) return audio_t;

    function next_noise
    (
        cur_val         : noise_t;
        update_envelope : boolean;
        update_length   : boolean
    )
    return noise_t;

    function write_reg_0(val : noise_t; reg : data_t) return noise_t;

    function write_reg_1(val : noise_t; reg : data_t) return noise_t;

    function write_reg_2(val : noise_t; reg : data_t) return noise_t;

    function write_reg_3(val : noise_t; reg : std_logic) return noise_t;

    function get_status(val : noise_t) return std_logic;

    type reg_t is record
        frame_seq : frame_seq_t;
        square_1  : square_t;
        square_2  : square_t;
        triangle  : triangle_t;
        noise     : noise_t;
        irq       : boolean;
    end record;

    type apu_output_t is record
        reg          : reg_t;
        audio        : apu_out_t;
        cpu_data_out : data_t;
        irq          : boolean;
    end record;

    function cycle_apu
    (
        reg         : reg_t;
        cpu_bus     : apu_bus_t;
        cpu_data_in : data_t;
        reset       : boolean
    )
    return apu_output_t;

end lib_apu;

package body lib_apu is

    -- Sequencer {
    function update_envelope(seq : frame_seq_t) return boolean
    is
    begin
        return seq.divider = ZERO(seq.divider) and
               seq.step <= "011";
    end;

    function update_length(seq : frame_seq_t) return boolean
    is
    begin
        return seq.divider = ZERO(seq.divider) and
               ((not seq.mode_5 and (seq.step = "001" or seq.step = "011")) or
                (seq.mode_5 and (seq.step = "000" or seq.step = "010")));
    end;

    function irq(seq : frame_seq_t) return boolean
    is
    begin
        return not seq.mode_5 and
               seq.step = "011" and
               not seq.irq_disable and
               seq.divider = ZERO(seq.divider);
    end;

    function next_sequence(cur_val : frame_seq_t) return frame_seq_t
    is
        variable next_val : frame_seq_t;
    begin
        next_val := cur_val;
        if cur_val.divider = ZERO(cur_val.divider)
        then
            next_val.divider := DIV_START;
            if (not cur_val.mode_5 and cur_val.step = "011") or
               (cur_val.mode_5 and cur_val.step = "100")
            then
                next_val.step := ZERO(cur_val.step);
            else
                next_val.step := cur_val.step + "1";
            end if;
        else
            next_val.divider := cur_val.divider - "1";
        end if;

        return next_val;
    end;

    function write_reg
    (
        val : frame_seq_t;
        reg : std_logic_vector(1 downto 0)
    )
    return frame_seq_t
    is
        variable ret : frame_seq_t;
    begin
        ret := val;
        ret.mode_5 := reg(1) = '1';
        ret.irq_disable := reg(0) = '1';
        ret.step := "000";
        -- If the mode flag is set, the sequencer is immediately clocked once
        if ret.mode_5
        then
            ret.divider := ZERO(val.divider);
        else
            ret.divider := DIV_START;
        end if;

        return ret;
    end;

    -- Envelope {

    -- audio function {
    function audio(envelope : envelope_t) return audio_t
    is
    begin
        -- When disable is set, the channel's volume is n (the period)
        if envelope.disable
        then
            return envelope.period;
        -- otherwise it is the value in the counter
        else
            return envelope.count;
        end if;
    end;

    -- next_envelope function {
    function next_envelope(cur_val : envelope_t) return envelope_t
    is
        variable next_val : envelope_t;
        variable next_divider : envelope_divider_t;
    begin
        next_val := cur_val;
        -- The divider's period is set to n + 1
        next_divider := resize(cur_val.period, next_val.divider'length) + "1";
        -- If there was a write to the fourth channel register
        -- since the last clock, the counter is set to 15 and
        -- the divider is reset
        if cur_val.reset
        then
            next_val.count := x"F";
            next_val.divider := next_divider;
            next_val.reset := false;
        -- otherwise, the divider is clocked
        elsif cur_val.divider = ZERO(cur_val.divider)
        then
            next_val.divider := next_divider;
            -- if loop is set and counter is zero, it is
            -- set to 15
            if cur_val.loop_env and cur_val.count = ZERO(cur_val.count)
            then
                next_val.count := x"F";
            -- otherwise if counter is non-zero, it is decremented
            elsif cur_val.count /= ZERO(cur_val.count)
            then
                next_val.count := cur_val.count - "1";
            end if;
        else
            next_val.divider := cur_val.divider - "1";
        end if;

        return next_val;
    end;

    -- write_reg function {
    function write_reg
    (
        val : envelope_t;
        reg : std_logic_vector(5 downto 0)
    )
    return envelope_t
    is
        variable ret : envelope_t;
    begin
        ret := val;
        ret.loop_env := reg(5) = '1';
        ret.disable := reg(4) = '1';
        ret.period := unsigned(reg(3 downto 0));

        return ret;
    end;

    -- reload function {
    function reload(val : envelope_t) return envelope_t
    is
        variable ret : envelope_t;
    begin
        ret := val;
        ret.reset := true;

        return ret;
    end;

    -- Length Counter {

    -- get_length_val function {
    function get_length_val
    (
        idx : length_idx_t
    )
    return length_count_t
    is
    begin
        case idx is
            when "00000" => return x"0A";
            when "00001" => return x"FE";
            when "00010" => return x"14";
            when "00011" => return x"02";
            when "00100" => return x"28";
            when "00101" => return x"04";
            when "00110" => return x"50";
            when "00111" => return x"06";
            when "01000" => return x"A0";
            when "01001" => return x"08";
            when "01010" => return x"3C";
            when "01011" => return x"0A";
            when "01100" => return x"0E";
            when "01101" => return x"0C";
            when "01110" => return x"1A";
            when "01111" => return x"0E";
            when "10000" => return x"0C";
            when "10001" => return x"10";
            when "10010" => return x"18";
            when "10011" => return x"12";
            when "10100" => return x"30";
            when "10101" => return x"14";
            when "10110" => return x"60";
            when "10111" => return x"16";
            when "11000" => return x"C0";
            when "11001" => return x"18";
            when "11010" => return x"48";
            when "11011" => return x"1A";
            when "11100" => return x"10";
            when "11101" => return x"1C";
            when "11110" => return x"20";
            when "11111" => return x"1E";
            when others  => return x"--";
        end case;
    end;

    -- enable_output function {
    function enable_output(length : length_t) return boolean
    is
    begin
        return length.count /= ZERO(length.count);
    end;

    -- next_length function {
    function next_length(cur_val : length_t) return length_t
    is
        variable next_val : length_t;
    begin
        next_val := cur_val;
        -- If the halt flag is clear and the counter is non-zero,
        -- it is decremented
        if not cur_val.halt and cur_val.count /= ZERO(cur_val.count)
        then
            next_val.count := cur_val.count - "1";
        end if;

        return next_val;
    end;

    -- is_zero function {
    function is_zero(val : length_t) return boolean
    is
    begin
        return val.count = ZERO(val.count);
    end;

    -- write_reg_0 function {
    function write_reg_0(val : length_t; reg : std_logic) return length_t
    is
        variable ret : length_t;
    begin
        ret := val;
        ret.halt := reg = '1';

        return ret;
    end;

    -- write_reg_1 function {
    function write_reg_1
    (
        val : length_t;
        reg : std_logic_vector(4 downto 0)
    )
    return length_t
    is
        variable ret : length_t;
    begin
        ret := val;
        if ret.enable
        then
            ret.count := get_length_val(reg);
        end if;

        return ret;
    end;

    -- write_reg_2 function {
    function write_reg_2
    (
        val : length_t;
        reg : std_logic
    )
    return length_t
    is
        variable ret : length_t;
    begin
        ret := val;
        ret.enable := reg = '1';
        if not ret.enable
        then
            ret.count := ZERO(ret.count);
        end if;

        return ret;
    end;

    -- Linear Counter {
    function enable_output(linear : linear_t) return boolean
    is
    begin
        -- Pass through output when count is non-zero
        return linear.count /= ZERO(linear.count);
    end;

    function next_linear(cur_val : linear_t) return linear_t
    is
        variable next_val : linear_t;
    begin
        next_val := cur_val;
        -- If halt flag is set, set counter to reload value
        if cur_val.halt
        then
            next_val.count := cur_val.reload_val;
        -- Otherwise if counter is non-zero, decrement it
        elsif cur_val.count /= ZERO(cur_val.count)
        then
            next_val.count := cur_val.count - "1";
        end if;

        -- If control flag is clear, clear halt flag
        if not cur_val.control
        then
            next_val.halt := false;
        end if;

        return next_val;
    end;

    function write_reg(val : linear_t; reg : data_t) return linear_t
    is
        variable ret : linear_t;
    begin
        ret := val;
        ret.reload_val := unsigned(reg(6 downto 0));
        ret.control := reg(7) = '1';

        return ret;
    end;

    -- Triangle Channel {

    -- next_triangle_seq function {
    function next_triangle_seq(cur_val : triangle_seq_t) return triangle_seq_t
    is
        variable next_val : triangle_seq_t;
    begin
        next_val := cur_val;
        if cur_val.descending
        then
            if cur_val.value = x"0"
            then
                next_val.descending := false;
            else
                next_val.value := cur_val.value - "1";
            end if;
        else
            if cur_val.value = x"F"
            then
                next_val.descending := true;
            else
                next_val.value := cur_val.value + "1";
            end if;
        end if;

        return next_val;
    end;

    -- audio function {
    function audio(triangle : triangle_t) return audio_t
    is
    begin
        return audio_t(triangle.seq.value);
    end;

    -- get_status function
    function get_status(val : triangle_t) return std_logic
    is
    begin
        return to_std_logic(not is_zero(val.length));
    end;

    -- next_triangle function {
    function next_triangle
    (
        cur_val       : triangle_t;
        update_linear : boolean;
        update_length : boolean
    )
    return triangle_t
    is
        variable next_val        : triangle_t;
        variable update_sequence : boolean;
    begin
        next_val := cur_val;
        if cur_val.count = ZERO(cur_val.count)
        then
            next_val.count := cur_val.period;
        else
            next_val.count := cur_val.count - "1";
        end if;

        if update_linear
        then
            next_val.linear := next_linear(cur_val.linear);
        end if;

        if update_length
        then
            next_val.length := next_length(cur_val.length);
        end if;

        update_sequence := cur_val.count = ZERO(cur_val.count) and
                           enable_output(cur_val.linear) and
                           enable_output(cur_val.length);
        if update_sequence
        then
            next_val.seq := next_triangle_seq(cur_val.seq);
        end if;

        return next_val;
    end;

    -- write_reg_0 function {
    function write_reg_0(val : triangle_t; reg : data_t) return triangle_t
    is
        variable ret : triangle_t;
    begin
        ret := val;
        ret.linear := write_reg(val.linear, reg);
        ret.length := write_reg_0(val.length, reg(7));

        return ret;
    end;

    -- write_reg_1 function {
    function write_reg_1(val : triangle_t; reg : data_t) return triangle_t
    is
        variable ret : triangle_t;
    begin
        ret := val;
        ret.period(7 downto 0) := unsigned(reg);

        return ret;
    end;

    -- write_reg_2 function {
    function write_reg_2(val : triangle_t; reg : data_t) return triangle_t
    is
        variable ret : triangle_t;
    begin
        ret := val;
        ret.length := write_reg_1(val.length, reg(7 downto 3));
        ret.period(10 downto 8) := unsigned(reg(2 downto 0));
        -- when register $400B is written to, the halt flag is set
        ret.linear.halt := true;

        return ret;
    end;

    -- write_reg_3 function {
    function write_reg_3(val : triangle_t; reg : std_logic) return triangle_t
    is
        variable ret : triangle_t;
    begin
        ret := val;
        ret.length := write_reg_2(val.length, reg);

        return ret;
    end;

    -- Square Channel {

    -- Sweep Unit {

    -- shift_period function {
    function shift_period
    (
        sweep : sweep_t;
        incr  : sweep_incr_t
    )
    return sweep_tgt_period_t
    is
        variable overflow : std_logic;
        variable shift_res : sweep_period_t;
        variable result : sweep_tgt_period_t;
    begin
        -- The channel's period is first shifted right by shift bits
        shift_res := sweep.period srl to_integer(sweep.shift);
        -- If negate is set, the shifted value's bits are inverted and
        -- on the second square channel the inverted value is incremented
        -- by 1
        if sweep.negate
        then
            shift_res := (not shift_res) + incr;
        end if;

        result := resize(sweep.period, result'length) +
                  resize(shift_res, result'length);
        -- In particular, if the negate flag is false, the shift count is
        -- zero, and the current period is at least $400, the target period
        -- will be large enough to mute the channel.
        
        -- We interpret this as the MSB being an overflow bit set if ths MSB of
        -- the target period is high and the negate bit isn't set
        overflow := result(result'high) and not to_std_logic(sweep.negate);
        -- The resulting value is added with the channel's current
        -- period, yielding the final result
        return overflow & result(sweep_period_t'range);
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
        variable next_div_count : sweep_count_t;
    begin
        next_val := cur_val;
        shift_val := shift_period(cur_val, incr);
        -- The divider's period is set to p + 1.
        next_div_count := resize(cur_val.divider, next_div_count'length) + "1";
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
        if cur_val.div_count = ZERO(cur_val.div_count)
        then
            next_val.reset := false;
            next_val.div_count := next_div_count;
            if cur_val.enable and
               cur_val.shift /= ZERO(cur_val.shift) and
               sweep_valid(cur_val.period, shift_val)
            then
                next_val.period := shift_val(next_val.period'range);
            end if;
        elsif cur_val.reset
        then
            next_val.reset := false;
            next_val.div_count := next_div_count;
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
        return (cur_period >= to_unsigned(8, cur_period'length)) and
               (target_period <= to_unsigned(16#7FF#, target_period'length));
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
        ret.shift := unsigned(reg(2 downto 0));

        return ret;
    end;

    -- write_reg_1 function {
    function write_reg_1(val : sweep_t; reg : data_t) return sweep_t
    is
        variable ret : sweep_t;
    begin
        ret := val;
        ret.period(7 downto 0) := unsigned(reg);

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
        ret.period(10 downto 8) := unsigned(reg);
        ret.reset := true;

        return ret;
    end;

    function enable_output(seq : square_seq_t) return boolean
    is
    begin
        case seq.duty is
            when "00" => return seq.cycle = "001";
            when "01" => return seq.cycle >= "001" and seq.cycle <= "010";
            when "10" => return seq.cycle >= "001" and seq.cycle <= "100";
            when "11" => return not (seq.cycle >= "001" and seq.cycle <= "010");
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
        -- the third and fourth registers form an 11-bit value
        -- and the divider's period is set to this value *plus one*.
        return (period + "1") & '0';
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
        ret.cycle := ZERO(val.cycle);

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
        if cur_val.timer = ZERO(cur_val.timer)
        then
            next_val.timer := square_timer_from_period(period);
            next_val.cycle := cur_val.cycle + "1";
        else
            next_val.timer := cur_val.timer - "1";
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

    function audio
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
            return audio(square.envelope);
        else
            return (others => '0');
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

    function write_reg_3(val : square_t; reg : data_t) return square_t
    is
        variable ret : square_t;
    begin
        ret := val;
        ret.length := write_reg_1(val.length, reg(7 downto 3));
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

    function enable_output(val : random_t) return boolean
    is
    begin
        return val.shift(0) = '1';
    end;

    function next_random(cur_val : random_t) return random_t
    is
        variable next_val : random_t;
        variable shift_in : std_logic;
    begin
        next_val := cur_val;
        if cur_val.count = ZERO(cur_val.count)
        then
            next_val.count := get_random_period(cur_val.period_idx);
            if cur_val.short_mode
            then
                shift_in := cur_val.shift(6) xor cur_val.shift(0);
            else
                shift_in := cur_val.shift(1) xor cur_val.shift(0);
            end if;

            next_val.shift := shift_in & cur_val.shift(14 downto 1);
        else
            next_val.count := cur_val.count - "1";
        end if;

        return next_val;
    end;

    function write_reg(val : random_t; reg : data_t) return random_t
    is
        variable ret : random_t;
    begin
        ret := val;
        ret.period_idx := reg(3 downto 0);
        ret.short_mode := reg(7) = '1';

        return ret;
    end;

    function get_random_period
    (
        idx : random_idx_t
    )
    return random_count_t
    is
    begin
        case idx is
            when x"0" => return x"004";
            when x"1" => return x"008";
            when x"2" => return x"010";
            when x"3" => return x"020";
            when x"4" => return x"040";
            when x"5" => return x"060";
            when x"6" => return x"080";
            when x"7" => return x"0A0";
            when x"8" => return x"0C0";
            when x"9" => return x"0FE";
            when x"A" => return x"17C";
            when x"B" => return x"1FC";
            when x"C" => return x"2FA";
            when x"D" => return x"3F8";
            when x"E" => return x"7F2";
            when x"F" => return x"FE4";
            when others => return x"000";
        end case;
    end;

    function next_noise
    (
        cur_val         : noise_t;
        update_envelope : boolean;
        update_length   : boolean
    )
    return noise_t
    is
        variable next_val : noise_t;
    begin
        next_val := cur_val;
        if update_envelope
        then
            next_val.envelope := next_envelope(cur_val.envelope);
        end if;

        if update_length
        then
            next_val.length := next_length(cur_val.length);
        end if;

        next_val.random := next_random(cur_val.random);

        return next_val;
    end;

    -- get_status function
    function get_status(val : noise_t) return std_logic
    is
    begin
        return to_std_logic(not is_zero(val.length));
    end;

    function audio(noise : noise_t) return audio_t
    is
    begin
        if enable_output(noise.random) and
           enable_output(noise.length)
        then
            return audio(noise.envelope);
        else
            return (others => '0');
        end if;
    end;

    function write_reg_0(val : noise_t; reg : data_t) return noise_t
    is
        variable ret : noise_t;
    begin
        ret := val;
        ret.envelope := write_reg(val.envelope, reg(5 downto 0));
        ret.length := write_reg_0(val.length, reg(5));

        return ret;
    end;

    function write_reg_1(val : noise_t; reg : data_t) return noise_t
    is
        variable ret : noise_t;
    begin
        ret := val;
        ret.random := write_reg(val.random, reg);

        return ret;
    end;

    function write_reg_2(val : noise_t; reg : data_t) return noise_t
    is
        variable ret : noise_t;
    begin
        ret := val;
        ret.length := write_reg_1(val.length, reg(7 downto 3));

        return ret;
    end;

    function write_reg_3(val : noise_t; reg : std_logic) return noise_t
    is
        variable ret : noise_t;
    begin
        ret := val;
        ret.length := write_reg_2(val.length, reg);

        return ret;
    end;

    function cycle_apu
    (
        reg         : reg_t;
        cpu_bus     : apu_bus_t;
        cpu_data_in : data_t;
        reset       : boolean
    )
    return apu_output_t
    is
        -- Internal variables
        variable v_audio           : apu_out_t;
        variable v_update_envelope : boolean;
        variable v_update_length   : boolean;
        variable v_reg             : reg_t;
        variable v_cpu_data_out    : data_t;

        -- Return value
        variable ret : apu_output_t;
    begin
        v_cpu_data_out   := (others => '-');
        v_reg            := reg;
        v_audio.square_1 := work.lib_apu.audio(reg.square_1, "0");
        v_audio.square_2 := work.lib_apu.audio(reg.square_2, "1");
        v_audio.triangle := work.lib_apu.audio(reg.triangle);
        v_audio.noise    := work.lib_apu.audio(reg.noise);
        
        if work.lib_apu.irq(reg.frame_seq)
        then
            v_reg.irq := true;
        end if;
        
        v_update_envelope := update_envelope(reg.frame_seq);
        v_update_length := update_length(reg.frame_seq);
        
        v_reg.triangle := next_triangle(reg.triangle,
                                        v_update_envelope,
                                        v_update_length);
        v_reg.square_1 := next_square(reg.square_1,
                                      v_update_envelope,
                                      v_update_length,
                                      "0");
        v_reg.square_2 := next_square(reg.square_2,
                                      v_update_envelope,
                                      v_update_length,
                                      "1");
        v_reg.noise := next_noise(reg.noise,
                                  v_update_envelope,
                                  v_update_length);
        v_reg.frame_seq := next_sequence(reg.frame_seq);
        
        -- Memory map {
        if is_bus_write(cpu_bus)
        then
            case cpu_bus.address is
                -- Square Channel 1
                when "00000" =>
                    v_reg.square_1 := write_reg_0(v_reg.square_1, cpu_data_in);
                when "00001" =>
                    v_reg.square_1 := write_reg_1(v_reg.square_1, cpu_data_in);
                when "00010" =>
                    v_reg.square_1 := write_reg_2(v_reg.square_1, cpu_data_in);
                when "00011" =>
                    v_reg.square_1 := write_reg_3(v_reg.square_1, cpu_data_in);

                -- Square Channel 2
                when "00100" =>
                    v_reg.square_2 := write_reg_0(v_reg.square_2, cpu_data_in);
                when "00101" =>
                    v_reg.square_2 := write_reg_1(v_reg.square_2, cpu_data_in);
                when "00110" =>
                    v_reg.square_2 := write_reg_2(v_reg.square_2, cpu_data_in);
                when "00111" =>
                    v_reg.square_2 := write_reg_3(v_reg.square_2, cpu_data_in);

                -- Triangle Channel
                -- Linear Counter registers
                when "01000" =>
                    v_reg.triangle := write_reg_0(v_reg.triangle, cpu_data_in);
                -- Timer period low
                when "01010" =>
                    v_reg.triangle := write_reg_1(v_reg.triangle, cpu_data_in);
                -- Timer period high and length counter reload
                when "01011" =>
                    v_reg.triangle := write_reg_2(v_reg.triangle, cpu_data_in);

                -- Noise Channel
                when "01100" =>
                    v_reg.noise := write_reg_0(v_reg.noise, cpu_data_in);
                when "01110" =>
                    v_reg.noise := write_reg_1(v_reg.noise, cpu_data_in);
                when "01111" =>
                    v_reg.noise := write_reg_2(v_reg.noise, cpu_data_in);
                -- DMC Channel
                when "10000" =>
                when "10001" =>
                when "10010" =>
                when "10011" =>
                -- Common
                when "10101" =>
                    v_reg.square_1 := write_reg_4(reg.square_1, cpu_data_in(0));
                    v_reg.square_2 := write_reg_4(reg.square_2, cpu_data_in(1));
                    v_reg.triangle := write_reg_3(reg.triangle, cpu_data_in(2));
                    v_reg.noise := write_reg_3(reg.noise, cpu_data_in(3));
                when "10111" =>
                    v_reg.frame_seq := write_reg(v_reg.frame_seq, 
                                                 cpu_data_in(7 downto 6));
                when others =>
            end case;
        elsif is_bus_read(cpu_bus) and
              cpu_bus.address = "10101"
        then
            v_cpu_data_out := 
            (
                6 => to_std_logic(reg.irq),
                3 => get_status(reg.noise),
                2 => get_status(reg.triangle),
                1 => get_status(reg.square_2),
                0 => get_status(reg.square_1),
                others => '0'
            );
            v_reg.irq := false;
        end if;
        -- }
        
        if reset then
            v_reg.frame_seq := RESET_FRAME_SEQ;
            v_reg.square_1 := RESET_SQUARE;
            v_reg.square_2 := RESET_SQUARE;
            v_reg.triangle := RESET_TRIANGLE;
            v_reg.noise := RESET_NOISE;
            v_reg.irq := false;
        end if;
        
        ret.reg := v_reg;
        ret.audio := v_audio;
        ret.cpu_data_out := v_cpu_data_out;
        ret.irq := reg.irq;

        return ret;
    end;

end package body;