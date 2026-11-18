library IEEE;
use IEEE.std_logic_1164.all;
use work.nes_types.all;
use work.prg_bus_types.all;
use work.cart_connector_types.all;

-- The buttons of controller 1, as a cartridge can tell them. The controller
-- ports are not on the cartridge connector, but the CPU's buses are: the
-- strobe is bit 0 of a write to 0x4016, and each read of 0x4016 puts the
-- controller's next bit on D0, high for a button that is pressed. So this
-- follows the game as it reads the controller, and has the buttons the game
-- last read. A game that doesn't read controller 1 shows none, and a read
-- that a DMC DMA repeats shifts the buttons after it by one.
entity cart_joy_snoop is
port
(
    clk   : in std_logic;
    reset : in boolean;

    cpu_en : in boolean;
    -- The CPU side of the cartridge connector
    cpu_in : in cart_cpu_in_t;

    -- The first 8 bits the CPU read from D0 after the last strobe: the
    -- buttons of a standard controller, with A in bit 0. Low while pressed,
    -- as joy_port has them
    buttons : out std_logic_vector(7 downto 0)
);
end entity;

architecture behavioral of cart_joy_snoop
is

    subtype buttons_t is std_logic_vector(7 downto 0);
    subtype bit_count_t is natural range 0 to buttons_t'length;

    type snoop_reg_t is record
        strobe    : boolean;
        read_bits : buttons_t;
        bit_count : bit_count_t;
        buttons   : buttons_t;
    end record;

    constant RESET_SNOOP_REG : snoop_reg_t :=
    (
        strobe => false,
        read_bits => (others => '1'),
        bit_count => bit_count_t'high,
        buttons => (others => '1')
    );

    -- 0x4016, less /ROMSEL's A15
    constant JOY_1_ADDR : prg_addr_t := "100000000010110";

    function is_joy_1(cpu : cart_cpu_in_t) return boolean
    is
    begin
        return not cpu.romsel and cpu.prg_bus.address = JOY_1_ADDR;
    end;

    -- A CPU cycle
    function cycle_snoop
    (
        reg : snoop_reg_t;
        cpu : cart_cpu_in_t
    )
    return snoop_reg_t
    is
        variable ret : snoop_reg_t;
    begin
        ret := reg;

        if not is_joy_1(cpu)
        then
            return ret;
        end if;

        if cpu.prg_bus.write
        then
            ret.strobe := cpu.data(0) = '1';
            if ret.strobe
            then
                ret.bit_count := 0;
            end if;
        -- While the strobe is high the controller doesn't shift
        elsif cpu.prg_bus.read and not reg.strobe and
              reg.bit_count < bit_count_t'high
        then
            ret.read_bits := not cpu.data(0) & reg.read_bits(7 downto 1);
            ret.bit_count := reg.bit_count + 1;

            if reg.bit_count = bit_count_t'high - 1
            then
                ret.buttons := ret.read_bits;
            end if;
        end if;

        return ret;
    end;

    signal reg : snoop_reg_t := RESET_SNOOP_REG;

begin

    buttons <= reg.buttons;

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_SNOOP_REG;
        elsif cpu_en
        then
            reg <= cycle_snoop(reg, cpu_in);
        end if;
    end if;
    end process;

end behavioral;
