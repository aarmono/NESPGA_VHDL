library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.ciram_bus_types.all;
use work.chip_ram_bus_types.all;
use work.opll_bus_types.all;
use work.cpu_bus_types.all;
use work.cart_mem_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
use work.perhipherals.all;
use work.perhipheral_types.all;
use work.lib_nes.all;
use work.cart_types.all;

entity nes_soc_ocram is
generic
(
    -- Leave the cartridge RAMs on the cartridge memory bus. Otherwise they
    -- are on chip, and only reads of the ROM file are on the bus
    USE_EXT_CART_RAM : boolean := false;
    -- Vendor of the on-chip RAMs. See syncram_sp
    VENDOR           : vendor_t := VENDOR_ALTERA;
    -- See clk_en
    CLK_FREQ         : positive := 50_000_000;
    CPU_FREQ_NUM     : positive := 39_375_000;
    CPU_FREQ_DEN     : positive := 22;
    -- See nes_soc
    CART_BOARDS      : board_set_t := ALL_BOARDS;
    -- See nes_soc
    POWER_UP_MODE    : power_up_mode_t := POWER_UP_ZERO;
    -- See nes_soc
    POWER_UP_SEED    : natural := 0
);
port
(
    clk   : in std_logic;
    reset : in boolean;
    -- See nes_soc
    soft_reset : in boolean := false;

    nes_running : out boolean;

    cpu_clk_en : out boolean;
    ppu_clk_en : out boolean;
    
    cart_mem_bus       : out cart_mem_bus_t;
    data_to_cart_mem   : out data_t;
    data_from_cart_mem : in data_t;

    pixel_bus : out pixel_bus_t;
    audio     : out mixed_audio_t;

    joy_strobe : out std_logic;

    joy_1_clk  : out std_logic;
    joy_1_data : in joy_data_t := JOY_DATA_IDLE;

    joy_2_clk  : out std_logic;
    joy_2_data : in joy_data_t := JOY_DATA_IDLE
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
    signal chip_ram_bus       : chip_ram_bus_t;
    signal data_to_chip_ram   : data_t;
    signal data_from_chip_ram : data_t;

    signal opll_ram_bus       : opll_ram_bus_t;
    signal data_to_opll_ram   : opll_ram_data_t;
    signal data_from_opll_ram : opll_ram_data_t;
    
begin

    soc : entity work.nes_soc(behavioral)
    generic map
    (
        CART_BOARDS => CART_BOARDS,
        POWER_UP_MODE => POWER_UP_MODE,
        POWER_UP_SEED => POWER_UP_SEED,
        CLK_FREQ => CLK_FREQ,
        CPU_FREQ_NUM => CPU_FREQ_NUM,
        CPU_FREQ_DEN => CPU_FREQ_DEN
    )
    port map
    (
        clk => clk,
        reset => reset,
        soft_reset => soft_reset,

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

        chip_ram_bus => chip_ram_bus,
        data_to_chip_ram => data_to_chip_ram,
        data_from_chip_ram => data_from_chip_ram,

        opll_ram_bus => opll_ram_bus,
        data_to_opll_ram => data_to_opll_ram,
        data_from_opll_ram => data_from_opll_ram,
        
        pixel_bus => pixel_bus,
        audio => audio,

        joy_strobe => joy_strobe,

        joy_1_clk => joy_1_clk,
        joy_1_data => joy_1_data,

        joy_2_clk => joy_2_clk,
        joy_2_data => joy_2_data
    );
    
    prg_ram : syncram_sp
    generic map
    (
        VENDOR => VENDOR,
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
            VENDOR => VENDOR,
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
        VENDOR => VENDOR,
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

    -- RAM inside the mapper chip, which has a bus of its own so that the
    -- chip can access it in every PPU cycle. It also holds the contents of
    -- the serial EEPROMs of the Bandai FCG boards
    gen_chip_ram : if CART_BOARDS(BOARD_N163) or CART_BOARDS(BOARD_BANDAI)
    generate
    begin
        chip_ram : syncram_sp
        generic map
        (
            VENDOR => VENDOR,
            ADDR_BITS => chip_ram_addr_t'length,
            DATA_BITS => data_t'length
        )
        port map
        (
            clk => clk,
            clk_en => sig_ppu_ram_en,

            address => chip_ram_bus.address,
            read => chip_ram_bus.read,
            write => chip_ram_bus.write,

            data_in => data_to_chip_ram,
            data_out => data_from_chip_ram
        );
    else generate
    begin
        data_from_chip_ram <= (others => '-');
    end generate;

    -- The state of the FM synthesizer of the VRC7, which the cartridge
    -- accesses once per PPU cycle
    gen_opll_ram : if CART_BOARDS(BOARD_VRC7_AUDIO) generate
    begin
        opll_ram : syncram_sp
        generic map
        (
            VENDOR => VENDOR,
            ADDR_BITS => opll_ram_addr_t'length,
            DATA_BITS => opll_ram_data_t'length
        )
        port map
        (
            clk => clk,
            clk_en => sig_ppu_ram_en,

            address => opll_ram_bus.address,
            read => opll_ram_bus.read,
            write => opll_ram_bus.write,

            data_in => data_to_opll_ram,
            data_out => data_from_opll_ram
        );
    else generate
    begin
        data_from_opll_ram <= (others => '-');
    end generate;

    oam : syncram_sp
    generic map
    (
        VENDOR => VENDOR,
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
        VENDOR => VENDOR,
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
        VENDOR => VENDOR,
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