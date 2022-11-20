library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_length is

    subtype length_count_t is unsigned(7 downto 0);
    subtype length_idx_t is unsigned(4 downto 0);

    type length_arr_t is array(0 to 16#1F#) of length_count_t;
    constant LENGTH_ARR : length_arr_t :=
    (
        x"0A",
        x"FE",
        x"14",
        x"02",
        x"28",
        x"04",
        x"50",
        x"06",
        x"A0",
        x"08",
        x"3C",
        x"0A",
        x"0E",
        x"0C",
        x"1A",
        x"0E",
        x"0C",
        x"10",
        x"18",
        x"12",
        x"30",
        x"14",
        x"60",
        x"16",
        x"C0",
        x"18",
        x"48",
        x"1A",
        x"10",
        x"1C",
        x"20",
        x"1E"
    );
    
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
    
    function write_reg_0(val : length_t; reg : std_logic) return length_t;
    
    function write_reg_1
    (
        val : length_t;
        reg : std_logic_vector(4 downto 0)
    )
    return length_t;
    
    function write_reg_2
    (
        val : length_t;
        reg : std_logic
    )
    return length_t;

end lib_apu_length;

package body lib_apu_length is

    -- get_length_val function {
    function get_length_val
    (
        idx : length_idx_t
    )
    return length_count_t
    is
    begin
        return LENGTH_ARR(to_integer(idx));
    end;

    -- enable_output function {
    function enable_output(length : length_t) return boolean
    is
    begin
        return not is_zero(length.count);
    end;

    -- next_length function {
    function next_length(cur_val : length_t) return length_t
    is
        variable next_val : length_t;
    begin
        next_val := cur_val;
        -- If the halt flag is clear and the counter is non-zero,
        -- it is decremented
        if not cur_val.halt and not is_zero(cur_val.count)
        then
            next_val.count := cur_val.count - "1";
        end if;

        return next_val;
    end;

    -- is_zero function {
    function is_zero(val : length_t) return boolean
    is
    begin
        return is_zero(val.count);
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
            ret.count := get_length_val(unsigned(reg));
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

end package body;