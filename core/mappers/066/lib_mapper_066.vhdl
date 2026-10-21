library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_066 is

    type mapper_066_reg_t is record
        -- 32KB PRG ROM bank
        prg_bank : unsigned(1 downto 0);
        -- 8KB CHR ROM bank
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
        variable banks : cart_banks_t;
    begin
        ret.reg := reg;

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            ret.reg.chr_bank := unsigned(cart_in.cpu.data(1 downto 0));
            ret.reg.prg_bank := unsigned(cart_in.cpu.data(5 downto 4));
        end if;

        -- The PPU sees the registers written by the CPU this cycle
        banks.prg_ram := false;
        banks.prg := resize(ret.reg.prg_bank & get_prg_window(cart_in.cpu),
                            prg_bank_8kb_t'length);
        banks.chr := resize(ret.reg.chr_bank & get_chr_window(cart_in.ppu),
                            chr_bank_1kb_t'length);
        banks.mirror := config.mirror;

        ret.cart := map_cart(config, cart_in, banks);

        return ret;
    end;

end package body;
