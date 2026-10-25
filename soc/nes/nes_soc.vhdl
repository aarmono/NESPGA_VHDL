library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.joy_bus_types.all;
use work.ram_bus_types.all;
use work.cart_mem_bus_types.all;
use work.chr_bus_types.all;
use work.ciram_bus_types.all;
use work.chip_ram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.ppu_bus_types.all;
use work.palette_bus_types.all;
use work.nes_types.all;
use work.nes_core.all;
use work.cart_types.all;
use work.lib_nes_mmap.all;
use work.lib_nes.all;

entity nes_soc is
generic
(
    -- See clk_en
    CLK_FREQ     : positive := 50_000_000;
    CPU_FREQ_NUM : positive := 39_375_000;
    CPU_FREQ_DEN : positive := 22
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    nes_running : out boolean;

    cpu_clk_en : out boolean;
    ppu_clk_en : out boolean;

    cpu_ram_en : out boolean;
    ppu_ram_en : out boolean;
    
    cart_mem_bus       : out cart_mem_bus_t;
    data_to_cart_mem   : out data_t;
    data_from_cart_mem : in data_t;

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
    
    ciram_bus       : out ciram_bus_t;
    data_to_ciram   : out data_t;
    data_from_ciram : in data_t;

    -- RAM inside the mapper chip
    chip_ram_bus       : out chip_ram_bus_t;
    data_to_chip_ram   : out data_t;
    data_from_chip_ram : in data_t;
    
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

    signal reg      : reg_t := RESET_REG;
    signal reg_next : reg_t;
    
    signal chr_bus           : chr_bus_t;
    signal chr_ale           : boolean;
    signal chr_data_from_ppu : data_t;
    signal chr_data_to_ppu   : data_t;
    
    signal cpu_bus           : cpu_bus_t;
    signal apu_dma_bus       : cpu_bus_t;
    signal oam_dma_bus       : cpu_bus_t;
    signal oam_dma_cpu_write : boolean;

    signal cart_in  : cart_in_t;
    signal cart_out : cart_out_t;
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

    signal cart_mem_bus_prg       : cart_mem_bus_t;
    signal data_to_cart_mem_prg   : data_t;
    signal data_from_cart_mem_prg : data_t;
    signal header_data            : data_t;
    
    signal cart_mem_bus_chr       : cart_mem_bus_t;
    signal data_to_cart_mem_chr   : data_t;
    signal data_from_cart_mem_chr : data_t;

    signal cpu_en         : boolean;
    signal ppu_en         : boolean;
    signal ppu_sync       : boolean;
    signal cpu_odd        : boolean;
    signal sig_ppu_ram_en : boolean;
    signal sig_cpu_ram_en : boolean;
    
    signal audio_out : apu_out_t;

    signal oam_dma_status : oam_dma_status_t;
    
    -- The NES is held in reset from power up, so asserts that only hold
    -- out of reset do not fail at initialization
    signal int_reset : boolean := true;
    signal nmi : boolean;
    
    signal cart_irq : boolean;
    signal next_cart_irq : boolean;

    signal apu_irq  : boolean;
    signal irq      : boolean;
    
    signal apu_ready : boolean;
    signal dma_ready : boolean;
    signal ready     : boolean;

begin

    nes_running <= not int_reset;

    cpu_clk_en <= cpu_en;
    ppu_clk_en <= ppu_en;

    ppu_ram_en <= sig_ppu_ram_en;
    cpu_ram_en <= sig_cpu_ram_en;

    ready <= apu_ready and dma_ready;

    irq <= apu_irq or cart_irq;

    cart_mem_mux : entity work.cart_mem_bus_mux(behavioral)
    port map
    (
        clk => clk,
        clk_en => ppu_en,
        clk_sync => ppu_sync,
        reset => reset,

        cart_mem_bus_chr => cart_mem_bus_chr,
        data_from_chr_bus => data_to_cart_mem_chr,
        data_to_chr_bus => data_from_cart_mem_chr,

        cart_mem_bus_prg => cart_mem_bus_prg,
        data_from_prg_bus => data_to_cart_mem_prg,
        data_to_prg_bus => data_from_cart_mem_prg,

        cart_mem_bus_out => cart_mem_bus,
        data_to_cart_mem => data_to_cart_mem,
        data_from_cart_mem => data_from_cart_mem
    );

    cart_in.ppu.chr_bus <= chr_bus;
    cart_in.ppu.ale <= chr_ale;
    cart_in.ppu.data <= chr_data_from_ppu;

    -- Kept out of the process below so that read data from the cartridge
    -- memory bus does not run cycle_nes again on its way to the cartridge
    cart_in.mem <=
    (
        data_from_prg_rom => data_from_cart_mem_prg,
        data_from_chr_rom => data_from_cart_mem_chr,
        data_from_prg_ram => data_from_cart_mem_prg,
        data_from_chr_ram => data_from_cart_mem_chr,
        data_from_cpu_exram => data_from_cart_mem_prg,
        data_from_ppu_exram => data_from_cart_mem_chr,
        data_from_chip_ram => data_from_chip_ram
    );

    -- The header is only read while loading, so that otherwise read data
    -- from the cartridge memory bus does not run cycle_nes again
    header_data <= data_from_cart_mem_prg when reg.cur_state = STATE_LOAD else
                   (others => '-');

    nes_cart : entity work.cartridge(behavioral)
    port map
    (
        clk => clk,
        clk_en => ppu_en,
        clk_sync => ppu_sync,
        reset => int_reset,

        config => reg.cart_config,

        cart_in => cart_in,
        cart_out => cart_out
    );

    nes_clk_en : clk_en
    generic map
    (
        CLK_FREQ => CLK_FREQ,
        CPU_FREQ_NUM => CPU_FREQ_NUM,
        CPU_FREQ_DEN => CPU_FREQ_DEN
    )
    port map
    (
        clk => clk,
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
        clk => clk,
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
        clk => clk,
        clk_en => cpu_en,
        clk_odd => cpu_odd,
        reset => int_reset,

        cpu_write => is_bus_write(cpu_bus),
        oam_dma => oam_dma_status,
        
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
        clk => clk,
        clk_en => cpu_en,
        clk_odd => cpu_odd,
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
        clk    => clk,
        clk_en => ppu_en,
        clk_sync => ppu_sync,
        reset  => int_reset,

        chr_bus             => chr_bus,
        chr_ale             => chr_ale,
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
        clk => clk,
        clk_en => cpu_en,
        clk_odd => cpu_odd,
        reset => int_reset,

        pause_dma => is_bus_active(apu_dma_bus),
        
        write_from_cpu => oam_dma_cpu_write,
        data_to_dma => data_to_oam_dma,
        
        dma_bus => oam_dma_bus,
        data_from_dma => data_from_oam_dma,
        
        status => oam_dma_status,

        ready => dma_ready
    );

    process(all)
    is
        variable nes_in : nes_in_t;
        variable nes_out : nes_out_t;
    begin
        nes_in.reg := reg;
        
        if is_bus_active(apu_dma_bus)
        then
            nes_in.cpu_bus.cpu_bus := apu_dma_bus;
            -- APU DMA is read-only, so this is a don't care
            nes_in.cpu_bus.data_from_cpu := data_from_cpu;
            nes_in.cpu_bus.dma_cycle := true;
        elsif is_bus_active(oam_dma_bus)
        then
            nes_in.cpu_bus.cpu_bus := oam_dma_bus;
            nes_in.cpu_bus.data_from_cpu := data_from_oam_dma;
            nes_in.cpu_bus.dma_cycle := true;
        else
            nes_in.cpu_bus.cpu_bus := cpu_bus;
            nes_in.cpu_bus.data_from_cpu := data_from_cpu;
            nes_in.cpu_bus.dma_cycle := false;
        end if;

        cart_in.cpu <= get_cart_cpu_in(nes_in.cpu_bus.cpu_bus,
                                       nes_in.cpu_bus.data_from_cpu);

        nes_in.cpu_bus.clk_sync := ppu_sync;
        nes_in.cpu_bus.apu_regs_active :=
            is_bus_active(cpu_bus) and
            cpu_bus.address(15 downto 5) = "01000000000";
        
        nes_in.cpu_bus.data_from_apu := data_from_apu;
        nes_in.cpu_bus.data_from_joy := data_from_joy;
        nes_in.cpu_bus.data_from_ram := data_from_prg_ram;
        nes_in.cpu_bus.data_from_ppu := prg_data_from_ppu;
        nes_in.data_from_cart_mem := header_data;
        
        nes_in.ppu_bus.chr_bus := chr_bus;
        nes_in.ppu_bus.data_from_ppu := chr_data_from_ppu;
        nes_in.ppu_bus.data_from_ciram := data_from_ciram;

        nes_in.cart := cart_out;
        
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
        ppu_bus <= nes_out.cpu_bus.ppu_bus;
        cart_mem_bus_prg <= nes_out.prg_cart_mem_bus;
        data_to_cart_mem_prg <= nes_out.data_to_prg_cart_mem;
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
        prg_data_to_ppu <= nes_out.cpu_bus.data_to_ppu;
        
        cart_mem_bus_chr <= nes_out.chr_cart_mem_bus;
        data_to_cart_mem_chr <= nes_out.data_to_chr_cart_mem;
        ciram_bus <= nes_out.ppu_bus.ciram_bus;
        chip_ram_bus <= nes_out.chip_ram_bus;
        data_to_chip_ram <= nes_out.data_to_chip_ram;
        
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

    process(clk)
    is
    begin
    if rising_edge(clk)
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