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
use work.lib_mapper_001.all;
use work.lib_mapper_002.all;
use work.lib_mapper_003.all;
use work.lib_mapper_004.all;

package lib_mapper is

    type mapper_reg_t is record
        mapper_num    : mapper_num_t;
        common        : mapper_common_reg_t;

        write_prev    : boolean;
        
        mapper_001_reg : mapper_001_reg_t;
        mapper_002_reg : mapper_002_reg_t;
        mapper_003_reg : mapper_003_reg_t;
        mapper_004_reg : mapper_004_reg_t;
    end record;
    
    constant RESET_MAPPER_REG : mapper_reg_t :=
    (
        mapper_num => (others => '0'),
        common => RESET_MAPPER_COMMON_REG,

        write_prev => false,
        
        mapper_001_reg => RESET_MAPPER_001_REG,
        mapper_002_reg => RESET_MAPPER_002_REG,
        mapper_003_reg => RESET_MAPPER_003_REG,
        mapper_004_reg => RESET_MAPPER_004_REG
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
        irq     : boolean;
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

        variable mapper_001_in : cpu_mapper_001_in_t;
        variable mapper_001_out : cpu_mapper_001_out_t;

        variable mapper_002_in : cpu_mapper_002_in_t;
        variable mapper_002_out : cpu_mapper_002_out_t;

        variable mapper_003_in : cpu_mapper_003_in_t;
        variable mapper_003_out : cpu_mapper_003_out_t;

        variable mapper_004_in : cpu_mapper_004_in_t;
        variable mapper_004_out : cpu_mapper_004_out_t;
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
            -- MMC1
            when x"001" =>
                mapper_001_in :=
                (
                    common => map_in.reg.common,
                    reg    => map_in.reg.mapper_001_reg,
                    bus_in => map_in.bus_in
                );

                mapper_001_out := cpu_map_using_mapper_001(mapper_001_in);

                map_out.reg.mapper_001_reg := mapper_001_out.reg;
                map_out.bus_out := mapper_001_out.bus_out;
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
            -- CNROM
            when x"003" =>
                mapper_003_in :=
                (
                    common => map_in.reg.common,
                    reg    => map_in.reg.mapper_003_reg,
                    bus_in => map_in.bus_in
                );

                mapper_003_out := cpu_map_using_mapper_003(mapper_003_in);

                map_out.reg.mapper_003_reg := mapper_003_out.reg;
                map_out.bus_out := mapper_003_out.bus_out;
            -- MMC3
            when x"004" =>
                mapper_004_in :=
                (
                    common => map_in.reg.common,
                    reg    => map_in.reg.mapper_004_reg,
                    bus_in => map_in.bus_in
                );

                mapper_004_out := cpu_map_using_mapper_004(mapper_004_in);

                map_out.reg.mapper_004_reg := mapper_004_out.reg;
                map_out.bus_out := mapper_004_out.bus_out;
            when others =>
                assert false report "Mapper not supported: " &
                    integer'image(to_integer(map_in.reg.mapper_num))
                    severity failure;
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

        variable mapper_001_in : ppu_mapper_001_in_t;
        variable mapper_001_out : ppu_mapper_001_out_t;

        variable mapper_003_in : ppu_mapper_003_in_t;
        variable mapper_003_out : ppu_mapper_003_out_t;

        variable mapper_004_in : ppu_mapper_004_in_t;
        variable mapper_004_out : ppu_mapper_004_out_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;
        map_out.irq := false;
        
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
            -- MMC1
            when x"001" =>
                mapper_001_in :=
                (
                    common => map_in.reg.common,
                    reg    => map_in.reg.mapper_001_reg,
                    bus_in => map_in.bus_in
                );

                mapper_001_out := ppu_map_using_mapper_001(mapper_001_in);

                map_out.bus_out := mapper_001_out.bus_out;
            -- CNROM
            when x"003" =>
                mapper_003_in :=
                (
                    common => map_in.reg.common,
                    reg    => map_in.reg.mapper_003_reg,
                    bus_in => map_in.bus_in
                );

                mapper_003_out := ppu_map_using_mapper_003(mapper_003_in);

                map_out.bus_out := mapper_003_out.bus_out;
            -- MMC3
            when x"004" =>
                mapper_004_in :=
                (
                    common => map_in.reg.common,
                    reg    => map_in.reg.mapper_004_reg,
                    bus_in => map_in.bus_in
                );

                mapper_004_out := ppu_map_using_mapper_004(mapper_004_in);

                map_out.bus_out := mapper_004_out.bus_out;
                map_out.reg.mapper_004_reg := mapper_004_out.reg;
                map_out.irq := mapper_004_out.irq;
            when others =>
                assert false report "Mapper not supported: " &
                    integer'image(to_integer(map_in.reg.mapper_num))
                    severity failure;
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
        
        if is_bus_active(map_in.bus_in.chr_bus)
        then
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
                        map_out.bus_out.chr_ram_bus.address :=
                            get_chr_ram_addr(map_in.bus_in.chr_bus.address);
                        map_out.bus_out.chr_ram_bus.read :=
                            map_in.bus_in.chr_bus.read;
                        map_out.bus_out.chr_ram_bus.write :=
                            map_in.bus_in.chr_bus.write;

                        map_out.bus_out.data_to_ppu :=
                            map_in.bus_in.data_from_chr_ram;
                        map_out.bus_out.data_to_chr_ram :=
                            map_in.bus_in.data_from_ppu;
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
        end if;
        
        return map_out;
    end;

end package body;
