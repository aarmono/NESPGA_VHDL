#!/usr/bin/env python3
"""Compare the audio of the mmc5_audio.py audio ROM in nes_bench with Mesen's.

Usage: mmc5_audio_compare.py AUDIO.au MESEN.wav

As vrc6_audio_compare.py, for each segment of mmc5_audio.SEGMENTS: the
fundamental frequency and its level, each divided by those of segment 1,
the APU pulse 1 at the period of the MMC5 pulse 1 of segment 0. The
envelope segment has no steady level, and the two pulses no one frequency,
so only the level of their fundamental is compared.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mmc5_audio  # noqa: E402
import vrc6_audio_compare as compare  # noqa: E402

# Segments of more than one tone or of a changing level
MIXED_SEGMENTS = {4, 5}


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    bench = compare.measure(*compare.read_au(sys.argv[1]),
                            compare.BENCH_FRAME, mmc5_audio, set(),
                            MIXED_SEGMENTS)
    mesen = compare.measure(*compare.read_wav(sys.argv[2]),
                            compare.NTSC_FRAME, mmc5_audio, set(),
                            MIXED_SEGMENTS)
    compare.report(bench, mesen)


if __name__ == '__main__':
    main()
