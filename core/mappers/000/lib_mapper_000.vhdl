library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.mapper_types.all;

package lib_mapper_000 is
    
    subtype file_off_t is unsigned(file_addr_t'range);
    
    type cpu_mapper_000_in_t is record
        reg    : mapper_common_reg_t;
        bus_in : cpu_mapper_bus_in_t;
    end record;
    
    type cpu_mapper_000_out_t is record
        bus_out : cpu_mapper_bus_out_t;
    end record;
    
    type ppu_mapper_000_in_t is record
        reg    : mapper_common_reg_t;
        bus_in : ppu_mapper_bus_in_t;
    end record;
    
    type ppu_mapper_000_out_t is record
        bus_out : ppu_mapper_bus_out_t;
    end record;
    
    function cpu_map_using_mapper_000
    (
        map_in : cpu_mapper_000_in_t
    )
    return cpu_mapper_000_out_t;
    
    function ppu_map_using_mapper_000
    (
        map_in : ppu_mapper_000_in_t
    )
    return ppu_mapper_000_out_t;
    
    function get_file_offset
    (
        offset_16kb : rom_blocks_t;
        has_trainer : boolean
    )
    return file_off_t;
    
    function get_cpu_prg_addr
    (
        addr_in       : cpu_addr_t;
        rom_size_16kb : rom_blocks_t
    )
    return unsigned;

end package lib_mapper_000;


package body lib_mapper_000 is
    
    function get_file_offset
    (
        offset_16kb : rom_blocks_t;
        has_trainer : boolean
    )
    return file_off_t
    is
        variable ret : unsigned(15 downto 0);
    begin
        ret := offset_16kb(1 downto 0) &
               "0000" &
               to_std_logic(has_trainer) &
               b"0_0001_0000";
        
        return resize(ret, file_off_t'length);
    end;
    
    function get_cpu_prg_addr
    (
        addr_in       : cpu_addr_t;
        rom_size_16kb : rom_blocks_t
    )
    return unsigned
    is
        variable ret  : unsigned(cpu_addr_t'range);
        variable mask : unsigned(cpu_addr_t'range);
    begin
        mask := (rom_size_16kb(1 downto 0) - "1") & b"11_1111_1111_1111";
        ret := (unsigned(addr_in) - x"8000") and mask;
        
        return ret;
    end;
    
    function cpu_map_using_mapper_000
    (
        map_in : cpu_mapper_000_in_t
    )
    return cpu_mapper_000_out_t
    is
        variable map_out : cpu_mapper_000_out_t;
        variable file_offset : file_off_t;
        variable address : unsigned(cpu_addr_t'range);
    begin
        
        map_out.bus_out := CPU_MAPPER_BUS_IDLE;
        
        case to_integer(map_in.bus_in.cpu_bus.address) is
            when 16#6000# to 16#7FFF# =>
                map_out.bus_out.sram_bus.address :=
                    get_sram_addr(map_in.bus_in.cpu_bus.address);
                map_out.bus_out.sram_bus.read := map_in.bus_in.cpu_bus.read;
                map_out.bus_out.sram_bus.write := map_in.bus_in.cpu_bus.write;
                
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_sram;
                map_out.bus_out.data_to_sram := map_in.bus_in.data_from_cpu;
            when 16#8000# to 16#FFFF# =>
                address := get_cpu_prg_addr(map_in.bus_in.cpu_bus.address,
                                            map_in.reg.prg_rom_16kb_blocks);
                file_offset := get_file_offset(x"00", map_in.reg.has_trainer);
                
                map_out.bus_out.file_bus := bus_read(address + file_offset);
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
            when others =>
                null;
        end case;
        
        return map_out;
    end;
    
    function ppu_map_using_mapper_000
    (
        map_in : ppu_mapper_000_in_t
    )
    return ppu_mapper_000_out_t
    is
        variable map_out : ppu_mapper_000_out_t;
        
        variable address : unsigned(chr_addr_t'range);
        variable file_offset : file_off_t;
    begin
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;
        
        case to_integer(map_in.bus_in.chr_bus.address) is
            when 16#0000# to 16#1FFF# =>
                file_offset :=
                    get_file_offset(map_in.reg.prg_rom_16kb_blocks,
                                    map_in.reg.has_trainer);
                
                address := unsigned(map_in.bus_in.chr_bus.address);
                map_out.bus_out.file_bus := bus_read(address + file_offset);
                map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_file;
            when 16#2000# to 16#3FFF# =>
                if map_in.reg.mirror(0) = '0'
                then
                    -- Horizontal mirror (CIRAM A10 = PPU A11)
                    map_out.bus_out.ciram_bus.address(10) :=
                        map_in.bus_in.chr_bus.address(11);
                    map_out.bus_out.ciram_bus.address(9 downto 0) :=
                        map_in.bus_in.chr_bus.address(9 downto 0);
                else
                    -- Vertical mirror (CIRAM A10 = PPU A10)
                    map_out.bus_out.ciram_bus.address :=
                        map_in.bus_in.chr_bus.address(ram_addr_t'range);
                end if;
                
                map_out.bus_out.ciram_bus.read := map_in.bus_in.chr_bus.read;
                map_out.bus_out.ciram_bus.write := map_in.bus_in.chr_bus.write;
                map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_ciram;
                map_out.bus_out.data_to_ciram := map_in.bus_in.data_from_ppu;
            when others =>
                null;
        end case;
        
        return map_out;
    end;

end package body;
