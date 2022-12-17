library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;

use work.cpu_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.ppu_bus_types.all;
use work.chr_bus_types.all;
use work.ciram_bus_types.all;
use work.palette_bus_types.all;
use work.joy_bus_types.all;

package mapper_types is

    subtype mapper_num_t is std_logic_vector(11 downto 0);
    subtype submapper_num_t is std_logic_vector(3 downto 0);
    subtype rom_blocks_t is unsigned(7 downto 0);
    subtype mirror_t is std_logic_vector(1 downto 0);
    subtype file_off_t is unsigned(file_addr_t'range);

    type mapper_common_reg_t is record
        submapper_num       : submapper_num_t;
        prg_rom_16kb_blocks : rom_blocks_t;
        chr_rom_8kb_blocks  : rom_blocks_t;
        mirror              : mirror_t;
        has_prg_ram         : boolean;
        has_trainer         : boolean;
    end record;
    
    constant RESET_MAPPER_COMMON_REG : mapper_common_reg_t :=
    (
        submapper_num => (others => '0'),
        prg_rom_16kb_blocks => (others => '0'),
        chr_rom_8kb_blocks => (others => '0'),
        mirror => (others => '0'),
        has_prg_ram => false,
        has_trainer => false
    );

    -- The complete set of bus inputs for
    -- NES CPU memory mapping
    type cpu_mmap_bus_in_t is record
        cpu_bus : cpu_bus_t;

        clk_sync : boolean;
        
        data_from_cpu  : data_t;
        data_from_apu  : data_t;
        data_from_joy  : data_t;
        data_from_ram  : data_t;
        data_from_sram : data_t;
        data_from_ppu  : data_t;
        data_from_file : data_t;
    end record;
    
    -- The complete set of bus outputs for
    -- NES CPU memory mapping
    type cpu_mmap_bus_out_t is record
        apu_bus       : apu_bus_t;
        joy_bus       : joy_bus_t;
        ram_bus       : ram_bus_t;
        sram_bus      : sram_bus_t;
        ppu_bus       : ppu_bus_t;
        oam_dma_write : boolean;
        file_bus      : file_bus_t;
        
        data_to_cpu     : data_t;
        data_to_apu     : data_t;
        data_to_joy     : data_t;
        data_to_ram     : data_t;
        data_to_sram    : data_t;
        data_to_ppu     : data_t;
    end record;
    
    constant CPU_MMAP_BUS_IDLE : cpu_mmap_bus_out_t :=
    (
        apu_bus => APU_BUS_IDLE,
        joy_bus => JOY_BUS_IDLE,
        ram_bus => RAM_BUS_IDLE,
        SRAM_BUS => SRAM_BUS_IDLE,
        PPU_BUS => PPU_BUS_IDLE,
        oam_dma_write => false,
        FILE_BUS => FILE_BUS_IDLE,
        
        data_to_cpu => (others => '-'),
        data_to_apu => (others => '-'),
        data_to_joy => (others => '-'),
        data_to_ram => (others => '-'),
        data_to_sram => (others => '-'),
        data_to_ppu => (others => '-')
    );

    -- The set of CPU bus inputs needed
    -- by a cartridge mapper
    type cpu_mapper_bus_in_t is record
        cpu_bus : cpu_bus_t;

        clk_sync    : boolean;
        first_write : boolean;
        
        data_from_cpu  : data_t;
        data_from_sram : data_t;
        data_from_file : data_t;
    end record;
    
    -- The set of CPU bus outputs generated
    -- by a cartridge mapper
    type cpu_mapper_bus_out_t is record
        sram_bus : sram_bus_t;
        file_bus : file_bus_t;
        
        data_to_cpu  : data_t;
        data_to_sram : data_t;
    end record;
    
    constant CPU_MAPPER_BUS_IDLE : cpu_mapper_bus_out_t :=
    (
        sram_bus => SRAM_BUS_IDLE,
        file_bus => FILE_BUS_IDLE,
        
        data_to_cpu => (others => '-'),
        data_to_sram => (others => '-')
    );
    
    function cpu_mmap_in_to_mapper_in
    (
        mmap_in    : cpu_mmap_bus_in_t;
        prev_write : boolean
    )
    return cpu_mapper_bus_in_t;
    
    function cpu_mapper_out_to_mmap_out
    (
        mapper_out : cpu_mapper_bus_out_t
    )
    return cpu_mmap_bus_out_t;
    
    -- The complete set of bus inputs for
    -- NES PPU memory mapping
    type ppu_mmap_bus_in_t is record
        chr_bus : chr_bus_t;
        
        data_from_ppu     : data_t;
        data_from_file    : data_t;
        data_from_chr_ram : data_t;
        data_from_ciram   : data_t;
    end record;
    
    -- The complete set of bus outputs for
    -- NES PPU memory mapping
    type ppu_mmap_bus_out_t is record
        chr_ram_bus : sram_bus_t;
        ciram_bus   : ciram_bus_t;
        file_bus    : file_bus_t;
        
        data_to_ppu     : data_t;
        data_to_chr_ram : data_t;
        data_to_ciram   : data_t;
    end record;
    
    constant PPU_MMAP_BUS_IDLE : ppu_mmap_bus_out_t :=
    (
        chr_ram_bus => SRAM_BUS_IDLE,
        ciram_bus => CIRAM_BUS_IDLE,
        file_bus => FILE_BUS_IDLE,
        
        data_to_ppu => (others => '-'),
        data_to_chr_ram => (others => '-'),
        data_to_ciram => (others => '-')
    );
    
    type ppu_mapper_bus_in_t is record
        chr_bus : chr_bus_t;
        
        data_from_ppu     : data_t;
        data_from_file    : data_t;
        data_from_chr_ram : data_t;
        data_from_ciram   : data_t;
    end record;
    
    type ppu_mapper_bus_out_t is record
        chr_ram_bus : sram_bus_t;
        ciram_bus   : ciram_bus_t;
        file_bus    : file_bus_t;
        
        data_to_ppu     : data_t;
        data_to_chr_ram : data_t;
        data_to_ciram   : data_t;
    end record;
    
    constant PPU_MAPPER_BUS_IDLE : ppu_mapper_bus_out_t :=
    (
        chr_ram_bus => SRAM_BUS_IDLE,
        ciram_bus => CIRAM_BUS_IDLE,
        file_bus => FILE_BUS_IDLE,
        
        data_to_ppu => (others => '-'),
        data_to_chr_ram => (others => '-'),
        data_to_ciram => (others => '-')
    );
    
    function ppu_mmap_in_to_mapper_in
    (
        mmap_in : ppu_mmap_bus_in_t
    )
    return ppu_mapper_bus_in_t;
    
    function ppu_mapper_out_to_mmap_out
    (
        mapper_out : ppu_mapper_bus_out_t
    )
    return ppu_mmap_bus_out_t;

    function get_mirrored_address
    (
        chr_addr : chr_addr_t;
        mirror   : mirror_t
    )
    return ciram_addr_t;
    
    function get_ram_addr(addr : cpu_addr_t) return ram_addr_t;
    
    function get_ppu_addr(addr : cpu_addr_t) return ppu_addr_t;
    
    function get_apu_addr(addr : cpu_addr_t) return apu_addr_t;

    function get_joy_addr(addr : cpu_addr_t) return joy_addr_t;
    
    function get_sram_addr(addr : cpu_addr_t) return sram_addr_t;
    
    function get_palette_addr(addr : chr_addr_t) return palette_addr_t;

    function get_chr_ram_addr(addr : chr_addr_t) return sram_addr_t;

    function get_file_offset
    (
        offset_16kb : rom_blocks_t;
        has_trainer : boolean
    )
    return file_off_t;

end package mapper_types;


package body mapper_types is

    function cpu_mmap_in_to_mapper_in
    (
        mmap_in    : cpu_mmap_bus_in_t;
        prev_write : boolean
    )
    return cpu_mapper_bus_in_t
    is
        variable mapper_in : cpu_mapper_bus_in_t;
    begin
        mapper_in.cpu_bus := mmap_in.cpu_bus;
        mapper_in.clk_sync := mmap_in.clk_sync;
        mapper_in.first_write := mmap_in.cpu_bus.write and not prev_write;
        mapper_in.data_from_cpu := mmap_in.data_from_cpu;
        mapper_in.data_from_sram := mmap_in.data_from_sram;
        mapper_in.data_from_file := mmap_in.data_from_file;
        
        return mapper_in;
    end;
    
    function cpu_mapper_out_to_mmap_out
    (
        mapper_out : cpu_mapper_bus_out_t
    )
    return cpu_mmap_bus_out_t
    is
        variable mmap_out : cpu_mmap_bus_out_t;
    begin
        mmap_out := CPU_MMAP_BUS_IDLE;
        mmap_out.sram_bus := mapper_out.sram_bus;
        mmap_out.file_bus := mapper_out.file_bus;
        
        mmap_out.data_to_cpu := mapper_out.data_to_cpu;
        mmap_out.data_to_sram := mapper_out.data_to_sram;
        
        return mmap_out;
    end;
    
    function ppu_mmap_in_to_mapper_in
    (
        mmap_in : ppu_mmap_bus_in_t
    )
    return ppu_mapper_bus_in_t
    is
        variable mapper_in : ppu_mapper_bus_in_t;
    begin
        mapper_in.chr_bus := mmap_in.chr_bus;
        mapper_in.data_from_ppu := mmap_in.data_from_ppu;
        mapper_in.data_from_file := mmap_in.data_from_file;
        mapper_in.data_from_chr_ram := mmap_in.data_from_chr_ram;
        mapper_in.data_from_ciram := mmap_in.data_from_ciram;
        
        return mapper_in;
    end;
    
    function ppu_mapper_out_to_mmap_out
    (
        mapper_out : ppu_mapper_bus_out_t
    )
    return ppu_mmap_bus_out_t
    is
        variable mmap_out : ppu_mmap_bus_out_t;
    begin
        mmap_out := PPU_MMAP_BUS_IDLE;
        mmap_out.chr_ram_bus := mapper_out.chr_ram_bus;
        mmap_out.ciram_bus := mapper_out.ciram_bus;
        mmap_out.file_bus := mapper_out.file_bus;
        
        mmap_out.data_to_ppu := mapper_out.data_to_ppu;
        mmap_out.data_to_chr_ram := mapper_out.data_to_chr_ram;
        mmap_out.data_to_ciram := mapper_out.data_to_ciram;
        
        return mmap_out;
    end;

    function get_mirrored_address
    (
        chr_addr : chr_addr_t;
        mirror   : mirror_t
    )
    return ciram_addr_t
    is
        variable mirrored_addr : ciram_addr_t;
        -- CIRAM is 2KB, starting at address 0x2000
        constant MIRROR_MASK : ciram_addr_t := b"0111_1111_1111";
    begin
        if mirror(1) = '1'
        then
            mirrored_addr := chr_addr(ciram_addr_t'range);
        else
            mirrored_addr := chr_addr(ciram_addr_t'range) and MIRROR_MASK;
            if mirror(0) = '0'
            then
                -- Horizontal mirror (CIRAM A10 = PPU A11)
                mirrored_addr(10) := chr_addr(11);
            end if;
        end if;

        return mirrored_addr;
    end;
    
    function get_ram_addr(addr : cpu_addr_t) return ram_addr_t
    is
    begin
        return addr(ram_addr_t'RANGE);
    end;
    
    function get_ppu_addr(addr : cpu_addr_t) return ppu_addr_t
    is
    begin
        return addr(ppu_addr_t'RANGE);
    end;
    
    function get_apu_addr(addr : cpu_addr_t) return apu_addr_t
    is
    begin
        return addr(apu_addr_t'RANGE);
    end;

    function get_joy_addr(addr : cpu_addr_t) return joy_addr_t
    is
    begin
        return addr(joy_addr_t'RANGE);
    end;
    
    function get_sram_addr(addr : cpu_addr_t) return sram_addr_t
    is
    begin
        return addr(sram_addr_t'RANGE);
    end;
    
    function get_palette_addr(addr : chr_addr_t) return palette_addr_t
    is
    begin
        return addr(palette_addr_t'RANGE);
    end;

    function get_chr_ram_addr(addr : chr_addr_t) return sram_addr_t
    is
    begin
        return addr(sram_addr_t'range);
    end;

    function get_file_offset
    (
        offset_16kb : rom_blocks_t;
        has_trainer : boolean
    )
    return file_off_t
    is
        variable ret : file_off_t;
    begin
        ret := offset_16kb(5 downto 0) &
               "0000" &
               to_std_logic(has_trainer) &
               b"0_0001_0000";
        
        return ret;
    end;

end package body;
