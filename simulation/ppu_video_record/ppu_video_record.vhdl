library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.binary_io.all;
use work.bmp_file.all;

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

        constant palette : palette_table_t :=
        (
            --  84  84  84
            x"00545454",
            --   0  30 116
            x"00001E74",
            --   8  16 144
            x"00081090",
            --  48   0 136
            x"00300088",
            --  68   0 100
            x"00440064",
            --  92   0  48
            x"005C0030",
            --  84   4   0
            x"00540400",
            --  60  24   0
            x"003C1800",
            --  32  42   0
            x"00202A00",
            --   8  58   0
            x"00083A00",
            --   0  64   0
            x"00004000",
            --   0  60   0
            x"00003C00",
            --   0  50  60
            x"0000323C",
            --   0   0   0
            x"00000000",
            -- 152 150 152
            x"00989698",
            --   8  76 196
            x"00084CC4",
            --  48  50 236
            x"003032EC",
            --  92  30 228
            x"005C1EE4",
            -- 136  20 176
            x"008814B0",
            -- 160  20 100
            x"00A01464",
            -- 152  34  32
            x"00982220",
            -- 120  60   0
            x"00783C00",
            --  84  90   0
            x"00545A00",
            --  40 114   0
            x"00287200",
            --   8 124   0
            x"00087C00",
            --   0 118  40
            x"00007628",
            --   0 102 120
            x"00006678",
            --   0   0   0
            x"00000000",
            -- 236 238 236
            x"00ECEEEC",
            --  76 154 236
            x"004C9AEC",
            -- 120 124 236
            x"00787CEC",
            -- 176  98 236
            x"00B062EC",
            -- 228  84 236
            x"00E454EC",
            -- 236  88 180
            x"00EC58B4",
            -- 236 106 100
            x"00EC6A64",
            -- 212 136  32
            x"00D48820",
            -- 160 170   0
            x"00A0AA00",
            -- 116 196   0
            x"0074C400",
            --  76 208  32
            x"004CD020",
            --  56 204 108
            x"0038CC6C",
            --  56 180 204
            x"0038B4CC",
            --  60  60  60
            x"003C3C3C",
            -- 236 238 236
            x"00ECEEEC",
            -- 168 204 236
            x"00A8CCEC",
            -- 188 188 236
            x"00BCBCEC",
            -- 212 178 236
            x"00D4B2EC",
            -- 236 174 236
            x"00ECAEEC",
            -- 236 174 212
            x"00ECAED4",
            -- 236 180 176
            x"00ECB4B0",
            -- 228 196 144
            x"00E4C490",
            -- 204 210 120
            x"00CCD278",
            -- 180 222 120
            x"00B4DE78",
            -- 168 226 144
            x"00A8E290",
            -- 152 226 180
            x"0098E2B4",
            -- 160 214 228
            x"00A0D6E4",
            -- 160 162 160
            x"00A0A2A0",
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
                          FILE_PREFIX & "_" & integer'image(frame_num) & ".bmp",
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
