#!/usr/bin/env bash

IFS='
'

rm -rf output/*
for line in `grep -v '^#' nes_tests.txt`
do
    NES_FILEPATH=`echo "$line" | cut -f 1 -d '|' | xargs`
    RUN_TIME=`echo "$line" | cut -f 2 -d '|' | xargs`
    OUTPUT_DIR=output/`basename "$NES_FILEPATH" .nes`

    echo "Running test $NES_FILEPATH"
    ./run_nes_bench.sh "$NES_FILEPATH" --stop-time="$RUN_TIME"
    # Last frame is incomplete
    find "$OUTPUT_DIR" -name 'frame*.bmp' | sort | tail -n 1 | xargs rm
done
