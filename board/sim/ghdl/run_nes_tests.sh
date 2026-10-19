#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [ -b BENCH ] [ -f TESTS_FILE ] [ -s SHARD/SHARD_COUNT ] [ -l ]"
    echo "       $0 [ -b BENCH ] [ -f TESTS_FILE ] [ -s SHARD/SHARD_COUNT ] -r RESULTS_FILE..."
    echo "  -b  Test bench to run the tests on: nes_bench (default) or"
    echo "      nes_de1_bench"
    echo "  -f  Test list to run (default: nes_tests.txt for nes_bench,"
    echo "      nes_de1_tests.txt for nes_de1_bench)"
    echo "  -s  Only run shard SHARD (1-based) of SHARD_COUNT. Tests are"
    echo "      distributed so each shard has about the same total run time"
    echo "  -l  List the selected tests and their run times, then exit"
    echo "  -r  Don't run tests. Print a report of the selected tests from the"
    echo "      given results files (results.txt in the output directory of"
    echo "      earlier runs, such as one from each shard), then exit"
    echo
    echo "When all tests finish, a Markdown table of the results is printed."
    echo "The exit status is nonzero if any selected test failed or has no result"
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
    OUTPUT_DIR="$OUTPUT_ROOT"/"$TEST_NAME"

    # Only pass -i when there is an FM2 input, since nes_de1_bench doesn't
    # support one
    FM2_ARGS=()
    if [ "$FM2_PATH" != "" ]
    then
        FM2_ARGS=(-i "$FM2_PATH")
    fi

    echo "Test start: $TEST_NAME"
    START=$SECONDS
    ./run_"$BENCH".sh -n "$NES_FILEPATH" -o "$OUTPUT_DIR" -t "$RUN_TIME" \
                      "${FM2_ARGS[@]}" 1> /dev/null

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

    printf '%s\t%s\t%s\n' "$STATUS" $((SECONDS - START)) "$TEST_NAME" \
        >> "$RESULTS_FILE"
}

# Prints a Markdown table of the results in the results files given as
# arguments (lines of STATUS<tab>SECONDS<tab>NAME) for the test names given on
# stdin, sorted by name. Tests without a result are listed as NOT RUN
results_table() {
    # Tag each line with where it came from: R for a result, T for a test name
    {
        cat "$@" 2> /dev/null | sed -e 's/^/R\t/'
        LC_ALL=C sort | sed -e 's/^/T\t/'
    } | awk -F '\t' '
        function duration(t) {
            if (t >= 3600)
                return sprintf("%d:%02d:%02d", t / 3600, t % 3600 / 60, t % 60)
            return sprintf("%d:%02d", t / 60, t % 60)
        }
        BEGIN {
            print "| Test | Status | Wall time |"
            print "| :--- | :----: | --------: |"
        }
        $1 == "R" && NF == 4 {
            status[$4] = $2
            secs[$4] = $3
        }
        $1 == "T" {
            if ($2 in status)
                print "| " $2 " | " status[$2] " | " duration(secs[$2]) " |"
            else
                print "| " $2 " | NOT RUN | - |"
        }
    '
}

# Prints a Markdown report of $TESTS from the results files given as arguments:
# a table of the results, the pass/fail counts and a list of the tests that
# failed or have no result. Returns nonzero if there are any of the latter
report() {
    TABLE=`for line in $TESTS; do test_name "$line"; done | results_table "$@"`

    # Count from the table so the summary always matches it
    PASSED=`echo "$TABLE" | grep -c '| PASS |'`
    FAILED=`echo "$TABLE" | grep -c '| FAIL |'`
    NOT_RUN=`echo "$TABLE" | grep -c '| NOT RUN |'`
    TOTAL=`echo "$TESTS" | grep -c .`

    echo "$TABLE"
    echo
    echo "Passed: $PASSED  Failed: $FAILED  Not run: $NOT_RUN  Total: $TOTAL"
    echo "$TABLE" | grep -E '\| (FAIL|NOT RUN) \|' |
        sed -E 's/^\| (.*) \| (FAIL|NOT RUN) \|.*$/- \2: \1/'

    [ $FAILED -eq 0 ] && [ $NOT_RUN -eq 0 ]
}

BENCH=nes_bench
TESTS_FILE=
SHARD=1
SHARD_COUNT=1
LIST_ONLY=0
REPORT_ONLY=0

while getopts b:f:s:lrh flag
do
    case "${flag}" in
        b) BENCH="${OPTARG}";;
        f) TESTS_FILE="${OPTARG}";;
        s) SHARD="${OPTARG%/*}"
           SHARD_COUNT="${OPTARG#*/}";;
        l) LIST_ONLY=1;;
        r) REPORT_ONLY=1;;
        h) usage
           exit 0;;
        *) exit_abnormal;;
    esac
done
shift $((OPTIND - 1))

if [ $REPORT_ONLY -eq 1 ] && [ $# -eq 0 ]
then
    echo "Error: -r requires at least one results file"
    exit_abnormal
fi

case "$BENCH" in
    nes_bench)
        DEFAULT_TESTS_FILE=nes_tests.txt
        OUTPUT_ROOT=output;;
    nes_de1_bench)
        DEFAULT_TESTS_FILE=nes_de1_tests.txt
        OUTPUT_ROOT=de1_output;;
    *)
        echo "Error: unknown bench '$BENCH'"
        exit_abnormal;;
esac

if [ "$TESTS_FILE" == "" ]
then
    TESTS_FILE=$DEFAULT_TESTS_FILE
fi

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

IFS='
'

if [ $REPORT_ONLY -eq 1 ]
then
    report "$@"
    exit
fi

if ! make -s -f "$BENCH".Makefile
then
    echo "$BENCH make failed"
    exit 1
fi

# NES file paths in the test list are relative to the root of the repository
BASEDIR=../../..
RESULTS_FILE="$OUTPUT_ROOT"/results.txt
FAILURES_DIR="$OUTPUT_ROOT"/failures

rm -rf "$OUTPUT_ROOT"/*
mkdir -p "$OUTPUT_ROOT"

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

echo
report "$RESULTS_FILE"
STATUS=$?
echo "Wall time: `date -u -d @$SECONDS +%T`"
exit $STATUS
