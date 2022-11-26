library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_cpu_types.all;
use work.lib_cpu_decode.all;
use work.lib_cpu_exec.all;

package lib_cpu is

    type registers_t is record
        pc       : unsigned(cpu_addr_t'RANGE);
        opstate  : opstate_t;
        opcode   : data_t;
        count    : count_t;
        data_in  : reg_t;
        c_addr   : unsigned(0 downto 0);
        addr_lo  : reg_t;
        addr_hi  : reg_t;
        nmi_req  : boolean;
        nmi_prev : boolean;
    end record;

    constant RESET_REGISTERS : registers_t :=
    (
        pc => (others => '0'),
        opstate => RESET_OPSTATE,
        opcode => OP_RESET,
        count => CYC_7,
        data_in => (others => '0'),
        c_addr => (others => '0'),
        addr_lo => (others => '0'),
        addr_hi => (others => '0'),
        nmi_req => false,
        nmi_prev => false
    );

    type cpu_output_t is record
        reg      : registers_t;
        data_out : data_t;
        data_bus : cpu_bus_t;
        sync     : boolean;
    end record;

    function branch
    (
        status : status_t;
        reg    : reg_t
    )
    return boolean;

    function stack_addr(data : data_t) return cpu_addr_t;

    function stack_addr(data : reg_t) return cpu_addr_t;

    function zero_addr(data : data_t) return cpu_addr_t;

    function zero_addr(data : reg_t) return cpu_addr_t;

    function cycle_cpu
    (
        reg     : registers_t;
        data_in : data_t;
        ready   : boolean;
        irq     : boolean;
        nmi     : boolean
    )
    return cpu_output_t;

end lib_cpu;

package body lib_cpu is

    function branch
    (
        status : status_t;
        reg    : reg_t
    )
    return boolean
    is
        variable reg_stat : reg_t;
    begin
        reg_stat := to_reg_t(status, false);
        return reg_stat(to_integer(reg(2 downto 0))) = reg(3);
    end;

    function stack_addr(data : data_t) return cpu_addr_t
    is
    begin
        return x"01" & data;
    end;

    function stack_addr(data : reg_t) return cpu_addr_t
    is
    begin
        return stack_addr(std_logic_vector(data));
    end;

    function zero_addr(data : data_t) return cpu_addr_t
    is
    begin
        return x"00" & data;
    end;
    
    function zero_addr(data : reg_t) return cpu_addr_t
    is
    begin
        return zero_addr(std_logic_vector(data));
    end;

    function cycle_cpu
    (
        reg     : registers_t;
        data_in : data_t;
        ready   : boolean;
        irq     : boolean;
        nmi     : boolean
    )
    return cpu_output_t
    is
        -- Internal variables
        variable v_decoded       : decode_state_t;
        variable v_arith_scratch : unsigned(8 downto 0);
        variable v_idx_reg       : reg_t;
        variable v_exec          : boolean;

        -- Variables which affect state or outputs
        variable v_sync     : boolean;
        variable v_data_out : reg_t;
        variable v_data_bus : cpu_bus_t;
        variable v_reg      : registers_t;

        -- Return variable
        variable ret : cpu_output_t;
    begin
        v_arith_scratch := (others => '-');
        v_idx_reg := (others => '-');
        v_data_out := (others => '-');
        v_data_bus := bus_idle(v_data_bus);
        v_reg := reg;
        v_sync := false;
        v_exec := false;

        v_decoded := get_decode_state(reg.opcode, reg.opstate, reg.addr_hi);

        case reg.count is
            when CYC_FETCH =>
                v_data_bus := bus_read(reg.pc);
                v_sync := true;
                -- Do not exec if this was a read-modify-write opcode
                v_exec := not (v_decoded.read and v_decoded.write);

            when CYC_DECODE =>
                v_data_bus := bus_read(reg.pc);
                v_reg.count := v_decoded.next_count;

                if v_decoded.incr_pc then
                    v_reg.pc := reg.pc + "1";
                end if;
            when others =>
                v_reg.count := reg.count - "1";
                case v_decoded.mode is
                    when MODE_ZERO =>
                        case reg.count is
                            when CYC_3 =>
                                if not v_decoded.read
                                then
                                    -- Write 00,ADL
                                    v_data_bus := bus_write(zero_addr(reg.data_in));
                                    v_data_out := v_decoded.reg;
                                else
                                    -- Fetch 00,ADL
                                    v_data_bus := bus_read(zero_addr(reg.data_in));
                                end if;

                                -- Save off ADL
                                v_reg.addr_lo := reg.data_in;

                                -- If this is not a read-modify-write cycle,
                                -- short-circuit the rest of the cycles
                                if (not v_decoded.read) or (not v_decoded.write)
                                then
                                    v_reg.count := CYC_FETCH;
                                end if;
                            when CYC_2 =>
                                -- Write garbage to the bus
                                v_data_bus := bus_write(zero_addr(reg.addr_lo));
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to the bus
                                v_data_bus := bus_write(zero_addr(reg.addr_lo));
                                v_data_out := reg.opstate.data_out;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_ABS =>
                        case reg.count is
                            when CYC_4 =>
                                -- Fetch ADH
                                v_data_bus := bus_read(reg.pc);
                                -- Increment PC
                                v_reg.pc := reg.pc + "1";
                                -- Save off ADL
                                v_reg.addr_lo := reg.data_in;
                            when CYC_3 =>
                                if not v_decoded.read
                                then
                                    -- Write ADH,ADL
                                    v_data_bus := bus_write(reg.data_in &
                                                            reg.addr_lo);
                                    v_data_out := v_decoded.reg;
                                else
                                    -- Fetch ADH,ADL
                                    v_data_bus := bus_read(reg.data_in &
                                                           reg.addr_lo);
                                end if;

                                -- Save off ADH
                                v_reg.addr_hi := reg.data_in;

                                -- If this is not a read-modify-write cycle,
                                -- short-circuit the rest of the cycles
                                if (not v_decoded.read) or (not v_decoded.write)
                                then
                                    v_reg.count := CYC_FETCH;
                                end if;
                            when CYC_2 =>
                                -- Write garbage to the bus
                                v_data_bus := bus_write(reg.addr_hi &
                                                        reg.addr_lo);
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus := bus_write(reg.addr_hi &
                                                        reg.addr_lo);
                                v_data_out := reg.opstate.data_out;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_IND_X =>
                        case reg.count is
                            when CYC_6 =>
                                -- Put BAL on the address bus
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate BAL + X (address of ADL)
                                v_reg.addr_lo := reg.data_in + reg.opstate.x;
                            when CYC_5 =>
                                -- Put BAL + X on the address bus
                                v_data_bus := bus_read(zero_addr(reg.addr_lo));
                                -- Calculate BAL + X + 1 (address of ADH)
                                v_reg.addr_lo := reg.addr_lo + "1";
                            when CYC_4 =>
                                -- Put BAL + X + 1 on the address bus
                                v_data_bus := bus_read(zero_addr(reg.addr_lo));
                                -- Save ADL
                                v_reg.addr_lo := reg.data_in;
                            when CYC_3 =>
                                if not v_decoded.read
                                then
                                    -- Write ADH,ADL
                                    v_data_out := v_decoded.reg;
                                    v_data_bus := bus_write(reg.data_in &
                                                            reg.addr_lo);
                                else
                                    -- Fetch ADH,ADL
                                    v_data_bus :=
                                        bus_read(reg.data_in & reg.addr_lo);
                                end if;

                                -- Save ADH
                                v_reg.addr_hi := reg.data_in;

                                -- If this is not a read-modify-write cycle,
                                -- short-circuit the rest of the cycles
                                if (not v_decoded.read) or (not v_decoded.write)
                                then
                                    v_reg.count := CYC_FETCH;
                                end if;
                            when CYC_2 =>
                                -- Write garbage to ADH,ADL
                                v_data_bus :=
                                    bus_write(reg.addr_hi & reg.addr_lo);
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus :=
                                    bus_write(reg.addr_hi & reg.addr_lo);
                                v_data_out := reg.opstate.data_out;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_ABS_IDX =>
                        case reg.count is
                            when CYC_5 =>
                                -- Fetch BAH
                                v_data_bus := bus_read(reg.pc);
                                -- Increment PC
                                v_reg.pc := reg.pc + "1";
                                -- Calculate BAL + IDX
                                v_arith_scratch := ("0" & reg.data_in) + 
                                                   v_decoded.idx_reg;
                                v_reg.c_addr(0) := v_arith_scratch(8);
                                v_reg.addr_lo := v_arith_scratch(7 downto 0);
                            when CYC_4 =>
                                -- Fetch BAH,BAL + IDX
                                v_data_bus := bus_read(reg.data_in & reg.addr_lo);
                                if v_decoded.special
                                then
                                    -- Calculate "special" BAH for SYA and SXA
                                    -- opcodes
                                    v_reg.addr_hi := v_decoded.reg and
                                                     (reg.data_in + "1");
                                else
                                    -- Calculate BAH + c
                                    v_reg.addr_hi := reg.data_in + reg.c_addr;
                                end if;

                                -- If no carry in previous cycle and this is
                                -- a read, short-circuit the rest of the cycles
                                if reg.c_addr = "0" and not v_decoded.write
                                then
                                    v_reg.count := CYC_FETCH;
                                end if;
                            when CYC_3 =>
                                if not v_decoded.read
                                then
                                    v_data_bus := bus_write(reg.addr_hi &
                                                            reg.addr_lo);
                                    v_data_out := v_decoded.reg;
                                else
                                    -- Fetch BAH + c,BAL + IDX
                                    v_data_bus := bus_read(reg.addr_hi &
                                                           reg.addr_lo);
                                end if;

                                -- If this is not a read-modify-write cycle,
                                -- short-circuit the rest of the cycles
                                if (not v_decoded.read) or (not v_decoded.write)
                                then
                                    v_reg.count := CYC_FETCH;
                                end if;
                            when CYC_2 =>
                                -- Write garbage to BAH + c,BAL + IDX
                                v_data_bus := bus_write(reg.addr_hi &
                                                        reg.addr_lo);
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus := bus_write(reg.addr_hi &
                                                        reg.addr_lo);
                                v_data_out := reg.opstate.data_out;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_ZERO_IDX =>
                        case reg.count is
                            when CYC_4 =>
                                -- Fetch 00,BAL
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate BAL + IDX
                                v_reg.addr_lo := reg.data_in +
                                                 v_decoded.idx_reg;
                            when CYC_3 =>
                                if not v_decoded.read
                                then
                                    -- Write 00,BAL + IDX
                                    v_data_bus :=
                                        bus_write(zero_addr(reg.addr_lo));
                                    v_data_out := v_decoded.reg;
                                else
                                    -- Fetch 00,BAL + IDX
                                    v_data_bus :=
                                        bus_read(zero_addr(reg.addr_lo));
                                end if;

                                -- If this is not a read-modify-write cycle,
                                -- short-circuit the rest of the cycles
                                if (not v_decoded.read) or (not v_decoded.write)
                                then
                                    v_reg.count := CYC_FETCH;
                                end if;
                            when CYC_2 =>
                                -- Write garbage to 00,BAL + IDX
                                v_data_bus := bus_write(zero_addr(reg.addr_lo));
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus := bus_write(zero_addr(reg.addr_lo));
                                v_data_out := reg.opstate.data_out;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_IND_Y =>
                        case reg.count is
                            when CYC_6 =>
                                -- Fetch 00,IAL (BAL)
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate IAL + 1
                                v_reg.addr_lo := reg.data_in + "1";
                            when CYC_5 =>
                                -- Fetch 00,IAL + 1 (BAH)
                                v_data_bus := bus_read(zero_addr(reg.addr_lo));
                                -- Calculate BAL + Y
                                v_arith_scratch := ("0" & reg.data_in) +
                                                   reg.opstate.y;
                                v_reg.c_addr(0) := v_arith_scratch(8);
                                v_reg.addr_lo := v_arith_scratch(7 downto 0);
                            when CYC_4 =>
                                -- Fetch BAH,BAL + Y
                                v_data_bus := bus_read(reg.data_in & reg.addr_lo);
                                -- Calculate BAH + c_addr
                                v_reg.addr_hi := reg.data_in + reg.c_addr;

                                -- If this is a read and no page boundary cross,
                                -- short-circuit the rest of the cycle
                                if not v_decoded.write and reg.c_addr = "0"
                                then
                                    v_reg.count := CYC_FETCH;
                                end if;
                            when CYC_3 =>
                                if not v_decoded.read
                                then
                                    -- Write BAH + c,BAL + Y
                                    v_data_bus := bus_write(reg.addr_hi &
                                                            reg.addr_lo);
                                    v_data_out := v_decoded.reg;
                                else
                                    -- Fetch BAH + c,BAL + Y
                                    v_data_bus := bus_read(reg.addr_hi &
                                                           reg.addr_lo);
                                end if;

                                -- If this is not a read-modify-write cycle,
                                -- short-circuit the rest of the cycles
                                if (not v_decoded.read) or (not v_decoded.write)
                                then
                                    v_reg.count := CYC_FETCH;
                                end if;
                            when CYC_2 =>
                                -- Write garbage to BAH + c,BAL + Y
                                v_data_bus := bus_write(reg.addr_hi &
                                                        reg.addr_lo);
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus := bus_write(reg.addr_hi &
                                                        reg.addr_lo);
                                v_data_out := reg.opstate.data_out;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_PUSH =>
                        case reg.count is
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus :=
                                    bus_write(stack_addr(reg.opstate.stack));
                                v_data_out := v_decoded.reg;
                                -- Update stack pointer
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_PULL =>
                        case reg.count is
                            when CYC_2 =>
                                -- Put current stack pointer on bus
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                -- Increment stack pointer
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_1 =>
                                -- Fetch stack data
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_JSR =>
                        case reg.count is
                            when CYC_4 =>
                                -- Garbage stack read
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                -- Save ADL
                                v_reg.addr_lo := reg.data_in;
                            when CYC_3 =>
                                -- Push PCH onto stack
                                v_data_bus :=
                                    bus_write(stack_addr(reg.opstate.stack));
                                v_data_out := reg.pc(15 downto 8);
                                -- Decrement stack pointer
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                            when CYC_2 =>
                                -- Push PCL onto stack
                                v_data_bus :=
                                    bus_write(stack_addr(reg.opstate.stack));
                                v_data_out := reg.pc(7 downto 0);
                                -- Decrement stack pointer
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                            when CYC_1 =>
                                -- Fetch ADH
                                v_data_bus := bus_read(reg.pc);
                                -- Update PC
                                v_reg.pc := unsigned(data_in) & reg.addr_lo;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_BRK =>
                        case reg.count is
                            when CYC_5 =>
                                v_data_bus :=
                                    bus_write(stack_addr(reg.opstate.stack));
                                v_data_out := reg.pc(15 downto 8);
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                            when CYC_4 =>
                                v_data_bus :=
                                    bus_write(stack_addr(reg.opstate.stack));
                                v_data_out := reg.pc(7 downto 0);
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                            when CYC_3 =>
                                v_data_bus :=
                                    bus_write(stack_addr(reg.opstate.stack));
                                v_data_out :=
                                    to_reg_t(reg.opstate.status,
                                             v_decoded.incr_pc);
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                                v_reg.opstate.status.i := true;
                            when CYC_2 =>
                                v_data_bus := bus_read(x"FF" & v_decoded.reg);
                                v_reg.addr_lo := v_decoded.reg + "1";
                            when CYC_1 =>
                                v_data_bus := bus_read(x"FF" & reg.addr_lo);
                                v_reg.pc := unsigned(data_in) & reg.data_in;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_RTI =>
                        case reg.count is
                            when CYC_4 =>
                                -- Read garbage from stack
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                -- Increment stack pointer
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_3 =>
                                -- Read status register off stack
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                v_reg.opstate.status := to_status_t(data_in);
                                -- Increment stack
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_2 =>
                                -- Read PCL from stack
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                v_reg.pc(7 downto 0) := unsigned(data_in);
                                -- Increment stack
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_1 =>
                                -- Read PCH from stack
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                v_reg.pc(15 downto 8) := unsigned(data_in);
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_JMP_ABS =>
                        case reg.count is
                            when CYC_1 =>
                                -- Put PC on bus
                                v_data_bus := bus_read(reg.pc);
                                -- Store result and previous data in PC
                                v_reg.pc := unsigned(data_in) & reg.data_in;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_JMP_IND =>
                        case reg.count is
                            when CYC_3 =>
                                -- Fetch IAH
                                v_data_bus := bus_read(reg.pc);
                                -- Save IAL
                                v_reg.addr_lo := reg.data_in;
                            when CYC_2 =>
                                -- Fetch ADL
                                v_data_bus := bus_read(reg.data_in &
                                                       reg.addr_lo);
                                -- Increment IAL
                                v_reg.addr_lo := reg.addr_lo + "1";
                                -- Save IAH
                                v_reg.addr_hi := reg.data_in;
                            when CYC_1 =>
                                -- Fetch ADH
                                v_data_bus := bus_read(reg.addr_hi &
                                                       reg.addr_lo);
                                -- Update PC
                                v_reg.pc := unsigned(data_in) & reg.data_in;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_RTS =>
                        case reg.count is
                            when CYC_4 =>
                                -- Put garbage stack pointer on bus
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                -- Increment stack pointer
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_3 =>
                                -- Fetch PCL
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                v_reg.pc(7 downto 0) := unsigned(data_in);
                                -- Increment stack pointer
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_2 =>
                                -- Fetch PCH
                                v_data_bus :=
                                    bus_read(stack_addr(reg.opstate.stack));
                                -- Assign input to PCH
                                v_reg.pc := unsigned(data_in) &
                                            reg.pc(7 downto 0);
                            when CYC_1 =>
                                -- Fetch garbage data
                                v_data_bus := bus_read(reg.pc);
                                -- Increment PC
                                v_reg.pc := reg.pc + 1;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when MODE_BRANCH =>
                        case reg.count is
                            when CYC_2 =>
                                v_data_bus := bus_read(reg.pc);

                                v_arith_scratch :=
                                    ("0" & reg.pc(7 downto 0)) +
                                    reg.data_in;

                                v_reg.addr_lo := reg.data_in;

                                if branch(reg.opstate.status, v_decoded.reg)
                                then
                                    v_reg.pc(7 downto 0) :=
                                        v_arith_scratch(7 downto 0);
                                    v_reg.c_addr(0) := v_arith_scratch(8) xor
                                                       reg.data_in(7);
                                else
                                    v_sync := true;
                                end if;
                            when CYC_1 =>
                                v_data_bus := bus_read(reg.pc);

                                if reg.addr_lo(7) = '1'
                                then
                                    v_arith_scratch(7 downto 0) :=
                                        reg.pc(15 downto 8) - reg.c_addr;
                                else
                                    v_arith_scratch(7 downto 0) :=
                                        reg.pc(15 downto 8) + reg.c_addr;
                                end if;

                                if reg.c_addr = "0"
                                then
                                    v_sync := true;
                                else
                                    v_reg.pc(15 downto 8) :=
                                        v_arith_scratch(7 downto 0);
                                end if;
                            when others =>
                                assert false report "Invalid cycle count"
                                             severity failure;
                        end case;
                    when others =>
                end case;
        end case;

        if v_exec
        then
            -- Execute an instruction (if applicable)
            v_reg.opstate := exec_opcode(v_decoded,
                                         reg.opstate,
                                         unsigned(reg.data_in));
        end if;

        if v_sync then
            if irq and not reg.opstate.status.i
            then
                v_reg.opcode := OP_IRQ;
            elsif reg.nmi_req
            then
                v_reg.opcode := OP_NMI;
                v_reg.nmi_req := false;
            else 
                v_reg.opcode := data_in;
                v_reg.pc := reg.pc + "1";
            end if;
            v_reg.count := CYC_7;
        end if;

        if nmi and not reg.nmi_prev
        then
            v_reg.nmi_req := true;
        end if;

        v_reg.nmi_prev := nmi;

        -- Store data bus input into hold register
        v_reg.data_in := unsigned(data_in);

        -- If the ready signal is not asserted and the current
        -- cycle is not a write cycle, revert values and idle the bus
        if is_bus_read(v_data_bus) and not ready
        then
            v_reg := reg;
            v_data_bus := bus_idle(v_data_bus);
            v_data_out := (others => '-');
        end if;

        ret.reg := v_reg;
        ret.data_bus := v_data_bus;
        ret.data_out := std_logic_vector(v_data_out);
        ret.sync := v_sync;

        return ret;
    end;

end package body;