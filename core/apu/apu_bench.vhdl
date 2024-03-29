library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;
use work.nes_types.all;
use work.nes_audio_mixer.all;
use work.apu_bus_types.all;
use work.utilities.all;
use work.simulation.all;

entity apu_bench is
end apu_bench;

architecture behavioral of apu_bench is
    signal apu_bus      : apu_bus_t;
    signal apu_data_out : data_t;
    
    signal audio_out : apu_out_t;
    
    signal reset : boolean;
    
    signal cpu_clk : std_logic := '0';
    
    signal done : boolean;
    
    signal aud_count : unsigned(3 downto 0) := x"F";
    
begin

    nsf_apu : apu
    port map
    (
        clk => cpu_clk,
        reset => reset,
        
        cpu_bus => apu_bus,
        data_to_apu => apu_data_out,
        
        audio => audio_out
    );
    
    apu_playback : apu_bus_playback
    generic map
    (
        FILEPATH => "C:\\GitHub\\NESPGA_VHDL\\core\\apu\\Sequence.dat"
    )
    port map
    (
        apu_bus => apu_bus,
        apu_data_out => apu_data_out,
        done => done
    );
    
    audio_recorder : apu_audio_record
    generic map
    (
        FILEPATH => "C:\\GitHub\\NESPGA_VHDL\\core\\apu\\out.au"
    )
    port map
    (
        audio => mix_audio(audio_out),
        ready => not reset,
        done => done
    );
    
    -- Clock {
    cpu_clk_gen : clock
    generic map
    (
        PERIOD => 559 ns
    )
    port map
    (
        done => done,
        clk => cpu_clk,
        reset => reset
    );
    -- }

end behavioral;