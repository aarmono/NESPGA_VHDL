library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.de1_types.all;

entity vga_gen is
port
(
    clk     : in std_logic;
    reset   : in boolean;

    sram_dq   : in std_logic_vector(15 downto 0);
    sram_addr : out std_logic_vector(17 downto 0);
    sram_oe_n : out std_logic;
    sram_ce_n : out std_logic;

    vga_out     : out vga_out_t
);
end vga_gen;

architecture behavioral of vga_gen
is
    subtype time_t is natural range 0 to 2**10-1;
    subtype pixel_coord_t is natural range 0 to 2**8-1;

    type video_time_t is record
        row : time_t;
        col : time_t;
    end record;

    constant TIME_ZERO : video_time_t :=
    (
        row => 0,
        col => 0
    );

    -- The sum of all these values should equal 800
    constant LINE_SYNC_TIME         : time_t := 96;
    -- Normally 48 for 640 pixels, but 112 for 512
    constant LINE_BACK_PORCH_TIME   : time_t := 96;
    -- Time before the active period where the sram bus is taken
    constant LINE_LEFT_MARGIN_TIME  : time_t := 16;
    -- Normally 640, but NES is 512
    constant LINE_ACTIVE_TIME       : time_t := 512;
    -- Time after the active period where the SRAM bus is taken
    constant LINE_RIGHT_MARGIN_TIME : time_t := 16;
    -- Normally 16 for 640 pixels, but 80 for 512
    constant LINE_FRONT_PORCH_TIME  : time_t := 64;

    constant FRAME_SYNC_TIME         : time_t := 2;
    constant FRAME_BACK_PORCH_TIME   : time_t := 32;
    constant FRAME_ACTIVE_TIME       : time_t := 480;
    constant FRAME_FRONT_PORCH_TIME  : time_t := 11;

    constant LINE_END : time_t := LINE_SYNC_TIME +
                                  LINE_BACK_PORCH_TIME +
                                  LINE_LEFT_MARGIN_TIME +
                                  LINE_ACTIVE_TIME +
                                  LINE_RIGHT_MARGIN_TIME +
                                  LINE_FRONT_PORCH_TIME -
                                  1;
    constant FRAME_END : time_t := FRAME_SYNC_TIME +
                                   FRAME_BACK_PORCH_TIME +
                                   FRAME_ACTIVE_TIME +
                                   FRAME_FRONT_PORCH_TIME -
                                   1;

    type vert_state_t is
    (
        V_FRONT,
        V_SYNC,
        V_ACTIVE,
        V_BACK
    );

    type horz_state_t is
    (
        H_FRONT,
        H_SYNC,
        H_RIGHT_MARGIN,
        H_ACTIVE,
        H_LEFT_MARGIN,
        H_BACK
    );

    function get_v_sync(state : vert_state_t) return std_logic
    is
    begin
        case state is
            when V_FRONT => return '1';
            when V_SYNC => return '0';
            when V_ACTIVE => return '1';
            when V_BACK => return '1';
        end case;
    end;

    function get_h_sync(state : horz_state_t) return std_logic
    is
    begin
        case state is
            when H_FRONT => return '1';
            when H_RIGHT_MARGIN => return '1';
            when H_SYNC => return '0';
            when H_ACTIVE => return '1';
            when H_BACK => return '1';
            when H_LEFT_MARGIN => return '1';
        end case;
    end;

    constant V_BACK_PORCH_START   : time_t := FRAME_SYNC_TIME;
    constant V_ACTIVE_START       : time_t := V_BACK_PORCH_START +
                                              FRAME_BACK_PORCH_TIME;
    constant V_FRONT_PORCH_START  : time_t := V_ACTIVE_START +
                                              FRAME_ACTIVE_TIME;

    function get_vert_state(cur_time : video_time_t) return vert_state_t
    is
    begin
        if cur_time.row < V_BACK_PORCH_START
        then
            return V_SYNC;
        elsif cur_time.row < V_ACTIVE_START
        then
            return V_BACK;
        elsif cur_time.row < V_FRONT_PORCH_START
        then
            return V_ACTIVE;
        else
            return V_FRONT;
        end if;
    end;

    constant H_BACK_PORCH_START   : time_t := LINE_SYNC_TIME;
    constant H_LEFT_MARGIN_START  : time_t := H_BACK_PORCH_START +
                                              LINE_BACK_PORCH_TIME;
    constant H_ACTIVE_START       : time_t := H_LEFT_MARGIN_START +
                                              LINE_LEFT_MARGIN_TIME;
    constant H_RIGHT_MARGIN_START : time_t := H_ACTIVE_START +
                                              LINE_ACTIVE_TIME;
    constant H_FRONT_PORCH_START  : time_t := H_RIGHT_MARGIN_START +
                                              LINE_RIGHT_MARGIN_TIME;

    function get_horz_state(cur_time : video_time_t) return horz_state_t
    is
    begin
        if cur_time.col < H_BACK_PORCH_START
        then
            return H_SYNC;
        elsif cur_time.col < H_LEFT_MARGIN_START
        then
            return H_BACK;
        elsif cur_time.col < H_ACTIVE_START
        then
            return H_LEFT_MARGIN;
        elsif cur_time.col < H_RIGHT_MARGIN_START
        then
            return H_ACTIVE;
        elsif cur_time.col < H_FRONT_PORCH_START
        then
            return H_RIGHT_MARGIN;
        else
            return H_FRONT;
        end if;
    end;

    function incr_time(cur_time : video_time_t) return video_time_t
    is
        variable ret : video_time_t := cur_time;
    begin
        if cur_time.col = LINE_END
        then
            ret.col := 0;
            if cur_time.row = FRAME_END
            then
                ret.row := 0;
            else
                ret.row := cur_time.row + 1;
            end if;
        else
            ret.col := cur_time.col + 1;
        end if;

        return ret;
    end;

    -- The SRAM bus is taken from the left margin to the right margin of
    -- active lines, and read during the active period
    function get_sram_ce_n(vert_state : vert_state_t;
                           horz_state : horz_state_t) return std_logic
    is
    begin
        if vert_state = V_ACTIVE and
           (horz_state = H_LEFT_MARGIN or
            horz_state = H_ACTIVE or
            horz_state = H_RIGHT_MARGIN)
        then
            return '0';
        else
            return '1';
        end if;
    end;

    function get_sram_oe_n(vert_state : vert_state_t;
                           horz_state : horz_state_t) return std_logic
    is
    begin
        if vert_state = V_ACTIVE and horz_state = H_ACTIVE
        then
            return '0';
        else
            return '1';
        end if;
    end;

    -- The state and SRAM enables are registered for the time in cur_time,
    -- rather than decoded from it, so that the SRAM enables are glitch free.
    -- ppu_video_ram_mux synchronizes sram_ce_n into its clock domain, where
    -- a glitch would let it take the SRAM bus during the active period
    type reg_t is record
        cur_time   : video_time_t;
        vert_state : vert_state_t;
        horz_state : horz_state_t;
        sram_oe_n  : std_logic;
        sram_ce_n  : std_logic;
        pixel_row  : pixel_coord_t;
        pixel_col  : pixel_coord_t;
        vga_out    : vga_out_t;
    end record;

    -- The states and SRAM enables are those of TIME_ZERO
    constant RESET_REG : reg_t :=
    (
        cur_time => TIME_ZERO,
        vert_state => V_SYNC,
        horz_state => H_SYNC,
        sram_oe_n => '1',
        sram_ce_n => '1',
        pixel_row => 0,
        pixel_col => 0,
        vga_out => VGA_RESET
    );

    function cycle_vga(reg : reg_t; dq : std_logic_vector(15 downto 0))
        return reg_t
    is
        variable ret : reg_t;
    begin
        ret := reg;
        ret.vga_out.v_sync := get_v_sync(reg.vert_state);
        ret.vga_out.h_sync := get_h_sync(reg.horz_state);
        ret.vga_out.lval := false;
        ret.vga_out.fval := false;

        case reg.vert_state is
            when V_FRONT =>
                ret.pixel_row := 0;
                ret.pixel_col := 0;
                ret.vga_out.color := COLOR_BLACK;
                ret.vga_out.fval := false;
            when V_SYNC =>
                ret.pixel_row := 0;
                ret.pixel_col := 0;
                ret.vga_out.color := COLOR_BLACK;
                ret.vga_out.fval := false;
            when V_ACTIVE =>
                ret.vga_out.fval := true;
                case reg.horz_state is
                    when H_FRONT |
                         H_RIGHT_MARGIN =>
                        ret.pixel_col := 0;
                        ret.vga_out.color := COLOR_BLACK;
                        ret.vga_out.lval := false;
                    when H_SYNC =>
                        ret.pixel_col := 0;
                        ret.vga_out.color := COLOR_BLACK;
                        ret.vga_out.lval := false;
                    when H_ACTIVE =>
                        ret.vga_out.color.red := dq(11 downto 8);
                        ret.vga_out.color.green := dq(7 downto 4);
                        ret.vga_out.color.blue := dq(3 downto 0);
                        ret.vga_out.lval := true;

                        if reg.cur_time.col mod 2 = 1
                        then
                            ret.pixel_col := wrap(reg.pixel_col + 1,
                                                  pixel_coord_t'high);
                        end if;
                    when H_BACK |
                         H_LEFT_MARGIN =>
                        ret.pixel_col := 0;
                        ret.vga_out.color := COLOR_BLACK;
                        ret.vga_out.lval := false;
                end case;

                if reg.cur_time.col = LINE_END and reg.cur_time.row mod 2 = 1
                then
                    ret.pixel_row := wrap(reg.pixel_row + 1,
                                          pixel_coord_t'high);
                end if;

            when V_BACK =>
                ret.pixel_row := 0;
                ret.pixel_col := 0;
                ret.vga_out.fval := false;
                ret.vga_out.color := COLOR_BLACK;
        end case;

        ret.cur_time := incr_time(reg.cur_time);
        ret.vert_state := get_vert_state(ret.cur_time);
        ret.horz_state := get_horz_state(ret.cur_time);
        ret.sram_oe_n := get_sram_oe_n(ret.vert_state, ret.horz_state);
        ret.sram_ce_n := get_sram_ce_n(ret.vert_state, ret.horz_state);

        return ret;
    end;

    signal reg : reg_t := RESET_REG;

begin

    vga_out <= reg.vga_out;

    sram_oe_n <= reg.sram_oe_n;
    sram_ce_n <= reg.sram_ce_n;

    sram_addr <= "00" &
                 to_std_logic_vector(reg.pixel_row, 8) &
                 to_std_logic_vector(reg.pixel_col, 8);

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= cycle_vga(reg, sram_dq);
        end if;
    end if;
    end process;

end behavioral;
