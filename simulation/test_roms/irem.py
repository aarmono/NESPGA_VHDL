#!/usr/bin/env python3
"""Generate test ROMs for the boards with 8KB PRG ROM banks and registers
selected by CPU A14-A12: Irem G-101 (32), Irem H3001 (65) and Konami VRC1
(75).

Usage: irem.py OUT.nes VARIANT

The checks are in groups:
   1  PRG ROM: the H3001 powers on with banks 0 and 1 at 0x8000 and 0xA000.
      Every bank through the register of 0x8000, others through those of
      0xA000 (and 0xC000 on the VRC1), the second last bank fixed at 0xC000
      and the last at 0xE000. Each 8KB bank holds its number at SIG_LO and
      its complement at SIG_HI. The registers ignore A11-A0
   2  PRG mode (G-101 0x9000 bit 1, H3001 0x9000 bit 7): the bank of 0x8000
      at 0xC000 and the second last bank at 0x8000. Major League (32
      submapper 1) has no control register
   3  CHR ROM: the eight 1KB banks at 0xB000-0xB007 (A2-A0, A11-A3
      ignored), or the two 4KB banks of the VRC1, with their low 4 bits at
      0xE000/0xF000 and the high bits at 0x9000. Each 1KB bank holds its
      number at its first byte
   4  Mirroring. G-101 and VRC1: 0x9000 bit 0. H3001: 0x9001 bits 7-6, one
      screen for 01 and 11. Major League: one screen. A four-screen VRC1
      board ignores bit 0
   5  Register decode: G-101 and H3001 have no registers at 0xC000-0xFFFF;
      the H3001 registers at 0x9000 decode A2-A0 only
   6  IRQ (H3001): none while disabled or with a count of 0; 0x9003 and
      0x9004 acknowledge it; it disables itself when raised
   7  IRQ timing trials: the reload value N is written to 0x9005/0x9006,
      0x9004 loads it and 0x9003 = 0x80 starts the counter, which raises the
      IRQ N cycles later. The IRQ handler stores the low byte of the return
      address, which tells which NOP of a sled the IRQ came after, at
      RESULTS + trial. Fails here if a sled runs out
   8  The trial results against EXPECTED

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed; the index of the
failing check in its group is at zero page DETAIL. The result is up a few
frames after reset, so 250ms of nes_bench is enough.

Variants:
  32       iNES 32, 256KB PRG, 128KB CHR
  32_1     NES 2.0 32 submapper 1 (Major League), 128KB PRG, 128KB CHR
  65       iNES 65, 256KB PRG, 256KB CHR
  75       iNES 75, 128KB PRG, 128KB CHR
  75_four  iNES 75 with the four-screen bit

With MESEN set, the checks where Mesen is known to differ are left out: the
H3001 PRG mode, one screen mirroring, register mirrors and the writes at
0xC000 (Mesen decodes exact addresses, has no PRG mode and has a PRG bank
register at 0xC000), the H3001 count of 0 (Mesen counts it down through
0xFFFF). EXPECTED is Mesen's. Mesen fails group 4 of 32_1: it does not
give it one screen mirroring.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    '32':      dict(board='g101', mapper=32, prg_banks=32, chr_banks=128),
    '32_1':    dict(board='g101_1', mapper=32, prg_banks=16, chr_banks=128,
                    nes2=True, submapper=1),
    '65':      dict(board='h3001', mapper=65, prg_banks=32, chr_banks=256),
    '75':      dict(board='vrc1', mapper=75, prg_banks=16, chr_banks=128),
    '75_four': dict(board='vrc1', mapper=75, prg_banks=16, chr_banks=128,
                    four=True),
}

# Builds the ROM for Mesen, see above
MESEN = False
# Shows the trial results in the backdrop before the result, a nibble per
# frame after a black frame, colors DUMP_COLORS, since nes_bench cannot dump
# RAM
DUMP = False
DUMP_COLORS = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
               0x0A, 0x0B, 0x0C, 0x10, 0x20, 0x2D]

PASS_COLOR = 0x2A

# The code is in the last 8KB bank, which is fixed at 0xE000. Each bank
# holds its number at SIG_LO and its complement at SIG_HI, clear of the code
# and the vectors
ORG = 0xE100
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# Zero page
DETAIL = 0x00
TRIAL = 0x01
# Bit 7 set: an IRQ now is a failure, of group FAIL_STEP. Bit 6 set: an IRQ
# is expected, and counted in DONE
MODE = 0x02
FAIL_STEP = 0x03
DONE = 0x04
PTR = 0x07
VAL = 0x08
RESULTS = 0x10

# The offset in each nametable of the bytes written to tell them apart
NT_OFFSET = 0x10

# The reload values of the H3001 timing trials, the cycles to the IRQ
TRIALS = [0x0001, 0x0002, 0x0003, 0x0004, 0x0015, 0x0016, 0x0101]
SLED_NOPS = 180
# The low bytes of the return addresses Mesen gives, or None to only record
# them
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
        assert name not in self.labels, name
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
STY_ZP, STX_ZP = 0x84, 0x86
LDA_ZP, STA_ZP, LDX_ZP, LDY_ZP, INC_ZP = 0xA5, 0x85, 0xA6, 0xA4, 0xE6
LDA_ABS_X, STA_ZP_X, LDA_ZP_X = 0xBD, 0x95, 0xB5
LSR_A, AND_IMM, TAX, JSR, RTS, PHA, PLA = (0x4A, 0x29, 0xAA, 0x20, 0x60,
                                           0x48, 0x68)
BPL, BMI, BVS, BEQ, BNE = 0x10, 0x30, 0x70, 0xF0, 0xD0
JMP_ABS, RTI = 0x4C, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX, DEY = (0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA,
                                          0xCA, 0x88)



def build(v):
    a = Assembler()
    # The group of checks and the index of the check in it
    step = [0]
    detail = [0]
    board = v['board']
    mapper = v['mapper']
    g101 = board in ('g101', 'g101_1')
    h3001 = board == 'h3001'
    vrc1 = board == 'vrc1'
    prg_banks = v['prg_banks']
    chr_banks = v['chr_banks']
    trials = TRIALS if h3001 else []

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

    # Waits about 5 * count CPU cycles
    def delay(count):
        a.emit(LDX_IMM, count)
        a.emit(DEX)
        a.emit(BNE, 0xFD)

    # Waits 1286 * count + 1 CPU cycles (count below 256)
    def delay_long(count):
        a.emit(LDY_IMM, count)
        a.emit(LDX_IMM, 0x00)                   # 2
        a.emit(DEX)                             # 256 * 5 - 1
        a.emit(BNE, 0xFD)
        a.emit(DEY)                             # 2
        a.emit(BNE, 0xF8)                       # 3, 2 the last time

    # Writes each nametable with its own byte; each then reads back the byte
    # of the last nametable written that shares its CIRAM page
    def nt_share(pages, base):
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i + NT_OFFSET, base + i)
        for i in range(4):
            last = max(j for j in range(4) if pages[j] == pages[i])
            ppu_check(0x2000 + 0x400 * i + NT_OFFSET, base + last)

    # A mirror of a register address, unless MESEN: G-101 and VRC1 ignore
    # A11-A0, the H3001 A11-A3 (A2-A0 select the registers at 0x9000 and
    # 0xB000)
    def mirror(addr, n):
        if MESEN and h3001:
            return addr
        if (g101 or vrc1) and (addr & 0xF000) != 0xB000:
            return addr | ((n * 0x5A5) & 0x0FFF)
        return addr | ((n * 0x5A8) & 0x0FF8)

    # The bits of the PRG bank registers: 5 on the G-101, 4 on the VRC1
    def prg_value(b, junk):
        if g101:
            return b | (junk & 0xE0)
        if vrc1:
            return b | (junk & 0xF0)
        return b

    # The control register of the G-101 and VRC1, with the CHR bank high
    # bits of the VRC1 kept as the CHR checks set them
    chr_hi = [0]

    def control(mirror_h=False, swap=False):
        value = (0x01 if mirror_h else 0) | (0x02 if swap else 0)
        if vrc1:
            value |= chr_hi[0]
        write(0x9000, value)

    def ack():
        write(0x9003, 0x00)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    write(0x4010, 0x00)
    write(0x4017, 0x40)                         # no frame IRQ
    if h3001:
        ack()
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, TRIAL)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # PRG ROM banks
    next_group()
    if h3001:
        bank_check(0x8000, 0)
        bank_check(0xA000, 1)
    for b in range(prg_banks):
        write(mirror(0x8000, b), prg_value(b, 0xA5 if b & 1 else 0x5A))
        bank_check(0x8000, b)
    for b in (3, prg_banks - 3, prg_banks - 1):
        write(mirror(0xA000, b), prg_value(b, 0xFF))
        bank_check(0xA000, b)
    if vrc1:
        for b in (5, prg_banks - 4, prg_banks - 1):
            write(mirror(0xC000, b), prg_value(b, 0xFF))
            bank_check(0xC000, b)
    else:
        bank_check(0xC000, prg_banks - 2)
    bank_check(0xE000, prg_banks - 1)
    bank_check(0x8000, prg_banks - 1)

    # PRG mode
    next_group()
    write(0x8000, 4)
    if g101:
        control(swap=True)
    elif h3001 and not MESEN:
        write(0x9000, 0x80)
    if board == 'g101' or (h3001 and not MESEN):
        bank_check(0x8000, prg_banks - 2)
        bank_check(0xC000, 4)
        # The register still selects the bank, now at 0xC000
        write(0x8000, 6)
        bank_check(0xC000, 6)
        bank_check(0xA000, prg_banks - 1)
        bank_check(0xE000, prg_banks - 1)
        if g101:
            control()
        else:
            write(0x9000, 0x7F)
        bank_check(0x8000, 6)
        bank_check(0xC000, prg_banks - 2)
    elif board == 'g101_1':
        bank_check(0x8000, 4)
        bank_check(0xC000, prg_banks - 2)

    # CHR ROM banks
    next_group()
    if vrc1:
        # 4KB banks of 5 bits
        for lo, hi in ((0x15, 0x0A), (0x0C, 0x13), (0x1F, 0x00)):
            chr_hi[0] = (0x02 if lo & 0x10 else 0) | (0x04 if hi & 0x10
                                                      else 0)
            write(0xE000, (lo & 0x0F) | 0xF0)
            write(0xF000, (hi & 0x0F) | 0xA0)
            control()
            for w in range(8):
                ppu_check(0x400 * w, (4 * (hi if w >= 4 else lo) + (w & 3))
                          % chr_banks)
        # The low bits alone leave the high bits
        write(mirror(0xF000, 3), 0x05)
        ppu_check(0x1000, 4 * 0x05)
        ppu_check(0x0000, 4 * 0x1F)
    else:
        regs = [(0x5B + 0x25 * w) % chr_banks for w in range(8)]
        for w, r in enumerate(regs):
            write(mirror(0xB000 + w, w), r)
        for w in range(8):
            ppu_check(0x400 * w, regs[w])
        if not (MESEN and h3001):
            # A3 is not decoded
            write(0xB00D, 0x11)
            ppu_check(0x1400, 0x11)
            ppu_check(0x1C00, regs[7])

    # Mirroring
    next_group()
    if board == 'g101_1':
        # Single screen whatever 0x9000 holds
        nt_share([0, 0, 0, 0], 0x40)
        write(0x9000, 0x01)
        nt_share([0, 0, 0, 0], 0x50)
    elif h3001:
        write(0x9001, 0x00)
        nt_share([0, 1, 0, 1], 0x40)
        write(mirror(0x9001, 1), 0xBF)
        nt_share([0, 0, 1, 1], 0x50)
        if not MESEN:
            write(0x9001, 0x40)
            nt_share([0, 0, 0, 0], 0x60)
            write(mirror(0x9001, 2), 0xC0)
            nt_share([0, 0, 0, 0], 0x70)
        write(0x9001, 0x3F)
        nt_share([0, 1, 0, 1], 0x80)
    elif v.get('four'):
        control(mirror_h=True)
        nt_share([0, 1, 2, 3], 0x40)
        control()
        nt_share([0, 1, 2, 3], 0x50)
    else:
        control()
        nt_share([0, 1, 0, 1], 0x40)
        control(mirror_h=True)
        nt_share([0, 0, 1, 1], 0x50)
        control()
        nt_share([0, 1, 0, 1], 0x60)

    # Register decode
    next_group()
    if g101 or (h3001 and not MESEN):
        write(0x8000, 7)
        write(0xA000, 8)
        for addr in (0xC000, 0xD000, 0xE000, 0xF000, 0xFFFF):
            write(addr, 0x02)
        bank_check(0x8000, 7)
        bank_check(0xA000, 8)
        bank_check(0xC000, prg_banks - 2)
        bank_check(0xE000, prg_banks - 1)
    if h3001 and not MESEN:
        # 0x9000 decodes A2-A0: 0x9008 is 0x9000 and 0x9002 nothing
        write(0x9008, 0x80)
        bank_check(0x8000, prg_banks - 2)
        write(0x9002, 0x00)
        bank_check(0x8000, prg_banks - 2)
        write(0x97F8, 0x00)
        bank_check(0x8000, 7)

    # IRQ
    next_group()
    if h3001:
        a.emit(LDA_IMM, step[0])
        a.emit(STA_ZP, FAIL_STEP)
        # Disabled: no IRQ
        write(0x9005, 0x00)
        write(0x9006, 0x01)
        write(0x9004, 0x00)
        a.emit(CLI)
        delay(50)
        a.emit(SEI)
        if not MESEN:
            # A count of 0 does not count
            write(0x9006, 0x00)
            write(0x9004, 0x00)
            write(0x9003, 0x80)
            a.emit(CLI)
            delay_long(52)
            a.emit(SEI)
            ack()
        a.emit(LDA_IMM, 0x40)
        a.emit(STA_ZP, MODE)
        # Raised with the CPU's I flag set, then acknowledged by 0x9003 and
        # 0x9004 but not 0x9005 or 0x9001
        write(0x9006, 0x02)
        for ack_addr, taken in ((0x9003, 0), (0x9004, 0), (0x9005, 1),
                                (0x9001, 1)):
            a.emit(LDA_IMM, 0x00)
            a.emit(STA_ZP, DONE)
            write(0x9004, 0x00)
            write(0x9003, 0x80)
            delay(4)
            write(ack_addr, 0x00 if ack_addr != 0x9001 else 0x80)
            a.emit(CLI)
            a.emit(NOP)
            a.emit(SEI)
            a.emit(LDA_ZP, DONE)
            check(taken)
        # It disabled itself: reloading does not start it again
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, DONE)
        write(0x9004, 0x00)
        write(0x9003, 0x80)
        delay(4)
        write(0x9004, 0x00)
        a.emit(CLI)
        delay(20)
        a.emit(SEI)
        a.emit(LDA_ZP, DONE)
        check(0)
        a.emit(LDA_IMM, 0x80)
        a.emit(STA_ZP, MODE)

    # The timing trials. The IRQ handler starts the next one
    next_group()
    trial_step = step[0]
    if trials:
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, MODE)
        a.label('trial')
        a.emit(LDX_ZP, TRIAL)
        a.abs_label(LDA_ABS_X, 'values_hi')
        a.abs(STA_ABS, 0x9005)
        a.abs_label(LDA_ABS_X, 'values_lo')
        a.abs(STA_ABS, 0x9006)
        a.abs(STA_ABS, 0x9004)
        a.emit(LDA_IMM, 0x80)
        a.emit(CLI)
        a.abs(STA_ABS, 0x9003)
        a.abs_label(JMP_ABS, 'sled')
    else:
        # Never reached, but the IRQ handler links to it
        a.label('trial')
    next_group()

    a.label('trials_done')
    if EXPECTED is not None and trials:
        assert len(EXPECTED) == len(trials)
        for t, value in enumerate(EXPECTED):
            a.emit(LDA_ZP, RESULTS + t)
            check(value)
    a.emit(LDX_IMM, PASS_COLOR)
    a.emit(LDY_IMM, 0x00)
    if DUMP:
        a.abs_label(JMP_ABS, 'show')

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show_color' if DUMP else 'show')
    a.emit(SEI)
    a.emit(STY_ZP, DETAIL)
    write(0x2000, 0x00)
    write(0x2001, 0x00)
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

    a.label('irq')
    a.emit(BIT_ZP, MODE)
    a.branch(BMI, 'irq_fail')
    a.branch(BVS, 'irq_count')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    ack()
    a.emit(LDX_IMM, 0xFF, TXS)
    a.emit(INC_ZP, TRIAL)
    a.emit(LDA_ZP, TRIAL)
    a.emit(CMP_IMM, len(trials))
    a.branch(BEQ, 'irq_done')
    a.abs_label(JMP_ABS, 'trial')
    a.label('irq_done')
    a.abs_label(JMP_ABS, 'trials_done')
    a.label('irq_fail')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_IMM, 0xFF)
    a.abs_label(JMP_ABS, 'show')
    # Counts the IRQ and acknowledges it
    a.label('irq_count')
    a.emit(INC_ZP, DONE)
    a.emit(PHA)
    ack()
    a.emit(PLA)
    a.emit(RTI)

    a.label('values_hi')
    a.emit(*[n >> 8 for n in trials])
    a.label('values_lo')
    a.emit(*[n & 0xFF for n in trials])

    # The sled starts a page, so the low byte of the address is enough
    a.emit(*([0xFF] * (-a.here() % 0x100)))
    a.label('sled')
    a.emit(*([NOP] * SLED_NOPS))
    a.emit(LDX_IMM, trial_step)
    a.emit(LDY_ZP, TRIAL)
    a.abs_label(JMP_ABS, 'show')

    if DUMP:
        build_dump(a, wait_vblank, len(trials))

    code = a.link()
    assert ORG + len(code) <= 0xE000 + SIG_HI, \
        'code runs into SIG_HI: %d bytes' % len(code)

    prg = bytearray([0xFF]) * (0x2000 * prg_banks)
    for b in range(prg_banks):
        prg[0x2000 * b + SIG_LO] = b
        prg[0x2000 * b + SIG_HI] = b ^ 0xFF

    last = len(prg) - 0x2000
    prg[last + ORG - 0xE000:last + ORG - 0xE000 + len(code)] = code
    for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'), (0xFFFE, 'irq')):
        prg[last + vec - 0xE000] = a.labels[name] & 0xFF
        prg[last + vec - 0xE000 + 1] = a.labels[name] >> 8

    chr_rom = bytearray(0x400 * chr_banks)
    for b in range(chr_banks):
        chr_rom[0x400 * b] = b & 0xFF

    flags6 = ((mapper & 0x0F) << 4) | (0x08 if v.get('four') else 0x00)
    flags7 = mapper & 0xF0
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000])
    if v.get('nes2'):
        header += bytes([flags6, flags7 | 0x08,
                         (v.get('submapper', 0) << 4) | (mapper >> 8), 0,
                         0, 0, 0, 0, 0, 0])
    else:
        header += bytes([flags6, flags7]) + bytes(8)

    return bytes(header + prg + chr_rom)


# Shows RESULTS in the backdrop, then the pass/fail color in X
def build_dump(a, wait_vblank, num_trials):
    a.label('show')
    a.emit(SEI)
    a.emit(STX_ZP, FAIL_STEP)
    a.emit(STY_ZP, DETAIL)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    a.emit(LDA_IMM, RESULTS)
    a.emit(STA_ZP, PTR)
    a.label('dump_byte')
    for low in (False, True):
        a.emit(LDX_ZP, PTR)
        a.emit(LDA_ZP_X, 0x00)
        if low:
            a.emit(AND_IMM, 0x0F)
        else:
            a.emit(LSR_A, LSR_A, LSR_A, LSR_A)
        a.emit(TAX)
        a.abs_label(LDA_ABS_X, 'dump_colors')
        a.emit(STA_ZP, VAL)
        a.abs_label(JSR, 'dump_color')
    a.emit(INC_ZP, PTR)
    a.emit(LDA_ZP, PTR)
    a.emit(CMP_IMM, RESULTS + num_trials)
    a.branch(BNE, 'dump_byte')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_ZP, DETAIL)
    a.abs_label(JMP_ABS, 'show_color')

    # A black frame and then color VAL. The vblank wait can miss a frame,
    # so each color can last two, but the black frames still separate them
    a.label('dump_color')
    a.emit(LDA_ZP, VAL)
    a.emit(PHA)
    a.emit(LDA_IMM, 0x0F)
    a.emit(STA_ZP, VAL)
    a.abs_label(JSR, 'dump_show')
    a.emit(PLA)
    a.emit(STA_ZP, VAL)
    a.label('dump_show')
    wait_vblank('dump_vblank')
    a.emit(LDA_IMM, 0x3F)
    a.abs(STA_ABS, 0x2006)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2006)
    a.emit(LDA_ZP, VAL)
    a.abs(STA_ABS, 0x2007)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2006)
    a.abs(STA_ABS, 0x2006)
    a.emit(RTS)

    a.label('dump_colors')
    a.emit(*DUMP_COLORS)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
