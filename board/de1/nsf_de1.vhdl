library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.file_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.soc.all;
use work.perhipheral_types.all;
use work.perhipherals.all;

entity nsf_de1 is
port
(
    clk_50 : in std_logic;
    clk_aud : in std_logic;

    i2c_sdat : out std_logic;
    i2c_sclk : out std_logic;
    
    sw : in std_logic_vector(3 downto 0);
    
    fl_dq    : in std_logic_vector(7 downto 0);
    fl_addr  : out std_logic_vector(21 downto 0);
    fl_we_n  : out std_logic;
    fl_oe_n  : out std_logic;
    fl_rst_n : out std_logic;
    
    aud_bclk    : out std_logic;
    aud_dacdat  : out std_logic;
    aud_daclrck : out std_logic
);
end nsf_de1;

architecture behavioral of nsf_de1 is
    
    signal nsf_bus     : file_bus_t;
    
    signal audio_out : mixed_audio_t;
    signal audio     : wm_audio_t;
    
    signal reset : boolean;
    
begin
    
    soc : nsf_soc_ocram
    port map
    (
        clk_50mhz => clk_50,
        reset_in => false,
        
        reset_out => reset,
        
        next_stb => '0',
        prev_stb => '0',
        
        file_bus => nsf_bus,
        data_from_file => fl_dq,
        
        audio => audio_out
    );
    
    fl_addr <= resize(nsf_bus.address, fl_addr'length);
    fl_we_n <= '1';
    fl_oe_n <= not to_std_logic(nsf_bus.read);
    fl_rst_n <= '1';
    
    
    audio <= "0" & std_logic_vector(audio_out) & "0000000";
    
    -- WM8731 interface {
    aud_out : wm8731
    port map
    (
        clk => clk_aud,
        reset => reset,
        
        audio => audio,
        
        sclk => i2c_sclk,
        sdat => i2c_sdat,
        
        bclk => aud_bclk,
        dac_dat => aud_dacdat,
        dac_lrck => aud_daclrck
    );
    -- }
    
end behavioral;