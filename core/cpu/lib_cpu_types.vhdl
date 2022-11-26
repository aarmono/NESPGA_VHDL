library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;

package lib_cpu_types is

    type addr_mode_t is
    (
        MODE_SBI,
        MODE_IMM,
        MODE_ZERO,
        MODE_ABS,
        MODE_IND_X,
        MODE_ABS_IDX,
        MODE_ZERO_IDX,
        MODE_IND_Y,
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
        IN_ISC,
        IN_TAS,
        IN_XAA,
        IN_LAS
    );

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

    type decode_state_t is record
        mode        : addr_mode_t;
        instruction : instruction_t;
        reg         : reg_t;
        idx_reg     : reg_t;
        read        : boolean;
        write       : boolean;
        incr_pc     : boolean;
        next_count  : count_t;
        special     : boolean;
    end record;

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

    function to_reg_t(status : status_t; b : boolean) return reg_t;

    function to_status_t(stat_in : data_t) return status_t;

end lib_cpu_types;

package body lib_cpu_types is

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

end package body;