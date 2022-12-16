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

package lib_mapper_002 is
    
    subtype bank_t is unsigned(3 downto 0);
    subtype prg_rom_addr_t is unsigned(17 downto 0);

    type mapper_002_reg_t is record
        bank : bank_t;
    end record;

    constant RESET_MAPPER_002_REG : mapper_002_reg_t :=
    (
        bank => (others => '0')
    );

    type cpu_mapper_002_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_002_reg_t;
        bus_in : cpu_mapper_bus_in_t;
    end record;
    
    type cpu_mapper_002_out_t is record
        reg     : mapper_002_reg_t;
        bus_out : cpu_mapper_bus_out_t;
    end record;
    
    function cpu_map_using_mapper_002
    (
        map_in : cpu_mapper_002_in_t
    )
    return cpu_mapper_002_out_t;
    
    function get_cpu_prg_addr
    (
        addr_in : cpu_addr_t;
        bank    : bank_t
    )
    return prg_rom_addr_t;

end package lib_mapper_002;


package body lib_mapper_002 is
    
    function get_cpu_prg_addr
    (
        addr_in : cpu_addr_t;
        bank    : bank_t
    )
    return prg_rom_addr_t
    is
        variable ret : prg_rom_addr_t;
        variable bank_addr : unsigned(cpu_addr_t'range);
    begin
        bank_addr := unsigned(addr_in);
        ret := bank & bank_addr(13 downto 0);
        
        return ret;
    end;
    
    function cpu_map_using_mapper_002
    (
        map_in : cpu_mapper_002_in_t
    )
    return cpu_mapper_002_out_t
    is
        variable map_out : cpu_mapper_002_out_t;
        variable file_offset : file_off_t;
        variable prg_address : prg_rom_addr_t;
        variable int_address : integer;
        variable bank : bank_t;
    begin
        
        map_out.bus_out := CPU_MAPPER_BUS_IDLE;
        map_out.reg := map_in.reg;
        int_address := to_integer(map_in.bus_in.cpu_bus.address);

        case int_address is
            when 16#8000# to 16#FFFF# =>
                if is_bus_write(map_in.bus_in.cpu_bus) and map_in.bus_in.clk_sync
                then
                    if map_in.common.prg_rom_16kb_blocks > x"08"
                    then
                        map_out.reg.bank :=
                            unsigned(map_in.bus_in.data_from_cpu(3 downto 0));
                    else
                        map_out.reg.bank :=
                            '0' & unsigned(map_in.bus_in.data_from_cpu(2 downto 0));
                    end if;
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    case int_address is
                        when 16#8000# to 16#BFFF# =>
                            bank := map_in.reg.bank;
                        when 16#C000# to 16#FFFF# =>
                            bank :=
                                map_in.common.prg_rom_16kb_blocks(bank_t'range) - "1";
                        when others =>
                            bank := (others => '-');
                    end case;

                    prg_address :=
                        get_cpu_prg_addr(map_in.bus_in.cpu_bus.address, bank);
                    file_offset :=
                        get_file_offset(x"00", map_in.common.has_trainer);
                
                    map_out.bus_out.file_bus := bus_read(prg_address + file_offset);
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
                end if;
            when others =>
                map_out.bus_out.data_to_cpu := (others => '0');
        end case;
        
        return map_out;
    end;

end package body;
