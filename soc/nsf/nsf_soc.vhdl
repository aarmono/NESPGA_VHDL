library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.nes_core.all;
use work.nes_audio_mixer.all;
use work.lib_nsf.all;
use work.simulation.all;

entity nsf_soc is
port
(
    clk_cpu : in std_logic;
    clk_nsf : in std_logic;
    
    reset_out : out boolean;
    
    next_stb : in std_logic;
    prev_stb : in std_logic;
    
    nsf_bus     : out file_bus_t;
    nsf_data_in : in data_t;
    
    sram_bus      : out sram_bus_t;
    sram_data_out : out data_t;
    sram_data_in  : in data_t;
    
    ram_bus      : out ram_bus_t;
    ram_data_out : out data_t;
    ram_data_in  : in data_t;
    
    enable_square_1 : in boolean;
    enable_square_2 : in boolean;
    enable_triangle : in boolean;
    enable_noise    : in boolean;
    enable_dmc      : in boolean;
    
    audio : out mixed_audio_t
);
end nsf_soc;

architecture behavioral of nsf_soc is
    
    signal reg : reg_t := RESET_REG;
    signal reg_in : reg_t;
    
    signal nsf_reg : nsf_reg_t := RESET_NSF_REG;
    signal nsf_reg_in : nsf_reg_t;
    
    signal song_sel_reg : song_sel_reg_t := RESET_SONG_SEL;
    signal song_sel     : song_sel_t;
    
    signal apu_bus     : apu_bus_t;
    signal cpu_bus     : cpu_bus_t;
    signal dma_bus     : cpu_bus_t;
    
    signal cpu_data_out     : data_t;
    signal cpu_data_in      : data_t;
    signal apu_data_out     : data_t;
    signal apu_data_in      : data_t;
    
    signal irq : boolean;
    signal nmi : boolean;
    signal reset : boolean;
    signal ready : boolean;
    
    signal audio_out   : apu_out_t;
    signal mixed_audio : mixed_audio_t;
begin
    
    reset_out <= reset;
    audio <= mixed_audio;
    song_sel <= song_sel_reg.song_sel;
    
    -- CPU {
    nsf_cpu : cpu
    port map
    (
        clk => clk_cpu,
        reset => reset,
        
        data_bus => cpu_bus,
        data_in => cpu_data_out,
        data_out => cpu_data_in,
        
        ready => ready,
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
        
        audio => audio_out,

        dma_bus => dma_bus,
        irq => irq,
        ready => ready
    );
    -- }
    
    -- Bus Recorder (for testbench) {
    apu_recorder : apu_bus_record
    generic map
    (
        FILEPATH => "C:\\GitHub\\NESPGA_VHDL\\core\\apu\\Sequence.dat"
    )
    port map
    (
        apu_bus => apu_bus,
        apu_data_in => apu_data_out
    );
    -- }
    
    process(all)
        variable nsf_out : nsf_out_t;
        variable nsf_in  : nsf_in_t;
    begin
        nsf_in.reg := reg;
        nsf_in.nsf_reg := nsf_reg;
        
        if is_bus_active(dma_bus)
        then
            nsf_in.bus_in.cpu_bus := dma_bus;
        else
            nsf_in.bus_in.cpu_bus := cpu_bus;
        end if;
        
        nsf_in.bus_in.data_from_cpu := cpu_data_in;
        nsf_in.bus_in.data_from_apu := apu_data_in;
        nsf_in.bus_in.data_from_ram := ram_data_in;
        nsf_in.bus_in.data_from_sram := sram_data_in;
        nsf_in.bus_in.data_from_file := nsf_data_in;
        
        nsf_in.enable_square_1 := enable_square_1;
        nsf_in.enable_square_2 := enable_square_2;
        nsf_in.enable_triangle := enable_triangle;
        nsf_in.enable_noise := enable_noise;
        nsf_in.enable_dmc := enable_dmc;
        nsf_in.audio := audio_out;
        nsf_in.song_sel := song_sel;
    
        nsf_out := cycle_nsf(nsf_in);
        
        apu_bus <= nsf_out.bus_out.apu_bus;
        sram_bus <= nsf_out.bus_out.sram_bus;
        ram_bus <= nsf_out.bus_out.ram_bus;
        nsf_bus <= nsf_out.bus_out.file_bus;
        
        sram_data_out <= nsf_out.bus_out.data_to_sram;
        apu_data_out <= nsf_out.bus_out.data_to_apu;
        ram_data_out <= nsf_out.bus_out.data_to_ram;
        cpu_data_out <= nsf_out.bus_out.data_to_cpu;
        
        reg_in <= nsf_out.reg;
        nsf_reg_in <= nsf_out.nsf_reg;
        
        reset <= nsf_out.reset;
        nmi <= nsf_out.nmi;
        
        mixed_audio <= nsf_out.audio;
    end process;
    
    -- Register update process {
    process(clk_cpu)
    begin
    if rising_edge(clk_cpu) then
        reg <= reg_in;
    end if;
    end process;
    -- }
    
    -- Song selector {
    process(clk_nsf)
    begin
    if rising_edge(clk_nsf)
    then
        if reset
        then
            song_sel_reg <= RESET_SONG_SEL;
        else
            song_sel_reg <= cycle_song_sel(song_sel_reg,
                                           next_stb,
                                           prev_stb,
                                           audio);
        end if;
    end if;
    end process;
    
    process(clk_nsf)
    begin
    if rising_edge(clk_nsf)
    then
        nsf_reg <= nsf_reg_in;
    end if;
    end process;
    
end behavioral;