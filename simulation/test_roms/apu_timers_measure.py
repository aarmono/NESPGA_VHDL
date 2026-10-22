#!/usr/bin/env python3
"""Measure the timer periods of an apu_timers.py ROM in audio.au of nes_bench
or in a WAV of Mesen.

Usage: apu_timers_measure.py AUDIO.au|MESEN.wav

For each segment of apu_timers.SEGMENTS, the period of its waveform is
found by folding: the samples are binned by their phase at a trial period,
and the trial period at which the samples vary least within the bins is the
period of the waveform. The samples are points in time that are not locked
to the CPU clock, so a period is found to a small fraction of a CPU cycle.
Bins rather than the differences of samples sorted by phase, since at a
trial period of a whole number of samples those differences are small
whatever the waveform. A bin is no narrower than half a sample, or bins of
a few samples each make the samples of steps shorter than a sample look
alike at the wrong period.

The period is divided by the number of steps in the waveform to give the
step, the period of the timer, in CPU cycles, which is compared with that
of hardware.

The trial periods are between 0.75 and 1.3 times that of hardware, which
leaves out the halves and the 4/3 of it, where a noise waveform of 31
steps is also smooth.
"""

import os
import struct
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import apu_timers  # noqa: E402

# The NTSC CPU clock of Mesen, in Hz
NTSC_CPU_HZ = 236.25e6 / 11 / 12
# The sample period of nes_bench, in ns
BENCH_SAMPLE_NS = 10416

LO, HI = 0.75, 1.3
# Bins per step of the waveform, unless that makes them narrower than half
# a sample
STEP_BINS = 16
# Each window of the search holds at least this many samples per bin and
# this many periods
BIN_SAMPLES = 8
MIN_PERIODS = 4


# The samples and the time of each, in CPU cycles
def read_au(path):
    data = open(path, 'rb').read()
    offset = struct.unpack('>I', data[4:8])[0]
    x = np.frombuffer(data[offset:], dtype='>i2').astype(float)
    return x, np.arange(len(x)) * BENCH_SAMPLE_NS / apu_timers.CPU_NS


def read_wav(path):
    w = wave.open(path)
    assert w.getsampwidth() == 2
    x = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2')
    x = x.reshape(-1, w.getnchannels()).mean(axis=1).astype(float)
    return x, np.arange(len(x)) * NTSC_CPU_HZ / w.getframerate()


# The sum of the squares of the samples from the means of their bins
def roughness(x, t, period, bins):
    b = (np.mod(t, period) * (bins / period)).astype(int)
    count = np.bincount(b, minlength=bins)
    total = np.bincount(b, weights=x, minlength=bins)
    used = count > 0
    return np.sum(x ** 2) - np.sum(total[used] ** 2 / count[used])


def best(x, t, periods, bins):
    scores = [roughness(x, t, p, bins) for p in periods]
    return periods[int(np.argmin(scores))]


# The period of the waveform, in CPU cycles
def fold_period(x, t, seg):
    hw = seg.step * seg.steps
    n = len(x)
    sample = (t[-1] - t[0]) / (n - 1)
    bins = int(hw / max(seg.step / STEP_BINS, sample / 2))
    # The grid spacing at which the phase of a window drifts by a quarter
    # step from one trial period to the next
    def spacing(m):
        return seg.step / 4 * hw / (t[m - 1] - t[0])

    m = min(n, max(BIN_SAMPLES * bins,
                   int(np.searchsorted(t - t[0], MIN_PERIODS * hw))))
    d = spacing(m)
    p = best(x[:m], t[:m], np.arange(LO * hw, HI * hw, d), bins)
    while m < n:
        m = min(n, 4 * m)
        p = best(x[:m], t[:m], np.linspace(p - 2 * d, p + 2 * d, 41), bins)
        d = spacing(m)
    # Finally to a tenth of the last spacing
    return best(x, t, np.linspace(p - 2 * d, p + 2 * d, 41), bins)


# The first sample that differs from the start, which is the start of
# segment 0 after the silence before it
def first_sound(x):
    return int(np.argmax(np.abs(x - x[0]) > 50))


def measure(x, t):
    frame = apu_timers.FRAME_CYCLES
    start = t[first_sound(x)]
    ret = []
    for seg in apu_timers.SEGMENTS:
        # Leave out the start, where the waveform may not have started, and
        # the end, which may be off by a part of a frame
        lo = np.searchsorted(t, start + 0.15 * seg.frames * frame)
        hi = np.searchsorted(t, start + 0.9 * seg.frames * frame)
        ret.append(fold_period(x[lo:hi], t[lo:hi], seg) / seg.steps)
        start += (seg.frames + 1) * frame
    return ret


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    path = sys.argv[1]
    x, t = (read_wav if path.endswith('.wav') else read_au)(path)
    print('%-16s %10s %10s %9s' % ('segment', 'hardware', 'measured',
                                   'error'))
    for seg, step in zip(apu_timers.SEGMENTS, measure(x, t)):
        print('%-16s %10d %10.3f %8.3f%%' %
              (seg.name, seg.step, step, 100 * (step / seg.step - 1)))


if __name__ == '__main__':
    main()
