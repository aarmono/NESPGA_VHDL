#!/usr/bin/env python3
"""Generate test ROMs for the Sunsoft FME-7 (mapper 69).

Usage: fme7.py OUT.nes {ines,nes2}

The ROM checks, in order:
  - PRG ROM banks at 0x6000 (command 8), 0x8000, 0xA000 and 0xC000
    (commands 9-B) and the last bank fixed at 0xE000. Each 8KB bank holds
    its number at SIG_LO and its complement at SIG_HI
  - PRG RAM at 0x6000: write and read back, PRG ROM selected in its place,
    and open bus (the high byte of the address, 0x60) with RAM selected but
    disabled, which also ignores writes
  - CHR ROM banks: each 1KB bank holds its number at its first byte, read
    back through $2006/$2007 with rendering off
  - The four mirroring modes (command C)
  - The IRQ counter: no IRQ when the counter wraps with IRQs disabled, nor
    when they are enabled after the wrap; then, for each count in TRIALS,
    the counter is set, started together with IRQs and a NOP sled is run.
    The IRQ handler stores the low byte of the return address, which tells
    which NOP the IRQ came after, at RESULTS + trial and compares it with
    EXPECTED, which is what Mesen gives

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the color of the step that failed (1 is the first
check). The result is up a few frames after reset, so 250ms of nes_bench is
enough.

Variants:
  ines  iNES, vertical: 8KB of PRG RAM, so the RAM bank bits are not checked
  nes2  NES 2.0 with 32KB of PRG RAM: the low bits of the 0x6000 bank select
        the 8KB bank of PRG RAM too

Mesen passes both.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    'ines': dict(nes2=False, ram_banks=1),
    'nes2': dict(nes2=True, ram_banks=4),
}

PASS_COLOR = 0x2A

PRG_BANKS = 16
CHR_BANKS = 64

# The code is in the last 8KB bank, which is fixed at 0xE000. Each bank
# holds its number at SIG_LO and its complement at SIG_HI, clear of the code
# and the vectors
ORG = 0xE100
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# Zero page
TRIAL = 0x00
# Bit 7 set: an IRQ now is a failure, of step FAIL_STEP
MODE = 0x01
FAIL_STEP = 0x02
RESULTS = 0x10

# The IRQ counts of the timing trials
TRIALS = [0x0000, 0x0001, 0x0002, 0x0003, 0x0014, 0x0015, 0x0100]
SLED_NOPS = 160
# The low bytes of the return addresses Mesen gives for TRIALS, or None to
# only record them
EXPECTED = [0x00, 0x00, 0x01, 0x01, 0x0A, 0x0A, 0x80]


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
LDX_IMM, CMP_IMM, BIT_ABS, BIT_ZP = 0xA2, 0xC9, 0x2C, 0x24
LDA_ZP, STA_ZP, LDX_ZP, INC_ZP = 0xA5, 0x85, 0xA6, 0xE6
LDA_ABS_X, STA_ZP_X, CMP_ABS_X = 0xBD, 0x95, 0xDD
BPL, BMI, BEQ, BNE, JMP_ABS, RTI = 0x10, 0x30, 0xF0, 0xD0, 0x4C, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX = 0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA, 0xCA


def build(v):
    a = Assembler()
    step = [1]

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def fme7(command, value):
        a.emit(LDA_IMM, command)
        a.abs(STA_ABS, 0x8000)
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, 0xA000)

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
    for b in range(PRG_BANKS - 1):
        fme7(0x9, b)
        bank_check(0x8000, b)
    for cmd, window, banks in ((0xA, 0xA000, (3, 12)),
                               (0xB, 0xC000, (5, 14)),
                               (0x8, 0x6000, (7, 15))):
        for b in banks:
            fme7(cmd, b)
            bank_check(window, b)
    bank_check(0xE000, PRG_BANKS - 1)
    # 0x8000-0xC000 are left as they were
    bank_check(0x8000, PRG_BANKS - 2)
    bank_check(0xA000, 12)
    bank_check(0xC000, 14)

    # PRG RAM
    for b in range(v['ram_banks']):
        fme7(0x8, 0xC0 | b)
        a.emit(LDA_IMM, 0xA0 + b)
        a.abs(STA_ABS, 0x6000)
        a.emit(LDA_IMM, 0x50 + b)
        a.abs(STA_ABS, 0x7FFF)
    for b in range(v['ram_banks']):
        fme7(0x8, 0xC0 | b)
        cpu_check(0x6000, 0xA0 + b)
        cpu_check(0x7FFF, 0x50 + b)
    fme7(0x8, 0x02)
    bank_check(0x6000, 2)
    fme7(0x8, 0x40)
    cpu_check(0x6000, 0x60)
    a.emit(LDA_IMM, 0x11)
    a.abs(STA_ABS, 0x6000)
    fme7(0x8, 0xC0)
    cpu_check(0x6000, 0xA0)

    # CHR ROM banks
    chr_banks = [(w * 9 + 5) % CHR_BANKS for w in range(8)]
    for w, b in enumerate(chr_banks):
        fme7(w, b)
    for w, b in enumerate(chr_banks):
        ppu_check(0x400 * w, b)

    # Mirroring. Each of the four nametables is written with its own byte,
    # so the bytes read back show which share CIRAM
    def nt_test(mode, expect):
        fme7(0xC, mode)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + expect[i])

    nt_test(0, [2, 3, 2, 3])
    nt_test(1, [1, 1, 3, 3])
    nt_test(2, [3, 3, 3, 3])
    nt_test(3, [3, 3, 3, 3])
    fme7(0xC, 2)
    ppu_check(0x2400, 0x63)

    # The counter wraps with IRQs disabled, then IRQs are enabled
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    step[0] += 1
    fme7(0xE, 0x05)
    fme7(0xF, 0x00)
    fme7(0xD, 0x80)
    a.emit(CLI)
    delay(20)
    fme7(0xD, 0x81)
    delay(20)
    a.emit(SEI)
    fme7(0xD, 0x00)

    # The timing trials. The IRQ handler starts the next one
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, MODE)
    a.label('trial')
    a.emit(LDX_ZP, TRIAL)
    a.emit(LDA_IMM, 0x0E)
    a.abs(STA_ABS, 0x8000)
    a.abs_label(LDA_ABS_X, 'trials_lo')
    a.abs(STA_ABS, 0xA000)
    a.emit(LDA_IMM, 0x0F)
    a.abs(STA_ABS, 0x8000)
    a.abs_label(LDA_ABS_X, 'trials_hi')
    a.abs(STA_ABS, 0xA000)
    a.emit(LDA_IMM, 0x0D)
    a.abs(STA_ABS, 0x8000)
    a.emit(LDA_IMM, 0x81)
    a.emit(CLI)
    a.abs(STA_ABS, 0xA000)
    # The sled starts a page, so the low byte of the address is enough
    a.abs_label(JMP_ABS, 'sled')
    a.emit(*([0xFF] * (-a.here() % 0x100)))
    a.label('sled')
    a.emit(*([NOP] * SLED_NOPS))
    # No IRQ
    a.emit(LDX_IMM, step[0])
    a.abs_label(JMP_ABS, 'show')
    step[0] += 1

    a.label('trials_done')
    if EXPECTED is not None:
        for t, expect in enumerate(EXPECTED):
            a.emit(LDA_ZP, RESULTS + t)
            check(expect)
    a.emit(LDX_IMM, PASS_COLOR)

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show')
    a.emit(SEI)
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
    a.branch(BPL, 'irq_trial')
    a.emit(LDX_ZP, FAIL_STEP)
    a.abs_label(JMP_ABS, 'show')
    a.label('irq_trial')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    fme7(0xD, 0x00)                             # acknowledge
    a.emit(LDX_IMM, 0xFF, TXS)
    a.emit(INC_ZP, TRIAL)
    a.emit(LDA_ZP, TRIAL)
    a.emit(CMP_IMM, len(TRIALS))
    a.branch(BEQ, 'irq_done')
    a.abs_label(JMP_ABS, 'trial')
    a.label('irq_done')
    a.abs_label(JMP_ABS, 'trials_done')

    a.label('trials_lo')
    a.emit(*[t & 0xFF for t in TRIALS])
    a.label('trials_hi')
    a.emit(*[t >> 8 for t in TRIALS])

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

    chr_rom = bytearray(0x400 * CHR_BANKS)
    for b in range(CHR_BANKS):
        chr_rom[0x400 * b] = b

    mapper = 69
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((mapper & 0x0F) << 4) | 0x01,
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[10] = 0x09                       # 32KB PRG RAM

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
