#!/usr/bin/env bash

# Generates the FM2 input files used by nes_tests.txt to run AccuracyCoin one
# page at a time. Each input waits for the main menu to load, presses Left or
# Right on the page index (whichever reaches the page in fewer presses) to
# select the page, then presses A to run every test on the page. Once the tests
# finish, the page shows the PASS/FAIL result of each test.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR"/fm2_lib.sh

# Prints the FM2 file to run page $1
page_fm2() {
    page_nav $1
    select_page_fm2 "AccuracyCoin page $1: press $PAGE_BUTTON_NAME" \
                    "$PAGE_PRESSES time(s) then A to run every test on the page"
    presses $A 1
}

for (( page = 1; page <= PAGE_COUNT; page++ ))
do
    page_fm2 $page > "$SCRIPT_DIR"/`printf 'page_%02d.fm2' $page`
done
