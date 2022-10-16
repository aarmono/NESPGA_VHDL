library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.apu_bus_types.all;
use work.nes_core.all;

entity apu_bus_playback is
generic
(
    FILEPATH : string
);
port
(
    apu_bus      : out apu_bus_t;
    apu_data_out : out data_t;
    done         : out boolean
);
end apu_bus_playback;

architecture behavioral of apu_bus_playback is

    file fptr: text;
    
    signal done_sig : boolean := false;
begin

    done <= done_sig;
    
    process
        variable fstatus   : file_open_status;
        variable file_line : line;
        variable delta     : time;
        variable address   : apu_addr_t;
        variable data      : data_t;
        variable bus_read  : boolean;
        variable bus_write : boolean;
    begin
        apu_bus <= bus_idle(apu_bus);
        apu_data_out <= (others => '-');
        
        if not done_sig
        then
            file_open(fstatus, fptr, FILEPATH, read_mode);
            
            while not endfile(fptr) loop
                readline(fptr, file_line);
                read(file_line, delta);
                read(file_line, address);
                read(file_line, bus_read);
                read(file_line, bus_write);
                read(file_line, data);
                
                wait for delta;
                
                apu_bus.address <= address;
                apu_bus.read <= bus_read;
                apu_bus.write <= bus_write;
                apu_data_out <= data;
            end loop;
            
            file_close(fptr);
            done_sig <= true;
        end if;
    end process;

end behavioral;