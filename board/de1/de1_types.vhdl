library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--use work.lib_wm8731.all;

package de1_types is
    
    type vga_color_t is record
        red   : std_logic_vector(3 downto 0);
        green : std_logic_vector(3 downto 0);
        blue  : std_logic_vector(3 downto 0);
    end record;
    
    constant COLOR_BLACK : vga_color_t :=
    (
        red => (others => '0'),
        green => (others => '0'),
        blue => (others => '0')
    );
    
    constant COLOR_RED : vga_color_t :=
    (
        red => (others => '1'),
        green => (others => '0'),
        blue => (others => '0')
    );
    
    type vga_out_t is record
        color  : vga_color_t;
        h_sync : std_logic;
        v_sync : std_logic;
    end record;
    
    constant VGA_RESET : vga_out_t :=
    (
        color => COLOR_BLACK,
        h_sync => '1',
        v_sync => '1'
    );
    
--    component wm8731 is
--    port
--    (
--        clk      : in std_logic;
--        reset    : in boolean;
--        
--        audio    : in wm_audio_t;
--        
--        sclk     : out std_logic;
--        sdat     : out std_logic;
--        bclk     : out std_logic;
--        dac_dat  : out std_logic;
--        dac_lrck : out std_logic
--    );
--    end component wm8731;
    
    component vga_gen is
    port
    (
        clk            : in std_logic;
        reset          : in boolean;
        
        ppu_clk        : in std_logic;
        ppu_valid      : in boolean;
        ppu_in         : in vga_color_t;
        
        vga_out        : out vga_out_t
    );
    end component vga_gen;
    
    component main_pll is
    port
    (
        inclk0 : in std_logic;
        c0     : out std_logic
    );
    end component main_pll;
    
end de1_types;

package body de1_types is
    
    
    
end package body;