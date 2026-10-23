#!/usr/bin/env python3
"""Generate test ROMs for the Nintendo MMC5 (mapper 5).

Usage: mmc5.py OUT.nes VARIANT

The ROM checks, in order (each is a group; its number is the failure color):
   1-4  PRG ROM banks in PRG modes 3, 2, 1 and 0 of 0x5100, with values
        that set every bank bit and bits above the size of the ROM. Each 8KB
        bank holds its number at SIG_LO and its complement at SIG_HI. The
        code is in every bank, so it keeps running whatever bank is at
        0xE000
   5    PRG RAM banks at 0x6000 (0x5113): each of the 8 banks is written in
        turn and read back, which shows the RAM layout of the variant: open
        bus (the high byte of the address) for an empty socket
   6    The write protection of 0x5102/0x5103
   7    PRG RAM in the windows at 0x8000-0xDFFF (bit 7 of 0x5114-0x5116
        clear) in PRG modes 3 and 2, read back through 0x6000, and bit 7 of
        0x5117 ignored
   8    ExRAM from the CPU in the four modes of 0x5104: read/write in mode
        2, read only in mode 3, open bus in modes 0 and 1, and a write in
        mode 0 outside the frame writes 0 (as in Mesen; nesdev says it may be
        ignored or corrupt the byte)
   9    The multiplier at 0x5205/0x5206
  10    CHR banks in CHR modes 0-3 with 8x8 sprites, read through
        $2006/$2007 with rendering off. Each 1KB bank holds the low and high
        bytes of its number at its first two bytes. Registers are written
        after 0x5130, so its bits are above each of them
  11    With 8x16 sprites and rendering enabled during vblank, $2007 reads
        use the last set of registers written: 0x5128-0x512B, which map both
        pattern tables, or 0x5120-0x5127
  12    Nametable mapping (0x5105): CIRAM pages 0 and 1, ExRAM and fill mode,
        written and read back through $2007, for a set of values
  13    The fill tile and color (0x5106/0x5107), and a nametable in ExRAM
        reading 0 in ExRAM mode 2
  14    No IRQ with 0x5203 = 0
  15    Scanline IRQ timing: for each target in TRIALS, the NMI handler
        waits until a few scanlines before it and runs a NOP sled. The IRQ
        handler stores the low byte of the return address, which tells which
        NOP the IRQ came after, and the two reads of 0x5204 that follow (the
        first acknowledges the IRQ), failing here if the sled runs out
  16    The results of 15 against EXPECTED, which is what Mesen gives. The
        return address may be a NOP either side, since the NMI lands in a
        3-cycle wait loop and the line-up of the CPU and PPU clocks differs
        by a cycle between emulators
  17    With the IRQ disabled, 0x5204 reads pending and in frame after the
        target scanline, then only in frame, then neither after a read of
        0xFFFA; compared with PENDING_EXPECTED, from Mesen

The expected values of 1-13 come from a model of the registers written from
the nesdev tables, run alongside the generation of the script.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group that failed; the index of the
failing row of its script (counted from 0 again every 255 rows) is at zero
page DETAIL. The result is up about 25 frames after reset, so 600ms of
nes_bench is enough.

Variants, by the PRG RAM on the board:
  ines   iNES, which gets 64KB: all 8 banks distinct
  ekrom  NES 2.0, 8KB: banks 0-3 are the one 8KB, 4-7 an empty socket
  etrom  NES 2.0, 8KB + 8KB: banks 0-3 the first chip, 4-7 the second
  ewrom  NES 2.0, 32KB: banks 0-3 distinct, 4-7 an empty socket
  ines_dump  ines, showing zero page RESULTS-PENDING in the backdrop at the
             end, a nibble at a time, for nes_bench, whose RAM cannot be
             read. Decode the frames with the colors of DUMP_COLORS

All pass in nes_bench. Mesen passes all but ekrom, which fails group 7: it
reads 0xFF from the empty socket mapped at 0xC000 rather than open bus,
though it gives open bus for the same socket at 0x6000.

The ROM is 256KB of PRG and 512KB of CHR, since nes_bench holds at most
1MB of ROM.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes. Most checks are rows of a script that a small
interpreter runs, which keeps the code small enough to be in every bank.
"""

import sys

VARIANTS = {
    'ines': dict(prg_ram=None),
    'ekrom': dict(prg_ram=0x70),
    'etrom': dict(prg_ram=0x77),
    'ewrom': dict(prg_ram=0x90),
    # ines that, on a failure, shows zero page DUMP_START-DUMP_END in the
    # backdrop instead, for an emulator whose RAM cannot be read: the high
    # and low nibble of each byte as the colors of DUMP_COLORS, each after
    # a black frame, then the color of the result. It dumps on a pass too. The code before the sled
    # is the same as for ines, so the timing trials give the same results
    'ines_dump': dict(prg_ram=None, dump=True),
}


PASS_COLOR = 0x2A

PRG_BANKS = 32
CHR_BANKS = 512

ORG = 0xE100
SIG_LO = 0x0010
SIG_HI = 0x1FF0

# Zero page
SCRIPT = 0x00
PTR = 0x02
KIND = 0x04
VAL = 0x05
DCOUNT = 0x06
DETAIL = 0x07
TRIAL = 0x08
# Bit 7 set: an IRQ now is a failure, of group FAIL_STEP
MODE = 0x09
FAIL_STEP = 0x0A
# Bit 7 set: the NMI handler runs a timing trial. Bit 6 set: it checks
# 0x5204 with the IRQ disabled
NMI_MODE = 0x0B
FRAMES = 0x0C
DONE = 0x0D
RESULTS = 0x10
FLAGS_1 = 0x18
FLAGS_2 = 0x20
PENDING = 0x28

# The zero page the ines_dump variant shows, and the color of each nibble
DUMP_START = RESULTS
DUMP_END = PENDING + 2
DUMP_COLORS = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
               0x0A, 0x0B, 0x0C, 0x10, 0x20, 0x2D]

# The scanline targets of the timing trials
TRIALS = [1, 2, 3, 0x10, 0x80, 0xEF]
# What Mesen gives for each trial: the low byte of the return address and
# the two reads of 0x5204. None to only record them
EXPECTED = [(0x89, 0xC0, 0x40), (0x87, 0xC0, 0x40), (0x87, 0xC0, 0x40),
            (0x76, 0xC0, 0x40), (0x69, 0xC0, 0x40), (0x94, 0xC0, 0x40)]
# The scanline the pending check reads 0x5204 at, and what Mesen gives for
# the three reads. None to only record them
PENDING_TARGET = 0x10
PENDING_LINE = 0x30
PENDING_EXPECTED = [0xC0, 0x40, 0x00]

# Each outer iteration of the NMI delay loop is this many CPU cycles
DELAY_LOOP = 116
SLED_NOPS = 256

# Script row kinds
K_WRITE, K_READ, K_PPU_ADDR, K_PPU_WRITE, K_PPU_READ, K_PPU_SKIP, K_VBLANK = \
    range(7)
K_END = 0xFF


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

    def imm_label(self, op, name, high):
        self.emit(op, 0)
        self.fixups.append((len(self.code) - 1, name, 'hi' if high else 'lo'))

    def branch(self, op, name):
        self.emit(op, 0)
        self.fixups.append((len(self.code) - 1, name, 'rel'))

    def link(self):
        for off, name, kind in self.fixups:
            addr = self.labels[name]
            if kind == 'abs':
                self.code[off] = addr & 0xFF
                self.code[off + 1] = addr >> 8
            elif kind == 'lo':
                self.code[off] = addr & 0xFF
            elif kind == 'hi':
                self.code[off] = addr >> 8
            else:
                d = addr - (ORG + off + 1)
                assert -128 <= d < 128, name
                self.code[off] = d & 0xFF
        return self.code


LDA_IMM, LDA_ABS, STA_ABS, STX_ABS = 0xA9, 0xAD, 0x8D, 0x8E
LDX_IMM, LDY_IMM, CMP_IMM, BIT_ABS, BIT_ZP = 0xA2, 0xA0, 0xC9, 0x2C, 0x24
LDA_ZP, STA_ZP, LDX_ZP, LDY_ZP, STX_ZP, STY_ZP, INC_ZP = \
    0xA5, 0x85, 0xA6, 0xA4, 0x86, 0x84, 0xE6
LDA_ZP_X = 0xB5
LDA_ABS_X, LDY_ABS_X, STA_ZP_X, LDA_IND_Y, STA_IND_Y, CMP_ZP = \
    0xBD, 0xBC, 0x95, 0xB1, 0x91, 0xC5
BPL, BMI, BEQ, BNE, BVS, BCC, JMP_ABS, JSR, RTS, RTI = \
    0x10, 0x30, 0xF0, 0xD0, 0x70, 0x90, 0x4C, 0x20, 0x60, 0x40
SEI, CLI, CLD, CLC, TXS, TSX, NOP, DEX, DEY = \
    0x78, 0x58, 0xD8, 0x18, 0x9A, 0xBA, 0xEA, 0xCA, 0x88
ADC_IMM, SBC_IMM, SEC, PHA, PLA = 0x69, 0xE9, 0x38, 0x48, 0x68


class Model:
    """What the MMC5 holds, from the nesdev description, for the expected
    values of the scripts"""

    def __init__(self, variant):
        self.prg_ram = VARIANTS[variant]['prg_ram']
        self.prg_mode = 3
        self.chr_mode = 0
        self.protect = [0, 0]
        self.exram_mode = 0
        self.nt = [0, 0, 0, 0]
        self.fill_tile = 0
        self.fill_attr = 0
        self.prg_ram_bank = 0
        self.prg_regs = [0, 0, 0, 0xFF]
        self.chr_regs = [0] * 12
        self.chr_upper = 0
        self.bg_written = False
        self.mul = [0xFF, 0xFF]
        self.sprite_8x16 = False
        self.substitutions = False
        self.ram = {}
        self.exram = {}
        self.ciram = [{}, {}]
        self.ppu_addr = 0
        self.ppu_buffer = None

    # The chip and page of a PRG RAM bank, or None for an empty socket
    def ram_location(self, bank):
        if self.prg_ram is None:                # iNES: 64KB
            return bank
        if self.prg_ram == 0x70:                # EKROM: 8KB
            return 0 if bank < 4 else None
        if self.prg_ram == 0x77:                # ETROM: 8KB + 8KB
            return bank >> 2
        return bank if bank < 4 else None       # EWROM: 32KB

    # ('rom', bank) or ('ram', bank) for a CPU address at 0x8000
    def prg_window(self, addr):
        w = (addr >> 13) & 3
        m = self.prg_mode
        if m == 0:
            reg, v = 3, (self.prg_regs[3] & ~3) | w
        elif m == 1:
            reg = 1 if w < 2 else 3
            v = (self.prg_regs[reg] & ~1) | (w & 1)
        elif m == 2:
            if w < 2:
                reg, v = 1, (self.prg_regs[1] & ~1) | (w & 1)
            else:
                reg, v = w, self.prg_regs[w]
        else:
            reg, v = w, self.prg_regs[w]
        if reg == 3 or v & 0x80:
            return 'rom', v & 0x7F
        return 'ram', v & 7

    def read(self, addr):
        open_bus = addr >> 8
        if addr in (0x5205, 0x5206):
            p = self.mul[0] * self.mul[1]
            return p & 0xFF if addr == 0x5205 else p >> 8
        if 0x5C00 <= addr <= 0x5FFF:
            if self.exram_mode >= 2:
                return self.exram[addr & 0x3FF]
            return open_bus
        if 0x6000 <= addr <= 0x7FFF:
            kind, bank = 'ram', self.prg_ram_bank
        else:
            kind, bank = self.prg_window(addr)
        if kind == 'rom':
            bank %= PRG_BANKS
            off = addr & 0x1FFF
            assert off in (SIG_LO, SIG_HI), hex(addr)
            return bank if off == SIG_LO else bank ^ 0xFF
        loc = self.ram_location(bank)
        if loc is None:
            return open_bus
        return self.ram[(loc, addr & 0x1FFF)]

    def write(self, addr, value):
        if 0x5000 <= addr <= 0x5BFF:
            self.write_register(addr, value)
        elif 0x5C00 <= addr <= 0x5FFF:
            if self.exram_mode == 2:
                self.exram[addr & 0x3FF] = value
            elif self.exram_mode < 2:
                # Outside the frame
                self.exram[addr & 0x3FF] = 0
        elif addr == 0x2000:
            self.sprite_8x16 = bool(value & 0x20)
        elif addr == 0x2001:
            self.substitutions = bool(value & 0x18)
        elif addr >= 0x6000:
            if addr < 0x8000:
                kind, bank = 'ram', self.prg_ram_bank
            else:
                kind, bank = self.prg_window(addr)
            loc = self.ram_location(bank)
            if kind == 'ram' and loc is not None and self.protect == [2, 1]:
                self.ram[(loc, addr & 0x1FFF)] = value

    def write_register(self, addr, value):
        if addr == 0x5100:
            self.prg_mode = value & 3
        elif addr == 0x5101:
            self.chr_mode = value & 3
        elif addr in (0x5102, 0x5103):
            self.protect[addr - 0x5102] = value & 3
        elif addr == 0x5104:
            self.exram_mode = value & 3
        elif addr == 0x5105:
            self.nt = [(value >> (2 * i)) & 3 for i in range(4)]
        elif addr == 0x5106:
            self.fill_tile = value
        elif addr == 0x5107:
            self.fill_attr = (value & 3) * 0x55
        elif addr == 0x5113:
            self.prg_ram_bank = value & 7
        elif 0x5114 <= addr <= 0x5117:
            self.prg_regs[addr - 0x5114] = value
        elif 0x5120 <= addr <= 0x512B:
            self.chr_regs[addr - 0x5120] = (self.chr_upper << 8) | value
            self.bg_written = addr >= 0x5128
        elif addr == 0x5130:
            self.chr_upper = value & 3
        elif addr in (0x5205, 0x5206):
            self.mul[addr - 0x5205] = value

    def chr_bank(self, addr):
        w = (addr >> 10) & 7
        mask = [7, 3, 1, 0][self.chr_mode]
        idx = w | mask
        # Rendering is off or in vblank: the last set written
        if self.sprite_8x16 and self.substitutions and self.bg_written:
            idx = 8 + idx % 4
        return ((self.chr_regs[idx] << (3 - self.chr_mode)) |
                (w & mask)) % CHR_BANKS

    def ppu_read_mem(self, addr):
        addr &= 0x3FFF
        if addr < 0x2000:
            # Only the first two bytes of a bank are not 0. The read
            # buffer reads one byte past the last checked
            off = addr & 0x3FF
            bank = self.chr_bank(addr)
            return [bank & 0xFF, bank >> 8, 0][min(off, 2)]
        source = self.nt[(addr >> 10) & 3]
        off = addr & 0x3FF
        # None for a byte not written, which is only read ahead into the
        # read buffer
        if source < 2:
            return self.ciram[source].get(off)
        if source == 2:
            return self.exram.get(off) if self.exram_mode < 2 else 0
        return self.fill_attr if off >= 0x3C0 else self.fill_tile

    def ppu_write_mem(self, addr, value):
        source = self.nt[(addr >> 10) & 3]
        off = addr & 0x3FF
        if source < 2:
            self.ciram[source][off] = value
        elif source == 2 and self.exram_mode < 2:
            self.exram[off] = value

    # $2007 reads return the buffer and refill it, except for the palettes
    def ppu_read(self):
        ret = self.ppu_buffer
        self.ppu_buffer = self.ppu_read_mem(self.ppu_addr)
        self.ppu_addr += 1
        return ret


class Script:
    def __init__(self, model):
        self.model = model
        self.rows = []

    def row(self, kind, addr, value):
        self.rows.append((kind, addr & 0xFF, addr >> 8, value & 0xFF))

    def w(self, addr, value):
        self.model.write(addr, value)
        self.row(K_WRITE, addr, value)

    def r(self, addr):
        self.row(K_READ, addr, self.model.read(addr))

    def ppu_addr(self, addr):
        self.model.ppu_addr = addr
        self.row(K_PPU_ADDR, addr, 0)

    def ppu_write(self, value):
        self.model.ppu_write_mem(self.model.ppu_addr, value)
        self.model.ppu_addr += 1
        self.row(K_PPU_WRITE, 0, value)

    # Sets the address and reads count bytes from it, checking each
    def ppu_check(self, addr, count):
        self.ppu_addr(addr)
        self.model.ppu_read()
        self.row(K_PPU_SKIP, 0, 0)
        for _ in range(count):
            value = self.model.ppu_read()
            assert value is not None, hex(addr)
            self.row(K_PPU_READ, 0, value)

    def vblank(self):
        self.row(K_VBLANK, 0, 0)

    # The rows in parts of at most 255, the most DCOUNT can count
    def parts(self):
        for i in range(0, len(self.rows), 255):
            out = bytearray()
            for r in self.rows[i:i + 255]:
                out.extend(r)
            out.append(K_END)
            yield out


def prg_scripts(model):
    s = []

    def sig(sc, window):
        sc.r(window + SIG_LO)
        sc.r(window + SIG_HI)

    values = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F, 0x20, 0x40, 0x55, 0x7F]

    # Mode 3: four 8KB banks
    sc = Script(model)
    sc.w(0x5100, 3)
    for reg in range(4):
        for v in values:
            sc.w(0x5114 + reg, 0x80 | v)
            sig(sc, 0x8000 + 0x2000 * reg)
        sc.w(0x5114 + reg, 0x80 | (PRG_BANKS - 4 + reg))
    for w in range(4):
        sig(sc, 0x8000 + 0x2000 * w)
    s.append(sc)

    # Mode 2: 16KB at 0x8000, 8KB at 0xC000 and 0xE000
    sc = Script(model)
    sc.w(0x5100, 2)
    for v in values:
        sc.w(0x5115, 0x80 | v)
        sig(sc, 0x8000)
        sig(sc, 0xA000)
        sc.w(0x5116, 0x80 | (v ^ 0x15))
        sig(sc, 0xC000)
        sc.w(0x5117, 0x80 | (v ^ 0x0A))
        sig(sc, 0xE000)
    s.append(sc)

    # Mode 1: 16KB at 0x8000 and 0xC000
    sc = Script(model)
    sc.w(0x5100, 1)
    for v in values:
        sc.w(0x5115, 0x80 | v)
        sc.w(0x5117, 0x80 | (v ^ 0x0F))
        for w in range(4):
            sig(sc, 0x8000 + 0x2000 * w)
    s.append(sc)

    # Mode 0: 32KB
    sc = Script(model)
    sc.w(0x5100, 0)
    for v in values:
        sc.w(0x5117, 0x80 | v)
        for w in range(4):
            sig(sc, 0x8000 + 0x2000 * w)
    sc.w(0x5117, 0xFF)
    sc.w(0x5100, 3)
    for reg in range(3):
        sc.w(0x5114 + reg, 0x80 | reg)
    s.append(sc)

    return s


def ram_scripts(model):
    s = []

    # The RAM layout
    sc = Script(model)
    sc.w(0x5102, 2)
    sc.w(0x5103, 1)
    for b in range(8):
        sc.w(0x5113, b)
        sc.w(0x6000, 0x40 + b)
        sc.w(0x7FFF, 0x50 + b)
    for b in range(8):
        sc.w(0x5113, b)
        sc.r(0x6000)
        sc.r(0x7FFF)
    s.append(sc)

    # Write protection
    sc = Script(model)
    sc.w(0x5113, 0)
    for p1, p2 in ((0, 1), (2, 0), (3, 1), (2, 3), (1, 2)):
        sc.w(0x5102, p1)
        sc.w(0x5103, p2)
        sc.w(0x6000, 0xE0 + p1 * 4 + p2)
        sc.r(0x6000)
    sc.w(0x5102, 2)
    sc.w(0x5103, 1)
    sc.w(0x6000, 0xA5)
    sc.r(0x6000)
    s.append(sc)

    # PRG RAM at 0x8000-0xDFFF
    sc = Script(model)
    sc.w(0x5100, 3)
    for reg, bank in ((0, 1), (1, 3), (2, 6), (2, 5)):
        sc.w(0x5114 + reg, bank)
        window = 0x8000 + 0x2000 * reg
        sc.w(window, 0x70 + bank)
        sc.w(window + 0x1FFF, 0x78 + bank)
        sc.r(window)
        sc.r(window + 0x1FFF)
        sc.w(0x5113, bank)
        sc.r(0x6000)
        sc.r(0x7FFF)
    sc.w(0x5100, 2)
    sc.w(0x5115, 0x04)
    sc.w(0x8000, 0x84)
    sc.w(0xA000, 0x85)
    sc.w(0xC000, 0x86)
    for b in (4, 5):
        sc.w(0x5113, b)
        sc.r(0x6000)
    sc.r(0xC000)
    # 0x5117 maps PRG ROM whatever bit 7 is
    sc.w(0x5117, 0x7F)
    sc.r(0xE000 + SIG_LO)
    sc.w(0x5117, 0xFF)
    sc.w(0x5100, 3)
    for reg in range(3):
        sc.w(0x5114 + reg, 0x80 | reg)
    s.append(sc)

    return s


def exram_mul_scripts(model):
    s = []

    sc = Script(model)
    sc.w(0x5104, 2)
    sc.w(0x5C00, 0x11)
    sc.w(0x5C01, 0x99)
    sc.w(0x5FFF, 0x22)
    sc.r(0x5C00)
    sc.r(0x5C01)
    sc.r(0x5FFF)
    sc.w(0x5104, 3)
    sc.w(0x5C00, 0x33)
    sc.r(0x5C00)
    sc.w(0x5104, 0)
    sc.r(0x5C00)
    sc.r(0x5FFF)
    sc.w(0x5C01, 0x44)
    sc.w(0x5104, 1)
    sc.r(0x5C00)
    sc.w(0x5104, 2)
    sc.r(0x5C01)
    sc.r(0x5C00)
    s.append(sc)

    sc = Script(model)
    for a, b in ((3, 5), (0xFF, 0xFF), (0x80, 0x02), (0x12, 0x34), (0, 0x77),
                 (0xC3, 0x5A)):
        sc.w(0x5205, a)
        sc.w(0x5206, b)
        sc.r(0x5205)
        sc.r(0x5206)
    s.append(sc)

    return s


A_REGS = [0x11, 0x23, 0x35, 0x47, 0x59, 0x6B, 0x7D, 0x8F]
B_REGS = [0xA2, 0xB4, 0xC6, 0xD8]


def chr_scripts(model):
    s = []

    sc = Script(model)
    sc.w(0x2000, 0x00)
    for upper, regs in ((0, A_REGS), (1, [r ^ 0x81 for r in A_REGS])):
        sc.w(0x5130, upper)
        for r, value in enumerate(regs):
            sc.w(0x5120 + r, value)
        for mode in range(4):
            sc.w(0x5101, mode)
            for w in range(8):
                sc.ppu_check(0x400 * w, 2)
    s.append(sc)

    # 8x16 sprites, rendering enabled in vblank: the last set written
    sc = Script(model)
    sc.w(0x5130, 0)
    sc.w(0x2000, 0x20)
    for r, value in enumerate(A_REGS):
        sc.w(0x5120 + r, value)
    for r, value in enumerate(B_REGS):
        sc.w(0x5128 + r, value)
    for last_a in (False, True):
        if last_a:
            sc.w(0x5127, A_REGS[7])
        for mode in range(4):
            sc.w(0x5101, mode)
            sc.vblank()
            sc.w(0x2001, 0x18)
            for w in (0, 1, 2, 3, 6):
                sc.ppu_check(0x400 * w, 1)
            sc.w(0x2001, 0x00)
    sc.w(0x2000, 0x00)
    sc.w(0x5101, 3)
    s.append(sc)

    return s


NT_VALUES = [0x00, 0x55, 0x44, 0x50, 0x14, 0xE4, 0xAA, 0xFF, 0x1B, 0x9C,
             0x27, 0xD8, 0x6E, 0x93]


def nt_scripts(model):
    s = []

    sc = Script(model)
    sc.w(0x5104, 0)
    sc.w(0x5106, 0x5A)
    sc.w(0x5107, 0x02)
    for n, value in enumerate(NT_VALUES):
        sc.w(0x5105, value)
        for i in range(4):
            sc.ppu_addr(0x2000 + 0x400 * i + n)
            sc.ppu_write(0xC0 + 4 * (n % 8) + i)
        for i in range(4):
            sc.ppu_check(0x2000 + 0x400 * i + n, 1)
    s.append(sc)

    sc = Script(model)
    sc.w(0x5105, 0xFF)
    sc.w(0x5106, 0x3C)
    sc.w(0x5107, 0x01)
    for addr in (0x2000, 0x23BF, 0x23C0, 0x27FF, 0x2C00, 0x2FFF):
        sc.ppu_check(addr, 1)
    sc.w(0x5107, 0x03)
    sc.ppu_check(0x23C0, 1)
    # A nametable in ExRAM reads 0 in modes 2 and 3
    sc.w(0x5105, 0xAA)
    sc.w(0x5104, 0)
    sc.ppu_addr(0x2005)
    sc.ppu_write(0x6D)
    sc.ppu_check(0x2005, 1)
    sc.w(0x5104, 2)
    sc.r(0x5C05)
    sc.ppu_check(0x2005, 1)
    sc.w(0x5104, 3)
    sc.ppu_check(0x2005, 1)
    sc.w(0x5104, 0)
    sc.w(0x5105, 0x44)
    s.append(sc)

    return s


def build(variant):
    v = VARIANTS[variant]
    a = Assembler()
    model = Model(variant)
    step = [1]
    scripts = []

    def next_group():
        step[0] += 1
        assert step[0] < PASS_COLOR

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    # Fails with the group number unless A is below value (unsigned)
    def check_below(value, detail):
        a.emit(LDX_IMM, step[0])
        a.emit(LDY_IMM, detail)
        a.emit(CMP_IMM, value)
        a.emit(BCC, 3)
        a.abs_label(JMP_ABS, 'show')

    # Fails with the group number unless A is value
    def check(value, detail):
        a.emit(LDX_IMM, step[0])
        a.emit(LDY_IMM, detail)
        a.emit(CMP_IMM, value)
        a.emit(BEQ, 3)
        a.abs_label(JMP_ABS, 'show')

    # Waits (outer * DELAY_LOOP) CPU cycles, with outer in Y
    def delay_y(name):
        a.label(name)
        a.emit(LDX_IMM, 22)
        a.label(name + '_inner')
        a.emit(DEX)
        a.branch(BNE, name + '_inner')
        a.emit(DEY)
        a.branch(BNE, name)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    a.abs(STA_ABS, 0x4010)
    a.abs(STA_ABS, 0x4015)
    a.emit(STA_ZP, TRIAL)
    a.emit(STA_ZP, NMI_MODE)
    a.emit(LDA_IMM, 0x40)                       # no frame IRQ
    a.abs(STA_ABS, 0x4017)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    a.emit(LDA_IMM, 0x01)
    a.emit(STA_ZP, FAIL_STEP)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    groups = (prg_scripts(model) + ram_scripts(model) +
              exram_mul_scripts(model) + chr_scripts(model) +
              nt_scripts(model))
    for sc in groups:
        for i, part in enumerate(sc.parts()):
            name = 'script_%d_%d' % (step[0], i)
            scripts.append((name, part))
            a.imm_label(LDA_IMM, name, False)
            a.emit(STA_ZP, SCRIPT)
            a.imm_label(LDA_IMM, name, True)
            a.emit(STA_ZP, SCRIPT + 1)
            a.emit(LDX_IMM, step[0])
            a.abs_label(JSR, 'run_script')
        next_group()

    # No IRQ with the target 0
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    wait_vblank('vblank_3')
    write(0x2001, 0x08)
    write(0x2000, 0x80)
    write(0x5203, 0x00)
    write(0x5204, 0x80)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, FRAMES)
    a.emit(CLI)
    a.label('target_0')
    a.emit(LDA_ZP, FRAMES)
    a.emit(CMP_IMM, 3)
    a.branch(BNE, 'target_0')
    a.emit(SEI)
    write(0x5204, 0x00)
    next_group()

    # The timing trials. The IRQ handler starts the next one
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, MODE)
    a.label('trial')
    a.abs(LDA_ABS, 0x5204)                      # acknowledge
    a.emit(LDX_ZP, TRIAL)
    a.abs_label(LDA_ABS_X, 'targets')
    a.abs(STA_ABS, 0x5203)
    write(0x5204, 0x80)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, NMI_MODE)
    a.label('trial_wait')
    a.abs_label(JMP_ABS, 'trial_wait')
    trial_step = step[0]
    next_group()

    a.label('trials_done')
    if EXPECTED is not None:
        for t, (lo, f1, f2) in enumerate(EXPECTED):
            # Within a NOP of what Mesen gives: where the NMI lands in the
            # wait loop depends on how the CPU and PPU clocks line up, which
            # differs by a cycle between emulators
            a.emit(LDA_ZP, RESULTS + t)
            a.emit(SEC)
            a.emit(SBC_IMM, (lo - 1) & 0xFF)
            check_below(3, 3 * t)
            a.emit(LDA_ZP, FLAGS_1 + t)
            check(f1, 3 * t + 1)
            a.emit(LDA_ZP, FLAGS_2 + t)
            check(f2, 3 * t + 2)
    next_group()

    # With the IRQ disabled
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    write(0x5203, PENDING_TARGET)
    write(0x5204, 0x00)
    a.abs(LDA_ABS, 0x5204)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, DONE)
    a.emit(LDA_IMM, 0x40)
    a.emit(STA_ZP, NMI_MODE)
    a.label('pending_wait')
    a.emit(LDA_ZP, DONE)
    a.branch(BEQ, 'pending_wait')
    if PENDING_EXPECTED is not None:
        for i, value in enumerate(PENDING_EXPECTED):
            a.emit(LDA_ZP, PENDING + i)
            check(value, i)
    next_group()

    a.emit(LDX_IMM, PASS_COLOR)
    a.emit(LDY_IMM, 0x00)
    a.abs_label(JMP_ABS, 'show')

    # Backdrop color X with rendering off, then the VRAM address off the
    # palette so that the backdrop is what rendering off shows
    a.label('show_color' if v.get('dump') else 'show')
    a.emit(SEI)
    a.emit(STY_ZP, DETAIL)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    wait_vblank('vblank_4')
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2001)
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

    # The script interpreter. X is the group, kept for a failure
    a.label('run_script')
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, DCOUNT)
    a.label('row')
    a.emit(LDY_IMM, 0)
    a.emit(LDA_IND_Y, SCRIPT)
    a.emit(CMP_IMM, K_END)
    a.branch(BNE, 'row_go')
    a.emit(RTS)
    a.label('row_go')
    a.emit(STA_ZP, KIND)
    a.emit(LDY_IMM, 1)
    a.emit(LDA_IND_Y, SCRIPT)
    a.emit(STA_ZP, PTR)
    a.emit(LDY_IMM, 2)
    a.emit(LDA_IND_Y, SCRIPT)
    a.emit(STA_ZP, PTR + 1)
    a.emit(LDY_IMM, 3)
    a.emit(LDA_IND_Y, SCRIPT)
    a.emit(STA_ZP, VAL)
    a.emit(LDY_IMM, 0)
    a.emit(LDA_ZP, KIND)
    a.emit(CMP_IMM, K_WRITE)
    a.branch(BNE, 'k_read')
    a.emit(LDA_ZP, VAL)
    a.emit(STA_IND_Y, PTR)
    a.abs_label(JMP_ABS, 'row_next')
    a.label('k_read')
    a.emit(CMP_IMM, K_READ)
    a.branch(BNE, 'k_ppu_addr')
    a.emit(LDA_IND_Y, PTR)
    a.abs_label(JMP_ABS, 'row_check')
    a.label('k_ppu_addr')
    a.emit(CMP_IMM, K_PPU_ADDR)
    a.branch(BNE, 'k_ppu_write')
    a.emit(LDA_ZP, PTR + 1)
    a.abs(STA_ABS, 0x2006)
    a.emit(LDA_ZP, PTR)
    a.abs(STA_ABS, 0x2006)
    a.abs_label(JMP_ABS, 'row_next')
    a.label('k_ppu_write')
    a.emit(CMP_IMM, K_PPU_WRITE)
    a.branch(BNE, 'k_ppu_read')
    a.emit(LDA_ZP, VAL)
    a.abs(STA_ABS, 0x2007)
    a.abs_label(JMP_ABS, 'row_next')
    a.label('k_ppu_read')
    a.emit(CMP_IMM, K_PPU_READ)
    a.branch(BNE, 'k_ppu_skip')
    a.abs(LDA_ABS, 0x2007)
    a.abs_label(JMP_ABS, 'row_check')
    a.label('k_ppu_skip')
    a.emit(CMP_IMM, K_PPU_SKIP)
    a.branch(BNE, 'k_vblank')
    a.abs(LDA_ABS, 0x2007)
    a.abs_label(JMP_ABS, 'row_next')
    # The flag may have been set long ago, so it is cleared first
    a.label('k_vblank')
    a.abs(BIT_ABS, 0x2002)
    a.label('k_vblank_wait')
    a.abs(BIT_ABS, 0x2002)
    a.branch(BPL, 'k_vblank_wait')
    a.abs_label(JMP_ABS, 'row_next')
    a.label('row_check')
    a.emit(CMP_ZP, VAL)
    a.branch(BEQ, 'row_next')
    a.emit(LDY_ZP, DCOUNT)
    a.abs_label(JMP_ABS, 'show')
    a.label('row_next')
    a.emit(CLC)
    a.emit(LDA_ZP, SCRIPT)
    a.emit(ADC_IMM, 4)
    a.emit(STA_ZP, SCRIPT)
    a.branch(BCC, 'row_same_page')
    a.emit(INC_ZP, SCRIPT + 1)
    a.label('row_same_page')
    a.emit(INC_ZP, DCOUNT)
    a.abs_label(JMP_ABS, 'row')

    # NMI: count frames, or run a timing trial or the pending check
    a.label('nmi')
    a.emit(BIT_ZP, NMI_MODE)
    a.branch(BMI, 'nmi_trial')
    a.branch(BVS, 'nmi_pending')
    a.emit(INC_ZP, FRAMES)
    a.emit(RTI)
    a.label('nmi_trial')
    a.emit(LDX_ZP, TRIAL)
    a.abs_label(LDY_ABS_X, 'delays')
    delay_y('trial_delay')
    a.emit(CLI)
    a.abs_label(JMP_ABS, 'sled')
    a.label('nmi_pending')
    a.emit(LDY_IMM, delay_for(PENDING_LINE))
    delay_y('pending_delay')
    a.abs(LDA_ABS, 0x5204)
    a.emit(STA_ZP, PENDING)
    a.abs(LDA_ABS, 0x5204)
    a.emit(STA_ZP, PENDING + 1)
    a.abs(LDA_ABS, 0xFFFA)
    a.abs(LDA_ABS, 0x5204)
    a.emit(STA_ZP, PENDING + 2)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, NMI_MODE)
    a.emit(LDA_IMM, 0xFF)
    a.emit(STA_ZP, DONE)
    a.emit(RTI)

    a.label('irq')
    a.emit(BIT_ZP, MODE)
    a.branch(BPL, 'irq_trial')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_IMM, 0xFF)
    a.abs_label(JMP_ABS, 'show')
    a.label('irq_trial')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    a.abs(LDA_ABS, 0x5204)
    a.emit(STA_ZP_X, FLAGS_1)
    a.abs(LDA_ABS, 0x5204)
    a.emit(STA_ZP_X, FLAGS_2)
    write(0x5204, 0x00)
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, NMI_MODE)
    a.emit(LDX_IMM, 0xFF, TXS)
    a.emit(INC_ZP, TRIAL)
    a.emit(LDA_ZP, TRIAL)
    a.emit(CMP_IMM, len(TRIALS))
    a.branch(BEQ, 'irq_done')
    a.abs_label(JMP_ABS, 'trial')
    a.label('irq_done')
    a.abs_label(JMP_ABS, 'trials_done')

    a.label('targets')
    a.emit(*TRIALS)
    a.label('delays')
    a.emit(*[delay_for(t) for t in TRIALS])

    for name, part in scripts:
        a.label(name)
        a.emit(*part)

    # The sled starts a page, so the low byte of the address is enough
    a.emit(*([0xFF] * (-a.here() % 0x100)))
    a.label('sled')
    a.emit(*([NOP] * SLED_NOPS))
    a.emit(LDX_IMM, trial_step)
    a.emit(LDY_IMM, 0xFE)
    a.abs_label(JMP_ABS, 'show')

    if v.get('dump'):
        build_dump(a, wait_vblank)

    code = a.link()
    assert ORG + len(code) <= 0xE000 + SIG_HI, \
        'code runs into SIG_HI: %d bytes' % len(code)

    # The code is in every bank, so it runs whatever bank is at 0xE000
    prg = bytearray()
    for b in range(PRG_BANKS):
        bank = bytearray([0xFF]) * 0x2000
        bank[ORG - 0xE000:ORG - 0xE000 + len(code)] = code
        bank[SIG_LO] = b
        bank[SIG_HI] = b ^ 0xFF
        for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'),
                          (0xFFFE, 'irq')):
            bank[vec - 0xE000] = a.labels[name] & 0xFF
            bank[vec - 0xE000 + 1] = a.labels[name] >> 8
        prg += bank

    chr_rom = bytearray(0x400 * CHR_BANKS)
    for b in range(CHR_BANKS):
        chr_rom[0x400 * b] = b & 0xFF
        chr_rom[0x400 * b + 1] = b >> 8

    nes2 = v['prg_ram'] is not None
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     0x50 | (0x02 if nes2 else 0x00),
                     0x08 if nes2 else 0x00])
    header += bytes(8)
    if nes2:
        header[10] = v['prg_ram']

    return bytes(header + prg + chr_rom)


def build_dump(a, wait_vblank):
    a.label('show')
    a.emit(SEI)
    a.emit(STX_ZP, FAIL_STEP)
    a.emit(STY_ZP, DETAIL)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    a.emit(LDA_IMM, DUMP_START)
    a.emit(STA_ZP, PTR)
    a.label('dump_byte')
    # The high nibble
    a.emit(LDX_ZP, PTR)
    a.emit(LDA_ZP_X, 0x00)
    for _ in range(4):
        a.emit(0x4A)                            # LSR A
    a.emit(0xAA)                                # TAX
    a.abs_label(LDA_ABS_X, 'dump_colors')
    a.emit(STA_ZP, VAL)
    a.abs_label(JSR, 'dump_color')
    # The low nibble
    a.emit(LDX_ZP, PTR)
    a.emit(LDA_ZP_X, 0x00)
    a.emit(0x29, 0x0F)                          # AND #$0F
    a.emit(0xAA)                                # TAX
    a.abs_label(LDA_ABS_X, 'dump_colors')
    a.emit(STA_ZP, VAL)
    a.abs_label(JSR, 'dump_color')
    a.emit(INC_ZP, PTR)
    a.emit(LDA_ZP, PTR)
    a.emit(CMP_IMM, DUMP_END + 1)
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


# The outer count of the delay that puts the IRQ at the start of scanline
# target about 250 cycles into the sled. The NMI is at scanline 241 and
# the IRQ at dot 3 of the target, (21 + target) scanlines later
def delay_for(target):
    cycles = (21 + target) * 341 / 3 - 25 - 250
    return round(cycles / DELAY_LOOP)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(sys.argv[2]))


if __name__ == '__main__':
    main()
