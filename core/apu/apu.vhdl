library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.lib_apu.all;
use work.apu_bus_types.all;
use work.cpu_bus_types.all;
use work.utilities.all;

entity apu is
port
(
    clk           : in  std_logic;
    clk_en        : in  boolean := true;
    clk_odd       : in  boolean;
    reset         : in  boolean;
    
    cpu_bus       : in  apu_bus_t;
    data_to_apu   : in  data_t;
    data_from_apu : out data_t;
    
    audio         : out apu_out_t;

    dma_bus       : out cpu_bus_t;
    irq           : out boolean;
    ready         : out boolean
);
end apu;

architecture behavioral of apu is
    
    signal reg    : reg_t := RESET_REG;
    signal reg_in : reg_t;
    
begin
    
    process(all)
        variable v_output : apu_output_t;
    begin

        v_output := cycle_apu(reg, cpu_bus, data_to_apu, clk_odd);

        reg_in <= v_output.reg;
        audio <= v_output.audio;
        data_from_apu <= v_output.cpu_data_out;
        dma_bus <= v_output.dma_bus;
        irq <= v_output.irq;
        ready <= v_output.ready;

    end process;
    
    process(clk)
    begin
    -- double-IF required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= reg_in;
        end if;
    end if;
    end if;
    end process;

end behavioral;