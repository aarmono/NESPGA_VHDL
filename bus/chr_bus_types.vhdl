library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package chr_bus_types is
   
    subtype chr_addr_t is std_logic_vector(13 downto 0);
    type chr_bus_t is record
        address  : chr_addr_t;
        read     : boolean;
        write    : boolean;
    end record;
    
    constant CHR_BUS_IDLE : chr_bus_t :=
    (
        address => (others => '-'),
        read => false,
        write => false
    );
    
    function bus_read(addr_in : chr_addr_t) return chr_bus_t;
    function bus_read(addr_in : unsigned(chr_addr_t'RANGE)) return chr_bus_t;
    function bus_write(addr_in : chr_addr_t) return chr_bus_t;
    function bus_write(addr_in : unsigned(chr_addr_t'RANGE)) return chr_bus_t;
    function bus_idle(bus_in : chr_bus_t) return chr_bus_t;
    
    function is_bus_active(bus_in : chr_bus_t) return boolean;
    function is_bus_write(bus_in : chr_bus_t) return boolean;
    function is_bus_read(bus_in :chr_bus_t) return boolean;
    
    procedure bus_assert_check(bus_in : in chr_bus_t);

end chr_bus_types;

package body chr_bus_types is
    
    function bus_read(addr_in : unsigned(chr_addr_t'RANGE)) return chr_bus_t
    is
    begin
        return bus_read(std_logic_vector(addr_in));
    end;
    
    function bus_read(addr_in : chr_addr_t) return chr_bus_t
    is
        variable ret : chr_bus_t;
    begin
        ret.address := addr_in;
        ret.read := true;
        ret.write := false;
        
        return ret;
    end;
    
    function bus_write(addr_in : unsigned(chr_addr_t'RANGE)) return chr_bus_t
    is
    begin
        return bus_write(std_logic_vector(addr_in));
    end;
    
    function bus_write(addr_in : chr_addr_t) return chr_bus_t
    is
        variable ret : chr_bus_t;
    begin
        ret.address := addr_in;
        ret.read := false;
        ret.write := true;
        
        return ret;
    end;
    
    function bus_idle(bus_in : chr_bus_t) return chr_bus_t
    is
        variable ret : chr_bus_t;
    begin
        ret.address := (others => '-');
        ret.read := false;
        ret.write := false;
        
        return ret;
    end;
    
    function is_bus_active(bus_in : chr_bus_t) return boolean
    is
    begin
        return bus_in.read or bus_in.write;
    end;
    
    function is_bus_read(bus_in : chr_bus_t) return boolean
    is
    begin
        bus_assert_check(bus_in);
        return bus_in.read;
    end;
    
    function is_bus_write(bus_in : chr_bus_t) return boolean
    is
    begin
        bus_assert_check(bus_in);
        return bus_in.write;
    end;
    
    procedure bus_assert_check(bus_in : in chr_bus_t)
    is
    begin
        assert not (bus_in.read and bus_in.write) report "Read and Write both True";
    end;
end package body;

