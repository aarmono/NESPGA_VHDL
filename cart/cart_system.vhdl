library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;
use work.perhipheral_types.all;
use work.cart_mem_bus_types.all;
use work.chip_ram_bus_types.all;
use work.opll_bus_types.all;
use work.cart_connector_types.all;
use work.cart_types.all;
use work.lib_cart_system.all;

-- The cartridge with its memories: the board, built from the header of the
-- ROM file, with PRG ROM and CHR ROM in the ROM file and its RAMs, all on
-- the cartridge memory bus. After reset the header is loaded and the RAMs
-- filled before the board can run
entity cart_system is
generic
(
    -- The boards the cartridge is built as. See board_set_t
    CART_BOARDS : board_set_t := ALL_BOARDS;
    -- Give the memory the board's two channels as they are, rather than
    -- one access per PPU cycle on the cartridge memory bus, for a memory
    -- that serves each when it is asked. See prg_mem_bus
    SPLIT_MEM_BUS : boolean := false;
    -- See cartridge
    A12_M2_FILTER : boolean := false
);
port
(
    clk      : in std_logic;
    -- Power up, or a new ROM file. The header is loaded again and the RAMs
    -- filled again
    reset    : in boolean;

    -- The console's clock enables
    cpu_en   : in boolean;
    ppu_en   : in boolean;
    clk_sync : in boolean;

    -- The fill leaves PRG RAM alone, because the board has loaded a save
    -- into it. Must be stable while reset is true
    keep_prg_ram  : in boolean := false;

    -- The data the RAMs are filled with, from a power_up_fill. Shared with
    -- a console, it is the console that steps it, once per CPU cycle of its
    -- own fill. The cartridge fills its RAMs on the same CPU cycles, so it
    -- takes the same data the console's RAMs did before they were split
    power_up_ready : in boolean;
    power_up_data  : in cart_power_up_data_t;

    -- The header is loaded. Once the power up data is ready as well, the
    -- fill starts on the next CPU cycle. The console starts its own fill on
    -- the same CPU cycle
    loaded : out boolean;
    -- The RAMs are filled by the end of this CPU cycle, so the console can
    -- leave reset after it. The board leaves reset then too
    ready  : out boolean;

    cpu_in  : in  cart_cpu_in_t;
    cpu_out : out cart_cpu_out_t;
    ppu_in  : in  cart_ppu_in_t;
    ppu_out : out cart_ppu_out_t;
    -- The audio of the chips on the board, which the console mixes with its
    -- own
    audio   : out cart_audio_t;

    -- The ROM file at the start, and the cartridge RAMs in the windows of
    -- its upper half. See cart_mem_bus_types
    cart_mem_bus       : out cart_mem_bus_t;
    data_to_cart_mem   : out data_t;
    data_from_cart_mem : in data_t;

    -- With SPLIT_MEM_BUS, the two channels of the cartridge memory bus,
    -- which is then unused: the accesses the board makes for the CPU and
    -- for the PPU. Each holds its access until the board moves on, and the
    -- memory answers both at once, as soon as it can
    prg_mem_bus       : out cart_mem_bus_t;
    data_to_prg_mem   : out data_t;
    data_from_prg_mem : in data_t := (others => '-');

    chr_mem_bus       : out cart_mem_bus_t;
    data_to_chr_mem   : out data_t;
    data_from_chr_mem : in data_t := (others => '-');

    -- RAM inside the mapper chip
    chip_ram_bus       : out chip_ram_bus_t;
    data_to_chip_ram   : out data_t;
    data_from_chip_ram : in data_t;

    -- RAM of the FM synthesizer of the VRC7
    opll_ram_bus       : out opll_ram_bus_t;
    data_to_opll_ram   : out opll_ram_data_t;
    data_from_opll_ram : in opll_ram_data_t
);
end entity;

architecture behavioral of cart_system
is

    signal reg      : cart_system_reg_t := RESET_CART_SYSTEM_REG;
    signal reg_next : cart_system_reg_t;

    -- The board is held in reset until the RAMs are filled. The connector
    -- has no reset pin, so the board does not see the console's reset
    signal board_reset : boolean := true;

    signal cart_in  : cart_in_t;
    signal cart_out : cart_out_t;
    -- The memories of the VRC7 audio are only accessed by the cartridge
    signal opll_mem_out : opll_mem_out_t;

    signal cart_mem_bus_prg       : cart_mem_bus_t;
    signal data_to_cart_mem_prg   : data_t;
    signal data_from_cart_mem_prg : data_t;
    signal header_data            : data_t;

    signal cart_mem_bus_chr       : cart_mem_bus_t;
    signal data_to_cart_mem_chr   : data_t;
    signal data_from_cart_mem_chr : data_t;

begin

    gen_mem_bus : if not SPLIT_MEM_BUS generate
    begin
        cart_mem_mux : entity work.cart_mem_bus_mux(behavioral)
        port map
        (
            clk => clk,
            clk_en => ppu_en,
            clk_sync => clk_sync,
            reset => reset,

            cart_mem_bus_chr => cart_mem_bus_chr,
            data_from_chr_bus => data_to_cart_mem_chr,
            data_to_chr_bus => data_from_cart_mem_chr,

            cart_mem_bus_prg => cart_mem_bus_prg,
            data_from_prg_bus => data_to_cart_mem_prg,
            data_to_prg_bus => data_from_cart_mem_prg,

            cart_mem_bus_out => cart_mem_bus,
            data_to_cart_mem => data_to_cart_mem,
            data_from_cart_mem => data_from_cart_mem
        );

        prg_mem_bus <= CART_MEM_BUS_IDLE;
        data_to_prg_mem <= (others => '-');
        chr_mem_bus <= CART_MEM_BUS_IDLE;
        data_to_chr_mem <= (others => '-');
    else generate
    begin
        cart_mem_bus <= CART_MEM_BUS_IDLE;
        data_to_cart_mem <= (others => '-');

        prg_mem_bus <= cart_mem_bus_prg;
        data_to_prg_mem <= data_to_cart_mem_prg;
        data_from_cart_mem_prg <= data_from_prg_mem;

        chr_mem_bus <= cart_mem_bus_chr;
        data_to_chr_mem <= data_to_cart_mem_chr;
        data_from_cart_mem_chr <= data_from_chr_mem;
    end generate;

    cart_in.cpu <= cpu_in;
    cart_in.ppu <= ppu_in;

    -- Kept out of the process below so that read data from the cartridge
    -- memory bus does not run cycle_cart_system again on its way to the
    -- board
    cart_in.mem <=
    (
        data_from_prg_rom => data_from_cart_mem_prg,
        data_from_chr_rom => data_from_cart_mem_chr,
        data_from_prg_ram => data_from_cart_mem_prg,
        data_from_chr_ram => data_from_cart_mem_chr,
        data_from_cpu_exram => data_from_cart_mem_prg,
        data_from_ppu_exram => data_from_cart_mem_chr,
        data_from_chip_ram => data_from_chip_ram,
        data_from_vram => data_from_cart_mem_chr
    );

    cpu_out <= cart_out.cpu;
    ppu_out <= cart_out.ppu;
    audio <= cart_out.audio;

    opll_ram_bus <= opll_mem_out.ram_bus;
    data_to_opll_ram <= opll_mem_out.data_to_ram;

    -- The header is only read while loading, so that otherwise read data
    -- from the cartridge memory bus does not run cycle_cart_system again
    header_data <= data_from_cart_mem_prg when reg.cur_state = STATE_LOAD else
                   (others => '-');

    board_reset <= reg.cur_state /= STATE_READY;

    board : entity work.cartridge(behavioral)
    generic map
    (
        CART_BOARDS => CART_BOARDS,
        A12_M2_FILTER => A12_M2_FILTER
    )
    port map
    (
        clk => clk,
        clk_en => ppu_en,
        clk_sync => clk_sync,
        reset => board_reset,

        config => reg.config,

        cart_in => cart_in,
        cart_out => cart_out,

        opll_mem_out => opll_mem_out,
        data_from_opll_ram => data_from_opll_ram
    );

    process(all)
    is
        variable sys_in  : cart_system_in_t;
        variable sys_out : cart_system_out_t;
    begin
        sys_in.reg := reg;
        sys_in.data_from_cart_mem := header_data;
        sys_in.mem := cart_out.mem;
        sys_in.power_up_ready := power_up_ready;
        sys_in.power_up_data := power_up_data;
        sys_in.keep_prg_ram := keep_prg_ram;

        sys_out := cycle_cart_system(sys_in);

        reg_next <= sys_out.reg;

        cart_mem_bus_prg <= sys_out.prg_cart_mem_bus;
        data_to_cart_mem_prg <= sys_out.data_to_prg_cart_mem;
        cart_mem_bus_chr <= sys_out.chr_cart_mem_bus;
        data_to_cart_mem_chr <= sys_out.data_to_chr_cart_mem;

        chip_ram_bus <= sys_out.chip_ram_bus;
        data_to_chip_ram <= sys_out.data_to_chip_ram;

        loaded <= sys_out.loaded;
        ready <= sys_out.ready;
    end process;

    process(clk)
    is
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_CART_SYSTEM_REG;
        elsif cpu_en
        then
            reg <= reg_next;
        end if;
    end if;
    end process;

end behavioral;
