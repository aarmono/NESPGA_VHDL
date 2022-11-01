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
use work.mapper_types.all;

package lib_mapper_220 is

    type mapper_220_reg_t is record
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
    
    constant RESET_MAPPER_220_REG : mapper_220_reg_t :=
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
    
    type mapper_220_in_t is record
        reg    : mapper_220_reg_t;
        bus_in : cpu_mapper_bus_in_t;
    end record;
    
    type mapper_220_out_t is record
        reg     : mapper_220_reg_t;
        bus_out : cpu_mapper_bus_out_t;
    end record;
    
    function map_enabled(reg : mapper_220_reg_t) return boolean;
    
    function map_using_mapper_220
    (
        map_in : mapper_220_in_t
    )
    return mapper_220_out_t;
    
    function get_mapped_file_bus
    (
        reg     : mapper_220_reg_t;
        cpu_bus : cpu_bus_t
    )
    return file_bus_t;
    
    function get_unmapped_file_bus
    (
        reg     : mapper_220_reg_t;
        cpu_bus : cpu_bus_t
    )
    return file_bus_t;
    
    function init_nsf_offset(reg : mapper_220_reg_t) return mapper_220_reg_t;

end package lib_mapper_220;


package body lib_mapper_220 is

    function init_nsf_offset(reg : mapper_220_reg_t) return mapper_220_reg_t
    is
        variable ret : mapper_220_reg_t;
    begin
        ret := reg;
        
        if map_enabled(reg)
        then
            ret.nsf_offset := (reg.load_addr and x"0FFF") + x"0080";
        end if;
        
        return ret;
    end;

    function get_mapped_file_bus
    (
        reg     : mapper_220_reg_t;
        cpu_bus : cpu_bus_t
    )
    return file_bus_t
    is
        variable bank : unsigned(data_t'range);
        variable bus_out : file_bus_t;
        variable cpu_base_address : unsigned(11 downto 0);
    begin
        cpu_base_address := unsigned(cpu_bus.address(cpu_base_address'range));
        bus_out := FILE_BUS_IDLE;

        if unsigned(cpu_bus.address) >= x"8000"
        then
            case cpu_bus.address(15 downto 12) is
                when x"8" => bank := reg.bank_0;
                when x"9" => bank := reg.bank_1;
                when x"A" => bank := reg.bank_2;
                when x"B" => bank := reg.bank_3;
                when x"C" => bank := reg.bank_4;
                when x"D" => bank := reg.bank_5;
                when x"E" => bank := reg.bank_6;
                when x"F" => bank := reg.bank_7;
                when others => bank := (others => '-');
            end case;
            
            bus_out := bus_read((bank & cpu_base_address) + reg.nsf_offset);
        end if;
        
        return bus_out;
    end;
    
    function get_unmapped_file_bus
    (
        reg     : mapper_220_reg_t;
        cpu_bus : cpu_bus_t
    )
    return file_bus_t
    is
        variable address : unsigned(file_addr_t'range);
        variable cpu_address : unsigned(file_addr_t'range);
        variable load_address : unsigned(file_addr_t'range);
        variable file_bus : file_bus_t;
    begin
        cpu_address := resize(unsigned(cpu_bus.address), cpu_address'length);
        load_address := resize(reg.load_addr, load_address'length);
        
        if cpu_address >= load_address
        then
            address := (cpu_address - load_address) + x"80";
            return bus_read(address);
        else
            return FILE_BUS_IDLE;
        end if;
    end;

    function map_enabled(reg : mapper_220_reg_t) return boolean
    is
    begin
        return not is_zero(reg.bank_0) or not is_zero(reg.bank_1) or
               not is_zero(reg.bank_2) or not is_zero(reg.bank_3) or
               not is_zero(reg.bank_4) or not is_zero(reg.bank_5) or
               not is_zero(reg.bank_6) or not is_zero(reg.bank_7);
    end;
    
    function map_using_mapper_220
    (
        map_in : mapper_220_in_t
    )
    return mapper_220_out_t
    is
        variable map_out : mapper_220_out_t;
        
        constant RESET_ADDR : cpu_addr_t := x"4200";
        constant NMI_ADDR : cpu_addr_t := x"4280";
        
        constant NSF_INIT_ADDR_LOW  : file_addr_t := x"0000A";
        constant NSF_INIT_ADDR_HIGH : file_addr_t := x"0000B";
        
        constant NSF_PLAY_ADDR_LOW  : file_addr_t := x"0000C";
        constant NSF_PLAY_ADDR_HIGH : file_addr_t := x"0000D";
        
        constant NSF_SONG_TYPE_ADDR : file_addr_t := x"0007A";
    begin
        map_out.reg := map_in.reg;
        
        map_out.bus_out := CPU_MAPPER_BUS_IDLE;
        
        case to_integer(map_in.bus_in.cpu_bus.address) is
            --Current Song
            when 16#4100# =>
                map_out.bus_out.data_to_cpu :=
                    std_logic_vector(map_in.reg.start_song - "1");
            -- Song type (NTSC or PAL)
            when 16#4101# =>
                map_out.bus_out.file_bus := bus_read(NSF_SONG_TYPE_ADDR);
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
            -- Init Address Low
            when 16#4102# =>
                map_out.bus_out.file_bus := bus_read(NSF_INIT_ADDR_LOW);
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
            -- Init Address High
            when 16#4103# =>
                map_out.bus_out.file_bus := bus_read(NSF_INIT_ADDR_HIGH);
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
            -- Play Address Low
            when 16#4104# =>
                map_out.bus_out.file_bus := bus_read(NSF_PLAY_ADDR_LOW);
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
            -- Play Address High
            when 16#4105# =>
                map_out.bus_out.file_bus := bus_read(NSF_PLAY_ADDR_HIGH);
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
            -- Mask NMI
            when 16#4106# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        "0000000" & to_std_logic(map_in.reg.mask_nmi);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.mask_nmi :=
                        map_in.bus_in.data_from_cpu(0) = '1';
                end if;
            -- Reset Address Low
            when 16#FFFC# =>
                map_out.bus_out.data_to_cpu := RESET_ADDR(7 downto 0);
            -- Reset Address High
            when 16#FFFD# =>
                map_out.bus_out.data_to_cpu := RESET_ADDR(15 downto 8);
            -- NMI Address Low
            when 16#FFFA# =>
                map_out.bus_out.data_to_cpu := NMI_ADDR(7 downto 0);
            -- NMI Address High
            when 16#FFFB# =>
                map_out.bus_out.data_to_cpu := NMI_ADDR(15 downto 8);
            when 16#4200# to 16#42FF# =>
                map_out.bus_out.data_to_cpu :=
                    get_nsf_byte(map_in.bus_in.cpu_bus.address(7 downto 0));
            -- Bankswitch registers
            when 16#5FF8# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.bank_0);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.bank_0 := unsigned(map_in.bus_in.data_from_cpu);
                end if;
            when 16#5FF9# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.bank_1);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.bank_1 := unsigned(map_in.bus_in.data_from_cpu);
                end if;
            when 16#5FFA# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.bank_2);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.bank_2 := unsigned(map_in.bus_in.data_from_cpu);
                end if;
            when 16#5FFB# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.bank_3);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.bank_3 := unsigned(map_in.bus_in.data_from_cpu);
                end if;
            when 16#5FFC# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.bank_4);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.bank_4 := unsigned(map_in.bus_in.data_from_cpu);
                end if;
            when 16#5FFD# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.bank_5);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.bank_5 := unsigned(map_in.bus_in.data_from_cpu);
                end if;
            when 16#5FFE# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.bank_6);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.bank_6 := unsigned(map_in.bus_in.data_from_cpu);
                end if;
            when 16#5FFF# =>
                if is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.bus_out.data_to_cpu :=
                        std_logic_vector(map_in.reg.bank_7);
                elsif is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.bank_7 := unsigned(map_in.bus_in.data_from_cpu);
                end if;
            -- SRAM
            when 16#6000# to 16#7FFF# =>
                map_out.bus_out.sram_bus.address :=
                    get_sram_addr(map_in.bus_in.cpu_bus.address);
                map_out.bus_out.sram_bus.read := map_in.bus_in.cpu_bus.read;
                map_out.bus_out.sram_bus.write := map_in.bus_in.cpu_bus.write;
                
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_sram;
                map_out.bus_out.data_to_sram := map_in.bus_in.data_from_cpu;
            when others =>
                if map_enabled(map_in.reg)
                then
                    map_out.bus_out.file_bus :=
                        get_mapped_file_bus(map_in.reg, map_in.bus_in.cpu_bus);
                else
                    map_out.bus_out.file_bus :=
                        get_unmapped_file_bus(map_in.reg, map_in.bus_in.cpu_bus);
                end if;
                
                map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_file;
        end case;
        
        return map_out;
    end;

end package body;
