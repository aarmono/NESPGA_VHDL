library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_core.all;
use work.utilities.all;
use work.chr_bus_types.all;
use work.palette_bus_types.all;

package lib_ppu is
    
    constant FRONT_BG_END  : unsigned(8 downto 0) := to_unsigned(255, 9);
    constant FRAME_START   : unsigned(8 downto 0) := to_unsigned(21, 9);
    constant FRAME_END     : unsigned(8 downto 0) := to_unsigned(260, 9);
    constant VINT_END      : unsigned(8 downto 0) := to_unsigned(19, 9);
    constant BACK_BG_START : unsigned(8 downto 0) := to_unsigned(320, 9);
    constant BACK_BG_END   : unsigned(8 downto 0) := to_unsigned(335, 9);

    subtype pixel_t         is std_logic_vector(5 downto 0);
    subtype name_sel_t      is std_logic_vector(1 downto 0);
    subtype attr_idx_t      is unsigned(2 downto 0);
    subtype tile_idx_t      is std_logic_vector(7 downto 0);
    subtype scroll_t        is std_logic_vector(2 downto 0);
    subtype attribute_t     is std_logic_vector(1 downto 0);
    subtype pattern_t       is std_logic_vector(7 downto 0);
    subtype y_offset_t      is std_logic_vector(3 downto 0);
    subtype pattern_shift_t is std_logic_vector(15 downto 0);
    subtype sprite_coord_t  is unsigned(8 downto 0);
    type    oam_mem_t       is array(0 to 255) of data_t;
    type    sec_oam_mem_t   is array(0 to 32) of data_t;
    type    palette_ram_t   is array(0 to 16#1F#) of pixel_t;

    type sprite_attr_t is record
        palette   : attribute_t;
        behind_bg : boolean;
        flip_horz : boolean;
        flip_vert : boolean;
    end record;

    function to_sprite_attr(val : data_t) return sprite_attr_t;

    type sprite_buffer_t is record
        pattern_1 : data_t;
        pattern_2 : data_t;
        palette   : attribute_t;
        behind_bg : boolean;
        x_coord   : sprite_coord_t;
    end record;

    type sprite_buffer_arr_t is array(0 to 7) of sprite_buffer_t;
    
    type pixel_bus_t is record
        pixel       : pixel_t;
        line_valid  : boolean;
        frame_valid : boolean;
    end record;
    
    -- Encapsulates the current time for the PPU
	type ppu_time_t is record
		frame    : unsigned(0 downto 0);
		scanline : unsigned(8 downto 0);
		cycle    : unsigned(8 downto 0);
	end record;
	
	-- Reset value for ppu_time_t registers
	constant TIME_ZERO : ppu_time_t :=
	(
		frame    => (others => '0'),
		scanline => (others => '0'),
		cycle    => (others => '0')
	);
	
    -- Increment a time register
    function incr_time(time_in : ppu_time_t) return ppu_time_t;
	
    -- Control register (0x2000)
	type control_t is record
        -- Base Nametable address:
        --   0 = 0x2000
        --   1 = 0x2400
        --   2 = 0x2800
        --   3 = 0x2C00
	    name_table_select    : name_sel_t;
        -- PPU Address increment (0 = +1, 1 = +32)
	    ppu_incr_32          : boolean;
        -- Sprite pattern table base address:
        --   0 = 0x0000
        --   1 = 0x1000
	    pattern_table_select : std_logic;
        -- Pattern table base address:
        --   0 = 0x0000
        --   1 = 0x1000
	    play_table_select    : std_logic;
        -- Sprite height select:
        --   0 = 8 pixels
        --   1 = 16 pixels
	    sprite_hgt_16        : boolean;
        -- Generate NMI at start of vblank
	    vbl_enable           : boolean;
	end record;

	function to_control_t(val : data_t) return control_t;

    -- Mask register (0x2001)
    type mask_t is record
        -- Output color or B/W pixels
        enable_color        : boolean;
        -- If true shows the leftmost 8 background pixels on the screen
        left_playfield_clip : boolean;
        -- If true shows the leftmost 8 sprite pixels on the screen
        left_sprite_clip    : boolean;
        -- If true enables background fetch/display
        enable_playfield    : boolean;
        -- If true enables sprite fetch/display
        enable_sprite       : boolean;
        -- If true intensifies red colors
        intense_red         : boolean;
        -- If true intensifies green colors
        intense_green       : boolean;
        -- If true intensifies blue colors
        intense_blue        : boolean;
    end record;
    
    function to_mask_t(val : data_t) return mask_t;
    
    -- Status register (0x2002)
    type status_t is record
        -- True if more than 8 sprites could be drawn on a scanline
        spr_overflow : boolean;
        -- True if a non-zero pixel of sprite 0 overlaps with a non-zero
        -- background pixel
        spr_0_hit    : boolean;
        -- True if vblank has started
        vbl          : boolean;
    end record;
    
    function to_std_logic(status : status_t) return std_logic_vector;
    
    -- The current name table address, attribute table address,
    -- and attribute table offset as derived from the PPU address
    -- and name table selector
    type tile_idx_addr_t is record
	    name_table_addr : chr_addr_t;
	    attr_table_addr : chr_addr_t;
	    attr_idx        : attr_idx_t;
    end record;

    type ppu_reg_t is record
        -- Index of the background tile as read from the nametable
        tile_idx        : tile_idx_t;
        -- Control register (0x2000)
        control         : control_t;
        -- Mask register (0x2001)
        mask            : mask_t;
        -- Status register (0x2002)
        status          : status_t;
        -- PPU Addr (0x2006)
        ppu_addr        : chr_addr_t;
        -- Shift register containing 2 tile's worth of pixel_idx[0]
        -- for the background
        pattern_table_1 : pattern_shift_t;
        -- Shift register containing 2 tile's worth of pixel_idx[1]
        -- for the background
        pattern_table_2 : pattern_shift_t;
        -- Fine horizontal scroll
        fine_scroll     : scroll_t;
        -- Temporary PPU Addr -- This is loaded into ppu_addr at
        -- certain times during the rendering process (at the beginning of
        -- a frame, after a write to 0x2007, etc...)
        addr_tmp        : chr_addr_t;
        -- A temporary holding area for the first pattern table byte. When
        -- This byte is read data is still being shifted out of the pattern
        -- table shift registers
        pattern_tmp     : data_t;
        -- Attribute value used as pixel_idx[3:2]
        attr_val        : attribute_t;
        -- A temporary holding area for the attribute value to be held
        -- while the previous one is still being used to render pixels
        attr_tmp        : attribute_t;
        -- OAM data address (0x2003). This is also used during sprite rendering
        -- as a scratch register
        oam_addr        : data_t;
        -- OAM data value (0x2004). This is also used during sprite rendering
        -- as a scratch register
        oam_data        : data_t;
        -- True if all 64 sprites have been processed when trying to load them
        -- into secondary OAM memory
        oam_overflow    : boolean;
        -- Current sprite y-offset used to fetch pattern table data
        sprite_y_coord  : sprite_coord_t;
        -- Current sprite tile index used to fetch pattern table data
        sprite_tile_idx : tile_idx_t;
        -- Current sprite attributes used to fetch pattern table data
        sprite_attr     : spr_attr_t;
        -- Fetched sprite data for up to 8 sprites -- used during render
        -- phase
        sprite_buffer   : sprite_buffer_arr_t;
        -- The current time (frame, scanline, and pixel)
        cur_time        : ppu_time_t;
        -- Memory access information for register accesses which
        -- require more than one read/write (reads/writes to 0x2005, 0x2007)
        count           : unsigned(0 downto 0);
    end record;
    
    function get_tile_idx_addr
    (
        name_table_select : name_sel_t;
        addr              : chr_addr_t
    )
    return tile_idx_addr_t;
	
	function attr_shift
    (
        data_in  : data_t;
        attr_idx : attr_idx_t
    )
    return attribute_t;
    
    function is_rendering(mask : mask_t; cur_time : ppu_time_t) return boolean;
    function scanline_valid(cur_time : ppu_time_t) return boolean;
    function is_vblank_start(cur_time : ppu_time_t) return boolean;
    function is_vblank_end(cur_time : ppu_time_t) return boolean;
    function shift_pattern_table(cur_time : ppu_time_t) return boolean;
    
    function get_y_offset
    (
        chr_addr  : chr_addr_t;
        height_16 : boolean
    )
    return y_offset_t;

    function get_y_offset
    (
        scanline  : unsigned(8 downto 0);
        y_coord   : sprite_coord_t;
        height_16 : boolean
    ) return y_offset_t;
    
    function to_palette_addr
    (
        is_sprite : boolean;
        pattern_1 : std_logic;
        pattern_2 : std_logic;
        attr_val  : attribute_t
    )
    return palette_addr_t;
    
    function get_pattern_table
    (
        idx             : std_logic;
        pattern_select  : std_logic;
        tile_idx        : tile_idx_t;
        y_offset        : y_offset_t;
        height_16       : boolean
    )
    return data_t;
    
    function incr_ppu_addr
    (
        addr : chr_addr_t;
        incr_32 : boolean
    )
    return chr_addr_t;
    
end lib_ppu;


package body lib_ppu is
    
    -- attr_shift function {
    function attr_shift
    (
        data_in  : data_t;
        attr_idx : attr_idx_t
    )
    return attribute_t
    is
        variable tmp : data_t;
    begin
        tmp := std_logic_vector(unsigned(data_in) srl to_integer(attr_idx));
        return tmp(attribute_t'RANGE);
    end;
    -- }

    -- scanline_valid function {
    function scanline_valid(cur_time : ppu_time_t) return boolean
    is
    begin
        return cur_time.scanline >= FRAME_START and
               cur_time.scanline <= FRAME_END;
    end function;
    -- }
    
    -- is_rendering function {
    function is_rendering(mask : mask_t ; cur_time : ppu_time_t) return boolean
    is
        variable render_enabled : boolean;
        variable in_frame : boolean;
        variable in_render : boolean;
    begin
        render_enabled := mask.enable_playfield or mask.enable_sprite;
        in_frame := cur_time.scanline >= FRAME_START and
                    cur_time.scanline <= FRAME_END;
        in_render := cur_time.cycle <= FRONT_BG_END;
        return render_enabled and in_frame and in_render;
    end;
    -- }
    
    -- get_y_offset function {
    function get_y_offset
    (
        chr_addr  : chr_addr_t;
        height_16 : boolean
    )
    return y_offset_t
    is
    begin
        if height_16
        then
            return chr_addr(8 downto 5);
        else
            return '0' & chr_addr(7 downto 5);
        end if;
    end;
    -- }
    
    -- to_palette_addr function {
    function to_palette_addr
    (
        is_sprite : boolean;
        pattern_1 : std_logic;
        pattern_2 : std_logic;
        attr_val  : attribute_t
    )
    return palette_addr_t
    is
        variable msb : std_logic;
    begin
        msb := to_std_logic(is_sprite);
        return msb & pattern_2 & pattern_1 & attr_val;
    end;
    -- }
    
    -- get_tile_idx_addr function {
    function get_tile_idx_addr
    (
        name_table_select : name_sel_t;
        addr              : chr_addr_t
    )
    return tile_idx_addr_t
    is
        variable ret : tile_idx_addr_t;
        variable tile_row : std_logic_vector(4 downto 0);
        variable tile_col : std_logic_vector(4 downto 0);
        variable tile_num : std_logic_vector(9 downto 0);
        variable attr_offset : std_logic_vector(5 downto 0);
    begin
        tile_row := addr(12 downto 8);
        tile_col := addr(4 downto 0);
        tile_num := tile_row & tile_col;
        attr_offset := tile_row(4 downto 2) & tile_col(4 downto 2);
        ret.name_table_addr := "10" & name_table_select & tile_num;
        ret.attr_table_addr := "10" & name_table_select & x"F" & attr_offset;
        ret.attr_idx := tile_row(1) & tile_col(1) & '0';
        
        return ret;
    end;
    -- }
    
    -- get_pattern_table function {
    function get_pattern_table
    (
        idx             : std_logic;
        pattern_select  : std_logic;
        tile_idx        : tile_idx_t;
        y_offset        : y_offset_t;
        height_16       : boolean
    )
    return data_t
    is
    begin
        if height_16
        then
            return pattern_select & tile_idx & idx & y_offset(2 downto 0);
        else
            return tile_idx(0) &
                   tile_idx(7 downto 1) &
                   y_offset(3) &
                   idx & 
                   y_offset(2 downto 0);
        end if;
    end;
    -- }
    
    -- incr_time function {
    function incr_time(time_in : ppu_time_t) return ppu_time_t is
		variable next_time : ppu_time_t;
		variable end_cycle : unsigned(8 downto 0);
		
		constant ODD_FRAME   : unsigned(0 downto 0) := "1";

		constant START_LINE  : unsigned(8 downto 0) := to_unsigned(0, 9);
		constant VAR_LINE    : unsigned(8 downto 0) := to_unsigned(20, 9);
		constant END_LINE    : unsigned(8 downto 0) := to_unsigned(261, 9);

		constant START_CYCLE : unsigned(8 downto 0) := to_unsigned(0, 9);
		constant SHORT_CYCLE : unsigned(8 downto 0) := to_unsigned(339, 9);
		constant REG_CYCLE   : unsigned(8 downto 0) := to_unsigned(340, 9);
	begin
        if time_in.frame = ODD_FRAME and
           time_in.scanline = VAR_LINE
        then
            end_cycle := SHORT_CYCLE;
        else
            end_cycle := REG_CYCLE;
        end if;

		next_time := time_in;
		if time_in.cycle = end_cycle
		then
			next_time.cycle := START_CYCLE;
			
			if time_in.scanline = END_LINE
			then
				next_time.scanline := START_LINE;
				next_time.frame := time_in.frame + "1";
			else
				next_time.scanline := time_in.scanline + "1";
			end if;
		else
			next_time.cycle := time_in.cycle + "1";
		end if;
		
		return next_time;
	end;
	-- }

end package body;