library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.perhipherals.all;
use work.perhipheral_types.all;
use work.file_bus_types.all;
use work.sram_bus_types.all;
use work.soc.all;
use work.de1_types.all;

entity nes_top is
port
(
    CLOCK_50  : in std_logic;
    CLOCK_27  : in std_logic_vector(1 downto 0);

    I2C_SDAT : out std_logic;
    I2C_SCLK : out std_logic;
    
    PS2_CLK : inout std_logic;
    PS2_DAT : inout std_logic;
    
    SW   : in std_logic_vector(9 downto 0);
    LEDR : out std_logic_vector(9 downto 0);
    LEDG : out std_logic_vector(7 downto 0);
    
    FL_DQ    : in std_logic_vector(7 downto 0);
    FL_ADDR  : out std_logic_vector(21 downto 0);
    FL_WE_N  : out std_logic;
    FL_OE_N  : out std_logic;
    FL_RST_N : out std_logic;
    
    SRAM_DQ   : inout std_logic_vector(15 downto 0);
    SRAM_ADDR : out std_logic_vector(17 downto 0);
    SRAM_LB_N : out std_logic;
    SRAM_UB_N : out std_logic;
    SRAM_CE_N : out std_logic;
    SRAM_OE_N : out std_logic;
    SRAM_WE_N : out std_logic;

    VGA_R    : out std_logic_vector(3 downto 0);
    VGA_G    : out std_logic_vector(3 downto 0);
    VGA_B    : out std_logic_vector(3 downto 0);
    VGA_HS   : out std_logic;
    VGA_VS   : out std_logic;
    
    AUD_BCLK    : out std_logic;
    AUD_DACDAT  : out std_logic;
    AUD_DACLRCK : out std_logic;
    AUD_XCK     : out std_logic
);
end nes_top;

architecture behavioral of nes_top is

    component aud_pll is
    port
    (
        inclk0 : in std_logic  := '0';
        c0     : out std_logic;
        c1     : out std_logic;
        locked : out std_logic
    );
    end component aud_pll;
    
    component vga_pll is
    port
    (
        inclk0 : in std_logic  := '0';
        c0     : out std_logic;
        locked : out std_logic
    );
    end component vga_pll;

    signal clk_aud : std_logic;
    signal clk_vga : std_logic;
    signal clk_we  : std_logic;
    
    signal aud_locked : std_logic;
    signal vga_locked : std_logic;
    signal reset_n : std_logic;

begin
    
    reset_n <= aud_locked and vga_locked;
    
    -- 54 ns clock period 
    aud_clock_gen : aud_pll
    port map
    (
        inclk0 => CLOCK_50,
        c0 => clk_aud,
        c1 => clk_we,
        locked => aud_locked
    );
    
    -- 40 ns clock period
    vga_clock_gen : vga_pll
    port map
    (
        inclk0 => CLOCK_27(0),
        c0 => clk_vga,
        locked => vga_locked
    );
    
    nes : entity work.nes_de1(behavioral)
    port map
    (
        CLOCK_50 => CLOCK_50,
        CLOCK_VGA => clk_vga,
        CLOCK_AUD => clk_aud,
        CLOCK_WE => clk_we,
        RESET_N => reset_n,
        
        I2C_SDAT => I2C_SDAT,
        I2C_SCLK => I2C_SCLK,
        
        PS2_CLK => PS2_CLK,
        PS2_DAT => PS2_DAT,
        
        SW => SW,
        LEDR => LEDR,
        LEDG => LEDG,
        
        FL_DQ    => FL_DQ,
        FL_ADDR  => FL_ADDR,
        FL_WE_N  => FL_WE_N,
        FL_OE_N  => FL_OE_N,
        FL_RST_N => FL_RST_N,
        
        SRAM_DQ   => SRAM_DQ,
        SRAM_ADDR => SRAM_ADDR,
        SRAM_LB_N => SRAM_LB_N,
        SRAM_UB_N => SRAM_UB_N,
        SRAM_CE_N => SRAM_CE_N,
        SRAM_OE_N => SRAM_OE_N,
        SRAM_WE_N => SRAM_WE_N,

        VGA_R    => VGA_R,
        VGA_G    => VGA_G,
        VGA_B    => VGA_B,
        VGA_HS   => VGA_HS,
        VGA_VS   => VGA_VS,
        
        AUD_BCLK    => AUD_BCLK,
        AUD_DACDAT  => AUD_DACDAT,
        AUD_DACLRCK => AUD_DACLRCK,
        AUD_XCK     => AUD_XCK
    );

end behavioral;