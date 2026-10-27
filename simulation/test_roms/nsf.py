#!/usr/bin/env python3
"""Generate the test ROM for the NSF subset board (mapper 31): eight
registers at 0x5000-0x5FFF, selected by A2-A0, select the 4KB PRG ROM banks
at 0x8000-0xFFFF.

Usage: nsf.py OUT.nes VARIANT

The ROM has 1MB of PRG ROM, the most the 8-bit registers select, and 8KB
of CHR RAM. It first checks that the last bank is at 0xF000 at power on,
then loads every register, then makes a series of writes, some of them
outside 0x5000-0x5FFF, and after each one checks the bank of each 4KB
window, in groups:
  1 The bank at 0xF000 at power on
  2 PRG ROM banks: each 4KB bank holds its number at SIG_LO and its
    complement at SIG_HI, read in each window

The code is the same in every 4KB bank, at the same offset, so it runs on
whichever bank is at 0xF000.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed; the
number of the write after which it failed is at zero page DETAIL and the
index of the check in its table at DETAIL+1. The result is up a few frames
after reset, so 250ms of nes_bench is enough.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

PASS_COLOR = 0x2A

# The code is at ORG in every 4KB bank. Each 4KB bank holds its number at
# SIG_LO and its complement at SIG_HI, clear of the code and the vectors
ORG = 0xF100
SIG_LO = 0x0010
SIG_HI = 0x0FF0

PRG_BANKS = 256

# Zero page
DETAIL = 0x00
GROUP = 0x02
PTR = 0x10

VARIANTS = ('31',)

# The first loads of the registers, then the writes checked one by one:
# each register at its NSF address and at the bottom of 0x5000-0x5FFF,
# values that toggle each bit, and writes outside the registers
SETUP = [(0x5FF8 + i, 0x11 * i + 3) for i in range(8)]
WRITES = ([(0x5FF8 + i, 0xFF - i) for i in range(8)] +
          [(0x5000 + i, (0x55, 0xAA, 0x01, 0x80, 0x0F, 0xF0, 0x7E, 0xC3)[i])
           for i in range(8)] +
          [(0x5ABC, 0x42), (0x5D53, 0x24), (0x4FFF, 0x00), (0x6000, 0x00),
           (0x7FFF, 0x00), (0x8000, 0x00), (0xFFFF, 0x01), (0x4100, 0x02),
           (0x5FFF, 0x00), (0x5FFF, 0xFF), (0x5555, 0x99)])


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
STA_ZP, STY_ZP, LDX_ZP, CMP_IND_Y = 0x85, 0x84, 0xA6, 0xD1
INY = 0xC8
BPL, BEQ, BNE, JMP_ABS, JSR, RTS, RTI = 0x10, 0xF0, 0xD0, 0x4C, 0x20, 0x60, \
    0x40


def build():
    a = Assembler()
    regs = [0] * 7 + [PRG_BANKS - 1]

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    def model_write(addr, value):
        if 0x5000 <= addr < 0x6000:
            regs[addr & 7] = value % PRG_BANKS

    def group(n):
        assert n < PASS_COLOR
        a.emit(LDA_IMM, n)
        a.emit(STA_ZP, GROUP)

    a.label('reset')
    a.emit(0x78, 0xD8, 0xA2, 0xFF, 0x9A)        # SEI CLD LDX #$FF TXS
    write(0x2000, 0)
    write(0x2001, 0)
    write(0x4017, 0x40)                         # no frame IRQ
    a.emit(LDA_IMM, 0xFF)
    a.emit(STA_ZP, DETAIL)

    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # The last bank at 0xF000 at power on
    group(1)
    a.emit(LDY_IMM, 0)
    a.abs(LDA_ABS, 0xF000 + SIG_LO)
    a.emit(CMP_IMM, PRG_BANKS - 1)
    a.emit(BEQ, 3)
    a.abs_label(JMP_ABS, 'fail')

    for addr, value in SETUP:
        model_write(addr, value)
        write(addr, value)

    # The writes, each with the table of the checks after it
    tables = []
    for n, (addr, value) in enumerate(WRITES):
        model_write(addr, value)
        write(addr, value)
        a.emit(LDA_IMM, n)
        a.emit(STA_ZP, DETAIL)
        name = 'table_%d' % n
        a.imm_label(LDA_IMM, name, False)
        a.emit(STA_ZP, PTR)
        a.imm_label(LDA_IMM, name, True)
        a.emit(STA_ZP, PTR + 1)
        a.abs_label(JSR, 'verify')
        tables.append((name, bytes(regs) + bytes([regs[0] ^ 0xFF])))

    a.emit(LDX_IMM, PASS_COLOR)
    a.abs_label(JMP_ABS, 'show')

    # Checks the selected banks against the table at PTR
    a.label('verify')
    a.emit(LDY_IMM, 0)
    group(2)
    for w in range(8):
        a.abs(LDA_ABS, 0x8000 + 0x1000 * w + SIG_LO)
        a.abs_label(JSR, 'cmp_next')
    a.abs(LDA_ABS, 0x8000 + SIG_HI)
    a.abs_label(JSR, 'cmp_next')
    a.emit(RTS)

    # Fails unless A is the byte of the table at Y, then moves to the next
    a.label('cmp_next')
    a.emit(CMP_IND_Y, PTR)
    a.branch(BNE, 'fail')
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
    assert ORG + len(code) <= 0xF000 + SIG_HI, 'code runs into SIG_HI'

    prg = bytearray([0xFF]) * (0x1000 * PRG_BANKS)
    for b in range(PRG_BANKS):
        base = 0x1000 * b
        prg[base + SIG_LO] = b
        prg[base + SIG_HI] = b ^ 0xFF
        prg[base + ORG - 0xF000:base + ORG - 0xF000 + len(code)] = code
        for vec, name in ((0x0FFA, 'rti'), (0x0FFC, 'reset'), (0x0FFE, 'rti')):
            prg[base + vec] = a.labels[name] & 0xFF
            prg[base + vec + 1] = a.labels[name] >> 8

    mapper = 31
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, 0, ((mapper & 0x0F) << 4) | 0x01,
                     mapper & 0xF0])
    header += bytes(8)

    return bytes(header + prg)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build())


if __name__ == '__main__':
    main()
