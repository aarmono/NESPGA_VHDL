library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.nsf_bus_types.all;
use work.nes_core.all;
use work.nes_audio_mixer.all;
use work.utilities.all;
use work.lib_nsf_mapper.all;

package lib_nsf is

    type song_sel_t is
    (
        SONG_SAME,
        SONG_NEXT,
        SONG_PREV
    );
    
    subtype silent_counter_t is unsigned(20 downto 0);
    constant SILENT_START : silent_counter_t :=
        to_unsigned(2000000, silent_counter_t'length);
    
    subtype play_counter_t is unsigned(26 downto 0);
    constant PLAY_START : play_counter_t :=
        to_unsigned(120000000, play_counter_t'length);
    
    type song_sel_reg_t is record
        next_prev    : std_logic;
        prev_prev    : std_logic;
        prev_audio   : mixed_audio_t;
        silent_count : silent_counter_t;
        play_count   : play_counter_t;
        song_sel     : song_sel_t;
    end record;
    
    constant RESET_SONG_SEL : song_sel_reg_t :=
    (
        next_prev    => '0',
        prev_prev    => '0',
        prev_audio   => (others => '0'),
        silent_count => SILENT_START,
        play_count   => PLAY_START,
        song_sel     => SONG_SAME
    );
    
    function cycle_song_sel
    (
        reg      : song_sel_reg_t;
        next_stb : std_logic;
        prev_stb : std_logic;
        audio    : mixed_audio_t
    )
    return song_sel_reg_t;

    type state_t is
    (
        STATE_RESET,
        STATE_LOAD,
        STATE_RUN
    );
    
    -- Clocked off the CPU timer
    type reg_t is record
        mapper_reg  : mapper_reg_t;
        speed       : unsigned(cpu_addr_t'RANGE);
        cur_cycle   : unsigned(cpu_addr_t'RANGE);
        cur_state   : state_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        mapper_reg => RESET_MAPPER_REG,
        speed => x"0000",
        cur_cycle => x"0000",
        cur_state => STATE_RESET
    );
    
    -- Clocked off the NSF timer
    type nsf_reg_t is record
        cur_time : unsigned(cpu_addr_t'range);
    end record;
    
    constant RESET_NSF_REG : nsf_reg_t :=
    (
        cur_time => (others => '0')
    );
    
    type nsf_out_t is record
        reg           : reg_t;
        nsf_reg       : nsf_reg_t;
        apu_bus       : apu_bus_t;
        apu_data_out  : data_t;
        sram_bus      : sram_bus_t;
        sram_data_out : data_t;
        ram_bus       : ram_bus_t;
        ram_data_out  : data_t;
        nsf_bus       : nsf_bus_t;
        cpu_data_out  : data_t;
        audio         : mixed_audio_t;
        reset         : boolean;
        nmi           : boolean;
    end record;

    function cycle_nsf
    (
        reg             : reg_t;
        nsf_reg         : nsf_reg_t;
        cpu_bus         : cpu_bus_t;
        dma_bus         : cpu_bus_t;
        cpu_data_in     : data_t;
        ram_data_in     : data_t;
        sram_data_in    : data_t;
        apu_data_in     : data_t;
        nsf_data_in     : data_t;
        enable_square_1 : boolean;
        enable_square_2 : boolean;
        enable_triangle : boolean;
        enable_noise    : boolean;
        enable_dmc      : boolean;
        audio           : apu_out_t;
        song_sel        : song_sel_t
    )
    return nsf_out_t;

end lib_nsf;

package body lib_nsf is

    function cycle_nsf
    (
        reg             : reg_t;
        nsf_reg         : nsf_reg_t;
        cpu_bus         : cpu_bus_t;
        dma_bus         : cpu_bus_t;
        cpu_data_in     : data_t;
        ram_data_in     : data_t;
        sram_data_in    : data_t;
        apu_data_in     : data_t;
        nsf_data_in     : data_t;
        enable_square_1 : boolean;
        enable_square_2 : boolean;
        enable_triangle : boolean;
        enable_noise    : boolean;
        enable_dmc      : boolean;
        audio           : apu_out_t;
        song_sel        : song_sel_t
    )
    return nsf_out_t
    is
        
        variable v_cpu_bus : cpu_bus_t;
        
        variable ret : nsf_out_t;
        
        variable map_in  : mapper_in_t;
        variable map_out : mapper_out_t;
    begin
        ret.reg := reg;
        ret.nsf_reg := nsf_reg;
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
        
        v_cpu_bus := cpu_bus;
        case reg.cur_state is
            when STATE_RESET =>
                ret.reset := true;
                ret.ram_bus := bus_write(reg.cur_cycle(ram_addr_t'range));
                ret.sram_bus := bus_write(reg.cur_cycle(sram_addr_t'range));
                
                ret.ram_data_out := x"00";
                ret.sram_data_out := x"00";
                
                ret.reg.mapper_reg := RESET_MAPPER_REG;
                -- Preserve the start song and total song registers
                ret.reg.mapper_reg.start_song := reg.mapper_reg.start_song;
                ret.reg.mapper_reg.total_songs := reg.mapper_reg.total_songs;
                
                ret.reg.cur_cycle := reg.cur_cycle + "1";
                if reg.cur_cycle = x"1FFF"
                then
                    -- If the NSF file hasn't already been loaded, set
                    -- the counter to zero to load it
                    if is_zero(reg.mapper_reg.start_song)
                    then
                        ret.reg.cur_cycle := x"0000";
                    -- Otherwise set the counter to 08 to skip loading the
                    -- song numbers
                    else
                        ret.reg.cur_cycle := x"0008";
                    end if;
                    ret.reg.cur_state := STATE_LOAD;
                end if;
            when STATE_LOAD =>
                ret.nsf_reg.cur_time := reg.speed;
                ret.reset := true;
                ret.nsf_bus :=
                    bus_read(resize(reg.cur_cycle, ret.nsf_bus.address'length));
                case reg.cur_cycle is
                    -- Total Songs
                    when x"0006" =>
                        ret.reg.mapper_reg.total_songs := unsigned(nsf_data_in);
                    -- Starting Song
                    when x"0007" =>
                        ret.reg.mapper_reg.start_song := unsigned(nsf_data_in);
                    -- Load Addr Low
                    when x"0008" =>
                        ret.reg.mapper_reg.load_addr(7 downto 0) := nsf_data_in;
                    -- Load Addr High
                    when x"0009" =>
                        ret.reg.mapper_reg.load_addr(15 downto 8) := nsf_data_in;
                    -- Init Addr Low
                    when x"000A" =>
                        ret.reg.mapper_reg.init_addr(7 downto 0) := nsf_data_in;
                    -- Init Addr High
                    when x"000B" =>
                        ret.reg.mapper_reg.init_addr(15 downto 8) := nsf_data_in;
                    -- Play Addr Low
                    when x"000C" =>
                        ret.reg.mapper_reg.play_addr(7 downto 0) := nsf_data_in;
                    -- Play Addr High
                    when x"000D" =>
                        ret.reg.mapper_reg.play_addr(15 downto 8) := nsf_data_in;
                    -- Speed Low, NTSC
                    when x"006E" =>
                        ret.reg.speed(7 downto 0) := unsigned(nsf_data_in);
                    -- Speed High, NTSC
                    when x"006F" =>
                        ret.reg.speed(15 downto 8) := unsigned(nsf_data_in);
                    -- Bankswitch values
                    when x"0070" =>
                        ret.reg.mapper_reg.bank_0 := unsigned(nsf_data_in);
                    when x"0071" =>
                        ret.reg.mapper_reg.bank_1 := unsigned(nsf_data_in);
                    when x"0072" =>
                        ret.reg.mapper_reg.bank_2 := unsigned(nsf_data_in);
                    when x"0073" =>
                        ret.reg.mapper_reg.bank_3 := unsigned(nsf_data_in);
                    when x"0074" =>
                        ret.reg.mapper_reg.bank_4 := unsigned(nsf_data_in);
                    when x"0075" =>
                        ret.reg.mapper_reg.bank_5 := unsigned(nsf_data_in);
                    when x"0076" =>
                        ret.reg.mapper_reg.bank_6 := unsigned(nsf_data_in);
                    when x"0077" =>
                        ret.reg.mapper_reg.bank_7 := unsigned(nsf_data_in);
                    when x"007A" =>
                        ret.reg.mapper_reg.song_type := nsf_data_in(0);
                    when others =>
                end case;
                
                if reg.cur_cycle = x"7F"
                then
                    ret.reg.cur_state := STATE_RUN;
                    ret.reg.mapper_reg := init_nsf_offset(reg.mapper_reg);
                else
                    ret.reg.cur_cycle := reg.cur_cycle + "1";
                end if;
                
            when STATE_RUN =>
                if nsf_reg.cur_time = x"0000"
                then
                    ret.nmi := not reg.mapper_reg.mask_nmi;
                    ret.nsf_reg.cur_time := reg.speed;
                else
                    ret.nmi := false;
                    ret.nsf_reg.cur_time := nsf_reg.cur_time - "1";
                end if;
                
                ret.audio := mix_audio(audio,
                                       enable_square_1,
                                       enable_square_2,
                                       enable_triangle,
                                       enable_noise,
                                       enable_dmc);

                if is_bus_active(dma_bus)
                then
                    v_cpu_bus := dma_bus;
                else
                    v_cpu_bus := cpu_bus;
                end if;

                map_in.reg := reg.mapper_reg;
                map_in.cpu_bus := v_cpu_bus;
                
                map_in.data_from_cpu := cpu_data_in;
                map_in.data_from_apu := apu_data_in;
                map_in.data_from_ram := ram_data_in;
                map_in.data_from_sram := sram_data_in;
                map_in.data_from_nsf := nsf_data_in;
                
                map_out := perform_memory_map(map_in);
                
                ret.reg.mapper_reg := map_out.reg;
                
                ret.apu_bus := map_out.apu_bus;
                ret.ram_bus := map_out.ram_bus;
                ret.sram_bus := map_out.sram_bus;
                ret.nsf_bus := map_out.nsf_bus;
                
                ret.cpu_data_out := map_out.data_to_cpu;
                ret.apu_data_out := map_out.data_to_apu;
                ret.sram_data_out := map_out.data_to_sram;
                ret.ram_data_out := map_out.data_to_ram;
                
                case song_sel is
                    when SONG_NEXT =>
                        ret.reg.cur_state := STATE_RESET;
                        ret.reg.cur_cycle := (others => '0');
                        if reg.mapper_reg.start_song = reg.mapper_reg.total_songs
                        then
                            ret.reg.mapper_reg.start_song := x"01";
                        else
                            ret.reg.mapper_reg.start_song := 
                                reg.mapper_reg.start_song + "1";
                        end if;
                    when SONG_PREV =>
                        ret.reg.cur_state := STATE_RESET;
                        ret.reg.cur_cycle := (others => '0');
                        if reg.mapper_reg.start_song = x"01"
                        then
                            ret.reg.mapper_reg.start_song :=
                                reg.mapper_reg.total_songs;
                        else
                            ret.reg.mapper_reg.start_song :=
                                reg.mapper_reg.start_song - "1";
                        end if;
                    when others =>
                end case;
        end case;
        
        return ret;
    end;
    
    function cycle_song_sel
    (
        reg      : song_sel_reg_t;
        next_stb : std_logic;
        prev_stb : std_logic;
        audio    : mixed_audio_t
    )
    return song_sel_reg_t
    is
        variable ret : song_sel_reg_t;
        variable next_edge : boolean;
        variable prev_edge : boolean;
    begin
        ret := reg;
        
        next_edge := next_stb = '1' and reg.next_prev = '0';
        prev_edge := prev_stb = '1' and reg.prev_prev = '0';
        
        if prev_edge and not next_edge
        then
            ret.song_sel := SONG_PREV;
        elsif (next_edge and not prev_edge) or
              is_zero(reg.play_count) or
              is_zero(reg.silent_count)
        then
            ret.song_sel := SONG_NEXT;
        else
            ret.song_sel := SONG_SAME;
        end if;
    
        if audio = reg.prev_audio
        then
            if reg.silent_count > ZERO(reg.silent_count)
            then
                ret.silent_count := reg.silent_count - "1";
            end if;
        else
            ret.prev_audio := audio;
            ret.silent_count := SILENT_START;
        end if;
        
        if reg.play_count > ZERO(reg.play_count)
        then
            ret.play_count := reg.play_count - "1";
        end if;
        
        ret.next_prev := next_stb;
        ret.prev_prev := prev_stb;
        
        return ret;
    end;

end package body;