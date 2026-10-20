# Sourced by generate_fm2.sh and the accuracycoin-single-test skill's
# single_test_fm2.sh to build the FM2 inputs that drive the AccuracyCoin menu.
#
# The menu only acts on newly pressed buttons and redrawing the page takes a
# couple of frames, so each press is followed by a few released frames. In
# Mesen, navigation misses presses with fewer than 3 released frames.

REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
ASM="$REPO_ROOT"/AccuracyCoin/AccuracyCoin.asm

if [ ! -f "$ASM" ]
then
    echo "Error: '$ASM' not found (is the AccuracyCoin submodule checked out?)" >&2
    exit 1
fi

# One page per entry in the table of .word Suite_* pointers
PAGE_COUNT=`grep -cE '^[[:space:]]*\.word[[:space:]]+Suite_' "$ASM"`

# Frames to wait for the main menu to load. It takes about 30 frames in
# nes_bench (and about 24 in Mesen) since some pre-tests run first
START_FRAMES=60
# Frames each button is held/released
PRESS_FRAMES=1
RELEASE_FRAMES=4

# FM2 stores buttons in the order RLDUTSBA
NONE='........'
RIGHT='R.......'
LEFT='.L......'
DOWN='..D.....'
A='.......A'

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

# Sets PAGE_PRESSES, PAGE_BUTTON and PAGE_BUTTON_NAME to whichever of Left or
# Right reaches page $1 in fewer presses
page_nav() {
    # The menu wraps around when pressing Left on the first page
    RIGHT_PRESSES=$(( $1 - 1 ))
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
}

# Prints the FM2 header with the arguments as its comment, then the input
# that waits for the main menu and moves to the page set by page_nav
select_page_fm2() {
    echo "version 3"
    echo "emuVersion 0"
    echo "rerecordCount 0"
    echo "palFlag 0"
    echo "romFilename AccuracyCoin"
    echo "port0 1"
    echo "port1 0"
    echo "port2 0"
    echo "comment $*"

    frames $NONE $START_FRAMES
    presses $PAGE_BUTTON $PAGE_PRESSES
}
