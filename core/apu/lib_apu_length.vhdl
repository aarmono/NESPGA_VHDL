library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;
use work.utilities.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_length is

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

end package body;