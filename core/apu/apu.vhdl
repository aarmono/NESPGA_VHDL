library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;
use work.lib_apu.all;
use work.apu_bus_types.all;
use work.cpu_bus_types.all;
use work.utilities.all;

entity apu is
port
(
    clk          : in  std_logic;
    reset        : in  boolean;
    
    cpu_bus      : in  apu_bus_t;
    cpu_data_in  : in  data_t;
    cpu_data_out : out data_t;
    
    audio        : out apu_out_t;

    dma_bus      : out cpu_bus_t;
    irq          : out boolean;
    ready        : out boolean
);
end apu;

architecture behavioral of apu is
    
    signal reg, reg_in : reg_t;
    
begin
    
    process(reset, cpu_bus, cpu_data_in, reg)
        variable v_output : apu_output_t;
    begin

        v_output := cycle_apu(reg, cpu_bus, cpu_data_in, reset);

        reg_in <= v_output.reg;
        audio <= v_output.audio;
        cpu_data_out <= v_output.cpu_data_out;
        dma_bus <= v_output.dma_bus;
        irq <= v_output.irq;
        ready <= v_output.ready;

    end process;
    
    process(clk)
    begin
        if rising_edge(clk)
        then
            reg <= reg_in;
        end if;
    end process;

end behavioral;