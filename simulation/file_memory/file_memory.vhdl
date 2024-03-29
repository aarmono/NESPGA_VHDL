library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.binary_io.all;
use work.nes_types.all;
use work.file_bus_types.all;

entity file_memory is
generic
(
    FILEPATH    : string;
    MEM_BYTES   : integer := 65536;
    READ_DELAY  : time := 0 ns;
    WRITE_DELAY : time := 0 ns
);
port
(
    file_bus_1       : in file_bus_t;
    data_to_file_1   : in data_t := (others => '-');
    data_from_file_1 : out data_t;
    
    file_bus_2       : in file_bus_t := FILE_BUS_IDLE;
    data_to_file_2   : in data_t := (others => '-');
    data_from_file_2 : out data_t
);
end file_memory;

architecture behavioral of file_memory is

    type file_memory_t is array (0 to MEM_BYTES-1) of data_t;
    signal mem : file_memory_t;
    signal mem_initialized : boolean := false;
    
begin

    process(all)
        file test_mem     : byte_file_t;
        variable read_val : byte;
    begin
        if not mem_initialized
        then
            byte_fopen(test_mem, FILEPATH, read_mode);
            for i in mem'RANGE loop
                if not byte_feof(test_mem)
                then
                    mem(i) <= byte_fread(test_mem);
                else
                    mem(i) <= x"00";
                end if;
            end loop;
            byte_fclose(test_mem);
            
            mem_initialized <= true;
        end if;
        
        if is_bus_read(file_bus_1)
        then
            data_from_file_1 <= mem(to_integer(file_bus_1.address)) after READ_DELAY;
        elsif is_bus_write(file_bus_1)
        then
            mem(to_integer(file_bus_1.address)) <= data_to_file_1 after WRITE_DELAY;
        else
            data_from_file_1 <= (others => '-');
        end if;
        
        if is_bus_read(file_bus_2)
        then
            data_from_file_2 <= mem(to_integer(file_bus_2.address)) after READ_DELAY;
        elsif is_bus_write(file_bus_2)
        then
            mem(to_integer(file_bus_2.address)) <= data_to_file_2 after WRITE_DELAY;
        else
            data_from_file_2 <= (others => '-');
        end if;
    end process;

end behavioral;