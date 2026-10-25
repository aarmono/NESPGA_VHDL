#!/usr/bin/env python3
"""Generate test ROMs for the discrete logic boards whose latch holds bits of
the address written as well as of the data: Active Enterprises (mapper 228,
Action 52 and Cheetah Men II).

Usage: latch_addr.py OUT.nes VARIANT

Mapper 228 latches A13-A0 and D1-D0 of a write to 0x8000-0xFFFF:
  A13     mirroring: 0 vertical, 1 horizontal
  A12-A11 socket of the 512KB PRG ROM chip
  A10-A6  16KB PRG ROM bank in the chip
  A5      1: the 16KB bank at both 0x8000 and 0xC000, 0: a 32KB bank
  A3-A0   bits 5-2 of the 8KB CHR ROM bank, D1-D0 its bits 1-0
Action 52 has chips in sockets 0, 1 and 3, and the ROM file holds them in
that order. Socket 2 is empty, so the CPU reads open bus there.

The ROM checks, in groups:
  1 32KB PRG ROM banks: each 8KB bank holds its number in the ROM file at
    SIG_LO and its complement at SIG_HI. Bit 0 of the 16KB bank is ignored
  2 16KB PRG ROM banks, at both 0x8000 and 0xC000
  3 Socket 2: open bus with three chips, which is read from code in RAM,
    since none of PRG ROM is there. Otherwise the bank wraps at the size of
    the ROM
  4 CHR ROM banks: the first byte of each 1KB bank holds the number of its
    8KB bank, the second its number in the 8KB bank, read back through
    $2006/$2007
  5 Mirroring

The code is in every odd 8KB bank, which is the one at 0xE000 in either PRG
mode, so it runs on whichever bank is selected. Rendering stays off, so the
PPU can be accessed at any time.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed; the
index of the failing check within its group is at zero page DETAIL. The
result is up a few frames after reset, so 250ms of nes_bench is enough.

Variants:
  228_a52   iNES mapper 228, 1.5MB PRG (three chips), 512KB CHR: Action 52
  228_small iNES mapper 228, 256KB PRG, 128KB CHR: Cheetah Men II. The bank
            numbers wrap at the size of the ROMs

Mesen fails group 3 of 228_a52: it maps socket 2 like socket 3.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

# prg: 16KB units; chr: 8KB units
VARIANTS = {
    '228_a52':   dict(prg=96, chr=64),
    '228_small': dict(prg=16, chr=16),
}

PASS_COLOR = 0x2A

# The code is at ORG in every odd 8KB bank. Each 8KB bank holds its number
# at SIG_LO and its complement at SIG_HI, clear of the code and the vectors
ORG = 0xE100
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# The routine that reads socket 2 runs from RAM
RAM_CODE = 0x0300

# Zero page
DETAIL = 0x00


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
LDX_IMM, LDY_IMM, CMP_IMM, BIT_ABS = 0xA2, 0xA0, 0xC9, 0x2C
STY_ZP, LDA_ABS_X, STA_ABS_X, INX, CPX_IMM = 0x84, 0xBD, 0x9D, 0xE8, 0xE0
BPL, BEQ, BNE, JMP_ABS, JSR, RTS, RTI = 0x10, 0xF0, 0xD0, 0x4C, 0x20, 0x60, \
    0x40


# The address of a write to the latch
def latch_addr(socket=0, page=0, nrom_128=False, chr_hi=0, horz=False):
    return (0x8000 | (horz << 13) | (socket << 11) | (page << 6) |
            (nrom_128 << 5) | chr_hi)


def build(v):
    a = Assembler()
    group = [1]
    detail = [0]
    prg_8kb = v['prg'] * 2
    chr_8kb = v['chr']
    three_chips = v['prg'] == 96

    # The 8KB bank of the ROM file in window w of 16KB bank page of socket
    def file_bank(socket, page, w):
        if three_chips:
            assert socket != 2
            if socket == 3:
                socket = 2
        return (((socket << 5) | page) * 2 + w) % prg_8kb

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

    def cpu_check(addr, value):
        a.abs(LDA_ABS, addr)
        check(value)

    def ppu_check(addr, value):
        ppu_addr(addr)
        a.abs(LDA_ABS, 0x2007)                  # the read buffer
        a.abs(LDA_ABS, 0x2007)
        check(value)

    # The 8KB banks at 0x8000, 0xA000, 0xC000 and 0xE000
    def windows_check(banks):
        for w, bank in enumerate(banks):
            cpu_check(0x8000 + 0x2000 * w + SIG_LO, bank)
        cpu_check(0x8000 + SIG_HI, banks[0] ^ 0xFF)

    def prg_32kb_check(socket, page):
        write(latch_addr(socket, page), 0)
        windows_check([file_bank(socket, page & ~1, w) for w in range(4)])

    a.label('reset')
    a.emit(0x78, 0xD8, 0xA2, 0xFF, 0x9A)        # SEI CLD LDX #$FF TXS
    write(0x2000, 0)
    write(0x2001, 0)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # The routine that reads socket 2 to RAM
    a.emit(LDX_IMM, 0)
    a.label('copy')
    a.abs_label(LDA_ABS_X, 'ram_code')
    a.abs(STA_ABS_X, RAM_CODE)
    a.emit(INX)
    a.emit(CPX_IMM, 0)                          # patched with the length
    cpx_operand = len(a.code) - 1
    a.branch(BNE, 'copy')

    sockets = [0, 1, 3]

    # 32KB PRG ROM banks
    for socket in sockets:
        for page in (0, 7, 22, 31):
            prg_32kb_check(socket, page)

    # 16KB PRG ROM banks
    next_group()
    for socket, page in ((0, 4), (1, 9), (3, 30), (3, 31)):
        write(latch_addr(socket, page, nrom_128=True), 0)
        windows_check([file_bank(socket, page, w) for w in (0, 1, 0, 1)])
    write(latch_addr(), 0)

    # Socket 2
    next_group()
    if three_chips:
        # LDA abs leaves the high byte of the address on the bus, which
        # differs from what is at SIG_HI of any bank
        a.abs_label(JSR, 'ram_code_run')
        check((0x8000 + SIG_HI) >> 8)
    else:
        prg_32kb_check(2, 5)
        write(latch_addr(), 0)

    # CHR ROM banks
    next_group()
    for bank in (0, 1, 2, 3, 5, 0x2A, 0x3F):
        write(latch_addr(chr_hi=bank >> 2), bank & 3)
        ppu_check(0x0000, bank % chr_8kb)
        ppu_check(0x1C00, bank % chr_8kb)
        ppu_check(0x1C01, 7)
    write(latch_addr(), 0)

    # Mirroring. Each of the four nametables is written with its own byte,
    # so the bytes read back show which share CIRAM
    next_group()
    for horz, expect in ((False, [2, 3, 2, 3]), (True, [1, 1, 3, 3])):
        write(latch_addr(horz=horz), 0)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + expect[i])
    write(latch_addr(), 0)

    a.emit(LDX_IMM, PASS_COLOR)

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show')
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

    a.label('rti')
    a.emit(RTI)

    # Copied to RAM_CODE: selects socket 2, reads it and selects the first
    # bank again, which has this code at 0xE000 to return to
    a.label('ram_code')
    ram_code = len(a.code)
    a.abs(STA_ABS, latch_addr(socket=2))
    a.abs(LDA_ABS, 0x8000 + SIG_HI)
    a.abs(STX_ABS, latch_addr())                # keeps A
    a.emit(RTS)
    a.code[cpx_operand] = len(a.code) - ram_code
    a.labels['ram_code_run'] = RAM_CODE

    code = a.link()
    assert ORG + len(code) <= 0xE000 + SIG_HI, 'code runs into SIG_HI'

    prg = bytearray([0xFF]) * (0x2000 * prg_8kb)
    for b in range(prg_8kb):
        prg[0x2000 * b + SIG_LO] = b
        prg[0x2000 * b + SIG_HI] = b ^ 0xFF

    for b in range(1, prg_8kb, 2):
        base = 0x2000 * b - 0xE000
        prg[base + ORG:base + ORG + len(code)] = code
        for vec, name in ((0xFFFA, 'rti'), (0xFFFC, 'reset'), (0xFFFE, 'rti')):
            prg[base + vec] = a.labels[name] & 0xFF
            prg[base + vec + 1] = a.labels[name] >> 8

    chr_rom = bytearray(0x2000 * chr_8kb)
    for b in range(chr_8kb):
        for k in range(8):
            chr_rom[0x2000 * b + 0x400 * k] = b
            chr_rom[0x2000 * b + 0x400 * k + 1] = k

    mapper = 228
    header = bytearray(b'NES\x1a')
    header += bytes([v['prg'], v['chr'], (mapper & 0x0F) << 4, mapper & 0xF0])
    header += bytes(8)

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
