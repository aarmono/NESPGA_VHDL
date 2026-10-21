library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.ciram_bus_types.all;
use work.cpu_bus_types.all;
use work.cart_mem_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
use work.perhipherals.all;
use work.perhipheral_types.all;
use work.lib_nes.all;

entity nes_soc_ocram is
generic
(
    -- Leave the cartridge RAMs on the cartridge memory bus. Otherwise they
    -- are on chip, and only reads of the ROM file are on the bus
    USE_EXT_CART_RAM : boolean := false;
    -- See clk_en
    CLK_FREQ         : positive := 50_000_000;
    CPU_FREQ_NUM     : positive := 39_375_000;
    CPU_FREQ_DEN     : positive := 22
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    nes_running : out boolean;

    cpu_clk_en : out boolean;
    ppu_clk_en : out boolean;
    
    cart_mem_bus       : out cart_mem_bus_t;
    data_to_cart_mem   : out data_t;
    data_from_cart_mem : in data_t;

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
    
    signal soc_cart_mem_bus       : cart_mem_bus_t;
    signal soc_data_to_cart_mem   : data_t;
    signal soc_data_from_cart_mem : data_t;

    signal prg_ram_bus  : ram_bus_t;
    signal oam_bus      : oam_bus_t;
    signal sec_oam_bus  : sec_oam_bus_t;
    signal palette_bus  : palette_bus_t;
    signal ciram_bus    : ciram_bus_t;
    
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

        nes_running => nes_running,

        ppu_clk_en => ppu_clk_en,
        cpu_clk_en => cpu_clk_en,

        cpu_ram_en => sig_cpu_ram_en,
        ppu_ram_en => sig_ppu_ram_en,
        
        cart_mem_bus => soc_cart_mem_bus,
        data_to_cart_mem => soc_data_to_cart_mem,
        data_from_cart_mem => soc_data_from_cart_mem,
        
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
        clk => clk,
        clk_en => sig_cpu_ram_en,

        address => prg_ram_bus.address,
        read => prg_ram_bus.read,
        write => prg_ram_bus.write,

        data_in => data_to_prg_ram,
        data_out => data_from_prg_ram
    );

    gen_cart_ram : if USE_EXT_CART_RAM generate
    begin
        cart_mem_bus <= soc_cart_mem_bus;
        data_to_cart_mem <= soc_data_to_cart_mem;
        soc_data_from_cart_mem <= data_from_cart_mem;
    else generate
        signal ram_read      : boolean;
        signal ram_write     : boolean;
        signal data_from_ram : data_t;
    begin
        -- The cartridge memory bus has at most one access per PPU cycle, so
        -- one RAM holds all of the cartridge RAMs. Like the SDRAM, the access
        -- is complete by the next PPU clock enable
        ram_read <= is_cart_ram(soc_cart_mem_bus) and
                    is_bus_read(soc_cart_mem_bus);
        ram_write <= is_cart_ram(soc_cart_mem_bus) and
                     is_bus_write(soc_cart_mem_bus);

        cart_mem_bus <= CART_MEM_BUS_IDLE when is_cart_ram(soc_cart_mem_bus)
                        else soc_cart_mem_bus;
        data_to_cart_mem <= (others => '-');
        soc_data_from_cart_mem <= data_from_ram
                                  when is_cart_ram(soc_cart_mem_bus)
                                  else data_from_cart_mem;

        cart_ram : syncram_sp
        generic map
        (
            ADDR_BITS => cart_ram_addr_t'length,
            DATA_BITS => data_t'length
        )
        port map
        (
            clk => clk,
            clk_en => sig_ppu_ram_en,

            address => soc_cart_mem_bus.address(cart_ram_addr_t'range),
            read => ram_read,
            write => ram_write,

            data_in => soc_data_to_cart_mem,
            data_out => data_from_ram
        );
    end generate;

    ciram : syncram_sp
    generic map
    (
        ADDR_BITS => ciram_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk,
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
        clk => clk,
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
        clk => clk,
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
        clk => clk,
        clk_en => sig_ppu_ram_en,

        address => palette_bus.address,
        read => palette_bus.read,
        write => palette_bus.write,

        data_in => data_to_palette,
        data_out => data_from_palette
    );

end behavioral;