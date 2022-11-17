library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.ppu_bus_types.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.nes_types.all;
use work.utilities.all;

package nes_core is
    
    component cpu is
    port
    (
        clk      : in  std_logic;
        clk_en   : in  boolean := true;
        reset    : in  boolean;
    
        cpu_bus       : out cpu_bus_t;
        data_to_cpu   : in  data_t;
        data_from_cpu : out data_t;
    
        sync     : out boolean;
    
        ready    : in  boolean;
        nmi      : in  boolean;
        irq      : in  boolean
    );
    end component cpu;
    
    component apu is
    port
    (
        clk           : in  std_logic;
        clk_en        : in  boolean := true;
        reset         : in  boolean;

        cpu_bus       : in  apu_bus_t;
        data_to_apu   : in  data_t;
        data_from_apu : out data_t;

        audio         : out apu_out_t;

        dma_bus       : out cpu_bus_t;
        irq           : out boolean;
        ready         : out boolean
    );
    end component apu;
    
    component ppu is
    port
    (
        clk               : in std_logic;
        clk_en            : in boolean := true;
        clk_sync          : in boolean := true;
        reset             : in boolean;

        chr_bus           : out chr_bus_t;
        chr_data_from_ppu : out data_t;
        chr_data_to_ppu   : in  data_t;
        
        oam_bus           : out oam_bus_t;
        data_to_oam       : out data_t;
        data_from_oam     : in data_t;
        
        sec_oam_bus       : out sec_oam_bus_t;
        data_to_sec_oam   : out data_t;
        data_from_sec_oam : in data_t;
        
        palette_bus       : out palette_bus_t;
        data_to_palette   : out data_t;
        data_from_palette : in data_t;
        
        cpu_bus           : in  ppu_bus_t;
        prg_data_from_ppu : out data_t;
        prg_data_to_ppu   : in  data_t;

        pixel_bus         : out pixel_bus_t;
        vint              : out boolean
    );
    end component ppu;
    
    component oam_dma is
    port
    (
        clk            : in std_logic;
        clk_en         : in boolean := true;
        reset          : in boolean;
        
        write_from_cpu : in boolean;
        data_to_dma    : in data_t;
        
        dma_bus         : out cpu_bus_t;
        data_from_dma   : out data_t;
        
        ready           : out boolean
    );
    end component oam_dma;
    
    component clk_en is
    port
    (
        clk_50mhz : in std_logic;
        reset     : in boolean;
        
        cpu_en    : out boolean;
        ppu_en    : out boolean;
        nsf_en    : out boolean;

        ppu_sync  : out boolean
    );
    end component clk_en;

end nes_core;

package body nes_core is
    
end package body;
