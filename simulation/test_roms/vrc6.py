#!/usr/bin/env python3
"""Generate test ROMs for the Konami VRC6 (mappers 24 and 26).

Usage: vrc6.py OUT.nes VARIANT

The bank ROMs (VARIANTs 24, 26 and 24_nes2) check, in order:
  - PRG ROM banks: the 16KB bank at 0x8000 (all 16, with bits 7-4 of the
    value set), the 8KB bank at 0xC000 (all 32, with bits 7-5 set) and the
    last bank fixed at 0xE000. Each 8KB bank holds its number at SIG_LO and
    its complement at SIG_HI
  - Pattern tables: for each of the PPU banking modes 0-3 of 0xB003 bits
    1-0, with bit 5 clear and set, the bank in each 1KB window. Each 1KB
    CHR ROM bank holds its number at its first byte, read back through
    $2006/$2007 with rendering off
  - Nametables in CIRAM: for each of the 32 values of 0xB003 bits 5 and
    3-0, each of the four nametables is written with its own byte, so the
    bytes read back show which share CIRAM
  - Nametables in CHR ROM (0xB003 bit 4): for the same 32 values, the bank
    of each nametable
  - PRG RAM at 0x6000-0x7FFF, enabled by 0xB003 bit 7: a write with it
    disabled is not stored and a read is open bus (0x60, the high byte of
    the address)
  - The IRQ counter: no IRQ with the IRQ disabled; the counter stopped by a
    control write without E, then started again by an acknowledge with A
    set; then, for each (latch, control) in TRIALS, the latch is set, the
    control written and a NOP sled is run. The IRQ handler stores the low
    byte of the return address, which tells which NOP the IRQ came after,
    at RESULTS + trial and compares it with EXPECTED, which is what Mesen
    gives

The expected banks of the nametables are the tables on nesdev, written out
in NT_TABLE and NT_TABLE_P, rather than derived from a model of the chip.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed (1 is the
first); the index of the failing check within its group is at zero page
DETAIL. The result is up a few frames after reset, so 250ms of nes_bench is
enough.

The audio ROMs (VARIANTs audio_24 and audio_26) play SEGMENTS, each for
SEGMENT_FRAMES frames with a frame of silence before it, and are compared
with Mesen's WAV by vrc6_audio_compare.py. The backdrop is green while they
play.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

# mapper, NES 2.0 header, audio ROM
VARIANTS = {
    '24': dict(mapper=24, nes2=False, audio=False),
    '26': dict(mapper=26, nes2=False, audio=False),
    '24_nes2': dict(mapper=24, nes2=True, audio=False),
    'audio_24': dict(mapper=24, nes2=False, audio=True),
    'audio_26': dict(mapper=26, nes2=False, audio=True),
}

PASS_COLOR = 0x2A

PRG_BANKS = 32
CHR_BANKS = 256

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
INDEX = 0x05
FRAMES = 0x06
RESULTS = 0x10

# R0-R7. Bit 0 differs between the registers of each pair so that the
# nametables show which register and which low bit they get
CHR_REGS = [0x10, 0x23, 0x34, 0x47, 0x58, 0x6B, 0x7C, 0x8F]

# (latch, control) of the timing trials: cycle mode (control 6) and
# scanline mode (control 2)
TRIALS = [(0xFF, 0x06), (0xFE, 0x06), (0xF0, 0x06), (0x90, 0x06),
          (0xFF, 0x02), (0xFE, 0x02), (0xFD, 0x02), (0xFC, 0x02)]
SLED_NOPS = 240
# The low bytes of the return addresses Mesen gives for TRIALS, or None to
# only record them
EXPECTED = [0x00, 0x00, 0x07, 0x37, 0x38, 0x71, 0xAA, 0xE3]

# The nametables of 0xB003 bits 3-0 with bit 5 clear, from nesdev: the
# register of each nametable, whose low bit is CIRAM A10
NT_TABLE = [
    [6, 6, 7, 7], [4, 5, 6, 7], [6, 7, 6, 7], [6, 7, 6, 7],
    [6, 7, 6, 7], [4, 5, 6, 7], [6, 6, 7, 7], [6, 6, 7, 7],
    [6, 6, 7, 7], [4, 5, 6, 7], [6, 7, 6, 7], [6, 7, 6, 7],
    [6, 7, 6, 7], [4, 5, 6, 7], [6, 6, 7, 7], [6, 6, 7, 7],
]

# With bit 5 set, modes 0 and 3 replace the low bit of the register: the
# register and the low bit of each nametable
NT_TABLE_P = {
    0x0: [(6, 0), (6, 1), (7, 0), (7, 1)],
    0x4: [(6, 0), (7, 0), (6, 1), (7, 1)],
    0x8: [(6, 0), (6, 0), (7, 0), (7, 0)],
    0xC: [(6, 1), (7, 1), (6, 1), (7, 1)],
    0x3: [(6, 0), (7, 0), (6, 1), (7, 1)],
    0x7: [(6, 0), (6, 1), (7, 0), (7, 1)],
    0xB: [(6, 1), (7, 1), (6, 1), (7, 1)],
    0xF: [(6, 0), (6, 0), (7, 0), (7, 0)],
}

# The registers of the eight pattern table windows for 0xB003 bits 1-0,
# and whether the window is half of a 2KB bank
CHR_TABLE = [
    [(0, False), (1, False), (2, False), (3, False),
     (4, False), (5, False), (6, False), (7, False)],
    [(0, True), (0, True), (1, True), (1, True),
     (2, True), (2, True), (3, True), (3, True)],
    [(0, False), (1, False), (2, False), (3, False),
     (4, True), (4, True), (5, True), (5, True)],
]
CHR_TABLE.append(CHR_TABLE[2])

# The audio segments: register writes (address for mapper 24, value). Each
# plays for SEGMENT_FRAMES frames after a frame of silence
SEGMENT_FRAMES = 20
SILENCE = [(0x9002, 0x00), (0xA002, 0x00), (0xB002, 0x00), (0x9003, 0x00),
           (0x4015, 0x00)]
SEGMENTS = [
    # Pulse 1, volume 15, 50%, period 0x1FF: 218.5 Hz
    [(0x9000, 0x7F), (0x9001, 0xFF), (0x9002, 0x81)],
    # The APU pulse 1, volume 15, 50%, at the same frequency, for the level
    [(0x4015, 0x01), (0x4000, 0xBF), (0x4001, 0x08), (0x4002, 0xFF),
     (0x4003, 0x01)],
    # Pulse 1, volume 9, 1/16, period 0x0FF
    [(0x9000, 0x09), (0x9001, 0xFF), (0x9002, 0x80)],
    # Pulse 1, volume 9, 4/16
    [(0x9000, 0x39), (0x9001, 0xFF), (0x9002, 0x80)],
    # Pulse 1, ignoring the duty: a constant level
    [(0x9000, 0x8C), (0x9001, 0xFF), (0x9002, 0x80)],
    # Pulse 2, volume 15, 50%, period 0x17F
    [(0xA000, 0x7F), (0xA001, 0x7F), (0xA002, 0x81)],
    # Pulse 2, volume 6, 6/16, period 0x0C0
    [(0xA000, 0x56), (0xA001, 0xC0), (0xA002, 0x80)],
    # Saw, rate 42, period 0x0FF: 499.4 Hz
    [(0xB000, 0x2A), (0xB001, 0xFF), (0xB002, 0x80)],
    # Saw, rate 20, period 0x1FF
    [(0xB000, 0x14), (0xB001, 0xFF), (0xB002, 0x81)],
    # Saw, rate 63: the accumulator wraps
    [(0xB000, 0x3F), (0xB001, 0xFF), (0xB002, 0x80)],
    # All three at full volume
    [(0x9000, 0x7F), (0x9001, 0x00), (0x9002, 0x82),
     (0xA000, 0x7F), (0xA001, 0x00), (0xA002, 0x83),
     (0xB000, 0x2A), (0xB001, 0x00), (0xB002, 0x82)],
    # The periods shifted right by 4 (period 0xFFF: 436.9 Hz)
    [(0x9003, 0x02), (0x9000, 0x7F), (0x9001, 0xFF), (0x9002, 0x8F)],
    # By 8, which overrides 4 (6.99 kHz)
    [(0x9003, 0x06), (0x9000, 0x7F), (0x9001, 0xFF), (0x9002, 0x8F)],
    # Halted at the first step: the pulse holds its level
    [(0x9000, 0x7A), (0x9001, 0xFF), (0x9002, 0x81), (0x9003, 0x01)],
    # The VRC6 pulse 1 and the APU pulse 1 together
    [(0x9000, 0x7F), (0x9001, 0xFF), (0x9002, 0x81),
     (0x4015, 0x01), (0x4000, 0xBF), (0x4001, 0x08), (0x4002, 0xFF),
     (0x4003, 0x01)],
]


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
LDA_ZP, STA_ZP, LDX_ZP, LDY_ZP, STY_ZP, INC_ZP, DEC_ZP = \
    0xA5, 0x85, 0xA6, 0xA4, 0x84, 0xE6, 0xC6
LDA_ABS_X, STA_ZP_X, CMP_ABS_Y = 0xBD, 0x95, 0xD9
BPL, BMI, BEQ, BNE, BVC, JMP_ABS, RTI = 0x10, 0x30, 0xF0, 0xD0, 0x50, 0x4C, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX = 0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA, 0xCA
PHA, PLA, INY, TAY, ASL_A, LSR_A = 0x48, 0x68, 0xC8, 0xA8, 0x0A, 0x4A


def chr_bank_of(b003, window):
    reg, half = CHR_TABLE[b003 & 3][window]
    bank = CHR_REGS[reg]
    if half and b003 & 0x20:
        bank = (bank & 0xFE) | (window & 1)
    return bank


def nt_bank_of(b003, nt):
    if b003 & 0x20 and (b003 & 0x0F) in NT_TABLE_P:
        reg, lsb = NT_TABLE_P[b003 & 0x0F][nt]
        return (CHR_REGS[reg] & 0xFE) | lsb
    return CHR_REGS[NT_TABLE[b003 & 0x0F][nt]]


def build_banks(v, a, reg_addr, vrc):
    step = [1]
    detail = [0]

    def next_group():
        step[0] += 1
        detail[0] = 0
        assert step[0] < PASS_COLOR

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

    # For each row, writes the 0xB003 value of the row, runs pre and checks
    # the first byte read at each of addrs against the expected bytes of the
    # row. DETAIL is the index of the row that fails
    def table_test(name, rows, addrs, pre=None):
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, INDEX)
        a.label(name)
        a.emit(LDX_ZP, INDEX)
        a.abs_label(LDA_ABS_X, name + '_b003')
        a.abs(STA_ABS, reg_addr(0xB000, 3))
        if pre is not None:
            pre()
        a.emit(LDA_ZP, INDEX)
        for _ in range((len(addrs) - 1).bit_length()):
            a.emit(ASL_A)
        a.emit(TAY)
        for addr in addrs:
            ppu_addr(addr)
            a.abs(LDA_ABS, 0x2007)              # the read buffer
            a.abs(LDA_ABS, 0x2007)
            a.abs_label(CMP_ABS_Y, name + '_expect')
            a.emit(BEQ, 3)
            a.abs_label(JMP_ABS, name + '_fail')
            a.emit(INY)
        a.emit(INC_ZP, INDEX)
        a.emit(LDA_ZP, INDEX)
        a.emit(CMP_IMM, len(rows))
        a.branch(BEQ, name + '_done')
        a.abs_label(JMP_ABS, name)
        a.label(name + '_fail')
        a.emit(LDX_IMM, step[0])
        a.emit(LDY_ZP, INDEX)
        a.abs_label(JMP_ABS, 'show')
        a.label(name + '_done')
        tables.append((name, rows))
        next_group()

    tables = []

    # PRG ROM banks
    for b in range(PRG_BANKS // 2):
        vrc(0x8000, 0, 0xF0 | b)
        bank_check(0x8000, 2 * b)
        bank_check(0xA000, 2 * b + 1)
    next_group()
    for b in range(PRG_BANKS):
        vrc(0xC000, 0, 0xE0 | b)
        bank_check(0xC000, b)
    next_group()
    vrc(0x8000, 3, 6)
    vrc(0xC000, 2, 21)
    bank_check(0x8000, 12)
    bank_check(0xA000, 13)
    bank_check(0xC000, 21)
    bank_check(0xE000, PRG_BANKS - 1)
    next_group()

    # The registers. R0-R3 at 0xD000-0xD003 and R4-R7 at 0xE000-0xE003
    for r, value in enumerate(CHR_REGS):
        vrc(0xD000 + 0x1000 * (r // 4), r % 4, value)

    # Pattern tables
    rows = [m | p for p in (0x00, 0x20) for m in range(4)]
    table_test('chr', [(b, [chr_bank_of(b, w) for w in range(8)])
                       for b in rows],
               [0x400 * w for w in range(8)])

    # Nametables in CIRAM
    def nt_write():
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0xC0 + i)

    def ciram_bytes(b003):
        a10 = [nt_bank_of(b003, i) & 1 for i in range(4)]
        # The last nametable written to each half of CIRAM
        last = {a10[i]: 0xC0 + i for i in range(4)}
        return [last[a10[i]] for i in range(4)]

    rows = [p | m for p in (0x00, 0x20) for m in range(16)]
    table_test('ciram', [(b, ciram_bytes(b)) for b in rows],
               [0x2000 + 0x400 * i for i in range(4)], nt_write)

    # Nametables in CHR ROM, read also through the mirror at 0x3000
    table_test('ntchr', [(b | 0x10, [nt_bank_of(b, i) for i in range(4)] * 2)
                         for b in rows],
               [0x2000 + 0x400 * i for i in range(4)] +
               [0x3000 + 0x400 * i for i in range(4)])

    # PRG RAM, enabled by 0xB003 bit 7
    vrc(0xB000, 3, 0xA0)
    a.emit(LDA_IMM, 0xA5)
    a.abs(STA_ABS, 0x6000)
    a.emit(LDA_IMM, 0x5A)
    a.abs(STA_ABS, 0x7FFF)
    cpu_check(0x6000, 0xA5)
    cpu_check(0x7FFF, 0x5A)
    vrc(0xB000, 3, 0x20)
    a.emit(LDA_IMM, 0x11)
    a.abs(STA_ABS, 0x6000)
    cpu_check(0x6000, 0x60)                     # open bus
    vrc(0xB000, 3, 0xA0)
    cpu_check(0x6000, 0xA5)
    next_group()

    # No IRQ while it is disabled
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    vrc(0xF000, 0, 0xFF)
    vrc(0xF000, 1, 0x04)
    a.emit(CLI)
    delay(100)
    a.emit(SEI)
    next_group()

    # Started with 256 cycles to go, stopped by a control write without
    # E, then started again by an acknowledge with A set
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    vrc(0xF000, 0, 0x00)
    vrc(0xF000, 1, 0x06)
    vrc(0xF000, 1, 0x05)
    a.emit(CLI)
    delay(100)
    a.emit(SEI)
    next_group()
    a.emit(LDA_IMM, 0x40)
    a.emit(STA_ZP, MODE)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, GOT_IRQ)
    vrc(0xF000, 2, 0x00)
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
    a.abs_label(LDA_ABS_X, 'trials_control')
    a.emit(CLI)
    a.abs(STA_ABS, reg_addr(0xF000, 1))
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
    a.emit(LDY_IMM, 0x00)
    a.abs_label(JMP_ABS, 'show')

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
    vrc(0xF000, 1, 0x00)                        # acknowledge and stop
    a.emit(PLA)
    a.emit(RTI)
    a.label('irq_trial')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    vrc(0xF000, 1, 0x00)                        # acknowledge and stop
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

    for name, rows in tables:
        a.label(name + '_b003')
        a.emit(*[b for b, _ in rows])
        a.label(name + '_expect')
        width = 1 << (len(rows[0][1]) - 1).bit_length()
        for _, expect in rows:
            a.emit(*(expect + [0] * (width - len(expect))))


def build_audio(v, a, reg_addr, vrc, wait_vblank):
    def write(addr, value):
        if addr >= 0x8000:
            vrc(addr & 0xF000, addr & 3, value)
        else:
            a.emit(LDA_IMM, value)
            a.abs(STA_ABS, addr)

    def wait_frames(n):
        a.emit(LDA_IMM, n)
        a.emit(STA_ZP, FRAMES)
        name = 'frames_%d' % len(a.code)
        a.label(name)
        wait_vblank(name + '_vbl')
        a.emit(DEC_ZP, FRAMES)
        a.branch(BNE, name)

    # The backdrop green while the segments play
    a.emit(LDA_IMM, 0x3F)
    a.abs(STA_ABS, 0x2006)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2006)
    a.emit(LDA_IMM, PASS_COLOR)
    a.abs(STA_ABS, 0x2007)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2006)
    a.abs(STA_ABS, 0x2006)

    for seg in SEGMENTS:
        for addr, value in SILENCE:
            write(addr, value)
        wait_frames(1)
        for addr, value in seg:
            write(addr, value)
        wait_frames(SEGMENT_FRAMES)
    for addr, value in SILENCE:
        write(addr, value)

    a.label('done')
    a.abs_label(JMP_ABS, 'done')

    a.label('irq')
    a.emit(RTI)


def build(v):
    a = Assembler()
    lines = (1, 0) if v['mapper'] == 26 else (0, 1)

    def reg_addr(base, r):
        return base | ((r & 1) << lines[0]) | ((r >> 1) << lines[1])

    def vrc(base, r, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, reg_addr(base, r))

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    a.abs(STA_ABS, 0x4010)
    a.abs(STA_ABS, 0x4015)
    a.emit(STA_ZP, TRIAL)
    a.emit(LDA_IMM, 0x40)                       # no frame IRQ
    a.abs(STA_ABS, 0x4017)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    vrc(0x9000, 3, 0x00)                        # as the games do
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    if v['audio']:
        build_audio(v, a, reg_addr, vrc, wait_vblank)
    else:
        build_banks(v, a, reg_addr, vrc)

        # Backdrop color X, then the VRAM address off the palette so that
        # the backdrop is what rendering off shows
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

    mapper = v['mapper']
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     (mapper & 0x0F) << 4,
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[10] = 0x07                       # 8KB PRG RAM

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
