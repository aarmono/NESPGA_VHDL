library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.apu_bus_types.all;
use work.file_bus_types.all;
use work.nes_types.all;
use work.nes_audio_mixer.all;

package simulation is

    component apu_bus_record is
    generic
    (
        FILEPATH : string
    );
    port
    (
        apu_bus     : in apu_bus_t;
        apu_data_in : in data_t
    );
    end component apu_bus_record;
    
    component apu_bus_playback is
    generic
    (
        FILEPATH : string
    );
    port
    (
        apu_bus      : out apu_bus_t;
        apu_data_out : out data_t;
        done         : out boolean
    );
    end component apu_bus_playback;
    
    component apu_audio_record is
    generic
    (
        FILEPATH : string
    );
    port
    (
        clk    : in std_logic;
        clk_en : in boolean;
        audio  : in mixed_audio_t;
        ready  : in boolean;
        done   : in boolean
    );
    end component apu_audio_record;

    component ppu_video_record is
    generic
    (
        FILE_PREFIX : string
    );
    port
    (
        clk       : in std_logic;
        clk_en    : in boolean;
        pixel_bus : in pixel_bus_t;
        ready     : in boolean;
        done      : in boolean
    );
    end component ppu_video_record;

    component fm2_joystick is
    generic
    (
        FILEPATH     : string;
        INPUT_OFFSET : integer := 0
    );
    port
    (
        frame_valid : in boolean;

        joy_strobe : in std_logic;

        shift_joy_1 : in std_logic;
        joy_1_val   : out std_logic;

        shift_joy_2 : in std_logic;
        joy_2_val   : out std_logic
    );
    end component fm2_joystick;
    
    component file_memory is
    generic
    (
        FILEPATH  : string;
        MEM_BYTES : integer := 131072
    );
    port
    (
        file_bus_1       : in file_bus_t;
        data_to_file_1   : in data_t := (others => '-');
        data_from_file_1 : out data_t;
        
        file_bus_2       : in file_bus_t := FILE_BUS_IDLE;
        data_to_file_2   : in data_t := (others => '-');
        data_from_file_2 : out data_t
    );
    end component file_memory;
    
    component clock is
    generic
    (
        PERIOD : time
    );
    port
    (
        done  : in boolean;
        clk   : out std_logic;
        reset : out boolean
    );
    end component clock;

end simulation;

package body simulation is

end package body;