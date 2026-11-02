library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.platform_video.all;
-- The PPU's frame timing, in the numbering ppu_position_t uses
use work.lib_ppu.DOTS_PER_LINE;
use work.lib_ppu.LINES_PER_FRAME;
use work.lib_ppu.LAST_LINE;
use work.lib_ppu.LAST_CYCLE;
use work.lib_ppu.FRAME_START;

-- Shows the PPU's picture, doubled to 512x480, on an output whose frames are
-- locked to the NES's, so that each NES line is shown about a line after the
-- PPU draws it, a constant ~64 us, close to a CRT on original hardware. A
-- frame buffer would add 0 to 2 frames, drifting with the rate mismatch.
--
-- The output timing runs free on clk_pix and is the master. The NES follows
-- it: once a frame, the time from a reference point of the output frame to
-- the start of the NES's picture is measured, and a PI loop sets how often a
-- CPU cycle is stretched by a clock. The NES's clk_en must run slightly
-- fast, so that the stretches slow it down to the output's rate.
--
-- After reset the NES waits to run until the output reaches the point in its
-- frame that matches where the PPU starts, so the NES starts locked.
--
-- Only LINES = 2**LINE_BITS NES lines are buffered. The output reads each
-- line once it is complete, 2 output lines per NES line. 525 output lines
-- are 262.5 line pairs, so the pairs are 0.65 dots shorter than an NES line
-- and the output gains 155 dots on the NES down the picture, which the
-- timing's lead_pix allows for.
entity frame_lock_video is
generic
(
    FORMAT          : video_format_t := FORMAT_640X480;
    VENDOR          : vendor_t := VENDOR_ALTERA;
    LINE_BITS       : positive := 2;
    -- The stretch rate the loop starts from, and the most it can reach, in
    -- units of 2**-15 stretches per CPU cycle. A unit is ~0.91 stretches a
    -- frame, about 1.1 ppm of the NES's rate at 50 MHz. START_RATE should be
    -- the rate that the board's clocks need, so that the NES starts locked.
    -- get_frame_lock_rates gives both
    START_RATE      : natural := 0;
    MAX_RATE        : positive := 2400;
    -- The loop's gains, in rate units per clock of phase error, are
    -- 2**-KP_SHIFT and 2**-KI_SHIFT. The defaults settle in ~10 frames,
    -- and a 200 ppm error in START_RATE peaks at ~200 clocks of phase
    KP_SHIFT        : natural := 1;
    KI_SHIFT        : natural := 3;
    -- PPU dots that the NES lags its start position by, from the clock that
    -- run is set on to the PPU starting
    START_LEAD_DOTS : natural := 4;
    -- Simulation only: report the phase error and stretch rate each frame
    LOG             : boolean := false
);
port
(
    clk_sys   : in std_logic;
    reset_sys : in boolean;
    clk_pix   : in std_logic;
    reset_pix : in boolean;

    -- From the NES, on clk_sys. pixel_bus is sampled on ppu_clk_en
    cpu_clk_en : in boolean;
    ppu_clk_en : in boolean;
    pixel_bus  : in pixel_bus_t;

    nes_running    : in boolean;
    waiting_to_run : in boolean;
    ppu_start      : in ppu_position_t;

    -- To the NES
    stretch : out boolean;
    run     : out boolean;

    -- On clk_pix
    video : out video_out_t;

    -- On clk_sys, for debugging. phase_error is in clocks, positive when
    -- the NES is late, and updates once a frame
    phase_error  : out integer;
    stretch_rate : out natural;
    locked       : out boolean
);
end frame_lock_video;

architecture behavioral of frame_lock_video is

    constant T : video_timing_t := get_timing(FORMAT);

    constant NES_WIDTH  : positive := 256;
    constant NES_HEIGHT : positive := 240;

    constant LINES : positive := 2**LINE_BITS;

    constant ADDR_BITS : positive := LINE_BITS + 8;
    subtype buf_addr_t is natural range 0 to 2**ADDR_BITS-1;
    subtype buf_line_t is natural range 0 to LINES-1;
    subtype nes_x_t    is natural range 0 to NES_WIDTH-1;

    -- Output timing {
    constant H_TOTAL : positive := T.h_sync + T.h_back + T.h_active + T.h_front;
    constant V_TOTAL : positive := T.v_sync + T.v_back + T.v_active + T.v_front;

    constant H_ACTIVE_START : natural := T.h_sync + T.h_back;
    constant V_ACTIVE_START : natural := T.v_sync + T.v_back;

    -- The picture is centred in the active area
    constant H_WIN_START : natural :=
        H_ACTIVE_START + (T.h_active - 2 * NES_WIDTH) / 2;
    constant V_WIN_START : natural :=
        V_ACTIVE_START + (T.v_active - 2 * NES_HEIGHT) / 2;

    subtype col_t is natural range 0 to H_TOTAL-1;
    subtype row_t is natural range 0 to V_TOTAL-1;

    -- Where in the output frame the NES's picture should start
    constant REF_POS : natural :=
        (V_WIN_START * H_TOTAL + H_WIN_START - T.lead_pix) mod
        (H_TOTAL * V_TOTAL);
    constant REF_ROW : row_t := REF_POS / H_TOTAL;
    constant REF_COL : col_t := REF_POS mod H_TOTAL;

    function sync_level(active : boolean; low : boolean) return std_logic
    is
    begin
        if active = low
        then
            return '0';
        else
            return '1';
        end if;
    end;

    type pix_ctl_t is record
        h_sync : std_logic;
        v_sync : std_logic;
        de     : boolean;
        lval   : boolean;
        fval   : boolean;
    end record;

    constant PIX_CTL_RESET : pix_ctl_t :=
    (
        h_sync => sync_level(false, T.h_sync_low),
        v_sync => sync_level(false, T.v_sync_low),
        de => false,
        lval => false,
        fval => false
    );

    function get_pix_ctl(row : row_t; col : col_t) return pix_ctl_t
    is
        variable ret : pix_ctl_t;
    begin
        ret.h_sync := sync_level(col < T.h_sync, T.h_sync_low);
        ret.v_sync := sync_level(row < T.v_sync, T.v_sync_low);
        ret.de := col >= H_ACTIVE_START and
                  col < H_ACTIVE_START + T.h_active and
                  row >= V_ACTIVE_START and
                  row < V_ACTIVE_START + T.v_active;
        ret.fval := row >= V_WIN_START and
                    row < V_WIN_START + 2 * NES_HEIGHT;
        ret.lval := ret.fval and
                    col >= H_WIN_START and
                    col < H_WIN_START + 2 * NES_WIDTH;

        return ret;
    end;

    -- The buffer address that output pixel (row, col) shows, when it is in
    -- the picture
    function get_read_addr(row : row_t; col : col_t) return buf_addr_t
    is
        variable line : buf_line_t;
        variable x : nes_x_t;
    begin
        if row >= V_WIN_START and col >= H_WIN_START and
           col < H_WIN_START + 2 * NES_WIDTH
        then
            line := ((row - V_WIN_START) / 2) mod LINES;
            x := (col - H_WIN_START) / 2;
        else
            line := 0;
            x := 0;
        end if;

        return line * NES_WIDTH + x;
    end;

    -- Pipeline: the buffer address is presented from row and col, the
    -- buffer's data follows a clock later, the colour index is registered
    -- from it and the colour is looked up from that a clock after
    type pix_reg_t is record
        row        : row_t;
        col        : col_t;
        ctl_1      : pix_ctl_t;
        ctl_2      : pix_ctl_t;
        ctl_3      : pix_ctl_t;
        color_2    : color_idx_t;
        color_3    : color_idx_t;
        ref_toggle : std_logic;
    end record;

    constant PIX_REG_RESET : pix_reg_t :=
    (
        row => 0,
        col => 0,
        ctl_1 => PIX_CTL_RESET,
        ctl_2 => PIX_CTL_RESET,
        ctl_3 => PIX_CTL_RESET,
        color_2 => COLOR_IDX_BLACK,
        color_3 => COLOR_IDX_BLACK,
        ref_toggle => '0'
    );

    function cycle_pix(reg : pix_reg_t; buf_data : color_idx_t)
        return pix_reg_t
    is
        variable ret : pix_reg_t;
    begin
        ret := reg;

        ret.ctl_1 := get_pix_ctl(reg.row, reg.col);
        ret.ctl_2 := reg.ctl_1;
        ret.ctl_3 := reg.ctl_2;

        if reg.ctl_1.lval
        then
            ret.color_2 := buf_data;
        else
            ret.color_2 := COLOR_IDX_BLACK;
        end if;
        ret.color_3 := reg.color_2;

        if reg.row = REF_ROW and reg.col = REF_COL
        then
            ret.ref_toggle := not reg.ref_toggle;
        end if;

        if reg.col = col_t'high
        then
            ret.col := 0;
            if reg.row = row_t'high
            then
                ret.row := 0;
            else
                ret.row := reg.row + 1;
            end if;
        else
            ret.col := reg.col + 1;
        end if;

        return ret;
    end;
    -- }

    -- Lock {
    -- A line and cycle of the PPU's frame, as ppu_position_t has them.
    -- FRAME_START is the line of the first pixel
    subtype frame_line_t  is natural range 0 to LAST_LINE;
    subtype frame_cycle_t is natural range 0 to LAST_CYCLE;

    -- Where the PPU is at the output's reference point when locked
    constant REF_DOT   : natural :=
        (FRAME_START * DOTS_PER_LINE + START_LEAD_DOTS) mod
        (LINES_PER_FRAME * DOTS_PER_LINE);
    constant REF_LINE  : frame_line_t := REF_DOT / DOTS_PER_LINE;
    constant REF_CYCLE : frame_cycle_t := REF_DOT mod DOTS_PER_LINE;

    -- A frame is ~832,000 clocks at 50 MHz
    subtype count_t is natural range 0 to 2**21-1;
    subtype error_t is integer range -2**21 to 2**21;

    -- Errors are clamped before the gains, which bounds the widths. The
    -- proportional term of the largest is still past MAX_RATE
    constant ERROR_CLAMP : positive := 2**14 - 1;
    subtype clamped_error_t is integer range -ERROR_CLAMP to ERROR_CLAMP;

    -- The start of the NES's picture is only measured after this many dots
    -- of VBlank, so that the PPU starting inside the picture is not taken
    -- for its start. VBlank is 21 lines
    constant MIN_BLANK_DOTS : positive := 4095;
    subtype blank_dots_t is natural range 0 to MIN_BLANK_DOTS;

    -- Locked while the error is within ~5 us
    constant LOCK_TOLERANCE : positive := 256;

    constant RATE_ONE : positive := 2**FRAME_LOCK_RATE_BITS;

    subtype rate_t  is natural range 0 to MAX_RATE;
    subtype integ_t is natural range 0 to MAX_RATE * 2**KI_SHIFT;
    subtype acc_t   is natural range 0 to RATE_ONE-1;

    type lock_in_t is record
        cpu_clk_en     : boolean;
        ppu_clk_en     : boolean;
        pixel_bus      : pixel_bus_t;
        nes_running    : boolean;
        waiting_to_run : boolean;
        ppu_start      : ppu_position_t;
        ref_toggle     : std_logic;
    end record;

    type lock_reg_t is record
        -- ref_toggle synchronized to clk_sys
        ref_sync         : std_logic_vector(2 downto 0);
        -- Clocks since the reference point, and between the last two
        since_ref        : count_t;
        frame_len        : count_t;
        -- Reference points seen, up to the 2 that make frame_len valid
        refs             : natural range 0 to 2;

        prev_line_valid  : boolean;
        -- Dots the NES has run outside its picture, up to MIN_BLANK_DOTS
        blank_dots       : blank_dots_t;

        -- Writes to the buffer
        write_x          : nes_x_t;
        write_line       : buf_line_t;
        write            : boolean;
        write_addr       : buf_addr_t;
        write_data       : color_idx_t;

        -- The loop
        error            : error_t;
        integ            : integ_t;
        rate             : rate_t;
        acc              : acc_t;
        stretch          : boolean;
        locked           : boolean;
        clamped_error    : clamped_error_t;
        -- The step of the update from a new error, 0 when none is running
        update_step      : natural range 0 to 3;

        -- Where the PPU would be if it were running locked, from the
        -- reference point, to start it from
        v_line           : frame_line_t;
        v_cycle          : frame_cycle_t;
        v_valid          : boolean;
        go               : boolean;
    end record;

    constant LOCK_REG_RESET : lock_reg_t :=
    (
        ref_sync => (others => '0'),
        since_ref => 0,
        frame_len => 0,
        refs => 0,

        prev_line_valid => false,
        blank_dots => 0,

        write_x => 0,
        write_line => 0,
        write => false,
        write_addr => 0,
        write_data => COLOR_IDX_BLACK,

        error => 0,
        integ => START_RATE * 2**KI_SHIFT,
        rate => START_RATE,
        acc => 0,
        stretch => false,
        locked => false,
        clamped_error => 0,
        update_step => 0,

        v_line => 0,
        v_cycle => 0,
        v_valid => false,
        go => false
    );

    function clamp(val : integer; lo : integer; hi : integer) return integer
    is
    begin
        if val < lo
        then
            return lo;
        elsif val > hi
        then
            return hi;
        else
            return val;
        end if;
    end;

    -- val / 2**shift, rounded toward zero. Shifting the magnitude avoids
    -- the divider that synthesis builds for a signed division
    function signed_shift_right(val : integer; shift : natural) return integer
    is
    begin
        if val < 0
        then
            return -shift_right(-val, shift);
        else
            return shift_right(val, shift);
        end if;
    end;

    -- The time from the reference point to the start of the NES's picture,
    -- taken as the nearer of the reference points before and after it
    function get_error(since_ref : count_t; frame_len : count_t)
        return error_t
    is
    begin
        if since_ref * 2 <= frame_len
        then
            return since_ref;
        else
            return since_ref - frame_len;
        end if;
    end;

    function cycle_lock(reg : lock_reg_t; lock_in : lock_in_t)
        return lock_reg_t
    is
        alias pixels : pixel_bus_t is lock_in.pixel_bus;
        variable ret : lock_reg_t;
        variable ref_event : boolean;
        variable sum : natural range 0 to 2 * RATE_ONE;
    begin
        ret := reg;
        ret.write := false;

        ref_event := reg.ref_sync(2) /= reg.ref_sync(1);
        ret.ref_sync := reg.ref_sync(1 downto 0) & lock_in.ref_toggle;

        -- Updates the loop from a new error over 3 clocks, which keeps
        -- the arithmetic off the critical path
        case reg.update_step is
            when 1 =>
                ret.clamped_error := clamp(reg.error,
                                           -ERROR_CLAMP,
                                           ERROR_CLAMP);
                ret.update_step := 2;
            when 2 =>
                ret.integ := clamp(reg.integ - reg.clamped_error,
                                   0,
                                   integ_t'high);
                ret.update_step := 3;
            when 3 =>
                ret.rate := clamp(shift_right(reg.integ, KI_SHIFT) -
                                  signed_shift_right(reg.clamped_error,
                                                     KP_SHIFT),
                                  0,
                                  MAX_RATE);
                ret.update_step := 0;
            when others =>
                null;
        end case;

        -- Applies the stretch rate. A stretch is held until the next
        -- cpu_clk_en, which clk_en samples it before
        if lock_in.cpu_clk_en
        then
            sum := reg.acc + reg.rate;
            ret.stretch := sum >= RATE_ONE;
            if ret.stretch
            then
                ret.acc := sum - RATE_ONE;
            else
                ret.acc := sum;
            end if;
        end if;

        if lock_in.ppu_clk_en
        then
            -- Measures the phase at the start of the NES's picture
            if pixels.frame_valid and reg.blank_dots = MIN_BLANK_DOTS and
               reg.refs = 2 and lock_in.nes_running
            then
                ret.error := get_error(reg.since_ref, reg.frame_len);
                ret.locked := abs(ret.error) < LOCK_TOLERANCE;
                ret.update_step := 1;
            end if;

            -- Writes the picture's lines to the buffer
            if pixels.line_valid
            then
                ret.write := true;
                ret.write_addr := reg.write_line * NES_WIDTH + reg.write_x;
                ret.write_data := to_emphasis_bits(pixels.emphasis) &
                                  pixels.pixel;
                ret.write_x := wrap(reg.write_x + 1, nes_x_t'high);
            elsif reg.prev_line_valid
            then
                ret.write_x := 0;
                ret.write_line := wrap(reg.write_line + 1, buf_line_t'high);
            end if;

            if not pixels.frame_valid
            then
                ret.write_x := 0;
                ret.write_line := 0;
            end if;

            if pixels.frame_valid
            then
                ret.blank_dots := 0;
            elsif reg.blank_dots < MIN_BLANK_DOTS
            then
                ret.blank_dots := reg.blank_dots + 1;
            end if;

            ret.prev_line_valid := pixels.line_valid;

            -- Starts the NES when the PPU would be where it starts from
            if lock_in.waiting_to_run and reg.v_valid and
               reg.v_line = lock_in.ppu_start.scanline and
               reg.v_cycle = lock_in.ppu_start.cycle
            then
                ret.go := true;
            end if;

            if reg.v_cycle = frame_cycle_t'high
            then
                ret.v_cycle := 0;
                if reg.v_line = frame_line_t'high
                then
                    ret.v_line := 0;
                else
                    ret.v_line := reg.v_line + 1;
                end if;
            else
                ret.v_cycle := reg.v_cycle + 1;
            end if;
        end if;

        if not lock_in.nes_running
        then
            -- Holds the rate while the NES isn't running to measure
            ret.rate := shift_right(reg.integ, KI_SHIFT);
            ret.locked := false;
            ret.blank_dots := 0;
        end if;

        if ref_event
        then
            ret.since_ref := 0;
            ret.frame_len := reg.since_ref;
            if reg.refs < 2
            then
                ret.refs := reg.refs + 1;
            end if;

            ret.v_line := REF_LINE;
            ret.v_cycle := REF_CYCLE;
            ret.v_valid := true;
        elsif reg.since_ref < count_t'high
        then
            ret.since_ref := reg.since_ref + 1;
        end if;

        -- The position is only kept while the PPU's clock runs, which it
        -- does from the RAM fill on
        if not (lock_in.waiting_to_run or lock_in.nes_running)
        then
            ret.v_valid := false;
        end if;

        if not lock_in.waiting_to_run
        then
            ret.go := false;
        end if;

        return ret;
    end;
    -- }

    signal pix_reg  : pix_reg_t := PIX_REG_RESET;
    signal lock_reg : lock_reg_t := LOCK_REG_RESET;

    signal read_addr : std_logic_vector(ADDR_BITS-1 downto 0);
    signal buf_data  : color_idx_t;

    signal rgb : rgb_t := (others => '0');

begin

    stretch <= lock_reg.stretch;
    run <= lock_reg.go;

    phase_error <= lock_reg.error;
    stretch_rate <= lock_reg.rate;
    locked <= lock_reg.locked;

    line_buf : entity work.syncram_sdp(behavioral)
    generic map
    (
        VENDOR => VENDOR,
        ADDR_BITS => ADDR_BITS,
        DATA_BITS => color_idx_t'length
    )
    port map
    (
        write_clk => clk_sys,
        write => lock_reg.write,
        write_address => to_std_logic_vector(lock_reg.write_addr, ADDR_BITS),
        data_in => lock_reg.write_data,

        read_clk => clk_pix,
        read_address => read_addr,
        data_out => buf_data
    );

    read_addr <= to_std_logic_vector(get_read_addr(pix_reg.row, pix_reg.col),
                                     ADDR_BITS);

    process(clk_sys)
        variable lock_in : lock_in_t;
    begin
    if rising_edge(clk_sys)
    then
        lock_in.cpu_clk_en := cpu_clk_en;
        lock_in.ppu_clk_en := ppu_clk_en;
        lock_in.pixel_bus := pixel_bus;
        lock_in.nes_running := nes_running;
        lock_in.waiting_to_run := waiting_to_run;
        lock_in.ppu_start := ppu_start;
        lock_in.ref_toggle := pix_reg.ref_toggle;

        if reset_sys
        then
            lock_reg <= LOCK_REG_RESET;
        else
            lock_reg <= cycle_lock(lock_reg, lock_in);
        end if;
    end if;
    end process;

    process(clk_pix)
    begin
    if rising_edge(clk_pix)
    then
        if reset_pix
        then
            pix_reg <= PIX_REG_RESET;
        else
            pix_reg <= cycle_pix(pix_reg, buf_data);
        end if;
    end if;
    end process;

    -- The colour lookup has a process of its own so that it is inferred as
    -- a ROM
    process(clk_pix)
    begin
    if rising_edge(clk_pix)
    then
        rgb <= COLOR_ROM(to_integer(unsigned(pix_reg.color_2)));
    end if;
    end process;

    video.red <= rgb(23 downto 16);
    video.green <= rgb(15 downto 8);
    video.blue <= rgb(7 downto 0);
    video.h_sync <= pix_reg.ctl_3.h_sync;
    video.v_sync <= pix_reg.ctl_3.v_sync;
    video.de <= pix_reg.ctl_3.de;
    video.lval <= pix_reg.ctl_3.lval;
    video.fval <= pix_reg.ctl_3.fval;
    video.color <= pix_reg.color_3;

    gen_log : if LOG generate
    begin
        process
        begin
            wait on lock_reg.error, lock_reg.rate;
            report "frame_lock_video: phase error " &
                   integer'image(lock_reg.error) & " rate " &
                   integer'image(lock_reg.rate);
        end process;
    end generate;

end behavioral;
