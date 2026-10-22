library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;

-- The audio of the Konami VRC6: two pulse channels and a sawtooth. Each has
-- a 12-bit period, in CPU cycles, and a divider that counts the period down
-- and clocks the channel when it wraps. The channels are summed by a linear
-- 6-bit DAC
package lib_vrc6_audio is

    subtype vrc6_period_t is natural range 0 to 2**12-1;

    type vrc6_pulse_t is record
        volume      : natural range 0 to 2**4-1;
        duty        : natural range 0 to 2**3-1;
        -- The volume is output at every step, whatever the duty
        ignore_duty : boolean;
        period      : vrc6_period_t;
        -- When clear, the divider and the steps stop and the output is 0
        enable      : boolean;
        -- The divider wraps after timer reaches 0
        timer       : vrc6_period_t;
        -- The volume is output while step is not above duty
        step        : natural range 0 to 2**4-1;
    end record;

    constant RESET_VRC6_PULSE : vrc6_pulse_t :=
    (
        volume => 0,
        duty => 0,
        ignore_duty => false,
        period => 0,
        enable => false,
        timer => 0,
        step => 0
    );

    type vrc6_saw_t is record
        -- Added to the accumulator every second of the 14 steps
        rate        : natural range 0 to 2**6-1;
        accumulator : natural range 0 to 2**8-1;
        period      : vrc6_period_t;
        -- When clear, the divider and the steps stop and the output is 0
        enable      : boolean;
        timer       : vrc6_period_t;
        step        : natural range 0 to 13;
    end record;

    constant RESET_VRC6_SAW : vrc6_saw_t :=
    (
        rate => 0,
        accumulator => 0,
        period => 0,
        enable => false,
        timer => 0,
        step => 0
    );

    -- The periods of all channels are shifted right by 0, 4 or 8 bits
    subtype vrc6_shift_t is natural range 0 to 8;

    type vrc6_audio_t is record
        pulse_1 : vrc6_pulse_t;
        pulse_2 : vrc6_pulse_t;
        saw     : vrc6_saw_t;
        -- The dividers and steps of all channels stop
        halt    : boolean;
        shift   : vrc6_shift_t;
    end record;

    constant RESET_VRC6_AUDIO : vrc6_audio_t :=
    (
        pulse_1 => RESET_VRC6_PULSE,
        pulse_2 => RESET_VRC6_PULSE,
        saw => RESET_VRC6_SAW,
        halt => false,
        shift => 0
    );

    -- The channel written by the registers at 0x9000, 0xA000 or 0xB000
    type vrc6_channel_t is
    (
        VRC6_PULSE_1,
        VRC6_PULSE_2,
        VRC6_SAW
    );

    -- The register of a channel: 0 for the volume, duty or rate, 1 for the
    -- low 8 bits of the period, 2 for its high 4 bits and the enable
    subtype vrc6_audio_reg_t is natural range 0 to 2;

    -- Clocks the channels for a CPU cycle
    function cycle_vrc6_audio
    (
        audio    : vrc6_audio_t;
        clk_sync : boolean
    )
    return vrc6_audio_t;

    function write_vrc6_channel
    (
        audio   : vrc6_audio_t;
        channel : vrc6_channel_t;
        reg     : vrc6_audio_reg_t;
        data    : data_t
    )
    return vrc6_audio_t;

    -- 0x9003. Bit 0 halts the channels, bit 1 shifts the periods right by
    -- 4 bits and bit 2, which overrides bit 1, by 8 bits
    function write_vrc6_frequency_control
    (
        audio : vrc6_audio_t;
        data  : data_t
    )
    return vrc6_audio_t;

    -- The level of the DAC, scaled to the units of the mixed audio
    function get_vrc6_audio_level(audio : vrc6_audio_t) return cart_audio_t;

end package lib_vrc6_audio;


package body lib_vrc6_audio is

    -- The divider counts the shifted period down to 0 and wraps when
    -- clocked at 0, so it wraps every shifted period + 1 cycles
    function get_shifted_period
    (
        period : vrc6_period_t;
        shift  : vrc6_shift_t
    )
    return vrc6_period_t
    is
    begin
        case shift is
            when 4 => return period / 2**4;
            when 8 => return period / 2**8;
            when others => return period;
        end case;
    end;

    -- As in Mesen, the steps count up from 0. On nesdev they count down
    -- from 15, which outputs the volume at the end of the cycle rather than
    -- at the start
    function cycle_pulse
    (
        pulse : vrc6_pulse_t;
        shift : vrc6_shift_t
    )
    return vrc6_pulse_t
    is
        variable ret : vrc6_pulse_t;
    begin
        ret := pulse;

        if pulse.enable
        then
            if pulse.timer = 0
            then
                ret.timer := get_shifted_period(pulse.period, shift);
                ret.step := wrap(pulse.step + 1, 2**4-1);
            else
                ret.timer := pulse.timer - 1;
            end if;
        end if;

        return ret;
    end;

    function cycle_saw
    (
        saw   : vrc6_saw_t;
        shift : vrc6_shift_t
    )
    return vrc6_saw_t
    is
        variable ret : vrc6_saw_t;
    begin
        ret := saw;

        if saw.enable
        then
            if saw.timer = 0
            then
                ret.timer := get_shifted_period(saw.period, shift);

                -- The accumulator is cleared on step 0 and the rate added
                -- on the even steps after it, 6 times in all
                if saw.step = 13
                then
                    ret.step := 0;
                    ret.accumulator := 0;
                else
                    ret.step := saw.step + 1;
                    if saw.step mod 2 = 1
                    then
                        ret.accumulator :=
                            wrap(saw.accumulator + saw.rate, 2**8-1);
                    end if;
                end if;
            else
                ret.timer := saw.timer - 1;
            end if;
        end if;

        return ret;
    end;

    function cycle_vrc6_audio
    (
        audio    : vrc6_audio_t;
        clk_sync : boolean
    )
    return vrc6_audio_t
    is
        variable ret : vrc6_audio_t;
    begin
        ret := audio;

        if clk_sync and not audio.halt
        then
            ret.pulse_1 := cycle_pulse(audio.pulse_1, audio.shift);
            ret.pulse_2 := cycle_pulse(audio.pulse_2, audio.shift);
            ret.saw := cycle_saw(audio.saw, audio.shift);
        end if;

        return ret;
    end;

    function set_period_low
    (
        period : vrc6_period_t;
        data   : data_t
    )
    return vrc6_period_t
    is
    begin
        return set_bits(period, 0, data);
    end;

    function set_period_high
    (
        period : vrc6_period_t;
        data   : data_t
    )
    return vrc6_period_t
    is
    begin
        return set_bits(period, 8, data(3 downto 0));
    end;

    function write_pulse
    (
        pulse : vrc6_pulse_t;
        reg   : vrc6_audio_reg_t;
        data  : data_t
    )
    return vrc6_pulse_t
    is
        variable ret : vrc6_pulse_t;
    begin
        ret := pulse;

        case reg is
            when 0 =>
                ret.volume := to_integer(data(3 downto 0));
                ret.duty := to_integer(data(6 downto 4));
                ret.ignore_duty := data(7) = '1';
            when 1 =>
                ret.period := set_period_low(pulse.period, data);
            when 2 =>
                ret.period := set_period_high(pulse.period, data);
                ret.enable := data(7) = '1';
                -- The steps start over when the channel is enabled again,
                -- but the divider does not
                if not ret.enable
                then
                    ret.step := 0;
                end if;
        end case;

        return ret;
    end;

    function write_saw
    (
        saw  : vrc6_saw_t;
        reg  : vrc6_audio_reg_t;
        data : data_t
    )
    return vrc6_saw_t
    is
        variable ret : vrc6_saw_t;
    begin
        ret := saw;

        case reg is
            when 0 =>
                ret.rate := to_integer(data(5 downto 0));
            when 1 =>
                ret.period := set_period_low(saw.period, data);
            when 2 =>
                ret.period := set_period_high(saw.period, data);
                ret.enable := data(7) = '1';
                -- The accumulator is held at 0 and the steps start over
                -- when the channel is enabled again, but the divider does
                -- not
                if not ret.enable
                then
                    ret.step := 0;
                    ret.accumulator := 0;
                end if;
        end case;

        return ret;
    end;

    function write_vrc6_channel
    (
        audio   : vrc6_audio_t;
        channel : vrc6_channel_t;
        reg     : vrc6_audio_reg_t;
        data    : data_t
    )
    return vrc6_audio_t
    is
        variable ret : vrc6_audio_t;
    begin
        ret := audio;

        case channel is
            when VRC6_PULSE_1 =>
                ret.pulse_1 := write_pulse(audio.pulse_1, reg, data);
            when VRC6_PULSE_2 =>
                ret.pulse_2 := write_pulse(audio.pulse_2, reg, data);
            when VRC6_SAW =>
                ret.saw := write_saw(audio.saw, reg, data);
        end case;

        return ret;
    end;

    function write_vrc6_frequency_control
    (
        audio : vrc6_audio_t;
        data  : data_t
    )
    return vrc6_audio_t
    is
        variable ret : vrc6_audio_t;
    begin
        ret := audio;

        ret.halt := data(0) = '1';
        if data(2) = '1'
        then
            ret.shift := 8;
        elsif data(1) = '1'
        then
            ret.shift := 4;
        else
            ret.shift := 0;
        end if;

        return ret;
    end;

    function get_pulse_level(pulse : vrc6_pulse_t) return natural
    is
    begin
        if pulse.enable and (pulse.ignore_duty or pulse.step <= pulse.duty)
        then
            return pulse.volume;
        else
            return 0;
        end if;
    end;

    function get_saw_level(saw : vrc6_saw_t) return natural
    is
    begin
        -- The high 5 bits of the accumulator
        if saw.enable
        then
            return saw.accumulator / 2**3;
        else
            return 0;
        end if;
    end;

    function get_vrc6_audio_level(audio : vrc6_audio_t) return cart_audio_t
    is
        variable level : natural range 0 to 61;
    begin
        level := get_pulse_level(audio.pulse_1) +
                 get_pulse_level(audio.pulse_2) +
                 get_saw_level(audio.saw);

        -- Mesen mixes each step of the DAC at 75, where the APU at its
        -- loudest is about 5000, so a step is 75 * 255 / 5000 = 3.825 here
        return (level * 245) / 2**6;
    end;

end package body;
