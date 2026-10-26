#!/usr/bin/env python3
"""Generate test ROMs for the Jaleco SS 88006 (mapper 18).

Usage: ss88006.py OUT.nes {ines,nes2}

The chip decodes CPU A0, A1 and A12-A14, so the registers are written at
mirrors of their addresses throughout. The ROM checks, in order:
  - PRG RAM at 0x6000, enabled and writable at power on; then 0x9002 = 1
    (enabled, writes ignored), 0 and 2 (disabled: open bus, the high byte of
    the address, 0x60, and writes ignored) and 3 (enabled and writable)
  - PRG ROM banks at 0x8000 (0x8000/1), 0xA000 (0x8002/3) and 0xC000
    (0x9000/1), and the last bank fixed at 0xE000. Each 8KB bank holds its
    number at SIG_LO and its complement at SIG_HI. A write of one nibble
    leaves the other as it was
  - CHR ROM banks (0xA000-0xD003): each 1KB bank holds its number at its
    first byte, read back through $2006/$2007 with rendering off
  - The four mirroring modes (0xF002)
  - The IRQ: no IRQ with the counter disabled, and a write to 0xF000
    acknowledges the IRQ
  - The IRQ timing trials: for each of TRIALS the reload value is written,
    the counter reloaded (0xF000) and then started (0xF001), and a NOP sled
    is run. The IRQ handler stores the low byte of the return address,
    which tells which NOP the IRQ came after, at RESULTS + trial and
    compares it with EXPECTED. The trials cover the four widths of the
    counter, whose nibbles above the width do not count

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed: 1 PRG
RAM, 2 PRG ROM banks, 3 CHR ROM banks, 4 mirroring, 5 an IRQ with the
counter disabled or after the acknowledge, 6 no IRQ in a timing trial, 7
the timing trial results. The index of the failing check within its group
is at zero page DETAIL. The result is up a few frames after reset, so
250ms of nes_bench is enough.

Variants:
  ines  iNES, battery: 8KB of PRG RAM
  nes2  NES 2.0 with 8KB of battery-backed PRG RAM

The chip raises the IRQ when the counter borrows from 0 (hardware-tested
Verilog on the nesdev talk page), so a reload value of N raises it on the
N+1th CPU cycle. Mesen raises it when the counter reaches 0, on the Nth.
With MESEN set, the trials reload N+1, so Mesen should give the results of
the hardware, and the 0x9002 checks, which Mesen ignores, are left out.
Mesen passes that build, and EXPECTED is what it gives. It fails group 1
of the others, as it lets the CPU write PRG RAM with 0x9002 = 1, and
nes_bench fails group 7 of the MESEN build.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    'ines': dict(nes2=False),
    'nes2': dict(nes2=True),
}

# Builds the ROM for Mesen, see above
MESEN = False

PASS_COLOR = 0x2A

PRG_BANKS = 64
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
FRAMES = 0x04
RESULTS = 0x10

# The timing trials: the reload value and the value written to 0xF001,
# whose bit 0 enables the counter and bits 3-1 narrow it to 4, 8 or 12 bits
TRIALS = [
    (0x0000, 0x01),
    (0x0001, 0x01),
    (0x0002, 0x01),
    (0x0003, 0x01),
    (0x0014, 0x01),
    (0x0015, 0x01),
    (0x0100, 0x01),
    # 4 bits: the high nibbles do not count
    (0x1235, 0x09),
    # 4 bits, as bit 3 wins over bits 2 and 1
    (0xFF03, 0x0F),
    # 8 bits
    (0xAB07, 0x05),
    # 8 bits, as bit 2 wins over bit 1
    (0x3214, 0x07),
    # 12 bits
    (0x7100, 0x03),
]
SLED_NOPS = 160
# The low bytes of the return addresses Mesen gives with MESEN set, or
# None to only record them
EXPECTED = [0x00, 0x00, 0x01, 0x01, 0x0A, 0x0A, 0x80, 0x02, 0x01, 0x03, 0x0A,
            0x80]


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
LDX_IMM, LDY_IMM, CMP_IMM, BIT_ABS, BIT_ZP = 0xA2, 0xA0, 0xC9, 0x2C, 0x24
STY_ZP = 0x84
LDA_ZP, STA_ZP, LDX_ZP, LDY_ZP, INC_ZP = 0xA5, 0x85, 0xA6, 0xA4, 0xE6
LDA_ABS_X, STA_ZP_X = 0xBD, 0x95
BPL, BEQ, BNE, JMP_ABS, RTI = 0x10, 0xF0, 0xD0, 0x4C, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX = 0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA, 0xCA
DEC_ZP = 0xC6


# A mirror of a register address: the chip ignores A2-A11
def mirror(addr, n):
    return addr | ((n * 0x154) & 0x0FFC)


# The register pairs of the PRG and CHR banks
PRG_REGS = [0x8000, 0x8002, 0x9000]
CHR_REGS = [0xA000, 0xA002, 0xB000, 0xB002, 0xC000, 0xC002, 0xD000, 0xD002]


def build(v):
    a = Assembler()
    step = [1]
    detail = [0]
    writes = [0]

    def next_group():
        step[0] += 1
        detail[0] = 0
        assert step[0] < PASS_COLOR

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    # Only D0-D3 reach the chip, so the high nibble written is junk
    def write(addr, value):
        a.emit(LDA_IMM, value | (0x50 + 0x30 * writes[0]) & 0xF0)
        a.abs(STA_ABS, mirror(addr, writes[0]))
        writes[0] += 1

    def write_low(reg, bank):
        write(reg, bank & 0x0F)

    def write_high(reg, bank):
        write(reg | 1, bank >> 4)

    def write_bank(reg, bank):
        write_low(reg, bank)
        write_high(reg, bank)

    def ppu_addr(addr):
        a.emit(LDA_IMM, addr >> 8)
        a.abs(STA_ABS, 0x2006)
        a.emit(LDA_IMM, addr & 0xFF)
        a.abs(STA_ABS, 0x2006)

    def ppu_write(addr, value):
        ppu_addr(addr)
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, 0x2007)

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

    def cpu_write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    def bank_check(window, bank):
        cpu_check(window + SIG_LO, bank)
        cpu_check(window + SIG_HI, bank ^ 0xFF)

    # Waits about 5 * count CPU cycles
    def delay(count):
        a.emit(LDX_IMM, count)
        a.emit(DEX)
        a.emit(BNE, 0xFD)

    def reload(value):
        for i in range(4):
            write(0xE000 + i, (value >> (4 * i)) & 0x0F)

    a.label('reset')
    a.emit(SEI, CLD, LDX_IMM, 0xFF, TXS)
    a.emit(LDA_IMM, 0x00)
    a.abs(STA_ABS, 0x2000)
    a.abs(STA_ABS, 0x2001)
    a.abs(STA_ABS, 0x4010)
    a.emit(STA_ZP, TRIAL)
    a.emit(LDA_IMM, 0x40)                       # no frame IRQ
    a.abs(STA_ABS, 0x4017)
    a.emit(LDA_IMM, 0x80)
    a.emit(STA_ZP, MODE)
    wait_vblank('vblank_1')
    wait_vblank('vblank_2')

    # PRG RAM, before anything writes 0x9002
    cpu_write(0x6000, 0xA0)
    cpu_write(0x7FFF, 0x5F)
    cpu_check(0x6000, 0xA0)
    cpu_check(0x7FFF, 0x5F)
    if not MESEN:
        # Enabled, writes ignored
        write(0x9002, 0x01)
        cpu_write(0x6000, 0x11)
        cpu_check(0x6000, 0xA0)
        # Disabled
        write(0x9002, 0x00)
        cpu_check(0x6000, 0x60)
        cpu_write(0x6000, 0x22)
        write(0x9002, 0x02)
        cpu_check(0x7FFF, 0x7F)
        cpu_write(0x7FFF, 0x33)
        write(0x9002, 0x03)
        cpu_check(0x6000, 0xA0)
        cpu_check(0x7FFF, 0x5F)
        cpu_write(0x6000, 0x44)
        cpu_check(0x6000, 0x44)
    next_group()

    # PRG ROM banks. The last is fixed at 0xE000
    for b in range(PRG_BANKS - 1):
        write_bank(PRG_REGS[0], b)
        bank_check(0x8000, b)
    for reg, window, banks in ((PRG_REGS[1], 0xA000, (0x05, 0x3A)),
                               (PRG_REGS[2], 0xC000, (0x17, 0x2C))):
        for b in banks:
            write_bank(reg, b)
            bank_check(window, b)
    bank_check(0xE000, PRG_BANKS - 1)
    # A nibble at a time: 0x2C, 0x23, then 0x13
    write_low(PRG_REGS[2], 0x03)
    bank_check(0xC000, 0x23)
    write_high(PRG_REGS[2], 0x10)
    bank_check(0xC000, 0x13)
    # The other banks are left as they were
    bank_check(0x8000, PRG_BANKS - 2)
    bank_check(0xA000, 0x3A)
    bank_check(0xE000, PRG_BANKS - 1)
    next_group()

    # CHR ROM banks
    chr_banks = [(w * 0x25 + 0x5B) % CHR_BANKS for w in range(8)]
    for reg, b in zip(CHR_REGS, chr_banks):
        write_bank(reg, b)
    for w, b in enumerate(chr_banks):
        ppu_check(0x400 * w, b)
    # A nibble at a time
    write_low(CHR_REGS[5], 0x0E)
    ppu_check(0x1400, (chr_banks[5] & 0xF0) | 0x0E)
    write_high(CHR_REGS[5], 0xC0)
    ppu_check(0x1400, 0xCE)
    ppu_check(0x1000, chr_banks[4])
    ppu_check(0x1800, chr_banks[6])
    next_group()

    # Mirroring. Each of the four nametables is written with its own byte,
    # so the bytes read back show which share CIRAM
    def nt_test(mode, expect):
        write(0xF002, mode)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + expect[i])

    nt_test(0, [1, 1, 3, 3])
    nt_test(1, [2, 3, 2, 3])
    nt_test(2, [3, 3, 3, 3])
    nt_test(3, [3, 3, 3, 3])
    write(0xF002, 2)
    ppu_check(0x2400, 0x63)
    next_group()

    # No IRQ with the counter disabled, whatever its width. Then the counter
    # is started from 0, raising an IRQ at once with IRQs masked, and a
    # write to 0xF000 acknowledges it, reloading 0x8000
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    next_group()
    reload(0x0000)
    write(0xF000, 0x00)
    write(0xF001, 0x0E)
    a.emit(CLI)
    delay(20)
    a.emit(SEI)
    write(0xF001, 0x01)
    delay(4)
    reload(0x8000)
    write(0xF000, 0x00)
    a.emit(CLI)
    delay(20)
    a.emit(SEI)
    write(0xF001, 0x00)

    # The timing trials. The IRQ handler starts the next one
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, MODE)
    a.label('trial')
    a.emit(LDX_ZP, TRIAL)
    for i in range(4):
        a.abs_label(LDA_ABS_X, 'trials_%d' % i)
        a.abs(STA_ABS, 0xE000 + i)
    a.abs(STA_ABS, 0xF000)
    a.abs_label(LDA_ABS_X, 'trials_ctrl')
    a.emit(CLI)
    a.abs(STA_ABS, 0xF001)
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
    if EXPECTED is not None:
        assert len(EXPECTED) == len(TRIALS)
        for t, expect in enumerate(EXPECTED):
            a.emit(LDA_ZP, RESULTS + t)
            check(expect)
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
    a.branch(BPL, 'irq_trial')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_IMM, 0x00)
    a.abs_label(JMP_ABS, 'show')
    a.label('irq_trial')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    cpu_write(0xF001, 0x00)                     # stop and acknowledge
    a.emit(LDX_IMM, 0xFF, TXS)
    a.emit(INC_ZP, TRIAL)
    a.emit(LDA_ZP, TRIAL)
    a.emit(CMP_IMM, len(TRIALS))
    a.branch(BEQ, 'irq_done')
    a.abs_label(JMP_ABS, 'trial')
    a.label('irq_done')
    a.abs_label(JMP_ABS, 'trials_done')

    reloads = [r + 1 if MESEN else r for r, _ in TRIALS]
    for r, (t, _) in zip(reloads, TRIALS):
        assert (r ^ t) < 0x10, 'MESEN reload carries out of the low nibble'
    for i in range(4):
        a.label('trials_%d' % i)
        a.emit(*[(r >> (4 * i)) & 0x0F for r in reloads])
    a.label('trials_ctrl')
    a.emit(*[c for _, c in TRIALS])

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

    mapper = 18
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((mapper & 0x0F) << 4) | 0x02,
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[10] = 0x70                       # 8KB battery PRG RAM

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
