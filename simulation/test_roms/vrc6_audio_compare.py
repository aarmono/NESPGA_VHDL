#!/usr/bin/env python3
"""Compare the audio of a vrc6.py audio ROM in nes_bench with Mesen's.

Usage: vrc6_audio_compare.py AUDIO.au MESEN.wav

The two cannot be compared sample by sample: Mesen filters its output and
the frame of nes_bench is not quite that of NTSC. Instead, for each segment
of vrc6.SEGMENTS, the fundamental frequency and the level of
its middle are measured in each file and divided by those of segment 1, the
APU pulse 1 at the period of the VRC6 pulse of segment 0. The level is the
amplitude of the fundamental, which Mesen's filters change little, unlike
the peak to peak level. A segment that outputs a constant level cannot be
compared, as Mesen filters the level out; its level is instead the peak to
peak level of its middle, which should be 0 in nes_bench and small in Mesen.
"""

import os
import struct
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vrc6  # noqa: E402

# The frame of nes_bench and of NTSC, in seconds
BENCH_FRAME = 0.0166772
NTSC_FRAME = 0.0166393

# The segment of the APU pulse that the others are measured against
APU_SEGMENT = 1
# Segments of a constant level
FLAT_SEGMENTS = {4, 13}
# Segments of more than one tone, which have no one frequency
MIXED_SEGMENTS = {10}


def read_au(path):
    data = open(path, 'rb').read()
    offset, _, _, rate = struct.unpack('>IIII', data[4:20])
    samples = np.frombuffer(data[offset:], dtype='>i2').astype(float)
    return samples, rate


def read_wav(path):
    w = wave.open(path)
    assert w.getsampwidth() == 2
    samples = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2')
    samples = samples.reshape(-1, w.getnchannels()).mean(axis=1)
    return samples.astype(float), w.getframerate()


# The first sample that differs from the start, which is the start of
# segment 0 after the silence before it
def first_sound(samples):
    base = samples[0]
    return int(np.argmax(np.abs(samples - base) > 50))


# The frequency and the amplitude of the fundamental, the highest peak of
# the spectrum
def fundamental(x, rate):
    window = np.hanning(len(x))
    spectrum = np.abs(np.fft.rfft((x - x.mean()) * window))
    spectrum[0] = 0
    k = int(np.argmax(spectrum))
    a, b, c = spectrum[k - 1:k + 2]
    # Parabolic interpolation of the peak
    offset = 0.5 * (a - c) / (a - 2 * b + c)
    amplitude = b - 0.25 * (a - c) * offset
    return (k + offset) * rate / len(x), 2 * amplitude / window.sum()


# The frequency from the crossings of the middle level, which is more exact
# than the spectrum for the unfiltered square waves of nes_bench
def frequency(x, rate):
    mid = (x.max() + x.min()) / 2
    up = np.flatnonzero((x[:-1] < mid) & (x[1:] >= mid))
    t = up + (mid - x[up]) / (x[up + 1] - x[up])
    return (len(t) - 1) * rate / (t[-1] - t[0])


# The starts of the segments. Each but the first is the first change after
# the silent frame before it: a quiet stretch of one to three frames. A frame
# count is not enough, since a vblank missed in polling makes a segment a
# frame longer
def find_onsets(samples, rate, frame, rom=vrc6):
    active = np.flatnonzero(np.abs(np.diff(samples)) > 20) + 1
    gaps = np.diff(active)
    onsets = [first_sound(samples)]
    for i in np.flatnonzero((gaps > 0.75 * frame * rate) &
                            (gaps < 3 * frame * rate)):
        start = active[i + 1]
        if start - onsets[-1] > 0.5 * rom.SEGMENT_FRAMES * frame * rate:
            onsets.append(start)
    assert len(onsets) == len(rom.SEGMENTS), len(onsets)
    return onsets


# The segments of rom, of which flat are of a constant level and mixed have
# no one frequency
def measure(samples, rate, frame, rom=vrc6, flat=FLAT_SEGMENTS,
            mixed=MIXED_SEGMENTS):
    length = rom.SEGMENT_FRAMES * frame
    ret = []
    for k, onset in enumerate(find_onsets(samples, rate, frame, rom)):
        lo = onset + int(0.2 * length * rate)
        hi = onset + int(0.8 * length * rate)
        x = samples[lo:hi]
        if k in flat:
            ret.append((None, np.ptp(x)))
        elif k in mixed:
            ret.append((None, fundamental(x, rate)[1]))
        else:
            ret.append((frequency(x, rate), fundamental(x, rate)[1]))
    return ret


def report(bench, mesen):
    bf0, bl0 = bench[APU_SEGMENT]
    mf0, ml0 = mesen[APU_SEGMENT]
    print('%3s  %22s  %22s' % ('seg', 'freq / APU (bench mesen)',
                               'level / APU (bench mesen)'))
    for k, ((bf, bl), (mf, ml)) in enumerate(zip(bench, mesen)):
        freq = '%10s %10s' % ('-', '-') if bf is None else \
            '%10.4f %10.4f' % (bf / bf0, mf / mf0)
        print('%3d  %22s  %10.3f %10.3f' % (k, freq, bl / bl0, ml / ml0))


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    report(measure(*read_au(sys.argv[1]), BENCH_FRAME),
           measure(*read_wav(sys.argv[2]), NTSC_FRAME))


if __name__ == '__main__':
    main()
