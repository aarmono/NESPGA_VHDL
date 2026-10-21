library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
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

end package lib_mapper_000;


package body lib_mapper_000 is

    function cycle_mapper_000
    (
        config  : cart_config_t;
        cart_in : cart_in_t
    )
    return cart_out_t
    is
        variable banks : cart_banks_t;
    begin
        -- Each window holds the bank of the same number, so 16KB of PRG ROM
        -- is mirrored at 0x8000 and 0xC000
        banks.prg_ram := true;
        banks.prg := resize(get_prg_window(cart_in.cpu), prg_bank_8kb_t'length);
        banks.chr := resize(get_chr_window(cart_in.ppu), chr_bank_1kb_t'length);
        banks.mirror := config.mirror;

        return map_cart(config, cart_in, banks);
    end;

end package body;
