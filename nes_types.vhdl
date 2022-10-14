library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.ppu_bus_types.all;
use work.prg_bus_types.all;
use work.utilities.all;

package nes_types is
    
    subtype data_t is std_logic_vector(7 downto 0);
    subtype audio_t is unsigned(3 downto 0);
    subtype mixed_audio_t is unsigned(6 downto 0);
    
    type apu_out_t is record
        square_1 : audio_t;
        square_2 : audio_t;
        triangle : audio_t;
        noise    : audio_t;
    end record;
    function mix_audio(audio_in : apu_out_t) return mixed_audio_t;
    
    function is_ram_addr(addr : cpu_addr_t) return boolean;
    function get_ram_addr(addr : cpu_addr_t) return ram_addr_t;
    
    function is_ppu_addr(addr : cpu_addr_t) return boolean;
    function get_ppu_addr(addr : cpu_addr_t) return ppu_addr_t;
    
    function is_apu_addr(addr : cpu_addr_t) return boolean;
    function get_apu_addr(addr : cpu_addr_t) return apu_addr_t;
    
    function is_sram_addr(addr : cpu_addr_t) return boolean;
    function get_sram_addr(addr : cpu_addr_t) return sram_addr_t;
    
    --function is_prg_addr(addr : cpu_addr_t) return boolean;
    --function get_prg_addr(addr : cpu_addr_t) return prg_addr_t;
    
    component cpu is
    port
    (
        clk      : in  std_logic;
        reset    : in  boolean;
    
        data_bus : out cpu_bus_t;
        data_in  : in  data_t;
        data_out : out data_t;
    
        sync     : out boolean;
    
        ready    : in  boolean;
        nmi      : in  boolean;
        irq      : in  boolean
    );
    end component cpu;
    
    component apu is
    port
    (
        clk          : in  std_logic;
        reset        : in  boolean;

        cpu_bus      : in  apu_bus_t;
        cpu_data_in  : in  data_t;
        cpu_data_out : out data_t;

        audio        : out apu_out_t;

        irq          : out boolean
    );
    end component apu;

end nes_types;

package body nes_types is
    
    function mix_audio(audio_in : apu_out_t) return mixed_audio_t
    is
        variable result : unsigned(mixed_audio_t'range);
        
        variable square_in : unsigned(audio_t'high+1 downto 0);
        variable square_out : unsigned(mixed_audio_t'range);
        
        variable tnd_in : unsigned(7 downto 0);
        variable tnd_out : unsigned(mixed_audio_t'range);
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
                  resize(audio_in.noise & '0', tnd_in'length);
        
        case square_in is
            when "00000" => square_out := "0000000";
            when "00001" => square_out := "0000001";
            when "00010" => square_out := "0000011";
            when "00011" => square_out := "0000100";
            when "00100" => square_out := "0000110";
            when "00101" => square_out := "0000111";
            when "00110" => square_out := "0001000";
            when "00111" => square_out := "0001010";
            when "01000" => square_out := "0001011";
            when "01001" => square_out := "0001100";
            when "01010" => square_out := "0001101";
            when "01011" => square_out := "0001111";
            when "01100" => square_out := "0010000";
            when "01101" => square_out := "0010001";
            when "01110" => square_out := "0010010";
            when "01111" => square_out := "0010011";
            when "10000" => square_out := "0010100";
            when "10001" => square_out := "0010101";
            when "10010" => square_out := "0010110";
            when "10011" => square_out := "0010111";
            when "10100" => square_out := "0011000";
            when "10101" => square_out := "0011001";
            when "10110" => square_out := "0011010";
            when "10111" => square_out := "0011011";
            when "11000" => square_out := "0011100";
            when "11001" => square_out := "0011101";
            when "11010" => square_out := "0011110";
            when "11011" => square_out := "0011110";
            when "11100" => square_out := "0011111";
            when "11101" => square_out := "0100000";
            when "11110" => square_out := "0100001";
            when "11111" => square_out := "0100001";
            when others  => square_out := "0000000";
        end case;
        
        case tnd_in is
            when "00000000" => tnd_out := "0000000";
            when "00000001" => tnd_out := "0000001";
            when "00000010" => tnd_out := "0000010";
            when "00000011" => tnd_out := "0000011";
            when "00000100" => tnd_out := "0000011";
            when "00000101" => tnd_out := "0000100";
            when "00000110" => tnd_out := "0000101";
            when "00000111" => tnd_out := "0000110";
            when "00001000" => tnd_out := "0000111";
            when "00001001" => tnd_out := "0000111";
            when "00001010" => tnd_out := "0001000";
            when "00001011" => tnd_out := "0001001";
            when "00001100" => tnd_out := "0001010";
            when "00001101" => tnd_out := "0001011";
            when "00001110" => tnd_out := "0001011";
            when "00001111" => tnd_out := "0001100";
            when "00010000" => tnd_out := "0001101";
            when "00010001" => tnd_out := "0001110";
            when "00010010" => tnd_out := "0001110";
            when "00010011" => tnd_out := "0001111";
            when "00010100" => tnd_out := "0010000";
            when "00010101" => tnd_out := "0010001";
            when "00010110" => tnd_out := "0010001";
            when "00010111" => tnd_out := "0010010";
            when "00011000" => tnd_out := "0010011";
            when "00011001" => tnd_out := "0010011";
            when "00011010" => tnd_out := "0010100";
            when "00011011" => tnd_out := "0010101";
            when "00011100" => tnd_out := "0010101";
            when "00011101" => tnd_out := "0010110";
            when "00011110" => tnd_out := "0010111";
            when "00011111" => tnd_out := "0010111";
            when "00100000" => tnd_out := "0011000";
            when "00100001" => tnd_out := "0011001";
            when "00100010" => tnd_out := "0011001";
            when "00100011" => tnd_out := "0011010";
            when "00100100" => tnd_out := "0011011";
            when "00100101" => tnd_out := "0011011";
            when "00100110" => tnd_out := "0011100";
            when "00100111" => tnd_out := "0011101";
            when "00101000" => tnd_out := "0011101";
            when "00101001" => tnd_out := "0011110";
            when "00101010" => tnd_out := "0011111";
            when "00101011" => tnd_out := "0011111";
            when "00101100" => tnd_out := "0100000";
            when "00101101" => tnd_out := "0100000";
            when "00101110" => tnd_out := "0100001";
            when "00101111" => tnd_out := "0100010";
            when "00110000" => tnd_out := "0100010";
            when "00110001" => tnd_out := "0100011";
            when "00110010" => tnd_out := "0100011";
            when "00110011" => tnd_out := "0100100";
            when "00110100" => tnd_out := "0100101";
            when "00110101" => tnd_out := "0100101";
            when "00110110" => tnd_out := "0100110";
            when "00110111" => tnd_out := "0100110";
            when "00111000" => tnd_out := "0100111";
            when "00111001" => tnd_out := "0100111";
            when "00111010" => tnd_out := "0101000";
            when "00111011" => tnd_out := "0101001";
            when "00111100" => tnd_out := "0101001";
            when "00111101" => tnd_out := "0101010";
            when "00111110" => tnd_out := "0101010";
            when "00111111" => tnd_out := "0101011";
            when "01000000" => tnd_out := "0101011";
            when "01000001" => tnd_out := "0101100";
            when "01000010" => tnd_out := "0101100";
            when "01000011" => tnd_out := "0101101";
            when "01000100" => tnd_out := "0101101";
            when "01000101" => tnd_out := "0101110";
            when "01000110" => tnd_out := "0101110";
            when "01000111" => tnd_out := "0101111";
            when "01001000" => tnd_out := "0101111";
            when "01001001" => tnd_out := "0110000";
            when "01001010" => tnd_out := "0110000";
            when "01001011" => tnd_out := "0110001";
            when "01001100" => tnd_out := "0110001";
            when "01001101" => tnd_out := "0110010";
            when "01001110" => tnd_out := "0110010";
            when "01001111" => tnd_out := "0110011";
            when "01010000" => tnd_out := "0110011";
            when "01010001" => tnd_out := "0110100";
            when "01010010" => tnd_out := "0110100";
            when "01010011" => tnd_out := "0110101";
            when "01010100" => tnd_out := "0110101";
            when "01010101" => tnd_out := "0110110";
            when "01010110" => tnd_out := "0110110";
            when "01010111" => tnd_out := "0110111";
            when "01011000" => tnd_out := "0110111";
            when "01011001" => tnd_out := "0111000";
            when "01011010" => tnd_out := "0111000";
            when "01011011" => tnd_out := "0111001";
            when "01011100" => tnd_out := "0111001";
            when "01011101" => tnd_out := "0111001";
            when "01011110" => tnd_out := "0111010";
            when "01011111" => tnd_out := "0111010";
            when "01100000" => tnd_out := "0111011";
            when "01100001" => tnd_out := "0111011";
            when "01100010" => tnd_out := "0111100";
            when "01100011" => tnd_out := "0111100";
            when "01100100" => tnd_out := "0111101";
            when "01100101" => tnd_out := "0111101";
            when "01100110" => tnd_out := "0111101";
            when "01100111" => tnd_out := "0111110";
            when "01101000" => tnd_out := "0111110";
            when "01101001" => tnd_out := "0111111";
            when "01101010" => tnd_out := "0111111";
            when "01101011" => tnd_out := "0111111";
            when "01101100" => tnd_out := "1000000";
            when "01101101" => tnd_out := "1000000";
            when "01101110" => tnd_out := "1000001";
            when "01101111" => tnd_out := "1000001";
            when "01110000" => tnd_out := "1000010";
            when "01110001" => tnd_out := "1000010";
            when "01110010" => tnd_out := "1000010";
            when "01110011" => tnd_out := "1000011";
            when "01110100" => tnd_out := "1000011";
            when "01110101" => tnd_out := "1000100";
            when "01110110" => tnd_out := "1000100";
            when "01110111" => tnd_out := "1000100";
            when "01111000" => tnd_out := "1000101";
            when "01111001" => tnd_out := "1000101";
            when "01111010" => tnd_out := "1000101";
            when "01111011" => tnd_out := "1000110";
            when "01111100" => tnd_out := "1000110";
            when "01111101" => tnd_out := "1000111";
            when "01111110" => tnd_out := "1000111";
            when "01111111" => tnd_out := "1000111";
            when "10000000" => tnd_out := "1001000";
            when "10000001" => tnd_out := "1001000";
            when "10000010" => tnd_out := "1001000";
            when "10000011" => tnd_out := "1001001";
            when "10000100" => tnd_out := "1001001";
            when "10000101" => tnd_out := "1001001";
            when "10000110" => tnd_out := "1001010";
            when "10000111" => tnd_out := "1001010";
            when "10001000" => tnd_out := "1001011";
            when "10001001" => tnd_out := "1001011";
            when "10001010" => tnd_out := "1001011";
            when "10001011" => tnd_out := "1001100";
            when "10001100" => tnd_out := "1001100";
            when "10001101" => tnd_out := "1001100";
            when "10001110" => tnd_out := "1001101";
            when "10001111" => tnd_out := "1001101";
            when "10010000" => tnd_out := "1001101";
            when "10010001" => tnd_out := "1001110";
            when "10010010" => tnd_out := "1001110";
            when "10010011" => tnd_out := "1001110";
            when "10010100" => tnd_out := "1001111";
            when "10010101" => tnd_out := "1001111";
            when "10010110" => tnd_out := "1001111";
            when "10010111" => tnd_out := "1010000";
            when "10011000" => tnd_out := "1010000";
            when "10011001" => tnd_out := "1010000";
            when "10011010" => tnd_out := "1010001";
            when "10011011" => tnd_out := "1010001";
            when "10011100" => tnd_out := "1010001";
            when "10011101" => tnd_out := "1010010";
            when "10011110" => tnd_out := "1010010";
            when "10011111" => tnd_out := "1010010";
            when "10100000" => tnd_out := "1010010";
            when "10100001" => tnd_out := "1010011";
            when "10100010" => tnd_out := "1010011";
            when "10100011" => tnd_out := "1010011";
            when "10100100" => tnd_out := "1010100";
            when "10100101" => tnd_out := "1010100";
            when "10100110" => tnd_out := "1010100";
            when "10100111" => tnd_out := "1010101";
            when "10101000" => tnd_out := "1010101";
            when "10101001" => tnd_out := "1010101";
            when "10101010" => tnd_out := "1010110";
            when "10101011" => tnd_out := "1010110";
            when "10101100" => tnd_out := "1010110";
            when "10101101" => tnd_out := "1010110";
            when "10101110" => tnd_out := "1010111";
            when "10101111" => tnd_out := "1010111";
            when "10110000" => tnd_out := "1010111";
            when "10110001" => tnd_out := "1011000";
            when "10110010" => tnd_out := "1011000";
            when "10110011" => tnd_out := "1011000";
            when "10110100" => tnd_out := "1011000";
            when "10110101" => tnd_out := "1011001";
            when "10110110" => tnd_out := "1011001";
            when "10110111" => tnd_out := "1011001";
            when "10111000" => tnd_out := "1011010";
            when "10111001" => tnd_out := "1011010";
            when "10111010" => tnd_out := "1011010";
            when "10111011" => tnd_out := "1011010";
            when "10111100" => tnd_out := "1011011";
            when "10111101" => tnd_out := "1011011";
            when "10111110" => tnd_out := "1011011";
            when "10111111" => tnd_out := "1011011";
            when "11000000" => tnd_out := "1011100";
            when "11000001" => tnd_out := "1011100";
            when "11000010" => tnd_out := "1011100";
            when "11000011" => tnd_out := "1011100";
            when "11000100" => tnd_out := "1011101";
            when "11000101" => tnd_out := "1011101";
            when "11000110" => tnd_out := "1011101";
            when "11000111" => tnd_out := "1011110";
            when "11001000" => tnd_out := "1011110";
            when "11001001" => tnd_out := "1011110";
            when "11001010" => tnd_out := "1011110";
            when others     => tnd_out := "0000000";
        end case;
        result := square_out + tnd_out;
        
        return mixed_audio_t(result);
    end;
    
    function is_ram_addr(addr : cpu_addr_t) return boolean
    is
    begin
        return addr < x"2000";
    end;
    
    function get_ram_addr(addr : cpu_addr_t) return ram_addr_t
    is
    begin
        return addr(ram_addr_t'RANGE);
    end;
    
    function is_ppu_addr(addr : cpu_addr_t) return boolean
    is
    begin
        return addr >= x"2000" and addr < x"4000";
    end;
    
    function get_ppu_addr(addr : cpu_addr_t) return ppu_addr_t
    is
    begin
        return addr(ppu_addr_t'RANGE);
    end;
    
    function is_apu_addr(addr : cpu_addr_t) return boolean
    is
    begin
        return addr >= x"4000" and addr < x"4020";
    end;
    
    function get_apu_addr(addr : cpu_addr_t) return apu_addr_t
    is
    begin
        return addr(apu_addr_t'RANGE);
    end;
    
    function is_sram_addr(addr : cpu_addr_t) return boolean
    is
    begin
        return addr >= x"6000" and addr < x"8000";
    end;
    
    function get_sram_addr(addr : cpu_addr_t) return sram_addr_t
    is
    begin
        return addr(sram_addr_t'RANGE);
    end;
    
end package body;
