library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use std.env.all;
use work.nes_types.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.platform_video.all;
use work.lib_ppu.DOTS_PER_LINE;
use work.lib_ppu.LINES_PER_FRAME;
use work.lib_ppu.LAST_CYCLE;
use work.lib_ppu.FRAME_START;
use work.lib_ppu.FRAME_END;
-- The pre-render line
use work.lib_ppu.VINT_END;

-- Tests frame_lock_video against a synthetic PPU, which outputs a pattern
-- that identifies each pixel's line and column, and tags each frame. Every
-- picture pixel the output shows is checked, which catches the buffer being
-- overrun or read before it is written.
--
-- The synthetic NES waits to run as nes_soc does, from a random start
-- position, and can be reloaded part way through, as the SD menu does
entity frame_lock_bench is
generic
(
    -- The output's pixel clock period in ps. 27 MHz * 29/31 on the DE1.
    -- ghdl can't override time generics
    PIX_PERIOD_PS : positive := 39591;
    -- Added to the pixel clock's period, but not to the rates computed from
    -- it, as an oscillator's error would be
    PIX_ERROR_PS  : integer := 0;
    -- Output frames to run for
    FRAMES        : positive := 60;
    -- Odd frames skip a dot, as when rendering is enabled
    RENDER        : boolean := true;
    -- The NES frame to reload at, with a new start position. 0 for none
    RELOAD_FRAME  : natural := 0;
    RELOAD_US     : positive := 3000;
    SEED          : positive := 1;
    -- The rate the loop starts from. -1 for get_frame_lock_rates's
    START_RATE    : integer := -1
);
end frame_lock_bench;

architecture behavioral of frame_lock_bench is

    constant SYS_PERIOD : time := 20 ns;
    constant PIX_PERIOD : time := (PIX_PERIOD_PS + PIX_ERROR_PS) * 1 ps;

    constant RATES : frame_lock_rates_t :=
        get_frame_lock_rates(FORMAT_640X480,
                             1 sec / SYS_PERIOD,
                             1.0e12 / real(PIX_PERIOD_PS));

    function get_start_rate return natural
    is
    begin
        if START_RATE < 0
        then
            return RATES.start_rate;
        else
            return START_RATE;
        end if;
    end;

    signal done : boolean := false;

    signal clk_sys : std_logic := '0';
    signal clk_pix : std_logic := '0';

    signal reset_sys : boolean := true;
    signal reset_pix : boolean := true;

    signal nes_reset  : boolean := true;
    signal cpu_clk_en : boolean;
    signal ppu_clk_en : boolean;
    signal stretch    : boolean;
    signal run        : boolean;

    signal pixel_bus : pixel_bus_t :=
    (
        pixel => (others => '0'),
        emphasis => NO_EMPHASIS,
        line_valid => false,
        frame_valid => false
    );

    signal nes_running    : boolean := false;
    signal waiting_to_run : boolean := false;
    signal ppu_start      : ppu_position_t := (0, 0, 0);

    signal video : video_out_t;

    signal phase_error  : integer;
    signal stretch_rate : natural;
    signal locked       : boolean;

    -- NES frames started since the last start
    signal nes_frames : natural := 0;

    -- The time of an even number of NES frames, from the 10th after the
    -- last start, once the loop has settled
    signal nes_timed_frames : natural := 0;
    signal nes_timed_time   : delay_length := 0 fs;

    -- The first dot of each picture line with a pixel
    constant FIRST_PIXEL     : natural := 2;

    -- The pattern pixel at (x, y), and the tag of a frame
    function pattern(x : natural; y : natural) return pixel_t
    is
    begin
        return to_std_logic_vector((x + 3 * y) mod 64, pixel_t'length);
    end;

    function frame_tag(frame : natural) return emphasis_bits_t
    is
    begin
        return to_std_logic_vector(frame mod 7 + 1, emphasis_bits_t'length);
    end;

begin

    clk_sys <= not clk_sys after SYS_PERIOD / 2 when not done;
    clk_pix <= not clk_pix after PIX_PERIOD / 2 when not done;

    reset_sys <= false after 10 * SYS_PERIOD;
    reset_pix <= false after 10 * PIX_PERIOD;

    nes_clk_en : entity work.clk_en(behavioral)
    generic map
    (
        CPU_FREQ_NUM => RATES.cpu_freq_num,
        CPU_FREQ_DEN => RATES.cpu_freq_den
    )
    port map
    (
        clk => clk_sys,
        reset => nes_reset,
        stretch => stretch,

        cpu_en => cpu_clk_en,
        ppu_en => ppu_clk_en,
        nsf_en => open,
        cpu_ram_en => open,
        ppu_ram_en => open,
        ppu_sync => open,
        odd_cpu_cycle => open
    );

    dut : entity work.frame_lock_video(behavioral)
    generic map
    (
        VENDOR => VENDOR_SIM,
        START_RATE => get_start_rate,
        MAX_RATE => RATES.max_rate,
        LINE_PIXELS => RATES.line_pixels,
        FRAME_LINES => RATES.frame_lines
    )
    port map
    (
        clk_sys => clk_sys,
        reset_sys => reset_sys,
        clk_pix => clk_pix,
        reset_pix => reset_pix,

        cpu_clk_en => cpu_clk_en,
        ppu_clk_en => ppu_clk_en,
        pixel_bus => pixel_bus,

        nes_running => nes_running,
        waiting_to_run => waiting_to_run,
        ppu_start => ppu_start,

        stretch => stretch,
        run => run,

        video => video,

        phase_error => phase_error,
        stretch_rate => stretch_rate,
        locked => locked
    );

    -- The synthetic NES: loads, waits to run, then runs a PPU that outputs
    -- the pattern
    nes : process
        variable seed_1 : positive := SEED * 7919;
        variable seed_2 : positive := SEED * 104729 + 1;
        variable rand : real;

        variable line : natural;
        variable cycle : natural;
        variable odd : boolean;
        variable frame_count : natural;
        variable reloaded : boolean := false;

        procedure random_start is
        begin
            uniform(seed_1, seed_2, rand);
            ppu_start.scanline <= integer(floor(rand * real(LINES_PER_FRAME)));
            uniform(seed_1, seed_2, rand);
            ppu_start.cycle <= integer(floor(rand * real(DOTS_PER_LINE)));
            ppu_start.frame <= 0;
        end;

        procedure wait_and_start is
        begin
            -- Loading. clk_en is held in reset
            nes_reset <= true;
            nes_running <= false;
            waiting_to_run <= false;
            pixel_bus.line_valid <= false;
            random_start;
            wait for RELOAD_US * 1 us;
            wait until rising_edge(clk_sys);
            nes_reset <= false;

            -- The RAM fill, ~100 us
            for i in 1 to 200
            loop
                wait until rising_edge(clk_sys) and cpu_clk_en;
            end loop;

            waiting_to_run <= true;
            loop
                wait until rising_edge(clk_sys) and cpu_clk_en;
                exit when run;
            end loop;
            report "NES started at line " &
                   integer'image(ppu_start.scanline) & " cycle " &
                   integer'image(ppu_start.cycle);
            waiting_to_run <= false;
            nes_running <= true;
            line := ppu_start.scanline;
            cycle := ppu_start.cycle;
            odd := false;
            frame_count := 0;
            nes_frames <= 0;
        end;

    begin
        wait until not reset_sys;
        wait_and_start;

        loop
            wait until rising_edge(clk_sys) and ppu_clk_en;

            pixel_bus.frame_valid <= line >= FRAME_START and line <= FRAME_END;
            if line >= FRAME_START and line <= FRAME_END and
               cycle >= FIRST_PIXEL and cycle < FIRST_PIXEL + 256
            then
                pixel_bus.line_valid <= true;
                pixel_bus.pixel <= pattern(cycle - FIRST_PIXEL,
                                           line - FRAME_START);
                pixel_bus.emphasis <= to_emphasis_t(frame_tag(frame_count));
            else
                pixel_bus.line_valid <= false;
                pixel_bus.pixel <= (others => '0');
            end if;

            -- The pre-render line is a dot short on odd rendered frames
            if cycle = LAST_CYCLE or
               (RENDER and odd and line = VINT_END and
                cycle = LAST_CYCLE - 1)
            then
                cycle := 0;
                line := (line + 1) mod LINES_PER_FRAME;
                if line = FRAME_START
                then
                    frame_count := frame_count + 1;
                    nes_frames <= frame_count;
                    odd := not odd;
                end if;
            else
                cycle := cycle + 1;
            end if;

            if RELOAD_FRAME > 0 and frame_count = RELOAD_FRAME and not reloaded
            then
                reloaded := true;
                report "Reloading";
                wait_and_start;
            end if;
        end loop;
    end process;

    -- Checks the output's pixels against the pattern
    check : process
        variable out_frames : natural := 0;
        variable row : natural;
        variable col : natural;
        variable prev_lval : boolean := false;
        variable prev_fval : boolean := false;
        variable tag : emphasis_bits_t;
        variable checking : boolean := false;
        variable frame_errors : natural;
        variable errors : natural := 0;
        variable checked_frames : natural := 0;
        variable expected : color_idx_t;
        variable period : real;
    begin
        report "Output totals " & integer'image(RATES.line_pixels) & "x" &
               integer'image(RATES.frame_lines) & ", start rate " &
               integer'image(RATES.start_rate);
        loop
            wait until rising_edge(clk_pix);

            if video.fval and not prev_fval
            then
                row := 0;
                frame_errors := 0;
                -- Only frames the NES has drawn whole are checked
                checking := nes_running and nes_frames >= 1;
            end if;

            if video.lval
            then
                if not prev_lval
                then
                    col := 0;
                    if row = 0
                    then
                        tag := video.color(8 downto 6);
                    end if;
                end if;

                expected := tag & pattern(col / 2, row / 2);
                if checking and video.color /= expected
                then
                    if frame_errors < 4
                    then
                        report "Output frame " & integer'image(out_frames) &
                               " row " & integer'image(row) &
                               " col " & integer'image(col) &
                               ": got " & to_hstring(video.color) &
                               " expected " & to_hstring(expected)
                            severity error;
                    end if;
                    frame_errors := frame_errors + 1;
                    errors := errors + 1;
                end if;
                col := col + 1;
            elsif prev_lval
            then
                row := row + 1;
            end if;

            if prev_fval and not video.fval
            then
                out_frames := out_frames + 1;
                if checking
                then
                    checked_frames := checked_frames + 1;
                end if;

                if out_frames = FRAMES
                then
                    report "Checked " & integer'image(checked_frames) &
                           " of " & integer'image(out_frames) &
                           " frames, " & integer'image(errors) &
                           " pixel errors";
                    if nes_timed_frames > 0
                    then
                        period := real(nes_timed_time / 1 ps) /
                                  real(nes_timed_frames);
                        report "NES frames " &
                               real'image(1.0e12 / period) & " Hz, " &
                               real'image((1.0e12 / period / NES_FRAME_FREQ -
                                           1.0) * 1.0e6) &
                               " ppm from NTSC";
                    end if;
                    if errors = 0 and checked_frames > 0
                    then
                        report "PASS";
                    else
                        report "FAIL" severity error;
                    end if;
                    done <= true;
                    finish;
                end if;
            end if;

            prev_lval := video.lval;
            prev_fval := video.fval;
        end loop;
    end process;

    -- Times the NES's frames, in pairs, since odd frames are a dot short
    -- with rendering on
    nes_rate : process
        variable first : time;
    begin
        wait on nes_frames;
        if nes_frames = 10
        then
            first := now;
            nes_timed_frames <= 0;
        elsif nes_frames > 10 and nes_frames mod 2 = 0
        then
            nes_timed_frames <= nes_frames - 10;
            nes_timed_time <= now - first;
        end if;
    end process;

    -- Logs the loop once a frame
    log : process
    begin
        wait on phase_error, stretch_rate;
        wait until rising_edge(clk_sys);
        report "NES frame " & integer'image(nes_frames) &
               " phase error " & integer'image(phase_error) &
               " rate " & integer'image(stretch_rate) &
               " locked " & boolean'image(locked);
    end process;

end behavioral;
