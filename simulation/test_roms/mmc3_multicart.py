#!/usr/bin/env python3
"""Generate test ROMs for the MMC3 multicart boards (mappers 37, 44, 45, 49
and 52), whose outer bank registers select the part of PRG ROM and CHR ROM
the MMC3 banks within.

Usage: mmc3_multicart.py OUT.nes VARIANT

Each variant has a model of its board, written from the nesdev wiki, which
gives the banks of the four PRG windows and eight CHR windows after each
write. The MMC3 itself is left to mmc3.py: PRG and CHR modes stay 0. The
ROM makes a series of writes to the MMC3 and to the outer registers, some
of them while the board must ignore them, and after each one checks the
banks against the model, in groups:
  1 PRG ROM banks: each 8KB bank holds its number at SIG_LO and its
    complement at SIG_HI, read at 0x8000, 0xA000, 0xC000 and 0xE000
  2 CHR ROM banks: the first two bytes of each 1KB bank hold its number,
    low byte first, read back through $2006/$2007 at each 1KB window
  3 PRG RAM after the writes: open bus on the boards with an outer register
    in its place (37, 49), otherwise the RAM, written where the board has
    no register

The code is the same in every 8KB bank, at the same offset, so it runs on
whichever bank is at 0xE000. Rendering stays off, so the PPU can be accessed
at any time.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed; the
number of the write after which it failed is at zero page DETAIL and the
index of the check in its table at DETAIL+1. The result is up a few frames
after reset, so 250ms of nes_bench is enough.

Mesen follows nesdev but on: 37, where it takes CHR A17 from the MMC3
while Q2 is clear and with the latch at 7 maps PRG A19 (past the ROM)
rather than A16 and A17; 45, whose registers it decodes at all of
0x6000-0x7FFF and does not reset on a write with A0 set; and the open bus
of 37 and 49, since it gives every board PRG RAM. With MESEN set, the ROMs
model 37 as Mesen does and leave out the other checks, and Mesen passes
them all.

Not covered: CHR A20 of 45 (the ROM has 1MB of CHR) and its menu selection
DIP switch, and the CHR RAM variants of 52.

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

# Builds the ROMs for Mesen, see above
MESEN = False

# Zero page
DETAIL = 0x00
GROUP = 0x02
PTR = 0x10


def bit(v, n):
    return (v >> n) & 1


# Values for the MMC3 bank registers R0-R7, with high bits set so that the
# outer registers have bits to mask
INNER_A = [0x5A, 0xA7, 0x3C, 0xC3, 0x96, 0x69, 0x35, 0xCA]
INNER_B = [0xFE, 0x01, 0xFF, 0x80, 0x7F, 0x40, 0xFF, 0x1E]


def inner(regs):
    """The writes that load R0-R7 with regs"""
    w = []
    for i, r in enumerate(regs):
        w += [(0x8000, i), (0x8001, r)]
    return w


class Multicart:
    """A board after reset. prg is in 8KB banks, chr in 1KB banks"""

    mapper = 0
    prg = 32
    chr = 256
    # 0x6000-0x7FFF is an outer register, which reads open bus
    open_6000 = False
    # An address with PRG RAM and no outer register
    ram_addr = 0x6000

    def __init__(self):
        self.r = [0] * 8
        self.idx = 0
        self.a001 = 0
        self.reset()

    def reset(self):
        pass

    def write(self, addr, value):
        if addr >= 0x8000:
            reg = addr & 0xE001
            if reg == 0x8000:
                self.idx = value & 7
            elif reg == 0x8001:
                self.r[self.idx] = value
            elif reg == 0xA001:
                self.a001 = value
        self.write_outer(addr, value)

    # A write to PRG RAM enabled without write protection
    def ram_write(self, addr):
        return 0x6000 <= addr < 0x8000 and (self.a001 & 0xC0) == 0x80

    def write_outer(self, addr, value):
        pass

    def prg_bank(self, b, w):
        return b

    def chr_bank(self, b):
        return b

    def prg_banks(self):
        r = self.r
        return [self.prg_bank(b, w) % self.prg
                for w, b in enumerate((r[6], r[7], 0xFE, 0xFF))]

    def chr_banks(self):
        r = self.r
        inner = [r[0] & 0xFE, r[0] | 1, r[1] & 0xFE, r[1] | 1] + r[2:6]
        return [self.chr_bank(b) % self.chr for b in inner]

    def outer_writes(self):
        return []

    # The writes made before the first check: the MMC3 bank registers,
    # which power on with no set value
    def setup(self):
        return inner(INNER_A)

    def writes(self):
        return ([(0xA001, 0x80)] + self.outer_writes() + inner(INNER_B) +
                [(0xA001, 0x80)])


# Writes ignored while PRG RAM is write protected or disabled, then the
# value at 0x7FFF
def gated(addr, value, last):
    return [(0xA001, 0xC0), (addr, value), (0xA001, 0x00), (addr, value),
            (0xA001, 0x80), (0x7FFF, last)]


class M37(Multicart):
    """PAL-ZZ: Q2-Q0 latched at 0x6000-0x7FFF. PRG A17 and CHR A17 are Q2,
    PRG A16 is Q0 and Q1 or Q2 and the A16 of the MMC3"""
    mapper = 37
    prg = 32
    chr = 256
    open_6000 = True

    def reset(self):
        self.q = 0

    def write_outer(self, addr, value):
        if self.ram_write(addr):
            self.q = value & 7

    def prg_bank(self, b, w):
        q = self.q
        if MESEN and q == 7:
            return 0x20 | (b & 7)
        a16 = (bit(q, 0) & bit(q, 1)) | (bit(q, 2) & bit(b, 3))
        return bit(q, 2) << 4 | a16 << 3 | (b & 7)

    def chr_bank(self, b):
        if MESEN:
            return bit(self.q, 2) << 7 | b
        return bit(self.q, 2) << 7 | (b & 0x7F)

    def outer_writes(self):
        w = []
        for q in (1, 2, 3, 4, 5, 6, 7, 0):
            w += [(0x6000 + 0x111 * q, q | 0xF8)]
            w += inner(INNER_B)[12:14] + inner(INNER_A)[12:14]
        return w + gated(0x6000, 0x04, 0x07) + inner(INNER_B) + \
            [(0x7FFF, 0x03), (0x6000, 0x00)]


class M44(Multicart):
    """Super Big 7-in-1: the block in bits 2-0 of 0xA001, 128KB of PRG and
    CHR each, or 256KB for blocks 6 and 7"""
    mapper = 44
    prg = 128
    chr = 1024

    def reset(self):
        self.b = 0

    def write_outer(self, addr, value):
        if addr >= 0x8000 and (addr & 0xE001) == 0xA001:
            self.b = min(value & 7, 6)

    def prg_bank(self, b, w):
        return self.b << 4 | (b & (0x1F if self.b == 6 else 0x0F))

    def chr_bank(self, b):
        return self.b << 7 | (b & (0xFF if self.b == 6 else 0x7F))

    def outer_writes(self):
        w = []
        for b in (1, 2, 3, 4, 5, 6, 7, 0, 6):
            w += [(0xA001 + 0x222 * b, 0x80 | b)]
        # Not 0xA001: mirroring, IRQ reload, IRQ enable
        w += [(0xA000, 0x83), (0xC001, 0x82), (0xE001, 0x85), (0xBFFE, 0x84)]
        w += inner(INNER_B) + [(0xBFFF, 0x85)] + inner(INNER_A)
        return w + [(0xA001, 0x86)]


class M45(Multicart):
    """GA23C: four registers written in turn at 0x6000-0x6FFF with A0
    clear, whatever 0xA001 holds; a write with A0 set resets them"""
    mapper = 45
    prg = 256
    chr = 1024
    ram_addr = 0x7000

    def reset(self):
        self.o = [0x00, 0x00, 0x0F, 0x00]
        self.oi = 0

    def write_outer(self, addr, value):
        if 0x6000 <= addr < 0x7000:
            if addr & 1:
                self.reset()
            elif not self.o[3] & 0x40:
                self.o[self.oi] = value
                self.oi = (self.oi + 1) & 3

    def prg_bank(self, b, w):
        o = self.o
        return (b & 0x3F & ~o[3]) | o[1]

    def chr_bank(self, b):
        o = self.o
        n = o[2] & 0x0F
        mask = 0xFF >> (15 - n) if n >= 8 else 0
        return (b & mask) | o[0] | (o[2] & 0x70) << 4

    def outer_writes(self):
        def regs(r0, r1, r2, r3, addr=0x6000):
            return [(addr, r0), (addr + 2, r1), (addr + 0xFFE, r2),
                    (addr + 0x420, r3)]
        w = regs(0x00, 0x00, 0x0F, 0x00)
        w += regs(0x80, 0x30, 0x1E, 0x30)
        w += regs(0x01, 0x05, 0x2D, 0x3C)
        w += regs(0x0C, 0x40, 0x3C, 0x3F)
        w += regs(0x3F, 0x8F, 0x5B, 0x20)
        w += regs(0x00, 0xC1, 0x77, 0x01)
        w += regs(0xF0, 0x7E, 0x48, 0x1F)
        # 0x7000-0x7FFF is not a register, nor is 0xA001 needed
        w += [(0x7000, 0x55), (0xA001, 0x00), (0x7FFE, 0xAA)]
        w += regs(0x10, 0x10, 0x09, 0x00) + [(0xA001, 0x80)]
        # Two writes, then a reset with A0 set, which starts at register 0
        w += [(0x6000, 0x22), (0x6002, 0x33), (0x6001, 0x00)]
        w += regs(0x40, 0x20, 0x2F, 0x10)
        # Locked: written no more, until a reset
        w += regs(0x08, 0x44, 0x1F, 0x50)
        w += regs(0x77, 0x77, 0x77, 0x77)
        w += [(0x6FFF, 0x00)] + regs(0x02, 0x41, 0x6E, 0x00)
        w += inner(INNER_B) + [(0x6001, 0xFF)]
        if MESEN:
            w = [(addr, v) for addr, v in w
                 if addr < 0x7000 and not addr & 1]
        return w


class M49(Multicart):
    """Super HiK 4-in-1: the register at 0x6000-0x7FFF, bits 7-6 the block,
    bit 0 clear the 32KB PRG bank of bits 5-4 within the first 128KB"""
    mapper = 49
    prg = 64
    chr = 512
    open_6000 = True

    def reset(self):
        self.o = 0

    def write_outer(self, addr, value):
        if self.ram_write(addr):
            self.o = value

    def prg_bank(self, b, w):
        o = self.o
        if o & 1:
            return (o >> 6) << 4 | (b & 0x0F)
        return ((o >> 4) & 3) << 2 | w

    def chr_bank(self, b):
        return (self.o >> 6) << 7 | (b & 0x7F)

    def outer_writes(self):
        w = [(0x6000, 0x10), (0x7FFF, 0x20), (0x6ABC, 0x30), (0x7000, 0xC0),
             (0x6000, 0x01), (0x6000, 0x41), (0x7FFF, 0x81), (0x6000, 0xC1),
             (0x6000, 0xF1), (0x6000, 0x7F), (0x6000, 0x8E)]
        return w + gated(0x6000, 0x41, 0xB1) + inner(INNER_B) + \
            [(0x6000, 0x50)]


class M52(Multicart):
    """Realtec 8213: the register at 0x6000-0x7FFF, until bit 7 locks it.
    Bits 2-0 PRG A19-A17 (A17 from the MMC3 unless bit 3 is set), bits
    2 and 5-4 CHR A19-A17 (A17 from the MMC3 unless bit 6 is set)"""
    mapper = 52
    prg = 128
    chr = 1024
    ram_addr = 0x6000

    def reset(self):
        self.o = 0

    def write_outer(self, addr, value):
        if self.ram_write(addr) and not self.o & 0x80:
            self.o = value

    def prg_bank(self, b, w):
        o = self.o
        if o & 0x08:
            return (o & 7) << 4 | (b & 0x0F)
        return (o & 6) << 4 | (b & 0x1F)

    def chr_bank(self, b):
        o = self.o
        base = (o & 0x04) << 7 | (o & 0x20) << 3
        if o & 0x40:
            return base | (o & 0x10) << 3 | (b & 0x7F)
        return base | (b & 0xFF)

    def outer_writes(self):
        w = [(0x6000, v) for v in (0x01, 0x02, 0x04, 0x08, 0x09, 0x0F, 0x10,
                                   0x20, 0x40, 0x50, 0x70, 0x34, 0x7F,
                                   0x00)]
        w += gated(0x6000, 0x0E, 0x4B) + inner(INNER_B)
        # Locked until reset
        w += [(0x6000, 0xA6), (0x7FFF, 0x00), (0x6000, 0x59), (0xA001, 0xC0),
              (0x6000, 0x00), (0xA001, 0x80)]
        return w


VARIANTS = {
    '37': M37,
    '44': M44,
    '45': M45,
    '49': M49,
    '52': M52,
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
STA_ZP, STY_ZP, LDX_ZP, CMP_IND_Y = 0x85, 0x84, 0xA6, 0xD1
INY = 0xC8
BPL, BEQ, BNE, JMP_ABS, JSR, RTS, RTI = 0x10, 0xF0, 0xD0, 0x4C, 0x20, 0x60, \
    0x40


def build(board):
    a = Assembler()

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
    write(0x4017, 0x40)                         # no frame IRQ

    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    for addr, value in board.setup():
        board.write(addr, value)
        write(addr, value)

    # The writes, each with the table of the checks after it
    tables = []
    states = board.writes()
    assert len(states) < 0xFF
    for n, (addr, value) in enumerate(states):
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
        banks = board.prg_banks()
        t += bytes(banks)
        t.append(banks[0] ^ 0xFF)
        for b in board.chr_banks():
            t += bytes([b & 0xFF, b >> 8])
        tables.append((name, t))

    # PRG RAM, or open bus: the high byte of the address
    a.emit(LDA_IMM, 0xFF)
    a.emit(STA_ZP, DETAIL)
    group(3)
    write(0xA001, 0x80)
    if board.open_6000 and MESEN:
        pass
    elif board.open_6000:
        write(0x6000, 0x5A)
        a.abs(LDA_ABS, 0x6000)
        check(0x60, 0)
        a.abs(LDA_ABS, 0x7FFF)
        check(0x7F, 1)
    else:
        write(board.ram_addr, 0x5A)
        write(board.ram_addr + 1, 0xA5)
        a.abs(LDA_ABS, board.ram_addr)
        check(0x5A, 0)
        a.abs(LDA_ABS, board.ram_addr + 1)
        check(0xA5, 1)

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
    group(2)
    for k in range(8):
        ppu_addr(0x0400 * k)
        a.abs(LDA_ABS, 0x2007)                  # the read buffer
        for _ in range(2):
            a.abs(LDA_ABS, 0x2007)
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
    assert ORG + len(code) <= 0xE000 + SIG_HI, 'code runs into SIG_HI'

    prg = bytearray([0xFF]) * (0x2000 * board.prg)
    for b in range(board.prg):
        base = 0x2000 * b
        prg[base + SIG_LO] = b & 0xFF
        prg[base + SIG_HI] = (b & 0xFF) ^ 0xFF
        prg[base + ORG - 0xE000:base + ORG - 0xE000 + len(code)] = code
        for vec, name in ((0x1FFA, 'rti'), (0x1FFC, 'reset'), (0x1FFE, 'rti')):
            prg[base + vec] = a.labels[name] & 0xFF
            prg[base + vec + 1] = a.labels[name] >> 8

    chr_data = bytearray(0x400 * board.chr)
    for b in range(board.chr):
        chr_data[0x400 * b] = b & 0xFF
        chr_data[0x400 * b + 1] = b >> 8

    mapper = board.mapper
    header = bytearray(b'NES\x1a')
    header += bytes([board.prg // 2, board.chr // 8,
                     ((mapper & 0x0F) << 4) | 0x01, mapper & 0xF0])
    header += bytes(8)

    return bytes(header + prg + chr_data)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]()))


if __name__ == '__main__':
    main()
