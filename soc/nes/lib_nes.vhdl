library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.chr_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.prg_bus_types.all;
use work.palette_bus_types.all;
use work.file_bus_types.all;
use work.nes_types.all;
use work.nes_audio_mixer.all;
use work.utilities.all;
use work.mapper_types.all;
use work.lib_mapper.all;
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
        mapper_reg  : mapper_reg_t;
        cur_cycle   : unsigned(cpu_addr_t'RANGE);
        cur_state   : state_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        mapper_reg => RESET_MAPPER_REG,
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
        oam_bus         : oam_bus_t;
        data_to_oam     : data_t;
        sec_oam_bus     : sec_oam_bus_t;
        data_to_sec_oam : data_t;
        palette_bus     : palette_bus_t;
        data_to_palette : pixel_t;
        audio           : mixed_audio_t;
        reset           : boolean;
    end record;
    
    type nes_in_t is record
        reg             : reg_t;
        cpu_bus         : cpu_mmap_bus_in_t;
        ppu_bus         : ppu_mmap_bus_in_t;
        oam_bus         : oam_bus_t;
        data_to_oam     : data_t;
        sec_oam_bus     : sec_oam_bus_t;
        data_to_sec_oam : data_t;
        palette_bus     : palette_bus_t;
        data_to_palette : pixel_t;
        audio           : apu_out_t;
    end record;

    function cycle_nes(nes_in : nes_in_t) return nes_out_t;

end lib_nes;

package body lib_nes is

    function cycle_nes(nes_in : nes_in_t) return nes_out_t
    is
        variable ret : nes_out_t;
        
        variable cpu_map_in  : cpu_mmap_in_t;
        variable cpu_map_out : cpu_mmap_out_t;
        
        variable ppu_map_in  : ppu_mmap_in_t;
        variable ppu_map_out : ppu_mmap_out_t;
    begin
        ret.reg := nes_in.reg;
        
        ret.cpu_bus := CPU_MMAP_BUS_IDLE;
        ret.ppu_bus := PPU_MMAP_BUS_IDLE;
        
        ret.oam_bus := OAM_BUS_IDLE;
        ret.sec_oam_bus := SEC_OAM_BUS_IDLE;
        ret.palette_bus := PALETTE_BUS_IDLE;
        ret.data_to_oam := (others => '-');
        ret.data_to_sec_oam := (others => '-');
        ret.data_to_palette := (others => '-');
        
        ret.audio := (others => '-');
        ret.reset := false;
        
        case nes_in.reg.cur_state is
            when STATE_RESET =>
                ret.reset := true;
                
                ret.cpu_bus.ram_bus :=
                    bus_write(nes_in.reg.cur_cycle(ram_addr_t'range));
                ret.cpu_bus.sram_bus :=
                    bus_write(nes_in.reg.cur_cycle(sram_addr_t'range));
                
                ret.oam_bus :=
                    bus_write(nes_in.reg.cur_cycle(oam_addr_t'range));
                ret.sec_oam_bus :=
                    bus_write(nes_in.reg.cur_cycle(sec_oam_addr_t'range));
                ret.palette_bus :=
                    bus_write(nes_in.reg.cur_cycle(palette_addr_t'range));
                
                ret.ppu_bus.ciram_bus :=
                    bus_write(nes_in.reg.cur_cycle(chr_addr_t'range));
                
                ret.cpu_bus.data_to_ram := x"00";
                ret.cpu_bus.data_to_sram := x"00";
                
                ret.data_to_oam := x"00";
                ret.data_to_sec_oam := x"00";
                ret.data_to_palette :=
                    STARTUP_PALETTE
                    (
                        to_integer(nes_in.reg.cur_cycle(palette_addr_t'range))
                    );
                
                ret.ppu_bus.data_to_ciram := x"00";
                
                ret.reg.mapper_reg := RESET_MAPPER_REG;
                
                if nes_in.reg.cur_cycle = x"3FFF"
                then
                    ret.reg.cur_cycle := x"0000";
                    ret.reg.cur_state := STATE_LOAD;
                else
                    ret.reg.cur_cycle := nes_in.reg.cur_cycle + "1";
                end if;
            when STATE_LOAD =>
                ret.reset := true;
                ret.cpu_bus.file_bus :=
                    bus_read(resize(nes_in.reg.cur_cycle, file_addr_t'length));
                case nes_in.reg.cur_cycle is
                    -- Size of PRG ROM in 16 KB units 
                    when x"0004" =>
                        ret.reg.mapper_reg.common.prg_rom_16kb_blocks :=
                            unsigned(nes_in.cpu_bus.data_from_file);
                    -- Size of CHR ROM in 8 KB units
                    -- (Value 0 means the board uses CHR RAM)
                    when x"0005" =>
                        ret.reg.mapper_reg.common.chr_rom_8kb_blocks :=
                            unsigned(nes_in.cpu_bus.data_from_file);
                    -- Flags 6
                    when x"0006" =>
                        ret.reg.mapper_reg.common.mirror :=
                            nes_in.cpu_bus.data_from_file(3) &
                            nes_in.cpu_bus.data_from_file(0);
                        ret.reg.mapper_reg.common.has_prg_ram :=
                            nes_in.cpu_bus.data_from_file(1) = '1';
                        ret.reg.mapper_reg.mapper_num(3 downto 0) :=
                            nes_in.cpu_bus.data_from_file(7 downto 4);
                    -- Flags 7
                    when x"0007" =>
                        ret.reg.mapper_reg.mapper_num(7 downto 4) :=
                            nes_in.cpu_bus.data_from_file(7 downto 4);
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
                
                ppu_map_in.bus_in := nes_in.ppu_bus;
                cpu_map_in.bus_in := nes_in.cpu_bus;
                
                cpu_map_in.reg := nes_in.reg.mapper_reg;
                cpu_map_out := mmap_cpu_memory(cpu_map_in);
                
                -- Note we pass the register OUTPUT from the CPU map to ensure
                -- we have all updates
                ppu_map_in.reg := cpu_map_out.reg;
                ppu_map_out := mmap_ppu_memory(ppu_map_in);
                
                ret.reg.mapper_reg := ppu_map_out.reg;
                ret.cpu_bus := cpu_map_out.bus_out;
                ret.ppu_bus := ppu_map_out.bus_out;
        end case;
        
        return ret;
    end;

end package body;