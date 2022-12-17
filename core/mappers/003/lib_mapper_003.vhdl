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

package lib_mapper_003 is

    subtype bank_t is unsigned(7 downto 0);

    type mapper_003_reg_t is record
        bank : bank_t;
    end record;

    constant RESET_MAPPER_003_REG : mapper_003_reg_t :=
    (
        bank => (others => '0')
    );

    type cpu_mapper_003_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_003_reg_t;
        bus_in : cpu_mapper_bus_in_t;
    end record;
    
    type cpu_mapper_003_out_t is record
        reg     : mapper_003_reg_t;
        bus_out : cpu_mapper_bus_out_t;
    end record;
    
    function cpu_map_using_mapper_003
    (
        map_in : cpu_mapper_003_in_t
    )
    return cpu_mapper_003_out_t;

    type ppu_mapper_003_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_003_reg_t;
        bus_in : ppu_mapper_bus_in_t;
    end record;

    type ppu_mapper_003_out_t is record
        bus_out : ppu_mapper_bus_out_t;
    end record;

    function ppu_map_using_mapper_003
    (
        map_in : ppu_mapper_003_in_t
    )
    return ppu_mapper_003_out_t;

end package lib_mapper_003;


package body lib_mapper_003 is

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
    
    function cpu_map_using_mapper_003
    (
        map_in : cpu_mapper_003_in_t
    )
    return cpu_mapper_003_out_t
    is
        variable map_out : cpu_mapper_003_out_t;

        variable file_offset : file_off_t;
        variable address : unsigned(cpu_addr_t'range);
    begin
        
        map_out.bus_out := CPU_MAPPER_BUS_IDLE;
        map_out.reg := map_in.reg;

        file_offset := get_file_offset(x"00", map_in.common.has_trainer);

        case to_integer(map_in.bus_in.cpu_bus.address) is
            when 16#8000# to 16#FFFF# =>
                if is_bus_write(map_in.bus_in.cpu_bus) and map_in.bus_in.clk_sync
                then
                    map_out.reg.bank := unsigned(map_in.bus_in.data_from_cpu);
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    address := get_cpu_prg_addr(map_in.bus_in.cpu_bus.address,
                                                map_in.common.prg_rom_16kb_blocks);
                    
                    map_out.bus_out.file_bus := bus_read(address + file_offset);
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
                end if;
            when others =>
                map_out.bus_out.data_to_cpu := (others => '0');
        end case;
        
        return map_out;
    end;

    function ppu_map_using_mapper_003
    (
        map_in : ppu_mapper_003_in_t
    )
    return ppu_mapper_003_out_t
    is
        variable map_out : ppu_mapper_003_out_t;
        
        variable bus_address : unsigned(chr_addr_t'range);
        variable bank_offset : unsigned(12 downto 0);
        variable address : file_off_t;
        variable file_offset : file_off_t;

        variable max_bank : bank_t;
        variable mod_bank : bank_t;
    begin
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;

        if is_bus_active(map_in.bus_in.chr_bus)
        then
            case to_integer(map_in.bus_in.chr_bus.address) is
                when 16#0000# to 16#1FFF# =>
                    if not is_zero(map_in.common.chr_rom_8kb_blocks)
                    then
                        max_bank := map_in.common.chr_rom_8kb_blocks - "1";
                        file_offset :=
                            get_file_offset(map_in.common.prg_rom_16kb_blocks,
                                            map_in.common.has_trainer);
                        
                        mod_bank := max_bank and map_in.reg.bank;
                        bus_address := unsigned(map_in.bus_in.chr_bus.address);
                        bank_offset := unsigned(bus_address(bank_offset'range));

                        address := resize(mod_bank(3 downto 0) & bank_offset,
                                          address'length);
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
