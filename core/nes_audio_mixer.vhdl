library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;

package nes_audio_mixer is

    subtype mixed_audio_t is unsigned(7 downto 0);

    function mix_audio(audio_in : apu_out_t) return mixed_audio_t;
    
    function mix_audio
    (
        audio_in        : apu_out_t;
        enable_square_1 : boolean;
        enable_square_2 : boolean;
        enable_triangle : boolean;
        enable_noise    : boolean;
        enable_dmc      : boolean
    )
    return mixed_audio_t;

end nes_audio_mixer;

package body nes_audio_mixer is

    function mix_audio
    (
        audio_in        : apu_out_t;
        enable_square_1 : boolean;
        enable_square_2 : boolean;
        enable_triangle : boolean;
        enable_noise    : boolean;
        enable_dmc      : boolean
    )
    return mixed_audio_t
    is
        variable v_audio : apu_out_t;
    begin
        v_audio := audio_in;
        
        if not enable_square_1
        then
            v_audio.square_1 := (others => '0');
        end if;
        if not enable_square_2
        then
            v_audio.square_2 := (others => '0');
        end if;
        if not enable_triangle
        then
            v_audio.triangle := (others => '0');
        end if;
        if not enable_noise
        then
            v_audio.noise := (others => '0');
        end if;
        if not enable_dmc
        then
            v_audio.dmc := (others => '0');
        end if;
        
        return mix_audio(v_audio);
    end;

    function mix_audio(audio_in : apu_out_t) return mixed_audio_t
    is
        variable result : mixed_audio_t;
        
        variable square_in : unsigned(audio_t'high+1 downto 0);
        variable square_out : mixed_audio_t;
        
        variable tnd_in : unsigned(7 downto 0);
        variable tnd_out : mixed_audio_t;
    begin
        --     The normalized audio output level is the sum of two groups
        --     of channels:
        --
        --     output = square_out + tnd_out
        --
        --
        --                           95.88
        --     square_out = -----------------------
        --                         8128
        --                  ----------------- + 100
        --                  square1 + square2
        --
        --
        --                           159.79
        --     tnd_out = ------------------------------
        --                           1
        --               ------------------------ + 100
        --               triangle   noise    dmc
        --               -------- + ----- + -----
        --                 8227     12241   22638
        --
        --
        -- where triangle, noise, dmc, square1 and square2 are the values
        -- fed to their DACs. The dmc ranges from 0 to 127 and the others
        -- range from 0 to 15. When the sub-denominator of a group is zero,
        -- its output is 0. The output ranges from 0.0 to 1.0.
        --
        --
        -- Implementation Using Lookup Table 
        -- ---------------------------------
        -- The formulas can be efficiently implemented using two lookup
        -- tables: a 31-entry table for the two square channels and a
        -- 203-entry table for the remaining channels (due to the
        -- approximation of tnd_out, the numerators are adjusted slightly
        -- to preserve the normalized output range).
        --
        --     square_table [n] = 95.52 / (8128.0 / n + 100)
        --
        --     square_out = square_table [square1 + square2]
        --
        -- The latter table is approximated (within 4%) by using a base
        -- unit close to the
        -- DMC's DAC.
        --
        --     tnd_table [n] = 163.67 / (24329.0 / n + 100)
        --
        --     tnd_out = tnd_table [3 * triangle + 2 * noise + dmc]
        square_in := resize(audio_in.square_1, square_in'length) +
                     resize(audio_in.square_2, square_in'length);
        tnd_in := resize(audio_in.triangle & '0', tnd_in'length) +
                  resize(audio_in.triangle, tnd_in'length) +
                  resize(audio_in.noise & '0', tnd_in'length) +
                  resize(audio_in.dmc, tnd_in'length);
        
        case square_in is
            when "00000" => square_out := "00000000";
            when "00001" => square_out := "00000011";
            when "00010" => square_out := "00000110";
            when "00011" => square_out := "00001001";
            when "00100" => square_out := "00001011";
            when "00101" => square_out := "00001110";
            when "00110" => square_out := "00010001";
            when "00111" => square_out := "00010011";
            when "01000" => square_out := "00010110";
            when "01001" => square_out := "00011000";
            when "01010" => square_out := "00011011";
            when "01011" => square_out := "00011101";
            when "01100" => square_out := "00011111";
            when "01101" => square_out := "00100010";
            when "01110" => square_out := "00100100";
            when "01111" => square_out := "00100110";
            when "10000" => square_out := "00101000";
            when "10001" => square_out := "00101010";
            when "10010" => square_out := "00101100";
            when "10011" => square_out := "00101110";
            when "10100" => square_out := "00110000";
            when "10101" => square_out := "00110010";
            when "10110" => square_out := "00110100";
            when "10111" => square_out := "00110110";
            when "11000" => square_out := "00111000";
            when "11001" => square_out := "00111001";
            when "11010" => square_out := "00111011";
            when "11011" => square_out := "00111101";
            when "11100" => square_out := "00111110";
            when "11101" => square_out := "01000000";
            when "11110" => square_out := "01000010";
            when others  => square_out := "--------";
        end case;
        
        case tnd_in is
            when "00000000" => tnd_out := "00000000";
            when "00000001" => tnd_out := "00000010";
            when "00000010" => tnd_out := "00000011";
            when "00000011" => tnd_out := "00000101";
            when "00000100" => tnd_out := "00000111";
            when "00000101" => tnd_out := "00001000";
            when "00000110" => tnd_out := "00001010";
            when "00000111" => tnd_out := "00001100";
            when "00001000" => tnd_out := "00001101";
            when "00001001" => tnd_out := "00001111";
            when "00001010" => tnd_out := "00010000";
            when "00001011" => tnd_out := "00010010";
            when "00001100" => tnd_out := "00010100";
            when "00001101" => tnd_out := "00010101";
            when "00001110" => tnd_out := "00010111";
            when "00001111" => tnd_out := "00011000";
            when "00010000" => tnd_out := "00011010";
            when "00010001" => tnd_out := "00011011";
            when "00010010" => tnd_out := "00011101";
            when "00010011" => tnd_out := "00011110";
            when "00010100" => tnd_out := "00100000";
            when "00010101" => tnd_out := "00100001";
            when "00010110" => tnd_out := "00100011";
            when "00010111" => tnd_out := "00100100";
            when "00011000" => tnd_out := "00100101";
            when "00011001" => tnd_out := "00100111";
            when "00011010" => tnd_out := "00101000";
            when "00011011" => tnd_out := "00101010";
            when "00011100" => tnd_out := "00101011";
            when "00011101" => tnd_out := "00101100";
            when "00011110" => tnd_out := "00101110";
            when "00011111" => tnd_out := "00101111";
            when "00100000" => tnd_out := "00110001";
            when "00100001" => tnd_out := "00110010";
            when "00100010" => tnd_out := "00110011";
            when "00100011" => tnd_out := "00110100";
            when "00100100" => tnd_out := "00110110";
            when "00100101" => tnd_out := "00110111";
            when "00100110" => tnd_out := "00111000";
            when "00100111" => tnd_out := "00111010";
            when "00101000" => tnd_out := "00111011";
            when "00101001" => tnd_out := "00111100";
            when "00101010" => tnd_out := "00111101";
            when "00101011" => tnd_out := "00111111";
            when "00101100" => tnd_out := "01000000";
            when "00101101" => tnd_out := "01000001";
            when "00101110" => tnd_out := "01000010";
            when "00101111" => tnd_out := "01000100";
            when "00110000" => tnd_out := "01000101";
            when "00110001" => tnd_out := "01000110";
            when "00110010" => tnd_out := "01000111";
            when "00110011" => tnd_out := "01001000";
            when "00110100" => tnd_out := "01001001";
            when "00110101" => tnd_out := "01001011";
            when "00110110" => tnd_out := "01001100";
            when "00110111" => tnd_out := "01001101";
            when "00111000" => tnd_out := "01001110";
            when "00111001" => tnd_out := "01001111";
            when "00111010" => tnd_out := "01010000";
            when "00111011" => tnd_out := "01010001";
            when "00111100" => tnd_out := "01010011";
            when "00111101" => tnd_out := "01010100";
            when "00111110" => tnd_out := "01010101";
            when "00111111" => tnd_out := "01010110";
            when "01000000" => tnd_out := "01010111";
            when "01000001" => tnd_out := "01011000";
            when "01000010" => tnd_out := "01011001";
            when "01000011" => tnd_out := "01011010";
            when "01000100" => tnd_out := "01011011";
            when "01000101" => tnd_out := "01011100";
            when "01000110" => tnd_out := "01011101";
            when "01000111" => tnd_out := "01011110";
            when "01001000" => tnd_out := "01011111";
            when "01001001" => tnd_out := "01100000";
            when "01001010" => tnd_out := "01100001";
            when "01001011" => tnd_out := "01100010";
            when "01001100" => tnd_out := "01100011";
            when "01001101" => tnd_out := "01100100";
            when "01001110" => tnd_out := "01100101";
            when "01001111" => tnd_out := "01100110";
            when "01010000" => tnd_out := "01100111";
            when "01010001" => tnd_out := "01101000";
            when "01010010" => tnd_out := "01101001";
            when "01010011" => tnd_out := "01101010";
            when "01010100" => tnd_out := "01101011";
            when "01010101" => tnd_out := "01101100";
            when "01010110" => tnd_out := "01101101";
            when "01010111" => tnd_out := "01101110";
            when "01011000" => tnd_out := "01101111";
            when "01011001" => tnd_out := "01110000";
            when "01011010" => tnd_out := "01110001";
            when "01011011" => tnd_out := "01110010";
            when "01011100" => tnd_out := "01110011";
            when "01011101" => tnd_out := "01110011";
            when "01011110" => tnd_out := "01110100";
            when "01011111" => tnd_out := "01110101";
            when "01100000" => tnd_out := "01110110";
            when "01100001" => tnd_out := "01110111";
            when "01100010" => tnd_out := "01111000";
            when "01100011" => tnd_out := "01111001";
            when "01100100" => tnd_out := "01111010";
            when "01100101" => tnd_out := "01111010";
            when "01100110" => tnd_out := "01111011";
            when "01100111" => tnd_out := "01111100";
            when "01101000" => tnd_out := "01111101";
            when "01101001" => tnd_out := "01111110";
            when "01101010" => tnd_out := "01111111";
            when "01101011" => tnd_out := "01111111";
            when "01101100" => tnd_out := "10000000";
            when "01101101" => tnd_out := "10000001";
            when "01101110" => tnd_out := "10000010";
            when "01101111" => tnd_out := "10000011";
            when "01110000" => tnd_out := "10000100";
            when "01110001" => tnd_out := "10000100";
            when "01110010" => tnd_out := "10000101";
            when "01110011" => tnd_out := "10000110";
            when "01110100" => tnd_out := "10000111";
            when "01110101" => tnd_out := "10001000";
            when "01110110" => tnd_out := "10001000";
            when "01110111" => tnd_out := "10001001";
            when "01111000" => tnd_out := "10001010";
            when "01111001" => tnd_out := "10001011";
            when "01111010" => tnd_out := "10001011";
            when "01111011" => tnd_out := "10001100";
            when "01111100" => tnd_out := "10001101";
            when "01111101" => tnd_out := "10001110";
            when "01111110" => tnd_out := "10001110";
            when "01111111" => tnd_out := "10001111";
            when "10000000" => tnd_out := "10010000";
            when "10000001" => tnd_out := "10010001";
            when "10000010" => tnd_out := "10010001";
            when "10000011" => tnd_out := "10010010";
            when "10000100" => tnd_out := "10010011";
            when "10000101" => tnd_out := "10010100";
            when "10000110" => tnd_out := "10010100";
            when "10000111" => tnd_out := "10010101";
            when "10001000" => tnd_out := "10010110";
            when "10001001" => tnd_out := "10010110";
            when "10001010" => tnd_out := "10010111";
            when "10001011" => tnd_out := "10011000";
            when "10001100" => tnd_out := "10011000";
            when "10001101" => tnd_out := "10011001";
            when "10001110" => tnd_out := "10011010";
            when "10001111" => tnd_out := "10011011";
            when "10010000" => tnd_out := "10011011";
            when "10010001" => tnd_out := "10011100";
            when "10010010" => tnd_out := "10011101";
            when "10010011" => tnd_out := "10011101";
            when "10010100" => tnd_out := "10011110";
            when "10010101" => tnd_out := "10011111";
            when "10010110" => tnd_out := "10011111";
            when "10010111" => tnd_out := "10100000";
            when "10011000" => tnd_out := "10100000";
            when "10011001" => tnd_out := "10100001";
            when "10011010" => tnd_out := "10100010";
            when "10011011" => tnd_out := "10100010";
            when "10011100" => tnd_out := "10100011";
            when "10011101" => tnd_out := "10100100";
            when "10011110" => tnd_out := "10100100";
            when "10011111" => tnd_out := "10100101";
            when "10100000" => tnd_out := "10100110";
            when "10100001" => tnd_out := "10100110";
            when "10100010" => tnd_out := "10100111";
            when "10100011" => tnd_out := "10100111";
            when "10100100" => tnd_out := "10101000";
            when "10100101" => tnd_out := "10101001";
            when "10100110" => tnd_out := "10101001";
            when "10100111" => tnd_out := "10101010";
            when "10101000" => tnd_out := "10101010";
            when "10101001" => tnd_out := "10101011";
            when "10101010" => tnd_out := "10101100";
            when "10101011" => tnd_out := "10101100";
            when "10101100" => tnd_out := "10101101";
            when "10101101" => tnd_out := "10101101";
            when "10101110" => tnd_out := "10101110";
            when "10101111" => tnd_out := "10101111";
            when "10110000" => tnd_out := "10101111";
            when "10110001" => tnd_out := "10110000";
            when "10110010" => tnd_out := "10110000";
            when "10110011" => tnd_out := "10110001";
            when "10110100" => tnd_out := "10110001";
            when "10110101" => tnd_out := "10110010";
            when "10110110" => tnd_out := "10110011";
            when "10110111" => tnd_out := "10110011";
            when "10111000" => tnd_out := "10110100";
            when "10111001" => tnd_out := "10110100";
            when "10111010" => tnd_out := "10110101";
            when "10111011" => tnd_out := "10110101";
            when "10111100" => tnd_out := "10110110";
            when "10111101" => tnd_out := "10110110";
            when "10111110" => tnd_out := "10110111";
            when "10111111" => tnd_out := "10111000";
            when "11000000" => tnd_out := "10111000";
            when "11000001" => tnd_out := "10111001";
            when "11000010" => tnd_out := "10111001";
            when "11000011" => tnd_out := "10111010";
            when "11000100" => tnd_out := "10111010";
            when "11000101" => tnd_out := "10111011";
            when "11000110" => tnd_out := "10111011";
            when "11000111" => tnd_out := "10111100";
            when "11001000" => tnd_out := "10111100";
            when "11001001" => tnd_out := "10111101";
            when "11001010" => tnd_out := "10111101";
            when others     => tnd_out := "--------";
        end case;
        result := square_out + tnd_out;
        
        return result;
    end;

end package body;
