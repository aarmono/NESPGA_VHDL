library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;
use work.nes_types.all;
use work.perhipherals.all;

entity nsf_soc_ocram is
port
(
    clk_50mhz : in std_logic;
    reset_in  : in boolean;
    
    reset_out : out boolean;
    
    next_stb : in std_logic;
    prev_stb : in std_logic;
    
    file_bus       : out file_bus_t;
    data_from_file : in data_t;
    
    enable_square_1 : in boolean := true;
    enable_square_2 : in boolean := true;
    enable_triangle : in boolean := true;
    enable_noise    : in boolean := true;
    enable_dmc      : in boolean := true;
    
    audio : out mixed_audio_t
);
end nsf_soc_ocram;

architecture behavioral of nsf_soc_ocram is
    
    signal sram_bus       : sram_bus_t;
    signal data_to_sram   : data_t;
    signal data_from_sram : data_t;
    
    signal ram_bus       : ram_bus_t;
    signal data_to_ram   : data_t;
    signal data_from_ram : data_t;
    
    signal ram_en : boolean;

begin
    
    nsf : entity work.nsf_soc(behavioral)
    port map
    (
        clk_50mhz => clk_50mhz,
        reset_in => reset_in,

        next_stb => next_stb,
        prev_stb => prev_stb,

        file_bus => file_bus,
        data_from_file => data_from_file,

        cpu_ram_en => ram_en,

        sram_bus => sram_bus,
        data_to_sram => data_to_sram,
        data_from_sram => data_from_sram,

        ram_bus => ram_bus,
        data_to_ram => data_to_ram,
        data_from_ram => data_from_ram,

        enable_square_1 => enable_square_1,
        enable_square_2 => enable_square_2,
        enable_triangle => enable_triangle,
        enable_noise    => enable_noise,
        enable_dmc      => enable_dmc,

        audio => audio
    );

    sram : syncram_sp
    generic map
    (
        ADDR_BITS => sram_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => ram_en,

        address => sram_bus.address,
        read => sram_bus.read,
        write => sram_bus.write,

        data_in => data_to_sram,
        data_out => data_from_sram
    );

    ram : syncram_sp
    generic map
    (
        ADDR_BITS => ram_addr_t'length,
        DATA_BITS => data_t'length
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => ram_en,

        address => ram_bus.address,
        read => ram_bus.read,
        write => ram_bus.write,

        data_in => data_to_ram,
        data_out => data_from_ram
    );
    
end behavioral;
