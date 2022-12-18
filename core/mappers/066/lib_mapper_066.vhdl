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

package lib_mapper_066 is
    
    type mapper_066_reg_t is record
        prg_bank : unsigned(1 downto 0);
        chr_bank : unsigned(1 downto 0);
    end record;

    constant RESET_MAPPER_066_REG : mapper_066_reg_t :=
    (
        prg_bank => (others => '0'),
        chr_bank => (others => '0')
    );

    type cpu_mapper_066_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_066_reg_t;
        bus_in : cpu_mapper_bus_in_t;
    end record;
    
    type cpu_mapper_066_out_t is record
        reg     : mapper_066_reg_t;
        bus_out : cpu_mapper_bus_out_t;
    end record;
    
    function cpu_map_using_mapper_066
    (
        map_in : cpu_mapper_066_in_t
    )
    return cpu_mapper_066_out_t;

    type ppu_mapper_066_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_066_reg_t;
        bus_in : ppu_mapper_bus_in_t;
    end record;

    type ppu_mapper_066_out_t is record
        bus_out : ppu_mapper_bus_out_t;
    end record;

    function ppu_map_using_mapper_066
    (
        map_in : ppu_mapper_066_in_t
    )
    return ppu_mapper_066_out_t;


end package lib_mapper_066;


package body lib_mapper_066 is
    
    function cpu_map_using_mapper_066
    (
        map_in : cpu_mapper_066_in_t
    )
    return cpu_mapper_066_out_t
    is
        variable map_out : cpu_mapper_066_out_t;
        
        variable file_offset : file_off_t;
        variable address : unsigned(16 downto 0);

        variable num_banks : rom_blocks_t;
        variable max_bank : unsigned(1 downto 0);
    begin
        
        map_out.bus_out := CPU_MAPPER_BUS_IDLE;
        map_out.reg := map_in.reg;

        num_banks := shift_right(map_in.common.prg_rom_16kb_blocks, 1);
        max_bank := resize(num_banks - "1", max_bank'length);
        
        file_offset := get_file_offset(x"00", map_in.common.has_trainer);

        case to_integer(map_in.bus_in.cpu_bus.address) is
            when 16#8000# to 16#FFFF# =>
                if is_bus_write(map_in.bus_in.cpu_bus) and map_in.bus_in.clk_sync
                then
                    map_out.reg.chr_bank :=
                        unsigned(map_in.bus_in.data_from_cpu(1 downto 0));
                    map_out.reg.prg_bank :=
                        unsigned(map_in.bus_in.data_from_cpu(5 downto 4));
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    address :=
                        (map_in.reg.prg_bank and max_bank) &
                        unsigned(map_in.bus_in.cpu_bus.address(14 downto 0));
                    
                    map_out.bus_out.file_bus := bus_read(address + file_offset);
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
                end if;
            when others =>
                map_out.bus_out.data_to_cpu := (others => '0');
        end case;
        
        return map_out;
    end;

    function ppu_map_using_mapper_066
    (
        map_in : ppu_mapper_066_in_t
    )
    return ppu_mapper_066_out_t
    is
        variable map_out : ppu_mapper_066_out_t;
        
        variable address : unsigned(14 downto 0);
        variable file_offset : file_off_t;

        variable max_bank : unsigned(1 downto 0);
    begin
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;
        
        file_offset := get_file_offset(map_in.common.prg_rom_16kb_blocks,
                                       map_in.common.has_trainer);
        max_bank := resize(map_in.common.chr_rom_8kb_blocks - "1",
                           max_bank'length);

        if is_bus_active(map_in.bus_in.chr_bus)
        then
            case to_integer(map_in.bus_in.chr_bus.address) is
                when 16#0000# to 16#1FFF# =>
                    address := (map_in.reg.chr_bank and max_bank) &
                               unsigned(map_in.bus_in.chr_bus.address(12 downto 0));
                    map_out.bus_out.file_bus := bus_read(address + file_offset);
                    map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_file;
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
