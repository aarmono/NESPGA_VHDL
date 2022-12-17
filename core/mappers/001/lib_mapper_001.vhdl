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

package lib_mapper_001 is
    
    subtype shift_t is unsigned(3 downto 0);
    constant SHIFT_MAX : shift_t := to_unsigned(4, shift_t'length);

    subtype prg_bank_t is unsigned(3 downto 0);
    subtype prg_rom_addr_t is unsigned(17 downto 0);

    subtype chr_bank_t is unsigned(4 downto 0);
    subtype chr_rom_addr_t is unsigned(17 downto 0);

    type mapper_001_reg_t is record
        shift : unsigned(3 downto 0);
        count : unsigned(2 downto 0);

        mirroring : unsigned(1 downto 0);
        prg_bank_mode : unsigned(1 downto 0);
        chr_bank_mode : std_logic;

        chr_bank_0 : chr_bank_t;
        chr_bank_1 : chr_bank_t;

        prg_bank : prg_bank_t;
        bypass   : std_logic;
    end record;

    constant RESET_MAPPER_001_REG : mapper_001_reg_t :=
    (
        shift => (others => '0'),
        count => (others => '0'),

        mirroring => (others => '0'),
        prg_bank_mode => (others => '1'),
        chr_bank_mode => '0',

        chr_bank_0 => (others => '0'),
        chr_bank_1 => (others => '0'),

        prg_bank => (others => '0'),
        bypass => '0'
    );

    type cpu_mapper_001_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_001_reg_t;
        bus_in : cpu_mapper_bus_in_t;
    end record;
    
    type cpu_mapper_001_out_t is record
        reg     : mapper_001_reg_t;
        bus_out : cpu_mapper_bus_out_t;
    end record;
    
    function cpu_map_using_mapper_001
    (
        map_in : cpu_mapper_001_in_t
    )
    return cpu_mapper_001_out_t;

    type ppu_mapper_001_in_t is record
        common : mapper_common_reg_t;
        reg    : mapper_001_reg_t;
        bus_in : ppu_mapper_bus_in_t;
    end record;

    type ppu_mapper_001_out_t is record
        bus_out : ppu_mapper_bus_out_t;
    end record;

    function ppu_map_using_mapper_001
    (
        map_in : ppu_mapper_001_in_t
    )
    return ppu_mapper_001_out_t;
    
    function get_cpu_prg_addr
    (
        addr_in   : cpu_addr_t;
        bank      : prg_bank_t;
        num_banks : prg_bank_t
    )
    return prg_rom_addr_t;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : chr_bank_t;
        num_banks : chr_bank_t
    )
    return chr_rom_addr_t;

end package lib_mapper_001;


package body lib_mapper_001 is
    
    function get_cpu_prg_addr
    (
        addr_in   : cpu_addr_t;
        bank      : prg_bank_t;
        num_banks : prg_bank_t
    )
    return prg_rom_addr_t
    is
        variable ret : prg_rom_addr_t;
        variable bank_addr : unsigned(cpu_addr_t'range);
        variable mod_bank : prg_bank_t;
    begin
        mod_bank := bank and (num_banks - "1");

        bank_addr := unsigned(addr_in);
        ret := mod_bank & bank_addr(13 downto 0);
        
        return ret;
    end;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : chr_bank_t;
        num_banks : chr_bank_t
    )
    return chr_rom_addr_t
    is
        variable ret : chr_rom_addr_t;
        variable bank_addr : unsigned(chr_addr_t'range);
        variable mod_bank : chr_bank_t;
    begin
        mod_bank := bank and (num_banks - "1");

        bank_addr := unsigned(addr_in);
        ret := mod_bank & bank_addr(11 downto 0);

        return ret;
    end;
    
    function cpu_map_using_mapper_001
    (
        map_in : cpu_mapper_001_in_t
    )
    return cpu_mapper_001_out_t
    is
        variable map_out : cpu_mapper_001_out_t;

        variable file_offset : file_off_t;
        variable prg_address : prg_rom_addr_t;

        variable bank : prg_bank_t;

        variable num_banks : prg_bank_t;
        variable max_bank  : prg_bank_t;

        variable reg_val : unsigned(4 downto 0);
    begin
        
        map_out.bus_out := CPU_MAPPER_BUS_IDLE;
        map_out.reg := map_in.reg;

        num_banks := map_in.common.prg_rom_16kb_blocks(num_banks'range);
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
            when 16#8000# to 16#FFFF# =>
                if is_bus_write(map_in.bus_in.cpu_bus) and map_in.bus_in.clk_sync
                then
                    if map_in.bus_in.data_from_cpu(7) = '1'
                    then
                        map_out.reg.count := (others => '0');
                        map_out.reg.shift := (others => '0');
                        map_out.reg.prg_bank_mode := (others => '1');
                    elsif map_in.bus_in.first_write and
                          map_in.reg.count < SHIFT_MAX
                    then
                        map_out.reg.shift := map_in.reg.shift(2 downto 0) &
                                             map_in.bus_in.data_from_cpu(0);
                        map_out.reg.count := map_in.reg.count + "1";
                    elsif map_in.bus_in.first_write
                    then
                        map_out.reg.shift := (others => '0');
                        map_out.reg.count := (others => '0');
                        reg_val := map_in.reg.shift &
                                   map_in.bus_in.data_from_cpu(0);
                        case map_in.bus_in.cpu_bus.address(14 downto 13) is
                            when "00" =>
                                map_out.reg.mirroring := reg_val(1 downto 0);
                                map_out.reg.prg_bank_mode := reg_val(3 downto 2);
                                map_out.reg.chr_bank_mode := reg_val(4);
                            when "01" =>
                                map_out.reg.chr_bank_0 := reg_val;
                            when "10" =>
                                map_out.reg.chr_bank_1 := reg_val;
                            when "11" =>
                                map_out.reg.prg_bank := reg_val(3 downto 0);
                                map_out.reg.bypass := reg_val(4);
                            when others =>
                                null;
                        end case;
                    end if;
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    case to_integer(map_in.bus_in.cpu_bus.address) is
                        when 16#8000# to 16#BFFF# =>
                            case map_in.reg.prg_bank_mode is
                                when "00" | "01" =>
                                    bank := map_in.reg.prg_bank;
                                    bank(0) := '0';
                                when "10" =>
                                    bank := (others => '0');
                                when "11" =>
                                    bank := map_in.reg.prg_bank;
                                when others =>
                                    null;
                            end case;
                            
                            prg_address :=
                                get_cpu_prg_addr(map_in.bus_in.cpu_bus.address,
                                                 bank,
                                                 num_banks);
                            map_out.bus_out.file_bus :=
                                bus_read(prg_address + file_offset);
                            map_out.bus_out.data_to_cpu :=
                                map_in.bus_in.data_from_file;

                        when 16#C000# to 16#FFFF# =>
                            case map_in.reg.prg_bank_mode is
                                when "00" | "01" =>
                                    bank := map_in.reg.prg_bank;
                                    bank(0) := '1';
                                when "10" =>
                                    bank := map_in.reg.prg_bank;
                                when "11" =>
                                    bank := max_bank;
                                when others =>
                                    null;
                            end case;

                            prg_address :=
                                get_cpu_prg_addr(map_in.bus_in.cpu_bus.address,
                                                 bank,
                                                 num_banks);
                            map_out.bus_out.file_bus :=
                                bus_read(prg_address + file_offset);
                            map_out.bus_out.data_to_cpu :=
                                map_in.bus_in.data_from_file;
                        when others =>
                            null;
                    end case;
                end if;
            when others =>
                map_out.bus_out.data_to_cpu := (others => '0');
        end case;
        
        return map_out;
    end;

    function ppu_map_using_mapper_001
    (
        map_in : ppu_mapper_001_in_t
    )
    return ppu_mapper_001_out_t
    is
        variable map_out : ppu_mapper_001_out_t;
        
        variable address : chr_rom_addr_t;
        variable file_offset : file_off_t;

        variable mirror : mirror_t;

        variable bank : chr_bank_t;
        variable num_banks : chr_bank_t;
    begin
        map_out.bus_out := PPU_MAPPER_BUS_IDLE;

        num_banks := map_in.common.chr_rom_8kb_blocks(num_banks'range);

        file_offset := get_file_offset(map_in.common.prg_rom_16kb_blocks,
                                       map_in.common.has_trainer);

        return map_out;
    end;

end package body;
