library IEEE;
use IEEE.std_logic_1164.all;

entity clock is
generic
(
    PERIOD : time;
    OFFSET : time := 0 ns;
    DUTY   : real range 0.0 to 1.0 := 0.5
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
        -- Compute low and high time this way to prevent
        -- rounding errors
        constant high_time : time := PERIOD * DUTY;
        constant low_time  : time := PERIOD - high_time;
    begin
        clk <= '0';
        reset <= true;
        wait for OFFSET;
        while not done loop
            wait for low_time;
            clk <= '1';
            wait for high_time;
            clk <= '0';
            reset <= false;
        end loop;
    end process;

end behavioral;