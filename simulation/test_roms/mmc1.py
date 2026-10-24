#!/usr/bin/env python3
"""Generate test ROMs for the MMC1 boards (mappers 1, 105 and 155).

Usage: mmc1.py OUT.nes {sxrom,surom,serom,155,105}

Each 16KB bank of PRG ROM holds its number at SIG_LO and its complement at
SIG_HI, and the same code, so that the code runs from 0xC000 whichever bank
is there. Each 1KB bank of CHR ROM holds its number at its first byte, read
back through $2006/$2007 with rendering off. The registers are written
through the serial port, a bit at a time with LSR between the writes.

The checks of each variant are in groups, in order; the number of the group
is the failure color:

sxrom  iNES mapper 1, 256KB PRG ROM, 128KB CHR ROM, 8KB PRG RAM
  1  The shift register: a write with bit 7 set drops the bits written so
     far and sets PRG mode 3, and the fifth write picks the register by its
     own address
  2  A read-modify-write instruction writes the serial port on two
     consecutive cycles, and the second write is ignored
  3  PRG mode 3: 16KB at 0x8000, the last bank fixed at 0xC000
  4  PRG mode 2: the first bank fixed at 0x8000, 16KB at 0xC000
  5  PRG modes 0 and 1: 32KB, bit 0 of the bank ignored
  6  CHR 8KB mode: bit 0 of CHR bank 0 ignored, CHR bank 1 unused
  7  CHR 4KB mode
  8  The four mirroring modes
  9  PRG RAM, and bit 4 of the PRG bank, which disables it (MMC1B): reads
     give open bus (the high byte of the address) and writes are ignored

surom  iNES mapper 1, 512KB PRG ROM, 8KB CHR RAM
  1  Bit 4 of CHR bank 0 selects the 256KB half of PRG ROM, for the fixed
     banks too, in PRG modes 3, 0 and 2 (8KB CHR mode)
  2  CHR RAM banked 4KB at a time in CHR 4KB mode

serom  NES 2.0 mapper 1 submapper 5, 32KB PRG ROM, 32KB CHR ROM
  1  PRG ROM is not banked: the CPU addresses it, whatever the PRG mode and
     bank
  2  CHR 4KB and 8KB modes

155    iNES mapper 155 (MMC1A), 256KB PRG ROM, 128KB CHR ROM, 8KB PRG RAM
  1  PRG mode 3
  2  PRG RAM stays enabled, for reads and writes, with bit 4 of the PRG bank
     set
  3  Bit 4 of the PRG bank set has bit 3 select the 128KB half of PRG ROM
     for the fixed bank at 0xC000 too (nesdev)

105    iNES mapper 105 (NES-EVENT), 256KB PRG ROM in two 128KB chips, 8KB CHR
       RAM. The timer IRQ is not checked: it takes about 5 minutes with the
       DIP switches at 0
  1  PRG ROM is locked to its first 32KB at power up, whatever the PRG
     register
  2  It stays locked once the I bit of CHR bank 0 is cleared
  3  Setting the I bit again unlocks it: with bit 3 of CHR bank 0 clear,
     bits 2-1 select a 32KB bank of the first chip
  4  With bit 3 set, the second chip is banked like any MMC1, in PRG modes
     3, 0 and 2
  5  Clearing and setting the I bit again does not lock it

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed. The result is up a
few frames after reset, so 250ms of nes_bench is enough.

Mesen passes sxrom, surom, serom and 105. It fails group 3 of 155, since it
does not model the fixed bank bypass of the MMC1A.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    'sxrom': dict(mapper=1, nes2=False, prg_banks=16, chr_kb=128),
    'surom': dict(mapper=1, nes2=False, prg_banks=32, chr_kb=0),
    'serom': dict(mapper=1, nes2=True, submapper=5, prg_banks=2, chr_kb=32),
    '155':   dict(mapper=155, nes2=False, prg_banks=16, chr_kb=128),
    '105':   dict(mapper=105, nes2=False, prg_banks=16, chr_kb=0),
}

PASS_COLOR = 0x2A

# The code is at the same place in every 16KB bank, so it runs from 0xC000
# whichever bank is there. Each bank holds its number at SIG_LO and its
# complement at SIG_HI, clear of the code and the vectors, and a zero at
# ZERO for the read-modify-write check
ORG = 0xC100
SIG_LO = 0x0010
SIG_HI = 0x3FF0
ZERO = 0x3F00

# The registers, by the address of the fifth write
CONTROL = 0x8000
CHR_0 = 0xA000
CHR_1 = 0xC000
PRG = 0xE000

# Control register values: CHR mode in bit 4, PRG mode in bits 3-2 and
# mirroring in bits 1-0 (vertical)
CHR_8KB, CHR_4KB = 0x00, 0x10
VERTICAL = 0x02


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
LDX_IMM, CMP_IMM, BIT_ABS, INC_ABS = 0xA2, 0xC9, 0x2C, 0xEE
BPL, BEQ, JMP_ABS, RTI, LSR_A = 0x10, 0xF0, 0x4C, 0x40, 0x4A
SEI, CLD, TXS = 0x78, 0xD8, 0x9A


def build(v):
    a = Assembler()
    group = [1]

    def next_group():
        group[0] += 1
        assert group[0] < PASS_COLOR

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    # The bits of value, from bit 0, written one at a time
    def serial(value, addrs):
        a.emit(LDA_IMM, value)
        for i, addr in enumerate(addrs):
            if i:
                a.emit(LSR_A)
            a.abs(STA_ABS, addr)

    def mmc1(reg, value):
        serial(value, [reg] * 5)

    def shift_reset():
        a.emit(LDA_IMM, 0x80)
        a.abs(STA_ABS, 0x8000)

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
        a.emit(LDX_IMM, group[0])
        a.emit(CMP_IMM, value)
        a.emit(BEQ, 3)
        a.abs_label(JMP_ABS, 'show')

    def ppu_check(addr, value):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)                  # the read buffer
        a.abs(LDA_ABS, 0x2007)
        check(value)

    def cpu_check(addr, value):
        a.abs(LDA_ABS, addr)
        check(value)

    def cpu_write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    def bank_check(window, bank):
        cpu_check(window + SIG_LO, bank)
        cpu_check(window + SIG_HI, bank ^ 0xFF)

    def banks_check(lo, hi):
        bank_check(0x8000, lo)
        bank_check(0xC000, hi)

    def ram_check():
        cpu_write(0x6000, 0xA5)
        cpu_write(0x7FFF, 0x5A)
        cpu_check(0x6000, 0xA5)
        cpu_check(0x7FFF, 0x5A)

    def nt_test(mode, expect):
        mmc1(CONTROL, CHR_4KB | 0x0C | mode)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + expect[i])

    last = v['prg_banks'] - 1

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

    name = v['name']
    if name == 'sxrom':
        # 1: the shift register
        mmc1(CONTROL, CHR_8KB | 0x08 | VERTICAL)
        mmc1(PRG, 5)
        banks_check(0, 5)
        # Three bits then a reset, which also sets PRG mode 3
        serial(0x07, [PRG] * 3)
        shift_reset()
        banks_check(5, last)
        mmc1(PRG, 9)
        banks_check(9, last)
        # The first four writes at the control register, the fifth at the
        # PRG bank
        serial(3, [CONTROL] * 4 + [PRG])
        banks_check(3, last)
        next_group()

        # 2: INC writes 0 then 1 on consecutive cycles. Only the 0 is
        # shifted in, so bits 4-1 complete the register as 6. Were the 1
        # shifted in too, the register would be 14
        shift_reset()
        a.abs(INC_ABS, 0xC000 + ZERO)
        serial(6 >> 1, [PRG] * 4)
        banks_check(6, last)
        next_group()

        # 3: PRG mode 3
        for b in (0, 1, 7, 14, 15):
            mmc1(PRG, b)
            banks_check(b, last)
        next_group()

        # 4: PRG mode 2
        mmc1(CONTROL, CHR_8KB | 0x08 | VERTICAL)
        for b in (0, 3, 14, 15):
            mmc1(PRG, b)
            banks_check(0, b)
        next_group()

        # 5: PRG modes 0 and 1
        for mode in (0x00, 0x04):
            mmc1(CONTROL, CHR_8KB | mode | VERTICAL)
            for b in (2, 5, 15):
                mmc1(PRG, b)
                banks_check(b & ~1, b | 1)
        mmc1(CONTROL, CHR_8KB | 0x0C | VERTICAL)
        mmc1(PRG, 0)
        next_group()

        # 6: CHR 8KB mode
        for b0, b1 in ((5, 9), (6, 9), (31, 2)):
            mmc1(CHR_0, b0)
            mmc1(CHR_1, b1)
            base = 4 * (b0 & ~1)
            for w in (0, 3, 4, 7):
                ppu_check(0x400 * w, base + w)
        next_group()

        # 7: CHR 4KB mode
        mmc1(CONTROL, CHR_4KB | 0x0C | VERTICAL)
        for b0, b1 in ((5, 9), (31, 0), (0, 30)):
            mmc1(CHR_0, b0)
            mmc1(CHR_1, b1)
            for w in (0, 1, 3):
                ppu_check(0x400 * w, 4 * b0 + w)
                ppu_check(0x1000 + 0x400 * w, 4 * b1 + w)
        next_group()

        # 8: mirroring. Each of the four nametables is written with its own
        # byte, so the bytes read back show which share CIRAM. One screen A
        # is checked again after one screen B
        nt_test(2, [2, 3, 2, 3])
        nt_test(3, [1, 1, 3, 3])
        nt_test(0, [3, 3, 3, 3])
        nt_test(1, [3, 3, 3, 3])
        mmc1(CONTROL, CHR_4KB | 0x0C | 0)
        ppu_check(0x2400, 0x43)
        mmc1(CONTROL, CHR_4KB | 0x0C | VERTICAL)
        next_group()

        # 9: PRG RAM and its disable
        ram_check()
        mmc1(PRG, 0x10)
        cpu_check(0x6000, 0x60)
        cpu_check(0x7FFF, 0x7F)
        cpu_write(0x6000, 0x11)
        mmc1(PRG, 0x00)
        cpu_check(0x6000, 0xA5)
        next_group()

    elif name == 'surom':
        # 1: the 256KB half, from bit 4 of CHR bank 0
        mmc1(CONTROL, CHR_8KB | 0x0C | VERTICAL)
        mmc1(PRG, 3)
        banks_check(3, 15)
        mmc1(CHR_0, 0x10)
        banks_check(19, 31)
        mmc1(CONTROL, CHR_8KB | 0x00 | VERTICAL)
        mmc1(PRG, 4)
        banks_check(20, 21)
        mmc1(CHR_0, 0x00)
        banks_check(4, 5)
        mmc1(CONTROL, CHR_8KB | 0x08 | VERTICAL)
        mmc1(PRG, 6)
        banks_check(0, 6)
        mmc1(CHR_0, 0x10)
        banks_check(16, 22)
        mmc1(CHR_0, 0x00)
        mmc1(CONTROL, CHR_8KB | 0x0C | VERTICAL)
        next_group()

        # 2: CHR RAM in 4KB banks
        ppu_write(0x0000, 0x11)
        ppu_write(0x1000, 0x22)
        ppu_check(0x0000, 0x11)
        ppu_check(0x1000, 0x22)
        mmc1(CONTROL, CHR_4KB | 0x0C | VERTICAL)
        mmc1(CHR_0, 1)
        mmc1(CHR_1, 0)
        ppu_check(0x0000, 0x22)
        ppu_check(0x1000, 0x11)
        ppu_write(0x0001, 0x33)
        mmc1(CHR_0, 0)
        mmc1(CHR_1, 1)
        ppu_check(0x1001, 0x33)
        ppu_check(0x0000, 0x11)
        next_group()

    elif name == 'serom':
        # 1: PRG ROM not banked. An MMC1 would put bank 1 at 0x8000 in mode
        # 3, and bank 0 at 0xC000 in mode 2
        banks_check(0, 1)
        mmc1(PRG, 1)
        banks_check(0, 1)
        mmc1(CONTROL, CHR_8KB | 0x08 | VERTICAL)
        mmc1(PRG, 0)
        banks_check(0, 1)
        mmc1(CONTROL, CHR_8KB | 0x00 | VERTICAL)
        mmc1(PRG, 1)
        banks_check(0, 1)
        mmc1(CONTROL, CHR_8KB | 0x0C | VERTICAL)
        next_group()

        # 2: CHR banks
        mmc1(CHR_0, 7)
        for w in (0, 3, 4, 7):
            ppu_check(0x400 * w, 24 + w)
        mmc1(CONTROL, CHR_4KB | 0x0C | VERTICAL)
        mmc1(CHR_0, 3)
        mmc1(CHR_1, 6)
        for w in (0, 3):
            ppu_check(0x400 * w, 12 + w)
            ppu_check(0x1000 + 0x400 * w, 24 + w)
        next_group()

    elif name == '155':
        # 1: PRG mode 3
        for b in (0, 7, 14):
            mmc1(PRG, b)
            banks_check(b, last)
        next_group()

        # 2: PRG RAM stays enabled
        mmc1(PRG, 0)
        ram_check()
        mmc1(PRG, 0x10)
        cpu_check(0x6000, 0xA5)
        cpu_write(0x6000, 0x11)
        cpu_check(0x6000, 0x11)
        mmc1(PRG, 0x00)
        cpu_check(0x6000, 0x11)
        next_group()

        # 3: the fixed bank bypass
        mmc1(PRG, 0x12)
        banks_check(2, 7)
        mmc1(PRG, 0x1A)
        banks_check(10, 15)
        mmc1(PRG, 0x02)
        banks_check(2, 15)
        next_group()

    elif name == '105':
        # 1: locked to the first 32KB
        banks_check(0, 1)
        mmc1(CONTROL, CHR_8KB | 0x0C | VERTICAL)
        mmc1(PRG, 5)
        banks_check(0, 1)
        next_group()

        # 2: the I bit cleared
        mmc1(CHR_0, 0x00)
        banks_check(0, 1)
        next_group()

        # 3: the I bit set again: 32KB banks of the first chip
        mmc1(CHR_0, 0x10)
        banks_check(0, 1)
        mmc1(CHR_0, 0x12)
        banks_check(2, 3)
        mmc1(CHR_0, 0x16)
        banks_check(6, 7)
        next_group()

        # 4: the second chip
        mmc1(CHR_0, 0x18)
        mmc1(PRG, 2)
        banks_check(10, 15)
        mmc1(CONTROL, CHR_8KB | 0x00 | VERTICAL)
        mmc1(PRG, 4)
        banks_check(12, 13)
        mmc1(CONTROL, CHR_8KB | 0x08 | VERTICAL)
        mmc1(PRG, 5)
        banks_check(8, 13)
        mmc1(CONTROL, CHR_8KB | 0x0C | VERTICAL)
        next_group()

        # 5: still unlocked
        mmc1(CHR_0, 0x00)
        mmc1(CHR_0, 0x14)
        banks_check(4, 5)
        next_group()

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

    a.label('rti')
    a.emit(RTI)

    code = a.link()
    assert ORG + len(code) <= 0xC000 + ZERO, 'code runs into ZERO'

    prg = bytearray([0xFF]) * (0x4000 * v['prg_banks'])
    for b in range(v['prg_banks']):
        base = 0x4000 * b
        prg[base + SIG_LO] = b
        prg[base + SIG_HI] = b ^ 0xFF
        prg[base + ZERO] = 0x00
        start = base + ORG - 0xC000
        prg[start:start + len(code)] = code
        for vec, label in ((0xFFFA, 'rti'), (0xFFFC, 'reset'),
                           (0xFFFE, 'rti')):
            prg[base + vec - 0xC000] = a.labels[label] & 0xFF
            prg[base + vec - 0xC000 + 1] = a.labels[label] >> 8

    chr_rom = bytearray(0x400 * v['chr_kb'])
    for b in range(v['chr_kb']):
        chr_rom[0x400 * b] = b

    mapper = v['mapper']
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((mapper & 0x0F) << 4) | 0x01,
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[8] = (v['submapper'] << 4) | (mapper >> 8)
        if not chr_rom:
            header[11] = 0x07                   # 8KB CHR RAM

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    v = dict(VARIANTS[sys.argv[2]], name=sys.argv[2])
    with open(sys.argv[1], 'wb') as f:
        f.write(build(v))


if __name__ == '__main__':
    main()
