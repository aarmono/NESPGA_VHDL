library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.nes_core.all;
use work.nes_audio_mixer.all;
use work.utilities.all;
use work.lib_nsf_rom.all;

package lib_nsf is

    type state_t is
    (
        STATE_RESET,
        STATE_LOAD,
        STATE_RUN
    );
    
    type reg_t is record
        total_songs : unsigned(data_t'RANGE);
        start_song  : unsigned(data_t'RANGE);
        load_addr   : cpu_addr_t;
        init_addr   : cpu_addr_t;
        play_addr   : cpu_addr_t;
        speed       : unsigned(cpu_addr_t'RANGE);
        cur_time    : unsigned(cpu_addr_t'RANGE);
        song_type   : std_logic;
        cur_state   : state_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        total_songs => x"00",
        start_song => x"00",
        load_addr => x"0000",
        init_addr => x"0000",
        play_addr => x"0000",
        speed => x"0000",
        cur_time => x"0000",
        song_type => '0',
        cur_state => STATE_RESET
    );
    
    type nsf_out_t is record
        reg           : reg_t;
        apu_bus       : apu_bus_t;
        apu_data_out  : data_t;
        sram_bus      : sram_bus_t;
        sram_data_out : data_t;
        ram_bus       : ram_bus_t;
        ram_data_out  : data_t;
        nsf_bus       : cpu_bus_t;
        cpu_data_out  : data_t;
        audio         : mixed_audio_t;
        reset         : boolean;
        nmi           : boolean;
    end record;

    function cycle_nsf
    (
        reg          : reg_t;
        cpu_bus      : cpu_bus_t;
        cpu_data_in  : data_t;
        ram_data_in  : data_t;
        sram_data_in : data_t;
        apu_data_in  : data_t;
        nsf_data_in  : data_t;
        audio        : apu_out_t
    )
    return nsf_out_t;

end lib_nsf;

package body lib_nsf is

    function cycle_nsf
    (
        reg          : reg_t;
        cpu_bus      : cpu_bus_t;
        cpu_data_in  : data_t;
        ram_data_in  : data_t;
        sram_data_in : data_t;
        apu_data_in  : data_t;
        nsf_data_in  : data_t;
        audio        : apu_out_t
    )
    return nsf_out_t
    is
        constant RESET_ADDR : cpu_addr_t := x"3800";
        constant NMI_ADDR : cpu_addr_t := x"3880";
        
        variable ret : nsf_out_t;
    begin
        ret.reg := reg;
        ret.ram_bus := bus_idle(ret.ram_bus);
        ret.sram_bus := bus_idle(ret.sram_bus);
        ret.apu_bus := bus_idle(ret.apu_bus);
        ret.nsf_bus := bus_idle(ret.nsf_bus);
        
        ret.ram_data_out := (others => '-');
        ret.sram_data_out := (others => '-');
        ret.cpu_data_out := (others => '-');
        ret.apu_data_out := (others => '-');
        
        ret.audio := (others => '-');
        
        ret.reset := false;
        ret.nmi := false;
        case reg.cur_state is
            when STATE_RESET =>
                ret.reset := true;
                ret.ram_bus := bus_write(reg.cur_time(ram_addr_t'range));
                ret.sram_bus := bus_write(reg.cur_time(sram_addr_t'range));
                
                ret.ram_data_out := x"00";
                ret.sram_data_out := x"00";
            
                ret.reg.cur_time := reg.cur_time + "1";
                if reg.cur_time = x"1FFF"
                then
                    ret.reg.cur_time := x"0000";
                    ret.reg.cur_state := STATE_LOAD;
                end if;
            when STATE_LOAD =>
                ret.reset := true;
                ret.nsf_bus :=
                    bus_read(resize(reg.cur_time, ret.nsf_bus.address'length));
                case reg.cur_time is
                    -- Total Songs
                    when x"0006" =>
                        ret.reg.total_songs := unsigned(nsf_data_in);
                    -- Starting Song
                    when x"0007" =>
                        ret.reg.start_song := unsigned(nsf_data_in);
                    -- Load Addr Low
                    when x"0008" =>
                        ret.reg.load_addr(7 downto 0) := nsf_data_in;
                    -- Load Addr High
                    when x"0009" =>
                        ret.reg.load_addr(15 downto 8) := nsf_data_in;
                    -- Init Addr Low
                    when x"000A" =>
                        ret.reg.init_addr(7 downto 0) := nsf_data_in;
                    -- Init Addr High
                    when x"000B" =>
                        ret.reg.init_addr(15 downto 8) := nsf_data_in;
                    -- Play Addr Low
                    when x"000C" =>
                        ret.reg.play_addr(7 downto 0) := nsf_data_in;
                    -- Play Addr High
                    when x"000D" =>
                        ret.reg.play_addr(15 downto 8) := nsf_data_in;
                    -- Speed Low, NTSC
                    when x"006E" =>
                        ret.reg.speed(7 downto 0) := unsigned(nsf_data_in);
                    -- Speed High, NTSC
                    when x"006F" =>
                        ret.reg.speed(15 downto 8) := unsigned(nsf_data_in);
                    when x"007A" =>
                        ret.reg.song_type := nsf_data_in(0);
                    when others =>
                end case;
                
                if reg.cur_time = x"7F"
                then
                    ret.reg.cur_state := STATE_RUN;
                    ret.reg.cur_time := reg.speed;
                else
                    ret.reg.cur_time := reg.cur_time + "1";
                end if;
                
            when STATE_RUN =>
                if reg.cur_time = x"0000"
                then
                    ret.nmi := true;
                    ret.reg.cur_time := reg.speed;
                else
                    ret.nmi := false;
                    ret.reg.cur_time := reg.cur_time - "1";
                end if;
                ret.audio := mix_audio(audio);
                
                case cpu_bus.address is
                    --Current Song
                    when x"3700" =>
                        ret.cpu_data_out := std_logic_vector(reg.start_song - "1");
                    -- Song type (NTSC or PAL)
                    when x"3701" =>
                        ret.cpu_data_out := "0000000" & reg.song_type;
                    -- Init Address Low
                    when x"3702" =>
                        ret.cpu_data_out := reg.init_addr(7 downto 0);
                    -- Init Address High
                    when x"3703" =>
                        ret.cpu_data_out := reg.init_addr(15 downto 8);
                    -- Play Address Low
                    when x"3704" =>
                        ret.cpu_data_out := reg.play_addr(7 downto 0);
                    -- Play Address High
                    when x"3705" =>
                        ret.cpu_data_out := reg.play_addr(15 downto 8);
                    -- Reset Address Low
                    when x"FFFC" =>
                        ret.cpu_data_out := RESET_ADDR(7 downto 0);
                    -- Reset Address High
                    when x"FFFD" =>
                        ret.cpu_data_out := RESET_ADDR(15 downto 8);
                    -- NMI Address Low
                    when x"FFFA" =>
                        ret.cpu_data_out := NMI_ADDR(7 downto 0);
                    -- NMI Address High
                    when x"FFFB" =>
                        ret.cpu_data_out := NMI_ADDR(15 downto 8);
                    when others =>
                        if cpu_bus.address(15 downto 8) = x"38"
                        then
                            ret.cpu_data_out := 
                                get_nsf_byte(cpu_bus.address(7 downto 0));
                        elsif is_ram_addr(cpu_bus.address)
                        then
                            ret.ram_bus.address := get_ram_addr(cpu_bus.address);
                            ret.ram_bus.read := cpu_bus.read;
                            ret.ram_bus.write := cpu_bus.write;
                            
                            ret.cpu_data_out := ram_data_in;
                            ret.ram_data_out := cpu_data_in;
                        elsif is_sram_addr(cpu_bus.address)
                        then
                            ret.sram_bus.address := get_sram_addr(cpu_bus.address);
                            ret.sram_bus.read := cpu_bus.read;
                            ret.sram_bus.write := cpu_bus.write;
                            
                            ret.cpu_data_out := sram_data_in;
                            ret.sram_data_out := cpu_data_in;
                        elsif is_apu_addr(cpu_bus.address)
                        then
                            ret.apu_bus.address := get_apu_addr(cpu_bus.address);
                            ret.apu_bus.read := cpu_bus.read;
                            ret.apu_bus.write := cpu_bus.write;
                            
                            ret.cpu_data_out := apu_data_in;
                            ret.apu_data_out := cpu_data_in;
                        elsif cpu_bus.address >= reg.load_addr
                        then
                            ret.nsf_bus :=
                                bus_read(unsigned(cpu_bus.address) -
                                         unsigned(reg.load_addr) +
                                         x"80");
                            ret.cpu_data_out := nsf_data_in;
                        end if;
                end case;
        end case;
        
        return ret;
    end;

end package body;