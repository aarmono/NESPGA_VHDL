#!/usr/bin/env python3
"""Generate test ROMs for the Konami VRC7 (mapper 85).

Usage: vrc7.py OUT.nes VARIANT

The checks are in groups:
   1  PRG ROM: every bank through 0x8000 (bits 7-6 of the value set), others
      through the registers of 0xA000 and 0xC000, the last bank fixed at
      0xE000. Each 8KB bank holds its number at SIG_LO and its complement at
      SIG_HI
   2  CHR: the eight 1KB banks at 0xA000-0xD000. Each CHR ROM bank holds its
      number at its first byte; with 8KB of CHR RAM the banks wrap, which is
      checked by writing each bank through one register and reading it back
      through another
   3  NES 2.0 variants: the register select line of the other board selects
      register 0
   4  Mirroring, the four modes of 0xE000
   5  PRG RAM: disabled at power on, enabled by bit 7 of 0xE000. Disabled,
      writes are ignored and reads are open bus
   6  IRQ: none while disabled
   7  IRQ: started with 256 cycles to go, stopped by a control write without
      E, then started again by an acknowledge with A set
   8  IRQ timing trials: for each (latch, control) in TRIALS, the latch is
      set, the control written and a NOP sled is run. The IRQ handler stores
      the low byte of the return address, which tells which NOP the IRQ came
      after, at RESULTS + trial. Fails here if a sled runs out
   9  The trial results against EXPECTED, which is what Mesen gives

Registers are written at the addresses of the variant's register select
line, A4 (VRC7a, Lagrange Point) or A3 (VRC7b, Tiny Toon Adventures 2).

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed; the index of the
failing check in the ROM is at zero page DETAIL. The result is up a few
frames after reset, so 250ms of nes_bench is enough.

Variants:
  85_ines_a4   iNES 85 written through A4, 512KB PRG, 256KB CHR ROM
  85_ines_a3   iNES 85 written through A3
  85_1         NES 2.0 submapper 1 (VRC7b, A3)
  85_2         NES 2.0 submapper 2 (VRC7a, A4)
  85_chr_ram   iNES 85 written through A4 with 8KB CHR RAM, as Lagrange
               Point

Mesen passes all of them. It decodes iNES and NES 2.0 85 alike, as the OR
of A3 and A4, so group 3 is left out of MESEN builds.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

# mapper submapper (None: iNES), register select line, the other board's
# line (NES 2.0 only), CHR RAM
VARIANTS = {
    '85_ines_a4': dict(sub=None, line=4),
    '85_ines_a3': dict(sub=None, line=3),
    '85_1': dict(sub=1, line=3, other=4),
    '85_2': dict(sub=2, line=4, other=3),
    '85_chr_ram': dict(sub=None, line=4, chr_ram=True),
}

# Builds the ROM for Mesen, see above
MESEN = False

PASS_COLOR = 0x2A

PRG_BANKS = 64
CHR_BANKS = 256
CHR_RAM_BANKS = 8

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


def build(v):
    a = Assembler()
    step = [1]
    detail = [0]
    chr_ram = v.get('chr_ram', False)

    def reg_addr(base, sel, line=v['line']):
        return base | (sel << line)

    def vrc(base, sel, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, reg_addr(base, sel))

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

    # The register of CHR window w
    def chr_reg(w, value):
        vrc(0xA000 + 0x1000 * (w // 2), w & 1, value)

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
    vrc(0x8000, 1, 0x00)
    vrc(0x9000, 0, 0x00)
    for b in range(PRG_BANKS):
        vrc(0x8000, 0, 0xC0 | b)
        bank_check(0x8000, b)
    for b in (3, 17, 62):
        vrc(0x8000, 1, b)
        bank_check(0xA000, b)
    for b in (5, 33, 60):
        vrc(0x9000, 0, b)
        bank_check(0xC000, b)
    vrc(0x8000, 0, 9)
    bank_check(0x8000, 9)
    bank_check(0xA000, 62)
    bank_check(0xC000, 60)
    bank_check(0xE000, PRG_BANKS - 1)
    next_group()

    # CHR banks
    if chr_ram:
        # Bank 7 - w through window w, read back through window 0
        for w in range(8):
            chr_reg(w, 0xF8 | (7 - w))
            ppu_write(0x400 * w, 0x30 + 7 - w)
        for b in range(8):
            chr_reg(0, b)
            ppu_check(0x0000, 0x30 + b)
    else:
        values = [(w * 73 + 0x15) & 0xFF for w in range(8)]
        for w in range(8):
            chr_reg(w, values[w])
        for w in range(8):
            ppu_check(0x400 * w, values[w])
    next_group()

    # The other board's select line selects register 0
    if v.get('other') is not None and not MESEN:
        chr_reg(0, 0x03)
        chr_reg(1, 0x04)
        a.emit(LDA_IMM, 0x05)
        a.abs(STA_ABS, reg_addr(0xA000, 1, v['other']))
        if chr_ram:
            ppu_check(0x0000, 0x30 + 5)
        else:
            ppu_check(0x0000, 0x05)
            ppu_check(0x0400, 0x04)
    next_group()

    # Mirroring. Each of the four nametables is written with its own byte,
    # so the bytes read back show which share CIRAM
    def nt_test(mode, expect):
        vrc(0xE000, 0, mode)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + expect[i])

    nt_test(0, [2, 3, 2, 3])
    nt_test(1, [1, 1, 3, 3])
    nt_test(2, [3, 3, 3, 3])
    nt_test(3, [3, 3, 3, 3])
    # One screen A and B are different pages
    vrc(0xE000, 0, 2)
    ppu_check(0x2400, 0x63)
    next_group()

    # PRG RAM
    vrc(0xE000, 0, 0x80)
    a.emit(LDA_IMM, 0xA5)
    a.abs(STA_ABS, 0x6000)
    a.emit(LDA_IMM, 0x5A)
    a.abs(STA_ABS, 0x7FFF)
    cpu_check(0x6000, 0xA5)
    cpu_check(0x7FFF, 0x5A)
    vrc(0xE000, 0, 0x00)
    a.emit(LDA_IMM, 0x11)
    a.abs(STA_ABS, 0x6000)
    cpu_check(0x6000, 0x60)                     # open bus
    vrc(0xE000, 0, 0x80)
    cpu_check(0x6000, 0xA5)
    next_group()

    # No IRQ while it is disabled
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    vrc(0xE000, 1, 0xFF)
    vrc(0xF000, 0, 0x04)
    a.emit(CLI)
    delay(100)
    a.emit(SEI)
    next_group()

    # Started with 256 cycles to go, stopped by a control write without E,
    # then started again by an acknowledge with A set
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    vrc(0xE000, 1, 0x00)
    vrc(0xF000, 0, 0x06)
    vrc(0xF000, 0, 0x05)
    a.emit(CLI)
    delay(100)
    a.emit(SEI)
    a.emit(LDA_IMM, 0x40)
    a.emit(STA_ZP, MODE)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, GOT_IRQ)
    vrc(0xF000, 1, 0x00)
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
    a.abs(STA_ABS, reg_addr(0xE000, 1))
    a.abs_label(LDA_ABS_X, 'trials_control')
    a.emit(CLI)
    a.abs(STA_ABS, reg_addr(0xF000, 0))
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
    a.emit(BIT_ZP, MODE)
    a.branch(BPL, 'irq_not_fail')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_IMM, 0xFF)
    a.abs_label(JMP_ABS, 'show')
    a.label('irq_not_fail')
    a.branch(BVC, 'irq_trial')
    a.emit(PHA)
    a.emit(INC_ZP, GOT_IRQ)
    vrc(0xF000, 0, 0x00)                        # acknowledge and stop
    a.emit(PLA)
    a.emit(RTI)
    a.label('irq_trial')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    vrc(0xF000, 0, 0x00)                        # acknowledge and stop
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

    if chr_ram:
        chr_rom = bytearray()
    else:
        chr_rom = bytearray(0x400 * CHR_BANKS)
        for b in range(CHR_BANKS):
            chr_rom[0x400 * b] = b

    nes2 = v['sub'] is not None
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((85 & 0x0F) << 4) | 0x01,
                     (85 & 0xF0) | (0x08 if nes2 else 0x00)])
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
