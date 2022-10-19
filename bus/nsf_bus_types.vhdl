library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package nsf_bus_types is
   
    subtype nsf_addr_t is std_logic_vector(19 downto 0);
    type nsf_bus_t is record
        address  : nsf_addr_t;
        read     : boolean;
        write    : boolean;
    end record;
    
    function bus_read(addr_in : nsf_addr_t) return nsf_bus_t;
    function bus_read(addr_in : unsigned(nsf_addr_t'RANGE)) return nsf_bus_t;
    function bus_write(addr_in : nsf_addr_t) return nsf_bus_t;
    function bus_write(addr_in : unsigned(nsf_addr_t'RANGE)) return nsf_bus_t;
    function bus_idle(bus_in : nsf_bus_t) return nsf_bus_t;
    
    function is_bus_active(bus_in : nsf_bus_t) return boolean;
    function is_bus_write(bus_in : nsf_bus_t) return boolean;
    function is_bus_read(bus_in :nsf_bus_t) return boolean;
    
    procedure bus_assert_check(bus_in : in nsf_bus_t);

end nsf_bus_types;

package body nsf_bus_types is
    
    function bus_read(addr_in : unsigned(nsf_addr_t'RANGE)) return nsf_bus_t
    is
    begin
        return bus_read(std_logic_vector(addr_in));
    end;
    
    function bus_read(addr_in : nsf_addr_t) return nsf_bus_t
    is
        variable ret : nsf_bus_t;
    begin
        ret.address := addr_in;
        ret.read := true;
        ret.write := false;
        
        return ret;
    end;
    
    function bus_write(addr_in : unsigned(nsf_addr_t'RANGE)) return nsf_bus_t
    is
    begin
        return bus_write(std_logic_vector(addr_in));
    end;
    
    function bus_write(addr_in : nsf_addr_t) return nsf_bus_t
    is
        variable ret : nsf_bus_t;
    begin
        ret.address := addr_in;
        ret.read := false;
        ret.write := true;
        
        return ret;
    end;
    
    function bus_idle(bus_in : nsf_bus_t) return nsf_bus_t
    is
        variable ret : nsf_bus_t;
    begin
        ret.address := (others => '-');
        ret.read := false;
        ret.write := false;
        
        return ret;
    end;
    
    function is_bus_active(bus_in : nsf_bus_t) return boolean
    is
    begin
        return bus_in.read or bus_in.write;
    end;
    
    function is_bus_read(bus_in : nsf_bus_t) return boolean
    is
    begin
        bus_assert_check(bus_in);
        return bus_in.read;
    end;
    
    function is_bus_write(bus_in : nsf_bus_t) return boolean
    is
    begin
        bus_assert_check(bus_in);
        return bus_in.write;
    end;
    
    procedure bus_assert_check(bus_in : in nsf_bus_t)
    is
    begin
        assert not (bus_in.read and bus_in.write) report "Read and Write both True";
    end;
end package body;

