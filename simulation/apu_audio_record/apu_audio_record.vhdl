library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.binary_io.all;
use work.au_file.all;

entity apu_audio_record is
generic
(
    FILEPATH : string
);
port
(
    clk    : in std_logic;
    clk_en : in boolean;
    audio  : in mixed_audio_t;
    ready  : in boolean;
    done   : in boolean
);
end apu_audio_record;

architecture behavioral of apu_audio_record is

    file audio_file : byte_file_t;
    
begin

    process
        variable aud_out : std_logic_vector(15 downto 0);
    begin
        au_fopen_16(audio_file, FILEPATH, x"00017700");

        wait on clk until rising_edge(clk) and clk_en and ready;
        
        while not done loop
            wait for 10416 ns;
            
            aud_out := std_logic_vector("0" & audio & "0000000");
            au_fwrite_16(audio_file, aud_out);
        end loop;
        
        au_fclose_16(audio_file);
    end process;

end behavioral;
