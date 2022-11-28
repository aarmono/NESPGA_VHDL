library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

package fm2_file is

    subtype joy_val_t is std_logic_vector(7 downto 0);

    procedure fm2_fopen
    (
        file file_in : text;
        filename     : string
    );
    
    procedure fm2_fread
    (
        file file_in : text;
        joy_val_1    : out joy_val_t;
        joy_val_2    : out joy_val_t
    );
    
    procedure fm2_fclose
    (
        file file_in : text
    );
    
end fm2_file;

package body fm2_file is
    
    procedure fm2_fopen
    (
        file file_in : text;
        filename     : string
    )
    is
        variable stat : file_open_status;
    begin
        file_open(stat, file_in, filename, read_mode);
    end;

    procedure read_single_joy(l : inout line; joy_val : out joy_val_t)
    is
        variable c   : character;
        variable val : std_logic;
    begin
        joy_val := (others => '1');

        -- Read the first character and skip if it's a pipe (meaning the
        -- controller is disconnected and there are no values to read)
        read(l, c);
        if c /= '|'
        then
            -- FM2 stores presses in the following order
            -- RLDUTSBA (Right, Left, Down, Up, sTart, Select, B, A)
            --
            -- NES reads presses in the following order:
            -- 0 - A
            -- 1 - B
            -- 2 - Select
            -- 3 - Start
            -- 4 - Up
            -- 5 - Down
            -- 6 - Left
            -- 7 - Right
            --
            -- So if we just loop 7 downto 0 then it all works out
            for i in joy_val_t'high downto joy_val_t'low
            loop
                -- Any character other than ' ' or '.' means that the button was
                -- pressed
                if c = '.' or c = ' '
                then
                    -- NES controller is active-low
                    val := '1';
                else
                    val := '0';
                end if;

                joy_val(i) := val;

                -- Don't skip the read at the end of the loop. On the last
                -- iteration this will read the ending pipe delimiter and allow
                -- us to call this function again after the first call returns
                read(l, c);
            end loop;
        end if;
    end;

    procedure fm2_fread
    (
        file file_in : text;
        joy_val_1    : out joy_val_t;
        joy_val_2    : out joy_val_t
    )
    is
        variable is_input_line : boolean := false;

        variable l : line;
        variable c : character;

        variable val : std_logic;
    begin
        joy_val_1 := (others => '1');
        joy_val_2 := (others => '1');

        if not endfile(file_in)
        then
            while not is_input_line
            loop
                readline(file_in, l);
                read(l, c);

                is_input_line := c = '|';
            end loop;

            -- Currently at one element past the starting pipe. Skip "commands"
            -- element
            read(l, c);
            while c /= '|'
            loop
                read(l, c);
            end loop;

            -- Controller 1 values
            read_single_joy(l, joy_val_1);
            -- Controller 2 values
            read_single_joy(l, joy_val_2);
        end if;
    end;

    procedure fm2_fclose
    (
        file file_in : text
    )
    is
    begin
        file_close(file_in);
    end;
end package body;