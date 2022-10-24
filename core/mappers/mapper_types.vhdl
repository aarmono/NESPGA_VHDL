library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_core.all;

use work.cpu_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.ppu_bus_types.all;

package mapper_types is

    -- The complete set of bus inputs for
    -- NES memory mapping
    type mmap_bus_in_t is record
        cpu_bus : cpu_bus_t;
        
        data_from_cpu  : data_t;
        data_from_apu  : data_t;
        data_from_ram  : data_t;
        data_from_sram : data_t;
        data_from_ppu  : data_t;
        data_from_file : data_t;
    end record;
    
    -- The complete set of bus outputs for
    -- NES memory mapping
    type mmap_bus_out_t is record
        apu_bus  : apu_bus_t;
        ram_bus  : ram_bus_t;
        sram_bus : sram_bus_t;
        ppu_bus  : ppu_bus_t;
        file_bus : file_bus_t;
        
        data_to_cpu  : data_t;
        data_to_apu  : data_t;
        data_to_ram  : data_t;
        data_to_sram : data_t;
        data_to_ppu  : data_t;
    end record;
    
    constant MMAP_BUS_IDLE : mmap_bus_out_t :=
    (
        apu_bus => APU_BUS_IDLE,
        ram_bus => RAM_BUS_IDLE,
        SRAM_BUS => SRAM_BUS_IDLE,
        PPU_BUS => PPU_BUS_IDLE,
        FILE_BUS => FILE_BUS_IDLE,
        
        data_to_cpu => (others => '-'),
        data_to_apu => (others => '-'),
        data_to_ram => (others => '-'),
        data_to_sram => (others => '-'),
        data_to_ppu => (others => '-')
    );

    -- The set of CPU bus inputs needed
    -- by a cartridge mapper
    type mapper_bus_in_t is record
        cpu_bus : cpu_bus_t;
        
        data_from_cpu  : data_t;
        data_from_sram : data_t;
        data_from_file : data_t;
    end record;
    
    -- The set of CPU bus outputs generated
    -- by a cartridge mapper
    type mapper_bus_out_t is record
        sram_bus : sram_bus_t;
        file_bus : file_bus_t;
        
        data_to_cpu  : data_t;
        data_to_sram : data_t;
    end record;
    
    constant MAPPER_BUS_IDLE : mapper_bus_out_t :=
    (
        sram_bus => SRAM_BUS_IDLE,
        file_bus => FILE_BUS_IDLE,
        
        data_to_cpu => (others => '-'),
        data_to_sram => (others => '-')
    );
    
    function mmap_in_to_mapper_in(mmap_in : mmap_bus_in_t) return mapper_bus_in_t;
    
    function mapper_out_to_mmap_out
    (
        mapper_out : mapper_bus_out_t
    )
    return mmap_bus_out_t;

end package mapper_types;


package body mapper_types is

    function mmap_in_to_mapper_in(mmap_in : mmap_bus_in_t) return mapper_bus_in_t
    is
        variable mapper_in : mapper_bus_in_t;
    begin
        mapper_in.cpu_bus := mmap_in.cpu_bus;
        mapper_in.data_from_cpu := mmap_in.data_from_cpu;
        mapper_in.data_from_sram := mmap_in.data_from_sram;
        mapper_in.data_from_file := mmap_in.data_from_file;
        
        return mapper_in;
    end;
    
    function mapper_out_to_mmap_out
    (
        mapper_out : mapper_bus_out_t
    )
    return mmap_bus_out_t
    is
        variable mmap_out : mmap_bus_out_t;
    begin
        mmap_out := MMAP_BUS_IDLE;
        mmap_out.sram_bus := mapper_out.sram_bus;
        mmap_out.file_bus := mapper_out.file_bus;
        
        mmap_out.data_to_cpu := mapper_out.data_to_cpu;
        mmap_out.data_to_sram := mapper_out.data_to_sram;
        
        return mmap_out;
    end;

end package body;