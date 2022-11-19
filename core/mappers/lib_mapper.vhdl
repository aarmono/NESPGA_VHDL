library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;

use work.chr_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;

use work.mapper_types.all;
use work.lib_mapper_000.all;
use work.lib_mapper_002.all;
use work.lib_mapper_220.all;

package lib_mapper is

    type mapper_reg_t is record
        mapper_num    : mapper_num_t;
        common        : mapper_common_reg_t;
        
        mapper_002_reg : mapper_002_reg_t;
        mapper_220_reg : mapper_220_reg_t;
    end record;
    
    constant RESET_MAPPER_REG : mapper_reg_t :=
    (
        mapper_num => (others => '0'),
        common => RESET_MAPPER_COMMON_REG,
        
        mapper_002_reg => RESET_MAPPER_002_REG,
        mapper_220_reg => RESET_MAPPER_220_REG
    );
    
    type cpu_mapper_in_t is record
        reg    : mapper_reg_t;
        bus_in : cpu_mapper_bus_in_t;
    end record;
    
    type cpu_mapper_out_t is record
        reg     : mapper_reg_t;
        bus_out : cpu_mapper_bus_out_t;
    end record;
    
    function map_cpu_using_mapper
    (
        map_in : cpu_mapper_in_t
    )
    return cpu_mapper_out_t;
    
    type ppu_mapper_in_t is record
        reg    : mapper_reg_t;
        bus_in : ppu_mapper_bus_in_t;
    end record;
    
    type ppu_mapper_out_t is record
        reg     : mapper_reg_t;
        bus_out : ppu_mapper_bus_out_t;
    end record;
    
    function map_ppu_using_mapper
    (
        map_in : ppu_mapper_in_t
    )
    return ppu_mapper_out_t;

    type ppu_mapper_def_in_t is record
        common : mapper_common_reg_t;
        bus_in : ppu_mapper_bus_in_t;
    end record;
    
    type ppu_mapper_def_out_t is record
        bus_out : ppu_mapper_bus_out_t;
    end record;

    function ppu_map_using_mapper_def
    (
        map_in : ppu_mapper_def_in_t
    )
    return ppu_mapper_def_out_t;

    function get_mirrored_address
    (
        chr_addr : chr_addr_t;
        mirror   : mirror_t
    )
    return chr_addr_t;

end package lib_mapper;

package body lib_mapper is

    function map_cpu_using_mapper
    (
        map_in : cpu_mapper_in_t
    )
    return cpu_mapper_out_t
    is
        variable map_out : cpu_mapper_out_t;
    
        variable mapper_000_in : cpu_mapper_000_in_t;
        variable mapper_000_out : cpu_mapper_000_out_t;

        variable mapper_002_in : cpu_mapper_002_in_t;
        variable mapper_002_out : cpu_mapper_002_out_t;
    
        variable mapper_220_in : mapper_220_in_t;
        variable mapper_220_out : mapper_220_out_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := CPU_MAPPER_BUS_IDLE;
        
        case map_in.reg.mapper_num is
            -- NROM
            when x"000" =>
                mapper_000_in :=
                (
                    reg => map_in.reg.common,
                    bus_in => map_in.bus_in
                );
                
                mapper_000_out := cpu_map_using_mapper_000(mapper_000_in);
                
                map_out.bus_out := mapper_000_out.bus_out;
            -- UxROM
            when x"002" =>
                mapper_002_in :=
                (
                    common => map_in.reg.common,
                    reg    => map_in.reg.mapper_002_reg,
                    bus_in => map_in.bus_in
                );
                
                mapper_002_out := cpu_map_using_mapper_002(mapper_002_in);
                
                map_out.reg.mapper_002_reg := mapper_002_out.reg;
                map_out.bus_out := mapper_002_out.bus_out;
            -- NSF pseudo-mapper
            when x"0DC" =>
                mapper_220_in :=
                (
                    reg => map_in.reg.mapper_220_reg,
                    bus_in => map_in.bus_in
                );
                
                mapper_220_out := map_using_mapper_220(mapper_220_in);
                
                map_out.reg.mapper_220_reg := mapper_220_out.reg;
                map_out.bus_out := mapper_220_out.bus_out;
            when others =>
                assert false report "Mapper not supported: " &
                    integer'image(to_integer(map_in.reg.mapper_num))
                    severity failure;
                null;
        end case;
    
        return map_out;
    end;
    
    function map_ppu_using_mapper
    (
        map_in : ppu_mapper_in_t
    )
    return ppu_mapper_out_t
    is
        variable map_out : ppu_mapper_out_t;
        
        variable mapper_def_in : ppu_mapper_def_in_t;
        variable mapper_def_out : ppu_mapper_def_out_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;
        
        case map_in.reg.mapper_num is
            -- NROM
            -- UxROM
            when x"000" |
                 x"002" =>
                mapper_def_in :=
                (
                    common => map_in.reg.common,
                    bus_in => map_in.bus_in
                );
                
                mapper_def_out := ppu_map_using_mapper_def(mapper_def_in);
                
                map_out.bus_out := mapper_def_out.bus_out;
            when others =>
                null;
        end case;
        
        return map_out;
    end;

    function ppu_map_using_mapper_def
    (
        map_in : ppu_mapper_def_in_t
    )
    return ppu_mapper_def_out_t
    is
        variable map_out : ppu_mapper_def_out_t;
        
        variable address : unsigned(chr_addr_t'range);
        variable file_offset : file_off_t;
    begin
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;
        
        case to_integer(map_in.bus_in.chr_bus.address) is
            when 16#0000# to 16#1FFF# =>
                if not is_zero(map_in.common.chr_rom_8kb_blocks)
                    then
                    file_offset :=
                        get_file_offset(map_in.common.prg_rom_16kb_blocks,
                                        map_in.common.has_trainer);
                    
                    address := unsigned(map_in.bus_in.chr_bus.address);
                    map_out.bus_out.file_bus := bus_read(address + file_offset);
                    map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_file;
                else
                    map_out.bus_out.ciram_bus := map_in.bus_in.chr_bus;

                    map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_ciram;
                    map_out.bus_out.data_to_ciram := map_in.bus_in.data_from_ppu;
                end if;
            when 16#2000# to 16#3FFF# =>
                map_out.bus_out.ciram_bus.address :=
                    get_mirrored_address(map_in.bus_in.chr_bus.address,
                                         map_in.common.mirror);

                map_out.bus_out.ciram_bus.read := map_in.bus_in.chr_bus.read;
                map_out.bus_out.ciram_bus.write := map_in.bus_in.chr_bus.write;
                map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_ciram;
                map_out.bus_out.data_to_ciram := map_in.bus_in.data_from_ppu;
            when others =>
                null;
        end case;
        
        return map_out;
    end;

    function get_mirrored_address
    (
        chr_addr : chr_addr_t;
        mirror   : mirror_t
    )
    return chr_addr_t
    is
        variable mirrored_addr : chr_addr_t;
        -- CIRAM is 2KB, starting at address 0x2000
        constant MIRROR_MASK : chr_addr_t := b"10_0111_1111_1111";
        constant QUAD_MASK : chr_addr_t := b"10_1111_1111_1111";
    begin
        if mirror(1) = '1'
        then
            mirrored_addr := chr_addr and QUAD_MASK;
        else
            mirrored_addr := chr_addr and MIRROR_MASK;
            if mirror(0) = '0'
            then
                -- Horizontal mirror (CIRAM A10 = PPU A11)
                mirrored_addr(10) := chr_addr(11);
            end if;
        end if;

        return mirrored_addr;
    end;

end package body;
