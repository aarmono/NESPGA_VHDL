library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

package nes_types is
    
    subtype data_t is std_logic_vector(7 downto 0);
    subtype audio_t is natural range 0 to 15;
    subtype dmc_audio_t is natural range 0 to 127;
    
    type apu_out_t is record
        square_1 : audio_t;
        square_2 : audio_t;
        triangle : audio_t;
        noise    : audio_t;
        dmc      : dmc_audio_t;
    end record;

    -- The level of the audio from the cartridge, in the units of the mixed
    -- audio, where the APU at its loudest is 255. Boards without audio of
    -- their own output 0
    subtype cart_audio_t is natural range 0 to 2**10-1-255;

    -- The APU with a quarter of the range and the cartridge audio with the
    -- rest
    subtype mixed_audio_t is unsigned(9 downto 0);
    
    subtype pixel_t is std_logic_vector(5 downto 0);

    -- Colour channels in the order of the emphasis bits ($2001 bits 5-7) on
    -- the NTSC 2C02. PAL and Dendy PPUs swap red and green
    type color_channel_t is (RED, GREEN, BLUE);

    -- True for each colour channel whose emphasis bit is set
    type emphasis_t is array(color_channel_t) of boolean;
    constant NO_EMPHASIS : emphasis_t := (others => false);

    -- Emphasis bits as they are in $2001 bits 5-7: red is the LSB
    subtype emphasis_bits_t is std_logic_vector(2 downto 0);
    
    type palette_t is array(0 to 16#1F#) of pixel_t;
    
    type ram_t is array(0 to 16#7FF#) of data_t;
    type vram_t is array(0 to 16#3FFF#) of data_t;
    type sram_t is array(0 to 16#1FFF#) of data_t;
    type oam_t is array(0 to 16#FF#) of data_t;
    type sec_oam_t is array(0 to 16#1F#) of data_t;
    
    type pixel_bus_t is record
        pixel       : pixel_t;
        emphasis    : emphasis_t;
        line_valid  : boolean;
        frame_valid : boolean;
    end record;
    
    type oam_dma_status_t is record
        active     : boolean;
        read_cycle : boolean;
    end record;

    function to_emphasis_t(bits : emphasis_bits_t) return emphasis_t;
    function to_emphasis_bits(emphasis : emphasis_t) return emphasis_bits_t;

end nes_types;

package body nes_types is

    function to_emphasis_t(bits : emphasis_bits_t) return emphasis_t
    is
        variable ret : emphasis_t;
    begin
        for channel in color_channel_t
        loop
            ret(channel) := bits(color_channel_t'pos(channel)) = '1';
        end loop;

        return ret;
    end;

    function to_emphasis_bits(emphasis : emphasis_t) return emphasis_bits_t
    is
        variable ret : emphasis_bits_t;
    begin
        for channel in color_channel_t
        loop
            ret(color_channel_t'pos(channel)) := to_std_logic(emphasis(channel));
        end loop;

        return ret;
    end;

end package body;
