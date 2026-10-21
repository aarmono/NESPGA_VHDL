library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

package lib_mapper_003 is

    -- 8KB CHR ROM bank
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
        variable banks : cart_banks_t;
    begin
        ret.reg := reg;

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            ret.reg.bank := unsigned(cart_in.cpu.data);
        end if;

        -- The PPU sees the registers written by the CPU this cycle
        banks.prg_ram := false;
        banks.prg := resize(get_prg_window(cart_in.cpu), prg_bank_8kb_t'length);
        banks.chr := resize(ret.reg.bank & get_chr_window(cart_in.ppu),
                            chr_bank_1kb_t'length);
        banks.mirror := config.mirror;

        ret.cart := map_cart(config, cart_in, banks);

        return ret;
    end;

end package body;
