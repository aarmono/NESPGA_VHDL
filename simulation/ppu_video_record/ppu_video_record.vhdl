library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.binary_io.all;
use work.bmp_file.all;
use std.textio.all;

entity ppu_video_record is
generic
(
    FILE_PREFIX : string
);
port
(
    clk       : in std_logic;
    clk_en    : in boolean;
    pixel_bus : in pixel_bus_t;
    ready     : in boolean;
    done      : in boolean
);
end ppu_video_record;

architecture behavioral of ppu_video_record is
    
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

        variable pixel_val : pixel_idx_t;

        constant WIDTH : dimension_t := to_unsigned(256, dimension_t'length);
        constant HEIGHT : dimension_t := to_unsigned(240, dimension_t'length);

        -- 2C02 values from the Mesen emulator
        constant palette : palette_table_t :=
        (
            x"00666666",
            x"00002A88",
            x"001412A7",
            x"003B00A4",
            x"005C007E",
            x"006E0040",
            x"006C0600",
            x"00561D00",
            x"00333500",
            x"000B4800",
            x"00005200",
            x"00004F08",
            x"0000404D",
            x"00000000",
            x"00000000",
            x"00000000",
            x"00ADADAD",
            x"00155FD9",
            x"004240FF",
            x"007527FE",
            x"00A01ACC",
            x"00B71E7B",
            x"00B53120",
            x"00994E00",
            x"006B6D00",
            x"00388700",
            x"000C9300",
            x"00008F32",
            x"00007C8D",
            x"00000000",
            x"00000000",
            x"00000000",
            x"00FFFEFF",
            x"0064B0FF",
            x"009290FF",
            x"00C676FF",
            x"00F36AFF",
            x"00FE6ECC",
            x"00FE8170",
            x"00EA9E22",
            x"00BCBE00",
            x"0088D800",
            x"005CE430",
            x"0045E082",
            x"0048CDDE",
            x"004F4F4F",
            x"00000000",
            x"00000000",
            x"00FFFEFF",
            x"00C0DFFF",
            x"00D3D2FF",
            x"00E8C8FF",
            x"00FBC2FF",
            x"00FEC4EA",
            x"00FECCC5",
            x"00F7D8A5",
            x"00E4E594",
            x"00CFEF96",
            x"00BDF4AB",
            x"00B3F3CC",
            x"00B5EBF2",
            x"00B8B8B8",
            x"00000000",
            x"00000000",
            others => x"00FF0000"
        );

    begin
        
        frame_num := 0;
        scanline_num := 0;
        pixel_num := 0;

        prev_frame_valid := false;
        prev_line_valid := false;

        while not done loop
            wait on clk until rising_edge(clk) and clk_en and ready;

            if pixel_bus.frame_valid and (not prev_frame_valid)
            then
                frame_num := frame_num + 1;
                scanline_num := 0;
                bmp_fopen(bmp_file,
                          FILE_PREFIX & "_" & format_frame_num(frame_num, 5) & ".bmp",
                          WIDTH,
                          HEIGHT,
                          palette);
            elsif (not pixel_bus.frame_valid) and prev_frame_valid
            then
                bmp_fclose(bmp_file);
            end if;

            if pixel_bus.frame_valid
            then
                if pixel_bus.line_valid and not prev_line_valid
                then
                    scanline_num := scanline_num + 1;
                    pixel_num := 0;
                elsif (not pixel_bus.line_valid) and prev_line_valid
                then
                    scanline_num := scanline_num + 1;
                end if;

                if pixel_bus.line_valid
                then
                    pixel_val := "00" & pixel_bus.pixel;
                    bmp_fwrite(bmp_file, pixel_val);

                    pixel_num := pixel_num + 1;
                end if;
            end if;

            prev_frame_valid := pixel_bus.frame_valid;
            prev_line_valid := pixel_bus.line_valid;
        end loop;
    end process;

end behavioral;
