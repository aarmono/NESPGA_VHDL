#!/usr/bin/env python3
"""Check the 5B audio of the fme7.py audio ROMs in nes_bench.

Usage: s5b_audio_check.py {audio,audio_ext} AUDIO.au [MESEN.wav]

Each segment of fme7.TONE_SEGMENTS (audio) or fme7.EXT_SEGMENTS (audio_ext)
is checked against what nesdev describes of the 5B, from the samples of
nes_bench, which are the mixed level exactly, sampled every 10416ns:
  tone        the frequency is CPU / (32 * period) and the level the DAC
              level of the volume
  mixed       the highest level is the sum of the DAC levels
  const       every sample is the DAC level
  noise       the samples are 0 or the DAC level, in bits of 32 * period
              CPU cycles, and the bits follow the 17-bit shift register with
              taps at bits 16 and 13: b[n + 17] == b[n] ^ b[n + 3]
  tone_noise  the level is never on for longer than half the tone
  env         the levels are the envelope shape, a step every 16 * period
              CPU cycles
  env_freq    the sawtooth is CPU / (512 * period), period 0 being 1
  env_tone    the tone reaches the loudest level and some in between

With MESEN.wav, the audio ROM is also compared with Mesen as
vrc6_audio_compare.py does: frequency and level relative to segment 1, the
APU pulse 1. The level of the last segment, the 5B and the APU at the same
frequency, depends on the phase of the two, which differs from Mesen's. At
volume 4 Mesen is lower, since it truncates its volume table.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fme7  # noqa: E402
import vrc6_audio_compare as compare  # noqa: E402

# A CPU cycle of nes_bench is 560ns, and it writes a sample every 10416ns
CPU_RATE = 1e9 / 560
SAMPLE_RATE = 1e9 / 10416
FRAME = compare.BENCH_FRAME

# The DAC of lib_sunsoft_5b_audio, in levels of the mixed audio
DAC = [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4, 4, 5, 6, 7, 9,
       10, 12, 14, 17, 20, 24, 29, 34, 41, 48, 57, 68, 81, 96, 114, 136]


def read_levels(path):
    samples, _ = compare.read_au(path)
    # The 10-bit mixed level is in the high bits of the 16-bit samples
    levels = np.round(samples / 32).astype(int)
    return levels - levels[0]


# The start of each segment: the first sound after at least 0.75 frames of
# silence, searched for from a little after the end of the segment before.
# The end of a segment that is silent at its end is not a change, so
# segments cannot be found by their changes
def find_onsets(levels, count):
    quiet = int(0.75 * FRAME * SAMPLE_RATE)
    loud = np.flatnonzero(levels != 0)
    # The sounds with a quiet stretch before them
    starts = loud[np.concatenate(([True], np.diff(loud) > quiet))]
    onsets = [int(starts[0])]
    for _ in range(count - 1):
        later = starts[starts >= onsets[-1] +
                       int((fme7.SEGMENT_FRAMES + 0.5) * FRAME * SAMPLE_RATE)]
        assert len(later), 'segment %d not found' % len(onsets)
        onsets.append(int(later[0]))
    return onsets


# Runs of equal levels: (level, length) pairs
def runs(x):
    edges = np.flatnonzero(np.diff(x)) + 1
    starts = np.concatenate(([0], edges))
    ends = np.concatenate((edges, [len(x)]))
    return [(int(x[s]), int(e - s)) for s, e in zip(starts, ends)]


def check_tone(x, period, volume):
    expect_f = CPU_RATE / (32 * max(period, 1))
    f = compare.frequency(x.astype(float), SAMPLE_RATE)
    ok = abs(f / expect_f - 1) < 0.002
    levels = set(np.unique(x))
    ok = ok and levels == {0, DAC[2 * volume + 1]}
    return ok, 'freq %.2f (%.2f) levels %s (%d)' % (
        f, expect_f, sorted(levels), DAC[2 * volume + 1])


def check_mixed(x, levels):
    expect = sum(DAC[level] for level in levels)
    # With the APU too, the APU's own level is added
    if len(levels) == 1:
        return x.max() > expect, 'max %d (> %d)' % (x.max(), expect)
    return x.max() == expect, 'max %d (%d)' % (x.max(), expect)


def check_const(x, level):
    values = sorted(set(np.unique(x)))
    return values == [DAC[level]], 'levels %s (%d)' % (values, DAC[level])


def check_noise(x, period, level):
    values = set(np.unique(x))
    if values != {0, DAC[level]}:
        return False, 'levels %s (0, %d)' % (sorted(values), DAC[level])
    # The first and last runs are cut short by the window
    r = runs(x)[1:-1]
    bit = 32 * max(period, 1) / CPU_RATE * SAMPLE_RATE
    # Refine the bit length from the runs, then count the bits of each
    for _ in range(3):
        counts = [max(1, round(n / bit)) for _, n in r]
        bit = sum(n for _, n in r) / sum(counts)
    expect_bit = 32 * max(period, 1) / CPU_RATE * SAMPLE_RATE
    counts = [max(1, round(n / bit)) for _, n in r]
    off = max(abs(n - c * bit) for (_, n), c in zip(r, counts))
    bits = np.concatenate([np.full(c, v != 0) for (v, _), c in zip(r, counts)])
    bad = np.count_nonzero(bits[17:] != (bits[:-17] ^ bits[3:-14]))
    ok = abs(bit / expect_bit - 1) < 0.002 and bad == 0 and off < 1.5
    return ok, 'bit %.3f samples (%.3f), %d bits, %d off the LFSR, ' \
        'worst run error %.2f samples' % (bit, expect_bit, len(bits), bad, off)


def check_tone_noise(x, period, level):
    half = 16 * max(period, 1) / CPU_RATE * SAMPLE_RATE
    on = [n for v, n in runs(x) if v != 0]
    values = set(np.unique(x))
    ok = values == {0, DAC[level]} and max(on) <= half + 1 and len(on) > 10
    return ok, 'levels %s, longest on %d samples (half tone %.1f)' % (
        sorted(values), max(on), half)


# The 5-bit levels of the shape, one per step, for steps steps
def envelope_levels(shape, steps):
    attack = bool(shape & 4)
    if shape & 8:
        hold, alternate = bool(shape & 1), bool(shape & 2)
    else:
        hold, alternate = True, attack
    invert = attack
    ret = []
    while len(ret) < steps:
        ramp = list(range(31, -1, -1))
        ret.extend(31 - s if invert else s for s in ramp)
        if alternate:
            invert = not invert
        if hold:
            ret.extend([31 if invert else 0] * steps)
    return ret[:steps]


def check_env(x, shape, period):
    step = 16 * max(period, 1) / CPU_RATE * SAMPLE_RATE
    steps = int(len(x) / step) + 2
    expect = [DAC[level] for level in envelope_levels(shape, steps)]
    # The segment starts at the first sound, which for a ramp up is at step 2
    lead = next(i for i, v in enumerate(expect) if v != 0)
    expect_runs = runs(np.array(expect[lead:]))
    got = runs(x)[:-1]
    n = min(len(got), len(expect_runs) - 1)
    if n == 0:
        return False, 'no runs'
    values_ok = [v for v, _ in got[:n]] == [v for v, _ in expect_runs[:n]]
    # Each run is within a sample or so of its steps
    worst = max(abs(g - e * step) for (_, g), (_, e) in
                zip(got[:n], expect_runs[:n]))
    ok = values_ok and worst < 1.5
    return ok, '%d runs match: %s, worst length error %.2f samples ' \
        '(step %.2f)' % (n, values_ok, worst, step)


def check_env_freq(x, period):
    expect_f = CPU_RATE / (512 * max(period, 1))
    f = compare.frequency(x.astype(float), SAMPLE_RATE)
    return abs(f / expect_f - 1) < 0.005, 'freq %.1f (%.1f)' % (f, expect_f)


def check_env_tone(x, period):
    values = set(np.unique(x))
    ok = max(values) == DAC[31] and len(values) > 8
    return ok, '%d levels, max %d' % (len(values), max(values))


CHECKS = {
    'tone': check_tone,
    'mixed': check_mixed,
    'const': check_const,
    'noise': check_noise,
    'tone_noise': check_tone_noise,
    'env': check_env,
    'env_freq': check_env_freq,
    'env_tone': check_env_tone,
}


def check(levels, segments):
    length = int(fme7.SEGMENT_FRAMES * FRAME * SAMPLE_RATE)
    failed = 0
    for k, (onset, (_, expect)) in enumerate(
            zip(find_onsets(levels, len(segments)), segments)):
        kind, args = expect[0], expect[1:]
        if kind == 'apu':
            print('%2d  apu' % k)
            continue
        # The envelope from its start; the others from their middle
        if kind == 'env':
            x = levels[onset:onset + int(0.95 * length)]
        else:
            x = levels[onset + int(0.2 * length):onset + int(0.8 * length)]
        ok, detail = CHECKS[kind](x, *args)
        failed += not ok
        print('%2d  %-4s %-10s %s' % (k, 'ok' if ok else 'FAIL', kind, detail))
    return failed


# The starts of the segments in Mesen's WAV: the first sharp change after
# 0.75 frames without one, at least half a segment after the start before.
# Mesen's filters keep its output changing into the silence after a loud
# segment, but slowly, unlike the edges of a tone
def find_mesen_onsets(samples, rate, count):
    frame = compare.NTSC_FRAME * rate
    sharp = np.flatnonzero(np.abs(np.diff(samples)) > 100) + 1
    starts = sharp[np.concatenate(([True], np.diff(sharp) > 0.75 * frame))]
    onsets = [int(starts[0])]
    for _ in range(count - 1):
        later = starts[starts >= onsets[-1] +
                       0.5 * fme7.SEGMENT_FRAMES * frame]
        assert len(later), 'segment %d not found' % len(onsets)
        onsets.append(int(later[0]))
    return onsets


# The frequency and the level of the fundamental of the middle of each
# segment
def measure(samples, rate, frame, segments, onsets):
    length = fme7.SEGMENT_FRAMES * frame * rate
    ret = []
    for onset, (_, expect) in zip(onsets, segments):
        x = samples[onset + int(0.2 * length):onset + int(0.8 * length)]
        level = compare.fundamental(x, rate)[1]
        if expect[0] == 'mixed':
            ret.append((None, level))
        else:
            ret.append((compare.frequency(x, rate), level))
    return ret


def compare_mesen(au, wav):
    segments = fme7.TONE_SEGMENTS
    samples, rate = compare.read_au(au)
    bench_onsets = [int(n * rate / SAMPLE_RATE) for n in
                    find_onsets(read_levels(au), len(segments))]
    bench = measure(samples, rate, FRAME, segments, bench_onsets)
    samples, rate = compare.read_wav(wav)
    mesen = measure(samples, rate, compare.NTSC_FRAME, segments,
                    find_mesen_onsets(samples, rate, len(segments)))
    compare.report(bench, mesen)


def main():
    if len(sys.argv) not in (3, 4) or sys.argv[1] not in ('audio',
                                                          'audio_ext'):
        sys.exit(__doc__)
    segments = fme7.TONE_SEGMENTS if sys.argv[1] == 'audio' else \
        fme7.EXT_SEGMENTS
    failed = check(read_levels(sys.argv[2]), segments)
    print('%d failed' % failed)
    if len(sys.argv) == 4:
        compare_mesen(sys.argv[2], sys.argv[3])
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
