library IEEE;
use IEEE.std_logic_1164.all;

entity clock is
generic
(
    PERIOD : time
);
port
(
    done  : in boolean;
    clk   : out std_logic;
    reset : out boolean
);
end clock;

architecture behavioral of clock is
begin

    process
        variable v_clk : std_logic := '0';
    begin
        clk <= '0';
        reset <= true;
        while not done loop
            wait for PERIOD / 2;
            clk <= '1';
            wait for PERIOD / 2;
            clk <= '0';
            reset <= false;
        end loop;
    end process;

end behavioral;