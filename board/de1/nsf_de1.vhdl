library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_nsf.all;
use work.lib_wm8731.all;

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
    type ram_t is array(0 to 16#7FF#) of data_t;
    type sram_t is array(0 to 16#1FFF#) of data_t;
    
    signal ram : ram_t;
    signal sram : sram_t;
    
    signal ram_bus     : ram_bus_t;
    signal ram_bus_in  : ram_bus_t;
    signal sram_bus_in : sram_bus_t;
    signal sram_bus    : sram_bus_t;
    signal nsf_bus     : cpu_bus_t;
    
    signal sram_data_out    : data_t;
    signal sram_data_out_in : data_t;
    signal sram_data_in     : data_t;
    signal ram_data_out     : data_t;
    signal ram_data_out_in  : data_t;
    signal ram_data_in      : data_t;
    
    signal audio_out : mixed_audio_t;
    signal audio     : wm_audio_t;
    
    signal reset : boolean;
    
    signal cpu_clk : std_logic;
    signal nsf_clk : std_logic;
    
    signal cpu_count : unsigned(4 downto 0) := "00000";
    signal nsf_count : unsigned(5 downto 0) := "000000";
    
begin
    
    soc : nsf_soc
    port map
    (
        clk_cpu => cpu_clk,
        clk_nsf => nsf_clk,
        
        reset_out => reset,
        
        nsf_bus => nsf_bus,
        nsf_data_in => fl_dq,
        
        sram_bus => sram_bus_in,
        sram_data_out => sram_data_out_in,
        sram_data_in => sram_data_in,
        
        ram_bus => ram_bus_in,
        ram_data_out => ram_data_out_in,
        ram_data_in => ram_data_in,
        
        audio => audio_out
    );
    
    fl_addr <= resize(nsf_bus.address, fl_addr'length);
    fl_we_n <= '1';
    fl_oe_n <= '0';
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
    
    process(clk_50)
    begin
    if rising_edge(clk_50)
    then
        if is_bus_write(sram_bus)
        then
            sram(to_integer(sram_bus.address)) <= sram_data_out;
        elsif is_bus_read(sram_bus)
        then
            sram_data_in <= sram(to_integer(sram_bus.address));
        end if;
        
        if is_bus_write(ram_bus)
        then
            ram(to_integer(ram_bus.address)) <= ram_data_out;
        elsif is_bus_read(ram_bus)
        then
            ram_data_in <= ram(to_integer(ram_bus.address));
        end if;
        
        if cpu_count = ZERO(cpu_count)
        then
            cpu_clk <= '1';
            cpu_count <= to_unsigned(27, 5);
        else
            cpu_clk <= '0';
            cpu_count <= cpu_count - "1";
        end if;
        
        if nsf_count = ZERO(nsf_count)
        then
            nsf_clk <= '1';
            nsf_count <= to_unsigned(49, 6);
        else
            nsf_clk <= '0';
            nsf_count <= nsf_count - "1";
        end if;
        
        sram_bus <= sram_bus_in;
        sram_data_out <= sram_data_out_in;
        ram_bus <= ram_bus_in;
        ram_data_out <= ram_data_out_in;
    end if;
    end process;
    -- }
    
end behavioral;