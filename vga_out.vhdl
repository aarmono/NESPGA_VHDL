library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.de1_types.all;
use work.utilities.all;

entity vga_gen is
port
(
    clk         : in std_logic;
    reset       : in boolean;
    
    ppu_clk     : in std_logic;
    ppu_valid   : in boolean;
    ppu_in      : in vga_color_t;
    
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
    
    constant LINE_SYNC_TIME         : time_t := to_unsigned(64, time_t'LENGTH);
    constant LINE_BACK_PORCH_TIME   : time_t := to_unsigned(80, time_t'LENGTH);
    constant LINE_ACTIVE_TIME       : time_t := to_unsigned(640, time_t'LENGTH);
    constant LINE_FRONT_PORCH_TIME  : time_t := to_unsigned(16, time_t'LENGTH);
    
    constant FRAME_SYNC_TIME         : time_t := to_unsigned(3, time_t'LENGTH);
    constant FRAME_BACK_PORCH_TIME   : time_t := to_unsigned(13, time_t'LENGTH);
    constant FRAME_ACTIVE_TIME       : time_t := to_unsigned(480, time_t'LENGTH);
    constant FRAME_FRONT_PORCH_TIME  : time_t := to_unsigned(1, time_t'LENGTH);
    
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
    
    function average(val1 : vga_color_t; val2 : vga_color_t) return vga_color_t
    is
        variable red : unsigned(4 downto 0);
        variable green : unsigned(4 downto 0);
        variable blue : unsigned(4 downto 0);
        variable ret : vga_color_t;
    begin
        red := resize(unsigned(val1.red), red'LENGTH) + unsigned(val2.red);
        green := resize(unsigned(val1.green), green'LENGTH) + unsigned(val2.green);
        blue := resize(unsigned(val1.blue), blue'LENGTH) + unsigned(val2.blue);
        
        ret.red := std_logic_vector(red(4 downto 1));
        ret.green := std_logic_vector(green(4 downto 1));
        ret.blue := std_logic_vector(blue(4 downto 1));
        
        return ret;
    end;
    
    type reg_t is record
        cur_time : video_time_t;
        vga_out  : vga_out_t;
    end record;
    
    constant RESET_REG : reg_t :=
    (
        cur_time => TIME_ZERO,
        vga_out => VGA_RESET
    );
    
    signal reg : reg_t := RESET_REG;
    
    type ram_t is array (0 to 511) of vga_color_t;
    signal ram        : ram_t;
    signal write_addr : unsigned(8 downto 0);
    signal read_pix   : unsigned(7 downto 0);
    signal avg_count  : unsigned(1 downto 0);
    signal prev_val   : vga_color_t;
    
begin

    vga_out <= reg.vga_out;
    
    process(clk)
        variable v_vert_state : vert_state_t := V_FRONT;
        variable v_horz_state : horz_state_t := H_FRONT;
        variable v_cur_time   : video_time_t;
        variable v_read_addr  : unsigned(8 downto 0) := (others => '-');
        variable v_mem        : vga_color_t := COLOR_BLACK;
        variable v_pix_row    : unsigned(9 downto 0) := (others => '-');
    begin
    if rising_edge(clk) then
        v_cur_time := reg.cur_time;
        v_vert_state := get_vert_state(v_cur_time);
        v_horz_state := get_horz_state(v_cur_time);
        
        reg.vga_out.v_sync <= get_v_sync(v_vert_state);
        reg.vga_out.h_sync <= get_h_sync(v_horz_state);
        
        case v_vert_state is
            when V_FRONT =>
                reg.vga_out.color <= COLOR_BLACK;
            when V_SYNC =>
                reg.vga_out.color <= COLOR_BLACK;
            when V_ACTIVE =>
                case v_horz_state is
                    when H_FRONT =>
                        reg.vga_out.color <= COLOR_BLACK;
                    when H_SYNC =>
                        reg.vga_out.color <= COLOR_BLACK;
                    when H_ACTIVE =>
                        v_pix_row := v_cur_time.row - V_ACTIVE_START;
                        
                        v_read_addr := v_pix_row(1) & read_pix;
                        v_mem := ram(to_integer(v_read_addr));
                        if avg_count = to_unsigned(1, 2)
                        then
                            prev_val <= v_mem;
                            reg.vga_out.color <= v_mem;
                            read_pix <= read_pix + "1";
                            avg_count <= avg_count + "1";
                        elsif avg_count = to_unsigned(2, 2)
                        then
                            reg.vga_out.color <= average(v_mem, prev_val);
                            avg_count <= ZERO(avg_count);
                        else
                            reg.vga_out.color <= v_mem;
                            avg_count <= avg_count + "1";
                        end if;
                    when H_BACK =>
                        reg.vga_out.color <= COLOR_BLACK;
                        
                end case;
                
            when V_BACK =>
                reg.vga_out.color <= COLOR_BLACK;
        end case;
        
        reg.cur_time <= incr_time(v_cur_time);
        
        if reset
        then
            reg <= RESET_REG;
            avg_count <= ZERO(avg_count);
            read_pix <= ZERO(read_pix);
        end if;
    
    end if;
    end process;
    
    process(ppu_clk) begin
    if rising_edge(ppu_clk)
    then
        if reset
        then
            write_addr <= ZERO(write_addr);
        elsif ppu_valid
        then
            ram(to_integer(write_addr)) <= ppu_in;
            write_addr <= write_addr + "1";
        end if;
    end if;
    end process;
    
end behavioral;