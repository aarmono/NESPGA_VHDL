library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.opll_bus_types.all;

-- The audio of the Konami VRC7: six channels of two-operator FM synthesis,
-- a cut down Yamaha YM2413 (OPLL). This follows Nuked-OPLL by Nuke.YKT,
-- which is taken from the die of the VRC7, clock for clock.
--
-- The synthesizer runs from a 3.58MHz resonator, twice the CPU clock, and
-- takes 4 of its clocks for each of 18 steps, so a step is 2 CPU cycles and
-- all 18 make a sample, 36 CPU cycles. Each step works on one operator, in
-- a pipeline: the phase of one operator is looked up in the log-sin table
-- while the exponent of the previous one is looked up and the output of the
-- one before that is ready. The 18 operators are the modulator and carrier
-- of 9 channels. The VRC7 is an OPLL in rhythm mode with no rhythm output,
-- so channels 6-8 are never heard, and their rhythm sounds are not built
-- here. The output is one operator per step; it is summed over the 18 steps
-- of a sample.
--
-- The state of the operators and the channel registers are in a RAM, with
-- one access per PPU cycle, and the tables in two ROMs. A step is 6 PPU
-- cycles, in which the RAM is accessed and the tables looked up as STEP_*
-- below; the step
-- itself is computed in the last, the CPU sync cycle of the second CPU
-- cycle. Nuked-OPLL keeps the operators in arrays read at several offsets
-- from the step; each is read once here and the value kept for the steps
-- that follow, and the feedback of a channel is kept with its modulator.
--
-- Writes to the address (0x9010) and data (0x9030) registers go to a latch
-- that the synthesizer samples on its next step and handles over the
-- following ones, as on the chip, so writes too close together are lost.
--
-- Bit 6 of 0xE000 holds the synthesizer in reset, which clears its
-- registers and its tremolo but not its vibrato, and ignores writes. Here
-- the RAM is cleared one word per PPU cycle after reset, before the first
-- step
package lib_vrc7_audio is

    -- The step of the 18 of a sample
    subtype opll_cycle_t is natural range 0 to 17;
    -- The PPU cycle of the 6 of a step
    subtype opll_dot_t is natural range 0 to 5;

    subtype opll_phase_t is natural range 0 to 2**19-1;
    subtype opll_level_t is natural range 0 to 2**7-1;
    type opll_eg_state_t is (EG_ATTACK, EG_DECAY, EG_SUSTAIN, EG_RELEASE);
    -- An output of an operator, signed 12 bits
    subtype opll_out_t is integer range -2**11 to 2**11-1;

    -- The state of an operator, in the RAM
    type opll_slot_t is record
        phase : opll_phase_t;
        level : opll_level_t;
        state : opll_eg_state_t;
        -- The last two outputs of the modulator of a channel, for its
        -- feedback. Not used by carriers
        fb1   : opll_out_t;
        fb2   : opll_out_t;
    end record;

    subtype opll_fnum_t is natural range 0 to 2**9-1;
    subtype opll_block_t is natural range 0 to 7;
    subtype opll_nibble_t is natural range 0 to 15;

    -- The registers of a channel, 0x10-0x18, 0x20-0x28 and 0x30-0x38, in the
    -- RAM
    type opll_channel_t is record
        fnum  : opll_fnum_t;
        octave : opll_block_t;
        kon   : boolean;
        son   : boolean;
        vol   : opll_nibble_t;
        inst  : opll_nibble_t;
    end record;

    -- An instrument: the 8 bytes of registers 0x00-0x07
    type opll_patch_t is array(0 to 7) of data_t;

    -- An output of the chip, one operator per step
    subtype opll_dac_t is integer range -256 to 256;
    -- The sum of a sample, 6 carriers
    subtype opll_sum_t is integer range -6 * 256 to 6 * 256;

    type vrc7_audio_t is record
        -- The RAM words still to be cleared after reset, from the top
        clear       : natural range 0 to 2**opll_ram_addr_t'length;
        cycle       : opll_cycle_t;
        -- PPU cycles since the last CPU sync cycle, and the CPU cycle of the
        -- step
        dot         : natural range 0 to 1;
        second      : boolean;

        -- The latch of the CPU writes and the address and data registers
        write_data  : data_t;
        write_a     : natural range 0 to 3;
        write_d     : natural range 0 to 3;
        write_a_en  : boolean;
        write_d_en  : boolean;
        fm_address  : boolean;
        fm_data     : boolean;
        mode_address : natural range 0 to 31;
        address     : natural range 0 to 255;
        data        : natural range 0 to 255;

        -- The envelope generator
        eg_counter_state      : natural range 0 to 3;
        eg_counter_state_prev : natural range 0 to 3;
        eg_timer              : natural range 0 to 2**18-1;
        eg_timer_low_lock     : natural range 0 to 3;
        eg_timer_carry        : natural range 0 to 1;
        eg_timer_shift        : opll_cycle_t;
        eg_timer_shift_lock   : natural range 0 to 13;
        eg_timer_shift_stop   : boolean;
        eg_kon                : natural range 0 to 3;
        eg_dokon              : natural range 0 to 2**16-1;
        eg_off                : natural range 0 to 3;
        eg_rate               : natural range 0 to 63;
        eg_zerorate           : boolean;
        eg_inc_lo             : natural range 0 to 1;
        eg_inc_hi             : natural range 0 to 1;
        eg_rate_hi            : opll_nibble_t;
        eg_sl                 : opll_nibble_t;
        eg_ksltl              : natural range 0 to 255;
        eg_out                : opll_level_t;
        eg_silent             : boolean;

        -- The phase generator
        pg_inc        : natural range 0 to 2**20-1;
        pg_phase_next : opll_phase_t;

        -- The operator
        op_mod    : natural range 0 to 2**9-1;
        op_neg    : natural range 0 to 3;
        op_logsin : natural range 0 to 2**12-1;
        op_exp_m  : natural range 0 to 2**11-1;
        op_exp_s  : opll_nibble_t;

        ch_out    : integer range -256 to 255;
        output_m  : opll_dac_t;

        -- The LFOs of vibrato and tremolo
        lfo_counter     : natural range 0 to 2**10-1;
        lfo_vib_counter : natural range 0 to 7;
        lfo_am_counter  : natural range 0 to 2**9-1;
        lfo_am_step     : boolean;
        lfo_am_dir      : boolean;
        lfo_am_car      : natural range 0 to 1;
        lfo_am_out      : opll_nibble_t;

        testmode : opll_nibble_t;
        patch    : opll_patch_t;

        -- Rhythm mode, which is always on in the VRC7: register 0x0E, the
        -- noise and the phase bits of the hi-hat and top cymbal
        rhythm     : natural range 0 to 63;
        rm_noise   : natural range 0 to 2**23-1;
        rm_hh_bit2 : boolean;
        rm_hh_bit3 : boolean;
        rm_hh_bit7 : boolean;
        rm_hh_bit8 : boolean;
        rm_tc_bit3 : boolean;
        rm_tc_bit5 : boolean;

        -- The patch and channel values prepared for the next steps
        c_tl        : natural range 0 to 63;
        c_ar        : opll_nibble_t;
        c_dr        : opll_nibble_t;
        c_rr        : opll_nibble_t;
        c_et        : boolean;
        c_ksr       : boolean;
        c_ksl       : natural range 0 to 3;
        c_ksr_freq  : opll_nibble_t;
        c_ksl_freq  : opll_nibble_t;
        c_ksl_block : opll_block_t;
        c_multi     : opll_nibble_t;
        c_sl        : opll_nibble_t;
        c_fb        : natural range 0 to 7;
        c_vib       : boolean;
        c_am        : boolean;
        c_dc        : natural range 0 to 7;
        c_dm        : natural range 0 to 7;
        c_fnum      : opll_fnum_t;
        c_block     : opll_block_t;

        -- What was read from the RAM for the step
        rd_channel  : opll_channel_t;
        rd_slot     : opll_slot_t;
        rd_old      : opll_channel_t;

        -- The addresses of the step's log-sin and exponent, which
        -- get_vrc7_tables looks up. The phase is negative: bit 9 of the
        -- phase of the operator. The exponent level is the attenuation, 12
        -- bits
        logsin_addr : natural range 0 to 2**8-1;
        phase_neg   : natural range 0 to 1;
        exp_level   : natural range 0 to 2**12-1;

        -- The operators of the two steps before, as they were read
        slot_1      : opll_slot_t;
        slot_2      : opll_slot_t;
        -- The phase of the operator of the step before, written with its
        -- state in the next step
        phase_wr    : opll_phase_t;
        -- The operator of two steps before, as the step left it, to be
        -- written in the next step
        slot_wr     : opll_slot_t;

        -- The sum of the output of the sample so far, and of the last
        sum         : opll_sum_t;
        level       : opll_sum_t;
    end record;

    -- What get_vrc7_tables looks up: the log-sin of the step's operator and
    -- the exponent of the operator of the step before
    type vrc7_tables_t is record
        logsin : natural range 0 to 2**12-1;
        exp    : natural range 0 to 2**11-1;
    end record;

    -- For a cycle_vrc7_audio whose result is not kept
    constant VRC7_TABLES_UNUSED : vrc7_tables_t := (logsin => 0, exp => 0);

    function get_reset_vrc7_audio return vrc7_audio_t;

    -- Holds the synthesizer in reset, which keeps the vibrato
    function reset_vrc7_audio(audio : vrc7_audio_t) return vrc7_audio_t;

    -- Runs the synthesizer for a PPU cycle. ram_data is what the access of
    -- get_vrc7_ram_bus reads, and tables what get_vrc7_tables looked up the
    -- PPU cycle before
    function cycle_vrc7_audio
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean;
        ram_data : opll_ram_data_t;
        tables   : vrc7_tables_t
    )
    return vrc7_audio_t;

    -- The CPU writes data to the address register (port 0, 0x9010) or the
    -- data register (port 1, 0x9030). Done after cycle_vrc7_audio
    function write_vrc7_audio
    (
        audio : vrc7_audio_t;
        port1 : boolean;
        data  : data_t
    )
    return vrc7_audio_t;

    function get_vrc7_ram_bus
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean
    )
    return opll_ram_bus_t;

    function get_vrc7_ram_data
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean
    )
    return opll_ram_data_t;

    -- Looks up the log-sin and exponent tables. Quartus builds them as ROMs
    -- in the on-chip memory only when the result goes straight into a
    -- register of its own, loaded every PPU cycle
    function get_vrc7_tables(audio : vrc7_audio_t) return vrc7_tables_t;

    -- The sum of the outputs of the last sample, in the units of the chip
    function get_vrc7_audio_sum(audio : vrc7_audio_t) return opll_sum_t;

    -- The output of the chip in the step just computed. For tests that
    -- compare with Nuked-OPLL, along with is_vrc7_audio_step
    function get_vrc7_audio_dac(audio : vrc7_audio_t) return opll_dac_t;

    -- The PPU cycle computes a step
    function is_vrc7_audio_step
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean
    )
    return boolean;

end package lib_vrc7_audio;


package body lib_vrc7_audio is

    -- The PPU cycles of a step: the channel registers of the step and the
    -- operator of the step are read, the operator of three steps before is
    -- written, the old registers of a channel written this step are read
    -- (and the table addresses worked out), the log-sin of the operator and
    -- the exponent of the operator before are looked up, and the step is
    -- computed and the channel written
    constant STEP_CHANNEL : opll_dot_t := 0;
    constant STEP_SLOT    : opll_dot_t := 1;
    constant STEP_WRITE   : opll_dot_t := 2;
    constant STEP_OLD     : opll_dot_t := 3;
    constant STEP_TABLES  : opll_dot_t := 4;
    constant STEP_EXP     : opll_dot_t := 5;

    -- RAM addresses: operators at 0-17, channels at 32-40
    constant RAM_CHANNEL : natural := 32;

    type cycle_arr_t is array(opll_cycle_t) of natural range 0 to 8;
    -- The channel of the operator after the step's
    constant CH_OFFSET : cycle_arr_t :=
        (1, 2, 0, 1, 2, 3, 4, 5, 3, 4, 5, 6, 7, 8, 6, 7, 8, 0);

    type multi_arr_t is array(opll_nibble_t) of natural range 0 to 30;
    -- The frequency multipliers, times 2
    constant PG_MULTI : multi_arr_t :=
        (1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 24, 24, 30, 30);

    type ksl_arr_t is array(opll_nibble_t) of natural range 0 to 64;
    constant EG_KSLTABLE : ksl_arr_t :=
        (0, 32, 40, 45, 48, 51, 53, 55, 56, 58, 59, 60, 61, 62, 63, 64);

    -- The log-sin table holds the attenuation of a quarter wave of a sine,
    -- in 1/256 steps of 6dB, and the exponent table 2**(-x/256), scaled to
    -- 0x400-0x7FA. The values are those dumped from the die by Nuke.YKT
    -- (Nuked-OPLL)
    type logsin_rom_t is array(0 to 2**8-1) of natural range 0 to 2**12-1;
    constant LOGSIN_ROM : logsin_rom_t :=
    (
        16#859#, 16#6C3#, 16#607#, 16#58B#, 16#52E#, 16#4E4#, 16#4A6#, 16#471#,
        16#443#, 16#41A#, 16#3F5#, 16#3D3#, 16#3B5#, 16#398#, 16#37E#, 16#365#,
        16#34E#, 16#339#, 16#324#, 16#311#, 16#2FF#, 16#2ED#, 16#2DC#, 16#2CD#,
        16#2BD#, 16#2AF#, 16#2A0#, 16#293#, 16#286#, 16#279#, 16#26D#, 16#261#,
        16#256#, 16#24B#, 16#240#, 16#236#, 16#22C#, 16#222#, 16#218#, 16#20F#,
        16#206#, 16#1FD#, 16#1F5#, 16#1EC#, 16#1E4#, 16#1DC#, 16#1D4#, 16#1CD#,
        16#1C5#, 16#1BE#, 16#1B7#, 16#1B0#, 16#1A9#, 16#1A2#, 16#19B#, 16#195#,
        16#18F#, 16#188#, 16#182#, 16#17C#, 16#177#, 16#171#, 16#16B#, 16#166#,
        16#160#, 16#15B#, 16#155#, 16#150#, 16#14B#, 16#146#, 16#141#, 16#13C#,
        16#137#, 16#133#, 16#12E#, 16#129#, 16#125#, 16#121#, 16#11C#, 16#118#,
        16#114#, 16#10F#, 16#10B#, 16#107#, 16#103#, 16#0FF#, 16#0FB#, 16#0F8#,
        16#0F4#, 16#0F0#, 16#0EC#, 16#0E9#, 16#0E5#, 16#0E2#, 16#0DE#, 16#0DB#,
        16#0D7#, 16#0D4#, 16#0D1#, 16#0CD#, 16#0CA#, 16#0C7#, 16#0C4#, 16#0C1#,
        16#0BE#, 16#0BB#, 16#0B8#, 16#0B5#, 16#0B2#, 16#0AF#, 16#0AC#, 16#0A9#,
        16#0A7#, 16#0A4#, 16#0A1#, 16#09F#, 16#09C#, 16#099#, 16#097#, 16#094#,
        16#092#, 16#08F#, 16#08D#, 16#08A#, 16#088#, 16#086#, 16#083#, 16#081#,
        16#07F#, 16#07D#, 16#07A#, 16#078#, 16#076#, 16#074#, 16#072#, 16#070#,
        16#06E#, 16#06C#, 16#06A#, 16#068#, 16#066#, 16#064#, 16#062#, 16#060#,
        16#05E#, 16#05C#, 16#05B#, 16#059#, 16#057#, 16#055#, 16#053#, 16#052#,
        16#050#, 16#04E#, 16#04D#, 16#04B#, 16#04A#, 16#048#, 16#046#, 16#045#,
        16#043#, 16#042#, 16#040#, 16#03F#, 16#03E#, 16#03C#, 16#03B#, 16#039#,
        16#038#, 16#037#, 16#035#, 16#034#, 16#033#, 16#031#, 16#030#, 16#02F#,
        16#02E#, 16#02D#, 16#02B#, 16#02A#, 16#029#, 16#028#, 16#027#, 16#026#,
        16#025#, 16#024#, 16#023#, 16#022#, 16#021#, 16#020#, 16#01F#, 16#01E#,
        16#01D#, 16#01C#, 16#01B#, 16#01A#, 16#019#, 16#018#, 16#017#, 16#017#,
        16#016#, 16#015#, 16#014#, 16#014#, 16#013#, 16#012#, 16#011#, 16#011#,
        16#010#, 16#00F#, 16#00F#, 16#00E#, 16#00D#, 16#00D#, 16#00C#, 16#00C#,
        16#00B#, 16#00A#, 16#00A#, 16#009#, 16#009#, 16#008#, 16#008#, 16#007#,
        16#007#, 16#007#, 16#006#, 16#006#, 16#005#, 16#005#, 16#005#, 16#004#,
        16#004#, 16#004#, 16#003#, 16#003#, 16#003#, 16#002#, 16#002#, 16#002#,
        16#002#, 16#001#, 16#001#, 16#001#, 16#001#, 16#001#, 16#001#, 16#001#,
        16#000#, 16#000#, 16#000#, 16#000#, 16#000#, 16#000#, 16#000#, 16#000#
    );

    type exp_rom_t is array(0 to 2**8-1) of natural range 0 to 2**11-1;
    constant EXP_ROM : exp_rom_t :=
    (
        16#7FA#, 16#7F5#, 16#7EF#, 16#7EA#, 16#7E4#, 16#7DF#, 16#7DA#, 16#7D4#,
        16#7CF#, 16#7C9#, 16#7C4#, 16#7BF#, 16#7B9#, 16#7B4#, 16#7AE#, 16#7A9#,
        16#7A4#, 16#79F#, 16#799#, 16#794#, 16#78F#, 16#78A#, 16#784#, 16#77F#,
        16#77A#, 16#775#, 16#770#, 16#76A#, 16#765#, 16#760#, 16#75B#, 16#756#,
        16#751#, 16#74C#, 16#747#, 16#742#, 16#73D#, 16#738#, 16#733#, 16#72E#,
        16#729#, 16#724#, 16#71F#, 16#71A#, 16#715#, 16#710#, 16#70B#, 16#706#,
        16#702#, 16#6FD#, 16#6F8#, 16#6F3#, 16#6EE#, 16#6E9#, 16#6E5#, 16#6E0#,
        16#6DB#, 16#6D6#, 16#6D2#, 16#6CD#, 16#6C8#, 16#6C4#, 16#6BF#, 16#6BA#,
        16#6B5#, 16#6B1#, 16#6AC#, 16#6A8#, 16#6A3#, 16#69E#, 16#69A#, 16#695#,
        16#691#, 16#68C#, 16#688#, 16#683#, 16#67F#, 16#67A#, 16#676#, 16#671#,
        16#66D#, 16#668#, 16#664#, 16#65F#, 16#65B#, 16#657#, 16#652#, 16#64E#,
        16#649#, 16#645#, 16#641#, 16#63C#, 16#638#, 16#634#, 16#630#, 16#62B#,
        16#627#, 16#623#, 16#61E#, 16#61A#, 16#616#, 16#612#, 16#60E#, 16#609#,
        16#605#, 16#601#, 16#5FD#, 16#5F9#, 16#5F5#, 16#5F0#, 16#5EC#, 16#5E8#,
        16#5E4#, 16#5E0#, 16#5DC#, 16#5D8#, 16#5D4#, 16#5D0#, 16#5CC#, 16#5C8#,
        16#5C4#, 16#5C0#, 16#5BC#, 16#5B8#, 16#5B4#, 16#5B0#, 16#5AC#, 16#5A8#,
        16#5A4#, 16#5A0#, 16#59C#, 16#599#, 16#595#, 16#591#, 16#58D#, 16#589#,
        16#585#, 16#581#, 16#57E#, 16#57A#, 16#576#, 16#572#, 16#56F#, 16#56B#,
        16#567#, 16#563#, 16#560#, 16#55C#, 16#558#, 16#554#, 16#551#, 16#54D#,
        16#549#, 16#546#, 16#542#, 16#53E#, 16#53B#, 16#537#, 16#534#, 16#530#,
        16#52C#, 16#529#, 16#525#, 16#522#, 16#51E#, 16#51B#, 16#517#, 16#514#,
        16#510#, 16#50C#, 16#509#, 16#506#, 16#502#, 16#4FF#, 16#4FB#, 16#4F8#,
        16#4F4#, 16#4F1#, 16#4ED#, 16#4EA#, 16#4E7#, 16#4E3#, 16#4E0#, 16#4DC#,
        16#4D9#, 16#4D6#, 16#4D2#, 16#4CF#, 16#4CC#, 16#4C8#, 16#4C5#, 16#4C2#,
        16#4BE#, 16#4BB#, 16#4B8#, 16#4B5#, 16#4B1#, 16#4AE#, 16#4AB#, 16#4A8#,
        16#4A4#, 16#4A1#, 16#49E#, 16#49B#, 16#498#, 16#494#, 16#491#, 16#48E#,
        16#48B#, 16#488#, 16#485#, 16#482#, 16#47E#, 16#47B#, 16#478#, 16#475#,
        16#472#, 16#46F#, 16#46C#, 16#469#, 16#466#, 16#463#, 16#460#, 16#45D#,
        16#45A#, 16#457#, 16#454#, 16#451#, 16#44E#, 16#44B#, 16#448#, 16#445#,
        16#442#, 16#43F#, 16#43C#, 16#439#, 16#436#, 16#433#, 16#430#, 16#42D#,
        16#42A#, 16#428#, 16#425#, 16#422#, 16#41F#, 16#41C#, 16#419#, 16#416#,
        16#414#, 16#411#, 16#40E#, 16#40B#, 16#408#, 16#406#, 16#403#, 16#400#
    );

    type patch_rom_t is array(1 to 15) of opll_patch_t;
    -- The instruments of the VRC7, as dumped from the chip
    constant PATCH_ROM : patch_rom_t :=
    (
        (x"03", x"21", x"05", x"06", x"E8", x"81", x"42", x"27"),
        (x"13", x"41", x"14", x"0D", x"D8", x"F6", x"23", x"12"),
        (x"11", x"11", x"08", x"08", x"FA", x"B2", x"20", x"12"),
        (x"31", x"61", x"0C", x"07", x"A8", x"64", x"61", x"27"),
        (x"32", x"21", x"1E", x"06", x"E1", x"76", x"01", x"28"),
        (x"02", x"01", x"06", x"00", x"A3", x"E2", x"F4", x"F4"),
        (x"21", x"61", x"1D", x"07", x"82", x"81", x"11", x"07"),
        (x"23", x"21", x"22", x"17", x"A2", x"72", x"01", x"17"),
        (x"35", x"11", x"25", x"00", x"40", x"73", x"72", x"01"),
        (x"B5", x"01", x"0F", x"0F", x"A8", x"A5", x"51", x"02"),
        (x"17", x"C1", x"24", x"07", x"F8", x"F8", x"22", x"12"),
        (x"71", x"23", x"11", x"06", x"65", x"74", x"18", x"16"),
        (x"01", x"02", x"D3", x"05", x"C9", x"95", x"03", x"02"),
        (x"61", x"63", x"0C", x"00", x"94", x"C0", x"33", x"F6"),
        (x"21", x"72", x"0D", x"00", x"C1", x"D5", x"56", x"06")
    );

    type drum_rom_t is array(0 to 5) of opll_patch_t;
    -- The drums of rhythm mode, as in Nuked-OPLL: bass drum (two
    -- operators), hi-hat, tom, snare and top cymbal
    constant DRUM_ROM : drum_rom_t :=
    (
        (x"01", x"00", x"18", x"0F", x"DF", x"00", x"6A", x"00"),
        (x"01", x"00", x"00", x"00", x"C8", x"00", x"A7", x"00"),
        (x"05", x"00", x"00", x"00", x"F8", x"00", x"59", x"00"),
        (x"00", x"01", x"00", x"00", x"00", x"F8", x"00", x"6D"),
        (x"00", x"01", x"00", x"00", x"00", x"D8", x"00", x"48"),
        (x"00", x"01", x"00", x"00", x"00", x"AA", x"00", x"55")
    );

    -- The drums in the order rhythm mode steps through them, in steps
    -- 11-16
    subtype rm_select_t is natural range 0 to 6;
    constant RM_BD0 : rm_select_t := 0;
    constant RM_HH  : rm_select_t := 1;
    constant RM_TOM : rm_select_t := 2;
    constant RM_BD1 : rm_select_t := 3;
    constant RM_SD  : rm_select_t := 4;
    constant RM_TC  : rm_select_t := 5;
    constant RM_NONE : rm_select_t := 6;

    constant RESET_SLOT : opll_slot_t :=
    (
        phase => 0,
        level => opll_level_t'high,
        state => EG_RELEASE,
        fb1 => 0,
        fb2 => 0
    );

    constant RESET_CHANNEL : opll_channel_t :=
    (
        fnum => 0,
        octave => 0,
        kon => false,
        son => false,
        vol => 0,
        inst => 0
    );

    function to_slot_word(slot : opll_slot_t) return opll_ram_data_t
    is
    begin
        return to_std_logic_vector(wrap(slot.fb2, 2**12-1), 12) &
               to_std_logic_vector(wrap(slot.fb1, 2**12-1), 12) &
               to_std_logic_vector(opll_eg_state_t'pos(slot.state), 2) &
               to_std_logic_vector(slot.level, 7) &
               to_std_logic_vector(slot.phase, 19);
    end;

    function to_signed_12(val : natural) return opll_out_t
    is
    begin
        if val >= 2**11
        then
            return val - 2**12;
        end if;
        return val;
    end;

    function from_slot_word(word : opll_ram_data_t) return opll_slot_t
    is
        variable ret : opll_slot_t;
    begin
        ret.phase := to_integer(word(18 downto 0));
        ret.level := to_integer(word(25 downto 19));
        ret.state := opll_eg_state_t'val(to_integer(word(27 downto 26)));
        ret.fb1 := to_signed_12(to_integer(word(39 downto 28)));
        ret.fb2 := to_signed_12(to_integer(word(51 downto 40)));

        return ret;
    end;

    function to_channel_word(ch : opll_channel_t) return opll_ram_data_t
    is
        variable ret : opll_ram_data_t;
    begin
        ret := (others => '0');
        ret(8 downto 0) := to_std_logic_vector(ch.fnum, 9);
        ret(11 downto 9) := to_std_logic_vector(ch.octave, 3);
        ret(12) := to_std_logic(ch.kon);
        ret(13) := to_std_logic(ch.son);
        ret(17 downto 14) := to_std_logic_vector(ch.vol, 4);
        ret(21 downto 18) := to_std_logic_vector(ch.inst, 4);

        return ret;
    end;

    function from_channel_word(word : opll_ram_data_t) return opll_channel_t
    is
        variable ret : opll_channel_t;
    begin
        ret.fnum := to_integer(word(8 downto 0));
        ret.octave := to_integer(word(11 downto 9));
        ret.kon := word(12) = '1';
        ret.son := word(13) = '1';
        ret.vol := to_integer(word(17 downto 14));
        ret.inst := to_integer(word(21 downto 18));

        return ret;
    end;

    function get_reset_vrc7_audio return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
    begin
        ret.clear := 2**opll_ram_addr_t'length;
        ret.cycle := 0;
        ret.dot := 0;
        ret.second := false;

        ret.write_data := (others => '0');
        ret.write_a := 0;
        ret.write_d := 0;
        ret.write_a_en := false;
        ret.write_d_en := false;
        ret.fm_address := false;
        ret.fm_data := false;
        ret.mode_address := 0;
        ret.address := 0;
        ret.data := 0;

        ret.eg_counter_state := 0;
        ret.eg_counter_state_prev := 0;
        ret.eg_timer := 0;
        ret.eg_timer_low_lock := 0;
        ret.eg_timer_carry := 0;
        ret.eg_timer_shift := 0;
        ret.eg_timer_shift_lock := 0;
        ret.eg_timer_shift_stop := false;
        ret.eg_kon := 0;
        ret.eg_dokon := 0;
        ret.eg_off := 0;
        ret.eg_rate := 0;
        ret.eg_zerorate := false;
        ret.eg_inc_lo := 0;
        ret.eg_inc_hi := 0;
        ret.eg_rate_hi := 0;
        ret.eg_sl := 0;
        ret.eg_ksltl := 0;
        ret.eg_out := opll_level_t'high;
        ret.eg_silent := false;

        ret.pg_inc := 0;
        ret.pg_phase_next := 0;

        ret.op_mod := 0;
        ret.op_neg := 0;
        ret.op_logsin := 0;
        ret.op_exp_m := 0;
        ret.op_exp_s := 0;

        ret.ch_out := 0;
        ret.output_m := 0;

        ret.lfo_counter := 0;
        ret.lfo_vib_counter := 0;
        ret.lfo_am_counter := 0;
        ret.lfo_am_step := false;
        ret.lfo_am_dir := false;
        ret.lfo_am_car := 0;
        ret.lfo_am_out := 0;

        ret.testmode := 0;
        ret.patch := (others => (others => '0'));

        ret.rhythm := 16#20#;
        ret.rm_noise := 0;
        ret.rm_hh_bit2 := false;
        ret.rm_hh_bit3 := false;
        ret.rm_hh_bit7 := false;
        ret.rm_hh_bit8 := false;
        ret.rm_tc_bit3 := false;
        ret.rm_tc_bit5 := false;

        ret.c_tl := 0;
        ret.c_ar := 0;
        ret.c_dr := 0;
        ret.c_rr := 0;
        ret.c_et := false;
        ret.c_ksr := false;
        ret.c_ksl := 0;
        ret.c_ksr_freq := 0;
        ret.c_ksl_freq := 0;
        ret.c_ksl_block := 0;
        ret.c_multi := 0;
        ret.c_sl := 0;
        ret.c_fb := 0;
        ret.c_vib := false;
        ret.c_am := false;
        ret.c_dc := 0;
        ret.c_dm := 0;
        ret.c_fnum := 0;
        ret.c_block := 0;

        ret.rd_channel := RESET_CHANNEL;
        ret.rd_slot := RESET_SLOT;
        ret.rd_old := RESET_CHANNEL;
        ret.logsin_addr := 0;
        ret.phase_neg := 0;
        ret.exp_level := 0;

        ret.slot_1 := RESET_SLOT;
        ret.slot_2 := RESET_SLOT;
        ret.phase_wr := 0;
        ret.slot_wr := RESET_SLOT;

        ret.sum := 0;
        ret.level := 0;

        return ret;
    end;

    function reset_vrc7_audio(audio : vrc7_audio_t) return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
    begin
        ret := get_reset_vrc7_audio;
        ret.lfo_counter := audio.lfo_counter;
        ret.lfo_vib_counter := audio.lfo_vib_counter;

        return ret;
    end;

    function get_dot
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean
    )
    return opll_dot_t
    is
        variable ret : opll_dot_t;
    begin
        if clk_sync
        then
            ret := 2;
        else
            ret := audio.dot;
        end if;
        if audio.second
        then
            ret := ret + 3;
        end if;

        return ret;
    end;

    function is_vrc7_audio_step
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean
    )
    return boolean
    is
    begin
        return audio.clear = 0 and get_dot(audio, clk_sync) = STEP_EXP;
    end;

    -- The arithmetic shift right of a signed val, which rounds down. The
    -- shifts are of naturals, which synthesize as shifts, where those of
    -- integers that can be negative synthesize as dividers
    function sar(val : integer; n : natural) return integer
    is
    begin
        if val < 0
        then
            return -shift_right(-val - 1, n) - 1;
        end if;
        return shift_right(val, n);
    end;

    -- val * 2**n, as a case of constant shifts rather than a multiplier
    function shl(val : natural; n : natural range 0 to 7) return natural
    is
    begin
        case n is
            when 0 => return val;
            when 1 => return val * 2**1;
            when 2 => return val * 2**2;
            when 3 => return val * 2**3;
            when 4 => return val * 2**4;
            when 5 => return val * 2**5;
            when 6 => return val * 2**6;
            when 7 => return val * 2**7;
        end case;
    end;

    -- A bit of a natural
    function bit_set(val : natural; idx : natural) return boolean
    is
    begin
        return (val / 2**idx) mod 2 = 1;
    end;

    function patch_bits
    (
        patch  : opll_patch_t;
        idx    : natural;
        hi, lo : natural
    )
    return natural
    is
    begin
        return to_integer(patch(idx)(hi downto lo));
    end;

    -- What depends on the step alone. The divisions by 3 and 18 of the step
    -- would synthesize as dividers, so they are worked out once here
    type cycle_info_t is record
        -- The operator of the output (mod1), the phase (mod2) and the
        -- modulation (mod3) of the step is a modulator. The drums but the
        -- bass drum have no modulator
        mod1       : boolean;
        mod2       : boolean;
        mod3       : boolean;
        -- The operator after the step's is a carrier
        mcsel      : natural range 0 to 1;
        -- The output of the step is that of a carrier of channels 0-5
        heard      : boolean;
        -- The drum of the operator after the step's
        rm         : rm_select_t;
        -- The operator of three steps before, and the channel of the step
        slot_3     : opll_cycle_t;
        channel    : natural range 0 to 8;
        next_cycle : opll_cycle_t;
    end record;

    type cycle_info_arr_t is array(opll_cycle_t) of cycle_info_t;

    function get_cycle_info return cycle_info_arr_t
    is
        function is_mod(val : natural) return boolean
        is
        begin
            return (val / 3) mod 2 = 1;
        end;

        variable ret : cycle_info_arr_t;
    begin
        for c in opll_cycle_t loop
            ret(c).mod1 := c /= 15 and c /= 16 and is_mod(c + 1);
            ret(c).mod2 := c /= 13 and c /= 14 and is_mod(c + 3);
            ret(c).mod3 := c /= 16 and c /= 17 and is_mod(c);
            ret(c).mcsel := boolean'pos(is_mod(c + 1));
            ret(c).heard := not is_mod(c) and (c + 15) mod 18 < 12;
            if c >= 11 and c <= 16
            then
                ret(c).rm := c - 11;
            else
                ret(c).rm := RM_NONE;
            end if;
            ret(c).slot_3 := (c + 15) mod 18;
            ret(c).channel := c mod 9;
            ret(c).next_cycle := (c + 1) mod 18;
        end loop;

        return ret;
    end;

    constant CYCLE_INFO : cycle_info_arr_t := get_cycle_info;

    -- The patch of the operator after the step's
    function get_patch
    (
        audio : vrc7_audio_t;
        inst  : opll_nibble_t
    )
    return opll_patch_t
    is
        variable rm : rm_select_t;
    begin
        rm := CYCLE_INFO(audio.cycle).rm;
        if rm /= RM_NONE
        then
            return DRUM_ROM(rm);
        elsif inst = 0
        then
            return audio.patch;
        end if;
        return PATCH_ROM(inst);
    end;

    -- The register of the channel written by the data register this step,
    -- if any
    function is_reg_write(audio : vrc7_audio_t) return boolean
    is
    begin
        return audio.fm_data and not audio.write_a_en and
               audio.address mod 16 = audio.cycle and audio.cycle < 16 and
               audio.address / 16 >= 1 and audio.address / 16 <= 3;
    end;

    -- The phase bits of the hi-hat and top cymbal, taken in steps 13 and 17
    function take_rhythm_bits(audio : vrc7_audio_t) return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
        variable phase : opll_phase_t;
    begin
        ret := audio;
        phase := audio.rd_slot.phase;
        if audio.cycle = 13
        then
            ret.rm_hh_bit2 := bit_set(phase, 2 + 9);
            ret.rm_hh_bit3 := bit_set(phase, 3 + 9);
            ret.rm_hh_bit7 := bit_set(phase, 7 + 9);
            ret.rm_hh_bit8 := bit_set(phase, 8 + 9);
        elsif audio.cycle = 17
        then
            ret.rm_tc_bit3 := bit_set(phase, 3 + 9);
            ret.rm_tc_bit5 := bit_set(phase, 5 + 9);
        end if;

        return ret;
    end;

    -- The phase of the operator of the step, 10 bits, which the hi-hat,
    -- snare and top cymbal replace with noise and other phase bits
    function get_pg_out(audio : vrc7_audio_t) return natural
    is
        variable rm : vrc7_audio_t;
        variable rm_bit : boolean;
        variable noise : boolean;
    begin
        rm := take_rhythm_bits(audio);
        rm_bit := (rm.rm_hh_bit2 xor rm.rm_hh_bit7) or
                  (rm.rm_hh_bit3 xor rm.rm_tc_bit5) or
                  (rm.rm_tc_bit3 xor rm.rm_tc_bit5);
        noise := audio.rm_noise mod 2 = 1;

        case audio.cycle is
            when 13 =>
                if rm_bit xor noise
                then
                    return boolean'pos(rm_bit) * 2**9 + 16#D0#;
                end if;
                return boolean'pos(rm_bit) * 2**9 + 16#34#;
            when 16 =>
                return boolean'pos(rm.rm_hh_bit8) * 2**9 +
                       boolean'pos(rm.rm_hh_bit8 xor noise) * 2**8;
            when 17 =>
                return boolean'pos(rm_bit) * 2**9 + 2**8;
            when others =>
                return (audio.rd_slot.phase / 2**9) mod 2**10;
        end case;
    end;

    -- The phase of the operator of the step, after modulation and feedback,
    -- 10 bits. The log-sin of its low 8 bits, mirrored in the odd quarters
    -- of the wave, is looked up
    function get_op_phase(audio : vrc7_audio_t) return natural
    is
        variable op_mod : natural;
    begin
        op_mod := 0;
        if CYCLE_INFO(audio.cycle).mod3
        then
            op_mod := audio.op_mod * 2;
        end if;
        if CYCLE_INFO(audio.cycle).mod2 and audio.c_fb /= 0
        then
            -- ((fb1 + fb2) >> 1) >> (7 - fb), of which only the low 10 bits
            -- are used: those of the sum shifted as a natural
            op_mod := shift_right(wrap(audio.rd_slot.fb1 + audio.rd_slot.fb2,
                                       2**17-1),
                                  8 - audio.c_fb);
        end if;

        return wrap(op_mod + get_pg_out(audio), 2**10-1);
    end;

    -- The address in the log-sin table of a phase from get_op_phase
    function get_logsin_addr(phase : natural) return natural
    is
    begin
        if bit_set(phase, 8)
        then
            return 255 - phase mod 256;
        end if;
        return phase mod 256;
    end;

    -- The attenuation of the operator of the step before
    function get_exp_level(audio : vrc7_audio_t) return natural
    is
    begin
        return min_int(audio.op_logsin + audio.eg_out * 16, 2**12-1);
    end;

    -- 0x00-0x07, 0x0F
    function write_mode(audio : vrc7_audio_t) return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
        variable idx : natural range 0 to 15;
    begin
        ret := audio;
        idx := audio.mode_address mod 16;
        if audio.mode_address >= 16 and audio.write_d_en
        then
            if idx <= 7
            then
                ret.patch(idx) := audio.write_data;
            elsif idx = 14
            then
                ret.rhythm := to_integer(audio.write_data(5 downto 0));
                if ret.rhythm < 32
                then
                    ret.rhythm := ret.rhythm + 32;
                end if;
            elsif idx = 15
            then
                ret.testmode := to_integer(audio.write_data(3 downto 0));
            end if;
        end if;

        return ret;
    end;

    -- The patch and channel values of the operator after the step's, for
    -- the envelope
    function prepare_patch_1
    (
        audio : vrc7_audio_t;
        ch    : opll_channel_t;
        patch : opll_patch_t
    )
    return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
        variable mcsel : natural range 0 to 1;
    begin
        ret := audio;
        mcsel := CYCLE_INFO(audio.cycle).mcsel;

        if CYCLE_INFO(audio.cycle).rm = RM_HH or
           CYCLE_INFO(audio.cycle).rm = RM_TOM
        then
            ret.c_tl := ch.inst * 4;
        elsif mcsel = 1
        then
            ret.c_tl := ch.vol * 4;
        else
            ret.c_tl := patch_bits(patch, 2, 5, 0);
        end if;
        ret.c_ar := patch_bits(patch, 4 + mcsel, 7, 4);
        ret.c_dr := patch_bits(patch, 4 + mcsel, 3, 0);
        ret.c_rr := patch_bits(patch, 6 + mcsel, 3, 0);
        ret.c_et := patch(mcsel)(5) = '1';
        ret.c_ksr := patch(mcsel)(4) = '1';
        ret.c_ksl := patch_bits(patch, 2 + mcsel, 7, 6);
        ret.c_ksr_freq := ch.octave * 2 + ch.fnum / 2**8;
        ret.c_ksl_freq := ch.fnum / 2**5;
        ret.c_ksl_block := ch.octave;

        return ret;
    end;

    -- The patch and channel values of the operator after the step's, for
    -- the phase and operator
    function prepare_patch_2
    (
        audio : vrc7_audio_t;
        ch    : opll_channel_t;
        patch : opll_patch_t
    )
    return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
        variable mcsel : natural range 0 to 1;
    begin
        ret := audio;
        mcsel := CYCLE_INFO(audio.cycle).mcsel;

        ret.c_fnum := ch.fnum;
        ret.c_block := ch.octave;
        ret.c_multi := patch_bits(patch, mcsel, 3, 0);
        ret.c_sl := patch_bits(patch, 6 + mcsel, 7, 4);
        ret.c_fb := patch_bits(patch, 3, 2, 0);
        ret.c_vib := patch(mcsel)(6) = '1';
        ret.c_am := patch(mcsel)(7) = '1';
        ret.c_dc := (audio.c_dc * 2) mod 8 + patch_bits(patch, 3, 4, 4);
        ret.c_dm := (audio.c_dm * 2) mod 8 + patch_bits(patch, 3, 3, 3);

        return ret;
    end;

    -- The step of the envelope of the operator of two steps before, in
    -- decay, sustain or release
    function get_eg_step(audio : vrc7_audio_t) return natural
    is
        variable rate_hi : opll_nibble_t;
        variable inc_hi : boolean;
        variable prev_1 : boolean;
        variable prev_3 : boolean;
        variable i0 : boolean;
        variable i1 : boolean;
    begin
        rate_hi := audio.eg_rate_hi;
        inc_hi := audio.eg_inc_hi = 1;
        prev_1 := audio.eg_counter_state_prev mod 2 = 1;
        prev_3 := audio.eg_counter_state_prev = 3;

        i0 := rate_hi = 15 or (rate_hi = 14 and inc_hi);
        i1 := (rate_hi = 14 and not inc_hi) or (rate_hi = 13 and inc_hi) or
              (rate_hi = 13 and not inc_hi and prev_1) or
              (rate_hi = 12 and inc_hi and prev_1) or
              (rate_hi = 12 and not inc_hi and prev_3) or
              (audio.eg_inc_lo = 1 and prev_3);

        if i0 and i1
        then
            return 3;
        elsif i0
        then
            return 2;
        elsif i1
        then
            return 1;
        end if;
        return 0;
    end;

    function envelope_generate
    (
        audio : vrc7_audio_t;
        ch    : opll_channel_t;
        slot  : opll_slot_t
    )
    return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
        variable mcsel : natural range 0 to 1;
        variable timer_inc : natural range 0 to 1;
        variable timer_low : natural range 0 to 3;
        variable timer_bit : natural range 0 to 2;
        variable level : opll_level_t;
        variable next_level : opll_level_t;
        variable zero : boolean;
        variable state : opll_eg_state_t;
        variable next_state : opll_eg_state_t;
        variable step : integer range -128 to 3;
        variable shift : integer range -11 to 4;
        variable rate_hi : opll_nibble_t;
        variable rate_lo : natural range 0 to 3;
        variable sum : opll_nibble_t;
        variable state_rate : opll_eg_state_t;
        variable rate : opll_nibble_t;
        variable ksr : opll_nibble_t;
        variable kon_1 : boolean;
        variable off_1 : boolean;
    begin
        ret := audio;
        mcsel := CYCLE_INFO(audio.cycle).mcsel;

        -- The timer
        if audio.eg_counter_state /= 3
        then
            timer_inc := 0;
        elsif audio.cycle = 0
        then
            timer_inc := 1;
        else
            timer_inc := audio.eg_timer_carry;
        end if;
        timer_low := audio.eg_timer mod 4;
        timer_bit := audio.eg_timer mod 2 + timer_inc;
        ret.eg_timer_carry := timer_bit / 2;
        ret.eg_timer := (timer_bit mod 2) * 2**17 + audio.eg_timer / 2;
        if bit_set(audio.testmode, 3)
        then
            ret.eg_timer := ret.eg_timer mod 2**16 +
                            (ret.eg_timer / 2**17) * 2**17;
            if audio.write_data(2) = '1'
            then
                ret.eg_timer := ret.eg_timer + 2**16;
            end if;
        end if;
        if not audio.eg_timer_shift_stop and bit_set(ret.eg_timer, 16)
        then
            ret.eg_timer_shift := audio.cycle;
        end if;
        if audio.cycle = 0 and audio.eg_counter_state_prev mod 2 = 1
        then
            ret.eg_timer_low_lock := timer_low;
            if ret.eg_timer_shift > 13
            then
                ret.eg_timer_shift_lock := 0;
            else
                ret.eg_timer_shift_lock := ret.eg_timer_shift;
            end if;
            ret.eg_timer_shift := 0;
        end if;
        ret.eg_timer_shift_stop := audio.eg_timer_shift_stop or
                                   bit_set(ret.eg_timer, 16);
        if audio.cycle = 0
        then
            ret.eg_timer_shift_stop := false;
        end if;
        ret.eg_counter_state_prev := audio.eg_counter_state;
        if audio.cycle = 17
        then
            ret.eg_counter_state := wrap(audio.eg_counter_state + 1, 3);
        end if;

        -- The operator of two steps before
        level := audio.slot_2.level;
        next_level := level;
        zero := level = 0;
        ret.eg_silent := level = opll_level_t'high;

        if audio.slot_2.state /= EG_ATTACK and bit_set(audio.eg_off, 1) and
           not bit_set(audio.eg_dokon, 1)
        then
            next_level := opll_level_t'high;
        end if;
        if audio.eg_rate_hi = 15 and bit_set(audio.eg_dokon, 1)
        then
            next_level := 0;
        end if;

        state := audio.slot_2.state;
        step := 0;

        case state is
            when EG_ATTACK =>
                if audio.eg_rate_hi /= 15 and bit_set(audio.eg_kon, 1) and
                   not zero
                then
                    if audio.eg_rate_hi < 12
                    then
                        shift := audio.eg_inc_lo;
                    else
                        shift := audio.eg_rate_hi - 11 + audio.eg_inc_hi;
                    end if;
                    if shift > 0
                    then
                        -- ~level >> (5 - shift), rounding down
                        step := -shift_right(level, 5 - shift) - 1;
                    end if;
                end if;
                if zero
                then
                    next_state := EG_DECAY;
                else
                    next_state := EG_ATTACK;
                end if;
            when EG_DECAY =>
                if not bit_set(audio.eg_off, 1) and
                   not bit_set(audio.eg_dokon, 1) and
                   level / 8 /= audio.eg_sl
                then
                    step := get_eg_step(ret);
                end if;
                if level / 8 = audio.eg_sl
                then
                    next_state := EG_SUSTAIN;
                else
                    next_state := EG_DECAY;
                end if;
            when EG_SUSTAIN | EG_RELEASE =>
                if not bit_set(audio.eg_off, 1) and
                   not bit_set(audio.eg_dokon, 1)
                then
                    step := get_eg_step(ret);
                end if;
                next_state := state;
        end case;

        if not bit_set(audio.eg_kon, 1)
        then
            next_state := EG_RELEASE;
        end if;
        if bit_set(audio.eg_dokon, 1)
        then
            next_state := EG_ATTACK;
        end if;

        ret.slot_wr.level := next_level + step;
        ret.slot_wr.state := next_state;

        -- The rate of the operator of the step
        rate_hi := audio.eg_rate / 4;
        rate_lo := audio.eg_rate mod 4;
        -- eg_stephi
        case rate_lo is
            when 0 => ret.eg_inc_hi := 0;
            when 1 =>
                if ret.eg_timer_low_lock = 0
                then
                    ret.eg_inc_hi := 1;
                else
                    ret.eg_inc_hi := 0;
                end if;
            when 2 =>
                ret.eg_inc_hi := 1 - ret.eg_timer_low_lock mod 2;
            when 3 =>
                if ret.eg_timer_low_lock = 3
                then
                    ret.eg_inc_hi := 0;
                else
                    ret.eg_inc_hi := 1;
                end if;
        end case;
        sum := wrap(ret.eg_timer_shift_lock + rate_hi, 15);
        ret.eg_inc_lo := 0;
        if rate_hi < 12 and not audio.eg_zerorate
        then
            case sum is
                when 12 => ret.eg_inc_lo := 1;
                when 13 => ret.eg_inc_lo := rate_lo / 2;
                when 14 => ret.eg_inc_lo := rate_lo mod 2;
                when others => null;
            end case;
        end if;
        ret.eg_rate_hi := rate_hi;

        case CYCLE_INFO(audio.cycle).rm is
            when RM_BD0 | RM_BD1 => kon_1 := ch.kon or bit_set(audio.rhythm, 4);
            when RM_SD => kon_1 := ch.kon or bit_set(audio.rhythm, 3);
            when RM_TOM => kon_1 := ch.kon or bit_set(audio.rhythm, 2);
            when RM_TC => kon_1 := ch.kon or bit_set(audio.rhythm, 1);
            when RM_HH => kon_1 := ch.kon or bit_set(audio.rhythm, 0);
            when others => kon_1 := ch.kon;
        end case;
        off_1 := slot.level / 4 = 31;
        ret.eg_kon := (audio.eg_kon * 2) mod 4;
        if kon_1
        then
            ret.eg_kon := ret.eg_kon + 1;
        end if;
        ret.eg_off := (audio.eg_off * 2) mod 4;
        if off_1
        then
            ret.eg_off := ret.eg_off + 1;
        end if;

        rate := 0;
        ret.eg_dokon := (audio.eg_dokon * 2) mod 2**16;
        state_rate := slot.state;
        if state_rate = EG_RELEASE and kon_1 and off_1
        then
            state_rate := EG_ATTACK;
            ret.eg_dokon := ret.eg_dokon + 1;
        end if;
        case state_rate is
            when EG_ATTACK =>
                rate := audio.c_ar;
            when EG_DECAY =>
                rate := audio.c_dr;
            when EG_SUSTAIN =>
                if not audio.c_et
                then
                    rate := audio.c_rr;
                end if;
            when EG_RELEASE =>
                if ch.son
                then
                    rate := 5;
                else
                    rate := audio.c_rr;
                end if;
        end case;
        if not kon_1 and mcsel = 0 and
           CYCLE_INFO(audio.cycle).rm /= RM_TOM and
           CYCLE_INFO(audio.cycle).rm /= RM_HH
        then
            rate := 0;
        end if;
        if kon_1 and slot.state = EG_RELEASE and not off_1
        then
            rate := 12;
        end if;
        if not kon_1 and not ch.son and mcsel = 1 and not audio.c_et
        then
            rate := 7;
        end if;
        ret.eg_zerorate := rate = 0;
        ksr := audio.c_ksr_freq;
        if not audio.c_ksr
        then
            ksr := ksr / 4;
        end if;
        if rate * 4 + ksr >= 64
        then
            ret.eg_rate := 16#3C# + ksr mod 4;
        else
            ret.eg_rate := rate * 4 + ksr;
        end if;
        ret.eg_sl := audio.c_sl;

        return ret;
    end;

    function do_lfo(audio : vrc7_audio_t) return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
        variable vib_step : natural range 0 to 1;
        variable am_inc : natural range 0 to 1;
        variable am_bit : natural range 0 to 3;
    begin
        ret := audio;

        if audio.cycle = 17
        then
            vib_step := (audio.lfo_counter + 1) / 2**10;
            ret.lfo_am_step := (audio.lfo_counter mod 2**6) = 2**6 - 1;
            if bit_set(audio.testmode, 3)
            then
                vib_step := 1;
            end if;
            ret.lfo_vib_counter := wrap(audio.lfo_vib_counter + vib_step, 7);
            ret.lfo_counter := wrap(audio.lfo_counter + 1, 2**10-1);
        end if;

        am_inc := 0;
        if (ret.lfo_am_step or bit_set(audio.testmode, 3)) and
           audio.cycle < 9
        then
            if audio.lfo_am_dir or audio.cycle = 0
            then
                am_inc := 1;
            end if;
        end if;

        if audio.cycle >= 9
        then
            ret.lfo_am_car := 0;
        end if;

        if audio.cycle = 0
        then
            if audio.lfo_am_dir and audio.lfo_am_counter mod 2**7 = 0
            then
                ret.lfo_am_dir := false;
            elsif not audio.lfo_am_dir and bit_set(audio.lfo_am_counter, 0) and
                  bit_set(audio.lfo_am_counter, 3) and
                  bit_set(audio.lfo_am_counter, 5) and
                  bit_set(audio.lfo_am_counter, 6)
            then
                ret.lfo_am_dir := true;
            end if;
        end if;

        am_bit := audio.lfo_am_counter mod 2 + am_inc + ret.lfo_am_car;
        ret.lfo_am_car := am_bit / 2;
        ret.lfo_am_counter := (am_bit mod 2) * 2**8 + audio.lfo_am_counter / 2;

        if bit_set(audio.testmode, 1)
        then
            ret.lfo_vib_counter := 0;
            ret.lfo_counter := 0;
            ret.lfo_am_dir := false;
            ret.lfo_am_counter := ret.lfo_am_counter mod 2**8;
        end if;

        return ret;
    end;

    -- The data the data register writes to a channel register this step:
    -- that of a write sampled this step, else the last
    function get_reg_data(audio : vrc7_audio_t) return natural
    is
    begin
        if audio.fm_address and audio.write_d_en and not audio.write_a_en
        then
            return to_integer(audio.write_data);
        end if;
        return audio.data;
    end;

    -- A write of data to channel register addr, 0x10-0x3F
    function write_channel
    (
        ch   : opll_channel_t;
        addr : natural;
        data : natural
    )
    return opll_channel_t
    is
        variable ret : opll_channel_t;
    begin
        ret := ch;
        case addr / 16 is
            when 1 =>
                ret.fnum := (ch.fnum / 2**8) * 2**8 + data;
            when 2 =>
                ret.fnum := ch.fnum mod 2**8 + (data mod 2) * 2**8;
                ret.octave := (data / 2) mod 8;
                ret.kon := bit_set(data, 4);
                ret.son := bit_set(data, 5);
            when others =>
                ret.vol := data mod 16;
                ret.inst := data / 16;
        end case;

        return ret;
    end;

    -- Nuked-OPLL's OPLL_Clock
    function clock_opll
    (
        audio  : vrc7_audio_t;
        tables : vrc7_tables_t
    )
    return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
        variable c : opll_cycle_t;
        variable ch : opll_channel_t;
        variable slot : opll_slot_t;
        variable ismod : boolean;
        variable ismod1 : boolean;
        variable output : opll_out_t;
        variable freq : natural range 0 to 2**19-1;
        variable vib : natural range 0 to 7;
        variable ksl : integer range -64 to 128;
        variable ksl_level : natural range 0 to 128;
        variable eg_level : natural range 0 to 511;
        variable patch : opll_patch_t;
    begin
        ret := audio;
        c := audio.cycle;
        ch := audio.rd_channel;
        slot := audio.rd_slot;

        if c = 0
        then
            ret.lfo_am_out := (audio.lfo_am_counter / 8) mod 16;
        end if;

        ret := write_mode(ret);
        patch := get_patch(ret, ch.inst);
        ret := prepare_patch_1(ret, ch, patch);

        -- OPLL_Channel: the output of the operator of two steps before, if a
        -- carrier of channels 0-5
        ret.output_m := audio.ch_out;
        if audio.ch_out >= 0
        then
            ret.output_m := audio.ch_out + 1;
        end if;
        if not CYCLE_INFO(c).heard
        then
            ret.output_m := 0;
        end if;

        -- OPLL_PhaseGenerate. The phase of the operator of the step before
        -- is written in the next step, with its state
        ret.phase_wr := wrap(audio.pg_phase_next + audio.pg_inc, 2**19-1);
        ret.slot_wr.phase := audio.phase_wr;
        ismod := CYCLE_INFO(c).mod2;
        if bit_set(ret.testmode, 2) or
           (ismod and bit_set(audio.eg_dokon, 15)) or
           (not ismod and bit_set(audio.eg_dokon, 0))
        then
            ret.pg_phase_next := 0;
        else
            ret.pg_phase_next := slot.phase;
        end if;
        ret := take_rhythm_bits(ret);

        -- OPLL_Operator: the output of the operator of two steps before, the
        -- exponent of the step before and the log-sin of this step
        ismod1 := CYCLE_INFO(c).mod1;
        -- Silence and the half-wave rectification of the waveform shift by
        -- 12 or more, which leaves none of the 11 bits of the mantissa
        if audio.eg_silent or
           (bit_set(audio.op_neg, 1) and
            ((ismod1 and bit_set(audio.c_dm, 2)) or
             (not ismod1 and bit_set(audio.c_dc, 2))))
        then
            output := 0;
        else
            output := shift_right(audio.op_exp_m, audio.op_exp_s);
        end if;
        if not audio.eg_silent and bit_set(audio.op_neg, 1)
        then
            output := -output - 1;
        end if;

        ret.op_exp_m := tables.exp;
        ret.op_exp_s := audio.exp_level / 2**8;

        ret.op_logsin := tables.logsin;
        ret.op_neg := (audio.op_neg * 2) mod 4 + audio.phase_neg;

        ret.slot_wr.fb1 := audio.slot_2.fb1;
        ret.slot_wr.fb2 := audio.slot_2.fb2;
        if ismod1
        then
            ret.slot_wr.fb2 := audio.slot_2.fb1;
            ret.slot_wr.fb1 := output;
        end if;
        ret.op_mod := wrap(output, 2**9-1);

        if ismod1
        then
            ret.ch_out := 0;
        else
            ret.ch_out := sar(output, 3);
        end if;

        -- OPLL_PhaseCalcIncrement, for the operator of the step after
        -- The vibrato is added in the first half of its cycle and taken
        -- away in the second
        freq := audio.c_fnum * 2;
        vib := 0;
        if audio.c_vib
        then
            case audio.lfo_vib_counter mod 4 is
                when 1 | 3 => vib := freq / 2**8;
                when 2 => vib := freq / 2**7;
                when others => null;
            end case;
        end if;
        if audio.lfo_vib_counter >= 4
        then
            freq := freq - vib;
        else
            freq := freq + vib;
        end if;
        freq := shl(freq, audio.c_block) / 2;
        ret.pg_inc := (freq * PG_MULTI(audio.c_multi)) / 2;

        -- OPLL_EnvelopeOutput, of the operator of the step before
        eg_level := audio.slot_1.level + audio.eg_ksltl;
        if audio.c_am
        then
            eg_level := eg_level + ret.lfo_am_out;
        end if;
        eg_level := min_int(eg_level, opll_level_t'high);
        if bit_set(ret.testmode, 0)
        then
            eg_level := 0;
        end if;
        ret.eg_out := eg_level;

        -- OPLL_EnvelopeKSLTL
        ksl := EG_KSLTABLE(ret.c_ksl_freq) - (8 - ret.c_ksl_block) * 8;
        ksl_level := max(ksl, 0) * 2;
        if ret.c_ksl /= 0
        then
            ksl_level := shift_right(ksl_level, 3 - ret.c_ksl);
        else
            ksl_level := 0;
        end if;
        ret.eg_ksltl := ksl_level + ret.c_tl * 2;

        ret := envelope_generate(ret, ch, slot);
        ret := do_lfo(ret);

        -- OPLL_DoRhythm: the noise
        if bit_set(audio.rm_noise, 0) /= bit_set(audio.rm_noise, 14) or
           audio.rm_noise = 0 or bit_set(ret.testmode, 1)
        then
            ret.rm_noise := 2**22 + audio.rm_noise / 2;
        else
            ret.rm_noise := audio.rm_noise / 2;
        end if;

        ret := prepare_patch_2(ret, ch, patch);

        -- OPLL_DoRegWrite. The channel register is written to the RAM by
        -- get_vrc7_ram_data
        if audio.write_a_en
        then
            if audio.write_data(7 downto 6) = "00"
            then
                ret.fm_address := true;
                ret.address := to_integer(audio.write_data);
            else
                ret.fm_address := false;
            end if;
        end if;
        if ret.fm_address and audio.write_d_en
        then
            ret.data := to_integer(audio.write_data);
        end if;
        if audio.write_a_en
        then
            ret.fm_data := false;
        end if;
        if ret.fm_address and audio.write_d_en
        then
            ret.fm_data := true;
        end if;
        if audio.write_a_en
        then
            if audio.write_data(7 downto 4) = "0000"
            then
                ret.mode_address := 16 + to_integer(audio.write_data(3 downto 0));
            else
                ret.mode_address := 0;
            end if;
        end if;

        -- OPLL_DoIO
        ret.write_a_en := audio.write_a = 1;
        ret.write_d_en := audio.write_d = 1;
        ret.write_a := (audio.write_a * 2) mod 4;
        ret.write_d := (audio.write_d * 2) mod 4;

        ret.cycle := CYCLE_INFO(c).next_cycle;

        ret.slot_2 := audio.slot_1;
        ret.slot_1 := slot;

        if c = opll_cycle_t'high
        then
            ret.level := audio.sum + ret.output_m;
            ret.sum := 0;
        else
            ret.sum := audio.sum + ret.output_m;
        end if;

        return ret;
    end;

    function cycle_vrc7_audio
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean;
        ram_data : opll_ram_data_t;
        tables   : vrc7_tables_t
    )
    return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
        variable dot : opll_dot_t;
        variable phase : natural range 0 to 2**10-1;
    begin
        ret := audio;
        dot := get_dot(audio, clk_sync);

        if audio.clear > 0
        then
            -- The first step starts a CPU cycle pair
            if audio.clear > 1 or dot = STEP_EXP
            then
                ret.clear := audio.clear - 1;
            end if;
        else
            case dot is
                when STEP_CHANNEL =>
                    ret.rd_channel := from_channel_word(ram_data);
                when STEP_SLOT =>
                    ret.rd_slot := from_slot_word(ram_data);
                when STEP_WRITE =>
                    null;
                when STEP_OLD =>
                    ret.rd_old := from_channel_word(ram_data);
                    phase := get_op_phase(audio);
                    ret.logsin_addr := get_logsin_addr(phase);
                    ret.phase_neg := phase / 2**9;
                    ret.exp_level := get_exp_level(audio);
                when STEP_TABLES =>
                    null;
                when STEP_EXP =>
                    ret := clock_opll(audio, tables);
            end case;
        end if;

        if clk_sync
        then
            ret.dot := 0;
            ret.second := not audio.second;
        else
            ret.dot := 1;
        end if;

        return ret;
    end;

    function write_vrc7_audio
    (
        audio : vrc7_audio_t;
        port1 : boolean;
        data  : data_t
    )
    return vrc7_audio_t
    is
        variable ret : vrc7_audio_t;
    begin
        ret := audio;
        ret.write_data := data;
        if port1
        then
            ret.write_d := (audio.write_d / 2) * 2 + 1;
        else
            ret.write_a := (audio.write_a / 2) * 2 + 1;
        end if;

        return ret;
    end;

    function get_vrc7_ram_bus
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean
    )
    return opll_ram_bus_t
    is
        variable addr : natural range 0 to 2**opll_ram_addr_t'length - 1;
    begin
        if audio.clear > 0
        then
            return bus_write(to_std_logic_vector(audio.clear - 1,
                                                 opll_ram_addr_t'length));
        end if;

        case get_dot(audio, clk_sync) is
            when STEP_CHANNEL =>
                addr := RAM_CHANNEL + CH_OFFSET(audio.cycle);
            when STEP_SLOT =>
                addr := audio.cycle;
            when STEP_WRITE =>
                return bus_write(to_std_logic_vector(
                    CYCLE_INFO(audio.cycle).slot_3,
                    opll_ram_addr_t'length));
            when STEP_OLD =>
                if not is_reg_write(audio)
                then
                    return OPLL_RAM_BUS_IDLE;
                end if;
                addr := RAM_CHANNEL + CYCLE_INFO(audio.cycle).channel;
            when STEP_TABLES =>
                return OPLL_RAM_BUS_IDLE;
            when STEP_EXP =>
                if not is_reg_write(audio)
                then
                    return OPLL_RAM_BUS_IDLE;
                end if;
                return bus_write(to_std_logic_vector(
                    RAM_CHANNEL + CYCLE_INFO(audio.cycle).channel,
                    opll_ram_addr_t'length));
        end case;

        return bus_read(to_std_logic_vector(addr, opll_ram_addr_t'length));
    end;

    function get_vrc7_ram_data
    (
        audio    : vrc7_audio_t;
        clk_sync : boolean
    )
    return opll_ram_data_t
    is
    begin
        if audio.clear > 0
        then
            if audio.clear - 1 >= RAM_CHANNEL
            then
                return to_channel_word(RESET_CHANNEL);
            end if;
            return to_slot_word(RESET_SLOT);
        elsif get_dot(audio, clk_sync) = STEP_WRITE
        then
            return to_slot_word(audio.slot_wr);
        end if;
        return to_channel_word(write_channel(audio.rd_old,
                                             audio.address,
                                             get_reg_data(audio)));
    end;

    function get_vrc7_tables(audio : vrc7_audio_t) return vrc7_tables_t
    is
    begin
        return (logsin => LOGSIN_ROM(audio.logsin_addr),
                exp => EXP_ROM(audio.exp_level mod 2**8));
    end;

    function get_vrc7_audio_sum(audio : vrc7_audio_t) return opll_sum_t
    is
    begin
        return audio.level;
    end;

    function get_vrc7_audio_dac(audio : vrc7_audio_t) return opll_dac_t
    is
    begin
        return audio.output_m;
    end;

end package body;
