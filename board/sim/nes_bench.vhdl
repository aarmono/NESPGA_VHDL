library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.chr_bus_types.all;
use work.cpu_bus_types.all;
use work.prg_bus_types.all;
use work.cart_mem_bus_types.all;
use work.cart_connector_types.all;
use work.cart_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.perhipherals.all;
use work.soc.all;
use work.console.all;
use work.cart.all;
use work.cart_pin_types.all;
use work.de1_types.all;
use work.simulation.all;
use work.binary_io.all;

entity nes_bench is
generic
(
    AU_FILEPATH     : string;
    BMP_FILE_PREFIX : string;
    NES_FILEPATH    : string;
    FM2_FILEPATH    : string := "";
    NES_FILE_BYTES  : integer := 196608;
    FM2_OFFSET      : integer := 2;
    -- Fill the RAMs with random bytes, the same ones in every run
    POWER_UP_FILL   : boolean := false;
    -- With POWER_UP_FILL, other seeds fill the RAMs with other bytes and
    -- start the PPU at another point of its frame
    POWER_UP_SEED   : natural := 0;
    -- Swaps which CPU cycles are APU get cycles. See clk_en
    INVERT_CYCLE_PARITY : boolean := false;
    -- Run as a Famicom rather than a front loading NES. See nes_console
    FAMICOM         : boolean := false;
    -- When set, write the CPU's external bus to this file, a line per CPU
    -- cycle once the NES is running: cycle, A0-A15, R/W (I when the bus is
    -- idle) and, for writes, D0-D7. See board/sim/trace/trace_diff.py
    TRACE_FILEPATH  : string := "";
    -- When set, write the visible pixels to this file from the first frame
    -- that starts once the NES is running, 2 bytes each: the colour, then
    -- the emphasis bits. See board/sim/trace/video_diff.py
    VIDEO_TRACE_FILEPATH : string := "";
    -- Report as an error each late change of the cartridge connector once
    -- the NES is running, which ends the run unless it is given
    -- --assert-level=none. On the CPU side (C), that is a
    -- change LATE_CLOCKS or more clocks after the start of a CPU cycle. A
    -- connector on pins needs the address stable before M2 rises, about 3/8
    -- of the way into the cycle, and write data before M2 falls. On the PPU
    -- side (P), it is any change after the clock that starts a dot. Each
    -- line has the CPU cycle, the side, clocks into its cycle or dot (CPU_DIV
    -- or 2 is when it ends), what changed (A for the address, /ROMSEL, /RD
    -- or /WR, D for write data, L for ALE) and the bus before and after.
    -- A CPU cycle where the bus neither reads nor writes is reported as I
    BUS_CHECK : boolean := true;
    BUS_CHECK_LATE_CLOCKS : positive := 2;
    -- Clocks in a CPU cycle. The clock runs at 50MHz * CPU_CYCLE_CLOCKS / 28,
    -- so the CPU cycle is as long as 28 clocks of a 50MHz clock whatever
    -- this is. 28 runs the 50MHz clock of the DE1
    CPU_CYCLE_CLOCKS : positive := 6;
    -- The cartridge the console runs, and whether it is at the pins of a
    -- cart_slot. See bench_cart_t. The two at the pins need
    -- CPU_CYCLE_CLOCKS = 28
    BENCH_CART : bench_cart_t := CART_EMULATED;
    -- With CART_LOOPBACK_SLOT, the period in ps of the clock cart_edge and the
    -- cartridge run on, as in a real console, where the cartridge's clock
    -- has nothing to do with M2. 0 runs them on the console's clock. 20043
    -- gives a real NES's 27.94 clocks per CPU cycle, and a phase between the
    -- two clocks that keeps moving
    EDGE_CLK_PERIOD_PS : natural := 0;
    -- With CART_LOOPBACK_SLOT, the clocks after M2 falls that the console's dots
    -- start, at most 8. The console starts them as M2 falls, but a real
    -- NES's sit 0 to 3 master clocks after it: 0 to 7 clocks. M2 and
    -- /ROMSEL move this many clocks earlier and the other pins keep their
    -- timing, so the address changes this much closer to M2 rising and
    -- write data comes this much after it. The console sees CPU D0-D7 and
    -- /IRQ this many clocks late, so that it samples them where it would
    -- with M2 in its place
    LOOPBACK_DOT_OFFSET : natural := 0;
    -- With CART_LOOPBACK_SLOT, the cartridge's memory is an SRAM behind
    -- sram_rom, which serves each access as it is asked for, as in
    -- cart_de1. Otherwise it is the ROM file with one access per dot and
    -- the cartridge RAMs on chip. The console waits while the ROM file is
    -- copied into the SRAM, 3 clocks a byte. Timing violations at the SRAM
    -- are written to the output
    LOOPBACK_SRAM : boolean := false;
    -- With CART_LOOPBACK_SLOT, the console is answered by cart_boot_stub for this
    -- many CPU cycles before the cartridge takes over, as when a cartridge
    -- in a real console loads its game. 0 leaves the stub out
    LOOPBACK_STUB_CYCLES : natural := 0;
    -- CART_NROM_SLOT access times in ns: address to data for the PRG and CHR
    -- ROMs, /RD to data for the memories on the PPU bus, and PPU A10, A11
    -- and /A13 to CIRAM A10 and /CE, level shifters included. See nrom_cart
    SLOT_PRG_ACCESS_NS  : natural := 150;
    SLOT_CHR_ACCESS_NS  : natural := 150;
    SLOT_OE_ACCESS_NS   : natural := 50;
    SLOT_CIRAM_DELAY_NS : natural := 30
);
end nes_bench;

architecture behavioral of nes_bench is

    function get_power_up_mode(fill : boolean) return power_up_mode_t
    is
    begin
        if fill
        then
            return POWER_UP_DETERMINISTIC;
        else
            return POWER_UP_ZERO;
        end if;
    end function;

    constant POWER_UP_MODE : power_up_mode_t := get_power_up_mode(POWER_UP_FILL);

    -- The simulated clock runs at 50MHz * (6 / 28) and the CPU runs at
    -- exactly a sixth of it, so a CPU cycle is as long as 28 clocks of a
    -- 50MHz clock. That is the rate the core ran at before clk_en supported
    -- the exact NTSC rate. Keeping it keeps the run times in nes_tests.txt,
    -- and there are fewer clock events to simulate than at 50MHz
    constant CLK_FREQ : positive := 50_000_000 * CPU_CYCLE_CLOCKS / 28;
    constant CLK_PERIOD : time := 1 sec / CLK_FREQ;

    function get_edge_clk_period return time
    is
    begin
        if EDGE_CLK_PERIOD_PS = 0
        then
            return CLK_PERIOD;
        else
            return EDGE_CLK_PERIOD_PS * 1 ps;
        end if;
    end;

    constant EDGE_CLK_PERIOD : time := get_edge_clk_period;

    -- cart_slot's M2_LOW_CLOCKS, which CART_LOOPBACK_SLOT moves M2 by
    constant SLOT_M2_LOW_CLOCKS : positive := 10;

    signal cart_mem_bus       : cart_mem_bus_t;
    signal data_from_cart_mem : data_t;
    
    signal audio_out : mixed_audio_t;
    signal pixel_bus : pixel_bus_t;
    -- The frames the FM2 input counts. While POWER_UP_FILL fills the RAMs,
    -- the PPU's position follows the fill's LFSR and frame_valid toggles
    -- about once a dot, which would play the FM2 before the NES runs
    signal fm2_frame_valid : boolean;

    signal joy_strobe : std_logic;

    signal joy_1_clk  : std_logic;
    signal joy_1_data : joy_data_t;

    signal joy_2_clk  : std_logic;
    signal joy_2_data : joy_data_t;

    signal ppu_clk_en : boolean;
    signal cpu_clk_en : boolean;
    
    signal soft_reset : boolean;
    
    signal clk : std_logic := '0';

    signal output_ready : boolean;

    signal board_cpu_in : cart_cpu_in_t;
    signal board_ppu_in : cart_ppu_in_t;

    -- The console's side of a cartridge at the pins, with CART_NROM_SLOT
    -- or CART_LOOPBACK_SLOT
    signal clk_sync       : boolean;
    signal cart_cpu_in    : cart_cpu_in_t;
    signal cart_cpu_out   : cart_cpu_out_t;
    signal cpu_data_bus   : data_t;
    signal cart_ppu_in    : cart_ppu_in_t;
    signal cart_ppu_out   : cart_ppu_out_t;
    signal cart_audio     : cart_audio_t;
    signal cart_loaded    : boolean := false;
    signal cart_ready     : boolean;

    signal power_up_ready : boolean;
    signal power_up_step  : boolean;
    signal console_power_up_ready : boolean;
    signal console_power_up_data  : console_power_up_data_t;

    -- The pins at the slot
    signal slot_pins       : cart_console_pins_t;
    signal slot_board_pins : cart_board_pins_t;

begin

    gen_soc : if BENCH_CART = CART_EMULATED generate
    soc : nes_soc_ocram
    generic map
    (
        -- The bench runs the RAMs built for simulation. nes_de1_bench runs
        -- the ones synthesized for the DE1
        VENDOR => VENDOR_SIM,
        CLK_FREQ => CLK_FREQ,
        CPU_FREQ_NUM => CLK_FREQ,
        CPU_FREQ_DEN => CPU_CYCLE_CLOCKS,
        POWER_UP_MODE => POWER_UP_MODE,
        POWER_UP_SEED => POWER_UP_SEED,
        INVERT_CYCLE_PARITY => INVERT_CYCLE_PARITY
    )
    port map
    (
        clk => clk,
        reset => false,
        soft_reset => soft_reset,
        famicom => FAMICOM,

        nes_running => output_ready,

        ppu_clk_en => ppu_clk_en,
        cpu_clk_en => cpu_clk_en,
        
        cart_mem_bus => cart_mem_bus,
        data_from_cart_mem => data_from_cart_mem,
        
        pixel_bus => pixel_bus,
        audio => audio_out,

        joy_strobe => joy_strobe,

        joy_1_clk => joy_1_clk,
        joy_1_data => joy_1_data,

        joy_2_clk => joy_2_clk,
        joy_2_data => joy_2_data,

        board_cpu_in => board_cpu_in,
        board_ppu_in => board_ppu_in
    );
    end generate;

    -- The console on its own, with its cartridge at the pins of a cart_slot
    gen_slot : if BENCH_CART /= CART_EMULATED generate
    begin
        assert CPU_CYCLE_CLOCKS = 28
            report "nes_bench: a cartridge at the pins needs " &
                   "CPU_CYCLE_CLOCKS = 28"
            severity failure;

        console : nes_console_ocram
        generic map
        (
            VENDOR => VENDOR_SIM,
            CLK_FREQ => CLK_FREQ,
            CPU_FREQ_NUM => CLK_FREQ,
            CPU_FREQ_DEN => CPU_CYCLE_CLOCKS,
            INVERT_CYCLE_PARITY => INVERT_CYCLE_PARITY
        )
        port map
        (
            clk => clk,
            reset => false,
            soft_reset => soft_reset,
            famicom => FAMICOM,

            nes_running => output_ready,

            cpu_clk_en => cpu_clk_en,
            ppu_clk_en => ppu_clk_en,
            clk_sync => clk_sync,

            pixel_bus => pixel_bus,
            audio => audio_out,

            joy_strobe => joy_strobe,

            joy_1_clk => joy_1_clk,
            joy_1_data => joy_1_data,

            joy_2_clk => joy_2_clk,
            joy_2_data => joy_2_data,

            cart_cpu_in => cart_cpu_in,
            cart_cpu_out => cart_cpu_out,
            cpu_data_bus => cpu_data_bus,
            cart_ppu_in => cart_ppu_in,
            cart_ppu_out => cart_ppu_out,
            cart_audio => cart_audio,

            run => cart_ready,
            power_up_ready => console_power_up_ready,
            power_up_data => console_power_up_data,
            power_up_step => power_up_step
        );

        console_power_up_ready <= power_up_ready and cart_loaded;

        slot : cart_slot
        generic map
        (
            M2_LOW_CLOCKS => SLOT_M2_LOW_CLOCKS
        )
        port map
        (
            clk => clk,
            reset => false,

            cpu_en => cpu_clk_en,
            ppu_en => ppu_clk_en,

            cpu_in => cart_cpu_in,
            cpu_out => cart_cpu_out,
            cpu_data_bus => cpu_data_bus,
            ppu_in => cart_ppu_in,
            ppu_out => cart_ppu_out,

            pins_out => slot_pins,
            pins_in => slot_board_pins
        );

        board_cpu_in <= cart_cpu_in;
        board_ppu_in <= cart_ppu_in;
    end generate;

    -- A real NROM cartridge at the pins (see nrom_cart)
    gen_nrom : if BENCH_CART = CART_NROM_SLOT generate
        signal board_drive : cart_board_drive_t;
    begin
        cart_audio <= 0;
        cart_ready <= true;

        -- The console has the power up fill to itself. The component is
        -- named in full, because the POWER_UP_FILL generic hides it
        fill : component work.perhipherals.power_up_fill
        generic map
        (
            MODE => POWER_UP_MODE,
            DATA_BITS => console_power_up_data_t'length,
            SEED => POWER_UP_SEED
        )
        port map
        (
            clk => clk,
            enable => false,
            step => power_up_step,
            ready => power_up_ready,
            data => console_power_up_data
        );

        -- A real cartridge has no header to load. cart_system has loaded the
        -- header on its 16th CPU cycle, so the console starts its fill on the
        -- same cycle as with the emulated cartridge, and the CPU cycles keep
        -- their parity
        process(clk)
        is
            variable cycles : natural := 0;
        begin
        if rising_edge(clk) and cpu_clk_en and not cart_loaded
        then
            cycles := cycles + 1;
            cart_loaded <= cycles = 15;
        end if;
        end process;

        cart : nrom_cart
        generic map
        (
            NES_FILEPATH => NES_FILEPATH,
            NES_FILE_BYTES => NES_FILE_BYTES,
            PRG_ACCESS => SLOT_PRG_ACCESS_NS * 1 ns,
            CHR_ACCESS => SLOT_CHR_ACCESS_NS * 1 ns,
            OE_ACCESS => SLOT_OE_ACCESS_NS * 1 ns,
            CIRAM_DELAY => SLOT_CIRAM_DELAY_NS * 1 ns,
            -- cart_slot samples on every clock, and the console takes the
            -- sample of the clock before M2 falls, or two clocks before /RD
            -- rises
            CPU_SAMPLE_LEAD => CLK_PERIOD,
            PPU_SAMPLE_LEAD => 2 * CLK_PERIOD,
            PPU_DOT => CLK_PERIOD * CPU_CYCLE_CLOCKS / 3
        )
        port map
        (
            pins => slot_pins,
            pins_out => board_drive
        );

        pin_bus : cart_pin_bus
        generic map
        (
            NAME => "nes_bench"
        )
        port map
        (
            console => slot_pins,
            drive => board_drive,
            board => slot_board_pins
        );
    end generate;

    -- The emulated cartridge through the pins: the console's cart_slot
    -- drives them, and cart_edge turns them back into the connector and
    -- clock enables of the cartridge, which only has the pins. Both sides
    -- driving a data bus is written to the output
    gen_loopback : if BENCH_CART = CART_LOOPBACK_SLOT generate
        signal power_up_data : power_up_data_t;

        -- The pins at the cartridge
        signal console_pins : cart_console_pins_t;
        signal board_pins   : cart_board_pins_t;
        signal board_drive  : cart_board_drive_t;

        -- M2 and /ROMSEL moved for LOOPBACK_DOT_OFFSET
        signal early_m2       : std_logic := '1';
        signal early_romsel_n : std_logic := '1';
        -- CPU D0-D7 and /IRQ as the console sees them for
        -- LOOPBACK_DOT_OFFSET
        signal delayed_cpu_data : data_t := (others => '0');
        signal delayed_irq_n    : std_logic := '1';

        -- The cartridge's side
        signal edge_clk      : std_logic;
        signal edge_cpu_en   : boolean;
        signal edge_ppu_en   : boolean;
        signal edge_clk_sync : boolean;
        signal edge_ram_en   : boolean;
        signal edge_cpu_in   : cart_cpu_in_t;
        signal edge_cpu_out  : cart_cpu_out_t;
        signal edge_ppu_in   : cart_ppu_in_t;
        signal edge_ppu_out  : cart_ppu_out_t;
        -- What the cartridge answers, before the boot stub
        signal sys_cpu_out   : cart_cpu_out_t;
        signal sys_ppu_out   : cart_ppu_out_t;

        -- The power up data as it was on the console's last CPU clock enable
        signal cart_power_up_ready : boolean := false;
        signal cart_power_up_data  : cart_power_up_data_t;
    begin
        assert LOOPBACK_DOT_OFFSET <= SLOT_M2_LOW_CLOCKS - 2
            report "nes_bench: LOOPBACK_DOT_OFFSET is too large"
            severity failure;

        -- Shared by the console and the cartridge, as in nes_soc_ocram
        fill : component work.perhipherals.power_up_fill
        generic map
        (
            MODE => POWER_UP_MODE,
            DATA_BITS => power_up_data_t'length,
            SEED => POWER_UP_SEED
        )
        port map
        (
            clk => clk,
            enable => false,
            step => power_up_step,
            ready => power_up_ready,
            data => power_up_data
        );

        console_power_up_data <= power_up_data(console_power_up_data_t'range);

        -- M2 and /ROMSEL LOOPBACK_DOT_OFFSET clocks earlier than the slot's.
        -- A CPU cycle is always CPU_CYCLE_CLOCKS here, so where M2 is comes
        -- from the clocks since cpu_clk_en
        process(clk)
        is
            variable position : natural range 0 to CPU_CYCLE_CLOCKS - 1 := 0;
            variable m2       : std_logic;
        begin
        if rising_edge(clk)
        then
            if cpu_clk_en
            then
                position := 0;
            elsif position < CPU_CYCLE_CLOCKS - 1
            then
                position := position + 1;
            end if;

            -- The slot's M2 is high after the clock edges SLOT_M2_LOW_CLOCKS
            -- to CPU_CYCLE_CLOCKS - 1 after cpu_clk_en
            if position >= SLOT_M2_LOW_CLOCKS - LOOPBACK_DOT_OFFSET and
               position < CPU_CYCLE_CLOCKS - LOOPBACK_DOT_OFFSET
            then
                m2 := '1';
            else
                m2 := '0';
            end if;

            early_m2 <= m2;
            if m2 = '1' and cart_cpu_in.romsel
            then
                early_romsel_n <= '0';
            else
                early_romsel_n <= '1';
            end if;
        end if;
        end process;

        -- The console's CPU samples CPU D0-D7 and /IRQ as its cycle ends,
        -- LOOPBACK_DOT_OFFSET clocks after M2 falls, so it sees them as
        -- late
        process(clk)
        is
            type cpu_pins_t is record
                cpu_data : data_t;
                irq_n    : std_logic;
            end record;
            -- With the signal's register, LOOPBACK_DOT_OFFSET clocks
            constant LAST : natural := maximum(LOOPBACK_DOT_OFFSET - 1, 0);
            type delay_t is array(0 to LAST) of cpu_pins_t;
            variable delay : delay_t := (others => ((others => '0'), '1'));
        begin
        if rising_edge(clk)
        then
            for i in LAST downto 1
            loop
                delay(i) := delay(i - 1);
            end loop;
            delay(0) := (board_pins.cpu_data, board_pins.irq_n);
            delayed_cpu_data <= delay(LAST).cpu_data;
            delayed_irq_n <= delay(LAST).irq_n;
        end if;
        end process;

        process(board_pins, delayed_cpu_data, delayed_irq_n)
        is
            variable pins : cart_board_pins_t;
        begin
            pins := board_pins;
            if LOOPBACK_DOT_OFFSET > 0
            then
                pins.cpu_data := delayed_cpu_data;
                pins.irq_n := delayed_irq_n;
            end if;
            slot_board_pins <= pins;
        end process;

        process(slot_pins, early_m2, early_romsel_n)
        is
            variable pins : cart_console_pins_t;
        begin
            pins := slot_pins;
            if LOOPBACK_DOT_OFFSET > 0
            then
                pins.m2 := early_m2;
                pins.romsel_n := early_romsel_n;
                -- The slot precharges the bus until its own M2 rises, but
                -- the cartridge may answer a read once this one has
                if early_m2 = '1' and slot_pins.m2 = '0'
                then
                    pins.cpu_data_oe := false;
                end if;
            end if;
            console_pins <= pins;
        end process;

        pin_bus : cart_pin_bus
        generic map
        (
            NAME => "nes_bench"
        )
        port map
        (
            console => console_pins,
            drive => board_drive,
            board => board_pins
        );

        -- A clock of its own even at the console's period: assigning clk
        -- to edge_clk would delay it by a delta, and the edge would sample
        -- the pins the console's registers have just changed
        edge_clk_gen : clock
        generic map
        (
            PERIOD => EDGE_CLK_PERIOD
        )
        port map
        (
            clk => edge_clk,
            done => false
        );

        edge : cart_edge
        generic map
        (
            DOT_CLOCKS => (CPU_CYCLE_CLOCKS * CLK_PERIOD) / (3 * EDGE_CLK_PERIOD)
        )
        port map
        (
            clk => edge_clk,
            reset => false,

            pins_in => console_pins,
            cpu_data_bus => board_pins.cpu_data,
            ppu_data_bus => board_pins.ppu_data,
            pins_out => board_drive,

            cpu_en => edge_cpu_en,
            ppu_en => edge_ppu_en,
            clk_sync => edge_clk_sync,
            ram_en => edge_ram_en,

            cpu_in => edge_cpu_in,
            cpu_out => edge_cpu_out,
            ppu_in => edge_ppu_in,
            ppu_out => edge_ppu_out
        );

        -- The console steps the power up data on its CPU clock enable, and
        -- the cartridge's comes a few clocks later
        process(clk)
        is
        begin
        if rising_edge(clk) and cpu_clk_en
        then
            cart_power_up_ready <= power_up_ready;
            cart_power_up_data <=
                power_up_data(power_up_data_t'high downto
                              console_power_up_data_t'length);
        end if;
        end process;

        gen_no_stub : if LOOPBACK_STUB_CYCLES = 0 generate
            edge_cpu_out <= sys_cpu_out;
            edge_ppu_out <= sys_ppu_out;
        end generate;

        gen_stub : if LOOPBACK_STUB_CYCLES > 0 generate
            signal stub_cycles : natural := 0;
            signal stub_ready  : boolean := false;
        begin
            process(edge_clk)
            begin
            if rising_edge(edge_clk) and edge_cpu_en and cart_ready
            then
                if stub_cycles < LOOPBACK_STUB_CYCLES
                then
                    stub_cycles <= stub_cycles + 1;
                else
                    stub_ready <= true;
                end if;
            end if;
            end process;

            stub : cart_boot_stub
            port map
            (
                clk => edge_clk,
                reset => false,

                cpu_en => edge_cpu_en,
                ready => stub_ready,
                active => open,

                cpu_in => edge_cpu_in,
                ppu_in => edge_ppu_in,

                cart_cpu_out => sys_cpu_out,
                cart_ppu_out => sys_ppu_out,

                cpu_out => edge_cpu_out,
                ppu_out => edge_ppu_out
            );
        end generate;

        gen_mem_mux : if not LOOPBACK_SRAM generate
            cart_sys : cart_system_ocram
            generic map
            (
                VENDOR => VENDOR_SIM
            )
            port map
            (
                clk => edge_clk,
                reset => false,

                cpu_en => edge_cpu_en,
                ppu_en => edge_ppu_en,
                clk_sync => edge_clk_sync,
                ram_en => edge_ram_en,

                power_up_ready => cart_power_up_ready,
                power_up_data => cart_power_up_data,

                loaded => cart_loaded,
                ready => cart_ready,

                cpu_in => edge_cpu_in,
                cpu_out => sys_cpu_out,
                ppu_in => edge_ppu_in,
                ppu_out => sys_ppu_out,
                audio => cart_audio,

                cart_mem_bus => cart_mem_bus,
                data_to_cart_mem => open,
                data_from_cart_mem => data_from_cart_mem
            );
        end generate;

        gen_mem_sram : if LOOPBACK_SRAM generate
            constant SRAM_ADDR_BITS : positive := cart_mem_addr_t'length - 1;

            signal rom_loading : boolean;

            signal load_valid : boolean := false;
            signal load_data  : data_t := (others => '0');
            signal load_ready : boolean;

            signal prg_mem_bus       : cart_mem_bus_t;
            signal data_to_prg_mem   : data_t;
            signal data_from_prg_mem : data_t;
            signal chr_mem_bus       : cart_mem_bus_t;
            signal data_to_chr_mem   : data_t;
            signal data_from_chr_mem : data_t;

            signal sram_addr : std_logic_vector(SRAM_ADDR_BITS - 1 downto 0);
            signal sram_dq   : std_logic_vector(15 downto 0);
            signal sram_ce_n : std_logic;
            signal sram_oe_n : std_logic;
            signal sram_we_n : std_logic;
            signal sram_lb_n : std_logic;
            signal sram_ub_n : std_logic;
        begin
            -- The bench's ROM file memory isn't used
            cart_mem_bus <= CART_MEM_BUS_IDLE;

            cart_sys : cart_system_ocram
            generic map
            (
                CART_MEM => CART_MEM_SPLIT,
                VENDOR => VENDOR_SIM
            )
            port map
            (
                clk => edge_clk,
                reset => rom_loading,

                cpu_en => edge_cpu_en,
                ppu_en => edge_ppu_en,
                clk_sync => edge_clk_sync,
                ram_en => edge_ram_en,

                power_up_ready => cart_power_up_ready,
                power_up_data => cart_power_up_data,

                loaded => cart_loaded,
                ready => cart_ready,

                cpu_in => edge_cpu_in,
                cpu_out => sys_cpu_out,
                ppu_in => edge_ppu_in,
                ppu_out => sys_ppu_out,
                audio => cart_audio,

                cart_mem_bus => open,
                data_to_cart_mem => open,

                prg_mem_bus => prg_mem_bus,
                data_to_prg_mem => data_to_prg_mem,
                data_from_prg_mem => data_from_prg_mem,

                chr_mem_bus => chr_mem_bus,
                data_to_chr_mem => data_to_chr_mem,
                data_from_chr_mem => data_from_chr_mem
            );

            -- The ROM file as a byte stream. A byte is taken on the clock
            -- load_ready is true
            process(edge_clk)
            is
                type byte_file_t is file of character;
                file rom_file : byte_file_t open read_mode is NES_FILEPATH;
                variable byte : character;
            begin
            if rising_edge(edge_clk) and (load_ready or not load_valid)
            then
                if endfile(rom_file)
                then
                    load_valid <= false;
                else
                    read(rom_file, byte);
                    load_data <= to_std_logic_vector(character'pos(byte),
                                                     data_t'length);
                    load_valid <= true;
                end if;
            end if;
            end process;

            rom : sram_rom
            generic map
            (
                ADDR_BITS => SRAM_ADDR_BITS
            )
            port map
            (
                clk => edge_clk,
                reset => false,

                loading => rom_loading,
                too_large => open,

                load_valid => load_valid,
                load_data => load_data,
                load_ready => load_ready,

                prg_mem_bus => prg_mem_bus,
                data_to_prg_mem => data_to_prg_mem,
                data_from_prg_mem => data_from_prg_mem,

                chr_mem_bus => chr_mem_bus,
                data_to_chr_mem => data_to_chr_mem,
                data_from_chr_mem => data_from_chr_mem,

                sram_addr => sram_addr,
                sram_dq => sram_dq,
                sram_ce_n => sram_ce_n,
                sram_oe_n => sram_oe_n,
                sram_we_n => sram_we_n,
                sram_lb_n => sram_lb_n,
                sram_ub_n => sram_ub_n
            );

            sram : sram_16
            generic map
            (
                ADDR_BITS => SRAM_ADDR_BITS
            )
            port map
            (
                addr => sram_addr,
                dq => sram_dq,
                ce_n => sram_ce_n,
                oe_n => sram_oe_n,
                we_n => sram_we_n,
                lb_n => sram_lb_n,
                ub_n => sram_ub_n
            );
        end generate;

    end generate;

    gen_trace : if TRACE_FILEPATH'length > 0 generate
        file trace_file : text open write_mode is TRACE_FILEPATH;
    begin
        -- The CPU bus is only valid at cpu_clk_en
        process(clk)
        is
            variable cycle : natural := 0;
            variable l     : line;
        begin
        if rising_edge(clk) and cpu_clk_en and output_ready
        then
            write(l, cycle, right, 8);
            write(l, ' ');
            write(l, to_hstring(std_logic_vector'(
                to_std_logic(board_cpu_in.romsel) &
                board_cpu_in.prg_bus.address)));
            if board_cpu_in.prg_bus.write
            then
                write(l, string'(" W "));
                write(l, to_hstring(board_cpu_in.data));
            elsif board_cpu_in.prg_bus.read
            then
                write(l, string'(" R --"));
            else
                write(l, string'(" I --"));
            end if;
            writeline(trace_file, l);
            cycle := cycle + 1;
        end if;
        end process;
    end generate;
    
    gen_bus_check : if BUS_CHECK generate

        -- Counted by the CPU side's process, so both sides' lines can be
        -- matched up
        signal cycle : natural := 0;

        function bus_image(cpu_in : cart_cpu_in_t) return string
        is
        begin
            if cpu_in.prg_bus.write
            then
                return to_hstring(std_logic_vector'(
                           to_std_logic(cpu_in.romsel) &
                           cpu_in.prg_bus.address)) &
                       " W " & to_hstring(cpu_in.data);
            elsif cpu_in.prg_bus.read
            then
                return to_hstring(std_logic_vector'(
                           to_std_logic(cpu_in.romsel) &
                           cpu_in.prg_bus.address)) & " R --";
            else
                return "---- I --";
            end if;
        end;

        function bus_image(ppu_in : cart_ppu_in_t) return string
        is
            function ale_image(ale : boolean) return string
            is
            begin
                if ale
                then
                    return " L";
                else
                    return " -";
                end if;
            end;
        begin
            if ppu_in.chr_bus.write
            then
                return to_hstring(ppu_in.chr_bus.address) &
                       " W " & to_hstring(ppu_in.data) &
                       ale_image(ppu_in.ale);
            elsif ppu_in.chr_bus.read
            then
                return to_hstring(ppu_in.chr_bus.address) & " R --" &
                       ale_image(ppu_in.ale);
            else
                return "---- I --" & ale_image(ppu_in.ale);
            end if;
        end;

        procedure write_change
        (
            at_cycle : natural;
            clocks   : natural;
            side     : character;
            what     : character;
            old_bus  : string;
            new_bus  : string
        )
        is
            variable l : line;
        begin
            write(l, at_cycle, right, 8);
            write(l, ' ');
            write(l, side);
            write(l, clocks, right, 2);
            write(l, ' ');
            write(l, what);
            write(l, ' ');
            write(l, old_bus);
            write(l, string'(" -> "));
            write(l, new_bus);
            report "nes_bench: late bus change " &
                   "(cycle, side and clocks, what, change): " & l.all
                severity error;
            deallocate(l);
        end;
    begin
        process(clk)
        is
            -- Clocks since the clock enable that started the CPU cycle
            variable clocks  : natural := 0;
            variable prev    : cart_cpu_in_t;
            variable started : boolean := false;
            variable addr_changed : boolean;
            variable data_changed : boolean;
        begin
        if rising_edge(clk)
        then
            clocks := clocks + 1;

            -- The bus sampled on a clock is what the clock before it left
            if started and output_ready
            then
                -- The address of an idle bus is a don't care
                addr_changed :=
                    prev.prg_bus.read /= board_cpu_in.prg_bus.read or
                    prev.prg_bus.write /= board_cpu_in.prg_bus.write or
                    (is_bus_active(board_cpu_in.prg_bus) and
                     (prev.prg_bus.address /= board_cpu_in.prg_bus.address or
                      prev.romsel /= board_cpu_in.romsel));
                data_changed :=
                    board_cpu_in.prg_bus.write and
                    prev.prg_bus.write and
                    prev.data /= board_cpu_in.data;

                if clocks >= BUS_CHECK_LATE_CLOCKS and addr_changed
                then
                    write_change(cycle, clocks, 'C', 'A',
                                 bus_image(prev), bus_image(board_cpu_in));
                elsif clocks >= BUS_CHECK_LATE_CLOCKS and data_changed
                then
                    write_change(cycle, clocks, 'C', 'D',
                                 bus_image(prev), bus_image(board_cpu_in));
                end if;
            end if;

            prev := board_cpu_in;

            -- A real bus always reads or writes
            if cpu_clk_en and output_ready and
               not is_bus_active(board_cpu_in.prg_bus)
            then
                write_change(cycle, clocks, 'C', 'I',
                             bus_image(board_cpu_in), bus_image(board_cpu_in));
            end if;

            if cpu_clk_en
            then
                started := true;
                clocks := 0;
                if output_ready
                then
                    cycle <= cycle + 1;
                end if;
            end if;
        end if;
        end process;

        -- The PPU side changes once a dot, at the clock of ppu_clk_en. A
        -- change on any later clock of the dot is late: a connector on pins
        -- needs the address stable through /RD and /WR, and the write data
        -- through /WR
        process(clk)
        is
            -- Clocks since the clock enable that started the PPU dot
            variable clocks  : natural := 0;
            variable prev    : cart_ppu_in_t;
            variable started : boolean := false;
            variable addr_changed : boolean;
            variable data_changed : boolean;
        begin
        if rising_edge(clk)
        then
            clocks := clocks + 1;

            if started and output_ready and clocks >= 2
            then
                addr_changed :=
                    prev.chr_bus.read /= board_ppu_in.chr_bus.read or
                    prev.chr_bus.write /= board_ppu_in.chr_bus.write or
                    (is_bus_active(board_ppu_in.chr_bus) and
                     prev.chr_bus.address /= board_ppu_in.chr_bus.address);
                data_changed :=
                    board_ppu_in.chr_bus.write and
                    prev.chr_bus.write and
                    prev.data /= board_ppu_in.data;

                if addr_changed
                then
                    write_change(cycle, clocks, 'P', 'A',
                                 bus_image(prev), bus_image(board_ppu_in));
                elsif data_changed
                then
                    write_change(cycle, clocks, 'P', 'D',
                                 bus_image(prev), bus_image(board_ppu_in));
                elsif prev.ale /= board_ppu_in.ale
                then
                    write_change(cycle, clocks, 'P', 'L',
                                 bus_image(prev), bus_image(board_ppu_in));
                end if;
            end if;

            prev := board_ppu_in;

            if ppu_clk_en
            then
                started := true;
                clocks := 0;
            end if;
        end if;
        end process;
    end generate;

    gen_video_trace : if VIDEO_TRACE_FILEPATH'length > 0 generate
        file video_file : byte_file_t open write_mode is VIDEO_TRACE_FILEPATH;
    begin
        process(clk)
        is
            -- A frame under way when the NES starts running is skipped
            variable started          : boolean := false;
            variable prev_frame_valid : boolean := true;
        begin
        if rising_edge(clk) and ppu_clk_en and output_ready
        then
            if pixel_bus.frame_valid and not prev_frame_valid
            then
                started := true;
            end if;

            if started and pixel_bus.frame_valid and pixel_bus.line_valid
            then
                byte_fwrite(video_file, "00" & pixel_bus.pixel);
                byte_fwrite(video_file, "00000" & to_emphasis_bits(pixel_bus.emphasis));
            end if;

            prev_frame_valid := pixel_bus.frame_valid;
        end if;
        end process;
    end generate;

    fm2_frame_valid <= pixel_bus.frame_valid and output_ready;

    ppu_recorder : ppu_video_record
    generic map
    (
        FILE_PREFIX => BMP_FILE_PREFIX
    )
    port map
    (
        clk => clk,
        clk_en => ppu_clk_en,
        pixel_bus => pixel_bus,
        ready => output_ready,
        done => false
    );

    apu_recorder : apu_audio_record
    generic map
    (
        FILEPATH => AU_FILEPATH
    )
    port map
    (
        clk => clk,
        clk_en => cpu_clk_en,
        audio => audio_out,
        ready => output_ready,
        done => false
    );

    fm2_controller : fm2_joystick
    generic map
    (
        FILEPATH => FM2_FILEPATH,
        INPUT_OFFSET => FM2_OFFSET
    )
    port map
    (
        frame_valid => fm2_frame_valid,

        soft_reset => soft_reset,

        joy_strobe => joy_strobe,

        joy_1_clk => joy_1_clk,
        joy_1_data => joy_1_data,

        joy_2_clk => joy_2_clk,
        joy_2_data => joy_2_data
    );
    
    nes_file : file_memory
    generic map
    (
       FILEPATH => NES_FILEPATH,
       MEM_BYTES => NES_FILE_BYTES,
       READ_DELAY => CLK_PERIOD / 2
    )
    port map
    (
       file_bus_1 => get_file_bus(cart_mem_bus),
       data_from_file_1 => data_from_cart_mem
    );
    
    clk_gen : clock
    generic map
    (
        PERIOD => CLK_PERIOD
    )
    port map
    (
        clk => clk,
        done => false
    );

end behavioral;