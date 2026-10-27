#!/usr/bin/env python3
"""Generate an audio test ROM for the Konami VRC7 (mapper 85).

Usage: vrc7_audio.py OUT.nes [WRITES.txt]

The ROM plays SEGMENTS, each a list of writes to the audio registers
followed by a wait to the end of the segment. The code runs straight through
with interrupts off and nothing else on the bus, so the CPU cycle of every
write is known. With WRITES.txt, those are written to it as "CYCLE PORT DATA"
lines (port 0 is 0x9010, 1 is 0x9030, data in hex), the cycle counted from
the write of 0x00 to 0xE000 that takes the audio out of reset, for comparing
the output with a model of the chip. A first segment resets the LFOs through
the test register, so that the vibrato is the same as after a reset.

The segments cover the 15 built-in instruments, the custom instrument
(waveforms, feedback, key scaling, envelope rates), the six channels at
once, the sustain bit, key off, the octave and volume ranges, vibrato and
tremolo, writes too close together to be taken, and the reset of 0xE000
bit 6 in the middle of a note, after which the channel stays silent until
its registers are written again.

The screen stays black. There is no assembler on the build machine, so the
6502 code is assembled here from opcodes, along with its cycle counts.
"""

import sys

PRG_BANKS = 16
ORG = 0xE000

CPU_HZ = 1789773
SEGMENT_CYCLES = CPU_HZ // 12

# Address and data writes are spaced as the chip needs: 6 CPU cycles after
# an address and 42 after data, with a margin
ADDR_GAP = 12
DATA_GAP = 48


def note(ch, fnum, octave, inst, vol, key=True, sus=False):
    """The writes that set channel ch and key it on (or off)."""
    return [(0x10 + ch, fnum & 0xFF),
            (0x30 + ch, (inst << 4) | vol),
            (0x20 + ch, (0x20 if sus else 0) | (0x10 if key else 0) |
             (octave << 1) | (fnum >> 8))]


def key_off(ch, fnum, octave, sus=False):
    return [(0x20 + ch, (0x20 if sus else 0) | (octave << 1) | (fnum >> 8))]


def custom(patch):
    return [(i, v) for i, v in enumerate(patch)]


# A4 is 440Hz: fnum = 440 * 2**(19 - octave) / 49716, octave 4: 290
A4 = 290
C4 = 172
E4 = 217
G4 = 258

# The LFOs reset by the test register, then a note of each built-in
# instrument, on channels 0 and 1 in turn
SEGMENTS = [[(0x0F, 0x02), (0x0F, 0x00)] + note(0, C4, 4, 1, 0)] + [
    key_off((inst - 2) % 2, C4 + 13 * (inst - 1), 4) +
    note((inst - 1) % 2, C4 + 13 * inst, 4, inst, inst % 3)
    for inst in range(2, 16)
] + [
    # Custom: sine carrier and modulator, no feedback, then feedback 7,
    # then half sines
    key_off(0, C4 + 13 * 15, 4) +
    custom([0x21, 0x21, 0x10, 0x00, 0xF0, 0xF0, 0x0F, 0x0F]) +
    note(2, A4, 4, 0, 0),
    custom([0x21, 0x21, 0x10, 0x07, 0xF0, 0xF0, 0x0F, 0x0F]),
    custom([0x21, 0x21, 0x10, 0x1F, 0xF0, 0xF0, 0x0F, 0x0F]),
    # Key scaling of level and rate, slow attack and decay
    custom([0x31, 0x31, 0x80, 0xC5, 0x52, 0x63, 0x44, 0x35]) +
    note(2, A4, 6, 0, 1),
    # Vibrato and tremolo
    custom([0xC1, 0xC1, 0x18, 0x03, 0xF2, 0xF2, 0x24, 0x24]) +
    note(2, A4, 3, 0, 0),
    # The six channels at once, a chord over the octaves
    key_off(2, A4, 3) +
    note(0, C4, 3, 3, 0) + note(1, E4, 3, 4, 0) + note(2, G4, 3, 5, 0) +
    note(3, C4, 4, 6, 0) + note(4, E4, 4, 7, 0) + note(5, G4, 4, 8, 0),
    # Key off of half of them, with and without sustain
    key_off(0, C4, 3) + key_off(1, E4, 3, sus=True) +
    key_off(2, G4, 3, sus=True),
    # Volume steps and the octave range
    key_off(3, C4, 4) + key_off(4, E4, 4) + key_off(5, G4, 4) +
    note(0, 0x1FF, 0, 9, 0) + note(1, 0x080, 7, 9, 15),
    [(0x30, 0x94), (0x31, 0x98)],
    [(0x30, 0x9C), (0x31, 0x90)],
    # Writes too close together: each 6 cycles after the last, so the
    # address writes come before the chip has taken the data
    key_off(0, 0x1FF, 0) + key_off(1, 0x080, 7) + ['fast'] +
    note(3, A4, 4, 2, 0) + ['slow'],
    # Instrument changes during a note
    [(0x33, 0x50)],
    [(0x33, 0xD0)],
    # The reset in the middle of a note, then the note again: silent until
    # its registers are written
    ['reset'],
    note(3, A4, 4, 2, 0),
]


class Assembler:
    def __init__(self):
        self.code = bytearray()
        self.cycles = 0

    def here(self):
        return ORG + len(self.code)

    def emit(self, cycles, *b):
        self.code.extend(b)
        self.cycles += cycles


LDA_IMM, STA_ABS, LDX_IMM, LDY_IMM = 0xA9, 0x8D, 0xA2, 0xA0
BIT_ABS, BIT_ZP, BPL, BNE, DEX, DEY, NOP = 0x2C, 0x24, 0x10, 0xD0, 0xCA, \
    0x88, 0xEA
SEI, CLD, TXS, JMP_ABS = 0x78, 0xD8, 0x9A, 0x4C


def build(writes_out=None):
    a = Assembler()
    log = []
    origin = [None]
    fast = [False]

    def sta(addr, value):
        a.emit(2, LDA_IMM, value)
        # The write is in the last cycle of the STA
        a.emit(3, STA_ABS, addr & 0xFF, addr >> 8)
        cycle = a.cycles
        a.emit(1)
        return cycle

    # Waits n cycles, with loops of LDX #k / DEX / BNE, 5 * k + 1 cycles,
    # whose branch does not cross a page, and NOPs
    def delay(n):
        assert n >= 2 or n == 0, n
        # LDY #m / LDX #0 / DEX / BNE / DEY / BNE, m * 1286 + 1 cycles
        while n >= 1286 + 1 + 20:
            pad = 0
            while (a.here() + pad + 2) >> 8 != (a.here() + pad + 10) >> 8:
                pad += 1
            m = min(256, (n - 2 * pad - 1 - 20) // 1286)
            for _ in range(pad):
                a.emit(2, NOP)
            a.emit(2, LDY_IMM, m & 0xFF)
            a.emit(m * 1286 - 1, LDX_IMM, 0x00, DEX, BNE, 0xFD, DEY, BNE,
                   0xF8)
            n -= 2 * pad + m * 1286 + 1
        while n >= 20:
            pad = 0
            while (a.here() + pad + 2) >> 8 != (a.here() + pad + 5) >> 8:
                pad += 1
            k = min(256, (n - 2 * pad - 1 - 2) // 5)
            for _ in range(pad):
                a.emit(2, NOP)
            a.emit(2, LDX_IMM, k & 0xFF)
            a.emit(5 * k - 1, DEX, BNE, 0xFD)
            n -= 2 * pad + 5 * k + 1
        assert n >= 0 and n != 1, n
        if n % 2 == 1:
            a.emit(3, BIT_ZP, 0x00)
            n -= 3
        while n > 0:
            a.emit(2, NOP)
            n -= 2

    def opll(port, value):
        cycle = sta(0x9030 if port else 0x9010, value)
        log.append((cycle, port, value))

    a.emit(0, SEI, CLD, LDX_IMM, 0xFF, TXS)
    for addr, value in ((0x2000, 0), (0x2001, 0), (0x4010, 0), (0x4015, 0),
                        (0x4017, 0x40), (0xE000, 0x40)):
        sta(addr, value)
    for _ in range(2):
        start = a.here()
        a.emit(0, BIT_ABS, 0x02, 0x20, BPL, 0xFB)
    # From here on the code runs straight through and its cycles count
    a.cycles = 0
    sta(0xE000, 0x00)
    origin[0] = a.cycles - 1
    delay(200)

    seg_start = a.cycles
    for seg in SEGMENTS:
        for w in seg:
            if w == 'fast':
                fast[0] = True
            elif w == 'slow':
                fast[0] = False
            elif w == 'reset':
                sta(0xE000, 0x40)
                delay(100)
                sta(0xE000, 0x00)
                log.append((a.cycles - 1, 'reset', 0))
                delay(200)
            else:
                reg, value = w
                opll(0, reg)
                delay(0 if fast[0] else ADDR_GAP - 6)
                opll(1, value)
                delay(0 if fast[0] else DATA_GAP - 6)
        seg_start += SEGMENT_CYCLES
        assert a.cycles < seg_start, 'segment too long'
        delay(seg_start - a.cycles)

    loop = a.here()
    a.emit(0, JMP_ABS, loop & 0xFF, loop >> 8)
    a.emit(0, 0x40)                             # RTI for NMI and IRQ
    rti = ORG + len(a.code) - 1

    code = a.code
    assert len(code) <= 0x2000 - 6, 'code too long'

    prg = bytearray([0xFF]) * (0x2000 * PRG_BANKS)
    last = len(prg) - 0x2000
    prg[last:last + len(code)] = code
    for vec, addr in ((0xFFFA, rti), (0xFFFC, ORG), (0xFFFE, rti)):
        prg[last + vec - 0xE000] = addr & 0xFF
        prg[last + vec - 0xE000 + 1] = addr >> 8

    chr_rom = bytearray(0x2000)
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((85 & 0x0F) << 4), (85 & 0xF0) | 0x08])
    header += bytes(8)
    header[8] = 0x20                            # submapper 2, VRC7a

    if writes_out is not None:
        with open(writes_out, 'w') as f:
            for cycle, port, value in log:
                if port == 'reset':
                    f.write('%d reset\n' % (cycle - origin[0]))
                else:
                    f.write('%d %d %02X\n' % (cycle - origin[0], port, value))

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    rom = build(sys.argv[2] if len(sys.argv) == 3 else None)
    with open(sys.argv[1], 'wb') as f:
        f.write(rom)


if __name__ == '__main__':
    main()
