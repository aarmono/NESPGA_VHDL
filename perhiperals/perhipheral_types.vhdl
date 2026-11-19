library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package perhipheral_types is

    subtype wm_audio_t is std_logic_vector(15 downto 0);

    -- Number of a 512 byte block on an SD card
    subtype sd_block_t is std_logic_vector(31 downto 0);
    -- Blocks in a run that sd_reader reads
    subtype sd_count_t is natural range 0 to 2**16 - 1;
    -- Offset of a byte in its block
    subtype sd_offset_t is natural range 0 to 511;

    -- VENDOR_SIM is for simulation only. It has the same behavior as the
    -- other vendors, built in a way that is cheap to simulate
    type vendor_t is
    (
        VENDOR_ALTERA,
        VENDOR_SIM
    );

    -- What the on-chip RAMs of the console contain after power up. The RAMs
    -- of a real console power up random
    type power_up_mode_t is
    (
        -- Whatever the RAM contains, which no fill touches
        POWER_UP_ZERO,
        -- Random bytes, from a seed read from a true random number generator
        POWER_UP_RANDOM,
        -- Random bytes from the same seed every time, for simulation. The
        -- oscillators of the true random number generator cannot be
        -- simulated
        POWER_UP_DETERMINISTIC
    );

    -- Random bytes for RAMs to power up with, from a power up fill, which
    -- changes them on every step of a fill: a byte for each RAM that is
    -- filled at once. All zero for POWER_UP_ZERO.
    --
    -- The console's RAMs: CPU RAM, OAM, secondary OAM and CIRAM
    subtype console_power_up_data_t is std_logic_vector(31 downto 0);
    -- The cartridge's RAMs: PRG and CHR RAM, ExRAM and VRAM, and chip RAM
    subtype cart_power_up_data_t is std_logic_vector(23 downto 0);
    -- Both, for a console and cartridge that share a power up fill: the
    -- console's in the low bits
    subtype power_up_data_t is
        std_logic_vector(cart_power_up_data_t'length +
                         console_power_up_data_t'length - 1 downto 0);
    
    type memory_type_t is
    (
        MEMORY_INFERRED,
        MEMORY_MEMORY,
        MEMORY_REGISTER
    );
    
    function ramtype_attr_str
    (
        vendor      : vendor_t;
        mem_type    : memory_type_t;
        default_val : string
    )
    return string;

end perhipheral_types;

package body perhipheral_types is

    function ramtype_attr_str
    (
        vendor      : vendor_t;
        mem_type    : memory_type_t;
        default_val : string
    )
    return string
    is
    begin
        case vendor is
            when VENDOR_ALTERA =>
                case mem_type is
                    when MEMORY_REGISTER =>
                        return "logic";
                    when others =>
                        return default_val;
                end case;
            when VENDOR_SIM =>
                return default_val;
        end case;
    end;

end package body;