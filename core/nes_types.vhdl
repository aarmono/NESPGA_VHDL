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

    subtype mixed_audio_t is unsigned(7 downto 0);
    
    subtype pixel_t is std_logic_vector(5 downto 0);

    -- Colour emphasis bits ($2001 bits 5-7). Bit 0 is red, bit 1 green and
    -- bit 2 blue on the NTSC 2C02 (PAL and Dendy swap red and green)
    subtype emphasis_t is std_logic_vector(2 downto 0);
    
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

end nes_types;

package body nes_types is
    
end package body;
