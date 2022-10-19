library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;
use work.utilities.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_frame_seq is

    subtype frame_seq_div_t is unsigned(12 downto 0);
    subtype frame_seq_step_t is unsigned(2 downto 0);

    type frame_seq_t is record
        divider     : frame_seq_div_t;
        mode_5      : boolean;
        irq_disable : boolean;
        step        : frame_seq_step_t;
    end record;

    constant RESET_FRAME_SEQ : frame_seq_t :=
    (
      divider => (others => '0'),
      mode_5 => false,
      irq_disable => false,
      step => (others => '0')
    );

    function update_envelope(seq : frame_seq_t) return boolean;

    function update_length(seq : frame_seq_t) return boolean;

    function assert_irq(seq : frame_seq_t) return boolean;

    function next_sequence(cur_val : frame_seq_t) return frame_seq_t;

    function write_reg
    (
        val : frame_seq_t;
        reg : std_logic_vector(1 downto 0)
    )
    return frame_seq_t;

    constant DIV_START : frame_seq_div_t :=
        to_unsigned(7456, frame_seq_div_t'length);
        
end lib_apu_frame_seq;

package body lib_apu_frame_seq is

    function update_envelope(seq : frame_seq_t) return boolean
    is
    begin
        return seq.divider = ZERO(seq.divider) and
               seq.step <= "011";
    end;

    function update_length(seq : frame_seq_t) return boolean
    is
    begin
        return seq.divider = ZERO(seq.divider) and
               ((not seq.mode_5 and (seq.step = "001" or seq.step = "011")) or
                (seq.mode_5 and (seq.step = "000" or seq.step = "010")));
    end;

    function assert_irq(seq : frame_seq_t) return boolean
    is
    begin
        return not seq.mode_5 and
               seq.step = "011" and
               not seq.irq_disable and
               seq.divider = ZERO(seq.divider);
    end;

    function next_sequence(cur_val : frame_seq_t) return frame_seq_t
    is
        variable next_val : frame_seq_t;
    begin
        next_val := cur_val;
        if cur_val.divider = ZERO(cur_val.divider)
        then
            next_val.divider := DIV_START;
            if (not cur_val.mode_5 and cur_val.step = "011") or
               (cur_val.mode_5 and cur_val.step = "100")
            then
                next_val.step := ZERO(cur_val.step);
            else
                next_val.step := cur_val.step + "1";
            end if;
        else
            next_val.divider := cur_val.divider - "1";
        end if;

        return next_val;
    end;

    function write_reg
    (
        val : frame_seq_t;
        reg : std_logic_vector(1 downto 0)
    )
    return frame_seq_t
    is
        variable ret : frame_seq_t;
    begin
        ret := val;
        ret.mode_5 := reg(1) = '1';
        ret.irq_disable := reg(0) = '1';
        ret.step := "000";
        -- If the mode flag is set, the sequencer is immediately clocked once
        if ret.mode_5
        then
            ret.divider := ZERO(val.divider);
        else
            ret.divider := DIV_START;
        end if;

        return ret;
    end;
    
end package body;