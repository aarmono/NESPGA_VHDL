library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_nsf_rom.all;

entity nsf_soc is
port
(
    clk_cpu : in std_logic;
    clk_nsf : in std_logic;
    
    reset_out : out boolean;
    
    fl_dq    : in std_logic_vector(7 downto 0);
    fl_addr  : out std_logic_vector(21 downto 0);
    fl_we_n  : out std_logic;
    fl_oe_n  : out std_logic;
    fl_rst_n : out std_logic;
    
    sram_bus      : out sram_bus_t;
    sram_data_out : out data_t;
    sram_data_in  : in data_t;
    
    ram_bus      : out ram_bus_t;
    ram_data_out : out data_t;
    ram_data_in  : in data_t;
    
    audio : out apu_out_t
);
end nsf_soc;

architecture behavioral of nsf_soc is
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
    
    signal reg : reg_t :=
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
    
    signal reg_in : reg_t;
    
    signal apu_bus     : apu_bus_t;
    signal cpu_bus     : cpu_bus_t;
    
    signal cpu_data_out     : data_t;
    signal cpu_data_in      : data_t;
    signal apu_data_out     : data_t;
    signal apu_data_in      : data_t;
    
    signal irq : boolean;
    signal nmi : boolean;
    signal reset : boolean;
begin
    
    fl_we_n <= '1';
    fl_oe_n <= '0';
    fl_rst_n <= '1';
    
    reset_out <= reset;
    
    -- CPU {
    nsf_cpu : cpu
    port map
    (
        clk => clk_cpu,
        reset => reset,
        
        data_bus => cpu_bus,
        data_in => cpu_data_out,
        data_out => cpu_data_in,
        
        ready => true,
        irq => irq,
        nmi => nmi
    );
    -- }
    
    -- APU {
    nsf_apu : apu
    port map
    (
        clk => clk_cpu,
        reset => reset,
        
        cpu_bus => apu_bus,
        cpu_data_in => apu_data_out,
        cpu_data_out => apu_data_in,
        
        audio => audio,
        irq => irq
    );
    -- }
    
    process
    (
        reg,
        fl_dq,
        cpu_bus,
        ram_data_in,
        sram_data_in,
        cpu_data_in,
        apu_data_in
    )
        variable v_ram_bus       : ram_bus_t;
        variable v_sram_bus      : sram_bus_t;
        variable v_apu_bus       : apu_bus_t;
        variable v_ram_data_out  : data_t;
        variable v_sram_data_out : data_t;
        variable v_apu_data_out  : data_t;
        variable v_cpu_data_out  : data_t;
        variable v_reg           : reg_t;
        variable v_flash_addr    : std_logic_vector(fl_addr'RANGE);
        
        variable v_reset : boolean;
        variable v_nmi   : boolean;
        
        constant RESET_ADDR : cpu_addr_t := x"3800";
        constant NMI_ADDR : cpu_addr_t := x"3880";
    begin
        v_reg := reg;
        v_ram_bus := bus_idle(v_ram_bus);
        v_sram_bus := bus_idle(v_sram_bus);
        v_apu_bus := bus_idle(v_apu_bus);
        
        v_ram_data_out := (others => '-');
        v_sram_data_out := (others => '-');
        v_cpu_data_out := (others => '-');
        v_apu_data_out := (others => '-');
        v_flash_addr := (others => '-');
        
        v_reset := false;
        v_nmi := false;
        case reg.cur_state is
            when STATE_RESET =>
                v_reset := true;
                v_ram_bus := bus_write(reg.cur_time(ram_addr_t'RANGE));
                v_sram_bus := bus_write(reg.cur_time(sram_addr_t'RANGE));
                
                v_ram_data_out := x"00";
                v_sram_data_out := x"00";
            
                v_reg.cur_time := reg.cur_time + "1";
                if reg.cur_time = x"1FFF"
                then
                    v_reg.cur_time := x"0000";
                    v_reg.cur_state := STATE_LOAD;
                end if;
            when STATE_LOAD =>
                v_reset := true;
                v_flash_addr := resize(std_logic_vector(reg.cur_time),
                                       v_flash_addr'LENGTH);
                case reg.cur_time is
                    -- Total Songs
                    when x"0006" =>
                        v_reg.total_songs := unsigned(fl_dq);
                    -- Starting Song
                    when x"0007" =>
                        v_reg.start_song := unsigned(fl_dq);
                    -- Load Addr Low
                    when x"0008" =>
                        v_reg.load_addr(7 downto 0) := fl_dq;
                    -- Load Addr High
                    when x"0009" =>
                        v_reg.load_addr(15 downto 8) := fl_dq;
                    -- Init Addr Low
                    when x"000A" =>
                        v_reg.init_addr(7 downto 0) := fl_dq;
                    -- Init Addr High
                    when x"000B" =>
                        v_reg.init_addr(15 downto 8) := fl_dq;
                    -- Play Addr Low
                    when x"000C" =>
                        v_reg.play_addr(7 downto 0) := fl_dq;
                    -- Play Addr High
                    when x"000D" =>
                        v_reg.play_addr(15 downto 8) := fl_dq;
                    -- Speed Low, NTSC
                    when x"006E" =>
                        v_reg.speed(7 downto 0) := unsigned(fl_dq);
                    -- Speed High, NTSC
                    when x"006F" =>
                        v_reg.speed(15 downto 8) := unsigned(fl_dq);
                    when x"007A" =>
                        v_reg.song_type := fl_dq(0);
                    when others =>
                end case;
                
                if reg.cur_time = x"7F"
                then
                    v_reg.cur_state := STATE_RUN;
                    v_reg.cur_time := v_reg.speed;
                else
                    v_reg.cur_time := reg.cur_time + "1";
                end if;
                
            when STATE_RUN =>
                if reg.cur_time = x"0000"
                then
                    v_nmi := true;
                    v_reg.cur_time := reg.speed;
                else
                    v_nmi := false;
                    v_reg.cur_time := reg.cur_time - "1";
                end if;
                
                case cpu_bus.address is
                    --Current Song
                    when x"3700" =>
                        v_cpu_data_out := std_logic_vector(reg.start_song - "1");
                    -- Song type (NTSC or PAL)
                    when x"3701" =>
                        v_cpu_data_out := "0000000" & reg.song_type;
                    -- Init Address Low
                    when x"3702" =>
                        v_cpu_data_out := reg.init_addr(7 downto 0);
                    -- Init Address High
                    when x"3703" =>
                        v_cpu_data_out := reg.init_addr(15 downto 8);
                    -- Play Address Low
                    when x"3704" =>
                        v_cpu_data_out := reg.play_addr(7 downto 0);
                    -- Play Address High
                    when x"3705" =>
                        v_cpu_data_out := reg.play_addr(15 downto 8);
                    -- Reset Address Low
                    when x"FFFC" =>
                        v_cpu_data_out := RESET_ADDR(7 downto 0);
                    -- Reset Address High
                    when x"FFFD" =>
                        v_cpu_data_out := RESET_ADDR(15 downto 8);
                    -- NMI Address Low
                    when x"FFFA" =>
                        v_cpu_data_out := NMI_ADDR(7 downto 0);
                    -- NMI Address High
                    when x"FFFB" =>
                        v_cpu_data_out := NMI_ADDR(15 downto 8);
                    when others =>
                        if cpu_bus.address(15 downto 8) = x"38"
                        then
                            v_cpu_data_out := 
                                get_nsf_byte(cpu_bus.address(7 downto 0));
                        elsif is_ram_addr(cpu_bus.address)
                        then
                            v_ram_bus.address := get_ram_addr(cpu_bus.address);
                            v_ram_bus.read := cpu_bus.read;
                            v_ram_bus.write := cpu_bus.write;
                            
                            v_cpu_data_out := ram_data_in;
                            v_ram_data_out := cpu_data_in;
                        elsif is_sram_addr(cpu_bus.address)
                        then
                            v_sram_bus.address := get_sram_addr(cpu_bus.address);
                            v_sram_bus.read := cpu_bus.read;
                            v_sram_bus.write := cpu_bus.write;
                            
                            v_cpu_data_out := sram_data_in;
                            v_sram_data_out := cpu_data_in;
                        elsif is_apu_addr(cpu_bus.address)
                        then
                            v_apu_bus.address := get_apu_addr(cpu_bus.address);
                            v_apu_bus.read := cpu_bus.read;
                            v_apu_bus.write := cpu_bus.write;
                            
                            v_cpu_data_out := apu_data_in;
                            v_apu_data_out := cpu_data_in;
                        elsif cpu_bus.address >= reg.load_addr
                        then
                            v_flash_addr := 
                                resize(std_logic_vector(unsigned(cpu_bus.address) -
                                                        unsigned(reg.load_addr) +
                                                        x"80"), v_flash_addr'LENGTH);
                            v_cpu_data_out := fl_dq;
                        end if;
                end case;
        end case;
        
        apu_bus <= v_apu_bus;
        sram_bus <= v_sram_bus;
        ram_bus <= v_ram_bus;
        
        sram_data_out <= v_sram_data_out;
        apu_data_out <= v_apu_data_out;
        ram_data_out <= v_ram_data_out;
        cpu_data_out <= v_cpu_data_out;
        
        reg_in <= v_reg;
        reset <= v_reset;
        nmi <= v_nmi;
        
        fl_addr <= v_flash_addr;
    end process;
    
    -- Register update process {
    process(clk_nsf)
    begin
    if rising_edge(clk_nsf) then
        reg <= reg_in;
    end if;
    end process;
    -- }
    
end behavioral;