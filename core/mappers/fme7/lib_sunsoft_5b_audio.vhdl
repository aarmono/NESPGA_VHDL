library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;

-- The audio of the Sunsoft 5B (s5b), a YM2149F with its SEL pin low, as on
-- nesdev: three square wave tone channels, and a noise generator and an
-- envelope generator that any of the channels can use. The CPU selects one of
-- 16 registers at 0xC000 and writes it at 0xE000.
--
-- The generators are clocked every 16 CPU cycles. Each counts up until the
-- count reaches its period, so that a period of 0 is the same as 1, then
-- resets the count and steps. None of them can be halted. Each channel puts
-- out a 5-bit level, the 4-bit volume or the envelope, through a logarithmic
-- DAC of 1.5 dB per step, and the three are summed.
--
-- Mesen has the tone channels only, with the 4-bit volume at 3 dB per step,
-- which gives the same levels as the 5-bit volume here
package lib_sunsoft_5b_audio is

    subtype s5b_reg_num_t is natural range 0 to 15;

    -- CPU cycles since the generators were last clocked
    subtype s5b_prescale_t is natural range 0 to 15;

    subtype s5b_tone_period_t is natural range 0 to 2**12-1;
    subtype s5b_noise_period_t is natural range 0 to 2**5-1;
    subtype s5b_env_period_t is natural range 0 to 2**16-1;

    -- A level of the DAC. 0 and 1 are silent
    subtype s5b_level_t is natural range 0 to 2**5-1;
    subtype s5b_volume_t is natural range 0 to 2**4-1;

    subtype s5b_channel_num_t is natural range 0 to 2;

    type s5b_channel_t is record
        period    : s5b_tone_period_t;
        count     : s5b_tone_period_t;
        -- The square wave, which flips each time the count reaches the
        -- period
        tone      : boolean;
        -- Bits of 0x07. With both set the channel is the constant level of
        -- its volume
        tone_off  : boolean;
        noise_off : boolean;
        volume    : s5b_volume_t;
        -- The volume is that of the envelope
        envelope  : boolean;
    end record;

    constant RESET_S5B_CHANNEL : s5b_channel_t :=
    (
        period => 0,
        count => 0,
        tone => false,
        tone_off => false,
        noise_off => false,
        volume => 0,
        envelope => false
    );

    type s5b_channel_arr_t is array(s5b_channel_num_t) of s5b_channel_t;

    -- A 17-bit linear feedback shift register with taps at bits 16 and 13,
    -- shifted right here, so the taps are bits 0 and 3 and the output bit 0
    subtype s5b_lfsr_t is natural range 0 to 2**17-1;

    type s5b_noise_t is record
        period : s5b_noise_period_t;
        count  : s5b_noise_period_t;
        -- The register is shifted every second time the count reaches the
        -- period, so the noise is half the frequency of a tone
        half   : boolean;
        lfsr   : s5b_lfsr_t;
    end record;

    constant RESET_S5B_NOISE : s5b_noise_t :=
    (
        period => 0,
        count => 0,
        half => false,
        lfsr => 1
    );

    type s5b_envelope_t is record
        period    : s5b_env_period_t;
        count     : s5b_env_period_t;
        -- Counts down from the top of the ramp
        step      : s5b_level_t;
        -- The level is the step inverted, so the ramp goes up. Set by the
        -- attack bit and flipped by the alternate bit at the end of a ramp
        invert    : boolean;
        -- At the end of a ramp the level holds rather than ramping again
        hold      : boolean;
        alternate : boolean;
        holding   : boolean;
    end record;

    -- The shape at reset is a ramp down that holds at 0
    constant RESET_S5B_ENVELOPE : s5b_envelope_t :=
    (
        period => 0,
        count => 0,
        step => s5b_level_t'high,
        invert => false,
        hold => true,
        alternate => false,
        holding => false
    );

    type s5b_audio_t is record
        -- The register selected by 0xC000
        reg_num      : s5b_reg_num_t;
        -- Writes to 0xE000 are ignored unless the high 4 bits of the last
        -- 0xC000 write are 0
        write_enable : boolean;
        prescale     : s5b_prescale_t;
        channels     : s5b_channel_arr_t;
        noise        : s5b_noise_t;
        envelope     : s5b_envelope_t;
    end record;

    constant RESET_S5B_AUDIO : s5b_audio_t :=
    (
        reg_num => 0,
        write_enable => true,
        prescale => 0,
        channels => (others => RESET_S5B_CHANNEL),
        noise => RESET_S5B_NOISE,
        envelope => RESET_S5B_ENVELOPE
    );

    -- Clocks the generators for a CPU cycle
    function cycle_s5b_audio
    (
        audio    : s5b_audio_t;
        clk_sync : boolean
    )
    return s5b_audio_t;

    -- 0xC000
    function write_s5b_select
    (
        audio : s5b_audio_t;
        data  : data_t
    )
    return s5b_audio_t;

    -- 0xE000
    function write_s5b_data
    (
        audio : s5b_audio_t;
        data  : data_t
    )
    return s5b_audio_t;

    -- The sum of the levels of the channels, scaled to the units of the mixed
    -- audio
    function get_s5b_audio_level(audio : s5b_audio_t) return cart_audio_t;

end package lib_sunsoft_5b_audio;


package body lib_sunsoft_5b_audio is

    -- Whether the count of a generator reaches its period this clock
    function reaches_period(count, period : natural) return boolean
    is
    begin
        return count + 1 >= period;
    end;

    function cycle_channel(channel : s5b_channel_t) return s5b_channel_t
    is
        variable ret : s5b_channel_t;
    begin
        ret := channel;

        if reaches_period(channel.count, channel.period)
        then
            ret.count := 0;
            ret.tone := not channel.tone;
        else
            ret.count := channel.count + 1;
        end if;

        return ret;
    end;

    function cycle_noise(noise : s5b_noise_t) return s5b_noise_t
    is
        variable ret : s5b_noise_t;
        variable feedback : natural range 0 to 1;
    begin
        ret := noise;

        if reaches_period(noise.count, noise.period)
        then
            ret.count := 0;
            ret.half := not noise.half;

            if noise.half
            then
                feedback := (noise.lfsr mod 2 + get_bits(noise.lfsr, 3, 3))
                            mod 2;
                ret.lfsr := noise.lfsr / 2 + feedback * 2**16;
            end if;
        else
            ret.count := noise.count + 1;
        end if;

        return ret;
    end;

    function cycle_envelope(envelope : s5b_envelope_t) return s5b_envelope_t
    is
        variable ret : s5b_envelope_t;
    begin
        ret := envelope;

        if not envelope.holding
        then
            if reaches_period(envelope.count, envelope.period)
            then
                ret.count := 0;

                if envelope.step /= 0
                then
                    ret.step := envelope.step - 1;
                else
                    -- The end of a ramp
                    if envelope.alternate
                    then
                        ret.invert := not envelope.invert;
                    end if;

                    if envelope.hold
                    then
                        ret.holding := true;
                    else
                        ret.step := s5b_level_t'high;
                    end if;
                end if;
            else
                ret.count := envelope.count + 1;
            end if;
        end if;

        return ret;
    end;

    function cycle_s5b_audio
    (
        audio    : s5b_audio_t;
        clk_sync : boolean
    )
    return s5b_audio_t
    is
        variable ret : s5b_audio_t;
    begin
        ret := audio;

        if clk_sync
        then
            if audio.prescale = s5b_prescale_t'high
            then
                ret.prescale := 0;

                for i in s5b_channel_num_t loop
                    ret.channels(i) := cycle_channel(audio.channels(i));
                end loop;
                ret.noise := cycle_noise(audio.noise);
                ret.envelope := cycle_envelope(audio.envelope);
            else
                ret.prescale := audio.prescale + 1;
            end if;
        end if;

        return ret;
    end;

    function write_s5b_select
    (
        audio : s5b_audio_t;
        data  : data_t
    )
    return s5b_audio_t
    is
        variable ret : s5b_audio_t;
    begin
        ret := audio;

        ret.reg_num := to_integer(data(3 downto 0));
        ret.write_enable := data(7 downto 4) = "0000";

        return ret;
    end;

    -- 0x0D. Restarts the envelope with the shape written. A shape that does
    -- not continue is the same as one that continues and holds at 0, which
    -- is the end of the ramp down or the inverted end of the ramp up
    function write_shape
    (
        envelope : s5b_envelope_t;
        data     : data_t
    )
    return s5b_envelope_t
    is
        variable ret : s5b_envelope_t;
    begin
        ret := envelope;

        ret.invert := data(2) = '1';
        if data(3) = '1'
        then
            ret.hold := data(0) = '1';
            ret.alternate := data(1) = '1';
        else
            ret.hold := true;
            ret.alternate := data(2) = '1';
        end if;

        ret.count := 0;
        ret.step := s5b_level_t'high;
        ret.holding := false;

        return ret;
    end;

    function write_s5b_data
    (
        audio : s5b_audio_t;
        data  : data_t
    )
    return s5b_audio_t
    is
        variable ret : s5b_audio_t;
        variable channel : s5b_channel_num_t;
    begin
        ret := audio;

        if audio.write_enable
        then
            case audio.reg_num is
                when 0 to 5 =>
                    channel := audio.reg_num / 2;
                    if audio.reg_num mod 2 = 0
                    then
                        ret.channels(channel).period :=
                            set_bits(audio.channels(channel).period, 0, data);
                    else
                        ret.channels(channel).period :=
                            set_bits(audio.channels(channel).period,
                                     8,
                                     data(3 downto 0));
                    end if;
                when 6 =>
                    ret.noise.period := to_integer(data(4 downto 0));
                when 7 =>
                    for i in s5b_channel_num_t loop
                        ret.channels(i).tone_off := data(i) = '1';
                        ret.channels(i).noise_off := data(i + 3) = '1';
                    end loop;
                when 8 to 10 =>
                    channel := audio.reg_num - 8;
                    ret.channels(channel).volume :=
                        to_integer(data(3 downto 0));
                    ret.channels(channel).envelope := data(4) = '1';
                when 11 =>
                    ret.envelope.period :=
                        set_bits(audio.envelope.period, 0, data);
                when 12 =>
                    ret.envelope.period :=
                        set_bits(audio.envelope.period, 8, data);
                when 13 =>
                    ret.envelope := write_shape(audio.envelope, data);
                -- The I/O ports, which the 5B does not have
                when 14 to 15 =>
                    null;
            end case;
        end if;

        return ret;
    end;

    -- The DAC, at 1.5 dB per level from 0 at level 1. Mesen mixes the 5B at
    -- 15 per unit of a volume table that is 1.1885**30 = 177.8 at level 31,
    -- where the APU at its loudest is about 5000, so level 31 is
    -- 177.8 * 15 * 255 / 5000 = 136 here
    type s5b_dac_t is array(s5b_level_t) of natural range 0 to 136;

    constant S5B_DAC : s5b_dac_t :=
    (
        0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4, 4, 5, 6, 7, 9,
        10, 12, 14, 17, 20, 24, 29, 34, 41, 48, 57, 68, 81, 96, 114, 136
    );

    function get_envelope_level(envelope : s5b_envelope_t) return s5b_level_t
    is
    begin
        if envelope.invert
        then
            return invert(envelope.step, s5b_level_t'high);
        else
            return envelope.step;
        end if;
    end;

    function get_channel_level
    (
        channel  : s5b_channel_t;
        noise    : s5b_noise_t;
        envelope : s5b_envelope_t
    )
    return natural
    is
        variable level : s5b_level_t;
    begin
        -- The 4-bit volume is the 5-bit level with its low bit set
        if channel.envelope
        then
            level := get_envelope_level(envelope);
        else
            level := channel.volume * 2 + 1;
        end if;

        if (channel.tone or channel.tone_off) and
           (noise.lfsr mod 2 = 1 or channel.noise_off)
        then
            return S5B_DAC(level);
        else
            return 0;
        end if;
    end;

    function get_s5b_audio_level(audio : s5b_audio_t) return cart_audio_t
    is
        variable level : natural range 0 to 3 * 136;
    begin
        level := 0;
        for i in s5b_channel_num_t loop
            level := level + get_channel_level(audio.channels(i),
                                                audio.noise,
                                                audio.envelope);
        end loop;

        return level;
    end;

end package body;
