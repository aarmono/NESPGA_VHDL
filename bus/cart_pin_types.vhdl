library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;

use work.prg_bus_types.all;
use work.chr_bus_types.all;

-- The pins of the cartridge connector, as a real cartridge sees them.
-- cart_connector_types has the connector as it is used inside the FPGA. The
-- data buses are shared: each side has its own driver, with an output enable,
-- and reads the bus. Level shifting and tri-stating are up to the board
package cart_pin_types is

    -- Driven by the console
    type cart_console_pins_t is record
        -- M2: high for the part of a CPU cycle where the bus is valid, about
        -- the last 5/8 of it
        m2          : std_logic;
        -- /ROMSEL: low while M2 is high, for an access to 0x8000-0xFFFF
        romsel_n    : std_logic;
        -- R/W: low for a write
        cpu_rw      : std_logic;
        -- CPU A0-A14
        cpu_addr    : prg_addr_t;
        -- CPU D0-D7, when the console drives them
        cpu_data    : data_t;
        cpu_data_oe : boolean;

        -- PPU /RD and /WR
        ppu_rd_n    : std_logic;
        ppu_wr_n    : std_logic;
        -- PPU A0-A13, and /A13 (PPU A13 inverted)
        ppu_addr    : chr_addr_t;
        ppu_a13_n   : std_logic;
        -- PPU D0-D7, when the console drives them
        ppu_data    : data_t;
        ppu_data_oe : boolean;
    end record;

    -- Driven by the cartridge, and the shared data buses as the console
    -- reads them
    type cart_board_pins_t is record
        -- CPU D0-D7
        cpu_data   : data_t;
        -- /IRQ: open drain, pulled up by the console
        irq_n      : std_logic;

        -- PPU D0-D7
        ppu_data   : data_t;
        -- CIRAM /CE and CIRAM A10
        ciram_ce_n : std_logic;
        ciram_a10  : std_logic;
    end record;

    -- Driven by the cartridge, before the shared data buses are resolved.
    -- A board can leave some CPU data bits floating while it drives the
    -- others, so each bit has its own enable
    type cart_board_drive_t is record
        -- CPU D0-D7, driven where cpu_data_oe is '1'
        cpu_data    : data_t;
        cpu_data_oe : data_t;
        -- /IRQ: '0' or 'Z'
        irq_n       : std_logic;

        ppu_data    : data_t;
        ppu_data_oe : boolean;
        ciram_ce_n  : std_logic;
        ciram_a10   : std_logic;
    end record;

    -- The pins with no access on them, and nothing driven
    constant CART_CONSOLE_PINS_IDLE : cart_console_pins_t :=
    (
        m2 => '0',
        romsel_n => '1',
        cpu_rw => '1',
        cpu_addr => (others => '0'),
        cpu_data => (others => '0'),
        cpu_data_oe => false,
        ppu_rd_n => '1',
        ppu_wr_n => '1',
        ppu_addr => (others => '0'),
        ppu_a13_n => '1',
        ppu_data => (others => '0'),
        ppu_data_oe => false
    );

    constant CART_BOARD_PINS_IDLE : cart_board_pins_t :=
    (
        cpu_data => (others => '0'),
        irq_n => '1',
        ppu_data => (others => '0'),
        ciram_ce_n => '1',
        ciram_a10 => '0'
    );

end package cart_pin_types;
