library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.perhipheral_types.all;

package de1_types is
    
    type rom_config_t is
    (
        ROM_FLASH_TO_SDRAM,
        ROM_SD_TO_SDRAM
    );

    subtype vga_channel_t is std_logic_vector(3 downto 0);

    type vga_color_t is record
        red   : vga_channel_t;
        green : vga_channel_t;
        blue  : vga_channel_t;
    end record;
    
    constant COLOR_BLACK : vga_color_t :=
    (
        red => (others => '0'),
        green => (others => '0'),
        blue => (others => '0')
    );
    
    constant COLOR_RED : vga_color_t :=
    (
        red => (others => '1'),
        green => (others => '0'),
        blue => (others => '0')
    );
    
    type vga_out_t is record
        color  : vga_color_t;
        h_sync : std_logic;
        v_sync : std_logic;
        lval   : boolean;
        fval   : boolean;
    end record;
    
    constant VGA_RESET : vga_out_t :=
    (
        color => COLOR_BLACK,
        h_sync => '1',
        v_sync => '1',
        lval => false,
        fval => false
    );

    subtype pixel_addr_t is unsigned(15 downto 0);
    constant PIXEL_ADDR_MAX : pixel_addr_t :=
        to_unsigned(61439, pixel_addr_t'length);
    
    component vga_gen is
    port
    (
        clk     : in std_logic;
        reset   : in boolean;

        sram_dq   : in std_logic_vector(15 downto 0);
        sram_addr : out std_logic_vector(17 downto 0);
        sram_oe_n : out std_logic;
        sram_ce_n : out std_logic;

        vga_out     : out vga_out_t
    );
    end component vga_gen;

    component ppu_video_ram_mux is
    generic
    (
        MEM_TYPE : memory_type_t := MEMORY_INFERRED
    );
    port
    (
        clk_50mhz : in std_logic;
        clk_we    : in std_logic;
        reset     : in boolean;

        sram_dq   : inout std_logic_vector(15 downto 0);
        sram_addr : out std_logic_vector(17 downto 0);
        sram_lb_n : out std_logic;
        sram_ub_n : out std_logic;
        sram_oe_n : out std_logic;
        sram_we_n : out std_logic;
        sram_ce_n : out std_logic;

        ppu_clk_en  : in boolean;
        pixel_bus   : in pixel_bus_t;

        data_to_vga    : out std_logic_vector(15 downto 0);
        vga_sram_addr  : in std_logic_vector(17 downto 0);
        vga_sram_oe_n  : in std_logic;
        vga_sram_ce_n  : in std_logic
    );
    end component ppu_video_ram_mux;
    
    component ps2_joystick is
    port
    (
        clk_key : in std_logic;
        clk_cpu : in std_logic;
        -- Resets synchronized to clk_key and clk_cpu
        reset_key : in boolean;
        reset_cpu : in boolean;
        
        filter_invalid : in boolean;
        
        ps2_clk : inout std_logic;
        ps2_dat : inout std_logic;
        
        joy_strobe  : in std_logic;
        
        shift_joy_1 : in std_logic;
        joy_1_val   : out std_logic;
        joy_1_reg   : out std_logic_vector(7 downto 0);
        
        shift_joy_2 : in std_logic;
        joy_2_val   : out std_logic;
        joy_2_reg   : out std_logic_vector(7 downto 0)
    );
    end component ps2_joystick;

    component nes_de1 is
    generic
    (
        ROM_CONFIG : rom_config_t := ROM_SD_TO_SDRAM
    );
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

        DRAM_ADDR  : out std_logic_vector(11 downto 0);
        DRAM_BA_0  : out std_logic;
        DRAM_BA_1  : out std_logic;
        DRAM_CAS_N : out std_logic;
        DRAM_CKE   : out std_logic;
        DRAM_CLK   : out std_logic;
        DRAM_CS_N  : out std_logic;
        DRAM_DQ    : inout std_logic_vector(15 downto 0);
        DRAM_LDQM  : out std_logic;
        DRAM_UDQM  : out std_logic;
        DRAM_RAS_N : out std_logic;
        DRAM_WE_N  : out std_logic;

        -- SD card in SPI mode
        SD_DAT  : in std_logic;
        SD_DAT3 : out std_logic;
        SD_CMD  : out std_logic;
        SD_CLK  : out std_logic;

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
    end component nes_de1;
    
end de1_types;

package body de1_types is
    
    
    
end package body;