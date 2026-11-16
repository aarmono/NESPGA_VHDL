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
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.soc.all;
use work.console.all;
use work.cart.all;
use work.cart_pin_types.all;
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
    -- When set, write to this file each late change of the cartridge
    -- connector once the NES is running. On the CPU side (C), that is a
    -- change LATE_CLOCKS or more clocks after the start of a CPU cycle. A
    -- connector on pins needs the address stable before M2 rises, about 3/8
    -- of the way into the cycle, and write data before M2 falls. On the PPU
    -- side (P), it is any change after the clock that starts a dot. Each
    -- line has the CPU cycle, the side, clocks into its cycle or dot (CPU_DIV
    -- or 2 is when it ends), what changed (A for the address, /ROMSEL, /RD
    -- or /WR, D for write data, L for ALE) and the bus before and after.
    -- A CPU cycle where the bus neither reads nor writes is logged as I
    BUS_CHECK_FILEPATH : string := "";
    BUS_CHECK_LATE_CLOCKS : positive := 2;
    -- Clocks in a CPU cycle. The clock runs at 50MHz * CPU_CYCLE_CLOCKS / 28,
    -- so the CPU cycle is as long as 28 clocks of a 50MHz clock whatever
    -- this is. 28 runs the 50MHz clock of the DE1
    CPU_CYCLE_CLOCKS : positive := 6;
    -- Run the cartridge as a real NROM cartridge at the pins of a cart_slot
    -- (see nrom_cart), instead of the emulated cartridge. Needs
    -- CPU_CYCLE_CLOCKS = 28, and only runs NROM ROMs with the RAMs zeroed.
    -- Timing violations at the pins are written to the output
    NROM_SLOT : boolean := false;
    -- Run the emulated cartridge through the pins: the console's cart_slot
    -- drives them, and cart_edge turns them back into the connector and
    -- clock enables of the cartridge, which only has the pins. Needs
    -- CPU_CYCLE_CLOCKS = 28. Both sides driving a data bus is written to the
    -- output
    LOOPBACK_SLOT : boolean := false
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
    
begin

    assert not (NROM_SLOT and LOOPBACK_SLOT)
        report "nes_bench: NROM_SLOT and LOOPBACK_SLOT can't both be set"
        severity failure;

    gen_soc : if not NROM_SLOT and not LOOPBACK_SLOT generate
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

    gen_slot : if NROM_SLOT generate
        signal clk_sync       : boolean;
        signal cart_cpu_in    : cart_cpu_in_t;
        signal cart_cpu_out   : cart_cpu_out_t;
        signal cpu_data_bus   : data_t;
        signal cart_ppu_in    : cart_ppu_in_t;
        signal cart_ppu_out   : cart_ppu_out_t;
        signal cart_loaded    : boolean := false;

        signal console_pins   : cart_console_pins_t;
        signal board_pins     : cart_board_pins_t;

        signal cart_cpu_data    : data_t;
        signal cart_cpu_data_oe : boolean;
        signal cart_ppu_data    : data_t;
        signal cart_ppu_data_oe : boolean;
    begin
        assert CPU_CYCLE_CLOCKS = 28
            report "nes_bench: NROM_SLOT needs CPU_CYCLE_CLOCKS = 28"
            severity failure;

        console : nes_console_ocram
        generic map
        (
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

            cart_loaded => cart_loaded,
            cart_ready => true
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

        slot : cart_slot
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

            pins_out => console_pins,
            pins_in => board_pins
        );

        cart : entity work.nrom_cart
        generic map
        (
            NES_FILEPATH => NES_FILEPATH,
            NES_FILE_BYTES => NES_FILE_BYTES,
            -- cart_slot samples on every clock, and the console takes the
            -- sample of the clock before M2 falls, or two clocks before /RD
            -- rises
            CPU_SAMPLE_LEAD => CLK_PERIOD,
            PPU_SAMPLE_LEAD => 2 * CLK_PERIOD,
            PPU_DOT => CLK_PERIOD * CPU_CYCLE_CLOCKS / 3
        )
        port map
        (
            pins => console_pins,

            cpu_data => cart_cpu_data,
            cpu_data_oe => cart_cpu_data_oe,
            irq_n => board_pins.irq_n,

            ppu_data => cart_ppu_data,
            ppu_data_oe => cart_ppu_data_oe,
            ciram_ce_n => board_pins.ciram_ce_n,
            ciram_a10 => board_pins.ciram_a10
        );

        -- The shared data buses. An undriven bus keeps its last value, which
        -- a board would do with bus hold
        process(console_pins, cart_cpu_data, cart_cpu_data_oe)
        is
            variable value : data_t := (others => '0');
            variable l     : line;
        begin
            if console_pins.cpu_data_oe and cart_cpu_data_oe
            then
                write(l, string'("nes_bench: "));
                write(l, now);
                write(l, string'(" CPU data bus driven by both sides"));
                writeline(output, l);
                value := (others => 'X');
            elsif console_pins.cpu_data_oe
            then
                value := console_pins.cpu_data;
            elsif cart_cpu_data_oe
            then
                value := cart_cpu_data;
            end if;
            board_pins.cpu_data <= value;
        end process;

        process(console_pins, cart_ppu_data, cart_ppu_data_oe)
        is
            variable value : data_t := (others => '0');
            variable l     : line;
        begin
            if console_pins.ppu_data_oe and cart_ppu_data_oe
            then
                write(l, string'("nes_bench: "));
                write(l, now);
                write(l, string'(" PPU data bus driven by both sides"));
                writeline(output, l);
                value := (others => 'X');
            elsif console_pins.ppu_data_oe
            then
                value := console_pins.ppu_data;
            elsif cart_ppu_data_oe
            then
                value := cart_ppu_data;
            end if;
            board_pins.ppu_data <= value;
        end process;

        board_cpu_in <= cart_cpu_in;
        board_ppu_in <= cart_ppu_in;
    end generate;

    gen_loopback : if LOOPBACK_SLOT generate
        -- The console's side
        signal clk_sync       : boolean;
        signal cart_cpu_in    : cart_cpu_in_t;
        signal cart_cpu_out   : cart_cpu_out_t;
        signal cpu_data_bus   : data_t;
        signal cart_ppu_in    : cart_ppu_in_t;
        signal cart_ppu_out   : cart_ppu_out_t;
        signal cart_audio     : cart_audio_t;
        signal cart_loaded    : boolean;
        signal cart_ready     : boolean;
        signal power_up_ready : boolean;
        signal power_up_data  : power_up_data_t;

        -- The pins
        signal console_pins : cart_console_pins_t;
        signal board_pins   : cart_board_pins_t;
        signal board_drive  : cart_board_drive_t;

        -- The cartridge's side
        signal edge_cpu_en   : boolean;
        signal edge_ppu_en   : boolean;
        signal edge_clk_sync : boolean;
        signal edge_ram_en   : boolean;
        signal edge_cpu_in   : cart_cpu_in_t;
        signal edge_cpu_out  : cart_cpu_out_t;
        signal edge_ppu_in   : cart_ppu_in_t;
        signal edge_ppu_out  : cart_ppu_out_t;

        -- The power up data as it was on the console's last CPU clock enable
        signal cart_power_up_ready : boolean := false;
        signal cart_power_up_data  : power_up_data_t;
    begin
        assert CPU_CYCLE_CLOCKS = 28
            report "nes_bench: LOOPBACK_SLOT needs CPU_CYCLE_CLOCKS = 28"
            severity failure;

        console : nes_console_ocram
        generic map
        (
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

            cart_loaded => cart_loaded,
            cart_ready => cart_ready,

            power_up_ready => power_up_ready,
            power_up_data => power_up_data
        );

        slot : cart_slot
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

            pins_out => console_pins,
            pins_in => board_pins
        );

        -- The shared data buses. A bit nobody drives keeps its last value,
        -- which a board would do with bus hold
        process(console_pins, board_drive)
        is
            variable value : data_t := (others => '0');
            variable l     : line;
        begin
            for i in value'range
            loop
                if console_pins.cpu_data_oe and board_drive.cpu_data_oe(i) = '1'
                then
                    value(i) := 'X';
                elsif console_pins.cpu_data_oe
                then
                    value(i) := console_pins.cpu_data(i);
                elsif board_drive.cpu_data_oe(i) = '1'
                then
                    value(i) := board_drive.cpu_data(i);
                end if;
            end loop;

            if console_pins.cpu_data_oe and board_drive.cpu_data_oe /= x"00"
            then
                write(l, string'("nes_bench: "));
                write(l, now);
                write(l, string'(" CPU data bus driven by both sides"));
                writeline(output, l);
            end if;

            board_pins.cpu_data <= value;
        end process;

        process(console_pins, board_drive)
        is
            variable value : data_t := (others => '0');
            variable l     : line;
        begin
            if console_pins.ppu_data_oe and board_drive.ppu_data_oe
            then
                write(l, string'("nes_bench: "));
                write(l, now);
                write(l, string'(" PPU data bus driven by both sides"));
                writeline(output, l);
                value := (others => 'X');
            elsif console_pins.ppu_data_oe
            then
                value := console_pins.ppu_data;
            elsif board_drive.ppu_data_oe
            then
                value := board_drive.ppu_data;
            end if;
            board_pins.ppu_data <= value;
        end process;

        -- /IRQ is pulled up by the console
        board_pins.irq_n <= '0' when board_drive.irq_n = '0' else '1';
        board_pins.ciram_ce_n <= board_drive.ciram_ce_n;
        board_pins.ciram_a10 <= board_drive.ciram_a10;

        edge : cart_edge
        generic map
        (
            DOT_CLOCKS => CPU_CYCLE_CLOCKS / 3
        )
        port map
        (
            clk => clk,
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
            cart_power_up_data <= power_up_data;
        end if;
        end process;

        cart_sys : cart_system_ocram
        generic map
        (
            VENDOR => VENDOR_SIM
        )
        port map
        (
            clk => clk,
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
            cpu_out => edge_cpu_out,
            ppu_in => edge_ppu_in,
            ppu_out => edge_ppu_out,
            audio => cart_audio,

            cart_mem_bus => cart_mem_bus,
            data_to_cart_mem => open,
            data_from_cart_mem => data_from_cart_mem
        );

        board_cpu_in <= cart_cpu_in;
        board_ppu_in <= cart_ppu_in;
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
    
    gen_bus_check : if BUS_CHECK_FILEPATH'length > 0 generate
        file check_file : text open write_mode is BUS_CHECK_FILEPATH;

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
            writeline(check_file, l);
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