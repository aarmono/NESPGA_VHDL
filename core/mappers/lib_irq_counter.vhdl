library IEEE;
use IEEE.std_logic_1164.all;
use work.nes_types.all;
use work.utilities.all;

-- The 16-bit counter of CPU cycles of the Sunsoft FME-7 and Sunsoft-3, the
-- Bandai FCG and LZ93D50, the Irem H3001, the Konami VRC3 and the Namco 163,
-- with the latch that some reload it from. Only one board is in use, so the
-- cartridge keeps one counter for all of them. The counter counts down from
-- 0 to 0xFFFF, or to the latch. The VRC3 and N163, whose counters count up,
-- keep them inverted. A board decides when the counter is clocked, when that
-- raises its IRQ and what the CPU writes to it
package lib_irq_counter is

    subtype irq_counter_value_t is natural range 0 to 2**16-1;

    type irq_counter_t is record
        count : irq_counter_value_t;
        latch : irq_counter_value_t;
    end record;

    constant RESET_IRQ_COUNTER : irq_counter_t :=
    (
        count => 0,
        latch => 0
    );

    -- The counter and the latch of the boards that keep them inverted, at 0
    constant RESET_INVERTED_IRQ_COUNTER : irq_counter_t :=
    (
        count => irq_counter_value_t'high,
        latch => irq_counter_value_t'high
    );

    -- The write of a CPU cycle to the counter or the latch
    type irq_counter_write_t is
    (
        IRQ_COUNTER_NO_WRITE,
        IRQ_COUNTER_COUNT_LOW,
        IRQ_COUNTER_COUNT_HIGH,
        IRQ_COUNTER_LATCH_LOW,
        IRQ_COUNTER_LATCH_HIGH,
        -- The nibbles of the latch, low first, from the low 4 bits of the
        -- data
        IRQ_COUNTER_LATCH_0,
        IRQ_COUNTER_LATCH_1,
        IRQ_COUNTER_LATCH_2,
        IRQ_COUNTER_LATCH_3,
        -- The counter is loaded from the latch
        IRQ_COUNTER_LOAD
    );

    -- What a board does to the counter in a CPU cycle
    type irq_counter_op_t is record
        -- The counter is decremented
        clock    : boolean;
        -- The counter is reloaded from the latch rather than decremented
        -- from 0
        reload   : boolean;
        -- Only the low 8 bits count and are reloaded
        low_byte : boolean;
        write    : irq_counter_write_t;
        -- The data is written inverted
        invert   : boolean;
    end record;

    constant IRQ_COUNTER_IDLE : irq_counter_op_t :=
    (
        clock => false,
        reload => false,
        low_byte => false,
        write => IRQ_COUNTER_NO_WRITE,
        invert => false
    );

    -- Clocks the counter, then makes the write of the CPU cycle, so the
    -- write is not undone by the clock
    function cycle_irq_counter
    (
        counter : irq_counter_t;
        op      : irq_counter_op_t;
        data    : data_t
    )
    return irq_counter_t;

end package lib_irq_counter;


package body lib_irq_counter is

    function cycle_irq_counter
    (
        counter : irq_counter_t;
        op      : irq_counter_op_t;
        data    : data_t
    )
    return irq_counter_t
    is
        variable ret : irq_counter_t;
        variable value : data_t;
    begin
        ret := counter;

        if op.clock
        then
            if op.low_byte and get_bits(counter.count, 7, 0) = 0
            then
                ret.count := get_bits(counter.count, 15, 8) * 2**8 +
                             get_bits(counter.latch, 7, 0);
            elsif counter.count = 0
            then
                if op.reload
                then
                    ret.count := counter.latch;
                else
                    ret.count := irq_counter_value_t'high;
                end if;
            else
                ret.count := counter.count - 1;
            end if;
        end if;

        value := data;
        if op.invert
        then
            value := not data;
        end if;

        case op.write is
            when IRQ_COUNTER_NO_WRITE =>
            when IRQ_COUNTER_COUNT_LOW =>
                ret.count := set_bits(ret.count, 0, value);
            when IRQ_COUNTER_COUNT_HIGH =>
                ret.count := set_bits(ret.count, 8, value);
            when IRQ_COUNTER_LATCH_LOW =>
                ret.latch := set_bits(counter.latch, 0, value);
            when IRQ_COUNTER_LATCH_HIGH =>
                ret.latch := set_bits(counter.latch, 8, value);
            when IRQ_COUNTER_LATCH_0 =>
                ret.latch := set_bits(counter.latch, 0, value(3 downto 0));
            when IRQ_COUNTER_LATCH_1 =>
                ret.latch := set_bits(counter.latch, 4, value(3 downto 0));
            when IRQ_COUNTER_LATCH_2 =>
                ret.latch := set_bits(counter.latch, 8, value(3 downto 0));
            when IRQ_COUNTER_LATCH_3 =>
                ret.latch := set_bits(counter.latch, 12, value(3 downto 0));
            when IRQ_COUNTER_LOAD =>
                ret.count := counter.latch;
        end case;

        return ret;
    end;

end package body;
