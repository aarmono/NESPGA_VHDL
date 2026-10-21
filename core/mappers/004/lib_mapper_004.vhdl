library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_004 is

    subtype bank_idx_t is unsigned(2 downto 0);

    subtype bank_t is unsigned(7 downto 0);
    type bank_arr_t is array(0 to 7) of bank_t;

    subtype irq_count_t is natural range 0 to 2**8-1;

    subtype prg_rom_addr_t is unsigned(18 downto 0);
    subtype chr_rom_addr_t is unsigned(17 downto 0);

    subtype irq_delay_t is boolean_array(1 downto 0);

    constant A12_MAX : natural := 10;
    subtype a12_count_t is natural range 0 to A12_MAX;

    type mapper_004_reg_t is record
        bank_idx : bank_idx_t;

        banks : bank_arr_t;

        chr_mode : std_logic;
        prg_mode : std_logic;

        mirroring : std_logic;

        irq_count  : irq_count_t;
        irq_reload : irq_count_t;
        irq_enable : boolean;
        irq        : boolean;
        irq_delay  : irq_delay_t;

        a12_count : a12_count_t;
    end record;

    constant RESET_MAPPER_004_REG : mapper_004_reg_t :=
    (
        bank_idx => (others => '0'),

        banks => (others => (others => '0')),

        chr_mode => '0',
        prg_mode => '0',

        mirroring => '0',

        irq_count => 0,
        irq_reload => 0,
        irq_enable => false,
        irq => false,
        irq_delay => (others => false),

        a12_count => 0
    );

    type mapper_004_out_t is record
        reg  : mapper_004_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_004
    (
        reg      : mapper_004_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_004_out_t;

    function get_cpu_prg_addr
    (
        addr_in   : prg_addr_t;
        bank      : bank_t;
        num_banks : bank_t
    )
    return prg_rom_addr_t;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : bank_t;
        num_banks : bank_t
    )
    return chr_rom_addr_t;

end package lib_mapper_004;


package body lib_mapper_004 is

    function get_cpu_prg_addr
    (
        addr_in   : prg_addr_t;
        bank      : bank_t;
        num_banks : bank_t
    )
    return prg_rom_addr_t
    is
        variable ret : prg_rom_addr_t;
        variable bank_addr : unsigned(prg_addr_t'range);
        variable mod_bank : bank_t;
    begin
        mod_bank := bank and (num_banks - "1");

        bank_addr := unsigned(addr_in);
        ret := mod_bank(5 downto 0) & bank_addr(12 downto 0);

        return ret;
    end;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : bank_t;
        num_banks : bank_t
    )
    return chr_rom_addr_t
    is
        variable ret : chr_rom_addr_t;
        variable bank_addr : unsigned(chr_addr_t'range);
        variable mod_bank : bank_t;
    begin
        mod_bank := bank and (num_banks - "1");

        bank_addr := unsigned(addr_in);
        ret := mod_bank & bank_addr(9 downto 0);

        return ret;
    end;

    -- The PRG ROM bank mapped at the 8KB window of the CPU address
    function get_prg_bank
    (
        reg      : mapper_004_reg_t;
        addr_in  : prg_addr_t;
        max_bank : bank_t
    )
    return bank_t
    is
        variable bank : bank_t;
    begin
        case addr_in(14 downto 13) is
            -- $8000-$9FFF
            when "00" =>
                if reg.prg_mode = '0'
                then
                    bank := reg.banks(6);
                else
                    bank := max_bank - "1";
                end if;
            -- $A000-$BFFF
            when "01" =>
                bank := reg.banks(7);
            -- $C000-$DFFF
            when "10" =>
                if reg.prg_mode = '0'
                then
                    bank := max_bank - "1";
                else
                    bank := reg.banks(6);
                end if;
            -- $E000-$FFFF is hardcoded to the last bank
            when others =>
                bank := max_bank;
        end case;

        return bank;
    end;

    -- The CHR ROM bank mapped at the 1KB window of the PPU address
    function get_chr_bank
    (
        reg     : mapper_004_reg_t;
        addr_in : chr_addr_t
    )
    return bank_t
    is
        variable bank : bank_t;
        variable window : std_logic_vector(2 downto 0);
    begin
        -- CHR mode 1 swaps the 2KB and 1KB banks between $0000 and $1000
        window := addr_in(12 downto 10);
        window(2) := window(2) xor reg.chr_mode;

        case window is
            when "000" | "001" =>
                bank := reg.banks(0);
                bank(0) := window(0);
            when "010" | "011" =>
                bank := reg.banks(1);
                bank(0) := window(0);
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

    function cycle_cpu
    (
        reg      : mapper_004_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        map_in   : mapper_004_out_t
    )
    return mapper_004_out_t
    is
        variable map_out : mapper_004_out_t;

        variable prg_address : prg_rom_addr_t;

        variable num_banks : rom_blocks_t;
    begin
        map_out := map_in;

        case get_cpu_addr(cart_in.cpu) is
            when 16#6000# to 16#7FFF# =>
                map_out.cart := map_prg_ram(cart_in, map_out.cart);
            when 16#8000# to 16#FFFF# =>
                if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
                then
                    case cart_in.cpu.prg_bus.address(14 downto 13) is
                        -- $8000-$9FFF
                        when "00" =>
                            if cart_in.cpu.prg_bus.address(0) = '0'
                            then
                                map_out.reg.bank_idx :=
                                    unsigned(cart_in.cpu.data(2 downto 0));
                                map_out.reg.chr_mode := cart_in.cpu.data(7);
                                map_out.reg.prg_mode := cart_in.cpu.data(6);
                            else
                                map_out.reg.banks(to_integer(reg.bank_idx)) :=
                                    unsigned(cart_in.cpu.data);
                            end if;
                        -- $A000-$BFFF
                        when "01" =>
                            if cart_in.cpu.prg_bus.address(0) = '0'
                            then
                                map_out.reg.mirroring := cart_in.cpu.data(0);
                            end if;
                        -- $C000-$DFFF
                        when "10" =>
                            if cart_in.cpu.prg_bus.address(0) = '0'
                            then
                                map_out.reg.irq_reload :=
                                    to_integer(unsigned(cart_in.cpu.data));
                            else
                                map_out.reg.irq_count := 0;
                            end if;
                        -- $E000-$FFFF
                        when others =>
                            map_out.reg.irq_enable :=
                                cart_in.cpu.prg_bus.address(0) = '1';

                            if cart_in.cpu.prg_bus.address(0) = '0'
                            then
                                map_out.reg.irq := false;
                            end if;
                    end case;
                elsif is_bus_read(cart_in.cpu.prg_bus)
                then
                    num_banks := shift_left(config.prg_rom_16kb_blocks, 1);

                    prg_address :=
                        get_cpu_prg_addr(cart_in.cpu.prg_bus.address,
                                         get_prg_bank(reg,
                                                      cart_in.cpu.prg_bus.address,
                                                      num_banks - "1"),
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
        reg     : mapper_004_reg_t;
        config  : cart_config_t;
        cart_in : cart_in_t;
        map_in  : mapper_004_out_t
    )
    return mapper_004_out_t
    is
        variable map_out : mapper_004_out_t;

        variable address : chr_rom_addr_t;

        variable mirror : mirror_t;

        variable num_banks : bank_t;
    begin
        map_out := map_in;

        if not is_bus_active(cart_in.ppu.chr_bus) or
           cart_in.ppu.chr_bus.address(12) = '0'
        then
            if reg.a12_count < A12_MAX
            then
                map_out.reg.a12_count := reg.a12_count + 1;
            end if;
        else
            map_out.reg.a12_count := 0;
            if reg.a12_count = A12_MAX
            then
                if reg.irq_count = 0
                then
                    map_out.reg.irq_count := reg.irq_reload;
                else
                    map_out.reg.irq_count := reg.irq_count - 1;
                end if;

                if map_out.reg.irq_count = 0
                then
                    map_out.reg.irq := reg.irq_enable;
                end if;
            end if;
        end if;

        -- IRQ needs to be delayed, but acknowledging it clears it immediately
        if map_out.reg.irq
        then
            map_out.reg.irq_delay := shift_left(reg.irq_delay, true);
        else
            map_out.reg.irq_delay := (others => false);
        end if;

        map_out.cart.cpu.irq := map_out.reg.irq and
                                reg.irq_delay(reg.irq_delay'high);

        if config.mirror = MIRROR_FOUR
        then
            mirror := config.mirror;
        elsif reg.mirroring = '1'
        then
            mirror := MIRROR_HORZ;
        else
            mirror := MIRROR_VERT;
        end if;

        if is_bus_active(cart_in.ppu.chr_bus)
        then
            if cart_in.ppu.chr_bus.address(13) = '0'
            then
                num_banks := shift_left(config.chr_rom_8kb_blocks, 3);

                address :=
                    get_ppu_chr_addr(cart_in.ppu.chr_bus.address,
                                     get_chr_bank(reg,
                                                  cart_in.ppu.chr_bus.address),
                                     num_banks);
                map_out.cart := map_chr(config, cart_in, address, map_out.cart);
            else
                map_out.cart := map_ciram(cart_in, mirror, map_out.cart);
            end if;
        end if;

        return map_out;
    end;

    function cycle_mapper_004
    (
        reg      : mapper_004_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_004_out_t
    is
        variable ret : mapper_004_out_t;
    begin
        ret.reg := reg;
        ret.cart := CART_OUT_IDLE;

        if is_bus_active(cart_in.cpu.prg_bus)
        then
            ret := cycle_cpu(reg, config, clk_sync, cart_in, ret);
        end if;

        -- The PPU sees the registers written by the CPU this cycle
        ret := cycle_ppu(ret.reg, config, cart_in, ret);

        return ret;
    end;

end package body;
