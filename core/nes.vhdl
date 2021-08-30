library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity nes is
port
(
    clk_master : in std_logic;
    reset      : in boolean;
    cpu_clk_en : in boolean;
    ppu_clk_en : in boolean;
);
end entity;

architecture behavioral of nes
is



begin

    processor : component cpu
    port map
    (
        clk    => clk_master,
        clk_en => cpu_clk_en,
        reset  => reset,
        
        data_bus => cpu_bus,
        data_in  => data_to_cpu,
        data_out => data_from_cpu,
        
        sync => cpu_sync,
        
        ready => cpu_ready,
        nmi   => cpu_nmi,
        irq   => cpu_irq
    );

    video : component ppu
    port map
    (
        clk    => clk_master,
        clk_en => ppu_clk_en,
        reset  => reset,

        chr_bus      => chr_bus,
        chr_data_out => chr_to_cartridge,
        chr_data_in  => chr_from_cartridge,
        
        ppu_bus      => ppu_bus,
        ppu_data_out => data_from_ppu,
        ppu_data_in  => data_to_ppu,

        pixel_bus => pixel_bus,
        vint      => cpu_nmi
    );

    audio : component apu_bus
    port map
    (
        clk    => clk_master,
        clk_en => cpu_clk_en,
        reset  => reset,

        cpu_bus      => apu_bus,
        cpu_data_in  => data_to_apu,
        cpu_data_out => data_from_apu,
        
        audio => audio,
        irq   => apu_irq
    );

    cpu_map : component mem_map
    port map
    (
        clk   => clk_master,
        reset => reset,

        cpu_bus      => cpu_bus,
        cpu_data_in  => data_from_cpu,
        cpu_data_out => data_to_cpu,

        sram_bus      => sram_bus,
        sram_data_in  => data_from_sram,
        sram_data_out => data_to_sram,

        ppu_bus      => ppu_bus,
        ppu_data_in  => data_from_ppu,
        ppu_data_out => data_to_ppu,

        apu_bus    => apu_bus,
        apu_data_in => data_from_apu,
        apu_data_out => data_to_apu,

    );



end behavioral;