library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;
use work.utilities.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_envelope is

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

    function get_audio(envelope : envelope_t) return audio_t;

    function next_envelope(cur_val : envelope_t) return envelope_t;

    function write_reg
    (
        val : envelope_t;
        reg : std_logic_vector(5 downto 0)
    )
    return envelope_t;

    function reload(val : envelope_t) return envelope_t;

end lib_apu_envelope;


package body lib_apu_envelope is

    -- audio function {
    function get_audio(envelope : envelope_t) return audio_t
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

end package body;