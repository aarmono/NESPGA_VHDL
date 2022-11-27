library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.fm2_file.all;
use std.textio.all;
use std.env.all;

entity fm2_file_bench is
generic
(
    FILEPATH : string
);
end fm2_file_bench;

architecture behavioral of fm2_file_bench is
begin

    process
    is
        file fm2 : text;

        variable joy_1_val : joy_val_t;
        variable joy_2_val : joy_val_t;

        variable frame : integer := 1;
    begin

        fm2_fopen(fm2, FILEPATH);

        while not endfile(fm2)
        loop
            fm2_fread(fm2, joy_1_val, joy_2_val);

            report "Frame: " & to_string(frame) &
                   " Joy 1: " & to_string(joy_1_val) &
                   " Joy 2: " & to_string(joy_2_val)
                   severity note;

            frame := frame + 1;
        end loop;

        fm2_fclose(fm2);
        finish;
    end process;

end behavioral;
