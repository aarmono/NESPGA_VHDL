#!/usr/bin/env python3
"""Compare the picture of a netlist video trace with nes_bench's.

The netlist trace (run_aprvisual.sh -v) has a little-endian uint32 per PPU
dot: bits 0-8 hpos, 9-17 vpos, 18-23 the colour and 24-26 the emphasis bits.
nes_bench's (-gVIDEO_TRACE_FILEPATH) has 2 bytes per visible pixel, the
colour then the emphasis bits, from the first frame that starts once the NES
is running.

The netlist's colour is the end of the 2C02's palette output pipeline, so
pixel x of a line is on it at hpos x+delay. The delay is a fixed property of
the chip; --calibrate finds it by trying each one. An error that shifts the
whole picture by the same amount can't be seen this way, but one that puts
some pixels at another position than the rest of the picture can.

Frames are numbered from the first whole frame of each trace, which is the
same frame when the traces come from runs aligned with power_up_seed.py.
"""
import argparse
import array
import sys

WIDTH = 256
HEIGHT = 240
FRAME_PIXELS = WIDTH * HEIGHT
DEFAULT_DELAY = 0


def load_netlist(path):
    """Frames of the netlist trace, each a dict of (vpos, hpos) -> value"""
    dots = array.array('I')
    with open(path, 'rb') as f:
        dots.frombytes(f.read())
    if sys.byteorder != 'little':
        dots.byteswap()
    frames = []
    frame = None
    for d in dots:
        h = d & 511
        v = d >> 9 & 511
        if v == 0 and h == 0:
            frame = {}
            frames.append(frame)
        if frame is not None:
            frame[v, h] = d >> 18 & 511
    if frames and len(frames[-1]) < 262 * 340:
        frames.pop()
    return frames


def load_bench(path):
    """Frames of the bench trace, each a list of values in raster order"""
    with open(path, 'rb') as f:
        data = f.read()
    values = [data[i] | data[i + 1] << 6 for i in range(0, len(data) - 1, 2)]
    return [values[i:i + FRAME_PIXELS]
            for i in range(0, len(values) - FRAME_PIXELS + 1, FRAME_PIXELS)]


def fmt(value):
    if value is None:
        return '--'
    colour, emphasis = value & 63, value >> 6
    return f'{colour:02X}' + (f'+e{emphasis}' if emphasis else '')


def mismatches(net, bench, delay):
    for y in range(HEIGHT):
        for x in range(WIDTH):
            n = net.get((y, x + delay))
            b = bench[y * WIDTH + x]
            if n != b:
                yield y, x, n, b


def runs(diffs):
    """Mismatches grouped into runs along a line"""
    run = None
    for y, x, n, b in diffs:
        if run and run[0] == y and run[2] == x - 1 and run[3] == n and run[4] == b:
            run[2] = x
        else:
            if run:
                yield run
            run = [y, x, x, n, b]
    if run:
        yield run


def write_ppm(path, net, bench, delay):
    """Netlist, bench and the mismatches side by side, palette-free: colour
    index as grey, mismatches white on black"""
    def grey(v):
        return 0 if v is None else (v & 63) * 4
    row_bytes = []
    for y in range(HEIGHT):
        row = bytearray()
        for x in range(WIDTH):
            g = grey(net.get((y, x + delay)))
            row += bytes((g, g, g))
        for x in range(WIDTH):
            g = grey(bench[y * WIDTH + x])
            row += bytes((g, g, g))
        for x in range(WIDTH):
            same = net.get((y, x + delay)) == bench[y * WIDTH + x]
            row += b'\0\0\0' if same else b'\xff\x00\x00'
        row_bytes.append(bytes(row))
    with open(path, 'wb') as f:
        f.write(b'P6 %d %d 255\n' % (3 * WIDTH, HEIGHT))
        f.write(b''.join(row_bytes))


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('netlist', help='run_aprvisual.sh -v trace')
    p.add_argument('bench', help='nes_bench -gVIDEO_TRACE_FILEPATH trace')
    p.add_argument('-d', '--delay', type=int, default=DEFAULT_DELAY,
                   help='hpos of pixel 0 in the netlist trace')
    p.add_argument('--calibrate', action='store_true',
                   help='count mismatches for each delay in up to 8 frames and use the best')
    p.add_argument('-s', '--start', type=int, default=0,
                   help='first frame to compare')
    p.add_argument('-r', '--runs', type=int, default=10,
                   help='mismatching runs shown for the first frame with any')
    p.add_argument('--ppm', help='write that frame side by side to this file')
    args = p.parse_args()

    net = load_netlist(args.netlist)
    bench = load_bench(args.bench)
    n = min(len(net), len(bench))
    print(f'{len(net)} netlist frames, {len(bench)} bench frames; comparing {n - args.start}')
    frames = range(args.start, n)

    delay = args.delay
    if args.calibrate:
        # A few frames spread over the run are enough
        sample = frames[::max(1, len(frames) // 8)]
        counts = {}
        for d in range(-8, 24):
            counts[d] = sum(1 for f in sample for _ in mismatches(net[f], bench[f], d))
        for d, c in counts.items():
            print(f'delay {d:3}: {c} mismatched pixels')
        delay = min(counts, key=counts.get)
        print(f'using delay {delay}')

    first = None
    total = 0
    for f in frames:
        c = sum(1 for _ in mismatches(net[f], bench[f], delay))
        total += c
        if c:
            print(f'frame {f}: {c} mismatched pixels')
            if first is None:
                first = f
    if first is None:
        print(f'match: {n - args.start} frames')
        return 0

    print(f'\nframe {first}, first mismatches (line, x range: netlist / bench):')
    for i, (y, x0, x1, nv, bv) in enumerate(runs(mismatches(net[first], bench[first], delay))):
        if i >= args.runs:
            break
        print(f'  line {y:3} x {x0:3}-{x1:3}: {fmt(nv)} / {fmt(bv)}')
    if args.ppm:
        write_ppm(args.ppm, net[first], bench[first], delay)
        print(f'wrote {args.ppm}')
    return 1


if __name__ == '__main__':
    sys.exit(main())
