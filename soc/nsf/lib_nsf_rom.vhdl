library IEEE;
use IEEE.std_logic_1164.all;


package lib_nsf_rom is

    function get_nsf_byte
    (
        addr : std_logic_vector(7 downto 0)
    )
    return std_logic_vector;


end lib_nsf_rom;

package body lib_nsf_rom is


    function get_nsf_byte
    (
        addr : std_logic_vector(7 downto 0)
    )
    return std_logic_vector
    is
        variable ret : std_logic_vector(7 downto 0);
    begin
        case addr is
            when "00000000" => ret := x"a2";
            when "00000001" => ret := x"ff";
            when "00000010" => ret := x"9a";
            when "00000011" => ret := x"a9";
            when "00000100" => ret := x"38";
            when "00000101" => ret := x"48";
            when "00000110" => ret := x"a9";
            when "00000111" => ret := x"12";
            when "00001000" => ret := x"48";
            when "00001001" => ret := x"ad";
            when "00001010" => ret := x"00";
            when "00001011" => ret := x"37";
            when "00001100" => ret := x"ae";
            when "00001101" => ret := x"01";
            when "00001110" => ret := x"37";
            when "00001111" => ret := x"6c";
            when "00010000" => ret := x"02";
            when "00010001" => ret := x"37";
            when "00010010" => ret := x"ea";
            when "00010011" => ret := x"a9";
            when "00010100" => ret := x"01";
            when "00010101" => ret := x"d0";
            when "00010110" => ret := x"fc";
            when "00010111" => ret := x"ff";
            when "00011000" => ret := x"ff";
            when "00011001" => ret := x"ff";
            when "00011010" => ret := x"ff";
            when "00011011" => ret := x"ff";
            when "00011100" => ret := x"ff";
            when "00011101" => ret := x"ff";
            when "00011110" => ret := x"ff";
            when "00011111" => ret := x"ff";
            when "00100000" => ret := x"ff";
            when "00100001" => ret := x"ff";
            when "00100010" => ret := x"ff";
            when "00100011" => ret := x"ff";
            when "00100100" => ret := x"ff";
            when "00100101" => ret := x"ff";
            when "00100110" => ret := x"ff";
            when "00100111" => ret := x"ff";
            when "00101000" => ret := x"ff";
            when "00101001" => ret := x"ff";
            when "00101010" => ret := x"ff";
            when "00101011" => ret := x"ff";
            when "00101100" => ret := x"ff";
            when "00101101" => ret := x"ff";
            when "00101110" => ret := x"ff";
            when "00101111" => ret := x"ff";
            when "00110000" => ret := x"ff";
            when "00110001" => ret := x"ff";
            when "00110010" => ret := x"ff";
            when "00110011" => ret := x"ff";
            when "00110100" => ret := x"ff";
            when "00110101" => ret := x"ff";
            when "00110110" => ret := x"ff";
            when "00110111" => ret := x"ff";
            when "00111000" => ret := x"ff";
            when "00111001" => ret := x"ff";
            when "00111010" => ret := x"ff";
            when "00111011" => ret := x"ff";
            when "00111100" => ret := x"ff";
            when "00111101" => ret := x"ff";
            when "00111110" => ret := x"ff";
            when "00111111" => ret := x"ff";
            when "01000000" => ret := x"ff";
            when "01000001" => ret := x"ff";
            when "01000010" => ret := x"ff";
            when "01000011" => ret := x"ff";
            when "01000100" => ret := x"ff";
            when "01000101" => ret := x"ff";
            when "01000110" => ret := x"ff";
            when "01000111" => ret := x"ff";
            when "01001000" => ret := x"ff";
            when "01001001" => ret := x"ff";
            when "01001010" => ret := x"ff";
            when "01001011" => ret := x"ff";
            when "01001100" => ret := x"ff";
            when "01001101" => ret := x"ff";
            when "01001110" => ret := x"ff";
            when "01001111" => ret := x"ff";
            when "01010000" => ret := x"ff";
            when "01010001" => ret := x"ff";
            when "01010010" => ret := x"ff";
            when "01010011" => ret := x"ff";
            when "01010100" => ret := x"ff";
            when "01010101" => ret := x"ff";
            when "01010110" => ret := x"ff";
            when "01010111" => ret := x"ff";
            when "01011000" => ret := x"ff";
            when "01011001" => ret := x"ff";
            when "01011010" => ret := x"ff";
            when "01011011" => ret := x"ff";
            when "01011100" => ret := x"ff";
            when "01011101" => ret := x"ff";
            when "01011110" => ret := x"ff";
            when "01011111" => ret := x"ff";
            when "01100000" => ret := x"ff";
            when "01100001" => ret := x"ff";
            when "01100010" => ret := x"ff";
            when "01100011" => ret := x"ff";
            when "01100100" => ret := x"ff";
            when "01100101" => ret := x"ff";
            when "01100110" => ret := x"ff";
            when "01100111" => ret := x"ff";
            when "01101000" => ret := x"ff";
            when "01101001" => ret := x"ff";
            when "01101010" => ret := x"ff";
            when "01101011" => ret := x"ff";
            when "01101100" => ret := x"ff";
            when "01101101" => ret := x"ff";
            when "01101110" => ret := x"ff";
            when "01101111" => ret := x"ff";
            when "01110000" => ret := x"ff";
            when "01110001" => ret := x"ff";
            when "01110010" => ret := x"ff";
            when "01110011" => ret := x"ff";
            when "01110100" => ret := x"ff";
            when "01110101" => ret := x"ff";
            when "01110110" => ret := x"ff";
            when "01110111" => ret := x"ff";
            when "01111000" => ret := x"ff";
            when "01111001" => ret := x"ff";
            when "01111010" => ret := x"ff";
            when "01111011" => ret := x"ff";
            when "01111100" => ret := x"ff";
            when "01111101" => ret := x"ff";
            when "01111110" => ret := x"ff";
            when "01111111" => ret := x"ff";
            when "10000000" => ret := x"a9";
            when "10000001" => ret := x"38";
            when "10000010" => ret := x"48";
            when "10000011" => ret := x"a9";
            when "10000100" => ret := x"89";
            when "10000101" => ret := x"48";
            when "10000110" => ret := x"6c";
            when "10000111" => ret := x"04";
            when "10001000" => ret := x"37";
            when "10001001" => ret := x"ea";
            when "10001010" => ret := x"40";
            when others => ret := (others => '-');
        end case;

        return ret;
    end;

end package body;

