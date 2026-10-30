library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.joy_bus_types.all;
use work.nes_types.all;
use work.utilities.all;

-- The controller port pins of the CPU: OUT0 (the strobe), /OE1 and /OE2
-- (the CLK lines of the ports) and the inverting buffers which put the port
-- data lines on the data bus.
entity joystick_io is
port
(
    clk    : in std_logic;
    clk_en : in boolean := true;
    clk_odd : in boolean;
    reset  : in boolean;

    cpu_bus       : in  joy_bus_t;
    data_to_joy   : in  data_t;
    data_from_joy : out data_t;

    -- OUT0, shared by both ports. A standard controller reloads its shift
    -- register from the buttons while this is high
    joy_strobe : out std_logic;

    -- The CLK lines are high while idle and low for the cycle after each
    -- cycle the CPU reads $4016/$4017. A standard controller shifts on the
    -- rising edge
    joy_1_clk  : out std_logic;
    joy_1_data : in joy_data_t;

    joy_2_clk  : out std_logic;
    joy_2_data : in joy_data_t
);
end entity;

architecture behavioral of joystick_io
is

    type reg_t is record
        joy_strobe  : std_logic;
        -- Last value written to the strobe bit
        strobe_val  : std_logic;
        joy_1_clk   : std_logic;
        joy_2_clk   : std_logic;
    end record;

    constant RESET_REG : reg_t :=
    (
        joy_strobe => '0',
        strobe_val => '0',
        joy_1_clk  => '1',
        joy_2_clk  => '1'
    );

    -- The CLK line of each controller port is R/W nand
    -- (ADDRESS == $4016/$4017) (i.e., CLK is low only when reading
    -- $4016/$4017, since R/W high means read). Consecutive reads hold it low,
    -- so they only clock the controller once.
    --
    -- The bus is only valid at the end of the cycle, so the line is
    -- registered then, which delays it by a cycle. It rises before the CPU
    -- can read the port again, other than in a consecutive read
    function get_joy_clk(bus_in : joy_bus_t; port_addr : joy_addr_t)
    return std_logic
    is
    begin
        if is_bus_read(bus_in) and bus_in.address = port_addr
        then
            return '0';
        else
            return '1';
        end if;
    end;

    type joy_in_t is record
        clk_odd     : boolean;
        cpu_bus     : joy_bus_t;
        data_to_joy : data_t;
    end record;

    function cycle_joy(reg : reg_t; joy_in : joy_in_t) return reg_t
    is
        variable ret : reg_t;
    begin
        ret := reg;

        if is_bus_write(joy_in.cpu_bus) and joy_in.cpu_bus.address = "0"
        then
            ret.strobe_val := joy_in.data_to_joy(0);
        end if;

        -- The strobe output only changes on the transition from a read
        -- (even) cycle to a write (odd) cycle
        if not joy_in.clk_odd
        then
            ret.joy_strobe := ret.strobe_val;
        end if;

        ret.joy_1_clk := get_joy_clk(joy_in.cpu_bus, "0");
        ret.joy_2_clk := get_joy_clk(joy_in.cpu_bus, "1");

        return ret;
    end;

    -- The data lines are read through inverting buffers: a high signal from
    -- the data line reads as 0, and a low signal reads as 1. Bits 7-5 are
    -- not driven, so the memory map fills them with open bus
    function read_joy(bus_in : joy_bus_t; data_1, data_2 : joy_data_t)
    return data_t
    is
    begin
        if bus_in.address = "1"
        then
            return "000" & not to_X01(data_2);
        else
            return "000" & not to_X01(data_1);
        end if;
    end;

    signal reg : reg_t := RESET_REG;

begin

    joy_strobe <= reg.joy_strobe;
    joy_1_clk <= reg.joy_1_clk;
    joy_2_clk <= reg.joy_2_clk;

    -- The CPU samples the data lines at the end of the read cycle
    data_from_joy <= read_joy(cpu_bus, joy_1_data, joy_2_data);

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
            reg <= cycle_joy(reg, (clk_odd, cpu_bus, data_to_joy));
        end if;
    end if;
    end if;
    end process;

end behavioral;
