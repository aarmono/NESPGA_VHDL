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
    
    filter_invalid : in boolean;
    
    ps2_clk : inout std_logic;
    ps2_dat : inout std_logic;
    
    joy_strobe  : in std_logic;
    
    shift_joy_1 : in std_logic;
    joy_1_val   : out std_logic;
    joy_1_reg   : out std_logic_vector(7 downto 0);
    
    shift_joy_2 : in std_logic;
    joy_2_val   : out std_logic;
    joy_2_reg   : out std_logic_vector(7 downto 0)
);
end ps2_joystick;

architecture behavioral of ps2_joystick is

    subtype joy_vals_t is std_logic_vector(7 downto 0);
    
    subtype key_idx_t is integer range 0 to 7;
    
    constant KEY_IDX_UP     : key_idx_t := 4;
    constant KEY_IDX_DOWN   : key_idx_t := 5;
    constant KEY_IDX_LEFT   : key_idx_t := 6;
    constant KEY_IDX_RIGHT  : key_idx_t := 7;
    constant KEY_IDX_B      : key_idx_t := 1;
    constant KEY_IDX_A      : key_idx_t := 0;
    constant KEY_IDX_START  : key_idx_t := 3;
    constant KEY_IDX_SELECT : key_idx_t := 2;
    
    function apply_filter(vals : joy_vals_t) return joy_vals_t
    is
        variable ret : joy_vals_t;
    begin
        ret := vals;
        
        ret(KEY_IDX_UP)   := vals(KEY_IDX_UP)   or not vals(KEY_IDX_DOWN);
        ret(KEY_IDX_DOWN) := vals(KEY_IDX_DOWN) or not vals(KEY_IDX_UP);

        ret(KEY_IDX_LEFT)  := vals(KEY_IDX_LEFT)  or not vals(KEY_IDX_RIGHT);
        ret(KEY_IDX_RIGHT) := vals(KEY_IDX_RIGHT) or not vals(KEY_IDX_LEFT);
        
        return ret;
    end;
    
    -- Keyboard clock domain
    signal joy_1_vals_ps2 : joy_vals_t := (others => '1');
    
    signal key_ascii   : std_logic_vector(7 downto 0);
    signal key_stb     : std_logic;
    signal key_pressed : boolean;
    
    -- CPU clock domain
    signal joy_1_vals_cpu : joy_vals_t := (others => '1');
    signal joy_1_shift : unsigned(joy_vals_t'range) := (others => '1');
    
    signal shift_joy_1_prev : std_logic;

    signal sig_joy_1_reg : joy_vals_t;

begin

    joy_1_val <= joy_1_shift(0);
    joy_2_val <= '1';
    
    joy_1_reg <= sig_joy_1_reg;
    joy_2_reg <= (others => '1');

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
        variable idx : key_idx_t;
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
                when x"77" |
                     x"57" =>
                    idx := KEY_IDX_UP;
                    update := true;
                -- s (Down)
                when x"73" |
                     x"53" =>
                    idx := KEY_IDX_DOWN;
                    update := true;
                -- a (Left)
                when x"61" |
                     x"41" =>
                    idx := KEY_IDX_LEFT;
                    update := true;
                -- d (Right)
                when x"64" |
                     x"44" =>
                    idx := KEY_IDX_RIGHT;
                    update := true;
                -- j (b)
                when x"6A" |
                     x"4A" =>
                    idx := KEY_IDX_B;
                    update := true;
                -- k (a)
                when x"6B" |
                     x"4B" =>
                    idx := KEY_IDX_A;
                    update := true;
                -- u (Start)
                when x"75" |
                     x"55" =>
                    idx := KEY_IDX_START;
                    update := true;
                -- i (Select)
                when x"69" |
                     x"49" =>
                    idx := KEY_IDX_SELECT;
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
    
    sig_joy_1_reg <= apply_filter(joy_1_vals_cpu) when filter_invalid else
                     joy_1_vals_cpu;
    
    process(clk_cpu)
    begin
    if rising_edge(clk_cpu) then
        if reset
        then
            joy_1_vals_cpu   <= (others => '1');
            shift_joy_1_prev <= '0';
            joy_1_shift      <= (others => '1');
        else
            shift_joy_1_prev <= shift_joy_1;
            
            -- Clock domain crossing
            joy_1_vals_cpu <= joy_1_vals_ps2;
            
            if joy_strobe = '1'
            then
                joy_1_shift <= unsigned(sig_joy_1_reg);
            elsif shift_joy_1 = '1' and shift_joy_1_prev = '0'
            then
                joy_1_shift <= shift_right(joy_1_shift, 1) or x"80";
            end if;
        end if;
    end if;
    end process;

end behavioral;