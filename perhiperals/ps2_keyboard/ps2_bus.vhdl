library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

entity ps2_bus is
port
(
    clk          : in std_logic;
    reset        : in boolean;

    ps2_clk      : inout std_logic;
    ps2_data     : inout std_logic;

    data_in      : in std_logic_vector(7 downto 0);
    data_in_clk  : in std_logic;

    data_out     : out std_logic_vector(7 downto 0);
    data_out_clk : out std_logic
);
end ps2_bus;

architecture behavioral of ps2_bus is
    signal count       : unsigned(3 downto 0);
    signal shift_reg   : std_logic_vector(7 downto 0);
    signal parity      : std_logic;
    signal read        : boolean;

    signal reset_rts   : boolean;
    signal rts_done    : boolean;
    
    signal ps2_event   : boolean;
    
    signal data_ready  : boolean;
    signal data_hold   : std_logic_vector(7 downto 0);
begin

    data_out <= shift_reg;

    ps2_detector : entity work.edge_detector(behavioral)
    port map
    (
        clk => clk,
        reset => reset,
        data => ps2_clk,
        negedge => ps2_event
    );

    rts_counter : entity work.counter(behavioral)
    generic map
    (
        SIZE => 7
    )
    port map
    (
        clk => clk,
        reset => reset_rts,
        update => true,
        value => to_unsigned(99, 7),
        match => rts_done
    );
    
    process(clk)
    begin
    if rising_edge(clk) then
        if reset then
            data_hold <= x"00";
            data_ready <= false;
        elsif data_in_clk = '1' then
            data_hold <= data_in;
            data_ready <= true;
        elsif not read and count = x"0C" and ps2_data = '0' then
            data_ready <= false;
        end if;
    end if;
    end process;

    process(clk)
    begin
    if rising_edge(clk) then
        if reset then
            data_out_clk <= '0';
            shift_reg <= x"00";
            parity <= '1';
            ps2_data <= 'Z';
            ps2_clk <= 'Z';
            count <= x"0";
            reset_rts <= true;
        elsif count = x"0" then
            if ps2_event and ps2_data = '0' then
                read <= true;
                reset_rts <= true;
                count <= count + x"1";
            elsif data_ready and ps2_clk = '1' then
                read <= false;
                count <= count + x"1";
                ps2_clk <= '0';
                ps2_data <= '0';
                shift_reg <= data_hold;
                reset_rts <= false;
            else
                ps2_clk <= 'Z';
                ps2_data <= 'Z';
            end if;
            data_out_clk <= '0';
            parity <= '1';
        elsif read and ps2_event then
            if count >= x"01" and count <= x"08" then
                shift_reg <= ps2_data & shift_reg(7 downto 1);
                parity <= parity xor ps2_data;
                count <= count + x"1";
            elsif count = x"09" then
                parity <= to_std_logic(parity = ps2_data);
                count <= count + x"1";
            else
                data_out_clk <= parity and ps2_data;
                count <= x"0";
            end if;
        elsif not read then
            if count = x"01" and rts_done then
                ps2_data <= '0';
                ps2_clk <= 'Z';
                count <= count + x"1";
                reset_rts <= true;
            elsif ps2_event then
                if count >= x"02" and count <= x"09" then
                    ps2_data <= shift_reg(0);
                    parity <= parity xor shift_reg(0);
                    shift_reg <= '0' & shift_reg(7 downto 1);
                    count <= count + x"1";
                elsif count = x"0A" then
                    ps2_data <= parity;
                    count <= count + x"1";
                elsif count = x"0B" then
                    ps2_data <= 'Z';
                    count <= count + x"1";
                elsif count = x"0C" then
                    count <= x"0";
                end if;
            end if;
        end if;
    end if;
    end process;

end behavioral;
