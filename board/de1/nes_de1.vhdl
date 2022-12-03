library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.nes_core.all;
use work.utilities.all;
use work.perhipherals.all;
use work.file_bus_types.all;

entity nes_de1 is
port
(
    CLOCK_50 : in std_logic;
    CLOCK_24 : in std_logic;

    I2C_SDAT : out std_logic;
    I2C_SCLK : out std_logic;
    
    FL_DQ    : in std_logic_vector(7 downto 0);
    FL_ADDR  : out std_logic_vector(21 downto 0);
    FL_WE_N  : out std_logic;
    FL_OE_N  : out std_logic;
    FL_RST_N : out std_logic;
    
    AUD_BCLK    : out std_logic;
    AUD_DACDAT  : out std_logic;
    AUD_DACLRCK : out std_logic
);
end nes_de1;

architecture behavioral of nes_de1 is
    
    signal audio_out : mixed_out_t;
    signal audio     : wm_audio_t;
    
    signal reg_audio_cpu_clk : mixed_out_t := (others => '0');
    signal reg_audio_aud_clk : mixed_out_t := (others => '0');

    signal cpu_clk_en  : boolean;
    signal nes_running : boolean;

    signal reset : boolean;
    
    signal clk_aud  : std_logic;
    
    signal flash_bus : file_bus_t;

    component nes_pll is
    port
    (
        inclk0 : in std_logic;
        c0     : out std_logic;
        c1     : out std_logic
    );
    end component nes_pll;
    
begin
    
    reset <= false;

    fl_addr <= resize(flash_bus.address, fl_addr'length)
    fl_we_n <= '1';
    fl_oe_n <= '0';
    fl_rst_n <= '1';
    
    -- Audio PLL {
    pll : nes_pll
    port map
    (
        inclk0 => CLOCK_50,
        c0 => clk_aud
    );
    -- }
    
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
    
    audio <= "0" & std_logic_vector(reg_audio_aud_clk) & "0000000";

    nes : nes_soc_ocram
    port map
    (
        clk => CLOCK_50
        reset => reset,

        nes_running => nes_running,

        cpu_clk_en => cpu_clk_en,

        file_bus => flash_bus,
        data_from_file => FL_DQ,

        audio => audio_out
    );

    process(CLOCK_50)
    begin
    if rising_edge(CLOCK_50) then
    if cpu_clk_en then
        if nes_running then
            reg_audio_cpu_clk <= audio_out;
        end if;
    end if;
    end if;
    end process;

    process(aud_clk)
    begin
    if rising_edge(aud_clk)
    then
        reg_audio_aud_clk <= reg_audio_cpu_clk;
    end if;
    end process;
    
end behavioral;