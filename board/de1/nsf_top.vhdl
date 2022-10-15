library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity nsf_top is
port
(
    CLOCK_50 : in std_logic;
    
    I2C_SDAT : out std_logic;
    I2C_SCLK : out std_logic;
    
    SW : in std_logic_vector(9 downto 0);
    
    FL_DQ    : in std_logic_vector(7 downto 0);
    FL_ADDR  : out std_logic_vector(21 downto 0);
    FL_WE_N  : out std_logic;
    FL_OE_N  : out std_logic;
    FL_RST_N : out std_logic;
    
    AUD_BCLK    : out std_logic;
    AUD_DACDAT  : out std_logic;
    AUD_DACLRCK : out std_logic;
    AUD_XCK     : out std_logic
);
end nsf_top;

architecture behavioral of nsf_top is

    component nsf_de1 is
    port
    (
        clk_50 : in std_logic;
        clk_aud : in std_logic;
        
        sw : in std_logic_vector(3 downto 0);

        i2c_sdat : out std_logic;
        i2c_sclk : out std_logic;
    
        fl_dq    : in std_logic_vector(7 downto 0);
        fl_addr  : out std_logic_vector(21 downto 0);
        fl_we_n  : out std_logic;
        fl_oe_n  : out std_logic;
        fl_rst_n : out std_logic;
    
        aud_bclk    : out std_logic;
        aud_dacdat  : out std_logic;
        aud_daclrck : out std_logic
    );
    end component;
    
    component aud_pll is
    port
    (
        inclk0 : in std_logic;
        c0     : out std_logic
    );
    end component aud_pll;

    signal clk_aud : std_logic;
begin

    aud_xck <= clk_aud;

    aud : component aud_pll
    port map
    (
        inclk0 => CLOCK_50,
        c0 => clk_aud
    );

    nsf : component nsf_de1
    port map
    (
        clk_50 => CLOCK_50,
        clk_aud => clk_aud,
        sw => sw(3 downto 0),
        i2c_sdat => i2c_sdat,
        i2c_sclk => i2c_sclk,
        fl_dq => fl_dq,
        fl_addr => fl_addr,
        fl_we_n => fl_we_n,
        fl_oe_n => fl_oe_n,
        fl_rst_n => fl_rst_n,
        aud_bclk => aud_bclk,
        aud_dacdat => aud_dacdat,
        aud_daclrck => aud_daclrck
    );

end behavioral;