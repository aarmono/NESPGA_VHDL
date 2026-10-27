library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package utilities is
    type boolean_array is array (natural range <>) of boolean;
    
    function shift_left(val : boolean_array; lsb : boolean) return boolean_array;

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

    function to_std_logic_vector
    (
        val  : natural;
        size : positive
    )
    return std_logic_vector;

    function shift_right(val : natural; shift : natural) return natural;

    -- Integer equivalents of unsigned vector operations. high is the 'high
    -- of a subtype whose range is 0 to 2**n-1, like an n bit vector
    function wrap(val : integer; high : natural) return natural;
    function invert(val : natural; high : natural) return natural;

    -- Equivalent of val(hi downto lo)
    function get_bits(val : natural; hi, lo : natural) return natural;
    -- Equivalent of val(lo + field'length - 1 downto lo) := field
    function set_bits
    (
        val   : natural;
        lo    : natural;
        field : std_logic_vector
    )
    return natural;

    function max(a, b : integer) return integer;
    -- Greatest common divisor
    function gcd(a, b : positive) return positive;

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

    function shift_left(val : boolean_array; lsb : boolean) return boolean_array
    is
        variable ret : boolean_array(val'range);
    begin
        for i in val'high downto val'low+1
        loop
            ret(i) := val(i - 1);
        end loop;
        
        ret(val'low) := lsb;
        
        return ret;
    end function;

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

    -- Faster in simulation than numeric_std's to_integer, which converts
    -- the vector with to_01 first. Any bit other than '1' is treated as '0'.
    function to_integer(val : std_logic_vector) return integer is
        variable ret : natural;
    begin
        ret := 0;
        for i in val'range
        loop
            ret := ret * 2;
            if val(i) = '1'
            then
                ret := ret + 1;
            end if;
        end loop;

        return ret;
    end function;

    function shift_right(val : natural; shift : natural) return natural
    is
    begin
        if shift >= 31
        then
            return 0;
        end if;

        return val / (2 ** shift);
    end;

    -- Faster in simulation than numeric_std's to_unsigned
    function to_std_logic_vector
    (
        val  : natural;
        size : positive
    )
    return std_logic_vector
    is
        variable ret : std_logic_vector(size-1 downto 0);
        variable rem_val : natural;
    begin
        rem_val := val;
        for i in ret'reverse_range
        loop
            if rem_val mod 2 = 1
            then
                ret(i) := '1';
            else
                ret(i) := '0';
            end if;
            rem_val := rem_val / 2;
        end loop;

        return ret;
    end;

    -- Reduce val into 0 to high, like an unsigned adder that wraps around
    function wrap(val : integer; high : natural) return natural
    is
    begin
        return val mod (high + 1);
    end;

    -- Bitwise not
    function invert(val : natural; high : natural) return natural
    is
    begin
        return high - val;
    end;

    function get_bits(val : natural; hi, lo : natural) return natural
    is
    begin
        return (val / 2**lo) mod 2**(hi - lo + 1);
    end;

    function set_bits
    (
        val   : natural;
        lo    : natural;
        field : std_logic_vector
    )
    return natural
    is
        constant SCALE : positive := 2**lo;
        constant WIDTH : positive := 2**field'length;
    begin
        -- A sum of the bits above, the field and the bits below, which
        -- don't overlap, so synthesis builds it without adders
        return (val / (SCALE * WIDTH)) * (SCALE * WIDTH) +
               to_integer(field) * SCALE + val mod SCALE;
    end;

    function max(a, b : integer) return integer
    is
    begin
        if a > b
        then
            return a;
        else
            return b;
        end if;
    end;

    function gcd(a, b : positive) return positive
    is
        variable x : natural := a;
        variable y : natural := b;
        variable r : natural;
    begin
        while y /= 0
        loop
            r := x mod y;
            x := y;
            y := r;
        end loop;

        return x;
    end;
    
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
        for i in val'range
        loop
            if val(i) /= '0'
            then
                return false;
            end if;
        end loop;

        return true;
    end;
    
    function zero(val : unsigned) return unsigned
    is
    begin
        return unsigned(zero(std_logic_vector(val)));
    end;
    
    function is_zero(val : unsigned) return boolean
    is
    begin
        return is_zero(std_logic_vector(val));
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
        for i in val'range
        loop
            if val(i) /= '1'
            then
                return false;
            end if;
        end loop;

        return true;
    end;
    
    function max_val(val : unsigned) return unsigned
    is
    begin
        return unsigned(max_val(std_logic_vector(val)));
    end;
    
    function is_max_val(val : unsigned) return boolean
    is
    begin
        return is_max_val(std_logic_vector(val));
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
