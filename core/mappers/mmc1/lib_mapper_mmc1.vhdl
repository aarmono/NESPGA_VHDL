library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_ram_bus_types.all;
use work.cart_types.all;

-- Boards built around the MMC1. The CPU writes its registers one bit at a
-- time through a shift register. The boards differ in the revision of the
-- chip and in how its outputs are wired, so the board is chosen by the
-- mapper number at run time.
--
-- To add a board, add it to mmc1_board_t and get_mmc1_board and its mapper
-- number to is_mmc1_mapper
package lib_mapper_mmc1 is

    type mmc1_board_t is
    (
        -- SxROM (1): the MMC1B, where bit 4 of the PRG bank disables PRG RAM.
        -- SUROM has 512KB of PRG ROM, and bit 4 of the CHR bank selects the
        -- 256KB half. SOROM, SZROM and SXROM bank PRG RAM (mmc1_prg_ram_t)
        MMC1_SXROM,
        -- SEROM, SHROM and SH1ROM (1, NES 2.0 submapper 5): 32KB of PRG ROM,
        -- addressed by the CPU rather than the chip, so it is not banked
        MMC1_SEROM,
        -- SxROM with the MMC1A (155). PRG RAM is always enabled, and bit 4
        -- of the PRG bank has bit 3 select the 128KB half of PRG ROM for the
        -- fixed bank too
        MMC1A_SXROM,
        -- NES-EVENT (105): Nintendo World Championships. Bits of CHR bank 0
        -- select the PRG ROM chip and its bank, and run a timer that raises
        -- an IRQ when the time is up
        MMC1_EVENT
    );

    -- The mapper number is that of a board built around this family
    function is_mmc1_mapper(mapper_num : mapper_num_t) return boolean;

    function get_mmc1_board(config : cart_config_t) return mmc1_board_t;

    -- SxROM boards with more than 8KB of PRG RAM select its 8KB bank with
    -- bits of the CHR bank that they do not need for CHR. Which bits is told
    -- from the sizes of PRG RAM and CHR in the header
    type mmc1_prg_ram_t is
    (
        -- 8KB or less
        PRG_RAM_UNBANKED,
        -- SOROM: 16KB, with 8KB of CHR. Bit 3 selects the bank
        PRG_RAM_SOROM,
        -- SZROM: 16KB, with more than 8KB of CHR ROM. Bit 4 selects the bank
        PRG_RAM_SZROM,
        -- SXROM: 32KB. Bits 3-2 select the bank
        PRG_RAM_SXROM
    );

    function get_mmc1_prg_ram(config : cart_config_t) return mmc1_prg_ram_t;

    -- The mask of the PRG RAM address for an iNES header, which has no RAM
    -- size. 32KB is enough for every SxROM game (nesdev), but a board with
    -- more than 8KB of CHR uses the bits that bank 32KB for CHR, so only
    -- boards with 8KB of CHR or less get it: SOROM, SUROM and SXROM, and
    -- SNROM, which ignores those bits. SZROM cannot be told from SKROM
    -- without the RAM size
    constant PRG_RAM_32KB_MASK : prg_ram_addr_t := x"7FFF";

    function get_mmc1_ines_prg_ram_mask
    (
        config : cart_config_t
    )
    return prg_ram_addr_t;

    -- The 5 bit value of a register
    subtype reg_value_t is unsigned(4 downto 0);

    -- The bits of a register value written so far, shifted in from bit 4
    -- ahead of a marker bit. The fifth write, when the marker has reached
    -- bit 0, writes the register
    subtype shift_t is reg_value_t;
    constant SHIFT_RESET : shift_t := "10000";

    -- Bits 3-0 select the 16KB bank, and bit 4 is the PRG RAM disable of
    -- the MMC1B or the fixed bank bypass of the MMC1A
    subtype prg_bank_t is reg_value_t;
    subtype prg_bank_16kb_t is unsigned(3 downto 0);

    subtype chr_bank_t is reg_value_t;

    -- PRG ROM on NES-EVENT is locked to its first 32KB until the I bit of
    -- CHR bank 0, which is set on power up, is cleared and then set
    type event_lock_t is
    (
        EVENT_LOCKED,
        EVENT_I_CLEARED,
        EVENT_UNLOCKED
    );

    -- The DIP switches of NES-EVENT set bits 28-25 of the CPU cycles the
    -- timer runs for: 0 (all open, as in Mesen) is about 5 minutes. The
    -- tournament used 4
    constant EVENT_DIP_SWITCHES : natural range 0 to 15 := 0;
    constant EVENT_TIMER_MAX : natural := 2**29 + EVENT_DIP_SWITCHES * 2**25;
    subtype event_timer_t is natural range 0 to EVENT_TIMER_MAX;

    type mapper_mmc1_reg_t is record
        shift : shift_t;

        mirror : mirror_t;
        prg_bank_mode : unsigned(1 downto 0);
        chr_bank_mode : std_logic;

        chr_bank_0 : chr_bank_t;
        chr_bank_1 : chr_bank_t;

        prg_bank : prg_bank_t;

        -- The CPU wrote on the previous cycle. Writes on consecutive cycles
        -- after the first are ignored
        write_prev : boolean;

        -- NES-EVENT only
        event_lock  : event_lock_t;
        -- The CPU cycles since the I bit was cleared
        event_timer : event_timer_t;
    end record;

    constant RESET_MAPPER_MMC1_REG : mapper_mmc1_reg_t :=
    (
        shift => SHIFT_RESET,

        mirror => MIRROR_A,
        prg_bank_mode => (others => '1'),
        chr_bank_mode => '0',

        chr_bank_0 => (others => '0'),
        chr_bank_1 => (others => '0'),

        prg_bank => (others => '0'),

        write_prev => false,

        event_lock => EVENT_LOCKED,
        event_timer => 0
    );

    function get_reset_mmc1_reg(board : mmc1_board_t) return mapper_mmc1_reg_t;

    type mapper_mmc1_out_t is record
        reg  : mapper_mmc1_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_mmc1
    (
        reg      : mapper_mmc1_reg_t;
        board    : mmc1_board_t;
        prg_ram  : mmc1_prg_ram_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc1_out_t;

end package lib_mapper_mmc1;


package body lib_mapper_mmc1 is

    function is_mmc1_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"001" | x"069" | x"09B" => return true;
            when others => return false;
        end case;
    end;

    function get_mmc1_board(config : cart_config_t) return mmc1_board_t
    is
    begin
        case config.mapper_num is
            when x"069" => return MMC1_EVENT;
            when x"09B" => return MMC1A_SXROM;
            when others =>
                if config.submapper_num = x"5"
                then
                    return MMC1_SEROM;
                else
                    return MMC1_SXROM;
                end if;
        end case;
    end;

    function get_mmc1_prg_ram(config : cart_config_t) return mmc1_prg_ram_t
    is
    begin
        case get_mmc1_board(config) is
            when MMC1_SXROM | MMC1A_SXROM =>
                if config.prg_ram_mask(14) = '1'
                then
                    return PRG_RAM_SXROM;
                elsif config.prg_ram_mask(13) = '0'
                then
                    return PRG_RAM_UNBANKED;
                elsif config.chr_rom_8kb_blocks > 1
                then
                    return PRG_RAM_SZROM;
                else
                    return PRG_RAM_SOROM;
                end if;
            when others =>
                return PRG_RAM_UNBANKED;
        end case;
    end;

    function get_mmc1_ines_prg_ram_mask
    (
        config : cart_config_t
    )
    return prg_ram_addr_t
    is
    begin
        case get_mmc1_board(config) is
            when MMC1_SXROM | MMC1A_SXROM =>
                if config.chr_rom_8kb_blocks <= 1
                then
                    return PRG_RAM_32KB_MASK;
                end if;
            when others =>
                null;
        end case;

        return DEFAULT_RAM_MASK;
    end;

    function get_reset_mmc1_reg(board : mmc1_board_t) return mapper_mmc1_reg_t
    is
        variable ret : mapper_mmc1_reg_t;
    begin
        ret := RESET_MAPPER_MMC1_REG;

        -- The timer of NES-EVENT does not run on power up
        if board = MMC1_EVENT
        then
            ret.chr_bank_0(4) := '1';
        end if;

        return ret;
    end;

    -- The mirroring of bits 1-0 of the control register: one screen A
    -- ("00") or B ("01"), vertical ("10") or horizontal ("11")
    function get_mirror(mode : unsigned(1 downto 0)) return mirror_t
    is
    begin
        if mode(1) = '1'
        then
            return get_hv_mirror(mode(0));
        else
            return get_single_screen_mirror(mode(0));
        end if;
    end;

    -- The register at the CPU address
    function write_register
    (
        reg    : mapper_mmc1_reg_t;
        cpu_in : cart_cpu_in_t;
        value  : reg_value_t
    )
    return mapper_mmc1_reg_t
    is
        variable ret : mapper_mmc1_reg_t;
    begin
        ret := reg;

        case cpu_in.prg_bus.address(14 downto 13) is
            when "00" =>
                ret.mirror := get_mirror(value(1 downto 0));
                ret.prg_bank_mode := value(3 downto 2);
                ret.chr_bank_mode := value(4);
            when "01" =>
                ret.chr_bank_0 := value;
            when "10" =>
                ret.chr_bank_1 := value;
            when "11" =>
                ret.prg_bank := value;
            when others =>
                null;
        end case;

        return ret;
    end;

    function cycle_write
    (
        reg      : mapper_mmc1_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc1_reg_t
    is
        variable ret : mapper_mmc1_reg_t;
        variable first_write : boolean;
        variable value : reg_value_t;
    begin
        ret := reg;

        first_write := cart_in.cpu.prg_bus.write and not reg.write_prev;

        if clk_sync
        then
            ret.write_prev := cart_in.cpu.prg_bus.write;
        end if;

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            if cart_in.cpu.data(7) = '1'
            then
                ret.shift := SHIFT_RESET;
                ret.prg_bank_mode := (others => '1');
            elsif first_write
            then
                value := cart_in.cpu.data(0) & reg.shift(4 downto 1);

                if reg.shift(0) = '1'
                then
                    ret := write_register(ret, cart_in.cpu, value);
                    ret.shift := SHIFT_RESET;
                else
                    ret.shift := value;
                end if;
            end if;
        end if;

        return ret;
    end;

    -- The I bit of CHR bank 0 on NES-EVENT unlocks PRG ROM and runs the
    -- timer while it is clear. The timer stops when the time is up
    function cycle_event
    (
        reg      : mapper_mmc1_reg_t;
        clk_sync : boolean
    )
    return mapper_mmc1_reg_t
    is
        variable ret : mapper_mmc1_reg_t;
    begin
        ret := reg;

        if reg.chr_bank_0(4) = '1'
        then
            ret.event_timer := 0;

            if reg.event_lock = EVENT_I_CLEARED
            then
                ret.event_lock := EVENT_UNLOCKED;
            end if;
        else
            if clk_sync and reg.event_timer < EVENT_TIMER_MAX
            then
                ret.event_timer := reg.event_timer + 1;
            end if;

            if reg.event_lock = EVENT_LOCKED
            then
                ret.event_lock := EVENT_I_CLEARED;
            end if;
        end if;

        return ret;
    end;

    -- The 16KB PRG ROM bank at 0x8000 or 0xC000
    function get_prg_bank_16kb
    (
        reg    : mapper_mmc1_reg_t;
        high   : std_logic
    )
    return prg_bank_16kb_t
    is
        variable bank : prg_bank_16kb_t;
    begin
        bank := reg.prg_bank(prg_bank_16kb_t'range);

        case reg.prg_bank_mode is
            -- 32KB
            when "00" | "01" =>
                bank(0) := high;
            -- 0x8000 is fixed to the first bank
            when "10" =>
                if high = '0'
                then
                    bank := (others => '0');
                end if;
            -- 0xC000 is fixed to the last bank
            when others =>
                if high = '1'
                then
                    bank := (others => '1');
                end if;
        end case;

        return bank;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_mmc1_reg_t;
        board  : mmc1_board_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable bank : prg_bank_16kb_t;
    begin
        bank := get_prg_bank_16kb(reg, window(1));

        case board is
            when MMC1_SEROM =>
                return resize(window, prg_bank_8kb_t'length);
            -- Two 128KB chips. The first is banked 32KB at a time by bits 2-1
            -- of CHR bank 0, and the second by the PRG bank like any MMC1
            when MMC1_EVENT =>
                if reg.event_lock /= EVENT_UNLOCKED
                then
                    return resize(window, prg_bank_8kb_t'length);
                elsif reg.chr_bank_0(3) = '0'
                then
                    return resize(reg.chr_bank_0(2 downto 1) & window,
                                  prg_bank_8kb_t'length);
                else
                    return resize('1' & bank(2 downto 0) & window(0),
                                  prg_bank_8kb_t'length);
                end if;
            when MMC1A_SXROM | MMC1_SXROM =>
                if board = MMC1A_SXROM and reg.prg_bank(4) = '1'
                then
                    bank(3) := reg.prg_bank(3);
                end if;

                -- SUROM has 512KB of PRG ROM, and bit 4 of the CHR bank
                -- selects the 256KB half. In 4KB CHR mode the chip takes it
                -- from the CHR bank that PPU A12 selects, but the SUROM
                -- games use 8KB CHR mode, so CHR bank 0 is used. With a
                -- smaller PRG ROM, the bit is masked off
                return resize(reg.chr_bank_0(4) & bank & window(0),
                              prg_bank_8kb_t'length);
        end case;
    end;

    -- The 8KB PRG RAM bank. Like the 256KB half of PRG ROM on SUROM, it
    -- comes from CHR bank 0. In 4KB CHR mode the chip takes it from the CHR
    -- bank that PPU A12 selects, so games either use 8KB CHR mode or set the
    -- bits the same in both CHR banks
    function get_prg_ram_bank
    (
        reg     : mapper_mmc1_reg_t;
        prg_ram : mmc1_prg_ram_t
    )
    return prg_ram_bank_8kb_t
    is
    begin
        case prg_ram is
            when PRG_RAM_UNBANKED =>
                return "000";
            when PRG_RAM_SOROM =>
                return "00" & reg.chr_bank_0(3);
            when PRG_RAM_SZROM =>
                return "00" & reg.chr_bank_0(4);
            when PRG_RAM_SXROM =>
                return '0' & reg.chr_bank_0(3 downto 2);
        end case;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_mmc1_reg_t;
        window : chr_window_t
    )
    return chr_bank_1kb_t
    is
        variable bank : chr_bank_t;
    begin
        if reg.chr_bank_mode = '0'
        then
            -- 8KB
            bank := reg.chr_bank_0;
            bank(0) := window(2);
        elsif window(2) = '0'
        then
            bank := reg.chr_bank_0;
        else
            bank := reg.chr_bank_1;
        end if;

        return resize(bank & window(1 downto 0), chr_bank_1kb_t'length);
    end;

    function cycle_mapper_mmc1
    (
        reg      : mapper_mmc1_reg_t;
        board    : mmc1_board_t;
        prg_ram  : mmc1_prg_ram_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc1_out_t
    is
        variable ret : mapper_mmc1_out_t;
        variable banks : cart_banks_t;
    begin
        ret.reg := cycle_write(reg, clk_sync, cart_in);
        banks := default_banks(config);

        if board = MMC1_EVENT
        then
            ret.reg := cycle_event(ret.reg, clk_sync);
        end if;

        -- The PPU sees the registers written by the CPU this cycle
        banks.prg_ram := board = MMC1A_SXROM or ret.reg.prg_bank(4) = '0';
        banks.prg_ram_bank := get_prg_ram_bank(ret.reg, prg_ram);
        banks.prg := get_prg_bank(ret.reg, board, get_prg_window(cart_in.cpu));
        banks.chr := get_chr_bank(ret.reg, get_chr_window(cart_in.ppu));
        banks.mirror := ret.reg.mirror;

        ret.cart := map_cart(config, cart_in, banks);

        ret.cart.cpu.irq := reg.event_timer >= EVENT_TIMER_MAX;

        return ret;
    end;

end package body;
