library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package utilities is
    function reverse_vector(data : std_logic_vector) return std_logic_vector;
    
    function to_std_logic(data : boolean) return std_logic;
    
    function to_unsigned(val : std_logic; size : positive) return unsigned;
    
    function to_unsigned(val : boolean; size : positive) return unsigned;
    
    function to_std_logic_vector
    (
        val  : std_logic;
        size : positive
    )
    return std_logic_vector;
    
    function to_std_logic_vector
    (
        val  : boolean;
        size : positive
    )
    return std_logic_vector;
    
    function add_vectors
    (
        val1 : std_logic_vector;
        val2 : std_logic_vector
    )
    return std_logic_vector;
    
    function to_integer(val : std_logic_vector) return integer;
    
    function zero(val : std_logic_vector) return std_logic_vector;
    function zero(val : unsigned) return unsigned;
    
    function is_zero(val : std_logic_vector) return boolean;
    function is_zero(val : unsigned) return boolean;
    
    function max_val(val : std_logic_vector) return std_logic_vector;
    function max_val(val : unsigned) return unsigned;
    
    function is_max_val(val : std_logic_vector) return boolean;
    function is_max_val(val : unsigned) return boolean;
    
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
    
    function to_unsigned(val : std_logic; size : positive) return unsigned
    is
    begin
        return unsigned(to_std_logic_vector(val, size));
    end;
    
    function to_unsigned(val : boolean; size : positive) return unsigned
    is
    begin
        return to_unsigned(to_std_logic(val), size);
    end;
    
    function to_std_logic_vector
    (
        val  : std_logic;
        size : positive
    )
    return std_logic_vector
    is
        variable ret : std_logic_vector(size-1 downto 0);
    begin
        ret := (others => '0');
        ret(0) := val;
        
        return ret;
    end;
    
    function to_std_logic_vector
    (
        val  : boolean;
        size : positive
    )
    return std_logic_vector
    is
    begin
        return to_std_logic_vector(to_std_logic(val), size);
    end;
    
    function to_std_logic_vector(val : character) return std_logic_vector
    is
    begin
        return std_logic_vector(to_unsigned(character'pos(val), 8));
    end;

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
    
    function is_zero(val : std_logic_vector) return boolean
    is
    begin
        return val = zero(val);
    end;
    
    function zero(val : unsigned) return unsigned
    is
    begin
        return unsigned(zero(std_logic_vector(val)));
    end;
    
    function is_zero(val : unsigned) return boolean
    is
    begin
        return val = zero(val);
    end;
    
    function max_val(val : std_logic_vector) return std_logic_vector
    is
        constant ret : std_logic_vector(val'RANGE) := (others => '1');
    begin
        return ret;
    end;
    
    function is_max_val(val : std_logic_vector) return boolean
    is
    begin
        return val = max_val(val);
    end;
    
    function max_val(val : unsigned) return unsigned
    is
    begin
        return unsigned(max_val(std_logic_vector(val)));
    end;
    
    function is_max_val(val : unsigned) return boolean
    is
    begin
        return val = max_val(val);
    end;
    
    function resize(val : std_logic_vector; len : natural) return std_logic_vector
    is
    begin
        return std_logic_vector(resize(unsigned(val), len));
    end;

    --procedure shift_right(signal val : std_logic_vector)
    --is
    --begin
    --    val <= "0" & val(val'high downto 1);
    --end procedure;
    
end package body;
