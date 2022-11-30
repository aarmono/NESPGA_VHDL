#!/usr/bin/env bash

check_hash() {
    echo "$1" | sha256sum -c --status --quiet
}

run_nes_test() {
    TEST_PATH=`echo "$1" | cut -f 1 -d '|' | xargs`
    NES_FILEPATH="$BASEDIR"/"$TEST_PATH"
    RUN_TIME=`echo "$1" | cut -f 2 -d '|' | xargs`
    HASH=`echo "$1" | cut -f 3 -d '|' | xargs`
    OUTPUT_DIR=output/"$TEST_PATH"

    echo "Test starting: $TEST_PATH"
    ./run_nes_bench.sh -n "$NES_FILEPATH" -o "$OUTPUT_DIR" -t "$RUN_TIME" 1> /dev/null

    if [ "$HASH" != "" ]
    then
        pushd "$OUTPUT_DIR" &> /dev/null
        if check_hash "$HASH"
        then
            STATUS=PASS
        else
            STATUS=FAIL
        fi

        echo "Test $STATUS: $TEST_PATH"
        popd &> /dev/null
    else
        echo "Test complete: $TEST_PATH"
    fi
}

IFS='
'

BASEDIR=../../../nes-test-roms

rm -rf output/*

N=`nproc`
for line in `grep -v '^#' nes_tests.txt`
do
    run_nes_test "$line" &

    if [ $(jobs -r -p | wc -l) -ge $N ]
    then
        wait -n
    fi
done
wait
