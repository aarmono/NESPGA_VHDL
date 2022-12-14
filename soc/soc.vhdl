library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.file_bus_types.all;
use work.ciram_bus_types.all;
use work.nes_types.all;

package soc is

    component nsf_soc is
    port
    (
        clk_50mhz : in std_logic;
        reset_in  : in boolean;
        
        reset_out : out boolean;
        
        next_stb : in std_logic;
        prev_stb : in std_logic;
        
        file_bus       : out file_bus_t;
        data_from_file : in data_t;

        cpu_ram_en : out boolean;
        
        sram_bus       : out sram_bus_t;
        data_to_sram   : out data_t;
        data_from_sram : in data_t;
        
        ram_bus       : out ram_bus_t;
        data_to_ram   : out data_t;
        data_from_ram : in data_t;
        
        enable_square_1 : in boolean := true;
        enable_square_2 : in boolean := true;
        enable_triangle : in boolean := true;
        enable_noise    : in boolean := true;
        enable_dmc      : in boolean := true;
        
        audio : out mixed_audio_t
    );
    end component nsf_soc;

    component nsf_soc_ocram is
    port
    (
        clk_50mhz : in std_logic;
        reset_in  : in boolean;
        
        reset_out : out boolean;
        
        next_stb : in std_logic;
        prev_stb : in std_logic;
        
        file_bus       : out file_bus_t;
        data_from_file : in data_t;
        
        enable_square_1 : in boolean := true;
        enable_square_2 : in boolean := true;
        enable_triangle : in boolean := true;
        enable_noise    : in boolean := true;
        enable_dmc      : in boolean := true;
        
        audio : out mixed_audio_t
    );
    end component nsf_soc_ocram;
    
    component nes_soc is
    port
    (
        clk_50mhz : in std_logic;
        reset     : in boolean;

        nes_running : out boolean;

        cpu_clk_en : out boolean;
        ppu_clk_en : out boolean;

        cpu_ram_en : out boolean;
        ppu_ram_en : out boolean;
        
        file_bus       : out file_bus_t;
        data_from_file : in data_t;
        
        prg_ram_bus       : out ram_bus_t;
        data_to_prg_ram   : out data_t;
        data_from_prg_ram : in data_t;
        
        oam_bus       : out oam_bus_t;
        data_to_oam   : out data_t;
        data_from_oam : in data_t;
        
        sec_oam_bus       : out sec_oam_bus_t;
        data_to_sec_oam   : out data_t;
        data_from_sec_oam : in data_t;
        
        palette_bus       : out palette_bus_t;
        data_to_palette   : out pixel_t;
        data_from_palette : in pixel_t;
        
        chr_ram_bus       : out sram_bus_t;
        data_to_chr_ram   : out data_t;
        data_from_chr_ram : in data_t;

        ciram_bus       : out ciram_bus_t;
        data_to_ciram   : out data_t;
        data_from_ciram : in data_t;
        
        pixel_bus : out pixel_bus_t;
        audio     : out mixed_audio_t;

        joy_strobe : out std_logic;

        shift_joy_1 : out std_logic;
        joy_1_val   : in std_logic := '1';

        shift_joy_2 : out std_logic;
        joy_2_val   : in std_logic := '1'
    );
    end component nes_soc;

    -- Variant of nes_soc that uses on-chip RAM
    component nes_soc_ocram is
    generic
    (
        USE_EXT_SRAM : boolean := false
    );
    port
    (
        clk_50mhz : in std_logic;
        reset     : in boolean;

        nes_running : out boolean;

        cpu_clk_en : out boolean;
        ppu_clk_en : out boolean;

        cpu_ram_en : out boolean;

        file_bus       : out file_bus_t;
        data_from_file : in data_t;
        
        sram_bus       : out sram_bus_t;
        data_to_sram   : out data_t;
        data_from_sram : in data_t := (others => '-');

        pixel_bus : out pixel_bus_t;
        audio     : out mixed_audio_t;

        joy_strobe : out std_logic;

        shift_joy_1 : out std_logic;
        joy_1_val   : in std_logic := '1';

        shift_joy_2 : out std_logic;
        joy_2_val   : in std_logic := '1'
    );
    end component nes_soc_ocram;

end soc;

package body soc is

end package body;