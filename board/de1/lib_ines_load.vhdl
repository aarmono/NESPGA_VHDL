library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;

-- The iNES header as a ROM loader reads it from the byte stream of a ROM
-- file, to tell an iNES file from other data and how many bytes it holds.
-- See sdram_rom and sram_rom
package lib_ines_load is

    subtype ines_banks_t is natural range 0 to 255;
    -- Bytes in an iNES file whose bank counts fit the header's bytes 4 and 5
    subtype ines_file_bytes_t is
        natural range 0 to 16 + 512 + 255 * (16384 + 8192);

    -- The stream offsets of the header bytes a loader acts on: the last
    -- byte of the signature, after which ines is valid, and the byte with
    -- the high bits of the bank counts, by which the other fields are valid
    constant INES_SIGNATURE_LAST : natural := 3;
    constant INES_SIZE_HIGH      : natural := 9;

    type ines_header_t is record
        -- The stream starts with the iNES signature
        ines      : boolean;
        nes2      : boolean;
        trainer   : boolean;
        prg_banks : ines_banks_t;
        chr_banks : ines_banks_t;
    end record;

    constant RESET_INES_HEADER : ines_header_t :=
    (
        ines => false,
        nes2 => false,
        trainer => false,
        prg_banks => 0,
        chr_banks => 0
    );

    -- The header after the byte at offset of the stream
    function cycle_ines_header
    (
        header : ines_header_t;
        offset : natural;
        data   : data_t
    )
    return ines_header_t;

    -- NES 2.0 keeps the high bits of the bank counts in the byte at
    -- INES_SIZE_HIGH, which is data. A file that uses them holds more than
    -- ines_file_bytes says
    function is_ines_size_high(header : ines_header_t; data : data_t)
        return boolean;

    -- Bytes in the file, from the low bytes of the bank counts
    function ines_file_bytes(header : ines_header_t)
        return ines_file_bytes_t;

end package lib_ines_load;

package body lib_ines_load is

    function cycle_ines_header
    (
        header : ines_header_t;
        offset : natural;
        data   : data_t
    )
    return ines_header_t
    is
        variable ret : ines_header_t;
    begin
        ret := header;

        case offset is
            when 0 =>
                ret.ines := data = x"4E";
            when 1 =>
                ret.ines := header.ines and data = x"45";
            when 2 =>
                ret.ines := header.ines and data = x"53";
            when 3 =>
                ret.ines := header.ines and data = x"1A";
            when 4 =>
                ret.prg_banks := to_integer(data);
            when 5 =>
                ret.chr_banks := to_integer(data);
            when 6 =>
                ret.trainer := data(2) = '1';
            when 7 =>
                ret.nes2 := data(3 downto 2) = "10";
            when others =>
                null;
        end case;

        return ret;
    end;

    function is_ines_size_high(header : ines_header_t; data : data_t)
        return boolean
    is
    begin
        return header.nes2 and data /= x"00";
    end;

    function ines_file_bytes(header : ines_header_t)
        return ines_file_bytes_t
    is
        variable ret : ines_file_bytes_t;
    begin
        ret := 16 + header.prg_banks * 16384 + header.chr_banks * 8192;
        if header.trainer
        then
            ret := ret + 512;
        end if;

        return ret;
    end;

end package body;
