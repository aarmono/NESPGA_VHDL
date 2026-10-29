library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.prg_ram_bus_types.all;
use work.chr_ram_bus_types.all;
use work.exram_bus_types.all;
use work.chip_ram_bus_types.all;
use work.chr_bus_types.all;
use work.ciram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.prg_bus_types.all;
use work.palette_bus_types.all;
use work.cart_mem_bus_types.all;
use work.nes_types.all;
use work.nes_audio_mixer.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.cart_types.all;
use work.lib_cartridge.all;
use work.lib_nes_mmap.all;

package lib_nes is

    -- The header is loaded first, so that reset knows the board when it
    -- fills the RAMs
    type state_t is
    (
        STATE_LOAD,
        STATE_RESET,
        STATE_CLEAR,
        STATE_RUN,
        -- The reset button is held. The NES runs as in STATE_RUN, with the
        -- CPU, APU and PPU held in reset. Like the other reset states, the
        -- state only changes on CPU cycles, so they all leave reset on the
        -- same clock
        STATE_SOFT_RESET
    );
    
    -- Clocked off the CPU timer
    type reg_t is record
        cart_config : cart_config_t;
        mmap_reg    : cpu_mmap_reg_t;
        cur_cycle   : unsigned(cpu_addr_t'RANGE);
        cur_state   : state_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        cart_config => RESET_CART_CONFIG,
        mmap_reg => RESET_CPU_MMAP_REG,
        cur_cycle => x"0000",
        cur_state => STATE_LOAD
    );

    constant STARTUP_PALETTE : palette_t :=
    (
        resize(x"09", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"0D", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"10", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"24", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"04", pixel_t'length),
        resize(x"2C", pixel_t'length),
        resize(x"09", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"34", pixel_t'length),
        resize(x"03", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"04", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"14", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"3A", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"20", pixel_t'length),
        resize(x"2C", pixel_t'length),
        resize(x"08", pixel_t'length)
    );
    
    type nes_out_t is record
        reg                  : reg_t;
        cpu_bus              : cpu_mmap_bus_out_t;
        ppu_bus              : ppu_mmap_bus_out_t;
        -- Memories on the cartridge. PRG ROM and CHR ROM are in the ROM file,
        -- and each RAM shares its channel with the ROM. ExRAM is on both
        -- channels: the CPU accesses it on the PRG channel and the PPU on
        -- the CHR channel
        prg_cart_mem_bus     : cart_mem_bus_t;
        data_to_prg_cart_mem : data_t;
        chr_cart_mem_bus     : cart_mem_bus_t;
        data_to_chr_cart_mem : data_t;
        -- RAM inside the mapper chip that is on a bus of its own
        chip_ram_bus         : chip_ram_bus_t;
        data_to_chip_ram     : data_t;
        oam_bus              : oam_bus_t;
        data_to_oam          : data_t;
        sec_oam_bus          : sec_oam_bus_t;
        data_to_sec_oam      : data_t;
        palette_bus          : palette_bus_t;
        data_to_palette      : pixel_t;
        audio                : mixed_audio_t;
        reset                : boolean;
        -- The reset button, for the CPU, APU and PPU
        soft_reset           : boolean;
        irq                  : boolean;
        -- The RAMs are being filled, so the power up data changes
        power_up_enable      : boolean;
    end record;
    
    type nes_in_t is record
        reg                : reg_t;
        cpu_bus            : cpu_mmap_bus_in_t;
        ppu_bus            : ppu_mmap_bus_in_t;
        data_from_cart_mem : data_t;
        cart               : cart_out_t;
        oam_bus            : oam_bus_t;
        data_to_oam        : data_t;
        sec_oam_bus        : sec_oam_bus_t;
        data_to_sec_oam    : data_t;
        palette_bus        : palette_bus_t;
        data_to_palette    : pixel_t;
        audio              : apu_out_t;
        -- The power up data is valid
        power_up_ready     : boolean;
        power_up_data      : power_up_data_t;
        -- The reset button is held
        soft_reset         : boolean;
    end record;

    function cycle_nes(nes_in : nes_in_t) return nes_out_t;

    function parse_mirror(mirror : std_logic_vector(1 downto 0)) return mirror_t;

    -- The ROM file is in the lower half of the cartridge memory bus, from
    -- address 0. The cartridge RAMs are in the upper half, each in its own
    -- fixed 64 KB window: PRG RAM, then CHR RAM, then ExRAM
    constant CART_RAM_BASE : natural := 2**(cart_mem_addr_t'length - 1);

    -- Offset into the cartridge RAM windows
    subtype cart_ram_addr_t is std_logic_vector(17 downto 0);

    function is_cart_ram(cart_mem_bus : cart_mem_bus_t) return boolean;

end lib_nes;

package body lib_nes is

    constant PRG_RAM_WINDOW : cart_mem_addr_t :=
        std_logic_vector(to_unsigned(CART_RAM_BASE, cart_mem_addr_t'length));
    constant CHR_RAM_WINDOW : cart_mem_addr_t :=
        std_logic_vector(to_unsigned(CART_RAM_BASE + 16#10000#,
                                     cart_mem_addr_t'length));
    constant EXRAM_WINDOW : cart_mem_addr_t :=
        std_logic_vector(to_unsigned(CART_RAM_BASE + 16#20000#,
                                     cart_mem_addr_t'length));

    function parse_mirror(mirror : std_logic_vector(1 downto 0)) return mirror_t
    is
        variable ret : mirror_t;
    begin
        case mirror is
            when "00" =>
                ret := MIRROR_HORZ;
            when "01" =>
                ret := MIRROR_VERT;
            when "10" |
                 "11" =>
                ret := MIRROR_FOUR;
            when others =>
                ret := MIRROR_HORZ;
        end case;

        return ret;
    end;

    -- The offset in the ROM file of the PRG ROM (offset_16kb = 0) or the
    -- CHR ROM (offset_16kb = the size of the PRG ROM)
    function get_file_offset
    (
        offset_16kb : rom_blocks_t;
        has_trainer : boolean
    )
    return unsigned
    is
        variable ret : unsigned(cart_mem_addr_t'range);
    begin
        ret := resize(offset_16kb &
                      "0000" &
                      to_std_logic(has_trainer) &
                      b"0_0001_0000",
                      ret'length);
        
        return ret;
    end;

    -- The ROM file access for an access to PRG ROM or CHR ROM
    function get_cart_mem_bus
    (
        rom_bus     : cart_mem_bus_t;
        file_offset : unsigned
    )
    return cart_mem_bus_t
    is
    begin
        if is_bus_active(rom_bus)
        then
            return bus_read(unsigned(rom_bus.address) + file_offset);
        else
            return CART_MEM_BUS_IDLE;
        end if;
    end;

    function is_cart_ram(cart_mem_bus : cart_mem_bus_t) return boolean
    is
    begin
        return cart_mem_bus.address(cart_mem_addr_t'high) = '1';
    end;

    -- The cartridge memory bus access for an access to PRG RAM
    function get_prg_ram_bus(ram_bus : prg_ram_bus_t) return cart_mem_bus_t
    is
        variable ret : cart_mem_bus_t;
    begin
        ret.address := PRG_RAM_WINDOW;
        ret.address(prg_ram_addr_t'range) := ram_bus.address;
        ret.read := ram_bus.read;
        ret.write := ram_bus.write;

        return ret;
    end;

    -- The cartridge memory bus access for an access to CHR RAM
    function get_chr_ram_bus(ram_bus : chr_ram_bus_t) return cart_mem_bus_t
    is
        variable ret : cart_mem_bus_t;
    begin
        ret.address := CHR_RAM_WINDOW;
        ret.address(chr_ram_addr_t'range) := ram_bus.address;
        ret.read := ram_bus.read;
        ret.write := ram_bus.write;

        return ret;
    end;

    -- The cartridge memory bus access for an access to ExRAM
    function get_exram_bus(ram_bus : exram_bus_t) return cart_mem_bus_t
    is
        variable ret : cart_mem_bus_t;
    begin
        ret.address := EXRAM_WINDOW;
        ret.address(exram_addr_t'range) := ram_bus.address;
        ret.read := ram_bus.read;
        ret.write := ram_bus.write;

        return ret;
    end;

    -- Reset fills the first 8KB of PRG RAM and CHR RAM. A board with more
    -- needs the rest cleared after reset
    function needs_ram_clear(config : cart_config_t) return boolean
    is
    begin
        return not is_zero(config.prg_ram_mask and not DEFAULT_RAM_MASK) or
               not is_zero(config.chr_ram_mask and not DEFAULT_RAM_MASK);
    end;

    -- What PRG RAM or chip RAM powers up with: random bytes, unless the
    -- board keeps its contents without power. There is no save to load, so
    -- it holds a blank one, which games expect more than random bytes
    function get_cart_ram_fill
    (
        config        : cart_config_t;
        power_up_data : data_t
    )
    return data_t
    is
    begin
        if has_save_ram(config)
        then
            return get_save_ram_fill(config);
        else
            return power_up_data;
        end if;
    end;

    function cycle_nes(nes_in : nes_in_t) return nes_out_t
    is
        variable ret : nes_out_t;
        
        variable cpu_map_in  : cpu_mmap_in_t;
        variable cpu_map_out : cpu_mmap_out_t;
        
        variable mirror : std_logic_vector(1 downto 0);
    begin
        ret.reg := nes_in.reg;
        
        ret.cpu_bus := CPU_MMAP_BUS_IDLE;
        ret.ppu_bus := PPU_MMAP_BUS_IDLE;

        ret.prg_cart_mem_bus := CART_MEM_BUS_IDLE;
        ret.data_to_prg_cart_mem := (others => '-');
        ret.chr_cart_mem_bus := CART_MEM_BUS_IDLE;
        ret.data_to_chr_cart_mem := (others => '-');

        ret.chip_ram_bus := nes_in.cart.mem.chip_ram_bus;
        ret.data_to_chip_ram := nes_in.cart.mem.data_to_chip_ram;
        
        ret.oam_bus := OAM_BUS_IDLE;
        ret.sec_oam_bus := SEC_OAM_BUS_IDLE;
        ret.palette_bus := PALETTE_BUS_IDLE;
        ret.data_to_oam := (others => '-');
        ret.data_to_sec_oam := (others => '-');
        ret.data_to_palette := (others => '-');
        
        ret.audio := (others => '-');
        ret.reset := false;
        ret.soft_reset := false;
        ret.irq   := false;
        ret.power_up_enable := false;
        
        case nes_in.reg.cur_state is
            when STATE_LOAD =>
                ret.reset := true;
                ret.prg_cart_mem_bus :=
                    bus_read(resize(nes_in.reg.cur_cycle,
                                    cart_mem_addr_t'length));
                case nes_in.reg.cur_cycle is
                    -- Size of PRG ROM in 16 KB units 
                    when x"0004" =>
                        ret.reg.cart_config.prg_rom_16kb_blocks :=
                            unsigned(nes_in.data_from_cart_mem);
                    -- Size of CHR ROM in 8 KB units
                    -- (Value 0 means the board uses CHR RAM)
                    when x"0005" =>
                        ret.reg.cart_config.chr_rom_8kb_blocks :=
                            unsigned(nes_in.data_from_cart_mem);
                    -- Flags 6
                    when x"0006" =>
                        mirror := nes_in.data_from_cart_mem(3) &
                                  nes_in.data_from_cart_mem(0);
                        ret.reg.cart_config.mirror := parse_mirror(mirror);
                        ret.reg.cart_config.mirror_pads := mirror;
                        ret.reg.cart_config.battery :=
                            nes_in.data_from_cart_mem(1) = '1';
                        ret.reg.cart_config.mapper_num(3 downto 0) :=
                            nes_in.data_from_cart_mem(7 downto 4);
                    -- Flags 7
                    when x"0007" =>
                        ret.reg.cart_config.mapper_num(7 downto 4) :=
                            nes_in.data_from_cart_mem(7 downto 4);
                        ret.reg.cart_config.nes2 :=
                            nes_in.data_from_cart_mem(3 downto 2) = "10";
                    -- Mapper MSB/Submapper (NES 2.0 only)
                    when x"0008" =>
                        if nes_in.reg.cart_config.nes2
                        then
                            ret.reg.cart_config.mapper_num(11 downto 8) :=
                                nes_in.data_from_cart_mem(3 downto 0);
                            ret.reg.cart_config.submapper_num :=
                                nes_in.data_from_cart_mem(7 downto 4);
                        end if;
                    -- PRG RAM size (NES 2.0 only)
                    when x"000A" =>
                        if nes_in.reg.cart_config.nes2
                        then
                            ret.reg.cart_config.prg_ram_mask :=
                                get_ram_mask(nes_in.data_from_cart_mem);
                        end if;
                    -- CHR RAM size (NES 2.0 only)
                    when x"000B" =>
                        if nes_in.reg.cart_config.nes2
                        then
                            ret.reg.cart_config.chr_ram_mask :=
                                get_ram_mask(nes_in.data_from_cart_mem);
                        end if;
                    when others =>
                end case;
                
                if nes_in.reg.cur_cycle < x"0F"
                then
                    ret.reg.cur_cycle := nes_in.reg.cur_cycle + "1";
                -- Waits for the power up data before filling the RAMs,
                -- so that it only changes on a clock enable once they
                -- are being filled
                elsif nes_in.power_up_ready
                then
                    ret.reg.cart_config :=
                        set_rom_masks(nes_in.reg.cart_config);
                    if not nes_in.reg.cart_config.nes2
                    then
                        ret.reg.cart_config :=
                            set_ines_ram_masks(ret.reg.cart_config);
                    end if;

                    ret.reg.cur_cycle := x"0000";
                    ret.reg.cur_state := STATE_RESET;
                end if;

            when STATE_RESET =>
                ret.reset := true;
                ret.power_up_enable := true;
                
                ret.cpu_bus.ram_bus :=
                    bus_write(nes_in.reg.cur_cycle(ram_addr_t'range));
                
                ret.oam_bus :=
                    bus_write(nes_in.reg.cur_cycle(oam_addr_t'range));
                ret.sec_oam_bus :=
                    bus_write(nes_in.reg.cur_cycle(sec_oam_addr_t'range));
                ret.palette_bus :=
                    bus_write(nes_in.reg.cur_cycle(palette_addr_t'range));
                
                ret.ppu_bus.ciram_bus :=
                    bus_write(nes_in.reg.cur_cycle(ciram_addr_t'range));
                ret.chip_ram_bus :=
                    bus_write(nes_in.reg.cur_cycle(chip_ram_addr_t'range));
                
                -- The RAMs of the console power up with random bytes, a
                -- different part of the power up data for each
                ret.cpu_bus.data_to_ram := nes_in.power_up_data(7 downto 0);
                
                ret.data_to_oam := nes_in.power_up_data(15 downto 8);
                ret.data_to_sec_oam := nes_in.power_up_data(23 downto 16);
                ret.data_to_palette :=
                    STARTUP_PALETTE
                    (
                        to_integer(nes_in.reg.cur_cycle(palette_addr_t'range))
                    );
                
                ret.ppu_bus.data_to_ciram := nes_in.power_up_data(31 downto 24);
                ret.data_to_chip_ram :=
                    get_cart_ram_fill(nes_in.reg.cart_config,
                                      nes_in.power_up_data(55 downto 48));

                -- PRG RAM and CHR RAM share the cartridge memory bus, so their
                -- first 8KB are filled on alternate CPU cycles, from the same
                -- part of the power up data. A write that
                -- is held for a whole CPU cycle by itself is always served,
                -- even in the partial CPU cycle the NES can leave reset in
                if nes_in.reg.cur_cycle(0) = '0'
                then
                    ret.prg_cart_mem_bus :=
                        get_prg_ram_bus(
                            bus_write(resize(nes_in.reg.cur_cycle(13 downto 1),
                                             prg_ram_addr_t'length)));
                    ret.data_to_prg_cart_mem :=
                        get_cart_ram_fill(nes_in.reg.cart_config,
                                          nes_in.power_up_data(39 downto 32));
                else
                    ret.chr_cart_mem_bus :=
                        get_chr_ram_bus(
                            bus_write(resize(nes_in.reg.cur_cycle(13 downto 1),
                                             chr_ram_addr_t'length)));
                    ret.data_to_chr_cart_mem := nes_in.power_up_data(39 downto 32);

                    -- ExRAM is filled alongside the first 1KB of CHR RAM
                    -- writes, on the PRG channel, which is otherwise idle in
                    -- these cycles. Two writes fit in a whole CPU cycle, and
                    -- these are never the first or last cycle of reset. Every
                    -- board gets this, so it costs no time in reset
                    if nes_in.reg.cur_cycle(13 downto 11) = "000"
                    then
                        ret.prg_cart_mem_bus :=
                            get_exram_bus(
                                bus_write(nes_in.reg.cur_cycle(10 downto 1)));
                        ret.data_to_prg_cart_mem := nes_in.power_up_data(47 downto 40);
                    end if;
                end if;
                
                ret.reg.mmap_reg := RESET_CPU_MMAP_REG;

                if nes_in.reg.cur_cycle = x"3FFF"
                then
                    -- Bandai boards fill their PRG RAM and chip RAM again
                    -- from the start, which reset already did. Their reset
                    -- takes as long as before reset knew the board
                    if get_save_ram_fill(nes_in.reg.cart_config) /= x"00"
                    then
                        ret.reg.cur_cycle := x"0000";
                        ret.reg.cur_state := STATE_CLEAR;
                    elsif needs_ram_clear(nes_in.reg.cart_config)
                    then
                        ret.reg.cur_cycle := unsigned(DEFAULT_RAM_MASK) + 1;
                        ret.reg.cur_state := STATE_CLEAR;
                    else
                        ret.reg.cur_state := STATE_RUN;
                    end if;
                else
                    ret.reg.cur_cycle := nes_in.reg.cur_cycle + "1";
                end if;
            when STATE_CLEAR =>
                ret.reset := true;

                -- Zeroes PRG RAM and CHR RAM past the first 8KB, both in the
                -- same CPU cycle. The mux serves the CHR write first, then
                -- the PRG write once the CHR write hits in its cache. A
                -- board with a save RAM fill has PRG RAM and the chip RAM
                -- filled from the start instead
                if is_zero(std_logic_vector(nes_in.reg.cur_cycle) and
                           not nes_in.reg.cart_config.prg_ram_mask)
                then
                    ret.prg_cart_mem_bus :=
                        get_prg_ram_bus(bus_write(nes_in.reg.cur_cycle));
                    ret.data_to_prg_cart_mem :=
                        get_save_ram_fill(nes_in.reg.cart_config);
                end if;

                if is_zero(nes_in.reg.cur_cycle(cpu_addr_t'high
                                                downto chip_ram_addr_t'length))
                then
                    ret.chip_ram_bus :=
                        bus_write(nes_in.reg.cur_cycle(chip_ram_addr_t'range));
                    ret.data_to_chip_ram :=
                        get_save_ram_fill(nes_in.reg.cart_config);
                end if;

                if is_zero(std_logic_vector(nes_in.reg.cur_cycle) and
                           not nes_in.reg.cart_config.chr_ram_mask)
                then
                    ret.chr_cart_mem_bus :=
                        get_chr_ram_bus(bus_write(nes_in.reg.cur_cycle));
                    ret.data_to_chr_cart_mem := x"00";
                end if;

                if std_logic_vector(nes_in.reg.cur_cycle) =
                   (nes_in.reg.cart_config.prg_ram_mask or
                    nes_in.reg.cart_config.chr_ram_mask)
                then
                    ret.reg.cur_state := STATE_RUN;
                else
                    ret.reg.cur_cycle := nes_in.reg.cur_cycle + "1";
                end if;
                
            when STATE_RUN | STATE_SOFT_RESET =>
                ret.soft_reset := nes_in.reg.cur_state = STATE_SOFT_RESET;
                if nes_in.soft_reset
                then
                    ret.reg.cur_state := STATE_SOFT_RESET;
                else
                    ret.reg.cur_state := STATE_RUN;
                end if;

                ret.audio := mix_audio(nes_in.audio, nes_in.cart.audio);
                
                ret.oam_bus := nes_in.oam_bus;
                ret.data_to_oam := nes_in.data_to_oam;
                
                ret.sec_oam_bus := nes_in.sec_oam_bus;
                ret.data_to_sec_oam := nes_in.data_to_sec_oam;
                
                ret.palette_bus := nes_in.palette_bus;
                ret.data_to_palette := nes_in.data_to_palette;
                
                cpu_map_in.reg := nes_in.reg.mmap_reg;
                cpu_map_in.bus_in := nes_in.cpu_bus;
                cpu_map_in.cart := nes_in.cart.cpu;
                cpu_map_out := mmap_cpu_memory(cpu_map_in);
                
                ret.reg.mmap_reg := cpu_map_out.reg;
                ret.cpu_bus := cpu_map_out.bus_out;
                ret.ppu_bus := mmap_ppu_memory(nes_in.ppu_bus, nes_in.cart.ppu);

                -- PRG ROM, PRG RAM and the CPU's ExRAM accesses share the PRG
                -- channel of the cartridge memory bus, since the CPU only
                -- accesses one at a time
                assert not ((is_bus_active(nes_in.cart.mem.prg_rom_bus) and
                             is_bus_active(nes_in.cart.mem.prg_ram_bus)) or
                            (is_bus_active(nes_in.cart.mem.prg_rom_bus) and
                             is_bus_active(nes_in.cart.mem.cpu_exram_bus)) or
                            (is_bus_active(nes_in.cart.mem.prg_ram_bus) and
                             is_bus_active(nes_in.cart.mem.cpu_exram_bus)))
                    report "PRG ROM, PRG RAM and ExRAM accessed together"
                    severity failure;

                if is_bus_active(nes_in.cart.mem.prg_ram_bus)
                then
                    ret.prg_cart_mem_bus :=
                        get_prg_ram_bus(nes_in.cart.mem.prg_ram_bus);
                    ret.data_to_prg_cart_mem :=
                        nes_in.cart.mem.data_to_prg_ram;
                elsif is_bus_active(nes_in.cart.mem.cpu_exram_bus)
                then
                    ret.prg_cart_mem_bus :=
                        get_exram_bus(nes_in.cart.mem.cpu_exram_bus);
                    ret.data_to_prg_cart_mem :=
                        nes_in.cart.mem.data_to_cpu_exram;
                else
                    ret.prg_cart_mem_bus :=
                        get_cart_mem_bus(
                            nes_in.cart.mem.prg_rom_bus,
                            get_file_offset(
                                x"00",
                                nes_in.reg.cart_config.has_trainer));
                end if;

                -- CHR ROM, CHR RAM and the PPU's ExRAM accesses share the CHR
                -- channel, since the board maps each PPU address to one of
                -- them
                assert not ((is_bus_active(nes_in.cart.mem.chr_rom_bus) and
                             is_bus_active(nes_in.cart.mem.chr_ram_bus)) or
                            (is_bus_active(nes_in.cart.mem.chr_rom_bus) and
                             is_bus_active(nes_in.cart.mem.ppu_exram_bus)) or
                            (is_bus_active(nes_in.cart.mem.chr_ram_bus) and
                             is_bus_active(nes_in.cart.mem.ppu_exram_bus)))
                    report "CHR ROM, CHR RAM and ExRAM accessed together"
                    severity failure;

                if is_bus_active(nes_in.cart.mem.chr_ram_bus)
                then
                    ret.chr_cart_mem_bus :=
                        get_chr_ram_bus(nes_in.cart.mem.chr_ram_bus);
                    ret.data_to_chr_cart_mem :=
                        nes_in.cart.mem.data_to_chr_ram;
                elsif is_bus_active(nes_in.cart.mem.ppu_exram_bus)
                then
                    ret.chr_cart_mem_bus :=
                        get_exram_bus(nes_in.cart.mem.ppu_exram_bus);
                    ret.data_to_chr_cart_mem :=
                        nes_in.cart.mem.data_to_ppu_exram;
                else
                    ret.chr_cart_mem_bus :=
                        get_cart_mem_bus(
                            nes_in.cart.mem.chr_rom_bus,
                            get_file_offset(
                                nes_in.reg.cart_config.prg_rom_16kb_blocks,
                                nes_in.reg.cart_config.has_trainer));
                end if;

                ret.irq := nes_in.cart.cpu.irq;
        end case;
        
        return ret;
    end;

end package body;