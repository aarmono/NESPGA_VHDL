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
        variable address : natural range 0 to 16#FFFF#;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := CPU_MMAP_BUS_IDLE;
        
        if is_bus_active(map_in.bus_in.cpu_bus)
        then
            address := to_integer(map_in.bus_in.cpu_bus.address);
            case address is
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
                when 16#4000# to 16#4013# =>
                    map_out.bus_out.apu_bus.address :=
                        get_apu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.apu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.apu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    -- Write-only registers
                    map_out.bus_out.data_to_cpu := map_in.reg.open_bus;
                    map_out.bus_out.data_to_apu := map_in.bus_in.data_from_cpu;
                when 16#4015# =>
                    map_out.bus_out.apu_bus.address :=
                        get_apu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.apu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.apu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    -- Bit 5 is open bus
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_apu;
                    map_out.bus_out.data_to_cpu(5) := map_in.reg.open_bus(5);
                    map_out.bus_out.data_to_apu := map_in.bus_in.data_from_cpu;
                when 16#4014# =>
                    if is_bus_write(map_in.bus_in.cpu_bus)
                    then
                        map_out.bus_out.oam_dma_write := true;
                        -- HACK since DMA and CPU data busses are shared
                        map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_cpu;
                    else
                        -- Write-only register
                        map_out.bus_out.data_to_cpu := map_in.reg.open_bus;
                    end if;
                when 16#4016# =>
                    map_out.bus_out.joy_bus.address :=
                        get_joy_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.joy_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.joy_bus.write := map_in.bus_in.cpu_bus.write;

                    map_out.bus_out.data_to_cpu :=
                        map_in.reg.open_bus(7 downto 5) &
                        map_in.bus_in.data_from_joy(4 downto 0);
                    map_out.bus_out.data_to_joy := map_in.bus_in.data_from_cpu;
                when 16#4017# =>
                    if is_bus_read(map_in.bus_in.cpu_bus)
                    then
                        map_out.bus_out.joy_bus.address :=
                            get_joy_addr(map_in.bus_in.cpu_bus.address);
                        map_out.bus_out.joy_bus.read := map_in.bus_in.cpu_bus.read;
                        map_out.bus_out.joy_bus.write := map_in.bus_in.cpu_bus.write;

                        map_out.bus_out.data_to_cpu :=
                            map_in.reg.open_bus(7 downto 5) &
                            map_in.bus_in.data_from_joy(4 downto 0);
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
                -- CPU test mode registers
                when 16#4018# to 16#401F# =>
                    map_out.bus_out.data_to_cpu := map_in.reg.open_bus;
                when others =>
                    mapper_in.reg := map_in.reg;
                    mapper_in.bus_in :=
                        cpu_mmap_in_to_mapper_in(map_in.bus_in,
                                                 map_in.reg.write_prev,
                                                 map_in.reg.open_bus);
                    
                    mapper_out := map_cpu_using_mapper(mapper_in);
                    
                    map_out.reg := mapper_out.reg;
                    map_out.bus_out :=
                        cpu_mapper_out_to_mmap_out(mapper_out.bus_out);
            end case;
        end if;
        
        if map_in.bus_in.clk_sync
        then
            map_out.reg.write_prev := map_in.bus_in.cpu_bus.write;

            if is_bus_write(map_in.bus_in.cpu_bus)
            then
                map_out.reg.open_bus := map_in.bus_in.data_from_cpu;
            -- 0x4015 is internal to the CPU
            elsif is_bus_read(map_in.bus_in.cpu_bus) and
                  address /= 16#4015#
            then
                map_out.reg.open_bus := map_out.bus_out.data_to_cpu;
            end if;
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
