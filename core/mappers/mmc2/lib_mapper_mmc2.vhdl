library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

-- Boards built around the MMC2 or the MMC4. Both switch each 4KB half of
-- CHR between two banks with a latch, set when the PPU reads the last rows
-- of tile 0xFD or 0xFE in that half. A game places one of those tiles where
-- it wants the bank to change, so the switch happens mid-frame without the
-- CPU. They differ in PRG banking and in which reads set the latch of the
-- lower half, so the board is chosen by the mapper number at run time.
--
-- To add a board, add it to mmc2_board_t and get_mmc2_board and its mapper
-- number to is_mmc2_mapper
package lib_mapper_mmc2 is

    type mmc2_board_t is
    (
        -- PxROM (9): the MMC2. An 8KB PRG ROM bank at 0x8000, and the last
        -- three banks at 0xA000-0xFFFF. Only a read of 0x0FD8 or 0x0FE8 sets
        -- the latch of the lower half
        MMC2_PXROM,
        -- FxROM (10): the MMC4. A 16KB PRG ROM bank at 0x8000, the last bank
        -- at 0xC000, and PRG RAM at 0x6000-0x7FFF
        MMC4_FXROM
    );

    -- The mapper number is that of a board built around the MMC2 or the MMC4
    function is_mmc2_mapper(mapper_num : mapper_num_t) return boolean;

    function get_mmc2_board(config : cart_config_t) return mmc2_board_t;

    subtype prg_bank_t is unsigned(3 downto 0);

    subtype chr_bank_t is unsigned(4 downto 0);
    -- Indexed by PPU A12 and the latch of that half: the banks written to
    -- 0xB000 (0x0000, 0xFD), 0xC000 (0x0000, 0xFE), 0xD000 (0x1000, 0xFD)
    -- and 0xE000 (0x1000, 0xFE)
    type chr_bank_arr_t is array(0 to 3) of chr_bank_t;

    -- A PPU read that sets a latch
    type latch_trigger_t is record
        active : boolean;
        -- PPU A12: the half whose latch is set
        half   : std_logic;
        -- The value of the latch: '0' for tile 0xFD, '1' for 0xFE
        value  : std_logic;
    end record;

    constant LATCH_TRIGGER_NONE : latch_trigger_t :=
    (
        active => false,
        half => '-',
        value => '-'
    );

    type mapper_mmc2_reg_t is record
        prg_bank : prg_bank_t;
        chr_banks : chr_bank_arr_t;

        mirroring : std_logic;

        -- The latches of the lower and upper halves of CHR
        latch : std_logic_vector(1 downto 0);
        -- The read on the previous PPU clock set a latch. The new bank is
        -- selected once that read is over
        trigger : latch_trigger_t;
    end record;

    constant RESET_MAPPER_MMC2_REG : mapper_mmc2_reg_t :=
    (
        prg_bank => (others => '0'),
        chr_banks => (others => (others => '0')),

        mirroring => '0',

        latch => (others => '1'),
        trigger => LATCH_TRIGGER_NONE
    );

    type mapper_mmc2_out_t is record
        reg  : mapper_mmc2_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_mmc2
    (
        reg      : mapper_mmc2_reg_t;
        board    : mmc2_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc2_out_t;

end package lib_mapper_mmc2;


package body lib_mapper_mmc2 is

    function is_mmc2_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"009" | x"00A" => return true;
            when others => return false;
        end case;
    end;

    function get_mmc2_board(config : cart_config_t) return mmc2_board_t
    is
    begin
        case config.mapper_num is
            when x"00A" => return MMC4_FXROM;
            when others => return MMC2_PXROM;
        end case;
    end;

    function cycle_write
    (
        reg      : mapper_mmc2_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc2_reg_t
    is
        variable ret : mapper_mmc2_reg_t;
        variable data : unsigned(7 downto 0);
    begin
        ret := reg;
        data := unsigned(cart_in.cpu.data);

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            case cart_in.cpu.prg_bus.address(14 downto 12) is
                when "010" =>
                    ret.prg_bank := data(prg_bank_t'range);
                when "011" =>
                    ret.chr_banks(0) := data(chr_bank_t'range);
                when "100" =>
                    ret.chr_banks(1) := data(chr_bank_t'range);
                when "101" =>
                    ret.chr_banks(2) := data(chr_bank_t'range);
                when "110" =>
                    ret.chr_banks(3) := data(chr_bank_t'range);
                when "111" =>
                    ret.mirroring := data(0);
                -- 0x8000-0x9FFF
                when others =>
                    null;
            end case;
        end if;

        return ret;
    end;

    -- The latch set by the PPU access, if any: a read of 0x0FD8-0x0FDF,
    -- 0x0FE8-0x0FEF, 0x1FD8-0x1FDF or 0x1FE8-0x1FEF, the second bit plane
    -- of the last rows of tile 0xFD or 0xFE. On the MMC2, only the read of
    -- the last row sets the latch of the lower half
    function get_latch_trigger
    (
        board   : mmc2_board_t;
        chr_bus : chr_bus_t
    )
    return latch_trigger_t
    is
        variable ret : latch_trigger_t;
        variable addr : chr_addr_t;
    begin
        ret := LATCH_TRIGGER_NONE;
        addr := chr_bus.address;

        if is_bus_read(chr_bus) and
           addr(13) = '0' and
           (addr(11 downto 3) = "111111011" or
            addr(11 downto 3) = "111111101") and
           (board = MMC4_FXROM or
            addr(12) = '1' or
            addr(2 downto 0) = "000")
        then
            ret.active := true;
            ret.half := addr(12);
            ret.value := addr(5);
        end if;

        return ret;
    end;

    -- The latch changes once the read that set it is over, so that read is
    -- from the bank the latch selected before it
    function cycle_latch
    (
        reg     : mapper_mmc2_reg_t;
        board   : mmc2_board_t;
        cart_in : cart_in_t
    )
    return mapper_mmc2_reg_t
    is
        variable ret : mapper_mmc2_reg_t;
    begin
        ret := reg;

        ret.trigger := get_latch_trigger(board, cart_in.ppu.chr_bus);

        if reg.trigger.active and ret.trigger /= reg.trigger
        then
            if reg.trigger.half = '0'
            then
                ret.latch(0) := reg.trigger.value;
            else
                ret.latch(1) := reg.trigger.value;
            end if;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_mmc2_reg_t;
        board  : mmc2_board_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable bank : prg_bank_8kb_t;
    begin
        if board = MMC4_FXROM
        then
            -- 16KB banks
            if window(1) = '0'
            then
                bank := resize(reg.prg_bank & window(0), bank'length);
            else
                bank := (others => '1');
                bank(0) := window(0);
            end if;
        elsif window = "00"
        then
            bank := resize(reg.prg_bank, bank'length);
        else
            -- The last three banks
            bank := (others => '1');
            bank(window'range) := window;
        end if;

        return bank;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_mmc2_reg_t;
        window : chr_window_t
    )
    return chr_bank_1kb_t
    is
        variable bank : chr_bank_t;
        variable latch : std_logic;
    begin
        if window(2) = '0'
        then
            latch := reg.latch(0);
        else
            latch := reg.latch(1);
        end if;

        bank := reg.chr_banks(to_integer(unsigned'(window(2) & latch)));

        return resize(bank & window(1 downto 0), chr_bank_1kb_t'length);
    end;

    function cycle_mapper_mmc2
    (
        reg      : mapper_mmc2_reg_t;
        board    : mmc2_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc2_out_t
    is
        variable ret : mapper_mmc2_out_t;
        variable banks : cart_banks_t;
    begin
        -- The PPU sees the registers written by the CPU this cycle, and the
        -- latch set by a read that is over
        ret.reg := cycle_latch(cycle_write(reg, clk_sync, cart_in),
                               board,
                               cart_in);

        banks := default_banks(config);
        banks.prg_ram := board = MMC4_FXROM;
        banks.prg := get_prg_bank(ret.reg, board, get_prg_window(cart_in.cpu));
        banks.chr := get_chr_bank(ret.reg, get_chr_window(cart_in.ppu));
        banks.mirror := get_hv_mirror(ret.reg.mirroring);

        ret.cart := map_cart(config, cart_in, banks);

        return ret;
    end;

end package body;
