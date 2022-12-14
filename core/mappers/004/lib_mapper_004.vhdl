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

package lib_mapper_004 is
    
    subtype bank_idx_t is unsigned(2 downto 0);

    subtype bank_t is unsigned(7 downto 0);
    type bank_arr_t is array(0 to 7) of bank_t;

    subtype irq_count_t is unsigned(7 downto 0);

    subtype prg_rom_addr_t is unsigned(18 downto 0);
    subtype chr_rom_addr_t is unsigned(17 downto 0);

    subtype a12_count_t is unsigned(2 downto 0);
    constant A12_MAX : a12_count_t := to_unsigned(6, a12_count_t'length);

    type mapper_004_reg_t is record
        bank_idx : bank_idx_t;

        banks : bank_arr_t;

        chr_mode : std_logic;
        prg_mode : std_logic;

        mirroring : std_logic;

        irq_count  : irq_count_t;
        irq_reload : irq_count_t;
        irq_enable : boolean;
        irq        : boolean;

        a12_count : a12_count_t;
    end record;

    constant RESET_MAPPER_004_REG : mapper_004_reg_t :=
    (
        bank_idx => (others => '0'),

        banks => (others => (others => '0')),

        chr_mode => '0',
        prg_mode => '0',

        mirroring => '0',

        irq_count => (others => '0'),
        irq_reload => (others => '0'),
        irq_enable => false,
        irq => false,

        a12_count => (others => '0')
    );

    type cpu_mapper_004_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_004_reg_t;
        bus_in : cpu_mapper_bus_in_t;
    end record;
    
    type cpu_mapper_004_out_t is record
        reg     : mapper_004_reg_t;
        bus_out : cpu_mapper_bus_out_t;
    end record;
    
    function cpu_map_using_mapper_004
    (
        map_in : cpu_mapper_004_in_t
    )
    return cpu_mapper_004_out_t;

    type ppu_mapper_004_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_004_reg_t;
        bus_in : ppu_mapper_bus_in_t;
    end record;

    type ppu_mapper_004_out_t is record
        reg     : mapper_004_reg_t;
        bus_out : ppu_mapper_bus_out_t;
        irq     : boolean;
    end record;

    function ppu_map_using_mapper_004
    (
        map_in : ppu_mapper_004_in_t
    )
    return ppu_mapper_004_out_t;

    function ppu_map_using_mapper_004_rom
    (
        reg         : mapper_004_reg_t;
        mirror      : mirror_t;
        num_banks   : bank_t;
        file_offset : file_off_t;
        bus_in      : ppu_mapper_bus_in_t
    )
    return ppu_mapper_bus_out_t;

    function ppu_map_using_mapper_004_ram
    (
        mirror : mirror_t;
        bus_in : ppu_mapper_bus_in_t
    )
    return ppu_mapper_bus_out_t;
    
    function get_cpu_prg_addr
    (
        addr_in   : cpu_addr_t;
        bank      : bank_t;
        num_banks : bank_t
    )
    return prg_rom_addr_t;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : bank_t;
        num_banks : bank_t
    )
    return chr_rom_addr_t;

end package lib_mapper_004;


package body lib_mapper_004 is
    
    function get_cpu_prg_addr
    (
        addr_in   : cpu_addr_t;
        bank      : bank_t;
        num_banks : bank_t
    )
    return prg_rom_addr_t
    is
        variable ret : prg_rom_addr_t;
        variable bank_addr : unsigned(cpu_addr_t'range);
        variable mod_bank : bank_t;
    begin
        mod_bank := bank and (num_banks - "1");

        bank_addr := unsigned(addr_in);
        ret := mod_bank(5 downto 0) & bank_addr(12 downto 0);
        
        return ret;
    end;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : bank_t;
        num_banks : bank_t
    )
    return chr_rom_addr_t
    is
        variable ret : chr_rom_addr_t;
        variable bank_addr : unsigned(chr_addr_t'range);
        variable mod_bank : bank_t;
    begin
        mod_bank := bank and (num_banks - "1");

        bank_addr := unsigned(addr_in);
        ret := mod_bank & bank_addr(9 downto 0);

        return ret;
    end;
    
    function cpu_map_using_mapper_004
    (
        map_in : cpu_mapper_004_in_t
    )
    return cpu_mapper_004_out_t
    is
        variable map_out : cpu_mapper_004_out_t;

        variable file_offset : file_off_t;
        variable prg_address : prg_rom_addr_t;

        variable bank : bank_t;

        variable num_banks : rom_blocks_t;
        variable max_bank : bank_t;
    begin
        
        map_out.bus_out := CPU_MAPPER_BUS_IDLE;
        map_out.reg := map_in.reg;

        num_banks := shift_left(map_in.common.prg_rom_16kb_blocks, 1);
        max_bank := num_banks - "1";

        file_offset := get_file_offset(x"00", map_in.common.has_trainer);

        case to_integer(map_in.bus_in.cpu_bus.address) is
            when 16#6000# to 16#7FFF# =>
                map_out.bus_out.sram_bus.address :=
                    get_sram_addr(map_in.bus_in.cpu_bus.address);
                map_out.bus_out.sram_bus.read := map_in.bus_in.cpu_bus.read;
                map_out.bus_out.sram_bus.write := map_in.bus_in.cpu_bus.write;
                
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_sram;
                map_out.bus_out.data_to_sram := map_in.bus_in.data_from_cpu;
            when 16#8000# to 16#9FFF# =>
                if is_bus_write(map_in.bus_in.cpu_bus)
                then
                    if map_in.bus_in.cpu_bus.address(0) = '0'
                    then
                        map_out.reg.bank_idx :=
                            unsigned(map_in.bus_in.data_from_cpu(2 downto 0));
                        map_out.reg.chr_mode := map_in.bus_in.data_from_cpu(7);
                        map_out.reg.prg_mode := map_in.bus_in.data_from_cpu(6);
                    else
                        map_out.reg.banks(to_integer(map_in.reg.bank_idx)) :=
                            unsigned(map_in.bus_in.data_from_cpu);
                    end if;
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    if map_in.reg.prg_mode = '0'
                    then
                        bank := map_in.reg.banks(6);
                    else
                        bank := max_bank - "1";
                    end if;

                    prg_address :=
                        get_cpu_prg_addr(map_in.bus_in.cpu_bus.address,
                                         bank,
                                         num_banks);

                    map_out.bus_out.file_bus := bus_read(prg_address + file_offset);
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
                end if;
            when 16#A000# to 16#BFFF# =>
                if is_bus_write(map_in.bus_in.cpu_bus)
                then
                    if map_in.bus_in.cpu_bus.address(0) = '0'
                    then
                        map_out.reg.mirroring := map_in.bus_in.data_from_cpu(0);
                    end if;
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    bank := map_in.reg.banks(7);
                    prg_address :=
                        get_cpu_prg_addr(map_in.bus_in.cpu_bus.address,
                                         bank,
                                         num_banks);

                    map_out.bus_out.file_bus := bus_read(prg_address + file_offset);
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
                end if;
            when 16#C000# to 16#DFFF# =>
                if is_bus_write(map_in.bus_in.cpu_bus)
                then
                    if map_in.bus_in.cpu_bus.address(0) = '0'
                    then
                        map_out.reg.irq_reload :=
                            unsigned(map_in.bus_in.data_from_cpu);
                    else
                        map_out.reg.irq_count := (others => '0');
                    end if;
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    if map_in.reg.prg_mode = '0'
                    then
                        bank := max_bank - "1";
                    else
                        bank := map_in.reg.banks(6);
                    end if;

                    prg_address :=
                        get_cpu_prg_addr(map_in.bus_in.cpu_bus.address,
                                         bank,
                                         num_banks);

                    map_out.bus_out.file_bus := bus_read(prg_address + file_offset);
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
                end if;
            when 16#E000# to 16#FFFF# =>
                if is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.irq_enable :=
                        map_in.bus_in.cpu_bus.address(0) = '1';
                    
                    if map_in.bus_in.cpu_bus.address(0) = '0'
                    then
                        map_out.reg.irq := false;
                    end if;
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    -- Hardcoded to the last bank
                    bank := max_bank;
                    prg_address :=
                        get_cpu_prg_addr(map_in.bus_in.cpu_bus.address,
                                         bank,
                                         num_banks);

                    map_out.bus_out.file_bus := bus_read(prg_address + file_offset);
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
                end if;
            when others =>
                map_out.bus_out.data_to_cpu := (others => '0');
        end case;
        
        return map_out;
    end;

    function ppu_map_using_mapper_004
    (
        map_in : ppu_mapper_004_in_t
    )
    return ppu_mapper_004_out_t
    is
        variable map_out : ppu_mapper_004_out_t;
        
        variable address : chr_rom_addr_t;
        variable file_offset : file_off_t;

        variable mirror : mirror_t;

        variable bank : bank_t;
        variable num_banks : bank_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;

        num_banks := shift_left(map_in.common.chr_rom_8kb_blocks, 3);

        if not is_bus_active(map_in.bus_in.chr_bus) or
           map_in.bus_in.chr_bus.address(12) = '0'
        then
            if map_in.reg.a12_count < A12_MAX
            then
                map_out.reg.a12_count := map_in.reg.a12_count + "1";
            end if;
        else
            map_out.reg.a12_count := (others => '0');
            if map_in.reg.a12_count = A12_MAX
            then
                if is_zero(map_in.reg.irq_count)
                then
                    map_out.reg.irq_count := map_in.reg.irq_reload;
                else
                    map_out.reg.irq_count := map_in.reg.irq_count - "1";
                end if;

                if is_zero(map_out.reg.irq_count)
                then
                    map_out.reg.irq := map_in.reg.irq_enable;
                end if;
            end if;
        end if;

        map_out.irq := map_out.reg.irq;

        file_offset := get_file_offset(map_in.common.prg_rom_16kb_blocks,
                                       map_in.common.has_trainer);

        mirror := map_in.common.mirror;
        mirror(0) := not map_in.reg.mirroring;

        if is_bus_active(map_in.bus_in.chr_bus)
        then
            if is_zero(map_in.common.chr_rom_8kb_blocks)
            then
                map_out.bus_out := ppu_map_using_mapper_004_ram(mirror,
                                                                map_in.bus_in);
            else
                map_out.bus_out := ppu_map_using_mapper_004_rom(map_in.reg,
                                                                mirror,
                                                                num_banks,
                                                                file_offset,
                                                                map_in.bus_in);
            end if;
        end if;

        return map_out;
    end;

    function ppu_map_using_mapper_004_rom
    (
        reg         : mapper_004_reg_t;
        mirror      : mirror_t;
        num_banks   : bank_t;
        file_offset : file_off_t;
        bus_in      : ppu_mapper_bus_in_t
    )
    return ppu_mapper_bus_out_t
    is
        variable bus_out : ppu_mapper_bus_out_t;

        variable address : chr_rom_addr_t;
        variable bank : bank_t;
    begin
        bus_out := PPU_MAPPER_BUS_IDLE;

        case to_integer(bus_in.chr_bus.address) is
            when 16#0000# to 16#03FF# =>
                if reg.chr_mode = '0'
                then
                    bank := reg.banks(0);
                    bank(0) := '0';
                else
                    bank := reg.banks(2);
                end if;

                address := get_ppu_chr_addr(bus_in.chr_bus.address,
                                            bank,
                                            num_banks);
                bus_out.file_bus := bus_read(address + file_offset);
                bus_out.data_to_ppu := bus_in.data_from_file;
            when 16#0400# to 16#07FF# =>
                if reg.chr_mode = '0'
                then
                    bank := reg.banks(0);
                    bank(0) := '1';
                else
                    bank := reg.banks(3);
                end if;

                address := get_ppu_chr_addr(bus_in.chr_bus.address,
                                            bank,
                                            num_banks);
                bus_out.file_bus := bus_read(address + file_offset);
                bus_out.data_to_ppu := bus_in.data_from_file;
            when 16#0800# to 16#0BFF# =>
                if reg.chr_mode = '0'
                then
                    bank := reg.banks(1);
                    bank(0) := '0';
                else
                    bank := reg.banks(4);
                end if;

                address := get_ppu_chr_addr(bus_in.chr_bus.address,
                                            bank,
                                            num_banks);
                bus_out.file_bus := bus_read(address + file_offset);
                bus_out.data_to_ppu := bus_in.data_from_file;
            when 16#0C00# to 16#0FFF# =>
                if reg.chr_mode = '0'
                then
                    bank := reg.banks(1);
                    bank(0) := '1';
                else
                    bank := reg.banks(5);
                end if;

                address := get_ppu_chr_addr(bus_in.chr_bus.address,
                                            bank,
                                            num_banks);
                bus_out.file_bus := bus_read(address + file_offset);
                bus_out.data_to_ppu := bus_in.data_from_file;
            when 16#1000# to 16#13FF# =>
                if reg.chr_mode = '0'
                then
                    bank := reg.banks(2);
                else
                    bank := reg.banks(0);
                    bank(0) := '0';
                end if;

                address := get_ppu_chr_addr(bus_in.chr_bus.address,
                                            bank,
                                            num_banks);
                bus_out.file_bus := bus_read(address + file_offset);
                bus_out.data_to_ppu := bus_in.data_from_file;
            when 16#1400# to 16#17FF# =>
                if reg.chr_mode = '0'
                then
                    bank := reg.banks(3);
                else
                    bank := reg.banks(0);
                    bank(0) := '1';
                end if;

                address := get_ppu_chr_addr(bus_in.chr_bus.address,
                                            bank,
                                            num_banks);
                bus_out.file_bus := bus_read(address + file_offset);
                bus_out.data_to_ppu := bus_in.data_from_file;
            when 16#1800# to 16#1BFF# =>
                if reg.chr_mode = '0'
                then
                    bank := reg.banks(4);
                else
                    bank := reg.banks(1);
                    bank(0) := '0';
                end if;

                address := get_ppu_chr_addr(bus_in.chr_bus.address,
                                            bank,
                                            num_banks);
                bus_out.file_bus := bus_read(address + file_offset);
                bus_out.data_to_ppu := bus_in.data_from_file;
            when 16#1C00# to 16#1FFF# =>
                if reg.chr_mode = '0'
                then
                    bank := reg.banks(5);
                else
                    bank := reg.banks(1);
                    bank(0) := '1';
                end if;

                address := get_ppu_chr_addr(bus_in.chr_bus.address,
                                            bank,
                                            num_banks);
                bus_out.file_bus := bus_read(address + file_offset);
                bus_out.data_to_ppu := bus_in.data_from_file;
            when 16#2000# to 16#3FFF# =>
                bus_out.ciram_bus.address :=
                    get_mirrored_address(bus_in.chr_bus.address, mirror);

                bus_out.ciram_bus.read := bus_in.chr_bus.read;
                bus_out.ciram_bus.write := bus_in.chr_bus.write;
                bus_out.data_to_ppu := bus_in.data_from_ciram;
                bus_out.data_to_ciram := bus_in.data_from_ppu;
            when others =>
                null;
        end case;

        return bus_out;
    end;

    function ppu_map_using_mapper_004_ram
    (
        mirror : mirror_t;
        bus_in : ppu_mapper_bus_in_t
    )
    return ppu_mapper_bus_out_t
    is
        variable bus_out : ppu_mapper_bus_out_t;
    begin
        case to_integer(bus_in.chr_bus.address) is
            when 16#0000# to 16#1FFF# =>
                bus_out.chr_ram_bus.address :=
                    get_chr_ram_addr(bus_in.chr_bus.address);
                bus_out.chr_ram_bus.read := bus_in.chr_bus.read;
                bus_out.chr_ram_bus.write := bus_in.chr_bus.write;

                bus_out.data_to_ppu := bus_in.data_from_chr_ram;
                bus_out.data_to_chr_ram := bus_in.data_from_ppu;
            when 16#2000# to 16#3FFF# =>
                bus_out.ciram_bus.address :=
                    get_mirrored_address(bus_in.chr_bus.address, mirror);

                bus_out.ciram_bus.read := bus_in.chr_bus.read;
                bus_out.ciram_bus.write := bus_in.chr_bus.write;
                bus_out.data_to_ppu := bus_in.data_from_ciram;
                bus_out.data_to_ciram := bus_in.data_from_ppu;
            when others =>
                null;
        end case;

        return bus_out;
    end;

end package body;
