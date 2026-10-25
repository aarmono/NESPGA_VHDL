#!/usr/bin/env python3
"""Generate test ROMs for the Action 53 board (mapper 28).

Usage: action53.py OUT.nes {ines,nes2}

The ROM checks, in groups:
  1  0xC000 holds the last 16KB at power on
  2  The register select at 0x5000-0x5FFF: only D7 and D0 count, the whole
     of 0x5000-0x5FFF selects, and it stays selected over several writes
  3  PRG ROM banks in every PRG bank mode and outer bank size, for several
     outer and inner banks, against the table on nesdev
  4  The four 8KB banks of CHR RAM
  5  Mirroring: the four modes of register 0x80, and in the one screen
     modes D4 of registers 0x00 and 0x01, which the H/V modes ignore

There are 64 16KB PRG ROM banks (1MB), each holding its number at SIG_LO
and its complement at SIG_HI. The code is in every bank at the same
address, so it runs whatever banks are selected.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed. The index
of the failing check within its group is at zero page DETAIL. The result is
up a few frames after reset, so 250ms of nes_bench is enough.

Variants:
  ines  iNES mapper 28, which gives no CHR RAM size: the board has 32KB
  nes2  NES 2.0 mapper 28 with 32KB of CHR RAM

Mesen passes nes2. It fails ines at group 4, since it gives iNES mapper 28
only 8KB of CHR RAM.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    'ines': dict(nes2=False),
    'nes2': dict(nes2=True),
}

PASS_COLOR = 0x2A

PRG_BANKS = 64

# Zero page
DETAIL = 0x00

# The code runs at 0xC000, from whichever bank is there
ORG = 0xC100
SIG_LO = 0x0008
SIG_HI = 0x3FF0

REG_CHR, REG_INNER, REG_MODE, REG_OUTER = 0x00, 0x01, 0x80, 0x81


def prg_banks(mode, outer, inner):
    """The 16KB banks at 0x8000 and 0xC000, from the table on nesdev"""
    size_mask = (2 << ((mode >> 4) & 3)) - 1
    prg_mode = (mode >> 2) & 3
    o = outer << 1

    def current(a14):
        i = (inner << 1) | a14 if prg_mode < 2 else inner
        return (o & ~size_mask) | (i & size_mask)

    if prg_mode < 2:
        lo, hi = current(0), current(1)
    elif prg_mode == 2:
        lo, hi = o, current(1)
    else:
        lo, hi = current(0), o | 1
    return lo % PRG_BANKS, hi % PRG_BANKS


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

    def branch(self, op, name):
        self.emit(op, 0)
        self.fixups.append((len(self.code) - 1, name, 'rel'))

    def link(self):
        for off, name, kind in self.fixups:
            addr = self.labels[name]
            if kind == 'abs':
                self.code[off] = addr & 0xFF
                self.code[off + 1] = addr >> 8
            else:
                d = addr - (ORG + off + 1)
                assert -128 <= d < 128, name
                self.code[off] = d & 0xFF
        return self.code


LDA_IMM, LDA_ABS, STA_ABS, STX_ABS = 0xA9, 0xAD, 0x8D, 0x8E
LDX_IMM, LDY_IMM, CMP_IMM, BIT_ABS = 0xA2, 0xA0, 0xC9, 0x2C
STY_ZP = 0x84
BPL, BEQ, JMP_ABS, JSR, RTS, RTI = 0x10, 0xF0, 0x4C, 0x20, 0x60, 0x40


def build(v):
    a = Assembler()
    step = [1]
    detail = [0]

    def next_group():
        step[0] += 1
        detail[0] = 0
        assert step[0] < PASS_COLOR

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def select(reg, addr=0x5000):
        a.emit(LDA_IMM, reg)
        a.abs(STA_ABS, addr)

    def write(value, addr=0x8000):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    def set_reg(reg, value):
        select(reg)
        write(value)

    def ppu_addr(addr):
        a.emit(LDA_IMM, addr >> 8)
        a.abs(STA_ABS, 0x2006)
        a.emit(LDA_IMM, addr & 0xFF)
        a.abs(STA_ABS, 0x2006)

    def ppu_write(addr, value):
        ppu_addr(addr)
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, 0x2007)

    # Fails with the group number unless A is value
    def check(value):
        a.emit(LDX_IMM, step[0])
        a.emit(LDY_IMM, detail[0] & 0xFF)
        a.emit(CMP_IMM, value)
        a.emit(BEQ, 3)
        a.abs_label(JMP_ABS, 'show')
        detail[0] += 1

    def ppu_check(addr, value):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)                  # the read buffer
        a.abs(LDA_ABS, 0x2007)
        check(value)

    def cpu_check(addr, value):
        a.abs(LDA_ABS, addr)
        check(value)

    def bank_check(lo, hi):
        cpu_check(0x8000 + SIG_LO, lo)
        cpu_check(0xC000 + SIG_LO, hi)
        cpu_check(0xC000 + SIG_HI, hi ^ 0xFF)

    a.label('reset')
    a.emit(0x78, 0xD8, 0xA2, 0xFF, 0x9A)        # SEI CLD LDX #$FF TXS
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)

    # Power on: the last bank at 0xC000
    cpu_check(0xC000 + SIG_LO, PRG_BANKS - 1)
    cpu_check(0xC000 + SIG_HI, (PRG_BANKS - 1) ^ 0xFF)
    next_group()

    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # The register select. 32KB banks of a 32KB game, so the outer bank
    # alone selects them
    set_reg(REG_MODE, 0x02)
    set_reg(REG_OUTER, 0x05)
    bank_check(10, 11)
    # Bits 6-1 are not decoded: 0x7E selects 0x00, 0xFF selects 0x81
    select(0xFF, 0x5FFF)
    write(0x06, 0xFFFF)
    bank_check(12, 13)
    # The select is kept: a second write goes to the same register
    write(0x07, 0xC000)
    bank_check(14, 15)
    # Writes outside 0x5000-0x5FFF do not select
    select(0x00, 0x4FFF)
    select(0x00, 0x6000)
    write(0x08)
    bank_check(16, 17)
    # 0x7E selects the CHR bank, which leaves the PRG banks alone
    select(0x7E)
    write(0x03)
    bank_check(16, 17)
    next_group()

    # The PRG banks in every mode and size. The mirroring bits are 2
    # (vertical) so that D4 of the inner bank does not matter
    for outer, inner in ((0x15, 0x0A), (0x0A, 0x05), (0x1F, 0x0F),
                         (0x20, 0x03)):
        set_reg(REG_OUTER, outer)
        set_reg(REG_INNER, inner)
        for m in range(16):
            mode = (m << 2) | 0x02
            set_reg(REG_MODE, mode)
            bank_check(*prg_banks(mode, outer, inner))
    next_group()

    # CHR RAM banks
    for b in range(4):
        set_reg(REG_CHR, b)
        ppu_write(0x0000, 0xC0 + b)
        ppu_write(0x1FFF, 0xD0 + b)
    for b in range(4):
        set_reg(REG_CHR, b)
        ppu_check(0x0000, 0xC0 + b)
        ppu_check(0x1FFF, 0xD0 + b)
    set_reg(REG_CHR, 0)
    next_group()

    # Nametables. Each of the four is written with its own byte, so the
    # bytes read back show which share CIRAM
    tag = [0x40]

    def nt_check(expect):
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, tag[0] + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, tag[0] + expect[i])
        tag[0] += 0x10

    one_a, one_b = [3, 3, 3, 3], [3, 3, 3, 3]
    horz, vert = [1, 1, 3, 3], [2, 3, 2, 3]

    set_reg(REG_MODE, 0x02)
    nt_check(vert)
    set_reg(REG_MODE, 0x03)
    nt_check(horz)
    # One screen: the two screens are told apart by a write to the first
    # and a read through the other
    set_reg(REG_MODE, 0x00)
    nt_check(one_a)
    ppu_write(0x2000, 0x11)
    set_reg(REG_MODE, 0x01)
    nt_check(one_b)
    ppu_write(0x2000, 0x22)
    set_reg(REG_MODE, 0x00)
    ppu_check(0x2400, 0x11)
    # D4 of the CHR bank and of the inner bank select the screen
    set_reg(REG_CHR, 0x10)
    ppu_check(0x2000, 0x22)
    set_reg(REG_INNER, 0x00)
    ppu_check(0x2000, 0x11)
    set_reg(REG_INNER, 0x10)
    ppu_check(0x2C00, 0x22)
    set_reg(REG_CHR, 0x00)
    ppu_check(0x2800, 0x11)
    # D4 is ignored in the H/V modes, and the mode keeps bit 0 as written
    set_reg(REG_MODE, 0x03)
    set_reg(REG_CHR, 0x10)
    set_reg(REG_INNER, 0x10)
    nt_check(horz)
    set_reg(REG_MODE, 0x02)
    set_reg(REG_INNER, 0x00)
    nt_check(vert)
    next_group()

    a.emit(LDX_IMM, PASS_COLOR)

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show')
    a.emit(STY_ZP, DETAIL)
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

    code = a.link()
    assert ORG + len(code) <= 0xC000 + SIG_HI, 'code runs into SIG_HI'

    prg = bytearray([0xFF]) * (0x4000 * PRG_BANKS)
    for b in range(PRG_BANKS):
        base = 0x4000 * b
        prg[base + ORG - 0xC000:base + ORG - 0xC000 + len(code)] = code
        prg[base + SIG_LO] = b
        prg[base + SIG_HI] = b ^ 0xFF
        for vec, name in ((0xFFFA, 'rti'), (0xFFFC, 'reset'), (0xFFFE, 'rti')):
            prg[base + vec - 0xC000] = a.labels[name] & 0xFF
            prg[base + vec - 0xC000 + 1] = a.labels[name] >> 8

    mapper = 28
    header = bytearray(b'NES\x1a')
    header += bytes([PRG_BANKS, 0, (mapper & 0x0F) << 4,
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[11] = 0x09                       # 32KB CHR RAM

    return bytes(header + prg)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
