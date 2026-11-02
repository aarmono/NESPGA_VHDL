library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.perhipheral_types.all;

package de1_types is
    
    type rom_config_t is
    (
        ROM_FLASH_TO_SDRAM,
        ROM_SD_TO_SDRAM,
        -- As ROM_SD_TO_SDRAM if the SD card starts with an iNES file,
        -- otherwise the card holds a filesystem, which the menu reads
        ROM_SD_MENU
    );

    subtype vga_channel_t is std_logic_vector(3 downto 0);

    type vga_color_t is record
        red   : vga_channel_t;
        green : vga_channel_t;
        blue  : vga_channel_t;
    end record;
    
    type vga_out_t is record
        color  : vga_color_t;
        h_sync : std_logic;
        v_sync : std_logic;
        lval   : boolean;
        fval   : boolean;
    end record;
    
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
        
        -- The keyboard as a standard controller, synchronized to clk_cpu
        joy_strobe : in std_logic;
        joy_clk    : in std_logic;
        joy_data   : out joy_data_t;

        -- Escape is held. Synchronized to clk_cpu
        soft_reset : out boolean
    );
    end component ps2_joystick;

    component joy_port is
    port
    (
        clk   : in std_logic;
        reset : in boolean;

        -- CPU side of the port. joy_strobe and joy_clk must be registered
        -- (glitch free), since they drive the pins directly
        joy_strobe : in std_logic;
        joy_clk    : in std_logic;
        joy_data   : out joy_data_t;

        -- Data lines of the controllers inside the FPGA on this port
        int_data : in joy_data_t := JOY_DATA_IDLE;

        -- The first 8 bits the CPU read from D0 after the last strobe: the
        -- buttons of a standard controller, with A in bit 0. Low while
        -- pressed
        buttons : out std_logic_vector(7 downto 0);

        pin_latch : out std_logic;
        pin_clk   : out std_logic;
        -- Pulled up, so that an empty port reads as nothing pressed
        pin_data  : in joy_data_t
    );
    end component joy_port;

    component nes_de1 is
    generic
    (
        ROM_CONFIG    : rom_config_t := ROM_SD_TO_SDRAM;
        POWER_UP_MODE : power_up_mode_t := POWER_UP_RANDOM;
        RETURN_HOLD_MS : positive := 2000;
        CLOCK_VGA_FREQ : real := 27.0e6 * 29.0 / 31.0;
        LOG_LOCK      : boolean := false
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

        -- NES controller ports. The data lines are low while pressed and
        -- must be pulled up, so that an empty port reads as nothing
        -- pressed. The keyboard shares port 1
        JOY_1_LATCH : out std_logic;
        JOY_1_CLK   : out std_logic;
        JOY_1_DATA  : in joy_data_t := JOY_DATA_IDLE;

        JOY_2_LATCH : out std_logic;
        JOY_2_CLK   : out std_logic;
        JOY_2_DATA  : in joy_data_t := JOY_DATA_IDLE;

        -- Push buttons, low while pressed
        KEY  : in std_logic_vector(3 downto 0) := (others => '1');
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