library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_003 is

    subtype bank_t is unsigned(7 downto 0);

    type mapper_003_reg_t is record
        bank : bank_t;
    end record;

    constant RESET_MAPPER_003_REG : mapper_003_reg_t :=
    (
        bank => (others => '0')
    );

    type mapper_003_out_t is record
        reg  : mapper_003_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_003
    (
        reg      : mapper_003_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_003_out_t;

end package lib_mapper_003;


package body lib_mapper_003 is

    function get_cpu_prg_addr
    (
        addr_in       : prg_addr_t;
        rom_size_16kb : rom_blocks_t
    )
    return unsigned
    is
        variable ret  : unsigned(15 downto 0);
        variable mask : unsigned(15 downto 0);
    begin
        mask := (rom_size_16kb(1 downto 0) - "1") & b"11_1111_1111_1111";
        ret := unsigned('0' & addr_in) and mask;

        return ret;
    end;

    function get_ppu_chr_addr
    (
        addr_in   : chr_addr_t;
        bank      : bank_t;
        num_banks : rom_blocks_t
    )
    return unsigned
    is
        variable max_bank : bank_t;
        variable mod_bank : bank_t;
    begin
        max_bank := num_banks - "1";
        mod_bank := max_bank and bank;

        return mod_bank(3 downto 0) & unsigned(addr_in(12 downto 0));
    end;

    function cycle_mapper_003
    (
        reg      : mapper_003_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_003_out_t
    is
        variable ret : mapper_003_out_t;
    begin
        ret.reg := reg;
        ret.cart := CART_OUT_IDLE;

        if is_bus_active(cart_in.cpu.prg_bus) and cart_in.cpu.romsel
        then
            if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
            then
                ret.reg.bank := unsigned(cart_in.cpu.data);
            elsif is_bus_read(cart_in.cpu.prg_bus)
            then
                ret.cart :=
                    map_prg_rom(cart_in,
                                get_cpu_prg_addr(cart_in.cpu.prg_bus.address,
                                                 config.prg_rom_16kb_blocks),
                                ret.cart);
            end if;
        end if;

        -- The PPU sees the registers written by the CPU this cycle
        if is_bus_active(cart_in.ppu.chr_bus)
        then
            if cart_in.ppu.chr_bus.address(13) = '0'
            then
                ret.cart :=
                    map_chr(config,
                            cart_in,
                            get_ppu_chr_addr(cart_in.ppu.chr_bus.address,
                                             ret.reg.bank,
                                             config.chr_rom_8kb_blocks),
                            ret.cart);
            else
                ret.cart := map_ciram(cart_in, config.mirror, ret.cart);
            end if;
        end if;

        return ret;
    end;

end package body;
