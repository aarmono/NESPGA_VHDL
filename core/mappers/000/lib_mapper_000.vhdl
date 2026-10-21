library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_000 is

    function cycle_mapper_000
    (
        config  : cart_config_t;
        cart_in : cart_in_t
    )
    return cart_out_t;

    function get_cpu_prg_addr
    (
        addr_in       : cpu_addr_int_t;
        rom_size_16kb : rom_blocks_t
    )
    return cpu_addr_int_t;

end package lib_mapper_000;


package body lib_mapper_000 is

    function get_cpu_prg_addr
    (
        addr_in       : cpu_addr_int_t;
        rom_size_16kb : rom_blocks_t
    )
    return cpu_addr_int_t
    is
    begin
        -- 32KB of PRG ROM is mapped directly to $8000-$FFFF, while 16KB
        -- is mirrored at $8000 and $C000
        if rom_size_16kb(1) = '1'
        then
            return addr_in mod 2**15;
        else
            return addr_in mod 2**14;
        end if;
    end;

    function cycle_mapper_000
    (
        config  : cart_config_t;
        cart_in : cart_in_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable address : cpu_addr_int_t;
        variable prg_addr : cpu_addr_int_t;
    begin
        ret := CART_OUT_IDLE;

        if is_bus_active(cart_in.cpu.prg_bus)
        then
            address := get_cpu_addr(cart_in.cpu);
            case address is
                when 16#6000# to 16#7FFF# =>
                    ret := map_prg_ram(cart_in, ret);
                when 16#8000# to 16#FFFF# =>
                    prg_addr := get_cpu_prg_addr(address,
                                                 config.prg_rom_16kb_blocks);
                    ret := map_prg_rom(cart_in,
                                       to_unsigned(prg_addr, prg_addr_t'length),
                                       ret);
                when others =>
                    null;
            end case;
        end if;

        if is_bus_active(cart_in.ppu.chr_bus)
        then
            if cart_in.ppu.chr_bus.address(13) = '0'
            then
                ret := map_chr(config,
                               cart_in,
                               unsigned(cart_in.ppu.chr_bus.address(12 downto 0)),
                               ret);
            else
                ret := map_ciram(cart_in, config.mirror, ret);
            end if;
        end if;

        return ret;
    end;

end package body;
