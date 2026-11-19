#!/usr/bin/env python3
"""Generate an NROM test ROM for the PPU's $2007 accesses at the cartridge
connector, for nes_bench CART_NROM_SLOT runs against a real cartridge's timing.

Usage: slot_ppu.py OUT.nes

A $2007 write of the emulated PPU is one dot long (a read is two), which is
too short for a real cartridge's memories unless the bus already holds the
address. A PPU that isn't rendering drives v on the address bus, so it does:
after a $2006 write, after another $2007 access, and when rendering stops.
This ROM checks the last, with a $2007 access after rendering stops and no
$2006 write.

With the scroll at 0, a whole frame leaves v at $0802 in vblank (fine Y wraps
to 0, coarse Y to 0 in the other nametable, coarse X at 2 from the prefetch
of the next line), and the last fetch of the frame was the nametable byte at
$2802. CIRAM is only deselected there, and its A10 stays: the last nametable
fetch and v differ in A13 alone. CIRAM is selected, at an A10 that may
change, when rendering is turned off mid-frame during a pattern fetch, on a
line whose fine Y is 2 or 3 (v at $2xxx).

The ROM checks, in groups:
  1 CHR ROM read through $2006/$2007, where the bus already holds the address
  2 CHR ROM read through $2007 in vblank after a rendered frame, rendering
    turned off and no $2006 write: $0802, then $0803
  3 CIRAM write through $2007 right after rendering is turned off on line
    18 or 19 (fine Y 2 or 3). There are 16 trials, each 3 CPU cycles later
    than the one before, so that rendering stops in the different dots of a
    tile fetch. Each trial clears the nametables, writes a marker and
    expects to find exactly one. The index is the trial

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed; the
index of the failing check within its group is at zero page DETAIL. The
result is up a few frames after reset, so 250ms of nes_bench is enough.

Mesen passes it.
"""

import sys

from latch import (Assembler, ORG, PASS_COLOR, LDA_IMM, LDA_ABS, STA_ABS,
                   STX_ABS, LDX_IMM, LDY_IMM, CMP_IMM, BIT_ABS, STY_ZP, BPL,
                   BEQ, JMP_ABS, JSR, RTS, RTI)

LDA_ZP, STA_ZP, INC_ZP = 0xA5, 0x85, 0xE6
DEX, DEY, BNE = 0xCA, 0x88, 0xD0

# Zero page
DETAIL = 0x00
FOUND = 0x01

CIRAM_TRIALS = 16
# In the first trial, the $2001 write that turns rendering off comes about
# 4,500 CPU cycles after the $2002 read that sees vblank: around dot 200 of
# line 18, which starts (262 - 241 + 18) * 341 dots after vblank does. Lines
# 18-19 make a window 682 dots wide. The trials add up to 135 dots and the
# $2002 loop up to 21 more
DELAY_OUTER = 9
DELAY_INNER = 98

# The address v holds in vblank after a frame rendered with the scroll at 0
VBLANK_V = 0x0802


def chr_byte(addr):
    return (addr ^ (addr >> 8) ^ 0x5A) & 0xFF


def build():
    a = Assembler()
    group = [1]
    detail = [0]

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def ppu_addr(addr):
        a.emit(LDA_IMM, addr >> 8)
        a.abs(STA_ABS, 0x2006)
        a.emit(LDA_IMM, addr & 0xFF)
        a.abs(STA_ABS, 0x2006)

    def next_group():
        group[0] += 1
        detail[0] = 0
        assert group[0] < PASS_COLOR

    # Fails with the group number unless A is value
    def check(value):
        a.emit(LDX_IMM, group[0])
        a.emit(LDY_IMM, detail[0] & 0xFF)
        a.emit(CMP_IMM, value)
        a.emit(BEQ, 3)
        a.abs_label(JMP_ABS, 'show')
        detail[0] += 1

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    a.label('reset')
    a.emit(0x78, 0xD8, 0xA2, 0xFF, 0x9A)        # SEI CLD LDX #$FF TXS
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # CHR ROM read with the address already on the bus
    ppu_addr(VBLANK_V)
    a.abs(LDA_ABS, 0x2007)                      # the read buffer
    a.abs(LDA_ABS, 0x2007)
    check(chr_byte(VBLANK_V))
    a.abs(LDA_ABS, 0x2007)
    check(chr_byte(VBLANK_V + 1))
    next_group()

    # Render a frame with the scroll at 0, the background only
    wait_vblank('vblank_3')
    write(0x2000, 0x00)
    write(0x2005, 0x00)
    write(0x2005, 0x00)
    write(0x2001, 0x08)
    wait_vblank('vblank_4')
    wait_vblank('vblank_5')
    write(0x2001, 0x00)
    a.abs(LDA_ABS, 0x2007)                      # the read buffer
    a.abs(LDA_ABS, 0x2007)
    check(chr_byte(VBLANK_V))
    a.abs(LDA_ABS, 0x2007)
    check(chr_byte(VBLANK_V + 1))

    next_group()

    for k in range(CIRAM_TRIALS):
        a.abs_label(JSR, 'clear_nt')
        wait_vblank(f'ciram_vblank_{k}')
        write(0x2000, 0x00)
        write(0x2005, 0x00)
        write(0x2005, 0x00)
        write(0x2001, 0x08)
        # DELAY_OUTER * (5 * DELAY_INNER + 6) + 1 cycles
        a.emit(LDY_IMM, DELAY_OUTER)
        a.label(f'delay_outer_{k}')
        a.emit(LDX_IMM, DELAY_INNER)
        a.label(f'delay_inner_{k}')
        a.emit(DEX)
        a.branch(BNE, f'delay_inner_{k}')
        a.emit(DEY)
        a.branch(BNE, f'delay_outer_{k}')
        for _ in range(k):
            a.emit(LDA_ZP, DETAIL)              # 3 cycles
        write(0x2001, 0x00)
        write(0x2007, 0x55)
        a.abs_label(JSR, 'count_nt')
        check(1)

    a.emit(LDX_IMM, PASS_COLOR)
    a.emit(LDY_IMM, 0)

    a.label('show')
    a.emit(STY_ZP, DETAIL)
    wait_vblank('vblank_6')
    write(0x2001, 0x00)
    ppu_addr(0x3F00)
    a.abs(STX_ABS, 0x2007)
    ppu_addr(0x0000)
    a.label('loop')
    a.abs_label(JMP_ABS, 'loop')

    a.label('clear_nt')
    ppu_addr(0x2000)
    a.emit(LDA_IMM, 0x00)
    a.emit(LDY_IMM, 8)
    a.label('clear_outer')
    a.emit(LDX_IMM, 0)
    a.label('clear_inner')
    a.abs(STA_ABS, 0x2007)
    a.emit(DEX)
    a.branch(BNE, 'clear_inner')
    a.emit(DEY)
    a.branch(BNE, 'clear_outer')
    a.emit(RTS)

    # A = the number of bytes of both nametables that aren't 0
    a.label('count_nt')
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, FOUND)
    ppu_addr(0x2000)
    a.abs(LDA_ABS, 0x2007)                      # the read buffer
    a.emit(LDY_IMM, 8)
    a.label('count_outer')
    a.emit(LDX_IMM, 0)
    a.label('count_inner')
    a.abs(LDA_ABS, 0x2007)
    a.branch(BEQ, 'count_next')
    a.emit(INC_ZP, FOUND)
    a.label('count_next')
    a.emit(DEX)
    a.branch(BNE, 'count_inner')
    a.emit(DEY)
    a.branch(BNE, 'count_outer')
    a.emit(LDA_ZP, FOUND)
    a.emit(RTS)

    a.label('rti')
    a.emit(RTI)

    code = a.link()

    # 16KB of PRG at 0xC000, mirrored at 0x8000
    prg = bytearray([0xFF]) * 0x4000
    base = ORG - 0xC000
    prg[base:base + len(code)] = code
    for vec, name in ((0xFFFA, 'rti'), (0xFFFC, 'reset'), (0xFFFE, 'rti')):
        prg[vec - 0xC000] = a.labels[name] & 0xFF
        prg[vec - 0xC000 + 1] = a.labels[name] >> 8

    chr_rom = bytes(chr_byte(i) for i in range(0x2000))

    # iNES mapper 0, vertical mirroring
    header = bytearray(b'NES\x1a') + bytes([1, 1, 0x01, 0x00]) + bytes(8)

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build())


if __name__ == '__main__':
    main()
