library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.nes_types.all;
use work.lib_ppu.all;
use work.utilities.all;
use work.lib_nsf_rom.all;
use work.lib_wm8731.all;

entity nsf_de1 is
port
(
    CLOCK_50 : in std_logic;

    I2C_SDAT : out std_logic;
    I2C_SCLK : out std_logic;
    
    FL_DQ    : in std_logic_vector(7 downto 0);
    FL_ADDR  : out std_logic_vector(21 downto 0);
    FL_WE_N  : out std_logic;
    FL_OE_N  : out std_logic;
    FL_RST_N : out std_logic;
    
    AUD_BCLK    : out std_logic;
    AUD_DACDAT  : out std_logic;
    AUD_DACLRCK : out std_logic
);
end nsf_de1;

architecture behavioral of nsf_de1 is
    type ram_t         is array(0 to 16#7FF#)  of data_t;
    type chr_ram_t     is array(0 to 16#7FF#)  of data_t;
    type sram_t        is array(0 to 16#1FFF#) of data_t;
    type palette_ram_t is array(0 to 16#1F#)   of pixel_t;
    
    type state_t is
    (
        STATE_RESET,
        STATE_LOAD,
        STATE_RUN
    );
    
    type reg_t is record
        prg_rom_size : unsigned(data_t'RANGE);
        chr_rom_size : unsigned(data_t'RANGE);
        mirror_mode  : std_logic_vector(1 downto 0);
        mapper       : data_t;
        cur_state    : state_t;
        cur_time     : unsigned(3 downto 0);
    end record;
    
    signal ram     : ram_t;
    signal sram    : sram_t;
    signal chr_ram : chr_ram_t;
    
    signal reg : reg_t :=
    (
        prg_rom_size => x"00",
        chr_rom_size => x"00",
        mirror_mode  => "00",
        mapper       => x"00",
        cur_state    => STATE_RESET,
        cur_time     => x"0"
    );
    
    signal reg_in : reg_t;
    
    signal apu_bus     : apu_bus_t;
    signal cpu_bus     : cpu_bus_t;
    signal ram_bus     : ram_bus_t;
    signal ram_bus_in  : ram_bus_t;
    signal sram_bus_in : sram_bus_t;
    signal sram_bus    : sram_bus_t;
    
    signal cpu_data_out     : data_t;
    signal cpu_data_in      : data_t;
    signal apu_data_out     : data_t;
    signal apu_data_in      : data_t;
    signal sram_data_out    : data_t;
    signal sram_data_out_in : data_t;
    signal sram_data_in     : data_t;
    signal ram_data_out     : data_t;
    signal ram_data_out_in  : data_t;
    signal ram_data_in      : data_t;
    
    signal audio_out : apu_out_t;
    signal audio     : wm_audio_t;
    
    signal irq   : boolean;
    signal nmi   : boolean;
    signal reset : boolean;
    signal ready : boolean;
    
    signal main_clk : std_logic;
    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;
    signal clk_aud  : std_logic;
    
    signal cpu_count : unsigned(5 downto 0) := "000000";
    signal ppu_count : unsigned(3 downto 0) := "0000";
    
    component nes_pll is
    port
    (
        inclk0 : in std_logic;
        c0     : out std_logic;
        c1     : out std_logic
    );
    end component nes_pll;
    
begin
    
    fl_we_n <= '1';
    fl_oe_n <= '0';
    fl_rst_n <= '1';
    
    -- Audio PLL {
    pll : nes_pll
    port map
    (
        inclk0 => CLOCK_50,
        c0 => clk_aud,
        c1 => main_clk
    );
    -- }
    
    -- WM8731 interface {
    aud_out : wm8731
    port map
    (
        clk => clk_aud,
        reset => reset,
        
        audio => audio,
        
        sclk => i2c_sclk,
        sdat => i2c_sdat,
        
        bclk => aud_bclk,
        dac_dat => aud_dacdat,
        dac_lrck => aud_daclrck
    );
    -- }
    
    -- CPU {
    nes_cpu : cpu
    port map
    (
        clk => cpu_clk,
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
    nes_apu : apu
    port map
    (
        clk => cpu_clk,
        reset => reset,
        
        cpu_bus => apu_bus,
        cpu_data_in => apu_data_out,
        cpu_data_out => apu_data_in,
        
        audio => audio_out,
        irq => irq
    );
    -- }
    
    nes_ppu : entity work.ppu(behavioral)
    port map
    (
        clk => ppu_clk,
        reset => reset,
        
        chr_bus => chr_bus,
        chr_data_in => chr_data_out,
        chr_data_out => chr_data_in,
        
        palette_bus => palette_bus,
        palette_data_in => palette_data_out,
        palette_data_out => paletted_data_in,
        
        ppu_bus => ppu_bus,
        ppu_data_in => ppu_data_out,
        ppu_data_out => ppu_data_in,
        
        pixel_bus => pixel_bus,
        vint => nmi
    );
        
    
    process
    (
        reg,
        fl_dq,
        cpu_bus,
        ram_data_in,
        sram_data_in,
        cpu_data_in,
        apu_data_in,
        audio_out
    )
        variable v_cpu_bus       : cpu_bus_t;
        variable v_cpu_data_in   : data_t;
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
        variable v_ready : boolean;
        
        variable v_audio : wm_audio_t;
        
    begin
        v_reg := reg;
        v_ram_bus := bus_idle(v_ram_bus);
        v_sram_bus := bus_idle(v_sram_bus);
        v_apu_bus := bus_idle(v_apu_bus);
        v_cpu_bus := bus_idle(v_cpu_bus);
        
        v_cpu_data_in := (others => '-');
        v_ram_data_out := (others => '-');
        v_sram_data_out := (others => '-');
        v_cpu_data_out := (others => '-');
        v_apu_data_out := (others => '-');
        v_flash_addr := (others => '-');
        
        v_audio := (others => '-');
        
        v_reset := false;
        v_nmi := false;
        v_ready := true;
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
                    -- PRG ROM Size
                    when x"4" =>
                        v_reg.prg_rom_size := unsigned(fl_dq);
                    -- CHR ROM Size
                    when x"5" =>
                        v_reg.chr_rom_size := unsigned(fl_dq);
                    -- Flags 6
                    when x"6" =>
                        v_reg.mirror_mode := fl_dq(1 downto 0);
                        v_reg.mapper(3 downto 0) := fl_dq(7 downto 4);
                    when x"7" =>
                        v_reg.mapper(7 downto 4) := fl_dq(7 downto 4);
                    when others =>
                end case;
                
                if reg.cur_time = x"F"
                then
                    v_reg.cur_state := STATE_RUN;
                end if;
                
            when STATE_RUN =>
                v_audio := "0" & mix_audio(audio_out) & "00000000";
                
                case reg.dma_state is
                    when DMA_START =>
                        v_ready := false;
                        v_reg.dma_state := DMA_READ;
                        v_reg.dma_addr(7 downto 0) := x"00";
                    when DMA_READ =>
                        v_ready := false;
                        v_cpu_bus := bus_read(reg.dma_addr);
                        v_reg.dma_val := cpu_data_in;
                        v_reg.dma_state := DMA_WRITE;
                    when DMA_WRITE =>
                        v_ready := false;
                        v_cpu_bus := bus_write(x"2003");
                        v_cpu_data_in := reg.dma_val;
                        if reg.dma_addr(7 downto 0) = x"FF"
                        then
                            v_reg.dma_state := DMA_IDLE;
                        else
                            v_reg.dma_state := DMA_READ;
                        end if;
                        v_reg.dma_addr := reg.dma_addr + "1";
                    when DMA_IDLE =>
                        v_ready := true;
                        v_cpu_bus := cpu_bus;
                        v_cpu_data_in := cpu_data_in;
                    when others =>
                        v_ready := true;
                        v_cpu_bus := cpu_bus;
                        v_cpu_data_in := cpu_data_in;
                end case;
                
                if is_ram_addr(v_cpu_bus.address)
                then
                    v_ram_bus.address := get_ram_addr(v_cpu_bus.address);
                    v_ram_bus.read := cpu_bus.read;
                    v_ram_bus.write := cpu_bus.write;
                    
                    v_cpu_data_out := ram_data_in;
                    v_ram_data_out := v_cpu_data_in;
                elsif is_ppu_addr(v_cpu_bus.address)
                then
                    v_ppu_bus.address := get_ppu_addr(v_cpu_bus.address);
                    v_ppu_bus.read := cpu_bus.read;
                    v_ppu_bus.write := cpu_bus.write;
                    
                    v_cpu_data_out := ppu_data_in;
                    v_ppu_data_out := v_cpu_data_in;
                elsif is_apu_addr(v_cpu_bus.address)
                then
                    v_apu_bus.address := get_apu_addr(v_cpu_bus.address);
                    v_apu_bus.read := cpu_bus.read;
                    v_apu_bus.write := cpu_bus.write;
                    
                    v_cpu_data_out := apu_data_in;
                    v_apu_data_out := v_cpu_data_in;
                elsif is_sram_addr(v_cpu_bus.address)
                then
                    v_sram_bus.address := get_sram_addr(v_cpu_bus.address);
                    v_sram_bus.read := cpu_bus.read;
                    v_sram_bus.write := cpu_bus.write;
                    
                    v_cpu_data_out := sram_data_in;
                    v_sram_data_out := v_cpu_data_in;
                elsif is_dma_addr(v_cpu_bus.addres)
                then
                    v_reg.dma_state := DMA_START;
                    v_reg.dma_addr(15 downto 8) := cpu_data_in;
                elsif is_prg_addr(cpu_bus.address)
                then
                    v_prg_flash_addr := unsigned(get_prg_addr(cpu_bus.address)) +
                                        to_unsigned(16, 5);
                    v_cpu_data_out := prg_fl_dq;
                end if;
                
                
                if chr_bus.address >= to_unsigned(16#2000#, chr_addr_t'LENGTH) and
                   chr_bus.address <= to_unsigned(16#27FF#, chr_addr_t'LENGTH)
                then
                    v_chr_ram_bus.address := chr_bus.address(chr_ram_addr_t'RANGE);
                    v_chr_ram_bus.read := chr_bus.read;
                    v_chr_ram_bus.write := chr_bus.write;
                    
                    v_ppu_data_out := chr_ram_data_in;
                    v_chr_ram_data_out := ppu_data_out;
                else
                    v_chr_flash_addr := unsigned(chr_bus.address) +
                                        (resize(reg.prg_rom_size, fl_addr'LENGTH) sll 14) +
                                        to_unsigned(16, 5);
                    v_ppu_data_out := chr_fl_dq;
                end if;
        end case;
        
        apu_bus <= v_apu_bus;
        sram_bus_in <= v_sram_bus;
        ram_bus_in <= v_ram_bus;
        
        sram_data_out_in <= v_sram_data_out;
        apu_data_out <= v_apu_data_out;
        ram_data_out_in <= v_ram_data_out;
        cpu_data_out <= v_cpu_data_out;
        
        reg_in <= v_reg;
        audio <= v_audio;
        reset <= v_reset;
        ready <= v_ready;
        
        fl_addr <= v_flash_addr;
    end process;
    
    -- Register update process {
    process(cpu_clk)
    begin
    if rising_edge(cpu_clk) then
        reg <= reg_in;
    end if;
    end process;
    -- }
    
    process(main_clk)
    begin
    if rising_edge(main_clk)
    then
        if is_bus_write(sram_bus)
        then
            sram(to_integer(sram_bus.address)) <= sram_data_out;
        elsif is_bus_read(sram_bus)
        then
            sram_data_in <= sram(to_integer(sram_bus.address));
        end if;
        
        if is_bus_write(ram_bus)
        then
            ram(to_integer(ram_bus.address)) <= ram_data_out;
        elsif is_bus_read(ram_bus)
        then
            ram_data_in <= ram(to_integer(ram_bus.address));
        end if;
        
        if cpu_count = ZERO(cpu_count)
        then
            cpu_clk <= '1';
            cpu_count <= to_unsigned(41, 6);
        else
            cpu_clk <= '0';
            cpu_count <= cpu_count - "1";
        end if;
        
        if ppu_count = ZERO(ppu_count)
        then
            ppu_clk <= '1';
            ppu_count <= to_unsigned(13, 4);
        else
            ppu_clk <= '0';
            ppu_count <= ppu_count - "1";
        end if;
        
        sram_bus <= sram_bus_in;
        sram_data_out <= sram_data_out_in;
        ram_bus <= ram_bus_in;
        ram_data_out <= ram_data_out_in;
    end if;
    end process;
    -- }
    
end behavioral;