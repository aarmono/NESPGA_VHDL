library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.ram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.cart_mem_bus_types.all;
use work.ciram_bus_types.all;
use work.chip_ram_bus_types.all;
use work.opll_bus_types.all;
use work.nes_types.all;
use work.perhipheral_types.all;
use work.cart_types.all;

package soc is
    
    component nes_soc is
    generic
    (
        CART_BOARDS  : board_set_t := ALL_BOARDS;
        CLK_FREQ     : positive := 50_000_000;
        CPU_FREQ_NUM : positive := 39_375_000;
        CPU_FREQ_DEN : positive := 22
    );
    port
    (
        clk   : in std_logic;
        reset : in boolean;

        nes_running : out boolean;

        cpu_clk_en : out boolean;
        ppu_clk_en : out boolean;

        cpu_ram_en : out boolean;
        ppu_ram_en : out boolean;
        
        cart_mem_bus       : out cart_mem_bus_t;
        data_to_cart_mem   : out data_t;
        data_from_cart_mem : in data_t;
        
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
        
        ciram_bus       : out ciram_bus_t;
        data_to_ciram   : out data_t;
        data_from_ciram : in data_t;

        -- RAM inside the mapper chip
        chip_ram_bus       : out chip_ram_bus_t;
        data_to_chip_ram   : out data_t;
        data_from_chip_ram : in data_t;

        opll_ram_bus       : out opll_ram_bus_t;
        data_to_opll_ram   : out opll_ram_data_t;
        data_from_opll_ram : in opll_ram_data_t;
        
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
        USE_EXT_CART_RAM : boolean := false;
        VENDOR           : vendor_t := VENDOR_ALTERA;
        CLK_FREQ         : positive := 50_000_000;
        CPU_FREQ_NUM     : positive := 39_375_000;
        CPU_FREQ_DEN     : positive := 22;
        CART_BOARDS      : board_set_t := ALL_BOARDS
    );
    port
    (
        clk   : in std_logic;
        reset : in boolean;

        nes_running : out boolean;

        cpu_clk_en : out boolean;
        ppu_clk_en : out boolean;

        cart_mem_bus       : out cart_mem_bus_t;
        data_to_cart_mem   : out data_t;
        data_from_cart_mem : in data_t;

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