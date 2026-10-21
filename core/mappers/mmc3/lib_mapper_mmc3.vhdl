library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

-- Boards built around the MMC3. They differ in how the outputs of the MMC3
-- are wired, so the board is chosen by the mapper number at run time.
--
-- To add a board, add it to mmc3_board_t and get_mmc3_board and its mapper
-- number to get_board in the cartridge
package lib_mapper_mmc3 is

    type mmc3_board_t is
    (
        -- TxROM (4)
        MMC3_TXROM,
        -- NES-QJ (47): two 128KB PRG ROM and CHR ROM sets, selected by a
        -- latch at 0x6000-0x7FFF in place of PRG RAM
        MMC3_QJ,
        -- TxSROM (118): bit 7 of the CHR bank drives CIRAM A10
        MMC3_TXSROM,
        -- TQROM (119): bit 6 of the CHR bank selects CHR RAM
        MMC3_TQROM
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

        prg_ram_enable  : boolean;
        prg_ram_protect : boolean;

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

        prg_ram_enable => false,
        prg_ram_protect => false,

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
            when x"02F" => return MMC3_QJ;
            when x"076" => return MMC3_TXSROM;
            when x"077" => return MMC3_TQROM;
            when others => return MMC3_TXROM;
        end case;
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

    function cycle_write
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_reg_t
    is
        variable ret : mapper_mmc3_reg_t;
    begin
        ret := reg;

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            case cart_in.cpu.prg_bus.address(14 downto 13) is
                -- 0x8000-0x9FFF
                when "00" =>
                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.bank_idx := unsigned(cart_in.cpu.data(2 downto 0));
                        ret.chr_mode := cart_in.cpu.data(7);
                        ret.prg_mode := cart_in.cpu.data(6);
                    else
                        ret.banks(to_integer(reg.bank_idx)) :=
                            unsigned(cart_in.cpu.data);
                    end if;
                -- 0xA000-0xBFFF
                when "01" =>
                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.mirroring := cart_in.cpu.data(0);
                    else
                        ret.prg_ram_enable := cart_in.cpu.data(7) = '1';
                        ret.prg_ram_protect := cart_in.cpu.data(6) = '1';
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
           reg.prg_ram_enable and
           not reg.prg_ram_protect
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

    function get_mirror
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        chr_bank : bank_t
    )
    return mirror_t
    is
    begin
        if board = MMC3_TXSROM
        then
            -- The CHR bank is computed for nametable addresses as well, so
            -- each 1KB nametable window has its own CIRAM A10
            if chr_bank(7) = '0'
            then
                return MIRROR_A;
            else
                return MIRROR_B;
            end if;
        elsif config.mirror = MIRROR_FOUR
        then
            return config.mirror;
        elsif reg.mirroring = '1'
        then
            return MIRROR_HORZ;
        else
            return MIRROR_VERT;
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
        written := cycle_write(reg, board, clk_sync, cart_in);
        ret.reg := cycle_irq(written, cart_in);

        prg_bank := get_prg_bank(written, get_prg_window(cart_in.cpu));
        chr_bank := get_chr_bank(written, get_chr_window(cart_in.ppu));

        banks.prg_ram := true;
        banks.chr_ram := has_chr_ram(config);
        banks.mirror := get_mirror(written, board, config, chr_bank);

        case board is
            when MMC3_TXROM | MMC3_TXSROM =>
            when MMC3_QJ =>
                prg_bank := "000" & written.outer & prg_bank(3 downto 0);
                chr_bank := written.outer & chr_bank(6 downto 0);
                banks.prg_ram := false;
            when MMC3_TQROM =>
                banks.chr_ram := chr_bank(6) = '1';
        end case;

        banks.prg := prg_bank;
        banks.chr := resize(chr_bank, chr_bank_1kb_t'length);

        ret.cart := map_cart(config, cart_in, banks);
        ret.cart.cpu.irq := ret.reg.irq and
                            written.irq_delay(written.irq_delay'high);

        return ret;
    end;

end package body;
