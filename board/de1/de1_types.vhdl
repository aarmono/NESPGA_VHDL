library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;

package de1_types is
    
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

        vga_out     : out vga_out_t
    );
    end component vga_gen;

    component ppu_video_ram_mux is
    port
    (
        clk_50mhz : in std_logic;
        reset     : in boolean;

        sram_dq   : inout std_logic_vector(15 downto 0);
        sram_addr : out std_logic_vector(17 downto 0);
        sram_lb_n : out std_logic;
        sram_ub_n : out std_logic;
        sram_oe_n : out std_logic;
        sram_we_n : out std_logic;

        ppu_clk_en  : in boolean;
        pixel_bus   : in pixel_bus_t;

        data_to_vga    : out std_logic_vector(15 downto 0);
        vga_sram_addr  : in std_logic_vector(17 downto 0);
        vga_sram_oe_n  : in std_logic;

        vga_line_valid : in boolean
    );
    end component ppu_video_ram_mux;
    
end de1_types;

package body de1_types is
    
    
    
end package body;