#!/usr/bin/env python3
"""Generate test ROMs for the Taito mapper chips (mappers 33, 48, 80, 82,
207 and 552).

Usage: taito.py OUT.nes VARIANT

The checks are in groups:
   1  PRG ROM: every bank through the register of 0x8000. Each 8KB bank
      holds its number at SIG_LO and its complement at SIG_HI
   2  The registers of 0xA000 and (X1 chips) 0xC000, and the fixed banks:
      the second last at 0xC000 (TC0190/TC0690) and the last at 0xE000.
      X1-005: the registers are in pairs (0x7EFB = 0x7EFA). X1-017: the bank
      bits of the register (82: bits 5-2; 552: bits 5-0 reversed)
   3  CHR ROM: the two 2KB banks and the four 1KB banks. Each 1KB bank
      holds its number at its first two bytes (low, high), read through
      $2006/$2007 with rendering off. TC0190/TC0690: 2KB banks in 2KB units
      reaching 512KB. X1 chips: bit 0 of the 2KB registers ignored; X1-017:
      CHR A12 inversion (0x7EF6 bit 1)
   4  Mirroring. 207: CIRAM A10 of each nametable is bit 7 of the 2KB bank
      register its address selects
   5  RAM. TC0190/TC0690: none, 0x6000 reads open bus. X1-005: 128 bytes at
      0x7F00 enabled by 0xA3 at 0x7EF8/9 and mirrored at 0x7F80, open bus
      when disabled. X1-017: 0x6000-0x67FF, 0x6800-0x6FFF and 0x7000-0x73FF
      enabled by 0xCA, 0x69 and 0x84 at 0x7EF7-0x7EF9; a read of disabled
      RAM, 0x7400-0x7FFF or a register gives 0 (the pull-downs)
   6  Register decode. TC0190: no registers at 0xC000-0xFFFF. TC0690:
      mirroring at 0xE000, not bit 6 of 0x8000. X1-005: the registers at
      0x7E70-0x7E7F as well (CPU A7 not seen). X1-017: not at 0x7E70
   7  IRQ (48, 82): no IRQ with IRQs disabled, and the acknowledges
   8  IRQ timing trials, one per entry of the board's trials: the IRQ
      handler stores the low byte of the return address, which tells which
      NOP of a sled the IRQ came after, at RESULTS + trial. Fails here if a
      sled runs out. 48 ('line'): rendering on (background at 0x0000,
      sprites at 0x1000, so A12 rises once a scanline); the NMI handler
      writes the inverted reload value N, reloads and enables, then waits
      until shortly before the IRQ, at scanline N - 1. 82 ('ack'): 0x7EFD =
      L, 0x7EFF (reload (L + 1) * 16, or 1 for L = 0), then 0x7EFE = 3;
      ('ctrl'): 0x7EFD = L, 0x7EFE = 2 (reload (L + 2) * 16, or 17), then 3
   9  The trial results against EXPECTED, within a NOP for 'line' trials

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed; the index of the
failing check in its group is at zero page DETAIL. The result is up about
20 frames after reset, so 500ms of nes_bench is enough.

Variants:
  33       iNES 33, 512KB PRG, 512KB CHR
  48       iNES 48, 256KB PRG, 256KB CHR
  80       iNES 80, 256KB PRG, 256KB CHR
  80_nes2  NES 2.0 80 with 128 bytes of battery-backed PRG RAM
  207      iNES 207, 256KB PRG, 128KB CHR
  82       iNES 82, 128KB PRG, 256KB CHR, battery
  552      NES 2.0 552, 512KB PRG, 256KB CHR, 8KB battery-backed PRG RAM

With MESEN set, the checks where Mesen is known to differ are left out:
33 writes at 0xC000-0xFFFF (it decodes 0xA003, so they alias 0x8000-0xBFFF);
bit 0 of the X1 2KB CHR registers (it uses it); the X1-005 registers at
0x7E70 and its RAM only at 0x7F00 (Mesen mirrors it through 0x6000-0x7FFF);
PRG RAM on the TC0190/TC0690 (Mesen gives every board some); the X1-017 pull-downs (it reads open bus) and IRQ (not emulated);
bits 7-6 of the 82 PRG registers (it takes bits 7-2). The 48 trial results
in EXPECTED are Mesen's.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    '33':      dict(mapper=33, prg_banks=64, chr_banks=512),
    '48':      dict(mapper=48, prg_banks=32, chr_banks=256),
    '80':      dict(mapper=80, prg_banks=32, chr_banks=256),
    '80_nes2': dict(mapper=80, prg_banks=32, chr_banks=256, nes2=True,
                    prg_ram=0x10),
    '207':     dict(mapper=207, prg_banks=32, chr_banks=128),
    '82':      dict(mapper=82, prg_banks=16, chr_banks=256, battery=True),
    '552':     dict(mapper=552, prg_banks=64, chr_banks=256, nes2=True,
                    prg_ram=0x70),
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
# Bit 7 set: the NMI handler starts a 'line' trial
NMI_MODE = 0x06
PTR = 0x07
VAL = 0x08
RESULTS = 0x10

# The offset in each nametable of the bytes written to tell them apart
NT_OFFSET = 0x10

# (kind, value): the reload value N for 'line', the latch L otherwise
TRIALS = {
    48: [('line', 0x01), ('line', 0x02), ('line', 0x03), ('line', 0x10),
         ('line', 0x60), ('line', 0xA0)],
    82: [('ack', 0x00), ('ack', 0x01), ('ack', 0x02), ('ack', 0x05),
         ('ack', 0x10), ('ctrl', 0x00), ('ctrl', 0x01), ('ctrl', 0x05)],
}
TRIALS[552] = TRIALS[82]
KINDS = {'line': 0, 'ack': 1, 'ctrl': 2}
SLED_NOPS = 180
# The low bytes of the return addresses, or None to only record them. 48:
# Mesen's. 82 and 552: nes_bench's, which follow the counts of nesdev: each
# step of the latch is 16 cycles (8 NOPs), and 'ctrl' is 16 cycles more
# than 'ack' for the same latch but for a latch of 0 (17 rather than 1)
EXPECTED = {
    48: [0x41, 0x40, 0x3E, 0x69, 0x46, 0x6F],
    82: [0x00, 0x0F, 0x17, 0x2F, 0x87, 0x08, 0x17, 0x37],
}
EXPECTED[552] = EXPECTED[82]

# The CPU cycles of one iteration of delay_y
DELAY_LOOP = 116


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
STY_ZP, STX_ZP, SBC_IMM, SEC = 0x84, 0x86, 0xE9, 0x38
LDA_ZP, STA_ZP, LDX_ZP, LDY_ZP, INC_ZP = 0xA5, 0x85, 0xA6, 0xA4, 0xE6
LDA_ABS_X, LDY_ABS_X, STA_ZP_X, LDA_ZP_X = 0xBD, 0xBC, 0x95, 0xB5
LSR_A, AND_IMM, TAX, JSR, RTS, PHA, PLA = (0x4A, 0x29, 0xAA, 0x20, 0x60,
                                           0x48, 0x68)
BPL, BMI, BVS, BEQ, BNE, BCC = 0x10, 0x30, 0x70, 0xF0, 0xD0, 0x90
JMP_ABS, RTI = 0x4C, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX, DEY = (0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA,
                                          0xCA, 0x88)


# The scanline whose A12 rise raises the IRQ of a 'line' trial with reload
# value n, written in vblank: the pre-render rise reloads n and each visible
# scanline decrements it
def irq_line(n):
    return n - 1


# The outer count of delay_y that puts the IRQ of a 'line' trial about 160
# cycles into the sled. The NMI is at dot 1 of scanline 241 and the A12 rise
# near dot 260 of the IRQ scanline, (21 + line) scanlines later
def delay_for(n):
    cycles = ((21 + irq_line(n)) * 341 + 260) / 3 - 40 - 160
    return round(cycles / DELAY_LOOP)


def x1_017_prg_value(mapper, bank, junk):
    if mapper == 82:
        return (bank << 2) | (junk & 0x03) | (0 if MESEN else junk & 0xC0)
    value = 0
    for i in range(6):
        if bank & (1 << i):
            value |= 1 << (5 - i)
    return value | (junk & 0xC0)


def build(v):
    a = Assembler()
    # The group of checks and the index of the check in it
    step = [0]
    detail = [0]
    mapper = v['mapper']
    prg_banks = v['prg_banks']
    chr_banks = v['chr_banks']
    tc = mapper in (33, 48)
    x1_005 = mapper in (80, 207)
    x1_017 = mapper in (82, 552)
    trials = TRIALS.get(mapper, [])
    expected = EXPECTED.get(mapper)
    if MESEN and x1_017:
        trials = []

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

    # Fails with the group number unless A is below value
    def check_below(value):
        a.emit(LDX_IMM, step[0])
        a.emit(LDY_IMM, detail[0])
        a.emit(CMP_IMM, value)
        a.emit(BCC, 3)
        a.abs_label(JMP_ABS, 'show')
        detail[0] += 1

    def ppu_check(addr, value):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)                  # the read buffer
        a.abs(LDA_ABS, 0x2007)
        check(value)

    # The 1KB CHR bank at the window of addr, from its first two bytes
    def chr_check(addr, bank):
        bank %= chr_banks
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)                  # the read buffer
        a.abs(LDA_ABS, 0x2007)
        check(bank & 0xFF)
        a.abs(LDA_ABS, 0x2007)
        check(bank >> 8)

    def cpu_check(addr, value):
        a.abs(LDA_ABS, addr)
        check(value)

    def bank_check(window, b):
        b %= prg_banks
        cpu_check(window + SIG_LO, b)
        cpu_check(window + SIG_HI, b ^ 0xFF)

    # Waits about delay * DELAY_LOOP CPU cycles, with delay in Y
    def delay_y(name):
        a.label(name)
        a.emit(LDX_IMM, 22)
        a.label(name + '_inner')
        a.emit(DEX)
        a.branch(BNE, name + '_inner')
        a.emit(DEY)
        a.branch(BNE, name)

    # Waits about 5 * count CPU cycles
    def delay(count):
        a.emit(LDX_IMM, count)
        a.emit(DEX)
        a.emit(BNE, 0xFD)

    # The PRG bank registers of the windows at 0x8000, 0xA000, 0xC000
    if tc:
        prg_regs = [0x8000, 0x8001]
    elif x1_005:
        prg_regs = [0x7EFA, 0x7EFC, 0x7EFE]
    else:
        prg_regs = [0x7EFA, 0x7EFB, 0x7EFC]

    def prg_bank(idx, b, junk=0x00):
        if tc:
            # 33 has the mirroring at bit 6 of 0x8000; leave it vertical
            value = b | (junk & 0x80)
        elif x1_005:
            value = b
        else:
            value = x1_017_prg_value(mapper, b, junk)
        write(prg_regs[idx], value)

    chr_regs = ([0x8002, 0x8003, 0xA000, 0xA001, 0xA002, 0xA003] if tc
                else [0x7EF0 + i for i in range(6)])

    # The 1KB bank the board maps at window w (of 0x400 bytes)
    def chr_bank(regs, w, invert=False):
        sw = w ^ (4 if invert else 0)
        if sw >= 4:
            return regs[sw - 2]
        r = regs[sw // 2]
        if tc:
            return 2 * r + (sw & 1)
        if mapper == 207:
            r &= 0x7F
        return (r & 0xFE) | (sw & 1)

    def mirror_reg(mode):
        # mode 'h' or 'v'
        if mapper == 33:
            write(0x8000, 0x40 if mode == 'h' else 0x00)
        elif mapper == 48:
            write(0xE000, 0x40 if mode == 'h' else 0x00)
        elif x1_005:
            write(0x7EF6, 0x01 if mode == 'v' else 0x00)
        else:
            write(0x7EF6, 0x01 if mode == 'v' else 0x00)

    # Writes each nametable with its own byte; each then reads back the byte
    # of the last nametable written that shares its CIRAM page
    def nt_share(pages, base):
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i + NT_OFFSET, base + i)
        for i in range(4):
            last = max(j for j in range(4) if pages[j] == pages[i])
            ppu_check(0x2000 + 0x400 * i + NT_OFFSET, base + last)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    write(0x4010, 0x00)
    write(0x4017, 0x40)                         # no frame IRQ
    if mapper == 48:
        write(0xC003, 0x00)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, TRIAL)
    a.emit(STA_ZP, NMI_MODE)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # PRG ROM banks
    next_group()
    for b in range(prg_banks):
        prg_bank(0, b, 0xC3 if b & 1 else 0x81)
        bank_check(0x8000, b)

    next_group()
    for b in (3, prg_banks - 3, prg_banks - 1):
        prg_bank(1, b)
        bank_check(0xA000, b)
    if tc:
        bank_check(0xC000, prg_banks - 2)
    else:
        for b in (5, prg_banks - 4, prg_banks - 1):
            prg_bank(2, b)
            bank_check(0xC000, b)
    bank_check(0xE000, prg_banks - 1)
    bank_check(0x8000, prg_banks - 1)
    if x1_005:
        # The second register of each pair
        write(0x7EFB, 6)
        write(0x7EFD, 7)
        write(0x7EFF, 8)
        bank_check(0x8000, 6)
        bank_check(0xA000, 7)
        bank_check(0xC000, 8)
    if x1_017:
        # Bits 1-0 (and bits 7-6) are not bank bits
        prg_bank(0, 9, 0xC3)
        bank_check(0x8000, 9)
        prg_bank(1, prg_banks - 2, 0x42)
        bank_check(0xA000, prg_banks - 2)

    # CHR ROM banks
    next_group()
    if tc:
        regs = [0xF3 if chr_banks > 256 else 0x73, 0x4E, 0xC5, 0x1A, 0x67,
                0xB8]
    else:
        regs = [0xA6, 0x5C, 0xC5, 0x1A, 0x67, 0xB8]
        if not MESEN:
            regs[0] |= 1
            regs[1] |= 1
        if mapper == 207:
            regs[0] &= 0x7F
            regs[1] &= 0x7F
    for r, value in zip(chr_regs, regs):
        write(r, value)
    for w in range(8):
        chr_check(0x400 * w, chr_bank(regs, w))
    if x1_017:
        write(0x7EF6, 0x02)
        for w in range(8):
            chr_check(0x400 * w, chr_bank(regs, w, True))
        write(0x7EF6, 0x00)
        for w in range(8):
            chr_check(0x400 * w, chr_bank(regs, w))

    # Mirroring
    next_group()
    if mapper == 207:
        write(0x7EF0, 0x00)
        write(0x7EF1, 0x80)
        nt_share([0, 0, 1, 1], 0x40)
        write(0x7EF0, 0x81)
        write(0x7EF1, 0x02)
        nt_share([1, 1, 0, 0], 0x50)
        write(0x7EF0, 0x83)
        write(0x7EF1, 0x84)
        nt_share([1, 1, 1, 1], 0x60)
        write(0x7EF0, 0x05)
        nt_share([0, 0, 1, 1], 0x70)
        # 0x7EF6 does nothing
        write(0x7EF6, 0x01)
        nt_share([0, 0, 1, 1], 0x80)
        write(0x7EF1, 0x06)
        nt_share([0, 0, 0, 0], 0x90)
    else:
        mirror_reg('v')
        nt_share([0, 1, 0, 1], 0x40)
        mirror_reg('h')
        nt_share([0, 0, 1, 1], 0x50)
        mirror_reg('v')
        nt_share([0, 1, 0, 1], 0x60)

    # RAM
    next_group()
    if tc:
        # Mesen gives every board PRG RAM
        if not MESEN:
            write(0x6000, 0x55)
            cpu_check(0x6000, 0x60)
            cpu_check(0x7FFF, 0x7F)
    elif x1_005:
        # Disabled at power on
        cpu_check(0x7F00, 0x7F)
        write(0x7EF8, 0xA3)
        write(0x7F00, 0x11)
        write(0x7F7F, 0x22)
        cpu_check(0x7F00, 0x11)
        cpu_check(0x7F80, 0x11)
        cpu_check(0x7FFF, 0x22)
        write(0x7F85, 0x33)
        cpu_check(0x7F05, 0x33)
        # Nothing else in 0x6000-0x7EFF
        if not MESEN:
            cpu_check(0x6000, 0x60)
            cpu_check(0x7E00, 0x7E)
        # Disabled by the second register of the pair, and by any other
        # value
        write(0x7EF9, 0xA2)
        cpu_check(0x7F00, 0x7F)
        write(0x7F00, 0x44)
        write(0x7EF9, 0xA3)
        cpu_check(0x7F00, 0x11)
        write(0x7EF8, 0x00)
        cpu_check(0x7FFF, 0x7F)
        write(0x7EF8, 0xA3)
        cpu_check(0x7FFF, 0x22)
    else:
        if not MESEN:
            # Disabled at power on, reading 0
            cpu_check(0x6000, 0x00)
            cpu_check(0x7000, 0x00)
        write(0x7EF7, 0xCA)
        write(0x7EF8, 0x69)
        write(0x7EF9, 0x84)
        parts = ((0x6000, 0xA1), (0x67FF, 0xA2), (0x6800, 0xB1),
                 (0x6FFF, 0xB2), (0x7000, 0xC1), (0x73FF, 0xC2))
        for addr, value in parts:
            write(addr, value)
        for addr, value in parts:
            cpu_check(addr, value)
        if not MESEN:
            cpu_check(0x7400, 0x00)
            cpu_check(0x7EF0, 0x00)
            cpu_check(0x7FFF, 0x00)
        # The parts are enabled on their own
        write(0x7EF8, 0x68)
        if not MESEN:
            cpu_check(0x6800, 0x00)
        write(0x6800, 0xFF)
        cpu_check(0x6000, 0xA1)
        cpu_check(0x7000, 0xC1)
        write(0x7EF7, 0x00)
        write(0x7EF9, 0x85)
        if not MESEN:
            cpu_check(0x6000, 0x00)
            cpu_check(0x73FF, 0x00)
        write(0x7EF7, 0xCA)
        write(0x7EF8, 0x69)
        write(0x7EF9, 0x84)
        for addr, value in parts:
            cpu_check(addr, value)

    # Register decode
    next_group()
    if mapper == 33:
        if not MESEN:
            prg_bank(0, 4)
            prg_bank(1, 5)
            write(chr_regs[2], 0x21)
            for addr in (0xC000, 0xC001, 0xE000, 0xE002):
                write(addr, 0x47)
            bank_check(0x8000, 4)
            bank_check(0xA000, 5)
            chr_check(0x1000, 0x21)
            nt_share([0, 1, 0, 1], 0x70)
        # Mirrors of the registers at A2-A12
        write(0x9FFC, 0x0A)
        write(0xBFFE, 0x31)
        bank_check(0x8000, 0x0A)
        chr_check(0x1800, 0x31)
    elif mapper == 48:
        # Bit 6 of 0x8000 is a PRG bank bit's neighbour, not mirroring
        write(0x8000, 0x40 | 4)
        bank_check(0x8000, 4)
        nt_share([0, 1, 0, 1], 0x70)
        write(0xFFFC, 0x40)
        nt_share([0, 0, 1, 1], 0x80)
        write(0xE000, 0x00)
        # Mirrors of the registers at A2-A12
        write(0x9FFD, 0x0B)
        bank_check(0xA000, 0x0B)
    elif x1_005:
        if not MESEN:
            write(0x7E7A, 0x0C)
            write(0x7E73, 0x29)
            bank_check(0x8000, 0x0C)
            chr_check(0x1400, 0x29)
            write(0x7E79, 0x00)
            cpu_check(0x7F00, 0x7F)
            write(0x7E78, 0xA3)
            cpu_check(0x7F00, 0x11)
    else:
        # Not at 0x7E70-0x7E7F
        prg_bank(0, 2)
        a.emit(LDA_IMM, x1_017_prg_value(mapper, 3, 0))
        a.abs(STA_ABS, 0x7E7A)
        bank_check(0x8000, 2)

    # IRQ
    next_group()
    if mapper == 48:
        # Disabled: no IRQ through a frame of rendering that would raise
        # one every scanline
        a.emit(LDA_IMM, step[0])
        a.emit(STA_ZP, FAIL_STEP)
        # Sprites at 0x1000, so A12 rises once a scanline
        write(0x2000, 0x08)
        write(0xC003, 0x00)
        write(0xC000, 0xFE)
        write(0xC001, 0x00)
        wait_vblank('irq_vblank_1')
        write(0x2001, 0x18)
        a.emit(CLI)
        wait_vblank('irq_vblank_2')
        a.emit(SEI)
        write(0x2001, 0x00)
        # Raised with the CPU's I flag set, then acknowledged by 0xC003
        # (which also disables IRQs), 0xC000 and 0xC001; 0xC002 does not
        a.emit(LDA_IMM, 0x40)
        a.emit(STA_ZP, MODE)
        for i, ack in enumerate((0xC003, 0xC000, 0xC001, None)):
            a.emit(LDA_IMM, 0x00)
            a.emit(STA_ZP, DONE)
            write(0xC000, 0xFE)
            write(0xC001, 0x00)
            write(0xC002, 0x00)
            wait_vblank('irq_ack_vblank_%d' % i)
            write(0x2001, 0x18)
            # Into the visible scanlines, past several IRQs, then rendering
            # off and long enough for the last delayed IRQ to be raised
            a.emit(LDY_IMM, 40)
            delay_y('irq_ack_delay_%d' % i)
            write(0x2001, 0x00)
            delay(20)
            if ack is None:
                write(0xC002, 0x00)
            else:
                write(ack, 0xFE)
            a.emit(CLI)
            a.emit(NOP)
            a.emit(SEI)
            a.emit(LDA_ZP, DONE)
            check(0x01 if ack is None else 0x00)
        write(0x2000, 0x00)
        a.emit(LDA_IMM, 0x80)
        a.emit(STA_ZP, MODE)
    elif x1_017 and not MESEN:
        a.emit(LDA_IMM, step[0])
        a.emit(STA_ZP, FAIL_STEP)
        # What the games write: no IRQ, as bit 2 stops the counter
        write(0x7EFD, 0xFF)
        write(0x7EFE, 0xFF)
        write(0x7EFF, 0xFF)
        a.emit(CLI)
        delay(250)
        a.emit(SEI)
        # Counting with /IRQ off: the counter reaches 0 (1 cycle), no IRQ
        write(0x7EFD, 0x00)
        write(0x7EFF, 0x00)
        write(0x7EFE, 0x01)
        a.emit(CLI)
        delay(4)
        a.emit(SEI)
        # Turning /IRQ on raises it, and 0x7EFF acknowledges it
        a.emit(LDA_IMM, 0x40)
        a.emit(STA_ZP, MODE)
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, DONE)
        write(0x7EFE, 0x03)
        a.emit(LDA_ZP, DONE)
        check(0x00)
        a.emit(CLI)
        a.emit(NOP)
        a.emit(SEI)
        a.emit(LDA_ZP, DONE)
        check(0x01)
        # With the counter stopped (bit 2) it does not count
        write(0x7EFE, 0x00)
        write(0x7EFF, 0x00)
        write(0x7EFE, 0x07)
        a.emit(CLI)
        delay(4)
        a.emit(SEI)
        a.emit(LDA_ZP, DONE)
        check(0x01)
        write(0x7EFE, 0x00)
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
        if mapper == 48:
            write(0xC003, 0x00)
            # Rendering on and NMIs
            a.emit(LDA_IMM, 0x00)
            a.emit(STA_ZP, NMI_MODE)
            wait_vblank('trial_vblank')
            write(0x2001, 0x18)
            write(0x2000, 0x88)
            a.emit(LDA_IMM, 0x80)
            a.emit(STA_ZP, NMI_MODE)
            a.label('trial_wait')
            a.abs_label(JMP_ABS, 'trial_wait')
        else:
            write(0x7EFE, 0x00)
            a.abs_label(LDA_ABS_X, 'values')
            a.abs(STA_ABS, 0x7EFD)
            a.abs_label(LDA_ABS_X, 'kinds')
            a.emit(CMP_IMM, KINDS['ack'])
            a.branch(BNE, 'trial_ctrl')
            # 'ack': 0x7EFF reloads the counter
            a.abs(STA_ABS, 0x7EFF)
            a.abs_label(JMP_ABS, 'trial_start')
            # 'ctrl': 0x7EFE = 2 reloads it, stopped
            a.label('trial_ctrl')
            write(0x7EFE, 0x02)
            a.label('trial_start')
            a.emit(LDA_IMM, 0x03)
            a.emit(CLI)
            a.abs(STA_ABS, 0x7EFE)
            a.abs_label(JMP_ABS, 'sled')
    else:
        # Never reached, but the IRQ handler links to it
        a.label('trial')
    next_group()

    a.label('trials_done')
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    if expected is not None and trials:
        assert len(expected) == len(trials)
        for t, value in enumerate(expected):
            a.emit(LDA_ZP, RESULTS + t)
            if trials[t][0] == 'line':
                a.emit(SEC)
                a.emit(SBC_IMM, (value - 1) & 0xFF)
                check_below(3)
            else:
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

    # NMI: start a 'line' trial
    a.label('nmi')
    a.emit(BIT_ZP, NMI_MODE)
    a.branch(BMI, 'nmi_trial')
    a.emit(RTI)
    a.label('nmi_trial')
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, NMI_MODE)
    if mapper == 48:
        a.emit(LDX_ZP, TRIAL)
        a.abs_label(LDA_ABS_X, 'values')
        a.abs(STA_ABS, 0xC000)
        a.abs(STA_ABS, 0xC001)
        a.abs(STA_ABS, 0xC002)
        a.abs_label(LDY_ABS_X, 'delays')
        delay_y('trial_delay')
        a.emit(CLI)
        a.abs_label(JMP_ABS, 'sled')
    else:
        a.emit(RTI)

    a.label('irq')
    a.emit(BIT_ZP, MODE)
    a.branch(BMI, 'irq_fail')
    a.branch(BVS, 'irq_count')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    if mapper == 48:
        write(0xC003, 0x00)
    else:
        write(0x7EFE, 0x00)
        a.abs(STA_ABS, 0x7EFF)
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
    if mapper == 48:
        a.abs(STA_ABS, 0xC003)
    else:
        a.abs(STA_ABS, 0x7EFF)
        write(0x7EFE, 0x00)
    a.emit(RTI)

    a.label('kinds')
    a.emit(*[KINDS[k] for k, _ in trials])
    a.label('values')
    a.emit(*[n ^ 0xFF if k == 'line' else n for k, n in trials])
    a.label('delays')
    a.emit(*[delay_for(n) if k == 'line' else 0 for k, n in trials])

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
        chr_rom[0x400 * b + 1] = b >> 8

    flags6 = ((mapper & 0x0F) << 4) | (0x02 if v.get('battery') else 0x00)
    flags7 = mapper & 0xF0
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000])
    if v.get('nes2'):
        header += bytes([flags6 | 0x02, flags7 | 0x08, mapper >> 8, 0,
                         v['prg_ram'], 0, 0, 0, 0, 0])
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
