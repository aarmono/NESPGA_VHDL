library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.lib_ppu.all;
use work.ppu_bus_types.all;
use work.chr_bus_types.all;
use work.palette_bus_types.all;
use work.nes_core.all;
use work.utilities.all;

entity ppu is
port
(
    clk             : in std_logic;
    reset           : in boolean;

    chr_bus         : out chr_bus_t;
    chr_data_out    : out data_t;
    chr_data_in     : in  data_t;
    
    palette_bus      : out palette_bus_t;
    palette_data_out : out pixel_t;
    palette_data_in  : in  pixel_t;
    
    ppu_bus         : in  ppu_bus_t;
    ppu_data_out    : out data_t;
    ppu_data_in     : in  data_t;

    pixel_bus       : out pixel_bus_t;
    vint            : out boolean
);
end ppu;

architecture behavioral of ppu is

    signal reg     : ppu_reg_t;
    signal oam     : oam_mem_t;
    signal sec_oam : sec_oam_mem_t;

    signal palette_ram : palette_ram_t;
begin

    process(clk)
        -- Bus access -- These are variables because there's bus multiplexing
        --               which goes on at the end of the process
        variable v_chr_bus            : chr_bus_t;
        variable v_palette_bus        : palette_bus_t;
        
        -- Shared variables
        variable v_pattern_table_addr : data_t;

        -- background render variables
        variable v_bg_state              : bg_state_t;
        variable v_bg_tile_idx_addr      : tile_idx_addr_t;
        variable v_bg_tile_y_offset      : y_offset_t;
        variable v_bg_shift_high         : integer range 0 to 15;
        variable v_bg_shift_low          : integer range 0 to 15;

        -- Sprite render variables
        variable v_spr_oam_addr      : integer range 0 to 255;
        variable v_spr_sec_oam_addr  : integer range 0 to 32;
        variable v_spr_buf_addr      : integer range 0 to 7;
        variable v_spr_copy_sprite   : boolean;
        variable v_spr_tile_y_offset : y_offset_t;
    begin
        if rising_edge(clk)
        then
            -- Initialize variables
            v_chr_bus     := bus_idle(v_chr_bus);
            v_palette_bus := bus_idle(v_palette_bus);

            v_bg_tile_y_offset      := (others => '-');
            v_bg_pattern_table_addr := (others => '-');
            v_bg_state := get_bg_state(reg.mask.enable_playfield,
                                       reg.reg.cur_time);
            v_bg_tile_idx_addr := get_tile_idx_addr(reg.name_table_select,
                                                    reg.ppu_addr);
            v_bg_shift_high := shift_high := 15 - to_integer(reg.fine_scroll);
            v_bg_shift_low  := shift_high - 7;

            v_spr_oam_addr      := to_integer(reg.oam_addr);
            v_spr_sec_oam_addr  := to_integer(reg.sec_oam_addr);
            v_spr_copy_sprite   := not reg.status.spr_overflow and
                                   is_sprite_hit(cur_time,
                                                 reg.control.spr_hgt_16,
                                                 reg.oam_data);
            v_spr_buf_addr      := to_integer(reg.sec_oam_addr(4 downto 2));
            v_spr_tile_y_offset := get_y_offset(reg.cur_time.scanline,
                                                reg.sprite_y_coord,
                                                reg.control.sprite_hgt_16);

            -- Fetch the attribute value and pattern table values for the
            -- current tile.
            if scanline_valid(reg.cur_time) and reg.mask.enable_playfield
            then
                case to_integer(reg.cur_time.cycle) is
                    when   0 to 255 |
                         320 to 335 =>
                        case reg.cur_time.cycle(2 downto 0) is
                            when "000" =>
                                -- Name table fetch.
                                v_chr_bus :=
                                    bus_read(v_bg_tile_idx_addr.name_table_addr);
                                -- Shift the pattern table
                                shift_right(reg.pattern_table_1);
                                shift_right(reg.pattern_table_2);
                            when "001" =>
                                -- Update tile index register with the returned
                                -- data.
                                reg.tile_idx <= chr_data_in;
                                -- Shift the pattern table
                                shift_right(reg.pattern_table_1);
                                shift_right(reg.pattern_table_2);
                            when "010" =>
                                -- Attribute table fetch.
                                v_chr_bus :=
                                    bus_read(v_bg_tile_idx_addr.attr_table_addr);
                                -- Shift the pattern table
                                shift_right(reg.pattern_table_1);
                                shift_right(reg.pattern_table_2);
                            when "011" =>
                                -- Update temporary register with the returned
                                -- data. Update the temporary register and not
                                -- the one used by the shift register as the
                                -- renderer is still working
                                reg.attr_tmp <=
                                    attr_shift(chr_data_in,
                                               v_bg_tile_idx_addr.attr_idx);
                                -- Shift the pattern table
                                shift_right(reg.pattern_table_1);
                                shift_right(reg.pattern_table_2);
                            when "100" =>
                                -- Get Y offset for the current tile
                                v_bg_tile_y_offset := get_y_offset(reg.ppu_addr,
                                                                   false);
                                v_pattern_table_addr :=
                                    get_pattern_table('0',
                                                      reg.control.play_table_select,
                                                      reg.tile_idx,
                                                      v_bg_tile_y_offset,
                                                      false);
                                v_chr_bus := bus_read(pattern_table_addr);
                                -- Shift the pattern table
                                shift_right(reg.pattern_table_1);
                                shift_right(reg.pattern_table_2);
                            when "101" =>
                                -- Save the first pattern table value in a
                                -- temporary register as the previous value is
                                -- still being used for rendering
                                ret.reg.pattern_tmp <= chr_data_in;
                                -- Shift the pattern tables
                                shift_right(reg.pattern_table_1);
                                shift_right(reg.pattern_table_2);
                            when "110" =>
                                v_bg_tile_y_offset := get_y_offset(reg.ppu_addr,
                                                                   false);
                                v_pattern_table_addr :=
                                    get_pattern_table('1',
                                                      reg.control.play_table_select,
                                                      reg.tile_idx,
                                                      v_bg_tile_y_offset,
                                                      false);
                                v_chr_bus := bus_read(pattern_table_addr);
                                -- Shift the pattern table
                                shift_right(reg.pattern_table_1);
                                shift_right(reg.pattern_table_2);
                            when "111" =>
                                -- This if the final clock cycle of a fetch
                                -- process. The renderer needs a new set of
                                -- data, so copy the temporary pattern byte
                                -- into pattern_table_1, save pattern_table_2,
                                -- and copy the temporary attribute value into
                                -- attr_val
                                reg.pattern_table_1(shift_high downto shift_low) <=
                                    reg.pattern_tmp;
                                reg.pattern_table_1((shift_low - 1) downto 0) <=
                                    reg.pattern_table_1(shift_low downto 1);
                                reg.pattern_table_2(shift_high downto shift_low) <=
                                    chr_data_in;
                                reg.pattern_table_2((shift_low - 1) downto 0) <=
                                    reg.pattern_table_2(shift_low downto 1);
                                reg.attr_val <= reg.attr_tmp;
                            when others =>
                        end case;
                    when 336 to 339 =>
                        -- These are garbage name table accesses
                        if reg.cur_time.cycle(0) = '0'
                        then
                            -- Name table fetch.
                            v_chr_bus :=
                               bus_read(v_bg_tile_idx_addr.name_table_addr);
                        else
                            -- Update tile index register with the returned
                            -- data.
                            reg.tile_idx <= chr_data_in;
                        end if;
                    when others;
                end case;
            end if;

            -- Fetch sprite data
            if scanline_valid(reg.cur_time) and reg.mask.enable_sprite
            then
                case to_integer(reg.cur_time.cycle) is
                    when 0 to 63 =>
                        -- For the first 64 clock cycles, initialize secondary
                        -- OAM memory to 0xFF. Each memory access takes 2
                        -- clock cycles (one to write to the data register, one
                        -- to write to the memory)
                        if reg.cur_time.cycle(0) = '0'
                        then
                            reg.oam_data <= (others => '1');
                        else
                            reg.sec_oam(v_spr_sec_oam_addr) <= reg.oam_data;
                            reg.sec_oam_addr <= reg.sec_oam_addr + "1";
                        end if;
                        reg.status.spr_overfow <= false;
                        reg.oam_overflow       <= false;

                        -- Shift the sprite buffers as needed
                        for i in reg.sprite_buffer'range
                        loop
                            if reg.sprite_buffer(i).x_coord = COORD_ZERO
                            then
                                shift_right(reg.sprite_buffer(i).pattern_1);
                                shift_right(reg.sprite_buffer(i).pattern_2);
                            else
                                reg.sprite_buffer(i).x_coord <=
                                    reg.sprite_buffer(i).x_coord - "1";
                            end if;
                        end loop;
                    when 64 to 255 =>
                        -- Even-numbered memory accesses are reads from OAM
                        -- memory
                        if reg.cur_time.cycle(0) = '0'
                        then
                            reg.oam_data <= oam(v_spr_oam_addr);
                        else
                            -- If we're reading the y-coordinate, it's in range,
                            -- and the sprite counter hasn't overflowed, or if
                            -- we've already started copying a sprite over, copy
                            -- this byte of data to secondary OAM memory
                            if (reg.oam_addr(1 downto 0) /= "00") or
                               v_spr_copy_sprite
                            then
                                sec_oam(v_spr_sec_oam_addr) <= reg.oam_data;

                                -- Set the overflow flag
                                if reg.sec_oam_addr = SEC_OAM_ADDR_MAX
                                then
                                    reg.status.spr_overflow <= true;
                                end if;
                                reg.sec_oam_addr <= reg.sec_oam_addr + "1";

                                if reg.oam_addr = SEC_OAM_ADDR_MAX
                                reg.oam_addr <= reg.oam_addr + "1";
                            else
                                reg.oam_addr <= reg.oam_addr + "100";
                            end if;
                        end if;

                        -- Shift the sprite buffers as needed
                        for i in reg.sprite_buffer'range
                        loop
                            if reg.sprite_buffer(i).x_coord = COORD_ZERO
                            then
                                shift_right(reg.sprite_buffer(i).pattern_1);
                                shift_right(reg.sprite_buffer(i).pattern_2);
                            else
                                reg.sprite_buffer(i).x_coord <=
                                    reg.sprite_buffer(i).x_coord - "1";
                            end if;
                        end loop;
                    when 256 to 319 =>
                        -- This does not correctly handle horizontal and
                        -- vertical flipping of sprites yet
                        case reg.cur_time.cycle(2 downto 0) is
                            -- First 2 CHR memory accesses are garbage
                            when "000" =>
                                v_chr_bus := bus_read(v_bg_tile_idx_addr.name_table_addr);
                                -- Read the sprite y-coordinate
                                reg.sprite_y_coord <= sec_oam(v_spr_sec_oam_addr);
                                reg.sec_oam_addr <= reg.sec_oam_addr + "1";
                            when "001" =>
                                -- Read the sprite tile index
                                reg.sprite_tile_idx <= sec_oam(v_spr_sec_addr);
                                reg.sec_oam_addr <= reg.sec_oam_addr + "1";
                            when "010" =>
                                v_chr_bus := bus_read(v_bg_tile_idx_addr.name_table_addr);
                                -- Read the sprite attributes
                                reg.sprite_attr <= to_sprite_attr(sec_oam(v_spr_sec_oam_addr));
                                reg.sec_oam_addr <= reg.sec_oam_addr + "1";
                            when "011" =>
                                -- Save relevant sprite attributes
                                reg.sprite_buffer(v_spr_buf_addr).palette <=
                                    reg.sprite_attr.palette;
                                reg.sprite_buffer(v_spr_buf_addr).behind_bg <=
                                    reg.sprite_attr.behind_bg;
                                -- Read the sprite x-coordinate
                                reg.sprite_buffer(v_spr_buf_addr).x_coord <=
                                    sec_oam(v_spr_sec_addr);
                                reg.sec_oam_addr <= reg.sec_oam_addr + "1";
                            when "100" =>
                                v_bg_pattern_table_addr :=
                                    get_pattern_table('0',
                                                      reg.control.pattern_table_select,
                                                      reg.cur_sprite.tile_idx,
                                                      v_spr_tile_y_offset,
                                                      false);
                            when "101" =>
                                reg.sprite_buffer(v_spr_buf_addr).pattern_1 <=
                                    chr_data_in;
                            when "110" =>
                                v_bg_pattern_table_addr :=
                                    get_pattern_table('1',
                                                      reg.control.pattern_table_select,
                                                      reg.cur_sprite.tile_idx,
                                                      v_spr_tile_y_offset,
                                                      false);
                            when "111" =>
                                reg.sprite_buffer(v_spr_buf_addr).pattern_2 <=
                                    chr_data_in;
                        end case;
                    when 320 to 340 =>
                        reg.oam_data <= sec_oam(v_spr_sec_oam_addr);
                    when others =>
                        null;
                end case;
            end if;

        
            -- Control vbl status register and vint if so enabled
            if is_vblank_start(reg.cur_time)
            then
                reg.status.vbl <= true;
                vint           <= reg.control.vbl_enable;
            elsif is_vblank_end(reg.cur_time)
            then
                reg.status.vbl <= false;
                vint           <= false;
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
            if is_bus_write(ppu_bus) then
                case ppu_bus.address is
                    -- Control Register
                    when "000" =>
                        reg.control <= to_control_t(ppu_data_in);
                    -- Mask Register
                    when "001" =>
                        reg.mask <= to_mask_t(ppu_data_in);
                    -- OAM Address
                    --when "011" =>
                    --    v_reg.oam_addr := ppu_data_in;
                    -- OAM Data
                    --when "100" =>
                    --    v_oam_bus := bus_write(reg.oam_addr);
                    --    v_oam_data_wr := mmap_data_rd;
                        -- OAM Address register is incremented after write access
                    --    v_reg.oam_addr := reg.oam_addr + "1";
                    -- Scroll Offset
                    when "101" =>
                        if reg.count = "0" then
                            reg.addr_tmp(4 downto 0) <= ppu_data_in(7 downto 3);
                            reg.fine_scroll <= ppu_data_in(2 downto 0);
                        else
                            -- The lower three bits of the value written
                            -- (scanline within tile) are copied to D14-D12 of
                            -- addr_tmp, and the upper five bits (distance from
                            -- top in tiles) are copied to D9-D5 of addr_tmp
                            reg.addr_tmp(14 downto 12) <= ppu_data_in(2 downto 0);
                            reg.addr_tmp(9 downto 5) <= ppu_data_in(7 downto 3);
                        end if;
                        reg.count <= reg.count + "1";
                    -- PPU Address
                    when "110" =>
                        if reg.count = "0" then
                            -- The first write to PPUADDR sets the high address
                            -- byte
                            reg.addr_tmp(14) <= '0';
                            reg.addr_tmp(13 downto 8) <= ppu_data_in(5 downto 0);
                        else
                            reg.addr_tmp(7 downto 0) <= ppu_data_in;
                            reg.ppu_addr <= reg.addr_tmp(14 downto 8) &
                                            ppu_data_in;
                        end if;
                        reg.count <= reg.count + "1";
                    -- PPU Data
                    when "111" =>
                        v_chr_bus := bus_read(reg.ppu_addr);
                        chr_data_out <= ppu_data_in;
                        reg.ppu_addr <= incr_ppu_addr(reg.ppu_addr,
                                                      reg.control.ppu_incr_32);
                    when others =>
                end case;
            -- Reads from CPU
            elsif is_bus_read(ppu_bus) then
                case ppu_bus.address is
                    -- Status
                    when "010" =>
                        ppu_data_out(7 downto 5) <= to_std_logic(reg.status);
                        ppu_data_out(4 downto 0) <= "00000";
                        -- Reads from status register clear vbl signal
                        reg.status.vbl <= false;
                        -- And reset the count register
                        reg.count <= "0";
                    -- OAM Data
                    --when ADDR_OAM_DATA =>
                    --    v_oam_bus := bus_read(reg.oam_addr);
                    --    v_mmap_data_rw := oam_data_rd;
                    -- PPU Data
                    when "111" =>
                        v_chr_bus := bus_write(reg.ppu_addr);
                        reg.ppu_addr <= incr_ppu_addr(reg.ppu_addr,
                                                      reg.control.ppu_incr_32);
                    when others =>
                end case;
            end if;
            -- }
            
            if is_rendering(reg.mask, reg.cur_time)
            then
                v_rnd_is_sprite := false;
                v_rnd_bg_pattern_color := to_color(reg.attr_val,
                                                   reg.pattern_table_1(0),
                                                   reg.pattern_table_2(0));
                for i in reg.sprite_buffer'range
                loop
                    v_rnd_spr_pattern_color :=
                        to_color(reg.sprite_buffer(i).palette,
                                 reg.sprite_buffer(i).pattern_table_1(0),
                                 reg.sprite_buffer(i).pattern_table_2(0));
                    if not is_sprite and 
                       not reg.sprite_buffer(i).behind_bg and
                       v_rnd_spr_pattern_color /= COLOR_ZERO
                    then
                        v_rnd_is_sprite := true;
                        v_rnd_pattern_color := v_rnd_spr_pattern_color;
                    end if;

                    if v_rnd_spr_pattern_color /= COLOR_ZERO and
                       v_rnd_bg_pattern_color /= COLOR_ZERO
                    then
                        reg.status.spr_0_hit <= true;
                    end if;
                end loop;

                v_palette_bus.address := to_palette_addr(v_rnd_is_sprite,
                                                         v_rnd_pattern_color;
                pixel_bus.pixel := palette_data_in;
                pixel_bus.valid := true;
            end if;

            -- If the PPU address is above 0x3F00, then we need
            -- to read from the Palette RAM
            if is_bus_active(v_chr_bus) and v_chr_bus.address >= 14x"3F00"
            then
                v_palette_bus.read := v_chr_bus.read;
                v_palette_bus.write := v_chr_bus.write;
                v_palette_bus.address := v_chr_bus.address(palette_addr_t'RANGE);
                v_palette_data_out := v_chr_data_out;
                
                -- Clear the read from the external bus
                v_chr_bus := bus_idle(v_chr_bus);
            end if;

            -- Update combinational signals
            chr_bus <= v_chr_bus;
            palette_bus <= v_palette_bus;
            chr_data_out <= v_chr_data_out;
            palette_data_out <= v_palette_data_out;
        end if;

    end process;

end behavioral;
