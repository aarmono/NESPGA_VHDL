#!/usr/bin/env python3
"""Generate test ROMs for the latch boards that latch.py, latch_chr_ram.py
and latch_addr.py do not cover: the discrete logic boards of Bandai, Irem,
Jaleco, Sunsoft, Camerica and others, and the address latch multicarts.

Usage: latch_boards.py OUT.nes VARIANT

Each variant has a model of its board, written from the nesdev wiki, which
gives what each write to the latches selects. The ROM makes a series of
writes, some of them to addresses the board ignores, and after each one
checks everything the board selects against the model, in groups:
  1 PRG ROM banks: each 8KB bank holds its number at SIG_LO and its
    complement at SIG_HI, read at 0x8000, 0xA000, 0xC000 and 0xE000
  2 CHR ROM banks: the first byte of each 1KB bank holds the number of its
    8KB bank, the second its number in the 8KB bank, read back through
    $2006/$2007 at each 1KB window. A disabled CHR ROM reads the low byte
    of the address with bit 0 set
  3 Nametables: each is read, then written with a byte of its own and read
    again, so the reads show which share CIRAM and, against the bytes left
    by earlier writes, which half of CIRAM is used
  4 CHR RAM: 0x0000 is read, written and read again, showing whether CHR
    RAM is disabled or write protected
  5 Other registers: PRG RAM, reads at 0x6000-0x7FFF, the 4-bit RAM of
    mapper 225
  6 The CHR ROM of iNES mapper 185 is disabled for the first reads after
    reset

The code is the same in every 8KB bank, at the same offset, so it runs on
whichever bank is at 0xE000. Rendering stays off, so the PPU can be accessed
at any time.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed; the
number of the write after which it failed is at zero page DETAIL and the
index of the check in its table at DETAIL+1. The result is up a few frames
after reset, so 250ms of nes_bench is enough.

Bus conflicts are not emulated. Mesen emulates them for 78 and 185, whose
latches are written through a table that avoids them.

Mesen differs from the models, and so fails, on: 70 (forces vertical
mirroring; 70_1scr: single screen only once bit 7 is set), 71 and 71_1
(single screen nametable inverted; any write selects the bank before $9000
is written), 78_ines (no four-screen heuristic), 93 (open bus of disabled
CHR RAM), 97 (writes at 0xC000-0xFFFF, mirroring from 2 bits), 184 (bit 2
of the bank at 0x1000 is not forced), 185_ines (another CHR enable
heuristic), 200 and 200_1 (mirroring inverted), 201 (only 2 PRG and 3 CHR
bits), 202 (the 32KB mode maps 16KB banks B and B+1; BizHawk matches the
model), 212 (reads at 0x6000 return its RAM with D7 set), 213 (only the
NROM-256 mode), 225 and 255 (no 4-bit RAM), 226, 227 and 242 (no CHR RAM
write protect; 242 is a 32KB-only board there), 227_2, 227_rpg and 242_rpg
(no submapper 2 or RPG variant), 61 and 61_1 (CHR not banked).

Variants are listed in VARIANTS.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

PASS_COLOR = 0x2A

# The code is at ORG in every 8KB bank. Each 8KB bank holds its number at
# SIG_LO and its complement at SIG_HI, clear of the code and the vectors
ORG = 0xE100
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# Every 8KB bank holds n at TABLE+n, so that a write to the latch of a
# board with bus conflicts at TABLE+n with n is not changed by them
TABLE = 0x1E00

# Zero page
DETAIL = 0x00
GROUP = 0x02
PTR = 0x10

# The bytes the nametable and CHR RAM checks write are in this range, so
# NONE can mark a read whose result is not known
NONE = 0xFF


def bits(v, hi, lo):
    return (v >> lo) & ((1 << (hi - lo + 1)) - 1)


def bit(v, n):
    return (v >> n) & 1


# 8KB banks of the four windows for 16KB banks lo and hi, or a 32KB bank
def prg16(lo, hi):
    return [2 * lo, 2 * lo + 1, 2 * hi, 2 * hi + 1]


def prg32(b):
    return [4 * b + w for w in range(4)]


# NROM-128 or NROM-256 from a 16KB bank
def nrom(b, nrom_128):
    return prg16(b, b) if nrom_128 else prg16(b & ~1, b | 1)


# 1KB banks of the eight windows for an 8KB bank, or two 4KB banks
def chr8(b):
    return [8 * b + k for k in range(8)]


def chr4(lo, hi):
    return [4 * lo + k for k in range(4)] + [4 * hi + k for k in range(4)]


LAST = 0xFF


class Board:
    """A board after reset: its latches hold what a write of 0 to 0x8000
    gives them. prg is in 16KB units, chr in 8KB units (0: 8KB of CHR
    RAM)"""

    mapper = 0
    submapper = 0
    nes2 = False
    prg = 2
    chr = 1
    mirror = 'V'
    four = False
    battery = False
    # The latch is written through TABLE, avoiding bus conflicts, which are
    # not emulated but which Mesen emulates for these boards
    bus_conflicts = False

    def __init__(self, **kw):
        self.__dict__.update(kw)
        self.reset()

    def reset(self):
        pass

    def write(self, addr, value):
        pass

    def prg_banks(self):
        return prg32(0)

    def chr_banks(self):
        return chr8(0)

    # 'V', 'H', 'A' (lower half of CIRAM) or 'B'
    def nametables(self):
        return self.mirror

    def chr_disabled(self):
        return False

    def chr_protected(self):
        return False

    # The writes to make, each followed by the checks
    def writes(self):
        return []

    def prg_ram(self):
        return False

    # CHR is disabled for the first two reads after reset
    def chr_reads_disabled(self):
        return False

    # Reads at 0x6000-0x7FFF with A4 clear have D7 set, the others are open
    # bus
    def d7_6000(self):
        return False

    # Four 4-bit RAMs at 0x5800-0x5803
    def nibble_ram(self):
        return False


# Data written at 0x8000-0xFFFF, with values that toggle each bit
DATA_VALUES = [0x00, 0xFF, 0x55, 0xAA, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20,
               0x40, 0x80, 0x0F, 0xF0, 0x33, 0xCC, 0x00]


def rom_writes(addrs=(0x8000, 0xFFFF, 0xC000, 0xA5A5), values=DATA_VALUES):
    return [(addrs[i % len(addrs)], v) for i, v in enumerate(values)]


# Address latches: each address bit A14-A0 alone, then some together
def addr_writes(value=0, extra=()):
    addrs = [0x8000] + [0x8000 | (1 << n) for n in range(15)]
    addrs += [0xFFFF, 0xD555, 0xAAAA, 0x8FFF, 0xF000] + list(extra) + \
        [0x8000]
    return [(a, value) for a in addrs]


class DataLatch(Board):
    """A latch written with the data at the addresses of region"""

    def reset(self):
        self.v = 0

    def region(self, addr):
        return addr >= 0x8000

    def write(self, addr, value):
        if self.region(addr):
            self.v = value

    def writes(self):
        return rom_writes()


class M70(DataLatch):
    mapper = 70
    prg = 16
    chr = 16

    def prg_banks(self):
        return prg16(bits(self.v, 7, 4), LAST)

    def chr_banks(self):
        return chr8(bits(self.v, 3, 0))


class M152(DataLatch):
    mapper = 152
    prg = 8
    chr = 16

    def prg_banks(self):
        return prg16(bits(self.v, 6, 4), LAST)

    def chr_banks(self):
        return chr8(bits(self.v, 3, 0))

    def nametables(self):
        return 'AB'[bit(self.v, 7)]


class M71(Board):
    mapper = 71
    prg = 16
    chr = 0

    def reset(self):
        self.p = 0
        self.single = self.submapper == 1
        self.nt = 0

    def write(self, addr, value):
        if addr >= 0xC000:
            self.p = bits(value, 3, 0)
        elif self.submapper == 1 and 0x8000 <= addr < 0xA000:
            self.nt = bit(value, 4)
        elif self.submapper != 1 and 0x9000 <= addr < 0xA000:
            self.single = True
            self.nt = bit(value, 4)

    def prg_banks(self):
        return prg16(self.p, LAST)

    def nametables(self):
        return 'AB'[self.nt] if self.single else self.mirror

    def writes(self):
        return ([(0xC000, 0x05), (0x8000, 0x10), (0xBFFF, 0x0F),
                 (0xC123, 0x0A), (0x8FFF, 0x10), (0xFFFF, 0x0F)] +
                rom_writes((0xC000,), [0x01, 0x02, 0x04, 0x08, 0xFF]) +
                [(0x9000, 0x10), (0x8000, 0x00), (0x9FFF, 0x00),
                 (0x9000, 0x10), (0xE000, 0x03), (0x8000, 0x10),
                 (0xA000, 0x00)])


class M78(DataLatch):
    mapper = 78
    prg = 8
    chr = 16
    bus_conflicts = True

    def holy_diver(self):
        return self.submapper == 3 or (self.submapper == 0 and self.four)

    def prg_banks(self):
        return prg16(bits(self.v, 2, 0), LAST)

    def chr_banks(self):
        return chr8(bits(self.v, 7, 4))

    def nametables(self):
        if self.holy_diver():
            return 'HV'[bit(self.v, 3)]
        return 'AB'[bit(self.v, 3)]


class M79(DataLatch):
    mapper = 79
    prg = 4
    chr = 8

    def region(self, addr):
        return (addr & 0xE100) == 0x4100

    def prg_banks(self):
        return prg32(bit(self.v, 3))

    def chr_banks(self):
        return chr8(bits(self.v, 2, 0))

    def writes(self):
        return rom_writes((0x4100, 0x5FFF, 0x4300, 0x5D80, 0x4200, 0x8000,
                           0x6100, 0x41FF))


class M87(DataLatch):
    mapper = 87
    prg = 2
    chr = 4

    def region(self, addr):
        return 0x6000 <= addr < 0x8000

    def chr_banks(self):
        return chr8((bit(self.v, 0) << 1) | bit(self.v, 1))

    def writes(self):
        return rom_writes((0x6000, 0x7FFF, 0x8000, 0x6ABC))


class M101(M87):
    mapper = 101
    chr = 8

    def chr_banks(self):
        return chr8(self.v)


class M89(DataLatch):
    mapper = 89
    prg = 8
    chr = 16

    def prg_banks(self):
        return prg16(bits(self.v, 6, 4), LAST)

    def chr_banks(self):
        return chr8((bit(self.v, 7) << 3) | bits(self.v, 2, 0))

    def nametables(self):
        return 'AB'[bit(self.v, 3)]


class M93(DataLatch):
    mapper = 93
    prg = 8
    chr = 0

    def prg_banks(self):
        return prg16(bits(self.v, 6, 4), LAST)

    def chr_disabled(self):
        return bit(self.v, 0) == 0


class M94(DataLatch):
    mapper = 94
    prg = 8
    chr = 0

    def prg_banks(self):
        return prg16(bits(self.v, 4, 2), LAST)


class M97(DataLatch):
    mapper = 97
    prg = 32

    def region(self, addr):
        return 0x8000 <= addr < 0xC000

    def prg_banks(self):
        return prg16(LAST, bits(self.v, 4, 0))

    def nametables(self):
        return 'HV'[bit(self.v, 7)]

    def writes(self):
        return rom_writes((0x8000, 0xBFFF, 0xC000, 0xA123, 0xFFFF))


class M140(M87):
    mapper = 140
    prg = 8
    chr = 16

    def prg_banks(self):
        return prg32(bits(self.v, 5, 4))

    def chr_banks(self):
        return chr8(bits(self.v, 3, 0))


class M180(DataLatch):
    mapper = 180
    prg = 8
    chr = 0

    def prg_banks(self):
        return prg16(0, bits(self.v, 2, 0))


class M184(M87):
    mapper = 184
    prg = 2
    chr = 4

    def chr_banks(self):
        return chr4(bits(self.v, 2, 0), 4 | bits(self.v, 5, 4))


class M185(DataLatch):
    mapper = 185
    prg = 2
    chr = 1
    bus_conflicts = True

    def chr_disabled(self):
        if self.submapper < 4:
            return False
        return bits(self.v, 1, 0) != self.submapper - 4

    def chr_reads_disabled(self):
        return self.submapper < 4


class M232(Board):
    mapper = 232
    prg = 16
    chr = 0

    def reset(self):
        self.outer = 0
        self.inner = 0

    def write(self, addr, value):
        if addr >= 0xC000:
            self.inner = bits(value, 1, 0)
        elif self.submapper == 1:
            self.outer = (bit(value, 3) << 1) | bit(value, 4)
        else:
            self.outer = bits(value, 4, 3)

    def prg_banks(self):
        return prg16(self.outer << 2 | self.inner, self.outer << 2 | 3)

    def writes(self):
        return ([(0xC000, 0x02), (0x8000, 0x08), (0xBFFF, 0x10),
                 (0xFFFF, 0x01), (0xA000, 0x18), (0xC000, 0x03),
                 (0x8000, 0xE7), (0xE000, 0xFC), (0x9000, 0x00),
                 (0xC000, 0x00)])


class AddrLatch(Board):
    """A latch of the address written at 0x8000-0xFFFF, and of the data"""

    def reset(self):
        self.a = 0
        self.d = 0

    def write(self, addr, value):
        if addr >= 0x8000:
            self.a = addr & 0x7FFF
            self.d = value

    def writes(self):
        return addr_writes()


class M58(AddrLatch):
    mapper = 58
    prg = 8
    chr = 8

    def prg_banks(self):
        return nrom(bits(self.a, 2, 0), bit(self.a, 6))

    def chr_banks(self):
        return chr8(bits(self.a, 5, 3))

    def nametables(self):
        return 'VH'[bit(self.a, 7)]


class M61(AddrLatch):
    mapper = 61
    prg = 32
    chr = 16

    def prg_banks(self):
        return nrom(bits(self.a, 3, 0) << 1 | bit(self.a, 5), bit(self.a, 4))

    def chr_banks(self):
        if self.submapper == 1:
            return chr8(bits(self.a, 11, 8) << 1 | bit(self.a, 6))
        return chr8(bits(self.a, 11, 8))

    def nametables(self):
        return 'VH'[bit(self.a, 7)]


class M62(AddrLatch):
    mapper = 62
    prg = 128
    chr = 128

    def prg_banks(self):
        return nrom(bit(self.a, 6) << 6 | bits(self.a, 13, 8), bit(self.a, 5))

    def chr_banks(self):
        return chr8(bits(self.a, 4, 0) << 2 | bits(self.d, 1, 0))

    def nametables(self):
        return 'VH'[bit(self.a, 7)]

    def writes(self):
        return [(a, (i * 0x55) & 0xFF) for i, (a, _) in
                enumerate(addr_writes())] + [(0x8000, 0x01), (0x8000, 0x02),
                                             (0x8000, 0x00)]


class M200(AddrLatch):
    mapper = 200
    prg = 16
    chr = 16

    def prg_banks(self):
        b = bits(self.a, 2, 0) if self.submapper == 1 else bits(self.a, 3, 0)
        return nrom(b, True)

    def chr_banks(self):
        b = bits(self.a, 2, 0) if self.submapper == 1 else bits(self.a, 3, 0)
        return chr8(b)

    def nametables(self):
        return 'VH'[bit(self.a, 2 if self.submapper == 1 else 3)]


class M201(AddrLatch):
    mapper = 201
    prg = 32
    chr = 16

    def prg_banks(self):
        return prg32(bits(self.a, 7, 0))

    def chr_banks(self):
        return chr8(bits(self.a, 7, 0))


class M202(AddrLatch):
    mapper = 202
    prg = 8
    chr = 8

    def prg_banks(self):
        return nrom(bits(self.a, 3, 1), not (bit(self.a, 3) and bit(self.a, 0)))

    def chr_banks(self):
        return chr8(bits(self.a, 3, 1))

    def nametables(self):
        return 'VH'[bit(self.a, 0)]

    def writes(self):
        return addr_writes(extra=(0x8009, 0x800B, 0x800F, 0x8008, 0x8001))


class M203(DataLatch):
    mapper = 203
    prg = 64
    chr = 4

    def prg_banks(self):
        return nrom(bits(self.v, 7, 2), True)

    def chr_banks(self):
        return chr8(bits(self.v, 1, 0))


class M212(AddrLatch):
    mapper = 212
    prg = 8
    chr = 8

    def prg_banks(self):
        return nrom(bits(self.a, 2, 0), not bit(self.a, 14))

    def chr_banks(self):
        return chr8(bits(self.a, 2, 0))

    def nametables(self):
        return 'VH'[bit(self.a, 3)]

    def d7_6000(self):
        return True


class M213(M58):
    mapper = 213


class M214(AddrLatch):
    mapper = 214
    prg = 4
    chr = 4

    def prg_banks(self):
        return nrom(bits(self.a, 3, 2), True)

    def chr_banks(self):
        return chr8(bits(self.a, 1, 0))


class M225(AddrLatch):
    mapper = 225
    prg = 128
    chr = 128

    def prg_banks(self):
        return nrom(bit(self.a, 14) << 6 | bits(self.a, 11, 6),
                    bit(self.a, 12))

    def chr_banks(self):
        return chr8(bit(self.a, 14) << 6 | bits(self.a, 5, 0))

    def nametables(self):
        return 'VH'[bit(self.a, 13)]

    def nibble_ram(self):
        return True


class M226(Board):
    mapper = 226
    prg = 128
    chr = 0

    def reset(self):
        self.r = [0, 0]

    def write(self, addr, value):
        if addr >= 0x8000:
            self.r[addr & 1] = value

    def prg_banks(self):
        r0, r1 = self.r
        b = bit(r1, 0) << 6 | bit(r0, 7) << 5 | bits(r0, 4, 0)
        return nrom(b, bit(r0, 5))

    def nametables(self):
        return 'HV'[bit(self.r[0], 6)]

    def chr_protected(self):
        return bit(self.r[1], 1) == 1

    def writes(self):
        w = []
        for v in DATA_VALUES:
            w.append((0x8000, v))
        for v in (0x01, 0x02, 0x03, 0x00):
            w.append((0x8001, v))
            w.append((0x8000, 0x9F))
        w += [(0xFFFE, 0x40), (0xFFFF, 0x01), (0xC000, 0x00), (0xC001, 0x00)]
        return w


class M227(AddrLatch):
    mapper = 227
    prg = 64
    chr = 0

    def bank(self):
        return bit(self.a, 8) << 5 | bits(self.a, 6, 2)

    def nrom_mode(self):
        return self.battery or bit(self.a, 7) == 1

    def prg_banks(self):
        b = self.bank()
        s = bit(self.a, 0)
        if self.nrom_mode():
            return nrom(b, not s)
        lo = b & ~1 if s else b
        if bit(self.a, 9):
            hi = b | 0x07
        else:
            hi = b & ~(0x1F if self.submapper == 2 else 0x07)
        return prg16(lo, hi)

    def nametables(self):
        return 'VH'[bit(self.a, 1)]

    def chr_protected(self):
        return not self.battery and bit(self.a, 7) == 1

    def prg_ram(self):
        return self.battery

    def writes(self):
        return addr_writes(extra=(0x8200, 0x8201, 0x8280, 0x8281, 0x80FC,
                                  0x82FD, 0x817C, 0x837C, 0x8000))


class M242(M227):
    mapper = 242
    prg = 32

    def bank(self):
        return bits(self.a, 6, 2)


class M231(AddrLatch):
    mapper = 231
    prg = 32
    chr = 0

    def prg_banks(self):
        b = bits(self.a, 4, 1) << 1 | bit(self.a, 5)
        return prg16(b & ~1, b)

    def nametables(self):
        return 'VH'[bit(self.a, 7)]


VARIANTS = {
    '70':         lambda: M70(mirror='H'),
    '70_1scr':    lambda: M152(mapper=70, four=True),
    '152':        lambda: M152(),
    '71':         lambda: M71(mirror='H'),
    '71_1':       lambda: M71(submapper=1, nes2=True, prg=8),
    '78_1':       lambda: M78(submapper=1, nes2=True),
    '78_3':       lambda: M78(submapper=3, nes2=True),
    '78_ines':    lambda: M78(four=True),
    '79':         lambda: M79(),
    '146':        lambda: M79(mapper=146, mirror='H'),
    '87':         lambda: M87(),
    '89':         lambda: M89(),
    '93':         lambda: M93(),
    '94':         lambda: M94(mirror='H'),
    '97':         lambda: M97(),
    '101':        lambda: M101(),
    '140':        lambda: M140(),
    '180':        lambda: M180(),
    '184':        lambda: M184(),
    '185_4':      lambda: M185(submapper=4, nes2=True),
    '185_5':      lambda: M185(submapper=5, nes2=True),
    '185_6':      lambda: M185(submapper=6, nes2=True),
    '185_7':      lambda: M185(submapper=7, nes2=True),
    '185_ines':   lambda: M185(),
    '232':        lambda: M232(),
    '232_1':      lambda: M232(submapper=1, nes2=True),
    '58':         lambda: M58(),
    '61':         lambda: M61(),
    '61_1':       lambda: M61(submapper=1, nes2=True, chr=32),
    '61_ram':     lambda: M61(chr=0),
    '62':         lambda: M62(),
    '200':        lambda: M200(),
    '200_1':      lambda: M200(submapper=1, nes2=True, prg=8, chr=8),
    '201':        lambda: M201(),
    '202':        lambda: M202(),
    '203':        lambda: M203(),
    '212':        lambda: M212(),
    '213':        lambda: M213(),
    '214':        lambda: M214(),
    '225':        lambda: M225(),
    '255':        lambda: M225(mapper=255),
    '226':        lambda: M226(),
    '227':        lambda: M227(),
    '227_2':      lambda: M227(submapper=2, nes2=True),
    '227_rpg':    lambda: M227(battery=True),
    '242':        lambda: M242(),
    '242_rpg':    lambda: M242(battery=True),
    '231':        lambda: M231(),
}


class Assembler:
    def __init__(self):
        self.code = bytearray()
        self.labels = {}
        self.fixups = []

    def emit(self, *b):
        self.code.extend(b)

    def here(self):
        return ORG + len(self.code)

    def label(self, name):
        self.labels[name] = self.here()

    def abs(self, op, addr):
        self.emit(op, addr & 0xFF, addr >> 8)

    def abs_label(self, op, name):
        self.emit(op, 0, 0)
        self.fixups.append((len(self.code) - 2, name, 'abs'))

    def imm_label(self, op, name, hi):
        self.emit(op, 0)
        self.fixups.append((len(self.code) - 1, name, 'hi' if hi else 'lo'))

    def branch(self, op, name):
        self.emit(op, 0)
        self.fixups.append((len(self.code) - 1, name, 'rel'))

    def link(self):
        for off, name, kind in self.fixups:
            addr = self.labels[name]
            if kind == 'abs':
                self.code[off] = addr & 0xFF
                self.code[off + 1] = addr >> 8
            elif kind == 'lo':
                self.code[off] = addr & 0xFF
            elif kind == 'hi':
                self.code[off] = addr >> 8
            else:
                d = addr - (ORG + off + 1)
                assert -128 <= d < 128, name
                self.code[off] = d & 0xFF
        return self.code


LDA_IMM, LDA_ABS, STA_ABS, STX_ABS = 0xA9, 0xAD, 0x8D, 0x8E
LDX_IMM, LDY_IMM, CMP_IMM, BIT_ABS = 0xA2, 0xA0, 0xC9, 0x2C
STA_ZP, STY_ZP, LDX_ZP, CMP_IND_Y, LDA_IND_Y = 0x85, 0x84, 0xA6, 0xD1, 0xB1
INY, PHA, PLA = 0xC8, 0x48, 0x68
BPL, BEQ, BNE, JMP_ABS, JSR, RTS, RTI = 0x10, 0xF0, 0xD0, 0x4C, 0x20, 0x60, \
    0x40


# Which half of CIRAM each nametable uses
NT_PAGES = {'V': [0, 1, 0, 1], 'H': [0, 0, 1, 1], 'A': [0, 0, 0, 0],
            'B': [1, 1, 1, 1]}


def build(board):
    a = Assembler()
    prg_8kb = board.prg * 2
    chr_rom = board.chr > 0
    chr_1kb = board.chr * 8

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    def ppu_addr(addr):
        write(0x2006, addr >> 8)
        write(0x2006, addr & 0xFF)

    # Reads PPU addr into A, through the read buffer
    def ppu_read(addr):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)
        a.abs(LDA_ABS, 0x2007)

    def group(n):
        assert n < PASS_COLOR
        a.emit(LDA_IMM, n)
        a.emit(STA_ZP, GROUP)

    # Fails with the group number unless A is value
    def check(value, detail):
        a.emit(LDY_IMM, detail)
        a.emit(CMP_IMM, value)
        a.emit(BEQ, 3)
        a.abs_label(JMP_ABS, 'fail')

    a.label('reset')
    a.emit(0x78, 0xD8, 0xA2, 0xFF, 0x9A)        # SEI CLD LDX #$FF TXS
    write(0x2000, 0)
    write(0x2001, 0)
    a.emit(LDA_IMM, NONE)
    a.emit(STA_ZP, DETAIL)

    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # The CHR ROM of iNES mapper 185 is disabled for the first reads, then
    # enabled
    if board.chr_reads_disabled():
        group(6)
        ppu_read(0x0000)
        check(0x01, 0)
        for _ in range(4):
            a.abs(LDA_ABS, 0x2007)
        ppu_read(0x0000)
        check(0x00, 1)
        a.abs(LDA_ABS, 0x2007)
        check(0x00, 2)

    # Other registers
    group(5)
    if board.prg_ram():
        write(0x6000, 0xA5)
        write(0x7FFF, 0x5A)
        a.abs(LDA_ABS, 0x6000)
        check(0xA5, 0)
        a.abs(LDA_ABS, 0x7FFF)
        check(0x5A, 1)
    if board.d7_6000():
        # D7 is set with A4 clear, the other bits are open bus: the high
        # byte of the address
        a.abs(LDA_ABS, 0x6000)
        check(0xE0, 2)
        a.abs(LDA_ABS, 0x7FEF)
        check(0xFF, 3)
        a.abs(LDA_ABS, 0x6010)
        check(0x60, 4)
    if board.nibble_ram():
        for i, v in enumerate((0x15, 0x2A, 0x3C, 0x0F)):
            write(0x5800 + i, v)
        for i, v in enumerate((0x5, 0xA, 0xC, 0xF)):
            a.abs(LDA_ABS, 0x5800 + i)
            check(0x50 | v, 5 + i)
            a.abs(LDA_ABS, 0x5FFC + i)
            check(0x50 | v, 9 + i)

    # The writes, each with the table of the checks after it
    tables = []
    ciram = [None, None]
    chr_ram = None
    states = board.writes()
    assert len(states) < NONE
    for n, (addr, value) in enumerate(states):
        if board.bus_conflicts and addr >= 0x8000:
            addr = (addr & 0xE000) | TABLE | value
        board.write(addr, value)
        write(addr, value)
        a.emit(LDA_IMM, n)
        a.emit(STA_ZP, DETAIL)
        name = 'table_%d' % n
        a.imm_label(LDA_IMM, name, False)
        a.emit(STA_ZP, PTR)
        a.imm_label(LDA_IMM, name, True)
        a.emit(STA_ZP, PTR + 1)
        a.abs_label(JSR, 'verify')

        t = bytearray()
        banks = [b % prg_8kb for b in board.prg_banks()]
        t += bytes(b & 0xFF for b in banks)
        t.append((banks[0] & 0xFF) ^ 0xFF)
        if chr_rom:
            for k, b in enumerate(board.chr_banks()):
                if board.chr_disabled():
                    t += bytes([0x01, 0x01])
                else:
                    b %= chr_1kb
                    t += bytes([(b // 8) & 0xFF, b % 8])
        pages = NT_PAGES[board.nametables()]
        t += bytes(NONE if ciram[p] is None else ciram[p] for p in pages)
        vals = [0x40 + (4 * n + i) % 0x80 for i in range(4)]
        t += bytes(vals)
        for i in range(4):
            ciram[pages[i]] = vals[i]
        t += bytes(ciram[p] for p in pages)
        if not chr_rom:
            v = 0x40 + n % 0x80
            if board.chr_disabled():
                t += bytes([0x01, v, 0x01])
            else:
                t += bytes([NONE if chr_ram is None else chr_ram, v])
                if not board.chr_protected():
                    chr_ram = v
                t.append(NONE if chr_ram is None else chr_ram)
        tables.append((name, t))

    a.emit(LDX_IMM, PASS_COLOR)
    a.abs_label(JMP_ABS, 'show')

    # Checks the selected banks against the table at PTR
    a.label('verify')
    a.emit(LDY_IMM, 0)
    group(1)
    for w in range(4):
        a.abs(LDA_ABS, 0x8000 + 0x2000 * w + SIG_LO)
        a.abs_label(JSR, 'cmp_next')
    a.abs(LDA_ABS, 0x8000 + SIG_HI)
    a.abs_label(JSR, 'cmp_next')
    if chr_rom:
        group(2)
        for k in range(8):
            ppu_read(0x0400 * k)
            a.abs_label(JSR, 'cmp_next')
            a.abs(LDA_ABS, 0x2007)
            a.abs_label(JSR, 'cmp_next')
    group(3)
    for i in range(4):
        ppu_read(0x2000 + 0x400 * i)
        a.abs_label(JSR, 'cmp_opt')
    for i in range(4):
        ppu_addr(0x2000 + 0x400 * i)
        a.emit(LDA_IND_Y, PTR)
        a.abs(STA_ABS, 0x2007)
        a.emit(INY)
    for i in range(4):
        ppu_read(0x2000 + 0x400 * i)
        a.abs_label(JSR, 'cmp_next')
    if not chr_rom:
        group(4)
        ppu_read(0x0000)
        a.abs_label(JSR, 'cmp_opt')
        ppu_addr(0x0000)
        a.emit(LDA_IND_Y, PTR)
        a.abs(STA_ABS, 0x2007)
        a.emit(INY)
        ppu_read(0x0000)
        a.abs_label(JSR, 'cmp_opt')
    a.emit(RTS)

    # Fails unless A is the byte of the table at Y, then moves to the next
    a.label('cmp_next')
    a.emit(CMP_IND_Y, PTR)
    a.branch(BNE, 'fail')
    a.emit(INY)
    a.emit(RTS)

    # As cmp_next, but passes when the byte of the table is NONE
    a.label('cmp_opt')
    a.emit(PHA)
    a.emit(LDA_IND_Y, PTR)
    a.emit(CMP_IMM, NONE)
    a.branch(BEQ, 'cmp_opt_skip')
    a.emit(PLA)
    a.abs_label(JMP_ABS, 'cmp_next')
    a.label('cmp_opt_skip')
    a.emit(PLA)
    a.emit(INY)
    a.emit(RTS)

    a.label('fail')
    a.emit(STY_ZP, DETAIL + 1)
    a.emit(LDX_ZP, GROUP)

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show')
    wait_vblank('vblank_3')
    a.emit(LDA_IMM, 0x3F)
    a.abs(STA_ABS, 0x2006)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2006)
    a.abs(STX_ABS, 0x2007)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2006)
    a.abs(STA_ABS, 0x2006)
    a.label('loop')
    a.abs_label(JMP_ABS, 'loop')

    a.label('rti')
    a.emit(RTI)

    for name, t in tables:
        a.label(name)
        a.emit(*t)

    code = a.link()
    assert ORG + len(code) <= 0xE000 + TABLE, 'code runs into TABLE'

    prg = bytearray([0xFF]) * (0x2000 * prg_8kb)
    for b in range(prg_8kb):
        base = 0x2000 * b
        prg[base + SIG_LO] = b & 0xFF
        prg[base + SIG_HI] = (b & 0xFF) ^ 0xFF
        prg[base + ORG - 0xE000:base + ORG - 0xE000 + len(code)] = code
        prg[base + TABLE:base + TABLE + 0x100] = bytes(range(0x100))
        for vec, name in ((0x1FFA, 'rti'), (0x1FFC, 'reset'), (0x1FFE, 'rti')):
            prg[base + vec] = a.labels[name] & 0xFF
            prg[base + vec + 1] = a.labels[name] >> 8

    chr_data = bytearray(0x400 * chr_1kb)
    for b in range(chr_1kb):
        chr_data[0x400 * b] = (b // 8) & 0xFF
        chr_data[0x400 * b + 1] = b % 8

    mapper = board.mapper
    flags6 = ((mapper & 0x0F) << 4) | (0x01 if board.mirror == 'V' else 0)
    if board.four:
        flags6 |= 0x08
    if board.battery:
        flags6 |= 0x02
    header = bytearray(b'NES\x1a')
    header += bytes([board.prg, board.chr, flags6,
                     (mapper & 0xF0) | (0x08 if board.nes2 else 0x00)])
    header += bytes(8)
    if board.nes2:
        header[8] = board.submapper << 4 | mapper >> 8
        if board.prg_ram():
            header[10] = 0x70                   # 8KB battery PRG RAM
        if not chr_rom:
            header[11] = 0x07                   # 8KB CHR RAM

    return bytes(header + prg + chr_data)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]()))


if __name__ == '__main__':
    main()
