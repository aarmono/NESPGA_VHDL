library IEEE;
use IEEE.std_logic_1164.all;
use work.cart_types.all;
use work.lib_mapper_latch.all;
use work.lib_mapper_mmc1.all;

-- What the console needs to know about the boards the cartridge can hold
package lib_cartridge is

    -- The config with the RAM sizes of its board when the header is iNES,
    -- which gives none. Boards that need more than the default size say how
    -- much here
    function set_ines_ram_masks(config : cart_config_t) return cart_config_t;

end package lib_cartridge;


package body lib_cartridge is

    function set_ines_ram_masks(config : cart_config_t) return cart_config_t
    is
        variable ret : cart_config_t;
    begin
        ret := config;

        if is_latch_mapper(config.mapper_num)
        then
            ret.chr_ram_mask := get_latch_ines_chr_ram_mask(config);
        elsif is_mmc1_mapper(config.mapper_num)
        then
            ret.prg_ram_mask := get_mmc1_ines_prg_ram_mask(config);
        end if;

        return ret;
    end;

end package body;
