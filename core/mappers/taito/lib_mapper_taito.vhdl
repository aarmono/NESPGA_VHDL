library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.prg_ram_bus_types.all;
use work.cart_types.all;

-- Boards built around the Taito mapper chips. All of them have 8KB PRG ROM
-- banks with the last bank fixed at 0xE000, and CHR ROM in two 2KB banks
-- at 0x0000-0x0FFF and four 1KB banks at 0x1000-0x1FFF. The board is chosen
-- by the mapper number at run time.
--
-- The TC0190 (33) and TC0690 (48) have their registers at 0x8000-0xFFFF,
-- decoded by A0, A1, A13 and A14, two switchable PRG ROM banks with the
-- second last bank fixed at 0xC000, and 2KB CHR banks numbered in 2KB units
-- (so they reach 512KB of CHR, the 1KB banks only 256KB). The TC0690 adds
-- the IRQ counter of the MMC3, clocked by PPU A12, whose reload value is
-- written inverted. It raises the IRQ TC0690_IRQ_DELAY CPU cycles after the
-- MMC3 would, the delay Mesen uses for The Flintstones (whose status bar
-- was checked on hardware) and Captain Saver
--
-- The X1-005 (80, 207) and X1-017 (82, 552) have their registers at
-- 0x7EF0-0x7EFF, three switchable PRG ROM banks, RAM inside the chip that is
-- enabled by writing magic values, and 2KB CHR banks that ignore bit 0 of
-- the register. The RAM is kept in PRG RAM. The X1-017 can swap its 2KB and
-- 1KB CHR banks, as the MMC3 can, and has an IRQ counter of CPU cycles that
-- no game uses, reverse-engineered by krzysiobal (nesdev). Its data bus has
-- pull-downs strong enough that a read of 0x6000-0x7FFF that nothing drives
-- reads 0 rather than open bus. That goes for the rest of the CPU address
-- space as well, which is not emulated
--
-- To add a board, add it to taito_board_t, get_taito_board and its mapper
-- number to is_taito_mapper
package lib_mapper_taito is

    type taito_board_t is
    (
        -- TC0190 (33): mirroring at bit 6 of 0x8000, no IRQ
        TAITO_TC0190,
        -- TC0690 (48), and the TC0190 with a PAL16R4 that some boards of
        -- mapper 48 have: mirroring at 0xE000 and the IRQ counter
        TAITO_TC0690,
        -- X1-005 (80): mirroring at 0x7EF6, 128 bytes of RAM at 0x7F00
        TAITO_X1_005,
        -- X1-005 with CHR A17 wired to CIRAM A10 (207), as on TxSROM, so bit
        -- 7 of the 2KB CHR banks selects the CIRAM page of the nametables.
        -- It has at most 128KB of CHR
        TAITO_X1_005_CIRAM,
        -- X1-017 (82): 5KB of RAM at 0x6000-0x73FF, enabled in three parts,
        -- and bits 5-2 of the PRG bank registers as PRG A13-A16, as the
        -- board was understood before it was traced
        TAITO_X1_017,
        -- X1-017 (NES 2.0 mapper 552): bits 5-0 of the PRG bank registers
        -- as PRG A18-A13, as the mask ROM is wired
        TAITO_X1_017_552
    );

    -- The mapper number is that of a board built around a Taito chip
    function is_taito_mapper(mapper_num : mapper_num_t) return boolean;

    function get_taito_board(config : cart_config_t) return taito_board_t;

    -- The RAM mask of a ROM file of the board whose header gives no RAM
    -- size
    function get_taito_ines_prg_ram_mask(config : cart_config_t)
        return prg_ram_addr_t;

    subtype bank_t is unsigned(7 downto 0);
    -- The PRG ROM banks at 0x8000, 0xA000 and 0xC000. The TC0190 and TC0690
    -- fix 0xC000 to the second last bank
    type prg_bank_arr_t is array(0 to 2) of prg_bank_8kb_t;
    -- The two 2KB CHR banks, then the four 1KB banks
    type chr_bank_arr_t is array(0 to 5) of bank_t;

    -- The RAM enables of the X1-017, for 0x6000-0x67FF, 0x6800-0x6FFF and
    -- 0x7000-0x73FF. The X1-005 uses the first for all of its RAM
    type ram_enable_arr_t is array(0 to 2) of boolean;

    -- The CPU cycles the TC0690 raises the IRQ after the MMC3 would
    constant TC0690_IRQ_DELAY : natural := 22;
    subtype tc0690_irq_delay_t is natural range 0 to TC0690_IRQ_DELAY;

    -- The MMC3 counts PPU clocks with A12 low, and clocks the IRQ counter
    -- when A12 rises after A12_MAX of them
    constant A12_MAX : natural := 10;
    subtype a12_count_t is natural range 0 to A12_MAX;

    subtype irq_count_t is natural range 0 to 16#FF#;
    -- The X1-017 counts CPU cycles down from at most (0xFF + 2) * 16, kept
    -- as X1_017_PRESCALE times an 8-bit count plus a prescaler, which runs
    -- from up to 2 * X1_017_PRESCALE - 1 down to 0 for each step of the count
    constant X1_017_PRESCALE : natural := 16;
    subtype irq_prescaler_t is natural range 0 to 2 * X1_017_PRESCALE - 1;

    type mapper_taito_reg_t is record
        prg_banks : prg_bank_arr_t;
        chr_banks : chr_bank_arr_t;
        -- The X1-017 swaps the 2KB and 1KB CHR banks between 0x0000 and
        -- 0x1000
        chr_invert : boolean;

        -- The mirroring bit is set: bit 6 of 0x8000 or 0xE000 on the TC0190
        -- and TC0690, horizontal when set, and bit 0 of 0x7EF6 on the X1
        -- chips, vertical when set
        mirroring : boolean;

        ram_enable : ram_enable_arr_t;

        -- The reload value of the TC0690, which is written inverted, or the
        -- latch of the X1-017
        irq_reload : irq_count_t;
        irq_count  : irq_count_t;
        -- TC0690: a clock of the counter that leaves it at 0 raises the IRQ.
        -- X1-017: the IRQ drives /IRQ
        irq_enable : boolean;
        irq        : boolean;

        a12_count : a12_count_t;
        -- TC0690: the CPU cycles until the IRQ is raised, or 0 for none
        irq_delay : tc0690_irq_delay_t;

        -- X1-017: bit 0 of 0x7EFE is set and bit 2, which stops the counter,
        -- is clear
        irq_counting  : boolean;
        -- X1-017: the counter has not reached 0 since it was reloaded. The
        -- CPU cycles left are
        -- irq_count * X1_017_PRESCALE + irq_prescaler + 1
        irq_running   : boolean;
        irq_prescaler : irq_prescaler_t;
    end record;

    -- The power on state is not known. The mirroring is that of a mirroring
    -- register of 0
    constant RESET_MAPPER_TAITO_REG : mapper_taito_reg_t :=
    (
        prg_banks => (others => (others => '0')),
        chr_banks => (others => (others => '0')),
        chr_invert => false,

        mirroring => false,

        ram_enable => (others => false),

        irq_reload => 0,
        irq_count => 0,
        irq_enable => false,
        irq => false,

        a12_count => 0,
        irq_delay => 0,

        irq_counting => false,
        irq_running => false,
        irq_prescaler => 0
    );

    type mapper_taito_out_t is record
        reg  : mapper_taito_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_taito
    (
        reg      : mapper_taito_reg_t;
        board    : taito_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_taito_out_t;

end package lib_mapper_taito;


package body lib_mapper_taito is

    function is_taito_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"021" | x"030" | x"050" | x"0CF" | x"052" | x"228" =>
                return true;
            when others =>
                return false;
        end case;
    end;

    function get_taito_board(config : cart_config_t) return taito_board_t
    is
    begin
        case config.mapper_num is
            when x"030" => return TAITO_TC0690;
            when x"050" => return TAITO_X1_005;
            when x"0CF" => return TAITO_X1_005_CIRAM;
            when x"052" => return TAITO_X1_017;
            when x"228" => return TAITO_X1_017_552;
            when others => return TAITO_TC0190;
        end case;
    end;

    function is_tc0x90(board : taito_board_t) return boolean
    is
    begin
        return board = TAITO_TC0190 or board = TAITO_TC0690;
    end;

    function is_x1_017(board : taito_board_t) return boolean
    is
    begin
        return board = TAITO_X1_017 or board = TAITO_X1_017_552;
    end;

    function is_x1_005(board : taito_board_t) return boolean
    is
    begin
        return board = TAITO_X1_005 or board = TAITO_X1_005_CIRAM;
    end;

    function get_taito_ines_prg_ram_mask(config : cart_config_t)
        return prg_ram_addr_t
    is
    begin
        -- The 128 bytes of RAM of the X1-005
        if get_taito_board(config) = TAITO_X1_005
        then
            return x"007F";
        else
            return config.prg_ram_mask;
        end if;
    end;

    -- The PRG ROM bank of a write to a PRG bank register of the X1-017
    function get_x1_017_prg_bank
    (
        board : taito_board_t;
        data  : data_t
    )
    return prg_bank_8kb_t
    is
        variable ret : prg_bank_8kb_t;
    begin
        ret := (others => '0');
        if board = TAITO_X1_017_552
        then
            ret(5 downto 0) := unsigned(reverse_vector(data(5 downto 0)));
        else
            ret(3 downto 0) := unsigned(data(5 downto 2));
        end if;

        return ret;
    end;

    -- Reloads the counter of the X1-017 when 0x7EFF is written, or with
    -- control set when 0x7EFE is written with bit 0 clear. It then raises
    -- the IRQ after (latch + 1) * 16 CPU cycles, or (latch + 2) * 16 with
    -- control set, but 1 or 17 for a latch of 0
    function reload_x1_017_irq
    (
        reg     : mapper_taito_reg_t;
        control : boolean
    )
    return mapper_taito_reg_t
    is
        variable ret : mapper_taito_reg_t;
    begin
        ret := reg;
        ret.irq_running := true;
        ret.irq_count := reg.irq_reload;
        -- The count steps take X1_017_PRESCALE cycles each, and the
        -- prescaler running out one more
        if reg.irq_reload = 0
        then
            if control
            then
                ret.irq_prescaler := X1_017_PRESCALE;
            else
                ret.irq_prescaler := 0;
            end if;
        elsif control
        then
            ret.irq_prescaler := 2 * X1_017_PRESCALE - 1;
        else
            ret.irq_prescaler := X1_017_PRESCALE - 1;
        end if;

        return ret;
    end;

    -- The registers of the TC0190 and TC0690 at 0x8000-0xFFFF. The TC0190
    -- has none at 0xC000-0xFFFF
    function cycle_tc0x90_write
    (
        reg      : mapper_taito_reg_t;
        board    : taito_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_taito_reg_t
    is
        variable ret : mapper_taito_reg_t;
        variable addr : prg_addr_t;
        variable data : data_t;
        variable idx : natural range 0 to 3;
    begin
        ret := reg;
        addr := cart_in.cpu.prg_bus.address;
        data := cart_in.cpu.data;
        idx := to_integer(unsigned(addr(1 downto 0)));

        if is_rom_write(cart_in.cpu, clk_sync) and
           (board = TAITO_TC0690 or addr(14) = '0')
        then
            case addr(14 downto 13) is
                -- 0x8000-0x9FFF
                when "00" =>
                    case idx is
                        when 0 | 1 =>
                            ret.prg_banks(idx) :=
                                resize(unsigned(data(5 downto 0)),
                                       prg_bank_8kb_t'length);
                            if board = TAITO_TC0190 and idx = 0
                            then
                                ret.mirroring := data(6) = '1';
                            end if;
                        when others =>
                            ret.chr_banks(idx - 2) := unsigned(data);
                    end case;
                -- 0xA000-0xBFFF
                when "01" =>
                    ret.chr_banks(idx + 2) := unsigned(data);
                -- 0xC000-0xDFFF, of which every write acknowledges the IRQ
                -- but that to 0xC002
                when "10" =>
                    case idx is
                        when 0 =>
                            ret.irq_reload := to_integer(unsigned(data));
                        -- The next clock reloads the counter
                        when 1 =>
                            ret.irq_count := 0;
                        when 2 =>
                            ret.irq_enable := true;
                        when 3 =>
                            ret.irq_enable := false;
                    end case;
                    if idx /= 2
                    then
                        ret.irq := false;
                    end if;
                -- 0xE000-0xFFFF
                when others =>
                    ret.mirroring := data(6) = '1';
            end case;
        end if;

        return ret;
    end;

    -- The registers of the X1-005 and X1-017 at 0x7EF0-0x7EFF. The X1-005
    -- does not see CPU A7, so they are at 0x7E70-0x7E7F as well, and its
    -- registers from 0x7EF6 on are in pairs
    function cycle_x1_write
    (
        reg      : mapper_taito_reg_t;
        board    : taito_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_taito_reg_t
    is
        variable ret : mapper_taito_reg_t;
        variable addr : prg_addr_t;
        variable data : data_t;
        variable idx : natural range 0 to 15;
    begin
        ret := reg;
        addr := cart_in.cpu.prg_bus.address;
        data := cart_in.cpu.data;
        idx := to_integer(unsigned(addr(3 downto 0)));

        if not cart_in.cpu.romsel and
           is_bus_write(cart_in.cpu.prg_bus) and
           clk_sync and
           addr(14 downto 8) = "1111110" and
           addr(6 downto 4) = "111" and
           (addr(7) = '1' or not is_x1_017(board))
        then
            if idx < 6
            then
                ret.chr_banks(idx) := unsigned(data);
            elsif is_x1_017(board)
            then
                case idx is
                    when 6 =>
                        ret.mirroring := data(0) = '1';
                        ret.chr_invert := data(1) = '1';
                    when 7 =>
                        ret.ram_enable(0) := data = x"CA";
                    when 8 =>
                        ret.ram_enable(1) := data = x"69";
                    when 9 =>
                        ret.ram_enable(2) := data = x"84";
                    when 10 to 12 =>
                        ret.prg_banks(idx - 10) :=
                            get_x1_017_prg_bank(board, data);
                    when 13 =>
                        ret.irq_reload := to_integer(unsigned(data));
                    when 14 =>
                        ret.irq_counting := data(0) = '1' and data(2) = '0';
                        ret.irq_enable := data(1) = '1';
                        if data(0) = '0'
                        then
                            ret := reload_x1_017_irq(ret, true);
                        end if;
                    when others =>
                        ret.irq := false;
                        ret := reload_x1_017_irq(ret, false);
                end case;
            else
                case idx is
                    when 6 | 7 =>
                        -- 207 wires CIRAM A10 to CHR A17 instead
                        ret.mirroring := data(0) = '1';
                    when 8 | 9 =>
                        ret.ram_enable(0) := data = x"A3";
                    when others =>
                        ret.prg_banks(idx / 2 - 5) := unsigned(data);
                end case;
            end if;
        end if;

        return ret;
    end;

    -- The IRQ counter of the TC0690 is clocked as that of the MMC3 is,
    -- when PPU A12 rises after being low for A12_MAX PPU clocks. A clock
    -- that leaves it at 0 with IRQs enabled raises the IRQ TC0690_IRQ_DELAY
    -- CPU cycles later, which acknowledging it does not cancel
    function cycle_tc0690_irq
    (
        reg      : mapper_taito_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_taito_reg_t
    is
        variable ret : mapper_taito_reg_t;
    begin
        ret := reg;

        if clk_sync and reg.irq_delay /= 0
        then
            ret.irq_delay := reg.irq_delay - 1;
            if reg.irq_delay = 1
            then
                ret.irq := true;
            end if;
        end if;

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
                    ret.irq_count := invert(reg.irq_reload, irq_count_t'high);
                else
                    ret.irq_count := reg.irq_count - 1;
                end if;

                if ret.irq_count = 0 and reg.irq_enable
                then
                    ret.irq_delay := TC0690_IRQ_DELAY;
                end if;
            end if;
        end if;

        return ret;
    end;

    -- The IRQ counter of the X1-017 counts CPU cycles down to 0 while bit 0
    -- of 0x7EFE is set and bit 2 clear, and stays there. Reaching 0 raises
    -- the IRQ, which is held until 0x7EFF is written and drives /IRQ while
    -- bit 1 of 0x7EFE is set, so toggling bit 1 can raise it again
    function cycle_x1_017_irq
    (
        reg      : mapper_taito_reg_t;
        clk_sync : boolean
    )
    return mapper_taito_reg_t
    is
        variable ret : mapper_taito_reg_t;
    begin
        ret := reg;

        if clk_sync and reg.irq_counting and reg.irq_running
        then
            if reg.irq_prescaler /= 0
            then
                ret.irq_prescaler := reg.irq_prescaler - 1;
            elsif reg.irq_count /= 0
            then
                ret.irq_prescaler := X1_017_PRESCALE - 1;
                ret.irq_count := reg.irq_count - 1;
            else
                ret.irq_running := false;
                ret.irq := true;
            end if;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_taito_reg_t;
        board  : taito_board_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
    begin
        case window is
            when "11" =>
                return x"FF";
            when "10" =>
                if is_tc0x90(board)
                then
                    return x"FE";
                else
                    return reg.prg_banks(2);
                end if;
            when others =>
                return reg.prg_banks(to_integer(window));
        end case;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_taito_reg_t;
        board  : taito_board_t;
        window : chr_window_t
    )
    return chr_bank_1kb_t
    is
        variable swapped : chr_window_t;
        variable bank : bank_t;
    begin
        swapped := window;
        if reg.chr_invert
        then
            swapped(2) := not window(2);
        end if;

        if swapped(2) = '1'
        then
            return resize(reg.chr_banks(to_integer(swapped(1 downto 0)) + 2),
                          chr_bank_1kb_t'length);
        end if;

        -- The 2KB banks are numbered in 2KB units on the TC0190 and TC0690.
        -- The X1 chips ignore bit 0 of the register
        bank := reg.chr_banks(to_integer(swapped(1 downto 1)));
        if is_tc0x90(board)
        then
            return resize(bank & swapped(0), chr_bank_1kb_t'length);
        else
            bank(0) := swapped(0);
            return resize(bank, chr_bank_1kb_t'length);
        end if;
    end;

    -- The RAM of the X1 chips is enabled at the CPU address
    function is_ram_enabled
    (
        reg     : mapper_taito_reg_t;
        board   : taito_board_t;
        cart_in : cart_in_t
    )
    return boolean
    is
        variable addr : prg_addr_t;
    begin
        addr := cart_in.cpu.prg_bus.address;

        if is_x1_017(board)
        then
            -- 0x6000-0x67FF, 0x6800-0x6FFF and 0x7000-0x73FF
            case addr(12 downto 10) is
                when "000" | "001" => return reg.ram_enable(0);
                when "010" | "011" => return reg.ram_enable(1);
                when "100" => return reg.ram_enable(2);
                when others => return false;
            end case;
        elsif is_x1_005(board)
        then
            -- 0x7F00-0x7FFF
            return reg.ram_enable(0) and addr(12 downto 8) = "11111";
        else
            return false;
        end if;
    end;

    function get_mirror
    (
        reg   : mapper_taito_reg_t;
        board : taito_board_t
    )
    return mirror_t
    is
    begin
        if reg.mirroring = is_tc0x90(board)
        then
            return MIRROR_HORZ;
        else
            return MIRROR_VERT;
        end if;
    end;

    function cycle_mapper_taito
    (
        reg      : mapper_taito_reg_t;
        board    : taito_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_taito_out_t
    is
        variable ret : mapper_taito_out_t;
        variable banks : cart_banks_t;
    begin
        -- The X1-017 clocks its counter before the write of the CPU cycle,
        -- so a write to it is not undone by the clock; the TC0690 after it,
        -- as the MMC3 does
        ret.reg := reg;
        if is_x1_017(board)
        then
            ret.reg := cycle_x1_017_irq(ret.reg, clk_sync);
        end if;
        if is_tc0x90(board)
        then
            ret.reg := cycle_tc0x90_write(ret.reg, board, clk_sync, cart_in);
        else
            ret.reg := cycle_x1_write(ret.reg, board, clk_sync, cart_in);
        end if;
        if board = TAITO_TC0690
        then
            ret.reg := cycle_tc0690_irq(ret.reg, clk_sync, cart_in);
        end if;

        -- The PPU sees the registers written by the CPU this cycle. The CPU
        -- does not: a register write is not a read of PRG ROM, and none of
        -- the registers are in the RAM. Not forwarding the write keeps the
        -- CPU data bus out of the PRG ROM address
        banks := default_banks(config);
        banks.prg_ram := is_ram_enabled(reg, board, cart_in);
        banks.prg := get_prg_bank(reg,
                                  board,
                                  get_prg_window(cart_in.cpu));
        banks.chr := get_chr_bank(ret.reg,
                                  board,
                                  get_chr_window(cart_in.ppu));
        -- On 207 CHR A17 drives CIRAM A10 instead, so the nametables at
        -- 0x2000 and 0x2400 have the CIRAM page of the first 2KB CHR bank,
        -- and those at 0x2800 and 0x2C00 that of the second, as their
        -- addresses select those banks
        if board = TAITO_X1_005_CIRAM
        then
            banks.mirror := get_single_screen_mirror(banks.chr(7));
            banks.chr(7) := '0';
        else
            banks.mirror := get_mirror(ret.reg, board);
        end if;

        ret.cart := map_cart(config, cart_in, banks);

        -- The X1-005 does not see CPU A7, so its 128 bytes of RAM are
        -- mirrored at 0x7F80
        if is_x1_005(board)
        then
            ret.cart.mem.prg_ram_bus.address(prg_ram_addr_t'high downto 7) :=
                (others => '0');
        end if;

        -- The pull-downs of the X1-017 read 0 where nothing drives the bus
        if is_x1_017(board) and
           is_prg_ram_window(cart_in.cpu) and
           is_bus_read(cart_in.cpu.prg_bus) and
           not banks.prg_ram
        then
            ret.cart.cpu.data := x"00";
            ret.cart.cpu.data_oe := true;
        end if;

        -- The delayed IRQ of the TC0690 is raised even if IRQs were disabled
        -- in the meantime
        if board = TAITO_TC0690
        then
            ret.cart.cpu.irq := reg.irq;
        else
            ret.cart.cpu.irq := reg.irq and reg.irq_enable;
        end if;

        return ret;
    end;

end package body;
