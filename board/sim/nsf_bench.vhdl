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
    
    signal file_bus    : file_bus_t;
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

    soc : nsf_soc_ocram
    port map
    (
        clk_50mhz => clk_50mhz,
        reset_in => false,
        
        reset_out => reset,
        
        next_stb => '0',
        prev_stb => '0',
        
        file_bus => file_bus,
        data_from_file => data_from_file,
        
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
