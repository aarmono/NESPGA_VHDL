library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

package ps2 is


    subtype ps2_state_t is std_logic_vector(3 downto 0);

    constant PS2_STATE_T_RESET : ps2_state_t := (others => '0');

    type key_state_t is record
        value   : std_logic_vector(7 downto 0);
        pressed : boolean;
        valid   : boolean;
    end record;

    constant KEY_STATE_T_RESET : key_state_t :=
    (
        value   => (others => '0'),
        pressed => false,
        valid   => false
    );

    type ps2_out_t is record
        state       : ps2_state_t;
        key         : key_state_t;
    end record;

    constant PS2_OUT_T_RESET : ps2_out_t :=
    (
        state => PS2_STATE_T_RESET,
        key   => KEY_STATE_T_RESET
    );

    function ps2_parser(cur_state : ps2_state_t;
                        key       : std_logic_vector(7 downto 0))
             return ps2_out_t;

    type keyboard_state_t is record
        caps_lock   : boolean;
        shift       : boolean;
        scroll_lock : boolean;
        num_lock    : boolean;
    end record;

    constant KEYBOARD_STATE_T_RESET : keyboard_state_t :=
    (
        caps_lock   => false,
        shift       => false,
        scroll_lock => false,
        num_lock    => false
    );

    type keyboard_out_t is record
        state       : keyboard_state_t;
        key         : key_state_t;
    end record;

    constant KEYBOARD_OUT_T_RESET : keyboard_out_t :=
    (
        state => KEYBOARD_STATE_T_RESET,
        key   => KEY_STATE_T_RESET
    );

    function next_keyboard_state
    (
        state : keyboard_state_t;
        key   : key_state_t
    )
    return keyboard_out_t;

end ps2;

package body ps2 is

    function ps2_parser(cur_state : ps2_state_t;
                        key       : std_logic_vector(7 downto 0))
             return ps2_out_t
    is
        constant START : std_logic_vector(3 downto 0) := "0000";
        constant F0 : ps2_state_t := "0001";
        constant E0F07CE0F0 : ps2_state_t := "0010";
        constant E012E0 : ps2_state_t := "0011";
        constant E0F0 : ps2_state_t := "0100";
        constant E11477E1 : ps2_state_t := "0101";
        constant E11477 : ps2_state_t := "0110";
        constant E11477E1F0 : ps2_state_t := "0111";
        constant E0F07CE0 : ps2_state_t := "1000";
        constant E012 : ps2_state_t := "1001";
        constant E11477E1F014 : ps2_state_t := "1010";
        constant E11477E1F014F0 : ps2_state_t := "1011";
        constant E0F07C : ps2_state_t := "1100";
        constant E1 : ps2_state_t := "1101";
        constant E0 : ps2_state_t := "1110";
        constant E114 : ps2_state_t := "1111";

        subtype in_state_t is std_logic_vector(11 downto 0);
        constant F0_07 : in_state_t := F0 & x"07";
        constant F0_09 : in_state_t := F0 & x"09";
        constant F0_77 : in_state_t := F0 & x"77";
        constant F0_0D : in_state_t := F0 & x"0D";
        constant F0_76 : in_state_t := F0 & x"76";
        constant F0_6C : in_state_t := F0 & x"6C";
        constant F0_0E : in_state_t := F0 & x"0E";
        constant F0_70 : in_state_t := F0 & x"70";
        constant F0_29 : in_state_t := F0 & x"29";
        constant F0_1A : in_state_t := F0 & x"1A";
        constant F0_1C : in_state_t := F0 & x"1C";
        constant F0_1B : in_state_t := F0 & x"1B";
        constant F0_1E : in_state_t := F0 & x"1E";
        constant F0_1D : in_state_t := F0 & x"1D";
        constant F0_66 : in_state_t := F0 & x"66";
        constant F0_5D : in_state_t := F0 & x"5D";
        constant F0_3C : in_state_t := F0 & x"3C";
        constant F0_3B : in_state_t := F0 & x"3B";
        constant F0_3A : in_state_t := F0 & x"3A";
        constant F0_7C : in_state_t := F0 & x"7C";
        constant F0_5A : in_state_t := F0 & x"5A";
        constant F0_3E : in_state_t := F0 & x"3E";
        constant F0_3D : in_state_t := F0 & x"3D";
        constant F0_24 : in_state_t := F0 & x"24";
        constant F0_25 : in_state_t := F0 & x"25";
        constant F0_26 : in_state_t := F0 & x"26";
        constant F0_01 : in_state_t := F0 & x"01";
        constant F0_06 : in_state_t := F0 & x"06";
        constant F0_21 : in_state_t := F0 & x"21";
        constant F0_22 : in_state_t := F0 & x"22";
        constant F0_23 : in_state_t := F0 & x"23";
        constant F0_46 : in_state_t := F0 & x"46";
        constant F0_44 : in_state_t := F0 & x"44";
        constant F0_45 : in_state_t := F0 & x"45";
        constant F0_42 : in_state_t := F0 & x"42";
        constant F0_43 : in_state_t := F0 & x"43";
        constant F0_41 : in_state_t := F0 & x"41";
        constant F0_74 : in_state_t := F0 & x"74";
        constant F0_71 : in_state_t := F0 & x"71";
        constant F0_4A : in_state_t := F0 & x"4A";
        constant F0_78 : in_state_t := F0 & x"78";
        constant F0_7D : in_state_t := F0 & x"7D";
        constant F0_7A : in_state_t := F0 & x"7A";
        constant F0_49 : in_state_t := F0 & x"49";
        constant F0_03 : in_state_t := F0 & x"03";
        constant F0_83 : in_state_t := F0 & x"83";
        constant F0_7E : in_state_t := F0 & x"7E";
        constant F0_2D : in_state_t := F0 & x"2D";
        constant F0_2E : in_state_t := F0 & x"2E";
        constant F0_75 : in_state_t := F0 & x"75";
        constant F0_0A : in_state_t := F0 & x"0A";
        constant F0_04 : in_state_t := F0 & x"04";
        constant F0_2A : in_state_t := F0 & x"2A";
        constant F0_2B : in_state_t := F0 & x"2B";
        constant F0_2C : in_state_t := F0 & x"2C";
        constant F0_5B : in_state_t := F0 & x"5B";
        constant F0_59 : in_state_t := F0 & x"59";
        constant F0_4D : in_state_t := F0 & x"4D";
        constant F0_4E : in_state_t := F0 & x"4E";
        constant F0_4B : in_state_t := F0 & x"4B";
        constant F0_4C : in_state_t := F0 & x"4C";
        constant F0_79 : in_state_t := F0 & x"79";
        constant F0_14 : in_state_t := F0 & x"14";
        constant F0_11 : in_state_t := F0 & x"11";
        constant F0_0B : in_state_t := F0 & x"0B";
        constant F0_6B : in_state_t := F0 & x"6B";
        constant F0_12 : in_state_t := F0 & x"12";
        constant F0_15 : in_state_t := F0 & x"15";
        constant F0_58 : in_state_t := F0 & x"58";
        constant F0_16 : in_state_t := F0 & x"16";
        constant F0_33 : in_state_t := F0 & x"33";
        constant F0_32 : in_state_t := F0 & x"32";
        constant F0_31 : in_state_t := F0 & x"31";
        constant F0_05 : in_state_t := F0 & x"05";
        constant F0_36 : in_state_t := F0 & x"36";
        constant F0_35 : in_state_t := F0 & x"35";
        constant F0_34 : in_state_t := F0 & x"34";
        constant F0_55 : in_state_t := F0 & x"55";
        constant F0_69 : in_state_t := F0 & x"69";
        constant F0_52 : in_state_t := F0 & x"52";
        constant F0_0C : in_state_t := F0 & x"0C";
        constant F0_7B : in_state_t := F0 & x"7B";
        constant F0_73 : in_state_t := F0 & x"73";
        constant F0_54 : in_state_t := F0 & x"54";
        constant F0_72 : in_state_t := F0 & x"72";
        constant E0F07CE0F0_12 : in_state_t := E0F07CE0F0 & x"12";
        constant E012E0_7C : in_state_t := E012E0 & x"7C";
        constant E0F0_11 : in_state_t := E0F0 & x"11";
        constant E0F0_6B : in_state_t := E0F0 & x"6B";
        constant E0F0_27 : in_state_t := E0F0 & x"27";
        constant E0F0_7C : in_state_t := E0F0 & x"7C";
        constant E0F0_14 : in_state_t := E0F0 & x"14";
        constant E0F0_7A : in_state_t := E0F0 & x"7A";
        constant E0F0_70 : in_state_t := E0F0 & x"70";
        constant E0F0_75 : in_state_t := E0F0 & x"75";
        constant E0F0_2F : in_state_t := E0F0 & x"2F";
        constant E0F0_6C : in_state_t := E0F0 & x"6C";
        constant E0F0_72 : in_state_t := E0F0 & x"72";
        constant E0F0_71 : in_state_t := E0F0 & x"71";
        constant E0F0_1F : in_state_t := E0F0 & x"1F";
        constant E0F0_69 : in_state_t := E0F0 & x"69";
        constant E0F0_5A : in_state_t := E0F0 & x"5A";
        constant E0F0_7D : in_state_t := E0F0 & x"7D";
        constant E0F0_74 : in_state_t := E0F0 & x"74";
        constant E0F0_4A : in_state_t := E0F0 & x"4A";
        constant E11477E1_F0 : in_state_t := E11477E1 & x"F0";
        constant E11477_E1 : in_state_t := E11477 & x"E1";
        constant E11477E1F0_14 : in_state_t := E11477E1F0 & x"14";
        constant E0F07CE0_F0 : in_state_t := E0F07CE0 & x"F0";
        constant START_5D : in_state_t := START & x"5D";
        constant START_5A : in_state_t := START & x"5A";
        constant START_5B : in_state_t := START & x"5B";
        constant START_24 : in_state_t := START & x"24";
        constant START_25 : in_state_t := START & x"25";
        constant START_26 : in_state_t := START & x"26";
        constant START_21 : in_state_t := START & x"21";
        constant START_22 : in_state_t := START & x"22";
        constant START_23 : in_state_t := START & x"23";
        constant START_29 : in_state_t := START & x"29";
        constant START_4 : in_state_t := START & x"04";
        constant START_F0 : in_state_t := START & x"F0";
        constant START_2D : in_state_t := START & x"2D";
        constant START_2E : in_state_t := START & x"2E";
        constant START_12 : in_state_t := START & x"12";
        constant START_2A : in_state_t := START & x"2A";
        constant START_2B : in_state_t := START & x"2B";
        constant START_2C : in_state_t := START & x"2C";
        constant START_59 : in_state_t := START & x"59";
        constant START_58 : in_state_t := START & x"58";
        constant START_55 : in_state_t := START & x"55";
        constant START_54 : in_state_t := START & x"54";
        constant START_52 : in_state_t := START & x"52";
        constant START_3C : in_state_t := START & x"3C";
        constant START_3B : in_state_t := START & x"3B";
        constant START_3A : in_state_t := START & x"3A";
        constant START_3E : in_state_t := START & x"3E";
        constant START_3D : in_state_t := START & x"3D";
        constant START_3 : in_state_t := START & x"03";
        constant START_7 : in_state_t := START & x"07";
        constant START_E1 : in_state_t := START & x"E1";
        constant START_E0 : in_state_t := START & x"E0";
        constant START_0B : in_state_t := START & x"0B";
        constant START_0C : in_state_t := START & x"0C";
        constant START_0A : in_state_t := START & x"0A";
        constant START_0D : in_state_t := START & x"0D";
        constant START_0E : in_state_t := START & x"0E";
        constant START_33 : in_state_t := START & x"33";
        constant START_32 : in_state_t := START & x"32";
        constant START_31 : in_state_t := START & x"31";
        constant START_36 : in_state_t := START & x"36";
        constant START_35 : in_state_t := START & x"35";
        constant START_34 : in_state_t := START & x"34";
        constant START_1A : in_state_t := START & x"1A";
        constant START_1C : in_state_t := START & x"1C";
        constant START_1B : in_state_t := START & x"1B";
        constant START_1E : in_state_t := START & x"1E";
        constant START_1D : in_state_t := START & x"1D";
        constant START_66 : in_state_t := START & x"66";
        constant START_69 : in_state_t := START & x"69";
        constant START_6 : in_state_t := START & x"06";
        constant START_4A : in_state_t := START & x"4A";
        constant START_11 : in_state_t := START & x"11";
        constant START_6B : in_state_t := START & x"6B";
        constant START_6C : in_state_t := START & x"6C";
        constant START_15 : in_state_t := START & x"15";
        constant START_14 : in_state_t := START & x"14";
        constant START_16 : in_state_t := START & x"16";
        constant START_83 : in_state_t := START & x"83";
        constant START_7E : in_state_t := START & x"7E";
        constant START_7D : in_state_t := START & x"7D";
        constant START_7C : in_state_t := START & x"7C";
        constant START_7B : in_state_t := START & x"7B";
        constant START_7A : in_state_t := START & x"7A";
        constant START_49 : in_state_t := START & x"49";
        constant START_46 : in_state_t := START & x"46";
        constant START_44 : in_state_t := START & x"44";
        constant START_45 : in_state_t := START & x"45";
        constant START_42 : in_state_t := START & x"42";
        constant START_43 : in_state_t := START & x"43";
        constant START_41 : in_state_t := START & x"41";
        constant START_1 : in_state_t := START & x"01";
        constant START_5 : in_state_t := START & x"05";
        constant START_9 : in_state_t := START & x"09";
        constant START_77 : in_state_t := START & x"77";
        constant START_76 : in_state_t := START & x"76";
        constant START_75 : in_state_t := START & x"75";
        constant START_74 : in_state_t := START & x"74";
        constant START_73 : in_state_t := START & x"73";
        constant START_72 : in_state_t := START & x"72";
        constant START_71 : in_state_t := START & x"71";
        constant START_70 : in_state_t := START & x"70";
        constant START_4D : in_state_t := START & x"4D";
        constant START_4E : in_state_t := START & x"4E";
        constant START_4B : in_state_t := START & x"4B";
        constant START_4C : in_state_t := START & x"4C";
        constant START_79 : in_state_t := START & x"79";
        constant START_78 : in_state_t := START & x"78";
        constant E012_E0 : in_state_t := E012 & x"E0";
        constant E11477E1F014_F0 : in_state_t := E11477E1F014 & x"F0";
        constant E11477E1F014F0_77 : in_state_t := E11477E1F014F0 & x"77";
        constant E0F07C_E0 : in_state_t := E0F07C & x"E0";
        constant E1_14 : in_state_t := E1 & x"14";
        constant E0_F0 : in_state_t := E0 & x"F0";
        constant E0_11 : in_state_t := E0 & x"11";
        constant E0_6B : in_state_t := E0 & x"6B";
        constant E0_27 : in_state_t := E0 & x"27";
        constant E0_14 : in_state_t := E0 & x"14";
        constant E0_7A : in_state_t := E0 & x"7A";
        constant E0_6C : in_state_t := E0 & x"6C";
        constant E0_70 : in_state_t := E0 & x"70";
        constant E0_75 : in_state_t := E0 & x"75";
        constant E0_2F : in_state_t := E0 & x"2F";
        constant E0_12 : in_state_t := E0 & x"12";
        constant E0_72 : in_state_t := E0 & x"72";
        constant E0_71 : in_state_t := E0 & x"71";
        constant E0_1F : in_state_t := E0 & x"1F";
        constant E0_69 : in_state_t := E0 & x"69";
        constant E0_5A : in_state_t := E0 & x"5A";
        constant E0_7D : in_state_t := E0 & x"7D";
        constant E0_74 : in_state_t := E0 & x"74";
        constant E0_4A : in_state_t := E0 & x"4A";
        constant E114_77 : in_state_t := E114 & x"77";

        variable in_val : in_state_t;
        variable ret    : ps2_out_t;
    begin
        in_val := cur_state & key;
        ret.state := cur_state;
        ret.key.value := (others => '-');
        ret.key.pressed := false;
        ret.key.valid := false;

        case in_val is
            when F0_07 =>
                ret.key.value := "10010101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_09 =>
                ret.key.value := "10010011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_77 =>
                ret.key.value := "10100010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_0D =>
                ret.key.value := "00001001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_76 =>
                ret.key.value := "00011011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_6C =>
                ret.key.value := "10110111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_0E =>
                ret.key.value := "01100000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_70 =>
                ret.key.value := "10110000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_29 =>
                ret.key.value := "00100000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_1A =>
                ret.key.value := "01111010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_1C =>
                ret.key.value := "01100001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_1B =>
                ret.key.value := "01110011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_1E =>
                ret.key.value := "00110010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_1D =>
                ret.key.value := "01110111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_66 =>
                ret.key.value := "00001000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_5D =>
                ret.key.value := "01011100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_3C =>
                ret.key.value := "01110101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_3B =>
                ret.key.value := "01101010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_3A =>
                ret.key.value := "01101101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_7C =>
                ret.key.value := "00101010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_5A =>
                ret.key.value := "00001010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_3E =>
                ret.key.value := "00111000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_3D =>
                ret.key.value := "00110111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_24 =>
                ret.key.value := "01100101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_25 =>
                ret.key.value := "00110100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_26 =>
                ret.key.value := "00110011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_01 =>
                ret.key.value := "10010010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_06 =>
                ret.key.value := "10001011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_21 =>
                ret.key.value := "01100011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_22 =>
                ret.key.value := "01111000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_23 =>
                ret.key.value := "01100100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_46 =>
                ret.key.value := "00111001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_44 =>
                ret.key.value := "01101111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_45 =>
                ret.key.value := "00110000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_42 =>
                ret.key.value := "01101011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_43 =>
                ret.key.value := "01001001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_41 =>
                ret.key.value := "00101100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_74 =>
                ret.key.value := "10110110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_71 =>
                ret.key.value := "10101110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_4A =>
                ret.key.value := "00101111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_78 =>
                ret.key.value := "10010100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_7D =>
                ret.key.value := "10111001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_7A =>
                ret.key.value := "10110011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_49 =>
                ret.key.value := "00101110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_03 =>
                ret.key.value := "10001110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_83 =>
                ret.key.value := "10010000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_7E =>
                ret.key.value := "10010111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_2D =>
                ret.key.value := "01110010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_2E =>
                ret.key.value := "00110101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_75 =>
                ret.key.value := "10111000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_0A =>
                ret.key.value := "10010001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_04 =>
                ret.key.value := "10001100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_2A =>
                ret.key.value := "01110110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_2B =>
                ret.key.value := "01100110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_2C =>
                ret.key.value := "01110100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_5B =>
                ret.key.value := "01011101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_59 =>
                ret.key.value := "10000001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_4D =>
                ret.key.value := "01110000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_4E =>
                ret.key.value := "10101101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_4B =>
                ret.key.value := "01101100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_4C =>
                ret.key.value := "00111011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_79 =>
                ret.key.value := "00101011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_14 =>
                ret.key.value := "10000010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_11 =>
                ret.key.value := "10000100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_0B =>
                ret.key.value := "10001111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_6B =>
                ret.key.value := "10110100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_12 =>
                ret.key.value := "10000001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_15 =>
                ret.key.value := "01110001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_58 =>
                ret.key.value := "10000000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_16 =>
                ret.key.value := "00110001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_33 =>
                ret.key.value := "01101000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_32 =>
                ret.key.value := "01100010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_31 =>
                ret.key.value := "01101110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_05 =>
                ret.key.value := "10001010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_36 =>
                ret.key.value := "00110110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_35 =>
                ret.key.value := "01111001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_34 =>
                ret.key.value := "01100111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_55 =>
                ret.key.value := "00111101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_69 =>
                ret.key.value := "10110001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_52 =>
                ret.key.value := "00100111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_0C =>
                ret.key.value := "10001101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_7B =>
                ret.key.value := "00101101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_73 =>
                ret.key.value := "10110101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_54 =>
                ret.key.value := "01011011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when F0_72 =>
                ret.key.value := "10110010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F07CE0F0_12 =>
                ret.key.value := "10010110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E012E0_7C =>
                ret.key.value := "10010110";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0F0_11 =>
                ret.key.value := "10001000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_6B =>
                ret.key.value := "10011111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_27 =>
                ret.key.value := "10000111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_7C =>
                ret.state := E0F07C;
            when E0F0_14 =>
                ret.key.value := "10000110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_7A =>
                ret.key.value := "10011101";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_70 =>
                ret.key.value := "10011001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_75 =>
                ret.key.value := "10011110";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_2F =>
                ret.key.value := "10001001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_6C =>
                ret.key.value := "10011010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_72 =>
                ret.key.value := "10100000";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_71 =>
                ret.key.value := "01111111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_1F =>
                ret.key.value := "10000011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_69 =>
                ret.key.value := "10011100";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_5A =>
                ret.key.value := "00001010";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_7D =>
                ret.key.value := "10011011";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_74 =>
                ret.key.value := "10100001";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E0F0_4A =>
                ret.key.value := "10101111";
                ret.key.valid := true;
                ret.key.pressed := False;
                ret.state := START;
            when E11477E1_F0 =>
                ret.state := E11477E1F0;
            when E11477_E1 =>
                ret.state := E11477E1;
            when E11477E1F0_14 =>
                ret.state := E11477E1F014;
            when E0F07CE0_F0 =>
                ret.state := E0F07CE0F0;
            when START_5D =>
                ret.key.value := "01011100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_5A =>
                ret.key.value := "00001010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_5B =>
                ret.key.value := "01011101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_24 =>
                ret.key.value := "01100101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_25 =>
                ret.key.value := "00110100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_26 =>
                ret.key.value := "00110011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_21 =>
                ret.key.value := "01100011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_22 =>
                ret.key.value := "01111000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_23 =>
                ret.key.value := "01100100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_29 =>
                ret.key.value := "00100000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_4 =>
                ret.key.value := "10001100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_F0 =>
                ret.state := F0;
            when START_2D =>
                ret.key.value := "01110010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_2E =>
                ret.key.value := "00110101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_12 =>
                ret.key.value := "10000001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_2A =>
                ret.key.value := "01110110";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_2B =>
                ret.key.value := "01100110";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_2C =>
                ret.key.value := "01110100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_59 =>
                ret.key.value := "10000001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_58 =>
                ret.key.value := "10000000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_55 =>
                ret.key.value := "00111101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_54 =>
                ret.key.value := "01011011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_52 =>
                ret.key.value := "00100111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_3C =>
                ret.key.value := "01110101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_3B =>
                ret.key.value := "01101010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_3A =>
                ret.key.value := "01101101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_3E =>
                ret.key.value := "00111000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_3D =>
                ret.key.value := "00110111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_3 =>
                ret.key.value := "10001110";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_7 =>
                ret.key.value := "10010101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_E1 =>
                ret.state := E1;
            when START_E0 =>
                ret.state := E0;
            when START_0B =>
                ret.key.value := "10001111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_0C =>
                ret.key.value := "10001101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_0A =>
                ret.key.value := "10010001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_0D =>
                ret.key.value := "00001001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_0E =>
                ret.key.value := "01100000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_33 =>
                ret.key.value := "01101000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_32 =>
                ret.key.value := "01100010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_31 =>
                ret.key.value := "01101110";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_36 =>
                ret.key.value := "00110110";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_35 =>
                ret.key.value := "01111001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_34 =>
                ret.key.value := "01100111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_1A =>
                ret.key.value := "01111010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_1C =>
                ret.key.value := "01100001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_1B =>
                ret.key.value := "01110011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_1E =>
                ret.key.value := "00110010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_1D =>
                ret.key.value := "01110111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_66 =>
                ret.key.value := "00001000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_69 =>
                ret.key.value := "10110001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_6 =>
                ret.key.value := "10001011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_4A =>
                ret.key.value := "00101111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_11 =>
                ret.key.value := "10000100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_6B =>
                ret.key.value := "10110100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_6C =>
                ret.key.value := "10110111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_15 =>
                ret.key.value := "01110001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_14 =>
                ret.key.value := "10000010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_16 =>
                ret.key.value := "00110001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_83 =>
                ret.key.value := "10010000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_7E =>
                ret.key.value := "10010111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_7D =>
                ret.key.value := "10111001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_7C =>
                ret.key.value := "00101010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_7B =>
                ret.key.value := "00101101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_7A =>
                ret.key.value := "10110011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_49 =>
                ret.key.value := "00101110";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_46 =>
                ret.key.value := "00111001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_44 =>
                ret.key.value := "01101111";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_45 =>
                ret.key.value := "00110000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_42 =>
                ret.key.value := "01101011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_43 =>
                ret.key.value := "01001001";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_41 =>
                ret.key.value := "00101100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_1 =>
                ret.key.value := "10010010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_5 =>
                ret.key.value := "10001010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_9 =>
                ret.key.value := "10010011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_77 =>
                ret.key.value := "10100010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_76 =>
                ret.key.value := "00011011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_75 =>
                ret.key.value := "10111000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_74 =>
                ret.key.value := "10110110";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_73 =>
                ret.key.value := "10110101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_72 =>
                ret.key.value := "10110010";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_71 =>
                ret.key.value := "10101110";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_70 =>
                ret.key.value := "10110000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_4D =>
                ret.key.value := "01110000";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_4E =>
                ret.key.value := "10101101";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_4B =>
                ret.key.value := "01101100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_4C =>
                ret.key.value := "00111011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_79 =>
                ret.key.value := "00101011";
                ret.key.valid := true;
                ret.key.pressed := True;
            when START_78 =>
                ret.key.value := "10010100";
                ret.key.valid := true;
                ret.key.pressed := True;
            when E012_E0 =>
                ret.state := E012E0;
            when E11477E1F014_F0 =>
                ret.state := E11477E1F014F0;
            when E11477E1F014F0_77 =>
                ret.key.value := "10011000";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0F07C_E0 =>
                ret.state := E0F07CE0;
            when E1_14 =>
                ret.state := E114;
            when E0_F0 =>
                ret.state := E0F0;
            when E0_11 =>
                ret.key.value := "10001000";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_6B =>
                ret.key.value := "10011111";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_27 =>
                ret.key.value := "10000111";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_14 =>
                ret.key.value := "10000110";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_7A =>
                ret.key.value := "10011101";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_6C =>
                ret.key.value := "10011010";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_70 =>
                ret.key.value := "10011001";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_75 =>
                ret.key.value := "10011110";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_2F =>
                ret.key.value := "10001001";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_12 =>
                ret.state := E012;
            when E0_72 =>
                ret.key.value := "10100000";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_71 =>
                ret.key.value := "01111111";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_1F =>
                ret.key.value := "10000011";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_69 =>
                ret.key.value := "10011100";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_5A =>
                ret.key.value := "00001010";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_7D =>
                ret.key.value := "10011011";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_74 =>
                ret.key.value := "10100001";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E0_4A =>
                ret.key.value := "10101111";
                ret.key.valid := true;
                ret.key.pressed := True;
                ret.state := START;
            when E114_77 =>
                ret.state := E11477;
            when others =>
                ret.state := START;
        end case;

        return ret;

    end function;

    function next_keyboard_state
    (
        state : keyboard_state_t;
        key   : key_state_t
    )
    return keyboard_out_t
    is
        variable case_in    : std_logic_vector(9 downto 0);
        variable ret        : keyboard_out_t;
        variable upper_case : boolean;
    begin
        ret.state := state;
        ret.key.value := (others => '-');
        ret.key.valid := false;
        ret.key.pressed := false;

        upper_case := state.caps_lock or state.shift;

        assert key.valid report "Invalid Key input";

        case_in := to_std_logic(upper_case) &
                   to_std_logic(state.num_lock) &
                   key.value;

        case case_in is

            -- 1, default
            when "0000110001" =>
                ret.key.value := "00110001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 1, CAPS
            when "1000110001" =>
                ret.key.value := "00100001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 1, NUM
            when "0100110001" =>
                ret.key.value := "00110001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 1, both
            when "1100110001" =>
                ret.key.value := "00100001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x20, default
            when "0000100000" =>
                ret.key.value := "00100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x20, CAPS
            when "1000100000" =>
                ret.key.value := "00100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x20, NUM
            when "0100100000" =>
                ret.key.value := "00100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x20, both
            when "1100100000" =>
                ret.key.value := "00100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- ,, default
            when "0000101100" =>
                ret.key.value := "00101100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ,, CAPS
            when "1000101100" =>
                ret.key.value := "00111100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ,, NUM
            when "0100101100" =>
                ret.key.value := "00101100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ,, both
            when "1100101100" =>
                ret.key.value := "00111100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0, default
            when "0000110000" =>
                ret.key.value := "00110000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0, CAPS
            when "1000110000" =>
                ret.key.value := "00101001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0, NUM
            when "0100110000" =>
                ret.key.value := "00110000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0, both
            when "1100110000" =>
                ret.key.value := "00101001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 4, default
            when "0000110100" =>
                ret.key.value := "00110100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 4, CAPS
            when "1000110100" =>
                ret.key.value := "00100100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 4, NUM
            when "0100110100" =>
                ret.key.value := "00110100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 4, both
            when "1100110100" =>
                ret.key.value := "00100100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 5, default
            when "0000110101" =>
                ret.key.value := "00110101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 5, CAPS
            when "1000110101" =>
                ret.key.value := "00100101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 5, NUM
            when "0100110101" =>
                ret.key.value := "00110101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 5, both
            when "1100110101" =>
                ret.key.value := "00100101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- \, default
            when "0001011100" =>
                ret.key.value := "01011100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- \, CAPS
            when "1001011100" =>
                ret.key.value := "01111100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- \, NUM
            when "0101011100" =>
                ret.key.value := "01011100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- \, both
            when "1101011100" =>
                ret.key.value := "01111100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- `, default
            when "0001100000" =>
                ret.key.value := "01100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- `, CAPS
            when "1001100000" =>
                ret.key.value := "01111110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- `, NUM
            when "0101100000" =>
                ret.key.value := "01100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- `, both
            when "1101100000" =>
                ret.key.value := "01111110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- d, default
            when "0001100100" =>
                ret.key.value := "01100100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- d, CAPS
            when "1001100100" =>
                ret.key.value := "01000100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- d, NUM
            when "0101100100" =>
                ret.key.value := "01100100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- d, both
            when "1101100100" =>
                ret.key.value := "01000100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x88, default
            when "0010001000" =>
                ret.key.value := "10001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x88, CAPS
            when "1010001000" =>
                ret.key.value := "10001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x88, NUM
            when "0110001000" =>
                ret.key.value := "10001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x88, both
            when "1110001000" =>
                ret.key.value := "10001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- l, default
            when "0001101100" =>
                ret.key.value := "01101100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- l, CAPS
            when "1001101100" =>
                ret.key.value := "01001100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- l, NUM
            when "0101101100" =>
                ret.key.value := "01101100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- l, both
            when "1101101100" =>
                ret.key.value := "01001100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- p, default
            when "0001110000" =>
                ret.key.value := "01110000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- p, CAPS
            when "1001110000" =>
                ret.key.value := "01010000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- p, NUM
            when "0101110000" =>
                ret.key.value := "01110000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- p, both
            when "1101110000" =>
                ret.key.value := "01010000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- t, default
            when "0001110100" =>
                ret.key.value := "01110100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- t, CAPS
            when "1001110100" =>
                ret.key.value := "01010100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- t, NUM
            when "0101110100" =>
                ret.key.value := "01110100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- t, both
            when "1101110100" =>
                ret.key.value := "01010100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- h, default
            when "0001101000" =>
                ret.key.value := "01101000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- h, CAPS
            when "1001101000" =>
                ret.key.value := "01001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- h, NUM
            when "0101101000" =>
                ret.key.value := "01101000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- h, both
            when "1101101000" =>
                ret.key.value := "01001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- x, default
            when "0001111000" =>
                ret.key.value := "01111000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- x, CAPS
            when "1001111000" =>
                ret.key.value := "01011000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- x, NUM
            when "0101111000" =>
                ret.key.value := "01111000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- x, both
            when "1101111000" =>
                ret.key.value := "01011000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- j, default
            when "0001101010" =>
                ret.key.value := "01101010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- j, CAPS
            when "1001101010" =>
                ret.key.value := "01001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- j, NUM
            when "0101101010" =>
                ret.key.value := "01101010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- j, both
            when "1101101010" =>
                ret.key.value := "01001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- ', default
            when "0000100111" =>
                ret.key.value := "00100111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ', CAPS
            when "1000100111" =>
                ret.key.value := "00100010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ', NUM
            when "0100100111" =>
                ret.key.value := "00100111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ', both
            when "1100100111" =>
                ret.key.value := "00100010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- +, default
            when "0000101011" =>
                ret.key.value := "00101011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- +, CAPS
            when "1000101011" =>
                ret.key.value := "00101011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- +, NUM
            when "0100101011" =>
                ret.key.value := "00101011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- +, both
            when "1100101011" =>
                ret.key.value := "00101011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- /, default
            when "0000101111" =>
                ret.key.value := "00101111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- /, CAPS
            when "1000101111" =>
                ret.key.value := "00111111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- /, NUM
            when "0100101111" =>
                ret.key.value := "00101111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- /, both
            when "1100101111" =>
                ret.key.value := "00111111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 3, default
            when "0000110011" =>
                ret.key.value := "00110011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 3, CAPS
            when "1000110011" =>
                ret.key.value := "00100011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 3, NUM
            when "0100110011" =>
                ret.key.value := "00110011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 3, both
            when "1100110011" =>
                ret.key.value := "00100011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 7, default
            when "0000110111" =>
                ret.key.value := "00110111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 7, CAPS
            when "1000110111" =>
                ret.key.value := "00100110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 7, NUM
            when "0100110111" =>
                ret.key.value := "00110111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 7, both
            when "1100110111" =>
                ret.key.value := "00100110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- ;, default
            when "0000111011" =>
                ret.key.value := "00111011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ;, CAPS
            when "1000111011" =>
                ret.key.value := "00111010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ;, NUM
            when "0100111011" =>
                ret.key.value := "00111011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ;, both
            when "1100111011" =>
                ret.key.value := "00111010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- [, default
            when "0001011011" =>
                ret.key.value := "01011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- [, CAPS
            when "1001011011" =>
                ret.key.value := "01111011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- [, NUM
            when "0101011011" =>
                ret.key.value := "01011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- [, both
            when "1101011011" =>
                ret.key.value := "01111011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- c, default
            when "0001100011" =>
                ret.key.value := "01100011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- c, CAPS
            when "1001100011" =>
                ret.key.value := "01000011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- c, NUM
            when "0101100011" =>
                ret.key.value := "01100011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- c, both
            when "1101100011" =>
                ret.key.value := "01000011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- g, default
            when "0001100111" =>
                ret.key.value := "01100111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- g, CAPS
            when "1001100111" =>
                ret.key.value := "01000111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- g, NUM
            when "0101100111" =>
                ret.key.value := "01100111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- g, both
            when "1101100111" =>
                ret.key.value := "01000111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- k, default
            when "0001101011" =>
                ret.key.value := "01101011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- k, CAPS
            when "1001101011" =>
                ret.key.value := "01001011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- k, NUM
            when "0101101011" =>
                ret.key.value := "01101011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- k, both
            when "1101101011" =>
                ret.key.value := "01001011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- o, default
            when "0001101111" =>
                ret.key.value := "01101111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- o, CAPS
            when "1001101111" =>
                ret.key.value := "01001111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- o, NUM
            when "0101101111" =>
                ret.key.value := "01101111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- o, both
            when "1101101111" =>
                ret.key.value := "01001111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- s, default
            when "0001110011" =>
                ret.key.value := "01110011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- s, CAPS
            when "1001110011" =>
                ret.key.value := "01010011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- s, NUM
            when "0101110011" =>
                ret.key.value := "01110011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- s, both
            when "1101110011" =>
                ret.key.value := "01010011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- w, default
            when "0001110111" =>
                ret.key.value := "01110111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- w, CAPS
            when "1001110111" =>
                ret.key.value := "01010111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- w, NUM
            when "0101110111" =>
                ret.key.value := "01110111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- w, both
            when "1101110111" =>
                ret.key.value := "01010111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- ., default
            when "0000101110" =>
                ret.key.value := "00101110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ., CAPS
            when "1000101110" =>
                ret.key.value := "00111110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ., NUM
            when "0100101110" =>
                ret.key.value := "00101110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ., both
            when "1100101110" =>
                ret.key.value := "00111110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;


            -- 0xA1, default
            when "0010100001" =>
                ret.key.value := "10100001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xA1, CAPS
            when "1010100001" =>
                ret.key.value := "10100001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xA1, NUM
            when "0110100001" =>
                ret.key.value := "10100001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xA1, both
            when "1110100001" =>
                ret.key.value := "10100001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xA0, default
            when "0010100000" =>
                ret.key.value := "10100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xA0, CAPS
            when "1010100000" =>
                ret.key.value := "10100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xA0, NUM
            when "0110100000" =>
                ret.key.value := "10100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xA0, both
            when "1110100000" =>
                ret.key.value := "10100000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- *, default
            when "0000101010" =>
                ret.key.value := "00101010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- *, CAPS
            when "1000101010" =>
                ret.key.value := "00101010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- *, NUM
            when "0100101010" =>
                ret.key.value := "00101010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- *, both
            when "1100101010" =>
                ret.key.value := "00101010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x7F, default
            when "0001111111" =>
                ret.key.value := "01111111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x7F, CAPS
            when "1001111111" =>
                ret.key.value := "01111111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x7F, NUM
            when "0101111111" =>
                ret.key.value := "01111111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x7F, both
            when "1101111111" =>
                ret.key.value := "01111111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 2, default
            when "0000110010" =>
                ret.key.value := "00110010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 2, CAPS
            when "1000110010" =>
                ret.key.value := "01000000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 2, NUM
            when "0100110010" =>
                ret.key.value := "00110010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 2, both
            when "1100110010" =>
                ret.key.value := "01000000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 6, default
            when "0000110110" =>
                ret.key.value := "00110110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 6, CAPS
            when "1000110110" =>
                ret.key.value := "01011110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 6, NUM
            when "0100110110" =>
                ret.key.value := "00110110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 6, both
            when "1100110110" =>
                ret.key.value := "01011110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB8, default
            when "0010111000" =>
                ret.key.value := "10111000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB8, CAPS
            when "1010111000" =>
                ret.key.value := "10111000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB8, NUM
            when "0110111000" =>
                ret.key.value := "00111000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB8, both
            when "1110111000" =>
                ret.key.value := "00111000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB9, default
            when "0010111001" =>
                ret.key.value := "10111001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB9, CAPS
            when "1010111001" =>
                ret.key.value := "10111001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB9, NUM
            when "0110111001" =>
                ret.key.value := "00111001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB9, both
            when "1110111001" =>
                ret.key.value := "00111001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 8, default
            when "0000111000" =>
                ret.key.value := "00111000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 8, CAPS
            when "1000111000" =>
                ret.key.value := "00101010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 8, NUM
            when "0100111000" =>
                ret.key.value := "00111000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 8, both
            when "1100111000" =>
                ret.key.value := "00101010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB2, default
            when "0010110010" =>
                ret.key.value := "10110010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB2, CAPS
            when "1010110010" =>
                ret.key.value := "10110010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB2, NUM
            when "0110110010" =>
                ret.key.value := "00110010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB2, both
            when "1110110010" =>
                ret.key.value := "00110010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB3, default
            when "0010110011" =>
                ret.key.value := "10110011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB3, CAPS
            when "1010110011" =>
                ret.key.value := "10110011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB3, NUM
            when "0110110011" =>
                ret.key.value := "00110011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB3, both
            when "1110110011" =>
                ret.key.value := "00110011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB0, default
            when "0010110000" =>
                ret.key.value := "10110000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB0, CAPS
            when "1010110000" =>
                ret.key.value := "10110000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB0, NUM
            when "0110110000" =>
                ret.key.value := "00110000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB0, both
            when "1110110000" =>
                ret.key.value := "00110000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB1, default
            when "0010110001" =>
                ret.key.value := "10110001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB1, CAPS
            when "1010110001" =>
                ret.key.value := "10110001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB1, NUM
            when "0110110001" =>
                ret.key.value := "00110001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB1, both
            when "1110110001" =>
                ret.key.value := "00110001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB6, default
            when "0010110110" =>
                ret.key.value := "10110110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB6, CAPS
            when "1010110110" =>
                ret.key.value := "10110110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB6, NUM
            when "0110110110" =>
                ret.key.value := "00110110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB6, both
            when "1110110110" =>
                ret.key.value := "00110110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB7, default
            when "0010110111" =>
                ret.key.value := "10110111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB7, CAPS
            when "1010110111" =>
                ret.key.value := "10110111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB7, NUM
            when "0110110111" =>
                ret.key.value := "00110111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB7, both
            when "1110110111" =>
                ret.key.value := "00110111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB4, default
            when "0010110100" =>
                ret.key.value := "10110100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB4, CAPS
            when "1010110100" =>
                ret.key.value := "10110100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB4, NUM
            when "0110110100" =>
                ret.key.value := "00110100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB4, both
            when "1110110100" =>
                ret.key.value := "00110100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xB5, default
            when "0010110101" =>
            -- 0xB5, CAPS
            when "1010110101" =>
            -- 0xB5, NUM
            when "0110110101" =>
                ret.key.value := "00110101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xB5, both
            when "1110110101" =>
                ret.key.value := "00110101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- b, default
            when "0001100010" =>
                ret.key.value := "01100010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- b, CAPS
            when "1001100010" =>
                ret.key.value := "01000010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- b, NUM
            when "0101100010" =>
                ret.key.value := "01100010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- b, both
            when "1101100010" =>
                ret.key.value := "01000010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- f, default
            when "0001100110" =>
                ret.key.value := "01100110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- f, CAPS
            when "1001100110" =>
                ret.key.value := "01000110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- f, NUM
            when "0101100110" =>
                ret.key.value := "01100110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- f, both
            when "1101100110" =>
                ret.key.value := "01000110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xAF, default
            when "0010101111" =>
                ret.key.value := "00101111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAF, CAPS
            when "1010101111" =>
                ret.key.value := "00101111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAF, NUM
            when "0110101111" =>
                ret.key.value := "00101111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAF, both
            when "1110101111" =>
                ret.key.value := "00101111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xAE, default
            when "0010101110" =>
                ret.key.value := "10101110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAE, CAPS
            when "1010101110" =>
                ret.key.value := "10101110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAE, NUM
            when "0110101110" =>
                ret.key.value := "00101110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAE, both
            when "1110101110" =>
                ret.key.value := "00101110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0xAD, default
            when "0010101101" =>
                ret.key.value := "00101101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAD, CAPS
            when "1010101101" =>
                ret.key.value := "01011111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAD, NUM
            when "0110101101" =>
                ret.key.value := "00101101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0xAD, both
            when "1110101101" =>
                ret.key.value := "01011111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- n, default
            when "0001101110" =>
                ret.key.value := "01101110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- n, CAPS
            when "1001101110" =>
                ret.key.value := "01001110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- n, NUM
            when "0101101110" =>
                ret.key.value := "01101110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- n, both
            when "1101101110" =>
                ret.key.value := "01001110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- r, default
            when "0001110010" =>
                ret.key.value := "01110010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- r, CAPS
            when "1001110010" =>
                ret.key.value := "01010010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- r, NUM
            when "0101110010" =>
                ret.key.value := "01110010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- r, both
            when "1101110010" =>
                ret.key.value := "01010010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- v, default
            when "0001110110" =>
                ret.key.value := "01110110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- v, CAPS
            when "1001110110" =>
                ret.key.value := "01010110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- v, NUM
            when "0101110110" =>
                ret.key.value := "01110110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- v, both
            when "1101110110" =>
                ret.key.value := "01010110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- z, default
            when "0001111010" =>
                ret.key.value := "01111010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- z, CAPS
            when "1001111010" =>
                ret.key.value := "01011010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- z, NUM
            when "0101111010" =>
                ret.key.value := "01111010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- z, both
            when "1101111010" =>
                ret.key.value := "01011010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x9F, default
            when "0010011111" =>
                ret.key.value := "10011111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9F, CAPS
            when "1010011111" =>
                ret.key.value := "10011111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9F, NUM
            when "0110011111" =>
                ret.key.value := "10011111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9F, both
            when "1110011111" =>
                ret.key.value := "10011111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x9E, default
            when "0010011110" =>
                ret.key.value := "10011110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9E, CAPS
            when "1010011110" =>
                ret.key.value := "10011110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9E, NUM
            when "0110011110" =>
                ret.key.value := "10011110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9E, both
            when "1110011110" =>
                ret.key.value := "10011110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x9D, default
            when "0010011101" =>
                ret.key.value := "10011101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9D, CAPS
            when "1010011101" =>
                ret.key.value := "10011101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9D, NUM
            when "0110011101" =>
                ret.key.value := "10011101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9D, both
            when "1110011101" =>
                ret.key.value := "10011101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x9C, default
            when "0010011100" =>
                ret.key.value := "10011100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9C, CAPS
            when "1010011100" =>
                ret.key.value := "10011100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9C, NUM
            when "0110011100" =>
                ret.key.value := "10011100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9C, both
            when "1110011100" =>
                ret.key.value := "10011100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x9B, default
            when "0010011011" =>
                ret.key.value := "10011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9B, CAPS
            when "1010011011" =>
                ret.key.value := "10011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9B, NUM
            when "0110011011" =>
                ret.key.value := "10011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9B, both
            when "1110011011" =>
                ret.key.value := "10011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x9A, default
            when "0010011010" =>
                ret.key.value := "10011010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9A, CAPS
            when "1010011010" =>
                ret.key.value := "10011010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9A, NUM
            when "0110011010" =>
                ret.key.value := "10011010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x9A, both
            when "1110011010" =>
                ret.key.value := "10011010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x1B, default
            when "0000011011" =>
                ret.key.value := "00011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x1B, CAPS
            when "1000011011" =>
                ret.key.value := "00011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x1B, NUM
            when "0100011011" =>
                ret.key.value := "00011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x1B, both
            when "1100011011" =>
                ret.key.value := "00011011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- q, default
            when "0001110001" =>
                ret.key.value := "01110001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- q, CAPS
            when "1001110001" =>
                ret.key.value := "01010001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- q, NUM
            when "0101110001" =>
                ret.key.value := "01110001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- q, both
            when "1101110001" =>
                ret.key.value := "01010001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x08, default
            when "0000001000" =>
                ret.key.value := "00001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x08, CAPS
            when "1000001000" =>
                ret.key.value := "00001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x08, NUM
            when "0100001000" =>
                ret.key.value := "00001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x08, both
            when "1100001000" =>
                ret.key.value := "00001000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x09, default
            when "0000001001" =>
                ret.key.value := "00001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x09, CAPS
            when "1000001001" =>
                ret.key.value := "00001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x09, NUM
            when "0100001001" =>
                ret.key.value := "00001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x09, both
            when "1100001001" =>
                ret.key.value := "00001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- -, default
            when "0000101101" =>
                ret.key.value := "00101101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- -, CAPS
            when "1000101101" =>
                ret.key.value := "00101101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- -, NUM
            when "0100101101" =>
                ret.key.value := "00101101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- -, both
            when "1100101101" =>
                ret.key.value := "00101101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x84, default
            when "0010000100" =>
                ret.key.value := "10000100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x84, CAPS
            when "1010000100" =>
                ret.key.value := "10000100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x84, NUM
            when "0110000100" =>
                ret.key.value := "10000100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x84, both
            when "1110000100" =>
                ret.key.value := "10000100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x86, default
            when "0010000110" =>
                ret.key.value := "10000110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x86, CAPS
            when "1010000110" =>
                ret.key.value := "10000110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x86, NUM
            when "0110000110" =>
                ret.key.value := "10000110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x86, both
            when "1110000110" =>
                ret.key.value := "10000110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x87, default
            when "0010000111" =>
                ret.key.value := "10000111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x87, CAPS
            when "1010000111" =>
                ret.key.value := "10000111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x87, NUM
            when "0110000111" =>
                ret.key.value := "10000111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x87, both
            when "1110000111" =>
                ret.key.value := "10000111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;



            -- 0x82, default
            when "0010000010" =>
                ret.key.value := "10000010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x82, CAPS
            when "1010000010" =>
                ret.key.value := "10000010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x82, NUM
            when "0110000010" =>
                ret.key.value := "10000010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x82, both
            when "1110000010" =>
                ret.key.value := "10000010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x83, default
            when "0010000011" =>
                ret.key.value := "10000011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x83, CAPS
            when "1010000011" =>
                ret.key.value := "10000011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x83, NUM
            when "0110000011" =>
                ret.key.value := "10000011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x83, both
            when "1110000011" =>
                ret.key.value := "10000011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 9, default
            when "0000111001" =>
                ret.key.value := "00111001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 9, CAPS
            when "1000111001" =>
                ret.key.value := "00101000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 9, NUM
            when "0100111001" =>
                ret.key.value := "00111001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 9, both
            when "1100111001" =>
                ret.key.value := "00101000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x93, default
            when "0010010011" =>
                ret.key.value := "10010011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x93, CAPS
            when "1010010011" =>
                ret.key.value := "10010011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x93, NUM
            when "0110010011" =>
                ret.key.value := "10010011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x93, both
            when "1110010011" =>
                ret.key.value := "10010011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- =, default
            when "0000111101" =>
                ret.key.value := "00111101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- =, CAPS
            when "1000111101" =>
                ret.key.value := "00101011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- =, NUM
            when "0100111101" =>
                ret.key.value := "00111101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- =, both
            when "1100111101" =>
                ret.key.value := "00101011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x89, default
            when "0010001001" =>
                ret.key.value := "10001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x89, CAPS
            when "1010001001" =>
                ret.key.value := "10001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x89, NUM
            when "0110001001" =>
                ret.key.value := "10001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x89, both
            when "1110001001" =>
                ret.key.value := "10001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x8D, default
            when "0010001101" =>
                ret.key.value := "10001101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8D, CAPS
            when "1010001101" =>
                ret.key.value := "10001101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8D, NUM
            when "0110001101" =>
                ret.key.value := "10001101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8D, both
            when "1110001101" =>
                ret.key.value := "10001101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x8E, default
            when "0010001110" =>
                ret.key.value := "10001110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8E, CAPS
            when "1010001110" =>
                ret.key.value := "10001110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8E, NUM
            when "0110001110" =>
                ret.key.value := "10001110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8E, both
            when "1110001110" =>
                ret.key.value := "10001110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x8F, default
            when "0010001111" =>
                ret.key.value := "10001111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8F, CAPS
            when "1010001111" =>
                ret.key.value := "10001111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8F, NUM
            when "0110001111" =>
                ret.key.value := "10001111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8F, both
            when "1110001111" =>
                ret.key.value := "10001111";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x8A, default
            when "0010001010" =>
                ret.key.value := "10001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8A, CAPS
            when "1010001010" =>
                ret.key.value := "10001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8A, NUM
            when "0110001010" =>
                ret.key.value := "10001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8A, both
            when "1110001010" =>
                ret.key.value := "10001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x8B, default
            when "0010001011" =>
                ret.key.value := "10001011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8B, CAPS
            when "1010001011" =>
                ret.key.value := "10001011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8B, NUM
            when "0110001011" =>
                ret.key.value := "10001011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8B, both
            when "1110001011" =>
                ret.key.value := "10001011";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x8C, default
            when "0010001100" =>
                ret.key.value := "10001100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8C, CAPS
            when "1010001100" =>
                ret.key.value := "10001100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8C, NUM
            when "0110001100" =>
                ret.key.value := "10001100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x8C, both
            when "1110001100" =>
                ret.key.value := "10001100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- I, default
            when "0001001001" =>
                ret.key.value := "01001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- I, CAPS
            when "1001001001" =>
                ret.key.value := "01001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- I, NUM
            when "0101001001" =>
                ret.key.value := "01001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- I, both
            when "1101001001" =>
                ret.key.value := "01001001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- ], default
            when "0001011101" =>
                ret.key.value := "01011101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ], CAPS
            when "1001011101" =>
                ret.key.value := "01111101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ], NUM
            when "0101011101" =>
                ret.key.value := "01011101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- ], both
            when "1101011101" =>
                ret.key.value := "01111101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x0A, default
            when "0000001010" =>
                ret.key.value := "00001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x0A, CAPS
            when "1000001010" =>
                ret.key.value := "00001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x0A, NUM
            when "0100001010" =>
                ret.key.value := "00001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x0A, both
            when "1100001010" =>
                ret.key.value := "00001010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- a, default
            when "0001100001" =>
                ret.key.value := "01100001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- a, CAPS
            when "1001100001" =>
                ret.key.value := "01000001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- a, NUM
            when "0101100001" =>
                ret.key.value := "01100001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- a, both
            when "1101100001" =>
                ret.key.value := "01000001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- e, default
            when "0001100101" =>
                ret.key.value := "01100101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- e, CAPS
            when "1001100101" =>
                ret.key.value := "01000101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- e, NUM
            when "0101100101" =>
                ret.key.value := "01100101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- e, both
            when "1101100101" =>
                ret.key.value := "01000101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- m, default
            when "0001101101" =>
                ret.key.value := "01101101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- m, CAPS
            when "1001101101" =>
                ret.key.value := "01001101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- m, NUM
            when "0101101101" =>
                ret.key.value := "01101101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- m, both
            when "1101101101" =>
                ret.key.value := "01001101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;


            -- 0x96, default
            when "0010010110" =>
                ret.key.value := "10010110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x96, CAPS
            when "1010010110" =>
                ret.key.value := "10010110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x96, NUM
            when "0110010110" =>
                ret.key.value := "10010110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x96, both
            when "1110010110" =>
                ret.key.value := "10010110";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x95, default
            when "0010010101" =>
                ret.key.value := "10010101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x95, CAPS
            when "1010010101" =>
                ret.key.value := "10010101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x95, NUM
            when "0110010101" =>
                ret.key.value := "10010101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x95, both
            when "1110010101" =>
                ret.key.value := "10010101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x94, default
            when "0010010100" =>
                ret.key.value := "10010100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x94, CAPS
            when "1010010100" =>
                ret.key.value := "10010100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x94, NUM
            when "0110010100" =>
                ret.key.value := "10010100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x94, both
            when "1110010100" =>
                ret.key.value := "10010100";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- u, default
            when "0001110101" =>
                ret.key.value := "01110101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- u, CAPS
            when "1001110101" =>
                ret.key.value := "01010101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- u, NUM
            when "0101110101" =>
                ret.key.value := "01110101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- u, both
            when "1101110101" =>
                ret.key.value := "01010101";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x92, default
            when "0010010010" =>
                ret.key.value := "10010010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x92, CAPS
            when "1010010010" =>
                ret.key.value := "10010010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x92, NUM
            when "0110010010" =>
                ret.key.value := "10010010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x92, both
            when "1110010010" =>
                ret.key.value := "10010010";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x91, default
            when "0010010001" =>
                ret.key.value := "10010001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x91, CAPS
            when "1010010001" =>
                ret.key.value := "10010001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x91, NUM
            when "0110010001" =>
                ret.key.value := "10010001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x91, both
            when "1110010001" =>
                ret.key.value := "10010001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x90, default
            when "0010010000" =>
                ret.key.value := "10010000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x90, CAPS
            when "1010010000" =>
                ret.key.value := "10010000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x90, NUM
            when "0110010000" =>
                ret.key.value := "10010000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x90, both
            when "1110010000" =>
                ret.key.value := "10010000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- y, default
            when "0001111001" =>
                ret.key.value := "01111001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- y, CAPS
            when "1001111001" =>
                ret.key.value := "01011001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- y, NUM
            when "0101111001" =>
                ret.key.value := "01111001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- y, both
            when "1101111001" =>
                ret.key.value := "01011001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x99, default
            when "0010011001" =>
                ret.key.value := "10011001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x99, CAPS
            when "1010011001" =>
                ret.key.value := "10011001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x99, NUM
            when "0110011001" =>
                ret.key.value := "10011001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x99, both
            when "1110011001" =>
                ret.key.value := "10011001";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;

            -- 0x98, default
            when "0010011000" =>
                ret.key.value := "10011000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x98, CAPS
            when "1010011000" =>
                ret.key.value := "10011000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x98, NUM
            when "0110011000" =>
                ret.key.value := "10011000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            -- 0x98, both
            when "1110011000" =>
                ret.key.value := "10011000";
                ret.key.valid := true;
                ret.key.pressed := key.pressed;
            when others =>
                -- Handle special keys
                case key.value is
                    -- Caps lock
                    when x"80" =>
                        if key.pressed
                        then
                            ret.state.caps_lock := not state.caps_lock;
                        end if;
                    -- Shift
                    when x"81" =>
                        ret.state.shift := key.pressed;
                    -- Scroll lock
                    when x"97" =>
                        if key.pressed
                        then
                            ret.state.scroll_lock := not state.scroll_lock;
                        end if;
                    -- Num lock
                    when x"A2" =>
                        if key.pressed
                        then
                            ret.state.num_lock := not state.num_lock;
                        end if;
                    when others =>
                end case;
        end case;

        return ret;
    end function;

end package body;

