library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_001 is

    subtype shift_t is unsigned(3 downto 0);
    constant SHIFT_MAX : shift_t := to_unsigned(4, shift_t'length);

    subtype prg_bank_t is unsigned(3 downto 0);
    subtype prg_rom_addr_t is unsigned(17 downto 0);

    subtype chr_bank_t is unsigned(4 downto 0);
    subtype chr_rom_addr_t is unsigned(16 downto 0);

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

    function get_cpu_prg_addr
    (
        addr_in   : prg_addr_t;
        bank      : prg_bank_t;
        num_banks : prg_bank_t
    )
    return prg_rom_addr_t;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : chr_bank_t;
        num_banks : chr_bank_t
    )
    return chr_rom_addr_t;

end package lib_mapper_001;


package body lib_mapper_001 is

    function get_cpu_prg_addr
    (
        addr_in   : prg_addr_t;
        bank      : prg_bank_t;
        num_banks : prg_bank_t
    )
    return prg_rom_addr_t
    is
        variable ret : prg_rom_addr_t;
        variable bank_addr : unsigned(prg_addr_t'range);
        variable mod_bank : prg_bank_t;
    begin
        mod_bank := bank and (num_banks - "1");

        bank_addr := unsigned(addr_in);
        ret := mod_bank & bank_addr(13 downto 0);

        return ret;
    end;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : chr_bank_t;
        num_banks : chr_bank_t
    )
    return chr_rom_addr_t
    is
        variable ret : chr_rom_addr_t;
        variable bank_addr : unsigned(chr_addr_t'range);
        variable mod_bank : chr_bank_t;
    begin
        mod_bank := bank and (num_banks - "1");

        bank_addr := unsigned(addr_in);
        ret := mod_bank & bank_addr(11 downto 0);

        return ret;
    end;

    function cycle_cpu
    (
        reg      : mapper_001_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        map_in   : mapper_001_out_t
    )
    return mapper_001_out_t
    is
        variable map_out : mapper_001_out_t;

        variable prg_address : prg_rom_addr_t;

        variable bank : prg_bank_t;

        variable num_banks : prg_bank_t;
        variable max_bank  : prg_bank_t;

        variable first_write : boolean;

        variable reg_val : unsigned(4 downto 0);
    begin
        map_out := map_in;

        num_banks := config.prg_rom_16kb_blocks(num_banks'range);
        max_bank := num_banks - "1";

        first_write := cart_in.cpu.prg_bus.write and not reg.write_prev;

        case get_cpu_addr(cart_in.cpu) is
            when 16#6000# to 16#7FFF# =>
                map_out.cart := map_prg_ram(cart_in, map_out.cart);
            when 16#8000# to 16#FFFF# =>
                if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
                then
                    if cart_in.cpu.data(7) = '1'
                    then
                        map_out.reg.count := (others => '0');
                        map_out.reg.shift := (others => '0');
                        map_out.reg.prg_bank_mode := (others => '1');
                    elsif first_write and reg.count < SHIFT_MAX
                    then
                        map_out.reg.shift := cart_in.cpu.data(0) &
                                             reg.shift(3 downto 1);
                        map_out.reg.count := reg.count + "1";
                    elsif first_write
                    then
                        map_out.reg.shift := (others => '0');
                        map_out.reg.count := (others => '0');
                        reg_val := cart_in.cpu.data(0) & reg.shift;

                        case cart_in.cpu.prg_bus.address(14 downto 13) is
                            when "00" =>
                                map_out.reg.mirroring := reg_val(1 downto 0);
                                map_out.reg.prg_bank_mode := reg_val(3 downto 2);
                                map_out.reg.chr_bank_mode := reg_val(4);
                            when "01" =>
                                map_out.reg.chr_bank_0 := reg_val;
                            when "10" =>
                                map_out.reg.chr_bank_1 := reg_val;
                            when "11" =>
                                map_out.reg.prg_bank := reg_val(3 downto 0);
                                map_out.reg.bypass := reg_val(4);
                            when others =>
                                null;
                        end case;
                    end if;
                elsif is_bus_read(cart_in.cpu.prg_bus)
                then
                    if cart_in.cpu.prg_bus.address(14) = '0'
                    then
                        -- $8000-$BFFF
                        case reg.prg_bank_mode is
                            when "00" |
                                 "01" =>
                                bank := reg.prg_bank;
                                bank(0) := '0';
                            when "10" =>
                                bank := (others => '0');
                            when "11" =>
                                bank := reg.prg_bank;
                            when others =>
                                null;
                        end case;
                    else
                        -- $C000-$FFFF
                        case reg.prg_bank_mode is
                            when "00" | "01" =>
                                bank := reg.prg_bank;
                                bank(0) := '1';
                            when "10" =>
                                bank := reg.prg_bank;
                            when "11" =>
                                bank := max_bank;
                            when others =>
                                null;
                        end case;
                    end if;

                    prg_address :=
                        get_cpu_prg_addr(cart_in.cpu.prg_bus.address,
                                         bank,
                                         num_banks);
                    map_out.cart := map_prg_rom(cart_in,
                                                prg_address,
                                                map_out.cart);
                end if;
            when others =>
                null;
        end case;

        return map_out;
    end;

    function cycle_ppu
    (
        reg     : mapper_001_reg_t;
        config  : cart_config_t;
        cart_in : cart_in_t;
        map_in  : mapper_001_out_t
    )
    return mapper_001_out_t
    is
        variable map_out : mapper_001_out_t;

        variable address : chr_rom_addr_t;

        variable mirror : mirror_t;

        variable bank : chr_bank_t;
        variable num_banks : chr_bank_t;
    begin
        map_out := map_in;

        num_banks :=
            shift_right(config.chr_rom_8kb_blocks, 1)(num_banks'range);

        case reg.mirroring is
            when "00" =>
                mirror := MIRROR_A;
            when "01" =>
                mirror := MIRROR_B;
            when "10" =>
                mirror := MIRROR_VERT;
            when "11" =>
                mirror := MIRROR_HORZ;
            when others =>
                mirror := MIRROR_HORZ;
        end case;

        if cart_in.ppu.chr_bus.address(13) = '0'
        then
            if cart_in.ppu.chr_bus.address(12) = '0'
            then
                -- $0000-$0FFF
                bank := reg.chr_bank_0;
                if reg.chr_bank_mode = '0'
                then
                    bank(0) := '0';
                end if;
            else
                -- $1000-$1FFF
                if reg.chr_bank_mode = '0'
                then
                    bank := reg.chr_bank_0;
                    bank(0) := '1';
                else
                    bank := reg.chr_bank_1;
                end if;
            end if;

            address := get_ppu_chr_addr(cart_in.ppu.chr_bus.address,
                                        bank,
                                        num_banks);
            map_out.cart := map_chr(config, cart_in, address, map_out.cart);
        else
            map_out.cart := map_ciram(cart_in, mirror, map_out.cart);
        end if;

        return map_out;
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
    begin
        ret.reg := reg;
        ret.cart := CART_OUT_IDLE;

        if clk_sync
        then
            ret.reg.write_prev := cart_in.cpu.prg_bus.write;
        end if;

        if is_bus_active(cart_in.cpu.prg_bus)
        then
            ret := cycle_cpu(reg, config, clk_sync, cart_in, ret);
        end if;

        -- The PPU sees the registers written by the CPU this cycle
        if is_bus_active(cart_in.ppu.chr_bus)
        then
            ret := cycle_ppu(ret.reg, config, cart_in, ret);
        end if;

        return ret;
    end;

end package body;
