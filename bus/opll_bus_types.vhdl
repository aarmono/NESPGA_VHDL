library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- The memory of the FM synthesizer of the Konami VRC7: a RAM that holds its
-- per-operator and per-channel state
package opll_bus_types is

    subtype opll_ram_addr_t is std_logic_vector(5 downto 0);
    subtype opll_ram_data_t is std_logic_vector(51 downto 0);

    type opll_ram_bus_t is record
        address : opll_ram_addr_t;
        read    : boolean;
        write   : boolean;
    end record;

    constant OPLL_RAM_BUS_IDLE : opll_ram_bus_t :=
    (
        address => (others => '-'),
        read => false,
        write => false
    );

    -- The accesses of the synthesizer to its RAM
    type opll_mem_out_t is record
        ram_bus     : opll_ram_bus_t;
        data_to_ram : opll_ram_data_t;
    end record;

    constant OPLL_MEM_OUT_IDLE : opll_mem_out_t :=
    (
        ram_bus => OPLL_RAM_BUS_IDLE,
        data_to_ram => (others => '-')
    );

    function bus_read(addr_in : opll_ram_addr_t) return opll_ram_bus_t;
    function bus_write(addr_in : opll_ram_addr_t) return opll_ram_bus_t;

end opll_bus_types;

package body opll_bus_types is

    function bus_read(addr_in : opll_ram_addr_t) return opll_ram_bus_t
    is
    begin
        return (address => addr_in, read => true, write => false);
    end;

    function bus_write(addr_in : opll_ram_addr_t) return opll_ram_bus_t
    is
    begin
        return (address => addr_in, read => false, write => true);
    end;

end package body;
