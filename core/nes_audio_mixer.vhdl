library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;

package nes_audio_mixer is

    -- The APU output mixed with the audio from the cartridge
    function mix_audio
    (
        audio_in   : apu_out_t;
        cart_audio : cart_audio_t := 0
    )
    return mixed_audio_t;

    function mix_audio
    (
        audio_in        : apu_out_t;
        enable_square_1 : boolean;
        enable_square_2 : boolean;
        enable_triangle : boolean;
        enable_noise    : boolean;
        enable_dmc      : boolean
    )
    return mixed_audio_t;

end nes_audio_mixer;

package body nes_audio_mixer is

    function mix_audio
    (
        audio_in        : apu_out_t;
        enable_square_1 : boolean;
        enable_square_2 : boolean;
        enable_triangle : boolean;
        enable_noise    : boolean;
        enable_dmc      : boolean
    )
    return mixed_audio_t
    is
        variable v_audio : apu_out_t;
    begin
        v_audio := audio_in;
        
        if not enable_square_1
        then
            v_audio.square_1 := 0;
        end if;
        if not enable_square_2
        then
            v_audio.square_2 := 0;
        end if;
        if not enable_triangle
        then
            v_audio.triangle := 0;
        end if;
        if not enable_noise
        then
            v_audio.noise := 0;
        end if;
        if not enable_dmc
        then
            v_audio.dmc := 0;
        end if;
        
        return mix_audio(v_audio);
    end;

    function mix_audio
    (
        audio_in   : apu_out_t;
        cart_audio : cart_audio_t := 0
    )
    return mixed_audio_t
    is
        subtype mixed_level_t is natural range 0 to 2**mixed_audio_t'length-1;

        -- Ranges are limited to the reachable sums so the lookup tables
        -- below cover every value
        variable square_in : natural range 0 to 30;
        variable square_out : mixed_level_t;

        variable tnd_in : natural range 0 to 202;
        variable tnd_out : mixed_level_t;
    begin
        --     The normalized audio output level is the sum of two groups
        --     of channels:
        --
        --     output = square_out + tnd_out
        --
        --
        --                           95.88
        --     square_out = -----------------------
        --                         8128
        --                  ----------------- + 100
        --                  square1 + square2
        --
        --
        --                           159.79
        --     tnd_out = ------------------------------
        --                           1
        --               ------------------------ + 100
        --               triangle   noise    dmc
        --               -------- + ----- + -----
        --                 8227     12241   22638
        --
        --
        -- where triangle, noise, dmc, square1 and square2 are the values
        -- fed to their DACs. The dmc ranges from 0 to 127 and the others
        -- range from 0 to 15. When the sub-denominator of a group is zero,
        -- its output is 0. The output ranges from 0.0 to 1.0.
        --
        --
        -- Implementation Using Lookup Table 
        -- ---------------------------------
        -- The formulas can be efficiently implemented using two lookup
        -- tables: a 31-entry table for the two square channels and a
        -- 203-entry table for the remaining channels (due to the
        -- approximation of tnd_out, the numerators are adjusted slightly
        -- to preserve the normalized output range).
        --
        --     square_table [n] = 95.52 / (8128.0 / n + 100)
        --
        --     square_out = square_table [square1 + square2]
        --
        -- The latter table is approximated (within 4%) by using a base
        -- unit close to the
        -- DMC's DAC.
        --
        --     tnd_table [n] = 163.67 / (24329.0 / n + 100)
        --
        --     tnd_out = tnd_table [3 * triangle + 2 * noise + dmc]
        square_in := audio_in.square_1 + audio_in.square_2;
        tnd_in := 3 * audio_in.triangle + 2 * audio_in.noise + audio_in.dmc;
        
        case square_in is
            when 0 => square_out := 0;
            when 1 => square_out := 3;
            when 2 => square_out := 6;
            when 3 => square_out := 9;
            when 4 => square_out := 11;
            when 5 => square_out := 14;
            when 6 => square_out := 17;
            when 7 => square_out := 19;
            when 8 => square_out := 22;
            when 9 => square_out := 24;
            when 10 => square_out := 27;
            when 11 => square_out := 29;
            when 12 => square_out := 31;
            when 13 => square_out := 34;
            when 14 => square_out := 36;
            when 15 => square_out := 38;
            when 16 => square_out := 40;
            when 17 => square_out := 42;
            when 18 => square_out := 44;
            when 19 => square_out := 46;
            when 20 => square_out := 48;
            when 21 => square_out := 50;
            when 22 => square_out := 52;
            when 23 => square_out := 54;
            when 24 => square_out := 56;
            when 25 => square_out := 57;
            when 26 => square_out := 59;
            when 27 => square_out := 61;
            when 28 => square_out := 62;
            when 29 => square_out := 64;
            when 30 => square_out := 66;
        end case;
        
        case tnd_in is
            when 0 => tnd_out := 0;
            when 1 => tnd_out := 2;
            when 2 => tnd_out := 3;
            when 3 => tnd_out := 5;
            when 4 => tnd_out := 7;
            when 5 => tnd_out := 8;
            when 6 => tnd_out := 10;
            when 7 => tnd_out := 12;
            when 8 => tnd_out := 13;
            when 9 => tnd_out := 15;
            when 10 => tnd_out := 16;
            when 11 => tnd_out := 18;
            when 12 => tnd_out := 20;
            when 13 => tnd_out := 21;
            when 14 => tnd_out := 23;
            when 15 => tnd_out := 24;
            when 16 => tnd_out := 26;
            when 17 => tnd_out := 27;
            when 18 => tnd_out := 29;
            when 19 => tnd_out := 30;
            when 20 => tnd_out := 32;
            when 21 => tnd_out := 33;
            when 22 => tnd_out := 35;
            when 23 => tnd_out := 36;
            when 24 => tnd_out := 37;
            when 25 => tnd_out := 39;
            when 26 => tnd_out := 40;
            when 27 => tnd_out := 42;
            when 28 => tnd_out := 43;
            when 29 => tnd_out := 44;
            when 30 => tnd_out := 46;
            when 31 => tnd_out := 47;
            when 32 => tnd_out := 49;
            when 33 => tnd_out := 50;
            when 34 => tnd_out := 51;
            when 35 => tnd_out := 52;
            when 36 => tnd_out := 54;
            when 37 => tnd_out := 55;
            when 38 => tnd_out := 56;
            when 39 => tnd_out := 58;
            when 40 => tnd_out := 59;
            when 41 => tnd_out := 60;
            when 42 => tnd_out := 61;
            when 43 => tnd_out := 63;
            when 44 => tnd_out := 64;
            when 45 => tnd_out := 65;
            when 46 => tnd_out := 66;
            when 47 => tnd_out := 68;
            when 48 => tnd_out := 69;
            when 49 => tnd_out := 70;
            when 50 => tnd_out := 71;
            when 51 => tnd_out := 72;
            when 52 => tnd_out := 73;
            when 53 => tnd_out := 75;
            when 54 => tnd_out := 76;
            when 55 => tnd_out := 77;
            when 56 => tnd_out := 78;
            when 57 => tnd_out := 79;
            when 58 => tnd_out := 80;
            when 59 => tnd_out := 81;
            when 60 => tnd_out := 83;
            when 61 => tnd_out := 84;
            when 62 => tnd_out := 85;
            when 63 => tnd_out := 86;
            when 64 => tnd_out := 87;
            when 65 => tnd_out := 88;
            when 66 => tnd_out := 89;
            when 67 => tnd_out := 90;
            when 68 => tnd_out := 91;
            when 69 => tnd_out := 92;
            when 70 => tnd_out := 93;
            when 71 => tnd_out := 94;
            when 72 => tnd_out := 95;
            when 73 => tnd_out := 96;
            when 74 => tnd_out := 97;
            when 75 => tnd_out := 98;
            when 76 => tnd_out := 99;
            when 77 => tnd_out := 100;
            when 78 => tnd_out := 101;
            when 79 => tnd_out := 102;
            when 80 => tnd_out := 103;
            when 81 => tnd_out := 104;
            when 82 => tnd_out := 105;
            when 83 => tnd_out := 106;
            when 84 => tnd_out := 107;
            when 85 => tnd_out := 108;
            when 86 => tnd_out := 109;
            when 87 => tnd_out := 110;
            when 88 => tnd_out := 111;
            when 89 => tnd_out := 112;
            when 90 => tnd_out := 113;
            when 91 => tnd_out := 114;
            when 92 => tnd_out := 115;
            when 93 => tnd_out := 115;
            when 94 => tnd_out := 116;
            when 95 => tnd_out := 117;
            when 96 => tnd_out := 118;
            when 97 => tnd_out := 119;
            when 98 => tnd_out := 120;
            when 99 => tnd_out := 121;
            when 100 => tnd_out := 122;
            when 101 => tnd_out := 122;
            when 102 => tnd_out := 123;
            when 103 => tnd_out := 124;
            when 104 => tnd_out := 125;
            when 105 => tnd_out := 126;
            when 106 => tnd_out := 127;
            when 107 => tnd_out := 127;
            when 108 => tnd_out := 128;
            when 109 => tnd_out := 129;
            when 110 => tnd_out := 130;
            when 111 => tnd_out := 131;
            when 112 => tnd_out := 132;
            when 113 => tnd_out := 132;
            when 114 => tnd_out := 133;
            when 115 => tnd_out := 134;
            when 116 => tnd_out := 135;
            when 117 => tnd_out := 136;
            when 118 => tnd_out := 136;
            when 119 => tnd_out := 137;
            when 120 => tnd_out := 138;
            when 121 => tnd_out := 139;
            when 122 => tnd_out := 139;
            when 123 => tnd_out := 140;
            when 124 => tnd_out := 141;
            when 125 => tnd_out := 142;
            when 126 => tnd_out := 142;
            when 127 => tnd_out := 143;
            when 128 => tnd_out := 144;
            when 129 => tnd_out := 145;
            when 130 => tnd_out := 145;
            when 131 => tnd_out := 146;
            when 132 => tnd_out := 147;
            when 133 => tnd_out := 148;
            when 134 => tnd_out := 148;
            when 135 => tnd_out := 149;
            when 136 => tnd_out := 150;
            when 137 => tnd_out := 150;
            when 138 => tnd_out := 151;
            when 139 => tnd_out := 152;
            when 140 => tnd_out := 152;
            when 141 => tnd_out := 153;
            when 142 => tnd_out := 154;
            when 143 => tnd_out := 155;
            when 144 => tnd_out := 155;
            when 145 => tnd_out := 156;
            when 146 => tnd_out := 157;
            when 147 => tnd_out := 157;
            when 148 => tnd_out := 158;
            when 149 => tnd_out := 159;
            when 150 => tnd_out := 159;
            when 151 => tnd_out := 160;
            when 152 => tnd_out := 160;
            when 153 => tnd_out := 161;
            when 154 => tnd_out := 162;
            when 155 => tnd_out := 162;
            when 156 => tnd_out := 163;
            when 157 => tnd_out := 164;
            when 158 => tnd_out := 164;
            when 159 => tnd_out := 165;
            when 160 => tnd_out := 166;
            when 161 => tnd_out := 166;
            when 162 => tnd_out := 167;
            when 163 => tnd_out := 167;
            when 164 => tnd_out := 168;
            when 165 => tnd_out := 169;
            when 166 => tnd_out := 169;
            when 167 => tnd_out := 170;
            when 168 => tnd_out := 170;
            when 169 => tnd_out := 171;
            when 170 => tnd_out := 172;
            when 171 => tnd_out := 172;
            when 172 => tnd_out := 173;
            when 173 => tnd_out := 173;
            when 174 => tnd_out := 174;
            when 175 => tnd_out := 175;
            when 176 => tnd_out := 175;
            when 177 => tnd_out := 176;
            when 178 => tnd_out := 176;
            when 179 => tnd_out := 177;
            when 180 => tnd_out := 177;
            when 181 => tnd_out := 178;
            when 182 => tnd_out := 179;
            when 183 => tnd_out := 179;
            when 184 => tnd_out := 180;
            when 185 => tnd_out := 180;
            when 186 => tnd_out := 181;
            when 187 => tnd_out := 181;
            when 188 => tnd_out := 182;
            when 189 => tnd_out := 182;
            when 190 => tnd_out := 183;
            when 191 => tnd_out := 184;
            when 192 => tnd_out := 184;
            when 193 => tnd_out := 185;
            when 194 => tnd_out := 185;
            when 195 => tnd_out := 186;
            when 196 => tnd_out := 186;
            when 197 => tnd_out := 187;
            when 198 => tnd_out := 187;
            when 199 => tnd_out := 188;
            when 200 => tnd_out := 188;
            when 201 => tnd_out := 189;
            when 202 => tnd_out := 189;
        end case;
        return to_unsigned(square_out + tnd_out + cart_audio,
                           mixed_audio_t'length);
    end;

end package body;
