library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.chr_bus_types.all;
use work.nes_core.all;
use work.utilities.all;
use work.mapper_types.all;

package lib_mapper_000 is
    
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

end package lib_mapper_000;


package body lib_mapper_000 is
    
    function cpu_map_using_mapper_000
    (
        map_in : cpu_mapper_000_in_t
    )
    return cpu_mapper_000_out_t
    is
        variable map_out : cpu_mapper_000_out_t;
        variable file_offset : unsigned(file_addr_t'range);
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
                address := unsigned(map_in.bus_in.cpu_bus.address) - x"8000";
                if map_in.reg.has_trainer
                then
                    file_offset := resize(x"210", file_offset'length);
                else
                    file_offset := resize(x"10", file_offset'length);
                end if;
                
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
        variable file_offset : unsigned(file_addr_t'range);
    begin
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;
        
        case to_integer(map_in.bus_in.chr_bus.address) is
            when 16#0000# to 16#1FFF# =>
                if map_in.reg.has_trainer
                then
                    -- PRG ROM size: 16 KiB for NROM-128, 32 KiB for NROM-256
                    -- (DIP-28 standard pinout)
                    -- So only use 2 bits for block size
                    file_offset :=
                        resize(map_in.reg.prg_rom_16kb_blocks(1 downto 0) &
                               b"00_0010_0000_0000", file_offset'length);
                else
                    file_offset :=
                        resize(map_in.reg.prg_rom_16kb_blocks(1 downto 0) &
                               b"00_0000_0000_0000", file_offset'length);
                end if;
                
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
