library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_002 is

    subtype bank_t is unsigned(3 downto 0);
    subtype prg_rom_addr_t is unsigned(17 downto 0);

    type mapper_002_reg_t is record
        bank : bank_t;
    end record;

    constant RESET_MAPPER_002_REG : mapper_002_reg_t :=
    (
        bank => (others => '0')
    );

    type mapper_002_out_t is record
        reg  : mapper_002_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_002
    (
        reg      : mapper_002_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_002_out_t;

    function get_cpu_prg_addr
    (
        addr_in : prg_addr_t;
        bank    : bank_t
    )
    return prg_rom_addr_t;

end package lib_mapper_002;


package body lib_mapper_002 is

    function get_cpu_prg_addr
    (
        addr_in : prg_addr_t;
        bank    : bank_t
    )
    return prg_rom_addr_t
    is
        variable ret : prg_rom_addr_t;
        variable bank_addr : unsigned(prg_addr_t'range);
    begin
        bank_addr := unsigned(addr_in);
        ret := bank & bank_addr(13 downto 0);

        return ret;
    end;

    function cycle_mapper_002
    (
        reg      : mapper_002_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_002_out_t
    is
        variable ret : mapper_002_out_t;
        variable prg_address : prg_rom_addr_t;
        variable bank : bank_t;
    begin
        ret.reg := reg;
        ret.cart := CART_OUT_IDLE;

        if is_bus_active(cart_in.cpu.prg_bus) and cart_in.cpu.romsel
        then
            if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
            then
                if config.prg_rom_16kb_blocks > x"08"
                then
                    ret.reg.bank := unsigned(cart_in.cpu.data(3 downto 0));
                else
                    ret.reg.bank :=
                        '0' & unsigned(cart_in.cpu.data(2 downto 0));
                end if;
            elsif is_bus_read(cart_in.cpu.prg_bus)
            then
                if cart_in.cpu.prg_bus.address(14) = '0'
                then
                    -- $8000-$BFFF
                    bank := reg.bank;
                else
                    -- $C000-$FFFF
                    bank := config.prg_rom_16kb_blocks(bank_t'range) - "1";
                end if;

                prg_address :=
                    get_cpu_prg_addr(cart_in.cpu.prg_bus.address, bank);
                ret.cart := map_prg_rom(cart_in, prg_address, ret.cart);
            end if;
        end if;

        if is_bus_active(cart_in.ppu.chr_bus)
        then
            if cart_in.ppu.chr_bus.address(13) = '0'
            then
                ret.cart := map_chr(config,
                                    cart_in,
                                    unsigned(cart_in.ppu.chr_bus.address(12 downto 0)),
                                    ret.cart);
            else
                ret.cart := map_ciram(cart_in, config.mirror, ret.cart);
            end if;
        end if;

        return ret;
    end;

end package body;
