library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;

use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.sram_bus_types.all;
use work.file_bus_types.all;

-- Types shared by the cartridge and the boards (mappers) it can hold. The
-- cart_cpu_* and cart_ppu_* records follow the pins of the cartridge
-- connector. The memories on the board (PRG ROM, CHR ROM, PRG RAM and
-- CHR RAM) are not on the connector, so they have records of their own
package cart_types is

    subtype mapper_num_t is std_logic_vector(11 downto 0);
    subtype submapper_num_t is std_logic_vector(3 downto 0);
    subtype rom_blocks_t is unsigned(7 downto 0);

    subtype cpu_addr_int_t is natural range 0 to 16#FFFF#;

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
        mapper_num          : mapper_num_t;
        submapper_num       : submapper_num_t;
        prg_rom_16kb_blocks : rom_blocks_t;
        chr_rom_8kb_blocks  : rom_blocks_t;
        mirror              : mirror_t;
        has_prg_ram         : boolean;
        has_trainer         : boolean;
    end record;

    constant RESET_CART_CONFIG : cart_config_t :=
    (
        mapper_num => (others => '0'),
        submapper_num => (others => '0'),
        prg_rom_16kb_blocks => (others => '0'),
        chr_rom_8kb_blocks => (others => '0'),
        mirror => MIRROR_HORZ,
        has_prg_ram => false,
        has_trainer => false
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

    constant CART_CPU_IN_IDLE : cart_cpu_in_t :=
    (
        prg_bus => PRG_BUS_IDLE,
        romsel => false,
        data => (others => '-')
    );

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

    constant CART_PPU_IN_IDLE : cart_ppu_in_t :=
    (
        chr_bus => CHR_BUS_IDLE,
        data => (others => '-')
    );

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

    constant CART_MEM_IN_IDLE : cart_mem_in_t :=
    (
        data_from_prg_rom => (others => '-'),
        data_from_chr_rom => (others => '-'),
        data_from_prg_ram => (others => '-'),
        data_from_chr_ram => (others => '-')
    );

    type cart_mem_out_t is record
        prg_rom_bus     : file_bus_t;
        chr_rom_bus     : file_bus_t;

        prg_ram_bus     : sram_bus_t;
        data_to_prg_ram : data_t;

        chr_ram_bus     : sram_bus_t;
        data_to_chr_ram : data_t;
    end record;

    constant CART_MEM_OUT_IDLE : cart_mem_out_t :=
    (
        prg_rom_bus => FILE_BUS_IDLE,
        chr_rom_bus => FILE_BUS_IDLE,

        prg_ram_bus => SRAM_BUS_IDLE,
        data_to_prg_ram => (others => '-'),

        chr_ram_bus => SRAM_BUS_IDLE,
        data_to_chr_ram => (others => '-')
    );

    type cart_in_t is record
        cpu : cart_cpu_in_t;
        ppu : cart_ppu_in_t;
        mem : cart_mem_in_t;
    end record;

    constant CART_IN_IDLE : cart_in_t :=
    (
        cpu => CART_CPU_IN_IDLE,
        ppu => CART_PPU_IN_IDLE,
        mem => CART_MEM_IN_IDLE
    );

    type cart_out_t is record
        cpu : cart_cpu_out_t;
        ppu : cart_ppu_out_t;
        mem : cart_mem_out_t;
    end record;

    constant CART_OUT_IDLE : cart_out_t :=
    (
        cpu => CART_CPU_OUT_IDLE,
        ppu => CART_PPU_OUT_IDLE,
        mem => CART_MEM_OUT_IDLE
    );

    -- The 16 bit address of a CPU access, from A0-A14 and /ROMSEL
    function get_cpu_addr(cpu_in : cart_cpu_in_t) return cpu_addr_int_t;

    -- The board puts PRG RAM at 0x6000-0x7FFF
    function map_prg_ram
    (
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return cart_out_t;

    -- The CPU reads PRG ROM at address
    function map_prg_rom
    (
        cart_in  : cart_in_t;
        address  : unsigned;
        cart_out : cart_out_t
    )
    return cart_out_t;

    -- The PPU reads CHR ROM at address, or CHR RAM if the board has no
    -- CHR ROM
    function map_chr
    (
        config   : cart_config_t;
        cart_in  : cart_in_t;
        address  : unsigned;
        cart_out : cart_out_t
    )
    return cart_out_t;

    -- The PPU accesses the nametables in CIRAM
    function map_ciram
    (
        cart_in  : cart_in_t;
        mirror   : mirror_t;
        cart_out : cart_out_t
    )
    return cart_out_t;

end package cart_types;


package body cart_types is

    function get_cpu_addr(cpu_in : cart_cpu_in_t) return cpu_addr_int_t
    is
        variable ret : cpu_addr_int_t;
    begin
        ret := to_integer(unsigned(cpu_in.prg_bus.address));
        if cpu_in.romsel
        then
            ret := ret + 16#8000#;
        end if;

        return ret;
    end;

    function map_prg_ram
    (
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
    begin
        ret := cart_out;

        ret.mem.prg_ram_bus.address :=
            cart_in.cpu.prg_bus.address(sram_addr_t'range);
        ret.mem.prg_ram_bus.read := cart_in.cpu.prg_bus.read;
        ret.mem.prg_ram_bus.write := cart_in.cpu.prg_bus.write;
        ret.mem.data_to_prg_ram := cart_in.cpu.data;

        ret.cpu.data := cart_in.mem.data_from_prg_ram;
        ret.cpu.data_oe := true;

        return ret;
    end;

    function map_prg_rom
    (
        cart_in  : cart_in_t;
        address  : unsigned;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
    begin
        ret := cart_out;

        ret.mem.prg_rom_bus := bus_read(resize(address, file_addr_t'length));

        ret.cpu.data := cart_in.mem.data_from_prg_rom;
        ret.cpu.data_oe := true;

        return ret;
    end;

    function map_chr
    (
        config   : cart_config_t;
        cart_in  : cart_in_t;
        address  : unsigned;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
    begin
        ret := cart_out;

        if not is_zero(config.chr_rom_8kb_blocks)
        then
            ret.mem.chr_rom_bus :=
                bus_read(resize(address, file_addr_t'length));
            ret.ppu.data := cart_in.mem.data_from_chr_rom;
        else
            ret.mem.chr_ram_bus.address :=
                cart_in.ppu.chr_bus.address(sram_addr_t'range);
            ret.mem.chr_ram_bus.read := cart_in.ppu.chr_bus.read;
            ret.mem.chr_ram_bus.write := cart_in.ppu.chr_bus.write;
            ret.mem.data_to_chr_ram := cart_in.ppu.data;

            ret.ppu.data := cart_in.mem.data_from_chr_ram;
        end if;
        ret.ppu.data_oe := true;

        return ret;
    end;

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

end package body;
