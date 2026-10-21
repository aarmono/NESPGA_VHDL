library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.chr_bus_types.all;
use work.cpu_bus_types.all;
use work.cart_mem_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
use work.soc.all;
use work.simulation.all;
use work.lib_nes.all;

entity nes_bench is
generic
(
    AU_FILEPATH     : string;
    BMP_FILE_PREFIX : string;
    NES_FILEPATH    : string;
    FM2_FILEPATH    : string := "";
    NES_FILE_BYTES  : integer := 196608;
    FM2_OFFSET      : integer := 2
);
end nes_bench;

architecture behavioral of nes_bench is

    -- The simulated clock runs at 50MHz * (6 / 28) and the CPU runs at
    -- exactly a sixth of it, so a CPU cycle is as long as 28 clocks of a
    -- 50MHz clock. That is the rate the core ran at before clk_en supported
    -- the exact NTSC rate. Keeping it keeps the run times in nes_tests.txt,
    -- and there are fewer clock events to simulate than at 50MHz
    constant CLK_FREQ : positive := 50_000_000 * 6 / 28;
    constant CLK_PERIOD : time := 1 sec / CLK_FREQ;

    type cart_ram_t is array(0 to 2**cart_ram_addr_t'length - 1) of data_t;

    signal cart_mem_bus       : cart_mem_bus_t;
    signal data_to_cart_mem   : data_t;
    signal data_from_cart_mem : data_t;

    signal file_bus       : cart_mem_bus_t;
    signal data_from_file : data_t;
    
    signal audio_out : mixed_audio_t;
    signal pixel_bus : pixel_bus_t;

    signal joy_strobe : std_logic;

    signal shift_joy_1 : std_logic;
    signal joy_1_val   : std_logic;

    signal shift_joy_2 : std_logic;
    signal joy_2_val   : std_logic;

    signal ppu_clk_en : boolean;
    signal cpu_clk_en : boolean;
    
    signal reset : boolean;
    
    signal clk : std_logic := '0';

    signal output_ready : boolean;
    
begin

    soc : nes_soc_ocram
    generic map
    (
        USE_EXT_CART_RAM => true,
        CLK_FREQ => CLK_FREQ,
        CPU_FREQ_NUM => CLK_FREQ,
        CPU_FREQ_DEN => 6
    )
    port map
    (
        clk => clk,
        reset => false,

        nes_running => output_ready,

        ppu_clk_en => ppu_clk_en,
        cpu_clk_en => cpu_clk_en,
        
        cart_mem_bus => cart_mem_bus,
        data_to_cart_mem => data_to_cart_mem,
        data_from_cart_mem => data_from_cart_mem,
        
        pixel_bus => pixel_bus,
        audio => audio_out,

        joy_strobe => joy_strobe,

        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,

        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );
    
    ppu_recorder : ppu_video_record
    generic map
    (
        FILE_PREFIX => BMP_FILE_PREFIX
    )
    port map
    (
        clk => clk,
        clk_en => ppu_clk_en,
        pixel_bus => pixel_bus,
        ready => output_ready,
        done => false
    );

    apu_recorder : apu_audio_record
    generic map
    (
        FILEPATH => AU_FILEPATH
    )
    port map
    (
        clk => clk,
        clk_en => cpu_clk_en,
        audio => audio_out,
        ready => output_ready,
        done => false
    );

    fm2_controller : fm2_joystick
    generic map
    (
        FILEPATH => FM2_FILEPATH,
        INPUT_OFFSET => FM2_OFFSET
    )
    port map
    (
        frame_valid => pixel_bus.frame_valid,

        joy_strobe => joy_strobe,

        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,

        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );
    
    nes_file : file_memory
    generic map
    (
       FILEPATH => NES_FILEPATH,
       MEM_BYTES => NES_FILE_BYTES,
       READ_DELAY => CLK_PERIOD / 2
    )
    port map
    (
       file_bus_1 => file_bus,
       data_from_file_1 => data_from_file
    );

    -- The cartridge RAMs. Writes are taken at the PPU clock enable, the end
    -- of the SDRAM slot that serves them on the board, so that the bus
    -- settling over delta cycles cannot write to the wrong address
    cart_ram : process(clk, cart_mem_bus, data_from_file)
        variable ram : cart_ram_t;
    begin
        if not is_cart_ram(cart_mem_bus)
        then
            file_bus <= cart_mem_bus;
            data_from_cart_mem <= data_from_file;
        else
            file_bus <= CART_MEM_BUS_IDLE;

            if is_bus_read(cart_mem_bus)
            then
                data_from_cart_mem <=
                    ram(to_integer(cart_mem_bus.address(cart_ram_addr_t'range)))
                    after CLK_PERIOD / 2;
            else
                data_from_cart_mem <= (others => '-');
            end if;

            if rising_edge(clk) and ppu_clk_en and is_bus_write(cart_mem_bus)
            then
                ram(to_integer(cart_mem_bus.address(cart_ram_addr_t'range))) :=
                    data_to_cart_mem;
            end if;
        end if;
    end process;
    
    clk_gen : clock
    generic map
    (
        PERIOD => CLK_PERIOD
    )
    port map
    (
        clk => clk,
        done => false
    );

end behavioral;