#!/usr/bin/env python3
"""Generate test ROMs for the discrete logic boards with ROM banks: NROM
(mapper 0), UxROM (2), CNROM (3), AxROM (7), Color Dreams (11), BNROM and
NINA-001 (34) and GxROM (66). latch_chr_ram.py covers the boards with banked
CHR RAM.

Usage: latch.py OUT.nes VARIANT

The ROM checks, in groups:
  1 PRG ROM banks: each 8KB bank holds its number at SIG_LO and its
    complement at SIG_HI. Every bank the latch can select is checked in
    each window it covers, and the fixed bank of UxROM. UxROM also checks
    that the bank number wraps at the size of the ROM
  2 PRG RAM at 0x6000-0x7FFF on the boards that have it
  3 CHR ROM banks: each 1KB bank holds its number at its first byte, read
    back through $2006/$2007 at the first and last 1KB of each window. The
    boards with CHR RAM write and read it back
  4 Mirroring: fixed by the header, or the single screen selected by the
    latch of AxROM

The latches at 0x8000-0xFFFF are written through a table in every bank
whose byte at 0xF000+n is n, so that a board with bus conflicts reads back
what is written. The code is the same in every 32KB bank, so it runs on
whichever bank the latch selects. Rendering stays off, so the PPU can be
accessed at any time.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed; the
index of the failing check within its group is at zero page DETAIL. A group
a board does not have is empty, so the numbers are the same for every
variant. The result is up a few frames after reset, so 250ms of nes_bench is
enough.

Variants:
  nrom_128      iNES mapper 0, horizontal, 16KB PRG: 0xC000 mirrors 0x8000.
                PRG RAM (Family BASIC)
  nrom_256_v    iNES mapper 0, vertical, 32KB PRG
  uxrom         iNES mapper 2, vertical, 128KB PRG (UNROM), CHR RAM
  uorom         iNES mapper 2, horizontal, 256KB PRG (UOROM)
  cnrom         iNES mapper 3, vertical, 32KB PRG, 32KB CHR
  axrom         iNES mapper 7, 256KB PRG (AOROM), CHR RAM: latch bit 4
                selects the nametable for single screen mirroring
  colordreams   iNES mapper 11, vertical, 128KB PRG (bits 1-0), 128KB CHR
                (bits 7-4)
  bnrom_ines    iNES mapper 34, 8KB CHR RAM: BNROM, 256KB PRG
  bnrom_nes2    NES 2.0 mapper 34 submapper 2: BNROM
  nina001_ines  iNES mapper 34, 64KB CHR: NINA-001, latches at $7FFD (32KB
                PRG bank), $7FFE and $7FFF (4KB CHR banks at 0x0000 and
                0x1000), with PRG RAM
  nina001_nes2  NES 2.0 mapper 34 submapper 1: NINA-001
  gxrom         iNES mapper 66, horizontal, 128KB PRG (bits 5-4), 32KB CHR
                (bits 1-0)

Mesen passes all of them.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

# prg: 16KB units; chr: 8KB units of CHR ROM, 0 for 8KB of CHR RAM
# prg_mode: 32 (32KB banks), 16 (16KB banks, last fixed) or None (no banks)
# chr_mode: 8 (8KB banks), 4 (4KB banks) or None (no banks)
VARIANTS = {
    'nrom_128':     dict(mapper=0, prg=1, chr=1, mirror='horz',
                         prg_mode=None, chr_mode=None, prg_ram=True),
    'nrom_256_v':   dict(mapper=0, prg=2, chr=1, mirror='vert',
                         prg_mode=None, chr_mode=None, prg_ram=True),
    'uxrom':        dict(mapper=2, prg=8, chr=0, mirror='vert',
                         prg_mode=16, chr_mode=None),
    'uorom':        dict(mapper=2, prg=16, chr=0, mirror='horz',
                         prg_mode=16, chr_mode=None),
    'cnrom':        dict(mapper=3, prg=2, chr=4, mirror='vert',
                         prg_mode=None, chr_mode=8),
    'axrom':        dict(mapper=7, prg=16, chr=0, mirror='single',
                         prg_mode=32, chr_mode=None),
    'colordreams':  dict(mapper=11, prg=8, chr=16, mirror='vert',
                         prg_mode=32, chr_mode=8),
    'bnrom_ines':   dict(mapper=34, prg=16, chr=0, mirror='vert',
                         prg_mode=32, chr_mode=None),
    'bnrom_nes2':   dict(mapper=34, submapper=2, nes2=True, prg=16, chr=0,
                         mirror='horz', prg_mode=32, chr_mode=None),
    'nina001_ines': dict(mapper=34, prg=4, chr=8, mirror='horz',
                         prg_mode=32, chr_mode=4, prg_ram=True, nina=True),
    'nina001_nes2': dict(mapper=34, submapper=1, nes2=True, prg=4, chr=8,
                         mirror='vert', prg_mode=32, chr_mode=4,
                         prg_ram=True, nina=True),
    'gxrom':        dict(mapper=66, prg=8, chr=4, mirror='horz',
                         prg_mode=32, chr_mode=8),
}

PASS_COLOR = 0x2A

# The code is in the last 8KB of each 32KB of PRG ROM, at 0xE000, with the
# table of latch values at TABLE. Each 8KB bank holds its number at SIG_LO
# and its complement at SIG_HI, clear of the code, the table and the vectors
ORG = 0xE100
TABLE = 0xF000
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# Zero page
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
LDX_IMM, LDY_IMM, CMP_IMM, BIT_ABS, TAY = 0xA2, 0xA0, 0xC9, 0x2C, 0xA8
STY_ZP = 0x84
BPL, BEQ, JMP_ABS, JSR, RTS, RTI = 0x10, 0xF0, 0x4C, 0x20, 0x60, 0x40
STA_ABS_Y = 0x99


# The value written to the latch of the board, or None if the bank is
# selected by a latch of its own (NINA-001)
def latch_value(v, prg=0, chr=0, nt=0):
    m = v['mapper']
    if m == 2 or m == 34:
        return prg
    if m == 3:
        return chr
    if m == 7:
        return (nt << 4) | prg
    if m == 11:
        return (chr << 4) | prg
    if m == 66:
        return (prg << 4) | chr
    raise ValueError(m)


def build(v):
    a = Assembler()
    group = [1]
    detail = [0]
    nina = v.get('nina', False)
    prg_8kb = v['prg'] * 2
    chr_1kb = v['chr'] * 8

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def set_latch(value):
        a.emit(LDA_IMM, value)
        a.abs_label(JSR, 'set_latch')

    def ppu_addr(addr):
        a.emit(LDA_IMM, addr >> 8)
        a.abs(STA_ABS, 0x2006)
        a.emit(LDA_IMM, addr & 0xFF)
        a.abs(STA_ABS, 0x2006)

    def ppu_write(addr, value):
        ppu_addr(addr)
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, 0x2007)

    def next_group():
        group[0] += 1
        detail[0] = 0
        assert group[0] < PASS_COLOR

    # Fails with the group number unless A is value
    def check(value):
        a.emit(LDX_IMM, group[0])
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

    def bank_check(window, bank):
        cpu_check(window + SIG_LO, bank)
        cpu_check(window + SIG_HI, bank ^ 0xFF)

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    a.label('reset')
    a.emit(0x78, 0xD8, 0xA2, 0xFF, 0x9A)        # SEI CLD LDX #$FF TXS
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # PRG ROM banks
    if v['prg_mode'] is None:
        for w in range(4):
            bank_check(0x8000 + 0x2000 * w, w % prg_8kb)
    elif v['prg_mode'] == 16:
        banks = prg_8kb // 2
        for b in range(banks):
            set_latch(latch_value(v, prg=b))
            bank_check(0x8000, 2 * b)
            bank_check(0xA000, 2 * b + 1)
            bank_check(0xC000, prg_8kb - 2)
            bank_check(0xE000, prg_8kb - 1)
        # The bank number wraps at the size of the ROM
        set_latch(latch_value(v, prg=banks + 3))
        bank_check(0x8000, 6)
        set_latch(latch_value(v, prg=0))
    else:
        for b in range(prg_8kb // 4):
            if nina:
                write(0x7FFD, b)
            else:
                set_latch(latch_value(v, prg=b))
            for w in range(4):
                bank_check(0x8000 + 0x2000 * w, 4 * b + w)
        if nina:
            write(0x7FFD, 0)
        else:
            set_latch(latch_value(v, prg=0))

    # PRG RAM
    next_group()
    if v.get('prg_ram', False):
        write(0x6000, 0xA5)
        write(0x7FFC, 0x5A)
        cpu_check(0x6000, 0xA5)
        cpu_check(0x7FFC, 0x5A)

    # CHR
    next_group()
    if v['chr'] == 0:
        ppu_write(0x0000, 0xC3)
        ppu_write(0x1FFF, 0x3C)
        ppu_check(0x0000, 0xC3)
        ppu_check(0x1FFF, 0x3C)
    elif v['chr_mode'] is None:
        for w in range(8):
            ppu_check(0x0400 * w, w)
    elif v['chr_mode'] == 8:
        for b in range(chr_1kb // 8):
            set_latch(latch_value(v, chr=b))
            ppu_check(0x0000, 8 * b)
            ppu_check(0x1C00, 8 * b + 7)
    else:
        # NINA-001: 4KB banks at 0x0000 ($7FFE) and 0x1000 ($7FFF)
        banks = chr_1kb // 4
        for b in range(banks):
            write(0x7FFE, b)
            write(0x7FFF, banks - 1 - b)
            ppu_check(0x0000, 4 * b)
            ppu_check(0x0C00, 4 * b + 3)
            ppu_check(0x1000, 4 * (banks - 1 - b))
            ppu_check(0x1C00, 4 * (banks - 1 - b) + 3)

    # Nametables. Each of the four is written with its own byte, so the
    # bytes read back show which share CIRAM
    def nt_test(nt, expect):
        if v['mirror'] == 'single':
            set_latch(latch_value(v, nt=nt))
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * nt + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * nt + expect[i])

    next_group()
    m = v['mirror']
    if m == 'horz':
        nt_test(0, [1, 1, 3, 3])
    elif m == 'vert':
        nt_test(0, [2, 3, 2, 3])
    elif m == 'single':
        nt_test(0, [3, 3, 3, 3])
        nt_test(1, [3, 3, 3, 3])
        # Back to the first nametable, which the second write left alone
        set_latch(latch_value(v, nt=0))
        ppu_check(0x2400, 0x43)

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

    a.label('set_latch')
    a.emit(TAY)
    a.abs(STA_ABS_Y, TABLE)
    a.emit(RTS)

    a.label('rti')
    a.emit(RTI)

    code = a.link()
    assert ORG + len(code) <= TABLE, 'code runs into the table'

    prg = bytearray([0xFF]) * (0x2000 * prg_8kb)
    for b in range(prg_8kb):
        prg[0x2000 * b + SIG_LO] = b
        prg[0x2000 * b + SIG_HI] = b ^ 0xFF

    # The code, the table and the vectors in the last 8KB bank, and in the
    # last 8KB of every 32KB bank of the boards that switch 32KB
    if v['prg_mode'] == 32:
        code_banks = range(3, prg_8kb, 4)
    else:
        code_banks = [prg_8kb - 1]
    for b in code_banks:
        base = 0x2000 * b - 0xE000
        prg[base + ORG:base + ORG + len(code)] = code
        prg[base + TABLE:base + TABLE + 0x100] = bytes(range(256))
        for vec, name in ((0xFFFA, 'rti'), (0xFFFC, 'reset'), (0xFFFE, 'rti')):
            prg[base + vec] = a.labels[name] & 0xFF
            prg[base + vec + 1] = a.labels[name] >> 8

    chr_rom = bytearray(0x400 * chr_1kb)
    for b in range(chr_1kb):
        chr_rom[0x400 * b] = b

    mapper = v['mapper']
    nes2 = v.get('nes2', False)
    header = bytearray(b'NES\x1a')
    header += bytes([v['prg'], v['chr'],
                     ((mapper & 0x0F) << 4) |
                     (0x01 if v['mirror'] == 'vert' else 0x00),
                     (mapper & 0xF0) | (0x08 if nes2 else 0x00)])
    header += bytes(8)
    if nes2:
        header[8] = v['submapper'] << 4
        if v.get('prg_ram', False):
            header[10] = 0x07                   # 8KB PRG RAM
        if v['chr'] == 0:
            header[11] = 0x07                   # 8KB CHR RAM

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
