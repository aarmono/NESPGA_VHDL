#!/usr/bin/env python3
"""Generate test ROMs for the Bandai FCG boards (mappers 16, 153, 157, 159).

Usage: bandai.py OUT.nes VARIANT

The ROM checks, in order:
  1 PRG ROM: each 16KB bank at 0x8000 (register 8) and the last bank fixed
    at 0xC000. Each 16KB bank holds its number at SIG_LO and its complement
    at SIG_HI. A write to the range of the other chip is ignored
  2 CHR: with CHR ROM, the 1KB banks of registers 0-7, each holding its
    number at its first byte; with CHR RAM, 8KB unbanked. Read back through
    $2006/$2007 with rendering off
  3 The four mirroring modes (register 9)
  4 The read port at 0x6000-0x7FFF: open bus but bit 4 (the EEPROMs, which
    release SDA, so 1) and bit 3 (the Datach barcode reader, 0), or open
    bus throughout on the FCG-1/2; 153's PRG RAM in its place
  5... The EEPROMs, a group each: written and read back through register D
    by bit-banged I2C, with every byte acknowledged. Blank (0xFF) at power
    on. The X24C02 takes byte and page writes, random and sequential reads,
    and does not answer another device address
  then the IRQ counter: no IRQ while disabled; on 16_ines a write to
    0x600B-0x600C sets the counter itself, which 0x600A starts without
    copying the latch written at 0x800B-0x800C; then, for each count in
    TRIALS, the counter is set, started together with IRQs and a NOP sled
    is run. The IRQ handler stores the low byte of the return address at
    RESULTS + trial and compares it with EXPECTED, which is what Mesen gives

The result is shown in the backdrop with rendering off: color $2A (green)
on pass, otherwise the number of the group of checks that failed (1 is the
first); the index of the failing check within its group is at zero page
DETAIL. The result is up a few frames after reset, so 250ms of nes_bench is
enough.

Variants:
  16_4     NES 2.0 submapper 4: FCG-1/2, registers at 0x6000-0x7FFF, the
           counter written directly, no EEPROM
  16_5     NES 2.0 submapper 5 with 256 bytes of PRG RAM: LZ93D50,
           registers at 0x8000-0xFFFF, the counter written through a latch,
           an X24C02
  16_ines  iNES: the FCG-1/2 at 0x6000 and the LZ93D50 at 0x8000, an X24C02
  153      512KB of PRG ROM, 8KB of PRG RAM enabled by register D bit 5 and
           filled with 0xFF at power on, CHR RAM. Bit 0 of the CHR bank
           register selected by the PPU's last access (PPU A11-A10) is
           PRG A18
  157      The Datach: CHR RAM, an X24C02 and an X24C01 whose SCL is bit 3
           of the CHR bank register selected like 153's PRG A18
  159      An X24C01, which shifts bits LSB first

Mesen differs on the checks MESEN leaves out: the PRG RAM and EEPROMs are
not blank at power on, its EEPROMs pull SDA low until the first start, it
compares only bits 7 and 5 of the X24C02 device
address, selects 153's PRG A18 from all eight CHR bank registers rather
than the one the PPU selects, and runs both ranges of iNES 16 as the
LZ93D50.

There is no assembler on the build machine, so the 6502 code is assembled
here from opcodes.
"""

import sys

VARIANTS = {
    '16_4': dict(mapper=16, nes2=True, sub=4, fcg=True, lz=False,
                 eeproms=[]),
    '16_5': dict(mapper=16, nes2=True, sub=5, prg_ram=0x20, fcg=False,
                 lz=True, eeproms=['x24c02']),
    '16_ines': dict(mapper=16, nes2=False, sub=0, fcg=True, lz=True,
                    eeproms=['x24c02']),
    '153': dict(mapper=153, nes2=True, sub=0, prg_ram=0x70, chr_ram=0x07,
                prg_banks=32, fcg=False, lz=True, eeproms=[], wram=True),
    '157': dict(mapper=157, nes2=True, sub=0, prg_ram=0x10, chr_ram=0x07,
                fcg=False, lz=True, eeproms=['x24c02', 'datach']),
    '159': dict(mapper=159, nes2=True, sub=0, prg_ram=0x10, fcg=False,
                lz=True, eeproms=['x24c01']),
}

# Leave out the checks that Mesen is known to fail, to compare the rest with
# it (see above)
MESEN = False

PASS_COLOR = 0x2A

CHR_BANKS = 256

# The code is in the last 16KB bank, which is fixed at 0xC000. Each bank
# holds its number at SIG_LO and its complement at SIG_HI, clear of the code
# and the vectors
ORG = 0xC100
SIG_LO = 0x0010
SIG_HI = 0x3FF0

# Zero page
TRIAL = 0x00
# Bit 7 set: an IRQ now is a failure, of step FAIL_STEP. Bit 6 set: an IRQ
# is expected; the handler sets FLAG and returns with IRQs disabled
MODE = 0x01
FAIL_STEP = 0x02
DETAIL = 0x03
FLAG = 0x04
BYTE = 0x05
TMP = 0x06
ACK = 0x07
RESULTS = 0x10

# The IRQ counts of the timing trials
TRIALS = [0x0000, 0x0001, 0x0002, 0x0003, 0x0014, 0x0015, 0x0100]
SLED_NOPS = 160
# The low bytes of the return addresses Mesen gives for TRIALS, or None to
# only record them
EXPECTED = [0x00, 0x00, 0x01, 0x01, 0x0A, 0x0A, 0x80]

# The EEPROM line bits of register D
SCL = 0x20
SDA = 0x40


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
AND_IMM, ORA_IMM, STY_ZP = 0x29, 0x09, 0x84
LDA_ZP, STA_ZP, LDX_ZP, LDY_ZP, INC_ZP = 0xA5, 0x85, 0xA6, 0xA4, 0xE6
LDA_ABS_X, STA_ABS_X, STA_ZP_X = 0xBD, 0x9D, 0x95
ASL_ZP, LSR_ZP, ROL_ZP, ROR_ZP, LSR_A = 0x06, 0x46, 0x26, 0x66, 0x4A
PHA, PLA, JSR, RTS = 0x48, 0x68, 0x20, 0x60
BPL, BMI, BVS, BEQ, BNE, BCC = 0x10, 0x30, 0x70, 0xF0, 0xD0, 0x90
JMP_ABS, RTI = 0x4C, 0x40
SEI, CLI, CLD, TXS, TSX, NOP, DEX, DEY = (0x78, 0x58, 0xD8, 0x9A, 0xBA, 0xEA,
                                          0xCA, 0x88)


def build(v):
    a = Assembler()
    step = [1]
    detail = [0]
    prg_banks = v.get('prg_banks', 16)
    chr_ram = 'chr_ram' in v
    # The registers written for the checks that are not about the range
    base = 0x8000 if v['lz'] else 0x6000

    def next_group():
        step[0] += 1
        detail[0] = 0
        assert step[0] < PASS_COLOR

    def wait_vblank(name):
        a.label(name)
        a.abs(BIT_ABS, 0x2002)
        a.branch(BPL, name)

    def write(addr, value):
        a.emit(LDA_IMM, value)
        a.abs(STA_ABS, addr)

    def reg(idx, value, at=None):
        write((base if at is None else at) + idx, value)

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

    def zp_check(addr, value):
        a.emit(LDA_ZP, addr)
        check(value)

    def bank_check(window, bank):
        cpu_check(window + SIG_LO, bank)
        cpu_check(window + SIG_HI, bank ^ 0xFF)

    # Waits about 5 * count CPU cycles
    def delay(count):
        a.emit(LDX_IMM, count)
        a.emit(DEX)
        a.emit(BNE, 0xFD)

    # Runs code with IRQs enabled for a while, and checks that an IRQ came
    # (FLAG 1) or did not
    def expect_irq(came):
        a.emit(LDA_IMM, 0x00)
        a.emit(STA_ZP, FLAG)
        a.emit(LDA_IMM, 0x40)
        a.emit(STA_ZP, MODE)
        a.emit(CLI)
        delay(60)
        a.emit(SEI)
        a.emit(LDA_IMM, 0x80)
        a.emit(STA_ZP, MODE)
        zp_check(FLAG, 1 if came else 0)

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

    # 153's PRG RAM is checked blank before anything else touches it
    if v.get('wram') and not MESEN:
        cpu_check(0x6000, 0xFF)
        cpu_check(0x7FFF, 0xFF)

    # 1: PRG ROM
    for b in range(16):
        reg(8, b)
        bank_check(0x8000, b)
    bank_check(0xC000, 15)
    reg(8, 5)
    other = 0x6000 if v['lz'] and not v['fcg'] else 0x8000
    if not (v['lz'] and v['fcg']):
        reg(8, 9, at=other)
        bank_check(0x8000, 5)
    if v.get('wram'):
        # The outer bank, from bit 0 of the CHR bank register of the PPU's
        # last access, which reads at 0x0000 select (register 0)
        ppu_addr(0x0000)
        a.abs(LDA_ABS, 0x2007)
        for r in range(4):
            reg(r, 0x01)
        bank_check(0x8000, 16 + 5)
        bank_check(0xC000, 31)
        if not MESEN:
            # Only register 1 has bit 0 set: a read at 0x0400 selects it,
            # one at 0x0800 register 2
            for r in range(4):
                reg(r, 0x01 if r == 1 else 0x00)
            bank_check(0x8000, 5)
            ppu_addr(0x0400)
            a.abs(LDA_ABS, 0x2007)
            bank_check(0x8000, 16 + 5)
            bank_check(0xC000, 31)
            ppu_addr(0x0800)
            a.abs(LDA_ABS, 0x2007)
            bank_check(0x8000, 5)
        for r in range(4):
            reg(r, 0x00)
        bank_check(0xC000, 15)
    next_group()

    # 2: CHR
    if chr_ram:
        for w in range(8):
            ppu_write(0x400 * w, 0xC0 + w)
            ppu_write(0x400 * w + 0x3FF, 0x30 + w)
        for w in range(8):
            ppu_check(0x400 * w, 0xC0 + w)
            ppu_check(0x400 * w + 0x3FF, 0x30 + w)
    else:
        chr_banks = [(w * 37 + 0xC5) % CHR_BANKS for w in range(8)]
        for w, b in enumerate(chr_banks):
            reg(w, b)
        for w, b in enumerate(chr_banks):
            ppu_check(0x400 * w, b)
    next_group()

    # 3: Mirroring. Each of the four nametables is written with its own byte,
    # so the bytes read back show which share CIRAM
    def nt_test(mode, expect):
        reg(9, mode)
        for i in range(4):
            ppu_write(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + i)
        for i in range(4):
            ppu_check(0x2000 + 0x400 * i, 0x40 + 0x10 * mode + expect[i])

    nt_test(0, [2, 3, 2, 3])
    nt_test(1, [1, 1, 3, 3])
    nt_test(2, [3, 3, 3, 3])
    nt_test(3, [3, 3, 3, 3])
    reg(9, 2)
    ppu_check(0x2400, 0x63)
    next_group()

    # 4: The read port, or 153's PRG RAM. Open bus is the high byte of the
    # address
    if v.get('wram'):
        reg(0xD, 0x20)
        write(0x6000, 0xA5)
        write(0x7FFF, 0x5A)
        cpu_check(0x6000, 0xA5)
        cpu_check(0x7FFF, 0x5A)
        reg(0xD, 0x00)
        cpu_check(0x6000, 0x60)
        write(0x6000, 0x11)
        reg(0xD, 0x20)
        cpu_check(0x6000, 0xA5)
    elif v['lz']:
        if not MESEN:
            cpu_check(0x6000, 0x70)
            cpu_check(0x7FF0, 0x77)
    else:
        cpu_check(0x6000, 0x60)
    next_group()

    # The EEPROMs, each with its routines
    def eeprom_routines(chip):
        msb = chip == 'x24c02'
        p = chip + '_'

        # Puts out the lines in A (SCL and SDA as in register D). The Datach
        # X24C01 has SCL on bit 3 of the CHR bank registers, written to all
        # four, and register D's SCL held low for the X24C02
        a.label(p + 'lines')
        if chip == 'datach':
            a.emit(PHA)
            a.emit(AND_IMM, SDA)
            a.abs(STA_ABS, 0x800D)
            a.emit(PLA)
            a.emit(AND_IMM, SCL)
            a.emit(LSR_A, LSR_A)
            for r in range(4):
                a.abs(STA_ABS, 0x8000 + r)
        else:
            a.abs(STA_ABS, 0x800D)
        a.emit(RTS)

        def lines(value):
            a.emit(LDA_IMM, value)
            a.abs_label(JSR, p + 'lines')

        a.label(p + 'start')
        lines(SDA)
        lines(SDA | SCL)
        lines(SCL)
        lines(0)
        a.emit(RTS)

        a.label(p + 'stop')
        lines(0)
        lines(SCL)
        lines(SDA | SCL)
        a.emit(RTS)

        # Sends BYTE, then clocks the acknowledge into ACK (0 if acknowledged)
        a.label(p + 'send')
        a.emit(LDY_IMM, 8)
        a.label(p + 'send_bit')
        a.emit(ASL_ZP if msb else LSR_ZP, BYTE)
        a.emit(LDA_IMM, 0)
        a.emit(BCC, 2)
        a.emit(LDA_IMM, SDA)
        a.emit(STA_ZP, TMP)
        a.abs_label(JSR, p + 'lines')
        a.emit(LDA_ZP, TMP)
        a.emit(ORA_IMM, SCL)
        a.abs_label(JSR, p + 'lines')
        a.emit(LDA_ZP, TMP)
        a.abs_label(JSR, p + 'lines')
        a.emit(DEY)
        a.branch(BNE, p + 'send_bit')
        lines(SDA)
        lines(SDA | SCL)
        a.abs(LDA_ABS, 0x6000)
        a.emit(AND_IMM, 0x10)
        a.emit(STA_ZP, ACK)
        lines(SDA)
        a.emit(RTS)

        # Reads a byte into BYTE
        a.label(p + 'recv')
        lines(SDA)
        a.emit(LDY_IMM, 8)
        a.label(p + 'recv_bit')
        lines(SDA | SCL)
        a.abs(LDA_ABS, 0x6000)
        a.emit(AND_IMM, 0x10)
        a.emit(CMP_IMM, 0x10)
        a.emit(ROL_ZP if msb else ROR_ZP, BYTE)
        lines(SDA)
        a.emit(DEY)
        a.branch(BNE, p + 'recv_bit')
        a.emit(RTS)

        # The master acknowledges a byte read, or does not
        a.label(p + 'ack')
        lines(0)
        lines(SCL)
        lines(0)
        a.emit(RTS)

        a.label(p + 'nack')
        lines(SDA)
        lines(SDA | SCL)
        lines(SDA)
        a.emit(RTS)

    def call(chip, name):
        a.abs_label(JSR, chip + '_' + name)

    # Sends value, which must be acknowledged
    def send(chip, value, acked=True):
        a.emit(LDA_IMM, value)
        a.emit(STA_ZP, BYTE)
        call(chip, 'send')
        zp_check(ACK, 0x00 if acked else 0x10)

    def recv_check(chip, value):
        call(chip, 'recv')
        zp_check(BYTE, value)

    # Writes the bytes at addr, then reads them back one at a time and, on
    # the X24C02, all together
    def x24c02_write(chip, addr, values):
        call(chip, 'start')
        send(chip, 0xA0)
        send(chip, addr)
        for value in values:
            send(chip, value)
        call(chip, 'stop')

    def x24c02_read(chip, addr, values):
        call(chip, 'start')
        send(chip, 0xA0)
        send(chip, addr)
        call(chip, 'start')
        send(chip, 0xA1)
        for i, value in enumerate(values):
            if i:
                call(chip, 'ack')
            recv_check(chip, value)
        call(chip, 'nack')
        call(chip, 'stop')

    def x24c01_write(chip, addr, value):
        call(chip, 'start')
        send(chip, addr)
        send(chip, value)
        call(chip, 'stop')

    def x24c01_read(chip, addr, value):
        call(chip, 'start')
        send(chip, 0x80 | addr)
        recv_check(chip, value)
        call(chip, 'nack')
        call(chip, 'stop')

    def eeprom_checks(chip):
        if chip == 'x24c02':
            if not MESEN:
                x24c02_read(chip, 0x00, [0xFF])
                x24c02_read(chip, 0xFF, [0xFF])
            x24c02_write(chip, 0x05, [0x12])
            x24c02_write(chip, 0x40, [0x34, 0x56, 0x78])
            x24c02_read(chip, 0x05, [0x12])
            x24c02_read(chip, 0x40, [0x34, 0x56, 0x78])
            x24c02_read(chip, 0x41, [0x56])
            # The current address read: after 0x41, 0x42
            call(chip, 'start')
            send(chip, 0xA1)
            recv_check(chip, 0x78)
            call(chip, 'nack')
            call(chip, 'stop')
            if not MESEN:
                # Another device address is not answered
                call(chip, 'start')
                send(chip, 0xA2, acked=False)
                call(chip, 'stop')
                x24c02_read(chip, 0x05, [0x12])
        else:
            if not MESEN:
                x24c01_read(chip, 0x00, 0xFF)
                x24c01_read(chip, 0x7F, 0xFF)
            x24c01_write(chip, 0x03, 0x9A)
            x24c01_write(chip, 0x7E, 0xBC)
            x24c01_read(chip, 0x03, 0x9A)
            x24c01_read(chip, 0x7E, 0xBC)
            x24c01_write(chip, 0x03, 0x9B)
            x24c01_read(chip, 0x03, 0x9B)

    if v['eeproms']:
        a.abs_label(JMP_ABS, 'eeprom_checks')
        for chip in v['eeproms']:
            eeprom_routines(chip)
        a.label('eeprom_checks')
        # Register D idle: SCL and SDA high
        reg(0xD, SDA | SCL)
        # Mesen's EEPROMs pull SDA low until their first start, and the
        # Datach's X24C01 would hide the X24C02
        if 'datach' in v['eeproms']:
            call('datach', 'start')
            call('datach', 'stop')
        for chip in v['eeproms']:
            eeprom_checks(chip)
            # Released after a stop
            cpu_check(0x6000, 0x70)
            next_group()
        # The Datach's two EEPROMs hold their own bytes at the same address
        if len(v['eeproms']) == 2:
            x24c02_write('x24c02', 0x03, [0x77])
            x24c01_read('datach', 0x03, 0x9B)
            x24c02_read('x24c02', 0x03, [0x77])
            next_group()

    # The IRQ counter. irq_reg writes the counter, or its latch, of the
    # chip at base
    irq_base = base

    def irq_reg(idx, value):
        write(irq_base + idx, value)

    # The counter wraps with IRQs disabled
    a.emit(LDA_IMM, step[0])
    a.emit(STA_ZP, FAIL_STEP)
    next_group()
    irq_reg(0xA, 0x00)
    irq_reg(0xB, 0x05)
    irq_reg(0xC, 0x00)
    irq_reg(0xA, 0x00)
    a.emit(CLI)
    delay(20)
    a.emit(SEI)

    if v['fcg'] and v['lz'] and not MESEN:
        # 0x600B-0x600C set the counter, 0x800B-0x800C the latch, and 0x600A
        # starts the counter without copying the latch. Then 0x800A copies
        # the latch, and starts the counter for longer than the wait
        write(0x600B, 0x14)
        write(0x600C, 0x00)
        write(0x800B, 0x00)
        write(0x800C, 0x20)
        write(0x600A, 0x01)
        expect_irq(True)
        write(0x600A, 0x00)
        write(0x800A, 0x01)
        expect_irq(False)
        write(0x800A, 0x00)
        next_group()

    # The timing trials. The IRQ handler starts the next one
    a.emit(LDA_IMM, 0x00)
    a.emit(STA_ZP, MODE)
    a.label('trial')
    a.emit(LDX_ZP, TRIAL)
    a.abs_label(LDA_ABS_X, 'trials_lo')
    a.abs(STA_ABS, irq_base + 0xB)
    a.abs_label(LDA_ABS_X, 'trials_hi')
    a.abs(STA_ABS, irq_base + 0xC)
    a.emit(LDA_IMM, 0x01)
    a.emit(CLI)
    a.abs(STA_ABS, irq_base + 0xA)
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
    a.branch(BMI, 'irq_fail')
    a.branch(BVS, 'irq_expected')
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0102)                    # return address, low byte
    a.emit(LDX_ZP, TRIAL)
    a.emit(STA_ZP_X, RESULTS)
    irq_reg(0xA, 0x00)                          # acknowledge
    a.emit(LDX_IMM, 0xFF, TXS)
    a.emit(INC_ZP, TRIAL)
    a.emit(LDA_ZP, TRIAL)
    a.emit(CMP_IMM, len(TRIALS))
    a.branch(BEQ, 'irq_done')
    a.abs_label(JMP_ABS, 'trial')
    a.label('irq_done')
    a.abs_label(JMP_ABS, 'trials_done')
    # An expected IRQ returns with IRQs disabled, since it is not
    # acknowledged
    a.label('irq_expected')
    a.emit(LDA_IMM, 0x01)
    a.emit(STA_ZP, FLAG)
    a.emit(TSX)
    a.abs(LDA_ABS_X, 0x0101)                    # status
    a.emit(ORA_IMM, 0x04)
    a.abs(STA_ABS_X, 0x0101)
    a.emit(RTI)
    a.label('irq_fail')
    a.emit(LDX_ZP, FAIL_STEP)
    a.emit(LDY_IMM, 0x00)
    a.abs_label(JMP_ABS, 'show')

    a.label('trials_lo')
    a.emit(*[t & 0xFF for t in TRIALS])
    a.label('trials_hi')
    a.emit(*[t >> 8 for t in TRIALS])

    a.label('nmi')
    a.emit(RTI)

    code = a.link()
    assert ORG + len(code) <= 0xC000 + SIG_HI, 'code runs into SIG_HI'

    prg = bytearray([0xFF]) * (0x4000 * prg_banks)
    for b in range(prg_banks):
        prg[0x4000 * b + SIG_LO] = b
        prg[0x4000 * b + SIG_HI] = b ^ 0xFF

    # The code is in the last bank of each 256KB outer bank
    for last in range(15, prg_banks, 16):
        off = 0x4000 * last + ORG - 0xC000
        prg[off:off + len(code)] = code
        for vec, name in ((0xFFFA, 'nmi'), (0xFFFC, 'reset'), (0xFFFE, 'irq')):
            off = 0x4000 * last + vec - 0xC000
            prg[off] = a.labels[name] & 0xFF
            prg[off + 1] = a.labels[name] >> 8

    if chr_ram:
        chr_rom = bytearray()
    else:
        chr_rom = bytearray(0x400 * CHR_BANKS)
        for b in range(CHR_BANKS):
            chr_rom[0x400 * b] = b

    mapper = v['mapper']
    header = bytearray(b'NES\x1a')
    header += bytes([len(prg) // 0x4000, len(chr_rom) // 0x2000,
                     ((mapper & 0x0F) << 4) | 0x01 |
                     (0x02 if 'prg_ram' in v else 0x00),
                     (mapper & 0xF0) | (0x08 if v['nes2'] else 0x00)])
    header += bytes(8)
    if v['nes2']:
        header[8] = v['sub'] << 4
        header[10] = v.get('prg_ram', 0)
        header[11] = v.get('chr_ram', 0)

    return bytes(header + prg + chr_rom)


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in VARIANTS:
        sys.exit(__doc__)
    with open(sys.argv[1], 'wb') as f:
        f.write(build(VARIANTS[sys.argv[2]]))


if __name__ == '__main__':
    main()
