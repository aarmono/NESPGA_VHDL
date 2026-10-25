#!/usr/bin/env python3
"""Copy an iNES ROM with an NES 2.0 header, for boards an iNES header cannot
select.

Usage: nes2_header.py IN.nes OUT.nes [submapper=N] [prg_ram=BYTES]
                      [chr_ram=BYTES]

The mapper number, ROM sizes, mirroring, battery and trainer are kept from
the iNES header. The submapper is 0 and there is no RAM unless given. RAM
sizes are volatile RAM, and must be a power of 2 from 128 bytes.

Used for test ROMs of boards that only an NES 2.0 header selects:
  - mmc3_test_2 6-MMC3_alt and mmc3_irq_tests 5.MMC3_rev_A, for the NEC
    MMC3 (submapper 4)
  - MMC1_A12 mmc1_a12, for SNROM (8KB PRG RAM, 8KB CHR RAM), whose PRG RAM
    an iNES header cannot tell from that of SXROM
"""

import sys


def shift_count(size):
    """The NES 2.0 RAM size field: 64 << count bytes, or 0 for none."""
    if size == 0:
        return 0
    count = size.bit_length() - 7
    if count < 1 or count > 15 or 64 << count != size:
        raise ValueError(f"bad RAM size {size}")
    return count


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)

    args = {"submapper": 0, "prg_ram": 0, "chr_ram": 0}
    for arg in sys.argv[3:]:
        key, _, value = arg.partition("=")
        if key not in args:
            sys.exit(f"unknown argument {arg}")
        args[key] = int(value, 0)

    with open(sys.argv[1], "rb") as f:
        rom = bytearray(f.read())

    if rom[:4] != b"NES\x1a" or rom[7] & 0x0C == 0x08:
        sys.exit(f"{sys.argv[1]} does not have an iNES header")

    # Bytes 7-15 of an old iNES header may hold junk, such as "DiskDude!".
    # Only the high nibble of byte 7 is kept, with the NES 2.0 identifier
    rom[7] = (rom[7] & 0xF0) | 0x08
    rom[8] = args["submapper"] << 4
    rom[9] = 0
    rom[10] = shift_count(args["prg_ram"])
    rom[11] = shift_count(args["chr_ram"])
    rom[12:16] = bytes(4)

    with open(sys.argv[2], "wb") as f:
        f.write(rom)


if __name__ == "__main__":
    main()
