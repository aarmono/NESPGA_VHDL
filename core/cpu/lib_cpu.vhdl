library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;

package lib_cpu is

    subtype count_t is unsigned(2 downto 0);
    subtype reg_t is unsigned(data_t'RANGE);

    constant CYC_7 : count_t := "111";
    constant CYC_6 : count_t := "110";
    constant CYC_5 : count_t := "101";
    constant CYC_4 : count_t := "100";
    constant CYC_3 : count_t := "011";
    constant CYC_2 : count_t := "010";
    constant CYC_1 : count_t := "001";
    constant CYC_0 : count_t := "000";

    constant CYC_FETCH  : count_t := "000";
    constant CYC_DECODE : count_t := "111";

    constant OP_RESET : data_t := x"F2";
    constant OP_NMI : data_t := x"12";
    constant OP_IRQ : data_t := x"22";

    type status_t is record
        c : unsigned(0 downto 0);
        z : boolean;
        v : boolean;
        n : boolean;
        d : boolean;
        i : boolean;
    end record;

    constant RESET_STATUS : status_t :=
    (
        c => (others => '0'),
        z => false,
        v => false,
        n => false,
        d => false,
        i => true
    );

    type opstate_t is record
        a        : reg_t;
        x        : reg_t;
        y        : reg_t;
        stack    : reg_t;
        status   : status_t;
        data_out : reg_t;
    end record;

    constant RESET_OPSTATE : opstate_t :=
    (
        a => (others => '0'),
        x => (others => '0'),
        y => (others => '0'),
        stack => (others => '0'),
        status => RESET_STATUS,
        data_out => (others => '0')
    );

    type registers_t is record
        pc          : unsigned(cpu_addr_t'RANGE);
        opstate     : opstate_t;
        opcode      : data_t;
        count       : count_t;
        data_in     : reg_t;
        c_hold      : unsigned(0 downto 0);
        addr_hold_1 : reg_t;
        addr_hold_2 : reg_t;
        nmi_req     : boolean;
        nmi_prev    : boolean;
    end record;

    constant RESET_REGISTERS : registers_t :=
    (
        pc => (others => '0'),
        opstate => RESET_OPSTATE,
        opcode => OP_RESET,
        count => CYC_7,
        data_in => (others => '0'),
        c_hold => (others => '0'),
        addr_hold_1 => (others => '0'),
        addr_hold_2 => (others => '0'),
        nmi_req => false,
        nmi_prev => false
    );

    type addr_mode_t is
    (
        MODE_SBI,
        MODE_IMM,
        MODE_ZERO_R,
        MODE_ABS_R,
        MODE_IND_X_R,
        MODE_ABS_X_R,
        MODE_ABS_Y_R,
        MODE_ZERO_X_R,
        MODE_ZERO_Y_R,
        MODE_IND_Y_R,
        MODE_ZERO_W,
        MODE_ABS_W,
        MODE_IND_X_W,
        MODE_ABS_X_W,
        MODE_ABS_Y_W,
        MODE_ZERO_X_W,
        MODE_ZERO_Y_W,
        MODE_IND_Y_W,
        MODE_SYA_W,
        MODE_SXA_W,
        MODE_ZERO_RW,
        MODE_ABS_RW,
        MODE_ZERO_X_RW,
        MODE_ABS_X_RW,
        MODE_ABS_Y_RW,
        MODE_IND_X_RW,
        MODE_IND_Y_RW,
        MODE_PUSH,
        MODE_PULL,
        MODE_JSR,
        MODE_BRK,
        MODE_RTI,
        MODE_JMP_ABS,
        MODE_JMP_IND,
        MODE_RTS,
        MODE_BRANCH
    );

    type instruction_t is
    (
        IN_NOP,
        -- Type 1 instructions
        IN_ORA,
        IN_AND,
        IN_EOR,
        IN_ADC,
        IN_LDA,
        IN_CMP,
        IN_SBC,
        -- Type 2 instructions
        IN_ASL,
        IN_ROL,
        IN_LSR,
        IN_ROR,
        IN_LDX,
        IN_DEC,
        IN_INC,
        -- Type 3 instructions
        IN_BIT,
        IN_LDY,
        IN_CPY,
        IN_CPX,
        -- Others
        IN_DEY,
        IN_TAY,
        IN_INY,
        IN_INX,
        IN_PLP,
        IN_PLA,
        IN_CLC,
        IN_SEC,
        IN_CLI,
        IN_SEI,
        IN_TYA,
        IN_CLV,
        IN_CLD,
        IN_SED,
        IN_TXA,
        IN_TXS,
        IN_TAX,
        IN_TSX,
        IN_DEX,
        IN_BRK,
        IN_NMI,
        IN_IRQ,
        -- Unofficial
        IN_ALR,
        IN_ANC,
        IN_ARR,
        IN_AXS,
        IN_LAX,
        IN_SLO,
        IN_RLA,
        IN_SRE,
        IN_RRA,
        IN_DCP,
        IN_ISC
    );

    type decode_state_t is record
        mode        : addr_mode_t;
        instruction : instruction_t;
        reg         : reg_t;
    end record;

    type cpu_output_t is record
        reg      : registers_t;
        data_out : data_t;
        data_bus : cpu_bus_t;
        sync     : boolean;
    end record;

    function to_reg_t(status : status_t; b : boolean) return reg_t;

    function to_status_t(stat_in : data_t) return status_t;

    function stack_addr(data : data_t) return cpu_addr_t;

    function stack_addr(data : reg_t) return cpu_addr_t;

    function zero_addr(data : data_t) return cpu_addr_t;

    function zero_addr(data : reg_t) return cpu_addr_t;

    function exec_on_fetch(mode : addr_mode_t) return boolean;

    function overflow
    (
        a   : reg_t;
        b   : reg_t;
        res : reg_t
    )
    return boolean;

    function branch
    (
        status : status_t;
        reg    : reg_t
    )
    return boolean;

    function exec_opcode
    (
        decoded   : decode_state_t;
        cur_state : opstate_t;
        data_in   : reg_t
    )
    return opstate_t;

    function get_decode_state
    (
        opcode  : data_t;
        opstate : opstate_t
    )
    return decode_state_t;

    function get_next_count(state : decode_state_t) return count_t;

    function incr_pc(decode_state : decode_state_t) return boolean;

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

    function to_reg_t(status : status_t; b : boolean) return reg_t
    is
        variable ret : reg_t;
    begin
        ret(7) := to_std_logic(status.n);
        ret(6) := to_std_logic(status.v);
        -- Bit 5 is always pushed as 1
        ret(5) := '1';
        ret(4) := to_std_logic(b);
        ret(3) := to_std_logic(status.d);
        ret(2) := to_std_logic(status.i);
        ret(1) := to_std_logic(status.z);
        ret(0) := status.c(0);

        return ret;
    end;

    function to_status_t(stat_in : data_t) return status_t
    is
        variable ret : status_t;
    begin
        ret.n    := stat_in(7) = '1';
        ret.v    := stat_in(6) = '1';
        -- The CPU disregards bits 5 and 4 when reading flags from the stack
        -- in the PLP or RTI instruction.
        ret.d    := stat_in(3) = '1';
        ret.i    := stat_in(2) = '1';
        ret.z    := stat_in(1) = '1';
        ret.c(0) := stat_in(0);

        return ret;
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

    function exec_on_fetch(mode : addr_mode_t) return boolean
    is
    begin
        case mode is
            when MODE_ZERO_RW   |
                 MODE_ABS_RW    |
                 MODE_ZERO_X_RW |
                 MODE_ABS_X_RW  |
                 MODE_ABS_Y_RW  |
                 MODE_IND_X_RW  |
                 MODE_IND_Y_RW  =>
                return false;
            when others =>
                return true;
        end case;
    end;

    function overflow
    (
        a   : reg_t;
        b   : reg_t;
        res : reg_t
    )
    return boolean
    is
    begin
        return (not (a(7) xor b(7)) and (b(7) xor res(7))) = '1';
    end;

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

    function exec_opcode
    (
        decoded   : decode_state_t;
        cur_state : opstate_t;
        data_in   : reg_t
    )
    return opstate_t
    is
        variable scratch    : unsigned(8 downto 0);
        variable next_state : opstate_t;
    begin
        next_state := cur_state;
        case decoded.instruction is
            when IN_ORA =>
                next_state.a := cur_state.a or data_in;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_AND =>
                next_state.a := cur_state.a and data_in;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_ANC =>
                next_state.a := cur_state.a and data_in;
                next_state.status.c(0) := next_state.a(7);
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_ALR =>
                scratch := '0' & (cur_state.a and data_in);

                next_state.a := scratch(8 downto 1);
                next_state.status.c(0) := scratch(0);
                next_state.status.z := scratch(8 downto 1) = x"00";
                next_state.status.n := scratch(8) = '1';
            when IN_ARR =>
                scratch := cur_state.status.c & (cur_state.a and data_in);

                next_state.a := scratch(8 downto 1);
                next_state.status.c(0) := scratch(7);
                next_state.status.z := scratch(8 downto 1) = x"00";
                next_state.status.n := scratch(8) = '1';
                next_state.status.v := (scratch(7) xor scratch(6)) = '1';
            when IN_AXS =>
                scratch := ("0" & (cur_state.a and cur_state.x)) +
                           not data_in +
                           "1";

                next_state.x := scratch(7 downto 0);
                next_state.status.c(0) := scratch(8);
                next_state.status.z := scratch(7 downto 0) = x"00";
                next_state.status.n := scratch(7) = '1';
            when IN_EOR =>
                next_state.a := cur_state.a xor data_in;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_ADC =>
                scratch := ("0" & cur_state.a) +
                           data_in +
                           cur_state.status.c;

                next_state.a := scratch(7 downto 0);
                next_state.status.c(0) := scratch(8);
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
                next_state.status.v := overflow(cur_state.a, data_in, next_state.a);
            when IN_LDA =>
                next_state.a := data_in;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_LAX =>
                next_state.a := data_in;
                next_state.x := data_in;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_CMP =>
                scratch := ("0" & cur_state.a) + 
                           not data_in +
                           "1";

                next_state.status.c(0) := scratch(8);
                next_state.status.z := scratch(7 downto 0) = x"00";
                next_state.status.n := scratch(7) = '1';
            when IN_SBC =>
                scratch := ("0" & cur_state.a) +
                           not data_in +
                           cur_state.status.c;

                next_state.a := scratch(7 downto 0);
                next_state.status.c(0) := scratch(8);
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
                next_state.status.v := overflow(cur_state.a,
                                                not data_in,
                                                next_state.a);
            when IN_ASL =>
                if decoded.mode = MODE_SBI then
                    scratch := cur_state.a & '0';
                    next_state.a := scratch(7 downto 0);
                else
                    scratch := data_in & '0';
                    next_state.data_out := scratch(7 downto 0);
                end if;
                next_state.status.c(0) := scratch(8);
                next_state.status.z := scratch(7 downto 0) = x"00";
                next_state.status.n := scratch(7) = '1';
            when IN_SLO =>
                scratch := data_in & '0';
                next_state.data_out := scratch(7 downto 0);
                
                next_state.a := cur_state.a or next_state.data_out;
                next_state.status.c(0) := scratch(8);
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_ROL =>
                if decoded.mode = MODE_SBI then
                    scratch := cur_state.a & cur_state.status.c;
                    next_state.a := scratch(7 downto 0);
                else
                    scratch := data_in & cur_state.status.c;
                    next_state.data_out := scratch(7 downto 0);
                end if;
                next_state.status.c(0) := scratch(8);
                next_state.status.z := scratch(7 downto 0) = x"00";
                next_state.status.n := scratch(7) = '1';
            when IN_RLA =>
                scratch := data_in & cur_state.status.c;
                next_state.data_out := scratch(7 downto 0);

                next_state.a := cur_state.a and next_state.data_out;
                next_state.status.c(0) := scratch(8);
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_LSR =>
                if decoded.mode = MODE_SBI then
                    scratch := '0' & cur_state.a;
                    next_state.a := scratch(8 downto 1);
                else
                    scratch := '0' & data_in;
                    next_state.data_out := scratch(8 downto 1);
                end if;
                next_state.status.c(0) := scratch(0);
                next_state.status.z := scratch(8 downto 1) = x"00";
                next_state.status.n := scratch(8) = '1';
            when IN_SRE =>
                scratch := '0' & data_in;
                next_state.data_out := scratch(8 downto 1);

                next_state.a := cur_state.a xor next_state.data_out;
                next_state.status.c(0) := scratch(0);
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_ROR =>
                if decoded.mode = MODE_SBI then
                    scratch := cur_state.status.c & cur_state.a;
                    next_state.a := scratch(8 downto 1);
                else
                    scratch := cur_state.status.c & data_in;
                    next_state.data_out := scratch(8 downto 1);
                end if;
                next_state.status.c(0) := scratch(0);
                next_state.status.z := scratch(8 downto 1) = x"00";
                next_state.status.n := scratch(8) = '1';
            when IN_RRA =>
                scratch := cur_state.status.c & data_in;
                next_state.data_out := scratch(8 downto 1);

                scratch := ("0" & cur_state.a) +
                           next_state.data_out +
                           data_in(0);
                next_state.a := scratch(7 downto 0);
                next_state.status.c(0) := scratch(8);
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
                next_state.status.v := overflow(cur_state.a,
                                                next_state.data_out,
                                                next_state.a);
            when IN_LDX =>
                next_state.x := data_in;
                next_state.status.z := next_state.x = x"00";
                next_state.status.n := next_state.x(7) = '1';
            when IN_DEC =>
                next_state.data_out := data_in - "1";
                next_state.status.z := next_state.data_out = x"00";
                next_state.status.n := next_state.data_out(7) = '1';
            when IN_DCP =>
                next_state.data_out := data_in - "1";

                scratch := ("0" & cur_state.a) +
                           not next_state.data_out +
                           "1";

                next_state.status.c(0) := scratch(8);
                next_state.status.z := scratch(7 downto 0) = x"00";
                next_state.status.n := scratch(7) = '1';
            when IN_INC =>
                next_state.data_out := data_in + "1";
                next_state.status.z := next_state.data_out = x"00";
                next_state.status.n := next_state.data_out(7) = '1';
            when IN_ISC =>
                next_state.data_out := data_in + "1";

                scratch := ("0" & cur_state.a) +
                           not next_state.data_out +
                           cur_state.status.c;

                next_state.a := scratch(7 downto 0);
                next_state.status.c(0) := scratch(8);
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
                next_state.status.v := overflow(cur_state.a,
                                                not next_state.data_out,
                                                next_state.a);
            when IN_BIT =>
                scratch(7 downto 0) := cur_state.a and data_in;
                next_state.status.z := scratch(7 downto 0) = x"00";
                next_state.status.v := data_in(6) = '1';
                next_state.status.n := data_in(7) = '1';
            when IN_LDY =>
                next_state.y := data_in;
                next_state.status.z := next_state.y = x"00";
                next_state.status.n := next_state.y(7) = '1';
            when IN_CPY =>
                scratch := ("0" & cur_state.y) +
                           not data_in +
                           "1";

                next_state.status.c(0) := scratch(8);
                next_state.status.z := scratch(7 downto 0) = x"00";
                next_state.status.n := scratch(7) = '1';
            when IN_CPX =>
                scratch := ("0" & cur_state.x) +
                           not data_in +
                           "1";

                next_state.status.c(0) := scratch(8);
                next_state.status.z := scratch(7 downto 0) = x"00";
                next_state.status.n := scratch(7) = '1';
            when IN_DEY =>
                next_state.y := cur_state.y - "1";
                next_state.status.z := next_state.y = x"00";
                next_state.status.n := next_state.y(7) = '1';
            when IN_TAY =>
                next_state.y := cur_state.a;
                next_state.status.z := next_state.y = x"00";
                next_state.status.n := next_state.y(7) = '1';
            when IN_INY =>
                next_state.y := cur_state.y + "1";
                next_state.status.z := next_state.y = x"00";
                next_state.status.n := next_state.y(7) = '1';
            when IN_INX =>
                next_state.x := cur_state.x + "1";
                next_state.status.z := next_state.x = x"00";
                next_state.status.n := next_state.x(7) = '1';
            when IN_PLP =>
                next_state.status := to_status_t(std_logic_vector(data_in));
            when IN_PLA =>
                next_state.a := data_in;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_CLC =>
                next_state.status.c := "0";
            when IN_SEC =>
                next_state.status.c := "1";
            when IN_CLI =>
                next_state.status.i := false;
            when IN_SEI =>
                next_state.status.i := true;
            when IN_TYA =>
                next_state.a := cur_state.y;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_CLV =>
                next_state.status.v := false;
            when IN_CLD =>
                next_state.status.d := false;
            when IN_SED =>
                next_state.status.d := true;
            when IN_TXA =>
                next_state.a := cur_state.x;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_TXS =>
                next_state.stack := cur_state.x;
            when IN_TAX =>
                next_state.x := cur_state.a;
                next_state.status.z := next_state.x = x"00";
                next_state.status.n := next_state.x(7) = '1';
            when IN_TSX =>
                next_state.x := cur_state.stack;
                next_state.status.z := next_state.x = x"00";
                next_state.status.n := next_state.x(7) = '1';
            when IN_DEX =>
                next_state.x := cur_state.x - "1";
                next_state.status.z := next_state.x = x"00";
                next_state.status.n := next_state.x(7) = '1';
            when others =>
        end case;

        return next_state;
    end;

    function get_decode_state
    (
        opcode  : data_t;
        opstate : opstate_t
    )
    return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret.mode := MODE_SBI;
        ret.instruction := IN_NOP;
        ret.reg := (others => '-');

        case opcode is
            -- BRK
            when x"00" =>
                ret.mode := MODE_BRK;
                ret.instruction := IN_BRK;
                ret.reg := x"FE";
            -- ORA (d,X)
            when x"01" =>
                ret.mode := MODE_IND_X_R;
                ret.instruction := IN_ORA;
            -- SLO (d,X)
            when x"03" =>
                ret.mode := MODE_IND_X_RW;
                ret.instruction := IN_SLO;
            -- NOP d
            when x"04" |
                 x"44" |
                 x"64" =>
                ret.mode := MODE_ZERO_R;
            -- ORA d
            when x"05" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_ORA;
            -- ASL d
            when x"06" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_ASL;
            -- SLO d
            when x"07" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_SLO;
            -- PHP
            when x"08" =>
                ret.mode := MODE_PUSH;
                ret.reg := to_reg_t(opstate.status, true);
            -- ORA #
            when x"09" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_ORA;
            -- ASL A
            when x"0A" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_ASL;
            -- ANC #
            when x"0B" |
                 x"2B" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_ANC;
            -- NOP a
            when x"0C" =>
                ret.mode := MODE_ABS_R;
            -- ORA a
            when x"0D" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_ORA;
            -- ASL a
            when x"0E" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_ASL;
            -- SLO a
            when x"0F" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_SLO;

            -- BPL r
            when x"10" =>
                ret.mode := MODE_BRANCH;
                ret.reg := to_unsigned(0, 5) &
                           to_unsigned(7, 3);
            -- ORA (d),Y
            when x"11" =>
                ret.mode := MODE_IND_Y_R;
                ret.instruction := IN_ORA;
            -- SLO (d),Y
            when x"13" =>
                ret.mode := MODE_IND_Y_RW;
                ret.instruction := IN_SLO;
            -- NOP d,X
            when x"14" |
                 x"34" |
                 x"54" |
                 x"74" |
                 x"D4" |
                 x"F4" =>
                ret.mode := MODE_IND_X_R;
            -- ORA d,X
            when x"15" =>
                ret.mode := MODE_ZERO_X_R;
                ret.instruction := IN_ORA;
            -- ASL d,X
            when x"16" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_ASL;
            -- SLO d,X
            when x"17" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_SLO;
            -- CLC
            when x"18" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_CLC;
            -- ORA a,Y
            when x"19" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_ORA;
            -- SLO a,Y
            when x"1B" =>
                ret.mode := MODE_ABS_Y_RW;
                ret.instruction := IN_SLO;
            -- NOP a,X
            when x"1C" |
                 x"3C" |
                 x"5C" |
                 x"7C" |
                 x"DC" |
                 x"FC" =>
                ret.mode := MODE_ABS_X_R;
            -- ORA a,X
            when x"1D" =>
                ret.mode := MODE_ABS_X_R;
                ret.instruction := IN_ORA;
            -- ASL a,X
            when x"1E" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_ASL;
            -- SLO a,X
            when x"1F" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_SLO;

            -- JSR a
            when x"20" =>
                ret.mode := MODE_JSR;
            -- AND (d,X)
            when x"21" =>
                ret.mode := MODE_IND_X_R;
                ret.instruction := IN_AND;
            -- RLA (d,X)
            when x"23" =>
                ret.mode := MODE_IND_X_RW;
                ret.instruction := IN_RLA;
            -- BIT d
            when x"24" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_BIT;
            -- AND d
            when x"25" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_AND;
            -- ROL d
            when x"26" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_ROL;
            -- RLA d
            when x"27" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_RLA;
            -- PLP
            when x"28" =>
                ret.mode := MODE_PULL;
                ret.instruction := IN_PLP;
            -- AND #
            when x"29" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_AND;
            -- ROL A
            when x"2A" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_ROL;
            -- BIT a
            when x"2C" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_BIT;
            -- AND a
            when x"2D" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_AND;
            -- ROL a
            when x"2E" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_ROL;
            when x"2F" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_RLA;

            -- BMI r
            when x"30" =>
                ret.mode := MODE_BRANCH;
                ret.reg := to_unsigned(1, 5) &
                           to_unsigned(7, 3);
            -- AND (d),Y
            when x"31" =>
                ret.mode := MODE_IND_Y_R;
                ret.instruction := IN_AND;
            -- RLA (d),Y
            when x"33" =>
                ret.mode := MODE_IND_Y_RW;
                ret.instruction := IN_RLA;
            -- AND d,X
            when x"35" =>
                ret.mode := MODE_ZERO_X_R;
                ret.instruction := IN_AND;
            -- ROL d,X
            when x"36" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_ROL;
            -- RLA d,X
            when x"37" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_RLA;
            -- SEC
            when x"38" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_SEC;
            -- AND a,Y
            when x"39" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_AND;
            -- RLA a,Y
            when x"3B" =>
                ret.mode := MODE_ABS_Y_RW;
                ret.instruction := IN_RLA;
            -- AND a,X
            when x"3D" =>
                ret.mode := MODE_ABS_X_R;
                ret.instruction := IN_AND;
            -- ROL a,X
            when x"3E" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_ROL;
            -- RLA a,X
            when x"3F" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_RLA;

            -- RTI
            when x"40" =>
                ret.mode := MODE_RTI;
            -- EOR (d,X)
            when x"41" =>
                ret.mode := MODE_IND_X_R;
                ret.instruction := IN_EOR;
            -- SRE (d,X)
            when x"43" =>
                ret.mode := MODE_IND_X_RW;
                ret.instruction := IN_SRE;
            -- EOR d
            when x"45" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_EOR;
            -- LSR d
            when x"46" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_LSR;
            -- SRE d
            when x"47" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_SRE;
            -- PHA
            when x"48" =>
                ret.mode := MODE_PUSH;
                ret.reg := opstate.a;
            -- EOR #
            when x"49" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_EOR;
            -- LSR A
            when x"4A" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_LSR;
            -- ALR #
            when x"4B" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_ALR;
            -- JMP a
            when x"4C" =>
                ret.mode := MODE_JMP_ABS;
            -- EOR a
            when x"4D" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_EOR;
            -- LSR a
            when x"4E" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_LSR;
            -- SRE a
            when x"4F" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_SRE;

            -- BVC r
            when x"50" =>
                ret.mode := MODE_BRANCH;
                ret.reg := to_unsigned(0, 5) &
                           to_unsigned(6, 3);
            -- EOR (d),Y
            when x"51" =>
                ret.mode := MODE_IND_Y_R;
                ret.instruction := IN_EOR;
            -- SRE (d),Y
            when x"53" =>
                ret.mode := MODE_IND_Y_RW;
                ret.instruction := IN_SRE;
            -- EOR d,X
            when x"55" =>
                ret.mode := MODE_ZERO_X_R;
                ret.instruction := IN_EOR;
            -- LSR d,X
            when x"56" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_LSR;
            -- SRE d,X
            when x"57" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_SRE;
            -- CLI
            when x"58" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_CLI;
            -- EOR a,Y
            when x"59" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_EOR;
            -- SRE a,Y
            when x"5B" =>
                ret.mode := MODE_ABS_Y_RW;
                ret.instruction := IN_SRE;
            -- EOR a,X
            when x"5D" =>
                ret.mode := MODE_ABS_X_R;
                ret.instruction := IN_EOR;
            -- LSR a,X
            when x"5E" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_LSR;
            -- SRE a,X
            when x"5F" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_SRE;

            -- RTS
            when x"60" =>
                ret.mode := MODE_RTS;
            -- ADC (d,X)
            when x"61" =>
                ret.mode := MODE_IND_X_R;
                ret.instruction := IN_ADC;
            -- RRA (d,X)
            when x"63" =>
                ret.mode := MODE_IND_X_RW;
                ret.instruction := IN_RRA;
            -- ADC d
            when x"65" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_ADC;
            -- ROR d
            when x"66" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_ROR;
            -- RRA d
            when x"67" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_RRA;
            -- PLA
            when x"68" =>
                ret.mode := MODE_PULL;
                ret.instruction := IN_PLA;
            -- ADC #
            when x"69" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_ADC;
            -- ROR A
            when x"6A" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_ROR;
            -- ARR #
            when x"6B" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_ARR;
            -- JMP (a)
            when x"6C" =>
                ret.mode := MODE_JMP_IND;
            -- ADC a
            when x"6D" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_ADC;
            -- ROR a
            when x"6E" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_ROR;
            -- RRA a
            when x"6F" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_RRA;

            -- BVS r
            when x"70" =>
                ret.mode := MODE_BRANCH;
                ret.reg := to_unsigned(1, 5) &
                           to_unsigned(6, 3);
            -- ADC (d),Y
            when x"71" =>
                ret.mode := MODE_IND_Y_R;
                ret.instruction := IN_ADC;
            -- RRA (d),Y
            when x"73" =>
                ret.mode := MODE_IND_Y_RW;
                ret.instruction := IN_RRA;
            -- ADC d,X
            when x"75" =>
                ret.mode := MODE_ZERO_X_R;
                ret.instruction := IN_ADC;
            -- ROR d,X
            when x"76" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_ROR;
            -- RRA d, X
            when x"77" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_RRA;
            -- SEI
            when x"78" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_SEI;
            -- ADC a,Y
            when x"79" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_ADC;
            -- RRA a,Y
            when x"7B" =>
                ret.mode := MODE_ABS_Y_RW;
                ret.instruction := IN_RRA;
            -- ADC a,X
            when x"7D" =>
                ret.mode := MODE_ABS_X_R;
                ret.instruction := IN_ADC;
            -- ROR a,X
            when x"7E" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_ROR;
            -- RRA a,X
            when x"7F" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_RRA;

            -- NOP #
            when x"80" |
                 x"82" |
                 x"89" |
                 x"C2" |
                 x"E2" =>
                ret.mode := MODE_IMM;
            -- STA (d,X)
            when x"81" =>
                ret.mode := MODE_IND_X_W;
                ret.reg := opstate.a;
            -- AAX (d,X)
            when x"83" =>
                ret.mode := MODE_IND_X_W;
                ret.reg := opstate.a and opstate.x;
            -- STY d
            when x"84" =>
                ret.mode := MODE_ZERO_W;
                ret.reg := opstate.y;
            -- STA d
            when x"85" =>
                ret.mode := MODE_ZERO_W;
                ret.reg := opstate.a;
            -- STX d
            when x"86" =>
                ret.mode := MODE_ZERO_W;
                ret.reg := opstate.x;
            -- AAX d
            when x"87" =>
                ret.mode := MODE_ZERO_W;
                ret.reg := opstate.a and opstate.x;
            -- DEY
            when x"88" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_DEY;
            -- TXA
            when x"8A" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_TXA;
            -- STY a
            when x"8C" =>
                ret.mode := MODE_ABS_W;
                ret.reg := opstate.y;
            -- STA a
            when x"8D" =>
                ret.mode := MODE_ABS_W;
                ret.reg := opstate.a;
            -- STX a
            when x"8E" =>
                ret.mode := MODE_ABS_W;
                ret.reg := opstate.x;
            -- AAX a
            when x"8F" =>
                ret.mode := MODE_ABS_W;
                ret.reg := opstate.a and opstate.x;

            -- BCC r
            when x"90" =>
                ret.mode := MODE_BRANCH;
                ret.reg := to_unsigned(0, 5) &
                           to_unsigned(0, 3);
            -- STA (d),Y
            when x"91" =>
                ret.mode := MODE_IND_Y_W;
                ret.reg := opstate.a;
            -- STY d,X
            when x"94" =>
                ret.mode := MODE_ZERO_X_W;
                ret.reg := opstate.y;
            -- STA d,X
            when x"95" =>
                ret.mode := MODE_ZERO_X_W;
                ret.reg := opstate.a;
            -- STX d,Y
            when x"96" =>
                ret.mode := MODE_ZERO_Y_W;
                ret.reg := opstate.x;
            -- AAX d,Y
            when x"97" =>
                ret.mode := MODE_ZERO_Y_W;
                ret.reg := opstate.a and opstate.x;
            -- TYA
            when x"98" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_TYA;
            -- STA a,Y
            when x"99" =>
                ret.mode := MODE_ABS_Y_W;
                ret.reg := opstate.a;
            -- TXS
            when x"9A" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_TXS;
            -- SYA a,X
            when x"9C" =>
                ret.mode := MODE_SYA_W;
                ret.reg := opstate.y;
            -- STA a,X
            when x"9D" =>
                ret.mode := MODE_ABS_X_W;
                ret.reg := opstate.a;
            -- SXA a,Y
            when x"9E" =>
                ret.mode := MODE_SXA_W;
                ret.reg := opstate.x;

            -- LDY #
            when x"A0" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_LDY;
            -- LDA (d,X)
            when x"A1" =>
                ret.mode := MODE_IND_X_R;
                ret.instruction := IN_LDA;
            -- LDX #
            when x"A2" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_LDX;
            -- LAX (d,X)
            when x"A3" =>
                ret.mode := MODE_IND_X_R;
                ret.instruction := IN_LAX;
            -- LDY d
            when x"A4" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_LDY;
            -- LDA d
            when x"A5" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_LDA;
            -- LDX d
            when x"A6" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_LDX;
            -- LAX d
            when x"A7" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_LAX;
            -- TAY
            when x"A8" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_TAY;
            -- LDA #
            when x"A9"=>
                ret.mode := MODE_IMM;
                ret.instruction := IN_LDA;
            -- TAX
            when x"AA" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_TAX;
            -- LAX #
            when x"AB" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_LAX;
            -- LDY a
            when x"AC" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_LDY;
            -- LDA a
            when x"AD" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_LDA;
            -- LDX a
            when x"AE" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_LDX;
            -- LAX a
            when x"AF" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_LAX;

            -- BCS r
            when x"B0" =>
                ret.mode := MODE_BRANCH;
                ret.reg := to_unsigned(1, 5) &
                           to_unsigned(0, 3);
            -- LDA (d),Y
            when x"B1" =>
                ret.mode := MODE_IND_Y_R;
                ret.instruction := IN_LDA;
            -- LAX (d),Y
            when x"B3" =>
                ret.mode := MODE_IND_Y_R;
                ret.instruction := IN_LAX;
            -- LDY d,X
            when x"B4" =>
                ret.mode := MODE_ZERO_X_R;
                ret.instruction := IN_LDY;
            -- LDA d,X
            when x"B5" =>
                ret.mode := MODE_ZERO_X_R;
                ret.instruction := IN_LDA;
            -- LDX d,Y
            when x"B6" =>
                ret.mode := MODE_ZERO_Y_R;
                ret.instruction := IN_LDX;
            -- LAX d,Y
            when x"B7" =>
                ret.mode := MODE_ZERO_Y_R;
                ret.instruction := IN_LAX;
            -- CLV
            when x"B8" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_CLV;
            -- LDA a,Y
            when x"B9" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_LDA;
            -- TSX
            when x"BA" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_TSX;
            -- LDY a,X
            when x"BC" =>
                ret.mode := MODE_ABS_X_R;
                ret.instruction := IN_LDY;
            -- LDA a,X
            when x"BD" =>
                ret.mode := MODE_ABS_X_R;
                ret.instruction := IN_LDA;
            -- LDX a,Y
            when x"BE" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_LDX;
            -- LAX a,Y
            when x"BF" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_LAX;

            -- CPY #
            when x"C0" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_CPY;
            -- CMP (d,X)
            when x"C1" =>
                ret.mode := MODE_IND_X_R;
                ret.instruction := IN_CMP;
            -- DCP (d,X)
            when x"C3" =>
                ret.mode := MODE_IND_X_RW;
                ret.instruction := IN_DCP;
            -- CPY d
            when x"C4" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_CPY;
            -- CMP d
            when x"C5" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_CMP;
            -- DEC d
            when x"C6" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_DEC;
            -- DCP d
            when x"C7" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_DCP;
            -- INY
            when x"C8" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_INY;
            -- CMP #
            when x"C9" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_CMP;
            -- DEX
            when x"CA" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_DEX;
            -- AXS
            when x"CB" =>
                ret.mode := MODE_IMM;
                ret.instruction := in_AXS;
            -- CPY a
            when x"CC" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_CPY;
            -- CMP a
            when x"CD" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_CMP;
            -- DEC a
            when x"CE" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_DEC;
            -- DCP a
            when x"CF" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_DCP;

            -- BNE r
            when x"D0" =>
                ret.mode := MODE_BRANCH;
                ret.reg := to_unsigned(0, 5) &
                           to_unsigned(1, 3);
            -- CMP (d),Y
            when x"D1" =>
                ret.mode := MODE_IND_Y_R;
                ret.instruction := IN_CMP;
            -- DCP (d),Y
            when x"D3" =>
                ret.mode := MODE_IND_Y_RW;
                ret.instruction := IN_DCP;
            -- CMP d,X
            when x"D5" =>
                ret.mode := MODE_ZERO_X_R;
                ret.instruction := IN_CMP;
            -- DEC d,X
            when x"D6" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_DEC;
            -- DCP d,X
            when x"D7" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_DCP;
            -- CLD
            when x"D8" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_CLD;
            -- CMP a,Y
            when x"D9" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_CMP;
            -- DCP a,Y
            when x"DB" =>
                ret.mode := MODE_ABS_Y_RW;
                ret.instruction := IN_DCP;
            -- CMP a,X
            when x"DD" =>
                ret.mode := MODE_ABS_X_R;
                ret.instruction := IN_CMP;
            -- DEC a,X
            when x"DE" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_DEC;
            -- DCP a,X
            when x"DF" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_DCP;

            -- CPX #
            when x"E0" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_CPX;
            -- SBC (d,X)
            when x"E1" =>
                ret.mode := MODE_IND_X_R;
                ret.instruction := IN_SBC;
            -- ISC (d,X)
            when x"E3" =>
                ret.mode := MODE_IND_X_RW;
                ret.instruction := IN_ISC;
            -- CPX d
            when x"E4" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_CPX;
            -- SBC d
            when x"E5" =>
                ret.mode := MODE_ZERO_R;
                ret.instruction := IN_SBC;
            -- INC d
            when x"E6" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_INC;
            -- ISC d
            when x"E7" =>
                ret.mode := MODE_ZERO_RW;
                ret.instruction := IN_ISC;
            -- INX
            when x"E8" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_INX;
            -- SBC #
            when x"E9" |
                 x"EB" =>
                ret.mode := MODE_IMM;
                ret.instruction := IN_SBC;
            -- NOP
            when x"EA" |
                 x"1A" |
                 x"3A" |
                 x"5A" |
                 x"7A" |
                 x"DA" |
                 x"FA" =>
                ret.mode := MODE_SBI;
            -- CPX a
            when x"EC" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_CPX;
            -- SBC a
            when x"ED" =>
                ret.mode := MODE_ABS_R;
                ret.instruction := IN_SBC;
            -- INC a
            when x"EE" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_INC;
            -- ISC a
            when x"EF" =>
                ret.mode := MODE_ABS_RW;
                ret.instruction := IN_ISC;

            -- BEQ r
            when x"F0" =>
                ret.mode := MODE_BRANCH;
                ret.reg := to_unsigned(1, 5) &
                           to_unsigned(1, 3);
            -- SBC (d),Y
            when x"F1" =>
                ret.mode := MODE_IND_Y_R;
                ret.instruction := IN_SBC;
            -- ISC (d),Y
            when x"F3" =>
                ret.mode := MODE_IND_Y_RW;
                ret.instruction := IN_ISC;
            -- SBC d,X
            when x"F5" =>
                ret.mode := MODE_ZERO_X_R;
                ret.instruction := IN_SBC;
            -- INC d,X
            when x"F6" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_INC;
            -- ISC d,X
            when x"F7" =>
                ret.mode := MODE_ZERO_X_RW;
                ret.instruction := IN_ISC;
            -- SED
            when x"F8" =>
                ret.mode := MODE_SBI;
                ret.instruction := IN_SED;
            -- SBC a,Y
            when x"F9" =>
                ret.mode := MODE_ABS_Y_R;
                ret.instruction := IN_SBC;
            -- ISC a,Y
            when x"FB" =>
                ret.mode := MODE_ABS_Y_RW;
                ret.instruction := IN_ISC;
            -- SBC a,X
            when x"FD" =>
                ret.mode := MODE_ABS_X_R;
                ret.instruction := IN_SBC;
            -- INC a,X
            when x"FE" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_INC;
            -- ISC a,X
            when x"FF" =>
                ret.mode := MODE_ABS_X_RW;
                ret.instruction := IN_ISC;
            -- RESET
            when OP_RESET =>
                ret.mode := MODE_BRK;
                ret.reg := x"FC";
            when OP_NMI =>
                ret.mode := MODE_BRK;
                ret.reg := x"FA";
                ret.instruction := IN_NMI;
            when OP_IRQ =>
                ret.mode := MODE_BRK;
                ret.reg := x"FE";
                ret.instruction := IN_IRQ;
            when others =>
                assert false report "Invalid opcode: " & to_hstring(opcode)
                             severity failure;
        end case;

        return ret;
    end;

    function get_next_count(state : decode_state_t) return count_t
    is
    begin
        case state.mode is
            when MODE_SBI =>
                return CYC_0;
            when MODE_IMM =>
                return CYC_0;
            when MODE_ZERO_R |
                 MODE_ZERO_W =>
                return CYC_1;
            when MODE_ABS_R |
                 MODE_ABS_W =>
                return CYC_2;
            when MODE_IND_X_R |
                 MODE_IND_X_W =>
                return CYC_4;
            when MODE_ABS_X_R |
                 MODE_ABS_Y_R |
                 MODE_ABS_X_W |
                 MODE_ABS_Y_W |
                 MODE_SYA_W   |
                 MODE_SXA_W   =>
                return CYC_3;
            when MODE_ZERO_X_R |
                 MODE_ZERO_Y_R |
                 MODE_ZERO_X_W |
                 MODE_ZERO_Y_W =>
                return CYC_2;
            when MODE_IND_Y_R |
                 MODE_IND_Y_W =>
                return CYC_4;
            when MODE_ZERO_RW =>
                return CYC_3;
            when MODE_ABS_RW =>
                return CYC_4;
            when MODE_ZERO_X_RW =>
                return CYC_4;
            when MODE_ABS_X_RW |
                 MODE_ABS_Y_RW =>
                return CYC_5;
            when MODE_IND_X_RW =>
                return CYC_6;
            when MODE_IND_Y_RW =>
                return CYC_6;
            when MODE_PUSH =>
                return CYC_1;
            when MODE_PULL =>
                return CYC_2;
            when MODE_JSR =>
                return CYC_4;
            when MODE_BRK =>
                return CYC_5;
            when MODE_RTI =>
                return CYC_4;
            when MODE_JMP_ABS =>
                return CYC_1;
            when MODE_JMP_IND =>
                return CYC_3;
            when MODE_RTS =>
                return CYC_4;
            when MODE_BRANCH =>
                return CYC_2;
        end case;
    end;

    function incr_pc(decode_state : decode_state_t) return boolean
    is
    begin
        case decode_state.mode is
            when MODE_SBI  |
                 MODE_PUSH |
                 MODE_PULL =>
                return false;
            when MODE_BRK =>
                return decode_state.instruction = IN_BRK;
            when others =>
                return true;
        end case;
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

        v_decoded := get_decode_state(reg.opcode, reg.opstate);

        case reg.count is
            when CYC_FETCH =>
                v_data_bus := bus_read(reg.pc);
                v_sync := true;
                v_exec := exec_on_fetch(v_decoded.mode);

            when CYC_DECODE =>
                v_data_bus := bus_read(reg.pc);
                v_reg.count := get_next_count(v_decoded);

                if incr_pc(v_decoded) then
                    v_reg.pc := reg.pc + "1";
                end if;
            when others =>
                v_reg.count := reg.count - "1";
                case v_decoded.mode is
                    when MODE_ZERO_R |
                         MODE_ZERO_W =>

                        case reg.count is
                            when CYC_1 =>
                                if v_decoded.mode = MODE_ZERO_W then
                                    v_data_bus := bus_write(zero_addr(reg.data_in));
                                    v_data_out := v_decoded.reg;
                                else
                                    v_data_bus := bus_read(zero_addr(reg.data_in));
                                end if;
                            when others =>
                        end case;
                    when MODE_ABS_R |
                         MODE_ABS_W =>
                        case reg.count is
                            when CYC_2 =>
                                -- Put ADH on the data bus
                                v_data_bus := bus_read(reg.pc);
                                -- Increment the program counter
                                v_reg.pc := reg.pc + "1";
                                -- Store ADL in a hold register
                                v_reg.addr_hold_1 := reg.data_in;
                            when CYC_1 =>
                                -- Put ADH,ADL on the bus
                                if v_decoded.mode = MODE_ABS_W then
                                    v_data_bus := bus_write(reg.data_in & reg.addr_hold_1);
                                    v_data_out := v_decoded.reg;
                                else
                                    v_data_bus := bus_read(reg.data_in & reg.addr_hold_1);
                                end if;
                            when others =>
                        end case;
                    when MODE_IND_X_R |
                         MODE_IND_X_W =>
                        case reg.count is
                            when CYC_4 =>
                                -- Put BAL on the address bus
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate BAL + X (address of ADL)
                                v_reg.addr_hold_1 := reg.data_in + reg.opstate.x;
                            when CYC_3 =>
                                -- Put BAL + X on the address bus
                                v_data_bus := bus_read(zero_addr(reg.addr_hold_1));
                                -- Calculate BAL + X + 1 (address of ADH)
                                v_reg.addr_hold_1 := reg.addr_hold_1 + "1";
                            when CYC_2 =>
                                -- Put BAL + X + 1 on the address bus
                                v_data_bus := bus_read(zero_addr(reg.addr_hold_1));
                                -- Save ADL
                                v_reg.addr_hold_1 := reg.data_in;
                            when CYC_1 =>
                                -- Put ADH,ADL on the address bus
                                if v_decoded.mode = MODE_IND_X_W then
                                    v_data_out := v_decoded.reg;
                                    v_data_bus := bus_write(reg.data_in &
                                                            reg.addr_hold_1);
                                else
                                    v_data_bus := bus_read(reg.data_in &
                                                           reg.addr_hold_1);
                                end if;
                            when others =>
                        end case;
                    when MODE_ABS_X_R |
                         MODE_ABS_X_W |
                         MODE_ABS_Y_R |
                         MODE_ABS_Y_W |
                         MODE_SYA_W   |
                         MODE_SXA_W   =>
                        case reg.count is
                            when CYC_3 =>
                                -- Fetch BAH
                                v_data_bus := bus_read(reg.pc);
                                -- Increment PC
                                v_reg.pc := reg.pc + "1";
                                -- Calculate BAL + IDX
                                if v_decoded.mode = MODE_ABS_X_R or
                                   v_decoded.mode = MODE_ABS_X_W or
                                   v_decoded.mode = MODE_SYA_W
                                then
                                    v_idx_reg := reg.opstate.x;
                                else
                                    v_idx_reg := reg.opstate.y;
                                end if;

                                v_arith_scratch := ("0" & reg.data_in) + v_idx_reg;
                                v_reg.c_hold(0) := v_arith_scratch(8);
                                v_reg.addr_hold_1 := v_arith_scratch(7 downto 0);
                            when CYC_2 =>
                                -- Get BAH,BAL + IDX
                                v_data_bus := bus_read(reg.data_in & reg.addr_hold_1);
                                -- Calculate BAH + c_hold (for possible carry)
                                case v_decoded.mode is
                                    when MODE_SXA_W |
                                         MODE_SYA_W =>
                                        v_reg.addr_hold_2 := v_decoded.reg and
                                                             (reg.data_in + "1");
                                    when others =>
                                        v_reg.addr_hold_2 := reg.data_in +
                                                             reg.c_hold;
                                end case;
                                -- If no carry in previous cycle, decrement count by
                                -- an additional tick (decremented again after the case)
                                if reg.c_hold = "0" and
                                   (v_decoded.mode = MODE_ABS_X_R or
                                    v_decoded.mode = MODE_ABS_Y_R)
                                then
                                    v_reg.count := reg.count -
                                                   to_unsigned(2, 3);
                                end if;
                            when CYC_1 =>
                                -- Get BAH + 1,BAL + IDX
                                case v_decoded.mode is
                                    when MODE_ABS_X_W |
                                         MODE_ABS_Y_W =>
                                        v_data_bus := bus_write(reg.addr_hold_2 &
                                                                reg.addr_hold_1);
                                        v_data_out := v_decoded.reg;
                                    when MODE_ABS_X_R |
                                         MODE_ABS_Y_R =>
                                        v_data_bus := bus_read(reg.addr_hold_2 &
                                                               reg.addr_hold_1);
                                    when others =>
                                        v_data_bus := bus_write(reg.addr_hold_2 &
                                                                reg.addr_hold_1);
                                        v_data_out := reg.addr_hold_2;
                                end case;
                            when others =>
                        end case;
                    when MODE_ZERO_X_R |
                         MODE_ZERO_X_W |
                         MODE_ZERO_Y_R |
                         MODE_ZERO_Y_W =>
                        case reg.count is
                            when CYC_2 =>
                                -- Fetch 00,BAL
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate BAL + IDX
                                if v_decoded.mode = MODE_ZERO_X_R or
                                   v_decoded.mode = MODE_ZERO_X_W
                                then
                                    v_idx_reg := reg.opstate.x;
                                else
                                    v_idx_reg := reg.opstate.y;
                                end if;

                                v_reg.addr_hold_1 := reg.data_in + v_idx_reg;
                            when CYC_1 =>
                                -- Fetch 00,BAL + IDX
                                if v_decoded.mode = MODE_ZERO_X_W or
                                   v_decoded.mode = MODE_ZERO_Y_W
                                then
                                    v_data_bus :=
                                        bus_write(zero_addr(reg.addr_hold_1));
                                    v_data_out := v_decoded.reg;
                                else
                                    v_data_bus :=
                                        bus_read(zero_addr(reg.addr_hold_1));
                                end if;
                            when others =>
                        end case;
                    when MODE_IND_Y_R |
                         MODE_IND_Y_W =>
                        case reg.count is
                            when CYC_4 =>
                                -- Fetch 00,IAL (BAL)
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate IAL + 1
                                v_reg.addr_hold_1 := reg.data_in + "1";
                            when CYC_3 =>
                                -- Fetch 00,IAL + 1 (BAH)
                                v_data_bus := bus_read(zero_addr(reg.addr_hold_1));
                                -- Calculate BAL + Y
                                v_arith_scratch := ("0" & reg.data_in) + reg.opstate.y;
                                v_reg.c_hold(0) := v_arith_scratch(8);
                                v_reg.addr_hold_1 := v_arith_scratch(7 downto 0);
                            when CYC_2 =>
                                -- Fetch BAH,BAL + Y
                                v_data_bus := bus_read(reg.data_in & reg.addr_hold_1);
                                -- Calculate BAH + c_hold
                                v_reg.addr_hold_2 := reg.data_in + reg.c_hold;
                                if reg.c_hold = "0" and
                                   v_decoded.mode = MODE_IND_Y_R
                                then
                                    v_reg.count := reg.count -
                                                   to_unsigned(2, 3);
                                end if;
                            when CYC_1 =>
                                -- Fetch BAH + 1,BAL + Y
                                if v_decoded.mode = MODE_IND_Y_W
                                then
                                    v_data_bus := bus_write(reg.addr_hold_2 &
                                                            reg.addr_hold_1);
                                    v_data_out := v_decoded.reg;
                                else
                                    v_data_bus := bus_read(reg.addr_hold_2 &
                                                           reg.addr_hold_1);
                                end if;
                            when others =>
                        end case;
                    when MODE_ZERO_RW =>
                        case reg.count is
                            when CYC_3 =>
                                -- Fetch 00,ADL
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Save off ADL
                                v_reg.addr_hold_1 := reg.data_in;
                            when CYC_2 =>
                                -- Write garbage to the bus
                                v_data_bus := bus_write(zero_addr(reg.addr_hold_1));
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to the bus
                                v_data_bus := bus_write(zero_addr(reg.addr_hold_1));
                                v_data_out := reg.opstate.data_out;
                            when others =>
                        end case;
                    when MODE_ABS_RW =>
                        case reg.count is
                            when CYC_4 =>
                                -- Fetch ADH
                                v_data_bus := bus_read(reg.pc);
                                -- Increment PC
                                v_reg.pc := reg.pc + "1";
                                -- Save off ADL
                                v_reg.addr_hold_1 := reg.data_in;
                            when CYC_3 =>
                                -- Fetch ADH,ADL
                                v_data_bus := bus_read(reg.data_in & reg.addr_hold_1);
                                -- Save off ADH
                                v_reg.addr_hold_2 := reg.data_in;
                            when CYC_2 =>
                                -- Write garbage to the bus
                                v_data_bus := bus_write(reg.addr_hold_2 &
                                                        reg.addr_hold_1);
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus := bus_write(reg.addr_hold_2 &
                                                        reg.addr_hold_1);
                                v_data_out := reg.opstate.data_out;
                            when others =>
                        end case;
                    when MODE_ZERO_X_RW =>
                        case reg.count is
                            when CYC_4 =>
                                -- Fetch 00,BAL
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate BAL + IDX
                                v_reg.addr_hold_1 := reg.data_in +
                                                     reg.opstate.x;
                            when CYC_3 =>
                                -- Fetch 00,BAL + IDX
                                v_data_bus := bus_read(zero_addr(reg.addr_hold_1));
                            when CYC_2 =>
                                -- Write garbage to 00,BAL + IDX
                                v_data_bus := bus_write(zero_addr(reg.addr_hold_1));
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus := bus_write(zero_addr(reg.addr_hold_1));
                                v_data_out := reg.opstate.data_out;
                            when others =>
                        end case;
                    when MODE_ABS_X_RW |
                         MODE_ABS_Y_RW =>
                        case reg.count is
                            when CYC_5 =>
                                -- Fetch BAH
                                v_data_bus := bus_read(reg.pc);
                                -- Increment PC
                                v_reg.pc := reg.pc + "1";
                                -- Calculate BAL + IDX
                                if v_decoded.mode = MODE_ABS_X_RW
                                then
                                    v_idx_reg := reg.opstate.x;
                                else
                                    v_idx_reg := reg.opstate.y;
                                end if;

                                v_arith_scratch := ("0" & reg.data_in) + v_idx_reg;
                                v_reg.c_hold(0) := v_arith_scratch(8);
                                v_reg.addr_hold_1 := v_arith_scratch(7 downto 0);
                            when CYC_4 =>
                                -- Fetch BAH,BAL + IDX
                                v_data_bus := bus_read(reg.data_in & reg.addr_hold_1);
                                -- Calculate BAH + c
                                v_reg.addr_hold_2 := reg.data_in + reg.c_hold;
                            when CYC_3 =>
                                -- Fetch BAH + c,BAL + IDX
                                v_data_bus :=
                                    bus_read(reg.addr_hold_2 & reg.addr_hold_1);
                            when CYC_2 =>
                                -- Write garbage to BAH + c,BAL + IDX
                                v_data_bus :=
                                    bus_write(reg.addr_hold_2 & reg.addr_hold_1);
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus :=
                                    bus_write(reg.addr_hold_2 & reg.addr_hold_1);
                                v_data_out := reg.opstate.data_out;
                            when others =>
                        end case;
                    when MODE_IND_X_RW =>
                        case reg.count is
                            when CYC_6 =>
                                -- Put BAL on the address bus
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate BAL + X (address of ADL)
                                v_reg.addr_hold_1 := reg.data_in + reg.opstate.x;
                            when CYC_5 =>
                                -- Put BAL + X on the address bus
                                v_data_bus := bus_read(zero_addr(reg.addr_hold_1));
                                -- Calculate BAL + X + 1 (address of ADH)
                                v_reg.addr_hold_1 := reg.addr_hold_1 + "1";
                            when CYC_4 =>
                                -- Put BAL + X + 1 on the address bus
                                v_data_bus := bus_read(zero_addr(reg.addr_hold_1));
                                -- Save ADL
                                v_reg.addr_hold_1 := reg.data_in;
                            when CYC_3 =>
                                -- Fetch ADH,ADL
                                v_data_bus :=
                                    bus_read(reg.data_in & reg.addr_hold_1);
                                -- Save ADH
                                v_reg.addr_hold_2 := reg.data_in;
                            when CYC_2 =>
                                -- Write garbage to ADH,ADL
                                v_data_bus :=
                                    bus_write(reg.addr_hold_2 & reg.addr_hold_1);
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus :=
                                    bus_write(reg.addr_hold_2 & reg.addr_hold_1);
                                v_data_out := reg.opstate.data_out;
                            when others =>
                        end case;
                    when MODE_IND_Y_RW =>
                        case reg.count is
                            when CYC_6 =>
                                -- Fetch 00,IAL (BAL)
                                v_data_bus := bus_read(zero_addr(reg.data_in));
                                -- Calculate IAL + 1
                                v_reg.addr_hold_1 := reg.data_in + "1";
                            when CYC_5 =>
                                -- Fetch 00,IAL + 1 (BAH)
                                v_data_bus := bus_read(zero_addr(reg.addr_hold_1));
                                -- Calculate BAL + Y
                                v_arith_scratch := ("0" & reg.data_in) + reg.opstate.y;
                                v_reg.c_hold(0) := v_arith_scratch(8);
                                v_reg.addr_hold_1 := v_arith_scratch(7 downto 0);
                            when CYC_4 =>
                                -- Fetch BAH,BAL + Y
                                v_data_bus := bus_read(reg.data_in & reg.addr_hold_1);
                                -- Calculate BAH + c_hold
                                v_reg.addr_hold_2 := reg.data_in + reg.c_hold;
                            when CYC_3 =>
                                -- Fetch BAH + c,BAL + Y
                                v_data_bus := bus_read(reg.addr_hold_2 &
                                                       reg.addr_hold_1);
                            when CYC_2 =>
                                -- Write garbage to BAH + c,BAL + Y
                                v_data_bus := bus_write(reg.addr_hold_2 &
                                                        reg.addr_hold_1);
                                v_data_out := reg.opstate.data_out;
                                v_exec := true;
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus := bus_write(reg.addr_hold_2 &
                                                        reg.addr_hold_1);
                                v_data_out := reg.opstate.data_out;
                            when others =>
                        end case;
                    when MODE_PUSH =>
                        case reg.count is
                            when CYC_1 =>
                                -- Write value to bus
                                v_data_bus := bus_write(stack_addr(reg.opstate.stack));
                                v_data_out := v_decoded.reg;
                                -- Update stack pointer
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                            when others =>
                        end case;
                    when MODE_PULL =>
                        case reg.count is
                            when CYC_2 =>
                                -- Put current stack pointer on bus
                                v_data_bus := bus_read(stack_addr(reg.opstate.stack));
                                -- Increment stack pointer
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_1 =>
                                -- Fetch stack data
                                v_data_bus := bus_read(stack_addr(reg.opstate.stack));
                            when others =>
                        end case;
                    when MODE_JSR =>
                        case reg.count is
                            when CYC_4 =>
                                -- Garbage stack read
                                v_data_bus := bus_read(stack_addr(reg.opstate.stack));
                                -- Save ADL
                                v_reg.addr_hold_1 := reg.data_in;
                            when CYC_3 =>
                                -- Push PCH onto stack
                                v_data_bus := bus_write(stack_addr(reg.opstate.stack));
                                v_data_out := reg.pc(15 downto 8);
                                -- Decrement stack pointer
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                            when CYC_2 =>
                                -- Push PCL onto stack
                                v_data_bus := bus_write(stack_addr(reg.opstate.stack));
                                v_data_out := reg.pc(7 downto 0);
                                -- Decrement stack pointer
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                            when CYC_1 =>
                                -- Fetch ADH
                                v_data_bus := bus_read(reg.pc);
                                -- Update PC
                                v_reg.pc := unsigned(data_in) & reg.addr_hold_1;
                            when others =>
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
                                             v_decoded.instruction = IN_BRK);
                                v_reg.opstate.stack := reg.opstate.stack - "1";
                                v_reg.opstate.status.i := true;
                            when CYC_2 =>
                                v_data_bus := bus_read(x"FF" & v_decoded.reg);
                                v_reg.addr_hold_1 := v_decoded.reg + "1";
                            when CYC_1 =>
                                v_data_bus := bus_read(x"FF" & reg.addr_hold_1);
                                v_reg.pc := unsigned(data_in) & reg.data_in;
                            when others =>
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
                        end case;
                    when MODE_JMP_ABS =>
                        case reg.count is
                            when CYC_1 =>
                                -- Put PC on bus
                                v_data_bus := bus_read(reg.pc);
                                -- Store result and previous data in PC
                                v_reg.pc := unsigned(data_in) & reg.data_in;
                            when others =>
                        end case;
                    when MODE_JMP_IND =>
                        case reg.count is
                            when CYC_3 =>
                                -- Fetch IAH
                                v_data_bus := bus_read(reg.pc);
                                -- Save IAL
                                v_reg.addr_hold_1 := reg.data_in;
                            when CYC_2 =>
                                -- Fetch ADL
                                v_data_bus := bus_read(reg.data_in & reg.addr_hold_1);
                                -- Increment IAL
                                v_reg.addr_hold_1 := reg.addr_hold_1 + "1";
                                -- Save IAH
                                v_reg.addr_hold_2 := reg.data_in;
                            when CYC_1 =>
                                -- Fetch ADH
                                v_data_bus := bus_read(reg.addr_hold_2 & reg.addr_hold_1);
                                -- Update PC
                                v_reg.pc := unsigned(data_in) & reg.data_in;
                            when others =>
                        end case;
                    when MODE_RTS =>
                        case reg.count is
                            when CYC_4 =>
                                -- Put garbage stack pointer on bus
                                v_data_bus := bus_read(stack_addr(reg.opstate.stack));
                                -- Increment stack pointer
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_3 =>
                                -- Fetch PCL
                                v_data_bus := bus_read(stack_addr(reg.opstate.stack));
                                v_reg.pc(7 downto 0) := unsigned(data_in);
                                -- Increment stack pointer
                                v_reg.opstate.stack := reg.opstate.stack + "1";
                            when CYC_2 =>
                                -- Fetch PCH
                                v_data_bus := bus_read(stack_addr(reg.opstate.stack));
                                -- Assign input to PCH
                                v_reg.pc := (unsigned(data_in) & reg.pc(7 downto 0));
                            when CYC_1 =>
                                -- Fetch garbage data
                                v_data_bus := bus_read(reg.pc);
                                -- Increment PC
                                v_reg.pc := reg.pc + 1;
                            when others =>
                        end case;
                    when MODE_BRANCH =>
                        case reg.count is
                            when CYC_2 =>
                                v_data_bus := bus_read(reg.pc);

                                v_arith_scratch :=
                                    ("0" & reg.pc(7 downto 0)) +
                                    reg.data_in;

                                v_reg.addr_hold_1 := reg.data_in;

                                if branch(reg.opstate.status, v_decoded.reg) then
                                    v_reg.pc(7 downto 0) := v_arith_scratch(7 downto 0);
                                    v_reg.c_hold(0) := v_arith_scratch(8) xor
                                                       reg.data_in(7);
                                else
                                    v_sync := true;
                                end if;
                            when CYC_1 =>
                                v_data_bus := bus_read(reg.pc);

                                if reg.addr_hold_1(7) = '1' then
                                    v_arith_scratch(7 downto 0) :=
                                        reg.pc(15 downto 8) - reg.c_hold;
                                else
                                    v_arith_scratch(7 downto 0) :=
                                        reg.pc(15 downto 8) + reg.c_hold;
                                end if;

                                if reg.c_hold = "0"
                                then
                                    v_sync := true;
                                else
                                    v_reg.pc(15 downto 8) :=
                                        v_arith_scratch(7 downto 0);
                                end if;
                            when others =>
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
        if is_bus_read(v_data_bus) and not ready then
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