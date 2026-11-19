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
-- The connector carries no dot clock, so each CPU cycle is split into three
-- dots from the measured M2 period, and cpu_en follows M2 falling by a phase
-- that tracks the PPU's accesses. The boards count CPU cycles and PPU
-- accesses, not dots, so the dots need not line up with the console's.
--
-- The data, /IRQ and CIRAM pins come straight from the cartridge's outputs,
-- without registers, which saves a clock on the way back to the console.
entity cart_edge is
generic
(
    -- The nominal clocks in a dot: a third of the M2 period in clocks.
    -- The dots are this until M2 has been measured, and periods of up to
    -- twice the nominal one are measured
    DOT_CLOCKS : positive := 9
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

    -- Clocks from the start of a dot to ram_en. Less than DOT_CLOCKS
    constant RAM_EN_CLOCKS : positive := 4;

    -- Saturates while there is no M2
    constant MAX_COUNT : positive := 6 * DOT_CLOCKS;
    subtype edge_count_t is natural range 0 to MAX_COUNT;

    -- The shortest M2 period measured: each dot is longer than
    -- RAM_EN_CLOCKS
    constant MIN_PERIOD : positive := 3 * (RAM_EN_CLOCKS + 1);

    -- Where /RD and /WR should fall in a dot, in clocks after its ppu_en.
    -- The cartridge has to see an access in the dot it starts in, and in
    -- time for its ram_en, or it answers a dot late. The PPU's dots sit
    -- anywhere from 0 to 3 master clocks off M2, but /RD and /WR fall at the
    -- same point in each of them
    constant FALL_POS_MIN : natural := 1;
    constant FALL_POS_MAX : natural := RAM_EN_CLOCKS - 1;

    -- Clocks from M2 falling to cpu_en: less than a dot
    subtype phase_t is natural range 0 to MAX_COUNT / 3;

    subtype dot_idx_t is natural range 0 to 2;

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
        -- A 2-FF synchronizer. Every pin goes through it, so their timing
        -- relative to each other is kept
        sync_1   : edge_pins_t;
        sync_2   : edge_pins_t;
        -- sync_2's M2, /RD and /WR a clock before
        m2_prev  : std_logic;
        rd_prev  : std_logic;
        wr_prev  : std_logic;
        -- The CPU bus while M2 was high, until cpu_en
        cpu_hold : cart_cpu_in_t;
        -- Clocks since M2 fell
        m2_count : edge_count_t;
        -- M2 fell, and cpu_en hasn't come yet
        cpu_pending : boolean;
        -- A third of the last M2 period, for the dots from the next cpu_en
        third    : phase_t;
        -- Clocks from M2 falling to cpu_en, and that from the next cpu_en
        phase      : phase_t;
        phase_next : phase_t;
        -- The dot of the CPU cycle, from 0 at cpu_en to 2 for the sync dot
        dot_idx  : dot_idx_t;
        -- Clocks since ppu_en
        dot_pos  : phase_t;
        -- The clocks in the first two dots of the CPU cycle
        dot_len  : phase_t;
        -- /RD or /WR fell since the buses were last held
        rd_fell  : boolean;
        wr_fell  : boolean;
        -- The buses held from ram_en to the end of the dot
        cpu_held : cart_cpu_in_t;
        ppu_held : cart_ppu_in_t;
        -- The PPU address and write data while /WR was low
        ppu_wr_addr : chr_addr_t;
        ppu_wr_data : data_t;
    end record;

    constant RESET_EDGE_REG : edge_reg_t :=
    (
        sync_1 => RESET_EDGE_PINS,
        sync_2 => RESET_EDGE_PINS,
        m2_prev => '0',
        rd_prev => '1',
        wr_prev => '1',
        cpu_hold => CART_CPU_IN_IDLE,
        m2_count => MAX_COUNT,
        cpu_pending => false,
        third => DOT_CLOCKS,
        phase => DOT_CLOCKS / 2,
        phase_next => DOT_CLOCKS / 2,
        dot_idx => 2,
        dot_pos => phase_t'high,
        dot_len => DOT_CLOCKS,
        rd_fell => false,
        wr_fell => false,
        cpu_held => CART_CPU_IN_IDLE,
        ppu_held => CART_PPU_IN_IDLE,
        ppu_wr_addr => (others => '0'),
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

    function is_m2_fall(reg : edge_reg_t) return boolean
    is
    begin
        return reg.sync_2.m2 = '0' and reg.m2_prev = '1';
    end;

    -- M2 has fallen, and cpu_en is this clock or still to come
    function is_cpu_pending(reg : edge_reg_t) return boolean
    is
    begin
        return reg.cpu_pending or is_m2_fall(reg);
    end;

    function is_cpu_en(reg : edge_reg_t) return boolean
    is
        variable since_fall : edge_count_t;
    begin
        if is_m2_fall(reg)
        then
            since_fall := 0;
        else
            since_fall := reg.m2_count;
        end if;
        return is_cpu_pending(reg) and since_fall = reg.phase;
    end;

    -- A third of the M2 period that ends this clock. A period that is cut
    -- short or far too long (no M2) is not measured
    function get_third(reg : edge_reg_t) return phase_t
    is
    begin
        if is_m2_fall(reg) and
           reg.m2_count >= MIN_PERIOD and reg.m2_count < MAX_COUNT
        then
            return reg.m2_count / 3;
        else
            return reg.third;
        end if;
    end;

    -- The first two dots of a CPU cycle are a third of the M2 period, rounded
    -- down. The last one, the sync dot, takes what is left
    function is_ppu_en(reg : edge_reg_t) return boolean
    is
    begin
        return is_cpu_en(reg) or
               (reg.dot_idx /= 2 and reg.dot_pos = reg.dot_len);
    end;

    function is_ram_en(reg : edge_reg_t) return boolean
    is
    begin
        return reg.dot_pos = RAM_EN_CLOCKS;
    end;

    -- Clocks since the last ppu_en, 0 on a ppu_en
    function get_dot_pos(reg : edge_reg_t) return phase_t
    is
    begin
        if is_ppu_en(reg)
        then
            return 0;
        else
            return reg.dot_pos;
        end if;
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

    -- From ram_en to the end of the dot the cartridge sees the held buses,
    -- and a pin that changes then shows in the next dot. The cartridge's RAMs
    -- take an access on ram_en and the memory mux counts it as served on the
    -- ppu_en that ends the dot, so both must see the same one
    function is_held(reg : edge_reg_t) return boolean
    is
    begin
        return reg.dot_pos > RAM_EN_CLOCKS;
    end;

    -- The CPU bus as the pins show it now. Write data is only on the pins
    -- while M2 is high, and /ROMSEL is only low then, so the bus is idle
    -- until M2 rises. From M2 falling to cpu_en, when the pins have changed
    -- for the next cycle, it is the bus as it was while M2 was high
    function get_pin_cpu_in(reg : edge_reg_t) return cart_cpu_in_t
    is
    begin
        if is_cpu_pending(reg)
        then
            return reg.cpu_hold;
        elsif reg.sync_2.m2 = '1'
        then
            return get_m2_bus(reg.sync_2);
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

    -- The PPU bus as the pins show it now. /RD and /WR fall on the first dot
    -- of an access, which is ALE. /WR rises as the dot ends, so a dot is a
    -- write if /WR fell in it, and a read if /RD is low
    function get_pin_ppu_in(reg : edge_reg_t) return cart_ppu_in_t
    is
        variable write : boolean;
        variable addr  : chr_addr_t;
        variable data  : data_t;
    begin
        write := reg.wr_fell or reg.sync_2.ppu_wr_n = '0';

        -- A write after /WR rose is to where /WR was low: the PPU has moved
        -- on to its next access by then
        if reg.sync_2.ppu_wr_n = '0'
        then
            addr := reg.sync_2.ppu_addr;
            data := reg.sync_2.ppu_data;
        elsif write
        then
            addr := reg.ppu_wr_addr;
            data := reg.ppu_wr_data;
        else
            addr := reg.sync_2.ppu_addr;
            data := reg.ppu_wr_data;
        end if;

        return
        (
            chr_bus => (address => addr,
                        read => not write and reg.sync_2.ppu_rd_n = '0',
                        write => write),
            ale => reg.rd_fell or reg.wr_fell or
                   is_rd_fall(reg) or is_wr_fall(reg),
            data => data
        );
    end;

    function get_cpu_in(reg : edge_reg_t) return cart_cpu_in_t
    is
    begin
        if is_held(reg)
        then
            return reg.cpu_held;
        else
            return get_pin_cpu_in(reg);
        end if;
    end;

    function get_ppu_in(reg : edge_reg_t) return cart_ppu_in_t
    is
    begin
        if is_held(reg)
        then
            return reg.ppu_held;
        else
            return get_pin_ppu_in(reg);
        end if;
    end;

    -- The M2, R/W and /RD pins gate the data drivers themselves, as a real
    -- cartridge's bus buffer does, so a bus is let go as soon as they change
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

    -- The phase that moves a fall of /RD or /WR a clock toward FALL_POS_MIN
    -- to FALL_POS_MAX in the dot: later if it fell late in the dot, earlier
    -- if it fell early or near the end
    function get_phase_next(reg : edge_reg_t) return phase_t
    is
        variable pos   : phase_t;
        variable phase : integer;
    begin
        pos := get_dot_pos(reg);
        phase := reg.phase;
        if pos > FALL_POS_MAX
        then
            if 2 * pos <= reg.third + FALL_POS_MIN + FALL_POS_MAX
            then
                phase := phase + 1;
            else
                phase := phase - 1;
            end if;
        elsif pos < FALL_POS_MIN
        then
            phase := phase - 1;
        end if;

        if phase < 0
        then
            return reg.third - 1;
        elsif phase >= reg.third
        then
            return 0;
        else
            return phase;
        end if;
    end;

    function cycle_cart_edge(edge_in : edge_in_t) return edge_reg_t
    is
        variable reg   : edge_reg_t;
        variable third : phase_t;
    begin
        reg := edge_in.reg;

        reg.sync_1 := to_edge_pins(edge_in.pins_in,
                                   edge_in.cpu_data_bus,
                                   edge_in.ppu_data_bus);
        reg.sync_2 := edge_in.reg.sync_1;
        reg.m2_prev := edge_in.reg.sync_2.m2;
        reg.rd_prev := edge_in.reg.sync_2.ppu_rd_n;
        reg.wr_prev := edge_in.reg.sync_2.ppu_wr_n;

        if edge_in.reg.sync_2.m2 = '1' and not is_cpu_pending(edge_in.reg)
        then
            reg.cpu_hold := get_m2_bus(edge_in.reg.sync_2);
        end if;

        third := get_third(edge_in.reg);
        reg.third := third;

        if is_m2_fall(edge_in.reg)
        then
            reg.m2_count := 1;
        elsif edge_in.reg.m2_count < MAX_COUNT
        then
            reg.m2_count := edge_in.reg.m2_count + 1;
        end if;

        if is_ppu_en(edge_in.reg)
        then
            reg.dot_pos := 1;
        elsif edge_in.reg.dot_pos < phase_t'high
        then
            reg.dot_pos := edge_in.reg.dot_pos + 1;
        end if;

        if is_rd_fall(edge_in.reg) or is_wr_fall(edge_in.reg)
        then
            reg.phase_next := get_phase_next(edge_in.reg);
        end if;

        if is_cpu_en(edge_in.reg)
        then
            -- The last M2 period and the PPU set the next CPU cycle's dots
            reg.cpu_pending := false;
            reg.dot_idx := 0;
            reg.dot_len := third;
            reg.phase := edge_in.reg.phase_next;
        else
            reg.cpu_pending := is_cpu_pending(edge_in.reg);
            if is_ppu_en(edge_in.reg)
            then
                reg.dot_idx := edge_in.reg.dot_idx + 1;
            end if;
        end if;

        if is_ram_en(edge_in.reg)
        then
            reg.cpu_held := get_pin_cpu_in(edge_in.reg);
            reg.ppu_held := get_pin_ppu_in(edge_in.reg);
            reg.rd_fell := false;
            reg.wr_fell := false;
        else
            reg.rd_fell := edge_in.reg.rd_fell or is_rd_fall(edge_in.reg);
            reg.wr_fell := edge_in.reg.wr_fell or is_wr_fall(edge_in.reg);
        end if;

        if edge_in.reg.sync_2.ppu_wr_n = '0'
        then
            reg.ppu_wr_addr := edge_in.reg.sync_2.ppu_addr;
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
    clk_sync <= reg.dot_idx = 2;
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
