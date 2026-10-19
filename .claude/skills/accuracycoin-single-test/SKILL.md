---
name: accuracycoin-single-test
description: Run a single AccuracyCoin test (instead of a whole page) in nes_bench by generating an FM2 input that selects it. Use when investigating or fixing one failing AccuracyCoin test, finding a test's page/number, or reading its result and error code.
---

# Running one AccuracyCoin test in nes_bench

The page tests in `board/sim/ghdl/nes_tests.txt` run every test on a page. When
working on one failing test, it is much faster to run only that test.
`single_test_fm2.sh` (next to this file) reads the page and test tables from
`AccuracyCoin/AccuracyCoin.asm` and prints an FM2 that waits for the menu,
moves to the page (Left/Right), moves the cursor down to the test and presses A.

## 1. Find the test and generate the FM2

```bash
SKILL=.claude/skills/accuracycoin-single-test
$SKILL/single_test_fm2.sh -l              # pages and their titles
$SKILL/single_test_fm2.sh -l 1            # tests on page 1, numbered
$SKILL/single_test_fm2.sh 'dummy write' > $SCRATCH/test.fm2   # by name substring
$SKILL/single_test_fm2.sh 1 7 > $SCRATCH/test.fm2             # by page and number
```

A name must match exactly one test; otherwise the candidates are listed. Write
the FM2 to the scratchpad, not the repo.

## 2. Run nes_bench on the host

`nes_bench` is built in docker (`./run_ghdl.sh make -s -f nes_bench.Makefile`
from `board/sim/ghdl`, needed after VHDL changes) but runs directly on the
host, so output can go to the scratchpad:

```bash
cd board/sim/ghdl
NES=../../../AccuracyCoin/AccuracyCoin.nes
OUT=$SCRATCH/test_out; mkdir -p $OUT
./nes_bench -gAU_FILEPATH=$OUT/audio.au -gBMP_FILE_PREFIX=$OUT/frame \
    -gNES_FILEPATH=$NES -gNES_FILE_BYTES=$(wc -c < $NES) \
    -gFM2_FILEPATH=$SCRATCH/test.fm2 --stop-time=1750ms \
    --asserts=disable --ieee-asserts=disable > $OUT/log.txt 2>&1
```

- Run it in the background; it takes ~4-5 minutes of wall time per second of
  simulation (1750ms took ~8.5 minutes).
- A is pressed on FM2 frame 61 + 5 * (page presses + test number). Pick a
  stop time that covers that plus the test's own run time (Dummy write cycles,
  page 1 test 7: A on frame 96, result on frame 101, 1750ms was enough). The
  page's run time in nes_tests.txt is an upper bound for any test on it.
- Rendering is off while a test runs, so blank frames mean "still running", not
  a hang (RAM $34 is 1 while tests run).

## 3. Read the result

Find the last frame where the screen changed (the final BMP is usually
truncated), then view it:

```bash
cd $OUT; prev=; for f in frame_*.bmp; do h=$(sha256sum $f | cut -c1-16); \
    [ "$h" != "$prev" ] && last=$f; prev=$h; done; echo $last
convert $last -scale 300% $SCRATCH/result.png   # then Read the PNG
```

The test's row shows `PASS` or `FAIL n`. Look up error code `n` under
`### <test name>` in `AccuracyCoin/README.md`. Each table line in the .asm
names the test routine (e.g. `TEST_DummyWrites`), whose comments describe each
sub-test and set `ErrorCode` before it.

## 4. Afterwards

- If the fix makes the whole page pass, uncomment the page's line in
  `nes_tests.txt` and set its hash and run time from a full-page run
  (`test_inputs/AccuracyCoin/page_NN.fm2`), using run time =
  ceil((N + 1) * 16.6772) ms for final frame N.
- To see what correct behavior looks like, run the test in Mesen with the
  mesen-agent skill.
