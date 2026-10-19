#!/usr/bin/env bash

# Lists the tests in AccuracyCoin, or prints an FM2 input that runs just one
# of them. The page and test tables are read from AccuracyCoin.asm so they
# stay in sync with the ROM.
#
# The input matches board/sim/ghdl/test_inputs/AccuracyCoin/generate_fm2.sh:
# wait for the main menu, press Left/Right to reach the page, then press Down
# to move the cursor onto the test and press A to run only that test.

usage() {
    echo "Usage: $0 -l [ PAGE ]"
    echo "       $0 PAGE TEST"
    echo "       $0 NAME"
    echo "  -l    List the pages, or the tests on PAGE, with their numbers"
    echo "  PAGE  Page number (1-based, as shown on the menu)"
    echo "  TEST  Test number on the page (1-based, top to bottom)"
    echo "  NAME  Case-insensitive substring of a test name that matches"
    echo "        exactly one test, e.g. 'dummy write'"
    echo "The FM2 is printed to stdout"
}

# Frames to wait for the main menu to load, and to hold/release each button.
# Same values as generate_fm2.sh
START_FRAMES=60
PRESS_FRAMES=1
RELEASE_FRAMES=4

REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
ASM="$REPO_ROOT"/AccuracyCoin/AccuracyCoin.asm

# FM2 stores buttons in the order RLDUTSBA
NONE='........'
RIGHT='R.......'
LEFT='.L......'
DOWN='..D.....'
A='.......A'

# Prints every test as PAGE<tab>TEST<tab>PAGE TITLE<tab>TEST NAME
all_tests() {
    awk '
        # The page order comes from the table of .word Suite_* pointers
        /^[ \t]*\.word[ \t]+Suite_/ {
            pages[$2] = ++page_count
            next
        }
        # Each suite starts with its label and title, then one table/tblf
        # line per test, and ends with .byte $FF
        /^Suite_[A-Za-z0-9_]*:/ {
            suite = substr($1, 1, length($1) - 1)
            test = 0
            title = ""
            next
        }
        suite != "" && title == "" && /^[ \t]*\.byte[ \t]+"/ {
            match($0, /"[^"]*"/)
            title = substr($0, RSTART + 1, RLENGTH - 2)
            next
        }
        suite != "" && /^[ \t]*(table|tblf1|tblf2)[ \t]+"/ {
            match($0, /"[^"]*"/)
            name = substr($0, RSTART + 1, RLENGTH - 2)
            # tblf lines append the addressing mode, e.g. str_Absolute, ",X"
            rest = substr($0, RSTART + RLENGTH)
            sub(/\$FF.*/, "", rest)
            gsub(/str_|[",]/, "", rest)
            gsub(/[ \t]+/, " ", rest)
            sub(/ +$/, "", rest)
            if (rest != "")
                name = name rest
            line[suite, ++test] = name
            count[suite] = test
            titles[suite] = title
            next
        }
        suite != "" && /^[ \t]*\.byte[ \t]+\$FF/ {
            suite = ""
        }
        END {
            for (s in pages)
                for (t = 1; t <= count[s]; t++)
                    print pages[s] "\t" t "\t" titles[s] "\t" line[s, t]
        }
    ' "$ASM" | sort -t "$(printf '\t')" -k 1,1n -k 2,2n
}

# Prints $2 input lines with controller 1 set to $1
frames() {
    for (( i = 0; i < $2; i++ ))
    do
        echo "|0|$1|||"
    done
}

# Prints $2 presses of button $1
presses() {
    for (( p = 0; p < $2; p++ ))
    do
        frames $1 $PRESS_FRAMES
        frames $NONE $RELEASE_FRAMES
    done
}

# Prints the FM2 that runs test $2 on page $1, named $3
test_fm2() {
    PAGE=$1
    TEST=$2
    PAGE_COUNT=`all_tests | cut -f 1 | sort -n | tail -1`

    # The menu wraps around when pressing Left on the first page
    RIGHT_PRESSES=$(( PAGE - 1 ))
    LEFT_PRESSES=$(( PAGE_COUNT - RIGHT_PRESSES ))
    if [ $RIGHT_PRESSES -le $LEFT_PRESSES ]
    then
        PAGE_PRESSES=$RIGHT_PRESSES
        PAGE_BUTTON=$RIGHT
        PAGE_BUTTON_NAME=Right
    else
        PAGE_PRESSES=$LEFT_PRESSES
        PAGE_BUTTON=$LEFT
        PAGE_BUTTON_NAME=Left
    fi

    echo "version 3"
    echo "emuVersion 0"
    echo "rerecordCount 0"
    echo "palFlag 0"
    echo "romFilename AccuracyCoin"
    echo "port0 1"
    echo "port1 0"
    echo "port2 0"
    echo "comment AccuracyCoin page $PAGE test $TEST ($3):" \
         "press $PAGE_BUTTON_NAME $PAGE_PRESSES time(s), Down $TEST time(s)," \
         "then A to run the test"

    frames $NONE $START_FRAMES
    presses $PAGE_BUTTON $PAGE_PRESSES
    presses $DOWN $TEST
    presses $A 1
}

if [ ! -f "$ASM" ]
then
    echo "Error: '$ASM' not found (is the AccuracyCoin submodule checked out?)" >&2
    exit 1
fi

if [ "$1" == "-h" ] || [ $# -eq 0 ] || [ $# -gt 2 ]
then
    usage
    [ "$1" == "-h" ]
    exit
fi

if [ "$1" == "-l" ]
then
    if [ "$2" == "" ]
    then
        all_tests | awk -F '\t' '$2 == 1 { print $1 "\t" $3 }'
    else
        all_tests | awk -F '\t' -v page="$2" '$1 == page { print $2 "\t" $4 }'
    fi
    exit 0
fi

if [ $# -eq 2 ]
then
    MATCH=`all_tests | awk -F '\t' -v page="$1" -v test="$2" \
                           '$1 == page && $2 == test'`
else
    MATCH=`all_tests | awk -F '\t' -v name="$1" \
                           'index(tolower($4), tolower(name))'`
fi

MATCHES=`echo -n "$MATCH" | grep -c .`
if [ $MATCHES -ne 1 ]
then
    echo "Error: expected 1 matching test, found $MATCHES" >&2
    echo "$MATCH" | awk -F '\t' 'NF { print "  page " $1 " test " $2 ": " $4 }' >&2
    exit 1
fi

IFS=$'\t' read -r PAGE TEST TITLE NAME <<< "$MATCH"
echo "Page $PAGE ($TITLE) test $TEST: $NAME" >&2
test_fm2 $PAGE $TEST "$NAME"
