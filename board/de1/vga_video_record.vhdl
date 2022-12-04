library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.de1_types.all;
use work.binary_io.all;
use work.bmp_file.all;
use std.textio.all;

entity vga_video_record is
generic
(
    FILE_PREFIX : string
);
port
(
    clk       : in std_logic;

    vga_out   : in vga_out_t;
    ready     : in boolean := true;
    done      : in boolean := false
);
end vga_video_record;

architecture behavioral of vga_video_record is
    
    function format_frame_num(frame_num : integer; len : integer) return string
    is
        variable ret : string (1 to len);
    begin
        ret := justify(integer'image(frame_num), RIGHT, len);
        for i in ret'range
        loop
            if ret(i) = ' '
            then
                ret(i) := '0';
            end if;
        end loop;

        return ret;
    end;

begin

    process
        file bmp_file : byte_file_t;

        variable frame_num : integer;
        variable scanline_num : integer;
        variable pixel_num : integer;

        variable prev_frame_valid : boolean;
        variable prev_line_valid : boolean;

        variable pixel_val : bgr_t;

        constant WIDTH : dimension_t := to_unsigned(512, dimension_t'length);
        constant HEIGHT : dimension_t := to_unsigned(480, dimension_t'length);

    begin
        
        frame_num := 0;
        scanline_num := 0;
        pixel_num := 0;

        prev_frame_valid := false;
        prev_line_valid := false;

        while not done loop
            wait on clk until rising_edge(clk) and ready;

            if vga_out.fval and (not prev_frame_valid)
            then
                frame_num := frame_num + 1;
                scanline_num := 0;
                bmp_fopen_bgr(bmp_file,
                              FILE_PREFIX & "_" & format_frame_num(frame_num, 5) & ".bmp",
                              WIDTH,
                              HEIGHT);
            elsif (not vga_out.fval) and prev_frame_valid
            then
                bmp_fclose(bmp_file);
            end if;

            if vga_out.fval
            then
                if vga_out.lval and not prev_line_valid
                then
                    scanline_num := scanline_num + 1;
                    pixel_num := 0;
                elsif (not vga_out.lval) and prev_line_valid
                then
                    scanline_num := scanline_num + 1;
                end if;

                if vga_out.lval
                then
                    pixel_val(23 downto 16) := vga_out.color.red & x"0";
                    pixel_val(15 downto 8) := vga_out.color.green & x"0";
                    pixel_val(7 downto 0) := vga_out.color.blue & x"0";
                    bmp_fwrite_bgr(bmp_file, pixel_val);

                    pixel_num := pixel_num + 1;
                end if;
            end if;

            prev_frame_valid := vga_out.fval;
            prev_line_valid := vga_out.lval;
        end loop;
    end process;

end behavioral;
