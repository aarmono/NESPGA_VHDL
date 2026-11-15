library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;
use work.perhipheral_types.all;
use work.perhipherals.all;
use work.cart_mem_bus_types.all;
use work.chip_ram_bus_types.all;
use work.opll_bus_types.all;
use work.cart_connector_types.all;
use work.cart_types.all;
use work.lib_cart_system.all;

-- Variant of cart_system with the RAMs of the mapper chips on chip, and
-- optionally the cartridge RAMs too
entity cart_system_ocram is
generic
(
    -- Leave the cartridge RAMs on the cartridge memory bus. Otherwise they
    -- are on chip, and only reads of the ROM file are on the bus
    USE_EXT_CART_RAM : boolean := false;
    -- Vendor of the on-chip RAMs. See syncram_sp
    VENDOR           : vendor_t := VENDOR_ALTERA;
    -- See cart_system
    CART_BOARDS      : board_set_t := ALL_BOARDS
);
port
(
    clk      : in std_logic;
    -- See cart_system
    reset    : in boolean;

    cpu_en   : in boolean;
    ppu_en   : in boolean;
    clk_sync : in boolean;
    -- The clock enable of the on-chip RAMs, which are accessed once per PPU
    -- cycle
    ram_en   : in boolean;

    -- See cart_system
    keep_prg_ram  : in boolean := false;

    power_up_ready : in boolean;
    power_up_data  : in power_up_data_t;

    loaded : out boolean;
    ready  : out boolean;

    cpu_in  : in  cart_cpu_in_t;
    cpu_out : out cart_cpu_out_t;
    ppu_in  : in  cart_ppu_in_t;
    ppu_out : out cart_ppu_out_t;
    audio   : out cart_audio_t;

    cart_mem_bus       : out cart_mem_bus_t;
    data_to_cart_mem   : out data_t;
    data_from_cart_mem : in data_t
);
end cart_system_ocram;

architecture behavioral of cart_system_ocram is

    signal sys_cart_mem_bus       : cart_mem_bus_t;
    signal sys_data_to_cart_mem   : data_t;
    signal sys_data_from_cart_mem : data_t;

    signal chip_ram_bus       : chip_ram_bus_t;
    signal data_to_chip_ram   : data_t;
    signal data_from_chip_ram : data_t;

    signal opll_ram_bus       : opll_ram_bus_t;
    signal data_to_opll_ram   : opll_ram_data_t;
    signal data_from_opll_ram : opll_ram_data_t;

begin

    sys : entity work.cart_system(behavioral)
    generic map
    (
        CART_BOARDS => CART_BOARDS
    )
    port map
    (
        clk => clk,
        reset => reset,

        cpu_en => cpu_en,
        ppu_en => ppu_en,
        clk_sync => clk_sync,

        keep_prg_ram => keep_prg_ram,

        power_up_ready => power_up_ready,
        power_up_data => power_up_data,

        loaded => loaded,
        ready => ready,

        cpu_in => cpu_in,
        cpu_out => cpu_out,
        ppu_in => ppu_in,
        ppu_out => ppu_out,
        audio => audio,

        cart_mem_bus => sys_cart_mem_bus,
        data_to_cart_mem => sys_data_to_cart_mem,
        data_from_cart_mem => sys_data_from_cart_mem,

        chip_ram_bus => chip_ram_bus,
        data_to_chip_ram => data_to_chip_ram,
        data_from_chip_ram => data_from_chip_ram,

        opll_ram_bus => opll_ram_bus,
        data_to_opll_ram => data_to_opll_ram,
        data_from_opll_ram => data_from_opll_ram
    );

    gen_cart_ram : if USE_EXT_CART_RAM generate
    begin
        cart_mem_bus <= sys_cart_mem_bus;
        data_to_cart_mem <= sys_data_to_cart_mem;
        sys_data_from_cart_mem <= data_from_cart_mem;
    else generate
        signal ram_read      : boolean;
        signal ram_write     : boolean;
        signal data_from_ram : data_t;
    begin
        -- The cartridge memory bus has at most one access per PPU cycle, so
        -- one RAM holds all of the cartridge RAMs. Like the SDRAM, the access
        -- is complete by the next PPU clock enable
        ram_read <= is_cart_ram(sys_cart_mem_bus) and
                    is_bus_read(sys_cart_mem_bus);
        ram_write <= is_cart_ram(sys_cart_mem_bus) and
                     is_bus_write(sys_cart_mem_bus);

        cart_mem_bus <= CART_MEM_BUS_IDLE when is_cart_ram(sys_cart_mem_bus)
                        else sys_cart_mem_bus;
        data_to_cart_mem <= (others => '-');
        sys_data_from_cart_mem <= data_from_ram
                                  when is_cart_ram(sys_cart_mem_bus)
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
            clk_en => ram_en,

            address => sys_cart_mem_bus.address(cart_ram_addr_t'range),
            read => ram_read,
            write => ram_write,

            data_in => sys_data_to_cart_mem,
            data_out => data_from_ram
        );
    end generate;

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
            clk_en => ram_en,

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
            clk_en => ram_en,

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

end behavioral;
