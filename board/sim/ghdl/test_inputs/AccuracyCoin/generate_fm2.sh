#!/usr/bin/env bash

# Generates the FM2 input files used by nes_tests.txt to run AccuracyCoin one
# page at a time. Each input waits for the main menu to load, presses Left or
# Right on the page index (whichever reaches the page in fewer presses) to
# select the page, then presses A to run every test on the page. Once the tests
# finish, the page shows the PASS/FAIL result of each test.
#
# The menu only acts on newly pressed buttons and redrawing the page takes a
# couple of frames, so each press is followed by a few released frames. In
# Mesen, navigation misses presses with fewer than 3 released frames.

PAGE_COUNT=22

# Frames to wait for the main menu to load. It takes about 30 frames in
# nes_bench (and about 24 in Mesen) since some pre-tests run first
START_FRAMES=60
# Frames each button is held/released
PRESS_FRAMES=1
RELEASE_FRAMES=4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# FM2 stores buttons in the order RLDUTSBA
NONE='........'
RIGHT='R.......'
LEFT='.L......'
A='.......A'

# Prints $2 input lines with controller 1 set to $1
frames() {
    for (( i = 0; i < $2; i++ ))
    do
        echo "|0|$1|||"
    done
}

# Prints the FM2 file to run page $1
page_fm2() {
    PAGE=$1

    # The menu wraps around when pressing Left on the first page
    RIGHT_PRESSES=$(( PAGE - 1 ))
    LEFT_PRESSES=$(( PAGE_COUNT - RIGHT_PRESSES ))
    if [ $RIGHT_PRESSES -le $LEFT_PRESSES ]
    then
        PRESSES=$RIGHT_PRESSES
        BUTTON=$RIGHT
        BUTTON_NAME=Right
    else
        PRESSES=$LEFT_PRESSES
        BUTTON=$LEFT
        BUTTON_NAME=Left
    fi

    echo "version 3"
    echo "emuVersion 0"
    echo "rerecordCount 0"
    echo "palFlag 0"
    echo "romFilename AccuracyCoin"
    echo "port0 1"
    echo "port1 0"
    echo "port2 0"
    echo "comment AccuracyCoin page $PAGE: press $BUTTON_NAME $PRESSES time(s)" \
         "then A to run every test on the page"

    frames $NONE $START_FRAMES
    for (( p = 0; p < PRESSES; p++ ))
    do
        frames $BUTTON $PRESS_FRAMES
        frames $NONE $RELEASE_FRAMES
    done
    frames $A $PRESS_FRAMES
    frames $NONE $RELEASE_FRAMES
}

for (( page = 1; page <= PAGE_COUNT; page++ ))
do
    page_fm2 $page > "$SCRIPT_DIR"/`printf 'page_%02d.fm2' $page`
done
