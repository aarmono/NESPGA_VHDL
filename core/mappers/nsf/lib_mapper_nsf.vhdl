library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.cart_mem_bus_types.all;
use work.cart_types.all;

-- The NSF subset board (31), made for compilations of NSF music. As with the
-- NSF mapper, eight registers at 0x5000-0x5FFF, selected by A2-A0 (NSFs
-- write them at 0x5FF8-0x5FFF), select the 4KB PRG ROM banks at
-- 0x8000-0xFFFF: register n the bank at 0x8000 + 0x1000 * n. CHR is 8KB and
-- not banked, and the mirroring is fixed
package lib_mapper_nsf is

    -- The mapper number is that of the NSF subset board
    function is_nsf_mapper(mapper_num : mapper_num_t) return boolean;

    -- An integer, which is faster to simulate than a vector
    subtype nsf_bank_t is natural range 0 to 2**8-1;
    type nsf_banks_t is array(0 to 7) of nsf_bank_t;

    type mapper_nsf_reg_t is record
        banks : nsf_banks_t;
    end record;

    -- The last bank is at 0xF000 at power on, for the startup code
    constant RESET_MAPPER_NSF_REG : mapper_nsf_reg_t :=
    (
        banks => (7 => nsf_bank_t'high, others => 0)
    );

    type mapper_nsf_out_t is record
        reg  : mapper_nsf_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_nsf
    (
        reg      : mapper_nsf_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_nsf_out_t;

end package lib_mapper_nsf;


package body lib_mapper_nsf is

    function is_nsf_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        return mapper_num = x"01F";
    end;

    function cycle_mapper_nsf
    (
        reg      : mapper_nsf_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_nsf_out_t
    is
        variable ret : mapper_nsf_out_t;
        variable banks : cart_banks_t;
        variable addr : prg_addr_t;
        variable bank : nsf_bank_t;
    begin
        ret.reg := reg;
        addr := cart_in.cpu.prg_bus.address;

        if is_bus_write(cart_in.cpu.prg_bus) and
           clk_sync and
           not cart_in.cpu.romsel and
           addr(14 downto 12) = "101"
        then
            ret.reg.banks(to_integer(addr(2 downto 0))) :=
                to_integer(cart_in.cpu.data);
        end if;

        -- The 4KB bank of the CPU address, which map_cart takes as the 8KB
        -- bank that holds it
        bank := ret.reg.banks(to_integer(addr(14 downto 12)));

        banks := default_banks(config);
        banks.prg := to_unsigned(bank / 2, prg_bank_8kb_t'length);
        -- CHR is not banked: each 1KB window is its own 1KB of CHR
        banks.chr := resize(get_chr_window(cart_in.ppu),
                            chr_bank_1kb_t'length);

        ret.cart := map_cart(config, cart_in, banks);

        -- The low bit of the 4KB bank is PRG ROM A12, in place of CPU A12
        if is_bus_active(ret.cart.mem.prg_rom_bus)
        then
            ret.cart.mem.prg_rom_bus.address(12) := to_std_logic(bank mod 2 = 1);
        end if;

        return ret;
    end;

end package body;
