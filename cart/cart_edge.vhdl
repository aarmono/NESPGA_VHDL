library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.cart_connector_types.all;
use work.cart_pin_types.all;

-- The cartridge connector on pins, for a cartridge in a real console: turns
-- the pins the console drives into the connector records and clock enables
-- the cartridge runs on, and the cartridge's side of the connector back into
-- pins. The counterpart of cart_slot.
--
-- Every pin from the console goes through the same 2-FF synchronizer, so the
-- cartridge sees them all the same number of clocks late, and their timing
-- relative to each other is kept: the address changing a clock after M2
-- falls is still a clock of hold time here.
--
-- Clock enables. cpu_en is the first clock M2 is low (after the
-- synchronizer). The console's dots split a CPU cycle into two of
-- DOT_CLOCKS, starting on its CPU clock enable, and a last one that takes
-- what is left: the sync dot. So ppu_en is at cpu_en and DOT_CLOCKS and
-- 2 * DOT_CLOCKS clocks after it, ram_en RAM_EN_CLOCKS into each dot, and
-- clk_sync is set through the sync dot. With the console's clock at the
-- same frequency, as in nes_bench, they are the console's enables, 3 clocks
-- later. In a real console, the PPU's dots can sit up to 3 master clocks off
-- M2, and these are only the nearest whole clocks.
--
-- CPU side. Write data is only on the pins while M2 is high, and /ROMSEL is
-- only low then, so the cartridge sees the bus as idle until M2 rises. Then
-- it sees the pins, and on cpu_en, when they have changed for M2 falling,
-- the bus as it was the clock before. The cartridge drives the data bus
-- while the M2 pin is high and R/W reads, for the bits its board drives:
-- the pins themselves gate it, as a real cartridge's bus buffer, so the bus
-- is let go as soon as M2 falls.
--
-- PPU side. /RD and /WR fall on the first dot of an access, which is ALE.
-- /WR rises as the dot ends, which is the clock the sync dot is sampled on,
-- so a dot is a write if /WR fell in it, a read if /RD is low, and ALE if
-- either fell in it. Write data is held from while /WR was low. The
-- cartridge drives PPU data while the /RD pin is low.
--
-- The data, /IRQ and CIRAM pins come straight from the cartridge's outputs.
-- The board computes those from its registers and the synchronized pins, so
-- they don't need registers of their own, and leaving them out saves a clock
-- on the way back to the console.
entity cart_edge is
generic
(
    -- Clocks in each of the first two dots of a CPU cycle
    DOT_CLOCKS    : positive := 9;
    -- Clocks from the start of a dot to ram_en. Less than DOT_CLOCKS
    RAM_EN_CLOCKS : positive := 4
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    -- The pins driven by the console. Their data and data enables are not
    -- used: the data buses are read as resolved, below
    pins_in      : in cart_console_pins_t;
    -- CPU D0-D7 and PPU D0-D7, as the cartridge reads them
    cpu_data_bus : in data_t;
    ppu_data_bus : in data_t;
    -- The pins driven by the cartridge
    pins_out     : out cart_board_drive_t;

    -- The clock enables the cartridge runs on. See cart_system
    cpu_en   : out boolean;
    ppu_en   : out boolean;
    clk_sync : out boolean;
    ram_en   : out boolean;

    -- The cartridge's side of the connector
    cpu_in  : out cart_cpu_in_t;
    cpu_out : in  cart_cpu_out_t;
    ppu_in  : out cart_ppu_in_t;
    ppu_out : in  cart_ppu_out_t
);
end entity;

architecture behavioral of cart_edge
is

    -- Saturates while there is no M2
    constant MAX_COUNT : positive := 3 * DOT_CLOCKS + 8;
    subtype edge_count_t is natural range 0 to MAX_COUNT;

    -- The pins the cartridge reads
    type edge_pins_t is record
        m2       : std_logic;
        romsel_n : std_logic;
        cpu_rw   : std_logic;
        cpu_addr : prg_addr_t;
        cpu_data : data_t;
        ppu_rd_n : std_logic;
        ppu_wr_n : std_logic;
        ppu_addr : chr_addr_t;
        ppu_data : data_t;
    end record;

    constant RESET_EDGE_PINS : edge_pins_t :=
    (
        m2 => '0',
        romsel_n => '1',
        cpu_rw => '1',
        cpu_addr => (others => '0'),
        cpu_data => (others => '0'),
        ppu_rd_n => '1',
        ppu_wr_n => '1',
        ppu_addr => (others => '0'),
        ppu_data => (others => '0')
    );

    type edge_reg_t is record
        -- The synchronizer
        sync_1   : edge_pins_t;
        sync_2   : edge_pins_t;
        -- sync_2's M2, /RD and /WR a clock before
        m2_prev  : std_logic;
        rd_prev  : std_logic;
        wr_prev  : std_logic;
        -- The CPU bus while M2 was high, for cpu_en
        cpu_hold : cart_cpu_in_t;
        -- Clocks since cpu_en
        count    : edge_count_t;
        -- /RD or /WR fell in this dot
        rd_fell  : boolean;
        wr_fell  : boolean;
        -- PPU write data while /WR was low
        ppu_wr_data : data_t;
    end record;

    constant RESET_EDGE_REG : edge_reg_t :=
    (
        sync_1 => RESET_EDGE_PINS,
        sync_2 => RESET_EDGE_PINS,
        m2_prev => '0',
        rd_prev => '1',
        wr_prev => '1',
        cpu_hold =>
        (
            prg_bus => (address => (others => '0'),
                        read => false,
                        write => false),
            romsel => false,
            data => (others => '0')
        ),
        count => MAX_COUNT,
        rd_fell => false,
        wr_fell => false,
        ppu_wr_data => (others => '0')
    );

    function to_edge_pins
    (
        pins     : cart_console_pins_t;
        cpu_data : data_t;
        ppu_data : data_t
    )
    return edge_pins_t
    is
    begin
        return
        (
            m2 => to_x01(pins.m2),
            romsel_n => to_x01(pins.romsel_n),
            cpu_rw => to_x01(pins.cpu_rw),
            cpu_addr => pins.cpu_addr,
            cpu_data => cpu_data,
            ppu_rd_n => to_x01(pins.ppu_rd_n),
            ppu_wr_n => to_x01(pins.ppu_wr_n),
            ppu_addr => pins.ppu_addr,
            ppu_data => ppu_data
        );
    end;

    function is_cpu_en(reg : edge_reg_t) return boolean
    is
    begin
        return reg.sync_2.m2 = '0' and reg.m2_prev = '1';
    end;

    function is_ppu_en(reg : edge_reg_t) return boolean
    is
    begin
        return is_cpu_en(reg) or
               reg.count = DOT_CLOCKS or
               reg.count = 2 * DOT_CLOCKS;
    end;

    function is_ram_en(reg : edge_reg_t) return boolean
    is
    begin
        return reg.count = RAM_EN_CLOCKS or
               reg.count = DOT_CLOCKS + RAM_EN_CLOCKS or
               reg.count = 2 * DOT_CLOCKS + RAM_EN_CLOCKS;
    end;

    function is_rd_fall(reg : edge_reg_t) return boolean
    is
    begin
        return reg.sync_2.ppu_rd_n = '0' and reg.rd_prev = '1';
    end;

    function is_wr_fall(reg : edge_reg_t) return boolean
    is
    begin
        return reg.sync_2.ppu_wr_n = '0' and reg.wr_prev = '1';
    end;

    -- The CPU bus while M2 is high
    function get_m2_bus(pins : edge_pins_t) return cart_cpu_in_t
    is
    begin
        return
        (
            prg_bus => (address => pins.cpu_addr,
                        read => pins.cpu_rw = '1',
                        write => pins.cpu_rw = '0'),
            romsel => pins.romsel_n = '0',
            data => pins.cpu_data
        );
    end;

    function get_cpu_in(reg : edge_reg_t) return cart_cpu_in_t
    is
    begin
        if reg.sync_2.m2 = '1'
        then
            return get_m2_bus(reg.sync_2);
        elsif is_cpu_en(reg)
        then
            return reg.cpu_hold;
        else
            return
            (
                prg_bus => (address => reg.sync_2.cpu_addr,
                            read => false,
                            write => false),
                romsel => false,
                data => reg.sync_2.cpu_data
            );
        end if;
    end;

    function get_ppu_in(reg : edge_reg_t) return cart_ppu_in_t
    is
        variable write : boolean;
        variable data  : data_t;
    begin
        write := reg.wr_fell or reg.sync_2.ppu_wr_n = '0';

        if reg.sync_2.ppu_wr_n = '0'
        then
            data := reg.sync_2.ppu_data;
        else
            data := reg.ppu_wr_data;
        end if;

        return
        (
            chr_bus => (address => reg.sync_2.ppu_addr,
                        read => not write and reg.sync_2.ppu_rd_n = '0',
                        write => write),
            ale => reg.rd_fell or reg.wr_fell or
                   is_rd_fall(reg) or is_wr_fall(reg),
            data => data
        );
    end;

    function get_pins_out
    (
        pins     : cart_console_pins_t;
        cart_cpu : cart_cpu_out_t;
        cart_ppu : cart_ppu_out_t
    )
    return cart_board_drive_t
    is
        variable ret : cart_board_drive_t;
    begin
        ret.cpu_data := cart_cpu.data;
        if cart_cpu.data_oe and to_x01(pins.m2) = '1' and
           to_x01(pins.cpu_rw) = '1'
        then
            ret.cpu_data_oe := not cart_cpu.data_float;
        else
            ret.cpu_data_oe := (others => '0');
        end if;

        if cart_cpu.irq
        then
            ret.irq_n := '0';
        else
            ret.irq_n := 'Z';
        end if;

        ret.ppu_data := cart_ppu.data;
        ret.ppu_data_oe := cart_ppu.data_oe and to_x01(pins.ppu_rd_n) = '0';

        if cart_ppu.ciram_ce
        then
            ret.ciram_ce_n := '0';
        else
            ret.ciram_ce_n := '1';
        end if;
        ret.ciram_a10 := cart_ppu.ciram_a10;

        return ret;
    end;

    type edge_in_t is record
        reg          : edge_reg_t;
        pins_in      : cart_console_pins_t;
        cpu_data_bus : data_t;
        ppu_data_bus : data_t;
    end record;

    function cycle_cart_edge(edge_in : edge_in_t) return edge_reg_t
    is
        variable reg : edge_reg_t;
    begin
        reg := edge_in.reg;

        reg.sync_1 := to_edge_pins(edge_in.pins_in,
                                   edge_in.cpu_data_bus,
                                   edge_in.ppu_data_bus);
        reg.sync_2 := edge_in.reg.sync_1;
        reg.m2_prev := edge_in.reg.sync_2.m2;
        reg.rd_prev := edge_in.reg.sync_2.ppu_rd_n;
        reg.wr_prev := edge_in.reg.sync_2.ppu_wr_n;

        if edge_in.reg.sync_2.m2 = '1'
        then
            reg.cpu_hold := get_m2_bus(edge_in.reg.sync_2);
        end if;

        if is_cpu_en(edge_in.reg)
        then
            reg.count := 1;
        elsif edge_in.reg.count < MAX_COUNT
        then
            reg.count := edge_in.reg.count + 1;
        end if;

        if is_ppu_en(edge_in.reg)
        then
            reg.rd_fell := false;
            reg.wr_fell := false;
        else
            reg.rd_fell := edge_in.reg.rd_fell or is_rd_fall(edge_in.reg);
            reg.wr_fell := edge_in.reg.wr_fell or is_wr_fall(edge_in.reg);
        end if;

        if edge_in.reg.sync_2.ppu_wr_n = '0'
        then
            reg.ppu_wr_data := edge_in.reg.sync_2.ppu_data;
        end if;

        return reg;
    end;

    signal reg : edge_reg_t := RESET_EDGE_REG;

begin

    assert RAM_EN_CLOCKS < DOT_CLOCKS
        report "cart_edge: RAM_EN_CLOCKS must be less than DOT_CLOCKS"
        severity failure;

    cpu_en <= is_cpu_en(reg);
    ppu_en <= is_ppu_en(reg);
    clk_sync <= reg.count > 2 * DOT_CLOCKS;
    ram_en <= is_ram_en(reg);

    cpu_in <= get_cpu_in(reg);
    ppu_in <= get_ppu_in(reg);

    pins_out <= get_pins_out(pins_in, cpu_out, ppu_out);

    process(clk)
    is
        variable edge_in : edge_in_t;
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_EDGE_REG;
        else
            edge_in.reg := reg;
            edge_in.pins_in := pins_in;
            edge_in.cpu_data_bus := cpu_data_bus;
            edge_in.ppu_data_bus := ppu_data_bus;

            reg <= cycle_cart_edge(edge_in);
        end if;
    end if;
    end process;

end behavioral;
