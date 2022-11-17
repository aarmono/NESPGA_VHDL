library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.cpu_bus_types.all;
use work.file_bus_types.all;
use work.utilities.all;
use work.soc.all;
use work.simulation.all;

entity nsf_bench is
generic
(
    AU_FILEPATH  : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\\out.au";
    NSF_FILEPATH : string := "C:\\GitHub\\NESPGA_VHDL\\NSF\\SkateOrDie.nsf"
);
end nsf_bench;

architecture behavioral of nsf_bench is
    type ram_t is array(0 to 16#7FF#) of data_t;
    type sram_t is array(0 to 16#1FFF#) of data_t;
    
    signal ram : ram_t;
    signal sram : sram_t;
    
    signal ram_bus     : ram_bus_t;
    signal sram_bus    : sram_bus_t;
    signal file_bus    : file_bus_t;
    
    signal data_to_sram     : data_t;
    signal data_from_sram   : data_t;
    signal data_to_ram      : data_t;
    signal data_from_ram    : data_t;
    signal data_from_file   : data_t;
    
    signal audio_out : mixed_audio_t;
    
    signal reset : boolean;
    
    signal clk_50mhz : std_logic := '0';
    
    signal enable_square_1 : boolean := true;
    signal enable_square_2 : boolean := true;
    signal enable_triangle : boolean := true;
    signal enable_noise    : boolean := true;
    signal enable_dmc      : boolean := true;
begin

    soc : nsf_soc
    port map
    (
        clk_50mhz => clk_50mhz,
        reset_in => false,
        
        reset_out => reset,
        
        next_stb => '0',
        prev_stb => '0',
        
        file_bus => file_bus,
        data_from_file => data_from_file,
        
        sram_bus => sram_bus,
        data_to_sram => data_to_sram,
        data_from_sram => data_from_sram,
        
        ram_bus => ram_bus,
        data_to_ram => data_to_ram,
        data_from_ram => data_from_ram,
        
        enable_square_1 => enable_square_1,
        enable_square_2 => enable_square_2,
        enable_triangle => enable_triangle,
        enable_noise => enable_noise,
        enable_dmc => enable_dmc,
        
        audio => audio_out
    );
    
    apu_recorder : apu_audio_record
    generic map
    (
        FILEPATH => AU_FILEPATH
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => true,
        audio => audio_out,
        ready => not reset,
        done => false
    );
    
    -- Memory {
    nsf_file : file_memory
    generic map
    (
       FILEPATH => NSF_FILEPATH
    )
    port map
    (
       file_bus_1 => file_bus,
       data_from_file_1 => data_from_file
    );
    -- }
    
    -- RAM {
    process(all)
    begin
        if is_bus_write(sram_bus)
        then
            sram(to_integer(sram_bus.address)) <= data_to_sram;
        elsif is_bus_read(sram_bus)
        then
            data_from_sram <= sram(to_integer(sram_bus.address));
        end if;
    end process;
    
    process(all)
    begin
        if is_bus_write(ram_bus)
        then
            ram(to_integer(ram_bus.address)) <= data_to_ram;
        elsif is_bus_read(ram_bus)
        then
            data_from_ram <= ram(to_integer(ram_bus.address));
        end if;
    end process;
    -- }
    
    -- Clock {
    clk_50mhz_gen : clock
    generic map
    (
        PERIOD => 20 ns
    )
    port map
    (
        clk => clk_50mhz,
        done => false
    );
    -- }

end behavioral;
