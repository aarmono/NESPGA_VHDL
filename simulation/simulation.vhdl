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
        audio : in mixed_audio_t;
        ready : in boolean;
        done  : in boolean
    );
    end component apu_audio_record;
    
    component file_memory is
    generic
    (
        FILEPATH  : string;
        MEM_BYTES : integer := 131072
    );
    port
    (
        file_bus_1       : in file_bus_t;
        data_from_file_1 : out data_t;
        
        file_bus_2       : in file_bus_t := FILE_BUS_IDLE;
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