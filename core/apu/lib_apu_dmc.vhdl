library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;

-- This file heavily quotes Blargg's NES APU Sound Hardware Reference:
-- https://www.nesdev.org/apu_ref.txt
package lib_apu_dmc is

subtype dmc_data_t is unsigned(data_t'range);
    
    type dma_buffer_t is record
        data  : dmc_data_t;
        valid : boolean;
    end record;
    
    constant RESET_DMA_BUFFER : dma_buffer_t :=
    (
        data => (others => '0'),
        valid => false
    );
    
    subtype dma_addr_t is unsigned(cpu_addr_t'range);
    subtype dma_remainder_t is unsigned(11 downto 0);
    
    type dma_xfer_t is record
        address         : dma_addr_t;
        bytes_remaining : dma_remainder_t;
    end record;
    
    constant RESET_DMA_XFER : dma_xfer_t :=
    (
        address => (others => '0'),
        bytes_remaining => (others => '0')
    );
    
    subtype dma_length_t is unsigned(7 downto 0);
    subtype dma_start_t is unsigned(7 downto 0);
    
    type dma_parms_t is record
        start_address : dma_start_t;
        dma_length    : dma_length_t;
    end record;
    
    constant RESET_DMA_PARMS : dma_parms_t :=
    (
        start_address => (others => '0'),
        dma_length => (others => '0')
    );
    
    function update_dma_xfer_vals
    (
        cur_vals     : dma_xfer_t;
        dma_parms    : dma_parms_t;
        loop_enabled : boolean
    )
    return dma_xfer_t;
    
    function init_dma_xfer_vals(dma_parms : dma_parms_t) return dma_xfer_t;
    
    type dma_state_t is
    (
        DMA_IDLE,
        DMA_READ_REQ,
        -- A reload DMA scheduled just after playback stopped. It halts
        -- the CPU for one cycle and is then aborted
        DMA_ABORT
    );
    
    subtype dma_delay_t is unsigned(1 downto 0);
    -- Halt and dummy cycles completed before the DMA read can happen
    subtype dma_halt_t is natural range 0 to 2;
    
    type dma_t is record
        -- Current state (whether idle or reading data)
        state          : dma_state_t;
        -- Current DMA xfer values (current address and bytes remaining)
        dma_xfer_vals  : dma_xfer_t;
        -- DMA xfer parms (memory-mapped)
        dma_xfer_parms : dma_parms_t;
        -- DMA buffer
        dma_buffer     : dma_buffer_t;
        -- IRQ on empty
        irq_enable     : boolean;
        -- Loop DMA
        loop_enable    : boolean;
        --IRQ active
        irq_active     : boolean;
        -- Cycles remaining before a DMA can be started
        start_delay    : dma_delay_t;
        -- Halt/dummy cycles the CPU has been halted for
        halt_count     : dma_halt_t;
        -- Bytes were remaining at the start of the previous APU cycle
        playing_prev   : boolean;
    end record;
    
    constant RESET_DMA : dma_t :=
    (
        state => DMA_IDLE,
        dma_xfer_vals => RESET_DMA_XFER,
        dma_xfer_parms => RESET_DMA_PARMS,
        dma_buffer => RESET_DMA_BUFFER,
        irq_enable => false,
        loop_enable => false,
        irq_active => false,
        start_delay => (others => '0'),
        halt_count => 0,
        playing_prev => false
    );
    
    function init_dma_address(start_address : dma_start_t) return dma_addr_t;
    function init_dma_remaining(dma_length : dma_length_t) return dma_remainder_t;
    
    -- True on the cycle the DMC DMA read is performed: the first even
    -- (read) cycle after the halt and dummy cycles. While OAM DMA is
    -- running the CPU is already halted, so the DMC DMA halt/dummy cycles
    -- overlap it and the read can only take the place of an OAM read cycle,
    -- never an OAM write cycle.
    function dma_read_now
    (
        dma     : dma_t;
        clk_odd : boolean;
        oam_dma : oam_dma_status_t
    )
    return boolean;

    function next_dma
    (
        cur_val        : dma_t;
        shift_reloaded : boolean;
        cpu_data_in    : data_t;
        clk_odd        : boolean;
        cpu_write      : boolean;
        oam_dma        : oam_dma_status_t
    )
    return dma_t;
    
    subtype dmc_timer_t is natural range 0 to 2**8-1;
    subtype dmc_idx_t is natural range 0 to 15;
    subtype dmc_dac_t is natural range 0 to 127;
    subtype dmc_count_t is natural range 0 to 7;

    type dmc_timer_arr_t is array(0 to 16#F#) of dmc_timer_t;

    constant DMC_TIMER_ARR : dmc_timer_arr_t :=
    (
        -- Rate in APU cycles - 1 (CPU cycle rate in comments)
        -- 428
        213,
        -- 380
        189,
        -- 340
        169,
        -- 320
        159,
        -- 286
        142,
        -- 254
        126,
        -- 226
        112,
        -- 214
        106,
        -- 190
        94,
        -- 160
        79,
        -- 142
        70,
        -- 128
        63,
        -- 106
        52,
        -- 84
        41,
        -- 72
        35,
        -- 54
        26
    );
    
    type dmc_output_t is record
        -- Timer period
        timer      : dmc_timer_t;
        -- Index value to load timer period (memory-mapped)
        timer_idx  : dmc_idx_t;
        -- Shift register used to update DMC output
        shift      : dmc_data_t;
        -- Shift register output counter
        shift_count : dmc_count_t;
        -- Audio value
        audio      : dmc_dac_t;
        -- True if silent cycle
        silent     : boolean;
    end record;
    
    constant RESET_DMC_OUTPUT : dmc_output_t :=
    (
        -- The first CPU cycle after reset is odd, so this makes the
        -- timer expire on the first even cycle
        timer => 1,
        timer_idx => 0,
        shift => (others => '0'),
        shift_count => 0,
        audio => 0,
        silent => true
    );
    
    function next_dmc_audio
    (
        audio     : dmc_dac_t;
        shift_val : std_logic
    )
    return dmc_dac_t;
    
    function get_dmc_period(idx : dmc_idx_t) return dmc_timer_t;
    
    function next_dmc_output
    (
        cur_val    : dmc_output_t;
        dma_buffer : dma_buffer_t;
        clk_odd    : boolean
    )
    return dmc_output_t;
    
    function update_shift
    (
        dmc_output : dmc_output_t;
        clk_odd    : boolean
    )
    return boolean;
    
    function enable_output(val : dmc_output_t) return boolean;
    
    type dmc_t is record
        dma    : dma_t;
        output : dmc_output_t;
    end record;
    
    constant RESET_DMC : dmc_t :=
    (
        dma => RESET_DMA,
        output => RESET_DMC_OUTPUT
    );
    
    function get_dma_bus
    (
        dmc     : dmc_t;
        clk_odd : boolean;
        oam_dma : oam_dma_status_t
    )
    return cpu_bus_t;
    
    function get_audio(dmc : dmc_t) return dmc_audio_t;
    
    function next_dmc
    (
        cur_val     : dmc_t;
        cpu_data_in : data_t;
        clk_odd     : boolean;
        cpu_write   : boolean;
        oam_dma     : oam_dma_status_t
    )
    return dmc_t;
    
    function dmc_irq_active(dmc : dmc_t) return boolean;
    
    function assert_ready(dmc : dmc_t) return boolean;
    
    function write_reg_0(val : dmc_t; reg : data_t) return dmc_t;
    
    function write_reg_1(val : dmc_t; reg : data_t) return dmc_t;
    
    function write_reg_2(val : dmc_t; reg : data_t) return dmc_t;
    
    function write_reg_3(val : dmc_t; reg : data_t) return dmc_t;
    
    function write_reg_4
    (
        val     : dmc_t;
        reg     : std_logic;
        clk_odd : boolean
    )
    return dmc_t;
    
    function get_status(dmc : dmc_t) return std_logic;

end package lib_apu_dmc;

package body lib_apu_dmc is

    function init_dma_xfer_vals(dma_parms : dma_parms_t) return dma_xfer_t
    is
        variable ret : dma_xfer_t;
    begin
        ret.address := init_dma_address(dma_parms.start_address);
        ret.bytes_remaining := init_dma_remaining(dma_parms.dma_length);
        
        return ret;
    end;
    
    function update_dma_xfer_vals
    (
        cur_vals     : dma_xfer_t;
        dma_parms    : dma_parms_t;
        loop_enabled : boolean
    )
    return dma_xfer_t
    is
        variable ret : dma_xfer_t;
        variable next_remaining : dma_remainder_t;
    begin
        ret := cur_vals;
        
        if not is_zero(cur_vals.bytes_remaining)
        then
            next_remaining := cur_vals.bytes_remaining - "1";
            -- The bytes counter is decremented; if it becomes zero and
            -- the loop flag is set, the sample is restarted
            if is_zero(next_remaining) and loop_enabled
            then
                ret := init_dma_xfer_vals(dma_parms);
            else
                ret.bytes_remaining := next_remaining;
                -- The address is incremented; if it exceeds $FFFF, it is
                -- wrapped around to $8000
                if cur_vals.address = x"FFFF"
                then
                    ret.address := x"8000";
                else
                    ret.address := cur_vals.address + "1";
                end if;
            end if;
        end if;
        
        return ret;
    end;

    function dma_read_now
    (
        dma     : dma_t;
        clk_odd : boolean;
        oam_dma : oam_dma_status_t
    )
    return boolean
    is
    begin
        return dma.state = DMA_READ_REQ and
               dma.halt_count = dma_halt_t'high and
               not clk_odd and
               (not oam_dma.active or oam_dma.read_cycle);
    end;

    function next_dma
    (
        cur_val        : dma_t;
        shift_reloaded : boolean;
        cpu_data_in    : data_t;
        clk_odd        : boolean;
        cpu_write      : boolean;
        oam_dma        : oam_dma_status_t
    )
    return dma_t
    is
        variable next_val : dma_t;
        variable v_playing : boolean;
    begin
        next_val := cur_val;
        v_playing := not is_zero(cur_val.dma_xfer_vals.bytes_remaining);

        if not is_zero(cur_val.start_delay)
        then
            next_val.start_delay := cur_val.start_delay - "1";
        end if;

        case cur_val.state is
            when DMA_IDLE =>
                -- The CPU is halted on its next read cycle, followed by a
                -- dummy cycle. The DMA read always happens on an even cycle,
                -- so it takes 3 cycles (halt, dummy, read) if the halt occurs
                -- on an even cycle and 4 (halt, dummy, alignment, read)
                -- if it occurs on an odd cycle
                -- The DMA is requested on the same cycle the shift
                -- register empties the sample buffer
                if (not cur_val.dma_buffer.valid or shift_reloaded) and
                   is_zero(cur_val.start_delay) and
                   v_playing
                then
                    next_val.halt_count := 0;
                    next_val.state := DMA_READ_REQ;
                -- If playback stopped (explicitly via 0x4015 or by a load
                -- DMA reading the last byte) during the APU cycle before
                -- a reload DMA would be requested, the DMA still starts
                -- but is aborted after one cycle
                elsif shift_reloaded and cur_val.playing_prev
                then
                    next_val.state := DMA_ABORT;
                end if;
                
                if shift_reloaded
                then
                    next_val.dma_buffer.valid := false;
                end if;
            when DMA_READ_REQ =>
                if dma_read_now(cur_val, clk_odd, oam_dma)
                then
                    next_val.state := DMA_IDLE;
                    
                    next_val.dma_buffer.data := unsigned(cpu_data_in);
                    next_val.dma_buffer.valid := true;
                    
                    -- Playback may have been stopped after the DMA was
                    -- requested
                    if v_playing
                    then
                        next_val.dma_xfer_vals :=
                            update_dma_xfer_vals(cur_val.dma_xfer_vals,
                                                 cur_val.dma_xfer_parms,
                                                 cur_val.loop_enable);
                        next_val.irq_active :=
                            cur_val.irq_enable and
                            is_zero(next_val.dma_xfer_vals.bytes_remaining);
                    end if;
                -- The CPU cannot be halted on a write cycle
                elsif not cpu_write and
                      cur_val.halt_count /= dma_halt_t'high
                then
                    next_val.halt_count := cur_val.halt_count + 1;
                end if;
            when DMA_ABORT =>
                -- The CPU was halted for this cycle unless it was a write
                -- cycle, in which case the DMA does not happen at all
                next_val.state := DMA_IDLE;
        end case;

        if not clk_odd
        then
            next_val.playing_prev := v_playing;
        end if;
        
        return next_val;
    end;

    function enable_output(val : dmc_output_t) return boolean
    is
    begin
        return not val.silent;
    end;
    
    function update_shift
    (
        dmc_output : dmc_output_t;
        clk_odd    : boolean
    )
    return boolean
    is
    begin
        return dmc_output.timer = 0 and
               dmc_output.shift_count = 0 and
               not clk_odd;
    end;
    
    function get_dmc_period(idx : dmc_idx_t) return dmc_timer_t
    is
    begin
        return DMC_TIMER_ARR(idx);
    end;
    
    function next_dmc_audio
    (
        audio     : dmc_dac_t;
        shift_val : std_logic
    )
    return dmc_dac_t
    is
        variable ret : dmc_dac_t;
        constant ADJ_AMOUNT : dmc_dac_t := 2;
        constant AUDIO_DECR_MIN : dmc_dac_t := 1;
        constant AUDIO_INCR_MAX : dmc_dac_t := 126;
    begin
        -- If the silence flag is clear, bit 0 of the shift register is applied
        -- to the DAC counter: If bit 0 is clear and the counter is greater
        -- than 1, the counter is decremented by 2, otherwise if bit 0 is set
        -- and the counter is less than 126, the counter is incremented by 2.
        if shift_val = '0' and audio > AUDIO_DECR_MIN
        then
            return audio - ADJ_AMOUNT;
        elsif shift_val = '1' and audio < AUDIO_INCR_MAX
        then
            return audio + ADJ_AMOUNT;
        else
            return audio;
        end if;
    end;
    
    function init_dma_address(start_address : dma_start_t) return dma_addr_t
    is
    begin
        return "11" & start_address & "000000";
    end;
    
    function init_dma_remaining(dma_length : dma_length_t) return dma_remainder_t
    is
    begin
        return dma_length & "0001";
    end;
    
    function next_dmc_output
    (
        cur_val    : dmc_output_t;
        dma_buffer : dma_buffer_t;
        clk_odd    : boolean
    )
    return dmc_output_t
    is
        variable next_val : dmc_output_t;
    begin
        next_val := cur_val;
        
        -- The timer is clocked once per APU cycle, on odd cycles. When it
        -- expires the output unit is clocked on the following even cycle,
        -- and the timer is reloaded on the odd cycle after that, so a
        -- write to 0x4010 on the same cycle as the output unit is clocked
        -- still sets the period of the reload
        if clk_odd
        then
            if cur_val.timer = 0
            then
                next_val.timer := get_dmc_period(cur_val.timer_idx);
            else
                next_val.timer := cur_val.timer - 1;
            end if;
        elsif cur_val.timer = 0
        then
            if not cur_val.silent
            then
                next_val.audio := next_dmc_audio(cur_val.audio,
                                                 cur_val.shift(0));
                next_val.shift := cur_val.shift srl 1;
            end if;
            
            -- When an output cycle is started, the counter is loaded with 8
            -- and if the sample buffer is empty, the silence flag is set,
            -- otherwise the silence flag is cleared and the sample buffer
            -- is emptied into the shift register.
            if cur_val.shift_count = 0
            then
                if dma_buffer.valid
                then
                    next_val.silent := false;
                    next_val.shift := dma_buffer.data;
                else
                    next_val.silent := true;
                end if;
            end if;
            
            next_val.shift_count := wrap(cur_val.shift_count - 1, dmc_count_t'high);
        end if;
        
        return next_val;
    end;
    
    function get_dma_bus
    (
        dmc     : dmc_t;
        clk_odd : boolean;
        oam_dma : oam_dma_status_t
    )
    return cpu_bus_t
    is
    begin
        if dma_read_now(dmc.dma, clk_odd, oam_dma)
        then
            return bus_read(dmc.dma.dma_xfer_vals.address);
        else
            return CPU_BUS_IDLE;
        end if;
    end;
    
    function get_audio(dmc : dmc_t) return dmc_audio_t
    is
    begin
        return dmc.output.audio;
    end;
    
    function dmc_irq_active(dmc : dmc_t) return boolean
    is
    begin
        return dmc.dma.irq_active;
    end;
    
    function assert_ready(dmc : dmc_t) return boolean
    is
    begin
        return dmc.dma.state = DMA_IDLE;
    end;
    
    function get_status(dmc : dmc_t) return std_logic
    is
    begin
        return to_std_logic(not is_zero(dmc.dma.dma_xfer_vals.bytes_remaining));
    end;
    
    function next_dmc
    (
        cur_val     : dmc_t;
        cpu_data_in : data_t;
        clk_odd     : boolean;
        cpu_write   : boolean;
        oam_dma     : oam_dma_status_t
    )
    return dmc_t
    is
        variable next_val : dmc_t;
        variable v_update_shift : boolean;
    begin
        next_val := cur_val;
        
        v_update_shift := update_shift(cur_val.output, clk_odd);
        
        next_val.output := next_dmc_output(cur_val.output,
                                           cur_val.dma.dma_buffer,
                                           clk_odd);
        next_val.dma := next_dma(cur_val.dma, v_update_shift, cpu_data_in, clk_odd,
                                 cpu_write, oam_dma);
        
        return next_val;
    end;
    
    function write_reg_0(val : dmc_t; reg : data_t) return dmc_t
    is
        variable ret : dmc_t;
    begin
        ret := val;
        
        ret.dma.irq_enable := reg(7) = '1';
        ret.dma.loop_enable := reg(6) = '1';
        ret.output.timer_idx := to_integer(reg(3 downto 0));

        -- If the new interrupt enabled status is clear, the
        -- interrupt flag is cleared.
        if not ret.dma.irq_enable
        then
            ret.dma.irq_active := false;
        end if;
        
        return ret;
    end;
    
    function write_reg_1(val : dmc_t; reg : data_t) return dmc_t
    is
        variable ret : dmc_t;
    begin
        ret := val;
        
        ret.output.audio := to_integer(reg(6 downto 0));
        
        return ret;
    end;
    
    function write_reg_2(val : dmc_t; reg : data_t) return dmc_t
    is
        variable ret : dmc_t;
    begin
        ret := val;
        
        ret.dma.dma_xfer_parms.start_address := unsigned(reg);
        
        return ret;
    end;
    
    function write_reg_3(val : dmc_t; reg : data_t) return dmc_t
    is
        variable ret : dmc_t;
    begin
        ret := val;
        
        ret.dma.dma_xfer_parms.dma_length := unsigned(reg);
        
        return ret;
    end;
    
    function write_reg_4
    (
        val     : dmc_t;
        reg     : std_logic;
        clk_odd : boolean
    )
    return dmc_t
    is
        variable ret : dmc_t;
        constant DELAY_ODD : dma_delay_t := to_unsigned(1, dma_delay_t'length);
        constant DELAY_EVEN : dma_delay_t := to_unsigned(2, dma_delay_t'length);
    begin
        ret := val;
        
        -- A DMA that has already been requested is not cancelled
        if reg = '0'
        then
            ret.dma.dma_xfer_vals.bytes_remaining := (others => '0');
        elsif reg = '1' and is_zero(val.dma.dma_xfer_vals.bytes_remaining)
        then
            ret.dma.dma_xfer_vals := init_dma_xfer_vals(val.dma.dma_xfer_parms);
            -- DMA transfer does not start right away: the CPU halt begins
            -- 3 cycles after a write on an odd cycle and 4 cycles
            -- on an even cycle
            if clk_odd
            then
                ret.dma.start_delay := DELAY_ODD;
            else
                ret.dma.start_delay := DELAY_EVEN;
            end if;
        end if;

        -- Writing to this register clears the DMC interrupt flag.
        ret.dma.irq_active := false;
        
        return ret;
    end;

end package body;