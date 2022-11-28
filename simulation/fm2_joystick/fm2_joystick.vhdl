library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.fm2_file.all;

entity fm2_joystick is
generic
(
    FILEPATH     : string;
    INPUT_OFFSET : integer := 0
);
port
(
    frame_valid : in boolean;

    joy_strobe : in std_logic;

    shift_joy_1 : in std_logic;
    joy_1_val   : out std_logic;

    shift_joy_2 : in std_logic;
    joy_2_val   : out std_logic
);
end fm2_joystick;

architecture behavioral of fm2_joystick is

    signal joy_1_cur   : joy_val_t := (others => '1');
    signal joy_1_shift : unsigned(joy_val_t'range) := (others => '0');

    signal joy_2_cur   : joy_val_t := (others => '1');
    signal joy_2_shift : unsigned(joy_val_t'range) := (others => '0');

begin

    joy_1_val <= joy_1_shift(0);
    joy_2_val <= joy_2_shift(0);

    process(all)
    begin

        -- Mimics the behavior of a 4021 shift register
        if joy_strobe = '1'
        then
            joy_1_shift <= unsigned(joy_1_cur);
        elsif rising_edge(shift_joy_1)
        then
            joy_1_shift <= shift_right(joy_1_shift, 1) or x"80";
        end if;

        if joy_strobe = '1'
        then
            joy_2_shift <= unsigned(joy_2_cur);
        elsif rising_edge(shift_joy_2)
        then
            joy_2_shift <= shift_right(joy_2_shift, 1) or x"80";
        end if;

    end process;

    read_fm2_proc : if FILEPATH'length > 0
    generate

        process
            file fm2_file : text;

            -- If INPUT_OFFSET is positive then the PPU is ahead of the input
            -- file, so the input file needs to catch up
            -- If INPUT_OFFSET is negative than the input file is ahead of the
            -- PPU, so the PPU needs to catch up
            --
            -- Examples:
            -- INPUT_OFFSET = +2
            -- input_frame = 0, ppu_frame = 2
            -- Skip first two inputs to synchronize
            --
            -- INPUT_OFFSET = -2
            -- input_frame = 2, ppu_frame = 0
            -- Skip reads for first two frames to synchronize
            variable input_frame : integer := maximum(-INPUT_OFFSET, 0);
            variable ppu_frame   : integer := maximum(INPUT_OFFSET, 0);

            variable joy_1_next : joy_val_t := (others => '1');
            variable joy_2_next : joy_val_t := (others => '1');
        begin

            fm2_fopen(fm2_file, FILEPATH);

            while input_frame < ppu_frame
            loop
                fm2_fread(fm2_file, joy_1_next, joy_2_next);
                input_frame := input_frame + 1;
            end loop;

            while true
            loop
                if ppu_frame = input_frame
                then
                    fm2_fread(fm2_file, joy_1_next, joy_2_next);

                    joy_1_cur <= joy_1_next;
                    joy_2_cur <= joy_2_next;

                    input_frame := input_frame + 1;
                end if;

                wait on frame_valid until not frame_valid and
                                          frame_valid'last_value;

                ppu_frame := ppu_frame + 1;
            end loop;
        end process;

    end generate;

end behavioral;
