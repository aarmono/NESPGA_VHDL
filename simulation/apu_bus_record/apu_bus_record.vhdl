library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.apu_bus_types.all;
use work.nes_types.all;

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
        
        variable bus_read_str  : string(1 to 8);
        variable bus_write_str : string(1 to 8);
        variable delta_str     : string(1 to 32);
    begin
        file_open(fstatus, fptr, FILEPATH, write_mode);
        last_time := NOW;
        while true loop
            wait on apu_bus;
            
            delta := NOW - last_time;
            bus_read_str := boolean'image(apu_bus.read);
            bus_write_str := boolean'image(apu_bus.write);
            delta_str := time'image(delta);
            
            write(file_line, delta_str, left, delta_str'length+1);
            write(file_line, apu_bus.address, left, apu_bus.address'length+1);
            write(file_line, bus_read_str,
                  left, bus_read_str'length+1);
            write(file_line, bus_write_str,
                  left, bus_write_str'length+1);
            write(file_line, apu_data_in);
            writeline(fptr, file_line);
            
            last_time := NOW;
        end loop;
    end process;

end behavioral;
