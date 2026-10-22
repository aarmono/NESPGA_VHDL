#!/usr/bin/env python3
"""Generate a test ROM for the PRG RAM banking of the MMC1 SxROM boards.

Usage: mmc1_prg_ram.py OUT.nes {sorom,sxrom,szrom,ines}

The ROM writes a different byte to the first and last address of each 8KB
PRG RAM bank, selecting the bank with the CHR bank 0 bits the board uses,
then reads them all back. A board that does not bank PRG RAM, or banks it
with the wrong bits, reads back the byte of another bank.

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the color of the step that failed (1 is the first byte
read back). The result is up two frames after reset, so 250ms of nes_bench
is enough.

Variants:
  sorom  NES 2.0, 8KB PRG RAM + 8KB PRG NVRAM, CHR RAM: bank in bit 3. Bit 2
         is set during the read back to check it is ignored
  sxrom  NES 2.0, 32KB PRG NVRAM, CHR RAM: bank in bits 3-2
  szrom  NES 2.0, 8KB PRG RAM + 8KB PRG NVRAM, 16KB CHR ROM: bank in bit 4.
         Bit 3 is set during the read back to check it is ignored
  ines   iNES, no RAM size, CHR RAM: checked as SXROM, which the cartridge
         assumes for an iNES MMC1 board with 8KB of CHR or less

Mesen passes sorom and sxrom. It does not model SZROM, and gives an iNES
header without a database entry 8KB of PRG RAM, so it fails szrom and ines.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    'sorom': dict(nes2=True, ram=0x77, chr=0, shift=3, banks=2, alias=0x04),
    'sxrom': dict(nes2=True, ram=0x90, chr=0, shift=2, banks=4, alias=0x00),
    'szrom': dict(nes2=True, ram=0x77, chr=2, shift=4, banks=2, alias=0x08),
    'ines':  dict(nes2=False, ram=0, chr=0, shift=2, banks=4, alias=0x00),
}

PASS_COLOR = 0x2A

# The code is in the last 16KB bank, which PRG mode 3 fixes at 0xC000
ORG = 0xC000


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
LDX_IMM, CMP_IMM, BIT_ABS, LSR_A = 0xA2, 0xC9, 0x2C, 0x4A
BPL, BNE, JMP_ABS, JSR, RTS, RTI = 0x10, 0xD0, 0x4C, 0x20, 0x60, 0x40


def build(v):
    a = Assembler()

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    # Writes A to an MMC1 register, one bit at a time. The LSRs keep the
    # writes off consecutive cycles, which the MMC1 would ignore
    def mmc1_write(name, reg):
        a.label(name)
        for i in range(5):
            a.abs(STA_ABS, reg)
            if i < 4:
                a.emit(LSR_A)
        a.emit(RTS)

    a.label('reset')
    a.emit(0x78, 0xD8, 0xA2, 0xFF, 0x9A)        # SEI CLD LDX #$FF TXS
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    a.emit(LDA_IMM, 0x80)                       # reset the shift register
    a.abs(STA_ABS, 0x8000)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    a.emit(LDA_IMM, 0x0C)                       # PRG mode 3, 8KB CHR mode
    a.abs_label(JSR, 'write_control')
    a.emit(LDA_IMM, 0x00)                       # PRG RAM enabled
    a.abs_label(JSR, 'write_prg_bank')

    for b in range(v['banks']):
        a.emit(LDA_IMM, b << v['shift'])
        a.abs_label(JSR, 'write_chr_bank_0')
        a.emit(LDA_IMM, 0xA0 + b)
        a.abs(STA_ABS, 0x6000)
        a.emit(LDA_IMM, 0x50 + b)
        a.abs(STA_ABS, 0x7FFF)

    step = 1
    for b in range(v['banks']):
        a.emit(LDA_IMM, (b << v['shift']) | v['alias'])
        a.abs_label(JSR, 'write_chr_bank_0')
        for addr, val in ((0x6000, 0xA0 + b), (0x7FFF, 0x50 + b)):
            a.emit(LDX_IMM, step)
            a.abs(LDA_ABS, addr)
            a.emit(CMP_IMM, val)
            a.branch(BNE, 'show')
            step += 1
    a.emit(LDX_IMM, PASS_COLOR)

    # Backdrop color X, then the VRAM address off the palette so that the
    # backdrop is what rendering off shows
    a.label('show')
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

    mmc1_write('write_control', 0x8000)
    mmc1_write('write_chr_bank_0', 0xA000)
    mmc1_write('write_prg_bank', 0xE000)
    a.label('rti')
    a.emit(RTI)

    code = a.link()

    # 32KB of PRG ROM, with the code and vectors in the last 16KB
    prg = bytearray([0xFF]) * 0x8000
    prg[0x4000:0x4000 + len(code)] = code
    for vec, name in ((0x7FFA, 'rti'), (0x7FFC, 'reset'), (0x7FFE, 'rti')):
        prg[vec] = a.labels[name] & 0xFF
        prg[vec + 1] = a.labels[name] >> 8

    # Mapper 1 with a battery, NES 2.0 or iNES
    header = bytearray(b'NES\x1a')
    header += bytes([2, v['chr'], 0x12, 0x08 if v['nes2'] else 0x00])
    header += bytes(8)
    if v['nes2']:
        header[10] = v['ram']
        header[11] = 0x07 if v['chr'] == 0 else 0x00

    return bytes(header + prg + bytes(0x2000 * v['chr']))


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
