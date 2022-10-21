library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;
use work.utilities.all;
use work.lib_apu_length.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_triangle is

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

    function get_audio(triangle : triangle_t) return audio_t;

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

end lib_apu_triangle;

package body lib_apu_triangle is

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
        elsif not is_zero(cur_val.count)
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
    function get_audio(triangle : triangle_t) return audio_t
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
        if is_zero(cur_val.count)
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

        update_sequence := is_zero(cur_val.count) and
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

end package body;