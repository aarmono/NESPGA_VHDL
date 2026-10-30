library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;

-- A controller port on the GPIO header. The CPU's strobe and CLK lines go
-- out to the port, and its data lines come back through a synchronizer.
-- Controllers inside the FPGA (the keyboard) share the port: the data lines
-- are wired-AND, so either one can press a button. It also records the
-- buttons the CPU reads, for the LEDs
entity joy_port is
port
(
    clk   : in std_logic;
    reset : in boolean;

    -- CPU side of the port. joy_strobe and joy_clk must be registered
    -- (glitch free), since they drive the pins directly
    joy_strobe : in std_logic;
    joy_clk    : in std_logic;
    joy_data   : out joy_data_t;

    -- Data lines of the controllers inside the FPGA on this port
    int_data : in joy_data_t := JOY_DATA_IDLE;

    -- The first 8 bits the CPU read from D0 after the last strobe: the
    -- buttons of a standard controller, with A in bit 0. Low while pressed
    buttons : out std_logic_vector(7 downto 0);

    pin_latch : out std_logic;
    pin_clk   : out std_logic;
    -- Pulled up, so that an empty port reads as nothing pressed
    pin_data  : in joy_data_t
);
end joy_port;

architecture behavioral of joy_port is

    subtype buttons_t is std_logic_vector(7 downto 0);
    subtype bit_count_t is natural range 0 to buttons_t'length;

    type reg_t is record
        data_sync : joy_data_t;
        data      : joy_data_t;
        clk_prev  : std_logic;
        -- D0 while CLK is low: the bit the CPU reads
        read_bit  : std_logic;
        read_bits : buttons_t;
        bit_count : bit_count_t;
        buttons   : buttons_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        data_sync => JOY_DATA_IDLE,
        data      => JOY_DATA_IDLE,
        clk_prev  => '1',
        read_bit  => '1',
        read_bits => (others => '1'),
        bit_count => bit_count_t'high,
        buttons   => (others => '1')
    );

    type port_in_t is record
        joy_strobe : std_logic;
        joy_clk    : std_logic;
        -- The data lines the CPU reads
        data_out   : joy_data_t;
        pin_data   : joy_data_t;
    end record;

    function cycle_port(reg : reg_t; port_in : port_in_t) return reg_t
    is
        variable ret : reg_t;
    begin
        ret := reg;

        ret.clk_prev := port_in.joy_clk;

        -- The CLK line rises before the controller shifts, so the bit
        -- recorded while it was low is the one the CPU read
        if port_in.joy_strobe = '1'
        then
            ret.bit_count := 0;
        elsif port_in.joy_clk = '0'
        then
            ret.read_bit := port_in.data_out(0);
        elsif reg.clk_prev = '0' and reg.bit_count < bit_count_t'high
        then
            ret.read_bits := reg.read_bit & reg.read_bits(7 downto 1);
            ret.bit_count := reg.bit_count + 1;

            if reg.bit_count = bit_count_t'high - 1
            then
                ret.buttons := ret.read_bits;
            end if;
        end if;

        -- Clock domain crossing. The lines change independently, so each
        -- bit is synchronized on its own
        ret.data := reg.data_sync;
        ret.data_sync := to_X01(port_in.pin_data);

        return ret;
    end;

    signal reg : reg_t := RESET_REG;

    signal data_out : joy_data_t;

begin

    pin_latch <= joy_strobe;
    pin_clk <= joy_clk;

    data_out <= reg.data and int_data;
    joy_data <= data_out;

    buttons <= reg.buttons;

    process(clk)
    begin
    if rising_edge(clk) then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= cycle_port(reg, (joy_strobe, joy_clk, data_out, pin_data));
        end if;
    end if;
    end process;

end behavioral;
