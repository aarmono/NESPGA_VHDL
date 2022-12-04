library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.binary_io.all;
use work.bmp_file.all;
use std.env.all;

entity bmp_file_bench is
generic
(
    FILEPATH  : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\\out.bmp"
);
end bmp_file_bench;

architecture behavioral of bmp_file_bench is
begin

    process
    is
        file bitmap : byte_file_t;

        constant WIDTH : dimension_t := to_unsigned(256, dimension_t'length);
        constant HEIGHT : dimension_t := to_unsigned(240, dimension_t'length);

        variable palette : palette_table_t;
        variable palette_val : unsigned(7 downto 0);

        variable pixel : unsigned(pixel_idx_t'range);
    begin
        for i in palette'range
        loop
            palette_val := to_unsigned(i, palette_val'length);
            palette(i) :=
                x"00" & std_logic_vector(palette_val & palette_val & palette_val);
        end loop;

        bmp_fopen_indexed(bitmap, FILEPATH, WIDTH, HEIGHT, palette);

        for y in 1 to to_integer(HEIGHT)
        loop
            for x in 0 to to_integer(WIDTH) - 1
            loop
                pixel := to_unsigned(x, pixel_idx_t'length) +
                         to_unsigned(y, pixel_idx_t'length);
                bmp_fwrite_indexed(bitmap, std_logic_vector(pixel));
            end loop;
        end loop;

        bmp_fclose(bitmap);
        finish;
    end process;

end behavioral;
