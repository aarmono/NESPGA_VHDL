library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.cart_connector_types.all;
use work.cart_pin_types.all;

-- The cartridge connector on pins, for a real cartridge: turns the
-- console's side of the connector into the signals a cartridge sees, and the
-- cartridge's pins back into the connector records.
--
-- CPU side. M2 falls on the clock where the console's CPU cycle ends
-- (cpu_en), and rises M2_LOW_CLOCKS later. Longer or stretched CPU cycles
-- only lengthen the high phase. The address and R/W change one clock after M2
-- falls, so that a cartridge latching on the fall of M2 has hold time. Write
-- data is driven while M2 is high and for one clock after it falls. Read data
-- is sampled on every clock, so the console's CPU takes what the bus held on
-- the clock before M2 falls.
--
-- Open bus. A cartridge doesn't say which data bits it drives, and through
-- level shifters an undriven bus doesn't hold its last value by itself. So
-- the bus is made to hold it, as on a real NES, and every read of the
-- cartridge's addresses takes all 8 bits from the pins:
--   * On a read of the console's own addresses (0x0000-0x401F) the slot
--     drives the console's value of the data bus while M2 is high, as the
--     console's chips drive the bus the connector shares.
--   * With PRECHARGE_CLOCKS > 0, the slot drives the value the bus held at
--     the end of the last CPU cycle while M2 is low, from PRECHARGE_CLOCKS
--     after M2 falls (so that the cartridge has let go of the bus) until M2
--     rises. The bus holds it while M2 is high, unless the cartridge drives
--     it. With PRECHARGE_CLOCKS = 0 the board must hold the bus instead
--     (bus hold).
--
-- PPU side. An access starts on the dot ppu_en begins with ALE. The address
-- changes one clock after the dot starts, and ALE_CLOCKS after the dot starts
-- /RD or /WR goes low. /RD goes high with the start of the next access; /WR
-- goes high at the end of its dot, one clock before the address changes.
-- Write data is driven from the fall of /WR to the address change. Read data
-- and CIRAM /CE and A10 are sampled on every clock. The PPU drives the low
-- byte of the address on PPU D0-D7 during ALE, but the console doesn't model
-- PPU open bus, and driving it right after /RD rises would fight a slow CHR
-- ROM's outputs, so the slot leaves the bus alone then.
--
-- /IRQ is synchronized. A board raises IRQ on a PPU clock enable, and the next
-- CPU clock enable is at least a dot later, so the delay doesn't move it.
entity cart_slot is
generic
(
    -- Clocks M2 is low after it falls, about 3/8 of a CPU cycle. Must be less
    -- than the shortest CPU cycle
    M2_LOW_CLOCKS    : positive := 10;
    -- Clocks after M2 falls before the bus is precharged. 0 for none
    PRECHARGE_CLOCKS : natural := 3;
    -- Clocks from the start of the dot an access starts on to the fall of
    -- /RD or /WR. Must be at least 2 and less than the shortest dot
    ALE_CLOCKS       : positive := 4
);
port
(
    clk    : in std_logic;
    reset  : in boolean;

    -- The console's clock enables
    cpu_en : in boolean;
    ppu_en : in boolean;

    -- The console's side of the connector
    cpu_in       : in  cart_cpu_in_t;
    cpu_out      : out cart_cpu_out_t;
    -- See nes_console
    cpu_data_bus : in  data_t;
    ppu_in       : in  cart_ppu_in_t;
    ppu_out      : out cart_ppu_out_t;

    -- The pins
    pins_out : out cart_console_pins_t;
    pins_in  : in  cart_board_pins_t
);
end entity;

architecture behavioral of cart_slot
is

    subtype m2_count_t is natural range 0 to M2_LOW_CLOCKS;
    subtype dot_count_t is natural range 0 to ALE_CLOCKS;

    type slot_reg_t is record
        pins         : cart_console_pins_t;
        -- Clocks since M2 fell, while it is low. 0 while it is high
        m2_low_count : m2_count_t;
        -- Clocks since the dot started, up to ALE_CLOCKS
        dot_count    : dot_count_t;
        -- The value on the CPU data bus at the end of the last CPU cycle
        bus_value    : data_t;
        -- The pins driven by the cartridge, sampled
        board        : cart_board_pins_t;
        irq_sync     : std_logic_vector(1 downto 0);
    end record;

    constant RESET_SLOT_REG : slot_reg_t :=
    (
        -- M2 starts high, as though a cycle had already started, so that the
        -- console's first CPU cycle ends with M2 falling
        pins =>
        (
            m2 => '1',
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
        ),
        m2_low_count => 0,
        dot_count => ALE_CLOCKS,
        bus_value => (others => '0'),
        board =>
        (
            cpu_data => (others => '0'),
            irq_n => '1',
            ppu_data => (others => '0'),
            ciram_ce_n => '1',
            ciram_a10 => '0'
        ),
        irq_sync => "11"
    );

    type slot_in_t is record
        reg          : slot_reg_t;
        cpu_en       : boolean;
        ppu_en       : boolean;
        cpu_in       : cart_cpu_in_t;
        cpu_data_bus : data_t;
        ppu_in       : cart_ppu_in_t;
        pins_in      : cart_board_pins_t;
    end record;

    -- An access to 0x0000-0x401F, which the console answers itself
    function is_console_address(bus_in : cart_cpu_in_t) return boolean
    is
    begin
        return not bus_in.romsel and
               (bus_in.prg_bus.address(14) = '0' or
                bus_in.prg_bus.address(13 downto 5) = "000000000");
    end;

    function cycle_cart_slot(slot_in : slot_in_t) return slot_reg_t
    is
        variable reg     : slot_reg_t;
        variable next_m2 : std_logic;
    begin
        reg := slot_in.reg;

        -- CPU side

        if slot_in.cpu_en
        then
            reg.m2_low_count := 1;
            next_m2 := '0';
        elsif slot_in.reg.m2_low_count = 0 or
              slot_in.reg.m2_low_count = M2_LOW_CLOCKS
        then
            reg.m2_low_count := 0;
            next_m2 := '1';
        else
            reg.m2_low_count := slot_in.reg.m2_low_count + 1;
            next_m2 := '0';
        end if;

        reg.pins.m2 := next_m2;

        if next_m2 = '1' and slot_in.cpu_in.romsel
        then
            reg.pins.romsel_n := '0';
        else
            reg.pins.romsel_n := '1';
        end if;

        if slot_in.cpu_en
        then
            -- M2 falls. Hold the data bus for a clock, and keep what it holds
            -- now for the precharge
            reg.bus_value := slot_in.cpu_data_bus;
        else
            -- The bus the console sampled on the cpu_en clock is still the
            -- last cycle's here, so the address only changes now
            if is_bus_active(slot_in.cpu_in.prg_bus)
            then
                reg.pins.cpu_addr := slot_in.cpu_in.prg_bus.address;
            end if;

            if slot_in.cpu_in.prg_bus.write
            then
                reg.pins.cpu_rw := '0';
            else
                reg.pins.cpu_rw := '1';
            end if;

            reg.pins.cpu_data_oe := false;
            if next_m2 = '1'
            then
                if slot_in.cpu_in.prg_bus.write
                then
                    reg.pins.cpu_data := slot_in.cpu_in.data;
                    reg.pins.cpu_data_oe := true;
                elsif slot_in.cpu_in.prg_bus.read and
                      is_console_address(slot_in.cpu_in)
                then
                    reg.pins.cpu_data := slot_in.cpu_data_bus;
                    reg.pins.cpu_data_oe := true;
                end if;
            elsif PRECHARGE_CLOCKS > 0 and
                  reg.m2_low_count > PRECHARGE_CLOCKS
            then
                reg.pins.cpu_data := slot_in.reg.bus_value;
                reg.pins.cpu_data_oe := true;
            end if;
        end if;

        -- PPU side

        if slot_in.ppu_en
        then
            -- The dot ends. A write ends with it, a clock before the address
            -- changes. The data bus holds for a clock
            reg.dot_count := 0;
            reg.pins.ppu_wr_n := '1';
        else
            if slot_in.reg.dot_count < ALE_CLOCKS
            then
                reg.dot_count := slot_in.reg.dot_count + 1;
            end if;

            -- The first clock after the dot started: the PPU's bus is the new
            -- dot's
            if slot_in.reg.dot_count = 0
            then
                -- The PPU holds the address while there is no access
                reg.pins.ppu_addr := slot_in.ppu_in.chr_bus.address;
                reg.pins.ppu_a13_n := not slot_in.ppu_in.chr_bus.address(13);

                reg.pins.ppu_data_oe := false;
                if slot_in.ppu_in.ale or
                   not is_bus_active(slot_in.ppu_in.chr_bus)
                then
                    reg.pins.ppu_rd_n := '1';
                end if;
            end if;

            if slot_in.ppu_in.ale and reg.dot_count = ALE_CLOCKS and
               slot_in.reg.dot_count /= ALE_CLOCKS
            then
                if slot_in.ppu_in.chr_bus.write
                then
                    reg.pins.ppu_wr_n := '0';
                    reg.pins.ppu_data := slot_in.ppu_in.data;
                    reg.pins.ppu_data_oe := true;
                else
                    reg.pins.ppu_rd_n := '0';
                end if;
            end if;
        end if;

        -- From the cartridge. The data and CIRAM pins answer the console's
        -- own outputs, so they are sampled once, where the console's timing
        -- says they are valid. /IRQ is asynchronous
        reg.board.cpu_data := slot_in.pins_in.cpu_data;
        reg.board.ppu_data := slot_in.pins_in.ppu_data;
        reg.board.ciram_ce_n := to_x01(slot_in.pins_in.ciram_ce_n);
        reg.board.ciram_a10 := to_x01(slot_in.pins_in.ciram_a10);
        reg.irq_sync := slot_in.reg.irq_sync(0) & to_x01(slot_in.pins_in.irq_n);

        return reg;
    end;

    signal reg : slot_reg_t := RESET_SLOT_REG;

begin

    assert M2_LOW_CLOCKS >= 2 and ALE_CLOCKS >= 2
        report "cart_slot: M2_LOW_CLOCKS and ALE_CLOCKS must be at least 2"
        severity failure;

    pins_out <= reg.pins;

    cpu_out <=
    (
        data => reg.board.cpu_data,
        -- Bits the cartridge leaves undriven hold the open bus value, see
        -- above
        data_oe => true,
        data_float => (others => '0'),
        irq => reg.irq_sync(1) = '0'
    );

    ppu_out <=
    (
        data => reg.board.ppu_data,
        data_oe => true,
        ciram_ce => reg.board.ciram_ce_n = '0',
        ciram_a10 => reg.board.ciram_a10
    );

    process(clk)
    is
        variable slot_in : slot_in_t;
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_SLOT_REG;
        else
            slot_in.reg := reg;
            slot_in.cpu_en := cpu_en;
            slot_in.ppu_en := ppu_en;
            slot_in.cpu_in := cpu_in;
            slot_in.cpu_data_bus := cpu_data_bus;
            slot_in.ppu_in := ppu_in;
            slot_in.pins_in := pins_in;

            reg <= cycle_cart_slot(slot_in);
        end if;
    end if;
    end process;

end behavioral;
