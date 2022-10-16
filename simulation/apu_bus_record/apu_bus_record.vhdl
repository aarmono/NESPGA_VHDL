library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.apu_bus_types.all;
use work.nes_core.all;

entity apu_bus_record is
generic
(
    FILEPATH : string
);
port
(
    apu_bus     : in apu_bus_t;
    apu_data_in : in data_t
);
end apu_bus_record;

architecture behavioral of apu_bus_record is

    file fptr: text;
    
begin

    process
        variable fstatus   : file_open_status;
        variable file_line : line;
        variable last_time : time;
        variable delta     : time;
    begin
        file_open(fstatus, fptr, FILEPATH, write_mode);
        last_time := NOW;
        while true loop
            wait on apu_bus;
            
            delta := NOW - last_time;
            write(file_line, delta, left, time'image(delta)'length+1);
            write(file_line, apu_bus.address, left, apu_bus.address'length+1);
            write(file_line, apu_bus.read,
                  left, boolean'image(apu_bus.read)'length+1);
            write(file_line, apu_bus.write,
                  left, boolean'image(apu_bus.write)'length+1);
            write(file_line, apu_data_in);
            writeline(fptr, file_line);
            
            last_time := NOW;
        end loop;
    end process;

end behavioral;