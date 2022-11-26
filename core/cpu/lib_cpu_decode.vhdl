library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_cpu_types.all;
use work.lib_cpu_decode_defs.all;

package lib_cpu_decode is

    -- Pseudo-opcodes that on a real 6502
    -- halt the CPU
    constant OP_RESET : data_t := x"F2";
    constant OP_NMI   : data_t := x"12";
    constant OP_IRQ   : data_t := x"22";

    function get_decode_state
    (
        opcode  : data_t;
        opstate : opstate_t;
        addr_hi : reg_t
    )
    return decode_state_t;

end lib_cpu_decode;

package body lib_cpu_decode is

    function get_decode_state
    (
        opcode  : data_t;
        opstate : opstate_t;
        addr_hi : reg_t
    )
    return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := decode_sbi(IN_NOP);

        case opcode is
            -- BRK
            when x"00" =>
                ret := decode_brk(x"FE", true);
            -- ORA (d,X)
            when x"01" =>
                ret := decode_ind_x_r(IN_ORA);
            -- SLO (d,X)
            when x"03" =>
                ret := decode_ind_x_rw(IN_SLO);
            -- NOP d
            when x"04" |
                 x"44" |
                 x"64" =>
                ret := decode_zero_r(IN_NOP);
            -- ORA d
            when x"05" =>
                ret := decode_zero_r(IN_ORA);
            -- ASL d
            when x"06" =>
                ret := decode_zero_rw(IN_ASL);
            -- SLO d
            when x"07" =>
                ret := decode_zero_rw(IN_SLO);
            -- PHP
            when x"08" =>
                ret := decode_push(to_reg_t(opstate.status, true));
            -- ORA #
            when x"09" =>
                ret := decode_imm(IN_ORA);
            -- ASL A
            when x"0A" =>
                ret := decode_sbi(IN_ASL);
            -- ANC #
            when x"0B" |
                 x"2B" =>
                ret := decode_imm(IN_ANC);
            -- NOP a
            when x"0C" =>
                ret := decode_abs_r(IN_NOP);
            -- ORA a
            when x"0D" =>
                ret := decode_abs_r(IN_ORA);
            -- ASL a
            when x"0E" =>
                ret := decode_abs_rw(IN_ASL);
            -- SLO a
            when x"0F" =>
                ret := decode_abs_rw(IN_SLO);

            -- BPL r
            when x"10" =>
                ret := decode_branch(to_unsigned(0, 5) &
                                     to_unsigned(7, 3));
            -- ORA (d),Y
            when x"11" =>
                ret := decode_ind_y_r(IN_ORA);
            -- SLO (d),Y
            when x"13" =>
                ret := decode_ind_y_rw(IN_SLO);
            -- NOP d,X
            when x"14" |
                 x"34" |
                 x"54" |
                 x"74" |
                 x"D4" |
                 x"F4" =>
                ret := decode_ind_x_r(IN_NOP);
            -- ORA d,X
            when x"15" =>
                ret := decode_zero_x_r(opstate, IN_ORA);
            -- ASL d,X
            when x"16" =>
                ret := decode_zero_x_rw(opstate, IN_ASL);
            -- SLO d,X
            when x"17" =>
                ret := decode_zero_x_rw(opstate, IN_SLO);
            -- CLC
            when x"18" =>
                ret := decode_sbi(IN_CLC);
            -- ORA a,Y
            when x"19" =>
                ret := decode_abs_y_r(opstate, IN_ORA);
            -- SLO a,Y
            when x"1B" =>
                ret := decode_abs_y_rw(opstate, IN_SLO);
            -- NOP a,X
            when x"1C" |
                 x"3C" |
                 x"5C" |
                 x"7C" |
                 x"DC" |
                 x"FC" =>
                ret := decode_abs_x_r(opstate, IN_NOP);
            -- ORA a,X
            when x"1D" =>
                ret := decode_abs_x_r(opstate, in_ORA);
            -- ASL a,X
            when x"1E" =>
                ret := decode_abs_x_rw(opstate, IN_ASL);
            -- SLO a,X
            when x"1F" =>
                ret := decode_abs_x_rw(opstate, IN_SLO);

            -- JSR a
            when x"20" =>
                ret := DECODE_JSR;
            -- AND (d,X)
            when x"21" =>
                ret := decode_ind_x_r(IN_AND);
            -- RLA (d,X)
            when x"23" =>
                ret := decode_ind_x_rw(IN_RLA);
            -- BIT d
            when x"24" =>
                ret := decode_zero_r(IN_BIT);
            -- AND d
            when x"25" =>
                ret := decode_zero_r(IN_AND);
            -- ROL d
            when x"26" =>
                ret := decode_zero_rw(IN_ROL);
            -- RLA d
            when x"27" =>
                ret := decode_zero_rw(IN_RLA);
            -- PLP
            when x"28" =>
                ret := decode_pull(IN_PLP);
            -- AND #
            when x"29" =>
                ret := decode_imm(IN_AND);
            -- ROL A
            when x"2A" =>
                ret := decode_sbi(IN_ROL);
            -- BIT a
            when x"2C" =>
                ret := decode_abs_r(IN_BIT);
            -- AND a
            when x"2D" =>
                ret := decode_abs_r(IN_AND);
            -- ROL a
            when x"2E" =>
                ret := decode_abs_rw(IN_ROL);
            when x"2F" =>
                ret := decode_abs_rw(IN_RLA);

            -- BMI r
            when x"30" =>
                ret := decode_branch(to_unsigned(1, 5) &
                                     to_unsigned(7, 3));
            -- AND (d),Y
            when x"31" =>
                ret := decode_ind_y_r(IN_AND);
            -- RLA (d),Y
            when x"33" =>
                ret := decode_ind_y_rw(IN_RLA);
            -- AND d,X
            when x"35" =>
                ret := decode_zero_x_r(opstate, IN_AND);
            -- ROL d,X
            when x"36" =>
                ret := decode_zero_x_rw(opstate, IN_ROL);
            -- RLA d,X
            when x"37" =>
                ret := decode_zero_x_rw(opstate, IN_RLA);
            -- SEC
            when x"38" =>
                ret := decode_sbi(IN_SEC);
            -- AND a,Y
            when x"39" =>
                ret := decode_abs_y_r(opstate, IN_AND);
            -- RLA a,Y
            when x"3B" =>
                ret := decode_abs_y_rw(opstate, IN_RLA);
            -- AND a,X
            when x"3D" =>
                ret := decode_abs_x_r(opstate, IN_AND);
            -- ROL a,X
            when x"3E" =>
                ret := decode_abs_x_rw(opstate, IN_ROL);
            -- RLA a,X
            when x"3F" =>
                ret := decode_abs_x_rw(opstate, IN_RLA);

            -- RTI
            when x"40" =>
                ret := DECODE_RTI;
            -- EOR (d,X)
            when x"41" =>
                ret := decode_ind_x_r(IN_EOR);
            -- SRE (d,X)
            when x"43" =>
                ret := decode_ind_x_rw(IN_SRE);
            -- EOR d
            when x"45" =>
                ret := decode_zero_r(IN_EOR);
            -- LSR d
            when x"46" =>
                ret := decode_zero_rw(IN_LSR);
            -- SRE d
            when x"47" =>
                ret := decode_zero_rw(IN_SRE);
            -- PHA
            when x"48" =>
                ret := decode_push(opstate.a);
            -- EOR #
            when x"49" =>
                ret := decode_imm(IN_EOR);
            -- LSR A
            when x"4A" =>
                ret := decode_sbi(IN_LSR);
            -- ALR #
            when x"4B" =>
                ret := decode_imm(IN_ALR);
            -- JMP a
            when x"4C" =>
                ret := DECODE_JMP_ABS;
            -- EOR a
            when x"4D" =>
                ret := decode_abs_r(IN_EOR);
            -- LSR a
            when x"4E" =>
                ret := decode_abs_rw(IN_LSR);
            -- SRE a
            when x"4F" =>
                ret := decode_abs_rw(IN_SRE);

            -- BVC r
            when x"50" =>
                ret := decode_branch(to_unsigned(0, 5) &
                                     to_unsigned(6, 3));
            -- EOR (d),Y
            when x"51" =>
                ret := decode_ind_y_r(IN_EOR);
            -- SRE (d),Y
            when x"53" =>
                ret := decode_ind_y_rw(IN_SRE);
            -- EOR d,X
            when x"55" =>
                ret := decode_zero_x_r(opstate, IN_EOR);
            -- LSR d,X
            when x"56" =>
                ret := decode_zero_x_rw(opstate, IN_LSR);
            -- SRE d,X
            when x"57" =>
                ret := decode_zero_x_rw(opstate, IN_SRE);
            -- CLI
            when x"58" =>
                ret := decode_sbi(IN_CLI);
            -- EOR a,Y
            when x"59" =>
                ret := decode_abs_y_r(opstate, IN_EOR);
            -- SRE a,Y
            when x"5B" =>
                ret := decode_abs_y_rw(opstate, IN_SRE);
            -- EOR a,X
            when x"5D" =>
                ret := decode_abs_x_r(opstate, IN_EOR);
            -- LSR a,X
            when x"5E" =>
                ret := decode_abs_x_rw(opstate, IN_LSR);
            -- SRE a,X
            when x"5F" =>
                ret := decode_abs_x_rw(opstate, IN_SRE);

            -- RTS
            when x"60" =>
                ret := DECODE_RTS;
            -- ADC (d,X)
            when x"61" =>
                ret := decode_ind_x_r(IN_ADC);
            -- RRA (d,X)
            when x"63" =>
                ret := decode_ind_x_rw(IN_RRA);
            -- ADC d
            when x"65" =>
                ret := decode_zero_r(IN_ADC);
            -- ROR d
            when x"66" =>
                ret := decode_zero_rw(IN_ROR);
            -- RRA d
            when x"67" =>
                ret := decode_zero_rw(IN_RRA);
            -- PLA
            when x"68" =>
                ret := decode_pull(IN_PLA);
            -- ADC #
            when x"69" =>
                ret := decode_imm(IN_ADC);
            -- ROR A
            when x"6A" =>
                ret := decode_sbi(IN_ROR);
            -- ARR #
            when x"6B" =>
                ret := decode_imm(IN_ARR);
            -- JMP (a)
            when x"6C" =>
                ret := DECODE_JMP_IND;
            -- ADC a
            when x"6D" =>
                ret := decode_abs_r(IN_ADC);
            -- ROR a
            when x"6E" =>
                ret := decode_abs_rw(IN_ROR);
            -- RRA a
            when x"6F" =>
                ret := decode_abs_rw(IN_RRA);

            -- BVS r
            when x"70" =>
                ret := decode_branch(to_unsigned(1, 5) &
                                     to_unsigned(6, 3));
            -- ADC (d),Y
            when x"71" =>
                ret := decode_ind_y_r(IN_ADC);
            -- RRA (d),Y
            when x"73" =>
                ret := decode_ind_y_rw(IN_RRA);
            -- ADC d,X
            when x"75" =>
                ret := decode_zero_x_r(opstate, IN_ADC);
            -- ROR d,X
            when x"76" =>
                ret := decode_zero_x_rw(opstate, IN_ROR);
            -- RRA d, X
            when x"77" =>
                ret := decode_zero_x_rw(opstate, IN_RRA);
            -- SEI
            when x"78" =>
                ret := decode_sbi(IN_SEI);
            -- ADC a,Y
            when x"79" =>
                ret := decode_abs_y_r(opstate, IN_ADC);
            -- RRA a,Y
            when x"7B" =>
                ret := decode_abs_y_rw(opstate, IN_RRA);
            -- ADC a,X
            when x"7D" =>
                ret := decode_abs_x_r(opstate, IN_ADC);
            -- ROR a,X
            when x"7E" =>
                ret := decode_abs_x_rw(opstate, IN_ROR);
            -- RRA a,X
            when x"7F" =>
                ret := decode_abs_x_rw(opstate, IN_RRA);

            -- NOP #
            when x"80" |
                 x"82" |
                 x"89" |
                 x"C2" |
                 x"E2" =>
                ret := decode_imm(IN_NOP);
            -- STA (d,X)
            when x"81" =>
                ret := decode_ind_x_w(opstate.a);
            -- AAX (d,X)
            when x"83" =>
                ret := decode_ind_x_w(opstate.a and opstate.x);
            -- STY d
            when x"84" =>
                ret := decode_zero_w(opstate.y);
            -- STA d
            when x"85" =>
                ret := decode_zero_w(opstate.a);
            -- STX d
            when x"86" =>
                ret := decode_zero_w(opstate.x);
            -- AAX d
            when x"87" =>
                ret := decode_zero_w(opstate.a and opstate.x);
            -- DEY
            when x"88" =>
                ret := decode_sbi(IN_DEY);
            -- TXA
            when x"8A" =>
                ret := decode_sbi(in_TXA);
            -- XAA #
            when x"8B" =>
                ret := decode_imm(IN_XAA);
            -- STY a
            when x"8C" =>
                ret := decode_abs_w(opstate.y);
            -- STA a
            when x"8D" =>
                ret := decode_abs_w(opstate.a);
            -- STX a
            when x"8E" =>
                ret := decode_abs_w(opstate.x);
            -- AAX a
            when x"8F" =>
                ret := decode_abs_w(opstate.a and opstate.x);

            -- BCC r
            when x"90" =>
                ret := decode_branch(to_unsigned(0, 5) &
                                     to_unsigned(0, 3));
            -- STA (d),Y
            when x"91" =>
                ret := decode_ind_y_w(opstate.a);
            -- AHX (d),Y
            when x"93" =>
                ret := decode_ind_y_w(opstate.x and
                                      opstate.a and
                                      (addr_hi + "1"));
            -- STY d,X
            when x"94" =>
                ret := decode_zero_x_w(opstate, opstate.y);
            -- STA d,X
            when x"95" =>
                ret := decode_zero_x_w(opstate, opstate.a);
            -- STX d,Y
            when x"96" =>
                ret := decode_zero_y_w(opstate, opstate.x);
            -- AAX d,Y
            when x"97" =>
                ret := decode_zero_y_w(opstate, opstate.a and opstate.x);
            -- TYA
            when x"98" =>
                ret := decode_sbi(IN_TYA);
            -- STA a,Y
            when x"99" =>
                ret := decode_abs_y_w(opstate, opstate.a);
            -- TXS
            when x"9A" =>
                ret := decode_sbi(IN_TXS);
            -- TAS a,Y
            when x"9B" =>
                ret :=
                    decode_abs_y_w(opstate,
                                   opstate.x and opstate.a and (addr_hi + "1"),
                                   IN_TAS);
            -- SYA a,X
            when x"9C" =>
                ret := decode_sya_w(opstate);
            -- STA a,X
            when x"9D" =>
                ret := decode_abs_x_w(opstate, opstate.a);
            -- SXA a,Y
            when x"9E" =>
                ret := decode_sxa_w(opstate);
            -- AHX a,Y
            when x"9F" =>
                ret :=
                    decode_abs_y_w(opstate,
                                   opstate.x and opstate.a and (addr_hi + "1"));

            -- LDY #
            when x"A0" =>
                ret := decode_imm(IN_LDY);
            -- LDA (d,X)
            when x"A1" =>
                ret := decode_ind_x_r(IN_LDA);
            -- LDX #
            when x"A2" =>
                ret := decode_imm(IN_LDX);
            -- LAX (d,X)
            when x"A3" =>
                ret := decode_ind_x_r(IN_LAX);
            -- LDY d
            when x"A4" =>
                ret := decode_zero_r(IN_LDY);
            -- LDA d
            when x"A5" =>
                ret := decode_zero_r(IN_LDA);
            -- LDX d
            when x"A6" =>
                ret := decode_zero_r(IN_LDX);
            -- LAX d
            when x"A7" =>
                ret := decode_zero_r(IN_LAX);
            -- TAY
            when x"A8" =>
                ret := decode_sbi(IN_TAY);
            -- LDA #
            when x"A9"=>
                ret := decode_imm(IN_LDA);
            -- TAX
            when x"AA" =>
                ret := decode_sbi(IN_TAX);
            -- LAX #
            when x"AB" =>
                ret := decode_imm(IN_LAX);
            -- LDY a
            when x"AC" =>
                ret := decode_abs_r(IN_LDY);
            -- LDA a
            when x"AD" =>
                ret := decode_abs_r(IN_LDA);
            -- LDX a
            when x"AE" =>
                ret := decode_abs_r(IN_LDX);
            -- LAX a
            when x"AF" =>
                ret := decode_abs_r(IN_LAX);

            -- BCS r
            when x"B0" =>
                ret := decode_branch(to_unsigned(1, 5) &
                                     to_unsigned(0, 3));
            -- LDA (d),Y
            when x"B1" =>
                ret := decode_ind_y_r(IN_LDA);
            -- LAX (d),Y
            when x"B3" =>
                ret := decode_ind_y_r(IN_LAX);
            -- LDY d,X
            when x"B4" =>
                ret := decode_zero_x_r(opstate, IN_LDY);
            -- LDA d,X
            when x"B5" =>
                ret := decode_zero_x_r(opstate, IN_LDA);
            -- LDX d,Y
            when x"B6" =>
                ret := decode_zero_y_r(opstate, IN_LDX);
            -- LAX d,Y
            when x"B7" =>
                ret := decode_zero_y_r(opstate, IN_LAX);
            -- CLV
            when x"B8" =>
                ret := decode_sbi(IN_CLV);
            -- LDA a,Y
            when x"B9" =>
                ret := decode_abs_y_r(opstate, IN_LDA);
            -- TSX
            when x"BA" =>
                ret := decode_sbi(IN_TSX);
            -- LAS a,Y
            when x"BB" =>
                ret := decode_abs_y_r(opstate, IN_LAS);
            -- LDY a,X
            when x"BC" =>
                ret := decode_abs_x_r(opstate, IN_LDY);
            -- LDA a,X
            when x"BD" =>
                ret := decode_abs_x_r(opstate, IN_LDA);
            -- LDX a,Y
            when x"BE" =>
                ret := decode_abs_y_r(opstate, IN_LDX);
            -- LAX a,Y
            when x"BF" =>
                ret := decode_abs_y_r(opstate, IN_LAX);

            -- CPY #
            when x"C0" =>
                ret := decode_imm(IN_CPY);
            -- CMP (d,X)
            when x"C1" =>
                ret := decode_ind_x_r(IN_CMP);
            -- DCP (d,X)
            when x"C3" =>
                ret := decode_ind_x_rw(IN_DCP);
            -- CPY d
            when x"C4" =>
                ret := decode_zero_r(IN_CPY);
            -- CMP d
            when x"C5" =>
                ret := decode_zero_r(IN_CMP);
            -- DEC d
            when x"C6" =>
                ret := decode_zero_rw(IN_DEC);
            -- DCP d
            when x"C7" =>
                ret := decode_zero_rw(IN_DCP);
            -- INY
            when x"C8" =>
                ret := decode_sbi(IN_INY);
            -- CMP #
            when x"C9" =>
                ret := decode_imm(IN_CMP);
            -- DEX
            when x"CA" =>
                ret := decode_sbi(IN_DEX);
            -- AXS
            when x"CB" =>
                ret := decode_imm(IN_AXS);
            -- CPY a
            when x"CC" =>
                ret := decode_abs_r(IN_CPY);
            -- CMP a
            when x"CD" =>
                ret := decode_abs_r(IN_CMP);
            -- DEC a
            when x"CE" =>
                ret := decode_abs_rw(IN_DEC);
            -- DCP a
            when x"CF" =>
                ret := decode_abs_rw(IN_DCP);

            -- BNE r
            when x"D0" =>
                ret := decode_branch(to_unsigned(0, 5) &
                                     to_unsigned(1, 3));
            -- CMP (d),Y
            when x"D1" =>
                ret := decode_ind_y_r(IN_CMP);
            -- DCP (d),Y
            when x"D3" =>
                ret := decode_ind_y_rw(IN_DCP);
            -- CMP d,X
            when x"D5" =>
                ret := decode_zero_x_r(opstate, IN_CMP);
            -- DEC d,X
            when x"D6" =>
                ret := decode_zero_x_rw(opstate, IN_DEC);
            -- DCP d,X
            when x"D7" =>
                ret := decode_zero_x_rw(opstate, IN_DCP);
            -- CLD
            when x"D8" =>
                ret := decode_sbi(IN_CLD);
            -- CMP a,Y
            when x"D9" =>
                ret := decode_abs_y_r(opstate, IN_CMP);
            -- DCP a,Y
            when x"DB" =>
                ret := decode_abs_y_rw(opstate, IN_DCP);
            -- CMP a,X
            when x"DD" =>
                ret := decode_abs_x_r(opstate, IN_CMP);
            -- DEC a,X
            when x"DE" =>
                ret := decode_abs_x_rw(opstate, IN_DEC);
            -- DCP a,X
            when x"DF" =>
                ret := decode_abs_x_rw(opstate, IN_DCP);

            -- CPX #
            when x"E0" =>
                ret := decode_imm(IN_CPX);
            -- SBC (d,X)
            when x"E1" =>
                ret := decode_ind_x_r(IN_SBC);
            -- ISC (d,X)
            when x"E3" =>
                ret := decode_ind_x_rw(IN_ISC);
            -- CPX d
            when x"E4" =>
                ret := decode_zero_r(IN_CPX);
            -- SBC d
            when x"E5" =>
                ret := decode_zero_r(IN_SBC);
            -- INC d
            when x"E6" =>
                ret := decode_zero_rw(IN_INC);
            -- ISC d
            when x"E7" =>
                ret := decode_zero_rw(IN_ISC);
            -- INX
            when x"E8" =>
                ret := decode_sbi(IN_INX);
            -- SBC #
            when x"E9" |
                 x"EB" =>
                ret := decode_imm(IN_SBC);
            -- NOP
            when x"EA" |
                 x"1A" |
                 x"3A" |
                 x"5A" |
                 x"7A" |
                 x"DA" |
                 x"FA" =>
                ret := decode_sbi(IN_NOP);
            -- CPX a
            when x"EC" =>
                ret := decode_abs_r(IN_CPX);
            -- SBC a
            when x"ED" =>
                ret := decode_abs_r(IN_SBC);
            -- INC a
            when x"EE" =>
                ret := decode_abs_rw(IN_INC);
            -- ISC a
            when x"EF" =>
                ret := decode_abs_rw(IN_ISC);

            -- BEQ r
            when x"F0" =>
                ret := decode_branch(to_unsigned(1, 5) &
                                     to_unsigned(1, 3));
            -- SBC (d),Y
            when x"F1" =>
                ret := decode_ind_y_r(IN_SBC);
            -- ISC (d),Y
            when x"F3" =>
                ret := decode_ind_y_rw(IN_ISC);
            -- SBC d,X
            when x"F5" =>
                ret := decode_zero_x_r(opstate, IN_SBC);
            -- INC d,X
            when x"F6" =>
                ret := decode_zero_x_rw(opstate, IN_INC);
            -- ISC d,X
            when x"F7" =>
                ret := decode_zero_x_rw(opstate, IN_ISC);
            -- SED
            when x"F8" =>
                ret := decode_sbi(IN_SED);
            -- SBC a,Y
            when x"F9" =>
                ret := decode_abs_y_r(opstate, IN_SBC);
            -- ISC a,Y
            when x"FB" =>
                ret := decode_abs_y_rw(opstate, IN_ISC);
            -- SBC a,X
            when x"FD" =>
                ret := decode_abs_x_r(opstate, IN_SBC);
            -- INC a,X
            when x"FE" =>
                ret := decode_abs_x_rw(opstate, IN_INC);
            -- ISC a,X
            when x"FF" =>
                ret := decode_abs_x_rw(opstate, IN_ISC);
            -- RESET
            when OP_RESET =>
                ret := decode_brk(x"FC", false);
            when OP_NMI =>
                ret := decode_brk(x"FA", false);
            when OP_IRQ =>
                ret := decode_brk(x"FE", false);
            when others =>
                assert false report "Invalid opcode: " & to_hstring(opcode)
                             severity failure;
        end case;

        return ret;
    end;

end package body;