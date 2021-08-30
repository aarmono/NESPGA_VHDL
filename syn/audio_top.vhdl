library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.lib_wm8731.all;

entity audio_top is
port
(
    CLOCK_50 : in std_logic;
    
    I2C_SDAT : out std_logic;
    I2C_SCLK : out std_logic;
    
    AUD_BCLK    : out std_logic;
    AUD_DACDAT  : out std_logic;
    AUD_DACLRCK : out std_logic;
    AUD_XCK     : out std_logic
);
end audio_top;

architecture behavioral of audio_top is
    
    component aud_pll is
    port
    (
        inclk0 : in std_logic;
        c0     : out std_logic
    );
    end component aud_pll;
    
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
    end component;

    signal clk_aud : std_logic;
    signal audio : unsigned(wm_audio_t'RANGE);
    signal up : boolean;
    signal reset : boolean := true;
begin

    aud_xck <= clk_aud;

    aud : component aud_pll
    port map
    (
        inclk0 => CLOCK_50,
        c0 => clk_aud
    );
    
    sound : component wm8731
    port map
    (
        clk => clk_aud,
        reset => false,
        audio => std_logic_vector(audio),
        sclk => i2c_sclk,
        sdat => i2c_sdat,
        bclk => aud_bclk,
        dac_dat => aud_dacdat,
        dac_lrck => aud_daclrck
    );
    
    process(clk_aud) begin
    if rising_edge(clk_aud)
    then
        if audio = ZERO(audio)
        then
            up <= true;
            audio <= audio + "1";
        elsif audio = x"7FFF"
        then
            up <= false;
            audio <= audio - "1";
        elsif up
        then
            audio <= audio + "1";
        else
            audio <= audio - "1";
        end if;
        
        if reset
        then
            reset <= false;
        end if;
    end if;
    end process;
            

end behavioral;