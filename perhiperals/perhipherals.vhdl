library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

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

    component syncram_sp is
    generic
    (
        ADDR_BITS : positive;
        DATA_BITS : positive := 8
    );
    port
    (
        clk              : in std_logic;
        clk_en           : in boolean;

        address : in std_logic_vector(ADDR_BITS-1 downto 0);
        read    : in boolean;
        write   : in boolean;

        data_in : in std_logic_vector(DATA_BITS-1 downto 0);
        data_out : out std_logic_vector(DATA_BITS-1 downto 0)
    );
    end component syncram_sp;

end perhipherals;

package body perhipherals is

end package body;