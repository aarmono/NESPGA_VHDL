#!/usr/bin/env python3
"""Generate test ROMs for the audio of the Nintendo MMC5 (mapper 5).

Usage: mmc5_audio.py OUT.nes VARIANT

The check ROM (VARIANT check) checks, in order (each is a group; its number
is the failure color):
   1  0x5015: a length counter is loaded only while its channel is enabled,
      reads back as a status bit and is cleared when the channel is
      disabled
   2  The length counters are clocked at 240 Hz: a count of 10 is still
      running 60,000 CPU cycles after it is loaded and done by 86,000 (at
      the 120 Hz of the APU it would take at least 134,000), unless halted
   3  The PCM IRQ in write mode: 0x5011 = 0 raises it while 0x5010 bit 7
      is set, a read of 0x5010 returns bit 7 and acknowledges it, an IRQ
      raised while disabled is taken when enabled, and a write of any other
      value clears it
   4  The PCM IRQ in read mode (0x5010 bit 0): 0x5011 is ignored, and a read
      of 0 from 0x8000-0xBFFF raises the IRQ but one from 0xC000-0xFFFF
      does not. 0x5010 reads back the mode in bit 0, which nesdev guesses

Mesen does not emulate the PCM IRQ or read mode, so it fails at group 3.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed; the index of the
failing check within its group is at zero page DETAIL. The result is up
about 15 frames after reset, so 400ms of nes_bench is enough.

The audio ROM (VARIANT audio) plays SEGMENTS, each for about SEGMENT_FRAMES
frames with a frame of silence before it, and is compared with Mesen's WAV
by mmc5_audio_compare.py. The backdrop is green while it plays.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = ['check', 'audio']

PASS_COLOR = 0x2A

PRG_BANKS = 8

# The code is in every 8KB bank, so it runs whatever bank is at 0xE000
ORG = 0xE100
# Offsets in every bank of a 0 byte and a nonzero byte, read in PCM read
# mode
ZERO_BYTE = 0x0020
NONZERO_BYTE = 0x0021

# Zero page
GOT_IRQ = 0x00
IRQ_VAL = 0x01
FRAMES = 0x02
COUNT = 0x03
DETAIL = 0x04

SEGMENT_FRAMES = 20
# The PCM DAC is left at its last level, which is silent, since 0x5011 = 0
# does not change it and a step to another level would be taken for the
# start of a segment
SILENCE = [(0x5015, 0x00), (0x4015, 0x00)]
# Register writes, or 'pcm' for the PCM square wave of pcm_wave
SEGMENTS = [
    # Pulse 1, constant volume 15, 50%, period 0x1FF: 218.5 Hz
    [(0x5015, 0x01), (0x5000, 0xBF), (0x5002, 0xFF), (0x5003, 0x01)],
    # The APU pulse 1, volume 15, 50%, at the same frequency, for the level
    [(0x4015, 0x01), (0x4000, 0xBF), (0x4001, 0x08), (0x4002, 0xFF),
     (0x4003, 0x01)],
    # Pulse 2, volume 9, 25%, period 0x0FF
    [(0x5015, 0x02), (0x5004, 0x79), (0x5006, 0xFF), (0x5007, 0x00)],
    # Pulse 1, volume 15, 12.5%, period 0x17F
    [(0x5015, 0x01), (0x5000, 0x3F), (0x5002, 0x7F), (0x5003, 0x01)],
    # Pulse 1, looping envelope of period 1: 30 Hz decays at 240 Hz. With a
    # longer period the volume would be 0 for a frame or more, which looks
    # like the silence between segments
    [(0x5015, 0x01), (0x5000, 0xA1), (0x5002, 0xFF), (0x5003, 0x01)],
    # Both pulses at full volume, an octave apart
    [(0x5015, 0x03), (0x5000, 0xBF), (0x5002, 0xFF), (0x5003, 0x01),
     (0x5004, 0xBF), (0x5006, 0xFF), (0x5007, 0x00)],
    # A square wave on the PCM DAC, 0x10 to 0x90. Mesen scales its output
    # by 4 into 16 bits, which overflows once the MMC5 channels sum to more
    # than about 190
    'pcm',
    # The MMC5 pulse 1 and the APU pulse 1 together, which are inverted
    # relative to each other, so they partly cancel
    [(0x5015, 0x01), (0x5000, 0xBF), (0x5002, 0xFF),
     (0x4015, 0x01), (0x4000, 0xBF), (0x4001, 0x08), (0x4002, 0xFF),
     (0x5003, 0x01), (0x4003, 0x01)],
]

# The half period of the PCM square wave in iterations of a 5-cycle loop,
# and the periods played
PCM_DELAY = 200
PCM_PERIODS = 300


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


LDA_IMM, LDA_ABS, STA_ABS, LDX_IMM, LDY_IMM = 0xA9, 0xAD, 0x8D, 0xA2, 0xA0
CMP_IMM, BIT_ABS, LDA_ZP, STA_ZP, INC_ZP, DEC_ZP = \
    0xC9, 0x2C, 0xA5, 0x85, 0xE6, 0xC6
BPL, BEQ, BNE, JMP_ABS, JSR, RTS, RTI = \
    0x10, 0xF0, 0xD0, 0x4C, 0x20, 0x60, 0x40
SEI, CLI, CLD, TXS, NOP, DEX, DEY, PHA, PLA = \
    0x78, 0x58, 0xD8, 0x9A, 0xEA, 0xCA, 0x88, 0x48, 0x68


def build_check(a):
    group = [0]
    index = [0]

    def next_group():
        group[0] += 1
        index[0] = 0

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    # Fails the group unless A is value
    def check(value):
        name = 'ok_%d' % len(a.code)
        a.emit(LDY_IMM, index[0])
        a.emit(CMP_IMM, value)
        a.branch(BEQ, name)
        a.emit(LDX_IMM, group[0])
        a.abs_label(JMP_ABS, 'show')
        a.label(name)
        index[0] += 1

    def read_check(addr, value):
        a.abs(LDA_ABS, addr)
        check(value)

    # Time for a pending IRQ to be taken, then the IRQs taken since the
    # count was cleared
    def irq_check(count, value=None):
        a.emit(NOP, NOP, NOP, NOP)
        a.emit(LDA_ZP, GOT_IRQ)
        check(count)
        if value is not None:
            a.emit(LDA_ZP, IRQ_VAL)
            check(value)

    def clear_irqs():
        a.emit(LDA_IMM, 0)
        a.emit(STA_ZP, GOT_IRQ)
        a.emit(STA_ZP, IRQ_VAL)

    # About 1285 * count CPU cycles
    def delay(count):
        a.emit(LDX_IMM, count)
        a.abs_label(JSR, 'delay')

    # 1: length counters and 0x5015
    next_group()
    write(0x5015, 0x00)
    write(0x5003, 0x08)
    read_check(0x5015, 0x00)
    write(0x5015, 0x03)
    write(0x5003, 0x08)
    read_check(0x5015, 0x01)
    write(0x5007, 0x08)
    read_check(0x5015, 0x03)
    write(0x5015, 0x01)
    read_check(0x5015, 0x01)
    write(0x5015, 0x00)
    read_check(0x5015, 0x00)

    # 2: the 240 Hz length counter clock
    next_group()
    write(0x5015, 0x01)
    write(0x5000, 0x10)
    write(0x5003, 0x00)                     # a count of 10
    delay(47)
    read_check(0x5015, 0x01)
    delay(20)
    read_check(0x5015, 0x00)
    write(0x5000, 0x30)                     # halted
    write(0x5003, 0x00)
    delay(67)
    read_check(0x5015, 0x01)
    write(0x5015, 0x00)

    # 3: the PCM IRQ in write mode
    next_group()
    clear_irqs()
    a.emit(CLI)
    write(0x5010, 0x00)
    write(0x5011, 0x00)
    irq_check(0)
    read_check(0x5010, 0x00)                # disabled, and acknowledged
    write(0x5010, 0x80)
    irq_check(0)
    write(0x5011, 0x00)
    irq_check(1, 0x80)
    read_check(0x5010, 0x00)
    clear_irqs()
    write(0x5010, 0x00)
    write(0x5011, 0x00)
    irq_check(0)
    write(0x5010, 0x80)                     # raised while disabled
    irq_check(1, 0x80)
    clear_irqs()
    write(0x5010, 0x00)
    write(0x5011, 0x00)
    write(0x5011, 0x40)                     # cleared
    write(0x5010, 0x80)
    irq_check(0)

    # 4: the PCM IRQ in read mode
    next_group()
    clear_irqs()
    write(0x5010, 0x81)
    read_check(0x5010, 0x01)
    write(0x5011, 0x00)                     # ignored
    irq_check(0)
    a.abs(LDA_ABS, 0xA000 + NONZERO_BYTE)
    irq_check(0)
    a.abs(LDA_ABS, 0xC000 + ZERO_BYTE)      # out of the window
    irq_check(0)
    a.abs(LDA_ABS, 0xA000 + ZERO_BYTE)
    irq_check(1, 0x81)
    a.abs(LDA_ABS, 0x8000 + NONZERO_BYTE)   # cleared
    clear_irqs()
    a.abs(LDA_ABS, 0x8000 + ZERO_BYTE)
    irq_check(1, 0x81)
    a.emit(SEI)
    write(0x5010, 0x00)

    a.emit(LDX_IMM, PASS_COLOR)
    a.emit(LDY_IMM, 0)
    a.abs_label(JMP_ABS, 'show')

    a.label('delay')
    a.emit(LDY_IMM, 0)
    a.label('delay_inner')
    a.emit(DEY)
    a.branch(BNE, 'delay_inner')
    a.emit(DEX)
    a.branch(BNE, 'delay')
    a.emit(RTS)


def build_audio(a, wait_vblank):
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

    # PCM_PERIODS periods of 0x90 then 0x10 for PCM_DELAY loops each, then
    # to the next vblank, so that the silence after it is a whole frame
    def pcm_wave():
        name = 'pcm_%d' % len(a.code)
        a.emit(LDX_IMM, PCM_PERIODS % 256)
        a.emit(LDA_IMM, PCM_PERIODS // 256 + 1)
        a.emit(STA_ZP, COUNT)
        a.label(name)
        for value in (0x90, 0x10):
            write(0x5011, value)
            a.emit(LDY_IMM, PCM_DELAY)
            a.label('%s_%x' % (name, value))
            a.emit(DEY)
            a.branch(BNE, '%s_%x' % (name, value))
        a.emit(DEX)
        a.branch(BNE, name)
        a.emit(DEC_ZP, COUNT)
        a.branch(BNE, name)
        wait_frames(1)

    a.label('show_green')
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
        if seg == 'pcm':
            pcm_wave()
        else:
            for addr, value in seg:
                write(addr, value)
            wait_frames(SEGMENT_FRAMES)
    for addr, value in SILENCE:
        write(addr, value)

    a.label('done')
    a.abs_label(JMP_ABS, 'done')


def build(variant):
    a = Assembler()

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
    a.abs(STA_ABS, 0x5010)
    a.abs(STA_ABS, 0x5015)
    a.emit(LDA_IMM, 0x40)                       # no frame IRQ
    a.abs(STA_ABS, 0x4017)
    # PRG mode 3, with ROM bank 0 at 0x8000-0xDFFF
    a.emit(LDA_IMM, 0x03)
    a.abs(STA_ABS, 0x5100)
    a.emit(LDA_IMM, 0x80)
    a.abs(STA_ABS, 0x5114)
    a.abs(STA_ABS, 0x5115)
    a.abs(STA_ABS, 0x5116)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    if variant == 'audio':
        build_audio(a, wait_vblank)
    else:
        build_check(a)

        # Backdrop color X, then the VRAM address off the palette so that
        # the backdrop is what rendering off shows
        a.label('show')
        a.emit(SEI)
        a.emit(0x84, DETAIL)                    # STY zp
        wait_vblank('vblank_3')
        a.emit(LDA_IMM, 0x3F)
        a.abs(STA_ABS, 0x2006)
        a.emit(LDA_IMM, 0x00)
        a.abs(STA_ABS, 0x2006)
        a.abs(0x8E, 0x2007)                     # STX abs
        a.emit(LDA_IMM, 0x00)
        a.abs(STA_ABS, 0x2006)
        a.abs(STA_ABS, 0x2006)
        a.label('loop')
        a.abs_label(JMP_ABS, 'loop')

    # The IRQ handler stores what 0x5010 reads, which acknowledges the PCM
    # IRQ
    a.label('irq')
    a.emit(PHA)
    a.abs(LDA_ABS, 0x5010)
    a.emit(STA_ZP, IRQ_VAL)
    a.emit(INC_ZP, GOT_IRQ)
    a.emit(PLA)
    a.label('nmi')
    a.emit(RTI)

    code = a.link()
    assert ORG + len(code) <= 0xFFFA, 'code runs into the vectors'

    bank = bytearray([0xFF]) * 0x2000
    bank[ZERO_BYTE] = 0x00
    bank[ORG - 0xE000:ORG - 0xE000 + len(code)] = code
    for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'), (0xFFFE, 'irq')):
        bank[vec - 0xE000] = a.labels[name] & 0xFF
        bank[vec - 0xE000 + 1] = a.labels[name] >> 8
    prg = bank * PRG_BANKS

    chr_rom = bytearray(0x2000)

    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000, 0x50, 0x00])
    header += bytes(8)

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(sys.argv[2]))


if __name__ == '__main__':
    main()
