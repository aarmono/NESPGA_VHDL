library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.perhipheral_types.all;

package perhipherals is

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
        MEM_TYPE  : memory_type_t := MEMORY_ALTERA;
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

    component ps2_keyboard is
    port
    (
        clk   : in std_logic;
        reset : in boolean := false;

        ps2_clk  : inout std_logic;
        ps2_data : inout std_logic;

        ascii_out     : out std_logic_vector(7 downto 0);
        ascii_out_clk : out std_logic;
        ascii_pressed : out boolean 
    );
    end component ps2_keyboard;

end perhipherals;

package body perhipherals is

end package body;