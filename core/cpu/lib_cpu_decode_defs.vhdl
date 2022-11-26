library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.lib_cpu_types.all;

package lib_cpu_decode_defs is

    constant REG_NONE : reg_t := (others => '-');

    constant DECODE_SBI_INIT : decode_state_t :=
    (
        mode        => MODE_SBI,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => false,
        next_count  => CYC_0,
        special     => false
    );

    constant DECODE_IMM_INIT : decode_state_t :=
    (
        mode        => MODE_IMM,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_0,
        special     => false
    );

    constant DECODE_ZERO_INIT : decode_state_t :=
    (
        mode        => MODE_ZERO,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_3,
        special     => false
    );

    constant DECODE_ABS_INIT : decode_state_t :=
    (
        mode        => MODE_ABS,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_4,
        special     => false
    );

    constant DECODE_ABS_IDX_INIT : decode_state_t :=
    (
        mode        => MODE_ABS_IDX,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_5,
        special     => false
    );

    constant DECODE_ZERO_IDX_INIT : decode_state_t :=
    (
        mode        => MODE_ZERO_IDX,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_4,
        special     => false
    );

    constant DECODE_IND_X_INIT : decode_state_t :=
    (
        mode        => MODE_IND_X,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_6,
        special     => false
    );

    constant DECODE_IND_Y_INIT : decode_state_t :=
    (
        mode        => MODE_IND_Y,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_6,
        special     => false
    );

    constant DECODE_BRK_INIT : decode_state_t :=
    (
        mode        => MODE_BRK,
        instruction => IN_NOP,
        incr_pc     => false,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        next_count  => CYC_5,
        special     => false
    );

    constant DECODE_PUSH_INIT : decode_state_t :=
    (
        mode        => MODE_PUSH,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => false,
        next_count  => CYC_1,
        special     => false
    );

    constant DECODE_PULL_INIT : decode_state_t :=
    (
        mode        => MODE_PULL,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => false,
        next_count  => CYC_2,
        special     => false
    );

    constant DECODE_BRANCH_INIT : decode_state_t :=
    (
        mode        => MODE_BRANCH,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_2,
        special     => false
    );

    constant DECODE_JSR : decode_state_t :=
    (
        mode        => MODE_JSR,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_4,
        special     => false
    );

    constant DECODE_RTI : decode_state_t :=
    (
        mode        => MODE_RTI,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_4,
        special     => false
    );

    constant DECODE_JMP_ABS : decode_state_t :=
    (
        mode        => MODE_JMP_ABS,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_1,
        special     => false
    );

    constant DECODE_JMP_IND : decode_state_t :=
    (
        mode        => MODE_JMP_IND,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_3,
        special     => false
    );

    constant DECODE_RTS : decode_state_t :=
    (
        mode        => MODE_RTS,
        instruction => IN_NOP,
        reg         => (others => '-'),
        idx_reg     => (others => '-'),
        read        => false,
        write       => false,
        incr_pc     => true,
        next_count  => CYC_4,
        special     => false
    );

    function decode_sbi(instruction : instruction_t) return decode_state_t;

    function decode_imm(instruction : instruction_t) return decode_state_t;

    function decode_zero
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t
    )
    return decode_state_t;

    function decode_zero_r(instruction : instruction_t) return decode_state_t;

    function decode_zero_w(reg : reg_t) return decode_state_t;

    function decode_zero_rw(instruction : instruction_t) return decode_state_t;

    function decode_abs
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t
    )
    return decode_state_t;

    function decode_abs_r(instruction : instruction_t) return decode_state_t;

    function decode_abs_rw(instruction : instruction_t) return decode_state_t;

    function decode_abs_w(reg : reg_t) return decode_state_t;

    function decode_abs_idx
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t;
        idx_reg     : reg_t
    )
    return decode_state_t;

    function decode_abs_x_r
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_abs_y_r
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_abs_x_rw
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_abs_y_rw
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_abs_x_w(opstate : opstate_t; reg : reg_t) return decode_state_t;

    function decode_abs_y_w(opstate : opstate_t; reg : reg_t) return decode_state_t;

    function decode_abs_y_w
    (
        opstate     : opstate_t;
        reg         : reg_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_sya_w(opstate : opstate_t) return decode_state_t;

    function decode_sxa_w(opstate : opstate_t) return decode_state_t;

    function decode_zero_idx
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t;
        idx_reg     : reg_t
    )
    return decode_state_t;

    function decode_zero_x_r
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_zero_y_r
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_zero_x_rw
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_zero_y_rw
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t;

    function decode_zero_x_w(opstate : opstate_t; reg : reg_t) return decode_state_t;

    function decode_zero_y_w(opstate : opstate_t; reg : reg_t) return decode_state_t;

    function decode_ind_x
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t
    )
    return decode_state_t;

    function decode_ind_x_r(instruction : instruction_t) return decode_state_t;

    function decode_ind_x_rw(instruction : instruction_t) return decode_state_t;

    function decode_ind_x_w(reg : reg_t) return decode_state_t;

    function decode_ind_y
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t
    )
    return decode_state_t;

    function decode_ind_y_r(instruction : instruction_t) return decode_state_t;

    function decode_ind_y_rw(instruction : instruction_t) return decode_state_t;

    function decode_ind_y_w(reg : reg_t) return decode_state_t;

    function decode_brk(reg : reg_t; incr_pc : boolean) return decode_state_t;

    function decode_push(reg : reg_t) return decode_state_t;

    function decode_pull(instruction : instruction_t) return decode_state_t;

    function decode_branch(reg : reg_t) return decode_state_t;

end lib_cpu_decode_defs;

package body lib_cpu_decode_defs is

    function decode_sbi(instruction : instruction_t) return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_SBI_INIT;
        ret.instruction := instruction;

        return ret;
    end;

    function decode_imm(instruction : instruction_t) return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_IMM_INIT;
        ret.instruction := instruction;

        return ret;
    end;

    function decode_zero
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t
    )
    return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_ZERO_INIT;
        ret.read := read;
        ret.write := write;
        ret.instruction := instruction;
        ret.reg := reg;

        return ret;
    end;

    function decode_zero_r(instruction : instruction_t) return decode_state_t
    is
    begin
        return decode_zero(true, false, instruction, REG_NONE);
    end;

    function decode_zero_w(reg : reg_t) return decode_state_t
    is
    begin
        return decode_zero(false, true, IN_NOP, reg);
    end;

    function decode_zero_rw(instruction : instruction_t) return decode_state_t
    is
    begin
        return decode_zero(true, true, instruction, REG_NONE);
    end;

    function decode_abs
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t
    )
    return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_ABS_INIT;
        ret.read := read;
        ret.write := write;
        ret.instruction := instruction;
        ret.reg := reg;

        return ret;
    end;

    function decode_abs_r(instruction : instruction_t) return decode_state_t
    is
    begin
        return decode_abs(true, false, instruction, REG_NONE);
    end;

    function decode_abs_w(reg : reg_t) return decode_state_t
    is
    begin
        return decode_abs(false, true, IN_NOP, reg);
    end;

    function decode_abs_rw(instruction : instruction_t) return decode_state_t
    is
    begin
        return decode_abs(true, true, instruction, REG_NONE);
    end;

    function decode_abs_idx
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t;
        idx_reg     : reg_t
    )
    return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_ABS_IDX_INIT;
        ret.read := read;
        ret.write := write;
        ret.instruction := instruction;
        ret.reg := reg;
        ret.idx_reg := idx_reg;

        return ret;
    end;

    function decode_abs_x_r
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_abs_idx(true, false, instruction, REG_NONE, opstate.x);
    end;

    function decode_abs_y_r
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_abs_idx(true, false, instruction, REG_NONE, opstate.y);
    end;

    function decode_abs_x_rw
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_abs_idx(true, true, instruction, REG_NONE, opstate.x);
    end;

    function decode_abs_y_rw
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_abs_idx(true, true, instruction, REG_NONE, opstate.y);
    end;

    function decode_abs_x_w(opstate : opstate_t; reg : reg_t) return decode_state_t
    is
    begin
        return decode_abs_idx(false, true, IN_NOP, reg, opstate.x);
    end;

    function decode_abs_y_w(opstate : opstate_t; reg : reg_t) return decode_state_t
    is
    begin
        return decode_abs_y_w(opstate, reg, IN_NOP);
    end;

    function decode_abs_y_w
    (
        opstate     : opstate_t;
        reg         : reg_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_abs_idx(false, true, instruction, reg, opstate.y);
    end;

    function decode_sya_w(opstate : opstate_t) return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := decode_abs_idx(false, true, IN_NOP, opstate.y, opstate.x);
        ret.special := true;

        return ret;
    end;

    function decode_sxa_w(opstate : opstate_t) return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := decode_abs_idx(false, true, IN_NOP, opstate.x, opstate.y);
        ret.special := true;

        return ret;
    end;

    function decode_zero_idx
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t;
        idx_reg     : reg_t
    )
    return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_ZERO_IDX_INIT;
        ret.read := read;
        ret.write := write;
        ret.instruction := instruction;
        ret.reg := reg;
        ret.idx_reg := idx_reg;

        return ret;
    end;

    function decode_zero_x_r
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_zero_idx(true, false, instruction, REG_NONE, opstate.x);
    end;

    function decode_zero_y_r
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_zero_idx(true, false, instruction, REG_NONE, opstate.y);
    end;

    function decode_zero_x_rw
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_zero_idx(true, true, instruction, REG_NONE, opstate.x);
    end;

    function decode_zero_y_rw
    (
        opstate     : opstate_t;
        instruction : instruction_t
    )
    return decode_state_t
    is
    begin
        return decode_zero_idx(true, true, instruction, REG_NONE, opstate.y);
    end;

    function decode_zero_x_w(opstate : opstate_t; reg : reg_t) return decode_state_t
    is
    begin
        return decode_zero_idx(false, true, IN_NOP, reg, opstate.x);
    end;

    function decode_zero_y_w(opstate : opstate_t; reg : reg_t) return decode_state_t
    is
    begin
        return decode_zero_idx(false, true, IN_NOP, reg, opstate.y);
    end;

    function decode_ind_x
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t
    )
    return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_IND_X_INIT;
        ret.read := read;
        ret.write := write;
        ret.instruction := instruction;
        ret.reg := reg;

        return ret;
    end;

    function decode_ind_x_r(instruction : instruction_t) return decode_state_t
    is
    begin
        return decode_ind_x(true, false, instruction, REG_NONE);
    end;

    function decode_ind_x_rw(instruction : instruction_t) return decode_state_t
    is
    begin
        return decode_ind_x(true, true, instruction, REG_NONE);
    end;

    function decode_ind_x_w(reg : reg_t) return decode_state_t
    is
    begin
        return decode_ind_x(false, true, IN_NOP, reg);
    end;

    function decode_ind_y
    (
        read        : boolean;
        write       : boolean;
        instruction : instruction_t;
        reg         : reg_t
    )
    return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_IND_Y_INIT;
        ret.read := read;
        ret.write := write;
        ret.instruction := instruction;
        ret.reg := reg;

        return ret;
    end;

    function decode_ind_y_r(instruction : instruction_t) return decode_state_t
    is
    begin
        return decode_ind_y(true, false, instruction, REG_NONE);
    end;

    function decode_ind_y_rw(instruction : instruction_t) return decode_state_t
    is
    begin
        return decode_ind_y(true, true, instruction, REG_NONE);
    end;

    function decode_ind_y_w(reg : reg_t) return decode_state_t
    is
    begin
        return decode_ind_y(false, true, IN_NOP, reg);
    end;

    function decode_brk(reg : reg_t; incr_pc : boolean) return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_BRK_INIT;
        ret.reg := reg;
        ret.incr_pc := incr_pc;

        return ret;
    end;

    function decode_push(reg : reg_t) return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_PUSH_INIT;
        ret.reg := reg;

        return ret;
    end;

    function decode_pull(instruction : instruction_t) return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_PULL_INIT;
        ret.instruction := instruction;

        return ret;
    end;

    function decode_branch(reg : reg_t) return decode_state_t
    is
        variable ret : decode_state_t;
    begin
        ret := DECODE_BRANCH_INIT;
        ret.reg := reg;

        return ret;
    end;

end package body;