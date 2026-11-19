library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Simulation model of an asynchronous SRAM of 16-bit words with byte
-- enables, such as the IS61LV25616 of the DE1 (256K words, 10 ns). The
-- memory starts as zeros.
--
-- A read drives X on DQ from HOLD after the address or a control changes
-- until the data is valid. A write is taken as /WE or /CE rises, for the
-- bytes enabled.
--
-- A timing violation is reported as an error starting with "sram_16:": /WE
-- low for less than WRITE_PULSE, the address changing while it is low or
-- within ADDR_SETUP before it falls, or the data changing within DATA_SETUP
-- before it rises
entity sram_16 is
generic
(
    ADDR_BITS   : positive := 18;
    -- Address, /CE or byte enable to data
    ACCESS_TIME : time := 10 ns;
    -- /OE to data
    OE_ACCESS   : time := 4 ns;
    -- Data stays valid this long after the address changes
    HOLD        : time := 2 ns;
    -- Deselect, /OE high or /WE low to the outputs floating
    DISABLE     : time := 4 ns;
    WRITE_PULSE : time := 8 ns;
    ADDR_SETUP  : time := 0 ns;
    DATA_SETUP  : time := 6 ns
);
port
(
    addr : in std_logic_vector(ADDR_BITS - 1 downto 0);
    dq   : inout std_logic_vector(15 downto 0);
    ce_n : in std_logic;
    oe_n : in std_logic;
    we_n : in std_logic;
    lb_n : in std_logic;
    ub_n : in std_logic
);
end entity;

architecture behavioral of sram_16
is

    procedure violation(msg : string)
    is
    begin
        report "sram_16: " & msg severity error;
    end;

begin

    -- The memory is a variable, since ghdl keeps a signal array as a
    -- signal per bit
    process(addr, ce_n, oe_n, we_n, lb_n, ub_n)
    is
        subtype byte_t is natural range 0 to 255;
        type mem_t is array(0 to 2**ADDR_BITS - 1) of byte_t;
        variable low_mem  : mem_t := (others => 0);
        variable high_mem : mem_t := (others => 0);

        variable writing   : boolean := false;
        variable write_at  : time := 0 ns;
        variable addr_at   : time := 0 ns;
        variable index     : natural;
        variable value     : std_logic_vector(15 downto 0);
        variable is_write  : boolean;
        variable reading   : boolean;
        variable was_reading : boolean := false;
    begin
        is_write := ce_n = '0' and we_n = '0';

        if addr'event
        then
            if writing
            then
                violation("address changed during a write");
            end if;
            addr_at := now;
        end if;

        if is_write and not writing
        then
            write_at := now;
            if now - addr_at < ADDR_SETUP
            then
                violation("address setup before /WE");
            end if;
        elsif writing and not is_write
        then
            if now - write_at < WRITE_PULSE
            then
                violation("write pulse too short");
            end if;
            if dq'last_event < DATA_SETUP
            then
                violation("data setup before the end of the write");
            end if;

            if not is_x(addr'last_value) or not addr'event
            then
                if addr'event
                then
                    index := to_integer(unsigned(addr'last_value));
                else
                    index := to_integer(unsigned(addr));
                end if;
                if lb_n = '0' and not is_x(dq(7 downto 0))
                then
                    low_mem(index) := to_integer(unsigned(dq(7 downto 0)));
                end if;
                if ub_n = '0' and not is_x(dq(15 downto 8))
                then
                    high_mem(index) := to_integer(unsigned(dq(15 downto 8)));
                end if;
            end if;
        end if;
        writing := is_write;

        reading := ce_n = '0' and oe_n = '0' and we_n = '1';
        if reading and not is_x(addr)
        then
            index := to_integer(unsigned(addr));
            value := (others => 'Z');
            if lb_n = '0'
            then
                value(7 downto 0) :=
                    std_logic_vector(to_unsigned(low_mem(index), 8));
            end if;
            if ub_n = '0'
            then
                value(15 downto 8) :=
                    std_logic_vector(to_unsigned(high_mem(index), 8));
            end if;

            if was_reading and not (ce_n'event or we_n'event)
               and oe_n'event
            then
                dq <= transport value after OE_ACCESS;
            elsif was_reading
            then
                dq <= transport (others => 'X') after HOLD;
                dq <= transport value after ACCESS_TIME;
            else
                dq <= transport value after ACCESS_TIME;
            end if;
        elsif reading
        then
            dq <= transport (others => 'X') after HOLD;
        else
            dq <= transport (others => 'Z') after DISABLE;
        end if;
        was_reading := reading;
    end process;

end behavioral;
