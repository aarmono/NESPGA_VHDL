library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.cart_types.all;

-- Boards with 8KB PRG ROM banks, the last fixed at 0xE000, and registers at
-- 0x8000-0xFFFF selected by CPU A14-A12: the PRG banks of 0x8000 and 0xA000
-- at 0x8000 and 0xA000, and a control register at 0x9000. The board is
-- chosen by the mapper number at run time.
--
-- The Irem G-101 (32) and H3001 (65) have eight 1KB CHR ROM banks at
-- 0xB000-0xB007 (A2-A0), and a PRG mode that swaps the bank of 0x8000 with
-- the second last bank, fixed at 0xC000. The control register of the G-101
-- holds the PRG mode and mirroring; that of the H3001 is eight registers at
-- 0x9000-0x9007, for the PRG mode, mirroring and a 16-bit counter of CPU
-- cycles that counts down from a reload value to raise the IRQ at 0, and
-- stops there. Its register decode, PRG mode and one screen mirroring follow
-- nesdev and puNES: Mesen and Nestopia have neither, and a PRG bank register
-- at 0xC000.
--
-- The Konami VRC1 (75) has a third PRG bank register, at 0xC000 for 0xC000,
-- and two 4KB CHR ROM banks whose low 4 bits are at 0xE000 and 0xF000 and
-- high bits in the control register, with the mirroring. A four-screen board
-- (the Vs. System games) ignores the mirroring bit.
--
-- To add a board, add it to irem_board_t, get_irem_board and its mapper
-- number to is_irem_mapper
package lib_mapper_irem is

    type irem_board_t is
    (
        G101,
        -- G-101 of Major League (NES 2.0 submapper 1), with CIRAM A10 tied
        -- high and the control register not connected
        G101_1_SCREEN,
        H3001,
        VRC1
    );

    -- The mapper number is that of a board in the family
    function is_irem_mapper(mapper_num : mapper_num_t) return boolean;

    function get_irem_board(config : cart_config_t) return irem_board_t;

    -- The PRG ROM banks at 0x8000, 0xA000 and 0xC000, or 0xC000 and 0x8000
    -- for the first and last with the PRG mode set. Only the VRC1 writes the
    -- last, which is the second last bank on the other boards
    type prg_bank_arr_t is array(0 to 2) of prg_bank_8kb_t;
    -- The 1KB CHR banks. The 4KB CHR banks of the VRC1 are in the first of
    -- each half, as 1KB banks: shifted left by 2
    subtype chr_bank_t is unsigned(7 downto 0);
    type chr_bank_arr_t is array(0 to 7) of chr_bank_t;

    subtype irq_count_t is natural range 0 to 16#FFFF#;

    type mapper_irem_reg_t is record
        prg_banks : prg_bank_arr_t;
        -- The bank of the first PRG register is at 0xC000 and the second
        -- last bank at 0x8000
        prg_swap  : boolean;
        chr_banks : chr_bank_arr_t;
        -- The mirroring, as bits 7-6 of 0x9001 of the H3001. The mirroring
        -- bit of the G-101 and VRC1 is in bit 1
        mirror    : std_logic_vector(1 downto 0);

        -- H3001
        irq_reload : irq_count_t;
        irq_count  : irq_count_t;
        irq_enable : boolean;
        irq        : boolean;
    end record;

    -- The power on state is not known. The H3001 games need the banks at
    -- 0x8000 and 0xA000 to be 0 and 1 (nesdev)
    constant RESET_MAPPER_IREM_REG : mapper_irem_reg_t :=
    (
        prg_banks => (x"00", x"01", x"FE"),
        prg_swap => false,
        chr_banks => (others => (others => '0')),
        mirror => "00",

        irq_reload => 0,
        irq_count => 0,
        irq_enable => false,
        irq => false
    );

    type mapper_irem_out_t is record
        reg  : mapper_irem_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_irem
    (
        reg      : mapper_irem_reg_t;
        board    : irem_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_irem_out_t;

end package lib_mapper_irem;


package body lib_mapper_irem is

    function is_irem_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"020" | x"041" | x"04B" => return true;
            when others => return false;
        end case;
    end;

    function get_irem_board(config : cart_config_t) return irem_board_t
    is
    begin
        case config.mapper_num is
            when x"041" =>
                return H3001;
            when x"04B" =>
                return VRC1;
            when others =>
                if config.submapper_num = x"1"
                then
                    return G101_1_SCREEN;
                else
                    return G101;
                end if;
        end case;
    end;

    -- The mirroring of bits 7-6 of 0x9001 of the H3001: vertical for 0,
    -- horizontal for 2 and one screen A otherwise
    function get_h3001_mirror(mode : std_logic_vector(1 downto 0))
        return mirror_t
    is
    begin
        if mode(0) = '1'
        then
            return MIRROR_A;
        else
            return get_hv_mirror(mode(1));
        end if;
    end;

    -- The control register of the H3001, by CPU A2-A0
    function cycle_h3001_write
    (
        reg  : mapper_irem_reg_t;
        addr : prg_addr_t;
        data : data_t
    )
    return mapper_irem_reg_t
    is
        variable ret : mapper_irem_reg_t;
    begin
        ret := reg;

        case addr(2 downto 0) is
            when "000" =>
                ret.prg_swap := data(7) = '1';
            when "001" =>
                ret.mirror := data(7 downto 6);
            when "011" =>
                ret.irq_enable := data(7) = '1';
                ret.irq := false;
            when "100" =>
                ret.irq_count := reg.irq_reload;
                ret.irq := false;
            when "101" =>
                ret.irq_reload := set_bits(reg.irq_reload, 8, data);
            when "110" =>
                ret.irq_reload := set_bits(reg.irq_reload, 0, data);
            when others =>
        end case;

        return ret;
    end;

    -- The registers are selected by CPU A14-A12
    function cycle_write
    (
        reg      : mapper_irem_reg_t;
        board    : irem_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_irem_reg_t
    is
        variable ret : mapper_irem_reg_t;
        variable addr : prg_addr_t;
        variable data : data_t;
        variable prg_bank : prg_bank_8kb_t;
    begin
        ret := reg;
        addr := cart_in.cpu.prg_bus.address;
        data := cart_in.cpu.data;

        if not is_rom_write(cart_in.cpu, clk_sync)
        then
            return ret;
        end if;

        -- The width of the PRG bank registers
        prg_bank := unsigned(data);
        case board is
            when G101 | G101_1_SCREEN =>
                prg_bank(7 downto 5) := "000";
            when VRC1 =>
                prg_bank(7 downto 4) := x"0";
            when H3001 =>
        end case;

        case addr(14 downto 12) is
            -- 0x8000
            when "000" =>
                ret.prg_banks(0) := prg_bank;
            -- 0x9000
            when "001" =>
                case board is
                    when G101 =>
                        ret.prg_swap := data(1) = '1';
                        ret.mirror := data(0) & '0';
                    when G101_1_SCREEN =>
                    when H3001 =>
                        ret := cycle_h3001_write(ret, addr, data);
                    when VRC1 =>
                        ret.mirror := data(0) & '0';
                        ret.chr_banks(0)(6) := data(1);
                        ret.chr_banks(4)(6) := data(2);
                end case;
            -- 0xA000
            when "010" =>
                ret.prg_banks(1) := prg_bank;
            -- 0xB000
            when "011" =>
                if board /= VRC1
                then
                    ret.chr_banks(to_integer(addr(2 downto 0))) :=
                        unsigned(data);
                end if;
            -- 0xC000
            when "100" =>
                if board = VRC1
                then
                    ret.prg_banks(2) := prg_bank;
                end if;
            -- 0xE000 and 0xF000
            when "110" | "111" =>
                if board = VRC1
                then
                    ret.chr_banks(4 * to_integer(addr(12 downto 12)))(
                        5 downto 2) := unsigned(data(3 downto 0));
                end if;
            when others =>
        end case;

        return ret;
    end;

    -- The counter of the H3001 counts down to 0 while enabled. Reaching 0
    -- raises the IRQ and disables it, as in Mesen, Nestopia and puNES
    function cycle_h3001_irq
    (
        reg      : mapper_irem_reg_t;
        clk_sync : boolean
    )
    return mapper_irem_reg_t
    is
        variable ret : mapper_irem_reg_t;
    begin
        ret := reg;

        if clk_sync and reg.irq_enable and reg.irq_count /= 0
        then
            ret.irq_count := reg.irq_count - 1;
            if reg.irq_count = 1
            then
                ret.irq_enable := false;
                ret.irq := true;
            end if;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_irem_reg_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
    begin
        case window is
            when "11" =>
                return x"FF";
            when "01" =>
                return reg.prg_banks(1);
            when "10" =>
                if reg.prg_swap
                then
                    return reg.prg_banks(0);
                else
                    return reg.prg_banks(2);
                end if;
            when others =>
                if reg.prg_swap
                then
                    return reg.prg_banks(2);
                else
                    return reg.prg_banks(0);
                end if;
        end case;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_irem_reg_t;
        board  : irem_board_t;
        window : chr_window_t
    )
    return chr_bank_1kb_t
    is
        variable idx  : chr_window_t;
        variable bank : chr_bank_t;
    begin
        idx := window;
        if board = VRC1
        then
            idx(1 downto 0) := "00";
        end if;
        bank := reg.chr_banks(to_integer(std_logic_vector(idx)));
        if board = VRC1
        then
            bank(1 downto 0) := window(1 downto 0);
        end if;

        return resize(bank, chr_bank_1kb_t'length);
    end;

    function cycle_mapper_irem
    (
        reg      : mapper_irem_reg_t;
        board    : irem_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_irem_out_t
    is
        variable ret : mapper_irem_out_t;
        variable banks : cart_banks_t;
    begin
        -- The counter is clocked before the write of the CPU cycle, so a
        -- write to it is not undone by the clock
        ret.reg := reg;
        if board = H3001
        then
            ret.reg := cycle_h3001_irq(ret.reg, clk_sync);
        end if;
        ret.reg := cycle_write(ret.reg, board, clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle. The CPU
        -- does not: a register write is not a read of PRG ROM, and not
        -- forwarding it keeps the CPU data bus out of the PRG ROM address
        banks := default_banks(config);
        banks.prg := get_prg_bank(reg, get_prg_window(cart_in.cpu));
        banks.chr := get_chr_bank(ret.reg,
                                  board,
                                  get_chr_window(cart_in.ppu));
        -- A four-screen board keeps the mirroring of the header
        if board = G101_1_SCREEN
        then
            banks.mirror := MIRROR_B;
        elsif config.mirror /= MIRROR_FOUR
        then
            banks.mirror := get_h3001_mirror(ret.reg.mirror);
        end if;

        ret.cart := map_cart(config, cart_in, banks);

        ret.cart.cpu.irq := reg.irq;

        return ret;
    end;

end package body;
