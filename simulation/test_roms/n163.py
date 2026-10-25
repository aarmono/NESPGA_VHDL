#!/usr/bin/env python3
"""Generate test ROMs for the Namco 163 (mapper 19) and the Namco 175 and 340
(mapper 210).

Usage: n163.py OUT.nes VARIANT

All variants check the PRG ROM banks at 0x8000, 0xA000 and 0xC000 (0xE000,
0xE800, 0xF000) and the last bank fixed at 0xE000 (each 8KB bank holds its
number at SIG_LO and its complement at SIG_HI), and the 1KB CHR ROM banks of
the pattern tables (0x8000-0xBFFF; each bank holds its number at its first
byte, read back through $2006/$2007 with rendering off). Nametables are
checked by writing each of the four with its own byte, so that the bytes
read back show which share CIRAM.

The 163 variants (163_ines, 163_nes2) then check:
  - Nametables (0xC000-0xDFFF): pages 0xE0-0xFF are the pages of CIRAM
    (even A, odd B), other pages are CHR ROM, also at 0x3000
  - CIRAM as CHR RAM in the pattern tables, for pages 0xE0-0xFF unless
    0xE800 bit 6 (0x0000-0x0FFF) or 7 (0x1000-0x1FFF) makes them CHR ROM
  - PRG RAM write protection (0xF800): writes are allowed in the 2KB
    windows whose bit is clear only when the high nibble is 4 (nesdev).
    Mesen only checks bit 6, so it fails check 8 (0xC0)
  - The chip RAM through 0xF800 and 0x4800: all 128 bytes written and read
    back with auto-increment, an address held without it, and the wrap
    from 0x7F to 0x00
  - The IRQ counter (0x5000, 0x5800): read back; it does not count while
    disabled, and does not raise an IRQ when enabled at 0x7FFF, where it
    stays. Then, for each count in TRIALS, the counter is set to 0x7FFF
    minus it, enabled, and a NOP sled is run. The IRQ handler stores the
    low byte of the return address at RESULTS + trial and compares it with
    EXPECTED, which is what Mesen gives
  - The audio: two channels (0x7F bits 6-4 = 1) are run for a while from a
    known phase, one with a phase beyond its waveform, and their phases are
    read back and compared with EXPECTED_PHASES, which is what Mesen gives

The 175 variant checks that pages 0xE0-0xFF are CHR ROM, that the mirroring
is that of the header whatever is written to 0xC800-0xDFFF and 0xE000, and
the PRG RAM enable (0xC000 bit 0): disabled, the PRG RAM is open bus (0x60,
the high byte of the address) and is not written, as nesdev and Nestopia.
Mesen makes it read-only instead, so fails group 4.

The 340 variant checks the mirroring of 0xE000 bits 7-6 (0 one screen A,
1 vertical, 2 one screen B, 3 horizontal, as nesdev and Nestopia; Mesen
swaps 2 and 3, so fails the third nametable test of group 3) and that there
is no PRG RAM.

The detect variants have iNES headers, which do not tell the chips apart, so
the chip is told from the registers written, as in Mesen. They step through
each change of chip and check the chip by its behavior:
  detect_19   mapper 19, which starts as the 163: 0xE000 bit 7 makes it the
              340, a write to 0x6000-0x7FFF makes it neither (no PRG RAM)
              and no longer the 340 by 0xE000, 0xC000 makes it the 175 and
              0xF800 the 163
  detect_210  mapper 210, which starts as neither: 0xE000 bit 6 makes it the
              340, then as above, with 0x4800 making it the 163
The mirroring is kept that of the header across the changes that leave it
alone, since Mesen keeps the last mirroring set rather than going back to
the header's.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed (1 is the
first); the index of the failing check within its group is at zero page
DETAIL. The result is up a few frames after reset, so 250ms of nes_bench is
enough.

The audio variant plays SEGMENTS, each for SEGMENT_FRAMES frames with a
frame of silence before it, and is compared with Mesen's WAV by
n163_audio_compare.py. The backdrop is green while it plays.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    '163_ines': dict(mapper=19, nes2=False, sub=0, chip='163'),
    '163_nes2': dict(mapper=19, nes2=True, sub=3, chip='163'),
    '175': dict(mapper=210, nes2=True, sub=1, chip='175'),
    '340': dict(mapper=210, nes2=True, sub=2, chip='340', horz=True),
    'detect_19': dict(mapper=19, nes2=False, sub=0, chip='detect_19'),
    'detect_210': dict(mapper=210, nes2=False, sub=0, chip='detect_210'),
    'audio': dict(mapper=19, nes2=True, sub=3, chip='audio'),
}

PASS_COLOR = 0x2A

PRG_BANKS = 16
CHR_BANKS = 256

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
DETAIL = 0x03
TEMP = 0x04
FRAMES = 0x05
RESULTS = 0x10
PHASES = 0x20

# The counts before 0x7FFF of the IRQ timing trials
TRIALS = [0x0001, 0x0002, 0x0003, 0x0004, 0x0014, 0x0015, 0x0100]
SLED_NOPS = 160
# The low bytes of the return addresses Mesen gives for TRIALS, or None to
# only record them
EXPECTED = [0x00, 0x00, 0x01, 0x01, 0x09, 0x0A, 0x7F]

# The phases (low, mid, high) of channels 6 and 7 after the audio test, from
# Mesen, or None to only record them
EXPECTED_PHASES = [0xDF, 0xFF, 0x06, 0xE8, 0x6A, 0x02]

# The audio test: channel 7 with a 256 sample waveform and channel 6 with a
# 16 sample one whose phase starts beyond it
AUDIO_FREQS = {7: 0x01234, 6: 0x3FFFF}
AUDIO_LENGTHS = {7: 256, 6: 16}
AUDIO_PHASE_HI = {7: 0x00, 6: 0xF3}
# The loop count of the delay the audio runs for, about 5 CPU cycles each
AUDIO_DELAY = 200

# Leave out the checks that Mesen is known to fail, to compare the rest with
# it: the nametables at 0x3000-0x3EFF, which the chip decodes from PPU A13,
# A11 and A10, and Mesen does not map; 0xF800 values with bit 6 set but a
# high nibble other than 4; and the PRG RAM after the chip is told to be the
# 340 or neither, which Mesen leaves mapped as it was
MESEN = False

# The PRG bank of 0xE000 while the 163 has its audio disabled
SOUND_OFF = 0x40

# Each segment of the audio variant is a list of (address, value) writes and
# plays for SEGMENT_FRAMES frames after a frame of silence
SEGMENT_FRAMES = 20


def ram_writes(addr, values):
    """Writes values to the chip RAM from addr"""
    return [(0xF800, 0x80 | addr)] + [(0x4800, v) for v in values]


def channel_writes(ch, freq, length, offset, volume, channels=0):
    """Sets the registers of channel ch, with its phase 0. channels is one
    less than the number of enabled channels, set with channel 7"""
    regs = [freq & 0xFF, 0, (freq >> 8) & 0xFF, 0,
            ((256 - length) & 0xFC) | (freq >> 16), 0, offset,
            volume | (channels << 4 if ch == 7 else 0)]
    return ram_writes(0x40 + 8 * ch, regs)


# Waveforms, two 4-bit samples per byte, the first in the low nibble
SQUARE_8 = [0x00, 0x00, 0xFF, 0xFF]             # samples 0-7, at 0x00
SAW_16 = [0x10, 0x32, 0x54, 0x76, 0x98, 0xBA, 0xDC, 0xFE]  # 16-31, at 0x08
SQUARE_64 = [0x00] * 16 + [0xFF] * 16           # 32-95, at 0x10
WAVES = ram_writes(0x00, SQUARE_8 + [0x00] * 4 + SAW_16 + SQUARE_64)

# The 8-sample square at the frequency of the APU pulse 1 at period 0x1FF
# (218.5 Hz) for one channel: f = 1789773 * p / (15 * 65536 * l * c)
P_218 = 960

SILENCE = [w for ch in range(8) for w in ram_writes(0x47 + 8 * ch, [0x00])]

SEGMENTS = [
    # One channel, the square at volume 15
    WAVES + channel_writes(7, P_218, 8, 0, 15),
    # The APU pulse 1, volume 15, 50%, at the same frequency, for the level
    [(0x4015, 0x01), (0x4000, 0xBF), (0x4001, 0x08), (0x4002, 0xFF),
     (0x4003, 0x01)],
    # The square at volume 7
    channel_writes(7, P_218, 8, 0, 7),
    # The sawtooth, 16 samples
    channel_writes(7, 2 * P_218, 16, 16, 15),
    # Two channels, the second silent: half the frequency and level
    channel_writes(6, P_218, 8, 0, 0) +
    channel_writes(7, 2 * P_218, 8, 0, 15, channels=1),
    # Four channels, three silent
    channel_writes(7, 4 * P_218, 8, 0, 15, channels=3),
    # Eight channels, seven silent
    channel_writes(7, 8 * P_218, 8, 0, 15, channels=7),
    # The 64-sample square at a frequency with its high bits set: 5593 Hz
    channel_writes(7, 0x30000, 64, 32, 15),
    # Two channels sounding: 218.5 Hz and 327.7 Hz
    channel_writes(6, 3 * P_218, 8, 0, 15) +
    channel_writes(7, 2 * P_218, 8, 0, 15, channels=1),
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
STY_ZP, CMP_ZP, CPX_IMM, EOR_IMM = 0x84, 0xC5, 0xE0, 0x49
LDA_ZP, STA_ZP, LDX_ZP, LDY_ZP, INC_ZP, DEC_ZP = \
    0xA5, 0x85, 0xA6, 0xA4, 0xE6, 0xC6
LDA_ABS_X, STA_ZP_X, CMP_ABS_X = 0xBD, 0x95, 0xDD
BPL, BMI, BEQ, BNE, JMP_ABS, RTI = 0x10, 0x30, 0xF0, 0xD0, 0x4C, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX = 0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA, 0xCA
TXA, TAY, INX = 0x8A, 0xA8, 0xE8


def nt_expect(pages):
    """The nametable whose byte each nametable reads back after each is
    written with its own byte in turn, when nametable i is in CIRAM page
    pages[i]"""
    return [max(j for j in range(4) if pages[j] == pages[i])
            for i in range(4)]


MIRRORS = {'v': [0, 1, 0, 1], 'h': [0, 0, 1, 1], 'a': [0, 0, 0, 0],
           'b': [1, 1, 1, 1]}


def build_checks(a, v):
    chip = v['chip']
    step = [1]
    detail = [0]
    nt_count = [0]
    is_163 = chip in ('163', 'detect_19')
    # The value of 0xE000 bits 7-6 with each PRG bank write
    e000 = SOUND_OFF if is_163 else 0x00

    def next_group():
        step[0] += 1
        detail[0] = 0
        assert step[0] < PASS_COLOR

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

    # Each nametable is written with its own byte, then read back, with
    # nametable i in CIRAM page pages[i]
    def nt_test(pages):
        expect = nt_expect(pages)
        base = 0x10 * (nt_count[0] % 15) + 0x08
        nt_count[0] += 1
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, base + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, base + expect[i])

    def nt_pages(pages):
        for i, p in enumerate(pages):
            write(0xC000 + 0x800 * i, p)

    # Waits about 5 * count CPU cycles
    def delay(count):
        a.emit(LDX_IMM, count)
        a.emit(DEX)
        a.emit(BNE, 0xFD)

    def prg_ram_absent():
        write(0x6000, 0xAA)
        cpu_check(0x6000, 0x60)

    def prg_ram_works(value):
        write(0x6000, value)
        write(0x7FFF, value ^ 0xFF)
        cpu_check(0x6000, value)
        cpu_check(0x7FFF, value ^ 0xFF)

    # PRG ROM banks
    for b in range(PRG_BANKS - 1):
        write(0xE000, e000 | b)
        bank_check(0x8000, b)
    for reg, window, banks in ((0xE800, 0xA000, (3, 12)),
                               (0xF000, 0xC000, (5, 13))):
        for b in banks:
            write(reg, b)
            bank_check(window, b)
    bank_check(0xE000, PRG_BANKS - 1)
    bank_check(0x8000, PRG_BANKS - 2)
    bank_check(0xA000, 12)
    next_group()

    # CHR ROM banks of the pattern tables
    pages = [(w * 29 + 5) % 0xE0 for w in range(8)]
    if not is_163:
        pages[0] = 0xE5
        pages[5] = 0xFE
    for w, p in enumerate(pages):
        write(0x8000 + 0x800 * w, p)
    for w, p in enumerate(pages):
        ppu_check(0x400 * w, p)
    next_group()

    if chip == '163':
        # Nametables in CIRAM
        for nt in ((0xE0, 0xE1, 0xE0, 0xE1), (0xE0, 0xE0, 0xE1, 0xE1),
                   (0xFE, 0xFE, 0xFE, 0xFE), (0xE1, 0xFF, 0xE3, 0xF5)):
            nt_pages(nt)
            nt_test([p & 1 for p in nt])
        # In CHR ROM, also at 0x3000
        nt_pages((0x13, 0x45, 0x80, 0xDF))
        for i, p in enumerate((0x13, 0x45, 0x80, 0xDF)):
            ppu_check(0x2000 + 0x400 * i, p)
            if not MESEN:
                ppu_check(0x3000 + 0x400 * i, p)
        # Both: nametable 0 in CIRAM A, 2 in CIRAM B
        nt_pages((0xE0, 0x45, 0xE1, 0x13))
        ppu_write(0x2000, 0x5C)
        ppu_write(0x2800, 0x6D)
        ppu_check(0x2000, 0x5C)
        ppu_check(0x2400, 0x45)
        ppu_check(0x2800, 0x6D)
        ppu_check(0x2C00, 0x13)
        next_group()

        # CIRAM in the pattern tables: 0x0000 in CIRAM B and 0x1000 in
        # CIRAM A, which are also nametables 1 and 0
        nt_pages((0xE0, 0xE1, 0xE0, 0xE1))
        write(0x8000, 0xE1)
        write(0xA000, 0xE0)
        write(0xE800, 0x00 | 12)
        ppu_write(0x2405, 0x77)
        ppu_check(0x0005, 0x77)
        ppu_write(0x0006, 0x88)
        ppu_check(0x2406, 0x88)
        ppu_write(0x2003, 0x99)
        ppu_check(0x1003, 0x99)
        # 0x0000 in CHR ROM. Mesen applies 0xE800 only when a page is
        # written, so the pages are written again
        def chr_rom_halves(value):
            write(0xE800, value | 12)
            write(0x8000, 0xE1)
            write(0xA000, 0xE0)

        chr_rom_halves(0x40)
        ppu_check(0x0000, 0xE1)
        ppu_check(0x1003, 0x99)
        # 0x1000 in CHR ROM
        chr_rom_halves(0x80)
        ppu_check(0x0005, 0x77)
        ppu_check(0x1000, 0xE0)
        # Both
        chr_rom_halves(0xC0)
        ppu_check(0x0000, 0xE1)
        ppu_check(0x1000, 0xE0)
        bank_check(0xA000, 12)
        next_group()

        # PRG RAM write protection, by 2KB window
        windows = (0x6000, 0x6800, 0x7000, 0x7800)
        write(0xF800, 0x40)
        for i, w in enumerate(windows):
            write(w, 0x11 * (i + 1))
        for i, w in enumerate(windows):
            cpu_check(w, 0x11 * (i + 1))
        held = [0x11, 0x55, 0x33, 0x55]
        write(0xF800, 0x45)
        for w in windows:
            write(w, 0x55)
        for w, value in zip(windows, held):
            cpu_check(w, value)
        for protect in (0x00, 0x4F) if MESEN else (0xC0, 0x00, 0x4F):
            write(0xF800, protect)
            for w in windows:
                write(w, 0x66)
            for w, value in zip(windows, held):
                cpu_check(w, value)
        next_group()

        # The chip RAM: every byte, with auto-increment
        write(0xF800, 0x80)
        a.emit(LDX_IMM, 0x00)
        a.label('ram_fill')
        a.emit(TXA, EOR_IMM, 0xA5)
        a.abs(STA_ABS, 0x4800)
        a.emit(INX, CPX_IMM, 0x80)
        a.branch(BNE, 'ram_fill')
        write(0xF800, 0x80)
        a.emit(LDX_IMM, 0x00)
        a.label('ram_check')
        a.emit(TXA, EOR_IMM, 0xA5, STA_ZP, TEMP)
        a.abs(LDA_ABS, 0x4800)
        a.emit(CMP_ZP, TEMP)
        a.branch(BEQ, 'ram_ok')
        a.emit(TXA, TAY, LDX_IMM, step[0])
        a.abs_label(JMP_ABS, 'show')
        a.label('ram_ok')
        a.emit(INX, CPX_IMM, 0x80)
        a.branch(BNE, 'ram_check')
        next_group()

        # An address held without auto-increment, and the wrap
        write(0xF800, 0x05)
        write(0x4800, 0x11)
        write(0x4800, 0x22)
        cpu_check(0x4800, 0x22)
        cpu_check(0x4800, 0x22)
        write(0xF800, 0x85)
        cpu_check(0x4800, 0x22)
        cpu_check(0x4800, 0x06 ^ 0xA5)
        write(0xF800, 0xFF)
        write(0x4800, 0x5A)
        write(0x4800, 0xC3)
        write(0xF800, 0x00)
        cpu_check(0x4800, 0xC3)
        write(0xF800, 0x7F)
        cpu_check(0x4800, 0x5A)
        next_group()

        # The IRQ counter: read back, stopped while disabled, and no IRQ
        # when enabled at 0x7FFF
        a.emit(LDA_IMM, step[0])
        a.emit(STA_ZP, FAIL_STEP)
        write(0x5000, 0x34)
        write(0x5800, 0x12)
        cpu_check(0x5000, 0x34)
        cpu_check(0x5800, 0x12)
        a.emit(CLI)
        delay(20)
        cpu_check(0x5000, 0x34)
        cpu_check(0x5800, 0x12)
        write(0x5000, 0xFF)
        write(0x5800, 0xFF)
        delay(20)
        a.emit(SEI)
        cpu_check(0x5000, 0xFF)
        cpu_check(0x5800, 0xFF)
        write(0x5800, 0x00)
        next_group()

        # The timing trials. The IRQ handler starts the next one
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, MODE)
        a.label('trial')
        a.emit(LDX_ZP, TRIAL)
        a.abs_label(LDA_ABS_X, 'trials_lo')
        a.abs(STA_ABS, 0x5000)
        a.abs_label(LDA_ABS_X, 'trials_hi')
        a.emit(CLI)
        a.abs(STA_ABS, 0x5800)
        # The sled starts a page, so the low byte of the address is enough
        a.abs_label(JMP_ABS, 'sled')
        a.emit(*([0xFF] * (-a.here() % 0x100)))
        a.label('sled')
        a.emit(*([NOP] * SLED_NOPS))
        # No IRQ
        a.emit(LDX_IMM, step[0])
        a.emit(LDY_ZP, TRIAL)
        a.abs_label(JMP_ABS, 'show')
        next_group()

        a.label('trials_done')
        a.emit(LDA_IMM, 0x80)
        a.emit(STA_ZP, MODE)
        if EXPECTED is not None:
            for t, expect in enumerate(EXPECTED):
                a.emit(LDA_ZP, RESULTS + t)
                check(expect)
        next_group()

        # The audio: channels 7 and 6, then their phases read back. The
        # channel updated next depends on the number of channels at the last
        # update, which can be any at power on since the RAM is undefined
        # then, so the audio first runs with one channel, which leaves
        # channel 7 next
        write(0xF800, 0x7F)
        write(0x4800, 0x00)
        write(0xE000, PRG_BANKS - 2)
        delay(10)
        write(0xE000, SOUND_OFF | (PRG_BANKS - 2))
        for ch in (6, 7):
            regs = [AUDIO_FREQS[ch] & 0xFF, 0x00,
                    (AUDIO_FREQS[ch] >> 8) & 0xFF, 0x00,
                    ((256 - AUDIO_LENGTHS[ch]) & 0xFC) |
                    (AUDIO_FREQS[ch] >> 16),
                    AUDIO_PHASE_HI[ch], 0x00, 0x10 if ch == 7 else 0x00]
            write(0xF800, 0x80 | (0x40 + 8 * ch))
            for r in regs:
                write(0x4800, r)
        write(0xE000, PRG_BANKS - 2)
        delay(AUDIO_DELAY)
        write(0xE000, SOUND_OFF | (PRG_BANKS - 2))
        i = 0
        for ch in (6, 7):
            for r in (1, 3, 5):
                write(0xF800, 0x40 + 8 * ch + r)
                a.abs(LDA_ABS, 0x4800)
                a.emit(STA_ZP, PHASES + i)
                i += 1
        if EXPECTED_PHASES is not None:
            for i, expect in enumerate(EXPECTED_PHASES):
                a.emit(LDA_ZP, PHASES + i)
                check(expect)
        next_group()

    elif chip == '175':
        # The mirroring of the header, which neither the nametable
        # registers of the 163 nor the mirroring of the 340 change
        nt_test(MIRRORS['v'])
        for i in range(1, 4):
            write(0xC000 + 0x800 * i, 0xE0)
        write(0xE000, 0xC0 | (PRG_BANKS - 2))
        nt_test(MIRRORS['v'])
        bank_check(0x8000, PRG_BANKS - 2)
        next_group()

        # The PRG RAM enable
        prg_ram_absent()
        write(0xC000, 0x01)
        prg_ram_works(0xA5)
        write(0xC000, 0x00)
        prg_ram_absent()
        write(0xC000, 0x01)
        cpu_check(0x6000, 0xA5)
        next_group()

    elif chip == '340':
        for mode, mirror in ((0, 'a'), (1, 'v'), (2, 'b'), (3, 'h')):
            write(0xE000, (mode << 6) | (PRG_BANKS - 2))
            nt_test(MIRRORS[mirror])
            bank_check(0x8000, PRG_BANKS - 2)
        next_group()

        prg_ram_absent()
        next_group()

    elif chip == 'detect_19':
        # The 163: the nametable registers
        nt_pages((0xE1, 0xE1, 0xE1, 0xE1))
        nt_test(MIRRORS['b'])
        next_group()

        # 0xE000 bit 7 makes it the 340: then one screen A and vertical.
        # Mesen swaps modes 2 and 3, so only 0 and 1 are checked
        write(0xE000, 0x80 | (PRG_BANKS - 2))
        write(0xE000, 0x00 | (PRG_BANKS - 2))
        nt_test(MIRRORS['a'])
        write(0xE000, 0x40 | (PRG_BANKS - 2))
        nt_test(MIRRORS['v'])
        bank_check(0x8000, PRG_BANKS - 2)
        if not MESEN:
            cpu_check(0x6000, 0x60)
        next_group()

        # A write to 0x6000 makes it neither: the mirroring of the header,
        # which 0xE000 no longer changes, and no PRG RAM
        if MESEN:
            write(0x6000, 0xAA)
        else:
            prg_ram_absent()
        nt_test(MIRRORS['v'])
        write(0xE000, 0x80 | (PRG_BANKS - 2))
        nt_test(MIRRORS['v'])
        next_group()

        # 0xC000 makes it the 175: PRG RAM enabled
        write(0xC000, 0x01)
        prg_ram_works(0x5A)
        nt_test(MIRRORS['v'])
        next_group()

        # 0xF800 makes it the 163
        write(0xF800, 0x40)
        nt_pages((0xE0, 0xE0, 0xE1, 0xE1))
        nt_test(MIRRORS['h'])
        prg_ram_works(0x69)
        next_group()

    elif chip == 'detect_210':
        # Neither: pages 0xE0-0xFF are CHR ROM, the mirroring is that of the
        # header and there is no PRG RAM. A write to 0x6000-0x7FFF would rule
        # out the 340, so it is only read
        nt_test(MIRRORS['v'])
        cpu_check(0x6000, 0x60)
        next_group()

        # 0xE000 bit 6 makes it the 340: vertical, then one screen A
        write(0xE000, 0x40 | (PRG_BANKS - 2))
        nt_test(MIRRORS['v'])
        write(0xE000, 0x00 | (PRG_BANKS - 2))
        nt_test(MIRRORS['a'])
        write(0xE000, 0x40 | (PRG_BANKS - 2))
        next_group()

        # A write to 0x6000 makes it neither, and no longer the 340
        prg_ram_absent()
        write(0xE000, 0x00 | (PRG_BANKS - 2))
        nt_test(MIRRORS['v'])
        next_group()

        # 0xC000 makes it the 175
        write(0xC000, 0x01)
        prg_ram_works(0x5A)
        next_group()

        # 0x4800 makes it the 163: the chip RAM
        write(0x4800, 0x7E)
        write(0xF800, 0x00)
        cpu_check(0x4800, 0x7E)
        nt_pages((0xE0, 0xE0, 0xE1, 0xE1))
        nt_test(MIRRORS['h'])
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
    if chip == '163':
        a.branch(BPL, 'irq_trial')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_IMM, 0x00)
    a.abs_label(JMP_ABS, 'show')
    if chip == '163':
        a.label('irq_trial')
        a.emit(TSX)
        a.abs(LDA_ABS_X, 0x0102)                # return address, low byte
        a.emit(LDX_ZP, TRIAL)
        a.emit(STA_ZP_X, RESULTS)
        write(0x5800, 0x00)                     # acknowledge
        a.emit(LDX_IMM, 0xFF, TXS)
        a.emit(INC_ZP, TRIAL)
        a.emit(LDA_ZP, TRIAL)
        a.emit(CMP_IMM, len(TRIALS))
        a.branch(BEQ, 'irq_done')
        a.abs_label(JMP_ABS, 'trial')
        a.label('irq_done')
        a.abs_label(JMP_ABS, 'trials_done')

        counts = [0x7FFF - t for t in TRIALS]
        a.label('trials_lo')
        a.emit(*[c & 0xFF for c in counts])
        a.label('trials_hi')
        a.emit(*[0x80 | (c >> 8) for c in counts])


def build_audio(a):
    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def write(addr, value):
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
    write(0x2006, 0x3F)
    write(0x2006, 0x00)
    write(0x2007, PASS_COLOR)
    write(0x2006, 0x00)
    write(0x2006, 0x00)

    # The audio enabled, with every channel silent
    for addr, value in SILENCE:
        write(addr, value)
    write(0xE000, 0x00)

    for seg in SEGMENTS:
        for addr, value in SILENCE + [(0x4015, 0x00)]:
            write(addr, value)
        wait_frames(1)
        for addr, value in seg:
            write(addr, value)
        wait_frames(SEGMENT_FRAMES)
    for addr, value in SILENCE + [(0x4015, 0x00)]:
        write(addr, value)

    a.label('done')
    a.abs_label(JMP_ABS, 'done')

    a.label('irq')
    a.emit(RTI)


def build(v):
    a = Assembler()

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    # The audio of the 163 off first, as games do
    if v['chip'] in ('163', 'detect_19', 'audio'):
        a.emit(LDA_IMM, SOUND_OFF)
        a.abs(STA_ABS, 0xE000)
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
    a.emit(LDA_IMM, 0x01)
    a.emit(STA_ZP, FAIL_STEP)
    for name in ('vblank_1', 'vblank_2'):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    if v['chip'] == 'audio':
        build_audio(a)
    else:
        build_checks(a, v)

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
    flags_6 = (mapper & 0x0F) << 4
    if not v.get('horz', False):
        flags_6 |= 0x01
    # Every 163 board with PRG RAM has a battery for it. Mesen maps the
    # 2KB windows of the 163 wrongly over PRG RAM without one
    battery = v['chip'] in ('163', 'detect_19')
    if battery:
        flags_6 |= 0x02
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000, flags_6,
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[8] = v['sub'] << 4
        # 8KB PRG RAM, none for the 340
        if v['chip'] == '340':
            header[10] = 0x00
        elif battery:
            header[10] = 0x70
        else:
            header[10] = 0x07

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
