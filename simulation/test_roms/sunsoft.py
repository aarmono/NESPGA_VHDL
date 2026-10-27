#!/usr/bin/env python3
"""Generate test ROMs for the boards with a 16KB PRG ROM bank and the last
bank fixed: Sunsoft-3 (67), Sunsoft-4 (68) and Konami VRC3 (73).

Usage: sunsoft.py OUT.nes VARIANT

The checks are in groups:
   1  PRG ROM: every 16KB bank at 0x8000 (0xF800, 0xF000 on the Sunsoft-4
      and VRC3) and the last bank fixed at 0xC000. Each 8KB bank holds its
      number at SIG_LO and its complement at SIG_HI. Sunsoft-3: a write with
      A11 clear (0xF000) does not change the bank
   2  CHR: the four 2KB CHR ROM banks (0x8000-0xB000; 0x8800-0xB800 on the
      Sunsoft-3, where writes with A11 clear do nothing to them). Each 1KB
      bank holds its number at its first byte. VRC3: 8KB of CHR RAM, not
      banked
   3  Mirroring: the four modes of 0xE000 (0xE800). VRC3: the header's
   4  Sunsoft-4: the nametables in CHR ROM (0xE000 bit 4), in the 1KB banks
      of 0xC000 and 0xD000 with bit 7 set, following the mirroring; writes
      to them are ignored, and CIRAM is back as it was after
   5  PRG RAM. Sunsoft-4: enabled by bit 4 of 0xF000, open bus otherwise.
      VRC3: always there. Sunsoft-3: none, open bus
   6  Sunsoft Dual Cartridge System: the sub-cartridge ROM (bit 3 of 0xF000
      clear) reads open bus until 0x6000 is written with PRG RAM disabled,
      and again SUNSOFT_4_DCS_TIMEOUT CPU cycles after; the bank bits wrap
      at its size
   7  IRQ: none with the counter stopped, and the acknowledges. Sunsoft-3: a
      write with A11 clear acknowledges, 0xD800 does not. VRC3: 0xC000 and
      0xD000 acknowledge, and 0xD000 copies bit 0 of 0xC000 to the enable
   8  IRQ timing trials: the IRQ handler stores the low byte of the return
      address, which tells which NOP of a sled the IRQ came after, at
      RESULTS + trial. Fails here if a sled runs out. Sunsoft-3: the count
      is written to 0xC800 (high, low), then 0xD800 = 0x10 starts it, and it
      raises the IRQ when it wraps, N + 1 cycles later. VRC3: the reload
      value is written to 0x8000-0xB000, then 0xC000 = 2 (16 bits) or 6
      (8 bits) reloads and starts it, and it raises the IRQ when it wraps
   9  The trial results against EXPECTED. Trials with the same number of
      cycles to the IRQ give the same result

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed; the index of the
failing check in its group is at zero page DETAIL. The result is up a few
frames after reset (the Dual Cartridge System variants wait for the timer,
about 7 frames), so 250ms of nes_bench is enough.

Variants:
  67           iNES 67, 128KB PRG, 128KB CHR
  68           iNES 68, 128KB PRG, 256KB CHR, battery: 8KB of PRG RAM
  68_nes2      NES 2.0 68, 256KB PRG, 256KB CHR, 8KB of PRG RAM
  68_dcs       iNES 68, 128KB + 16KB of sub-cartridge PRG, 128KB CHR
  68_dcs_nes2  NES 2.0 68 submapper 1, as 68_dcs, 8KB of PRG RAM
  73           iNES 73, 128KB PRG, 8KB of CHR RAM, battery

With MESEN set, the checks where Mesen is known to differ are left out:
the Sunsoft-3 acknowledges (Mesen acknowledges at 0xD800, not with A11
clear), Sunsoft-4 PRG banks past 128KB (it takes 3 bits and runs a larger
ROM as the Dual Cartridge System, so 68_nes2 fails there), the Dual
Cartridge System open bus before the timer starts and with a write with PRG
RAM enabled (it restarts the timer on any write), the VRC3 8-bit trials (its 8-bit counter
never raises the IRQ) and the open bus of 0x6000 on the Sunsoft-3 (it gives
every board PRG RAM). The handlers acknowledge both ways. EXPECTED is
Mesen's.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    '67':          dict(board='s3', mapper=67, prg16=8, chr_kb=128),
    '68':          dict(board='s4', mapper=68, prg16=8, chr_kb=256,
                        battery=True),
    '68_nes2':     dict(board='s4', mapper=68, prg16=16, chr_kb=256,
                        nes2=True, prg_ram=0x70, battery=True),
    '68_dcs':      dict(board='dcs', mapper=68, prg16=9, chr_kb=128),
    '68_dcs_nes2': dict(board='dcs', mapper=68, prg16=9, chr_kb=128,
                        nes2=True, submapper=1, prg_ram=0x70,
                        battery=True),
    '73':          dict(board='vrc3', mapper=73, prg16=8, chr_kb=0,
                        battery=True),
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

# The code is in the last 8KB of the fixed bank at 0xC000. Each 8KB bank
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

# The cycles the sub-cartridge ROM can be read after 0x6000 is written
DCS_TIMEOUT = 1024 * 105

# The IRQ timing trials: (kind, value). 's3': the count. 'v16' and 'v8':
# the reload value of the VRC3 with 16 or 8 bits counting
TRIALS = {
    's3': [('s3', 0x0000), ('s3', 0x0001), ('s3', 0x0002), ('s3', 0x0003),
           ('s3', 0x0014), ('s3', 0x0015), ('s3', 0x0100)],
    'vrc3': [('v16', 0xFFFF), ('v16', 0xFFFE), ('v16', 0xFFFD),
             ('v16', 0xFFFC), ('v16', 0xFFEB), ('v16', 0xFFEA),
             ('v16', 0xFF00),
             # The same numbers of cycles with 8 bits; the high byte does
             # not count
             ('v8', 0x12FF), ('v8', 0x00FE), ('v8', 0xABFD), ('v8', 0x5600)],
}
SLED_NOPS = 180
# The low bytes of the return addresses Mesen gives, or None to only record
# them. The 8-bit VRC3 trials are those of the 16-bit ones with the same
# cycles
EXPECTED = {
    's3': [0x00, 0x00, 0x01, 0x01, 0x0A, 0x0A, 0x80],
    'vrc3': [0x00, 0x00, 0x01, 0x01, 0x0A, 0x0A, 0x7F],
}


# The cycles from the start of a trial to its IRQ
def trial_cycles(kind, value):
    if kind == 's3':
        return value + 1
    if kind == 'v16':
        return 0x10000 - value
    return 0x100 - (value & 0xFF)


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
    s3 = board == 's3'
    s4 = board in ('s4', 'dcs')
    dcs = board == 'dcs'
    vrc3 = board == 'vrc3'
    prg_banks = 2 * v['prg16']
    # The 8KB banks of the cartridge ROM; the DCS sub-cartridge ROM follows
    cart_banks = 16 if dcs else prg_banks
    chr_banks = v['chr_kb']
    trials = TRIALS.get(board, [])
    if MESEN:
        trials = [t for t in trials if t[0] != 'v8']
    expected = EXPECTED.get(board)

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

    # Waits about n CPU cycles, within a few
    def delay_cycles(n):
        count = (n - 2) // 1286
        delay_long(count)
        n -= 1286 * count + 1
        count = (n - 2) // 5
        if count > 0:
            delay(count)
            n -= 5 * count + 1
        while n >= 2:
            a.emit(NOP)
            n -= 2

    # Writes each nametable with its own byte; each then reads back the byte
    # of the last nametable written that shares its CIRAM page
    def nt_share(pages, base):
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i + NT_OFFSET, base + i)
        for i in range(4):
            last = max(j for j in range(4) if pages[j] == pages[i])
            ppu_check(0x2000 + 0x400 * i + NT_OFFSET, base + last)

    prg_reg = 0xF800 if s3 else 0xF000
    chr_regs = [0x8800, 0x9800, 0xA800, 0xB800] if s3 else \
        [0x8000, 0x9000, 0xA000, 0xB000]
    mirror_reg = 0xE800 if s3 else 0xE000

    # The value of the PRG bank register for 16KB bank b, with junk in the
    # bits that do not select it (bit 4 enables PRG RAM on the Sunsoft-4)
    def prg_value(b, junk=0x00):
        if dcs:
            return 0x08 | b | (junk & 0xE0)
        if vrc3:
            return b | (junk & 0xF8)
        return b | (junk & 0xE0)

    def ack_s3():
        write(0x8000, 0x00)
        if MESEN:
            write(0xD800, 0x00)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    write(0x4010, 0x00)
    write(0x4017, 0x40)                         # no frame IRQ
    if s3:
        write(0xD800, 0x00)
        ack_s3()
    elif vrc3:
        write(0xC000, 0x00)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, TRIAL)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # PRG ROM banks. The fixed bank is the last of the cartridge
    next_group()
    banks16 = cart_banks // 2
    if MESEN and s4:
        banks16 = min(banks16, 8)
    for b in range(banks16):
        write(prg_reg | (0x0FFF if b & 1 else 0), prg_value(b, 0xF5))
        bank_check(0x8000, 2 * b)
        bank_check(0xA000, 2 * b + 1)
    bank_check(0xC000, cart_banks - 2)
    bank_check(0xE000, cart_banks - 1)
    if s3 and not MESEN:
        # A11 clear: the IRQ acknowledge
        write(0xF000, prg_value(2))
        bank_check(0x8000, 2 * (banks16 - 1))
        write(0xF7FF, prg_value(3))
        bank_check(0x8000, 2 * (banks16 - 1))
    if s4:
        # Every address of the register
        write(0xF5A5, prg_value(1))
        bank_check(0x8000, 2)
        write(0xFFFF, prg_value(0))
        bank_check(0x8000, 0)

    # CHR
    next_group()
    if vrc3:
        # 8KB of RAM, so each 1KB window keeps its own byte
        for w in range(8):
            ppu_write(0x400 * w, 0x30 + w)
        for w in range(8):
            ppu_check(0x400 * w, 0x30 + w)
        write(0x8000, 0x05)
        write(0xF000, prg_value(0))
        ppu_check(0x0000, 0x30)
    else:
        regs = [0x5C, 0x0F, 0x3A, 0x71] if chr_banks <= 128 else \
            [0xA6, 0x5C, 0x7F, 0xC1]
        for r, value in zip(chr_regs, regs):
            write(r, value)
        for w in range(8):
            ppu_check(0x400 * w, (2 * regs[w // 2] + (w & 1)) % chr_banks)
        # Mirrors: the registers ignore A10-A0 (Sunsoft-3: A10-A0 with A11
        # set)
        write(chr_regs[1] | 0x07FF, 0x21)
        ppu_check(0x0800, 0x42)
        ppu_check(0x0C00, 0x43)
        if s3 and not MESEN:
            # A11 clear: the IRQ acknowledge
            write(0x9000, 0x33)
            write(0xA7FF, 0x34)
            ppu_check(0x0800, 0x42)
            ppu_check(0x1000, (2 * regs[2]) % chr_banks)

    # Mirroring
    next_group()
    if vrc3:
        # Horizontal, from the header
        nt_share([0, 0, 1, 1], 0x40)
    else:
        write(mirror_reg, 0x00)
        nt_share([0, 1, 0, 1], 0x40)
        write(mirror_reg, 0x01)
        nt_share([0, 0, 1, 1], 0x50)
        write(mirror_reg, 0x02)
        nt_share([0, 0, 0, 0], 0x60)
        write(mirror_reg | 0x0FF7, 0x03)
        nt_share([1, 1, 1, 1], 0x70)
        # One screen B is the other page: the bytes of mode 1 written to
        # 0x2800 and 0x2C00 (page 1) are there, as screen B left them
        write(mirror_reg, 0x01)
        ppu_check(0x2000 + NT_OFFSET, 0x60 + 3)
        ppu_check(0x2800 + NT_OFFSET, 0x70 + 3)

    # The nametables in CHR ROM
    next_group()
    if s4:
        # CIRAM, with vertical mirroring
        write(0xE000, 0x00)
        for i in range(2):
            ppu_write(0x2000 + 0x400 * i, 0x20 + i)
        # Bit 7 of the banks is ignored and always set
        nt = [0x05 | 0x80, 0x7A | 0x80]
        write(0xC000, 0x05)
        write(0xDFFF, 0x7A)
        for mode, pages in ((0, [0, 1, 0, 1]), (1, [0, 0, 1, 1]),
                            (2, [0, 0, 0, 0]), (3, [1, 1, 1, 1])):
            write(0xE000, 0x10 | mode)
            for i in range(4):
                ppu_check(0x2000 + 0x400 * i, nt[pages[i]] % chr_banks)
        # ROM: writes are ignored
        ppu_write(0x2400, 0x55)
        ppu_check(0x2400, nt[1] % chr_banks)
        # The pattern tables are not affected
        ppu_check(0x0800, 0x42)
        # A bank change shows at once
        write(0xD000, 0x03)
        ppu_check(0x2C00, 0x83 % chr_banks)
        write(0xE000, 0x00)
        ppu_check(0x2000, 0x20)
        ppu_check(0x2400, 0x21)

    # PRG RAM
    next_group()
    if s4:
        write(prg_reg, prg_value(0) | 0x10)
        write(0x6000, 0xA0)
        write(0x7FFF, 0x5F)
        cpu_check(0x6000, 0xA0)
        cpu_check(0x7FFF, 0x5F)
        # Disabled: open bus (the high byte of the address), writes ignored
        write(prg_reg, prg_value(0))
        cpu_check(0x6000, 0x60)
        cpu_check(0x7FFF, 0x7F)
        if not dcs:
            write(0x6000, 0x11)
        write(prg_reg, prg_value(0) | 0x10)
        cpu_check(0x6000, 0xA0)
        cpu_check(0x7FFF, 0x5F)
        write(prg_reg, prg_value(0))
    elif vrc3:
        write(0x6000, 0xA0)
        write(0x7FFF, 0x5F)
        cpu_check(0x6000, 0xA0)
        cpu_check(0x7FFF, 0x5F)
    elif not MESEN:
        cpu_check(0x6000, 0x60)

    # The sub-cartridge ROM of the Dual Cartridge System
    next_group()
    if dcs:
        # Its 16KB bank, past the 8 of the cartridge. Before the timer
        # starts it reads open bus
        write(0xF000, 0x00)
        if not MESEN:
            cpu_check(0x8000 + SIG_LO, 0x80)
            cpu_check(0xA000 + SIG_LO, 0xA0)
        if not MESEN:
            # A write with PRG RAM enabled does not start the timer
            write(0xF000, 0x10)
            write(0x6000, 0x00)
            write(0xF000, 0x00)
            cpu_check(0x8000 + SIG_LO, 0x80)
        write(0x7123, 0x00)
        bank_check(0x8000, 16)
        bank_check(0xA000, 17)
        # Its bank bits wrap at its size
        write(0xF000, 0x05)
        bank_check(0x8000, 16)
        # The cartridge ROM is readable whatever the timer
        write(0xF000, 0x0B)
        bank_check(0x8000, 6)
        write(0xF000, 0x00)
        # Just before and after the timer runs out
        write(0x6000, 0x00)
        delay_cycles(DCS_TIMEOUT - 120)
        bank_check(0x8000, 16)
        write(0x6000, 0x00)
        delay_cycles(DCS_TIMEOUT + 60)
        cpu_check(0x8000 + SIG_LO, 0x80)
        bank_check(0xC000, 14)
        write(0xF000, 0x08)

    # IRQ
    next_group()
    if s3:
        a.emit(LDA_IMM, step[0])
        a.emit(STA_ZP, FAIL_STEP)
        # Stopped: no IRQ
        write(0xD800, 0x00)
        write(0xC800, 0x00)
        write(0xC800, 0x00)
        a.emit(CLI)
        delay(50)
        a.emit(SEI)
        if not MESEN:
            a.emit(LDA_IMM, 0x40)
            a.emit(STA_ZP, MODE)
            # Raised with the CPU's I flag set: 0xD800 does not acknowledge
            # it, a write with A11 clear does, and one with A11 set does not
            for i, (ack, taken) in enumerate(((0xD800, 1), (0x8000, 0),
                                              (0xF7FF, 0), (0xC800, 1),
                                              (0x9234, 0))):
                a.emit(LDA_IMM, 0x00)
                a.emit(STA_ZP, DONE)
                write(0xD800, 0x00)
                write(0xC800, 0x00)
                write(0xC800, 0x00)
                write(0xD800, 0x10)
                delay(4)
                write(ack, 0x00)
                a.emit(CLI)
                a.emit(NOP)
                a.emit(SEI)
                a.emit(LDA_ZP, DONE)
                check(taken)
            # Stopped once it raises the IRQ: it is not raised again
            a.emit(LDA_IMM, 0x00)
            a.emit(STA_ZP, DONE)
            write(0xD800, 0x00)
            write(0xC800, 0x00)
            write(0xC800, 0x01)
            write(0xD800, 0x10)
            delay(4)
            ack_s3()
            a.emit(CLI)
            delay_cycles(0x10000 + 1000)
            a.emit(SEI)
            a.emit(LDA_ZP, DONE)
            check(0)
            a.emit(LDA_IMM, 0x80)
            a.emit(STA_ZP, MODE)
    elif vrc3:
        a.emit(LDA_IMM, step[0])
        a.emit(STA_ZP, FAIL_STEP)
        # A reload value of 0xFF00: the IRQ every 256 cycles while counting
        for i, value in enumerate((0x0, 0x0, 0xF, 0xF)):
            write(0x8000 + 0x1000 * i, value)
        # Stopped: no IRQ. Bit 0 alone does not start it
        write(0xC000, 0x01)
        a.emit(CLI)
        delay(120)
        a.emit(SEI)
        a.emit(LDA_IMM, 0x40)
        a.emit(STA_ZP, MODE)
        # Raised with the CPU's I flag set, then acknowledged by 0xC000 and
        # by 0xD000, which also stops the counter with bit 0 of 0xC000 clear
        for ack in (0xC000, 0xD000, None):
            a.emit(LDA_IMM, 0x00)
            a.emit(STA_ZP, DONE)
            write(0xC000, 0x02)
            delay(60)
            if ack is not None:
                write(ack, 0x00)
                delay(60)
            a.emit(CLI)
            a.emit(NOP)
            a.emit(SEI)
            a.emit(LDA_ZP, DONE)
            check(1 if ack is None else 0)
        # With bit 0 set, 0xD000 leaves the counter counting from the reload
        # value, so it raises the IRQ again
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, DONE)
        write(0xC000, 0x03)
        delay(60)
        write(0xD000, 0x00)
        delay(60)
        a.emit(CLI)
        a.emit(NOP)
        a.emit(SEI)
        write(0xC000, 0x00)
        a.emit(LDA_ZP, DONE)
        check(1)
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
        if s3:
            write(0xD800, 0x00)
            a.abs_label(LDA_ABS_X, 'values_hi')
            a.abs(STA_ABS, 0xC800)
            a.abs_label(LDA_ABS_X, 'values_lo')
            a.abs(STA_ABS, 0xC800)
            a.emit(LDA_IMM, 0x10)
            a.emit(CLI)
            a.abs(STA_ABS, 0xD800)
        else:
            for i in range(4):
                a.abs_label(LDA_ABS_X, 'nibbles_%d' % i)
                a.abs(STA_ABS, 0x8000 + 0x1000 * i)
            a.abs_label(LDA_ABS_X, 'ctrls')
            a.emit(CLI)
            a.abs(STA_ABS, 0xC000)
        a.abs_label(JMP_ABS, 'sled')
    else:
        # Never reached, but the IRQ handler links to it
        a.label('trial')
    next_group()

    a.label('trials_done')
    if expected is not None and trials:
        # Trials with the same cycles to the IRQ give the same result
        by_cycles = {}
        for (kind, value), result in zip(TRIALS[board], expected):
            by_cycles.setdefault(trial_cycles(kind, value), result)
        for t, (kind, value) in enumerate(trials):
            a.emit(LDA_ZP, RESULTS + t)
            check(by_cycles[trial_cycles(kind, value)])
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

    def ack():
        if s3:
            write(0xD800, 0x00)
            ack_s3()
        else:
            write(0xC000, 0x00)

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
    # Counts the IRQ and acknowledges it. The VRC3 is left counting, as
    # 0xC000 would reload it
    a.label('irq_count')
    a.emit(INC_ZP, DONE)
    a.emit(PHA)
    if s3:
        ack_s3()
    else:
        write(0xD000, 0x00)
    a.emit(PLA)
    a.emit(RTI)

    if s3:
        a.label('values_hi')
        a.emit(*[n >> 8 for _, n in trials])
        a.label('values_lo')
        a.emit(*[n & 0xFF for _, n in trials])
    elif trials:
        for i in range(4):
            a.label('nibbles_%d' % i)
            a.emit(*[(n >> (4 * i)) & 0x0F for _, n in trials])
        a.label('ctrls')
        a.emit(*[0x02 if k == 'v16' else 0x06 for k, _ in trials])

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

    last = 0x2000 * (cart_banks - 1)
    prg[last + ORG - 0xE000:last + ORG - 0xE000 + len(code)] = code
    for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'), (0xFFFE, 'irq')):
        prg[last + vec - 0xE000] = a.labels[name] & 0xFF
        prg[last + vec - 0xE000 + 1] = a.labels[name] >> 8

    chr_rom = bytearray(0x400 * chr_banks)
    for b in range(chr_banks):
        chr_rom[0x400 * b] = b & 0xFF

    flags6 = ((mapper & 0x0F) << 4) | (0x02 if v.get('battery') else 0x00)
    flags7 = mapper & 0xF0
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000])
    if v.get('nes2'):
        chr_ram = 0x07 if chr_banks == 0 else 0x00
        header += bytes([flags6, flags7 | 0x08,
                         (v.get('submapper', 0) << 4) | (mapper >> 8), 0,
                         v.get('prg_ram', 0), chr_ram, 0, 0, 0, 0])
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
