library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.prg_bus_types.all;
use work.chr_ram_bus_types.all;
use work.cart_types.all;

-- The Action 53 multicart board (28), which can act as NROM, CNROM, UNROM,
-- BNROM or AOROM for each game. The CPU writes a register number to
-- 0x5000-0x5FFF and the register to 0x8000-0xFFFF: the CHR RAM bank (0x00)
-- and the bank within the game (0x01), which the game changes, and the mode
-- (0x80) and the bank of the game in PRG ROM (0x81), which the menu sets.
-- There is 32KB of CHR RAM and no PRG RAM.
--
-- The outer bank has 8 bits, for 8MB of PRG ROM, of which the low 6 bits
-- (2MB) are used here
package lib_mapper_action53 is

    -- The mapper number is that of the Action 53 board
    function is_action53_mapper(mapper_num : mapper_num_t) return boolean;

    -- The mask of the CHR RAM address when the header is iNES, which gives
    -- no size
    constant ACTION53_INES_CHR_RAM_MASK : chr_ram_addr_t := x"7FFF";

    type action53_reg_select_t is
    (
        REG_CHR,
        REG_INNER,
        REG_MODE,
        REG_OUTER
    );

    type action53_prg_mode_t is
    (
        -- A 32KB bank at 0x8000
        PRG_32KB,
        -- The bottom half of the outer bank at 0x8000 and a 16KB bank at
        -- 0xC000, like mapper 180
        PRG_FIXED_8000,
        -- A 16KB bank at 0x8000 and the top half of the outer bank at
        -- 0xC000, like UNROM
        PRG_FIXED_C000
    );

    subtype action53_chr_bank_t is unsigned(1 downto 0);
    subtype action53_inner_bank_t is unsigned(3 downto 0);
    subtype action53_outer_bank_t is unsigned(7 downto 0);

    type mapper_action53_reg_t is record
        reg_select : action53_reg_select_t;
        chr_bank   : action53_chr_bank_t;
        inner_bank : action53_inner_bank_t;
        outer_bank : action53_outer_bank_t;
        prg_mode   : action53_prg_mode_t;
        -- The bits of the 16KB bank that come from the inner bank in the
        -- 16KB modes, from the size of the game: one bit for 32KB up to
        -- four for 256KB. In the 32KB mode the lowest of them is CPU A14
        inner_mask : action53_inner_bank_t;
        mirror     : mirror_t;
    end record;

    -- The power on state is not given, except that 0xC000 holds the last
    -- 16KB of PRG ROM. The outer bank of all ones does that in the 32KB
    -- mode
    constant RESET_MAPPER_ACTION53_REG : mapper_action53_reg_t :=
    (
        reg_select => REG_CHR,
        chr_bank => (others => '0'),
        inner_bank => (others => '0'),
        outer_bank => (others => '1'),
        prg_mode => PRG_32KB,
        inner_mask => "0001",
        mirror => MIRROR_A
    );

    type mapper_action53_out_t is record
        reg  : mapper_action53_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_action53
    (
        reg      : mapper_action53_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_action53_out_t;

end package lib_mapper_action53;


package body lib_mapper_action53 is

    function is_action53_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        return mapper_num = x"01C";
    end;

    -- The mirroring of modes 0 to 3: one screen A or B, vertical or
    -- horizontal
    function get_action53_mirror(mode : std_logic_vector(1 downto 0))
    return mirror_t
    is
    begin
        if mode(1) = '0'
        then
            return get_single_screen_mirror(mode(0));
        else
            return get_hv_mirror(mode(0));
        end if;
    end;

    function write_mode
    (
        reg  : mapper_action53_reg_t;
        data : data_t
    )
    return mapper_action53_reg_t
    is
        variable ret : mapper_action53_reg_t;
    begin
        ret := reg;

        ret.mirror := get_action53_mirror(data(1 downto 0));

        if data(3) = '0'
        then
            ret.prg_mode := PRG_32KB;
        elsif data(2) = '0'
        then
            ret.prg_mode := PRG_FIXED_8000;
        else
            ret.prg_mode := PRG_FIXED_C000;
        end if;

        case data(5 downto 4) is
            when "00" => ret.inner_mask := "0001";
            when "01" => ret.inner_mask := "0011";
            when "10" => ret.inner_mask := "0111";
            when others => ret.inner_mask := "1111";
        end case;

        return ret;
    end;

    function cycle_write
    (
        reg      : mapper_action53_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_action53_reg_t
    is
        variable ret : mapper_action53_reg_t;
        variable data : data_t;
        variable reg_select : std_logic_vector(1 downto 0);
    begin
        ret := reg;
        data := cart_in.cpu.data;
        reg_select := data(7) & data(0);

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            case reg.reg_select is
                when REG_CHR =>
                    ret.chr_bank := unsigned(data(1 downto 0));
                when REG_INNER =>
                    ret.inner_bank := unsigned(data(3 downto 0));
                when REG_MODE =>
                    ret := write_mode(reg, data);
                when REG_OUTER =>
                    ret.outer_bank := unsigned(data);
            end case;

            -- In the one screen modes D4 of the bank registers selects the
            -- screen, as on AOROM
            if (reg.reg_select = REG_CHR or reg.reg_select = REG_INNER) and
               (reg.mirror = MIRROR_A or reg.mirror = MIRROR_B)
            then
                ret.mirror := get_single_screen_mirror(data(4));
            end if;
        elsif is_bus_write(cart_in.cpu.prg_bus) and clk_sync and
              not cart_in.cpu.romsel and
              cart_in.cpu.prg_bus.address(14 downto 12) = "101"
        then
            case reg_select is
                when "00" => ret.reg_select := REG_CHR;
                when "01" => ret.reg_select := REG_INNER;
                when "10" => ret.reg_select := REG_MODE;
                when others => ret.reg_select := REG_OUTER;
            end case;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address. The bits of
    -- the 16KB bank are those of the outer bank with the low bits replaced
    -- by those of the inner bank, or, in the fixed half, by CPU A14 alone
    function get_prg_bank
    (
        reg    : mapper_action53_reg_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable bank : unsigned(8 downto 0);
        variable inner : action53_inner_bank_t;
        variable mask : action53_inner_bank_t;
    begin
        mask := reg.inner_mask;
        case reg.prg_mode is
            when PRG_32KB =>
                inner := reg.inner_bank(2 downto 0) & window(1);
            when PRG_FIXED_8000 | PRG_FIXED_C000 =>
                inner := reg.inner_bank;
                if (reg.prg_mode = PRG_FIXED_8000 and window(1) = '0') or
                   (reg.prg_mode = PRG_FIXED_C000 and window(1) = '1')
                then
                    inner(0) := window(1);
                    mask := "0001";
                end if;
        end case;

        bank := reg.outer_bank & '0';
        for i in mask'range
        loop
            if mask(i) = '1'
            then
                bank(i) := inner(i);
            end if;
        end loop;

        return resize(bank & window(0), prg_bank_8kb_t'length);
    end;

    function cycle_mapper_action53
    (
        reg      : mapper_action53_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_action53_out_t
    is
        variable ret : mapper_action53_out_t;
        variable banks : cart_banks_t;
    begin
        ret.reg := cycle_write(reg, clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle
        banks := default_banks(config);
        banks.prg := get_prg_bank(ret.reg, get_prg_window(cart_in.cpu));
        banks.chr := resize(ret.reg.chr_bank & get_chr_window(cart_in.ppu),
                            chr_bank_1kb_t'length);
        banks.mirror := ret.reg.mirror;

        ret.cart := map_cart(config, cart_in, banks);

        return ret;
    end;

end package body;
