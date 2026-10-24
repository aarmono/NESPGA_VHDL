#!/usr/bin/env python3
"""Generate test ROMs for the boards built around the MMC3, the MMC6 and the
Namco 108 (mappers 4, 47, 76, 88, 95, 118, 119, 154 and 206).

Usage: mmc3.py OUT.nes VARIANT

The IRQ counter is left to blargg's mmc3_test and mmc3_irq_tests. The checks
are in groups; every variant starts with:
   1  PRG ROM: every bank through R6 at 0x8000 in PRG mode 0. Each 8KB bank
      holds its number at SIG_LO and its complement at SIG_HI
   2  R7 at 0xA000, the second last bank at 0xC000, the last at 0xE000, and
      a bank number wider than the ROM wrapping
   3  PRG mode 1 (0x8000 and 0xC000 swapped). The Namco 108 has no PRG mode,
      so setting bit 6 of 0x8000 must change nothing
 4-7  CHR ROM: all six bank registers, R0 and R1 (2KB) odd, wider than the
      ROM, in CHR mode 0, 1, 0, 1. Each 1KB bank holds its number at its
      first byte, read through $2006/$2007 with rendering off. The Namco 108
      has no CHR mode, so setting bit 7 of 0x8000 must change nothing
   8  Mirroring: $A000 vertical/horizontal on the MMC3 and MMC6, the CIRAM
      page from the CHR banks on txsrom and 95, single screen on 154, the
      header on 206/88/76
Then, by variant:
  mmc3       NES 2.0 mapper 4, 256KB PRG, 128KB CHR, 8KB PRG RAM. 9-11 PRG
             RAM: enabled by $A001 bit 7; write protected by bit 6;
             disabled, which reads open bus (the high byte of the address).
             12 bit 5 of 0x8000, which only the MMC6 uses, leaves the PRG
             RAM alone
  mmc3_big   iNES mapper 4, 512KB PRG, 256KB CHR: the full width of the bank
             registers. 9-11 as mmc3
  qj         iNES mapper 47 (NES-QJ), 2x128KB PRG and CHR. The 128KB set is
             selected by bit 0 of a write to 0x6000-0x7FFF, which only takes
             while $A001 enables PRG RAM without write protection. The code
             is in the last bank of both sets. 9 PRG ROM of the second set,
             10-11 its CHR ROM, 12 writes ignored while protected or
             disabled, 13 back to the first set, 14 its CHR ROM
  txsrom     iNES mapper 118, 128KB CHR. Bit 7 of the CHR bank selects the
             CIRAM page of the nametables: 8 R0/R1 in CHR mode 0, 9 $A000
             does nothing, 10 R2-R5 in CHR mode 1, 11 bit 7 does not select
             CHR ROM. 12-14 PRG RAM as mmc3 9-11
  tqrom      iNES mapper 119, 64KB CHR ROM and 8KB CHR RAM. Bit 6 of the CHR
             bank selects CHR RAM: 9 CHR RAM banks, CHR ROM ignores writes,
             10 the RAM banks wrap at 8KB, and RAM in a 2KB bank. 11-13 PRG
             RAM as mmc3 9-11
  mmc6_nes2  NES 2.0 mapper 4 submapper 1 (MMC6) with 1KB of battery backed
             PRG RAM, as on StarTropics. The 1KB of PRG RAM is at
             0x7000-0x7FFF, mirrored, enabled by bit 5 of 0x8000, with read
             and write enables for each 512 byte half in $A001 bits 7-4.
             9 RAM mirrored every 1KB, 10 both halves read only, 11 lower
             half only, 12 upper half only, 13 neither reads open bus,
             14 clearing bit 5 of 0x8000 disables the RAM and holds $A001
             at 0 (nesdev), so the RAM stays disabled after bit 5 is set
             again until $A001 is written, 15 write enable without read
             enable does not write, 16 a half that cannot be read reads 0
             while the other can, 17 nothing at 0x6000-0x6FFF (open bus)
  mmc6_ines  iNES mapper 4: an MMC3 until bit 5 of 0x8000 is set. 9-11 PRG
             RAM as mmc3, 12 the whole 8KB at 0x6000, 13 bit 5 makes it an
             MMC6, which stays one with bit 5 clear. 14-22 as mmc6_nes2 9-17
  206        iNES mapper 206 (DxROM), vertical, 128KB PRG, 64KB CHR
  88         iNES mapper 88, horizontal, 128KB CHR: PPU A12 drives CHR A16,
             so R0/R1 select from the first 64KB and R2-R5 from the second
  76         iNES mapper 76 (NAMCOT-3446), vertical, 128KB CHR: R2-R5
             select 2KB CHR banks at 0x0000, 0x0800, 0x1000 and 0x1800
  95         iNES mapper 95 (NAMCOT-3425), 32KB CHR: bit 5 of R0 selects
             the CIRAM page of the nametables at $2000/$2400, and of R1 at
             $2800/$2C00. 9 bit 7 of 0x8000 does not swap R0/R1 with R2-R5
  154        iNES mapper 154 (NAMCOT-3453), 128KB CHR, wired as 88: bit 6 of
             every write to 0x8000-0xFFFF selects the CIRAM page for single
             screen mirroring. 9 bank data writes select it too
The Namco 108 variants (206, 88, 76, 95, 154) end with two groups: the
registers are only at 0x8000-0x9FFF (writes to $A000/$A001, $C000/$C001 and
$E000/$E001 are ignored), then nothing is at 0x6000 (open bus).

Mirroring is checked by writing each of the four nametables with its own
byte and reading them back, which shows which share CIRAM, or, where single
screen mirroring has to be told apart, by reading back bytes written to
CIRAM page 0 and page 1 beforehand.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed; the index of the
failing check in its group is at zero page DETAIL. The result is up about 5
frames after reset, so 250ms of nes_bench is enough.

All pass in nes_bench. Mesen passes mmc3, mmc3_big, qj, txsrom and tqrom. It
fails the Namco 108 variants in their register group (it folds writes to
0x8000-0xFFFF onto $8000/$8001, which nesdev and Nestopia do not; it also
gives every board PRG RAM), mmc6_ines in group 13 (without its game
database an iNES header is never an MMC6), and mmc6_nes2 from group 14 on:
it does not ignore or clear $A001 while the RAM is disabled, writes a half
that is write enabled but not read enabled, and reads a disabled half as
open bus rather than 0.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

# kind: mmc3 (the MMC3 chip: modes, $A000/$A001), mmc6, or namco
VARIANTS = {
    'mmc3':      dict(mapper=4, nes2=True, prg_banks=32, chr_banks=128,
                      kind='mmc3', board='txrom', vertical=False),
    'mmc3_big':  dict(mapper=4, nes2=False, prg_banks=64, chr_banks=256,
                      kind='mmc3', board='txrom', vertical=False),
    'qj':        dict(mapper=47, nes2=False, prg_banks=32, chr_banks=256,
                      kind='mmc3', board='qj', vertical=True),
    'txsrom':    dict(mapper=118, nes2=False, prg_banks=32, chr_banks=128,
                      kind='mmc3', board='txsrom', vertical=True),
    'tqrom':     dict(mapper=119, nes2=False, prg_banks=16, chr_banks=64,
                      kind='mmc3', board='tqrom', vertical=True),
    'mmc6_nes2': dict(mapper=4, nes2=True, submapper=1, prg_banks=16,
                      chr_banks=64, kind='mmc6', board='mmc6',
                      vertical=True),
    'mmc6_ines': dict(mapper=4, nes2=False, prg_banks=16, chr_banks=64,
                      kind='mmc3', board='mmc6_ines', vertical=True),
    '206':       dict(mapper=206, nes2=False, prg_banks=16, chr_banks=64,
                      kind='namco', board='206', vertical=True),
    '88':        dict(mapper=88, nes2=False, prg_banks=16, chr_banks=128,
                      kind='namco', board='88', vertical=False),
    '76':        dict(mapper=76, nes2=False, prg_banks=16, chr_banks=128,
                      kind='namco', board='76', vertical=True),
    '95':        dict(mapper=95, nes2=False, prg_banks=16, chr_banks=32,
                      kind='namco', board='95', vertical=True),
    '154':       dict(mapper=154, nes2=False, prg_banks=16, chr_banks=128,
                      kind='namco', board='154', vertical=True),
}

PASS_COLOR = 0x2A

# The code is in the last 8KB bank, which is fixed at 0xE000. Each bank
# holds its number at SIG_LO and its complement at SIG_HI, clear of the code
# and the vectors
ORG = 0xE100
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# Zero page: the index of the failed check in its group
DETAIL = 0x00

# The offset in each nametable of the bytes written to tell them apart
NT_OFFSET = 0x10


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
    # The group of checks and the index of the check in it
    step = [0]
    detail = [0]
    kind = v['kind']
    board = v['board']
    namco = kind == 'namco'
    prg_banks = v['prg_banks']
    chr_banks = v['chr_banks']
    # The PRG banks of one NES-QJ set
    set_banks = 16 if board == 'qj' else prg_banks

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    # Bank register idx, with bits 7-5 of 0x8000 given by ctl
    def bank(idx, value, ctl=0x00):
        write(0x8000, ctl | idx)
        write(0x8001, value)

    def ppu_addr(addr):
        write(0x2006, addr >> 8)
        write(0x2006, addr & 0xFF)

    def ppu_write(addr, value):
        ppu_addr(addr)
        write(0x2007, value)

    def next_group():
        step[0] += 1
        detail[0] = 0
        assert step[0] < PASS_COLOR

    # Fails with the group number unless A is value
    def check(value):
        a.emit(LDX_IMM, step[0])
        a.emit(LDY_IMM, detail[0])
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

    def bank_check(window, b):
        b %= prg_banks
        cpu_check(window + SIG_LO, b)
        cpu_check(window + SIG_HI, b ^ 0xFF)

    # The 1KB CHR bank the board maps at window w (of 0x400 bytes)
    def chr_expect(regs, mode, w, outer=0):
        if board == '76':
            b = ((regs[2 + w // 2] & 0x3F) << 1) | (w & 1)
        else:
            if namco:
                mode = 0
            sw = w ^ (4 if mode else 0)
            if sw < 4:
                b = (regs[sw // 2] & 0xFE) | (sw & 1)
            else:
                b = regs[sw - 2]
            if namco:
                b = (b & 0x3F) | (0x40 if w >= 4 else 0)
            if board == 'qj':
                b = (outer << 7) | (b & 0x7F)
        return b % chr_banks

    def chr_test(regs, mode, outer=0):
        for i, r in enumerate(regs):
            bank(i, r, mode << 7)
        for w in range(8):
            ppu_check(0x400 * w, chr_expect(regs, mode, w, outer))

    # Writes each nametable with its own byte; each then reads back the byte
    # of the last nametable written that shares its CIRAM page
    def nt_share(pages, base):
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i + NT_OFFSET, base + i)
        for i in range(4):
            last = max(j for j in range(4) if pages[j] == pages[i])
            ppu_check(0x2000 + 0x400 * i + NT_OFFSET, base + last)

    # Marks CIRAM page 0 and page 1 through the nametables at addr0 and
    # addr1, which must be on those pages
    def nt_mark(addr0, addr1):
        ppu_write(addr0 + NT_OFFSET + 1, 0xA0)
        ppu_write(addr1 + NT_OFFSET + 1, 0xA1)

    # Each nametable reads back the mark of its CIRAM page
    def nt_pages(pages):
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i + NT_OFFSET + 1, 0xA0 + pages[i])

    VERT = [0, 1, 0, 1]
    HORZ = [0, 0, 1, 1]

    def prg_ram_test():
        next_group()
        write(0xA001, 0x80)
        write(0x6000, 0x5A)
        write(0x7FFF, 0xA5)
        cpu_check(0x6000, 0x5A)
        cpu_check(0x7FFF, 0xA5)
        # Write protected
        next_group()
        write(0xA001, 0xC0)
        write(0x6000, 0x11)
        cpu_check(0x6000, 0x5A)
        # Disabled: open bus
        next_group()
        write(0xA001, 0x00)
        write(0x7FFF, 0x22)
        cpu_check(0x6000, 0x60)
        write(0xA001, 0x80)
        cpu_check(0x6000, 0x5A)
        cpu_check(0x7FFF, 0xA5)

    def mmc6_test():
        next_group()
        bank(6, 0, 0x20)
        write(0xA001, 0xF0)
        write(0x7000, 0x11)
        write(0x7200, 0x22)
        write(0x73FF, 0x33)
        write(0x71FF, 0x44)
        # Mirrored every 1KB
        cpu_check(0x7000, 0x11)
        cpu_check(0x7200, 0x22)
        cpu_check(0x7400, 0x11)
        cpu_check(0x7E00, 0x22)
        cpu_check(0x7FFF, 0x33)
        cpu_check(0x7DFF, 0x44)
        next_group()
        # Both halves read only
        write(0xA001, 0xA0)
        write(0x7000, 0x55)
        write(0x7200, 0x55)
        cpu_check(0x7000, 0x11)
        cpu_check(0x7200, 0x22)
        next_group()
        # Lower half only
        write(0xA001, 0x30)
        cpu_check(0x7000, 0x11)
        write(0x7000, 0x77)
        cpu_check(0x7400, 0x77)
        next_group()
        # Upper half only
        write(0xA001, 0xC0)
        cpu_check(0x7200, 0x22)
        write(0x7600, 0x88)
        cpu_check(0x7200, 0x88)
        next_group()
        # Neither: open bus
        write(0xA001, 0x00)
        cpu_check(0x7000, 0x70)
        cpu_check(0x7200, 0x72)
        next_group()
        # Disabled by 0x8000 bit 5, which holds $A001 at 0 (nesdev), so
        # it stays disabled when bit 5 is set again until $A001 is written
        write(0xA001, 0xF0)
        bank(6, 0, 0x00)
        cpu_check(0x7000, 0x70)
        write(0xA001, 0xF0)
        bank(6, 0, 0x20)
        cpu_check(0x7000, 0x70)
        write(0xA001, 0xF0)
        cpu_check(0x7000, 0x77)
        cpu_check(0x7200, 0x88)
        # Write enable without read enable does not write (Mesen writes)
        next_group()
        write(0xA001, 0x50)
        write(0x7000, 0x66)
        write(0x7200, 0x66)
        write(0xA001, 0xF0)
        cpu_check(0x7000, 0x77)
        cpu_check(0x7200, 0x88)
        # A half that cannot be read reads 0 while the other can be read
        # (Mesen reads open bus)
        next_group()
        write(0xA001, 0x30)
        cpu_check(0x7200, 0x00)
        cpu_check(0x7000, 0x77)
        write(0xA001, 0xC0)
        cpu_check(0x7000, 0x00)
        cpu_check(0x7200, 0x88)
        # Nothing at 0x6000-0x6FFF
        next_group()
        cpu_check(0x6000, 0x60)
        cpu_check(0x6FFF, 0x6F)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    write(0x4010, 0x00)
    write(0x4017, 0x40)                         # no frame IRQ
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    next_group()
    # PRG ROM banks, mode 0
    for b in range(set_banks):
        bank(6, b)
        bank_check(0x8000, b)
    next_group()
    for b in (3, set_banks - 3, set_banks - 1):
        bank(7, b)
        bank_check(0xA000, b)
    bank_check(0xC000, set_banks - 2)
    bank_check(0xE000, set_banks - 1)
    # Wider than the ROM
    bank(6, 0xFF - 4)
    bank_check(0x8000, 0xFF - 4 if board != 'qj' else 11)
    bank(6, 5)
    bank(7, 6)
    next_group()
    # Mode 1, or no change on the Namco 108
    write(0x8000, 0x46)
    if namco:
        bank_check(0x8000, 5)
        bank_check(0xC000, set_banks - 2)
    else:
        bank_check(0x8000, set_banks - 2)
        bank_check(0xC000, 5)
    bank_check(0xA000, 6)
    bank_check(0xE000, set_banks - 1)
    write(0x8000, 0x06)
    bank_check(0x8000, 5)
    bank_check(0xC000, set_banks - 2)

    # CHR ROM banks
    regs_a = [(w * 0x29 + 0x13) & 0xFF for w in range(8)][:6]
    regs_b = [0xFF - r for r in regs_a]
    regs_c = [0x07, 0x7E, 0xC1, 0x3F, 0x80, 0x40]
    if board == 'tqrom':
        regs_a = [r & ~0x40 for r in regs_a]
        regs_b = [r & ~0x40 for r in regs_b]
        regs_c = [r & ~0x40 for r in regs_c]
    next_group()
    chr_test(regs_a, 0)
    next_group()
    chr_test(regs_b, 1)
    next_group()
    chr_test(regs_c, 0)
    next_group()
    chr_test(regs_a, 1)

    # The board
    if kind in ('mmc3', 'mmc6') and board != 'txsrom':
        next_group()
        write(0xA000, 0x00)
        nt_share(VERT, 0x40)
        write(0xA000, 0x01)
        nt_share(HORZ, 0x50)
        write(0xA000, 0x00)
        nt_share(VERT, 0x60)

    if board == 'txrom':
        prg_ram_test()
        if v['nes2']:
            next_group()
            # Bit 5 of 0x8000 is not the MMC6 on an MMC3 board
            bank(6, 0, 0x20)
            cpu_check(0x6000, 0x5A)
            write(0x6000, 0x33)
            write(0x7000, 0x44)
            cpu_check(0x6000, 0x33)
            cpu_check(0x7000, 0x44)
            bank(6, 0, 0x00)

    elif board == 'qj':
        next_group()
        # The first set, then the second
        write(0xA001, 0x80)
        write(0x6000, 0x01)
        for b in (0, 5, 15):
            bank(6, b)
            bank_check(0x8000, 16 + b)
        bank(7, 0x13)
        bank_check(0xA000, 16 + 3)
        bank_check(0xC000, 30)
        bank_check(0xE000, 31)
        next_group()
        chr_test(regs_a, 0, outer=1)
        next_group()
        chr_test(regs_b, 1, outer=1)
        next_group()
        # Ignored while protected or disabled
        write(0xA001, 0xC0)
        write(0x6000, 0x00)
        bank_check(0xE000, 31)
        write(0xA001, 0x00)
        write(0x7FFF, 0x00)
        bank_check(0xE000, 31)
        next_group()
        # Back to the first set
        write(0xA001, 0x80)
        write(0x7FFF, 0x02)
        bank_check(0xE000, 15)
        bank_check(0xC000, 14)
        bank_check(0xA000, 3)
        next_group()
        chr_test(regs_c, 0, outer=0)

    elif board == 'txsrom':
        next_group()
        # R0 and R1 select the pages in CHR mode 0
        bank(0, 0x00)
        bank(1, 0x80)
        nt_mark(0x2000, 0x2800)
        nt_pages([0, 0, 1, 1])
        bank(0, 0x80)
        bank(1, 0x00)
        nt_pages([1, 1, 0, 0])
        bank(1, 0x80)
        nt_pages([1, 1, 1, 1])
        next_group()
        # $A000 does nothing
        write(0xA000, 0x00)
        nt_pages([1, 1, 1, 1])
        write(0xA000, 0x01)
        bank(0, 0x00)
        bank(1, 0x00)
        nt_pages([0, 0, 0, 0])
        next_group()
        # R2-R5 select the pages in CHR mode 1
        for i, r in enumerate((0x80, 0x00, 0x00, 0x80)):
            bank(2 + i, r, 0x80)
        nt_pages([1, 0, 0, 1])
        bank(2, 0x05, 0x80)
        bank(5, 0x86, 0x80)
        nt_pages([0, 0, 0, 1])
        next_group()
        # Bit 7 does not select CHR ROM
        ppu_check(0x0000, 0x05)
        ppu_check(0x0C00, 0x06)
        write(0x8000, 0x00)
        prg_ram_test()

    elif board == 'tqrom':
        next_group()
        bank(2, 0x40)
        bank(3, 0x41)
        bank(4, 0x05)
        bank(5, 0x47)
        ppu_write(0x1000, 0xC0)
        ppu_write(0x1400, 0xC1)
        ppu_write(0x1C00, 0xC7)
        # CHR ROM ignores writes
        ppu_write(0x1800, 0xEE)
        ppu_check(0x1000, 0xC0)
        ppu_check(0x1400, 0xC1)
        ppu_check(0x1800, 0x05)
        ppu_check(0x1C00, 0xC7)
        next_group()
        # 8KB of RAM, so bank 8 is bank 0; and RAM in a 2KB bank
        bank(4, 0x48)
        ppu_check(0x1800, 0xC0)
        bank(0, 0x46)
        ppu_write(0x0400, 0xC4)
        ppu_check(0x0400, 0xC4)
        bank(3, 0x47)
        ppu_check(0x1400, 0xC4)
        bank(0, 0x02)
        ppu_check(0x0000, 0x02)
        ppu_check(0x0400, 0x03)
        prg_ram_test()

    elif board == 'mmc6':
        mmc6_test()

    elif board == 'mmc6_ines':
        # An MMC3 until bit 5 of 0x8000 is set
        prg_ram_test()
        next_group()
        write(0x6000, 0x33)
        write(0x7000, 0x35)
        write(0x7400, 0x34)
        cpu_check(0x6000, 0x33)
        cpu_check(0x7000, 0x35)
        cpu_check(0x7400, 0x34)
        # Bit 5 makes it an MMC6, which it stays with bit 5 clear
        next_group()
        bank(6, 0, 0x20)
        write(0xA001, 0xF0)
        cpu_check(0x6000, 0x60)
        bank(6, 0, 0x00)
        write(0xA001, 0x80)
        cpu_check(0x6000, 0x60)
        cpu_check(0x7000, 0x70)
        mmc6_test()

    elif board in ('206', '76'):
        next_group()
        nt_share(VERT, 0x40)

    elif board == '88':
        next_group()
        nt_share(HORZ, 0x40)

    elif board == '95':
        next_group()
        bank(0, 0x00)
        bank(1, 0x20)
        nt_mark(0x2000, 0x2800)
        nt_pages([0, 0, 1, 1])
        bank(0, 0x20)
        bank(1, 0x00)
        nt_pages([1, 1, 0, 0])
        bank(1, 0x20)
        nt_pages([1, 1, 1, 1])
        bank(0, 0x00)
        bank(1, 0x00)
        nt_pages([0, 0, 0, 0])
        next_group()
        # Bit 7 of 0x8000 does not swap R0/R1 with R2-R5
        bank(2, 0x20, 0x80)
        bank(4, 0x20, 0x80)
        nt_pages([0, 0, 0, 0])
        ppu_check(0x1000, 0x00)

    elif board == '154':
        next_group()
        write(0x8000, 0x00)
        ppu_write(0x2000 + NT_OFFSET + 1, 0xA0)
        write(0x8000, 0x40)
        ppu_write(0x2000 + NT_OFFSET + 1, 0xA1)
        nt_pages([1, 1, 1, 1])
        write(0xC000, 0x00)
        nt_pages([0, 0, 0, 0])
        write(0xE001, 0x40)
        nt_pages([1, 1, 1, 1])
        write(0xA001, 0x00)
        nt_pages([0, 0, 0, 0])
        next_group()
        # Bank data writes too
        write(0x8000, 0x02)
        write(0x8001, 0x43)
        nt_pages([1, 1, 1, 1])
        ppu_check(0x1000, 0x43)

    if namco:
        next_group()
        # The registers are only at 0x8000-0x9FFF
        bank(6, 2)
        bank(2, 0x04)
        write(0xA000, 0x06)
        write(0xA001, 0x07)
        write(0xC000, 0x06)
        write(0xC001, 0x08)
        write(0xE000, 0x06)
        write(0xE001, 0x09)
        bank_check(0x8000, 2)
        write(0x9FFF, 0x0A)
        ppu_check(0x0000 if board == '76' else 0x1000,
                  chr_expect([0, 0, 0x0A, 0, 0, 0], 0,
                             0 if board == '76' else 4))
        write(0x9FFE, 0x06)
        write(0x9FFF, 0x03)
        bank_check(0x8000, 3)
        next_group()
        # No PRG RAM
        write(0x6000, 0x5A)
        cpu_check(0x6000, 0x60)

    a.emit(LDX_IMM, PASS_COLOR)

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show')
    a.emit(SEI)
    a.emit(STY_ZP, DETAIL)
    wait_vblank('vblank_3')
    write(0x2006, 0x3F)
    write(0x2006, 0x00)
    a.abs(STX_ABS, 0x2007)
    write(0x2006, 0x00)
    a.abs(STA_ABS, 0x2006)
    a.label('loop')
    a.abs_label(JMP_ABS, 'loop')

    a.label('nmi')
    a.emit(RTI)

    code = a.link()
    assert ORG + len(code) <= 0xE000 + SIG_HI, 'code runs into SIG_HI'

    prg = bytearray([0xFF]) * (0x2000 * prg_banks)
    for b in range(prg_banks):
        prg[0x2000 * b + SIG_LO] = b
        prg[0x2000 * b + SIG_HI] = b ^ 0xFF

    # The last bank, and on NES-QJ the last of each set
    code_banks = [prg_banks - 1]
    if board == 'qj':
        code_banks.append(set_banks - 1)
    for cb in code_banks:
        base = 0x2000 * cb - 0xE000
        prg[base + ORG:base + ORG + len(code)] = code
        for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'),
                          (0xFFFE, 'nmi')):
            prg[base + vec] = a.labels[name] & 0xFF
            prg[base + vec + 1] = a.labels[name] >> 8

    chr_rom = bytearray(0x400 * chr_banks)
    for b in range(chr_banks):
        chr_rom[0x400 * b] = b

    mapper = v['mapper']
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((mapper & 0x0F) << 4) | (0x01 if v['vertical'] else 0) |
                     (0x02 if kind == 'mmc6' else 0),
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[8] = (v.get('submapper', 0) << 4) | (mapper >> 8)
        # 8KB of PRG RAM, or the 1KB of battery backed PRG RAM of the MMC6,
        # which Mesen needs to map it
        header[10] = 0x40 if kind == 'mmc6' else 0x07

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
