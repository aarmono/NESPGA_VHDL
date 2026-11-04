#!/usr/bin/env python3
"""Find a nes_bench POWER_UP_SEED that starts the PPU at a chosen position.

nes_bench -gPOWER_UP_FILL=true -gPOWER_UP_SEED=<seed> starts the PPU where 19
bits of the power up LFSR say (see lib_ppu.power_up_ppu_time). The LFSR's
state at the end of reset is linear in the seed over GF(2): it steps 0x4000
times in the RAM fill after 7 TRNG bytes are mixed in, and in simulation the
TRNG bytes are the same in every run. So the seed for a position is a
solution of 19 linear equations in its 31 bits.

The PPU loads the state from the last PPU cycle of reset. When the board
goes straight from the fill to running (no PRG or CHR RAM to clear, and the
bench never holds the NES in STATE_WAIT), the last fill step and the end of
reset are the same clock edge, so the PPU starts from the state one step
before the last. Boards that clear RAM after the fill (--clear) start from
the last state, which is also what nes_soc's ppu_start port shows.

Positions are lib_ppu's numbering: line 0 is the start of VBL (hardware
scanline 241), line 21 is visible scanline 0, and cycle c is hardware dot
c+1. The default, line 21 cycle 6 of an odd frame, starts the PPU where
AprVisual's netlist simulation has it relative to the CPU's reset with
run_aprvisual.sh's default CPU-PPU clock alignment (-k 1). It was measured
with ppu_vbl_nmi/rom_singles/04-nmi_control.nes, whose $2002 reads at the
VBL edge leave one position that matches its whole bus trace (984493 cycles):
a dot either way reads the VBL flag a read early or late, and an even frame
skips the pre-render dot on the wrong frames once rendering is on.
"""
import argparse

LFSR_TAPS = 0xC0000600000000   # x^56 + x^55 + x^35 + x^34 + 1, as power_up_fill
SEED_BITS = 31                 # POWER_UP_SEED is a natural
POS_BITS = 19                  # ppu_power_up_seed_t

# The constant part of the PPU's 19 bits (what seed 0 gives), measured from
# nes_bench runs, and the number of LFSR steps to the state the PPU loads
FILL_STEPS = 0x4000 + 7
DIRECT = (FILL_STEPS - 1, 39089)
CLEAR = (FILL_STEPS, 142695)


def lfsr_step(x):
    for _ in range(56):
        x = (x >> 1) ^ LFSR_TAPS if x & 1 else x >> 1
    return x


def columns(steps):
    """What each seed bit adds to the PPU's 19 bits"""
    cols = [1 << i for i in range(SEED_BITS)]
    for _ in range(steps):
        cols = [lfsr_step(c) for c in cols]
    return [c & (2**POS_BITS - 1) for c in cols]


def seed_for(line, cycle, frame, steps, const):
    target = (line | cycle << 9 | frame << 18) ^ const
    basis = {}
    for i, col in enumerate(columns(steps)):
        v, s = col, 1 << i
        for b in reversed(range(POS_BITS)):
            if not v >> b & 1:
                continue
            if b in basis:
                v ^= basis[b][0]
                s ^= basis[b][1]
            else:
                basis[b] = (v, s)
                break
    v, s = target, 0
    for b in reversed(range(POS_BITS)):
        if v >> b & 1:
            if b not in basis:
                raise SystemExit('no seed gives that position')
            v ^= basis[b][0]
            s ^= basis[b][1]
    return s


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('line', type=int, nargs='?', default=21, help='0-261')
    p.add_argument('cycle', type=int, nargs='?', default=6, help='0-340')
    p.add_argument('frame', type=int, nargs='?', default=1, help='0 or 1')
    p.add_argument('--clear', action='store_true',
                   help='the board clears PRG or CHR RAM after the fill')
    args = p.parse_args()
    if not (0 <= args.line < 262 and 0 <= args.cycle < 341 and args.frame in (0, 1)):
        p.error('position out of range')
    steps, const = CLEAR if args.clear else DIRECT
    print(seed_for(args.line, args.cycle, args.frame, steps, const))


if __name__ == '__main__':
    main()
