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
use work.lib_nsf_rom.all;

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
        total_songs : unsigned(data_t'RANGE);
        start_song  : unsigned(data_t'RANGE);
        load_addr   : cpu_addr_t;
        init_addr   : cpu_addr_t;
        play_addr   : cpu_addr_t;
        speed       : unsigned(cpu_addr_t'RANGE);
        cur_cycle   : unsigned(cpu_addr_t'RANGE);
        song_type   : std_logic;
        bank_0      : unsigned(data_t'range);
        bank_1      : unsigned(data_t'range);
        bank_2      : unsigned(data_t'range);
        bank_3      : unsigned(data_t'range);
        bank_4      : unsigned(data_t'range);
        bank_5      : unsigned(data_t'range);
        bank_6      : unsigned(data_t'range);
        bank_7      : unsigned(data_t'range);
        map_enabled : boolean;
        nsf_offset  : unsigned(cpu_addr_t'range);
        cur_state   : state_t;
        mask_nmi    : boolean;
    end record;

    constant RESET_REG : reg_t :=
    (
        total_songs => x"00",
        start_song => x"00",
        load_addr => x"0000",
        init_addr => x"0000",
        play_addr => x"0000",
        speed => x"0000",
        cur_cycle => x"0000",
        song_type => '0',
        bank_0 => x"00",
        bank_1 => x"00",
        bank_2 => x"00",
        bank_3 => x"00",
        bank_4 => x"00",
        bank_5 => x"00",
        bank_6 => x"00",
        bank_7 => x"00",
        map_enabled => false,
        nsf_offset => x"0000",
        cur_state => STATE_RESET,
        mask_nmi => false
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
    
    function get_mapped_nsf_bus
    (
        reg     : reg_t;
        cpu_bus : cpu_bus_t
    )
    return nsf_bus_t;
    
    function get_unmapped_nsf_bus
    (
        reg     : reg_t;
        cpu_bus : cpu_bus_t
    )
    return nsf_bus_t;

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

    function get_mapped_nsf_bus
    (
        reg     : reg_t;
        cpu_bus : cpu_bus_t
    )
    return nsf_bus_t
    is
        variable mapped_address : unsigned(nsf_addr_t'range);
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
        reg     : reg_t;
        cpu_bus : cpu_bus_t
    )
    return nsf_bus_t
    is
        variable address : unsigned(nsf_addr_t'range);
    begin
        address := x"0" & (unsigned(cpu_bus.address) -
                           unsigned(reg.load_addr) + x"80");
        return bus_read(address);
    end;

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
        constant RESET_ADDR : cpu_addr_t := x"3800";
        constant NMI_ADDR : cpu_addr_t := x"3880";
        
        variable v_cpu_bus : cpu_bus_t;
        variable v_audio : apu_out_t;
        
        variable ret : nsf_out_t;
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
                
                ret.reg.mask_nmi := false;
                ret.reg.map_enabled := false;
            
                ret.reg.cur_cycle := reg.cur_cycle + "1";
                if reg.cur_cycle = x"1FFF"
                then
                    -- If the NSF file hasn't already been loaded, set
                    -- the counter to zero to load it
                    if is_zero(reg.start_song)
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
                    -- Bankswitch values
                    when x"0070" =>
                        ret.reg.bank_0 := unsigned(nsf_data_in);
                        ret.reg.map_enabled := not is_zero(nsf_data_in) or
                                               reg.map_enabled;
                    when x"0071" =>
                        ret.reg.bank_1 := unsigned(nsf_data_in);
                        ret.reg.map_enabled := not is_zero(nsf_data_in) or
                                               reg.map_enabled;
                    when x"0072" =>
                        ret.reg.bank_2 := unsigned(nsf_data_in);
                        ret.reg.map_enabled := not is_zero(nsf_data_in) or
                                               reg.map_enabled;
                    when x"0073" =>
                        ret.reg.bank_3 := unsigned(nsf_data_in);
                        ret.reg.map_enabled := not is_zero(nsf_data_in) or
                                               reg.map_enabled;
                    when x"0074" =>
                        ret.reg.bank_4 := unsigned(nsf_data_in);
                        ret.reg.map_enabled := not is_zero(nsf_data_in) or
                                               reg.map_enabled;
                    when x"0075" =>
                        ret.reg.bank_5 := unsigned(nsf_data_in);
                        ret.reg.map_enabled := not is_zero(nsf_data_in) or
                                               reg.map_enabled;
                    when x"0076" =>
                        ret.reg.bank_6 := unsigned(nsf_data_in);
                        ret.reg.map_enabled := not is_zero(nsf_data_in) or
                                               reg.map_enabled;
                    when x"0077" =>
                        ret.reg.bank_7 := unsigned(nsf_data_in);
                        ret.reg.map_enabled := not is_zero(nsf_data_in) or
                                               reg.map_enabled;
                    when x"007A" =>
                        ret.reg.song_type := nsf_data_in(0);
                    when others =>
                end case;
                
                if reg.cur_cycle = x"7F"
                then
                    ret.reg.cur_state := STATE_RUN;
                    if reg.map_enabled
                    then
                        ret.reg.nsf_offset :=
                            unsigned(reg.load_addr and x"0FFF") + x"0080";
                    end if;
                else
                    ret.reg.cur_cycle := reg.cur_cycle + "1";
                end if;
                
            when STATE_RUN =>
                if nsf_reg.cur_time = x"0000"
                then
                    ret.nmi := not reg.mask_nmi;
                    ret.nsf_reg.cur_time := reg.speed;
                else
                    ret.nmi := false;
                    ret.nsf_reg.cur_time := nsf_reg.cur_time - "1";
                end if;

                v_audio := audio;
                if not enable_square_1
                then
                    v_audio.square_1 := (others => '0');
                end if;
                if not enable_square_2
                then
                    v_audio.square_2 := (others => '0');
                end if;
                if not enable_triangle
                then
                    v_audio.triangle := (others => '0');
                end if;
                if not enable_noise
                then
                    v_audio.noise := (others => '0');
                end if;
                if not enable_dmc
                then
                    v_audio.dmc := (others => '0');
                end if;
                
                ret.audio := mix_audio(v_audio);

                if is_bus_active(dma_bus)
                then
                    v_cpu_bus := dma_bus;
                else
                    v_cpu_bus := cpu_bus;
                end if;

                case v_cpu_bus.address is
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
                    -- Mask NMI
                    when x"3706" =>
                        if is_bus_read(v_cpu_bus)
                        then
                            ret.cpu_data_out :=
                                "0000000" & to_std_logic(reg.mask_nmi);
                        elsif is_bus_write(v_cpu_bus)
                        then
                            ret.reg.mask_nmi := cpu_data_in(0) = '1';
                        end if;
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
                        if v_cpu_bus.address(15 downto 8) = x"38"
                        then
                            ret.cpu_data_out := 
                                get_nsf_byte(v_cpu_bus.address(7 downto 0));
                        elsif is_ram_addr(v_cpu_bus.address)
                        then
                            ret.ram_bus.address := get_ram_addr(v_cpu_bus.address);
                            ret.ram_bus.read := v_cpu_bus.read;
                            ret.ram_bus.write := v_cpu_bus.write;
                            
                            ret.cpu_data_out := ram_data_in;
                            ret.ram_data_out := cpu_data_in;
                        elsif is_sram_addr(v_cpu_bus.address)
                        then
                            ret.sram_bus.address := get_sram_addr(v_cpu_bus.address);
                            ret.sram_bus.read := v_cpu_bus.read;
                            ret.sram_bus.write := v_cpu_bus.write;
                            
                            ret.cpu_data_out := sram_data_in;
                            ret.sram_data_out := cpu_data_in;
                        elsif is_apu_addr(v_cpu_bus.address)
                        then
                            ret.apu_bus.address := get_apu_addr(v_cpu_bus.address);
                            ret.apu_bus.read := v_cpu_bus.read;
                            ret.apu_bus.write := v_cpu_bus.write;
                            
                            ret.cpu_data_out := apu_data_in;
                            ret.apu_data_out := cpu_data_in;
                        elsif reg.map_enabled and
                              v_cpu_bus.address >= x"5FF8" and
                              v_cpu_bus.address <= x"5FFF"
                        then
                            if is_bus_read(v_cpu_bus)
                            then
                                case v_cpu_bus.address is
                                    when x"5FF8" => ret.cpu_data_out := std_logic_vector(reg.bank_0);
                                    when x"5FF9" => ret.cpu_data_out := std_logic_vector(reg.bank_1);
                                    when x"5FFA" => ret.cpu_data_out := std_logic_vector(reg.bank_2);
                                    when x"5FFB" => ret.cpu_data_out := std_logic_vector(reg.bank_3);
                                    when x"5FFC" => ret.cpu_data_out := std_logic_vector(reg.bank_4);
                                    when x"5FFD" => ret.cpu_data_out := std_logic_vector(reg.bank_5);
                                    when x"5FFE" => ret.cpu_data_out := std_logic_vector(reg.bank_6);
                                    when x"5FFF" => ret.cpu_data_out := std_logic_vector(reg.bank_7);
                                    when others  => ret.cpu_data_out := (others => '-');
                                end case;
                            elsif is_bus_write(v_cpu_bus)
                            then
                                case v_cpu_bus.address is
                                    when x"5FF8" => ret.reg.bank_0 := unsigned(cpu_data_in);
                                    when x"5FF9" => ret.reg.bank_1 := unsigned(cpu_data_in);
                                    when x"5FFA" => ret.reg.bank_2 := unsigned(cpu_data_in);
                                    when x"5FFB" => ret.reg.bank_3 := unsigned(cpu_data_in);
                                    when x"5FFC" => ret.reg.bank_4 := unsigned(cpu_data_in);
                                    when x"5FFD" => ret.reg.bank_5 := unsigned(cpu_data_in);
                                    when x"5FFE" => ret.reg.bank_6 := unsigned(cpu_data_in);
                                    when x"5FFF" => ret.reg.bank_7 := unsigned(cpu_data_in);
                                    when others  => null;
                                end case;
                            end if;
                        elsif reg.map_enabled and v_cpu_bus.address >= x"8000"
                        then
                            ret.nsf_bus := get_mapped_nsf_bus(reg, v_cpu_bus);
                            ret.cpu_data_out := nsf_data_in;
                            ret.apu_data_out := nsf_data_in;
                        elsif not reg.map_enabled and
                              v_cpu_bus.address >= reg.load_addr
                        then
                            ret.nsf_bus := get_unmapped_nsf_bus(reg, v_cpu_bus);
                            ret.cpu_data_out := nsf_data_in;
                            ret.apu_data_out := nsf_data_in;
                        end if;
                end case;
                
                case song_sel is
                    when SONG_NEXT =>
                        ret.reg.cur_state := STATE_RESET;
                        ret.reg.cur_cycle := (others => '0');
                        if reg.start_song = reg.total_songs
                        then
                            ret.reg.start_song := x"01";
                        else
                            ret.reg.start_song := reg.start_song + "1";
                        end if;
                    when SONG_PREV =>
                        ret.reg.cur_state := STATE_RESET;
                        ret.reg.cur_cycle := (others => '0');
                        if reg.start_song = x"01"
                        then
                            ret.reg.start_song := reg.total_songs;
                        else
                            ret.reg.start_song := reg.start_song - "1";
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