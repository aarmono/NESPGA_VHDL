library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;
use work.perhipheral_types.all;
use work.prg_ram_bus_types.all;
use work.chr_ram_bus_types.all;
use work.exram_bus_types.all;
use work.vram_bus_types.all;
use work.chip_ram_bus_types.all;
use work.cart_mem_bus_types.all;
use work.cart_types.all;
use work.lib_cartridge.all;

-- The cartridge system: loads the header of the ROM file, fills the RAMs of
-- the cartridge after power up, and puts the memory accesses of the board on
-- the PRG and CHR channels of the cartridge memory bus
package lib_cart_system is

    -- The header is loaded first, so that the fill knows the board
    type cart_system_state_t is
    (
        STATE_LOAD,
        -- The first 8KB of PRG RAM and CHR RAM, ExRAM, chip RAM and VRAM are
        -- filled
        STATE_FILL,
        -- RAM past the first 8KB is cleared, or a save RAM fill is redone
        STATE_CLEAR,
        -- The RAMs are ready, and the board runs
        STATE_READY
    );

    -- Clocked off the CPU timer
    type cart_system_reg_t is record
        config    : cart_config_t;
        cur_cycle : unsigned(15 downto 0);
        cur_state : cart_system_state_t;
    end record;

    constant RESET_CART_SYSTEM_REG : cart_system_reg_t :=
    (
        config => RESET_CART_CONFIG,
        cur_cycle => x"0000",
        cur_state => STATE_LOAD
    );

    type cart_system_in_t is record
        reg                : cart_system_reg_t;
        -- Read data of the PRG channel, while the header is loaded
        data_from_cart_mem : data_t;
        -- The memory accesses of the board
        mem                : cart_mem_out_t;
        -- The power up data is valid
        power_up_ready     : boolean;
        power_up_data      : cart_power_up_data_t;
        -- The fill leaves PRG RAM alone, as it holds a save the board loaded
        keep_prg_ram       : boolean;
    end record;

    type cart_system_out_t is record
        reg                  : cart_system_reg_t;
        -- PRG ROM and CHR ROM are in the ROM file, and each RAM shares its
        -- channel with the ROM. ExRAM is on both channels: the CPU accesses
        -- it on the PRG channel and the PPU on the CHR channel
        prg_cart_mem_bus     : cart_mem_bus_t;
        data_to_prg_cart_mem : data_t;
        chr_cart_mem_bus     : cart_mem_bus_t;
        data_to_chr_cart_mem : data_t;
        -- RAM inside the mapper chip that is on a bus of its own
        chip_ram_bus         : chip_ram_bus_t;
        data_to_chip_ram     : data_t;
        -- See cart_system
        loaded               : boolean;
        ready                : boolean;
    end record;

    function cycle_cart_system(sys_in : cart_system_in_t)
    return cart_system_out_t;

    function parse_mirror(mirror : std_logic_vector(1 downto 0)) return mirror_t;

    -- Offset into the cartridge RAM windows
    subtype cart_ram_addr_t is std_logic_vector(17 downto 0);

    function is_cart_ram(cart_mem_bus : cart_mem_bus_t) return boolean;

end lib_cart_system;

package body lib_cart_system is

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
    return natural
    is
        variable ret : natural;
    begin
        ret := to_integer(std_logic_vector(offset_16kb)) * 16384 + 16;
        if has_trainer
        then
            ret := ret + 512;
        end if;

        return ret;
    end;

    -- The ROM file access for an access to PRG ROM or CHR ROM
    function get_cart_mem_bus
    (
        rom_bus     : cart_mem_bus_t;
        file_offset : natural
    )
    return cart_mem_bus_t
    is
    begin
        if is_bus_active(rom_bus)
        then
            return bus_read(
                to_std_logic_vector(to_integer(rom_bus.address) + file_offset,
                                    cart_mem_addr_t'length));
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

    -- The cartridge memory bus access for an access to the VRAM of a
    -- four-screen board
    function get_vram_bus(ram_bus : vram_bus_t) return cart_mem_bus_t
    is
        variable ret : cart_mem_bus_t;
    begin
        ret.address := VRAM_WINDOW;
        ret.address(vram_addr_t'range) := ram_bus.address;
        ret.read := ram_bus.read;
        ret.write := ram_bus.write;

        return ret;
    end;

    -- The fill covers the first 8KB of PRG RAM and CHR RAM. A board with
    -- more needs the rest cleared after it
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

    function cycle_cart_system(sys_in : cart_system_in_t)
    return cart_system_out_t
    is
        -- These have initial values because without one ghdl fills in every
        -- element on each call, which is slow to simulate. They are constants
        -- because Quartus 13 can fail to infer registers from a variable
        -- whose initial value isn't
        variable ret : cart_system_out_t :=
            (reg => RESET_CART_SYSTEM_REG,
             prg_cart_mem_bus => CART_MEM_BUS_IDLE,
             data_to_prg_cart_mem => (others => '-'),
             chr_cart_mem_bus => CART_MEM_BUS_IDLE,
             data_to_chr_cart_mem => (others => '-'),
             chip_ram_bus => CHIP_RAM_BUS_IDLE,
             data_to_chip_ram => (others => '-'),
             loaded => false,
             ready => false);

        variable mirror : std_logic_vector(1 downto 0);
    begin
        ret.reg := sys_in.reg;

        ret.chip_ram_bus := sys_in.mem.chip_ram_bus;
        ret.data_to_chip_ram := sys_in.mem.data_to_chip_ram;

        ret.loaded := sys_in.reg.cur_state /= STATE_LOAD or
                      sys_in.reg.cur_cycle = x"000F";

        case sys_in.reg.cur_state is
            when STATE_LOAD =>
                ret.prg_cart_mem_bus :=
                    bus_read(resize(sys_in.reg.cur_cycle,
                                    cart_mem_addr_t'length));
                case sys_in.reg.cur_cycle is
                    -- Size of PRG ROM in 16 KB units
                    when x"0004" =>
                        ret.reg.config.prg_rom_16kb_blocks :=
                            unsigned(sys_in.data_from_cart_mem);
                    -- Size of CHR ROM in 8 KB units
                    -- (Value 0 means the board uses CHR RAM)
                    when x"0005" =>
                        ret.reg.config.chr_rom_8kb_blocks :=
                            unsigned(sys_in.data_from_cart_mem);
                    -- Flags 6
                    when x"0006" =>
                        mirror := sys_in.data_from_cart_mem(3) &
                                  sys_in.data_from_cart_mem(0);
                        ret.reg.config.mirror := parse_mirror(mirror);
                        ret.reg.config.mirror_pads := mirror;
                        ret.reg.config.battery :=
                            sys_in.data_from_cart_mem(1) = '1';
                        ret.reg.config.has_trainer :=
                            sys_in.data_from_cart_mem(2) = '1';
                        ret.reg.config.mapper_num(3 downto 0) :=
                            sys_in.data_from_cart_mem(7 downto 4);
                    -- Flags 7
                    when x"0007" =>
                        ret.reg.config.mapper_num(7 downto 4) :=
                            sys_in.data_from_cart_mem(7 downto 4);
                        ret.reg.config.nes2 :=
                            sys_in.data_from_cart_mem(3 downto 2) = "10";
                    -- Mapper MSB/Submapper (NES 2.0 only)
                    when x"0008" =>
                        if sys_in.reg.config.nes2
                        then
                            ret.reg.config.mapper_num(11 downto 8) :=
                                sys_in.data_from_cart_mem(3 downto 0);
                            ret.reg.config.submapper_num :=
                                sys_in.data_from_cart_mem(7 downto 4);
                        end if;
                    -- PRG RAM size (NES 2.0 only)
                    when x"000A" =>
                        if sys_in.reg.config.nes2
                        then
                            ret.reg.config.prg_ram_mask :=
                                get_ram_mask(sys_in.data_from_cart_mem);
                        end if;
                    -- CHR RAM size (NES 2.0 only)
                    when x"000B" =>
                        if sys_in.reg.config.nes2
                        then
                            ret.reg.config.chr_ram_mask :=
                                get_ram_mask(sys_in.data_from_cart_mem);
                        end if;
                    when others =>
                end case;

                if sys_in.reg.cur_cycle < x"0F"
                then
                    ret.reg.cur_cycle := sys_in.reg.cur_cycle + "1";
                -- Waits for the power up data before filling the RAMs,
                -- so that it only changes on a clock enable once they
                -- are being filled. The console starts its own fill on
                -- the same CPU cycle (see cart_system)
                elsif sys_in.power_up_ready
                then
                    ret.reg.config := set_rom_masks(sys_in.reg.config);
                    if not sys_in.reg.config.nes2
                    then
                        ret.reg.config := set_ines_ram_masks(ret.reg.config);
                    end if;

                    ret.reg.cur_cycle := x"0000";
                    ret.reg.cur_state := STATE_FILL;
                end if;

            when STATE_FILL =>
                ret.chip_ram_bus :=
                    bus_write(sys_in.reg.cur_cycle(chip_ram_addr_t'range));
                ret.data_to_chip_ram :=
                    get_cart_ram_fill(sys_in.reg.config,
                                      sys_in.power_up_data(23 downto 16));

                -- PRG RAM and CHR RAM share the cartridge memory bus, so their
                -- first 8KB are filled on alternate CPU cycles, from the same
                -- part of the power up data. PRG RAM is left alone when the
                -- board has loaded a save into it. A write that
                -- is held for a whole CPU cycle by itself is always served,
                -- even in the partial CPU cycle the NES can leave reset in
                if sys_in.reg.cur_cycle(0) = '0'
                then
                    if not sys_in.keep_prg_ram
                    then
                        ret.prg_cart_mem_bus :=
                            get_prg_ram_bus(
                                bus_write(resize(sys_in.reg.cur_cycle(13 downto 1),
                                                 prg_ram_addr_t'length)));
                        ret.data_to_prg_cart_mem :=
                            get_cart_ram_fill(sys_in.reg.config,
                                              sys_in.power_up_data(7 downto 0));
                    end if;
                else
                    ret.chr_cart_mem_bus :=
                        get_chr_ram_bus(
                            bus_write(resize(sys_in.reg.cur_cycle(13 downto 1),
                                             chr_ram_addr_t'length)));
                    ret.data_to_chr_cart_mem := sys_in.power_up_data(7 downto 0);

                    -- ExRAM, then the VRAM of a four-screen board, are filled
                    -- alongside the CHR RAM writes, on the PRG channel, which
                    -- is otherwise idle in these cycles. Two writes fit in a
                    -- whole CPU cycle, and these are never the first or last
                    -- cycle of the fill. Every board gets this, so it costs
                    -- no time in reset
                    if sys_in.reg.cur_cycle(13 downto 11) = "000"
                    then
                        ret.prg_cart_mem_bus :=
                            get_exram_bus(
                                bus_write(sys_in.reg.cur_cycle(10 downto 1)));
                        ret.data_to_prg_cart_mem := sys_in.power_up_data(15 downto 8);
                    elsif sys_in.reg.cur_cycle(13 downto 12) = "01"
                    then
                        ret.prg_cart_mem_bus :=
                            get_vram_bus(
                                bus_write(sys_in.reg.cur_cycle(11 downto 1)));
                        ret.data_to_prg_cart_mem := sys_in.power_up_data(15 downto 8);
                    end if;
                end if;

                if sys_in.reg.cur_cycle = x"3FFF"
                then
                    -- Bandai boards fill their PRG RAM and chip RAM again
                    -- from the start, which the fill already did. Their
                    -- reset takes as long as before the fill knew the board
                    if get_save_ram_fill(sys_in.reg.config) /= x"00"
                    then
                        ret.reg.cur_cycle := x"0000";
                        ret.reg.cur_state := STATE_CLEAR;
                    elsif needs_ram_clear(sys_in.reg.config)
                    then
                        ret.reg.cur_cycle := unsigned(DEFAULT_RAM_MASK) + 1;
                        ret.reg.cur_state := STATE_CLEAR;
                    else
                        ret.reg.cur_state := STATE_READY;
                    end if;
                else
                    ret.reg.cur_cycle := sys_in.reg.cur_cycle + "1";
                end if;

            when STATE_CLEAR =>
                -- Zeroes PRG RAM and CHR RAM past the first 8KB, both in the
                -- same CPU cycle. The mux serves the CHR write first, then
                -- the PRG write once the CHR write hits in its cache. A
                -- board with a save RAM fill has PRG RAM and the chip RAM
                -- filled from the start instead. PRG RAM is left alone when
                -- the board has loaded a save into it
                if is_zero(std_logic_vector(sys_in.reg.cur_cycle) and
                           not sys_in.reg.config.prg_ram_mask) and
                   not sys_in.keep_prg_ram
                then
                    ret.prg_cart_mem_bus :=
                        get_prg_ram_bus(bus_write(sys_in.reg.cur_cycle));
                    ret.data_to_prg_cart_mem :=
                        get_save_ram_fill(sys_in.reg.config);
                end if;

                if is_zero(sys_in.reg.cur_cycle(sys_in.reg.cur_cycle'high
                                                downto chip_ram_addr_t'length))
                then
                    ret.chip_ram_bus :=
                        bus_write(sys_in.reg.cur_cycle(chip_ram_addr_t'range));
                    ret.data_to_chip_ram :=
                        get_save_ram_fill(sys_in.reg.config);
                end if;

                if is_zero(std_logic_vector(sys_in.reg.cur_cycle) and
                           not sys_in.reg.config.chr_ram_mask)
                then
                    ret.chr_cart_mem_bus :=
                        get_chr_ram_bus(bus_write(sys_in.reg.cur_cycle));
                    ret.data_to_chr_cart_mem := x"00";
                end if;

                if std_logic_vector(sys_in.reg.cur_cycle) =
                   (sys_in.reg.config.prg_ram_mask or
                    sys_in.reg.config.chr_ram_mask)
                then
                    ret.reg.cur_state := STATE_READY;
                else
                    ret.reg.cur_cycle := sys_in.reg.cur_cycle + "1";
                end if;

            when STATE_READY =>
                -- PRG ROM, PRG RAM and the CPU's ExRAM accesses share the
                -- PRG channel of the cartridge memory bus, since the CPU
                -- only accesses one at a time
                assert not ((is_bus_active(sys_in.mem.prg_rom_bus) and
                             is_bus_active(sys_in.mem.prg_ram_bus)) or
                            (is_bus_active(sys_in.mem.prg_rom_bus) and
                             is_bus_active(sys_in.mem.cpu_exram_bus)) or
                            (is_bus_active(sys_in.mem.prg_ram_bus) and
                             is_bus_active(sys_in.mem.cpu_exram_bus)))
                    report "PRG ROM, PRG RAM and ExRAM accessed together"
                    severity failure;

                if is_bus_active(sys_in.mem.prg_ram_bus)
                then
                    ret.prg_cart_mem_bus :=
                        get_prg_ram_bus(sys_in.mem.prg_ram_bus);
                    ret.data_to_prg_cart_mem :=
                        sys_in.mem.data_to_prg_ram;
                elsif is_bus_active(sys_in.mem.cpu_exram_bus)
                then
                    ret.prg_cart_mem_bus :=
                        get_exram_bus(sys_in.mem.cpu_exram_bus);
                    ret.data_to_prg_cart_mem :=
                        sys_in.mem.data_to_cpu_exram;
                else
                    ret.prg_cart_mem_bus :=
                        get_cart_mem_bus(
                            sys_in.mem.prg_rom_bus,
                            get_file_offset(
                                x"00",
                                sys_in.reg.config.has_trainer));
                end if;

                -- CHR ROM, CHR RAM, the PPU's ExRAM accesses and VRAM share
                -- the CHR channel, since the board maps each PPU address to
                -- one of them
                assert not ((is_bus_active(sys_in.mem.chr_rom_bus) and
                             is_bus_active(sys_in.mem.chr_ram_bus)) or
                            (is_bus_active(sys_in.mem.chr_rom_bus) and
                             is_bus_active(sys_in.mem.ppu_exram_bus)) or
                            (is_bus_active(sys_in.mem.chr_ram_bus) and
                             is_bus_active(sys_in.mem.ppu_exram_bus)) or
                            (is_bus_active(sys_in.mem.vram_bus) and
                             (is_bus_active(sys_in.mem.chr_rom_bus) or
                              is_bus_active(sys_in.mem.chr_ram_bus) or
                              is_bus_active(sys_in.mem.ppu_exram_bus))))
                    report "CHR ROM, CHR RAM, ExRAM and VRAM accessed together"
                    severity failure;

                if is_bus_active(sys_in.mem.chr_ram_bus)
                then
                    ret.chr_cart_mem_bus :=
                        get_chr_ram_bus(sys_in.mem.chr_ram_bus);
                    ret.data_to_chr_cart_mem :=
                        sys_in.mem.data_to_chr_ram;
                elsif is_bus_active(sys_in.mem.ppu_exram_bus)
                then
                    ret.chr_cart_mem_bus :=
                        get_exram_bus(sys_in.mem.ppu_exram_bus);
                    ret.data_to_chr_cart_mem :=
                        sys_in.mem.data_to_ppu_exram;
                elsif is_bus_active(sys_in.mem.vram_bus)
                then
                    ret.chr_cart_mem_bus :=
                        get_vram_bus(sys_in.mem.vram_bus);
                    ret.data_to_chr_cart_mem := sys_in.mem.data_to_vram;
                else
                    ret.chr_cart_mem_bus :=
                        get_cart_mem_bus(
                            sys_in.mem.chr_rom_bus,
                            get_file_offset(
                                sys_in.reg.config.prg_rom_16kb_blocks,
                                sys_in.reg.config.has_trainer));
                end if;
        end case;

        -- The fill ends with this CPU cycle
        ret.ready := ret.reg.cur_state = STATE_READY;

        return ret;
    end;

end package body;
