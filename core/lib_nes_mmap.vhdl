library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.ppu_bus_types.all;
use work.file_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.mapper_types.all;
use work.lib_mapper.all;

package lib_nes_mmap is
    
    type cpu_mmap_in_t is record
        reg    : mapper_reg_t;
        bus_in : cpu_mmap_bus_in_t;
    end record;
    
    type cpu_mmap_out_t is record
        reg     : mapper_reg_t;
        bus_out : cpu_mmap_bus_out_t;
    end record;
    
    function mmap_cpu_memory(map_in : cpu_mmap_in_t) return cpu_mmap_out_t;
    
    type ppu_mmap_in_t is record
        reg    : mapper_reg_t;
        bus_in : ppu_mmap_bus_in_t;
    end record;
    
    type ppu_mmap_out_t is record
        reg     : mapper_reg_t;
        bus_out : ppu_mmap_bus_out_t;
        irq     : boolean;
    end record;
    
    function mmap_ppu_memory(map_in : ppu_mmap_in_t) return ppu_mmap_out_t;

end package lib_nes_mmap;


package body lib_nes_mmap is
    
    function mmap_cpu_memory(map_in : cpu_mmap_in_t) return cpu_mmap_out_t
    is
        variable map_out : cpu_mmap_out_t;
        variable mapper_in : cpu_mapper_in_t;
        variable mapper_out : cpu_mapper_out_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := CPU_MMAP_BUS_IDLE;
        
        if is_bus_active(map_in.bus_in.cpu_bus)
        then
            case to_integer(map_in.bus_in.cpu_bus.address) is
                -- RAM
                when 16#0000# to 16#1FFF# =>
                    map_out.bus_out.ram_bus.address :=
                        get_ram_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.ram_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.ram_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_ram;
                    map_out.bus_out.data_to_ram := map_in.bus_in.data_from_cpu;
                -- PPU
                when 16#2000# to 16#3FFF# =>
                    map_out.bus_out.ppu_bus.address :=
                        get_ppu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.ppu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.ppu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_ppu;
                    map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_cpu;
                -- APU
                when 16#4000# to 16#4013# |
                     16#4015#             |
                     16#4018# to 16#401F# =>
                    map_out.bus_out.apu_bus.address :=
                        get_apu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.apu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.apu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_apu;
                    map_out.bus_out.data_to_apu := map_in.bus_in.data_from_cpu;
                when 16#4014# =>
                    map_out.bus_out.oam_dma_write := true;
                    -- HACK since DMA and CPU data busses are shared
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_cpu;
                when 16#4016# =>
                    map_out.bus_out.joy_bus.address :=
                        get_joy_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.joy_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.joy_bus.write := map_in.bus_in.cpu_bus.write;

                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_joy;
                    map_out.bus_out.data_to_joy := map_in.bus_in.data_from_cpu;
                when 16#4017# =>
                    -- TODO: implement joystick
                    if is_bus_read(map_in.bus_in.cpu_bus)
                    then
                        map_out.bus_out.joy_bus.address :=
                            get_joy_addr(map_in.bus_in.cpu_bus.address);
                        map_out.bus_out.joy_bus.read := map_in.bus_in.cpu_bus.read;
                        map_out.bus_out.joy_bus.write := map_in.bus_in.cpu_bus.write;

                        map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_joy;
                        map_out.bus_out.data_to_joy := map_in.bus_in.data_from_cpu;
                    elsif is_bus_write(map_in.bus_in.cpu_bus)
                    then
                        map_out.bus_out.apu_bus.address :=
                            get_apu_addr(map_in.bus_in.cpu_bus.address);
                        map_out.bus_out.apu_bus.read := map_in.bus_in.cpu_bus.read;
                        map_out.bus_out.apu_bus.write := map_in.bus_in.cpu_bus.write;
                        
                        map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_apu;
                        map_out.bus_out.data_to_apu := map_in.bus_in.data_from_cpu;
                    end if;
                when others =>
                    mapper_in.reg := map_in.reg;
                    mapper_in.bus_in := cpu_mmap_in_to_mapper_in(map_in.bus_in);
                    
                    mapper_out := map_cpu_using_mapper(mapper_in);
                    
                    map_out.reg := mapper_out.reg;
                    map_out.bus_out :=
                        cpu_mapper_out_to_mmap_out(mapper_out.bus_out);
            end case;
        end if;
        
        return map_out;
    end;
    
    function mmap_ppu_memory(map_in : ppu_mmap_in_t) return ppu_mmap_out_t
    is
        variable map_out : ppu_mmap_out_t;
        variable mapper_in : ppu_mapper_in_t;
        variable mapper_out : ppu_mapper_out_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := PPU_MMAP_BUS_IDLE;
        
        mapper_in.reg := map_in.reg;
        mapper_in.bus_in := ppu_mmap_in_to_mapper_in(map_in.bus_in);
        
        mapper_out := map_ppu_using_mapper(mapper_in);
        map_out.bus_out :=
            ppu_mapper_out_to_mmap_out(mapper_out.bus_out);
        map_out.reg := mapper_out.reg;
        map_out.irq := mapper_out.irq;
        
        return map_out;
    end;

end package body;
