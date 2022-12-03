library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter is
generic
(
    SIZE : natural := 16
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    update  : in boolean;
    value   : in unsigned(SIZE - 1 downto 0);

    match   : out boolean
);
end counter;

architecture behavioral of counter is
    signal cur_count : unsigned(SIZE - 1 downto 0);
    constant ZERO    : unsigned(SIZE - 1 downto 0) := to_unsigned(0, SIZE);
begin

    process(clk)
    begin
    if rising_edge(clk) then
        if reset then
            match <= false;
            cur_count <= value;
        elsif update then
            if cur_count = ZERO then
                match <= true;
                cur_count <= value;
            else
                match <= false;
                cur_count <= cur_count - x"1";
            end if;
        end if;
    end if;
    end process;

end behavioral;
