library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity video_bench is
end video_bench;

architecture behavioral of video_bench is
    signal clk_50 : std_logic := '0';
    
    signal vga_hs : std_logic;
    signal vga_vs : std_logic;
	signal vga_r  : std_logic_vector(3 downto 0);
	signal vga_g  : std_logic_vector(3 downto 0);
	signal vga_b  : std_logic_vector(3 downto 0);
	
begin

    video : entity work.video_top(behavioral)
    port map
    (
        CLOCK_50 => clk_50,
        
        SW => "0000000000",
        
        VGA_HS => vga_hs,
        VGA_VS => vga_vs,
		VGA_R => vga_r,
		VGA_G => vga_g,
		VGA_B => vga_b
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