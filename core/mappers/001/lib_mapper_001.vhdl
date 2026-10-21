library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_001 is

    subtype shift_t is unsigned(3 downto 0);
    constant SHIFT_MAX : shift_t := to_unsigned(4, shift_t'length);

    subtype prg_bank_t is unsigned(3 downto 0);

    subtype chr_bank_t is unsigned(4 downto 0);

    type mapper_001_reg_t is record
        shift : unsigned(3 downto 0);
        count : unsigned(2 downto 0);

        mirroring : unsigned(1 downto 0);
        prg_bank_mode : unsigned(1 downto 0);
        chr_bank_mode : std_logic;

        chr_bank_0 : chr_bank_t;
        chr_bank_1 : chr_bank_t;

        prg_bank : prg_bank_t;
        bypass   : std_logic;

        -- The CPU wrote on the previous cycle. Writes on consecutive cycles
        -- after the first are ignored
        write_prev : boolean;
    end record;

    constant RESET_MAPPER_001_REG : mapper_001_reg_t :=
    (
        shift => (others => '0'),
        count => (others => '0'),

        mirroring => (others => '0'),
        prg_bank_mode => (others => '1'),
        chr_bank_mode => '0',

        chr_bank_0 => (others => '0'),
        chr_bank_1 => (others => '0'),

        prg_bank => (others => '0'),
        bypass => '0',

        write_prev => false
    );

    type mapper_001_out_t is record
        reg  : mapper_001_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_001
    (
        reg      : mapper_001_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_001_out_t;

end package lib_mapper_001;


package body lib_mapper_001 is

    function cycle_write
    (
        reg      : mapper_001_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_001_reg_t
    is
        variable ret : mapper_001_reg_t;
        variable first_write : boolean;
        variable reg_val : unsigned(4 downto 0);
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
                ret.count := (others => '0');
                ret.shift := (others => '0');
                ret.prg_bank_mode := (others => '1');
            elsif first_write and reg.count < SHIFT_MAX
            then
                ret.shift := cart_in.cpu.data(0) & reg.shift(3 downto 1);
                ret.count := reg.count + "1";
            elsif first_write
            then
                ret.shift := (others => '0');
                ret.count := (others => '0');
                reg_val := cart_in.cpu.data(0) & reg.shift;

                case cart_in.cpu.prg_bus.address(14 downto 13) is
                    when "00" =>
                        ret.mirroring := reg_val(1 downto 0);
                        ret.prg_bank_mode := reg_val(3 downto 2);
                        ret.chr_bank_mode := reg_val(4);
                    when "01" =>
                        ret.chr_bank_0 := reg_val;
                    when "10" =>
                        ret.chr_bank_1 := reg_val;
                    when "11" =>
                        ret.prg_bank := reg_val(3 downto 0);
                        ret.bypass := reg_val(4);
                    when others =>
                        null;
                end case;
            end if;
        end if;

        return ret;
    end;

    -- The 16KB PRG ROM bank at 0x8000 or 0xC000
    function get_prg_bank
    (
        reg    : mapper_001_reg_t;
        high   : std_logic
    )
    return prg_bank_t
    is
        variable bank : prg_bank_t;
    begin
        case reg.prg_bank_mode is
            -- 32KB
            when "00" | "01" =>
                bank := reg.prg_bank;
                bank(0) := high;
            -- 0x8000 is fixed to the first bank
            when "10" =>
                if high = '0'
                then
                    bank := (others => '0');
                else
                    bank := reg.prg_bank;
                end if;
            -- 0xC000 is fixed to the last bank
            when others =>
                if high = '0'
                then
                    bank := reg.prg_bank;
                else
                    bank := (others => '1');
                end if;
        end case;

        return bank;
    end;

    -- The 4KB CHR bank at 0x0000 or 0x1000
    function get_chr_bank
    (
        reg  : mapper_001_reg_t;
        high : std_logic
    )
    return chr_bank_t
    is
        variable bank : chr_bank_t;
    begin
        if reg.chr_bank_mode = '1'
        then
            if high = '0'
            then
                bank := reg.chr_bank_0;
            else
                bank := reg.chr_bank_1;
            end if;
        else
            -- 8KB
            bank := reg.chr_bank_0;
            bank(0) := high;
        end if;

        return bank;
    end;

    function get_mirror(reg : mapper_001_reg_t) return mirror_t
    is
    begin
        case reg.mirroring is
            when "00" =>
                return MIRROR_A;
            when "01" =>
                return MIRROR_B;
            when "10" =>
                return MIRROR_VERT;
            when others =>
                return MIRROR_HORZ;
        end case;
    end;

    function cycle_mapper_001
    (
        reg      : mapper_001_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_001_out_t
    is
        variable ret : mapper_001_out_t;
        variable banks : cart_banks_t;
        variable prg_window : prg_window_t;
        variable chr_window : chr_window_t;
    begin
        ret.reg := cycle_write(reg, clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle
        prg_window := get_prg_window(cart_in.cpu);
        chr_window := get_chr_window(cart_in.ppu);

        -- SUROM has 512KB of PRG ROM, and bit 4 of the CHR bank selects the
        -- 256KB half. In 4KB CHR mode the chip takes it from the CHR bank
        -- that PPU A12 selects, but the SUROM games use 8KB CHR mode, so
        -- CHR bank 0 is used. With a smaller PRG ROM, the bit is masked off
        banks.prg_ram := true;
        banks.prg := resize(ret.reg.chr_bank_0(4) &
                            get_prg_bank(ret.reg, prg_window(1)) &
                            prg_window(0),
                            prg_bank_8kb_t'length);
        banks.chr_ram := has_chr_ram(config);
        banks.chr := resize(get_chr_bank(ret.reg, chr_window(2)) &
                            chr_window(1 downto 0),
                            chr_bank_1kb_t'length);
        banks.mirror := get_mirror(ret.reg);

        ret.cart := map_cart(config, cart_in, banks);

        return ret;
    end;

end package body;
