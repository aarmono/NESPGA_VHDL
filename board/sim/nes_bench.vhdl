library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.chr_bus_types.all;
use work.cpu_bus_types.all;
use work.cart_mem_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.soc.all;
use work.simulation.all;

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
    POWER_UP_SEED   : natural := 0
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
        POWER_UP_SEED => POWER_UP_SEED
    )
    port map
    (
        clk => clk,
        reset => false,
        soft_reset => soft_reset,

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
        joy_2_data => joy_2_data
    );
    
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
        frame_valid => pixel_bus.frame_valid,

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