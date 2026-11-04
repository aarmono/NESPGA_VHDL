#!/usr/bin/env python3
"""Compare two CPU bus traces cycle by cycle.

Each trace has a line per CPU cycle:

    <cycle> <A0-A15 hex> <R|W|I> <D0-D7 hex or --> [extra columns...]

nes_bench writes one with -gTRACE_FILEPATH. Lines starting with # are skipped,
as are the columns after the data. The traces are aligned on their first read
of the reset vector ($FFFC), since what each does before reset ends differs.
Data is compared when both traces have it, which is only for writes in
nes_bench's trace.
"""
import argparse
import sys


def load(path):
    cycles = []
    with open(path) as f:
        for line in f:
            if line.startswith('#'):
                continue
            fields = line.split()
            if len(fields) < 4:
                continue
            addr = int(fields[1], 16) if 'X' not in fields[1] else None
            data = None if fields[3] == '--' else int(fields[3], 16)
            cycles.append((addr, fields[2], data))
    return cycles


def reset_index(cycles, path):
    for i, (addr, rw, _) in enumerate(cycles):
        if addr == 0xFFFC and rw == 'R':
            return i
    sys.exit(f'{path}: no read of $FFFC')


def fmt(c):
    addr, rw, data = c
    a = '????' if addr is None else f'{addr:04X}'
    d = '--' if data is None else f'{data:02X}'
    return f'{a} {rw} {d}'


def same(a, b, data=True):
    if a[0] != b[0] or a[1] != b[1]:
        return False
    return not data or a[2] is None or b[2] is None or a[2] == b[2]


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('expected', help='reference trace, such as the netlist sim')
    p.add_argument('actual', help='trace under test, such as nes_bench')
    p.add_argument('-c', '--context', type=int, default=8,
                   help='cycles shown before a mismatch')
    p.add_argument('-n', '--max-mismatches', type=int, default=1,
                   help='stop after this many mismatches')
    p.add_argument('--no-data', action='store_true',
                   help='compare only addresses and R/W, for runs whose RAMs power up differently')
    args = p.parse_args()

    exp = load(args.expected)
    act = load(args.actual)
    e0 = reset_index(exp, args.expected)
    a0 = reset_index(act, args.actual)
    n = min(len(exp) - e0, len(act) - a0)

    print(f'aligned on $FFFC: expected line {e0}, actual line {a0}; '
          f'comparing {n} cycles')
    mismatches = 0
    for i in range(n):
        e, a = exp[e0 + i], act[a0 + i]
        if same(e, a, not args.no_data):
            continue
        mismatches += 1
        print(f'\nmismatch {mismatches} at cycle {i} after the $FFFC read:')
        print(f'{"cycle":>9}  {"expected":<11}  actual')
        for j in range(max(0, i - args.context), min(n, i + 3)):
            mark = '>' if j == i else ' '
            print(f'{mark}{j:8}  {fmt(exp[e0 + j]):<11}  {fmt(act[a0 + j])}')
        if mismatches >= args.max_mismatches:
            break

    if mismatches == 0:
        print(f'match: {n} cycles')
        return 0
    return 1


if __name__ == '__main__':
    sys.exit(main())
