library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.nes_core.all;
use work.nes_audio_mixer.all;
use work.lib_nsf.all;

entity nsf_soc is
port
(
    clk_cpu : in std_logic;
    clk_nsf : in std_logic;
    
    reset_out : out boolean;
    
    nsf_bus     : out cpu_bus_t;
    nsf_data_in : in data_t;
    
    sram_bus      : out sram_bus_t;
    sram_data_out : out data_t;
    sram_data_in  : in data_t;
    
    ram_bus      : out ram_bus_t;
    ram_data_out : out data_t;
    ram_data_in  : in data_t;
    
    audio : out mixed_audio_t
);
end nsf_soc;

architecture behavioral of nsf_soc is
    
    signal reg : reg_t := RESET_REG;
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
    
    signal audio_out : apu_out_t;
begin
    
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
        
        audio => audio_out,
        irq => irq
    );
    -- }
    
    process
    (
        reg,
        cpu_bus,
        ram_data_in,
        sram_data_in,
        cpu_data_in,
        apu_data_in,
        nsf_data_in,
        audio_out
    )
        variable nsf_out : nsf_out_t;
    begin
        nsf_out := cycle_nsf(reg,
                             cpu_bus,
                             cpu_data_in,
                             ram_data_in,
                             sram_data_in,
                             apu_data_in,
                             nsf_data_in,
                             audio_out);
        
        apu_bus <= nsf_out.apu_bus;
        sram_bus <= nsf_out.sram_bus;
        ram_bus <= nsf_out.ram_bus;
        nsf_bus <= nsf_out.nsf_bus;
        
        sram_data_out <= nsf_out.sram_data_out;
        apu_data_out <= nsf_out.apu_data_out;
        ram_data_out <= nsf_out.ram_data_out;
        cpu_data_out <= nsf_out.cpu_data_out;
        
        reg_in <= nsf_out.reg;
        reset <= nsf_out.reset;
        nmi <= nsf_out.nmi;
        
        audio <= nsf_out.audio;
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