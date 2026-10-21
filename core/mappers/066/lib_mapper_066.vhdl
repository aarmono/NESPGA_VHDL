library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_066 is

    type mapper_066_reg_t is record
        prg_bank : unsigned(1 downto 0);
        chr_bank : unsigned(1 downto 0);
    end record;

    constant RESET_MAPPER_066_REG : mapper_066_reg_t :=
    (
        prg_bank => (others => '0'),
        chr_bank => (others => '0')
    );

    type mapper_066_out_t is record
        reg  : mapper_066_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_066
    (
        reg      : mapper_066_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_066_out_t;

end package lib_mapper_066;


package body lib_mapper_066 is

    function cycle_mapper_066
    (
        reg      : mapper_066_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_066_out_t
    is
        variable ret : mapper_066_out_t;

        variable prg_address : unsigned(16 downto 0);
        variable chr_address : unsigned(14 downto 0);

        variable num_banks : rom_blocks_t;
        variable max_prg_bank : unsigned(1 downto 0);
        variable max_chr_bank : unsigned(1 downto 0);
    begin
        ret.reg := reg;
        ret.cart := CART_OUT_IDLE;

        if is_bus_active(cart_in.cpu.prg_bus) and cart_in.cpu.romsel
        then
            if is_bus_write(cart_in.cpu.prg_bus) and clk_sync
            then
                ret.reg.chr_bank := unsigned(cart_in.cpu.data(1 downto 0));
                ret.reg.prg_bank := unsigned(cart_in.cpu.data(5 downto 4));
            elsif is_bus_read(cart_in.cpu.prg_bus)
            then
                num_banks := shift_right(config.prg_rom_16kb_blocks, 1);
                max_prg_bank := resize(num_banks - "1", max_prg_bank'length);

                prg_address := (reg.prg_bank and max_prg_bank) &
                               unsigned(cart_in.cpu.prg_bus.address);
                ret.cart := map_prg_rom(cart_in, prg_address, ret.cart);
            end if;
        end if;

        -- The PPU sees the registers written by the CPU this cycle
        if is_bus_active(cart_in.ppu.chr_bus)
        then
            if cart_in.ppu.chr_bus.address(13) = '0'
            then
                max_chr_bank := resize(config.chr_rom_8kb_blocks - "1",
                                       max_chr_bank'length);

                chr_address :=
                    (ret.reg.chr_bank and max_chr_bank) &
                    unsigned(cart_in.ppu.chr_bus.address(12 downto 0));
                ret.cart := map_chr(config, cart_in, chr_address, ret.cart);
            else
                ret.cart := map_ciram(cart_in, config.mirror, ret.cart);
            end if;
        end if;

        return ret;
    end;

end package body;
