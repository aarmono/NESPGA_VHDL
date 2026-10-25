library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.chip_ram_bus_types.all;

-- The audio of the Namco 163: up to 8 channels that play 4-bit wavetable
-- samples out of the 128 bytes of chip RAM, which also holds the registers of
-- the channels, 8 bytes each from 0x40 for channel 0 to 0x78 for channel 7.
-- One channel is updated every 15 CPU cycles: its registers and a sample are
-- read from the RAM, its frequency is added to its phase, which is written
-- back, and its output is the sample times its volume. The enabled channels
-- are updated in turn from channel 7 down.
--
-- The chip outputs the channels one at a time. As in Mesen, the output here
-- is the average of the enabled channels instead, since the audio is sampled
-- without the low pass filter that hides the switching on a console.
--
-- The RAM is accessed once per PPU cycle. The CPU accesses it in the sync
-- cycle, and the update in the other two PPU cycles of the CPU cycle, over
-- the last 8 CPU cycles before the channel's output changes, which is when
-- Mesen updates the channel all at once
package lib_n163_audio is

    subtype n163_channel_t is natural range 0 to 7;

    -- The output of a channel: its sample, biased by -8, times its volume
    subtype n163_output_t is integer range -8 * 15 to 7 * 15;
    type n163_output_arr_t is array(n163_channel_t) of n163_output_t;
    -- An output offset to be positive
    subtype n163_level_t is natural range 0 to
                                          n163_output_t'high - n163_output_t'low;

    -- CPU cycles since the last update. A channel is updated in the CPU
    -- cycle that takes the count to 15
    subtype n163_count_t is natural range 0 to 14;

    subtype n163_freq_t is natural range 0 to 2**18-1;
    -- The 24-bit phase, with room for the frequency to be added to it. The
    -- high 8 bits are the position of the sample in the waveform
    subtype n163_phase_t is natural range 0 to 2**25-1;
    -- The length of the waveform, in samples, shifted left by up to 6 bits
    subtype n163_divisor_t is natural range 0 to 256 * 2**6;
    subtype n163_volume_t is natural range 0 to 15;

    type n163_audio_t is record
        -- Bit 6 of 0xE000. The count stops, so no channel is updated and the
        -- output is held
        disable  : boolean;
        -- One less than the number of enabled channels, which are channels 7
        -- down to 7 - channels. Bits 6-4 of 0x7F of the RAM, kept as the CPU
        -- writes it, since only the CPU writes 0x7F
        channels : n163_channel_t;
        count    : n163_count_t;
        -- Which of the two PPU cycles before the sync cycle this is
        dot      : natural range 0 to 1;
        -- The channel being updated
        channel  : n163_channel_t;

        -- The registers of the channel being updated, read from the RAM
        freq     : n163_freq_t;
        phase    : n163_phase_t;
        -- The phase is brought below the length of the waveform by
        -- subtracting the length shifted left by 6 down to 0 bits, when it
        -- is no larger, one shift per PPU cycle
        divisor  : n163_divisor_t;
        offset   : natural range 0 to 2**8-1;
        volume   : n163_volume_t;

        -- The output of each channel, from when it has its sample in its
        -- last update
        outputs  : n163_output_arr_t;
        -- The average of the enabled channels when the last was updated
        level    : n163_level_t;
    end record;

    -- Mesen mixes each step of the output at 20, where the APU at its
    -- loudest is about 5000, so a step is 20 * 255 / 5000 = 1.02 here, or
    -- N163_STEP / 2**8. The output is offset to keep the level positive
    constant N163_STEP : natural := 261;

    constant RESET_N163_AUDIO : n163_audio_t :=
    (
        disable => false,
        channels => 0,
        count => 0,
        dot => 0,
        channel => 7,

        freq => 0,
        phase => 0,
        divisor => 0,
        offset => 0,
        volume => 0,

        outputs => (others => 0),
        level => -n163_output_t'low
    );

    -- Updates the channels for a PPU cycle. data is what the RAM access
    -- of get_n163_ram_bus reads
    function cycle_n163_audio
    (
        audio    : n163_audio_t;
        clk_sync : boolean;
        data     : data_t
    )
    return n163_audio_t;

    -- The access of the RAM by the update in this PPU cycle, which is not
    -- the sync cycle, the CPU's
    function get_n163_ram_bus(audio : n163_audio_t) return chip_ram_bus_t;

    -- The data of a write by get_n163_ram_bus
    function get_n163_ram_data(audio : n163_audio_t) return data_t;

    -- The CPU writes data to the RAM at addr
    function write_n163_ram
    (
        audio : n163_audio_t;
        addr  : chip_ram_addr_t;
        data  : data_t
    )
    return n163_audio_t;

    -- The level of the output, scaled to the units of the mixed audio
    function get_n163_audio_level(audio : n163_audio_t) return cart_audio_t;

end package lib_n163_audio;


package body lib_n163_audio is

    -- The steps of an update, each a PPU cycle: 4 * count plus the PPU
    -- cycle within the CPU cycle, 2 for the sync cycle. 4 rather than 3
    -- makes the step a concatenation instead of an adder; step 3 of each CPU
    -- cycle never happens
    subtype n163_step_t is natural range 0 to 4 * n163_count_t'high + 2;

    -- The RAM is read and written in the first two PPU cycles of each CPU
    -- cycle: the frequency and length, the phase, the offset and volume, a
    -- sample, then the phase is written back
    constant STEP_FREQ_LO  : n163_step_t := 4 * 7;
    constant STEP_FREQ_MID : n163_step_t := 4 * 7 + 1;
    constant STEP_FREQ_HI  : n163_step_t := 4 * 8;
    constant STEP_PHASE_LO : n163_step_t := 4 * 8 + 1;
    constant STEP_PHASE_MID : n163_step_t := 4 * 9;
    constant STEP_PHASE_HI : n163_step_t := 4 * 9 + 1;
    -- The frequency is added to the phase, which is then brought below the
    -- length of the waveform
    constant STEP_ADD      : n163_step_t := 4 * 9 + 2;
    constant STEP_OFFSET   : n163_step_t := 4 * 10;
    constant STEP_VOLUME   : n163_step_t := 4 * 10 + 1;
    constant STEP_MOD_FIRST : n163_step_t := 4 * 10;
    constant STEP_MOD_LAST : n163_step_t := 4 * 12;
    -- The PPU cycles from STEP_MOD_FIRST to STEP_MOD_LAST, less one: the
    -- shifts of the length
    constant MOD_SHIFTS    : natural := 6;
    constant STEP_SAMPLE   : n163_step_t := 4 * 12 + 1;
    constant STEP_WRITE_LO : n163_step_t := 4 * 13;
    constant STEP_WRITE_MID : n163_step_t := 4 * 13 + 1;
    constant STEP_WRITE_HI : n163_step_t := 4 * 14;
    constant STEP_UPDATE   : n163_step_t := 4 * 14 + 2;

    function get_step
    (
        audio    : n163_audio_t;
        clk_sync : boolean
    )
    return n163_step_t
    is
    begin
        if clk_sync
        then
            return 4 * audio.count + 2;
        else
            return 4 * audio.count + audio.dot;
        end if;
    end;

    -- The address in the RAM of register idx of the channel being updated
    function get_reg_addr
    (
        audio : n163_audio_t;
        idx   : natural
    )
    return chip_ram_addr_t
    is
    begin
        return to_std_logic_vector(16#40# + 8 * audio.channel + idx,
                                   chip_ram_addr_t'length);
    end;

    -- The position in the waveform of the sample of the channel being
    -- updated, in 4-bit samples from the start of the RAM
    function get_sample_pos(audio : n163_audio_t) return natural
    is
    begin
        return wrap(audio.phase / 2**16 + audio.offset, 2**8-1);
    end;

    -- The average of the enabled channels. The sum is divided by the number
    -- of channels by multiplying by 2**13 over it, rounded up, which
    -- truncates exactly for every sum. Like the division in Mesen, it
    -- truncates towards zero, as integer division does
    function get_average(audio : n163_audio_t) return n163_output_t
    is
        type recip_arr_t is array(n163_channel_t) of natural;
        constant RECIP : recip_arr_t :=
            (8192, 4096, 2731, 2048, 1639, 1366, 1171, 1024);

        variable sum : integer range 8 * n163_output_t'low to
                                     8 * n163_output_t'high;
    begin
        sum := 0;
        for i in n163_channel_t
        loop
            if i >= 7 - audio.channels
            then
                sum := sum + audio.outputs(i);
            end if;
        end loop;

        return (sum * RECIP(audio.channels)) / 2**13;
    end;

    -- The channel updated after the one being updated
    function get_next_channel(audio : n163_audio_t) return n163_channel_t
    is
    begin
        if audio.channel <= 7 - audio.channels
        then
            return 7;
        else
            return audio.channel - 1;
        end if;
    end;

    function cycle_n163_audio
    (
        audio    : n163_audio_t;
        clk_sync : boolean;
        data     : data_t
    )
    return n163_audio_t
    is
        variable ret : n163_audio_t;
        variable step : n163_step_t;
        variable sample : natural range 0 to 15;
    begin
        ret := audio;

        if clk_sync
        then
            ret.dot := 0;
        else
            ret.dot := 1;
        end if;

        if not audio.disable
        then
            step := get_step(audio, clk_sync);

            case step is
                when STEP_FREQ_LO =>
                    ret.freq := set_bits(audio.freq, 0, data);
                when STEP_FREQ_MID =>
                    ret.freq := set_bits(audio.freq, 8, data);
                when STEP_FREQ_HI =>
                    ret.freq := set_bits(audio.freq, 16, data(1 downto 0));
                    ret.divisor := (256 - 4 * to_integer(data(7 downto 2))) *
                                   2**MOD_SHIFTS;
                when STEP_PHASE_LO =>
                    ret.phase := set_bits(audio.phase, 0, data);
                when STEP_PHASE_MID =>
                    ret.phase := set_bits(audio.phase, 8, data);
                when STEP_PHASE_HI =>
                    ret.phase := set_bits(audio.phase, 16, data);
                when STEP_ADD =>
                    ret.phase := audio.phase + audio.freq;
                when STEP_OFFSET =>
                    ret.offset := to_integer(data);
                when STEP_VOLUME =>
                    ret.volume := to_integer(data(3 downto 0));
                when STEP_SAMPLE =>
                    if get_sample_pos(audio) mod 2 = 0
                    then
                        sample := to_integer(data(3 downto 0));
                    else
                        sample := to_integer(data(7 downto 4));
                    end if;
                    ret.outputs(audio.channel) := (sample - 8) * audio.volume;
                when STEP_UPDATE =>
                    ret.level := get_average(audio) - n163_output_t'low;
                    ret.channel := get_next_channel(audio);
                when others =>
                    null;
            end case;

            if step >= STEP_MOD_FIRST and step <= STEP_MOD_LAST
            then
                if audio.phase / 2**16 >= audio.divisor
                then
                    ret.phase := audio.phase - audio.divisor * 2**16;
                end if;
                ret.divisor := audio.divisor / 2;
            end if;

            if clk_sync
            then
                if audio.count = n163_count_t'high
                then
                    ret.count := 0;
                else
                    ret.count := audio.count + 1;
                end if;
            end if;
        end if;

        return ret;
    end;

    function get_n163_ram_bus(audio : n163_audio_t) return chip_ram_bus_t
    is
    begin
        if audio.disable
        then
            return CHIP_RAM_BUS_IDLE;
        end if;

        case get_step(audio, false) is
            when STEP_FREQ_LO => return bus_read(get_reg_addr(audio, 0));
            when STEP_FREQ_MID => return bus_read(get_reg_addr(audio, 2));
            when STEP_FREQ_HI => return bus_read(get_reg_addr(audio, 4));
            when STEP_PHASE_LO => return bus_read(get_reg_addr(audio, 1));
            when STEP_PHASE_MID => return bus_read(get_reg_addr(audio, 3));
            when STEP_PHASE_HI => return bus_read(get_reg_addr(audio, 5));
            when STEP_OFFSET => return bus_read(get_reg_addr(audio, 6));
            when STEP_VOLUME => return bus_read(get_reg_addr(audio, 7));
            when STEP_SAMPLE =>
                return bus_read(to_std_logic_vector(get_sample_pos(audio) / 2,
                                                    chip_ram_addr_t'length));
            when STEP_WRITE_LO => return bus_write(get_reg_addr(audio, 1));
            when STEP_WRITE_MID => return bus_write(get_reg_addr(audio, 3));
            when STEP_WRITE_HI => return bus_write(get_reg_addr(audio, 5));
            when others => return CHIP_RAM_BUS_IDLE;
        end case;
    end;

    function get_n163_ram_data(audio : n163_audio_t) return data_t
    is
        variable phase_byte : natural range 0 to 2**8-1;
    begin
        case get_step(audio, false) is
            when STEP_WRITE_LO => phase_byte := get_bits(audio.phase, 7, 0);
            when STEP_WRITE_MID => phase_byte := get_bits(audio.phase, 15, 8);
            when others => phase_byte := get_bits(audio.phase, 23, 16);
        end case;

        return to_std_logic_vector(phase_byte, data_t'length);
    end;

    function write_n163_ram
    (
        audio : n163_audio_t;
        addr  : chip_ram_addr_t;
        data  : data_t
    )
    return n163_audio_t
    is
        variable ret : n163_audio_t;
    begin
        ret := audio;

        if addr = "1111111"
        then
            ret.channels := to_integer(data(6 downto 4));
        end if;

        return ret;
    end;

    function get_n163_audio_level(audio : n163_audio_t) return cart_audio_t
    is
    begin
        return (audio.level * N163_STEP) / 2**8;
    end;

end package body;
