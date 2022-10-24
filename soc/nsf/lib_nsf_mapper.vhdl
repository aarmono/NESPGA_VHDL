library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.nes_core.all;
use work.lib_nsf_rom.all;
use work.utilities.all;

package lib_nsf_mapper is

    type mapper_reg_t is record
        total_songs : unsigned(data_t'RANGE);
        start_song  : unsigned(data_t'RANGE);
        
        mask_nmi    : boolean;
        
        load_addr  : unsigned(cpu_addr_t'range);
        nsf_offset : unsigned(cpu_addr_t'range);
        
        bank_0     : unsigned(data_t'range);
        bank_1     : unsigned(data_t'range);
        bank_2     : unsigned(data_t'range);
        bank_3     : unsigned(data_t'range);
        bank_4     : unsigned(data_t'range);
        bank_5     : unsigned(data_t'range);
        bank_6     : unsigned(data_t'range);
        bank_7     : unsigned(data_t'range);
    end record;
    
    constant RESET_MAPPER_REG : mapper_reg_t :=
    (
        total_songs => (others => '0'),
        start_song => (others => '0'),
        
        mask_nmi => false,
        
        load_addr => (others => '0'),
        nsf_offset => (others => '0'),
        
        bank_0 => (others => '0'),
        bank_1 => (others => '0'),
        bank_2 => (others => '0'),
        bank_3 => (others => '0'),
        bank_4 => (others => '0'),
        bank_5 => (others => '0'),
        bank_6 => (others => '0'),
        bank_7 => (others => '0')
    );
    
    type mapper_in_t is record
        reg : mapper_reg_t;
        
        cpu_bus : cpu_bus_t;
        
        data_from_cpu  : data_t;
        data_from_apu  : data_t;
        data_from_ram  : data_t;
        data_from_sram : data_t;
        data_from_nsf  : data_t;
    end record;
    
    type mapper_out_t is record
        reg : mapper_reg_t;
        
        apu_bus  : apu_bus_t;
        ram_bus  : ram_bus_t;
        sram_bus : sram_bus_t;
        nsf_bus  : file_bus_t;
        
        data_to_cpu  : data_t;
        data_to_apu  : data_t;
        data_to_ram  : data_t;
        data_to_sram : data_t;
    end record;
    
    function map_enabled(reg : mapper_reg_t) return boolean;
    
    function perform_memory_map(map_in : mapper_in_t) return mapper_out_t;
    
    function get_mapped_nsf_bus
    (
        reg     : mapper_reg_t;
        cpu_bus : cpu_bus_t
    )
    return file_bus_t;
    
    function get_unmapped_nsf_bus
    (
        reg     : mapper_reg_t;
        cpu_bus : cpu_bus_t
    )
    return file_bus_t;
    
    function init_nsf_offset(reg : mapper_reg_t) return mapper_reg_t;

end package lib_nsf_mapper;


package body lib_nsf_mapper is

    function init_nsf_offset(reg : mapper_reg_t) return mapper_reg_t
    is
        variable ret : mapper_reg_t;
    begin
        ret := reg;
        
        if map_enabled(reg)
        then
            ret.nsf_offset := (reg.load_addr and x"0FFF") + x"0080";
        end if;
        
        return ret;
    end;

    function get_mapped_nsf_bus
    (
        reg     : mapper_reg_t;
        cpu_bus : cpu_bus_t
    )
    return file_bus_t
    is
        variable mapped_address : unsigned(file_addr_t'range);
        variable cpu_base_address : unsigned(11 downto 0);
    begin
        cpu_base_address := unsigned(cpu_bus.address(cpu_base_address'range));

        case cpu_bus.address(15 downto 12) is
            when x"8" => mapped_address := reg.bank_0 & cpu_base_address;
            when x"9" => mapped_address := reg.bank_1 & cpu_base_address;
            when x"A" => mapped_address := reg.bank_2 & cpu_base_address;
            when x"B" => mapped_address := reg.bank_3 & cpu_base_address;
            when x"C" => mapped_address := reg.bank_4 & cpu_base_address;
            when x"D" => mapped_address := reg.bank_5 & cpu_base_address;
            when x"E" => mapped_address := reg.bank_6 & cpu_base_address;
            when x"F" => mapped_address := reg.bank_7 & cpu_base_address;
            when others => mapped_address := (others => '-');
        end case;
    
        return bus_read(mapped_address + reg.nsf_offset);
    end;
    
    function get_unmapped_nsf_bus
    (
        reg     : mapper_reg_t;
        cpu_bus : cpu_bus_t
    )
    return file_bus_t
    is
        variable address : unsigned(file_addr_t'range);
        variable cpu_address : unsigned(file_addr_t'range);
        variable load_address : unsigned(file_addr_t'range);
        variable nsf_bus : file_bus_t;
    begin
        cpu_address := resize(unsigned(cpu_bus.address), cpu_address'length);
        load_address := resize(reg.load_addr, load_address'length);
        
        if cpu_address >= load_address
        then
            address := (cpu_address - load_address) + x"80";
            return bus_read(address);
        else
            return bus_idle(nsf_bus);
        end if;
    end;

    function map_enabled(reg : mapper_reg_t) return boolean
    is
    begin
        return not is_zero(reg.bank_0) or not is_zero(reg.bank_1) or
               not is_zero(reg.bank_2) or not is_zero(reg.bank_3) or
               not is_zero(reg.bank_4) or not is_zero(reg.bank_5) or
               not is_zero(reg.bank_6) or not is_zero(reg.bank_7);
    end;
    
    function perform_memory_map(map_in : mapper_in_t) return mapper_out_t
    is
        variable map_out : mapper_out_t;
        
        constant RESET_ADDR : cpu_addr_t := x"4200";
        constant NMI_ADDR : cpu_addr_t := x"4280";
        
        constant NSF_INIT_ADDR_LOW  : file_addr_t := x"0000A";
        constant NSF_INIT_ADDR_HIGH : file_addr_t := x"0000B";
        
        constant NSF_PLAY_ADDR_LOW  : file_addr_t := x"0000C";
        constant NSF_PLAY_ADDR_HIGH : file_addr_t := x"0000D";
        
        constant NSF_SONG_TYPE_ADDR : file_addr_t := x"0007A";
    begin
        map_out.reg := map_in.reg;
        
        map_out.apu_bus := bus_idle(map_out.apu_bus);
        map_out.ram_bus := bus_idle(map_out.ram_bus);
        map_out.sram_bus := bus_idle(map_out.sram_bus);
        map_out.nsf_bus := bus_idle(map_out.nsf_bus);
        
        map_out.data_to_cpu := (others => '-');
        map_out.data_to_apu := (others => '-');
        map_out.data_to_ram := (others => '-');
        map_out.data_to_sram := (others => '-');
        
        if is_bus_active(map_in.cpu_bus)
        then
            case? map_in.cpu_bus.address is
                --Current Song
                when x"4100" =>
                    map_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.start_song - "1");
                -- Song type (NTSC or PAL)
                when x"4101" =>
                    map_out.nsf_bus := bus_read(NSF_SONG_TYPE_ADDR);
                    map_out.data_to_cpu := map_in.data_from_nsf;
                -- Init Address Low
                when x"4102" =>
                    map_out.nsf_bus := bus_read(NSF_INIT_ADDR_LOW);
                    map_out.data_to_cpu := map_in.data_from_nsf;
                -- Init Address High
                when x"4103" =>
                    map_out.nsf_bus := bus_read(NSF_INIT_ADDR_HIGH);
                    map_out.data_to_cpu := map_in.data_from_nsf;
                -- Play Address Low
                when x"4104" =>
                    map_out.nsf_bus := bus_read(NSF_PLAY_ADDR_LOW);
                    map_out.data_to_cpu := map_in.data_from_nsf;
                -- Play Address High
                when x"4105" =>
                    map_out.nsf_bus := bus_read(NSF_PLAY_ADDR_HIGH);
                    map_out.data_to_cpu := map_in.data_from_nsf;
                -- Mask NMI
                when x"4106" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu :=
                            "0000000" & to_std_logic(map_in.reg.mask_nmi);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.mask_nmi := map_in.data_from_cpu(0) = '1';
                    end if;
                -- Reset Address Low
                when x"FFFC" =>
                    map_out.data_to_cpu := RESET_ADDR(7 downto 0);
                -- Reset Address High
                when x"FFFD" =>
                    map_out.data_to_cpu := RESET_ADDR(15 downto 8);
                -- NMI Address Low
                when x"FFFA" =>
                    map_out.data_to_cpu := NMI_ADDR(7 downto 0);
                -- NMI Address High
                when x"FFFB" =>
                    map_out.data_to_cpu := NMI_ADDR(15 downto 8);
                when x"42--" =>
                    map_out.data_to_cpu :=
                        get_nsf_byte(map_in.cpu_bus.address(7 downto 0));
                -- RAM
                when x"0---" |
                     x"1---" =>
                    map_out.ram_bus.address := get_ram_addr(map_in.cpu_bus.address);
                    map_out.ram_bus.read := map_in.cpu_bus.read;
                    map_out.ram_bus.write := map_in.cpu_bus.write;
                    
                    map_out.data_to_cpu := map_in.data_from_ram;
                    map_out.data_to_ram := map_in.data_from_cpu;
                -- APU
                when x"400-" |
                     x"401-" =>
                    map_out.apu_bus.address := get_apu_addr(map_in.cpu_bus.address);
                    map_out.apu_bus.read := map_in.cpu_bus.read;
                    map_out.apu_bus.write := map_in.cpu_bus.write;
                    
                    map_out.data_to_cpu := map_in.data_from_apu;
                    map_out.data_to_apu := map_in.data_from_cpu;
                -- Bankswitch registers
                when x"5FF8" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu := std_logic_vector(map_in.reg.bank_0);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.bank_0 := unsigned(map_in.data_from_cpu);
                    end if;
                when x"5FF9" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu := std_logic_vector(map_in.reg.bank_1);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.bank_1 := unsigned(map_in.data_from_cpu);
                    end if;
                when x"5FFA" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu := std_logic_vector(map_in.reg.bank_2);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.bank_2 := unsigned(map_in.data_from_cpu);
                    end if;
                when x"5FFB" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu := std_logic_vector(map_in.reg.bank_3);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.bank_3 := unsigned(map_in.data_from_cpu);
                    end if;
                when x"5FFC" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu := std_logic_vector(map_in.reg.bank_4);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.bank_4 := unsigned(map_in.data_from_cpu);
                    end if;
                when x"5FFD" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu := std_logic_vector(map_in.reg.bank_5);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.bank_5 := unsigned(map_in.data_from_cpu);
                    end if;
                when x"5FFE" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu := std_logic_vector(map_in.reg.bank_6);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.bank_6 := unsigned(map_in.data_from_cpu);
                    end if;
                when x"5FFF" =>
                    if is_bus_read(map_in.cpu_bus)
                    then
                        map_out.data_to_cpu := std_logic_vector(map_in.reg.bank_7);
                    elsif is_bus_write(map_in.cpu_bus)
                    then
                        map_out.reg.bank_7 := unsigned(map_in.data_from_cpu);
                    end if;
                -- SRAM
                when x"6---" |
                     x"7---" =>
                    map_out.sram_bus.address :=
                        get_sram_addr(map_in.cpu_bus.address);
                    map_out.sram_bus.read := map_in.cpu_bus.read;
                    map_out.sram_bus.write := map_in.cpu_bus.write;
                    
                    map_out.data_to_cpu := map_in.data_from_sram;
                    map_out.data_to_sram := map_in.data_from_cpu;
                when x"8---" |
                     x"9---" |
                     x"A---" |
                     x"B---" |
                     x"C---" |
                     x"D---" |
                     x"E---" |
                     x"F--0" |
                     x"F--1" |
                     x"F--2" |
                     x"F--3" |
                     x"F--4" |
                     x"F--5" |
                     x"F--6" |
                     x"F--7" |
                     x"F--8" |
                     x"F--9" |
                     x"F--E" |
                     x"F--F" =>
                    if map_enabled(map_in.reg)
                    then
                        map_out.nsf_bus :=
                            get_mapped_nsf_bus(map_in.reg, map_in.cpu_bus);
                    else
                        map_out.nsf_bus :=
                            get_unmapped_nsf_bus(map_in.reg, map_in.cpu_bus);
                    end if;
                    
                    map_out.data_to_cpu := map_in.data_from_nsf;
                when others =>
                    null;
            end case?;
        end if;
        
        return map_out;
    end;

end package body;