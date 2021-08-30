library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.binary_io.all;
use work.au_file.all;
use work.utilities.all;

entity test_bench is
end test_bench;

architecture behavioral of test_bench is
    signal clk_50 : std_logic := '0';
    signal clk_aud : std_logic := '0';
    
    signal i2c_sdat : std_logic;
    signal i2c_sclk : std_logic;
    
    signal sw : std_logic_vector(3 downto 0);
    
    signal fl_dq   : std_logic_vector(7 downto 0);
    signal fl_addr : std_logic_vector(21 downto 0);
    
    signal bclk    : std_logic;
    signal dacdat  : std_logic;
    signal daclrck : std_logic;
    
    type memory_t is array (0 to 65535) of data_t;
    signal mem : memory_t;
    signal mem_initialized : boolean := false;
    
    file audio_file : byte_file_t;
    signal aud_initialized : boolean := false;
    signal aud_shift : std_logic_vector(15 downto 0) := x"0000";
    signal aud_count : unsigned(3 downto 0) := x"F";
begin

    nsf : entity work.nsf_de1(behavioral)
    port map
    (
        clk_50 => clk_50,
        clk_aud => clk_aud,
        
        i2c_sdat => i2c_sdat,
        i2c_sclk => i2c_sclk,
        
        sw => "1111",
        
        fl_dq => fl_dq,
        fl_addr => fl_addr,
        
        aud_bclk => bclk,
        aud_dacdat => dacdat,
        aud_daclrck => daclrck
    );
    
    process(bclk)
        variable aud_out : std_logic_vector(15 downto 0);
    begin
    if rising_edge(bclk) then
        if not aud_initialized
        then
            au_fopen_16(audio_file, "C:\\NES_TNG\\out.au", x"00017700");
            aud_initialized <= true;
        end if;
        
        aud_out := aud_shift;
        if daclrck = '1'
        then
            aud_out(to_integer(aud_count)) := dacdat;
            if aud_count = x"0"
            then
                au_fwrite_16(audio_file, aud_out);
                flush(audio_file);
            end if;
            
            aud_shift <= aud_out;
            aud_count <= aud_count - "1";
        end if;
    end if;
    end process;
            
    
    -- Memory {
    process(fl_addr, mem_initialized)
        file test_mem     : byte_file_t;
        variable read_val : byte;
    begin
        if not mem_initialized
        then
            byte_fopen(test_mem, "C:\\NES_TNG\\NSF\\Mario.nsf", read_mode);
            for i in mem'RANGE loop
                if not byte_feof(test_mem)
                then
                    mem(i) <= byte_fread(test_mem);
                else
                    mem(i) <= x"00";
                end if;
            end loop;
            byte_fclose(test_mem);
            
            mem_initialized <= true;
        else
            fl_dq <= mem(to_integer(fl_addr(15 downto 0)));
        end if;
    end process;
    -- }
    
    -- Clock {
    process
    begin
        while true loop
            clk_50 <= not clk_50;
            wait for 10 ns;
        end loop;
    end process;
    
    process
    begin
        while true loop
            clk_aud <= not clk_aud;
            wait for 27 ns;
        end loop;
    end process;
    
    -- }

end behavioral;