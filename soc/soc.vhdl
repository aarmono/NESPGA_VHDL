library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.nes_core.all;
use work.nes_audio_mixer.all;

package soc is

    component nsf_soc is
    port
    (
        clk_cpu : in std_logic;
        clk_nsf : in std_logic;
        
        reset_out : out boolean;
        
        next_stb : in std_logic;
        prev_stb : in std_logic;
        
        nsf_bus     : out cpu_bus_t;
        nsf_data_in : in data_t;
        
        sram_bus      : out sram_bus_t;
        sram_data_out : out data_t;
        sram_data_in  : in data_t;
        
        ram_bus      : out ram_bus_t;
        ram_data_out : out data_t;
        ram_data_in  : in data_t;
        
        audio : out mixed_audio_t
    );
    end component nsf_soc;

end soc;

package body soc is

end package body;