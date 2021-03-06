library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package utilities is
    function reverse_vector(data : std_logic_vector) return std_logic_vector;
    function to_std_logic(data : boolean) return std_logic;
    function to_integer(val : std_logic_vector) return integer;
    
    function add_vectors
    (
        val1 : std_logic_vector;
        val2 : std_logic_vector
    )
    return std_logic_vector;
    
    function zero(val : std_logic_vector) return std_logic_vector;
    function zero(val : unsigned) return unsigned;
    
    function resize(val : std_logic_vector; len : natural) return std_logic_vector;
    function to_std_logic_vector(val : character) return std_logic_vector;

    --procedure shift_right(signal val : std_logic_vector);
    
end utilities;

package body utilities is

    function reverse_vector(data : std_logic_vector) return std_logic_vector is
        variable reversed : std_logic_vector(data'RANGE);
        alias rev_data : std_logic_vector(data'REVERSE_RANGE) is data;
    begin
        for i in rev_data'RANGE loop
            reversed(i) := rev_data(i);
        end loop;
        
        return reversed;
    end function;

    function to_std_logic(data : boolean) return std_logic is
        variable result : std_logic;
    begin
        case data is
            when true => result := '1';
            when false => result := '0';
        end case;
        return result;
    end function;

    function to_integer(val : std_logic_vector) return integer is
    begin
        return to_integer(unsigned(val));
    end function;
    
    function add_vectors
    (
        val1 : std_logic_vector;
        val2 : std_logic_vector
    )
    return std_logic_vector
    is
    begin
        return std_logic_vector(unsigned(val1) + unsigned(val2));
    end;
    
    function zero(val : std_logic_vector) return std_logic_vector
    is
        constant ret : std_logic_vector(val'RANGE) := (others => '0');
    begin
        return ret;
    end;
    
    function zero(val : unsigned) return unsigned
    is
    begin
        return unsigned(zero(std_logic_vector(val)));
    end;
    
    function resize(val : std_logic_vector; len : natural) return std_logic_vector
    is
    begin
        return std_logic_vector(resize(unsigned(val), len));
    end;
    
    function to_std_logic_vector(val : character) return std_logic_vector
    is
    begin
        return std_logic_vector(to_unsigned(character'pos(val), 8));
    end;

    --procedure shift_right(signal val : std_logic_vector)
    --is
    --begin
    --    val <= "0" & val(val'high downto 1);
    --end procedure;
    
end package body;
