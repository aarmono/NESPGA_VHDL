library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.chr_bus_types.all;
use work.cpu_bus_types.all;
use work.cart_mem_bus_types.all;
use work.cart_types.all;
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
    -- Run as a Famicom rather than a front loading NES. See nes_soc
    FAMICOM         : boolean := false;
    -- When set, write the CPU's external bus to this file, a line per CPU
    -- cycle once the NES is running: cycle, A0-A15, R/W (I when the bus is
    -- idle) and, for writes, D0-D7. See board/sim/trace/trace_diff.py
    TRACE_FILEPATH  : string := "";
    -- When set, write the visible pixels to this file from the first frame
    -- that starts once the NES is running, 2 bytes each: the colour, then
    -- the emphasis bits. See board/sim/trace/video_diff.py
    VIDEO_TRACE_FILEPATH : string := ""
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

        board_cpu_in => board_cpu_in
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