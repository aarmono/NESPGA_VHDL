#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [ -f TESTS_FILE ] [ -s SHARD/SHARD_COUNT ] [ -l ]"
    echo "  -f  Test list to run (default: nes_tests.txt)"
    echo "  -s  Only run shard SHARD (1-based) of SHARD_COUNT. Tests are"
    echo "      distributed so each shard has about the same total run time"
    echo "  -l  List the selected tests and their run times, then exit"
    echo
    echo "Each line of the test list has the format:"
    echo "  NES file path | run time | hash [ | FM2 input path ]"
    echo "NES file paths are relative to the root of the repository. FM2 input"
    echo "paths are relative to this script's directory"
}

exit_abnormal() {
    usage
    exit 1
}

# Prints the non-comment lines of the test list in $1, longest run time
# first. If $2/$3 are given, only prints the lines in shard $2 of $3.
#
# Shards are assigned greedily (longest test to the shard with the least
# total run time so far), which is deterministic, so every shard computes
# the same partition independently. Running longest tests first also
# minimizes the wall time when tests run in parallel.
select_tests() {
    awk -F '|' '
        function to_ms(t,    num, unit) {
            gsub(/[ \t]/, "", t)
            if (!match(t, /^[0-9.]+/)) return 0
            num = substr(t, 1, RLENGTH)
            unit = substr(t, RLENGTH + 1)
            if (unit == "fs")  return num / 1000000000000
            if (unit == "ps")  return num / 1000000000
            if (unit == "ns")  return num / 1000000
            if (unit == "us")  return num / 1000
            if (unit == "ms")  return num
            if (unit == "sec") return num * 1000
            if (unit == "min") return num * 60000
            if (unit == "hr")  return num * 3600000
            return 0
        }
        /^#/ || /^[ \t]*$/ { next }
        { print to_ms($2) "\t" $0 }
    ' "$1" |
    sort -s -t "$(printf '\t')" -k 1,1gr |
    awk -F '\t' -v shard="${2:-1}" -v count="${3:-1}" '
        {
            best = 1
            for (i = 2; i <= count; i++)
                if (load[i] < load[best]) best = i
            load[best] += $1
            if (best == shard) print $2
        }
    '
}

check_hash() {
    echo "$1" | sha256sum -c --status --quiet &> /dev/null
}

# Prints the name of the test on line $1 of the test list: the NES file path,
# followed by the name of the FM2 input file (if any) so that multiple tests
# can run the same NES file with different inputs
test_name() {
    TEST_PATH=`echo "$1" | cut -f 1 -d '|' | xargs`
    FM2_PATH=`echo "$1" | cut -f 4 -d '|' | xargs`

    if [ "$FM2_PATH" != "" ]
    then
        echo "$TEST_PATH"/`basename "$FM2_PATH" .fm2`
    else
        echo "$TEST_PATH"
    fi
}

run_nes_test() {
    TEST_PATH=`echo "$1" | cut -f 1 -d '|' | xargs`
    NES_FILEPATH="$BASEDIR"/"$TEST_PATH"
    RUN_TIME=`echo "$1" | cut -f 2 -d '|' | xargs`
    HASH=`echo "$1" | cut -f 3 -d '|' | xargs`
    FM2_PATH=`echo "$1" | cut -f 4 -d '|' | xargs`
    TEST_NAME=`test_name "$1"`
    OUTPUT_DIR=output/"$TEST_NAME"

    echo "Test start: $TEST_NAME"
    ./run_nes_bench.sh -n "$NES_FILEPATH" -o "$OUTPUT_DIR" -t "$RUN_TIME" \
                       -i "$FM2_PATH" 1> /dev/null

    if [ "$HASH" != "" ]
    then
        pushd "$OUTPUT_DIR" &> /dev/null
        if check_hash "$HASH"
        then
            STATUS=PASS
        else
            STATUS=FAIL
        fi
        popd &> /dev/null

        if [ "$STATUS" == "FAIL" ]
        then
            # Keep the file the hash was computed over so it can be inspected
            HASH_FILE=`echo "$HASH" | sed -E 's/^[0-9a-fA-F]+ [ *]//'`
            mkdir -p "$FAILURES_DIR"/"$TEST_NAME"
            cp -f "$OUTPUT_DIR"/"$HASH_FILE" "$FAILURES_DIR"/"$TEST_NAME"/ 2> /dev/null
        fi

        echo "Test  $STATUS: $TEST_NAME"
    else
        STATUS=DONE
        echo "Test complete: $TEST_NAME"
    fi

    echo "$STATUS $TEST_NAME" >> "$RESULTS_FILE"
}

TESTS_FILE=nes_tests.txt
SHARD=1
SHARD_COUNT=1
LIST_ONLY=0

while getopts f:s:lh flag
do
    case "${flag}" in
        f) TESTS_FILE="${OPTARG}";;
        s) SHARD="${OPTARG%/*}"
           SHARD_COUNT="${OPTARG#*/}";;
        l) LIST_ONLY=1;;
        h) usage
           exit 0;;
        *) exit_abnormal;;
    esac
done

if ! [[ "$SHARD" =~ ^[0-9]+$ && "$SHARD_COUNT" =~ ^[0-9]+$ ]] ||
   [ "$SHARD" -lt 1 ] || [ "$SHARD" -gt "$SHARD_COUNT" ]
then
    echo "Error: invalid shard '$SHARD/$SHARD_COUNT'"
    exit_abnormal
fi

if [ ! -f "$TESTS_FILE" ]
then
    echo "Error: test list '$TESTS_FILE' not found"
    exit 1
fi

TESTS=`select_tests "$TESTS_FILE" "$SHARD" "$SHARD_COUNT"`

if [ $LIST_ONLY -eq 1 ]
then
    echo "$TESTS" | cut -f 1,2,4 -d '|' | sed -E 's/[ \t]*\|[ \t]*$//'
    exit 0
fi

if ! make -s -f nes_bench.Makefile
then
    echo "nes_bench make failed"
    exit 1
fi

IFS='
'

# NES file paths in the test list are relative to the root of the repository
BASEDIR=../../..
RESULTS_FILE=output/results.txt
FAILURES_DIR=output/failures

rm -rf output/*
mkdir -p output

N=`nproc`
for line in $TESTS
do
    run_nes_test "$line" &

    if [ $(jobs -r -p | wc -l) -ge $N ]
    then
        wait -n
    fi
done
wait

touch "$RESULTS_FILE"
PASSED=`grep -c '^PASS ' "$RESULTS_FILE"`
FAILED=`grep -c '^FAIL ' "$RESULTS_FILE"`
TOTAL=`echo "$TESTS" | grep -c .`
FINISHED=`grep -c . "$RESULTS_FILE"`

echo
echo "Passed: $PASSED  Failed: $FAILED  Total: $TOTAL"
grep '^FAIL ' "$RESULTS_FILE" | sed -e 's/^FAIL /  FAIL: /'

if [ $FAILED -ne 0 ] || [ $FINISHED -ne $TOTAL ]
then
    exit 1
fi
