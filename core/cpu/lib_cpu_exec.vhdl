library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_cpu_types.all;

package lib_cpu_exec is

    function overflow
    (
        a   : reg_t;
        b   : reg_t;
        res : reg_t
    )
    return boolean;

    function exec_opcode
    (
        decoded   : decode_state_t;
        cur_state : opstate_t;
        data_in   : reg_t
    )
    return opstate_t;

end lib_cpu_exec;

package body lib_cpu_exec is

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
                           data_in(0 downto 0);
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
            when IN_TAS =>
                next_state.stack := cur_state.x and cur_state.a;
            when IN_XAA =>
                next_state.a := cur_state.x and data_in;
                next_state.status.z := next_state.a = x"00";
                next_state.status.n := next_state.a(7) = '1';
            when IN_LAS =>
                scratch(reg_t'range) := cur_state.stack and data_in;

                next_state.a := scratch(reg_t'range);
                next_state.x := scratch(reg_t'range);
                next_state.stack := scratch(reg_t'range);

                next_state.status.z := scratch(reg_t'range) = x"00";
                next_state.status.n := scratch(7) = '1';
            when others =>
        end case;

        return next_state;
    end;

end package body;