library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.file_bus_types.all;

-- Streams the contents of flash from address 0, for sdram_rom.
--
-- Each byte is presented on data with valid true once the flash has had
-- FLASH_READ_CLKS clocks to respond to its address, and is held until it is
-- taken by a clock where ready is also true. The address is advanced on the
-- clock after a byte is taken, and only if stop is not true by then, so the
-- flash is never read past the last byte that was needed.
entity flash_stream is
generic
(
    -- Clocks to wait after changing the flash address before sampling data
    FLASH_READ_CLKS : positive := 8
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    flash_bus       : out file_bus_t;
    data_from_flash : in data_t;

    stop  : in boolean;
    data  : out data_t;
    valid : out boolean;
    ready : in boolean
);
end flash_stream;

architecture behavioral of flash_stream is

    subtype addr_t is natural range 0 to 2**file_addr_t'length - 1;
    subtype wait_t is natural range 0 to FLASH_READ_CLKS;

    type reg_t is record
        addr       : addr_t;
        flash_wait : wait_t;
        advance    : boolean;
    end record;

    constant RESET_REG : reg_t :=
    (
        addr => 0,
        flash_wait => FLASH_READ_CLKS,
        advance => false
    );

    signal reg    : reg_t := RESET_REG;
    signal reg_in : reg_t;

begin

    flash_bus <= FILE_BUS_IDLE when stop else
                 bus_read(to_unsigned(reg.addr, file_addr_t'length));
    data <= data_from_flash;
    valid <= reg.flash_wait = 0 and not reg.advance and not stop;

    process(all)
        variable v_reg : reg_t;
    begin
        v_reg := reg;

        if reg.advance
        then
            if not stop
            then
                v_reg.advance := false;
                v_reg.flash_wait := FLASH_READ_CLKS;
                if reg.addr = addr_t'high
                then
                    v_reg.addr := 0;
                else
                    v_reg.addr := reg.addr + 1;
                end if;
            end if;
        elsif reg.flash_wait /= 0
        then
            v_reg.flash_wait := reg.flash_wait - 1;
        elsif ready
        then
            v_reg.advance := true;
        end if;

        reg_in <= v_reg;
    end process;

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= reg_in;
        end if;
    end if;
    end process;

end behavioral;
