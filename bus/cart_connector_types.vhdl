library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;

use work.prg_bus_types.all;
use work.chr_bus_types.all;

-- The signals of the cartridge connector, which both the console and the
-- cartridge use. The records follow its pins: the CPU side and the PPU side,
-- each with the signals driven by the console (in) and those driven by the
-- cartridge (out)
package cart_connector_types is

    -- CPU side of the connector, driven by the console
    type cart_cpu_in_t is record
        -- CPU A0-A14 and R/W. The board sees every access, including those
        -- to the console's own registers and RAM. Neither read nor write is
        -- set when the bus is idle
        prg_bus : prg_bus_t;
        -- /ROMSEL, active high: set for an access to 0x8000-0xFFFF
        romsel  : boolean;
        -- CPU D0-D7 during a write
        data    : data_t;
    end record;

    -- No access, as after reset
    constant CART_CPU_IN_IDLE : cart_cpu_in_t :=
    (
        prg_bus => (address => (others => '0'),
                    read => false,
                    write => false),
        romsel => false,
        data => (others => '0')
    );

    -- CPU side of the connector, driven by the board
    type cart_cpu_out_t is record
        -- CPU D0-D7. When the board does not drive them the console reads
        -- open bus
        data    : data_t;
        data_oe : boolean;
        -- The bits of data the board leaves floating when it drives the
        -- others: the console reads open bus there
        data_float : data_t;
        -- /IRQ, active high
        irq     : boolean;
    end record;

    constant CART_CPU_OUT_IDLE : cart_cpu_out_t :=
    (
        data => (others => '-'),
        data_oe => false,
        data_float => (others => '0'),
        irq => false
    );

    -- The CPU side of the connector driven by the cartridge and by another
    -- device on it, as the console sees it. When the device drives the data
    -- bus it answers the read instead of the cartridge. /IRQ is shared, so
    -- the IRQs are ORed
    function merge_cart_cpu_out
    (
        cart   : cart_cpu_out_t;
        device : cart_cpu_out_t
    )
    return cart_cpu_out_t;

    -- PPU side of the connector, driven by the console
    type cart_ppu_in_t is record
        -- PPU A0-A13, /RD and /WR
        chr_bus : chr_bus_t;
        -- Set on the first dot of each access. On the console /RD and /WR
        -- go high between back-to-back accesses, which chr_bus does not
        -- show, so this stands in for their falling edges
        ale     : boolean;
        -- PPU D0-D7 during a write
        data    : data_t;
    end record;

    -- No access, as after reset
    constant CART_PPU_IN_IDLE : cart_ppu_in_t :=
    (
        chr_bus => (address => (others => '0'),
                    read => false,
                    write => false),
        ale => false,
        data => (others => '0')
    );

    -- PPU side of the connector, driven by the board
    type cart_ppu_out_t is record
        -- PPU D0-D7, when CIRAM is not enabled
        data      : data_t;
        data_oe   : boolean;
        -- CIRAM /CE, active high, and CIRAM A10. The console addresses CIRAM
        -- with these and PPU A0-A9
        ciram_ce  : boolean;
        ciram_a10 : std_logic;
    end record;

    constant CART_PPU_OUT_IDLE : cart_ppu_out_t :=
    (
        data => (others => '-'),
        data_oe => false,
        ciram_ce => false,
        ciram_a10 => '-'
    );

end package cart_connector_types;

package body cart_connector_types is

    function merge_cart_cpu_out
    (
        cart   : cart_cpu_out_t;
        device : cart_cpu_out_t
    )
    return cart_cpu_out_t
    is
        variable ret : cart_cpu_out_t;
    begin
        ret := cart;
        if device.data_oe
        then
            ret.data := device.data;
            ret.data_oe := true;
            ret.data_float := device.data_float;
        end if;
        ret.irq := cart.irq or device.irq;

        return ret;
    end;

end package body cart_connector_types;
