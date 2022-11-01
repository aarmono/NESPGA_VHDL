library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.nes_types.all;
use work.nes_audio_mixer.all;
use work.utilities.all;
use work.mapper_types.all;
use work.lib_mapper_220.all;
use work.lib_nes_mmap.all;

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
        mapper_reg  : mapper_220_reg_t;
        speed       : unsigned(cpu_addr_t'RANGE);
        cur_cycle   : unsigned(cpu_addr_t'RANGE);
        cur_state   : state_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        mapper_reg => RESET_MAPPER_220_REG,
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
        reg     : reg_t;
        nsf_reg : nsf_reg_t;
        bus_out : cpu_mmap_bus_out_t;
        audio   : mixed_audio_t;
        reset   : boolean;
        nmi     : boolean;
    end record;
    
    type nsf_in_t is record
        reg             : reg_t;
        nsf_reg         : nsf_reg_t;
        bus_in          : cpu_mmap_bus_in_t;
        enable_square_1 : boolean;
        enable_square_2 : boolean;
        enable_triangle : boolean;
        enable_noise    : boolean;
        enable_dmc      : boolean;
        audio           : apu_out_t;
        song_sel        : song_sel_t;
    end record;

    function cycle_nsf(nsf_in : nsf_in_t) return nsf_out_t;
    
    type nsf_mapper_in_t is record
        reg    : mapper_220_reg_t;
        bus_in : cpu_mmap_bus_in_t;
    end record;
    
    type nsf_mapper_out_t is record
        reg     : mapper_220_reg_t;
        bus_out : cpu_mmap_bus_out_t;
    end record;

    function perform_memory_map(map_in : nsf_mapper_in_t) return nsf_mapper_out_t;

end lib_nsf;

package body lib_nsf is

    function cycle_nsf(nsf_in : nsf_in_t) return nsf_out_t
    is
        variable ret : nsf_out_t;
        
        variable map_in  : nsf_mapper_in_t;
        variable map_out : nsf_mapper_out_t;
    begin
        ret.reg := nsf_in.reg;
        ret.nsf_reg := nsf_in.nsf_reg;
        
        ret.bus_out := CPU_MMAP_BUS_IDLE;
        
        ret.audio := (others => '-');
        
        ret.reset := false;
        ret.nmi := false;
        
        case nsf_in.reg.cur_state is
            when STATE_RESET =>
                ret.reset := true;
                ret.bus_out.ram_bus :=
                    bus_write(nsf_in.reg.cur_cycle(ram_addr_t'range));
                ret.bus_out.sram_bus :=
                    bus_write(nsf_in.reg.cur_cycle(sram_addr_t'range));
                
                ret.bus_out.data_to_ram := x"00";
                ret.bus_out.data_to_sram := x"00";
                
                ret.reg.mapper_reg := RESET_MAPPER_220_REG;
                -- Preserve the start song and total song registers
                ret.reg.mapper_reg.start_song := nsf_in.reg.mapper_reg.start_song;
                ret.reg.mapper_reg.total_songs := nsf_in.reg.mapper_reg.total_songs;
                
                ret.reg.cur_cycle := nsf_in.reg.cur_cycle + "1";
                if nsf_in.reg.cur_cycle = x"1FFF"
                then
                    -- If the NSF file hasn't already been loaded, set
                    -- the counter to zero to load it
                    if is_zero(nsf_in.reg.mapper_reg.start_song)
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
                ret.nsf_reg.cur_time := nsf_in.reg.speed;
                ret.reset := true;
                ret.bus_out.file_bus :=
                    bus_read(resize(nsf_in.reg.cur_cycle, file_addr_t'length));
                case nsf_in.reg.cur_cycle is
                    -- Total Songs
                    when x"0006" =>
                        ret.reg.mapper_reg.total_songs :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    -- Starting Song
                    when x"0007" =>
                        ret.reg.mapper_reg.start_song :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    -- Load Addr Low
                    when x"0008" =>
                        ret.reg.mapper_reg.load_addr(7 downto 0) :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    -- Load Addr High
                    when x"0009" =>
                        ret.reg.mapper_reg.load_addr(15 downto 8) :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    -- Speed Low, NTSC
                    when x"006E" =>
                        ret.reg.speed(7 downto 0) :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    -- Speed High, NTSC
                    when x"006F" =>
                        ret.reg.speed(15 downto 8) :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    -- Bankswitch values
                    when x"0070" =>
                        ret.reg.mapper_reg.bank_0 :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    when x"0071" =>
                        ret.reg.mapper_reg.bank_1 :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    when x"0072" =>
                        ret.reg.mapper_reg.bank_2 :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    when x"0073" =>
                        ret.reg.mapper_reg.bank_3 :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    when x"0074" =>
                        ret.reg.mapper_reg.bank_4 :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    when x"0075" =>
                        ret.reg.mapper_reg.bank_5 :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    when x"0076" =>
                        ret.reg.mapper_reg.bank_6 :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    when x"0077" =>
                        ret.reg.mapper_reg.bank_7 :=
                            unsigned(nsf_in.bus_in.data_from_file);
                    when others =>
                end case;
                
                if nsf_in.reg.cur_cycle = x"7F"
                then
                    ret.reg.cur_state := STATE_RUN;
                    ret.reg.mapper_reg := init_nsf_offset(nsf_in.reg.mapper_reg);
                else
                    ret.reg.cur_cycle := nsf_in.reg.cur_cycle + "1";
                end if;
                
            when STATE_RUN =>
                if nsf_in.nsf_reg.cur_time = x"0000"
                then
                    ret.nmi := not nsf_in.reg.mapper_reg.mask_nmi;
                    ret.nsf_reg.cur_time := nsf_in.reg.speed;
                else
                    ret.nmi := false;
                    ret.nsf_reg.cur_time := nsf_in.nsf_reg.cur_time - "1";
                end if;
                
                ret.audio := mix_audio(nsf_in.audio,
                                       nsf_in.enable_square_1,
                                       nsf_in.enable_square_2,
                                       nsf_in.enable_triangle,
                                       nsf_in.enable_noise,
                                       nsf_in.enable_dmc);

                map_in.reg := nsf_in.reg.mapper_reg;
                map_in.bus_in := nsf_in.bus_in;
                
                map_out := perform_memory_map(map_in);
                
                ret.reg.mapper_reg := map_out.reg;
                
                ret.bus_out := map_out.bus_out;
                
                case nsf_in.song_sel is
                    when SONG_NEXT =>
                        ret.reg.cur_state := STATE_RESET;
                        ret.reg.cur_cycle := (others => '0');
                        if nsf_in.reg.mapper_reg.start_song =
                           nsf_in.reg.mapper_reg.total_songs
                        then
                            ret.reg.mapper_reg.start_song := x"01";
                        else
                            ret.reg.mapper_reg.start_song := 
                                nsf_in.reg.mapper_reg.start_song + "1";
                        end if;
                    when SONG_PREV =>
                        ret.reg.cur_state := STATE_RESET;
                        ret.reg.cur_cycle := (others => '0');
                        if nsf_in.reg.mapper_reg.start_song = x"01"
                        then
                            ret.reg.mapper_reg.start_song :=
                                nsf_in.reg.mapper_reg.total_songs;
                        else
                            ret.reg.mapper_reg.start_song :=
                                nsf_in.reg.mapper_reg.start_song - "1";
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
    
        if audio = reg.prev_audio and not is_zero(reg.silent_count)
        then
            ret.silent_count := reg.silent_count - "1";
        elsif audio /= reg.prev_audio
        then
            ret.prev_audio := audio;
            ret.silent_count := SILENT_START;
        end if;
        
        if not is_zero(reg.play_count)
        then
            ret.play_count := reg.play_count - "1";
        end if;
        
        ret.next_prev := next_stb;
        ret.prev_prev := prev_stb;
        
        return ret;
    end;
    
    function perform_memory_map(map_in : nsf_mapper_in_t) return nsf_mapper_out_t
    is
        variable map_out  : nsf_mapper_out_t;
        variable mmap_in  : cpu_mmap_in_t;
        variable mmap_out : cpu_mmap_out_t;
    begin
        mmap_in.reg.mapper_num := x"0DC";
        mmap_in.reg.mapper_220_reg := map_in.reg;
        
        mmap_in.bus_in := map_in.bus_in;
        
        mmap_out := mmap_cpu_memory(mmap_in);
        
        map_out.reg := mmap_out.reg.mapper_220_reg;
        map_out.bus_out := mmap_out.bus_out;
        
        return map_out;
    end;

end package body;