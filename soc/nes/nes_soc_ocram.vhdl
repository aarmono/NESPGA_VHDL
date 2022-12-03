library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.chr_bus_types.all;
use work.cpu_bus_types.all;
use work.file_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
use work.perhipherals.all;

entity nes_soc_ocram is
generic
(
    USE_EXT_SRAM : boolean := false
);
port
(
    clk_50mhz : in std_logic;
    reset     : in boolean;

    nes_running : out boolean;

    cpu_clk_en : out boolean;
    ppu_clk_en : out boolean;

    cpu_ram_en : out boolean;
    
    file_bus       : out file_bus_t;
    data_from_file : in data_t;

    sram_bus       : out sram_bus_t;
    data_to_sram   : out data_t;
    data_from_sram : in data_t := (others => '-');

    pixel_bus : out pixel_bus_t;
    audio     : out mixed_audio_t;

    joy_strobe : out std_logic;

    shift_joy_1 : out std_logic;
    joy_1_val   : in std_logic := '1';

    shift_joy_2 : out std_logic;
    joy_2_val   : in std_logic := '1'
);
end nes_soc_ocram;

architecture behavioral of nes_soc_ocram is

    signal sig_cpu_ram_en : boolean;
    signal sig_ppu_ram_en : boolean;
    
    signal sig_sram_bus       : sram_bus_t;
    signal sig_data_to_sram   : data_t;
    signal sig_data_from_sram : data_t;

    signal prg_ram_bus  : ram_bus_t;
    signal oam_bus      : oam_bus_t;
    signal sec_oam_bus  : sec_oam_bus_t;
    signal palette_bus  : palette_bus_t;
    signal ciram_bus    : chr_bus_t;
    
    signal data_to_prg_ram    : data_t;
    signal data_from_prg_ram  : data_t;
    signal data_to_oam        : data_t;
    signal data_from_oam      : data_t;
    signal data_to_sec_oam    : data_t;
    signal data_from_sec_oam  : data_t;
    signal data_to_palette    : pixel_t;
    signal data_from_palette  : pixel_t;
    signal data_from_ciram    : data_t;
    signal data_to_ciram      : data_t;
    
begin

    soc : entity work.nes_soc(behavioral)
    port map
    (
        clk_50mhz => clk_50mhz,
        reset => false,

        nes_running => nes_running,

        ppu_clk_en => ppu_clk_en,
        cpu_clk_en => cpu_clk_en,

        cpu_ram_en => sig_cpu_ram_en,
        ppu_ram_en => sig_ppu_ram_en,
        
        file_bus => file_bus,
        data_from_file => data_from_file,
        
        sram_bus => sig_sram_bus,
        data_to_sram => sig_data_to_sram,
        data_from_sram => sig_data_from_sram,
        
        prg_ram_bus => prg_ram_bus,
        data_to_prg_ram => data_to_prg_ram,
        data_from_prg_ram => data_from_prg_ram,
        
        oam_bus => oam_bus,
        data_to_oam => data_to_oam,
        data_from_oam => data_from_oam,
        
        sec_oam_bus => sec_oam_bus,
        data_to_sec_oam => data_to_sec_oam,
        data_from_sec_oam => data_from_sec_oam,
        
        palette_bus => palette_bus,
        data_to_palette => data_to_palette,
        data_from_palette => data_from_palette,
        
        ciram_bus => ciram_bus,
        data_to_ciram => data_to_ciram,
        data_from_ciram => data_from_ciram,
        
        pixel_bus => pixel_bus,
        audio => audio,

        joy_strobe => joy_strobe,

        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,

        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );
    
    prg_ram : syncram_sp
    generic map
    (
        ADDR_BITS => ram_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => sig_cpu_ram_en,

        address => prg_ram_bus.address,
        read => prg_ram_bus.read,
        write => prg_ram_bus.write,

        data_in => data_to_prg_ram,
        data_out => data_from_prg_ram
    );

    gen_sram : if not USE_EXT_SRAM generate
    begin
        sram_bus <= SRAM_BUS_IDLE;
        data_to_sram <= (others => '-');
        cpu_ram_en <= false;

        sram : syncram_sp
        generic map
        (
            ADDR_BITS => sram_addr_t'length,
            DATA_BITS => data_t'length
        )
        port map
        (
            clk => clk_50mhz,
            clk_en => sig_cpu_ram_en,

            address => sig_sram_bus.address,
            read => sig_sram_bus.read,
            write => sig_sram_bus.write,

            data_in => sig_data_to_sram,
            data_out => sig_data_from_sram
        );
    end generate;

    drive_sram : if USE_EXT_SRAM generate
    begin
        sram_bus <= sig_sram_bus;
        data_to_sram <= sig_data_to_sram;
        sig_data_from_sram <= data_from_sram;
        cpu_ram_en <= sig_cpu_ram_en;
    end generate;

    ciram : syncram_sp
    generic map
    (
        ADDR_BITS => chr_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => sig_ppu_ram_en,

        address => ciram_bus.address,
        read => ciram_bus.read,
        write => ciram_bus.write,

        data_in => data_to_ciram,
        data_out => data_from_ciram
    );

    oam : syncram_sp
    generic map
    (
        ADDR_BITS => oam_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => sig_ppu_ram_en,

        address => oam_bus.address,
        read => oam_bus.read,
        write => oam_bus.write,

        data_in => data_to_oam,
        data_out => data_from_oam
    );
    
    sec_oam : syncram_sp
    generic map
    (
        ADDR_BITS => sec_oam_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => sig_ppu_ram_en,

        address => sec_oam_bus.address,
        read => sec_oam_bus.read,
        write => sec_oam_bus.write,

        data_in => data_to_sec_oam,
        data_out => data_from_sec_oam
    );
    
    palette : syncram_sp
    generic map
    (
        ADDR_BITS => palette_addr_t'length,
        DATA_BITS => pixel_t'length
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => sig_ppu_ram_en,

        address => palette_bus.address,
        read => palette_bus.read,
        write => palette_bus.write,

        data_in => data_to_palette,
        data_out => data_from_palette
    );

end behavioral;