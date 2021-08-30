library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity audio_bench is
end audio_bench;

architecture behavioral of audio_bench is
    signal clk_50 : std_logic := '0';
    
    signal i2c_sdat : std_logic;
    signal i2c_sclk : std_logic;
	
	signal aud_bclk : std_logic;
	signal aud_dacdat : std_logic;
	signal aud_daclrck : std_logic;
begin

    nsf : entity work.audio_top(behavioral)
    port map
    (
        CLOCK_50 => clk_50,
        
        I2C_SDAT => i2c_sdat,
        I2C_SCLK => i2c_sclk,
        
        AUD_BCLK => aud_bclk,
        AUD_DACDAT => aud_dacdat,
        AUD_DACLRCK => aud_daclrck
    );
	
	process
	begin
		while true
		loop
			clk_50 <= not clk_50;
			wait for 10 ns;
		end loop;
	end process;

end behavioral;