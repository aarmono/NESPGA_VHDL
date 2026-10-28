#!/usr/bin/env python3
"""Generate a ROM that shows what the RAMs of the console powered up with,
so that the power up fill can be compared between power cycles.

Usage: power_up_view.py OUT.nes

The board is NROM (NES 2.0 mapper 0) with 8KB of CHR RAM and 8KB of PRG RAM
without a battery, vertical mirroring, so that every kind of RAM the fill
makes random is there.

Before it writes any RAM the ROM copies CPU RAM to CHR RAM 0x0000-0x07FF,
using only the registers: no stack, no zero page. Then it takes
  CHR RAM 0x0800-0x1FFF, the part the copy left alone
  CIRAM, read through $2007 and copied to CHR RAM 0x1000-0x17FF
  OAM, read through $2004 and copied to CHR RAM 0x1800-0x18FF
  PRG RAM 0x6000-0x7FFF, which nothing writes
and puts a font in CHR RAM 0x0800-0x0BFF.

The summary screen shows:
  CPU RAM as a picture: the copy in CHR RAM is tiles $00-$7F, 2 bits per
    pixel, a row of 16 tiles for each 256 bytes
  The CRC32 (as zlib.crc32) and the number of 1 bits of each RAM. A RAM
    the same as at the last power up has the same CRC, and random bytes have
    about half their bits set
  For CIRAM and OAM, the shift S from -8 to +8 at which the most bytes are
    the same as CPU RAM, X[A] = RAM[B+A+S] (wrapping within the 2KB), and
    how many are. Independent random bytes match 1 time in 256
Left and right step through hex dumps of the RAMs, 256 bytes a page (CPU
RAM, CIRAM, OAM and PRG RAM: 49 pages), up and down by 8 pages, select or
start back to the summary. The bytes of a row alternate in colour.

The summary is up about 1.5s after reset (frame 86-96 of nes_bench; equal
bytes take longer to count). nes_bench gives the RAMs the same bytes every
run (POWER_UP_DETERMINISTIC with -gPOWER_UP_FILL=true, zero otherwise), so
it is on the board that the power cycles differ. Mesen powers up its RAMs
random, and the numbers it shows match its memory dumped before reset.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys
import zlib

# Zero page, free once CPU RAM is copied
PTR = 0x00
PTR2 = 0x02
CRC = 0x04                  # 4 bytes, least significant first
ONES = 0x08                 # 3 bytes
Q = 0x0B
PAGE = 0x0C
BUTTONS = 0x0D
PREV = 0x0E
NEW = 0x0F
NUM = 0x10                  # 3 bytes
T0 = 0x13
T1 = 0x14
LEAD = 0x15
ALO = 0x16
AHI = 0x17
BEST_LO = 0x18
BEST_HI = 0x19
BEST_SI = 0x1A
RES = 0x20                  # 7 bytes a region: CRC, ones
CORR_CIRAM = 0x44           # shift index, count lo, count hi
CORR_OAM = 0x47
SHIFTS = 17
CNT_LO = 0x50
CNT_HI = CNT_LO + SHIFTS

BUF_A = 0x0300
BUF_B = 0x0400              # 8 + 256 + 8 bytes

ORG = 0x8000
DATA = 0xE000

# Regions in the order of RES: name, row, number of bits
REGIONS = [('CPU RAM', 2048), ('CIRAM', 2048), ('OAM', 256),
           ('CHR RAM', 6144), ('PRG RAM', 8192)]
SLOT_CPU, SLOT_CIRAM, SLOT_OAM, SLOT_CHR, SLOT_PRG = range(5)

# Hex pages: title, address shown, source (ppu or cpu), source high byte
PAGES = ([('CPU RAM', 0x0000 + 0x100 * p, 'ppu', 0x00 + p) for p in range(8)] +
         [('CIRAM', 0x2000 + 0x100 * p, 'ppu', 0x10 + p) for p in range(8)] +
         [('OAM', 0x00, 'ppu', 0x18)] +
         [('PRG RAM', 0x6000 + 0x100 * p, 'cpu', 0x60 + p)
          for p in range(32)])
NUM_SCREENS = len(PAGES) + 1

BTN_RIGHT, BTN_LEFT, BTN_DOWN, BTN_UP = 0x01, 0x02, 0x04, 0x08
BTN_START_SELECT = 0x30

# Font: 5x7 glyphs for ASCII $20-$5F, the tiles $80-$BF. The glyphs are in
# both planes, colour 3
GLYPHS = {
    '0': '01110 10001 10011 10101 11001 10001 01110',
    '1': '00100 01100 00100 00100 00100 00100 01110',
    '2': '01110 10001 00001 00010 00100 01000 11111',
    '3': '11111 00010 00100 00010 00001 10001 01110',
    '4': '00010 00110 01010 10010 11111 00010 00010',
    '5': '11111 10000 11110 00001 00001 10001 01110',
    '6': '00110 01000 10000 11110 10001 10001 01110',
    '7': '11111 00001 00010 00100 01000 01000 01000',
    '8': '01110 10001 10001 01110 10001 10001 01110',
    '9': '01110 10001 10001 01111 00001 00010 01100',
    'A': '01110 10001 10001 11111 10001 10001 10001',
    'B': '11110 10001 10001 11110 10001 10001 11110',
    'C': '01110 10001 10000 10000 10000 10001 01110',
    'D': '11100 10010 10001 10001 10001 10010 11100',
    'E': '11111 10000 10000 11110 10000 10000 11111',
    'F': '11111 10000 10000 11110 10000 10000 10000',
    'G': '01110 10001 10000 10111 10001 10001 01111',
    'H': '10001 10001 10001 11111 10001 10001 10001',
    'I': '01110 00100 00100 00100 00100 00100 01110',
    'J': '00111 00010 00010 00010 00010 10010 01100',
    'K': '10001 10010 10100 11000 10100 10010 10001',
    'L': '10000 10000 10000 10000 10000 10000 11111',
    'M': '10001 11011 10101 10101 10001 10001 10001',
    'N': '10001 10001 11001 10101 10011 10001 10001',
    'O': '01110 10001 10001 10001 10001 10001 01110',
    'P': '11110 10001 10001 11110 10000 10000 10000',
    'Q': '01110 10001 10001 10001 10101 10010 01101',
    'R': '11110 10001 10001 11110 10100 10010 10001',
    'S': '01111 10000 10000 01110 00001 00001 11110',
    'T': '11111 00100 00100 00100 00100 00100 00100',
    'U': '10001 10001 10001 10001 10001 10001 01110',
    'V': '10001 10001 10001 10001 10001 01010 00100',
    'W': '10001 10001 10001 10101 10101 10101 01010',
    'X': '10001 10001 01010 00100 01010 10001 10001',
    'Y': '10001 10001 10001 01010 00100 00100 00100',
    'Z': '11111 00001 00010 00100 01000 10000 11111',
    '/': '00001 00001 00010 00100 01000 10000 10000',
    '+': '00000 00100 00100 11111 00100 00100 00000',
    '-': '00000 00000 00000 11111 00000 00000 00000',
    '$': '00100 01111 10100 01110 00101 11110 00100',
    ':': '00000 01100 01100 00000 01100 01100 00000',
    '.': '00000 00000 00000 00000 00000 01100 01100',
    ',': '00000 00000 00000 00000 01100 00100 01000',
    '=': '00000 00000 11111 00000 11111 00000 00000',
    '[': '01110 01000 01000 01000 01000 01000 01110',
    ']': '01110 00010 00010 00010 00010 00010 01110',
    '(': '00010 00100 01000 01000 01000 00100 00010',
    ')': '01000 00100 00010 00010 00010 00100 01000',
}


def tile(ch):
    assert 0x20 <= ord(ch) < 0x60, ch
    return ord(ch) + 0x60


SPACE = tile(' ')
PLUS = tile('+')
MINUS = tile('-')
DIGIT0 = tile('0')


def font():
    out = bytearray()
    for c in range(0x20, 0x60):
        rows = [int(r, 2) << 2 for r in GLYPHS.get(chr(c), '').split()]
        rows = (rows + [0] * 8)[:8]
        out += bytes(rows) * 2
    return out


def nt_addr(row, col):
    return 0x2000 + 32 * row + col


OPS = {
    ('LDA', 'imm'): 0xA9, ('LDA', 'zp'): 0xA5, ('LDA', 'abs'): 0xAD,
    ('LDA', 'absx'): 0xBD, ('LDA', 'absy'): 0xB9, ('LDA', 'indy'): 0xB1,
    ('LDA', 'zpx'): 0xB5,
    ('LDX', 'imm'): 0xA2, ('LDX', 'zp'): 0xA6,
    ('LDY', 'imm'): 0xA0, ('LDY', 'zp'): 0xA4, ('LDY', 'absx'): 0xBC,
    ('STA', 'zp'): 0x85, ('STA', 'abs'): 0x8D, ('STA', 'absx'): 0x9D,
    ('STA', 'absy'): 0x99, ('STA', 'zpx'): 0x95,
    ('STX', 'zp'): 0x86, ('STX', 'abs'): 0x8E,
    ('STY', 'zp'): 0x84, ('STY', 'abs'): 0x8C,
    ('ADC', 'imm'): 0x69, ('ADC', 'zp'): 0x65,
    ('SBC', 'imm'): 0xE9, ('SBC', 'absx'): 0xFD,
    ('AND', 'imm'): 0x29, ('AND', 'zp'): 0x25,
    ('EOR', 'imm'): 0x49, ('EOR', 'zp'): 0x45, ('EOR', 'absx'): 0x5D,
    ('CMP', 'imm'): 0xC9, ('CMP', 'zp'): 0xC5, ('CMP', 'indy'): 0xD1,
    ('CPX', 'imm'): 0xE0, ('CPY', 'imm'): 0xC0,
    ('INC', 'zp'): 0xE6, ('INC', 'zpx'): 0xF6, ('DEC', 'zp'): 0xC6,
    ('BIT', 'abs'): 0x2C,
    ('ROL', 'zp'): 0x26,
    ('JMP', 'abs'): 0x4C, ('JSR', 'abs'): 0x20,
}

IMPLIED = {
    'SEI': 0x78, 'CLD': 0xD8, 'CLC': 0x18, 'SEC': 0x38, 'TAX': 0xAA,
    'TXA': 0x8A, 'TAY': 0xA8, 'TYA': 0x98, 'TXS': 0x9A, 'INX': 0xE8,
    'INY': 0xC8, 'DEX': 0xCA, 'DEY': 0x88, 'PHA': 0x48, 'PLA': 0x68, 'RTS': 0x60,
    'RTI': 0x40, 'LSR': 0x4A,
}

BRANCHES = {'BPL': 0x10, 'BMI': 0x30, 'BNE': 0xD0, 'BEQ': 0xF0,
            'BCC': 0x90, 'BCS': 0xB0}

SIZES = {'imm': 2, 'zp': 2, 'zpx': 2, 'indy': 2,
         'abs': 3, 'absx': 3, 'absy': 3}


class Assembler:
    """Operands are numbers, label names, or ('<', label) and ('>', label)
    for the bytes of a label's address"""

    def __init__(self, labels):
        self.code = bytearray()
        self.labels = dict(labels)
        self.fixups = []
        self.anon = 0

    def here(self):
        return ORG + len(self.code)

    def label(self, name=None):
        if name is None:
            name = self.new_label()
        assert name not in self.labels, name
        self.labels[name] = self.here()
        return name

    def new_label(self):
        self.anon += 1
        return '_%d' % self.anon

    def __call__(self, m, mode=None, v=None):
        if mode is None:
            if m in IMPLIED:
                self.code.append(IMPLIED[m])
            else:
                assert m in BRANCHES, m
                raise ValueError('branch needs a label')
            return
        if m in BRANCHES:
            self.code += bytes([BRANCHES[m], 0])
            self.fixups.append((len(self.code) - 1, mode, 'rel'))
            return
        self.code.append(OPS[(m, mode)])
        size = SIZES[mode] - 1
        self.code += bytes(size)
        self.fixups.append((len(self.code) - size, v, size))

    def resolve(self, v):
        if isinstance(v, int):
            return v
        if isinstance(v, tuple):
            part, name = v
            addr = self.labels[name]
            return addr & 0xFF if part == '<' else addr >> 8
        return self.labels[v]

    def link(self):
        for off, v, kind in self.fixups:
            if kind == 'rel':
                d = self.labels[v] - (ORG + off + 1)
                assert -128 <= d < 128, v
                self.code[off] = d & 0xFF
            else:
                val = self.resolve(v)
                assert 0 <= val < (1 << (8 * kind)), (v, val)
                self.code[off] = val & 0xFF
                if kind == 2:
                    self.code[off + 1] = val >> 8
        return self.code


def text_list(items):
    """A print list: records of address, tiles, 0; then 0xFF"""
    out = bytearray()
    for row, col, s in items:
        addr = nt_addr(row, col)
        out += bytes([addr >> 8, addr & 0xFF]) + bytes(tile(c) for c in s)
        out.append(0)
    out.append(0xFF)
    return out


SUMMARY_ROW = 14
CORR_ROW = 21

SUMMARY_TEXT = (
    [(1, 2, 'POWER-UP RAM CONTENTS'),
     (2, 2, 'CPU RAM, 2 BITS PER PIXEL:')] +
    [(4 + r, 3, '$%X00' % r) for r in range(8)] +
    [(SUMMARY_ROW - 1, 2, 'REGION  CRC32    ONES/BITS')] +
    [(SUMMARY_ROW + i, 2, name) for i, (name, _) in enumerate(REGIONS)] +
    [(SUMMARY_ROW + i, 24, '/%5d' % (8 * size))
     for i, (_, size) in enumerate(REGIONS)] +
    [(CORR_ROW - 1, 2, 'BEST S FOR X[A]=RAM[B+A+S]'),
     (CORR_ROW, 2, 'CIRAM'), (CORR_ROW, 10, 'B=$000 S='),
     (CORR_ROW, 27, '/2048'),
     (CORR_ROW + 1, 2, 'OAM'), (CORR_ROW + 1, 10, 'B=$700 S='),
     (CORR_ROW + 1, 27, '/ 256'),
     (CORR_ROW + 2, 2, '(CHANCE MATCHES: 1 IN 256)'),
     (25, 2, 'LEFT/RIGHT/UP/DOWN: HEX VIEW')])

HEX_TEXT = [(21, 2, '16 BYTES PER ROW'),
            (23, 2, 'LEFT/RIGHT: PAGE, UP/DOWN: 8'),
            (24, 2, 'SELECT/START: SUMMARY')]

HEX_ROW = 4

PALETTE = bytes([0x0F, 0x00, 0x10, 0x30, 0x0F, 0x00, 0x10, 0x21] +
                [0x0F, 0x00, 0x10, 0x30] * 6)

# Hex rows 4-19 are attribute rows 1-4: odd bytes in palette 1
ATTR_HEX = bytes([0x00] * 8 + [0x44] * 32 + [0x00] * 24)


def crc_tables():
    tables = [bytearray(256) for _ in range(4)]
    for i in range(256):
        c = i
        for _ in range(8):
            c = (c >> 1) ^ 0xEDB88320 if c & 1 else c >> 1
        for b in range(4):
            tables[b][i] = (c >> (8 * b)) & 0xFF
    return tables


def build():
    data = {}
    blobs = []

    def place(name, blob, addr=None):
        if addr is None:
            addr = blobs[-1][0] + len(blobs[-1][1]) if blobs else DATA
        data[name] = addr
        blobs.append((addr, bytes(blob)))

    for b, t in enumerate(crc_tables()):
        place('crc_t%d' % b, t, DATA + 0x100 * b)
    place('pop', bytes(bin(i).count('1') for i in range(256)), DATA + 0x400)
    place('font', font(), DATA + 0x500)
    place('hex_tiles', bytes(tile(c) for c in '0123456789ABCDEF'))
    place('palette', PALETTE)
    place('attr_hex', ATTR_HEX)
    place('pow_lo', bytes(p & 0xFF for p in (10000, 1000, 100, 10, 1)))
    place('pow_hi', bytes(p >> 8 for p in (10000, 1000, 100, 10, 1)))
    place('pg_type', bytes(1 if src == 'cpu' else 0 for _, _, src, _ in PAGES))
    place('pg_hi', bytes(hi for _, _, _, hi in PAGES))
    place('summary_text', text_list(SUMMARY_TEXT))
    place('hex_text', text_list(HEX_TEXT))
    titles = []
    for i, (name, shown, _, _) in enumerate(PAGES):
        width = 2 if name == 'OAM' else 4
        title = '%s $%0*X-$%0*X' % (name, width, shown, width, shown + 0xFF)
        place('title_%d' % i,
              text_list([(1, 2, title),
                         (2, 2, 'PAGE %02d/%02d' % (i + 1, len(PAGES)))]))
        titles.append(data['title_%d' % i])
    place('pg_title_lo', bytes(t & 0xFF for t in titles))
    place('pg_title_hi', bytes(t >> 8 for t in titles))
    end = blobs[-1][0] + len(blobs[-1][1])
    assert end <= 0xFFFA, 'data runs into the vectors'

    a = Assembler(data)

    def wait_vblank():
        loop = a.label()
        a('BIT', 'abs', 0x2002)
        a('BPL', loop)

    def ppu_addr(addr):
        a('LDA', 'imm', addr >> 8)
        a('STA', 'abs', 0x2006)
        a('LDA', 'imm', addr & 0xFF)
        a('STA', 'abs', 0x2006)

    def set_ptr(zp, name):
        a('LDA', 'imm', ('<', name))
        a('STA', 'zp', zp)
        a('LDA', 'imm', ('>', name))
        a('STA', 'zp', zp + 1)

    # A loop over the pages first to first+count-1 in Q, loading each into
    # BUF_A and hashing it
    def hash_region(src, first, count, slot):
        a('JSR', 'abs', 'crc_init')
        a('LDA', 'imm', first)
        a('STA', 'zp', Q)
        loop = a.label()
        a('LDA', 'zp', Q)
        a('JSR', 'abs', 'ppu_read_page' if src == 'ppu' else 'cpu_read_page')
        a('JSR', 'abs', 'hash_buf')
        a('INC', 'zp', Q)
        a('LDA', 'zp', Q)
        a('CMP', 'imm', first + count)
        a('BNE', loop)
        a('LDX', 'imm', 7 * slot)
        a('JSR', 'abs', 'store_result')

    def store_best(dest):
        a('JSR', 'abs', 'find_best')
        for i, src in enumerate((BEST_SI, BEST_LO, BEST_HI)):
            a('LDA', 'zp', src)
            a('STA', 'zp', dest + i)

    # Power up: CPU RAM to CHR RAM 0x0000-0x07FF, before anything writes
    # RAM. Two vblanks for the PPU to take $2006 writes
    a.label('reset')
    a('SEI')
    a('CLD')
    a('LDA', 'imm', 0x00)
    a('STA', 'abs', 0x2000)
    a('STA', 'abs', 0x2001)
    wait_vblank()
    wait_vblank()
    a('LDA', 'imm', 0x00)
    a('STA', 'abs', 0x2006)
    a('STA', 'abs', 0x2006)
    for p in range(8):
        a('LDX', 'imm', 0x00)
        loop = a.label()
        a('LDA', 'absx', 0x100 * p)
        a('STA', 'abs', 0x2007)
        a('INX')
        a('BNE', loop)
    a('LDX', 'imm', 0xFF)
    a('TXS')

    # CHR RAM, before anything else is copied there
    hash_region('ppu', 0x08, 24, SLOT_CHR)

    # CIRAM to CHR RAM 0x1000, OAM to 0x1800, so that they can be shown
    # once the nametable is drawn
    a('LDA', 'imm', 0)
    a('STA', 'zp', Q)
    loop = a.label()
    a('LDA', 'zp', Q)
    a('CLC')
    a('ADC', 'imm', 0x20)
    a('JSR', 'abs', 'ppu_read_page')
    a('LDA', 'zp', Q)
    a('CLC')
    a('ADC', 'imm', 0x10)
    a('JSR', 'abs', 'ppu_write_page')
    a('INC', 'zp', Q)
    a('LDA', 'zp', Q)
    a('CMP', 'imm', 8)
    a('BNE', loop)

    # $2004 reads do not move the OAM address
    a('LDY', 'imm', 0)
    loop = a.label()
    a('STY', 'abs', 0x2003)
    a('LDA', 'abs', 0x2004)
    a('STA', 'absy', BUF_A)
    a('INY')
    a('BNE', loop)
    a('LDA', 'imm', 0x18)
    a('JSR', 'abs', 'ppu_write_page')

    hash_region('ppu', 0x00, 8, SLOT_CPU)
    hash_region('ppu', 0x10, 8, SLOT_CIRAM)
    hash_region('ppu', 0x18, 1, SLOT_OAM)
    hash_region('cpu', 0x60, 32, SLOT_PRG)

    # CIRAM page Q against CPU RAM around page Q, for every shift
    a('JSR', 'abs', 'clear_counts')
    a('LDA', 'imm', 0)
    a('STA', 'zp', Q)
    loop = a.label()
    a('LDA', 'zp', Q)
    a('CLC')
    a('ADC', 'imm', 0x10)
    a('JSR', 'abs', 'ppu_read_page')
    a('JSR', 'abs', 'load_window')
    a('JSR', 'abs', 'corr_page')
    a('INC', 'zp', Q)
    a('LDA', 'zp', Q)
    a('CMP', 'imm', 8)
    a('BNE', loop)
    store_best(CORR_CIRAM)

    # OAM against the last page of CPU RAM
    a('JSR', 'abs', 'clear_counts')
    a('LDA', 'imm', 0x18)
    a('JSR', 'abs', 'ppu_read_page')
    a('LDA', 'imm', 7)
    a('STA', 'zp', Q)
    a('JSR', 'abs', 'load_window')
    a('JSR', 'abs', 'corr_page')
    store_best(CORR_OAM)

    # The font, the tiles $80-$BF
    for p in range(4):
        ppu_addr(0x0800 + 0x100 * p)
        a('LDY', 'imm', 0)
        loop = a.label()
        a('LDA', 'absy', data['font'] + 0x100 * p)
        a('STA', 'abs', 0x2007)
        a('INY')
        a('BNE', loop)

    ppu_addr(0x3F00)
    a('LDX', 'imm', 0)
    loop = a.label()
    a('LDA', 'absx', 'palette')
    a('STA', 'abs', 0x2007)
    a('INX')
    a('CPX', 'imm', 32)
    a('BNE', loop)

    a('LDA', 'imm', 0)
    a('STA', 'zp', PAGE)
    a('STA', 'zp', PREV)
    a('JSR', 'abs', 'draw')

    # Buttons, read in the order A, B, select, start, up, down, left,
    # right, so right is bit 0
    a.label('main')
    wait_vblank()
    a('LDA', 'imm', 1)
    a('STA', 'abs', 0x4016)
    a('LDA', 'imm', 0)
    a('STA', 'abs', 0x4016)
    a('LDX', 'imm', 8)
    loop = a.label()
    a('LDA', 'abs', 0x4016)
    a('LSR')
    a('ROL', 'zp', BUTTONS)
    a('DEX')
    a('BNE', loop)
    a('LDA', 'zp', PREV)
    a('EOR', 'imm', 0xFF)
    a('AND', 'zp', BUTTONS)
    a('STA', 'zp', NEW)
    a('LDA', 'zp', BUTTONS)
    a('STA', 'zp', PREV)

    a('LDA', 'zp', NEW)
    a('AND', 'imm', BTN_START_SELECT)
    a('BEQ', 'not_summary')
    a('LDA', 'imm', 0)
    a('JMP', 'abs', 'new_page')
    a.label('not_summary')
    a('LDA', 'zp', NEW)
    a('AND', 'imm', BTN_RIGHT)
    a('BEQ', 'not_right')
    a('LDA', 'zp', PAGE)
    a('CLC')
    a('ADC', 'imm', 1)
    a('JMP', 'abs', 'wrap_up')
    a.label('not_right')
    a('LDA', 'zp', NEW)
    a('AND', 'imm', BTN_DOWN)
    a('BEQ', 'not_down')
    a('LDA', 'zp', PAGE)
    a('CLC')
    a('ADC', 'imm', 8)
    a.label('wrap_up')
    a('CMP', 'imm', NUM_SCREENS)
    a('BCC', 'new_page')
    a('SBC', 'imm', NUM_SCREENS)
    a('JMP', 'abs', 'new_page')
    a.label('not_down')
    a('LDA', 'zp', NEW)
    a('AND', 'imm', BTN_LEFT)
    a('BEQ', 'not_left')
    a('LDA', 'zp', PAGE)
    a('SEC')
    a('SBC', 'imm', 1)
    a('JMP', 'abs', 'wrap_down')
    a.label('not_left')
    a('LDA', 'zp', NEW)
    a('AND', 'imm', BTN_UP)
    a('BEQ', 'main_next')
    a('LDA', 'zp', PAGE)
    a('SEC')
    a('SBC', 'imm', 8)
    a.label('wrap_down')
    a('BCS', 'new_page')
    a('ADC', 'imm', NUM_SCREENS)
    a.label('new_page')
    a('STA', 'zp', PAGE)
    a('JSR', 'abs', 'draw')
    a.label('main_next')
    a('JMP', 'abs', 'main')

    # Draws screen PAGE with rendering off
    a.label('draw')
    wait_vblank()
    a('LDA', 'imm', 0x00)
    a('STA', 'abs', 0x2001)
    ppu_addr(0x2000)
    a('LDA', 'imm', SPACE)
    a('LDY', 'imm', 4)
    a('LDX', 'imm', 0)
    loop = a.label()
    a('STA', 'abs', 0x2007)
    a('INX')
    a('BNE', loop)
    a('DEY')
    a('BNE', loop)
    ppu_addr(0x23C0)
    a('LDX', 'imm', 0)
    a('LDA', 'zp', PAGE)
    a('BEQ', 'attr_summary')
    loop = a.label()
    a('LDA', 'absx', 'attr_hex')
    a('STA', 'abs', 0x2007)
    a('INX')
    a('CPX', 'imm', 64)
    a('BNE', loop)
    a('JMP', 'abs', 'draw_hex')
    a.label('attr_summary')
    a('LDA', 'imm', 0)
    loop = a.label()
    a('STA', 'abs', 0x2007)
    a('INX')
    a('CPX', 'imm', 64)
    a('BNE', loop)

    set_ptr(PTR2, 'summary_text')
    a('JSR', 'abs', 'print_list')
    for r in range(8):
        ppu_addr(nt_addr(4 + r, 8))
        a('LDX', 'imm', 16 * r)
        loop = a.label()
        a('STX', 'abs', 0x2007)
        a('INX')
        a('CPX', 'imm', 16 * r + 16)
        a('BNE', loop)
    for slot in range(len(REGIONS)):
        ppu_addr(nt_addr(SUMMARY_ROW + slot, 10))
        for b in (3, 2, 1, 0):
            a('LDA', 'zp', RES + 7 * slot + b)
            a('JSR', 'abs', 'print_hex')
        ppu_addr(nt_addr(SUMMARY_ROW + slot, 19))
        for b in range(3):
            a('LDA', 'zp', RES + 7 * slot + 4 + b)
            a('STA', 'zp', NUM + b)
        a('JSR', 'abs', 'print_dec5')
    for i, corr in enumerate((CORR_CIRAM, CORR_OAM)):
        ppu_addr(nt_addr(CORR_ROW + i, 19))
        a('LDA', 'zp', corr)
        a('JSR', 'abs', 'print_shift')
        ppu_addr(nt_addr(CORR_ROW + i, 22))
        a('LDA', 'zp', corr + 1)
        a('STA', 'zp', NUM)
        a('LDA', 'zp', corr + 2)
        a('STA', 'zp', NUM + 1)
        a('LDA', 'imm', 0)
        a('STA', 'zp', NUM + 2)
        a('JSR', 'abs', 'print_dec5')
    a('JMP', 'abs', 'draw_done')

    a.label('draw_hex')
    a('LDX', 'zp', PAGE)
    a('DEX')
    a('LDA', 'absx', 'pg_title_lo')
    a('STA', 'zp', PTR2)
    a('LDA', 'absx', 'pg_title_hi')
    a('STA', 'zp', PTR2 + 1)
    a('JSR', 'abs', 'print_list')
    set_ptr(PTR2, 'hex_text')
    a('JSR', 'abs', 'print_list')
    a('LDX', 'zp', PAGE)
    a('DEX')
    a('LDA', 'absx', 'pg_hi')
    a('LDY', 'absx', 'pg_type')
    a('BNE', 'hex_cpu')
    a('JSR', 'abs', 'ppu_read_page')
    a('JMP', 'abs', 'hex_loaded')
    a.label('hex_cpu')
    a('JSR', 'abs', 'cpu_read_page')
    a.label('hex_loaded')
    a('LDA', 'imm', nt_addr(HEX_ROW, 0) & 0xFF)
    a('STA', 'zp', ALO)
    a('LDA', 'imm', nt_addr(HEX_ROW, 0) >> 8)
    a('STA', 'zp', AHI)
    a('LDY', 'imm', 0)
    row = a.label()
    a('LDA', 'zp', AHI)
    a('STA', 'abs', 0x2006)
    a('LDA', 'zp', ALO)
    a('STA', 'abs', 0x2006)
    col = a.label()
    a('LDA', 'absy', BUF_A)
    a('JSR', 'abs', 'print_hex')
    a('INY')
    a('TYA')
    a('AND', 'imm', 0x0F)
    a('BNE', col)
    a('LDA', 'zp', ALO)
    a('CLC')
    a('ADC', 'imm', 32)
    a('STA', 'zp', ALO)
    skip = a.new_label()
    a('BCC', skip)
    a('INC', 'zp', AHI)
    a.label(skip)
    a('CPY', 'imm', 0)
    a('BNE', row)

    a.label('draw_done')
    wait_vblank()
    a('LDA', 'imm', 0)
    a('STA', 'abs', 0x2005)
    a('STA', 'abs', 0x2005)
    a('STA', 'abs', 0x2000)
    a('LDA', 'imm', 0x0A)                   # background, left 8 pixels
    a('STA', 'abs', 0x2001)
    a('RTS')

    # 256 bytes from PPU address A*256 to BUF_A
    a.label('ppu_read_page')
    a('STA', 'abs', 0x2006)
    a('LDA', 'imm', 0)
    a('STA', 'abs', 0x2006)
    a('LDA', 'abs', 0x2007)                 # the read buffer
    a('LDY', 'imm', 0)
    loop = a.label()
    a('LDA', 'abs', 0x2007)
    a('STA', 'absy', BUF_A)
    a('INY')
    a('BNE', loop)
    a('RTS')

    # BUF_A to PPU address A*256
    a.label('ppu_write_page')
    a('STA', 'abs', 0x2006)
    a('LDA', 'imm', 0)
    a('STA', 'abs', 0x2006)
    a('LDY', 'imm', 0)
    loop = a.label()
    a('LDA', 'absy', BUF_A)
    a('STA', 'abs', 0x2007)
    a('INY')
    a('BNE', loop)
    a('RTS')

    # 256 bytes from CPU address A*256 to BUF_A
    a.label('cpu_read_page')
    a('STA', 'zp', PTR2 + 1)
    a('LDA', 'imm', 0)
    a('STA', 'zp', PTR2)
    a('LDY', 'imm', 0)
    loop = a.label()
    a('LDA', 'indy', PTR2)
    a('STA', 'absy', BUF_A)
    a('INY')
    a('BNE', loop)
    a('RTS')

    # BUF_B = CPU RAM page Q with the 8 bytes either side, wrapping within
    # the 2KB, from its copy in CHR RAM
    a.label('load_window')
    for hi, lo, count, dest in (('prev', 0xF8, 8, BUF_B),
                                ('this', 0x00, 0, BUF_B + 8),
                                ('next', 0x00, 8, BUF_B + 264)):
        a('LDA', 'zp', Q)
        if hi == 'prev':
            a('SEC')
            a('SBC', 'imm', 1)
        elif hi == 'next':
            a('CLC')
            a('ADC', 'imm', 1)
        a('AND', 'imm', 0x07)
        a('STA', 'abs', 0x2006)
        a('LDA', 'imm', lo)
        a('STA', 'abs', 0x2006)
        a('LDA', 'abs', 0x2007)
        a('LDY', 'imm', 0)
        loop = a.label()
        a('LDA', 'abs', 0x2007)
        a('STA', 'absy', dest)
        a('INY')
        a('CPY', 'imm', count)
        a('BNE', loop)
    a('RTS')

    a.label('clear_counts')
    a('LDA', 'imm', 0)
    a('LDX', 'imm', 0)
    loop = a.label()
    a('STA', 'zpx', CNT_LO)
    a('INX')
    a('CPX', 'imm', 2 * SHIFTS)
    a('BNE', loop)
    a('RTS')

    # For each shift index X (shift X-8), counts Y where
    # BUF_A[Y] = BUF_B[X+Y]
    a.label('corr_page')
    a('LDX', 'imm', 0)
    shift = a.label()
    a('TXA')
    a('CLC')
    a('ADC', 'imm', BUF_B & 0xFF)
    a('STA', 'zp', PTR)
    a('LDA', 'imm', BUF_B >> 8)
    a('ADC', 'imm', 0)
    a('STA', 'zp', PTR + 1)
    a('LDY', 'imm', 0)
    loop = a.label()
    a('LDA', 'absy', BUF_A)
    a('CMP', 'indy', PTR)
    skip = a.new_label()
    a('BNE', skip)
    a('INC', 'zpx', CNT_LO)
    a('BNE', skip)
    a('INC', 'zpx', CNT_HI)
    a.label(skip)
    a('INY')
    a('BNE', loop)
    a('INX')
    a('CPX', 'imm', SHIFTS)
    a('BNE', shift)
    a('RTS')

    # The first shift with the most matches
    a.label('find_best')
    a('LDA', 'zp', CNT_LO)
    a('STA', 'zp', BEST_LO)
    a('LDA', 'zp', CNT_HI)
    a('STA', 'zp', BEST_HI)
    a('LDX', 'imm', 0)
    a('STX', 'zp', BEST_SI)
    nxt = a.label()
    a('INX')
    a('CPX', 'imm', SHIFTS)
    a('BEQ', 'find_best_done')
    a('LDA', 'zpx', CNT_HI)
    a('CMP', 'zp', BEST_HI)
    a('BCC', nxt)
    better = a.new_label()
    a('BNE', better)
    a('LDA', 'zpx', CNT_LO)
    a('CMP', 'zp', BEST_LO)
    a('BCC', nxt)
    a('BEQ', nxt)
    a.label(better)
    a('LDA', 'zpx', CNT_LO)
    a('STA', 'zp', BEST_LO)
    a('LDA', 'zpx', CNT_HI)
    a('STA', 'zp', BEST_HI)
    a('STX', 'zp', BEST_SI)
    a('JMP', 'abs', nxt)
    a.label('find_best_done')
    a('RTS')

    a.label('crc_init')
    a('LDA', 'imm', 0xFF)
    for b in range(4):
        a('STA', 'zp', CRC + b)
    a('LDA', 'imm', 0)
    for b in range(3):
        a('STA', 'zp', ONES + b)
    a('RTS')

    # The CRC and ones of a region to RES+X
    a.label('store_result')
    for b in range(4):
        a('LDA', 'zp', CRC + b)
        a('EOR', 'imm', 0xFF)
        a('STA', 'zpx', RES + b)
    for b in range(3):
        a('LDA', 'zp', ONES + b)
        a('STA', 'zpx', RES + 4 + b)
    a('RTS')

    # BUF_A into the CRC and the count of ones
    a.label('hash_buf')
    a('LDY', 'imm', 0)
    loop = a.label()
    a('LDA', 'absy', BUF_A)
    a('TAX')
    a('LDA', 'absx', 'pop')
    a('CLC')
    a('ADC', 'zp', ONES)
    a('STA', 'zp', ONES)
    skip = a.new_label()
    a('BCC', skip)
    a('INC', 'zp', ONES + 1)
    a('BNE', skip)
    a('INC', 'zp', ONES + 2)
    a.label(skip)
    a('TXA')
    a('EOR', 'zp', CRC)
    a('TAX')
    for b in range(3):
        a('LDA', 'zp', CRC + b + 1)
        a('EOR', 'absx', 'crc_t%d' % b)
        a('STA', 'zp', CRC + b)
    a('LDA', 'absx', 'crc_t3')
    a('STA', 'zp', CRC + 3)
    a('INY')
    a('BNE', loop)
    a('RTS')

    # Prints the records at PTR2
    a.label('print_list')
    rec = a.label()
    a('LDY', 'imm', 0)
    a('LDA', 'indy', PTR2)
    a('CMP', 'imm', 0xFF)
    a('BEQ', 'print_list_done')
    a('STA', 'abs', 0x2006)
    a('INY')
    a('LDA', 'indy', PTR2)
    a('STA', 'abs', 0x2006)
    a('INY')
    ch = a.label()
    a('LDA', 'indy', PTR2)
    end_rec = a.new_label()
    a('BEQ', end_rec)
    a('STA', 'abs', 0x2007)
    a('INY')
    a('JMP', 'abs', ch)
    a.label(end_rec)
    a('INY')
    a('TYA')
    a('CLC')
    a('ADC', 'zp', PTR2)
    a('STA', 'zp', PTR2)
    a('BCC', rec)
    a('INC', 'zp', PTR2 + 1)
    a('JMP', 'abs', rec)
    a.label('print_list_done')
    a('RTS')

    # A as two hex digits. Keeps Y
    a.label('print_hex')
    a('PHA')
    for _ in range(4):
        a('LSR')
    a('TAX')
    a('LDA', 'absx', 'hex_tiles')
    a('STA', 'abs', 0x2007)
    a('PLA')
    a('AND', 'imm', 0x0F)
    a('TAX')
    a('LDA', 'absx', 'hex_tiles')
    a('STA', 'abs', 0x2007)
    a('RTS')

    # NUM (below 100000) as 5 decimal digits, leading zeroes as spaces
    a.label('print_dec5')
    a('LDA', 'imm', 0)
    a('STA', 'zp', LEAD)
    a('LDX', 'imm', 0)
    digit = a.label()
    a('LDY', 'imm', 0)
    sub = a.label()
    a('SEC')
    a('LDA', 'zp', NUM)
    a('SBC', 'absx', 'pow_lo')
    a('STA', 'zp', T0)
    a('LDA', 'zp', NUM + 1)
    a('SBC', 'absx', 'pow_hi')
    a('STA', 'zp', T1)
    a('LDA', 'zp', NUM + 2)
    a('SBC', 'imm', 0)
    done = a.new_label()
    a('BCC', done)
    a('STA', 'zp', NUM + 2)
    a('LDA', 'zp', T1)
    a('STA', 'zp', NUM + 1)
    a('LDA', 'zp', T0)
    a('STA', 'zp', NUM)
    a('INY')
    a('JMP', 'abs', sub)
    a.label(done)
    nonzero = a.new_label()
    out = a.new_label()
    a('TYA')
    a('BNE', nonzero)
    a('LDA', 'zp', LEAD)
    a('BNE', nonzero)
    a('CPX', 'imm', 4)
    a('BEQ', nonzero)
    a('LDA', 'imm', SPACE)
    a('JMP', 'abs', out)
    a.label(nonzero)
    a('LDA', 'imm', 1)
    a('STA', 'zp', LEAD)
    a('TYA')
    a('CLC')
    a('ADC', 'imm', DIGIT0)
    a.label(out)
    a('STA', 'abs', 0x2007)
    a('INX')
    a('CPX', 'imm', 5)
    a('BNE', digit)
    a('RTS')

    # Shift index A as the shift, a sign and a digit
    a.label('print_shift')
    a('SEC')
    a('SBC', 'imm', 8)
    pos = a.new_label()
    a('BCS', pos)
    a('EOR', 'imm', 0xFF)
    a('CLC')
    a('ADC', 'imm', 1)
    a('TAX')
    a('LDA', 'imm', MINUS)
    sign = a.new_label()
    a('JMP', 'abs', sign)
    a.label(pos)
    a('TAX')
    a('LDA', 'imm', PLUS)
    a.label(sign)
    a('STA', 'abs', 0x2007)
    a('TXA')
    a('CLC')
    a('ADC', 'imm', DIGIT0)
    a('STA', 'abs', 0x2007)
    a('RTS')

    a.label('rti')
    a('RTI')

    code = a.link()
    assert ORG + len(code) <= DATA, 'code runs into the data'

    prg = bytearray([0xFF]) * 0x8000
    prg[:len(code)] = code
    for addr, blob in blobs:
        prg[addr - ORG:addr - ORG + len(blob)] = blob
    for vec, name in ((0xFFFA, 'rti'), (0xFFFC, 'reset'), (0xFFFE, 'rti')):
        prg[vec - ORG] = a.labels[name] & 0xFF
        prg[vec - ORG + 1] = a.labels[name] >> 8

    # NES 2.0 mapper 0, vertical, 32KB PRG ROM, 8KB PRG RAM, 8KB CHR RAM
    header = bytearray(b'NES\x1a') + bytes([2, 0, 0x01, 0x08]) + bytes(8)
    header[10] = 0x07
    header[11] = 0x07

    return bytes(header + prg)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build())


if __name__ == '__main__':
    main()
