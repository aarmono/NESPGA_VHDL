library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.chr_bus_types.all;
use work.cpu_bus_types.all;
use work.file_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
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
    FM2_OFFSET      : integer := 2
);
end nes_bench;

architecture behavioral of nes_bench is

    signal file_bus_prg : file_bus_t;
    signal file_bus_chr : file_bus_t;
    
    signal data_from_file_prg : data_t;
    signal data_from_file_chr : data_t;
    
    signal audio_out : mixed_audio_t;
    signal pixel_bus : pixel_bus_t;

    signal joy_strobe : std_logic;

    signal shift_joy_1 : std_logic;
    signal joy_1_val   : std_logic;

    signal shift_joy_2 : std_logic;
    signal joy_2_val   : std_logic;

    signal ppu_clk_en : boolean;
    signal cpu_clk_en : boolean;
    
    signal reset : boolean;
    
    signal clk_50mhz : std_logic := '0';

    signal output_ready : boolean;
    
begin

    soc : nes_soc_ocram
    port map
    (
        clk_50mhz => clk_50mhz,
        reset => false,

        nes_running => output_ready,

        ppu_clk_en => ppu_clk_en,
        cpu_clk_en => cpu_clk_en,
        
        file_bus_prg => file_bus_prg,
        data_from_file_prg => data_from_file_prg,
        
        file_bus_chr => file_bus_chr,
        data_from_file_chr => data_from_file_chr,
        
        pixel_bus => pixel_bus,
        audio => audio_out,

        joy_strobe => joy_strobe,

        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,

        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );
    
    ppu_recorder : ppu_video_record
    generic map
    (
        FILE_PREFIX => BMP_FILE_PREFIX
    )
    port map
    (
        clk => clk_50mhz,
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
        clk => clk_50mhz,
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

        joy_strobe => joy_strobe,

        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,

        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );
    
    nes_file : file_memory
    generic map
    (
       FILEPATH => NES_FILEPATH,
       MEM_BYTES => NES_FILE_BYTES
    )
    port map
    (
       file_bus_1 => file_bus_prg,
       data_from_file_1 => data_from_file_prg,
       
       file_bus_2 => file_bus_chr,
       data_from_file_2 => data_from_file_chr
    );
    
    clk_50mhz_gen : clock
    generic map
    (
        PERIOD => 20 ns
    )
    port map
    (
        clk => clk_50mhz,
        done => false
    );

end behavioral;