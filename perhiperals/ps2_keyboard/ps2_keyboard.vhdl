library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.ps2.all;

entity ps2_keyboard is
port
(
    clk   : in std_logic;
    reset : in boolean := false;

    ps2_clk  : inout std_logic;
    ps2_data : inout std_logic;

    ascii_out     : out std_logic_vector(7 downto 0);
    ascii_out_clk : out std_logic;
    ascii_pressed : out boolean 
);
end ps2_keyboard;

architecture behavioral of ps2_keyboard is
    signal key_data_in      : std_logic_vector(7 downto 0);
    signal key_data_in_clk  : std_logic;
    signal key_data_out     : std_logic_vector(7 downto 0);
    signal key_data_out_clk : std_logic;

    type state_t is
    (
        IDLE,
        STAT_REQ
    );

    signal ps2_state : ps2_state_t := PS2_STATE_T_RESET;
    signal key_state : keyboard_state_t := KEYBOARD_STATE_T_RESET;
    signal cur_state : state_t := IDLE;
begin

    ps2_bus : entity work.ps2_bus(behavioral)
    port map
    (
        clk => clk,
        reset => reset,
        
        ps2_clk => ps2_clk,
        ps2_data => ps2_data,

        data_in => key_data_in,
        data_in_clk => key_data_in_clk,
        
        data_out => key_data_out,
        data_out_clk => key_data_out_clk
    );

    process(clk)
        variable ps2_out : ps2_out_t;
        variable key_out : keyboard_out_t;
    begin
    if rising_edge(clk) then
        key_data_in_clk <= '0';
        ascii_out_clk <= '0';
        
        if key_data_out_clk = '1' then
            case cur_state is
                when IDLE =>
                    ps2_out := ps2_parser(ps2_state, key_data_out);
                    ps2_state <= ps2_out.state;
                    if ps2_out.key.valid
                    then
                        key_out := ps2_keyboard(key_state, ps2_out.key);
                        key_state <= key_out.state;
                        if key_out.key.valid
                        then
                            ascii_out <= key_out.key.value;
                            ascii_pressed <= key_out.key.pressed;
                            ascii_out_clk <= '1';
                        else
                            if key_out.state.caps_lock /= key_state.caps_lock or
                               key_out.state.num_lock /= key_state.num_lock or
                               key_out.state.scroll_lock /= key_state.scroll_lock
                            then
                                key_data_in <= x"ED";
                                key_data_in_clk <= '1';
                                cur_state <= STAT_REQ;
                            end if;
                        end if;
                    end if;
                when STAT_REQ =>
                    if key_data_out = x"FA" then
                        key_data_in <= "00000" &
                                       to_std_logic(key_state.caps_lock) &
                                       to_std_logic(key_state.num_lock) &
                                       to_std_logic(key_state.scroll_lock);
                        key_data_in_clk <= '1';
                        cur_state <= IDLE;
                    else
                        cur_state <= IDLE;
                    end if;
                when others =>
                    cur_state <= IDLE;
            end case;    
        end if;
        
        if reset then
            ascii_out <= (others => '0');
            ascii_out_clk <= '0';
            ascii_pressed <= false;
            ps2_state <= PS2_STATE_T_RESET;
            key_state <= KEYBOARD_STATE_T_RESET;
            cur_state <= IDLE;
        end if;
    end if;
    end process;
end behavioral;

