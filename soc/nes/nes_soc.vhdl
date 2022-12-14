library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.joy_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.chr_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.ppu_bus_types.all;
use work.palette_bus_types.all;
use work.nes_types.all;
use work.nes_core.all;
use work.lib_nes.all;
use work.lib_ppu.all;

entity nes_soc is
port
(
    clk_50mhz : in std_logic;
    reset     : in boolean;

    nes_running : out boolean;

    cpu_clk_en : out boolean;
    ppu_clk_en : out boolean;

    cpu_ram_en : out boolean;
    ppu_ram_en : out boolean;
    
    file_bus       : out file_bus_t;
    data_from_file : in data_t;
    
    sram_bus       : out sram_bus_t;
    data_to_sram   : out data_t;
    data_from_sram : in data_t;
    
    prg_ram_bus       : out ram_bus_t;
    data_to_prg_ram   : out data_t;
    data_from_prg_ram : in data_t;
    
    oam_bus       : out oam_bus_t;
    data_to_oam   : out data_t;
    data_from_oam : in data_t;
    
    sec_oam_bus       : out sec_oam_bus_t;
    data_to_sec_oam   : out data_t;
    data_from_sec_oam : in data_t;
    
    palette_bus       : out palette_bus_t;
    data_to_palette   : out pixel_t;
    data_from_palette : in pixel_t;
    
    ciram_bus       : out chr_bus_t;
    data_to_ciram   : out data_t;
    data_from_ciram : in data_t;
    
    pixel_bus : out pixel_bus_t;
    audio     : out mixed_audio_t;

    joy_strobe : out std_logic;

    shift_joy_1 : out std_logic;
    joy_1_val   : in std_logic := '1';

    shift_joy_2 : out std_logic;
    joy_2_val   : in std_logic := '1'
);
end entity;

architecture behavioral of nes_soc
is

    component file_bus_mux is
    port
    (
        clk    : in std_logic;
        clk_en : in boolean;
        reset  : in boolean;

        file_bus_chr    : in file_bus_t;
        data_to_chr_bus : out data_t;

        file_bus_prg    : in file_bus_t;
        data_to_prg_bus : out data_t;

        file_bus_out    : out file_bus_t;
        data_from_file  : in data_t
    );
    end component;

    signal reg      : reg_t := RESET_REG;
    signal reg_next : reg_t;
    
    signal chr_bus           : chr_bus_t;
    signal chr_data_from_ppu : data_t;
    signal chr_data_to_ppu   : data_t;
    
    signal cpu_bus           : cpu_bus_t;
    signal apu_dma_bus       : cpu_bus_t;
    signal oam_dma_bus       : cpu_bus_t;
    signal oam_dma_cpu_write : boolean;
    signal apu_bus           : apu_bus_t;
    signal joy_bus           : joy_bus_t;
    signal ppu_bus           : ppu_bus_t;
    
    signal oam_bus_from_ppu     : oam_bus_t;
    signal data_to_oam_from_ppu : data_t;
    
    signal sec_oam_bus_from_ppu     : sec_oam_bus_t;
    signal data_to_sec_oam_from_ppu : data_t;
    
    signal palette_bus_from_ppu     : palette_bus_t;
    signal data_to_palette_from_ppu : pixel_t;
    
    signal data_to_cpu       : data_t;
    signal data_from_cpu     : data_t;
    signal data_to_oam_dma   : data_t;
    signal data_from_oam_dma : data_t;
    signal data_to_apu       : data_t;
    signal data_from_apu     : data_t;
    signal data_to_joy       : data_t;
    signal data_from_joy     : data_t;
    signal prg_data_to_ppu   : data_t;
    signal prg_data_from_ppu : data_t;

    signal file_bus_prg       : file_bus_t;
    signal data_from_file_prg : data_t;
    
    signal file_bus_chr       : file_bus_t;
    signal data_from_file_chr : data_t;

    signal cpu_en         : boolean;
    signal ppu_en         : boolean;
    signal ppu_sync       : boolean;
    signal cpu_odd        : boolean;
    signal sig_ppu_ram_en : boolean;
    signal sig_cpu_ram_en : boolean;
    
    signal audio_out : apu_out_t;
    
    signal int_reset : boolean;
    signal nmi : boolean;
    
    signal cart_irq : boolean;
    signal next_cart_irq : boolean;

    signal apu_irq  : boolean;
    signal irq      : boolean;
    
    signal apu_ready : boolean;
    signal dma_ready : boolean;
    signal ready     : boolean;

    signal ppu_time : ppu_time_t;

begin

    nes_running <= not int_reset;

    cpu_clk_en <= cpu_en;
    ppu_clk_en <= ppu_en;

    ppu_ram_en <= sig_ppu_ram_en;
    cpu_ram_en <= sig_cpu_ram_en;

    ready <= apu_ready and dma_ready;

    irq <= apu_irq or cart_irq;

    file_mux : file_bus_mux
    port map
    (
        clk => clk_50mhz,
        clk_en => ppu_en,
        reset => reset,

        file_bus_chr => file_bus_chr,
        data_to_chr_bus => data_from_file_chr,

        file_bus_prg => file_bus_prg,
        data_to_prg_bus => data_from_file_prg,

        file_bus_out => file_bus,
        data_from_file => data_from_file
    );

    nes_clk_en : clk_en
    port map
    (
        clk_50mhz => clk_50mhz,
        reset => reset,
        
        cpu_en => cpu_en,
        ppu_en => ppu_en,

        cpu_ram_en => sig_cpu_ram_en,
        ppu_ram_en => sig_ppu_ram_en,

        ppu_sync => ppu_sync,
        odd_cpu_cycle => cpu_odd
    );

    nes_cpu : cpu
    port map
    (
        clk => clk_50mhz,
        clk_en => cpu_en,
        reset => int_reset,
        
        cpu_bus => cpu_bus,
        data_to_cpu => data_to_cpu,
        data_from_cpu => data_from_cpu,
        
        ready => ready,
        irq => irq,
        nmi => nmi
    );
    
    nes_apu : apu
    port map
    (
        clk => clk_50mhz,
        clk_en => cpu_en,
        clk_odd => cpu_odd,
        reset => int_reset,
        
        cpu_bus => apu_bus,
        data_to_apu => data_to_apu,
        data_from_apu => data_from_apu,
        
        audio => audio_out,

        dma_bus => apu_dma_bus,
        irq => apu_irq,
        ready => apu_ready
    );

    nes_joystick_io : joystick_io
    port map
    (
        clk => clk_50mhz,
        clk_en => cpu_en,
        reset => int_reset,

        cpu_bus => joy_bus,
        data_to_joy => data_to_joy,
        data_from_joy => data_from_joy,

        joy_strobe => joy_strobe,

        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,

        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );

    nes_ppu : ppu
    port map
    (
        clk    => clk_50mhz,
        clk_en => ppu_en,
        clk_sync => ppu_sync,
        reset  => int_reset,

        chr_bus             => chr_bus,
        chr_data_from_ppu   => chr_data_from_ppu,
        chr_data_to_ppu     => chr_data_to_ppu,
        
        oam_bus       => oam_bus_from_ppu,
        data_to_oam   => data_to_oam_from_ppu,
        data_from_oam => data_from_oam,
        
        sec_oam_bus       => sec_oam_bus_from_ppu,
        data_to_sec_oam   => data_to_sec_oam_from_ppu,
        data_from_sec_oam => data_from_sec_oam,
        
        palette_bus => palette_bus_from_ppu,
        data_to_palette => data_to_palette_from_ppu,
        data_from_palette => data_from_palette,
        
        cpu_bus            => ppu_bus,
        prg_data_from_ppu  => prg_data_from_ppu,
        prg_data_to_ppu    => prg_data_to_ppu,

        pixel_bus => pixel_bus,
        vint      => nmi
    );
    
    nes_oam_dma : oam_dma
    port map
    (
        clk => clk_50mhz,
        clk_en => cpu_en,
        clk_odd => cpu_odd,
        reset => int_reset,
        
        write_from_cpu => oam_dma_cpu_write,
        data_to_dma => data_to_oam_dma,
        
        dma_bus => oam_dma_bus,
        data_from_dma => data_from_oam_dma,
        
        ready => dma_ready
    );

    process(all)
    is
        variable nes_in : nes_in_t;
        variable nes_out : nes_out_t;
    begin
        nes_in.reg := reg;
        
        if is_bus_active(oam_dma_bus)
        then
            nes_in.cpu_bus.cpu_bus := oam_dma_bus;
            nes_in.cpu_bus.data_from_cpu := data_from_oam_dma;
        elsif is_bus_active(apu_dma_bus)
        then
            nes_in.cpu_bus.cpu_bus := apu_dma_bus;
            -- APU DMA is read-only, so this is a don't care
            nes_in.cpu_bus.data_from_cpu := data_from_cpu;
        else
            nes_in.cpu_bus.cpu_bus := cpu_bus;
            nes_in.cpu_bus.data_from_cpu := data_from_cpu;
        end if;
        
        nes_in.cpu_bus.data_from_apu := data_from_apu;
        nes_in.cpu_bus.data_from_joy := data_from_joy;
        nes_in.cpu_bus.data_from_ram := data_from_prg_ram;
        nes_in.cpu_bus.data_from_sram := data_from_sram;
        nes_in.cpu_bus.data_from_ppu := prg_data_from_ppu;
        nes_in.cpu_bus.data_from_file := data_from_file_prg;
        
        nes_in.ppu_bus.chr_bus := chr_bus;
        nes_in.ppu_bus.data_from_ppu := chr_data_from_ppu;
        nes_in.ppu_bus.data_from_file := data_from_file_chr;
        nes_in.ppu_bus.data_from_ciram := data_from_ciram;
        
        nes_in.oam_bus := oam_bus_from_ppu;
        nes_in.data_to_oam := data_to_oam_from_ppu;
        nes_in.sec_oam_bus := sec_oam_bus_from_ppu;
        nes_in.data_to_sec_oam := data_to_sec_oam_from_ppu;
        nes_in.palette_bus := palette_bus_from_ppu;
        nes_in.data_to_palette := data_to_palette_from_ppu;
        
        nes_in.audio := audio_out;
        
        nes_out := cycle_nes(nes_in);
        
        reg_next <= nes_out.reg;
        
        apu_bus <= nes_out.cpu_bus.apu_bus;
        joy_bus <= nes_out.cpu_bus.joy_bus;
        prg_ram_bus <= nes_out.cpu_bus.ram_bus;
        sram_bus <= nes_out.cpu_bus.sram_bus;
        ppu_bus <= nes_out.cpu_bus.ppu_bus;
        file_bus_prg <= nes_out.cpu_bus.file_bus;
        oam_dma_cpu_write <= nes_out.cpu_bus.oam_dma_write;
        
        data_to_cpu <= nes_out.cpu_bus.data_to_cpu;
        data_to_oam_dma <= nes_out.cpu_bus.data_to_cpu;
        data_to_joy <= nes_out.cpu_bus.data_to_joy;
        
        if is_bus_read(apu_dma_bus)
        then
            data_to_apu <= nes_out.cpu_bus.data_to_cpu;
        else
            data_to_apu <= nes_out.cpu_bus.data_to_apu;
        end if;
        
        data_to_prg_ram <= nes_out.cpu_bus.data_to_ram;
        data_to_sram <= nes_out.cpu_bus.data_to_sram;
        prg_data_to_ppu <= nes_out.cpu_bus.data_to_ppu;
        
        file_bus_chr <= nes_out.ppu_bus.file_bus;
        ciram_bus <= nes_out.ppu_bus.ciram_bus;
        
        chr_data_to_ppu <= nes_out.ppu_bus.data_to_ppu;
        data_to_ciram <= nes_out.ppu_bus.data_to_ciram;
        
        oam_bus <= nes_out.oam_bus;
        data_to_oam <= nes_out.data_to_oam;
        
        sec_oam_bus <= nes_out.sec_oam_bus;
        data_to_sec_oam <= nes_out.data_to_sec_oam;
        
        palette_bus <= nes_out.palette_bus;
        data_to_palette <= nes_out.data_to_palette;
        
        audio <= nes_out.audio;
        int_reset <= nes_out.reset;

        next_cart_irq <= nes_out.irq;
        
    end process;

    process(clk_50mhz)
    is
    begin
    if rising_edge(clk_50mhz)
    then
        if reset
        then
            reg <= RESET_REG;
        elsif (reg.cur_state = STATE_RUN and ppu_en) or cpu_en
        then
            reg <= reg_next;
        end if;

        if reset
        then
            cart_irq <= false;
        elsif cpu_en
        then
            cart_irq <= next_cart_irq;
        end if;
    end if;
    end process;
    

end behavioral;