library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.prg_ram_bus_types.all;
use work.exram_bus_types.all;
use work.cart_types.all;
use work.lib_mmc5_audio.all;

-- Boards built around the Nintendo MMC5 (5): EKROM, ELROM, ETROM and
-- EWROM. PRG ROM and PRG RAM are banked in four modes, with PRG RAM at
-- 0x6000 and optionally in the windows at 0x8000-0xDFFF. CHR is banked in
-- four modes, with a second set of registers for the background when
-- sprites are 8x16. The 1KB of ExRAM inside the chip is a nametable,
-- extended attributes or RAM for the CPU. It is kept with the memories of
-- the board, with a bus for the CPU and one for the PPU. Each nametable is
-- CIRAM, ExRAM or a fill tile. The MMC5 watches the reads of the PPU to
-- find the start of each scanline, which clocks a counter that raises an
-- IRQ, and to tell sprite fetches from background fetches. In the vertical
-- split, the tiles on one side of a column come from ExRAM with their own
-- vertical scroll. The audio (lib_mmc5_audio) is two pulses and a PCM DAC,
-- which can raise an IRQ of its own. NES carts have no audio pins, so the
-- output of the audio is only built when told to. Its registers, status
-- and IRQ are always there, as on an NES cart
package lib_mapper_mmc5 is

    -- The mapper number is that of a board built around the MMC5
    function is_mmc5_mapper(mapper_num : mapper_num_t) return boolean;

    -- An iNES header gives no PRG RAM size. 64KB covers every board, and no
    -- game is known to depend on the banks of a smaller RAM mirroring
    constant MMC5_INES_PRG_RAM_MASK : prg_ram_addr_t := x"FFFF";

    -- 0x5100
    type prg_mode_t is
    (
        PRG_32KB,
        PRG_16KB,
        PRG_16KB_8KB,
        PRG_8KB
    );

    -- 0x5101: CHR banks of 8KB, 4KB, 2KB or 1KB
    subtype chr_mode_t is natural range 0 to 3;

    -- 0x5104
    type exram_mode_t is
    (
        EXRAM_NT,
        EXRAM_EXT_ATTR,
        EXRAM_RAM,
        EXRAM_ROM
    );

    -- 0x5105, for each nametable
    type nt_source_t is
    (
        NT_CIRAM_0,
        NT_CIRAM_1,
        NT_EXRAM,
        NT_FILL
    );
    type nt_source_arr_t is array(0 to 3) of nt_source_t;

    -- 0x5114-0x5117. Bit 7 selects PRG ROM rather than PRG RAM; it is
    -- always set for 0x5117
    subtype prg_reg_t is unsigned(7 downto 0);
    type prg_reg_arr_t is array(0 to 3) of prg_reg_t;

    -- 0x5113
    subtype prg_ram_reg_t is unsigned(2 downto 0);

    -- 0x5120-0x512B, with the bits of 0x5130 above the 8 written
    subtype chr_reg_t is unsigned(9 downto 0);
    type chr_reg_arr_t is array(0 to 11) of chr_reg_t;

    -- 0x5205 and 0x5206
    subtype factor_t is natural range 0 to 255;

    -- A scanline counted by the MMC5, or the vertical scroll of the split
    subtype scanline_t is natural range 0 to 255;

    -- The reads before the last from the same nametable address. The
    -- start of a scanline is detected at the read after the third
    subtype match_count_t is natural range 0 to 2;

    -- The CPU cycles since the PPU last read. The PPU is no longer
    -- rendering after the last
    subtype idle_cycles_t is natural range 0 to 3;

    -- The reads the PPU has made since the start of the scanline was
    -- detected, counting the read at which it was
    subtype fetch_count_t is natural range 0 to 255;

    -- A row or column of tiles in ExRAM
    subtype tile_pos_t is natural range 0 to 31;

    -- The palette of a background tile, one field of an attribute byte
    subtype palette_t is std_logic_vector(1 downto 0);

    -- The part of a background tile fetch the PPU is reading, as the MMC5
    -- tells from the order of its reads
    type bg_fetch_t is
    (
        FETCH_NONE,
        FETCH_NT,
        FETCH_AT,
        FETCH_PT_LOW,
        FETCH_PT_HIGH
    );

    type mapper_mmc5_reg_t is record
        prg_mode        : prg_mode_t;
        chr_mode        : chr_mode_t;
        -- 0x5102 and 0x5103
        prg_ram_protect : std_logic_vector(3 downto 0);
        exram_mode      : exram_mode_t;
        nt_sources      : nt_source_arr_t;
        fill_tile       : data_t;
        fill_palette    : palette_t;

        prg_ram_bank    : prg_ram_reg_t;
        prg_regs        : prg_reg_arr_t;

        chr_regs        : chr_reg_arr_t;
        chr_upper       : unsigned(1 downto 0);
        -- The last CHR registers written were 0x5128-0x512B
        chr_bg_written  : boolean;

        multiplicand    : factor_t;
        multiplier      : factor_t;

        -- Bit 5 of the last write to 0x2000
        sprite_8x16     : boolean;
        -- Bits 4-3 of the last write to 0x2001 were not both clear. When
        -- they were the MMC5 makes no substitutions on the PPU data bus:
        -- no separate background banks and no extended attributes
        substitutions   : boolean;

        irq_target      : scanline_t;
        irq_enable      : boolean;
        irq_pending     : boolean;

        -- The PPU is rendering visible scanlines
        in_frame        : boolean;
        scanline        : scanline_t;
        -- The address of the last read
        last_addr       : chr_addr_t;
        match_count     : match_count_t;
        fetch_count     : fetch_count_t;
        -- The PPU has read since the last CPU cycle
        ppu_reading     : boolean;
        idle_cycles     : idle_cycles_t;

        bg_fetch        : bg_fetch_t;
        -- The ExRAM byte of the last nametable fetch
        ext_attr        : data_t;

        -- 0x5200: the split is enabled, is right of the threshold rather
        -- than left of it, and the threshold in tiles
        split_enable    : boolean;
        split_right     : boolean;
        split_threshold : tile_pos_t;
        -- 0x5201 and 0x5202
        split_scroll    : scanline_t;
        split_bank      : unsigned(7 downto 0);
        -- The background tile being fetched is in the split region, and
        -- its place in the ExRAM nametable
        split_inside    : boolean;
        split_row       : tile_pos_t;
        split_col       : tile_pos_t;

        audio           : mmc5_audio_t;
    end record;

    constant RESET_MAPPER_MMC5_REG : mapper_mmc5_reg_t :=
    (
        -- The Koei games never write 0x5100 and expect mode 3, and the
        -- reset vector must be in the last bank of PRG ROM
        prg_mode => PRG_8KB,
        chr_mode => 0,
        prg_ram_protect => (others => '0'),
        exram_mode => EXRAM_NT,
        nt_sources => (others => NT_CIRAM_0),
        fill_tile => (others => '0'),
        fill_palette => (others => '0'),

        prg_ram_bank => (others => '0'),
        prg_regs => (3 => (others => '1'), others => (others => '0')),

        chr_regs => (others => (others => '0')),
        chr_upper => (others => '0'),
        chr_bg_written => false,

        -- The power-on values measured on the MMC5A
        multiplicand => 255,
        multiplier => 255,

        sprite_8x16 => false,
        substitutions => false,

        irq_target => 0,
        irq_enable => false,
        irq_pending => false,

        in_frame => false,
        scanline => 0,
        last_addr => (others => '0'),
        match_count => 0,
        fetch_count => 0,
        ppu_reading => false,
        idle_cycles => 0,

        bg_fetch => FETCH_NONE,
        ext_attr => (others => '0'),

        split_enable => false,
        split_right => false,
        split_threshold => 0,
        split_scroll => 0,
        split_bank => (others => '0'),
        split_inside => false,
        split_row => 0,
        split_col => 0,

        audio => RESET_MMC5_AUDIO
    );

    type mapper_mmc5_out_t is record
        reg  : mapper_mmc5_reg_t;
        cart : cart_out_t;
    end record;

    -- The output of the audio is built when audio is set
    function cycle_mapper_mmc5
    (
        reg      : mapper_mmc5_reg_t;
        audio    : boolean;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc5_out_t;

end package lib_mapper_mmc5;


package body lib_mapper_mmc5 is

    function is_mmc5_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        return mapper_num = x"005";
    end;

    -- The low 12 bits of a CPU access to 0x5000-0x5FFF, where the registers
    -- and ExRAM are, or -1 for any other access
    function get_reg_addr(cpu_in : cart_cpu_in_t) return integer
    is
    begin
        if not cpu_in.romsel and
           cpu_in.prg_bus.address(14 downto 12) = "101"
        then
            return to_integer(cpu_in.prg_bus.address(11 downto 0));
        else
            return -1;
        end if;
    end;

    -- The CPU reads 0xFFFA or 0xFFFB, the NMI vector
    function is_nmi_vector_read(cpu_in : cart_cpu_in_t) return boolean
    is
    begin
        return cpu_in.romsel and
               is_bus_read(cpu_in.prg_bus) and
               cpu_in.prg_bus.address(14 downto 1) = "11111111111101";
    end;

    -- The PPU address is in a nametable, 0x2000-0x2FFF
    function is_nt_addr(addr : chr_addr_t) return boolean
    is
    begin
        return addr(13 downto 12) = "10";
    end;

    -- The PPU address is in the attribute table of a nametable
    function is_attr_addr(addr : chr_addr_t) return boolean
    is
    begin
        return addr(9 downto 6) = "1111";
    end;

    function get_nt_source
    (
        reg  : mapper_mmc5_reg_t;
        addr : chr_addr_t
    )
    return nt_source_t
    is
    begin
        return reg.nt_sources(to_integer(addr(11 downto 10)));
    end;

    -- A 2-bit palette in each of the four fields of an attribute byte
    function repeat_palette(palette : palette_t) return data_t
    is
    begin
        return palette & palette & palette & palette;
    end;

    -- The PPU is fetching sprite patterns: reads 127 to 158 after the
    -- start of the scanline, which are dots 257 to 320
    function is_sprite_fetch(reg : mapper_mmc5_reg_t) return boolean
    is
    begin
        return reg.in_frame and
               reg.fetch_count >= 127 and
               reg.fetch_count <= 158;
    end;

    -- ExRAM is a nametable or extended attributes
    function is_exram_nt_mode(reg : mapper_mmc5_reg_t) return boolean
    is
    begin
        return reg.exram_mode = EXRAM_NT or reg.exram_mode = EXRAM_EXT_ATTR;
    end;

    -- The read of the nametable byte of tile 0 of the next scanline, at dot
    -- 321. Tiles 0 and 1 are fetched at the end of the scanline before
    -- theirs, and tile 2 at dot 1, before its start is detected
    constant SPLIT_PREFETCH_COUNT : fetch_count_t := 159;

    -- The tile of the scanline, 0 to 33, whose nametable byte is being
    -- read. Tile 3 is read 3 reads after the start was detected, at dot 9,
    -- and tile 33 120 reads after that
    function get_split_col(fetch_count : fetch_count_t) return natural
    is
    begin
        if fetch_count >= SPLIT_PREFETCH_COUNT + 8
        then
            return 2;
        elsif fetch_count >= SPLIT_PREFETCH_COUNT
        then
            return (fetch_count - SPLIT_PREFETCH_COUNT) / 4;
        elsif fetch_count >= 123
        then
            return 33;
        else
            return (fetch_count + 9) / 4;
        end if;
    end;

    -- The vertical scroll of 0x5201 plus the scanline wraps from 239 to 0
    -- like that of the PPU, but from 255 when it starts at 240 or more, so
    -- the attribute rows are read as tiles
    function get_split_y
    (
        scroll : scanline_t;
        line   : natural
    )
    return scanline_t
    is
        variable sum : natural range 0 to 511;
    begin
        sum := scroll + line;
        if scroll < 240 and sum >= 240
        then
            sum := sum - 240;
        end if;

        return sum mod 256;
    end;

    -- At the nametable fetch of a background tile, whether the tile is in
    -- the split region, counted in fetches from the left of the screen
    -- whatever the horizontal scroll, and its place in ExRAM. The split is
    -- only made with ExRAM as a nametable or extended attributes
    function fetch_split_tile(reg : mapper_mmc5_reg_t) return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
        variable col : natural range 0 to 33;
        variable line : natural range 0 to 256;
    begin
        ret := reg;
        col := get_split_col(reg.fetch_count);
        if reg.fetch_count >= SPLIT_PREFETCH_COUNT
        then
            line := reg.scanline + 1;
        else
            line := reg.scanline;
        end if;

        ret.split_inside := reg.split_enable and
                            reg.substitutions and
                            reg.in_frame and
                            is_exram_nt_mode(reg) and
                            (col >= reg.split_threshold) = reg.split_right;
        ret.split_row := get_split_y(reg.split_scroll, line) / 8;
        ret.split_col := col mod 32;

        return ret;
    end;

    -- The PPU is no longer rendering. The MMC5 forgets the address of the
    -- last read, so that it starts looking for three matching reads again
    function exit_frame(reg : mapper_mmc5_reg_t) return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
    begin
        ret := reg;
        ret.in_frame := false;
        ret.last_addr := (others => '0');
        ret.match_count := 0;

        return ret;
    end;

    -- Leaves the frame: the scanline IRQ is acknowledged, and the counter
    -- starts from 0 at the next scanline that is detected
    function leave_frame(reg : mapper_mmc5_reg_t) return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
    begin
        ret := exit_frame(reg);
        ret.irq_pending := false;

        return ret;
    end;

    -- Every CPU cycle (M2 rising) the MMC5 checks whether the PPU has read.
    -- After 3 cycles without a read it is no longer rendering
    function cycle_cpu
    (
        reg      : mapper_mmc5_reg_t;
        clk_sync : boolean
    )
    return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
    begin
        ret := reg;

        if clk_sync
        then
            if reg.ppu_reading
            then
                ret.idle_cycles := 0;
            elsif reg.idle_cycles < idle_cycles_t'high
            then
                ret.idle_cycles := reg.idle_cycles + 1;
                if ret.idle_cycles = idle_cycles_t'high
                then
                    ret := exit_frame(ret);
                end if;
            end if;
            ret.ppu_reading := false;
        end if;

        return ret;
    end;

    -- The start of each read by the PPU. Three reads from the same
    -- nametable address are the two dummy fetches at the end of a scanline
    -- and the first fetch of the next, so the read after them (the
    -- attribute fetch at dot 3) is the start of a scanline
    function cycle_ppu_read
    (
        reg     : mapper_mmc5_reg_t;
        cart_in : cart_in_t
    )
    return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
        variable addr : chr_addr_t;
    begin
        ret := reg;
        addr := cart_in.ppu.chr_bus.address;

        if cart_in.ppu.ale and is_bus_read(cart_in.ppu.chr_bus)
        then
            if reg.match_count = match_count_t'high
            then
                if not reg.in_frame
                then
                    ret.in_frame := true;
                    ret.scanline := 0;
                    ret.irq_pending := false;
                else
                    ret.scanline := (reg.scanline + 1) mod (scanline_t'high + 1);
                    if ret.scanline = reg.irq_target and reg.irq_target /= 0
                    then
                        ret.irq_pending := true;
                    end if;
                end if;
                ret.fetch_count := 0;
            elsif reg.fetch_count < fetch_count_t'high
            then
                ret.fetch_count := reg.fetch_count + 1;
            end if;

            if is_nt_addr(addr) and addr = reg.last_addr
            then
                if reg.match_count < match_count_t'high
                then
                    ret.match_count := reg.match_count + 1;
                end if;
            else
                ret.match_count := 0;
            end if;
            ret.last_addr := addr;
            ret.ppu_reading := true;

            -- A background tile is a nametable, attribute and two pattern
            -- reads
            if is_nt_addr(addr) and
               not is_attr_addr(addr) and
               not is_sprite_fetch(ret)
            then
                ret.bg_fetch := FETCH_NT;
                ret := fetch_split_tile(ret);
            else
                case reg.bg_fetch is
                    when FETCH_NT => ret.bg_fetch := FETCH_AT;
                    when FETCH_AT => ret.bg_fetch := FETCH_PT_LOW;
                    when FETCH_PT_LOW => ret.bg_fetch := FETCH_PT_HIGH;
                    when others => ret.bg_fetch := FETCH_NONE;
                end case;
            end if;
        end if;

        return ret;
    end;

    function to_nt_source(data : std_logic_vector(1 downto 0)) return nt_source_t
    is
    begin
        case data is
            when "00" => return NT_CIRAM_0;
            when "01" => return NT_CIRAM_1;
            when "10" => return NT_EXRAM;
            when others => return NT_FILL;
        end case;
    end;

    -- A write to 0x2001. The MMC5 stops substituting when rendering is
    -- disabled, and leaves the frame when it is enabled again
    function write_ppu_mask
    (
        reg  : mapper_mmc5_reg_t;
        data : data_t
    )
    return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
    begin
        ret := reg;

        if data(4 downto 3) = "00"
        then
            ret := exit_frame(ret);
            ret.substitutions := false;
        elsif not reg.substitutions
        then
            ret := leave_frame(ret);
            ret.substitutions := true;
        end if;

        return ret;
    end;

    function write_register
    (
        reg      : mapper_mmc5_reg_t;
        reg_addr : natural;
        data     : data_t
    )
    return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
    begin
        ret := reg;

        case reg_addr is
            when 16#100# =>
                case data(1 downto 0) is
                    when "00" => ret.prg_mode := PRG_32KB;
                    when "01" => ret.prg_mode := PRG_16KB;
                    when "10" => ret.prg_mode := PRG_16KB_8KB;
                    when others => ret.prg_mode := PRG_8KB;
                end case;
            when 16#101# =>
                ret.chr_mode := to_integer(data(1 downto 0));
            when 16#102# =>
                ret.prg_ram_protect(1 downto 0) := data(1 downto 0);
            when 16#103# =>
                ret.prg_ram_protect(3 downto 2) := data(1 downto 0);
            when 16#104# =>
                case data(1 downto 0) is
                    when "00" => ret.exram_mode := EXRAM_NT;
                    when "01" => ret.exram_mode := EXRAM_EXT_ATTR;
                    when "10" => ret.exram_mode := EXRAM_RAM;
                    when others => ret.exram_mode := EXRAM_ROM;
                end case;
            when 16#105# =>
                for i in nt_source_arr_t'range
                loop
                    ret.nt_sources(i) := to_nt_source(data(2 * i + 1 downto 2 * i));
                end loop;
            when 16#106# =>
                ret.fill_tile := data;
            when 16#107# =>
                ret.fill_palette := data(1 downto 0);
            when 16#113# =>
                ret.prg_ram_bank := unsigned(data(prg_ram_reg_t'range));
            when 16#114# to 16#116# =>
                ret.prg_regs(reg_addr - 16#114#) := unsigned(data);
            when 16#117# =>
                ret.prg_regs(3) := unsigned('1' & data(6 downto 0));
            when 16#120# to 16#12B# =>
                ret.chr_regs(reg_addr - 16#120#) := reg.chr_upper & unsigned(data);
                ret.chr_bg_written := reg_addr >= 16#128#;
            when 16#130# =>
                ret.chr_upper := unsigned(data(1 downto 0));
            when 16#200# =>
                ret.split_enable := data(7) = '1';
                ret.split_right := data(6) = '1';
                ret.split_threshold := to_integer(data(4 downto 0));
            when 16#201# =>
                ret.split_scroll := to_integer(data);
            when 16#202# =>
                ret.split_bank := unsigned(data);
            when 16#203# =>
                ret.irq_target := to_integer(data);
            when 16#204# =>
                ret.irq_enable := data(7) = '1';
            when 16#205# =>
                ret.multiplicand := to_integer(data);
            when 16#206# =>
                ret.multiplier := to_integer(data);
            when others =>
                null;
        end case;

        return ret;
    end;

    function cycle_write
    (
        reg      : mapper_mmc5_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        reg_addr : integer
    )
    return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
    begin
        ret := reg;

        if clk_sync and is_bus_write(cart_in.cpu.prg_bus)
        then
            if reg_addr >= 0
            then
                ret := write_register(reg, reg_addr, cart_in.cpu.data);
            -- The MMC5 fully decodes the PPU registers it watches
            elsif is_low_addr(cart_in.cpu, "010000000000000")
            then
                ret.sprite_8x16 := cart_in.cpu.data(5) = '1';
            elsif is_low_addr(cart_in.cpu, "010000000000001")
            then
                ret := write_ppu_mask(reg, cart_in.cpu.data);
            end if;
        end if;

        return ret;
    end;

    -- Reads that change the state of the MMC5
    function cycle_read
    (
        reg      : mapper_mmc5_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        reg_addr : integer
    )
    return mapper_mmc5_reg_t
    is
        variable ret : mapper_mmc5_reg_t;
    begin
        ret := reg;

        if clk_sync
        then
            if is_nmi_vector_read(cart_in.cpu)
            then
                ret := leave_frame(reg);
            elsif is_bus_read(cart_in.cpu.prg_bus)
            then
                case reg_addr is
                    when 16#204# =>
                        ret.irq_pending := false;
                    when 16#010# =>
                        ret.audio := ack_mmc5_pcm_irq(reg.audio);
                    when others =>
                        null;
                end case;
            end if;
        end if;

        return ret;
    end;

    -- The CPU accesses 0x5C00-0x5FFF. It can only read ExRAM in the RAM and
    -- ROM modes, and can write it in any mode but ROM. As a nametable or
    -- extended attributes ExRAM can only be written while the PPU is
    -- rendering; otherwise 0 is written, as in Mesen. nesdev says the write
    -- may be ignored or corrupt the byte. Writes are made in the sync
    -- cycle, where the PRG channel of the cartridge memory bus always wins
    function map_cpu_exram
    (
        reg      : mapper_mmc5_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        reg_addr : integer;
        cart     : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable addr : exram_addr_t;
    begin
        ret := cart;
        addr := cart_in.cpu.prg_bus.address(exram_addr_t'range);

        if reg_addr >= 16#C00#
        then
            if is_bus_read(cart_in.cpu.prg_bus) and not is_exram_nt_mode(reg)
            then
                ret.mem.cpu_exram_bus := bus_read(addr);
            elsif clk_sync and
                  is_bus_write(cart_in.cpu.prg_bus) and
                  reg.exram_mode /= EXRAM_ROM
            then
                ret.mem.cpu_exram_bus := bus_write(addr);
                if reg.exram_mode = EXRAM_RAM or reg.in_frame
                then
                    ret.mem.data_to_cpu_exram := cart_in.cpu.data;
                else
                    ret.mem.data_to_cpu_exram := (others => '0');
                end if;
            end if;
        end if;

        return ret;
    end;

    -- The PPU is fetching a background tile in the split region
    function is_split_fetch(reg : mapper_mmc5_reg_t) return boolean
    is
    begin
        return reg.split_inside and
               reg.in_frame and
               reg.bg_fetch /= FETCH_NONE;
    end;

    -- The ExRAM address of the nametable or attribute byte of a tile in the
    -- split region
    function get_split_exram_addr(reg : mapper_mmc5_reg_t) return exram_addr_t
    is
    begin
        if reg.bg_fetch = FETCH_NT
        then
            return to_std_logic_vector(reg.split_row * 32 + reg.split_col,
                                       exram_addr_t'length);
        else
            return "1111" &
                   to_std_logic_vector(reg.split_row / 4, 3) &
                   to_std_logic_vector(reg.split_col / 4, 3);
        end if;
    end;

    -- The palette of a tile in the split region from its attribute byte,
    -- in each of the four attribute fields
    function get_split_attr
    (
        reg  : mapper_mmc5_reg_t;
        data : data_t
    )
    return data_t
    is
        variable palette : palette_t;
    begin
        if (reg.split_row / 2) mod 2 = 0
        then
            if (reg.split_col / 2) mod 2 = 0
            then
                palette := data(1 downto 0);
            else
                palette := data(3 downto 2);
            end if;
        elsif (reg.split_col / 2) mod 2 = 0
        then
            palette := data(5 downto 4);
        else
            palette := data(7 downto 6);
        end if;

        return repeat_palette(palette);
    end;

    -- The PPU accesses a nametable in ExRAM, or reads the ExRAM byte of
    -- each background nametable fetch for its extended attributes. A
    -- nametable in ExRAM reads as 0 and cannot be written in the RAM and
    -- ROM modes, so ExRAM is not accessed
    function map_ppu_exram
    (
        reg     : mapper_mmc5_reg_t;
        cart_in : cart_in_t;
        source  : nt_source_t;
        cart    : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable addr : chr_addr_t;
        variable in_exram : boolean;
    begin
        ret := cart;
        addr := cart_in.ppu.chr_bus.address;
        in_exram := source = NT_EXRAM;

        if is_nt_addr(addr) and is_split_fetch(reg)
        then
            if is_bus_read(cart_in.ppu.chr_bus)
            then
                ret.mem.ppu_exram_bus := bus_read(get_split_exram_addr(reg));
            end if;
        elsif is_nt_addr(addr) and is_exram_nt_mode(reg)
        then
            if is_bus_write(cart_in.ppu.chr_bus) and in_exram
            then
                ret.mem.ppu_exram_bus := bus_write(addr(exram_addr_t'range));
                ret.mem.data_to_ppu_exram := cart_in.ppu.data;
            elsif is_bus_read(cart_in.ppu.chr_bus) and
                  (in_exram or
                   (reg.exram_mode = EXRAM_EXT_ATTR and
                    reg.bg_fetch = FETCH_NT))
            then
                ret.mem.ppu_exram_bus := bus_read(addr(exram_addr_t'range));
            end if;
        end if;

        return ret;
    end;

    -- The PRG bank register for the window of a CPU access to
    -- 0x8000-0xFFFF, with its low bits replaced by CPU A14-A13 when the
    -- bank is larger than 8KB
    function get_prg_reg
    (
        reg    : mapper_mmc5_reg_t;
        window : prg_window_t
    )
    return prg_reg_t
    is
        variable ret : prg_reg_t;
    begin
        case reg.prg_mode is
            when PRG_32KB =>
                ret := reg.prg_regs(3);
                ret(1 downto 0) := window;
            when PRG_16KB =>
                if window(1) = '0'
                then
                    ret := reg.prg_regs(1);
                else
                    ret := reg.prg_regs(3);
                end if;
                ret(0) := window(0);
            when PRG_16KB_8KB =>
                if window(1) = '0'
                then
                    ret := reg.prg_regs(1);
                    ret(0) := window(0);
                else
                    ret := reg.prg_regs(to_integer(std_logic_vector(window)));
                end if;
            when PRG_8KB =>
                ret := reg.prg_regs(to_integer(std_logic_vector(window)));
        end case;

        return ret;
    end;

    -- Bit 2 of a PRG RAM bank selects one of two RAM chips. A board with
    -- 16KB has two 8KB chips. A board with 8KB or 32KB has one, so the CPU
    -- reads open bus when bit 2 is set. A RAM of 64KB holds every bank
    function is_two_chip_prg_ram(config : cart_config_t) return boolean
    is
    begin
        return config.prg_ram_mask(15 downto 13) = "001";
    end;

    function get_prg_ram_bank
    (
        config : cart_config_t;
        bank   : prg_ram_reg_t
    )
    return prg_ram_bank_8kb_t
    is
    begin
        if is_two_chip_prg_ram(config)
        then
            return "00" & bank(2);
        else
            return bank;
        end if;
    end;

    function has_prg_ram_bank
    (
        config : cart_config_t;
        bank   : prg_ram_reg_t
    )
    return boolean
    is
    begin
        return bank(2) = '0' or
               config.prg_ram_mask(15) = '1' or
               is_two_chip_prg_ram(config);
    end;

    -- The 1KB CHR bank of a pattern table access. With 8x16 sprites the
    -- background uses 0x5128-0x512B, which map both pattern tables alike.
    -- Larger banks use the last register of their 1KB banks
    function get_chr_bank
    (
        reg    : mapper_mmc5_reg_t;
        window : chr_window_t;
        bg     : boolean
    )
    return chr_bank_1kb_t
    is
        variable low_mask : chr_window_t;
        variable idx : natural range 0 to 11;
        variable bank : chr_reg_t;
    begin
        case reg.chr_mode is
            when 0 => low_mask := "111";
            when 1 => low_mask := "011";
            when 2 => low_mask := "001";
            when 3 => low_mask := "000";
        end case;
        idx := to_integer(std_logic_vector(window or low_mask));
        if bg
        then
            idx := 8 + idx mod 4;
        end if;

        bank := reg.chr_regs(idx);
        case reg.chr_mode is
            when 0 => return bank(7 downto 0) & window;
            when 1 => return bank(8 downto 0) & window(1 downto 0);
            when 2 => return bank & window(0);
            when 3 => return '0' & bank;
        end case;
    end;

    -- The PPU fetches the background with the separate registers: sprites
    -- are 8x16, and it is rendering but not fetching sprites. Otherwise,
    -- such as through 0x2007, the last set of registers written is used
    function is_bg_chr(reg : mapper_mmc5_reg_t) return boolean
    is
    begin
        if not reg.sprite_8x16 or not reg.substitutions
        then
            return false;
        elsif reg.in_frame
        then
            return not is_sprite_fetch(reg);
        else
            return reg.chr_bg_written;
        end if;
    end;

    -- Extended attributes replace the attribute and pattern reads of a
    -- background tile outside the split region
    function is_ext_attr_fetch(reg : mapper_mmc5_reg_t) return boolean
    is
    begin
        return reg.exram_mode = EXRAM_EXT_ATTR and
               reg.substitutions and
               reg.in_frame and
               not reg.split_inside and
               reg.bg_fetch >= FETCH_AT;
    end;

    -- The PPU reads data from the MMC5 rather than CIRAM or CHR
    function drive_ppu_data
    (
        cart : cart_out_t;
        data : data_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
    begin
        ret := cart;
        ret.ppu.ciram_ce := false;
        ret.ppu.data := data;
        ret.ppu.data_oe := true;

        return ret;
    end;

    -- The nametable data of a PPU access to a nametable in ExRAM or fill
    -- mode
    function get_nt_data
    (
        reg    : mapper_mmc5_reg_t;
        addr   : chr_addr_t;
        source : nt_source_t;
        exram  : data_t
    )
    return data_t
    is
    begin
        if source = NT_FILL
        then
            if is_attr_addr(addr)
            then
                return repeat_palette(reg.fill_palette);
            else
                return reg.fill_tile;
            end if;
        elsif is_exram_nt_mode(reg)
        then
            return exram;
        else
            return x"00";
        end if;
    end;

    function map_ppu
    (
        reg     : mapper_mmc5_reg_t;
        config  : cart_config_t;
        cart_in : cart_in_t;
        source  : nt_source_t;
        banks   : cart_banks_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable v_banks : cart_banks_t;
        variable addr : chr_addr_t;
    begin
        v_banks := banks;
        addr := cart_in.ppu.chr_bus.address;

        if addr(13) = '0'
        then
            -- The PPU gives the row of the pattern (CHR A0-A2), as on the
            -- Nintendo boards, which are wired in "CL" mode. Only when the
            -- fine scroll of 0x5201 is that of the PPU are the rows of the
            -- tiles in the split region in place
            if is_split_fetch(reg)
            then
                v_banks.chr := '0' & reg.split_bank & unsigned(addr(11 downto 10));
            elsif is_ext_attr_fetch(reg)
            then
                v_banks.chr := '0' &
                               reg.chr_upper &
                               unsigned(reg.ext_attr(5 downto 0)) &
                               unsigned(addr(11 downto 10));
            else
                v_banks.chr := get_chr_bank(reg,
                                            get_chr_window(cart_in.ppu),
                                            is_bg_chr(reg));
            end if;
        else
            v_banks.mirror := get_single_screen_mirror(to_std_logic(source = NT_CIRAM_1));
        end if;

        ret := map_cart(config, cart_in, v_banks);

        if is_bus_active(cart_in.ppu.chr_bus) and addr(13) = '1'
        then
            if is_split_fetch(reg)
            then
                if reg.bg_fetch = FETCH_NT
                then
                    ret := drive_ppu_data(ret, cart_in.mem.data_from_ppu_exram);
                else
                    ret := drive_ppu_data(ret,
                                          get_split_attr(reg,
                                                         cart_in.mem.data_from_ppu_exram));
                end if;
            elsif is_ext_attr_fetch(reg)
            then
                ret := drive_ppu_data(ret, repeat_palette(reg.ext_attr(7 downto 6)));
            elsif source = NT_EXRAM or source = NT_FILL
            then
                ret := drive_ppu_data(ret,
                                      get_nt_data(reg, addr, source,
                                                  cart_in.mem.data_from_ppu_exram));
            end if;
        end if;

        return ret;
    end;

    -- Data the CPU reads from the registers and ExRAM
    function read_register
    (
        reg     : mapper_mmc5_reg_t;
        cart_in  : cart_in_t;
        reg_addr : integer;
        cart     : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable product : std_logic_vector(15 downto 0);
    begin
        ret := cart;

        if is_bus_read(cart_in.cpu.prg_bus)
        then
            case reg_addr is
                when 16#010# =>
                    ret.cpu.data := get_mmc5_pcm_status(reg.audio);
                    ret.cpu.data_oe := true;
                when 16#015# =>
                    ret.cpu.data := get_mmc5_pulse_status(reg.audio);
                    ret.cpu.data_oe := true;
                when 16#204# =>
                    ret.cpu.data := to_std_logic(reg.irq_pending) &
                                    to_std_logic(reg.in_frame) &
                                    "000000";
                    ret.cpu.data_oe := true;
                when 16#205# | 16#206# =>
                    product := to_std_logic_vector(reg.multiplicand * reg.multiplier,
                                                   product'length);
                    if reg_addr = 16#205#
                    then
                        ret.cpu.data := product(7 downto 0);
                    else
                        ret.cpu.data := product(15 downto 8);
                    end if;
                    ret.cpu.data_oe := true;
                when 16#C00# to 16#FFF# =>
                    if not is_exram_nt_mode(reg)
                    then
                        ret.cpu.data := cart_in.mem.data_from_cpu_exram;
                        ret.cpu.data_oe := true;
                    end if;
                when others =>
                    null;
            end case;
        end if;

        return ret;
    end;

    function cycle_mapper_mmc5
    (
        reg      : mapper_mmc5_reg_t;
        audio    : boolean;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc5_out_t
    is
        variable ret : mapper_mmc5_out_t;
        variable reg_addr : integer;
        variable banks : cart_banks_t;
        variable prg_reg : prg_reg_t;
        variable ram_bank : prg_ram_reg_t;
        variable ram : boolean;
        variable source : nt_source_t;
    begin
        reg_addr := get_reg_addr(cart_in.cpu);

        ret.reg := cycle_cpu(reg, clk_sync);
        ret.reg := cycle_ppu_read(ret.reg, cart_in);
        ret.reg := cycle_write(ret.reg, clk_sync, cart_in, reg_addr);
        -- The audio is clocked every CPU cycle, before a write to its
        -- registers at 0x5000-0x501F
        ret.reg.audio := cycle_mmc5_audio(ret.reg.audio,
                                          clk_sync,
                                          is_bus_write(cart_in.cpu.prg_bus) and
                                          reg_addr >= 0 and
                                          reg_addr < 16#20#,
                                          reg_addr mod 2**5,
                                          cart_in.cpu.data);
        ret.reg := cycle_read(ret.reg, clk_sync, cart_in, reg_addr);

        -- The PPU sees the registers written by the CPU this cycle, and the
        -- read it starts this dot
        banks := default_banks(config);

        ram := false;
        ram_bank := ret.reg.prg_ram_bank;
        if cart_in.cpu.romsel
        then
            prg_reg := get_prg_reg(ret.reg, get_prg_window(cart_in.cpu));
            if prg_reg(7) = '0'
            then
                ram := true;
                ram_bank := prg_reg(prg_ram_reg_t'range);
                banks.prg_ram_8000 := true;
            else
                banks.prg := '0' & prg_reg(6 downto 0);
            end if;
        elsif is_prg_ram_window(cart_in.cpu)
        then
            ram := true;
            banks.prg_ram := true;
        end if;
        banks.prg_ram_bank := get_prg_ram_bank(config, ram_bank);

        source := get_nt_source(ret.reg, cart_in.ppu.chr_bus.address);
        ret.cart := map_ppu(ret.reg, config, cart_in, source, banks);
        ret.cart := map_ppu_exram(ret.reg, cart_in, source, ret.cart);
        ret.cart := map_cpu_exram(ret.reg, clk_sync, cart_in, reg_addr, ret.cart);

        -- Latched on both dots of the nametable read, so the second, which
        -- the cartridge memory bus always serves, is kept. Extended
        -- attributes are not used until the next read
        if ret.reg.bg_fetch = FETCH_NT and
           is_bus_read(ret.cart.mem.ppu_exram_bus)
        then
            ret.reg.ext_attr := cart_in.mem.data_from_ppu_exram;
        end if;

        if ram
        then
            if not has_prg_ram_bank(config, ram_bank)
            then
                ret.cart.cpu := CART_CPU_OUT_IDLE;
                ret.cart.mem.prg_ram_bus := PRG_RAM_BUS_IDLE;
            elsif ret.reg.prg_ram_protect /= "0110"
            then
                ret.cart.mem.prg_ram_bus.write := false;
            end if;
        end if;

        ret.cart := read_register(reg, cart_in, reg_addr, ret.cart);

        -- In PCM read mode the DAC is given what the CPU reads from
        -- 0x8000-0xBFFF
        if clk_sync and
           cart_in.cpu.romsel and
           cart_in.cpu.prg_bus.address(14) = '0' and
           is_bus_read(cart_in.cpu.prg_bus) and
           ret.cart.cpu.data_oe
        then
            ret.reg.audio := read_mmc5_pcm(ret.reg.audio, ret.cart.cpu.data);
        end if;

        ret.cart.cpu.irq := (reg.irq_pending and reg.irq_enable) or
                            get_mmc5_pcm_irq(reg.audio);
        if audio
        then
            ret.cart.audio := get_mmc5_audio_level(reg.audio);
        end if;

        return ret;
    end;

end package body;
