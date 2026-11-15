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
    -- or /WR, D for write data, L for ALE) and the bus before and after
    BUS_CHECK_FILEPATH : string := "";
    BUS_CHECK_LATE_CLOCKS : positive := 2
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
    constant CLK_FREQ : positive := 50_000_000 * 6 / 28;
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

    soc : nes_soc_ocram
    generic map
    (
        -- The bench runs the RAMs built for simulation. nes_de1_bench runs
        -- the ones synthesized for the DE1
        VENDOR => VENDOR_SIM,
        CLK_FREQ => CLK_FREQ,
        CPU_FREQ_NUM => CLK_FREQ,
        CPU_FREQ_DEN => 6,
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