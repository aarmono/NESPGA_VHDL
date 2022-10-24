library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.ppu_bus_types.all;
use work.file_bus_types.all;
use work.nes_core.all;
use work.utilities.all;
use work.mapper_types.all;
use work.lib_mapper.all;

package lib_nes_mmap is
    
    type mmap_in_t is record
        reg    : mapper_reg_t;
        bus_in : mmap_bus_in_t;
    end record;
    
    type mmap_out_t is record
        reg     : mapper_reg_t;
        bus_out : mmap_bus_out_t;
    end record;
    
    function mmap_cpu_memory(map_in : mmap_in_t) return mmap_out_t;

end package lib_nes_mmap;


package body lib_nes_mmap is
    
    function mmap_cpu_memory(map_in : mmap_in_t) return mmap_out_t
    is
        variable map_out : mmap_out_t;
        variable mapper_in : mapper_in_t;
        variable mapper_out : mapper_out_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := MMAP_BUS_IDLE;
        
        if is_bus_active(map_in.bus_in.cpu_bus)
        then
            case? map_in.bus_in.cpu_bus.address is
                -- RAM
                when x"0---" |
                     x"1---" =>
                    map_out.bus_out.ram_bus.address :=
                        get_ram_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.ram_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.ram_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_ram;
                    map_out.bus_out.data_to_ram := map_in.bus_in.data_from_cpu;
                -- PPU
                when x"2---" |
                     x"3---" =>
                    map_out.bus_out.ppu_bus.address :=
                        get_ppu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.ppu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.ppu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_ppu;
                    map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_cpu;
                -- APU
                when x"400-" |
                     x"401-" =>
                    map_out.bus_out.apu_bus.address :=
                        get_apu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.apu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.apu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_apu;
                    map_out.bus_out.data_to_apu := map_in.bus_in.data_from_cpu;
                when others =>
                    mapper_in.reg := map_in.reg;
                    mapper_in.bus_in := mmap_in_to_mapper_in(map_in.bus_in);
                    
                    mapper_out := map_using_mapper(mapper_in);
                    
                    map_out.reg := mapper_out.reg;
                    map_out.bus_out := mapper_out_to_mmap_out(mapper_out.bus_out);
            end case?;
        end if;
        
        return map_out;
    end;

end package body;