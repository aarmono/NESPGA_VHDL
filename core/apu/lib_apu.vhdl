library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.apu_bus_types.all;
use work.cpu_bus_types.all;
use work.utilities.all;
use work.lib_apu_frame_seq.all;
use work.lib_apu_square.all;
use work.lib_apu_triangle.all;
use work.lib_apu_noise.all;
use work.lib_apu_dmc.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu is

    type reg_t is record
        frame_seq : frame_seq_t;
        square_1  : square_t;
        square_2  : square_t;
        triangle  : triangle_t;
        dmc       : dmc_t;
        noise     : noise_t;
        frame_irq : boolean;
        dmc_irq   : boolean;
    end record;
    
    constant RESET_REG : reg_t :=
    (
        frame_seq => RESET_FRAME_SEQ,
        square_1 => RESET_SQUARE,
        square_2 => RESET_SQUARE,
        triangle => RESET_TRIANGLE,
        dmc => RESET_DMC,
        noise => RESET_NOISE,
        frame_irq => false,
        dmc_irq => false
    );

    type apu_output_t is record
        reg          : reg_t;
        audio        : apu_out_t;
        cpu_data_out : data_t;
        dma_bus      : cpu_bus_t;
        irq          : boolean;
        ready        : boolean;
    end record;

    function cycle_apu
    (
        reg         : reg_t;
        cpu_bus     : apu_bus_t;
        cpu_data_in : data_t;
        reset       : boolean;
        odd_cycle   : boolean
    )
    return apu_output_t;

end lib_apu;

package body lib_apu is

    function cycle_apu
    (
        reg         : reg_t;
        cpu_bus     : apu_bus_t;
        cpu_data_in : data_t;
        reset       : boolean;
        odd_cycle   : boolean
    )
    return apu_output_t
    is
        -- Internal variables
        variable v_audio           : apu_out_t;
        variable v_update_envelope : boolean;
        variable v_update_length   : boolean;
        variable v_reg             : reg_t;
        variable v_cpu_data_out    : data_t;
        variable v_ready           : boolean;
        variable v_frame_irq       : boolean;
        variable v_dmc_irq         : boolean;
        variable v_dma_bus         : cpu_bus_t;

        -- Return value
        variable ret : apu_output_t;
    begin
        v_cpu_data_out   := (others => '-');
        v_reg            := reg;
        v_audio.square_1 := get_audio(reg.square_1, "0");
        v_audio.square_2 := get_audio(reg.square_2, "1");
        v_audio.triangle := get_audio(reg.triangle);
        v_audio.noise    := get_audio(reg.noise);
        v_audio.dmc      := get_audio(reg.dmc);
        
        v_ready := assert_ready(reg.dmc);
        
        v_dma_bus := get_dma_bus(reg.dmc);
        
        v_update_envelope := update_envelope(reg.frame_seq);
        v_update_length := update_length(reg.frame_seq);
        
        v_reg.triangle := next_triangle(reg.triangle,
                                        v_update_envelope,
                                        v_update_length);
        v_reg.square_1 := next_square(reg.square_1,
                                      v_update_envelope,
                                      v_update_length,
                                      "0");
        v_reg.square_2 := next_square(reg.square_2,
                                      v_update_envelope,
                                      v_update_length,
                                      "1");
        v_reg.noise := next_noise(reg.noise,
                                  v_update_envelope,
                                  v_update_length);
        v_reg.dmc := next_dmc(reg.dmc, cpu_data_in);
        v_reg.frame_seq := next_sequence(reg.frame_seq);
        
        -- Memory map {
        if is_bus_write(cpu_bus)
        then
            case cpu_bus.address is
                -- Square Channel 1
                -- $4000
                when "00000" =>
                    v_reg.square_1 := write_reg_0(v_reg.square_1, cpu_data_in);
                -- $4001
                when "00001" =>
                    v_reg.square_1 := write_reg_1(v_reg.square_1, cpu_data_in);
                -- $4002
                when "00010" =>
                    v_reg.square_1 := write_reg_2(v_reg.square_1, cpu_data_in);
                -- $4003
                when "00011" =>
                    v_reg.square_1 := write_reg_3(v_reg.square_1, cpu_data_in);

                -- Square Channel 2
                -- $4004
                when "00100" =>
                    v_reg.square_2 := write_reg_0(v_reg.square_2, cpu_data_in);
                -- $4005
                when "00101" =>
                    v_reg.square_2 := write_reg_1(v_reg.square_2, cpu_data_in);
                -- $4006
                when "00110" =>
                    v_reg.square_2 := write_reg_2(v_reg.square_2, cpu_data_in);
                -- $4007
                when "00111" =>
                    v_reg.square_2 := write_reg_3(v_reg.square_2, cpu_data_in);

                -- Triangle Channel
                -- Linear Counter registers
                -- $4008
                when "01000" =>
                    v_reg.triangle := write_reg_0(v_reg.triangle, cpu_data_in);
                -- Timer period low
                -- $400A
                when "01010" =>
                    v_reg.triangle := write_reg_1(v_reg.triangle, cpu_data_in);
                -- Timer period high and length counter reload
                -- $400B
                when "01011" =>
                    v_reg.triangle := write_reg_2(v_reg.triangle, cpu_data_in);

                -- Noise Channel
                -- $400C
                when "01100" =>
                    v_reg.noise := write_reg_0(v_reg.noise, cpu_data_in);
                -- $400E
                when "01110" =>
                    v_reg.noise := write_reg_1(v_reg.noise, cpu_data_in);
                -- $400F
                when "01111" =>
                    v_reg.noise := write_reg_2(v_reg.noise, cpu_data_in);

                -- DMC Channel
                -- $4010
                when "10000" =>
                    v_reg.dmc := write_reg_0(v_reg.dmc, cpu_data_in);
                    -- If the new interrupt enabled status is clear, the
                    -- interrupt flag is cleared.
                    if cpu_data_in(7) = '0'
                    then
                        v_reg.dmc_irq := false;
                    end if;
                -- $4011
                when "10001" =>
                    v_reg.dmc := write_reg_1(v_reg.dmc, cpu_data_in);
                -- $4012
                when "10010" =>
                    v_reg.dmc := write_reg_2(v_reg.dmc, cpu_data_in);
                -- $4013
                when "10011" =>
                    v_reg.dmc := write_reg_3(v_reg.dmc, cpu_data_in);

                -- Common
                -- $4015
                when "10101" =>
                    v_reg.square_1 := write_reg_4(reg.square_1, cpu_data_in(0));
                    v_reg.square_2 := write_reg_4(reg.square_2, cpu_data_in(1));
                    v_reg.triangle := write_reg_3(reg.triangle, cpu_data_in(2));
                    v_reg.noise := write_reg_3(reg.noise, cpu_data_in(3));
                    v_reg.dmc := write_reg_4(reg.dmc, cpu_data_in(4));

                -- Frame Sequencer
                -- $4017
                when "10111" =>
                    v_reg.frame_seq := write_reg(v_reg.frame_seq, 
                                                 cpu_data_in(7 downto 6),
                                                 odd_cycle);
                    -- The frame interrupt flag... can be cleared either by
                    -- reading $4015 (which also returns its old status) or by
                    -- setting the interrupt inhibit flag.
                    if cpu_data_in(6) = '1'
                    then
                        v_reg.frame_irq := false;
                    end if;
                when others =>
            end case;
        elsif is_bus_read(cpu_bus) and
              cpu_bus.address = "10101"
        then
            v_cpu_data_out := 
            (
                7 => to_std_logic(reg.dmc_irq),
                6 => to_std_logic(reg.frame_irq),
                4 => get_status(reg.dmc),
                3 => get_status(reg.noise),
                2 => get_status(reg.triangle),
                1 => get_status(reg.square_2),
                0 => get_status(reg.square_1),
                others => '0'
            );
            -- The frame interrupt flag... can be cleared either by
            -- reading $4015 (which also returns its old status) or by
            -- setting the interrupt inhibit flag.
            v_reg.frame_irq := false;
        end if;
        -- }

        if assert_irq(v_reg.frame_seq)
        then
            v_reg.frame_irq := true;
        end if;
        
        if assert_irq(v_reg.dmc)
        then
            v_reg.dmc_irq := true;
        end if;
        
        if reset then
            v_reg := RESET_REG;
        end if;
        
        ret.reg := v_reg;
        ret.audio := v_audio;
        ret.cpu_data_out := v_cpu_data_out;
        ret.ready := v_ready;
        ret.irq := reg.frame_irq or reg.dmc_irq;
        ret.dma_bus := v_dma_bus;

        return ret;
    end;

end package body;