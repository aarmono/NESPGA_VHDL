library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;

use work.mapper_types.all;
use work.lib_mapper_000.all;
use work.lib_mapper_220.all;

package lib_mapper is

    type mapper_reg_t is record
        mapper_num    : mapper_num_t;
        common        : mapper_common_reg_t;
        
        mapper_220_reg : mapper_220_reg_t;
    end record;
    
    constant RESET_MAPPER_REG : mapper_reg_t :=
    (
        mapper_num => (others => '0'),
        common => RESET_MAPPER_COMMON_REG,
        
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
        
        variable mapper_000_in : ppu_mapper_000_in_t;
        variable mapper_000_out : ppu_mapper_000_out_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;
        
        case map_in.reg.mapper_num is
            -- NROM
            when x"000" =>
                mapper_000_in :=
                (
                    reg => map_in.reg.common,
                    bus_in => map_in.bus_in
                );
                
                mapper_000_out := ppu_map_using_mapper_000(mapper_000_in);
                
                map_out.bus_out := mapper_000_out.bus_out;
            when others =>
                null;
        end case;
        
        return map_out;
    end;

end package body;