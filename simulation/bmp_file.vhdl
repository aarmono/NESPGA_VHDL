library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.binary_io.all;

package bmp_file is

    subtype dimension_t is unsigned(15 downto 0);
    subtype pixel_idx_t is std_logic_vector(7 downto 0);
    -- Red channel is 23 downto 16
    -- Green channel is 15 downto 8
    -- Blue channel is 7 downto 0
    subtype bgr_t is std_logic_vector(23 downto 0);
    -- Alpha channel is 31 downto 24
    -- Red channel is 23 downto 16
    -- Green channel is 15 downto 8
    -- Blue channel is 7 downto 0
    subtype bgra_t is std_logic_vector(31 downto 0);
    type palette_table_t is array(0 to 255) of bgra_t;

    procedure bmp_fopen_indexed
    (
        file byte_file : byte_file_t;
        filename       : string;
        width          : dimension_t;
        height         : dimension_t;
        palette_table  : palette_table_t
    );

    procedure bmp_fopen_bgr
    (
        file byte_file : byte_file_t;
        filename       : string;
        width          : dimension_t;
        height         : dimension_t
    );
    
    procedure bmp_fwrite_indexed
    (
        file file_in : byte_file_t;
        val          : pixel_idx_t
    );

    procedure bmp_fwrite_bgr
    (
        file file_in : byte_file_t;
        val          : bgr_t
    );
    
    procedure bmp_fclose
    (
        file file_in : byte_file_t
    );
    
end bmp_file;

package body bmp_file is
    
    procedure bmp_fopen_indexed
    (
        file byte_file : byte_file_t;
        filename       : string;
        width          : dimension_t;
        height         : dimension_t;
        palette_table  : palette_table_t
    )
    is
        variable signed_height : unsigned(31 downto 0);
        variable signed_width  : unsigned(31 downto 0);

        variable image_size : integer;
        constant HEADER_SIZE : integer := 54;
        constant START_OF_IMAGE : integer := HEADER_SIZE +
                                             (palette_table_t'length * 4);
    begin
        byte_fopen(byte_file, filename, write_mode);

        signed_width := resize(unsigned(width), signed_width'length);
        signed_height :=
            (not resize(unsigned(height), signed_height'length)) + "1";

        image_size := (to_integer(width) * to_integer(height)) + START_OF_IMAGE;

        -- File Header
        -- Magic Number
        byte_fwrite(byte_file, x"4D42");
        -- Size
        byte_fwrite(byte_file, std_logic_vector(to_unsigned(image_size, 32)));
        -- Reserved 1
        byte_fwrite(byte_file, x"0000");
        -- Reserved 2
        byte_fwrite(byte_file, x"0000");
        -- Image offset
        byte_fwrite(byte_file, std_logic_vector(to_unsigned(START_OF_IMAGE, 32)));

        -- BITMAPINFOHEADER
        -- Header size
        byte_fwrite(byte_file, x"00000028");
        -- Width
        byte_fwrite(byte_file, std_logic_vector(signed_width));
        -- Height
        byte_fwrite(byte_file, std_logic_vector(signed_height));
        -- Color planes
        byte_fwrite(byte_file, x"0001");
        -- Bits per pixel
        byte_fwrite(byte_file, x"0008");
        -- Compression method
        byte_fwrite(byte_file, x"00000000");
        -- Image size
        byte_fwrite(byte_file, x"00000000");
        -- Horizontal resolution
        byte_fwrite(byte_file, x"00000000");
        -- Vertical resolution
        byte_fwrite(byte_file, x"00000000");
        -- Color palette colors
        byte_fwrite(byte_file, x"00000000");
        -- Important colors
        byte_fwrite(byte_file, x"00000000");

        for i in palette_table'range
        loop
            byte_fwrite(byte_file, palette_table(i));
        end loop;
    end;

    procedure bmp_fopen_bgr
    (
        file byte_file : byte_file_t;
        filename       : string;
        width          : dimension_t;
        height         : dimension_t
    )
    is
        variable signed_height : unsigned(31 downto 0);
        variable signed_width  : unsigned(31 downto 0);

        variable image_size : integer;
        constant HEADER_SIZE : integer := 54;
        constant START_OF_IMAGE : integer := HEADER_SIZE;
    begin
        byte_fopen(byte_file, filename, write_mode);

        signed_width := resize(unsigned(width), signed_width'length);
        signed_height :=
            (not resize(unsigned(height), signed_height'length)) + "1";

        image_size := (to_integer(width) * to_integer(height)) + START_OF_IMAGE;

        -- File Header
        -- Magic Number
        byte_fwrite(byte_file, x"4D42");
        -- Size
        byte_fwrite(byte_file, std_logic_vector(to_unsigned(image_size, 32)));
        -- Reserved 1
        byte_fwrite(byte_file, x"0000");
        -- Reserved 2
        byte_fwrite(byte_file, x"0000");
        -- Image offset
        byte_fwrite(byte_file, std_logic_vector(to_unsigned(START_OF_IMAGE, 32)));

        -- BITMAPINFOHEADER
        -- Header size
        byte_fwrite(byte_file, x"00000028");
        -- Width
        byte_fwrite(byte_file, std_logic_vector(signed_width));
        -- Height
        byte_fwrite(byte_file, std_logic_vector(signed_height));
        -- Color planes
        byte_fwrite(byte_file, x"0001");
        -- Bits per pixel
        byte_fwrite(byte_file, x"0018");
        -- Compression method
        byte_fwrite(byte_file, x"00000000");
        -- Image size
        byte_fwrite(byte_file, x"00000000");
        -- Horizontal resolution
        byte_fwrite(byte_file, x"00000000");
        -- Vertical resolution
        byte_fwrite(byte_file, x"00000000");
        -- Color palette colors
        byte_fwrite(byte_file, x"00000000");
        -- Important colors
        byte_fwrite(byte_file, x"00000000");
    end;
    
    procedure bmp_fwrite_indexed
    (
        file file_in : byte_file_t;
        val          : pixel_idx_t
    )
    is
    begin
        byte_fwrite(file_in, val);
    end;

    procedure bmp_fwrite_bgr
    (
        file file_in : byte_file_t;
        val          : bgr_t
    )
    is
    begin
        byte_fwrite(file_in, val);
    end;
    
    procedure bmp_fclose
    (
        file file_in : byte_file_t
    )
    is
    begin
        byte_fclose(file_in);
    end;
end package body;