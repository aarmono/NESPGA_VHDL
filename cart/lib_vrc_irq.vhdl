library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;

-- The IRQ counter of the Konami VRC4, VRC6 and VRC7. An 8-bit counter counts
-- up and raises an IRQ when it wraps, reloading itself from a latch. It is
-- clocked every CPU cycle in cycle mode, or in scanline mode by a prescaler
-- that divides the CPU cycles by 114, 114 and 113 in turn, which is 113+2/3
-- cycles: an NTSC scanline
package lib_vrc_irq is

    subtype vrc_irq_count_t is natural range 0 to 2**8-1;

    -- The prescaler starts at 341 and is decremented by 3 every CPU cycle.
    -- The counter is clocked when it would drop to 0 or below, and 341 is
    -- added to it
    constant VRC_IRQ_PRESCALER_START : natural := 341;
    subtype vrc_irq_prescaler_t is natural range 0 to VRC_IRQ_PRESCALER_START;

    type vrc_irq_t is record
        latch            : vrc_irq_count_t;
        count            : vrc_irq_count_t;
        prescaler        : vrc_irq_prescaler_t;
        -- Copied to enable when the IRQ is acknowledged
        enable_after_ack : boolean;
        -- The prescaler and the counter are clocked
        enable           : boolean;
        -- The counter is clocked every CPU cycle rather than by the
        -- prescaler
        cycle_mode       : boolean;
        irq              : boolean;
    end record;

    constant RESET_VRC_IRQ : vrc_irq_t :=
    (
        latch => 0,
        count => 0,
        prescaler => 0,
        enable_after_ack => false,
        enable => false,
        cycle_mode => false,
        irq => false
    );

    -- The write of a CPU cycle to the registers of the counter
    type vrc_irq_write_t is
    (
        VRC_IRQ_NO_WRITE,
        -- The VRC6 and VRC7 write the latch a byte at a time. The VRC4
        -- writes its low or high nibble from the low 4 bits of the data
        VRC_IRQ_LATCH,
        VRC_IRQ_LATCH_LOW,
        VRC_IRQ_LATCH_HIGH,
        -- Bit 0 enables the IRQ after it is acknowledged, bit 1 enables it
        -- now and bit 2 selects cycle mode. Acknowledges the IRQ and, when
        -- it is enabled, reloads the counter and resets the prescaler
        VRC_IRQ_CONTROL,
        -- Acknowledges the IRQ and enables it if bit 0 of the control was
        -- set
        VRC_IRQ_ACK
    );

    -- Clocks the prescaler and the counter for a CPU cycle, then makes the
    -- write of that cycle, so a write to the control is not undone by the
    -- clock
    function cycle_vrc_irq
    (
        irq      : vrc_irq_t;
        clk_sync : boolean;
        write    : vrc_irq_write_t;
        data     : data_t
    )
    return vrc_irq_t;

end package lib_vrc_irq;


package body lib_vrc_irq is

    function clock_vrc_irq
    (
        irq      : vrc_irq_t;
        clk_sync : boolean
    )
    return vrc_irq_t
    is
        variable ret : vrc_irq_t;
        variable clock : boolean;
    begin
        ret := irq;

        if clk_sync and irq.enable
        then
            clock := irq.cycle_mode;
            if irq.prescaler <= 3
            then
                ret.prescaler := irq.prescaler + VRC_IRQ_PRESCALER_START - 3;
                clock := true;
            else
                ret.prescaler := irq.prescaler - 3;
            end if;

            if clock
            then
                if irq.count = vrc_irq_count_t'high
                then
                    ret.count := irq.latch;
                    ret.irq := true;
                else
                    ret.count := irq.count + 1;
                end if;
            end if;
        end if;

        return ret;
    end;

    function write_vrc_irq_control
    (
        irq  : vrc_irq_t;
        data : data_t
    )
    return vrc_irq_t
    is
        variable ret : vrc_irq_t;
    begin
        ret := irq;

        ret.enable_after_ack := data(0) = '1';
        ret.enable := data(1) = '1';
        ret.cycle_mode := data(2) = '1';
        ret.irq := false;

        if ret.enable
        then
            ret.count := irq.latch;
            ret.prescaler := VRC_IRQ_PRESCALER_START;
        end if;

        return ret;
    end;

    function cycle_vrc_irq
    (
        irq      : vrc_irq_t;
        clk_sync : boolean;
        write    : vrc_irq_write_t;
        data     : data_t
    )
    return vrc_irq_t
    is
        variable ret : vrc_irq_t;
    begin
        ret := clock_vrc_irq(irq, clk_sync);

        case write is
            when VRC_IRQ_NO_WRITE =>
            when VRC_IRQ_LATCH =>
                ret.latch := to_integer(data);
            when VRC_IRQ_LATCH_LOW =>
                ret.latch := set_bits(ret.latch, 0, data(3 downto 0));
            when VRC_IRQ_LATCH_HIGH =>
                ret.latch := set_bits(ret.latch, 4, data(3 downto 0));
            when VRC_IRQ_CONTROL =>
                ret := write_vrc_irq_control(ret, data);
            when VRC_IRQ_ACK =>
                ret.enable := ret.enable_after_ack;
                ret.irq := false;
        end case;

        return ret;
    end;

end package body;
