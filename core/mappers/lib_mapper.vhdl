library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_core.all;

use work.mapper_types.all;
use work.lib_mapper_220.all;

package lib_mapper is

    subtype mapper_num_t is std_logic_vector(11 downto 0);
    subtype submapper_num_t is std_logic_vector(3 downto 0);

    type mapper_reg_t is record
        mapper_num    : mapper_num_t;
        submapper_num : submapper_num_t;
        
        mapper_220_reg : mapper_220_reg_t;
    end record;
    
    constant RESET_MAPPER_REG : mapper_reg_t :=
    (
        mapper_num => (others => '0'),
        submapper_num => (others => '0'),
        
        mapper_220_reg => RESET_MAPPER_220_REG
    );
    
    type mapper_in_t is record
        reg    : mapper_reg_t;
        bus_in : mapper_bus_in_t;
    end record;
    
    type mapper_out_t is record
        reg     : mapper_reg_t;
        bus_out : mapper_bus_out_t;
    end record;
    
    function map_using_mapper(map_in : mapper_in_t) return mapper_out_t;

end package lib_mapper;

package body lib_mapper is

    function map_using_mapper(map_in : mapper_in_t) return mapper_out_t
    is
        variable map_out : mapper_out_t;
    
        variable mapper_220_in : mapper_220_in_t;
        variable mapper_220_out : mapper_220_out_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := MAPPER_BUS_IDLE;
        
        case map_in.reg.mapper_num is
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

end package body;