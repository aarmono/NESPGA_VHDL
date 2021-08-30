library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.de1_types.all;

entity video_top is
port
(
    CLOCK_50 : in std_logic;
    
    SW     : in std_logic_vector(9 downto 0);
    
    VGA_HS : out std_logic;
    VGA_VS : out std_logic;
    VGA_R  : out std_logic_vector(3 downto 0);
    VGA_G  : out std_logic_vector(3 downto 0);
    VGA_B  : out std_logic_vector(3 downto 0)
);
end video_top;

architecture behavioral of video_top is
    
    signal clk_75  : std_logic;
    signal clk_vga : std_logic;
    signal clk_ppu : std_logic;
    signal clk_div : unsigned(3 downto 0) := x"0";
    
    signal vga_out  : vga_out_t;
    
    component vga_pll is
    port
    (
        inclk0 : in std_logic;
        c0     : out std_logic
    );
    end component vga_pll;
    
    component test_pll is
    port
    (
        inclk0 : in std_logic;
        c0     : out std_logic
    );
    end component test_pll;
    
    component ppu_test is
    port
    (
        clk   : in std_logic;
        reset : in boolean;
        
        vert_patt : in boolean;
        
        ppu_valid : out boolean;
        ppu_out   : out vga_color_t
    );
    end component ppu_test;
    
    signal ppu_out : vga_color_t;
    signal ppu_valid : boolean;
    signal vert_patt : boolean;
begin

    vga_hs <= vga_out.h_sync;
    vga_vs <= vga_out.v_sync;
    vga_r  <= vga_out.color.red;
    vga_g  <= vga_out.color.green;
    vga_b  <= vga_out.color.blue;

    vert_patt <= sw(0) = '1';

    v_pll : component vga_pll
    port map
    (
        inclk0 => CLOCK_50,
        c0 => clk_vga
    );
    
    p_pll : component main_pll
    port map
    (
        inclk0 => CLOCK_50,
        c0 => clk_75
    );
    
    vga : component vga_gen
    port map
    (
        clk => clk_vga,
        reset => false,
        
        ppu_clk => clk_ppu,
        ppu_valid => ppu_valid,
        ppu_in => ppu_out,
        
        vga_out => vga_out
    );
    
    ppu : component ppu_test
    port map
    (
        clk => clk_ppu,
        reset => false,
        
        vert_patt => vert_patt,
        
        ppu_valid => ppu_valid,
        ppu_out => ppu_out
    );
    
    process(clk_75) begin
    if rising_edge(clk_75) then
        if clk_div = x"0"
        then
            clk_div <= to_unsigned(13, 4);
            clk_ppu <= '1';
        else
            clk_div <= clk_div - "1";
            clk_ppu <= '0';
        end if;
    end if;
    end process;
            

end behavioral;