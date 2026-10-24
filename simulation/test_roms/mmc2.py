#!/usr/bin/env python3
"""Generate test ROMs for the Nintendo MMC2 (mapper 9) and MMC4 (mapper 10).

Usage: mmc2.py OUT.nes {mmc2,mmc4}

Each 8KB PRG ROM bank holds its number at SIG_LO and its complement at
SIG_HI. Each 4KB CHR ROM bank holds its number at its first byte. CHR is read through
$2006/$2007 with rendering off. Writing the second byte of $2006 puts the
new address on the PPU bus, as does each $2007 access afterwards with the
incremented address, and either sets a latch when the address is a trigger.
The latch changes once that read is over, so it has already changed by the
time a $2007 read fetches the trigger address: that the read setting a
latch is from the bank selected before it, which rendering shows, cannot be
seen here. The banks are read back at 0x0000 and 0x1000, which set no
latch.

The groups of checks, in order:
  1. The latches at reset select the 0xFE banks (0xC000 and 0xE000)
  2. PRG ROM banks at 0x8000 (0xA000), and the fixed banks: the last three
     8KB banks for the MMC2, the last 16KB bank for the MMC4. A write to
     0x9000 changes nothing
  3. All 32 CHR banks through each of the four bank registers, with the
     latches set each way by 0x0FD8/0x0FE8 and 0x1FD8/0x1FE8
  4. Each latch set alone
  5. A $2007 read or write that moves the address onto a trigger sets the
     latch
  6. Reads of the first bit plane of the last rows (0x0FD0, 0x0FE0, ...)
     set nothing
  7. The upper half is set by any of 0x1FD8-0x1FDF and 0x1FE8-0x1FEF
  8. The lower half is set by any of 0x0FD8-0x0FDF and 0x0FE8-0x0FEF on the
     MMC4, only 0x0FD8 and 0x0FE8 on the MMC2
  9. Mirroring (0xF000): vertical and horizontal
  10. MMC4 only: PRG RAM at 0x6000. The MMC2 has none, but Mesen gives it
      8KB, so 0x6000 is not checked for it

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed; the index
of the failing check within its group is at zero page DETAIL. The result is
up a few frames after reset, so 250ms of nes_bench is enough.

Variants:
  mmc2  iNES mapper 9: 128KB PRG ROM, 128KB CHR ROM
  mmc4  iNES mapper 10: 256KB PRG ROM, 128KB CHR ROM, 8KB PRG RAM

Mesen passes both.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    'mmc2': dict(mapper=9, prg_8kb=16),
    'mmc4': dict(mapper=10, prg_8kb=32),
}

PASS_COLOR = 0x2A

CHR_BANKS = 32

# The code is in the last 8KB bank, which is fixed at 0xE000. Each bank
# holds its number at SIG_LO and its complement at SIG_HI, clear of the code
# and the vectors
ORG = 0xE100
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# Zero page: the index of the failing check within its group
DETAIL = 0x00


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
BPL, BEQ, JMP_ABS, RTI = 0x10, 0xF0, 0x4C, 0x40
SEI, CLD, TXS = 0x78, 0xD8, 0x9A


def build(v):
    a = Assembler()
    group = [1]
    detail = [0]
    mmc4 = v['mapper'] == 10
    prg_8kb = v['prg_8kb']

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

    def ppu_write(addr, value):
        ppu_addr(addr)
        write(0x2007, value)

    def next_group():
        group[0] += 1
        detail[0] = 0
        assert group[0] < PASS_COLOR

    # Fails with the group number, and the index of the check within the
    # group in Y, unless A is value
    def check(value):
        a.emit(LDX_IMM, group[0])
        a.emit(LDY_IMM, detail[0] & 0xFF)
        a.emit(CMP_IMM, value)
        a.emit(BEQ, 3)
        a.abs_label(JMP_ABS, 'show')
        detail[0] += 1

    # The PPU byte at addr. The first read fills the read buffer
    def ppu_check(addr, value):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)
        a.abs(LDA_ABS, 0x2007)
        check(value)

    def cpu_check(addr, value):
        a.abs(LDA_ABS, addr)
        check(value)

    def bank_check(window, bank):
        cpu_check(window + SIG_LO, bank)
        cpu_check(window + SIG_HI, bank ^ 0xFF)

    # Sets the latch of the half of addr, if addr is a trigger: $2006 puts
    # it on the PPU bus
    def trigger(addr):
        ppu_addr(addr)

    # The banks selected in the lower and upper halves
    def chr_check(lower, upper):
        ppu_check(0x0000, lower)
        ppu_check(0x1000, upper)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    a.abs(STA_ABS, 0x4010)
    a.emit(LDA_IMM, 0x40)                       # no frame IRQ
    a.abs(STA_ABS, 0x4017)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # The latches at reset select the 0xFE banks
    write(0xB000, 1)
    write(0xC000, 2)
    write(0xD000, 3)
    write(0xE000, 4)
    chr_check(2, 4)

    next_group()

    # PRG ROM banks
    if mmc4:
        for b in range(prg_8kb // 2):
            write(0xA000, b)
            bank_check(0x8000, 2 * b)
            bank_check(0xA000, 2 * b + 1)
        bank_check(0xC000, prg_8kb - 2)
        bank_check(0xE000, prg_8kb - 1)
        write(0xA000, 5)
        write(0x9000, 3)
        bank_check(0x8000, 10)
    else:
        for b in range(prg_8kb):
            write(0xA000, b)
            bank_check(0x8000, b)
        for i, window in enumerate((0xA000, 0xC000, 0xE000)):
            bank_check(window, prg_8kb - 3 + i)
        write(0xA000, 5)
        write(0x9000, 3)
        bank_check(0x8000, 5)

    next_group()

    # CHR ROM banks: every bank through every register, with the latches
    # set each way
    for b in range(0, CHR_BANKS, 4):
        regs = [b, b + 1, b + 2, b + 3]
        for i, r in enumerate(regs):
            write(0xB000 + 0x1000 * i, r)
        trigger(0x0FD8)
        trigger(0x1FD8)
        chr_check(regs[0], regs[2])
        trigger(0x0FE8)
        trigger(0x1FE8)
        chr_check(regs[1], regs[3])

    next_group()

    # The latches. 0xFD selects bank 5 (lower) or 7 (upper), 0xFE bank 6
    # or 8
    write(0xB000, 5)
    write(0xC000, 6)
    write(0xD000, 7)
    write(0xE000, 8)
    # Each half alone
    trigger(0x0FD8)
    chr_check(5, 8)
    trigger(0x1FD8)
    chr_check(5, 7)
    trigger(0x0FE8)
    chr_check(6, 7)
    trigger(0x1FE8)
    chr_check(6, 8)

    next_group()

    # A $2007 access that moves the address onto a trigger sets the latch
    # too: the incremented address is put on the PPU bus
    trigger(0x0FD8)
    trigger(0x1FD8)
    chr_check(5, 7)
    for addr, lower, upper in ((0x0FE7, 6, 7), (0x1FE7, 6, 8),
                               (0x0FD7, 5, 8), (0x1FD7, 5, 7)):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)
        chr_check(lower, upper)
    ppu_addr(0x0FE7)
    write(0x2007, 0x00)                         # CHR ROM: no effect
    chr_check(6, 7)

    next_group()

    # The first bit plane sets nothing
    trigger(0x0FE0)
    trigger(0x1FE0)
    trigger(0x0FD0)
    trigger(0x1FD0)
    chr_check(6, 7)
    trigger(0x0FD8)

    next_group()

    # The whole last row of the upper half
    trigger(0x1FEF)
    chr_check(5, 8)
    trigger(0x1FDC)
    chr_check(5, 7)
    trigger(0x1FEB)
    chr_check(5, 8)
    trigger(0x1FDF)
    chr_check(5, 7)

    next_group()

    # The rest of the last row of the lower half: only the MMC4
    trigger(0x0FEF)
    chr_check(6 if mmc4 else 5, 7)
    trigger(0x0FDC)
    chr_check(5, 7)
    trigger(0x0FEB)
    chr_check(6 if mmc4 else 5, 7)
    trigger(0x0FE8)
    trigger(0x0FD9)
    chr_check(5 if mmc4 else 6, 7)
    trigger(0x0FDF)
    chr_check(5 if mmc4 else 6, 7)

    next_group()

    # Mirroring. Each of the four nametables is written with its own byte,
    # so the bytes read back show which share CIRAM
    def nt_test(mode, expect):
        write(0xF000, mode)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + expect[i])

    nt_test(0, [2, 3, 2, 3])
    nt_test(1, [1, 1, 3, 3])

    next_group()

    # PRG RAM
    if mmc4:
        write(0x6000, 0xA5)
        write(0x7FFF, 0x5A)
        cpu_check(0x6000, 0xA5)
        cpu_check(0x7FFF, 0x5A)

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

    a.label('nmi')
    a.emit(RTI)

    code = a.link()
    assert ORG + len(code) <= 0xE000 + SIG_HI, 'code runs into SIG_HI'

    prg = bytearray([0xFF]) * (0x2000 * prg_8kb)
    for b in range(prg_8kb):
        prg[0x2000 * b + SIG_LO] = b
        prg[0x2000 * b + SIG_HI] = b ^ 0xFF

    last = len(prg) - 0x2000
    prg[last + ORG - 0xE000:last + ORG - 0xE000 + len(code)] = code
    for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'), (0xFFFE, 'nmi')):
        prg[last + vec - 0xE000] = a.labels[name] & 0xFF
        prg[last + vec - 0xE000 + 1] = a.labels[name] >> 8

    chr_rom = bytearray(0x1000 * CHR_BANKS)
    for b in range(CHR_BANKS):
        chr_rom[0x1000 * b] = b

    mapper = v['mapper']
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((mapper & 0x0F) << 4) | (0x02 if mmc4 else 0x00),  # battery
                     mapper & 0xF0])
    header += bytes(8)

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
