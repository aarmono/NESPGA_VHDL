library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_cpu.all;

entity cpu is
port
(
    clk      : in  std_logic;
    clk_en   : in  boolean := true;
    reset    : in  boolean;
    
    cpu_bus       : out cpu_bus_t;
    data_to_cpu   : in  data_t;
    data_from_cpu : out data_t;
    
    sync     : out boolean;
    
    ready    : in  boolean;
    nmi      : in  boolean;
    irq      : in  boolean
);
end cpu;

architecture behavioral of cpu is

    signal reg_in : registers_t;
    signal reg    : registers_t := RESET_REGISTERS;

begin

    process(all)
        -- Internal variables
        variable v_output : cpu_output_t;
    begin
        v_output := cycle_cpu(reg, data_to_cpu, ready, irq, nmi);

        reg_in <= v_output.reg;
        cpu_bus <= v_output.data_bus;
        data_from_cpu <= v_output.data_out;
        sync <= v_output.sync;
    end process;
    
    process(clk)
    begin
    -- double-IF required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= RESET_REGISTERS;
        else
            reg <= reg_in;
        end if;
    end if;
    end if;
    end process;

end behavioral;