library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package cart_mem_bus_types is
   
    subtype cart_mem_addr_t is std_logic_vector(22 downto 0);
    type cart_mem_bus_t is record
        address  : cart_mem_addr_t;
        read     : boolean;
        write    : boolean;
    end record;
    
    constant CART_MEM_BUS_IDLE : cart_mem_bus_t :=
    (
        address => (others => '-'),
        read => false,
        write => false
    );

    -- The ROM file is in the lower half of the cartridge memory bus, from
    -- address 0. The cartridge RAMs are in the upper half, each in its own
    -- fixed 64 KB window: PRG RAM, then CHR RAM, then ExRAM
    constant CART_RAM_BASE : natural := 2**(cart_mem_addr_t'length - 1);
    -- The address bits within a window
    subtype cart_ram_window_bits_t is natural range 15 downto 0;
    constant CART_RAM_WINDOW_BYTES : natural :=
        2**(cart_ram_window_bits_t'high + 1);

    constant PRG_RAM_WINDOW : cart_mem_addr_t :=
        std_logic_vector(to_unsigned(CART_RAM_BASE, cart_mem_addr_t'length));
    constant CHR_RAM_WINDOW : cart_mem_addr_t :=
        std_logic_vector(to_unsigned(CART_RAM_BASE + CART_RAM_WINDOW_BYTES,
                                     cart_mem_addr_t'length));
    constant EXRAM_WINDOW : cart_mem_addr_t :=
        std_logic_vector(to_unsigned(CART_RAM_BASE + 2 * CART_RAM_WINDOW_BYTES,
                                     cart_mem_addr_t'length));

    -- The address is in the given cartridge RAM window
    function is_in_window
    (
        address : cart_mem_addr_t;
        window  : cart_mem_addr_t
    )
    return boolean;
    
    function bus_read(addr_in : cart_mem_addr_t) return cart_mem_bus_t;
    function bus_read(addr_in : unsigned(cart_mem_addr_t'RANGE)) return cart_mem_bus_t;
    function bus_write(addr_in : cart_mem_addr_t) return cart_mem_bus_t;
    function bus_write(addr_in : unsigned(cart_mem_addr_t'RANGE)) return cart_mem_bus_t;
    function bus_idle(bus_in : cart_mem_bus_t) return cart_mem_bus_t;
    
    function is_bus_active(bus_in : cart_mem_bus_t) return boolean;
    function is_bus_write(bus_in : cart_mem_bus_t) return boolean;
    function is_bus_read(bus_in :cart_mem_bus_t) return boolean;
    
    procedure bus_assert_check(bus_in : in cart_mem_bus_t);

end cart_mem_bus_types;

package body cart_mem_bus_types is

    function is_in_window
    (
        address : cart_mem_addr_t;
        window  : cart_mem_addr_t
    )
    return boolean
    is
        constant HIGH : natural := cart_mem_addr_t'high;
        constant LOW  : natural := cart_ram_window_bits_t'high + 1;
    begin
        return address(HIGH downto LOW) = window(HIGH downto LOW);
    end;
    
    function bus_read(addr_in : unsigned(cart_mem_addr_t'RANGE)) return cart_mem_bus_t
    is
    begin
        return bus_read(std_logic_vector(addr_in));
    end;
    
    function bus_read(addr_in : cart_mem_addr_t) return cart_mem_bus_t
    is
        variable ret : cart_mem_bus_t;
    begin
        ret.address := addr_in;
        ret.read := true;
        ret.write := false;
        
        return ret;
    end;
    
    function bus_write(addr_in : unsigned(cart_mem_addr_t'RANGE)) return cart_mem_bus_t
    is
    begin
        return bus_write(std_logic_vector(addr_in));
    end;
    
    function bus_write(addr_in : cart_mem_addr_t) return cart_mem_bus_t
    is
        variable ret : cart_mem_bus_t;
    begin
        ret.address := addr_in;
        ret.read := false;
        ret.write := true;
        
        return ret;
    end;
    
    function bus_idle(bus_in : cart_mem_bus_t) return cart_mem_bus_t
    is
        variable ret : cart_mem_bus_t;
    begin
        ret.address := (others => '-');
        ret.read := false;
        ret.write := false;
        
        return ret;
    end;
    
    function is_bus_active(bus_in : cart_mem_bus_t) return boolean
    is
    begin
        return bus_in.read or bus_in.write;
    end;
    
    function is_bus_read(bus_in : cart_mem_bus_t) return boolean
    is
    begin
        bus_assert_check(bus_in);
        return bus_in.read;
    end;
    
    function is_bus_write(bus_in : cart_mem_bus_t) return boolean
    is
    begin
        bus_assert_check(bus_in);
        return bus_in.write;
    end;
    
    procedure bus_assert_check(bus_in : in cart_mem_bus_t)
    is
    begin
        assert not (bus_in.read and bus_in.write) report "Read and Write both True";
    end;
end package body;

