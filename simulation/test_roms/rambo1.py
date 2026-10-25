#!/usr/bin/env python3
"""Generate test ROMs for the Tengen RAMBO-1 (mappers 64 and 158).

Usage: rambo1.py OUT.nes VARIANT

The checks are in groups:
   1  PRG ROM: every bank through R6 at 0x8000 in PRG mode 0. Each 8KB bank
      holds its number at SIG_LO and its complement at SIG_HI
   2  R7 at 0xA000, RF at 0xC000, the last bank at 0xE000, and a bank
      number wider than the ROM wrapping
   3  PRG mode 1: RF at 0x8000, R7 at 0xA000, R6 at 0xC000
 4-7  CHR ROM: R0-R5 with 2KB banks (R0 and R1 odd), in CHR mode 0 and 1,
      then R0, R8, R1, R9 as 1KB banks (bit 5 of 0x8000) in CHR mode 0 and
      1. Each 1KB bank holds its number at its first byte, read through
      $2006/$2007 with rendering off
   8  The bank registers at 0xA-0xE do not exist: writing them changes no
      bank, and R8/R9 are not R0/R1
   9  Mirroring: $A000 vertical/horizontal on 64; on 158 the CIRAM page of
      each nametable is bit 7 of the CHR bank at its 1KB window of
      0x0000-0x0FFF (R0/R1, R0/R8/R1/R9, or R2-R5 in CHR mode 1), and $A000
      does nothing
  10  No PRG RAM: 0x6000 reads open bus (the high byte of the address)
  11  The counter clocked in CPU cycle mode with IRQs disabled raises no
      IRQ, nor do IRQs enabled afterwards
  12  0xE001 does not acknowledge an IRQ that is already raised (with the
      CPU's I flag set), nor does stopping the counter
  13  IRQ timing trials, one per entry of TRIALS: the IRQ handler stores
      the low byte of the return address, which tells which NOP of a sled
      the IRQ came after, at RESULTS + trial. Fails here if a sled runs
      out. 'cpu' trials write $C000 and $C001 with CPU cycle mode just
      before the sled; 'period' trials do the same but acknowledge the
      first IRQ and time the second; 'line' trials run with rendering on
      (background at 0x0000, sprites at 0x1000, so A12 rises once a
      scanline), and the NMI handler writes $C000 and $C001 with scanline
      mode, then waits until shortly before the scanline of the IRQ
  14  The trial results against EXPECTED, within a NOP for the 'line'
      trials

The counter follows nesdev's rules demonstrated on hardware: on a clock, a
count of 0 raises the IRQ (one CPU cycle later, if enabled) and reloads the
latch, else the count is decremented. Writing $C001 loads the latch at once,
restarts the CPU cycle prescaler, and sets the 4-bit A12 filter (falls of M2
with A12 low) to 17, so the next rise of A12 does not clock the counter.
After a $C001 write in vblank, the rise of the pre-render scanline is
skipped and a latch of N raises the IRQ on scanline N; in CPU cycle mode the
IRQ is raised 4 * (N + 1) + 1 cycles after the write.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed; the index of the
failing check in its group is at zero page DETAIL. The result is up about
30 frames after reset, so 600ms of nes_bench is enough.

Variants:
  64       iNES mapper 64, 256KB PRG, 256KB CHR, vertical
  158      iNES mapper 158, 128KB PRG, 128KB CHR
  64_dump, 158_dump
           64 or 158, then the trial results shown in the backdrop, a
           nibble per frame after a black frame, colors DUMP_COLORS,
           followed by the pass/fail color
  64_continue, 158_continue
           Checks do not stop the ROM, so the trial results of Mesen can
           be read from zero page RESULTS even though it fails earlier
           groups

All pass in nes_bench. Mesen fails group 3: in PRG mode 1 it maps R6 at
0xA000 and R7 at 0xC000, where nesdev and Nestopia keep R7 at 0xA000 and
swap only 0x8000 and 0xC000. With the continue variants it also fails group
10 (it gives every board PRG RAM) and, on 158, group 9 (with 1KB CHR banks
it takes the nametable pages from R0/R1 rather than R8/R9, and it only
updates them when a bank register is written). Its counter follows its own
rules (a $C001 write reloads at the next clock with the latch + 2, or the
latch + 1 for a latch of 0 or 1, and an A12 rise clocks it after a PPU clock
filter), so its trial results differ in group 14 where the rules do: the
'cpu' and 'period' trials with a latch of 2 or more come 4 cycles (2 NOPs)
later, and the 'line' trials with a latch of 0 or 1 a scanline earlier,
before the sled.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    '64':      dict(mapper=64, prg_banks=32, chr_banks=256, dump=False),
    '158':     dict(mapper=158, prg_banks=16, chr_banks=128, dump=False),
    '64_dump': dict(mapper=64, prg_banks=32, chr_banks=256, dump=True),
    '158_dump': dict(mapper=158, prg_banks=16, chr_banks=128, dump=True),
    '64_continue': dict(mapper=64, prg_banks=32, chr_banks=256, dump=False,
                        cont=True),
    '158_continue': dict(mapper=158, prg_banks=16, chr_banks=128,
                         dump=False, cont=True),
}

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
# Set once the first IRQ of a 'period' trial was taken
SECOND = 0x05
# Bit 7 set: the NMI handler starts a 'line' trial
NMI_MODE = 0x06
PTR = 0x07
VAL = 0x08
RESULTS = 0x10

# The offset in each nametable of the bytes written to tell them apart
NT_OFFSET = 0x10

# (kind, latch)
TRIALS = [('cpu', 0x00), ('cpu', 0x01), ('cpu', 0x02), ('cpu', 0x03),
          ('cpu', 0x10), ('cpu', 0x30),
          ('period', 0x10), ('period', 0x20),
          ('line', 0x00), ('line', 0x01), ('line', 0x02), ('line', 0x03),
          ('line', 0x10), ('line', 0x80), ('line', 0xC0)]
KINDS = {'cpu': 0, 'period': 1, 'line': 2}
SLED_NOPS = 160
# The low bytes of the return addresses, or None to only record them. The
# 'cpu' and 'period' trials are what Mesen gives, 2 NOPs earlier for a latch
# of 2 or more. The 'line' trials are what nes_bench gives, and may be a NOP
# off: where the NMI lands in the wait loop depends on how the CPU and PPU
# clocks line up, so they move with the code layout (64 and 158 differ). With
# a latch of 2 or more they are within a NOP of Mesen
EXPECTED = [0x02, 0x04, 0x06, 0x08, 0x22, 0x62, 0x2B, 0x6B,
            0x35, 0x34, 0x34, 0x32, 0x5D, 0x4E, 0x3E]

DUMP_COLORS = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
               0x0A, 0x0B, 0x0C, 0x10, 0x20, 0x2D]

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
STX_ZP, STY_ZP = 0x86, 0x84
LDA_ZP, STA_ZP, LDX_ZP, LDY_ZP, INC_ZP = 0xA5, 0x85, 0xA6, 0xA4, 0xE6
LDA_ABS_X, LDY_ABS_X, STA_ZP_X, LDA_ZP_X = 0xBD, 0xBC, 0x95, 0xB5
BPL, BMI, BVS, BEQ, BNE = 0x10, 0x30, 0x70, 0xF0, 0xD0
JMP_ABS, JSR, RTS, RTI = 0x4C, 0x20, 0x60, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX, DEY = \
    0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA, 0xCA, 0x88
LSR_A, TAX, AND_IMM, SEC, SBC_IMM, BCC = 0x4A, 0xAA, 0x29, 0x38, 0xE9, 0x90


# The outer count of delay_y that puts the IRQ of a 'line' trial on
# scanline target about 160 cycles into the sled. The NMI is at dot 1 of
# scanline 241 and the IRQ near dot 265 of the target, (21 + target)
# scanlines later
def delay_for(target):
    cycles = ((21 + target) * 341 + 264) / 3 - 40 - 160
    return round(cycles / DELAY_LOOP)


def build(v):
    a = Assembler()
    # The group of checks and the index of the check in it
    step = [0]
    detail = [0]
    mapper = v['mapper']
    prg_banks = v['prg_banks']
    chr_banks = v['chr_banks']

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    # Bank register idx, with bits 7-5 of 0x8000 given by ctl
    def bank(idx, value, ctl=0x00):
        write(0x8000, ctl | idx)
        write(0x8001, value)

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
        if v.get('cont'):
            a.emit(NOP, NOP, NOP)
        else:
            a.abs_label(JMP_ABS, 'show')
        detail[0] += 1

    # Fails with the group number unless A is below value
    def check_below(value):
        a.emit(LDX_IMM, step[0])
        a.emit(LDY_IMM, detail[0])
        a.emit(CMP_IMM, value)
        a.emit(BCC, 3)
        if v.get('cont'):
            a.emit(NOP, NOP, NOP)
        else:
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

    # The value of the CHR bank register the board uses at window w (of
    # 0x400 bytes), before the 2KB banks take PPU A10 for bit 0
    def chr_reg(regs, mode, k, w):
        sw = w ^ (4 if mode else 0)
        if sw < 4:
            if k:
                return regs[(0, 8, 1, 9)[sw]]
            return (regs[sw // 2] & 0xFE) | (sw & 1)
        return regs[sw - 2]

    def chr_test(regs, mode, k):
        ctl = (mode << 7) | (0x20 if k else 0x00)
        for i, r in regs.items():
            bank(i, r, ctl)
        for w in range(8):
            ppu_check(0x400 * w, chr_reg(regs, mode, k, w) % chr_banks)

    # Writes each nametable with its own byte; each then reads back the byte
    # of the last nametable written that shares its CIRAM page
    def nt_share(pages, base):
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i + NT_OFFSET, base + i)
        for i in range(4):
            last = max(j for j in range(4) if pages[j] == pages[i])
            ppu_check(0x2000 + 0x400 * i + NT_OFFSET, base + last)

    # Each nametable reads back the mark of its CIRAM page
    def nt_pages(pages):
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i + NT_OFFSET + 1, 0xA0 + pages[i])

    # Sets the CHR banks and checks the CIRAM page of each nametable is
    # bit 7 of its bank
    def nt_158(regs, mode, k):
        ctl = (mode << 7) | (0x20 if k else 0x00)
        for i, r in regs.items():
            bank(i, r, ctl)
        nt_pages([chr_reg(regs, mode, k, w) >> 7 for w in range(4)])

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    write(0x4010, 0x00)
    write(0x4017, 0x40)                         # no frame IRQ
    write(0xE000, 0x00)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, TRIAL)
    a.emit(STA_ZP, NMI_MODE)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    next_group()
    # PRG ROM banks, mode 0
    for b in range(prg_banks):
        bank(6, b)
        bank_check(0x8000, b)
    next_group()
    bank(15, 4)
    for b in (3, prg_banks - 3, prg_banks - 1):
        bank(7, b)
        bank_check(0xA000, b)
    bank_check(0xC000, 4)
    bank(15, prg_banks - 5)
    bank_check(0xC000, prg_banks - 5)
    bank_check(0xE000, prg_banks - 1)
    # Wider than the ROM
    bank(6, 0xFF - 6)
    bank_check(0x8000, 0xFF - 6)
    next_group()
    # Mode 1
    bank(6, 5, 0x40)
    bank(7, 6, 0x40)
    bank(15, 7, 0x40)
    bank_check(0x8000, 7)
    bank_check(0xA000, 6)
    bank_check(0xC000, 5)
    bank_check(0xE000, prg_banks - 1)
    write(0x8000, 0x00)
    bank_check(0x8000, 5)
    bank_check(0xC000, 7)

    regs_2kb = {0: 0x13, 1: 0x26, 2: 0x31, 3: 0x4C, 4: 0x57, 5: 0x6A}
    regs_1kb = {0: 0x15, 8: 0x22, 1: 0x2F, 9: 0x38, 2: 0x41, 3: 0x5E,
                4: 0x63, 5: 0x7D}
    if chr_banks > 128:
        regs_2kb[5] = 0xFA
        regs_1kb[9] = 0xB8
    for regs, mode, k in ((regs_2kb, 0, False), (regs_2kb, 1, False),
                          (regs_1kb, 0, True), (regs_1kb, 1, True)):
        next_group()
        chr_test(regs, mode, k)

    next_group()
    # No registers at 0xA-0xE; R8 and R9 are not R0 and R1
    for idx in range(0xA, 0xF):
        bank(idx, 0x77, 0x20)
    write(0x8000, 0x80 | 0x20)
    for w in range(8):
        ppu_check(0x400 * w, chr_reg(regs_1kb, 1, True, w) % chr_banks)
    bank_check(0x8000, 5)
    bank_check(0xA000, 6)
    bank_check(0xC000, 7)
    write(0x8000, 0x80)
    for w in range(8):
        ppu_check(0x400 * w, chr_reg(regs_1kb, 1, False, w) % chr_banks)

    next_group()
    if mapper == 64:
        write(0xA000, 0x00)
        nt_share([0, 1, 0, 1], 0x40)
        write(0xA000, 0x01)
        nt_share([0, 0, 1, 1], 0x50)
        write(0xA000, 0x00)
        nt_share([0, 1, 0, 1], 0x60)
    else:
        # Mark CIRAM page 0 through $2000 and page 1 through $2800
        bank(0, 0x00)
        bank(1, 0x80)
        ppu_write(0x2000 + NT_OFFSET + 1, 0xA0)
        ppu_write(0x2800 + NT_OFFSET + 1, 0xA1)
        nt_pages([0, 0, 1, 1])
        nt_158({0: 0x81, 1: 0x02}, 0, False)
        write(0xA000, 0x00)
        nt_pages([1, 1, 0, 0])
        write(0xA000, 0x01)
        nt_pages([1, 1, 0, 0])
        nt_158({0: 0x01, 8: 0x83, 1: 0x84, 9: 0x05}, 0, True)
        nt_158({2: 0x86, 3: 0x07, 4: 0x08, 5: 0x89}, 1, False)
        nt_158({2: 0x06, 3: 0x87, 4: 0x88, 5: 0x09}, 1, True)

    next_group()
    # No PRG RAM
    write(0x6000, 0x55)
    cpu_check(0x6000, 0x60)
    cpu_check(0x7FFF, 0x7F)

    # CPU cycle mode with IRQs disabled, then enabled with the counter
    # stopped (scanline mode, rendering off)
    next_group()
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    write(0xE000, 0x00)
    write(0xC000, 0x02)
    write(0xC001, 0x01)
    a.emit(CLI)
    delay(40)
    write(0xC001, 0x00)
    write(0xE001, 0x00)
    delay(40)
    a.emit(SEI)

    # 0xE001 does not acknowledge
    next_group()
    a.emit(LDA_IMM, 0x40)
    a.emit(STA_ZP, MODE)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, DONE)
    write(0xC000, 0x00)
    write(0xC001, 0x01)
    delay(10)
    # Stop the counter
    write(0xC001, 0x00)
    a.emit(LDA_ZP, DONE)
    check(0x00)
    write(0xE001, 0x00)
    a.emit(CLI)
    a.emit(NOP)
    a.emit(SEI)
    a.emit(LDA_ZP, DONE)
    check(0x01)

    # The timing trials. The IRQ handler starts the next one
    next_group()
    trial_step = step[0]
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, MODE)
    a.label('trial')
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, SECOND)
    # IRQs off and the counter stopped (scanline mode, no rendering in
    # vblank or with rendering off) until the trial starts it
    a.abs(STA_ABS, 0xE000)
    a.abs(STA_ABS, 0xC001)
    a.emit(LDX_ZP, TRIAL)
    a.abs_label(LDA_ABS_X, 'kinds')
    a.emit(CMP_IMM, KINDS['line'])
    a.branch(BEQ, 'trial_line')
    a.abs_label(LDA_ABS_X, 'latches')
    a.abs(STA_ABS, 0xC000)
    a.abs(STA_ABS, 0xE001)
    a.emit(LDA_IMM, 0x01)
    a.emit(CLI)
    a.abs(STA_ABS, 0xC001)
    a.abs_label(JMP_ABS, 'sled')
    # Rendering on and NMIs, from the first 'line' trial on
    a.label('trial_line')
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, NMI_MODE)
    wait_vblank('trial_vblank')
    write(0x2001, 0x08)
    write(0x2000, 0x88)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, NMI_MODE)
    a.label('trial_wait')
    a.abs_label(JMP_ABS, 'trial_wait')
    next_group()

    a.label('trials_done')
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    if EXPECTED is not None:
        for t, expect in enumerate(EXPECTED):
            a.emit(LDA_ZP, RESULTS + t)
            if TRIALS[t][0] == 'line':
                a.emit(SEC)
                a.emit(SBC_IMM, (expect - 1) & 0xFF)
                check_below(3)
            else:
                check(expect)
    a.emit(LDX_IMM, PASS_COLOR)
    a.emit(LDY_IMM, 0x00)
    a.abs_label(JMP_ABS, 'show')

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show_color' if v['dump'] else 'show')
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
    a.emit(LDX_ZP, TRIAL)
    a.abs_label(LDA_ABS_X, 'latches')
    a.abs(STA_ABS, 0xC000)
    a.abs(STA_ABS, 0xE001)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0xC001)
    a.abs_label(LDY_ABS_X, 'delays')
    delay_y('trial_delay')
    a.emit(CLI)
    a.abs_label(JMP_ABS, 'sled')

    a.label('irq')
    a.emit(BIT_ZP, MODE)
    a.branch(BMI, 'irq_fail')
    a.branch(BVS, 'irq_count')
    # The first IRQ of a 'period' trial
    a.emit(LDX_ZP, TRIAL)
    a.abs_label(LDA_ABS_X, 'kinds')
    a.emit(CMP_IMM, KINDS['period'])
    a.branch(BNE, 'irq_trial')
    a.emit(LDA_ZP, SECOND)
    a.branch(BNE, 'irq_trial')
    a.emit(INC_ZP, SECOND)
    a.abs(STA_ABS, 0xE000)
    a.abs(STA_ABS, 0xE001)
    a.emit(RTI)
    a.label('irq_fail')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_IMM, 0xFF)
    a.abs_label(JMP_ABS, 'show')
    a.label('irq_count')
    a.abs(STA_ABS, 0xE000)
    a.emit(INC_ZP, DONE)
    a.emit(RTI)
    a.label('irq_trial')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    a.abs(STA_ABS, 0xE000)
    a.emit(LDX_IMM, 0xFF, TXS)
    a.emit(INC_ZP, TRIAL)
    a.emit(LDA_ZP, TRIAL)
    a.emit(CMP_IMM, len(TRIALS))
    a.branch(BEQ, 'irq_done')
    a.abs_label(JMP_ABS, 'trial')
    a.label('irq_done')
    a.abs_label(JMP_ABS, 'trials_done')

    a.label('kinds')
    a.emit(*[KINDS[k] for k, _ in TRIALS])
    a.label('latches')
    a.emit(*[latch for _, latch in TRIALS])
    a.label('delays')
    a.emit(*[delay_for(latch) if k == 'line' else 0 for k, latch in TRIALS])

    # The sled starts a page, so the low byte of the address is enough
    a.emit(*([0xFF] * (-a.here() % 0x100)))
    a.label('sled')
    a.emit(*([NOP] * SLED_NOPS))
    a.emit(LDX_IMM, trial_step)
    a.emit(LDY_ZP, TRIAL)
    a.abs_label(JMP_ABS, 'show')

    if v['dump']:
        build_dump(a, wait_vblank)

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
        chr_rom[0x400 * b] = b

    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((mapper & 0x0F) << 4) | 0x01, mapper & 0xF0])
    header += bytes(8)

    return bytes(header + prg + chr_rom)


# Shows RESULTS in the backdrop, then the pass/fail color in X
def build_dump(a, wait_vblank):
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
    # The high nibble
    a.emit(LDX_ZP, PTR)
    a.emit(LDA_ZP_X, 0x00)
    a.emit(LSR_A, LSR_A, LSR_A, LSR_A)
    a.emit(TAX)
    a.abs_label(LDA_ABS_X, 'dump_colors')
    a.emit(STA_ZP, VAL)
    a.abs_label(JSR, 'dump_color')
    # The low nibble
    a.emit(LDX_ZP, PTR)
    a.emit(LDA_ZP_X, 0x00)
    a.emit(AND_IMM, 0x0F)
    a.emit(TAX)
    a.abs_label(LDA_ABS_X, 'dump_colors')
    a.emit(STA_ZP, VAL)
    a.abs_label(JSR, 'dump_color')
    a.emit(INC_ZP, PTR)
    a.emit(LDA_ZP, PTR)
    a.emit(CMP_IMM, RESULTS + len(TRIALS))
    a.branch(BNE, 'dump_byte')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_ZP, DETAIL)
    a.abs_label(JMP_ABS, 'show_color')

    # A black frame and then color VAL. The vblank wait can miss a frame,
    # so each color can last two, but the black frames still separate them
    a.label('dump_color')
    a.emit(LDA_ZP, VAL)
    a.emit(0x48)                                # PHA
    a.emit(LDA_IMM, 0x0F)
    a.emit(STA_ZP, VAL)
    a.abs_label(JSR, 'dump_show')
    a.emit(0x68)                                # PLA
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
