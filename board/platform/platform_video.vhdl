library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.perhipheral_types.all;
use IEEE.math_real.all;
use work.lib_ppu.DOTS_PER_LINE;
use work.lib_ppu.LINES_PER_FRAME;

-- Video output shared by the boards: output timings, the NES palette at 8
-- bits per channel, and frame_lock_video, which shows the PPU's picture on an
-- output whose frames are locked to the NES's
package platform_video is

    -- The output timings frame_lock_video can generate. Each line starts with
    -- its horizontal sync pulse, then the back porch, the active pixels and
    -- the front porch, and each frame starts the same way with lines
    type video_format_t is
    (
        -- CEA-861 VIC 1, 640x480 with 800x525 totals, at a pixel clock about
        -- 0.26% fast (~25.24 MHz) so that frames come at the NES's 60.0988 Hz
        FORMAT_640X480
    );

    type video_timing_t is record
        h_sync   : positive;
        h_back   : natural;
        h_active : positive;
        h_front  : natural;

        v_sync   : positive;
        v_back   : natural;
        v_active : positive;
        v_front  : natural;

        -- Sync pulses are low
        h_sync_low : boolean;
        v_sync_low : boolean;

        -- Output pixel clocks from the start of NES visible line 0 to the
        -- start of the picture, the first pixel of the first output line
        -- of NES line 0. The output reads only NES lines that are complete,
        -- so this is the latency of the top left pixel. It must leave room
        -- for the output gaining on the NES down the picture, and for the
        -- loop's phase error (see get_timing)
        lead_pix : positive;
    end record;

    function get_timing(format : video_format_t) return video_timing_t;

    -- frame_lock_video's stretch rate is in units of 2**-FRAME_LOCK_RATE_BITS
    -- stretches per CPU cycle
    constant FRAME_LOCK_RATE_BITS : positive := 15;

    -- The least that the NES's base rate is faster than the frame lock
    -- needs, for the oscillators' tolerances. The DE1's are +-50 ppm
    constant FRAME_LOCK_MARGIN_PPM : positive := 200;

    -- The rates that a board runs the NES at with the frame lock, for clk_en
    -- and frame_lock_video
    type frame_lock_rates_t is record
        -- The NES's base rate, CPU_FREQ_NUM / CPU_FREQ_DEN Hz
        cpu_freq_num : positive;
        cpu_freq_den : positive;
        -- The stretch rate that slows the base rate to the output's, for
        -- START_RATE
        start_rate   : natural;
        -- For MAX_RATE, twice start_rate, so that the loop can slow the NES
        -- as far past the output's rate as it can speed it up, to the base
        -- rate
        max_rate     : positive;
    end record;

    -- The frame lock's rates for an output of format on a pixel clock of
    -- pix_freq Hz, with clk_sys at sys_freq Hz. The base rate is the
    -- fastest whose CPU cycles are a whole number of tenths of a clock,
    -- which keeps clk_en's fraction small, and at least
    -- FRAME_LOCK_MARGIN_PPM faster than the locked rate. The locked rate is
    -- for rendering off, as the NES starts. Rendering on makes odd frames a
    -- dot shorter, 5.6 ppm, which the loop makes up
    function get_frame_lock_rates(format   : video_format_t;
                                  sys_freq : positive;
                                  pix_freq : real)
        return frame_lock_rates_t;

    -- A colour at 8 bits per channel, red in the top byte
    subtype rgb_t is std_logic_vector(23 downto 0);

    -- A pixel as the PPU outputs it: its emphasis bits above its palette
    -- index, the same layout as Mesen's 512 colour palette
    subtype color_idx_t is std_logic_vector(8 downto 0);

    -- The index of a black pixel, shown outside the picture
    constant COLOR_IDX_BLACK : color_idx_t := "000001111";

    type video_out_t is record
        red      : std_logic_vector(7 downto 0);
        green    : std_logic_vector(7 downto 0);
        blue     : std_logic_vector(7 downto 0);
        h_sync   : std_logic;
        v_sync   : std_logic;
        -- The active area of the output timing
        de       : boolean;
        -- The NES picture within the active area, and the lines it is on
        lval     : boolean;
        fval     : boolean;
        -- The pixel that red, green and blue show, COLOR_IDX_BLACK outside
        -- the picture
        color    : color_idx_t;
    end record;

    constant VIDEO_OUT_RESET : video_out_t :=
    (
        red => (others => '0'),
        green => (others => '0'),
        blue => (others => '0'),
        h_sync => '1',
        v_sync => '1',
        de => false,
        lval => false,
        fval => false,
        color => COLOR_IDX_BLACK
    );

    type color_rom_t is array(0 to 2**color_idx_t'length-1) of rgb_t;

    -- The 2C02 palette from the Mesen emulator, with Mesen's emphasis. Each
    -- emphasis bit darkens the other two colour channels by a factor of
    -- 0.84, compounding, and columns $xE and $xF are not affected
    function make_color_rom return color_rom_t;

    constant COLOR_ROM : color_rom_t;

    component frame_lock_video is
    generic
    (
        FORMAT          : video_format_t := FORMAT_640X480;
        VENDOR          : vendor_t := VENDOR_ALTERA;
        LINE_BITS       : positive := 2;
        START_RATE      : natural := 0;
        MAX_RATE        : positive := 2400;
        KP_SHIFT        : natural := 1;
        KI_SHIFT        : natural := 3;
        START_LEAD_DOTS : natural := 4;
        LOG             : boolean := false
    );
    port
    (
        clk_sys   : in std_logic;
        reset_sys : in boolean;
        clk_pix   : in std_logic;
        reset_pix : in boolean;

        cpu_clk_en : in boolean;
        ppu_clk_en : in boolean;
        pixel_bus  : in pixel_bus_t;

        nes_running    : in boolean;
        waiting_to_run : in boolean;
        ppu_start      : in ppu_position_t;

        stretch : out boolean;
        run     : out boolean;

        video : out video_out_t;

        phase_error  : out integer;
        stretch_rate : out natural;
        locked       : out boolean
    );
    end component frame_lock_video;

end platform_video;

package body platform_video is

    function get_timing(format : video_format_t) return video_timing_t
    is
    begin
        case format is
            when FORMAT_640X480 =>
                -- 450 NES dots, ~83.8 us, at 4.701 pixel clocks per dot. The
                -- output's line pairs are 0.65 dots shorter than an NES
                -- line, so by the last line the lead is 155 dots shorter,
                -- and that line's first output line starts ~36 dots after
                -- its last pixel is written. The output reads a line 2.35
                -- times as fast as the PPU writes it, so the nearest a
                -- pixel is read to being written is the last pixel of the
                -- last line, ~145 dots (27 us). With 4 lines buffered, a
                -- line is overwritten ~630 dots after it is last read
                return
                (
                    h_sync => 96,
                    h_back => 48,
                    h_active => 640,
                    h_front => 16,
                    v_sync => 2,
                    v_back => 33,
                    v_active => 480,
                    v_front => 10,
                    h_sync_low => true,
                    v_sync_low => true,
                    lead_pix => 2116
                );
        end case;
    end;

    function get_frame_lock_rates(format   : video_format_t;
                                  sys_freq : positive;
                                  pix_freq : real)
        return frame_lock_rates_t
    is
        constant T : video_timing_t := get_timing(format);
        constant FRAME_PIX : positive :=
            (T.h_sync + T.h_back + T.h_active + T.h_front) *
            (T.v_sync + T.v_back + T.v_active + T.v_front);
        constant FRAME_CPU_CYCLES : real :=
            real(DOTS_PER_LINE * LINES_PER_FRAME) / 3.0;
        -- clk_sys clocks per CPU cycle that keep the NES's frames at the
        -- output's rate
        constant LOCKED_DIV : real :=
            real(sys_freq) * real(FRAME_PIX) / (pix_freq * FRAME_CPU_CYCLES);
        -- clk_sys clocks per CPU cycle at the base rate, in tenths
        constant BASE_DIV_10 : positive :=
            integer(floor(LOCKED_DIV * 10.0 *
                          (1.0 - real(FRAME_LOCK_MARGIN_PPM) * 1.0e-6)));
        constant START_RATE : natural :=
            integer(round((LOCKED_DIV - real(BASE_DIV_10) / 10.0) *
                          real(2**FRAME_LOCK_RATE_BITS)));
    begin
        return
        (
            cpu_freq_num => sys_freq * 10,
            cpu_freq_den => BASE_DIV_10,
            start_rate => START_RATE,
            max_rate => 2 * START_RATE
        );
    end;

    type palette_t is array(0 to 63) of rgb_t;

    -- 2C02 values from the Mesen emulator
    constant PALETTE : palette_t :=
    (
        x"666666", x"002A88", x"1412A7", x"3B00A4",
        x"5C007E", x"6E0040", x"6C0600", x"561D00",
        x"333500", x"0B4800", x"005200", x"004F08",
        x"00404D", x"000000", x"000000", x"000000",
        x"ADADAD", x"155FD9", x"4240FF", x"7527FE",
        x"A01ACC", x"B71E7B", x"B53120", x"994E00",
        x"6B6D00", x"388700", x"0C9300", x"008F32",
        x"007C8D", x"000000", x"000000", x"000000",
        x"FFFEFF", x"64B0FF", x"9290FF", x"C676FF",
        x"F36AFF", x"FE6ECC", x"FE8170", x"EA9E22",
        x"BCBE00", x"88D800", x"5CE430", x"45E082",
        x"48CDDE", x"4F4F4F", x"000000", x"000000",
        x"FFFEFF", x"C0DFFF", x"D3D2FF", x"E8C8FF",
        x"FBC2FF", x"FEC4EA", x"FECCC5", x"F7D8A5",
        x"E4E594", x"CFEF96", x"BDF4AB", x"B3F3CC",
        x"B5EBF2", x"B8B8B8", x"000000", x"000000"
    );

    type channel_lsb_t is array(color_channel_t) of natural;
    -- Bit position of each colour channel in an rgb_t
    constant RGB_CHANNEL_LSB : channel_lsb_t :=
    (
        RED => 16,
        GREEN => 8,
        BLUE => 0
    );

    function make_color_rom return color_rom_t
    is
        variable ret : color_rom_t;
        variable emphasis : emphasis_t;
        variable lsb : natural;
        variable channel_val : natural;
        variable dim_count : natural;
    begin
        for emphasis_bits in 0 to 2**emphasis_bits_t'length-1
        loop
            emphasis := to_emphasis_t(
                to_std_logic_vector(emphasis_bits, emphasis_bits_t'length));

            for pixel_idx in palette_t'range
            loop
                for channel in color_channel_t
                loop
                    lsb := RGB_CHANNEL_LSB(channel);
                    channel_val :=
                        to_integer(PALETTE(pixel_idx)(lsb+7 downto lsb));

                    dim_count := 0;
                    if pixel_idx mod 16 < 14
                    then
                        for other in color_channel_t
                        loop
                            if other /= channel and emphasis(other)
                            then
                                dim_count := dim_count + 1;
                            end if;
                        end loop;
                    end if;

                    -- Truncated, like Mesen
                    case dim_count is
                        when 0 =>
                            null;
                        when 1 =>
                            channel_val := (channel_val * 84) / 100;
                        when others =>
                            channel_val := (channel_val * 7056) / 10000;
                    end case;

                    ret(emphasis_bits * 64 + pixel_idx)(lsb+7 downto lsb) :=
                        to_std_logic_vector(channel_val, 8);
                end loop;
            end loop;
        end loop;

        return ret;
    end;

    constant COLOR_ROM : color_rom_t := make_color_rom;

end package body platform_video;
