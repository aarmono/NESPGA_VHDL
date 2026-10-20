#!/usr/bin/env bash

# Lists the tests in AccuracyCoin, or prints an FM2 input that runs just one
# of them. The page and test tables are read from AccuracyCoin.asm so they
# stay in sync with the ROM.
#
# The input is built like the ones from
# board/sim/ghdl/test_inputs/AccuracyCoin/generate_fm2.sh (sharing its
# fm2_lib.sh): wait for the main menu, press Left/Right to reach the page, then
# press Down to move the cursor onto the test and press A to run only that test.

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

REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
. "$REPO_ROOT"/board/sim/ghdl/test_inputs/AccuracyCoin/fm2_lib.sh

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

# Prints the FM2 that runs test $2 on page $1, named $3
test_fm2() {
    page_nav $1
    select_page_fm2 "AccuracyCoin page $1 test $2 ($3):" \
                    "press $PAGE_BUTTON_NAME $PAGE_PRESSES time(s)," \
                    "Down $2 time(s), then A to run the test"
    presses $DOWN $2
    presses $A 1
}

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
