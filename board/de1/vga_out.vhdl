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

    vga_out     : out vga_out_t
);
end vga_gen;

architecture behavioral of vga_gen
is
    subtype time_t is unsigned(9 downto 0);
    
    type video_time_t is record
        row : time_t;
        col : time_t;
    end record;
    
    constant TIME_ZERO : video_time_t :=
    (
        row => (others => '0'),
        col => (others => '0')
    );

    type reg_t is record
        cur_time   : video_time_t;
        pixel_addr : pixel_addr_t;
        vga_out    : vga_out_t;
    end record;
    
    constant RESET_REG : reg_t :=
    (
        cur_time => TIME_ZERO,
        pixel_addr => (others => '0'),
        vga_out => VGA_RESET
    );
    
    constant LINE_SYNC_TIME         : time_t := to_unsigned(64, time_t'LENGTH);
    -- Normally 80 for 640 pixels, but 144 for 512
    constant LINE_BACK_PORCH_TIME   : time_t := to_unsigned(144, time_t'LENGTH);
    -- Normally 640, but NES is 512
    constant LINE_ACTIVE_TIME       : time_t := to_unsigned(512, time_t'LENGTH);
    -- Normally 16 for 640 pixels, but 80 for 512
    constant LINE_FRONT_PORCH_TIME  : time_t := to_unsigned(80, time_t'LENGTH);
    
    constant FRAME_SYNC_TIME         : time_t := to_unsigned(4, time_t'LENGTH);
    constant FRAME_BACK_PORCH_TIME   : time_t := to_unsigned(13, time_t'LENGTH);
    constant FRAME_ACTIVE_TIME       : time_t := to_unsigned(480, time_t'LENGTH);
    constant FRAME_FRONT_PORCH_TIME  : time_t := to_unsigned(3, time_t'LENGTH);
    
    constant V_ACTIVE_START          : time_t := FRAME_SYNC_TIME +
                                                 FRAME_BACK_PORCH_TIME;
    
    constant LINE_END : time_t := LINE_SYNC_TIME +
                                  LINE_BACK_PORCH_TIME +
                                  LINE_ACTIVE_TIME +
                                  LINE_FRONT_PORCH_TIME -
                                  "1";
    constant FRAME_END : time_t := FRAME_SYNC_TIME +
                                   FRAME_BACK_PORCH_TIME +
                                   FRAME_ACTIVE_TIME +
                                   FRAME_FRONT_PORCH_TIME -
                                   "1";
    
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
        H_ACTIVE,
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
            when H_SYNC => return '0';
            when H_ACTIVE => return '1';
            when H_BACK => return '1';
        end case;
    end;
    
    function get_vert_state(cur_time : video_time_t) return vert_state_t
    is
        constant SYNC_TIME         : time_t := FRAME_SYNC_TIME;
        constant BACK_PORCH_TIME   : time_t := FRAME_BACK_PORCH_TIME;
        constant ACTIVE_TIME       : time_t := FRAME_ACTIVE_TIME;
        constant FRONT_PORCH_TIME  : time_t := FRAME_FRONT_PORCH_TIME;
        
        constant SYNC_START        : time_t := to_unsigned(0, time_t'LENGTH);
        constant SYNC_END          : time_t := SYNC_TIME - "1";
        constant BACK_PORCH_START  : time_t := SYNC_END + "1";
        constant BACK_PORCH_END    : time_t := BACK_PORCH_START + BACK_PORCH_TIME - "1";
        constant ACTIVE_START      : time_t := BACK_PORCH_END + "1";
        constant ACTIVE_END        : time_t := ACTIVE_START + ACTIVE_TIME - "1";
        constant FRONT_PORCH_START : time_t := ACTIVE_END + "1";
        constant FRONT_PORCH_END   : time_t := FRONT_PORCH_START + FRONT_PORCH_TIME - "1";
    begin
        if cur_time.row >= FRONT_PORCH_START and
           cur_time.row <= FRONT_PORCH_END
        then
            return V_FRONT;
        elsif cur_time.row >= SYNC_START and
              cur_time.row <= SYNC_END
        then
            return V_SYNC;
        elsif cur_time.row >= BACK_PORCH_START and
              cur_time.row <= BACK_PORCH_END
        then
            return V_BACK;
        elsif cur_time.row >= ACTIVE_START and
              cur_time.row <= ACTIVE_END
        then
            return V_ACTIVE;
        else
            return V_FRONT;
        end if;
    end;
    
    function get_horz_state(cur_time : video_time_t) return horz_state_t
    is
        constant SYNC_TIME         : time_t := LINE_SYNC_TIME;
        constant BACK_PORCH_TIME   : time_t := LINE_BACK_PORCH_TIME;
        constant ACTIVE_TIME       : time_t := LINE_ACTIVE_TIME;
        constant FRONT_PORCH_TIME  : time_t := LINE_FRONT_PORCH_TIME;
        
        constant SYNC_START        : time_t := to_unsigned(0, time_t'LENGTH);
        constant SYNC_END          : time_t := SYNC_TIME - "1";
        constant BACK_PORCH_START  : time_t := SYNC_END + "1";
        constant BACK_PORCH_END    : time_t := BACK_PORCH_START + BACK_PORCH_TIME - "1";
        constant ACTIVE_START      : time_t := BACK_PORCH_END + "1";
        constant ACTIVE_END        : time_t := ACTIVE_START + ACTIVE_TIME - "1";
        constant FRONT_PORCH_START : time_t := ACTIVE_END + "1";
        constant FRONT_PORCH_END   : time_t := FRONT_PORCH_START + FRONT_PORCH_TIME - "1";
    begin
        if cur_time.col >= FRONT_PORCH_START and
           cur_time.col <= FRONT_PORCH_END
        then
            return H_FRONT;
        elsif cur_time.col >= SYNC_START and
              cur_time.col <= SYNC_END
        then
            return H_SYNC;
        elsif cur_time.col >= BACK_PORCH_START and
              cur_time.col <= BACK_PORCH_END
        then
            return H_BACK;
        elsif cur_time.col >= ACTIVE_START and
              cur_time.col <= ACTIVE_END
        then
            return H_ACTIVE;
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
            ret.col := ZERO(cur_time.col);
            if cur_time.row = FRAME_END
            then
                ret.row := ZERO(cur_time.row);
            else
                ret.row := cur_time.row + "1";
            end if;
        else
            ret.col := cur_time.col + "1";
        end if;
        
        return ret;
    end;
    
    signal reg : reg_t := RESET_REG;
    signal reg_next : reg_t;
    
begin

    vga_out <= reg.vga_out;
    
    process(all)
        variable v_vert_state : vert_state_t := V_FRONT;
        variable v_horz_state : horz_state_t := H_FRONT;

        constant MAX_ROW : unsigned(7 downto 0) := to_unsigned(239, 8);

        alias ppu_pixel_row : unsigned(7 downto 0) is reg.pixel_addr(15 downto 8);
        alias ppu_pixel_col : unsigned(7 downto 0) is reg.pixel_addr(7 downto 0);

        alias next_ppu_pixel_row : unsigned(7 downto 0) is reg_next.pixel_addr(15 downto 8);
        alias next_ppu_pixel_col : unsigned(7 downto 0) is reg_next.pixel_addr(7 downto 0);
    begin
        v_vert_state := get_vert_state(reg.cur_time);
        v_horz_state := get_horz_state(reg.cur_time);
        
        reg_next <= reg;
        reg_next.vga_out.v_sync <= get_v_sync(v_vert_state);
        reg_next.vga_out.h_sync <= get_h_sync(v_horz_state);
        reg_next.vga_out.lval <= false;
        reg_next.vga_out.fval <= false;

        sram_oe_n <= '1';
        sram_addr <= std_logic_vector(resize(reg.pixel_addr, sram_addr'length));
        
        case v_vert_state is
            when V_FRONT =>
                reg_next.pixel_addr <= (others => '0');
                reg_next.vga_out.color <= COLOR_BLACK;
                reg_next.vga_out.fval <= false;
            when V_SYNC =>
                reg_next.pixel_addr <= (others => '0');
                reg_next.vga_out.color <= COLOR_BLACK;
                reg_next.vga_out.fval <= false;
            when V_ACTIVE =>
                reg_next.vga_out.fval <= true;
                case v_horz_state is
                    when H_FRONT =>
                        next_ppu_pixel_col <= (others => '0');
                        reg_next.vga_out.color <= COLOR_BLACK;
                        reg_next.vga_out.lval <= false;
                    when H_SYNC =>
                        next_ppu_pixel_col <= (others => '0');
                        reg_next.vga_out.color <= COLOR_BLACK;
                        reg_next.vga_out.lval <= false;
                    when H_ACTIVE =>
                        sram_oe_n <= '0';

                        reg_next.vga_out.color.red <= sram_dq(11 downto 8);
                        reg_next.vga_out.color.green <= sram_dq(7 downto 4);
                        reg_next.vga_out.color.blue <= sram_dq(3 downto 0);
                        reg_next.vga_out.lval <= true;

                        if reg.cur_time.col(0) = '1'
                        then
                            next_ppu_pixel_col <= ppu_pixel_col + "1";
                        end if;
                    when H_BACK =>
                        next_ppu_pixel_col <= (others => '0');
                        reg_next.vga_out.color <= COLOR_BLACK;
                        reg_next.vga_out.lval <= false;
                end case;

                if reg.cur_time.col = LINE_END and reg.cur_time.row(0) = '0'
                then
                    next_ppu_pixel_row <= ppu_pixel_row + "1";
                end if;
                
            when V_BACK =>
                reg_next.pixel_addr <= (others => '0');
                reg_next.vga_out.fval <= false;
                reg_next.vga_out.color <= COLOR_BLACK;
        end case;
        
        reg_next.cur_time <= incr_time(reg.cur_time);
    end process;

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= reg_next;
        end if;
    end if;
    end process;
    
end behavioral;