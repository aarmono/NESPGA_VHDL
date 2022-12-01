library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.joy_bus_types.all;
use work.nes_types.all;
use work.utilities.all;

entity joystick_io is
port
(
    clk    : in std_logic;
    clk_en : in boolean := true;
    reset  : in boolean;

    cpu_bus       : in  joy_bus_t;
    data_to_joy   : in  data_t;
    data_from_joy : out data_t;

    joy_strobe : out std_logic;

    shift_joy_1 : out std_logic;
    joy_1_val   : in std_logic;

    shift_joy_2 : out std_logic;
    joy_2_val   : in std_logic
);
end entity;

architecture behavioral of joystick_io
is

    type reg_t is record
        joy_1_val   : std_logic;
        joy_2_val   : std_logic;
        joy_strobe  : std_logic;
        shift_joy_1 : std_logic;
        shift_joy_2 : std_logic;
    end record;
    
    constant RESET_REG : reg_t :=
    (
        joy_1_val => '0',
        joy_2_val => '0',
        joy_strobe => '0',
        shift_joy_1 => '0',
        shift_joy_2 => '0'
    );
    
    type joy_out_t is record
        reg           : reg_t;
        data_from_joy : data_t;
        joy_strobe    : std_logic;
        shift_joy_1   : std_logic;
        shift_joy_2   : std_logic;
    end record;
    
    type joy_in_t is record
        reg            : reg_t;
        cpu_bus        : joy_bus_t;
        data_to_joy    : data_t;
        joy_1_val      : std_logic;
        joy_2_val      : std_logic;
    end record;

    function cycle_joy(joy_in : joy_in_t) return joy_out_t
    is
        variable joy_out : joy_out_t;
    begin
        joy_out.reg := joy_in.reg;
        joy_out.data_from_joy := (others => '-');

        if is_bus_read(joy_in.cpu_bus)
        then
            -- Reading from this register causes a clock pulse to be sent to
            -- the controller port CLK line on one controller, and one bit
            -- will be read from the connected input lines. $4016 reads only
            -- from controller port 1, and $4017 reads only from controller
            -- port 2
            --
            -- The CLK line for controller port is R/W nand
            -- (ADDRESS == $4016/$4017) (i.e., CLK is low only when reading
            -- $4016/$4017, since R/W high means read). When this transitions
            -- from high to low, the buffer inside the NES latches the output
            -- of the controller data lines, and when it transitions from low
            -- to high, the shift register in the controller shifts one bit.
            case joy_in.cpu_bus.address is
                when "0" =>
                    joy_out.reg.shift_joy_1 := '1';
                    joy_out.data_from_joy :=
                        x"40" or to_std_logic_vector(joy_in.reg.joy_1_val,
                                                     data_t'length);
                when "1" =>
                    joy_out.reg.shift_joy_2 := '1';
                    joy_out.data_from_joy :=
                        x"40" or to_std_logic_vector(joy_in.reg.joy_2_val,
                                                     data_t'length);
                when others =>
                    null;
            end case;
        elsif is_bus_write(joy_in.cpu_bus) and joy_in.cpu_bus.address = "0"
        then
            joy_out.reg.joy_strobe := joy_in.data_to_joy(0);
        else
            joy_out.reg.shift_joy_1 := '0';
            joy_out.reg.shift_joy_2 := '0';

            -- The read value is inverted: a high signal from the data line
            -- will read as 0, and a low signal will read as 1.
            if joy_in.reg.shift_joy_1 = '1' or joy_in.reg.joy_strobe = '1'
            then
                joy_out.reg.joy_1_val := not joy_in.joy_1_val;
            end if;

            if joy_in.reg.shift_joy_2 = '1' or joy_in.reg.joy_strobe = '1'
            then
                joy_out.reg.joy_2_val := not joy_in.joy_2_val;
            end if;
        end if;

        joy_out.joy_strobe := joy_in.reg.joy_strobe;
        joy_out.shift_joy_1 := joy_in.reg.shift_joy_1;
        joy_out.shift_joy_2 := joy_in.reg.shift_joy_2;
        
        return joy_out;
    end;
    
    signal reg : reg_t := RESET_REG;
    signal reg_next : reg_t;

begin


    process(all)
    is
        variable joy_in : joy_in_t;
        variable joy_out : joy_out_t;
    begin
        joy_in.reg := reg;

        joy_in.cpu_bus := cpu_bus;
        joy_in.data_to_joy := data_to_joy;
        
        joy_in.joy_1_val := joy_1_val;
        joy_in.joy_2_val := joy_2_val;
        
        joy_out := cycle_joy(joy_in);
        
        reg_next <= joy_out.reg;

        data_from_joy <= joy_out.data_from_joy;

        joy_strobe <= joy_out.joy_strobe;
        shift_joy_1 <= joy_out.shift_joy_1;
        shift_joy_2 <= joy_out.shift_joy_2;
    end process;
    
    process(clk)
    is
    begin
    -- double-IF required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= reg_next;
        end if;
    end if;
    end if;
    end process;

end behavioral;
