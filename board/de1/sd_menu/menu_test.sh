#!/usr/bin/env bash
#
# Runs the menu in Mesen (mesen-agent) on SD card images made with mtools,
# with sd_test.lua standing in for sd_menu's registers. Each case presses
# buttons, then checks the file launched or the error shown, and the text
# on the screen. Run make first.
#
# Usage: menu_test.sh

HERE=$(cd "$(dirname "$0")"; pwd)
REPO=$(cd "$HERE/../../.."; pwd)
MESEN_AGENT=${MESEN_AGENT:-$HOME/.local/bin/mesen-agent}
ROMS=$REPO/nes-test-roms/instr_test-v5/rom_singles
export MTOOLS_SKIP_CHECK=1

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

failures=0

# Frame of the first press, and between presses
FIRST_PRESS=20
PRESS_GAP=6

# fat IMAGE FAT [ MBR_START ]: an empty FAT16 or FAT32 filesystem, either at
# block 0 or in the first partition of an MBR
fat() {
    local img=$1 fat=$2 start=${3:-0} kb=16384
    # mtools takes the FAT type from the number of clusters
    [ "$fat" == 32 ] && kb=40960
    rm -f "$img"
    if [ "$start" == 0 ]
    then
        /usr/sbin/mkfs.fat -C -F "$fat" -s 1 "$img" $kb > /dev/null 2>&1
    else
        local type=0x0E
        [ "$fat" == 32 ] && type=0x0C
        truncate -s $((start * 512 + kb * 1024)) "$img"
        printf "start=%d, type=%x\n" "$start" "$type" |
            /usr/sbin/sfdisk -q "$img" > /dev/null
        /usr/sbin/mkfs.fat -F "$fat" -s 1 --offset "$start" "$img" $kb \
            > /dev/null 2>&1
        img="$img@@$((start * 512))"
    fi
    mcopy -i "$img" "$HERE/menu.nes" ::/MENU.NES
}

# no_hint IMAGE [ MBR_START ]: clears the next free cluster hint of a FAT32
# filesystem, so that mtools fills holes from the start of the FAT
no_hint() {
    python3 -c '
import struct, sys
start = int(sys.argv[2]) * 512
with open(sys.argv[1], "r+b") as f:
    f.seek(start + 0x30)
    fsinfo, = struct.unpack("<H", f.read(2))
    f.seek(start + fsinfo * 512 + 0x1EC)
    f.write(b"\xff" * 4)
' "$1" "${2:-0}"
}

# rom FILE SEED: a 16400 byte iNES file whose contents depend on SEED
rom() {
    python3 -c '
import random, sys
random.seed(sys.argv[2])
data = b"NES\x1a\x01\x00" + bytes(10) + random.randbytes(16384)
open(sys.argv[1], "wb").write(data)
' "$1" "$2"
}

# run NAME IMAGE EXPECT BUTTONS...: presses each button (a, b, up, down,
# left, right, start) in turn from frame FIRST_PRESS, PRESS_GAP frames
# apart. The screen is logged after the last press. EXPECT is the file that
# a launch must load. The log is in NAME.log
run() {
    local name=$1 img=$2 expect=$3
    shift 3
    local frame=$FIRST_PRESS
    local inputs=()
    for button in "$@"
    do
        inputs+=(--input "0:$button@$frame-$((frame + 1))")
        frame=$((frame + PRESS_GAP))
    done
    rm -rf home
    SD_IMAGE="$img" SD_EXPECT="$expect" SD_SCREEN_FRAME=$frame \
        "$MESEN_AGENT" "$HERE/menu.nes" --home home \
        --frames $((frame + 20)) --timeout 60 "${inputs[@]}" \
        --lua "$HERE/sd_test.lua" --lua-allow-io > events.jsonl \
        2> stderr.log
    echo "exit $?" > "$name.log"
    python3 -c '
import json, sys
for line in open(sys.argv[1]):
    event = json.loads(line)
    if event.get("event") == "lua_log":
        print(event["text"], end="")
' events.jsonl >> "$name.log"
    current=$name
}

result() {
    local status=$1 what=$2
    [ "$status" == ok ] || failures=$((failures + 1))
    printf "%-4s %-16s %s\n" "$status" "$current" "$what"
}

# want_launch [ EXTENTS ]: the last run launched EXPECT, leaving menu mode,
# with EXTENTS extents if given
want_launch() {
    if grep -q "^exit 0" "$current.log" &&
       grep -q "^LAUNCH value 0, ${1:-[0-9]*} extents,.*MATCH" "$current.log"
    then
        result ok "$(grep ^LAUNCH "$current.log")"
    else
        result FAIL "no launch: $(grep -E "^(LAUNCH|ERROR|exit)" \
            "$current.log" | tr '\n' ' ')"
    fi
}

# want_error CODE: the last run showed error CODE
want_error() {
    if grep -q "^exit 2" "$current.log" &&
       grep -q "^ERROR color \$$1 " "$current.log"
    then
        result ok "error \$$1"
    else
        result FAIL "no error \$$1: $(grep -E "^(LAUNCH|ERROR|exit)" \
            "$current.log" | tr '\n' ' ')"
    fi
}

# want_screen ROW TEXT: row ROW of the last screen logged is TEXT, from
# column 0, with the cursor shown as '>'
want_screen() {
    local row line
    row=$(printf "%02d" "$1")
    line=$(awk -v row="$row" '
        /^SCREEN --$/ { split("", rows); next }
        /^SCREEN / && $2 == row { rows[row] = substr($0, 11) }
        END { print rows[row] }' "$current.log")
    if [ "$line" == "$2" ]
    then
        result ok "row $1: '$2'"
    else
        result FAIL "row $1: '$line', not '$2'"
    fi
}

for n in 1 2 3 4
do
    rom game$n.nes $n
done
rom big.nes big
dd if=/dev/urandom bs=1024 count=300 status=none >> big.nes

# The root directory, with long and short names, entries that are not
# listed, a subdirectory, and deleted entries. mtools changes [ and ] in
# long names to _, so they are not tested
fat root.img 16
mcopy -i root.img game1.nes "::/Super Game (U) {!} & co.nes"
mcopy -i root.img game2.nes ::/GAME2.NES
mcopy -i root.img game3.nes ::/deleted.nes
echo text > readme.txt
mcopy -i root.img readme.txt ::/README.TXT
mcopy -i root.img game3.nes "::/._Super Game (U) {!} & co.nes"
mcopy -i root.img game3.nes ::/hidden.nes
mattrib -i root.img +h ::/hidden.nes
mdel -i root.img ::/deleted.nes
mmd -i root.img "::/Test ROMs"
mmd -i root.img "::/Test ROMs/Empty"
mcopy -i root.img game3.nes \
    "::/Test ROMs/A very long name, longer than the screen is wide.nes"
mcopy -i root.img game4.nes "::/Test ROMs/Pokémon.nes"
mcopy -i root.img game4.nes "::/Test ROMs/lower.nes"

run root root.img game1.nes a
want_launch
want_screen 2 "   /"
want_screen 4 "  >Super Game (U) {!} & co"
want_screen 5 "   GAME2"
want_screen 6 "   Test ROMs/"
want_screen 7 ""
want_screen 27 "   A:Open  B:Back       1/1"

run down root.img game2.nes down a
want_launch

run wrap_up root.img game1.nes up up up a
want_launch

run subdir root.img game3.nes down down a down a
want_launch
want_screen 2 "   Test ROMs/"
want_screen 4 "   Empty/"
want_screen 5 "  >A very long name, longer th"
want_screen 6 "   Pok?mon"
want_screen 7 "   lower"

run back root.img game2.nes down down a down b up a
want_launch
want_screen 2 "   /"
want_screen 5 "  >GAME2"

run empty_dir root.img game1.nes down down a a
want_screen 2 "   Empty/"
want_screen 4 "   No games here"
want_screen 27 "   A:Open  B:Back"

run empty_back root.img game3.nes down down a a b down a
want_launch

# Two and a third pages on FAT32 in a partition, and a file in two extents:
# it fills the hole that .tmp/hole.bin leaves first. Directories starting
# with '.' are not listed
fat pages.img 32 2048
part="pages.img@@$((2048 * 512))"
mmd -i "$part" ::/.tmp
mcopy -i "$part" game1.nes ::/.tmp/hole.bin
for n in $(seq -w 1 50)
do
    rom page$n.nes $n
    mcopy -i "$part" page$n.nes "::/Game number $n.nes"
done
mdel -i "$part" ::/.tmp/hole.bin
no_hint pages.img 2048
mcopy -i "$part" big.nes "::/Big game.nes"

run first_page pages.img page01.nes a
want_launch
want_screen 2 "   /"
want_screen 4 "  >Game number 01"
want_screen 25 "   Game number 22"
want_screen 27 "   A:Open  B:Back       1/3"

run right pages.img page25.nes right down down a
want_launch
want_screen 4 "   Game number 23"
want_screen 6 "  >Game number 25"
want_screen 27 "   A:Open  B:Back       2/3"

run last_page pages.img big.nes right right right a
want_launch 2
want_screen 10 "  >Big game"
want_screen 11 ""
want_screen 27 "   A:Open  B:Back       3/3"

run wrap_down pages.img page02.nes up down right left down a
want_launch
want_screen 5 "  >Game number 02"

run page_left pages.img page01.nes down down left a
want_launch

# A file with more than 64 extents: 1 block clusters, every other one free
fat frag.img 16
echo small > small.bin
for n in $(seq 1 130)
do
    mcopy -i frag.img small.bin ::/F$n.BIN
done
for n in $(seq 1 2 130)
do
    mdel -i frag.img ::/F$n.BIN
done
rom frag.nes frag
dd if=/dev/urandom bs=512 count=1100 status=none >> frag.nes
mcopy -i frag.img frag.nes "::/Fragmented.nes"

run fragmented frag.img frag.nes a
want_error 19
want_screen 2 "   Error"
want_screen 4 "   File has over 64 fragments"

SD_ERROR_CONTINUE=1 run frag_back frag.img frag.nes a a
want_screen 4 "  >Fragmented"

SD_FAIL=1 run card_failed root.img game1.nes
want_error 11
want_screen 4 "   SD card failed"

if [ $failures == 0 ]
then
    echo "PASS"
else
    echo "$failures FAILED"
    exit 1
fi
