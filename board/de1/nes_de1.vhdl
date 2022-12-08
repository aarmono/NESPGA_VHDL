library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.perhipherals.all;
use work.perhipheral_types.all;
use work.file_bus_types.all;
use work.sram_bus_types.all;
use work.soc.all;
use work.de1_types.all;

entity nes_de1 is
port
(
    CLOCK_50  : in std_logic;
    CLOCK_VGA : in std_logic;
    CLOCK_AUD : in std_logic;
    CLOCK_WE  : in std_logic;
    RESET_N   : in std_logic;

    I2C_SDAT : out std_logic;
    I2C_SCLK : out std_logic;
    
    PS2_CLK : inout std_logic;
    PS2_DAT : inout std_logic;
    
    SW   : in std_logic_vector(9 downto 0);
    LEDR : out std_logic_vector(9 downto 0);
    LEDG : out std_logic_vector(7 downto 0);
    
    FL_DQ    : in std_logic_vector(7 downto 0);
    FL_ADDR  : out std_logic_vector(21 downto 0);
    FL_WE_N  : out std_logic;
    FL_OE_N  : out std_logic;
    FL_RST_N : out std_logic;
    
    SRAM_DQ   : inout std_logic_vector(15 downto 0);
    SRAM_ADDR : out std_logic_vector(17 downto 0);
    SRAM_LB_N : out std_logic;
    SRAM_UB_N : out std_logic;
    SRAM_CE_N : out std_logic;
    SRAM_OE_N : out std_logic;
    SRAM_WE_N : out std_logic;

    VGA_R    : out std_logic_vector(3 downto 0);
    VGA_G    : out std_logic_vector(3 downto 0);
    VGA_B    : out std_logic_vector(3 downto 0);
    VGA_HS   : out std_logic;
    VGA_VS   : out std_logic;
    VGA_LVAL : out std_logic;
    VGA_FVAL : out std_logic;
    
    AUD_BCLK    : out std_logic;
    AUD_DACDAT  : out std_logic;
    AUD_DACLRCK : out std_logic;
    AUD_XCK     : out std_logic
);
end nes_de1;

architecture behavioral of nes_de1 is
    
    signal audio_out : mixed_audio_t;
    signal audio     : wm_audio_t;

    signal pixel_bus : pixel_bus_t;

    signal vga_sram_dq   : std_logic_vector(SRAM_DQ'range);
    signal vga_sram_addr : std_logic_vector(SRAM_ADDR'range);
    signal vga_sram_oe_n : std_logic;
    signal vga_sram_ce_n : std_logic;
    
    signal vga_out : vga_out_t;

    signal reg_audio_cpu_clk : mixed_audio_t := (others => '0');
    signal reg_audio_aud_clk : mixed_audio_t := (others => '0');

    signal cpu_clk_en  : boolean;
    signal ppu_clk_en  : boolean;

    signal nes_running : boolean;

    signal reset : boolean;
    
    signal flash_bus : file_bus_t;
    
    signal joy_strobe : std_logic;
    
    signal shift_joy_1 : std_logic;
    signal joy_1_val   : std_logic;
    signal joy_1_reg   : std_logic_vector(7 downto 0);
    
    signal shift_joy_2 : std_logic;
    signal joy_2_val   : std_logic;
    
begin
    
    reset <= RESET_N = '0';

    FL_ADDR <= resize(flash_bus.address, fl_addr'length);
    FL_WE_N <= '1';
    FL_OE_N <= not to_std_logic(is_bus_read(flash_bus));
    FL_RST_N <= '1';

    VGA_R <= vga_out.color.red;
    VGA_G <= vga_out.color.green;
    VGA_B <= vga_out.color.blue;
    VGA_HS <= vga_out.h_sync;
    VGA_VS <= vga_out.v_sync;
    VGA_LVAL <= to_std_logic(vga_out.lval);
    VGA_FVAL <= to_std_logic(vga_out.fval);
    
    AUD_XCK <= CLOCK_AUD;
    
    LEDR(9) <= SW(9);
    LEDR(8 downto 0) <= (others => '0');
    
    LEDG <= not joy_1_reg;
    
    -- WM8731 interface {
    aud_out : wm8731
    port map
    (
        clk => CLOCK_AUD,
        reset => reset,
        
        audio => audio,
        
        sclk => i2c_sclk,
        sdat => i2c_sdat,
        
        bclk => aud_bclk,
        dac_dat => aud_dacdat,
        dac_lrck => aud_daclrck
    );
    -- }
    
    audio <= "0" & std_logic_vector(reg_audio_aud_clk) & "0000000";

    vram_mux : ppu_video_ram_mux
    generic map
    (
        MEM_TYPE => MEMORY_REGISTER
    )
    port map
    (
        clk_50mhz => CLOCK_50,
        clk_we => CLOCK_WE,
        reset => reset,

        sram_dq => SRAM_DQ,
        sram_addr => SRAM_ADDR,
        sram_lb_n => SRAM_LB_N,
        sram_ub_n => SRAM_UB_N,
        sram_oe_n => SRAM_OE_N,
        sram_we_n => SRAM_WE_N,
        sram_ce_n => SRAM_CE_N,

        ppu_clk_en => ppu_clk_en,
        pixel_bus  => pixel_bus,

        data_to_vga => vga_sram_dq,
        vga_sram_addr => vga_sram_addr,
        vga_sram_oe_n => vga_sram_oe_n,
        vga_sram_ce_n => vga_sram_ce_n
    );

    vga : vga_gen
    port map
    (
        clk => CLOCK_VGA,
        reset => reset,

        sram_dq => vga_sram_dq,
        sram_addr => vga_sram_addr,
        sram_oe_n => vga_sram_oe_n,
        sram_ce_n => vga_sram_ce_n,

        vga_out => vga_out
    );

    nes : nes_soc_ocram
    generic map
    (
        USE_EXT_SRAM => false
    )
    port map
    (
        clk_50mhz => CLOCK_50,
        reset => reset,

        nes_running => nes_running,

        cpu_clk_en => cpu_clk_en,
        ppu_clk_en => ppu_clk_en,

        file_bus => flash_bus,
        data_from_file => FL_DQ,

        pixel_bus => pixel_bus,
        audio => audio_out,
        
        joy_strobe => joy_strobe,
        
        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,
        
        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );
    
    joystick : ps2_joystick
    port map
    (
        clk_key => CLOCK_AUD,
        clk_cpu => CLOCK_50,
        reset => reset,
        
        filter_invalid => SW(9) = '1',
        
        ps2_clk => PS2_CLK,
        ps2_dat => PS2_DAT,
        
        joy_strobe => joy_strobe,
        
        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,
        joy_1_reg => joy_1_reg,
        
        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );

    process(CLOCK_50)
    begin
    if rising_edge(CLOCK_50) then
    if cpu_clk_en then
        if nes_running
        then
            reg_audio_cpu_clk <= audio_out;
        end if;
    end if;
    end if;
    end process;

    process(CLOCK_AUD)
    begin
    if rising_edge(CLOCK_AUD)
    then
        reg_audio_aud_clk <= reg_audio_cpu_clk;
    end if;
    end process;
    
end behavioral;