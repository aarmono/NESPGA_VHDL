library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_apu_length.all;
use work.lib_apu_envelope.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_noise is

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

    function get_audio(noise : noise_t) return audio_t;

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

end lib_apu_noise;

package body lib_apu_noise is

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
        if is_zero(cur_val.count)
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
            when others => return x"---";
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

    function get_audio(noise : noise_t) return audio_t
    is
    begin
        if enable_output(noise.random) and
           enable_output(noise.length)
        then
            return get_audio(noise.envelope);
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
        -- if there was a write to the fourth channel register since
        -- the last clock, the counter is set to 15 and the divider
        -- is reset
        ret.envelope := reload(val.envelope);

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

end package body;