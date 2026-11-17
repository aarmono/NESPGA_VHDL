library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.joy_bus_types.all;
use work.ram_bus_types.all;
use work.chr_bus_types.all;
use work.ciram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.ppu_bus_types.all;
use work.palette_bus_types.all;
use work.nes_types.all;
use work.nes_core.all;
use work.cart_connector_types.all;
use work.lib_nes_mmap.all;
use work.lib_nes.all;

-- The NES console: the CPU, APU and PPU, OAM DMA and the joystick ports, with
-- its RAMs on buses. It talks to the cartridge only through the cartridge
-- connector, the clock enables and the cartridge audio
entity nes_console is
generic
(
    -- See clk_en
    CLK_FREQ     : positive := 50_000_000;
    CPU_FREQ_NUM : positive := 39_375_000;
    CPU_FREQ_DEN : positive := 22;
    -- What the RAMs contain after power up. See power_up_mode_t
    POWER_UP_MODE : power_up_mode_t := POWER_UP_ZERO;
    -- See power_up_fill
    POWER_UP_SEED : natural := 0;
    -- See clk_en
    INVERT_CYCLE_PARITY : boolean := false
);
port
(
    clk   : in std_logic;
    reset : in boolean;
    -- The reset button. It resets the CPU and PPU like the reset button of
    -- a front loading NES, except that the PPU's frame keeps running (see
    -- soft_reset_ppu_reg), and is ignored until the NES is running. The
    -- cartridge has no reset line, so it is not reset
    soft_reset : in boolean := false;
    -- Run as a Famicom rather than a front loading NES: the PPU's reset pin
    -- is tied high, so it ignores no writes after power up and the reset
    -- button resets only the CPU and APU (see ppu). Must be stable while
    -- reset is true
    famicom : in boolean := false;

    nes_running : out boolean;

    -- Lengthens a CPU cycle by one clock, to slow the NES down a little so a
    -- board can keep it in step with something else. See clk_en
    stretch : in boolean := false;
    -- Once its RAMs are ready after reset, the NES leaves reset when run is
    -- true. Until then it waits with waiting_to_run true, and the PPU is held
    -- where it will start, ppu_start, so that a board can start the NES when
    -- it chooses. Sampled on cpu_clk_en
    run            : in boolean := true;
    waiting_to_run : out boolean;
    -- Where in its frame the PPU starts when the NES leaves reset. Final
    -- once waiting_to_run is true
    ppu_start      : out ppu_position_t;

    cpu_clk_en : out boolean;
    ppu_clk_en : out boolean;
    -- Set on the PPU clock enables of the part of a CPU cycle that lines up
    -- with the CPU's. See clk_en
    clk_sync   : out boolean;

    cpu_ram_en : out boolean;
    ppu_ram_en : out boolean;

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
    
    pixel_bus : out pixel_bus_t;
    audio     : out mixed_audio_t;

    joy_strobe : out std_logic;

    joy_1_clk  : out std_logic;
    joy_1_data : in joy_data_t := JOY_DATA_IDLE;

    joy_2_clk  : out std_logic;
    joy_2_data : in joy_data_t := JOY_DATA_IDLE;

    -- The CPU side of the cartridge connector. Like the CPU bus, it is only
    -- valid at cpu_clk_en
    cart_cpu_in  : out cart_cpu_in_t;
    cart_cpu_out : in cart_cpu_out_t;
    -- The value on the CPU data bus, which the connector shares: the write
    -- data, the read data of the console's own registers and RAM, or what
    -- the cartridge drove. Where nothing drove it, the value it held: the
    -- open bus value. Valid at cpu_clk_en. A connector on pins (cart_slot)
    -- drives it on reads of the console's own addresses, as the console's
    -- chips drive the shared bus
    cpu_data_bus : out data_t;
    -- The PPU side of the cartridge connector. Only valid at ppu_clk_en
    cart_ppu_in  : out cart_ppu_in_t;
    cart_ppu_out : in cart_ppu_out_t;
    -- The audio of the chips on the cartridge, mixed with the console's
    cart_audio   : in cart_audio_t := 0;

    -- The fill of the RAMs after reset starts on the CPU cycle after this
    -- is true and the power up data is ready. A board that fills RAMs of
    -- its own from the power up data holds it false until they can start
    -- on the same CPU cycle. Sampled on cpu_clk_en
    power_up_start : in boolean := true;

    -- The data the RAMs are filled with after power up, for a board that
    -- fills RAMs of its own with it too. It steps once per CPU cycle of
    -- the fill. See power_up_fill
    power_up_ready : out boolean;
    power_up_data  : out power_up_data_t
);
end entity;

architecture behavioral of nes_console
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
    signal int_soft_reset : boolean := false;
    -- OAM DMA and the joystick port are reset the same by both
    signal dma_joy_reset : boolean;
    signal nmi : boolean;
    
    signal cart_irq : boolean;
    signal next_cart_irq : boolean;

    signal apu_irq  : boolean;
    signal irq      : boolean;
    
    signal fill_enable : boolean;
    signal fill_step   : boolean;
    signal fill_ready  : boolean;
    signal fill_data   : power_up_data_t;

    signal apu_ready : boolean;
    signal dma_ready : boolean;
    signal ready     : boolean;

begin

    nes_running <= not int_reset;
    waiting_to_run <= reg.cur_state = STATE_WAIT;

    dma_joy_reset <= int_reset or int_soft_reset;

    fill : entity work.power_up_fill
    generic map
    (
        MODE => POWER_UP_MODE,
        SEED => POWER_UP_SEED
    )
    port map
    (
        clk => clk,
        enable => reset,
        step => fill_step,
        ready => fill_ready,
        data => fill_data
    );

    -- The power up data steps once per CPU cycle, so that it holds for the
    -- whole CPU cycle reset holds each write to the cartridge memory bus,
    -- which is served in any of its PPU cycles
    fill_step <= fill_enable and cpu_en;

    power_up_ready <= fill_ready;
    power_up_data <= fill_data;

    cpu_clk_en <= cpu_en;
    ppu_clk_en <= ppu_en;
    clk_sync <= ppu_sync;

    ppu_ram_en <= sig_ppu_ram_en;
    cpu_ram_en <= sig_cpu_ram_en;

    ready <= apu_ready and dma_ready;

    irq <= apu_irq or cart_irq;

    cart_ppu_in.chr_bus <= chr_bus;
    cart_ppu_in.ale <= chr_ale;
    cart_ppu_in.data <= chr_data_from_ppu;

    nes_clk_en : clk_en
    generic map
    (
        CLK_FREQ => CLK_FREQ,
        CPU_FREQ_NUM => CPU_FREQ_NUM,
        CPU_FREQ_DEN => CPU_FREQ_DEN,
        INVERT_CYCLE_PARITY => INVERT_CYCLE_PARITY
    )
    port map
    (
        clk => clk,
        reset => reset,
        stretch => stretch,
        
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
        soft_reset => int_soft_reset,
        
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
        soft_reset => int_soft_reset,

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
        reset => dma_joy_reset,

        cpu_bus => joy_bus,
        data_to_joy => data_to_joy,
        data_from_joy => data_from_joy,

        joy_strobe => joy_strobe,

        joy_1_clk => joy_1_clk,
        joy_1_data => joy_1_data,

        joy_2_clk => joy_2_clk,
        joy_2_data => joy_2_data
    );

    nes_ppu : ppu
    port map
    (
        clk    => clk,
        clk_en => ppu_en,
        clk_sync => ppu_sync,
        reset  => int_reset,
        soft_reset => int_soft_reset,
        famicom => famicom,
        -- The PPU reloads this on every PPU cycle of reset. The power up data
        -- last changes with the last step of the RAM fill, so the PPU starts
        -- from that value, which holds through the end of reset
        power_up_seed => fill_data(ppu_power_up_seed_t'range),
        start_position => ppu_start,

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
        reset => dma_joy_reset,

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

        cart_cpu_in <= get_cart_cpu_in(nes_in.cpu_bus.cpu_bus,
                                       nes_in.cpu_bus.data_from_cpu);

        nes_in.cpu_bus.clk_sync := ppu_sync;
        nes_in.cpu_bus.apu_regs_active :=
            is_bus_active(cpu_bus) and
            cpu_bus.address(15 downto 5) = "01000000000";
        
        nes_in.cpu_bus.data_from_apu := data_from_apu;
        nes_in.cpu_bus.data_from_joy := data_from_joy;
        nes_in.cpu_bus.data_from_ram := data_from_prg_ram;
        nes_in.cpu_bus.data_from_ppu := prg_data_from_ppu;
        
        nes_in.ppu_bus.chr_bus := chr_bus;
        nes_in.ppu_bus.data_from_ppu := chr_data_from_ppu;
        nes_in.ppu_bus.data_from_ciram := data_from_ciram;

        nes_in.cart_cpu := cart_cpu_out;
        nes_in.cart_ppu := cart_ppu_out;
        nes_in.cart_audio := cart_audio;
        
        nes_in.oam_bus := oam_bus_from_ppu;
        nes_in.data_to_oam := data_to_oam_from_ppu;
        nes_in.sec_oam_bus := sec_oam_bus_from_ppu;
        nes_in.data_to_sec_oam := data_to_sec_oam_from_ppu;
        nes_in.palette_bus := palette_bus_from_ppu;
        nes_in.data_to_palette := data_to_palette_from_ppu;
        
        nes_in.audio := audio_out;

        nes_in.power_up_ready := fill_ready and power_up_start;
        nes_in.power_up_data := fill_data;

        nes_in.soft_reset := soft_reset;
        nes_in.run := run;
        
        nes_out := cycle_nes(nes_in);
        
        reg_next <= nes_out.reg;
        
        apu_bus <= nes_out.cpu_bus.apu_bus;
        joy_bus <= nes_out.cpu_bus.joy_bus;
        prg_ram_bus <= nes_out.cpu_bus.ram_bus;
        ppu_bus <= nes_out.cpu_bus.ppu_bus;
        oam_dma_cpu_write <= nes_out.cpu_bus.oam_dma_write;
        
        data_to_cpu <= nes_out.cpu_bus.data_to_cpu;
        cpu_data_bus <= nes_out.cpu_bus.ext_data;
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
        int_soft_reset <= nes_out.soft_reset;
        fill_enable <= nes_out.power_up_enable;

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