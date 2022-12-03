library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
port
(
    clk   : in std_logic;
    reset : in boolean;
    
    data  : in std_logic;

    posedge    : out boolean;
    negedge    : out boolean;
    level      : out boolean;
    registered : out std_logic
);
end edge_detector;

architecture behavioral of edge_detector is
    signal prev_data : std_logic;
    signal cur_data  : std_logic;
    signal data_buf  : std_logic;
begin

    registered <= cur_data;
    level      <= prev_data = cur_data;
    posedge    <= (prev_data = '0') and (cur_data = '1');
    negedge    <= (prev_data = '1') and (cur_data = '0');

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            prev_data <= '0';
            cur_data <= '0';
            data_buf <= '0';
        else
            prev_data <= to_x01(cur_data);
            cur_data <= to_x01(data_buf);
            data_buf <= to_x01(data);
        end if;
    end if;
    end process;

end behavioral;
