library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.cart_pin_types.all;

-- The pins between a cart_slot and a cartridge, made from what each side
-- drives. A data bit nobody drives keeps its last value, as on a board with
-- bus hold. Both sides driving a data bus is reported as an error starting
-- with NAME, and the bits both drive are X
entity cart_pin_bus is
generic
(
    NAME : string := "cart_pin_bus"
);
port
(
    -- What the console drives
    console : in cart_console_pins_t;
    -- What the cartridge drives
    drive   : in cart_board_drive_t;
    -- What the console sees
    board   : out cart_board_pins_t
);
end entity;

architecture behavioral of cart_pin_bus is
begin

    process(console, drive)
    is
        variable value : data_t := (others => '0');
    begin
        for i in value'range
        loop
            if console.cpu_data_oe and drive.cpu_data_oe(i) = '1'
            then
                value(i) := 'X';
            elsif console.cpu_data_oe
            then
                value(i) := console.cpu_data(i);
            elsif drive.cpu_data_oe(i) = '1'
            then
                value(i) := drive.cpu_data(i);
            end if;
        end loop;

        if console.cpu_data_oe and drive.cpu_data_oe /= x"00"
        then
            report NAME & ": CPU data bus driven by both sides"
                severity error;
        end if;

        board.cpu_data <= value;
    end process;

    process(console, drive)
    is
        variable value : data_t := (others => '0');
    begin
        if console.ppu_data_oe and drive.ppu_data_oe
        then
            report NAME & ": PPU data bus driven by both sides"
                severity error;
            value := (others => 'X');
        elsif console.ppu_data_oe
        then
            value := console.ppu_data;
        elsif drive.ppu_data_oe
        then
            value := drive.ppu_data;
        end if;
        board.ppu_data <= value;
    end process;

    -- /IRQ is pulled up by the console
    board.irq_n <= '0' when drive.irq_n = '0' else '1';
    board.ciram_ce_n <= drive.ciram_ce_n;
    board.ciram_a10 <= drive.ciram_a10;

end behavioral;
