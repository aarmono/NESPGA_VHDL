library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_core.all;
use work.utilities.all;
use work.lib_cpu.all;

entity cpu is
port
(
    clk      : in  std_logic;
    reset    : in  boolean;
    
    data_bus : out cpu_bus_t;
    data_in  : in  data_t;
    data_out : out data_t;
    
    sync     : out boolean;
    
    ready    : in  boolean;
    nmi      : in  boolean;
    irq      : in  boolean
);
end cpu;

architecture behavioral of cpu is

    signal reg_in, reg : registers_t;

begin

    process(all)
        -- Internal variables
        variable v_output : cpu_output_t;
    begin
        v_output := cycle_cpu(reg, data_in, ready, irq, nmi, reset);

        reg_in <= v_output.reg;
        data_bus <= v_output.data_bus;
        data_out <= v_output.data_out;
        sync <= v_output.sync;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            reg <= reg_in;
        end if;
    end process;

end behavioral;