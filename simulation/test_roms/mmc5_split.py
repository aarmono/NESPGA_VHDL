#!/usr/bin/env python3
"""Generate a test ROM for the vertical split of the Nintendo MMC5 (mapper 5).

Usage: mmc5_split.py OUT.nes [continue]

Each check is a probe of one pixel with sprite 0: the sprite's only opaque
pixel is its top left, so the sprite 0 hit flag, read in the vblank after
the frame, tells whether the background is opaque at that pixel. The
background outside the split is transparent unless extended attributes
pick a solid tile, and the split region is drawn from the tiles of the
ExRAM layout, so the hits show where the split region is and which ExRAM
row and column it reads. The expected hits come from a model of the
nesdev description, run alongside the generation:

- Tiles are counted from the first fetched for the scanline, so the split
  threshold is a fixed number of fetched tiles from the left of the screen
  (it moves with the fine horizontal scroll only) and the split region
  reads ExRAM column N for the Nth tile fetched. Left: tiles 0 to T-1,
  right: T and on
- The ExRAM row is (0x5201 + scanline) / 8, where the sum wraps from 239
  to 0, or from 255 to 0 when 0x5201 is 240 or more, so the attribute rows
  are read as tiles
- The PPU gives the row within the pattern (CHR A0-A2), as on the
  Nintendo boards, which are wired in "CL" mode
- 0x5202 is the 4KB CHR bank of the split region
- The split is only made in ExRAM modes 0 and 1, and in mode 1 only the
  tiles outside the split region get extended attributes

All pass in nes_bench. Mesen fails groups 13-18 and 21-22: from tile 3 on
it draws the split region's rows one scanline early (tiles 0-2 are where
the model puts them, and Nestopia also adds the scanline to 0x5201 as the
model does), it makes the pattern row from 0x5201, as "SL" mode boards
would (15), and it wraps 0x5201 values of 240 or more at 240 (21-22).
Outside the split region the pass screen matches Mesen, and inside it
matches Mesen's one scanline later.

The result is shown with rendering off as the backdrop color, the number
of the group that failed (see GROUP_COLORS), with the index of the failing
probe of the group at zero page DETAIL. On a pass a split screen is shown
with backdrop color $2A (green): tiles in four palettes in the split region
on the left, vertically scrolled by three tiles, and stripes on the right.
The result is up after about 120 frames, so 2400ms of nes_bench is enough.

With "continue" the ROM does not stop at a failure but sets the byte of
the failing probe in FAILS, for an emulator whose RAM can be read; the
probes are numbered from 0 through all the groups in order.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes, with the assembler of mmc5.py.
"""

import sys

from mmc5 import (Assembler, ORG, LDA_IMM, LDA_ABS, STA_ABS, LDX_IMM,
                  LDY_IMM, BIT_ABS, STA_ZP, STX_ZP, STA_IND_Y, LDA_ABS_X,
                  BPL, BNE, JMP_ABS, JSR, RTS, RTI, SEI, CLD, TXS, DEX)

PASS_COLOR = 0x2A

# The backdrop color for a failure of each group, leaving out the blacks
# and the pass color
GROUP_COLORS = [c for c in range(0x40)
                if (c & 0x0F) <= 0x0C and c not in (PASS_COLOR, 0x30)]

PRG_BANKS = 4
CHR_BANKS_4KB = 8

# 4KB CHR banks
BANK_BLANK = 0
BANK_SPRITE = 1
BANK_SPLIT = 2
BANK_SPLIT_BLANK = 3
BANK_EXT = 4
BANK_STRIPES = 5

# Tiles of BANK_SPLIT
TILE_SOLID = 0x01
TILE_EMPTY = 0x04
TILE_ROW = 0x10                                 # + row: only that row opaque
TILE_VISUAL = 0x20                              # 4 tiles for the pass screen

# Zero page
PTR = 0x00
DETAIL = 0x02
GROUP = 0x03
# One byte per probe, set on a failure, for "continue"
FAILS = 0x0300

CMP_ABS_X, AND_IMM, TAX, INY, STA_ABS_X = 0xDD, 0x29, 0xAA, 0xC8, 0x9D


def tile_rows(rows):
    """The 16 bytes of a tile from 8 rows of 8 colors (0-3)"""
    lo = bytearray(8)
    hi = bytearray(8)
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            lo[y] |= (c & 1) << (7 - x)
            hi[y] |= (c >> 1) << (7 - x)
    return bytes(lo + hi)


def solid(c):
    return tile_rows([[c] * 8] * 8)


def make_chr():
    banks = [bytearray(0x1000) for _ in range(CHR_BANKS_4KB)]

    def put(bank, tile, data):
        banks[bank][tile * 16:tile * 16 + 16] = data

    dot = [[0] * 8 for _ in range(8)]
    dot[0][0] = 1
    put(BANK_SPRITE, 0, tile_rows(dot))

    put(BANK_SPLIT, TILE_SOLID, solid(1))
    for r in range(8):
        rows = [[0] * 8 for _ in range(8)]
        rows[r] = [1] * 8
        put(BANK_SPLIT, TILE_ROW + r, tile_rows(rows))
    # A color with a border of another, so the tile edges show
    for i, (fill, border) in enumerate([(1, 3), (2, 1), (3, 2), (1, 2)]):
        rows = [[border] * 8] + [[border] + [fill] * 6 + [border]
                                 for _ in range(6)] + [[border] * 8]
        put(BANK_SPLIT, TILE_VISUAL + i, tile_rows(rows))

    put(BANK_EXT, 0, solid(1))

    put(BANK_STRIPES, 0,
        tile_rows([[2 if (x + y) % 4 < 2 else 0 for x in range(8)]
                   for y in range(8)]))

    return b''.join(banks)


def pixel(chr_rom, bank, tile, row, col):
    """The color of a pixel of a tile"""
    off = (bank % CHR_BANKS_4KB) * 0x1000 + tile * 16
    lo = chr_rom[off + row] >> (7 - col) & 1
    hi = chr_rom[off + 8 + row] >> (7 - col) & 1
    return lo | hi << 1


# ExRAM layouts: a list of (start, count, value) fills over all zero
def layout_rows(rows, value):
    return [(r * 32, 32, value) for r in rows]


def layout_cols(cols, value):
    return [(r * 32 + c, 1, value) for r in range(32) for c in cols]


ALL_SOLID = [(0, 960, TILE_SOLID)]
ROW_5 = layout_rows([5], TILE_SOLID)
ROW_0 = layout_rows([0], TILE_SOLID)
ROW_31 = layout_rows([31], TILE_SOLID)
ROW_5_LINE_0 = layout_rows([5], TILE_ROW + 0)
COLS = layout_cols([0, 1, 10], TILE_SOLID)
# The left half is split tiles, the right half extended attributes that
# select the solid tile 0 of BANK_EXT
EXT_HALVES = ([(r * 32, 16, TILE_SOLID) for r in range(30)] +
              [(r * 32 + 16, 16, BANK_EXT) for r in range(30)])


def split_reg(enable=True, right=False, threshold=0):
    return (0x80 if enable else 0) | (0x40 if right else 0) | threshold


class Config:
    def __init__(self, split, scroll=0, bank=BANK_SPLIT, mode=0, sx=0, sy=0):
        self.split = split
        self.scroll = scroll
        self.bank = bank
        self.mode = mode
        self.sx = sx
        self.sy = sy


def split_y(scroll, line):
    total = scroll + line
    if scroll < 240 and total >= 240:
        total -= 240
    return total % 256


def model_hit(chr_rom, exram, cfg, x, y):
    """Whether the background is opaque at pixel (x, y)"""
    fine_x = cfg.sx & 7
    col = (x + fine_x) // 8
    px = (x + fine_x) & 7
    fine_y = (cfg.sy + y) & 7
    enable = cfg.split & 0x80
    right = cfg.split & 0x40
    threshold = cfg.split & 0x1F
    if enable and cfg.mode <= 1 and (col >= threshold) == bool(right):
        row = split_y(cfg.scroll, y) // 8
        tile = exram[row * 32 + col % 32]
        return pixel(chr_rom, cfg.bank, tile, fine_y, px) != 0
    if cfg.mode == 1:
        nt_row = ((cfg.sy + y) // 8) % 30
        nt_col = (cfg.sx // 8 + col) % 32
        bank = exram[nt_row * 32 + nt_col] & 0x3F
        return pixel(chr_rom, bank, 0, fine_y, px) != 0
    return pixel(chr_rom, BANK_BLANK, 0, fine_y, px) != 0


# Each group is an ExRAM layout, a configuration, and the pixels probed. The
# expected hits are from the model; those given are checked against it
L, R = False, True
GROUPS = [
    # 1-4: where the split region is, left and right, from the threshold
    (ALL_SOLID, Config(split_reg(right=L, threshold=10)),
     [(79, 50, True), (80, 50, False), (2, 50, True), (12, 9, True),
      (20, 100, True), (200, 200, False)]),
    (ALL_SOLID, Config(split_reg(right=R, threshold=20)),
     [(159, 50, False), (160, 50, True), (254, 50, True), (2, 50, False)]),
    (ALL_SOLID, Config(split_reg(right=L, threshold=0)),
     [(2, 50, False), (128, 50, False)]),
    (ALL_SOLID, Config(split_reg(right=R, threshold=0)),
     [(2, 50, True), (200, 200, True)]),
    # 5-7: the threshold moves with the fine horizontal scroll only
    (ALL_SOLID, Config(split_reg(right=L, threshold=10), sx=3),
     [(76, 50, True), (77, 50, False)]),
    (ALL_SOLID, Config(split_reg(right=R, threshold=20), sx=3),
     [(156, 50, False), (157, 50, True)]),
    (ALL_SOLID, Config(split_reg(right=L, threshold=10), sx=21),
     [(74, 50, True), (75, 50, False)]),
    # 8-12: no split when disabled, in ExRAM modes 2 and 3, and the bank
    (ALL_SOLID, Config(split_reg(enable=False, threshold=10)),
     [(2, 50, False)]),
    (ALL_SOLID, Config(split_reg(right=R), mode=2),
     [(2, 50, False), (128, 50, False)]),
    (ALL_SOLID, Config(split_reg(right=R), mode=3),
     [(2, 50, False)]),
    (ALL_SOLID, Config(split_reg(right=R), bank=BANK_SPLIT_BLANK),
     [(2, 50, False), (128, 50, False)]),
    (ALL_SOLID, Config(split_reg(right=L, threshold=31)),
     [(247, 50, True), (248, 50, False)]),
    # 13-14: the ExRAM row from 0x5201, and the PPU's vertical scroll
    # ignored
    (ROW_5, Config(split_reg(right=R), scroll=16),
     [(100, 23, False), (100, 24, True), (100, 31, True), (100, 32, False)]),
    (ROW_5, Config(split_reg(right=R), scroll=16, sy=24),
     [(100, 23, False), (100, 24, True), (100, 32, False)]),
    # 15: CL mode, the PPU's row of the pattern: row 0 of the tile is drawn
    # where the PPU's fine scroll is 0, not where that of 0x5201 is
    (ROW_5_LINE_0, Config(split_reg(right=R), scroll=4),
     [(100, 36, False), (100, 40, True), (100, 41, False)]),
    # 16: tiles 0-2 are fetched before the scanline is detected, but are
    # in the row of their scanline
    (ROW_5, Config(split_reg(right=R)),
     [(2, 39, False), (2, 40, True), (2, 47, True), (2, 48, False),
      (10, 40, True), (10, 48, False), (18, 40, True), (18, 48, False),
      (100, 39, False), (100, 40, True), (100, 47, True), (100, 48, False)]),
    # 17: the fine scroll of 0x5201 matching the PPU's
    (ROW_5_LINE_0, Config(split_reg(right=R), scroll=4, sy=4),
     [(100, 36, True), (100, 40, False)]),
    # 18: the sum of 0x5201 and the scanline wraps at 240
    (ROW_5, Config(split_reg(right=R), scroll=200),
     [(100, 79, False), (100, 80, True), (100, 87, True), (100, 88, False)]),
    # 19-20: ExRAM columns are not scrolled, and line up with the tiles
    # fetched
    (COLS, Config(split_reg(right=L, threshold=16), sx=16),
     [(2, 50, True), (10, 50, True), (16, 50, False), (64, 50, False),
      (79, 50, False), (80, 50, True), (87, 50, True), (88, 50, False)]),
    (COLS, Config(split_reg(right=L, threshold=16), sx=19),
     [(2, 50, True), (13, 50, False), (76, 50, False), (77, 50, True),
      (84, 50, True), (85, 50, False)]),
    # 21-22: 0x5201 of 240 or more reads the attribute rows as tiles, then
    # wraps to row 0
    (ROW_31, Config(split_reg(right=R), scroll=248),
     [(100, 4, True), (100, 8, False)]),
    (ROW_0, Config(split_reg(right=R), scroll=248),
     [(100, 7, False), (100, 8, True), (100, 15, True), (100, 16, False)]),
    # 23-26: extended attributes outside the split region only
    (EXT_HALVES, Config(split_reg(right=L, threshold=16), mode=1),
     [(30, 50, True), (200, 50, True)]),
    (EXT_HALVES, Config(split_reg(right=L, threshold=16), mode=0),
     [(30, 50, True), (200, 50, False)]),
    (EXT_HALVES, Config(split_reg(enable=False, threshold=16), mode=1),
     [(30, 50, False), (200, 50, True)]),
    (EXT_HALVES, Config(split_reg(right=R, threshold=16), mode=1),
     [(30, 50, False), (200, 50, False)]),
]

# The pass screen
VISUAL_SPLIT = split_reg(right=L, threshold=12)
VISUAL_SCROLL = 24
VISUAL_SX = 4
VISUAL_LAYOUT = ([(r * 32, 32, TILE_VISUAL + r % 4) for r in range(30)] +
                 [(0x3C0, 64, 0xE4)])
PALETTES = [PASS_COLOR, 0x16, 0x27, 0x18,
            PASS_COLOR, 0x11, 0x21, 0x31,
            PASS_COLOR, 0x14, 0x24, 0x34,
            PASS_COLOR, 0x19, 0x29, 0x39,
            PASS_COLOR, 0x30, 0x30, 0x30] + [PASS_COLOR, 0x30, 0x30, 0x30] * 3


def exram_of(layout):
    exram = bytearray(1024)
    for start, count, value in layout:
        exram[start:start + count] = bytes([value]) * count
    return exram


def build(keep_going=False):
    chr_rom = make_chr()
    assert len(GROUPS) <= len(GROUP_COLORS)

    # The probes, one row of each table per pixel
    tables = {k: [] for k in ('grp', 'idx', 'mode', 'split', 'scroll', 'bank',
                              'sx', 'sy', 'oy', 'ox', 'hit')}
    for g, (layout, cfg, points) in enumerate(GROUPS):
        exram = exram_of(layout)
        for i, (x, y, given) in enumerate(points):
            assert 1 <= y < 240 and x < 255
            hit = model_hit(chr_rom, exram, cfg, x, y)
            assert hit == given, (g + 1, i, x, y, hit)
            for k, v in (('grp', g), ('idx', i), ('mode', cfg.mode),
                         ('split', cfg.split), ('scroll', cfg.scroll),
                         ('bank', cfg.bank), ('sx', cfg.sx), ('sy', cfg.sy),
                         ('oy', y - 1), ('ox', x),
                         ('hit', 0x40 if hit else 0x00)):
                tables[k].append(v)
    assert len(tables['grp']) <= 256

    a = Assembler()

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    # The flag may have been set long ago, so it is cleared first
    def wait_vblank(name):
        a.abs(BIT_ABS, 0x2002)
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def ppu_addr(addr):
        write(0x2006, addr >> 8)
        write(0x2006, addr & 0xFF)

    # Fills ExRAM with a layout, in ExRAM mode 2
    def load_layout(layout):
        write(0x5104, 0x02)
        a.emit(LDA_IMM, 0x00)
        for page in range(4):
            fill_call(0x5C00 + 0x100 * page, 0x100)
        for start, count, value in layout:
            a.emit(LDA_IMM, value)
            fill_call(0x5C00 + start, count)

    def fill_call(addr, count):
        while count > 0:
            part = min(count, 0x100)
            a.emit(LDX_IMM, addr & 0xFF)
            a.emit(STX_ZP, PTR)
            a.emit(LDX_IMM, addr >> 8)
            a.emit(STX_ZP, PTR + 1)
            a.emit(LDX_IMM, part & 0xFF)
            a.abs_label(JSR, 'fill')
            addr += part
            count -= part

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    write(0x2000, 0x00)
    write(0x2001, 0x00)
    write(0x4010, 0x00)
    write(0x4015, 0x00)
    write(0x4017, 0x40)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    write(0x5101, 0x01)                         # 4KB CHR banks
    write(0x5130, 0x00)
    write(0x5123, BANK_BLANK)
    write(0x5127, BANK_SPRITE)
    write(0x5105, 0x00)                         # all CIRAM page 0

    ppu_addr(0x3F00)
    for c in PALETTES:
        write(0x2007, c)
    ppu_addr(0x3F00)
    write(0x2007, 0x0F)                         # black backdrop while probing
    ppu_addr(0x2000)
    a.emit(LDA_IMM, 0x00)
    for i in range(4):
        a.emit(LDX_IMM, 0x00)
        a.label('ciram_%d' % i)
        a.abs(STA_ABS, 0x2007)
        a.emit(DEX)
        a.branch(BNE, 'ciram_%d' % i)

    if keep_going:
        a.emit(LDA_IMM, 0x00)
        a.emit(LDX_IMM, 0x00)
        a.label('clear_fails')
        a.abs(STA_ABS_X, FAILS)
        a.emit(DEX)
        a.branch(BNE, 'clear_fails')

    # Every sprite but 0 below the screen
    write(0x2003, 0x00)
    a.emit(LDA_IMM, 0xFF)
    a.emit(LDX_IMM, 0x00)
    a.label('oam')
    a.abs(STA_ABS, 0x2004)
    a.emit(DEX)
    a.branch(BNE, 'oam')

    probe = 0
    for g, (layout, cfg, points) in enumerate(GROUPS):
        if g == 0 or layout is not GROUPS[g - 1][0]:
            write(0x2001, 0x00)
            load_layout(layout)
            wait_vblank('layout_%d' % g)
        for _ in points:
            a.emit(LDX_IMM, probe)
            a.abs_label(JSR, 'probe')
            probe += 1

    # Pass: the split screen
    write(0x2001, 0x00)
    write(0x2003, 0x00)
    write(0x2004, 0xFF)
    load_layout(VISUAL_LAYOUT)
    write(0x5123, BANK_STRIPES)
    ppu_addr(0x3F00)
    write(0x2007, PASS_COLOR)
    wait_vblank('vblank_3')
    write(0x5104, 0x00)
    write(0x5200, VISUAL_SPLIT)
    write(0x5201, VISUAL_SCROLL)
    write(0x5202, BANK_SPLIT)
    write(0x2000, 0x08)
    write(0x2005, VISUAL_SX)
    write(0x2005, 0x00)
    write(0x2001, 0x1E)
    a.label('loop')
    a.abs_label(JMP_ABS, 'loop')

    # One probe, X: set up in vblank, then the hit flag in the next one
    a.label('probe')
    for k, reg in (('mode', 0x5104), ('split', 0x5200), ('scroll', 0x5201),
                   ('bank', 0x5202)):
        a.abs_label(LDA_ABS_X, 't_' + k)
        a.abs(STA_ABS, reg)
    write(0x2003, 0x00)
    a.abs_label(LDA_ABS_X, 't_oy')
    a.abs(STA_ABS, 0x2004)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2004)
    a.abs(STA_ABS, 0x2004)
    a.abs_label(LDA_ABS_X, 't_ox')
    a.abs(STA_ABS, 0x2004)
    write(0x2000, 0x08)                         # sprites at 0x1000
    a.abs_label(LDA_ABS_X, 't_sx')
    a.abs(STA_ABS, 0x2005)
    a.abs_label(LDA_ABS_X, 't_sy')
    a.abs(STA_ABS, 0x2005)
    write(0x2001, 0x1E)
    a.abs(BIT_ABS, 0x2002)
    a.label('probe_wait')
    a.abs(LDA_ABS, 0x2002)
    a.branch(BPL, 'probe_wait')
    a.emit(AND_IMM, 0x40)
    a.abs_label(CMP_ABS_X, 't_hit')
    a.branch(BNE, 'fail')
    a.emit(RTS)

    # The group's color with rendering off
    a.label('fail')
    if keep_going:
        a.emit(LDA_IMM, 0x01)
        a.abs(STA_ABS_X, FAILS)
        a.emit(RTS)
    a.abs_label(LDA_ABS_X, 't_idx')
    a.emit(STA_ZP, DETAIL)
    a.abs_label(LDA_ABS_X, 't_grp')
    a.emit(STA_ZP, GROUP)
    a.emit(TAX)
    write(0x2001, 0x00)
    ppu_addr(0x3F00)
    a.abs_label(LDA_ABS_X, 'group_colors')
    a.abs(STA_ABS, 0x2007)
    ppu_addr(0x0000)
    a.label('fail_loop')
    a.abs_label(JMP_ABS, 'fail_loop')

    # Fills X bytes (0 for 256) at PTR with A
    a.label('fill')
    a.emit(LDY_IMM, 0x00)
    a.label('fill_loop')
    a.emit(STA_IND_Y, PTR)
    a.emit(INY)
    a.emit(DEX)
    a.branch(BNE, 'fill_loop')
    a.emit(RTS)

    a.label('nmi')
    a.emit(RTI)

    for k, values in tables.items():
        a.label('t_' + k)
        a.emit(*values)
    a.label('group_colors')
    a.emit(*GROUP_COLORS)

    code = a.link()
    assert ORG + len(code) <= 0x10000 - 6, 'code too large: %d' % len(code)

    prg = bytearray([0xFF]) * (0x2000 * PRG_BANKS)
    last = 0x2000 * (PRG_BANKS - 1)
    prg[last + ORG - 0xE000:last + ORG - 0xE000 + len(code)] = code
    for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'), (0xFFFE, 'nmi')):
        prg[last + vec - 0xE000] = a.labels[name] & 0xFF
        prg[last + vec - 0xE000 + 1] = a.labels[name] >> 8

    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000, 0x50, 0x00])
    header += bytes(8)

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) not in (2, 3) or sys.argv[2:] not in ([], ['continue']):
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(keep_going=len(sys.argv) == 3))


if __name__ == '__main__':
    main()
