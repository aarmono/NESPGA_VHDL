library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_apu_envelope.all;
use work.lib_apu_length.all;
use work.lib_apu_square.all;

-- The audio of the Nintendo MMC5: two pulse channels like those of the APU
-- and an 8-bit PCM DAC. The pulses have no sweep unit and are not silenced
-- by periods below 8, and their envelopes and length counters are clocked
-- at a fixed 240 Hz, so the length counters run twice as fast as those of
-- the APU. The output of every channel is inverted relative to the APU
package lib_mmc5_audio is

    -- CPU cycles between the 240 Hz clocks of the envelopes and length
    -- counters: the NTSC CPU clock / 240, as in Mesen
    constant MMC5_FRAME_PERIOD : natural := 7457;

    -- The level of the 8-bit PCM DAC
    subtype mmc5_pcm_t is natural range 0 to 2**8-1;

    type mmc5_audio_t is record
        pulse_1        : square_t;
        pulse_2        : square_t;
        frame_timer    : natural range 0 to MMC5_FRAME_PERIOD-1;
        -- 0x5010: the DAC is set by CPU reads of 0x8000-0xBFFF rather than
        -- writes to 0x5011, and the PCM IRQ is enabled
        pcm_read_mode  : boolean;
        pcm_irq_enable : boolean;
        -- The last value given to the DAC was 0, which leaves the DAC
        -- unchanged
        pcm_irq        : boolean;
        pcm            : mmc5_pcm_t;
    end record;

    -- The PCM DAC is 0 at power on, as in Mesen. nesdev has seen an MMC5A
    -- power on at 0xEF or 0xFF, which only adds a constant level
    constant RESET_MMC5_AUDIO : mmc5_audio_t :=
    (
        pulse_1 => RESET_SQUARE,
        pulse_2 => RESET_SQUARE,
        frame_timer => 0,
        pcm_read_mode => false,
        pcm_irq_enable => false,
        pcm_irq => false,
        pcm => 0
    );

    -- The register of a CPU access to 0x5000-0x5015, from its low 5 bits
    subtype mmc5_audio_reg_t is natural range 0 to 31;

    -- Clocks the channels for a CPU cycle, then makes a write to a
    -- register in the same cycle
    function cycle_mmc5_audio
    (
        audio    : mmc5_audio_t;
        clk_sync : boolean;
        write    : boolean;
        reg      : mmc5_audio_reg_t;
        data     : data_t
    )
    return mmc5_audio_t;

    -- A CPU read of 0x8000-0xBFFF in PCM read mode gives the DAC the data
    -- read
    function read_mmc5_pcm
    (
        audio : mmc5_audio_t;
        data  : data_t
    )
    return mmc5_audio_t;

    -- A CPU read of 0x5010 acknowledges the PCM IRQ
    function ack_mmc5_pcm_irq(audio : mmc5_audio_t) return mmc5_audio_t;

    -- The data of a CPU read of 0x5010
    function get_mmc5_pcm_status(audio : mmc5_audio_t) return data_t;

    -- The data of a CPU read of 0x5015
    function get_mmc5_pulse_status(audio : mmc5_audio_t) return data_t;

    function get_mmc5_pcm_irq(audio : mmc5_audio_t) return boolean;

    -- The level of the channels, inverted and scaled to the units of the
    -- mixed audio
    function get_mmc5_audio_level(audio : mmc5_audio_t) return cart_audio_t;

end package lib_mmc5_audio;


package body lib_mmc5_audio is

    -- The highest level of the channels, scaled to the units of the mixed
    -- audio. The inverted output is this less the level
    constant MMC5_AUDIO_MAX : cart_audio_t := 625;

    -- The PCM IRQ is raised when the DAC is given 0, which does not change
    -- it, and cleared when it is given any other value
    function set_pcm
    (
        audio : mmc5_audio_t;
        data  : data_t
    )
    return mmc5_audio_t
    is
        variable ret : mmc5_audio_t;
    begin
        ret := audio;

        ret.pcm_irq := is_zero(data);
        if not ret.pcm_irq
        then
            ret.pcm := to_integer(data);
        end if;

        return ret;
    end;

    -- A write to a pulse register, 0 to 3. The second, the sweep of the
    -- APU, has no effect
    function write_pulse
    (
        pulse         : square_t;
        reg           : natural;
        data          : data_t;
        update_length : boolean
    )
    return square_t
    is
    begin
        case reg is
            when 0 => return write_reg_0(pulse, data);
            when 2 => return write_reg_2(pulse, data);
            when 3 => return write_reg_3(pulse, data, update_length);
            when others => return pulse;
        end case;
    end;

    function cycle_mmc5_audio
    (
        audio    : mmc5_audio_t;
        clk_sync : boolean;
        write    : boolean;
        reg      : mmc5_audio_reg_t;
        data     : data_t
    )
    return mmc5_audio_t
    is
        variable ret : mmc5_audio_t;
        variable tick : boolean;
    begin
        ret := audio;

        if clk_sync
        then
            -- The sweep is never enabled, so the increment of its negate is
            -- unused
            tick := audio.frame_timer = 0;
            ret.pulse_1 := next_square(audio.pulse_1, tick, tick, 0);
            ret.pulse_2 := next_square(audio.pulse_2, tick, tick, 0);
            if tick
            then
                ret.frame_timer := MMC5_FRAME_PERIOD - 1;
            else
                ret.frame_timer := audio.frame_timer - 1;
            end if;

            if write
            then
                case reg is
                    when 16#00# to 16#03# =>
                        ret.pulse_1 := write_pulse(ret.pulse_1, reg, data, tick);
                    when 16#04# to 16#07# =>
                        ret.pulse_2 := write_pulse(ret.pulse_2, reg - 4, data, tick);
                    when 16#10# =>
                        ret.pcm_read_mode := data(0) = '1';
                        ret.pcm_irq_enable := data(7) = '1';
                    when 16#11# =>
                        if not audio.pcm_read_mode
                        then
                            ret := set_pcm(ret, data);
                        end if;
                    when 16#15# =>
                        ret.pulse_1 := write_reg_4(ret.pulse_1, data(0));
                        ret.pulse_2 := write_reg_4(ret.pulse_2, data(1));
                    when others =>
                        null;
                end case;
            end if;
        end if;

        return ret;
    end;

    function read_mmc5_pcm
    (
        audio : mmc5_audio_t;
        data  : data_t
    )
    return mmc5_audio_t
    is
    begin
        if audio.pcm_read_mode
        then
            return set_pcm(audio, data);
        else
            return audio;
        end if;
    end;

    function ack_mmc5_pcm_irq(audio : mmc5_audio_t) return mmc5_audio_t
    is
        variable ret : mmc5_audio_t;
    begin
        ret := audio;
        ret.pcm_irq := false;

        return ret;
    end;

    function get_mmc5_pcm_irq(audio : mmc5_audio_t) return boolean
    is
    begin
        return audio.pcm_irq and audio.pcm_irq_enable;
    end;

    -- Bit 0 of 0x5010 reading back the mode is nesdev's guess; Mesen reads
    -- 0
    function get_mmc5_pcm_status(audio : mmc5_audio_t) return data_t
    is
    begin
        return to_std_logic(get_mmc5_pcm_irq(audio)) & "000000" &
               to_std_logic(audio.pcm_read_mode);
    end;

    function get_mmc5_pulse_status(audio : mmc5_audio_t) return data_t
    is
    begin
        return "000000" &
               get_status(audio.pulse_2) &
               get_status(audio.pulse_1);
    end;

    -- The volume of a pulse while its step of the duty is high and its
    -- length counter is not 0. Unlike the APU, a period below 8 does not
    -- silence it
    function get_pulse_level(pulse : square_t) return audio_t
    is
    begin
        if enable_output(pulse.seq) and enable_output(pulse.length)
        then
            return get_audio(pulse.envelope);
        else
            return 0;
        end if;
    end;

    function get_mmc5_audio_level(audio : mmc5_audio_t) return cart_audio_t
    is
        variable level : natural range 0 to 2 * audio_t'high + mmc5_pcm_t'high;
    begin
        level := get_pulse_level(audio.pulse_1) +
                 get_pulse_level(audio.pulse_2) +
                 audio.pcm;

        -- Mesen mixes each step at 43, where the APU at its loudest is
        -- about 5000, so a step is 43 * 255 / 5000 = 2.193 here. The pulses
        -- at their loudest match the APU pulses, as nesdev says
        return MMC5_AUDIO_MAX - (level * 281) / 2**7;
    end;

end package body;
