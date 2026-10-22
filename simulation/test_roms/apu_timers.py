#!/usr/bin/env python3
"""Generate a test ROM for the periods of the APU pulse and noise timers.

Usage: apu_timers.py OUT.nes

The ROM (NROM) plays SEGMENTS, each for its number of frames with a frame
of silence before it, and apu_timers_measure.py measures the period of
each in the audio.au of nes_bench. The segments are the pulses at a few
periods and the noise in short mode at each of its 16 periods. The
backdrop is green while they play. Frames are counted in the NMI handler,
so each segment starts a whole number of frames after the first.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

PASS_COLOR = 0x2A

# NROM-128: the 16KB of PRG ROM is at 0x8000 and 0xC000
ORG = 0xC000
PRG_SIZE = 0x4000
CHR_SIZE = 0x2000

# Zero page
FRAMES = 0x00

# A CPU cycle in nes_bench, in ns: 6 periods of its 50MHz * 6 / 28 clock,
# which is 93333336 fs after the integer divisions of time in nes_bench
CPU_NS = 6 * 93.333336
# A frame with rendering off, which has no short frames: 89342 PPU cycles
FRAME_CYCLES = 89342 / 3

# The noise periods, in CPU cycles, from nesdev
NOISE_PERIODS = [4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762,
                 1016, 2034, 4068]
# Each segment plays at least this many frames, and long enough for this
# many periods of its waveform
MIN_FRAMES = 15
MIN_REPEATS = 6

PULSE_REGS = {1: 0x4000, 2: 0x4004}


class Segment:
    """name, register writes, and the length of a step of the waveform in
    CPU cycles on hardware (the period of the timer) and the number of steps
    in a period of the waveform"""

    def __init__(self, name, writes, step, steps):
        self.name = name
        self.writes = writes
        self.step = step
        self.steps = steps
        cycles = MIN_REPEATS * step * steps
        self.frames = max(MIN_FRAMES, -(-int(cycles) // int(FRAME_CYCLES)))


def pulse(channel, period):
    base = PULSE_REGS[channel]
    # Duty 50%, length counter halted, constant volume 15. The sweep is
    # disabled, with negate set so that it never mutes
    writes = [(0x4015, channel), (base, 0xBF), (base + 1, 0x08),
              (base + 2, period & 0xFF), (base + 3, period >> 8)]
    return Segment('pulse %d P=0x%03X' % (channel, period), writes,
                   2 * (period + 1), 8)


def noise(index):
    # Length counter halted, constant volume 15, short mode. The LFSR then
    # repeats every 93 clocks (or 31, which also repeats every 93)
    writes = [(0x4015, 0x08), (0x400C, 0x3F), (0x400E, 0x80 | index),
              (0x400F, 0x08)]
    return Segment('noise %2d' % index, writes, NOISE_PERIODS[index], 93)


SEGMENTS = ([pulse(1, p) for p in (0x008, 0x040, 0x0FD, 0x1FF)] +
            [pulse(2, 0x0FD)] +
            [noise(i) for i in range(16)])


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


LDA_IMM, LDX_IMM, STA_ABS, STA_ZP, LDA_ZP, BIT_ABS = \
    0xA9, 0xA2, 0x8D, 0x85, 0xA5, 0x2C
BPL, BEQ, BNE, JMP_ABS, JSR, RTS, RTI = \
    0x10, 0xF0, 0xD0, 0x4C, 0x20, 0x60, 0x40
SEI, CLD, TXS, PHA, PLA, DEC_ZP = 0x78, 0xD8, 0x9A, 0x48, 0x68, 0xC6


def build():
    a = Assembler()

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    def wait_frames(n):
        assert 0 < n < 256
        a.emit(LDA_IMM, n)
        a.abs_label(JSR, 'wait_frames')

    # Waits for FRAMES NMIs
    a.label('wait_frames')
    a.emit(STA_ZP, FRAMES)
    a.label('wait_loop')
    a.emit(LDA_ZP, FRAMES)
    a.branch(BNE, 'wait_loop')
    a.emit(RTS)

    a.label('nmi')
    a.emit(PHA)
    a.emit(LDA_ZP, FRAMES)
    a.branch(BEQ, 'nmi_done')
    a.emit(DEC_ZP, FRAMES)
    a.label('nmi_done')
    a.emit(PLA)
    a.label('irq')
    a.emit(RTI)

    a.label('reset')
    a.emit(SEI, CLD)
    a.emit(LDX_IMM, 0xFF, TXS)
    # No frame IRQ
    write(0x4017, 0x40)
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    for k in range(2):
        a.label('vblank%d' % k)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, 'vblank%d' % k)

    write(0x2006, 0x3F)
    write(0x2006, 0x00)
    write(0x2007, PASS_COLOR)
    write(0x2006, 0x00)
    write(0x2006, 0x00)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, FRAMES)
    write(0x2000, 0x80)

    for seg in SEGMENTS:
        write(0x4015, 0x00)
        wait_frames(1)
        for addr, value in seg.writes:
            write(addr, value)
        wait_frames(seg.frames)
    write(0x4015, 0x00)
    a.label('done')
    a.abs_label(JMP_ABS, 'done')

    code = a.link()
    prg = bytearray(PRG_SIZE)
    prg[:len(code)] = code
    for off, name in ((0x3FFA, 'nmi'), (0x3FFC, 'reset'), (0x3FFE, 'irq')):
        prg[off] = a.labels[name] & 0xFF
        prg[off + 1] = a.labels[name] >> 8
    return prg


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    header = b'NES\x1a' + bytes([PRG_SIZE // 0x4000, CHR_SIZE // 0x2000]) + \
        bytes(10)
    with open(sys.argv[1], 'wb') as f:
        f.write(header + build() + bytes(CHR_SIZE))
    frames = 2 + sum(seg.frames + 1 for seg in SEGMENTS)
    print('%d frames, %.0f ms of nes_bench' %
          (frames, frames * FRAME_CYCLES * CPU_NS / 1e6 + 50))


if __name__ == '__main__':
    main()
