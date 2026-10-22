library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;

use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.prg_ram_bus_types.all;
use work.chr_ram_bus_types.all;
use work.cart_mem_bus_types.all;

-- Types shared by the cartridge and the boards (mappers) it can hold. The
-- cart_cpu_* and cart_ppu_* records follow the pins of the cartridge
-- connector. The memories on the board (PRG ROM, CHR ROM, PRG RAM and
-- CHR RAM) are not on the connector, so they have records of their own
package cart_types is

    subtype mapper_num_t is std_logic_vector(11 downto 0);
    subtype submapper_num_t is std_logic_vector(3 downto 0);
    subtype rom_blocks_t is unsigned(7 downto 0);

    -- The boards map PRG ROM in 8KB banks to the four windows at 0x8000,
    -- 0xA000, 0xC000 and 0xE000, and CHR ROM in 1KB banks to the eight
    -- windows at 0x0000-0x1FFF. A board with larger banks maps one to
    -- consecutive windows, using the low bits of the window as the low bits
    -- of the bank
    subtype prg_window_t is unsigned(1 downto 0);
    subtype chr_window_t is unsigned(2 downto 0);

    subtype prg_bank_8kb_t is unsigned(7 downto 0);
    subtype chr_bank_1kb_t is unsigned(10 downto 0);

    -- PRG RAM is mapped in 8KB banks to the window at 0x6000. CHR RAM is
    -- mapped in the same 1KB banks as CHR ROM
    subtype prg_ram_bank_8kb_t is unsigned(2 downto 0);

    type mirror_t is
    (
        MIRROR_HORZ,
        MIRROR_VERT,
        MIRROR_A,
        MIRROR_B,
        MIRROR_FOUR
    );

    -- How the board is built: the chips on it and its solder pads. It comes
    -- from the header of the ROM file
    type cart_config_t is record
        -- The header is NES 2.0. Otherwise it is iNES, which has no
        -- submapper number, and the submapper number is 0
        nes2                : boolean;
        mapper_num          : mapper_num_t;
        submapper_num       : submapper_num_t;
        prg_rom_16kb_blocks : rom_blocks_t;
        chr_rom_8kb_blocks  : rom_blocks_t;
        mirror              : mirror_t;
        -- Bits 3 and 0 of byte 6 of the header, from which mirror is
        -- decoded. A few boards give them a meaning of their own
        mirror_pads         : std_logic_vector(1 downto 0);
        -- The board keeps its memory with a battery, or in flash
        battery             : boolean;
        has_trainer         : boolean;

        -- The ROMs are only wired to as many address lines as their size
        -- needs, so the high bits of a bank number are dropped. These are
        -- set from the sizes of the ROMs once the header is loaded
        prg_rom_mask        : prg_bank_8kb_t;
        chr_rom_mask        : chr_bank_1kb_t;

        -- Likewise for the RAMs, whose sizes come from the header. These
        -- mask the RAM address, since a RAM can be smaller than a bank
        prg_ram_mask        : prg_ram_addr_t;
        chr_ram_mask        : chr_ram_addr_t;
    end record;

    -- The size of PRG RAM and CHR RAM when the header does not give one
    constant DEFAULT_RAM_MASK : std_logic_vector(15 downto 0) := x"1FFF";

    constant RESET_CART_CONFIG : cart_config_t :=
    (
        nes2 => false,
        mapper_num => (others => '0'),
        submapper_num => (others => '0'),
        prg_rom_16kb_blocks => (others => '0'),
        chr_rom_8kb_blocks => (others => '0'),
        mirror => MIRROR_HORZ,
        mirror_pads => "00",
        battery => false,
        has_trainer => false,

        prg_rom_mask => (others => '0'),
        chr_rom_mask => (others => '0'),

        prg_ram_mask => DEFAULT_RAM_MASK,
        chr_ram_mask => DEFAULT_RAM_MASK
    );

    -- CPU side of the connector, driven by the console
    type cart_cpu_in_t is record
        -- CPU A0-A14 and R/W. The board sees every access, including those
        -- to the console's own registers and RAM. Neither read nor write is
        -- set when the bus is idle
        prg_bus : prg_bus_t;
        -- /ROMSEL, active high: set for an access to 0x8000-0xFFFF
        romsel  : boolean;
        -- CPU D0-D7 during a write
        data    : data_t;
    end record;

    -- CPU side of the connector, driven by the board
    type cart_cpu_out_t is record
        -- CPU D0-D7. When the board does not drive them the console reads
        -- open bus
        data    : data_t;
        data_oe : boolean;
        -- /IRQ, active high
        irq     : boolean;
    end record;

    constant CART_CPU_OUT_IDLE : cart_cpu_out_t :=
    (
        data => (others => '-'),
        data_oe => false,
        irq => false
    );

    -- PPU side of the connector, driven by the console
    type cart_ppu_in_t is record
        -- PPU A0-A13, /RD and /WR
        chr_bus : chr_bus_t;
        -- PPU D0-D7 during a write
        data    : data_t;
    end record;

    -- PPU side of the connector, driven by the board
    type cart_ppu_out_t is record
        -- PPU D0-D7, when CIRAM is not enabled
        data      : data_t;
        data_oe   : boolean;
        -- CIRAM /CE, active high, and CIRAM A10. The console addresses CIRAM
        -- with these and PPU A0-A9
        ciram_ce  : boolean;
        ciram_a10 : std_logic;
        -- Not on the connector. A four-screen board carries 2KB of VRAM of
        -- its own; here the console's CIRAM is 4KB, and this selects the
        -- half that stands in for the board's VRAM
        ciram_a11 : std_logic;
    end record;

    constant CART_PPU_OUT_IDLE : cart_ppu_out_t :=
    (
        data => (others => '-'),
        data_oe => false,
        ciram_ce => false,
        ciram_a10 => '-',
        ciram_a11 => '-'
    );

    -- The memories on the board. ROM addresses are relative to the start of
    -- PRG/CHR ROM, which the console finds in the ROM file
    type cart_mem_in_t is record
        data_from_prg_rom : data_t;
        data_from_chr_rom : data_t;
        data_from_prg_ram : data_t;
        data_from_chr_ram : data_t;
    end record;

    type cart_mem_out_t is record
        prg_rom_bus     : cart_mem_bus_t;
        chr_rom_bus     : cart_mem_bus_t;

        prg_ram_bus     : prg_ram_bus_t;
        data_to_prg_ram : data_t;

        chr_ram_bus     : chr_ram_bus_t;
        data_to_chr_ram : data_t;
    end record;

    constant CART_MEM_OUT_IDLE : cart_mem_out_t :=
    (
        prg_rom_bus => CART_MEM_BUS_IDLE,
        chr_rom_bus => CART_MEM_BUS_IDLE,

        prg_ram_bus => PRG_RAM_BUS_IDLE,
        data_to_prg_ram => (others => '-'),

        chr_ram_bus => CHR_RAM_BUS_IDLE,
        data_to_chr_ram => (others => '-')
    );

    type cart_in_t is record
        cpu : cart_cpu_in_t;
        ppu : cart_ppu_in_t;
        mem : cart_mem_in_t;
    end record;

    type cart_out_t is record
        cpu   : cart_cpu_out_t;
        ppu   : cart_ppu_out_t;
        mem   : cart_mem_out_t;
        -- The audio of the chips on the board, which the console mixes with
        -- its own. A Famicom cartridge does the mixing itself, on the
        -- audio pins of its connector
        audio : cart_audio_t;
    end record;

    constant CART_OUT_IDLE : cart_out_t :=
    (
        cpu => CART_CPU_OUT_IDLE,
        ppu => CART_PPU_OUT_IDLE,
        mem => CART_MEM_OUT_IDLE,
        audio => 0
    );

    -- The banks a board selects for an access: the PRG ROM bank in the
    -- window of the CPU address and the CHR bank in the window of the PPU
    -- address
    type cart_banks_t is record
        -- The board has PRG RAM at 0x6000-0x7FFF, in bank prg_ram_bank
        prg_ram      : boolean;
        prg_ram_bank : prg_ram_bank_8kb_t;
        -- The board has PRG ROM at 0x6000-0x7FFF, in bank prg, rather than
        -- PRG RAM. prg_ram is not used
        prg_rom_6000 : boolean;
        prg          : prg_bank_8kb_t;
        -- The PPU accesses CHR RAM rather than CHR ROM, in bank chr
        chr_ram      : boolean;
        chr          : chr_bank_1kb_t;
        mirror       : mirror_t;
        -- The PPU accesses the nametables in CHR, in bank chr like the
        -- pattern tables, rather than in CIRAM. mirror is not used
        nt_chr       : boolean;
    end record;

    -- The config with the masks for the sizes of the ROMs in its header
    function set_rom_masks(config : cart_config_t) return cart_config_t;

    -- The mask of the RAM address for a RAM size byte of an NES 2.0 header
    -- (byte 10 for PRG RAM, 11 for CHR RAM). Its low nibble is the size of
    -- the volatile RAM and its high nibble that of the battery backed RAM,
    -- each 64 bytes shifted left by the nibble, or none for 0. A board with
    -- no RAM given gets the default size, like an iNES board
    function get_ram_mask(sizes : data_t) return std_logic_vector;

    -- The board has CHR RAM in place of CHR ROM
    function has_chr_ram(config : cart_config_t) return boolean;

    -- The window of a CPU access to PRG ROM
    function get_prg_window(cpu_in : cart_cpu_in_t) return prg_window_t;

    -- The window of a PPU access to CHR
    function get_chr_window(ppu_in : cart_ppu_in_t) return chr_window_t;

    -- The CPU writes to 0x8000-0xFFFF, where most boards have their
    -- registers
    function is_rom_write
    (
        cpu_in   : cart_cpu_in_t;
        clk_sync : boolean
    )
    return boolean;

    -- The CPU address is in 0x6000-0x7FFF, where boards have PRG RAM
    function is_prg_ram_window(cpu_in : cart_cpu_in_t) return boolean;

    -- The mirroring of a board that drives CIRAM A10 with a single bit
    function get_single_screen_mirror(a10 : std_logic) return mirror_t;

    -- The mirroring of a board with a register bit that selects horizontal
    -- ('1') or vertical ('0') mirroring
    function get_hv_mirror(horz : std_logic) return mirror_t;

    -- The banks of a board before it selects any: no PRG RAM, bank 0 of
    -- PRG ROM and of CHR, CHR RAM if the board has no CHR ROM, and the
    -- nametables in CIRAM with the mirroring of the header. A board sets
    -- the ones its chips control
    function default_banks(config : cart_config_t) return cart_banks_t;

    -- Connects the CPU and PPU to the memories on the board, through the
    -- banks the board selects
    function map_cart
    (
        config  : cart_config_t;
        cart_in : cart_in_t;
        banks   : cart_banks_t
    )
    return cart_out_t;

end package cart_types;


package body cart_types is

    -- All of the bits up to the highest one needed for a bank number below
    -- num_banks
    function get_bank_mask(num_banks : unsigned) return unsigned
    is
        variable ret : unsigned(num_banks'length - 1 downto 0);
    begin
        ret := num_banks - 1;
        for i in ret'high - 1 downto 0
        loop
            ret(i) := ret(i) or ret(i + 1);
        end loop;

        return ret;
    end;

    function set_rom_masks(config : cart_config_t) return cart_config_t
    is
        variable ret : cart_config_t;
    begin
        ret := config;

        ret.prg_rom_mask :=
            resize(get_bank_mask(shift_left(resize(config.prg_rom_16kb_blocks,
                                                   prg_bank_8kb_t'length + 1),
                                            1)),
                   prg_bank_8kb_t'length);
        ret.chr_rom_mask :=
            get_bank_mask(shift_left(resize(config.chr_rom_8kb_blocks,
                                            chr_bank_1kb_t'length),
                                     3));

        return ret;
    end;

    function get_ram_mask(sizes : data_t) return std_logic_vector
    is
        variable volatile : integer range 0 to 15;
        variable battery  : integer range 0 to 15;
        variable shift    : integer range 0 to 16;
        variable ret      : std_logic_vector(DEFAULT_RAM_MASK'range);
    begin
        volatile := to_integer(unsigned(sizes(3 downto 0)));
        battery := to_integer(unsigned(sizes(7 downto 4)));

        -- Two RAMs, each no larger than the larger one, fit in twice its
        -- size
        shift := max(volatile, battery);
        if volatile /= 0 and battery /= 0
        then
            shift := shift + 1;
        end if;

        if shift = 0
        then
            return DEFAULT_RAM_MASK;
        end if;

        -- 64 bytes shifted left by shift, up to the 64KB the cartridge
        -- memory bus has room for
        for i in ret'range
        loop
            ret(i) := to_std_logic(i < shift + 6);
        end loop;

        return ret;
    end;

    function has_chr_ram(config : cart_config_t) return boolean
    is
    begin
        return is_zero(config.chr_rom_8kb_blocks);
    end;

    function get_prg_window(cpu_in : cart_cpu_in_t) return prg_window_t
    is
    begin
        return unsigned(cpu_in.prg_bus.address(14 downto 13));
    end;

    function get_chr_window(ppu_in : cart_ppu_in_t) return chr_window_t
    is
    begin
        return unsigned(ppu_in.chr_bus.address(12 downto 10));
    end;

    function is_rom_write
    (
        cpu_in   : cart_cpu_in_t;
        clk_sync : boolean
    )
    return boolean
    is
    begin
        return cpu_in.romsel and is_bus_write(cpu_in.prg_bus) and clk_sync;
    end;

    function is_prg_ram_window(cpu_in : cart_cpu_in_t) return boolean
    is
    begin
        return not cpu_in.romsel and
               cpu_in.prg_bus.address(14 downto 13) = "11";
    end;

    function get_single_screen_mirror(a10 : std_logic) return mirror_t
    is
    begin
        if a10 = '0'
        then
            return MIRROR_A;
        else
            return MIRROR_B;
        end if;
    end;

    function get_hv_mirror(horz : std_logic) return mirror_t
    is
    begin
        if horz = '1'
        then
            return MIRROR_HORZ;
        else
            return MIRROR_VERT;
        end if;
    end;

    function default_banks(config : cart_config_t) return cart_banks_t
    is
    begin
        return
        (
            prg_ram => false,
            prg_ram_bank => (others => '0'),
            prg_rom_6000 => false,
            prg => (others => '0'),
            chr_ram => has_chr_ram(config),
            chr => (others => '0'),
            mirror => config.mirror,
            nt_chr => false
        );
    end;

    function map_prg_ram
    (
        config   : cart_config_t;
        cart_in  : cart_in_t;
        bank     : prg_ram_bank_8kb_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
    begin
        ret := cart_out;

        ret.mem.prg_ram_bus.address :=
            (std_logic_vector(bank) & cart_in.cpu.prg_bus.address(12 downto 0))
            and config.prg_ram_mask;
        ret.mem.prg_ram_bus.read := cart_in.cpu.prg_bus.read;
        ret.mem.prg_ram_bus.write := cart_in.cpu.prg_bus.write;
        ret.mem.data_to_prg_ram := cart_in.cpu.data;

        ret.cpu.data := cart_in.mem.data_from_prg_ram;
        ret.cpu.data_oe := true;

        return ret;
    end;

    function map_prg_rom
    (
        config   : cart_config_t;
        cart_in  : cart_in_t;
        bank     : prg_bank_8kb_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable address : unsigned(cart_mem_addr_t'range);
    begin
        ret := cart_out;

        address := (bank and config.prg_rom_mask) &
                   unsigned(cart_in.cpu.prg_bus.address(12 downto 0));
        ret.mem.prg_rom_bus := bus_read(address);

        ret.cpu.data := cart_in.mem.data_from_prg_rom;
        ret.cpu.data_oe := true;

        return ret;
    end;

    -- The PPU accesses CHR ROM or CHR RAM
    function map_chr
    (
        config   : cart_config_t;
        cart_in  : cart_in_t;
        banks    : cart_banks_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable address : unsigned(cart_mem_addr_t'range);
    begin
        ret := cart_out;

        if not banks.chr_ram
        then
            address := (banks.chr and config.chr_rom_mask) &
                       unsigned(cart_in.ppu.chr_bus.address(9 downto 0));
            ret.mem.chr_rom_bus := bus_read(address);
            ret.ppu.data := cart_in.mem.data_from_chr_rom;
        else
            ret.mem.chr_ram_bus.address :=
                (std_logic_vector(banks.chr(chr_ram_addr_t'high - 10
                                            downto 0)) &
                 cart_in.ppu.chr_bus.address(9 downto 0))
                and config.chr_ram_mask;
            ret.mem.chr_ram_bus.read := cart_in.ppu.chr_bus.read;
            ret.mem.chr_ram_bus.write := cart_in.ppu.chr_bus.write;
            ret.mem.data_to_chr_ram := cart_in.ppu.data;

            ret.ppu.data := cart_in.mem.data_from_chr_ram;
        end if;
        ret.ppu.data_oe := true;

        return ret;
    end;

    -- The PPU accesses the nametables in CIRAM
    function map_ciram
    (
        cart_in  : cart_in_t;
        mirror   : mirror_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable addr : chr_addr_t;
    begin
        ret := cart_out;
        addr := cart_in.ppu.chr_bus.address;

        ret.ppu.ciram_ce := true;
        ret.ppu.ciram_a11 := '0';

        case mirror is
            when MIRROR_FOUR =>
                ret.ppu.ciram_a10 := addr(10);
                ret.ppu.ciram_a11 := addr(11);
            when MIRROR_HORZ =>
                ret.ppu.ciram_a10 := addr(11);
            when MIRROR_VERT =>
                ret.ppu.ciram_a10 := addr(10);
            when MIRROR_A =>
                ret.ppu.ciram_a10 := '0';
            when MIRROR_B =>
                ret.ppu.ciram_a10 := '1';
        end case;

        return ret;
    end;

    function map_cart
    (
        config  : cart_config_t;
        cart_in : cart_in_t;
        banks   : cart_banks_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
    begin
        ret := CART_OUT_IDLE;

        if cart_in.cpu.romsel or
           (banks.prg_rom_6000 and is_prg_ram_window(cart_in.cpu))
        then
            if is_bus_read(cart_in.cpu.prg_bus)
            then
                ret := map_prg_rom(config, cart_in, banks.prg, ret);
            end if;
        elsif banks.prg_ram and
              is_bus_active(cart_in.cpu.prg_bus) and
              is_prg_ram_window(cart_in.cpu)
        then
            ret := map_prg_ram(config, cart_in, banks.prg_ram_bank, ret);
        end if;

        if is_bus_active(cart_in.ppu.chr_bus)
        then
            if cart_in.ppu.chr_bus.address(13) = '0' or banks.nt_chr
            then
                ret := map_chr(config, cart_in, banks, ret);
            else
                ret := map_ciram(cart_in, banks.mirror, ret);
            end if;
        end if;

        return ret;
    end;

end package body;
