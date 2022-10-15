library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.cpu_bus_types.all;
use work.binary_io.all;
use work.au_file.all;
use work.utilities.all;
use work.lib_nsf.all;

entity test_bench is
end test_bench;

architecture behavioral of test_bench is
    type ram_t is array(0 to 16#7FF#) of data_t;
    type sram_t is array(0 to 16#1FFF#) of data_t;
    
    signal ram : ram_t;
    signal sram : sram_t;
    
    signal ram_bus     : ram_bus_t;
    signal sram_bus    : sram_bus_t;
    signal nsf_bus     : cpu_bus_t;
    
    signal sram_data_out    : data_t;
    signal sram_data_in     : data_t;
    signal ram_data_out     : data_t;
    signal ram_data_in      : data_t;
    signal nsf_data_in      : data_t;
    
    signal audio_out : mixed_audio_t;
    
    signal reset : boolean;
    
    signal cpu_clk : std_logic := '0';
    signal nsf_clk : std_logic := '0';
    
    type memory_t is array (0 to 65535) of data_t;
    signal mem : memory_t;
    signal mem_initialized : boolean := false;
    
    file audio_file : byte_file_t;
    signal aud_count : unsigned(3 downto 0) := x"F";
begin

    soc : nsf_soc
    port map
    (
        clk_cpu => cpu_clk,
        clk_nsf => nsf_clk,
        
        reset_out => reset,
        
        nsf_bus => nsf_bus,
        nsf_data_in => nsf_data_in,
        
        sram_bus => sram_bus,
        sram_data_out => sram_data_out,
        sram_data_in => sram_data_in,
        
        ram_bus => ram_bus,
        ram_data_out => ram_data_out,
        ram_data_in => ram_data_in,
        
        audio => audio_out
    );
    
    process
        variable aud_out : std_logic_vector(15 downto 0);
    begin
        au_fopen_16(audio_file, "C:\\GitHub\\NESPGA_VHDL\\sim\\out.au", x"00017700");
        
        while true loop
            wait for 10416 ns;
            if not reset
            then
                aud_out := std_logic_vector("0" & audio_out & "00000000");
                au_fwrite_16(audio_file, aud_out);
            end if;
        end loop;
    end process;
            
    
    -- Memory {
    process(nsf_bus, mem_initialized)
        file test_mem     : byte_file_t;
        variable read_val : byte;
    begin
        if not mem_initialized
        then
            byte_fopen(test_mem, "C:\\GitHub\\NESPGA_VHDL\\NSF\\WorldCup.nsf", read_mode);
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
        end if;
        
        if is_bus_read(nsf_bus)
        then
            nsf_data_in <= mem(to_integer(nsf_bus.address));
        end if;
    end process;
    -- }
    
    -- RAM {
    process(sram_bus, sram_data_out)
    begin
        if is_bus_write(sram_bus)
        then
            sram(to_integer(sram_bus.address)) <= sram_data_out;
        elsif is_bus_read(sram_bus)
        then
            sram_data_in <= sram(to_integer(sram_bus.address));
        end if;
    end process;
    
    process(ram_bus, ram_data_out)
    begin
        if is_bus_write(ram_bus)
        then
            ram(to_integer(ram_bus.address)) <= ram_data_out;
        elsif is_bus_read(ram_bus)
        then
            ram_data_in <= ram(to_integer(ram_bus.address));
        end if;
    end process;
    -- }
    
    -- Clock {
    process
    begin
        while true loop
            wait for 279 ns;
            cpu_clk <= '1';
            wait for 280 ns;
            cpu_clk <= '0';
        end loop;
    end process;
    
    process
    begin
        while true loop
            wait for 500 ns;
            nsf_clk <= '1';
            wait for 500 ns;
            nsf_clk <= '0';
        end loop;
    end process;
    -- }

end behavioral;