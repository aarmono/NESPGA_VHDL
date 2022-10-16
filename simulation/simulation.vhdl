library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.apu_bus_types.all;
use work.nes_core.all;
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

end simulation;

package body simulation is

end package body;