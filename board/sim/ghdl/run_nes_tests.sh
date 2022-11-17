#!/usr/bin/env bash

IFS='
'

BASEDIR=../../../nes-test-roms

rm -rf output/*
for line in `grep -v '^#' nes_tests.txt`
do
    TEST_PATH=`echo "$line" | cut -f 1 -d '|' | xargs`
    NES_FILEPATH="$BASEDIR"/"$TEST_PATH"
    RUN_TIME=`echo "$line" | cut -f 2 -d '|' | xargs`
    HASH=`echo "$line" | cut -f 3 -d '|' | xargs`
    OUTPUT_DIR=output/"$TEST_PATH"

    echo "Running test $TEST_PATH"
    ./run_nes_bench.sh "$NES_FILEPATH" "$OUTPUT_DIR" --stop-time="$RUN_TIME"

    if [ "$HASH" != "" ]
    then
        pushd "$OUTPUT_DIR"
        echo "$HASH" | sha256sum -c
        popd
    fi
done
