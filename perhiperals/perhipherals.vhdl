library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.nes_core.all;
use work.nes_audio_mixer.all;

package perhipherals is

    subtype wm_audio_t is std_logic_vector(15 downto 0);

    component wm8731 is
    port
    (
        clk      : in std_logic;
        reset    : in boolean;
        
        audio    : in wm_audio_t;
        
        sclk     : out std_logic;
        sdat     : out std_logic;
        bclk     : out std_logic;
        dac_dat  : out std_logic;
        dac_lrck : out std_logic
    );
    end component wm8731;

end perhipherals;

package body perhipherals is

end package body;