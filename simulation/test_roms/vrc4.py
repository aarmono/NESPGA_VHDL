#!/usr/bin/env python3
"""Generate test ROMs for the Konami VRC2 and VRC4 (mappers 21, 22, 23, 25).

Usage: vrc4.py OUT.nes VARIANT

The ROM checks, in order:
  - PRG ROM banks: 0x8000 (all 32 banks, with bits 7-5 of the value set),
    0xA000, the second to last bank fixed at 0xC000 and the last at 0xE000.
    Each 8KB bank holds its number at SIG_LO and its complement at SIG_HI
  - VRC4 only: the PRG swap mode (bit 1 of 0x9002), which swaps 0x8000 and
    0xC000, and clearing it through 0x9003
  - CHR ROM banks: each 1KB bank holds the low byte of its number at its
    first byte and the high byte at its second, read back through
    $2006/$2007 with rendering off. The VRC4 banks use the ninth bit. The
    VRC2 ignores bit 4 of the high register, and VRC2a drops the low bit of
    the bank
  - Mirroring: on the VRC4 the four modes at 0x9000 and 0x9001; on the VRC2
    bit 1 is ignored, and every register of 0x9000-0x9003 sets it
  - PRG RAM at 0x6000-0x7FFF
  - VRC4 only, the IRQ counter: no IRQ with the IRQ disabled; the counter
    stopped by a control write without E, then started again by an
    acknowledge with A set; then, for each (latch, control) in TRIALS, the
    latch is set, the control written and a NOP sled is run. The IRQ handler
    stores the low byte of the return address, which tells which NOP the
    IRQ came after, at RESULTS + trial and compares it with EXPECTED, which
    is what Mesen gives

Registers are written at the addresses of the variant's wiring of the chip's
A0 and A1. NES 2.0 variants with one wiring also check that the address of
register 1 of the other wiring of the iNES mapper selects register 0.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed (1 is the
first); the index of the failing check within the ROM is at zero page
DETAIL. The result is up a few frames after reset, so 250ms of nes_bench is
enough.

Variants are named MAPPER_SUBMAPPER for NES 2.0 headers and MAPPER_ines_X
for iNES headers written through wiring X of the two the iNES mapper ORs
together. Mesen passes all of them except:
  - 23_1 (VRC4f): Mesen runs submapper 1 as VRC2b
  - 23_ines_*: Mesen runs iNES 23 as VRC2b at 0x9002 (mirroring rather
    than the swap mode), so these fail the swap mode group

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

# mapper, submapper (None: iNES), CPU lines of chip A0 and A1, VRC4, the
# other wiring of the iNES mapper (lines of A0 and A1) or None
VARIANTS = {
    '21_ines_a': dict(mapper=21, sub=None, lines=(1, 2), vrc4=True),
    '21_ines_c': dict(mapper=21, sub=None, lines=(6, 7), vrc4=True),
    '21_1': dict(mapper=21, sub=1, lines=(1, 2), vrc4=True, other=(6, 7)),
    '21_2': dict(mapper=21, sub=2, lines=(6, 7), vrc4=True, other=(1, 2)),
    '22': dict(mapper=22, sub=None, lines=(1, 0), vrc4=False),
    '23_ines_f': dict(mapper=23, sub=None, lines=(0, 1), vrc4=True),
    '23_ines_e': dict(mapper=23, sub=None, lines=(2, 3), vrc4=True),
    '23_1': dict(mapper=23, sub=1, lines=(0, 1), vrc4=True, other=(2, 3)),
    '23_2': dict(mapper=23, sub=2, lines=(2, 3), vrc4=True, other=(0, 1)),
    '23_3': dict(mapper=23, sub=3, lines=(0, 1), vrc4=False, other=(2, 3)),
    '25_ines_b': dict(mapper=25, sub=None, lines=(1, 0), vrc4=True),
    '25_ines_d': dict(mapper=25, sub=None, lines=(3, 2), vrc4=True),
    '25_1': dict(mapper=25, sub=1, lines=(1, 0), vrc4=True, other=(3, 2)),
    '25_2': dict(mapper=25, sub=2, lines=(3, 2), vrc4=True, other=(1, 0)),
    '25_3': dict(mapper=25, sub=3, lines=(1, 0), vrc4=False, other=(3, 2)),
}

PASS_COLOR = 0x2A

PRG_BANKS = 32

# The code is in the last 8KB bank, which is fixed at 0xE000. Each bank
# holds its number at SIG_LO and its complement at SIG_HI, clear of the code
# and the vectors
ORG = 0xE100
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# Zero page
TRIAL = 0x00
# Bit 7 set: an IRQ now is a failure, of group FAIL_STEP. Bit 6 set: an IRQ
# is counted in GOT_IRQ and acknowledged
MODE = 0x01
FAIL_STEP = 0x02
GOT_IRQ = 0x03
DETAIL = 0x04
RESULTS = 0x10

# (latch, control) of the timing trials: cycle mode (control 6) and
# scanline mode (control 2)
TRIALS = [(0xFF, 0x06), (0xFE, 0x06), (0xF0, 0x06), (0x90, 0x06),
          (0xFF, 0x02), (0xFE, 0x02), (0xFD, 0x02), (0xFC, 0x02)]
SLED_NOPS = 240
# The low bytes of the return addresses Mesen gives for TRIALS, or None to
# only record them
EXPECTED = [0x00, 0x00, 0x07, 0x37, 0x38, 0x71, 0xAA, 0xE3]


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
LDX_IMM, LDY_IMM, CMP_IMM, BIT_ABS, BIT_ZP = 0xA2, 0xA0, 0xC9, 0x2C, 0x24
LDA_ZP, STA_ZP, LDX_ZP, STY_ZP, INC_ZP = 0xA5, 0x85, 0xA6, 0x84, 0xE6
LDA_ABS_X, STA_ZP_X = 0xBD, 0x95
BPL, BMI, BEQ, BNE, BVC, JMP_ABS, RTI = 0x10, 0x30, 0xF0, 0xD0, 0x50, 0x4C, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX = 0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA, 0xCA
PHA, PLA = 0x48, 0x68


def chr_banks_of(v):
    if v['mapper'] == 22:
        return 128
    return 512 if v['vrc4'] else 256


def build(v):
    a = Assembler()
    step = [1]
    detail = [0]
    a0_line, a1_line = v['lines']

    def reg_addr(base, r, lines=v['lines']):
        return base | ((r & 1) << lines[0]) | ((r >> 1) << lines[1])

    def vrc(base, r, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, reg_addr(base, r))

    def next_group():
        step[0] += 1
        assert step[0] < PASS_COLOR

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

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

    def ppu_check_2(addr, value0, value1):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)                  # the read buffer
        a.abs(LDA_ABS, 0x2007)
        check(value0)
        a.abs(LDA_ABS, 0x2007)
        check(value1)

    def cpu_check(addr, value):
        a.abs(LDA_ABS, addr)
        check(value)

    def bank_check(window, bank):
        cpu_check(window + SIG_LO, bank)
        cpu_check(window + SIG_HI, bank ^ 0xFF)

    # Waits about 5 * count CPU cycles
    def delay(count):
        a.emit(LDX_IMM, count)
        a.emit(DEX)
        a.emit(BNE, 0xFD)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    a.abs(STA_ABS, 0x4010)
    a.emit(STA_ZP, TRIAL)
    a.emit(LDA_IMM, 0x40)                       # no frame IRQ
    a.abs(STA_ABS, 0x4017)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # PRG ROM banks
    vrc(0x9000, 0, 0x00)                        # no swap on the VRC4
    vrc(0x9000, 2, 0x00)
    vrc(0xA000, 0, 0x00)
    for b in range(PRG_BANKS):
        vrc(0x8000, 0, 0xE0 | b)
        bank_check(0x8000, b)
    next_group()
    for b in (3, 17, 29):
        vrc(0xA000, 0, b)
        bank_check(0xA000, b)
    next_group()
    vrc(0x8000, 0, 5)
    bank_check(0x8000, 5)
    bank_check(0xA000, 29)
    bank_check(0xC000, PRG_BANKS - 2)
    bank_check(0xE000, PRG_BANKS - 1)
    next_group()

    # PRG swap mode
    if v['vrc4']:
        vrc(0x9000, 2, 0x02)
        bank_check(0x8000, PRG_BANKS - 2)
        bank_check(0xA000, 29)
        bank_check(0xC000, 5)
        bank_check(0xE000, PRG_BANKS - 1)
        vrc(0x8000, 0, 9)
        bank_check(0xC000, 9)
        vrc(0x9000, 3, 0x00)
        bank_check(0x8000, 9)
        bank_check(0xC000, PRG_BANKS - 2)
    next_group()

    # CHR ROM banks
    num_chr = chr_banks_of(v)
    for w in range(8):
        value = (w * 73 + 0x105) & 0x1FF
        if v['vrc4']:
            bank = value
        else:
            value |= 0x100                      # bit 4 of the high register
            bank = value & 0xFF
            if v['mapper'] == 22:
                bank >>= 1
        base = 0xB000 + 0x1000 * (w // 2)
        vrc(base, (w & 1) * 2, value & 0x0F)
        vrc(base, (w & 1) * 2 + 1, value >> 4)
        assert bank < num_chr
    for w in range(8):
        value = (w * 73 + 0x105) & 0x1FF
        if v['vrc4']:
            bank = value
        else:
            bank = value & 0xFF
            if v['mapper'] == 22:
                bank >>= 1
        ppu_check_2(0x400 * w, bank & 0xFF, bank >> 8)
    next_group()

    # Register 1 of the other wiring is register 0 of this one
    if v.get('other') is not None:
        vrc(0xB000, 0, 0x03)
        vrc(0xB000, 1, 0x00)
        a.emit(LDA_IMM, 0x05)
        a.abs(STA_ABS, reg_addr(0xB000, 1, v['other']))
        ppu_check_2(0x0000, 0x05, 0x00)
    next_group()

    # Mirroring. Each of the four nametables is written with its own byte,
    # so the bytes read back show which share CIRAM
    def nt_test(r, mode, expect):
        vrc(0x9000, r, mode)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + expect[i])

    VERT, HORZ, ONE = [2, 3, 2, 3], [1, 1, 3, 3], [3, 3, 3, 3]
    if v['vrc4']:
        nt_test(0, 0, VERT)
        nt_test(0, 1, HORZ)
        nt_test(0, 2, ONE)
        nt_test(0, 3, ONE)
        vrc(0x9000, 0, 2)
        ppu_check(0x2400, 0x63)
        nt_test(1, 0, VERT)
        nt_test(1, 1, HORZ)
    else:
        nt_test(0, 0, VERT)
        nt_test(0, 1, HORZ)
        nt_test(0, 2, VERT)
        nt_test(0, 3, HORZ)
        nt_test(1, 0, VERT)
        nt_test(2, 1, HORZ)
        nt_test(3, 0, VERT)
    next_group()

    # PRG RAM
    a.emit(LDA_IMM, 0xA5)
    a.abs(STA_ABS, 0x6000)
    a.emit(LDA_IMM, 0x5A)
    a.abs(STA_ABS, 0x7FFF)
    cpu_check(0x6000, 0xA5)
    cpu_check(0x7FFF, 0x5A)
    next_group()

    if v['vrc4']:
        # No IRQ while it is disabled
        a.emit(LDA_IMM, step[0])
        a.emit(STA_ZP, FAIL_STEP)
        vrc(0xF000, 0, 0x0F)
        vrc(0xF000, 1, 0x0F)
        vrc(0xF000, 2, 0x04)
        a.emit(CLI)
        delay(100)
        a.emit(SEI)
        next_group()

        # Started with 256 cycles to go, stopped by a control write without
        # E, then started again by an acknowledge with A set
        a.emit(LDA_IMM, step[0])
        a.emit(STA_ZP, FAIL_STEP)
        vrc(0xF000, 0, 0x00)
        vrc(0xF000, 1, 0x00)
        vrc(0xF000, 2, 0x06)
        vrc(0xF000, 2, 0x05)
        a.emit(CLI)
        delay(100)
        a.emit(SEI)
        next_group()
        a.emit(LDA_IMM, 0x40)
        a.emit(STA_ZP, MODE)
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, GOT_IRQ)
        vrc(0xF000, 3, 0x00)
        a.emit(CLI)
        delay(100)
        a.emit(SEI)
        a.emit(LDA_ZP, GOT_IRQ)
        check(1)
        next_group()

        # The timing trials. The IRQ handler starts the next one
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, MODE)
        a.label('trial')
        a.emit(LDX_ZP, TRIAL)
        a.abs_label(LDA_ABS_X, 'trials_latch')
        a.abs(STA_ABS, reg_addr(0xF000, 0))
        a.emit(0x4A, 0x4A, 0x4A, 0x4A)          # LSR A x4
        a.abs(STA_ABS, reg_addr(0xF000, 1))
        a.abs_label(LDA_ABS_X, 'trials_control')
        a.emit(CLI)
        a.abs(STA_ABS, reg_addr(0xF000, 2))
        # The sled starts a page, so the low byte of the address is enough
        a.abs_label(JMP_ABS, 'sled')
        a.emit(*([0xFF] * (-a.here() % 0x100)))
        a.label('sled')
        a.emit(*([NOP] * SLED_NOPS))
        # No IRQ
        a.emit(LDX_IMM, step[0])
        a.abs_label(JMP_ABS, 'show')
        next_group()

        a.label('trials_done')
        if EXPECTED is not None:
            for t, expect in enumerate(EXPECTED):
                a.emit(LDA_ZP, RESULTS + t)
                check(expect)
        next_group()

    a.emit(LDX_IMM, PASS_COLOR)

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show')
    a.emit(SEI)
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

    a.label('irq')
    if v['vrc4']:
        a.emit(BIT_ZP, MODE)
        a.branch(BPL, 'irq_not_fail')
        a.emit(LDX_ZP, FAIL_STEP)
        a.emit(LDY_IMM, 0xFF)
        a.abs_label(JMP_ABS, 'show')
        a.label('irq_not_fail')
        a.branch(BVC, 'irq_trial')
        a.emit(PHA)
        a.emit(INC_ZP, GOT_IRQ)
        vrc(0xF000, 2, 0x00)                    # acknowledge and stop
        a.emit(PLA)
        a.emit(RTI)
        a.label('irq_trial')
        a.emit(TSX)
        a.abs(LDA_ABS_X, 0x0102)                # return address, low byte
        a.emit(LDX_ZP, TRIAL)
        a.emit(STA_ZP_X, RESULTS)
        vrc(0xF000, 2, 0x00)                    # acknowledge and stop
        a.emit(LDX_IMM, 0xFF, TXS)
        a.emit(INC_ZP, TRIAL)
        a.emit(LDA_ZP, TRIAL)
        a.emit(CMP_IMM, len(TRIALS))
        a.branch(BEQ, 'irq_done')
        a.abs_label(JMP_ABS, 'trial')
        a.label('irq_done')
        a.abs_label(JMP_ABS, 'trials_done')

        a.label('trials_latch')
        a.emit(*[t[0] for t in TRIALS])
        a.label('trials_control')
        a.emit(*[t[1] for t in TRIALS])
    else:
        # The VRC2 has no IRQ
        a.emit(LDX_IMM, 0x3F)
        a.emit(LDY_IMM, 0xFF)
        a.abs_label(JMP_ABS, 'show')

    a.label('nmi')
    a.emit(RTI)

    code = a.link()
    assert ORG + len(code) <= 0xE000 + SIG_HI, 'code runs into SIG_HI'

    prg = bytearray([0xFF]) * (0x2000 * PRG_BANKS)
    for b in range(PRG_BANKS):
        prg[0x2000 * b + SIG_LO] = b
        prg[0x2000 * b + SIG_HI] = b ^ 0xFF

    last = len(prg) - 0x2000
    prg[last + ORG - 0xE000:last + ORG - 0xE000 + len(code)] = code
    for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'), (0xFFFE, 'irq')):
        prg[last + vec - 0xE000] = a.labels[name] & 0xFF
        prg[last + vec - 0xE000 + 1] = a.labels[name] >> 8

    chr_rom = bytearray(0x400 * num_chr)
    for b in range(num_chr):
        chr_rom[0x400 * b] = b & 0xFF
        chr_rom[0x400 * b + 1] = b >> 8

    mapper = v['mapper']
    nes2 = v['sub'] is not None
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((mapper & 0x0F) << 4) | 0x01,
                     (mapper & 0xF0) | (0x08 if nes2 else 0x00)])
    header += bytes(8)
    if nes2:
        header[8] = v['sub'] << 4
        header[10] = 0x07                       # 8KB PRG RAM

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
