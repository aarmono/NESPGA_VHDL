#!/usr/bin/env python3
"""Generate test ROMs for the discrete logic boards with banked CHR RAM:
CPROM (mapper 13) and UNROM 512 (mapper 30).

Usage: latch_chr_ram.py OUT.nes {cprom,unrom512,flash,single,four,hv}

The ROM writes a different byte to each bank of CHR RAM (and of PRG ROM, for
UNROM 512), selecting the bank with the latch, then reads them all back
through $2006/$2007. It then checks the nametable arrangement of the board.
Rendering stays off, so the PPU can be accessed at any time.

The latch is written through a table in the fixed bank whose byte at
$F000+n is n, so that a board with bus conflicts reads back what is written.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the color of the step that failed (1 is the first byte
read back). The result is up a few frames after reset, so 250ms of
nes_bench is enough.

Variants:
  cprom     iNES mapper 13, vertical: 4KB CHR RAM banks at $1000, the first
            fixed at $0000. iNES gives CPROM 16KB of CHR RAM
  unrom512  iNES mapper 30, horizontal, no battery: 32 16KB PRG banks and
            four 8KB CHR RAM banks, latch at $8000-$FFFF. iNES gives
            UNROM 512 32KB of CHR RAM
  flash     As unrom512, vertical, with the battery bit (flash): the latch
            is only at $C000-$FFFF, so a write to $8000 is checked to leave
            the PRG bank alone
  single    As unrom512 with byte 6 bits 3,0 = 1,0: latch bit 7 selects the
            nametable for single screen mirroring
  four      As unrom512 with byte 6 bits 3,0 = 1,1: the nametables, and
            $3000-$3EFF, are the last 8KB of CHR RAM
  hv        NES 2.0 mapper 30 submapper 3: latch bit 7 selects vertical (1)
            or horizontal (0) mirroring

Mesen passes all of them.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    'cprom':    dict(mapper=13, prg_banks=0, chr_banks=4, nes2=False,
                     pads=0x01, battery=False, mirror='vert'),
    'unrom512': dict(mapper=30, prg_banks=32, chr_banks=4, nes2=False,
                     pads=0x00, battery=False, mirror='horz'),
    'flash':    dict(mapper=30, prg_banks=32, chr_banks=4, nes2=False,
                     pads=0x01, battery=True, mirror='vert'),
    'single':   dict(mapper=30, prg_banks=32, chr_banks=4, nes2=False,
                     pads=0x08, battery=False, mirror='single'),
    'four':     dict(mapper=30, prg_banks=32, chr_banks=4, nes2=False,
                     pads=0x09, battery=False, mirror='four'),
    'hv':       dict(mapper=30, prg_banks=32, chr_banks=4, nes2=True,
                     pads=0x00, battery=False, mirror='hv'),
}

PASS_COLOR = 0x2A

# The code is in the last 16KB, which both boards have fixed at 0xC000. Each
# 16KB PRG bank of UNROM 512 holds its number at SIG_LO and its complement
# at SIG_HI, which are kept clear of the code, the table and the vectors
ORG = 0xC100
TABLE = 0xF000
SIG_LO = 0x0008
SIG_HI = 0x3FF0


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
LDX_IMM, CMP_IMM, BIT_ABS, TAY = 0xA2, 0xC9, 0x2C, 0xA8
BPL, BEQ, JMP_ABS, JSR, RTS, RTI = 0x10, 0xF0, 0x4C, 0x20, 0x60, 0x40
STA_ABS_Y = 0x99


def build(v):
    a = Assembler()
    step = [1]

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

    # Fails with the next step number unless A is value
    def check(value):
        a.emit(LDX_IMM, step[0])
        a.emit(CMP_IMM, value)
        a.emit(BEQ, 3)
        a.abs_label(JMP_ABS, 'show')
        step[0] += 1

    def ppu_check(addr, value):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)                  # the read buffer
        a.abs(LDA_ABS, 0x2007)
        check(value)

    def cpu_check(addr, value):
        a.abs(LDA_ABS, addr)
        check(value)

    def latch(prg=0, chr=0, nt=0):
        set_latch((nt << 7) | (chr << 5) | prg if v['mapper'] == 30 else chr)

    a.label('reset')
    a.emit(0x78, 0xD8, 0xA2, 0xFF, 0x9A)        # SEI CLD LDX #$FF TXS
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # PRG ROM banks
    for b in range(v['prg_banks']):
        latch(prg=b)
        cpu_check(0x8000 + SIG_LO, b)
        cpu_check(0x8000 + SIG_HI, b ^ 0xFF)

    if v['battery']:
        # Only 0xC000-0xFFFF has the latch. The flash takes a write of 0 at
        # 0x8000 as no command
        latch(prg=1)
        a.emit(LDA_IMM, 0x00)
        a.abs(STA_ABS, 0x8000)
        cpu_check(0x8000 + SIG_LO, 1)

    # CHR RAM banks. CPROM banks 4KB at 0x1000 only, so bank 0 there is the
    # same RAM as 0x0000, which no bank select moves
    if v['mapper'] == 13:
        for b in range(v['chr_banks']):
            latch(chr=b)
            ppu_write(0x1010, 0xE0 + b)
            ppu_write(0x1FFF, 0xF0 + b)
        latch(chr=3)
        ppu_write(0x0020, 0x99)
        for b in range(v['chr_banks']):
            latch(chr=b)
            ppu_check(0x1010, 0xE0 + b)
            ppu_check(0x1FFF, 0xF0 + b)
            ppu_check(0x0020, 0x99)
        latch(chr=0)
        ppu_check(0x1020, 0x99)
        ppu_check(0x0010, 0xE0)
    else:
        for b in range(v['chr_banks']):
            latch(chr=b)
            ppu_write(0x0000, 0xC0 + b)
            ppu_write(0x1FFF, 0xD0 + b)
        for b in range(v['chr_banks']):
            latch(chr=b)
            ppu_check(0x0000, 0xC0 + b)
            ppu_check(0x1FFF, 0xD0 + b)

    # Nametables. Each of the four is written with its own byte, so the
    # bytes read back show which share CIRAM
    def nt_test(nt, expect):
        latch(nt=nt)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * nt + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * nt + expect[i])

    m = v['mirror']
    if m == 'horz':
        nt_test(0, [1, 1, 3, 3])
    elif m == 'vert':
        nt_test(0, [2, 3, 2, 3])
    elif m == 'hv':
        nt_test(0, [1, 1, 3, 3])
        nt_test(1, [2, 3, 2, 3])
        # Back to horizontal: 0x2000 and 0x2400 are the nametable that
        # 0x2000 and 0x2800 were
        latch(nt=0)
        ppu_check(0x2400, 0x52)
    elif m == 'single':
        nt_test(0, [3, 3, 3, 3])
        nt_test(1, [3, 3, 3, 3])
        latch(nt=0)
        ppu_check(0x2400, 0x43)
    elif m == 'four':
        nt_test(0, [0, 1, 2, 3])
        ppu_write(0x3000, 0x35)
        ppu_check(0x2000, 0x40)
        ppu_check(0x3000, 0x35)
        # The nametables are CHR RAM bank 3, whichever bank is at 0x0000
        latch(chr=3)
        for i in range(4):
            ppu_check(0x0400 * i, 0x40 + i)
        ppu_check(0x1000, 0x35)
        latch(chr=0)
        ppu_check(0x2C00, 0x43)

    a.emit(LDX_IMM, PASS_COLOR)

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

    a.label('set_latch')
    a.emit(TAY)
    a.abs(STA_ABS_Y, TABLE)
    a.emit(RTS)

    a.label('rti')
    a.emit(RTI)

    code = a.link()
    assert ORG + len(code) <= TABLE, 'code runs into the table'

    if v['mapper'] == 13:
        prg = bytearray([0xFF]) * 0x8000
    else:
        prg = bytearray([0xFF]) * (0x4000 * v['prg_banks'])
        for b in range(v['prg_banks']):
            prg[0x4000 * b + SIG_LO] = b
            prg[0x4000 * b + SIG_HI] = b ^ 0xFF

    last = len(prg) - 0x4000
    prg[last + ORG - 0xC000:last + ORG - 0xC000 + len(code)] = code
    prg[last + TABLE - 0xC000:last + TABLE - 0xC000 + 0x100] = bytes(range(256))
    for vec, name in ((0xFFFA, 'rti'), (0xFFFC, 'reset'), (0xFFFE, 'rti')):
        prg[last + vec - 0xC000] = a.labels[name] & 0xFF
        prg[last + vec - 0xC000 + 1] = a.labels[name] >> 8

    mapper = v['mapper']
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, 0,
                     ((mapper & 0x0F) << 4) | v['pads'] |
                     (0x02 if v['battery'] else 0x00),
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[8] = 0x30                        # submapper 3
        header[11] = 0x09                       # 32KB CHR RAM

    return bytes(header + prg)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
