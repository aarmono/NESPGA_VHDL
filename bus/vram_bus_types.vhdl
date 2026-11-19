library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- The 2KB of VRAM a four-screen board carries for the nametables at
-- 0x2800-0x2FFF, which CIRAM in the console does not hold
package vram_bus_types is
   
    subtype vram_addr_t is std_logic_vector(10 downto 0);
    type vram_bus_t is record
        address  : vram_addr_t;
        read     : boolean;
        write    : boolean;
    end record;
    
    constant VRAM_BUS_IDLE : vram_bus_t :=
    (
        address => (others => '-'),
        read => false,
        write => false
    );
    
    function bus_read(addr_in : vram_addr_t) return vram_bus_t;
    function bus_read(addr_in : unsigned(vram_addr_t'RANGE)) return vram_bus_t;
    function bus_write(addr_in : vram_addr_t) return vram_bus_t;
    function bus_write(addr_in : unsigned(vram_addr_t'RANGE)) return vram_bus_t;
    function bus_idle(bus_in : vram_bus_t) return vram_bus_t;
    
    function is_bus_active(bus_in : vram_bus_t) return boolean;
    function is_bus_write(bus_in : vram_bus_t) return boolean;
    function is_bus_read(bus_in :vram_bus_t) return boolean;
    
    procedure bus_assert_check(bus_in : in vram_bus_t);

end vram_bus_types;

package body vram_bus_types is
    
    function bus_read(addr_in : unsigned(vram_addr_t'RANGE)) return vram_bus_t
    is
    begin
        return bus_read(std_logic_vector(addr_in));
    end;
    
    function bus_read(addr_in : vram_addr_t) return vram_bus_t
    is
    begin
        return (address => addr_in,
                read => true,
                write => false);
    end;
    
    function bus_write(addr_in : unsigned(vram_addr_t'RANGE)) return vram_bus_t
    is
    begin
        return bus_write(std_logic_vector(addr_in));
    end;
    
    function bus_write(addr_in : vram_addr_t) return vram_bus_t
    is
    begin
        return (address => addr_in,
                read => false,
                write => true);
    end;
    
    function bus_idle(bus_in : vram_bus_t) return vram_bus_t
    is
    begin
        return (address => (others => '-'),
                read => false,
                write => false);
    end;
    
    function is_bus_active(bus_in : vram_bus_t) return boolean
    is
    begin
        return bus_in.read or bus_in.write;
    end;
    
    function is_bus_read(bus_in : vram_bus_t) return boolean
    is
    begin
        bus_assert_check(bus_in);
        return bus_in.read;
    end;
    
    function is_bus_write(bus_in : vram_bus_t) return boolean
    is
    begin
        bus_assert_check(bus_in);
        return bus_in.write;
    end;
    
    procedure bus_assert_check(bus_in : in vram_bus_t)
    is
    begin
        assert not (bus_in.read and bus_in.write) report "Read and Write both True";
    end;
end package body;

