library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.nes_types.all;
use work.lib_nsf.all;
use work.nes_core.all;

entity nsf_soc is
port
(
    clk_50mhz : in std_logic;
    reset_in  : in boolean;
    
    reset_out : out boolean;
    
    next_stb : in std_logic;
    prev_stb : in std_logic;
    
    file_bus       : out file_bus_t;
    data_from_file : in data_t;

    cpu_ram_en : out boolean;
    
    sram_bus       : out sram_bus_t;
    data_to_sram   : out data_t;
    data_from_sram : in data_t;
    
    ram_bus       : out ram_bus_t;
    data_to_ram   : out data_t;
    data_from_ram : in data_t;
    
    enable_square_1 : in boolean := true;
    enable_square_2 : in boolean := true;
    enable_triangle : in boolean := true;
    enable_noise    : in boolean := true;
    enable_dmc      : in boolean := true;
    
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
    
    signal data_from_cpu    : data_t;
    signal data_to_cpu      : data_t;
    signal data_from_apu    : data_t;
    signal data_to_apu      : data_t;
    
    signal irq : boolean;
    signal nmi : boolean;
    signal reset : boolean;
    signal ready : boolean;

    signal clk_odd : boolean;
    
    signal audio_out   : apu_out_t;
    signal mixed_audio : mixed_audio_t;
    
    signal cpu_en : boolean;
    signal nsf_en : boolean;
begin
    
    reset_out <= reset;
    audio <= mixed_audio;
    song_sel <= song_sel_reg.song_sel;
    
    nsf_clk_en : clk_en
    port map
    (
        clk_50mhz => clk_50mhz,
        reset => false,
        
        cpu_en => cpu_en,
        nsf_en => nsf_en,

        cpu_ram_en => cpu_ram_en,

        odd_cpu_cycle => clk_odd
    );
    
    -- CPU {
    nsf_cpu : cpu
    port map
    (
        clk => clk_50mhz,
        clk_en => cpu_en,
        reset => reset,
        
        cpu_bus => cpu_bus,
        data_to_cpu => data_to_cpu,
        data_from_cpu => data_from_cpu,
        
        ready => ready,
        irq => irq,
        nmi => nmi
    );
    -- }
    
    -- APU {
    nsf_apu : apu
    port map
    (
        clk => clk_50mhz,
        clk_en => cpu_en,
        clk_odd => clk_odd,
        reset => reset,
        
        cpu_bus => apu_bus,
        data_to_apu => data_to_apu,
        data_from_apu => data_from_apu,
        
        audio => audio_out,

        dma_bus => dma_bus,
        irq => irq,
        ready => ready
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
        
        nsf_in.bus_in.data_from_cpu := data_from_cpu;
        nsf_in.bus_in.data_from_apu := data_from_apu;
        nsf_in.bus_in.data_from_ram := data_from_ram;
        nsf_in.bus_in.data_from_sram := data_from_sram;
        nsf_in.bus_in.data_from_file := data_from_file;
        -- No PPU
        nsf_in.bus_in.data_from_ppu := (others => '-');
        -- No joystick
        nsf_in.bus_in.data_from_joy := (others => '-');
        
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
        file_bus <= nsf_out.bus_out.file_bus;
        
        if is_bus_read(dma_bus)
        then
            data_to_apu <= nsf_out.bus_out.data_to_cpu;
        else
            data_to_apu <= nsf_out.bus_out.data_to_apu;
        end if;
        
        data_to_sram <= nsf_out.bus_out.data_to_sram;
        data_to_ram <= nsf_out.bus_out.data_to_ram;
        data_to_cpu <= nsf_out.bus_out.data_to_cpu;
        
        reg_in <= nsf_out.reg;
        nsf_reg_in <= nsf_out.nsf_reg;
        
        reset <= nsf_out.reset;
        nmi <= nsf_out.nmi;
        
        mixed_audio <= nsf_out.audio;
    end process;
    
    -- Register update process {
    process(clk_50mhz)
    begin
    if rising_edge(clk_50mhz) then
    if cpu_en then
        if reset_in
        then
            reg <= RESET_REG;
        else
            reg <= reg_in;
        end if;
    end if;
    end if;
    end process;
    -- }
    
    -- Song selector {
    process(clk_50mhz)
    begin
    if rising_edge(clk_50mhz) then
    if nsf_en then
        if reset_in
        then
            song_sel_reg <= RESET_SONG_SEL;
        else
            song_sel_reg <= cycle_song_sel(song_sel_reg,
                                           next_stb,
                                           prev_stb,
                                           mixed_audio);
        end if;
        
        nsf_reg <= nsf_reg_in;
    end if;
    end if;
    end process;
    
end behavioral;
