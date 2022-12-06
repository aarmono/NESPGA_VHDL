library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.perhipherals.all;

entity ps2_joystick is
port
(
    clk_key : in std_logic;
    clk_cpu : in std_logic;
    reset   : in boolean;
    
    ps2_clk : inout std_logic;
    ps2_dat : inout std_logic;
    
    joy_strobe  : in std_logic;
    
    shift_joy_1 : in std_logic;
    joy_1_val   : out std_logic;
    
    shift_joy_2 : in std_logic;
    joy_2_val   : out std_logic
);
end ps2_joystick;

architecture behavioral of ps2_joystick is

    subtype joy_vals_t is std_logic_vector(7 downto 0);
    
    -- Keyboard clock domain
    signal joy_1_vals_ps2 : joy_vals_t := (others => '1');
    
    signal key_ascii   : std_logic_vector(7 downto 0);
    signal key_stb     : std_logic;
    signal key_pressed : boolean;
    
    -- CPU clock domain
    signal joy_1_vals_cpu : joy_vals_t := (others => '1');
    signal joy_1_shift : unsigned(joy_vals_t'range) := (others => '1');
    
    signal shift_joy_1_prev : std_logic;

begin

    joy_1_val <= joy_1_shift(0);
    joy_2_val <= '1';

    keyboard_controller : ps2_keyboard
    port map
    (
        clk => clk_key,
        reset => reset,
        
        ps2_clk => ps2_clk,
        ps2_data => ps2_dat,
        
        ascii_out => key_ascii,
        ascii_out_clk => key_stb,
        ascii_pressed => key_pressed
    );
    
    process(clk_key)
        variable idx : integer;
        variable val : std_logic;
        variable update : boolean;
    begin
    if rising_edge(clk_key)
    then
        if reset
        then
            joy_1_vals_ps2 <= (others => '1');
        elsif key_stb = '1'
        then
            update := false;
            -- Keys are active low
            val := not to_std_logic(key_pressed);
            case key_ascii is
                -- w (Up)
                when x"77" =>
                    idx := 4;
                    update := true;
                -- s (Down)
                when x"73" =>
                    idx := 5;
                    update := true;
                -- a (Left)
                when x"61" =>
                    idx := 6;
                    update := true;
                -- d (Right)
                when x"64" =>
                    idx := 7;
                    update := true;
                -- j (b)
                when x"6A" =>
                    idx := 1;
                    update := true;
                -- k (a)
                when x"6B" =>
                    idx := 0;
                    update := true;
                -- u (Start)
                when x"75" =>
                    idx := 3;
                    update := true;
                -- i (Select)
                when x"69" =>
                    idx := 2;
                    update := true;
                when others =>
            end case;
            
            if update
            then
                joy_1_vals_ps2(idx) <= val;
            end if;
        end if;
    end if;
    end process;
    
    process(clk_cpu)
    begin
    if rising_edge(clk_cpu) then
        if reset
        then
            joy_1_vals_cpu <= (others => '1');
            shift_joy_1_prev <= '0';
            joy_1_shift <= (others => '1');
        else
            shift_joy_1_prev <= shift_joy_1;
            
            -- Clock domain crossing
            joy_1_vals_cpu <= joy_1_vals_ps2;
            
            if joy_strobe = '1'
            then
                joy_1_shift <= unsigned(joy_1_vals_cpu);
            elsif shift_joy_1 = '1' and shift_joy_1_prev = '0'
            then
                joy_1_shift <= shift_right(joy_1_shift, 1) or x"80";
            end if;
        end if;
    end if;
    end process;

end behavioral;