library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.ppu_bus_types.all;
use work.prg_bus_types.all;
use work.utilities.all;

package nes_core is
    
    subtype data_t is std_logic_vector(7 downto 0);
    subtype audio_t is unsigned(3 downto 0);
    
    type apu_out_t is record
        square_1 : audio_t;
        square_2 : audio_t;
        triangle : audio_t;
        noise    : audio_t;
    end record;
    
    function is_ram_addr(addr : cpu_addr_t) return boolean;
    function get_ram_addr(addr : cpu_addr_t) return ram_addr_t;
    
    function is_ppu_addr(addr : cpu_addr_t) return boolean;
    function get_ppu_addr(addr : cpu_addr_t) return ppu_addr_t;
    
    function is_apu_addr(addr : cpu_addr_t) return boolean;
    function get_apu_addr(addr : cpu_addr_t) return apu_addr_t;
    
    function is_sram_addr(addr : cpu_addr_t) return boolean;
    function get_sram_addr(addr : cpu_addr_t) return sram_addr_t;
    
    --function is_prg_addr(addr : cpu_addr_t) return boolean;
    --function get_prg_addr(addr : cpu_addr_t) return prg_addr_t;
    
    component cpu is
    port
    (
        clk      : in  std_logic;
        reset    : in  boolean;
    
        data_bus : out cpu_bus_t;
        data_in  : in  data_t;
        data_out : out data_t;
    
        sync     : out boolean;
    
        ready    : in  boolean;
        nmi      : in  boolean;
        irq      : in  boolean
    );
    end component cpu;
    
    component apu is
    port
    (
        clk          : in  std_logic;
        reset        : in  boolean;

        cpu_bus      : in  apu_bus_t;
        cpu_data_in  : in  data_t;
        cpu_data_out : out data_t;

        audio        : out apu_out_t;

        irq          : out boolean
    );
    end component apu;

end nes_core;

package body nes_core is
    
    function is_ram_addr(addr : cpu_addr_t) return boolean
    is
    begin
        return addr < x"2000";
    end;
    
    function get_ram_addr(addr : cpu_addr_t) return ram_addr_t
    is
    begin
        return addr(ram_addr_t'RANGE);
    end;
    
    function is_ppu_addr(addr : cpu_addr_t) return boolean
    is
    begin
        return addr >= x"2000" and addr < x"4000";
    end;
    
    function get_ppu_addr(addr : cpu_addr_t) return ppu_addr_t
    is
    begin
        return addr(ppu_addr_t'RANGE);
    end;
    
    function is_apu_addr(addr : cpu_addr_t) return boolean
    is
    begin
        return addr >= x"4000" and addr < x"4020";
    end;
    
    function get_apu_addr(addr : cpu_addr_t) return apu_addr_t
    is
    begin
        return addr(apu_addr_t'RANGE);
    end;
    
    function is_sram_addr(addr : cpu_addr_t) return boolean
    is
    begin
        return addr >= x"6000" and addr < x"8000";
    end;
    
    function get_sram_addr(addr : cpu_addr_t) return sram_addr_t
    is
    begin
        return addr(sram_addr_t'RANGE);
    end;
    
end package body;
