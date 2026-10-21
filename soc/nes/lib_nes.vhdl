library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.chr_bus_types.all;
use work.ciram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.prg_bus_types.all;
use work.palette_bus_types.all;
use work.file_bus_types.all;
use work.nes_types.all;
use work.nes_audio_mixer.all;
use work.utilities.all;
use work.cart_types.all;
use work.lib_nes_mmap.all;

package lib_nes is

    type state_t is
    (
        STATE_RESET,
        STATE_LOAD,
        STATE_RUN
    );
    
    -- Clocked off the CPU timer
    type reg_t is record
        cart_config : cart_config_t;
        mmap_reg    : cpu_mmap_reg_t;
        cur_cycle   : unsigned(cpu_addr_t'RANGE);
        cur_state   : state_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        cart_config => RESET_CART_CONFIG,
        mmap_reg => RESET_CPU_MMAP_REG,
        cur_cycle => x"0000",
        cur_state => STATE_RESET
    );

    constant STARTUP_PALETTE : palette_t :=
    (
        resize(x"09", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"0D", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"10", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"24", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"04", pixel_t'length),
        resize(x"2C", pixel_t'length),
        resize(x"09", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"34", pixel_t'length),
        resize(x"03", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"04", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"14", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"3A", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"20", pixel_t'length),
        resize(x"2C", pixel_t'length),
        resize(x"08", pixel_t'length)
    );
    
    type nes_out_t is record
        reg             : reg_t;
        cpu_bus         : cpu_mmap_bus_out_t;
        ppu_bus         : ppu_mmap_bus_out_t;
        -- Memories on the cartridge. PRG ROM and CHR ROM are in the ROM file
        prg_file_bus    : file_bus_t;
        chr_file_bus    : file_bus_t;
        sram_bus        : sram_bus_t;
        data_to_sram    : data_t;
        chr_ram_bus     : sram_bus_t;
        data_to_chr_ram : data_t;
        oam_bus         : oam_bus_t;
        data_to_oam     : data_t;
        sec_oam_bus     : sec_oam_bus_t;
        data_to_sec_oam : data_t;
        palette_bus     : palette_bus_t;
        data_to_palette : pixel_t;
        audio           : mixed_audio_t;
        reset           : boolean;
        irq             : boolean;
    end record;
    
    type nes_in_t is record
        reg             : reg_t;
        cpu_bus         : cpu_mmap_bus_in_t;
        ppu_bus         : ppu_mmap_bus_in_t;
        data_from_file  : data_t;
        cart            : cart_out_t;
        oam_bus         : oam_bus_t;
        data_to_oam     : data_t;
        sec_oam_bus     : sec_oam_bus_t;
        data_to_sec_oam : data_t;
        palette_bus     : palette_bus_t;
        data_to_palette : pixel_t;
        audio           : apu_out_t;
    end record;

    function cycle_nes(nes_in : nes_in_t) return nes_out_t;

    function parse_mirror(mirror : std_logic_vector(1 downto 0)) return mirror_t;

    -- The offset in the ROM file of the PRG ROM (offset_16kb = 0) or the
    -- CHR ROM (offset_16kb = the size of the PRG ROM)
    function get_file_offset
    (
        offset_16kb : rom_blocks_t;
        has_trainer : boolean
    )
    return unsigned;

    -- The ROM file access for an access to PRG ROM or CHR ROM
    function get_file_bus
    (
        rom_bus     : file_bus_t;
        file_offset : unsigned
    )
    return file_bus_t;

end lib_nes;

package body lib_nes is

    function parse_mirror(mirror : std_logic_vector(1 downto 0)) return mirror_t
    is
        variable ret : mirror_t;
    begin
        case mirror is
            when "00" =>
                ret := MIRROR_HORZ;
            when "01" =>
                ret := MIRROR_VERT;
            when "10" |
                 "11" =>
                ret := MIRROR_FOUR;
            when others =>
                ret := MIRROR_HORZ;
        end case;

        return ret;
    end;

    function get_file_offset
    (
        offset_16kb : rom_blocks_t;
        has_trainer : boolean
    )
    return unsigned
    is
        variable ret : unsigned(file_addr_t'range);
    begin
        ret := offset_16kb(5 downto 0) &
               "0000" &
               to_std_logic(has_trainer) &
               b"0_0001_0000";
        
        return ret;
    end;

    function get_file_bus
    (
        rom_bus     : file_bus_t;
        file_offset : unsigned
    )
    return file_bus_t
    is
    begin
        if is_bus_active(rom_bus)
        then
            return bus_read(unsigned(rom_bus.address) + file_offset);
        else
            return FILE_BUS_IDLE;
        end if;
    end;

    function cycle_nes(nes_in : nes_in_t) return nes_out_t
    is
        variable ret : nes_out_t;
        
        variable cpu_map_in  : cpu_mmap_in_t;
        variable cpu_map_out : cpu_mmap_out_t;
        
        variable mirror : std_logic_vector(1 downto 0);
    begin
        ret.reg := nes_in.reg;
        
        ret.cpu_bus := CPU_MMAP_BUS_IDLE;
        ret.ppu_bus := PPU_MMAP_BUS_IDLE;

        ret.prg_file_bus := FILE_BUS_IDLE;
        ret.chr_file_bus := FILE_BUS_IDLE;
        ret.sram_bus := SRAM_BUS_IDLE;
        ret.data_to_sram := (others => '-');
        ret.chr_ram_bus := SRAM_BUS_IDLE;
        ret.data_to_chr_ram := (others => '-');
        
        ret.oam_bus := OAM_BUS_IDLE;
        ret.sec_oam_bus := SEC_OAM_BUS_IDLE;
        ret.palette_bus := PALETTE_BUS_IDLE;
        ret.data_to_oam := (others => '-');
        ret.data_to_sec_oam := (others => '-');
        ret.data_to_palette := (others => '-');
        
        ret.audio := (others => '-');
        ret.reset := false;
        ret.irq   := false;
        
        case nes_in.reg.cur_state is
            when STATE_RESET =>
                ret.reset := true;
                
                ret.cpu_bus.ram_bus :=
                    bus_write(nes_in.reg.cur_cycle(ram_addr_t'range));
                ret.sram_bus :=
                    bus_write(nes_in.reg.cur_cycle(sram_addr_t'range));
                
                ret.oam_bus :=
                    bus_write(nes_in.reg.cur_cycle(oam_addr_t'range));
                ret.sec_oam_bus :=
                    bus_write(nes_in.reg.cur_cycle(sec_oam_addr_t'range));
                ret.palette_bus :=
                    bus_write(nes_in.reg.cur_cycle(palette_addr_t'range));
                
                ret.chr_ram_bus :=
                    bus_write(nes_in.reg.cur_cycle(sram_addr_t'range));
                ret.ppu_bus.ciram_bus :=
                    bus_write(nes_in.reg.cur_cycle(ciram_addr_t'range));
                
                ret.cpu_bus.data_to_ram := x"00";
                ret.data_to_sram := x"00";
                
                ret.data_to_oam := x"00";
                ret.data_to_sec_oam := x"00";
                ret.data_to_palette :=
                    STARTUP_PALETTE
                    (
                        to_integer(nes_in.reg.cur_cycle(palette_addr_t'range))
                    );
                
                ret.data_to_chr_ram := x"00";
                ret.ppu_bus.data_to_ciram := x"00";
                
                ret.reg.cart_config := RESET_CART_CONFIG;
                ret.reg.mmap_reg := RESET_CPU_MMAP_REG;
                
                if nes_in.reg.cur_cycle = x"3FFF"
                then
                    ret.reg.cur_cycle := x"0000";
                    ret.reg.cur_state := STATE_LOAD;
                else
                    ret.reg.cur_cycle := nes_in.reg.cur_cycle + "1";
                end if;
            when STATE_LOAD =>
                ret.reset := true;
                ret.prg_file_bus :=
                    bus_read(resize(nes_in.reg.cur_cycle, file_addr_t'length));
                case nes_in.reg.cur_cycle is
                    -- Size of PRG ROM in 16 KB units 
                    when x"0004" =>
                        ret.reg.cart_config.prg_rom_16kb_blocks :=
                            unsigned(nes_in.data_from_file);
                    -- Size of CHR ROM in 8 KB units
                    -- (Value 0 means the board uses CHR RAM)
                    when x"0005" =>
                        ret.reg.cart_config.chr_rom_8kb_blocks :=
                            unsigned(nes_in.data_from_file);
                    -- Flags 6
                    when x"0006" =>
                        mirror := nes_in.data_from_file(3) &
                                  nes_in.data_from_file(0);
                        ret.reg.cart_config.mirror := parse_mirror(mirror);
                        ret.reg.cart_config.has_prg_ram :=
                            nes_in.data_from_file(1) = '1';
                        ret.reg.cart_config.mapper_num(3 downto 0) :=
                            nes_in.data_from_file(7 downto 4);
                    -- Flags 7
                    when x"0007" =>
                        ret.reg.cart_config.mapper_num(7 downto 4) :=
                            nes_in.data_from_file(7 downto 4);
                        ret.reg.cart_config.nes2 :=
                            nes_in.data_from_file(3 downto 2) = "10";
                    -- Mapper MSB/Submapper (NES 2.0 only)
                    when x"0008" =>
                        if nes_in.reg.cart_config.nes2
                        then
                            ret.reg.cart_config.mapper_num(11 downto 8) :=
                                nes_in.data_from_file(3 downto 0);
                            ret.reg.cart_config.submapper_num :=
                                nes_in.data_from_file(7 downto 4);
                        end if;
                    when others =>
                end case;
                
                if nes_in.reg.cur_cycle = x"0F"
                then
                    ret.reg.cur_state := STATE_RUN;
                else
                    ret.reg.cur_cycle := nes_in.reg.cur_cycle + "1";
                end if;
                
            when STATE_RUN =>
                ret.audio := mix_audio(nes_in.audio);
                
                ret.oam_bus := nes_in.oam_bus;
                ret.data_to_oam := nes_in.data_to_oam;
                
                ret.sec_oam_bus := nes_in.sec_oam_bus;
                ret.data_to_sec_oam := nes_in.data_to_sec_oam;
                
                ret.palette_bus := nes_in.palette_bus;
                ret.data_to_palette := nes_in.data_to_palette;
                
                cpu_map_in.reg := nes_in.reg.mmap_reg;
                cpu_map_in.bus_in := nes_in.cpu_bus;
                cpu_map_in.cart := nes_in.cart.cpu;
                cpu_map_out := mmap_cpu_memory(cpu_map_in);
                
                ret.reg.mmap_reg := cpu_map_out.reg;
                ret.cpu_bus := cpu_map_out.bus_out;
                ret.ppu_bus := mmap_ppu_memory(nes_in.ppu_bus, nes_in.cart.ppu);

                ret.prg_file_bus :=
                    get_file_bus(nes_in.cart.mem.prg_rom_bus,
                                 get_file_offset(x"00",
                                                 nes_in.reg.cart_config.has_trainer));
                ret.chr_file_bus :=
                    get_file_bus(nes_in.cart.mem.chr_rom_bus,
                                 get_file_offset(nes_in.reg.cart_config.prg_rom_16kb_blocks,
                                                 nes_in.reg.cart_config.has_trainer));

                ret.sram_bus := nes_in.cart.mem.prg_ram_bus;
                ret.data_to_sram := nes_in.cart.mem.data_to_prg_ram;
                ret.chr_ram_bus := nes_in.cart.mem.chr_ram_bus;
                ret.data_to_chr_ram := nes_in.cart.mem.data_to_chr_ram;

                ret.irq := nes_in.cart.cpu.irq;
        end case;
        
        return ret;
    end;

end package body;