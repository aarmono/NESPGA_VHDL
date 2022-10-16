library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_audio_mixer.all;
use work.binary_io.all;
use work.au_file.all;

entity apu_audio_record is
generic
(
    FILEPATH : string
);
port
(
    audio : in mixed_audio_t;
    ready : in boolean;
    done  : in boolean
);
end apu_audio_record;

architecture behavioral of apu_audio_record is

    file audio_file : byte_file_t;
    
begin

    process
        variable aud_out : std_logic_vector(15 downto 0);
    begin
        au_fopen_16(audio_file, FILEPATH, x"00017700");
        
        while not done loop
            wait for 10416 ns;
            if ready
            then
                aud_out := std_logic_vector("0" & audio & "0000000");
                au_fwrite_16(audio_file, aud_out);
            end if;
        end loop;
        
        byte_fclose(audio_file);
    end process;

end behavioral;