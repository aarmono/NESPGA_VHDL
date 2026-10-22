library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.prg_ram_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

-- Boards built around the MMC3, the MMC6 or the Namco 108, which came before
-- the MMC3. They differ in how the outputs of the chip are wired, so the
-- board is chosen by the mapper number at run time.
--
-- The Namco 108 has only the bank select and bank data registers of the
-- MMC3, at 0x8000-0x9FFF. Its PRG and CHR modes are always 0, and it has no
-- mirroring control, PRG RAM or IRQ. Its CHR banks are 6 bits wide
--
-- An iNES header cannot tell the MMC6 from the MMC3, so a TxROM board with
-- an iNES header becomes an MMC6 once the CPU sets bit 5 of 0x8000, which
-- enables the PRG RAM of the MMC6 and does nothing on the MMC3
--
-- To add a board, add it to mmc3_board_t and get_mmc3_board and its mapper
-- number to get_board in the cartridge
package lib_mapper_mmc3 is

    type mmc3_board_t is
    (
        -- TxROM (4)
        MMC3_TXROM,
        -- HKROM (4, NES 2.0 submapper 1): the MMC6, which has 1KB of PRG
        -- RAM at 0x7000-0x7FFF, enabled in 512 byte halves
        MMC3_MMC6,
        -- NES-QJ (47): two 128KB PRG ROM and CHR ROM sets, selected by a
        -- latch at 0x6000-0x7FFF in place of PRG RAM
        MMC3_QJ,
        -- TxSROM (118): bit 7 of the CHR bank drives CIRAM A10
        MMC3_TXSROM,
        -- TQROM (119): bit 6 of the CHR bank selects CHR RAM
        MMC3_TQROM,
        -- Namco 108 boards with hardwired mirroring: DxROM (206) and
        -- NAMCOT-3433/3443 (88), which wires PPU A12 to CHR A16 for 128KB of
        -- CHR. DxROM has at most 64KB of CHR, so it can be wired the same way
        NAMCO_108,
        -- NAMCOT-3425 (95): bit 5 of the CHR bank drives CIRAM A10
        NAMCO_3425,
        -- NAMCOT-3446 (76): 128KB of CHR in four 2KB banks, selected by the
        -- registers of the 1KB banks
        NAMCO_3446,
        -- NAMCOT-3453 (154): NAMCOT-3433 with single screen mirroring,
        -- selected by bit 6 of every write to 0x8000-0xFFFF
        NAMCO_3453
    );

    function get_mmc3_board(config : cart_config_t) return mmc3_board_t;

    subtype bank_idx_t is unsigned(2 downto 0);

    subtype bank_t is unsigned(7 downto 0);
    type bank_arr_t is array(0 to 7) of bank_t;

    subtype irq_count_t is natural range 0 to 2**8-1;

    subtype irq_delay_t is boolean_array(1 downto 0);

    constant A12_MAX : natural := 10;
    subtype a12_count_t is natural range 0 to A12_MAX;

    type mapper_mmc3_reg_t is record
        bank_idx : bank_idx_t;

        banks : bank_arr_t;

        chr_mode : std_logic;
        prg_mode : std_logic;

        mirroring : std_logic;

        -- Bits 7-4 of 0xA001. On the MMC3, bit 7 enables PRG RAM and bit 6
        -- protects it from writes. On the MMC6, bits 7 and 6 enable reads
        -- and writes of the upper 512 bytes, and bits 5 and 4 of the lower
        prg_ram_bits : std_logic_vector(7 downto 4);
        -- Bit 5 of 0x8000, which enables the PRG RAM of the MMC6
        mmc6_ram_enable : std_logic;
        -- The chip is an MMC6, found from the writes to 0x8000
        mmc6 : boolean;

        irq_count  : irq_count_t;
        irq_reload : irq_count_t;
        irq_enable : boolean;
        irq        : boolean;
        irq_delay  : irq_delay_t;

        a12_count : a12_count_t;

        -- The 128KB set of NES-QJ
        outer : std_logic;
    end record;

    constant RESET_MAPPER_MMC3_REG : mapper_mmc3_reg_t :=
    (
        bank_idx => (others => '0'),

        banks => (others => (others => '0')),

        chr_mode => '0',
        prg_mode => '0',

        mirroring => '0',

        prg_ram_bits => (others => '0'),
        mmc6_ram_enable => '0',
        mmc6 => false,

        irq_count => 0,
        irq_reload => 0,
        irq_enable => false,
        irq => false,
        irq_delay => (others => false),

        a12_count => 0,

        outer => '0'
    );

    type mapper_mmc3_out_t is record
        reg  : mapper_mmc3_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_mmc3
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_out_t;

end package lib_mapper_mmc3;


package body lib_mapper_mmc3 is

    function get_mmc3_board(config : cart_config_t) return mmc3_board_t
    is
    begin
        case config.mapper_num is
            when x"004" =>
                if config.submapper_num = x"1"
                then
                    return MMC3_MMC6;
                else
                    return MMC3_TXROM;
                end if;
            when x"02F" => return MMC3_QJ;
            when x"076" => return MMC3_TXSROM;
            when x"077" => return MMC3_TQROM;
            when x"0CE" | x"058" => return NAMCO_108;
            when x"05F" => return NAMCO_3425;
            when x"04C" => return NAMCO_3446;
            when x"09A" => return NAMCO_3453;
            when others => return MMC3_TXROM;
        end case;
    end;

    function is_mmc6
    (
        reg   : mapper_mmc3_reg_t;
        board : mmc3_board_t
    )
    return boolean
    is
    begin
        return board = MMC3_MMC6 or reg.mmc6;
    end;

    function is_namco_108(board : mmc3_board_t) return boolean
    is
    begin
        return board = NAMCO_108 or
               board = NAMCO_3425 or
               board = NAMCO_3446 or
               board = NAMCO_3453;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_mmc3_reg_t;
        window : prg_window_t
    )
    return bank_t
    is
        variable bank : bank_t;
    begin
        case window is
            -- 0x8000-0x9FFF
            when "00" =>
                if reg.prg_mode = '0'
                then
                    bank := reg.banks(6);
                else
                    bank := x"FE";
                end if;
            -- 0xA000-0xBFFF
            when "01" =>
                bank := reg.banks(7);
            -- 0xC000-0xDFFF
            when "10" =>
                if reg.prg_mode = '0'
                then
                    bank := x"FE";
                else
                    bank := reg.banks(6);
                end if;
            -- 0xE000-0xFFFF is the last bank
            when others =>
                bank := x"FF";
        end case;

        return bank;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_mmc3_reg_t;
        window : chr_window_t
    )
    return bank_t
    is
        variable bank : bank_t;
        variable swapped : chr_window_t;
    begin
        -- CHR mode 1 swaps the 2KB and 1KB banks between 0x0000 and 0x1000
        swapped := window;
        swapped(2) := window(2) xor reg.chr_mode;

        case swapped is
            when "000" | "001" =>
                bank := reg.banks(0);
                bank(0) := swapped(0);
            when "010" | "011" =>
                bank := reg.banks(1);
                bank(0) := swapped(0);
            when "100" =>
                bank := reg.banks(2);
            when "101" =>
                bank := reg.banks(3);
            when "110" =>
                bank := reg.banks(4);
            when others =>
                bank := reg.banks(5);
        end case;

        return bank;
    end;

    -- The 1KB CHR bank in the window of the PPU address on NAMCOT-3446,
    -- which maps the 2KB banks of the 1KB bank registers to 0x0000-0x1FFF
    function get_chr_bank_3446
    (
        reg    : mapper_mmc3_reg_t;
        window : chr_window_t
    )
    return bank_t
    is
        variable bank : bank_t;
    begin
        case window(2 downto 1) is
            when "00"   => bank := reg.banks(2);
            when "01"   => bank := reg.banks(3);
            when "10"   => bank := reg.banks(4);
            when others => bank := reg.banks(5);
        end case;

        return "0" & bank(5 downto 0) & window(0);
    end;

    -- Writes to the Namco 108
    function cycle_write_namco_108
    (
        reg     : mapper_mmc3_reg_t;
        board   : mmc3_board_t;
        cart_in : cart_in_t
    )
    return mapper_mmc3_reg_t
    is
        variable ret : mapper_mmc3_reg_t;
    begin
        ret := reg;

        if cart_in.cpu.prg_bus.address(14 downto 13) = "00"
        then
            if cart_in.cpu.prg_bus.address(0) = '0'
            then
                ret.bank_idx := unsigned(cart_in.cpu.data(2 downto 0));
            else
                ret.banks(to_integer(reg.bank_idx)) :=
                    unsigned(cart_in.cpu.data);
            end if;
        end if;

        -- The single screen mirroring of NAMCOT-3453
        if board = NAMCO_3453
        then
            ret.mirroring := cart_in.cpu.data(6);
        end if;

        return ret;
    end;

    function cycle_write
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_reg_t
    is
        variable ret : mapper_mmc3_reg_t;
    begin
        ret := reg;

        if is_rom_write(cart_in.cpu, clk_sync) and is_namco_108(board)
        then
            ret := cycle_write_namco_108(reg, board, cart_in);
        elsif is_rom_write(cart_in.cpu, clk_sync)
        then
            case cart_in.cpu.prg_bus.address(14 downto 13) is
                -- 0x8000-0x9FFF
                when "00" =>
                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.bank_idx := unsigned(cart_in.cpu.data(2 downto 0));
                        ret.chr_mode := cart_in.cpu.data(7);
                        ret.prg_mode := cart_in.cpu.data(6);
                        ret.mmc6_ram_enable := cart_in.cpu.data(5);

                        if board = MMC3_TXROM and
                           not config.nes2 and
                           cart_in.cpu.data(5) = '1'
                        then
                            ret.mmc6 := true;
                        end if;
                    else
                        ret.banks(to_integer(reg.bank_idx)) :=
                            unsigned(cart_in.cpu.data);
                    end if;
                -- 0xA000-0xBFFF
                when "01" =>
                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.mirroring := cart_in.cpu.data(0);
                    -- The MMC6 ignores this while its PRG RAM is disabled
                    elsif not is_mmc6(reg, board) or
                          reg.mmc6_ram_enable = '1'
                    then
                        ret.prg_ram_bits := cart_in.cpu.data(7 downto 4);
                    end if;
                -- 0xC000-0xDFFF
                when "10" =>
                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.irq_reload := to_integer(unsigned(cart_in.cpu.data));
                    else
                        ret.irq_count := 0;
                    end if;
                -- 0xE000-0xFFFF
                when others =>
                    ret.irq_enable := cart_in.cpu.prg_bus.address(0) = '1';

                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.irq := false;
                    end if;
            end case;
        end if;

        -- The NES-QJ latch is written through the PRG RAM enables of the
        -- MMC3
        if board = MMC3_QJ and
           not cart_in.cpu.romsel and
           is_bus_write(cart_in.cpu.prg_bus) and
           clk_sync and
           cart_in.cpu.prg_bus.address(14 downto 13) = "11" and
           reg.prg_ram_bits(7 downto 6) = "10"
        then
            ret.outer := cart_in.cpu.data(0);
        end if;

        return ret;
    end;

    -- The IRQ counter is clocked when PPU A12 rises after being low for
    -- A12_MAX PPU clocks
    function cycle_irq
    (
        reg     : mapper_mmc3_reg_t;
        cart_in : cart_in_t
    )
    return mapper_mmc3_reg_t
    is
        variable ret : mapper_mmc3_reg_t;
    begin
        ret := reg;

        if not is_bus_active(cart_in.ppu.chr_bus) or
           cart_in.ppu.chr_bus.address(12) = '0'
        then
            if reg.a12_count < A12_MAX
            then
                ret.a12_count := reg.a12_count + 1;
            end if;
        else
            ret.a12_count := 0;
            if reg.a12_count = A12_MAX
            then
                if reg.irq_count = 0
                then
                    ret.irq_count := reg.irq_reload;
                else
                    ret.irq_count := reg.irq_count - 1;
                end if;

                if ret.irq_count = 0
                then
                    ret.irq := reg.irq_enable;
                end if;
            end if;
        end if;

        -- IRQ needs to be delayed, but acknowledging it clears it immediately
        if ret.irq
        then
            ret.irq_delay := shift_left(reg.irq_delay, true);
        else
            ret.irq_delay := (others => false);
        end if;

        return ret;
    end;

    -- The CPU accesses PRG RAM at 0x6000-0x7FFF
    function is_prg_ram_enabled
    (
        reg     : mapper_mmc3_reg_t;
        board   : mmc3_board_t;
        cart_in : cart_in_t
    )
    return boolean
    is
    begin
        if board = MMC3_QJ or is_namco_108(board)
        then
            return false;
        elsif is_mmc6(reg, board)
        then
            -- 0x7000-0x7FFF, when either half can be read
            return reg.mmc6_ram_enable = '1' and
                   cart_in.cpu.prg_bus.address(12) = '1' and
                   (reg.prg_ram_bits(7) = '1' or reg.prg_ram_bits(5) = '1');
        else
            return reg.prg_ram_bits(7) = '1';
        end if;
    end;

    -- Applies the write protection of the PRG RAM, and on the MMC6 the
    -- 1KB size of the PRG RAM and the enables of its halves
    function protect_prg_ram
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable bits : std_logic_vector(1 downto 0);
    begin
        ret := cart_out;

        if is_mmc6(reg, board)
        then
            ret.mem.prg_ram_bus.address(12 downto 10) := "000";

            -- The read and write enables of the half selected by bit 9 of
            -- the address
            if cart_in.cpu.prg_bus.address(9) = '1'
            then
                bits := reg.prg_ram_bits(7 downto 6);
            else
                bits := reg.prg_ram_bits(5 downto 4);
            end if;

            -- A half that cannot be read reads 0 when the other half can be
            -- read. A half can only be written when it can be read
            if bits(1) = '0'
            then
                ret.cpu.data := x"00";
            end if;

            if bits /= "11"
            then
                ret.mem.prg_ram_bus.write := false;
            end if;
        elsif reg.prg_ram_bits(6) = '1'
        then
            ret.mem.prg_ram_bus.write := false;
        end if;

        return ret;
    end;

    function get_mirror
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        chr_bank : bank_t
    )
    return mirror_t
    is
        variable a10 : std_logic;
    begin
        -- The CHR bank is computed for nametable addresses as well, so on
        -- the boards that wire a bit of it to CIRAM A10, each 1KB nametable
        -- window has its own CIRAM A10
        case board is
            when MMC3_TXSROM =>
                a10 := chr_bank(7);
            when NAMCO_3425 =>
                a10 := chr_bank(5);
            when NAMCO_3453 =>
                a10 := reg.mirroring;
            when NAMCO_108 | NAMCO_3446 =>
                return config.mirror;
            when others =>
                if config.mirror = MIRROR_FOUR
                then
                    return config.mirror;
                elsif reg.mirroring = '1'
                then
                    return MIRROR_HORZ;
                else
                    return MIRROR_VERT;
                end if;
        end case;

        if a10 = '0'
        then
            return MIRROR_A;
        else
            return MIRROR_B;
        end if;
    end;

    function cycle_mapper_mmc3
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_out_t
    is
        variable ret : mapper_mmc3_out_t;
        variable written : mapper_mmc3_reg_t;
        variable banks : cart_banks_t;
        variable prg_bank : bank_t;
        variable chr_bank : bank_t;
    begin
        -- The PPU sees the registers written by the CPU this cycle
        written := cycle_write(reg, board, config, clk_sync, cart_in);
        ret.reg := cycle_irq(written, cart_in);

        prg_bank := get_prg_bank(written, get_prg_window(cart_in.cpu));
        chr_bank := get_chr_bank(written, get_chr_window(cart_in.ppu));

        banks.prg_ram := is_prg_ram_enabled(written, board, cart_in);
        banks.prg_ram_bank := (others => '0');
        banks.chr_ram := has_chr_ram(config);
        banks.mirror := get_mirror(written, board, config, chr_bank);

        case board is
            when MMC3_TXROM | MMC3_MMC6 | MMC3_TXSROM =>
            when MMC3_QJ =>
                prg_bank := "000" & written.outer & prg_bank(3 downto 0);
                chr_bank := written.outer & chr_bank(6 downto 0);
            when MMC3_TQROM =>
                banks.chr_ram := chr_bank(6) = '1';
            when NAMCO_108 | NAMCO_3425 | NAMCO_3453 =>
                -- PPU A12 drives CHR A16 on NAMCOT-3433 and NAMCOT-3453.
                -- The other boards have at most 64KB of CHR, which drops it
                chr_bank := "0" & cart_in.ppu.chr_bus.address(12) &
                            chr_bank(5 downto 0);
            when NAMCO_3446 =>
                chr_bank := get_chr_bank_3446(written,
                                              get_chr_window(cart_in.ppu));
        end case;

        banks.prg := prg_bank;
        banks.chr := resize(chr_bank, chr_bank_1kb_t'length);

        ret.cart := map_cart(config, cart_in, banks);
        if is_bus_active(ret.cart.mem.prg_ram_bus)
        then
            ret.cart := protect_prg_ram(written, board, cart_in, ret.cart);
        end if;
        ret.cart.cpu.irq := ret.reg.irq and
                            written.irq_delay(written.irq_delay'high);

        return ret;
    end;

end package body;
