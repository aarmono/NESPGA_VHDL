library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.chr_bus_types.all;
use work.ppu_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;

package lib_ppu is
    
    subtype ppu_cycle_t is unsigned(8 downto 0);

    constant FRONT_BG_END  : ppu_cycle_t := to_unsigned(255, ppu_cycle_t'length);
    constant FRAME_START   : ppu_cycle_t := to_unsigned(21, ppu_cycle_t'length);
    constant FRAME_END     : ppu_cycle_t := to_unsigned(260, ppu_cycle_t'length);
    constant VINT_START    : ppu_cycle_t := to_unsigned(0, ppu_cycle_t'length);
    constant VINT_END      : ppu_cycle_t := to_unsigned(20, ppu_cycle_t'length);
    constant BACK_BG_START : ppu_cycle_t := to_unsigned(320, ppu_cycle_t'length);
    constant BACK_BG_END   : ppu_cycle_t := to_unsigned(335, ppu_cycle_t'length);

    subtype vram_addr_t     is unsigned(14 downto 0);
    subtype palette_idx_t   is std_logic_vector(3 downto 0);
    subtype name_sel_t      is std_logic_vector(1 downto 0);
    subtype attr_idx_t      is unsigned(2 downto 0);
    subtype tile_idx_t      is std_logic_vector(7 downto 0);
    subtype attribute_t     is std_logic_vector(1 downto 0);
    subtype pattern_t       is unsigned(7 downto 0);
    subtype y_offset_t      is std_logic_vector(3 downto 0);
    subtype pattern_shift_t is unsigned(15 downto 0);
    subtype sprite_coord_t  is unsigned(7 downto 0);
    subtype fine_scroll_t   is unsigned(2 downto 0);
    subtype coarse_scroll_t is unsigned(4 downto 0);
        
    type attribute_arr_t is array(0 to 8) of attribute_t;

    type sprite_attr_t is record
        palette   : attribute_t;
        behind_bg : boolean;
        flip_horz : boolean;
        flip_vert : boolean;
    end record;
    
    constant RESET_SPRITE_ATTR : sprite_attr_t :=
    (
        palette => (others => '0'),
        behind_bg => false,
        flip_horz => false,
        flip_vert => false
    );

    function to_sprite_attr(val : data_t) return sprite_attr_t;

    type sprite_buffer_t is record
        pattern_1 : pattern_t;
        pattern_2 : pattern_t;
        palette   : attribute_t;
        behind_bg : boolean;
        x_coord   : sprite_coord_t;
    end record;
    
    constant RESET_SPRITE_BUFFER : sprite_buffer_t :=
    (
        pattern_1 => (others => '0'),
        pattern_2 => (others => '0'),
        palette => (others => '0'),
        behind_bg => false,
        x_coord => (others => '0')
    );

    type sprite_buffer_arr_t is array(0 to 7) of sprite_buffer_t;
    
    constant RESET_SPRITE_BUFFER_ARR : sprite_buffer_arr_t :=
        (others => RESET_SPRITE_BUFFER);
        
    type scroll_t is record
        -- Base Nametable address:
        --   0 = 0x2000
        --   1 = 0x2400
        --   2 = 0x2800
        --   3 = 0x2C00
        name_table_select : name_sel_t;
        coarse_x_scroll   : coarse_scroll_t;
        fine_y_scroll     : fine_scroll_t;
        coarse_y_scroll   : coarse_scroll_t;
    end record;
    
    constant RESET_SCROLL : scroll_t :=
    (
        name_table_select => (others => '0'),
        coarse_x_scroll => (others => '0'),
        fine_y_scroll => (others => '0'),
        coarse_y_scroll => (others => '0')
    );
    
    function scroll_to_vram_addr(scroll : scroll_t) return vram_addr_t;
    function vram_addr_to_scroll(addr : vram_addr_t) return scroll_t;

    function bus_read_scroll(scroll : scroll_t) return chr_bus_t;
    
    -- Encapsulates the current time for the PPU
    type ppu_time_t is record
        frame    : unsigned(0 downto 0);
        scanline : ppu_cycle_t;
        cycle    : ppu_cycle_t;
    end record;
    
    -- Reset value for ppu_time_t registers
    constant TIME_ZERO : ppu_time_t :=
    (
        frame    => (others => '0'),
        scanline => (others => '0'),
        cycle    => (others => '0')
    );
    
    -- Increment a time register
    function incr_time
    (
        time_in        : ppu_time_t;
        render_enabled : boolean
    )
    return ppu_time_t;
    
    function is_sprite_hit
    (
        cur_time      : ppu_time_t;
        sprite_hgt_16 : boolean;
        oam_data      : data_t
    )
    return boolean;

    function can_display_pixel
    (
        cur_time       : ppu_time_t;
        render_enabled : boolean;
        left_enabled   : boolean
    )
    return boolean;
    
    -- Control register (0x2000)
    type control_t is record
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
    
    constant RESET_CONTROL : control_t :=
    (
        ppu_incr_32 => false,
        pattern_table_select => '0',
        play_table_select => '0',
        sprite_hgt_16 => false,
        vbl_enable => false
    );

    function to_control_t(val : data_t) return control_t;

    -- Mask register (0x2001)
    type mask_t is record
        -- Output color or B/W pixels
        enable_grayscale    : boolean;
        -- If true shows the leftmost 8 background pixels on the screen
        left_playfield_show : boolean;
        -- If true shows the leftmost 8 sprite pixels on the screen
        left_sprite_show    : boolean;
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
    
    constant RESET_MASK : mask_t :=
    (
        enable_grayscale => false,
        left_playfield_show => false,
        left_sprite_show => false,
        enable_playfield => false,
        enable_sprite => false,
        intense_red => false,
        intense_green => false,
        intense_blue => false
    );
    
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
    
    constant RESET_STATUS : status_t :=
    (
        spr_overflow => false,
        spr_0_hit => false,
        vbl => false
    );
    
    function to_std_logic(status : status_t) return data_t;

    function overflow(next_val : unsigned; cur_val : unsigned) return boolean;
    
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
        tile_idx         : tile_idx_t;
        -- Control register (0x2000)
        control          : control_t;
        -- Mask register (0x2001)
        mask             : mask_t;
        -- Status register (0x2002)
        status           : status_t;
        -- PPU Addr (0x2006)
        ppu_addr         : scroll_t;
        -- PPU Data (0x2007) register for VRAM reads
        ppu_data         : data_t;
        -- Shift register containing 2 tile's worth of pixel_idx[0]
        -- for the background
        pattern_table_1  : pattern_shift_t;
        -- Shift register containing 2 tile's worth of pixel_idx[1]
        -- for the background
        pattern_table_2  : pattern_shift_t;
        -- Fine horizontal scroll
        fine_x_scroll    : fine_scroll_t;
        -- Scroll registers loaded through 0x2007
        scroll           : scroll_t;
        -- A temporary holding area for the first pattern table byte. When
        -- This byte is read data is still being shifted out of the pattern
        -- table shift registers
        pattern_tmp      : data_t;
        -- Attribute value used as pixel_idx[3:2]
        attr_val         : attribute_arr_t;
        -- A temporary holding area for the attribute value to be held
        -- while the previous one is still being used to render pixels
        attr_tmp         : attribute_t;
        -- OAM data address (0x2003). This is also used during sprite rendering
        -- as a scratch register
        oam_addr         : unsigned(oam_addr_t'range);
        -- OAM data value (0x2004). This is also used during sprite rendering
        -- as a scratch register
        oam_data         : data_t;
        -- True if all 64 sprites have been processed when trying to load them
        -- into secondary OAM memory
        oam_overflow     : boolean;
        -- True if all 8 sprites have been loaded into secondary OAM memory
        sec_oam_overflow : boolean;
        -- Current sprite y-offset used to fetch pattern table data
        sprite_y_coord   : sprite_coord_t;
        -- Current sprite tile index used to fetch pattern table data
        sprite_tile_idx  : tile_idx_t;
        -- Current sprite attributes used to fetch pattern table data
        sprite_attr      : sprite_attr_t;
        -- Fetched sprite data for up to 8 sprites -- used during render
        -- phase
        sprite_buffer    : sprite_buffer_arr_t;
        -- The current time (frame, scanline, and pixel)
        cur_time         : ppu_time_t;
        -- Memory access information for register accesses which
        -- require more than one read/write (reads/writes to 0x2005, 0x2007)
        count            : unsigned(0 downto 0);
        -- Address for secondary OAM memory access
        sec_oam_addr     : unsigned(sec_oam_addr_t'range);
        -- True if Sprite 0 was fetched from OAM to be potentially rendered
        -- next scanline
        sprite_0_hit     : boolean;
        -- True if the scanline render buffers presently contain sprite zero
        sprite_0_buffer  : boolean;
        -- Bus address used for $2007 reads
        chr_bus          : chr_bus_t;
    end record;
    
    constant RESET_PPU_REG : ppu_reg_t :=
    (
        tile_idx => (others => '0'),
        control => RESET_CONTROL,
        mask => RESET_MASK,
        status => RESET_STATUS,
        ppu_addr => RESET_SCROLL,
        ppu_data => (others => '0'),
        pattern_table_1 => (others => '0'),
        pattern_table_2 => (others => '0'),
        fine_x_scroll => (others => '0'),
        scroll => RESET_SCROLL,
        pattern_tmp => (others => '0'),
        attr_val => (others => (others => '0')),
        attr_tmp => (others => '0'),
        oam_addr => (others => '0'),
        oam_data => (others => '0'),
        oam_overflow => false,
        sec_oam_overflow => false,
        sprite_y_coord => (others => '0'),
        sprite_tile_idx => (others => '0'),
        sprite_attr => RESET_SPRITE_ATTR,
        sprite_buffer => RESET_SPRITE_BUFFER_ARR,
        cur_time => TIME_ZERO,
        count => (others => '0'),
        sec_oam_addr => (others => '0'),
        sprite_0_hit => false,
        sprite_0_buffer => false,
        chr_bus => CHR_BUS_IDLE
    );
    
    function reload_pattern_table
    (
        pattern_table : pattern_shift_t;
        data_in       : data_t
    )
    return pattern_shift_t;

    function reload_attr_table
    (
        attr_table : attribute_arr_t;
        attr_in    : attribute_t
    )
    return attribute_arr_t;

    function shift_attr_table(attr_table : attribute_arr_t) return attribute_arr_t;
    
    function get_tile_idx_addr
    (
        ppu_addr          : scroll_t
    )
    return tile_idx_addr_t;
    
    function attr_shift
    (
        data_in  : data_t;
        attr_idx : attr_idx_t
    )
    return attribute_t;
    
    function rendering_enabled(mask : mask_t) return boolean;
    function is_rendering(cur_time : ppu_time_t) return boolean;
    function background_active(cur_time : ppu_time_t) return boolean;
    function scanline_valid(cur_time : ppu_time_t) return boolean;
    function is_vblank_start(cur_time : ppu_time_t) return boolean;
    function is_vblank_end(cur_time : ppu_time_t) return boolean;
    
    function mask_oam_data(oam_addr : oam_addr_t; oam_data : data_t) return data_t;

    function to_color
    (
        attr_val  : attribute_t;
        pattern_1 : std_logic;
        pattern_2 : std_logic
    )
    return palette_idx_t;

    function mask_pixel(grayscale : boolean; pixel : pixel_t) return pixel_t;

    function is_transparent(palette_idx : palette_idx_t) return boolean;
    
    function shift_sprite_buffers
    (
        spr_in : sprite_buffer_arr_t
    )
    return sprite_buffer_arr_t;
    
    function get_y_offset(ppu_addr : scroll_t) return y_offset_t;
    
    function get_y_offset
    (
        scanline  : ppu_cycle_t;
        y_coord   : sprite_coord_t;
        height_16 : boolean;
        flip_vert : boolean
    )
    return y_offset_t;
    
    function to_palette_addr
    (
        is_sprite : boolean;
        pattern_1 : std_logic;
        pattern_2 : std_logic;
        attr_val  : attribute_t
    )
    return palette_addr_t;
    
    function to_palette_addr
    (
        is_sprite   : boolean;
        palette_idx : palette_idx_t
    )
    return palette_addr_t;

    function to_palette_addr(vram_addr : unsigned) return palette_addr_t;
    
    function get_pattern_table
    (
        idx             : std_logic;
        pattern_select  : std_logic;
        tile_idx        : tile_idx_t;
        y_offset        : y_offset_t;
        height_16       : boolean
    )
    return chr_addr_t;
    
    function incr_ppu_addr
    (
        scroll  : scroll_t;
        incr_32 : boolean
    )
    return scroll_t;
    
    function incr_ppu_addr_x(scroll  : scroll_t) return scroll_t;
    function incr_ppu_addr_y(scroll  : scroll_t) return scroll_t;
    
    type ppu_render_in_t is record
        reg               : ppu_reg_t;
        
        cpu_bus           : ppu_bus_t;
        data_from_cpu     : data_t;

        data_from_oam     : data_t;
        data_from_sec_oam : data_t;
        data_from_chr     : data_t;
        data_from_palette : pixel_t;
    end record;
    
    
    type ppu_render_out_t is record
        reg             : ppu_reg_t;
        
        data_to_cpu     : data_t;
        
        oam_bus         : oam_bus_t;
        data_to_oam     : data_t;
        sec_oam_bus     : sec_oam_bus_t;
        data_to_sec_oam : data_t;
        chr_bus         : chr_bus_t;
        data_to_chr     : data_t;
        palette_bus     : palette_bus_t;
        data_to_palette : pixel_t;
        
        vint            : boolean;
        
        pixel_bus       : pixel_bus_t;
    end record;
    
    function cycle_ppu(render_in : ppu_render_in_t) return ppu_render_out_t;
    
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
    
    function to_sprite_attr(val : data_t) return sprite_attr_t
    is
        variable ret : sprite_attr_t;
    begin
        ret.palette := val(1 downto 0);
        ret.behind_bg := val(5) = '1';
        ret.flip_horz := val(6) = '1';
        ret.flip_vert := val(7) = '1';
        
        return ret;
    end;
    
    function to_control_t(val : data_t) return control_t
    is
        variable ret : control_t;
    begin
        ret.ppu_incr_32 := val(2) = '1';
        ret.pattern_table_select := val(3);
        ret.play_table_select := val(4);
        ret.sprite_hgt_16 := val(5) = '1';
        ret.vbl_enable := val(7) = '1';
        
        return ret;
    end;
    
    function to_mask_t(val : data_t) return mask_t
    is
        variable ret : mask_t;
    begin
        ret.intense_blue := val(7) = '1';
        ret.intense_green := val(6) = '1';
        ret.intense_red := val(5) = '1';
        ret.enable_sprite := val(4) = '1';
        ret.enable_playfield := val(3) = '1';
        ret.left_sprite_show := val(2) = '1';
        ret.left_playfield_show := val(1) = '1';
        ret.enable_grayscale := val(0) = '1';
        
        return ret;
    end;

    function overflow(next_val : unsigned; cur_val : unsigned) return boolean
    is
    begin
        assert next_val'high = cur_val'high report "overflow: unequal length"
               severity failure;
        return next_val(next_val'high) = '0' and cur_val(cur_val'high) = '1';
    end;
    
    function scroll_to_vram_addr(scroll : scroll_t) return vram_addr_t
    is
        variable ret : vram_addr_t;
    begin
        -- The 15 bit registers t and v are composed this way during rendering:

        -- yyy NN YYYYY XXXXX
        -- ||| || ||||| +++++-- coarse X scroll
        -- ||| || +++++-------- coarse Y scroll
        -- ||| ++-------------- nametable select
        -- +++----------------- fine Y scroll
        ret(4 downto 0) := scroll.coarse_x_scroll;
        ret(9 downto 5) := scroll.coarse_y_scroll;
        ret(11 downto 10) := unsigned(scroll.name_table_select);
        ret(14 downto 12) := scroll.fine_y_scroll;
        
        return ret;
    end;
    
    function vram_addr_to_scroll(addr : vram_addr_t) return scroll_t
    is
        variable ret : scroll_t;
    begin
        ret.coarse_x_scroll := addr(4 downto 0);
        ret.coarse_y_scroll := addr(9 downto 5);
        ret.name_table_select := std_logic_vector(addr(11 downto 10));
        ret.fine_y_scroll := addr(14 downto 12);
        
        return ret;
    end;

    function bus_read_scroll(scroll : scroll_t) return chr_bus_t
    is
        variable vram_addr : vram_addr_t;
    begin
        vram_addr := scroll_to_vram_addr(scroll);
        return bus_read(vram_addr(chr_addr_t'range));
    end;

    -- scanline_valid function {
    function scanline_valid(cur_time : ppu_time_t) return boolean
    is
    begin
        return cur_time.scanline >= FRAME_START and
               cur_time.scanline <= FRAME_END;
    end;
    -- }
    
    function background_active(cur_time : ppu_time_t) return boolean
    is
    begin
    return cur_time.scanline >= VINT_END and
           cur_time.scanline <= FRAME_END;
    end;
    
    function is_vblank_start(cur_time : ppu_time_t) return boolean
    is
    begin
        return cur_time.scanline = VINT_START and is_zero(cur_time.cycle);
    end;
    
    function is_vblank_end(cur_time : ppu_time_t) return boolean
    is
    begin
        return cur_time.scanline = VINT_END and is_zero(cur_time.cycle);
    end;

    function rendering_enabled(mask : mask_t) return boolean
    is
    begin
        return mask.enable_playfield or mask.enable_sprite;
    end;
    
    -- is_rendering function {
    function is_rendering(cur_time : ppu_time_t) return boolean
    is
        variable in_frame : boolean;
        variable in_render : boolean;
    begin
        in_frame := cur_time.scanline >= FRAME_START and
                    cur_time.scanline <= FRAME_END;
        in_render := cur_time.cycle <= FRONT_BG_END;
        return in_frame and in_render;
    end;
    -- }

    function can_display_pixel
    (
        cur_time       : ppu_time_t;
        render_enabled : boolean;
        left_enabled   : boolean
    )
    return boolean
    is
        constant LEFT_END : ppu_cycle_t := to_unsigned(7, ppu_cycle_t'length);
    begin
        return render_enabled and (left_enabled or cur_time.cycle > LEFT_END);
    end;

    function mask_oam_data(oam_addr : oam_addr_t; oam_data : data_t) return data_t
    is
        variable mask : data_t;
    begin
        if oam_addr(1 downto 0) = "10"
        then
            mask := x"E3";
        else
            mask := x"FF";
        end if;

        return oam_data and mask;
    end;
    
    function to_color
    (
        attr_val  : attribute_t;
        pattern_1 : std_logic;
        pattern_2 : std_logic
    )
    return palette_idx_t
    is
    begin
        return attr_val & pattern_2 & pattern_1;
    end;

    function mask_pixel(grayscale : boolean; pixel : pixel_t) return pixel_t
    is
        variable mask : pixel_t;
    begin
        if grayscale
        then
            mask := b"11_0000";
        else
            mask := (others => '1');
        end if;

        return mask and pixel;
    end;

    function is_transparent(palette_idx : palette_idx_t) return boolean
    is
    begin
        return is_zero(palette_idx(1 downto 0));
    end;
    
    -- get_y_offset function {
    function get_y_offset(ppu_addr : scroll_t) return y_offset_t
    is
    begin
        return '0' & std_logic_vector(ppu_addr.fine_y_scroll);
    end;
    
    function get_y_offset
    (
        scanline  : ppu_cycle_t;
        y_coord   : sprite_coord_t;
        height_16 : boolean;
        flip_vert : boolean
    )
    return y_offset_t
    is
        variable cur_scanline : sprite_coord_t;
        variable scanline_offset : sprite_coord_t;
        variable tile_offset : unsigned(y_offset_t'range);
    begin
        cur_scanline := resize(scanline - FRAME_START,
                               cur_scanline'length);
        scanline_offset := cur_scanline - y_coord;
        if height_16
        then
            tile_offset := scanline_offset(y_offset_t'range);
            if flip_vert
            then
                tile_offset := x"F" - tile_offset;
            end if;
        else
            tile_offset := '0' & scanline_offset(2 downto 0);
            if flip_vert
            then
                tile_offset := x"7" - tile_offset;
            end if;
        end if;
        
        return std_logic_vector(tile_offset);
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
    begin
        return to_palette_addr(is_sprite, attr_val & pattern_2 & pattern_1);
    end;
    -- }
    
    function to_palette_addr
    (
        is_sprite   : boolean;
        palette_idx : palette_idx_t
    )
    return palette_addr_t
    is
        variable msb : std_logic;
    begin
        msb := to_std_logic(is_sprite);
        if is_transparent(palette_idx)
        then
            return "00000";
        else
            return msb & palette_idx;
        end if;
    end;

    function to_palette_addr(vram_addr : unsigned) return palette_addr_t
    is
        variable ret : palette_addr_t;
    begin
        ret := std_logic_vector(vram_addr(ret'range));
        -- Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of
        -- $3F00/$3F04/$3F08/$3F0C. Note that this goes for
        -- writing as well as reading. A symptom of not having
        -- implemented this correctly in an emulator is the
        -- sky being black in Super Mario Bros., which writes
        -- the backdrop color through $3F10.
        if is_zero(ret(1 downto 0))
        then
            ret(ret'high) := '0';
        end if;

        return ret;
    end;
    
    -- get_tile_idx_addr function {
    function get_tile_idx_addr
    (
        ppu_addr          : scroll_t
    )
    return tile_idx_addr_t
    is
        variable vram_addr : vram_addr_t;
        variable ret : tile_idx_addr_t;
    begin
        -- tile address = 0x2000 | (v & 0x0FFF)
        vram_addr := scroll_to_vram_addr(ppu_addr);
        ret.name_table_addr := "10" & std_logic_vector(vram_addr(11 downto 0));
        -- The low 12 bits of the attribute address are composed in the following way:
        --
        -- NN 1111 YYY XXX
        -- || |||| ||| +++-- high 3 bits of coarse X (x/4)
        -- || |||| +++------ high 3 bits of coarse Y (y/4)
        -- || ++++---------- attribute offset (960 bytes)
        -- ++--------------- nametable select
        ret.attr_table_addr :=
            "10" & 
            ppu_addr.name_table_select &
            x"F" &
            std_logic_vector(ppu_addr.coarse_y_scroll(4 downto 2)) &
            std_logic_vector(ppu_addr.coarse_x_scroll(4 downto 2));
        ret.attr_idx := ppu_addr.coarse_y_scroll(1) &
                        ppu_addr.coarse_x_scroll(1) &
                        '0';
        
        return ret;
    end;
    -- }
    
    function incr_ppu_addr_x(scroll  : scroll_t) return scroll_t
    is
        variable ret : scroll_t;
    begin
        ret := scroll;
        if is_max_val(scroll.coarse_x_scroll)
        then
            ret.name_table_select(0) := not scroll.name_table_select(0);
        end if;
        
        ret.coarse_x_scroll := scroll.coarse_x_scroll + "1";
        
        return ret;
        
    end;
    
    function incr_ppu_addr_y(scroll  : scroll_t) return scroll_t
    is
        variable ret : scroll_t;

        constant COARSE_Y_NT_FLIP : coarse_scroll_t :=
            to_unsigned(29, coarse_scroll_t'length);
    begin
        ret := scroll;
        
        -- if fine Y < 7
        if not is_max_val(scroll.fine_y_scroll)
        then
            -- increment fine Y
            ret.fine_y_scroll := scroll.fine_y_scroll + "1";
        else
            -- fine Y = 0
            ret.fine_y_scroll := (others => '0');
            if scroll.coarse_y_scroll = COARSE_Y_NT_FLIP
            then
                -- coarse Y = 0
                ret.coarse_y_scroll := (others => '0');
                -- switch vertical nametable
                ret.name_table_select(1) := not scroll.name_table_select(1);
            elsif is_max_val(scroll.coarse_y_scroll)
            then
                -- coarse Y = 0, nametable not switched
                ret.coarse_y_scroll := (others => '0');
            else
                -- increment coarse Y
                ret.coarse_y_scroll := scroll.coarse_y_scroll + "1";
            end if;
        end if;
        
        return ret;
    end;
    
    -- get_pattern_table function {
    function get_pattern_table
    (
        idx             : std_logic;
        pattern_select  : std_logic;
        tile_idx        : tile_idx_t;
        y_offset        : y_offset_t;
        height_16       : boolean
    )
    return chr_addr_t
    is
    begin
        if height_16
        then
            -- The value written to PPUCTRL ($2000) controls whether the
            -- background and sprites use the left half ($0000-$0FFF) or the
            -- right half ($1000-$1FFF) of the pattern table. PPUCTRL bit 4
            -- applies to backgrounds, bit 3 applies to 8x8 sprites, and bit 0
            -- of each OAM entry's tile number applies to 8x16 sprites. 
            return '0'                  &
                   tile_idx(0)          &
                   tile_idx(7 downto 1) &
                   y_offset(3)          &
                   idx                  &
                   y_offset(2 downto 0);
        else
            return '0'            &
                   pattern_select &
                   tile_idx       &
                   idx            &
                   y_offset(2 downto 0);
        end if;
    end;
    -- }
    
    -- incr_time function {
    function incr_time
    (
        time_in        : ppu_time_t;
        render_enabled : boolean
    )
    return ppu_time_t
    is
        variable next_time : ppu_time_t;
        variable end_cycle : ppu_cycle_t;
        
        constant ODD_FRAME   : unsigned(0 downto 0) := "1";

        constant START_LINE  : ppu_cycle_t := to_unsigned(0, ppu_cycle_t'length);
        constant VAR_LINE    : ppu_cycle_t := to_unsigned(20, ppu_cycle_t'length);
        constant END_LINE    : ppu_cycle_t := to_unsigned(261, ppu_cycle_t'length);

        constant START_CYCLE : ppu_cycle_t := to_unsigned(0, ppu_cycle_t'length);
        constant SHORT_CYCLE : ppu_cycle_t := to_unsigned(339, ppu_cycle_t'length);
        constant REG_CYCLE   : ppu_cycle_t := to_unsigned(340, ppu_cycle_t'length);
    begin
        -- With rendering disabled (background and sprites disabled in PPUMASK
        -- ($2001)), each PPU frame is 341*262=89342 PPU clocks long. There is
        -- no skipped clock every other frame.
        -- With rendering enabled, each odd PPU frame is one PPU clock shorter
        -- than normal. This is done by skipping the first idle tick on the
        -- first visible scanline (by jumping directly from (339,261) on the
        -- pre-render scanline to (0,0) on the first visible scanline and doing
        -- the last cycle of the last dummy nametable fetch there instead
        if time_in.frame = ODD_FRAME and
           time_in.scanline = VAR_LINE and
           render_enabled
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
    
    function incr_ppu_addr
    (
        scroll  : scroll_t;
        incr_32 : boolean
    )
    return scroll_t
    is
        variable addr : vram_addr_t;
    begin
        addr := scroll_to_vram_addr(scroll);
        if incr_32
        then
            addr := addr + x"20";
        else
            addr := addr + "1";
        end if;
        
        return vram_addr_to_scroll(addr);
    end;
    
    function is_sprite_hit
    (
        cur_time      : ppu_time_t;
        sprite_hgt_16 : boolean;
        oam_data      : data_t
    )
    return boolean
    is
        variable y_pos : unsigned(oam_data'range);
        variable scanline_max : unsigned(oam_data'range);
        variable cur_scanline : unsigned(oam_data'range);
    begin
        y_pos := unsigned(oam_data);
        cur_scanline := resize(cur_time.scanline - FRAME_START,
                               cur_scanline'length);
        if sprite_hgt_16
        then
            scanline_max := y_pos + x"10";
        else
            scanline_max := y_pos + x"08";
        end if;
        
        return cur_scanline >= y_pos and cur_scanline < scanline_max;
    end;
    
    function shift_sprite_buffers
    (
        spr_in : sprite_buffer_arr_t
    )
    return sprite_buffer_arr_t
    is
        variable spr_out : sprite_buffer_arr_t;
    begin
        spr_out := spr_in;
        
        for i in spr_in'range
        loop
            if is_zero(spr_in(i).x_coord)
            then
                spr_out(i).pattern_1 := shift_left(spr_in(i).pattern_1, 1);
                spr_out(i).pattern_2 := shift_left(spr_in(i).pattern_2, 1);
            else
                spr_out(i).x_coord := spr_in(i).x_coord - "1";
            end if;
        end loop;
        
        return spr_out;
    end;
    
    function to_std_logic(status : status_t) return data_t
    is
    begin
        return to_std_logic(status.vbl) &
               to_std_logic(status.spr_0_hit) &
               to_std_logic(status.spr_overflow) &
               "00000";
    end;
    
    function reload_pattern_table
    (
        pattern_table : pattern_shift_t;
        data_in       : data_t
    )
    return pattern_shift_t
    is
        variable shifted : pattern_shift_t;
    begin
        shifted := shift_left(pattern_table, 1);
        shifted(data_in'range) := unsigned(data_in);
        
        return shifted;
    end;

    function shift_attr_table(attr_table : attribute_arr_t) return attribute_arr_t
    is
        variable ret : attribute_arr_t;
    begin
        for i in 1 to attribute_arr_t'high
        loop
            ret(i-1) := attr_table(i);
        end loop;

        -- Keep the last element the same since this will "fill in" the
        -- shift register with the attribute value for the next tile
        ret(attribute_arr_t'high) := attr_table(attribute_arr_t'high);

        return ret;
    end;

    function reload_attr_table
    (
        attr_table : attribute_arr_t;
        attr_in    : attribute_t
    )
    return attribute_arr_t
    is
        variable ret : attribute_arr_t;
    begin
        -- Shift the table
        ret := shift_attr_table(attr_table);
        -- Then load the last element with the attribute for the next tile
        ret(attr_table'high) := attr_in;

        return ret;
    end;
    
    function cycle_ppu(render_in : ppu_render_in_t) return ppu_render_out_t
    is
        variable render_out : ppu_render_out_t;
        
        -- Shared variables
        variable v_pattern_table_addr : chr_addr_t;
        variable v_rnd_pattern_color  : palette_idx_t;
        variable v_ppu_chr_addr       : unsigned(chr_addr_t'range);
        variable v_rnd_mask           : mask_t;

        -- background render variables
        variable v_bg_tile_idx_addr      : tile_idx_addr_t;
        variable v_bg_tile_y_offset      : y_offset_t;
        variable v_rnd_bg_pattern_color  : palette_idx_t;
        variable v_bg_palette_idx        : integer;
        variable v_bg_attribute_idx      : integer;

        -- Sprite render variables
        variable v_spr_copy_sprite       : boolean;
        variable v_sec_oam_init_addr     : unsigned(sec_oam_addr_t'range);
        variable v_sec_oam_fetch_addr    : unsigned(sec_oam_addr_t'range);
        variable v_spr_tile_y_offset     : y_offset_t;
        variable v_spr_buf_addr          : integer range 0 to 7;
        variable v_rnd_is_sprite         : boolean;
        variable v_rnd_spr_pattern_color : palette_idx_t;
        
        constant PALETTE_ADDR_START : unsigned(chr_addr_t'range) :=
            resize(x"3F00", chr_addr_t'length);
    begin
        render_out.reg := render_in.reg;
        
        render_out.chr_bus := CHR_BUS_IDLE;
        render_out.oam_bus := OAM_BUS_IDLE;
        render_out.sec_oam_bus := SEC_OAM_BUS_IDLE;
        render_out.palette_bus := PALETTE_BUS_IDLE;
        
        render_out.data_to_chr := (others => '-');
        render_out.data_to_oam := (others => '-');
        render_out.data_to_sec_oam := (others => '-');
        render_out.data_to_cpu := (others => '-');
        render_out.data_to_palette := (others => '-');
        
        v_ppu_chr_addr :=
            scroll_to_vram_addr(render_in.reg.ppu_addr)(chr_addr_t'range);
        
        v_bg_tile_idx_addr := get_tile_idx_addr(render_in.reg.ppu_addr);
        v_bg_tile_y_offset := get_y_offset(render_in.reg.ppu_addr);
        
        v_spr_buf_addr := to_integer(render_in.reg.cur_time.cycle(5 downto 3));

        render_out.reg.cur_time := incr_time(render_in.reg.cur_time,
                                             rendering_enabled(render_in.reg.mask));
    
        -- Fetch the attribute value and pattern table values for the
        -- current tile.
        -- If either of bits 3 or 4 is enabled, at any time outside of the
        -- vblank interval the PPU will be making continual use to the PPU
        -- address and data bus to fetch tiles to render, as well as internally
        -- fetching sprite data from the OAM.
        if rendering_enabled(render_in.reg.mask) and
           background_active(render_in.reg.cur_time)
        then
            case to_integer(render_in.reg.cur_time.cycle) is
                when   0 to 255 |
                     320 to 335 =>
                    case render_in.reg.cur_time.cycle(2 downto 0) is
                        when "000" =>
                            -- Name table fetch.
                            render_out.chr_bus :=
                                bus_read(v_bg_tile_idx_addr.name_table_addr);
                            -- Shift the pattern table
                            render_out.reg.pattern_table_1 :=
                                shift_left(render_in.reg.pattern_table_1, 1);
                            render_out.reg.pattern_table_2 :=
                                shift_left(render_in.reg.pattern_table_2, 1);
                            -- Shift the attribute table
                            render_out.reg.attr_val :=
                                shift_attr_table(render_in.reg.attr_val);
                        when "001" =>
                            -- Name table fetch.
                            render_out.chr_bus :=
                                bus_read(v_bg_tile_idx_addr.name_table_addr);
                            -- Update tile index register with the returned
                            -- data.
                            render_out.reg.tile_idx := render_in.data_from_chr;
                            -- Shift the pattern table
                            render_out.reg.pattern_table_1 :=
                                shift_left(render_in.reg.pattern_table_1, 1);
                            render_out.reg.pattern_table_2 :=
                                shift_left(render_in.reg.pattern_table_2, 1);
                            -- Shift the attribute table
                            render_out.reg.attr_val :=
                                shift_attr_table(render_in.reg.attr_val);
                        when "010" =>
                            -- Attribute table fetch.
                            render_out.chr_bus :=
                                bus_read(v_bg_tile_idx_addr.attr_table_addr);
                            -- Shift the pattern table
                            render_out.reg.pattern_table_1 :=
                                shift_left(render_in.reg.pattern_table_1, 1);
                            render_out.reg.pattern_table_2 :=
                                shift_left(render_in.reg.pattern_table_2, 1);
                            -- Shift the attribute table
                            render_out.reg.attr_val :=
                                shift_attr_table(render_in.reg.attr_val);
                        when "011" =>
                            -- Attribute table fetch.
                            render_out.chr_bus :=
                                bus_read(v_bg_tile_idx_addr.attr_table_addr);
                            -- Update temporary register with the returned
                            -- data. Update the temporary register and not
                            -- the one used by the shift register as the
                            -- renderer is still working
                            render_out.reg.attr_tmp :=
                                attr_shift(render_in.data_from_chr,
                                           v_bg_tile_idx_addr.attr_idx);
                            -- Shift the pattern table
                            render_out.reg.pattern_table_1 :=
                                shift_left(render_in.reg.pattern_table_1, 1);
                            render_out.reg.pattern_table_2 :=
                                shift_left(render_in.reg.pattern_table_2, 1);
                            -- Shift the attribute table
                            render_out.reg.attr_val :=
                                shift_attr_table(render_in.reg.attr_val);
                        when "100" =>
                            v_pattern_table_addr :=
                                get_pattern_table
                                (
                                    '0',
                                    render_in.reg.control.play_table_select,
                                    render_in.reg.tile_idx,
                                    v_bg_tile_y_offset,
                                    false
                                );
                            render_out.chr_bus := bus_read(v_pattern_table_addr);
                            -- Shift the pattern table
                            render_out.reg.pattern_table_1 :=
                                shift_left(render_in.reg.pattern_table_1, 1);
                            render_out.reg.pattern_table_2 :=
                                shift_left(render_in.reg.pattern_table_2, 1);
                            -- Shift the attribute table
                            render_out.reg.attr_val :=
                                shift_attr_table(render_in.reg.attr_val);
                        when "101" =>
                            v_pattern_table_addr :=
                                get_pattern_table
                                (
                                    '0',
                                    render_in.reg.control.play_table_select,
                                    render_in.reg.tile_idx,
                                    v_bg_tile_y_offset,
                                    false
                                );
                            render_out.chr_bus := bus_read(v_pattern_table_addr);
                            -- Save the first pattern table value in a
                            -- temporary register as the previous value is
                            -- still being used for rendering
                            render_out.reg.pattern_tmp := render_in.data_from_chr;
                            -- Shift the pattern tables
                            render_out.reg.pattern_table_1 :=
                                shift_left(render_in.reg.pattern_table_1, 1);
                            render_out.reg.pattern_table_2 :=
                                shift_left(render_in.reg.pattern_table_2, 1);
                            -- Shift the attribute table
                            render_out.reg.attr_val :=
                                shift_attr_table(render_in.reg.attr_val);
                        when "110" =>
                            v_pattern_table_addr :=
                                get_pattern_table
                                (
                                    '1',
                                    render_in.reg.control.play_table_select,
                                    render_in.reg.tile_idx,
                                    v_bg_tile_y_offset,
                                    false
                                );
                            render_out.chr_bus := bus_read(v_pattern_table_addr);
                            -- Shift the pattern table
                            render_out.reg.pattern_table_1 :=
                                shift_left(render_in.reg.pattern_table_1, 1);
                            render_out.reg.pattern_table_2 :=
                                shift_left(render_in.reg.pattern_table_2, 1);
                            -- Shift the attribute table
                            render_out.reg.attr_val :=
                                shift_attr_table(render_in.reg.attr_val);
                        when "111" =>
                            v_pattern_table_addr :=
                                get_pattern_table
                                (
                                    '1',
                                    render_in.reg.control.play_table_select,
                                    render_in.reg.tile_idx,
                                    v_bg_tile_y_offset,
                                    false
                                );
                            render_out.chr_bus := bus_read(v_pattern_table_addr);
                            -- This if the final clock cycle of a fetch
                            -- process. The renderer needs a new set of
                            -- data, so copy the temporary pattern byte
                            -- into pattern_table_1, save pattern_table_2,
                            -- and copy the temporary attribute value into
                            -- attr_val
                            render_out.reg.pattern_table_1 :=
                                reload_pattern_table
                                (
                                    render_in.reg.pattern_table_1,
                                    render_in.reg.pattern_tmp
                                );
                            render_out.reg.pattern_table_2 :=
                                reload_pattern_table
                                (
                                    render_in.reg.pattern_table_2,
                                    render_in.data_from_chr
                                );
                            render_out.reg.attr_val :=
                                reload_attr_table(render_in.reg.attr_val,
                                                  render_in.reg.attr_tmp);
                            
                            -- increment ppu_addr
                            render_out.reg.ppu_addr :=
                                incr_ppu_addr_x(render_in.reg.ppu_addr);
                            if render_in.reg.cur_time.cycle = FRONT_BG_END
                            then
                                render_out.reg.ppu_addr :=
                                    incr_ppu_addr_y(render_out.reg.ppu_addr);
                            end if;
                        when others =>
                            null;
                    end case;
                when 256 =>
                    render_out.reg.ppu_addr.name_table_select(0) :=
                        render_in.reg.scroll.name_table_select(0);
                    render_out.reg.ppu_addr.coarse_x_scroll :=
                        render_in.reg.scroll.coarse_x_scroll;
                when 279 to 303 =>
                    if render_in.reg.cur_time.scanline = VINT_END
                    then
                        render_out.reg.ppu_addr.coarse_y_scroll :=
                            render_in.reg.scroll.coarse_y_scroll;
                        render_out.reg.ppu_addr.fine_y_scroll :=
                            render_in.reg.scroll.fine_y_scroll;
                        render_out.reg.ppu_addr.name_table_select(1) :=
                            render_in.reg.scroll.name_table_select(1);
                    end if;
                when 336 to 339 =>
                    -- These are garbage name table accesses
                    if render_in.reg.cur_time.cycle(0) = '0'
                    then
                        -- Name table fetch.
                        render_out.chr_bus :=
                           bus_read(v_bg_tile_idx_addr.name_table_addr);
                    else
                        -- Name table fetch.
                        render_out.chr_bus :=
                           bus_read(v_bg_tile_idx_addr.name_table_addr);
                        -- Update tile index register with the returned
                        -- data.
                        render_out.reg.tile_idx := render_in.data_from_chr;
                    end if;
                when others =>
                    null;
            end case;
        end if;

        -- Fetch sprite data
        -- If either of bits 3 or 4 is enabled, at any time outside of the
        -- vblank interval the PPU will be making continual use to the PPU
        -- address and data bus to fetch tiles to render, as well as internally
        -- fetching sprite data from the OAM.
        if rendering_enabled(render_in.reg.mask) and
           background_active(render_in.reg.cur_time)
        then
            case to_integer(render_in.reg.cur_time.cycle) is
                when 0 to 63 =>
                    -- For the first 64 clock cycles, initialize secondary
                    -- OAM memory to 0xFF. Each memory access takes 2
                    -- clock cycles (one to write to the data register, one
                    -- to write to the memory)
                    v_sec_oam_init_addr :=
                        render_in.reg.cur_time.cycle(sec_oam_addr_t'high+1 downto 1);
                    if render_in.reg.cur_time.cycle(0) = '0'
                    then
                        render_out.reg.oam_data := (others => '1');
                    else
                        render_out.sec_oam_bus := bus_write(v_sec_oam_init_addr);
                        render_out.data_to_sec_oam := render_in.reg.oam_data;
                    end if;
                    
                    render_out.reg.sec_oam_addr := (others => '0');
                    render_out.reg.oam_overflow := false;
                    render_out.reg.sec_oam_overflow := false;
                    render_out.reg.sprite_0_hit := false;

                    -- Shift the sprite buffers as needed
                    render_out.reg.sprite_buffer :=
                        shift_sprite_buffers(render_in.reg.sprite_buffer);
                when 64 to 255 =>
                    -- Even-numbered memory accesses are reads from OAM
                    -- memory. And during the pre-render scanline disable
                    -- sprite hit detection
                    if render_in.reg.cur_time.cycle(0) = '0' or
                       not scanline_valid(render_in.reg.cur_time)
                    then
                        render_out.oam_bus := bus_read(render_in.reg.oam_addr);
                        render_out.reg.oam_data := render_in.data_from_oam;
                    else
                        v_spr_copy_sprite :=
                            is_sprite_hit(render_in.reg.cur_time,
                                          render_in.reg.control.sprite_hgt_16,
                                          render_in.reg.oam_data);
                        -- If we're reading the y-coordinate, it's in range,
                        -- and the sprite counter hasn't overflowed, or if
                        -- we've already started copying a sprite over, copy
                        -- this byte of data to secondary OAM memory
                        if not render_in.reg.oam_overflow and
                           (not is_zero(render_in.reg.sec_oam_addr(1 downto 0)) or
                            v_spr_copy_sprite)
                        then

                            -- Set a flag if this is sprite 0
                            if is_zero(render_in.reg.oam_addr)
                            then
                                render_out.reg.sprite_0_hit := true;
                            end if;

                            if not render_in.reg.sec_oam_overflow
                            then
                                render_out.sec_oam_bus :=
                                    bus_write(render_in.reg.sec_oam_addr);
                                render_out.data_to_sec_oam :=
                                    render_in.reg.oam_data;
                            else
                                -- If the value is in range, set the sprite
                                -- overflow flag in $2002 and read the next 3
                                -- entries of OAM (incrementing 'm' after each
                                -- byte and incrementing 'n' when 'm' overflows);
                                -- if m = 3, increment n
                                render_out.reg.status.spr_overflow := true;
                            end if;
                            
                            render_out.reg.sec_oam_addr :=
                                render_in.reg.sec_oam_addr + "1";
                            
                            render_out.reg.oam_addr :=
                                render_in.reg.oam_addr + "1";
                        else
                            render_out.reg.oam_addr(oam_addr_t'high downto 2) :=
                                render_in.reg.oam_addr(oam_addr_t'high downto 2) +
                                "1";

                            -- This reproduces a hardware bug in the original
                            -- NES PPU
                            --
                            -- If the value is not in range, increment n and m
                            -- (without carry).
                            --
                            -- The m increment is a hardware bug - if only n was
                            -- incremented, the overflow flag would be set
                            -- whenever more than 8 sprites were present on the
                            -- same scanline, as expected.
                            render_out.reg.oam_addr(1 downto 0) :=
                                render_in.reg.oam_addr(1 downto 0) +
                                to_unsigned(render_in.reg.sec_oam_overflow, 1);
                        end if;

                        -- If exactly 8 sprites have been found, disable
                        -- writes to secondary OAM because it is full.
                        -- This causes sprites in back to drop out
                        if overflow(render_out.reg.sec_oam_addr,
                                    render_in.reg.sec_oam_addr)
                        then
                            render_out.reg.sec_oam_overflow := true;
                        end if;

                        -- Stop OAM searching once all sprites have been
                        -- evaluated once
                        if overflow(render_out.reg.oam_addr,
                                    render_in.reg.oam_addr)
                        then
                            render_out.reg.oam_overflow := true;
                        end if;
                    end if;

                    -- Shift the sprite buffers as needed
                    render_out.reg.sprite_buffer :=
                        shift_sprite_buffers(render_in.reg.sprite_buffer);
                when 256 to 319 =>
                    -- OAMADDR is set to 0 during each of ticks 257-320
                    -- (the sprite tile loading interval) of the pre-render
                    -- and visible scanlines
                    render_out.reg.oam_addr := (others => '0');
                    render_out.reg.sec_oam_addr := (others => '0');

                    -- Update the flag indicating whether or not the sprite
                    -- buffers contain sprite 0
                    render_out.reg.sprite_0_buffer := render_in.reg.sprite_0_hit;
                    
                    v_sec_oam_fetch_addr :=
                        render_in.reg.cur_time.cycle(5 downto 3) &
                        render_in.reg.cur_time.cycle(1 downto 0);
                    -- This does not correctly handle
                    -- vertical flipping of sprites yet
                    case render_in.reg.cur_time.cycle(2 downto 0) is
                        -- First 2 CHR memory accesses are garbage
                        when "000" =>
                            render_out.chr_bus :=
                                bus_read(v_bg_tile_idx_addr.name_table_addr);
                            -- Read the sprite y-coordinate
                            render_out.sec_oam_bus :=
                                bus_read(v_sec_oam_fetch_addr);
                            render_out.reg.sprite_y_coord :=
                                unsigned(render_in.data_from_sec_oam);
                        when "001" =>
                            render_out.chr_bus :=
                                bus_read(v_bg_tile_idx_addr.name_table_addr);
                            -- Read the sprite tile index
                            render_out.sec_oam_bus :=
                                bus_read(v_sec_oam_fetch_addr);
                            render_out.reg.sprite_tile_idx :=
                                render_in.data_from_sec_oam;
                        when "010" =>
                            render_out.chr_bus :=
                                bus_read(v_bg_tile_idx_addr.attr_table_addr);
                            -- Read the sprite attributes
                            render_out.sec_oam_bus :=
                                bus_read(v_sec_oam_fetch_addr);
                            render_out.reg.sprite_attr :=
                                to_sprite_attr(render_in.data_from_sec_oam);
                        when "011" =>
                            render_out.chr_bus :=
                                bus_read(v_bg_tile_idx_addr.attr_table_addr);
                            -- Save relevant sprite attributes
                            render_out.reg.sprite_buffer(v_spr_buf_addr).palette :=
                                render_in.reg.sprite_attr.palette;
                            render_out.reg.sprite_buffer(v_spr_buf_addr).behind_bg :=
                                render_in.reg.sprite_attr.behind_bg;
                            -- Read the sprite x-coordinate
                            render_out.sec_oam_bus :=
                                bus_read(v_sec_oam_fetch_addr);
                            render_out.reg.sprite_buffer(v_spr_buf_addr).x_coord :=
                                unsigned(render_in.data_from_sec_oam);
                        when "100" =>
                            v_spr_tile_y_offset :=
                                get_y_offset(render_in.reg.cur_time.scanline,
                                             render_in.reg.sprite_y_coord,
                                             render_in.reg.control.sprite_hgt_16,
                                             render_in.reg.sprite_attr.flip_vert);
                            v_pattern_table_addr :=
                                get_pattern_table
                                (
                                    '0',
                                    render_in.reg.control.pattern_table_select,
                                    render_in.reg.sprite_tile_idx,
                                    v_spr_tile_y_offset,
                                    render_in.reg.control.sprite_hgt_16
                                );
                            render_out.chr_bus := bus_read(v_pattern_table_addr);
                        when "101" =>
                            v_spr_tile_y_offset :=
                                get_y_offset(render_in.reg.cur_time.scanline,
                                             render_in.reg.sprite_y_coord,
                                             render_in.reg.control.sprite_hgt_16,
                                             render_in.reg.sprite_attr.flip_vert);
                            v_pattern_table_addr :=
                                get_pattern_table
                                (
                                    '0',
                                    render_in.reg.control.pattern_table_select,
                                    render_in.reg.sprite_tile_idx,
                                    v_spr_tile_y_offset,
                                    render_in.reg.control.sprite_hgt_16
                                );
                            render_out.chr_bus := bus_read(v_pattern_table_addr);
                            if render_in.reg.sprite_attr.flip_horz
                            then
                                render_out.reg.sprite_buffer(v_spr_buf_addr).pattern_1 :=
                                    unsigned(reverse_vector(render_in.data_from_chr));
                            else
                                render_out.reg.sprite_buffer(v_spr_buf_addr).pattern_1 :=
                                    unsigned(render_in.data_from_chr);
                            end if;
                        when "110" =>
                            v_spr_tile_y_offset :=
                                get_y_offset(render_in.reg.cur_time.scanline,
                                             render_in.reg.sprite_y_coord,
                                             render_in.reg.control.sprite_hgt_16,
                                             render_in.reg.sprite_attr.flip_vert);
                            v_pattern_table_addr :=
                                get_pattern_table
                                (
                                    '1',
                                    render_in.reg.control.pattern_table_select,
                                    render_in.reg.sprite_tile_idx,
                                    v_spr_tile_y_offset,
                                    render_in.reg.control.sprite_hgt_16
                                );
                            render_out.chr_bus := bus_read(v_pattern_table_addr);
                        when "111" =>
                            v_spr_tile_y_offset :=
                                get_y_offset(render_in.reg.cur_time.scanline,
                                             render_in.reg.sprite_y_coord,
                                             render_in.reg.control.sprite_hgt_16,
                                             render_in.reg.sprite_attr.flip_vert);
                            v_pattern_table_addr :=
                                get_pattern_table
                                (
                                    '1',
                                    render_in.reg.control.pattern_table_select,
                                    render_in.reg.sprite_tile_idx,
                                    v_spr_tile_y_offset,
                                    render_in.reg.control.sprite_hgt_16
                                );
                            render_out.chr_bus := bus_read(v_pattern_table_addr);
                            if render_in.reg.sprite_attr.flip_horz
                            then
                                render_out.reg.sprite_buffer(v_spr_buf_addr).pattern_2 :=
                                    unsigned(reverse_vector(render_in.data_from_chr));
                            else
                                render_out.reg.sprite_buffer(v_spr_buf_addr).pattern_2 :=
                                    unsigned(render_in.data_from_chr);
                            end if;
                        when others =>
                            null;
                    end case;
                when 320 to 340 =>
                    render_out.reg.sec_oam_addr := (others => '0');
                    render_out.sec_oam_bus := bus_read(render_out.reg.sec_oam_addr);
                    render_out.reg.oam_data := render_in.data_from_sec_oam;
                    render_out.reg.sprite_0_buffer := render_in.reg.sprite_0_hit;
                when others =>
                    null;
            end case;
        end if;
    
        -- Control vbl status register and vint if so enabled
        -- Do this before CPU access so that the CPU can see and
        -- clear the VBL flag to suppress NMI on the same cycle NMI
        -- would occur
        if is_vblank_start(render_out.reg.cur_time)
        then
            render_out.reg.status.vbl := true;
        elsif is_vblank_end(render_out.reg.cur_time)
        then
            render_out.reg.status.vbl := false;
            render_out.reg.status.spr_0_hit := false;
            render_out.reg.status.spr_overflow := false;
        end if;

        -- External memory access from CPU. {
        -- NOTE: from most of the documentation I've read
        -- on conflicts between CPU bus access and regular
        -- operation (the normal rendering pipeline),
        -- it appears as though CPU bus access takes precedence.
        -- See documentation RE. writing to PPUADDR and PPUDATA
        -- while out of VBLANK and documentation RE. VINT being
        -- signaled at the same time as the status register is read
        -- Writes from CPU
        if is_bus_write(render_in.cpu_bus)
        then
            case render_in.cpu_bus.address is
                -- Control Register
                when "000" =>
                    render_out.reg.control :=
                        to_control_t(render_in.data_from_cpu);
                    render_out.reg.scroll.name_table_select :=
                        render_in.data_from_cpu(1 downto 0);
                -- Mask Register
                when "001" =>
                    render_out.reg.mask := to_mask_t(render_in.data_from_cpu);
                -- OAM Address
                when "011" =>
                    render_out.reg.oam_addr := unsigned(render_in.data_from_cpu);
                -- OAM Data
                when "100" =>
                    render_out.oam_bus := bus_write(render_in.reg.oam_addr);
                    render_out.data_to_oam :=
                        mask_oam_data(std_logic_vector(render_in.reg.oam_addr),
                                      render_in.data_from_cpu);
                    -- OAM Address register is incremented after write access
                    render_out.reg.oam_addr := render_in.reg.oam_addr + "1";
                -- Scroll Offset
                when "101" =>
                    if is_zero(render_in.reg.count)
                    then
                        render_out.reg.scroll.coarse_x_scroll :=
                            unsigned(render_in.data_from_cpu(7 downto 3));
                        render_out.reg.fine_x_scroll :=
                            unsigned(render_in.data_from_cpu(2 downto 0));
                    else
                        render_out.reg.scroll.coarse_y_scroll :=
                            unsigned(render_in.data_from_cpu(7 downto 3));
                        render_out.reg.scroll.fine_y_scroll :=
                            unsigned(render_in.data_from_cpu(2 downto 0));
                    end if;
                    render_out.reg.count := render_in.reg.count + "1";
                -- PPU Address
                when "110" =>
                    if is_zero(render_in.reg.count)
                    then
                        render_out.reg.scroll.fine_y_scroll :=
                            unsigned('0' & render_in.data_from_cpu(5 downto 4));
                        render_out.reg.scroll.name_table_select :=
                            render_in.data_from_cpu(3 downto 2);
                        render_out.reg.scroll.coarse_y_scroll(4 downto 3) :=
                            unsigned(render_in.data_from_cpu(1 downto 0));
                    else
                        render_out.reg.scroll.coarse_x_scroll :=
                            unsigned(render_in.data_from_cpu(4 downto 0));
                        render_out.reg.scroll.coarse_y_scroll(2 downto 0) :=
                            unsigned(render_in.data_from_cpu(7 downto 5));
                        -- Update using OUTPUT value
                        render_out.reg.ppu_addr := render_out.reg.scroll;
                        render_out.chr_bus :=
                            bus_read_scroll(render_out.reg.ppu_addr);
                    end if;
                    render_out.reg.count := render_in.reg.count + "1";
                -- PPU Data
                when "111" =>
                    if v_ppu_chr_addr >= PALETTE_ADDR_START
                    then
                        render_out.palette_bus :=
                            bus_write(to_palette_addr(v_ppu_chr_addr));
                        render_out.data_to_palette :=
                            render_in.data_from_cpu(pixel_t'range);
                    else
                        render_out.chr_bus := bus_write(v_ppu_chr_addr);
                        render_out.data_to_chr := render_in.data_from_cpu;
                    end if;

                    -- After access, the video memory address will increment
                    -- by an amount determined by bit 2 of $2000.
                    render_out.reg.ppu_addr :=
                        incr_ppu_addr(render_in.reg.ppu_addr,
                                      render_in.reg.control.ppu_incr_32);

                    render_out.reg.chr_bus :=
                        bus_read_scroll(render_out.reg.ppu_addr);
                when others =>
                    null;
            end case;
        -- Reads from CPU
        elsif is_bus_read(render_in.cpu_bus)
        then
            case render_in.cpu_bus.address is
                -- Status
                when "010" =>
                    render_out.data_to_cpu := to_std_logic(render_in.reg.status);
                    -- Reads from status register clear vbl signal
                    render_out.reg.status.vbl := false;
                    -- And reset the count register
                    render_out.reg.count := "0";
                -- OAM Data
                when "100" =>
                    render_out.oam_bus := bus_read(render_in.reg.oam_addr);
                    render_out.data_to_cpu := render_in.data_from_oam;
                -- PPU Data
                when "111" =>
                    if v_ppu_chr_addr >= PALETTE_ADDR_START
                    then
                        -- Reading palette data from $3F00-$3FFF works
                        -- differently. The palette data is placed immediately
                        -- on the data bus, and hence no priming read is
                        -- required.
                        render_out.palette_bus :=
                            bus_read(to_palette_addr(v_ppu_chr_addr));
                        render_out.data_to_cpu :=
                            resize(mask_pixel(render_in.reg.mask.enable_grayscale,
                                              render_in.data_from_palette),
                                   data_t'length);
                    else
                        -- When reading while the VRAM address is in the range
                        -- 0-$3EFF (i.e., before the palettes), the read will
                        -- return the contents of an internal read buffer. This
                        -- internal buffer is updated only when reading PPUDATA,
                        -- and so is preserved across frames. After the CPU reads
                        -- and gets the contents of the internal buffer, the PPU
                        -- will immediately update the internal buffer with the
                        -- byte at the current VRAM address.
                        render_out.data_to_cpu := render_in.reg.ppu_data;
                    end if;
                    
                    -- Reading the palettes still updates the internal buffer
                    -- though, but the data placed in it is the mirrored
                    -- nametable data that would appear "underneath" the palette.
                    render_out.chr_bus := bus_read(v_ppu_chr_addr);

                    -- Update the PPUDATA register for the next access
                    render_out.reg.ppu_data := render_in.data_from_chr;

                    -- After access, the video memory address will increment
                    -- by an amount determined by bit 2 of $2000.
                    render_out.reg.ppu_addr :=
                        incr_ppu_addr(render_in.reg.ppu_addr,
                                      render_in.reg.control.ppu_incr_32);

                    render_out.reg.chr_bus :=
                        bus_read_scroll(render_out.reg.ppu_addr);
                when others =>
                    render_out.data_to_cpu := (others => '0');
            end case;
        end if;
        -- }
        
        if is_rendering(render_in.reg.cur_time)
        then
            v_rnd_mask := render_out.reg.mask;
            if can_display_pixel(render_in.reg.cur_time,
                                 v_rnd_mask.enable_playfield,
                                 v_rnd_mask.left_playfield_show)
            then
                v_bg_palette_idx := pattern_shift_t'high -
                                    to_integer(render_in.reg.fine_x_scroll);
                v_bg_attribute_idx := to_integer(render_in.reg.fine_x_scroll);
                v_rnd_bg_pattern_color :=
                    to_color(render_in.reg.attr_val(v_bg_attribute_idx),
                             render_in.reg.pattern_table_1(v_bg_palette_idx),
                             render_in.reg.pattern_table_2(v_bg_palette_idx));
            else
                v_rnd_bg_pattern_color := (others => '0');
            end if;

            v_rnd_pattern_color := v_rnd_bg_pattern_color;
            v_rnd_is_sprite := false;
            for i in render_in.reg.sprite_buffer'reverse_range
            loop
                v_rnd_spr_pattern_color :=
                    to_color
                    (
                        render_in.reg.sprite_buffer(i).palette,
                        render_in.reg.sprite_buffer(i).pattern_1(pattern_t'high),
                        render_in.reg.sprite_buffer(i).pattern_2(pattern_t'high)
                    );
                if can_display_pixel(render_in.reg.cur_time,
                                     v_rnd_mask.enable_sprite,
                                     v_rnd_mask.left_sprite_show) and
                   is_zero(render_in.reg.sprite_buffer(i).x_coord) and
                   not is_transparent(v_rnd_spr_pattern_color)
                then
                    -- * Sprites with lower OAM indices are drawn in front.
                    --   For example, sprite 0 is in front of sprite 1, which is
                    --   in front of sprite 63.
                    -- * At any given pixel, if the frontmost opaque sprite's
                    --   priority bit is true (1), an opaque background pixel
                    --   is drawn in front of it.
                    --
                    -- Putting a back-priority sprite at a lower OAM index
                    -- than a front-priority sprite can cover up the the
                    -- front-priority sprite and let the background show through
                    --
                    -- For each pixel in the background buffer, the corresponding
                    -- sprite pixel replaces it only if the sprite pixel is
                    -- opaque and front priority or if the background pixel is
                    -- transparent.
                    v_rnd_is_sprite :=
                        not render_in.reg.sprite_buffer(i).behind_bg or
                        is_transparent(v_rnd_bg_pattern_color);
                    if v_rnd_is_sprite
                    then
                        v_rnd_pattern_color := v_rnd_spr_pattern_color;
                    else
                        v_rnd_pattern_color := v_rnd_bg_pattern_color;
                    end if;

                    -- Sprite 0 hit does not happen:
                    -- * If background or sprite rendering is disabled in
                    --   PPUMASK ($2001)
                    -- * At x=0 to x=7 if the left-side clipping window is
                    --   enabled (if bit 2 or bit 1 of PPUMASK is 0).
                    -- * At x=255, for an obscure reason related to the pixel
                    --   pipeline.
                    -- * At any pixel where the background or sprite pixel is
                    --   transparent (2-bit color index from the CHR pattern is
                    --   %00).
                    if i = 0 and
                       render_in.reg.sprite_0_buffer and
                       not is_transparent(v_rnd_bg_pattern_color) and
                       render_in.reg.cur_time.cycle /= FRONT_BG_END
                    then
                        render_out.reg.status.spr_0_hit := true;
                    end if;
                end if;
            end loop;

            -- "If the current VRAM address points in the range $3F00-$3FFF
            -- during forced blanking, the color indicated by this palette
            -- location will be shown on screen instead of the backdrop color."
            if not is_bus_active(render_out.palette_bus)
            then
                render_out.palette_bus :=
                    bus_read(to_palette_addr(v_rnd_is_sprite,
                                             v_rnd_pattern_color));
            end if;
            render_out.pixel_bus.pixel :=
                mask_pixel(v_rnd_mask.enable_grayscale, render_in.data_from_palette);
            render_out.pixel_bus.line_valid := true;
        else
            render_out.pixel_bus.line_valid := false;
        end if;
        
        render_out.pixel_bus.frame_valid := scanline_valid(render_in.reg.cur_time);

        -- Use render_out to ensure vint can be suppressed on the exact clock
        -- cycle it would be output
        render_out.vint := render_out.reg.status.vbl and
                           render_out.reg.control.vbl_enable;

        if is_bus_active(render_in.reg.chr_bus)
        then
            render_out.chr_bus := render_in.reg.chr_bus;
            render_out.reg.chr_bus := CHR_BUS_IDLE;
        end if;
        
        return render_out;
    end;

end package body;
