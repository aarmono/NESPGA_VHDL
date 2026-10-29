library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
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

    constant WIDTH : dimension_t := to_unsigned(256, dimension_t'length);
    constant HEIGHT : dimension_t := to_unsigned(240, dimension_t'length);

    -- 2C02 values from the Mesen emulator
    constant PALETTE : palette_table_t :=
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

    -- Index of a pixel and its emphasis bits into EMPHASIS_PALETTE. The same
    -- layout as Mesen's 512 colour palette
    subtype color_idx_t is integer range 0 to 511;

    type emphasis_palette_t is array(color_idx_t) of bgr_t;

    function to_color_idx(emphasis : emphasis_t; pixel : pixel_t) return color_idx_t
    is
    begin
        return to_integer(std_logic_vector'(to_emphasis_bits(emphasis) &
                                            pixel));
    end;

    type channel_lsb_t is array(color_channel_t) of natural;
    -- Bit position of each colour channel in a bgr_t
    constant BGR_CHANNEL_LSB : channel_lsb_t :=
    (
        RED => 16,
        GREEN => 8,
        BLUE => 0
    );

    type channel_values_t is array(color_channel_t) of real;

    -- Attenuates a colour channel by Mesen's emphasis factor
    function attenuate(channel : real) return real
    is
    begin
        return channel * 0.84;
    end;

    function to_channel(channel : real) return std_logic_vector
    is
        variable ret : integer;
    begin
        -- Truncate rather than round, like Mesen does
        ret := integer(channel);
        if real(ret) > channel
        then
            ret := ret - 1;
        end if;

        return to_std_logic_vector(ret, 8);
    end;

    -- Builds the colours of all 8 emphasis combinations from PALETTE the same
    -- way Mesen does (NesDefaultVideoFilter::GenerateFullColorPalette). On
    -- the NTSC 2C02 each emphasis bit darkens the other two colour components,
    -- and columns $xE and $xF are not affected
    function make_emphasis_palette return emphasis_palette_t
    is
        variable ret : emphasis_palette_t;
        variable emphasis : emphasis_t;
        variable pixel : pixel_t;
        variable channels : channel_values_t;
        variable color : bgr_t;
        variable lsb : natural;
    begin
        for emphasis_bits in 0 to 2**emphasis_bits_t'length-1
        loop
            emphasis := to_emphasis_t(
                to_std_logic_vector(emphasis_bits, emphasis_bits_t'length));

            for pixel_idx in 0 to 2**pixel_t'length-1
            loop
                pixel := to_std_logic_vector(pixel_idx, pixel_t'length);

                for channel in color_channel_t
                loop
                    lsb := BGR_CHANNEL_LSB(channel);
                    channels(channel) := real(to_integer(
                        PALETTE(pixel_idx)(lsb+7 downto lsb)));
                end loop;

                if pixel(3 downto 1) /= "111"
                then
                    for emphasized in color_channel_t
                    loop
                        if emphasis(emphasized)
                        then
                            for channel in color_channel_t
                            loop
                                if channel /= emphasized
                                then
                                    channels(channel) :=
                                        attenuate(channels(channel));
                                end if;
                            end loop;
                        end if;
                    end loop;
                end if;

                color := (others => '0');
                for channel in color_channel_t
                loop
                    lsb := BGR_CHANNEL_LSB(channel);
                    color(lsb+7 downto lsb) := to_channel(channels(channel));
                end loop;

                ret(to_color_idx(emphasis, pixel)) := color;
            end loop;
        end loop;

        return ret;
    end;

    constant EMPHASIS_PALETTE : emphasis_palette_t := make_emphasis_palette;

    constant FRAME_PIXELS : positive :=
        to_integer(WIDTH) * to_integer(HEIGHT);

    type frame_t is array(0 to FRAME_PIXELS-1) of color_idx_t;

begin

    process
        file bmp_file : byte_file_t;

        variable frame_num : integer;
        variable scanline_num : integer;
        variable pixel_num : integer;

        variable prev_frame_valid : boolean;
        variable prev_line_valid : boolean;

        -- Frames are buffered and written when they end, since the format
        -- depends on whether any pixel in the frame uses emphasis
        variable frame : frame_t;
        variable frame_emphasis : boolean;

        variable pixel_val : pixel_idx_t;

    begin
        
        frame_num := 0;
        scanline_num := 0;
        pixel_num := 0;

        prev_frame_valid := false;
        prev_line_valid := false;

        frame_emphasis := false;

        while not done loop
            wait on clk until rising_edge(clk) and clk_en and ready;

            if pixel_bus.frame_valid and (not prev_frame_valid)
            then
                frame_num := frame_num + 1;
                scanline_num := 0;
                pixel_num := 0;
                frame_emphasis := false;
            elsif (not pixel_bus.frame_valid) and prev_frame_valid
            then
                -- Frames without emphasis are written as 8-bit indexed
                -- BMPs so that they don't depend on the emphasis palette.
                -- Only frames that use emphasis need 24-bit colour
                if frame_emphasis
                then
                    bmp_fopen_bgr(bmp_file,
                                  FILE_PREFIX & "_" & format_frame_num(frame_num, 5) & ".bmp",
                                  WIDTH,
                                  HEIGHT);
                    for i in 0 to pixel_num-1
                    loop
                        bmp_fwrite_bgr(bmp_file, EMPHASIS_PALETTE(frame(i)));
                    end loop;
                else
                    bmp_fopen_indexed(bmp_file,
                                      FILE_PREFIX & "_" & format_frame_num(frame_num, 5) & ".bmp",
                                      WIDTH,
                                      HEIGHT,
                                      PALETTE);
                    for i in 0 to pixel_num-1
                    loop
                        pixel_val := to_std_logic_vector(frame(i), 8);
                        bmp_fwrite_indexed(bmp_file, pixel_val);
                    end loop;
                end if;
                bmp_fclose(bmp_file);
            end if;

            if pixel_bus.frame_valid
            then
                if pixel_bus.line_valid and not prev_line_valid
                then
                    scanline_num := scanline_num + 1;
                elsif (not pixel_bus.line_valid) and prev_line_valid
                then
                    scanline_num := scanline_num + 1;
                end if;

                if pixel_bus.line_valid and pixel_num < FRAME_PIXELS
                then
                    frame(pixel_num) :=
                        to_color_idx(pixel_bus.emphasis, pixel_bus.pixel);
                    if pixel_bus.emphasis /= NO_EMPHASIS
                    then
                        frame_emphasis := true;
                    end if;

                    pixel_num := pixel_num + 1;
                end if;
            end if;

            prev_frame_valid := pixel_bus.frame_valid;
            prev_line_valid := pixel_bus.line_valid;
        end loop;
    end process;

end behavioral;
