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

entity nes_de1 is
port
(
    CLOCK_50 : in std_logic;
    CLOCK_24 : in std_logic_vector(1 downto 0);

    I2C_SDAT : out std_logic;
    I2C_SCLK : out std_logic;
    
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
    
    AUD_BCLK    : out std_logic;
    AUD_DACDAT  : out std_logic;
    AUD_DACLRCK : out std_logic
);
end nes_de1;

architecture behavioral of nes_de1 is
    
    signal audio_out : mixed_audio_t;
    signal audio     : wm_audio_t;
    
    signal reg_audio_cpu_clk : mixed_audio_t := (others => '0');
    signal reg_audio_aud_clk : mixed_audio_t := (others => '0');

    signal cpu_clk_en  : boolean;
    signal nes_running : boolean;
    signal cpu_ram_en  : boolean;

    signal reset : boolean;
    
    signal clk_aud  : std_logic;
    
    signal flash_bus : file_bus_t;
    
    signal sram_bus       : sram_bus_t;
    signal data_to_sram   : data_t;
    signal data_from_sram : data_t;
    
    signal reg_sram_addr : std_logic_vector(SRAM_ADDR'range) := (others => '0');
    signal reg_sram_oe_n : std_logic := '1';
    signal reg_sram_we_n : std_logic := '1';

    component aud_pll is
    port
    (
        inclk0 : in std_logic;
        c0     : out std_logic
    );
    end component aud_pll;
    
begin
    
    reset <= false;

    fl_addr <= resize(flash_bus.address, fl_addr'length);
    fl_we_n <= '1';
    fl_oe_n <= '0';
    fl_rst_n <= '1';
    
    SRAM_CE_N <= '0';
    SRAM_LB_N <= '0';
    SRAM_UB_N <= '1';
    
    SRAM_WE_N <= reg_sram_oe_n;
    SRAM_OE_N <= reg_sram_oe_n;
    SRAM_ADDR <= reg_sram_addr;
    
    -- Audio PLL {
    pll : aud_pll
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
    generic map
    (
        USE_EXT_SRAM => true
    )
    port map
    (
        clk_50mhz => CLOCK_50,
        reset => reset,

        nes_running => nes_running,

        cpu_clk_en => cpu_clk_en,
        cpu_ram_en => cpu_ram_en,

        file_bus => flash_bus,
        data_from_file => FL_DQ,
        
        sram_bus => sram_bus,
        data_to_sram => data_to_sram,
        data_from_sram => data_from_sram,

        audio => audio_out
    );
    
    process(CLOCK_50)
    begin
    if rising_edge(CLOCK_50) then
    if cpu_ram_en then
        reg_sram_addr <= resize(sram_bus.address, SRAM_ADDR'length);
        reg_sram_oe_n <= not to_std_logic(sram_bus.read);
        reg_sram_oe_n <= not to_std_logic(sram_bus.write);
    end if;
    end if;
    end process;
    
    process(all)
    begin
        if reg_sram_oe_n
        then
            SRAM_DQ <= (others => 'Z');
            data_from_sram <= SRAM_DQ(data_from_sram'range);
        elsif reg_sram_we_n
        then
            SRAM_DQ <= resize(data_to_sram, SRAM_DQ'length);
            data_from_sram <= (others => '-');
        else
            SRAM_DQ <= (others => 'Z');
            data_from_sram <= (others => '-');
        end if;
    end process;

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

    process(clk_aud)
    begin
    if rising_edge(clk_aud)
    then
        reg_audio_aud_clk <= reg_audio_cpu_clk;
    end if;
    end process;
    
end behavioral;