library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.binary_io.all;

package au_file is
    procedure au_fopen_16
    (
        file byte_file : byte_file_t;
        filename       : string;
        sample_rate    : std_logic_vector(31 downto 0)
    );
    
    procedure au_fwrite_16
    (
        file file_in : byte_file_t; 
        val          : std_logic_vector(15 downto 0)
    );
    
end au_file;

package body au_file is
    procedure au_fwrite_word
    (
        file byte_file : byte_file_t;
        word           : std_logic_vector(31 downto 0)
    )
    is
    begin
        byte_fwrite(byte_file, word(31 downto 24));
        byte_fwrite(byte_file, word(23 downto 16));
        byte_fwrite(byte_file, word(15 downto 8));
        byte_fwrite(byte_file, word(7 downto 0));
    end;
    
    procedure au_fopen_16
    (
        file byte_file : byte_file_t;
        filename       : string;
        sample_rate    : std_logic_vector(31 downto 0)
    )
    is
    begin
        byte_fopen(byte_file, filename, write_mode);
        -- Magic Number
        au_fwrite_word(byte_file, x"2E736E64");
        -- Data Offset (24 bytes)
        au_fwrite_word(byte_file, x"00000018");
        -- Data Size (0xFFFFFFFF for unknown)
        au_fwrite_word(byte_file, x"FFFFFFFF");
        -- 16-bit linear PCM
        au_fwrite_word(byte_file, x"00000003");
        -- Sample rate
        au_fwrite_word(byte_file, sample_rate);
        -- 1 Channel
        au_fwrite_word(byte_file, x"00000001");
    end;
    
    procedure au_fwrite_16
    (
        file file_in : byte_file_t; 
        val          : std_logic_vector(15 downto 0)
    )
    is
    begin
        byte_fwrite(file_in, val(15 downto 8));
        byte_fwrite(file_in, val(7 downto 0));
    end;
end package body;