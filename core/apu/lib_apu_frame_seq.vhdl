library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_frame_seq is

    subtype frame_seq_count_t is natural range 0 to 2**16-1;
    subtype frame_seq_mode_t is natural range 0 to 1;
    subtype frame_seq_step_t is unsigned(2 downto 0);

    type frame_seq_event is record
        count : frame_seq_count_t;
        env   : boolean;
        len   : boolean;
        irq   : boolean;
    end record;

    type frame_seq_event_arr_t is array(0 to 6) of frame_seq_event;
    type frame_seq_mode_arr_t is array(0 to 1) of frame_seq_event_arr_t;

    -- Values from Mesen
    constant FRAME_SEQ_COUNT_MODE_0 : frame_seq_event_arr_t :=
    (
        (
            -- 7457 cycles run
            count => 7456,
            env => true,
            len => false,
            irq => false
        ),
        (
            -- 14913 cycles run
            count => 14912,
            env => true,
            len => true,
            irq => false
        ),
        (
            -- 22371 cycles run
            count => 22370,
            env => true,
            len => false,
            irq => false
        ),
        (
            -- 29828 cycles run
            count => 29827,
            env => false,
            len => false,
            irq => true
        ),
        (
            -- 29829 cycles run
            count => 29828,
            env => true,
            len => true,
            irq => true
        ),
        (
            -- 29830 cycles run
            count => 29829,
            env => false,
            len => false,
            irq => true
        ),
        -- Pseudo entry used for writes to $4017
        (
            count => frame_seq_count_t'high,
            env => false,
            len => false,
            irq => false
        )
    );

    constant FRAME_SEQ_COUNT_MODE_1 : frame_seq_event_arr_t :=
    (
        (
            count => 7456,
            env => true,
            len => false,
            irq => false
        ),
        (
            count => 14912,
            env => true,
            len => true,
            irq => false
        ),
        (
            count => 22370,
            env => true,
            len => false,
            irq => false
        ),
        (
            count => 29828,
            env => false,
            len => false,
            irq => false
        ),
        (
            count => 37280,
            env => true,
            len => true,
            irq => false
        ),
        (
            count => 37281,
            env => false,
            len => false,
            irq => false
        ),
        -- Pseudo entry used for writes to $4017
        (
            count => frame_seq_count_t'high,
            env => true,
            len => true,
            irq => false
        )
    );

    constant FRAME_SEQ_COUNTS : frame_seq_mode_arr_t :=
    (
        FRAME_SEQ_COUNT_MODE_0,
        FRAME_SEQ_COUNT_MODE_1
    );

    type frame_seq_t is record
        count       : frame_seq_count_t;
        mode        : frame_seq_mode_t;
        irq_disable : boolean;
        irq_active  : boolean;
    end record;

    constant RESET_FRAME_SEQ : frame_seq_t :=
    (
      count => 0,
      mode => 0,
      irq_disable => false,
      irq_active => false
    );

    function update_envelope(seq : frame_seq_t) return boolean;

    function update_length(seq : frame_seq_t) return boolean;

    function assert_frame_irq(seq : frame_seq_t) return boolean;

    function update_frame_irq(seq : frame_seq_t) return frame_seq_t;

    function clear_frame_irq(seq : frame_seq_t) return frame_seq_t;

    function frame_irq_active(seq : frame_seq_t) return boolean;

    function next_sequence(cur_val : frame_seq_t) return frame_seq_t;

    function write_reg
    (
        val       : frame_seq_t;
        reg       : std_logic_vector(1 downto 0);
        odd_cycle : boolean
    )
    return frame_seq_t;
        
end lib_apu_frame_seq;

package body lib_apu_frame_seq is

    function update_envelope(seq : frame_seq_t) return boolean
    is
        variable ret : boolean;
        variable idx : integer;
    begin
        idx := seq.mode;
        ret := false;

        for i in frame_seq_event_arr_t'range
        loop
            if seq.count = FRAME_SEQ_COUNTS(idx)(i).count
            then
                ret := FRAME_SEQ_COUNTS(idx)(i).env;
            end if;
        end loop;

        return ret;
    end;

    function update_length(seq : frame_seq_t) return boolean
    is
        variable ret : boolean;
        variable idx : integer;
    begin
        idx := seq.mode;
        ret := false;

        for i in frame_seq_event_arr_t'range
        loop
            if seq.count = FRAME_SEQ_COUNTS(idx)(i).count
            then
                ret := FRAME_SEQ_COUNTS(idx)(i).len;
            end if;
        end loop;

        return ret;
    end;

    function frame_irq_active(seq : frame_seq_t) return boolean
    is
    begin
        return seq.irq_active;
    end;

    function assert_frame_irq(seq : frame_seq_t) return boolean
    is
        variable irq : boolean;
        variable idx : integer;
    begin
        idx := seq.mode;
        irq := false;

        for i in frame_seq_event_arr_t'range
        loop
            if seq.count = FRAME_SEQ_COUNTS(idx)(i).count
            then
                irq := FRAME_SEQ_COUNTS(idx)(i).irq;
            end if;
        end loop;

        return irq and not seq.irq_disable;
    end;

    function update_frame_irq(seq : frame_seq_t) return frame_seq_t
    is
        variable ret : frame_seq_t;
    begin
        ret := seq;
        if assert_frame_irq(seq)
        then
            ret.irq_active := true;
        end if;

        return ret;
    end;

    function clear_frame_irq(seq : frame_seq_t) return frame_seq_t
    is
        variable ret : frame_seq_t;
    begin
        ret := seq;
        ret.irq_active := false;

        return ret;
    end;

    function next_sequence(cur_val : frame_seq_t) return frame_seq_t
    is
        variable next_val : frame_seq_t;
        variable idx : integer;
    begin
        next_val := cur_val;
        idx := cur_val.mode;

        if cur_val.count = FRAME_SEQ_COUNTS(idx)(5).count or
           cur_val.count = FRAME_SEQ_COUNTS(idx)(6).count
        then
            next_val.count := 0;
        else
            next_val.count := cur_val.count + 1;
        end if;

        return next_val;
    end;

    function write_reg
    (
        val       : frame_seq_t;
        reg       : std_logic_vector(1 downto 0);
        odd_cycle : boolean
    )
    return frame_seq_t
    is
        variable ret : frame_seq_t;
        variable idx : integer;
        variable offset : natural range 2 to 3;
    begin
        ret := val;
        if reg(1) = '1'
        then
            ret.mode := 1;
        else
            ret.mode := 0;
        end if;
        ret.irq_disable := reg(0) = '1';

        -- The frame interrupt flag... can be cleared either by
        -- reading $4015 (which also returns its old status) or by
        -- setting the interrupt inhibit flag.
        if ret.irq_disable
        then
            ret.irq_active := false;
        end if;

        -- If the write occurs during an APU cycle, the effects occur 3 CPU
        -- cycles after the $4017 write cycle, and if the write occurs between
        -- APU cycles, the effects occurs 4 CPU cycles after the write cycle.
        --
        -- DMA reads occur on even CPU cycles, so the write is between APU cycles
        -- when it occurs on an even cycle.
        --
        -- Since the frame sequencer pseudo-entry takes 1 clock cycle, offset
        -- by 2 or 3 from the pseudo-entry
        if odd_cycle
        then
            offset := 2;
        else
            offset := 3;
        end if;

        -- If the mode flag is set, the sequencer is immediately clocked once
        idx := ret.mode;
        ret.count := FRAME_SEQ_COUNTS(idx)(6).count - offset;

        return ret;
    end;
    
end package body;