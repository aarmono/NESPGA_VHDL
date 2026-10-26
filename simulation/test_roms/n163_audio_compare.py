#!/usr/bin/env python3
"""Compare the audio of the n163.py audio ROM in nes_bench with Mesen's.

Usage: n163_audio_compare.py AUDIO.au MESEN.wav

As vrc6_audio_compare.py, for each segment of n163.SEGMENTS: the
fundamental frequency and its level, each divided by those of segment 1,
the APU pulse 1 at the frequency of the one channel of segment 0. The
segment of two channels sounding has no one frequency, so only the level
of its fundamental is compared.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import n163  # noqa: E402
import vrc6_audio_compare as compare  # noqa: E402

# Segments of more than one tone
MIXED_SEGMENTS = {8}


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    bench = compare.measure(*compare.read_au(sys.argv[1]),
                            compare.BENCH_FRAME, n163, set(),
                            MIXED_SEGMENTS)
    mesen = compare.measure(*compare.read_wav(sys.argv[2]),
                            compare.NTSC_FRAME, n163, set(),
                            MIXED_SEGMENTS)
    compare.report(bench, mesen)


if __name__ == '__main__':
    main()
