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
. "$HERE/sd_test_lib.sh"
ROMS=$REPO/nes-test-roms/instr_test-v5/rom_singles
export MTOOLS_SKIP_CHECK=1

WORK=$(mktemp -d)
trap '[ -n "$KEEP_WORK" ] || rm -rf "$WORK"' EXIT
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

# rom_bat FILE SEED [ NVRAM ]: the same with the battery bit set, and with
# NVRAM, a NES 2.0 header with PRG NVRAM of 64 << NVRAM bytes
rom_bat() {
    python3 -c '
import random, sys
random.seed(sys.argv[2])
header = bytearray(b"NES\x1a\x01\x00\x02") + bytes(9)
if len(sys.argv) > 3:
    header[7] = 0x08
    header[10] = int(sys.argv[3]) << 4
open(sys.argv[1], "wb").write(bytes(header) + random.randbytes(16384))
' "$@"
}

# random FILE BYTES SEED: random bytes
random_file() {
    python3 -c '
import random, sys
random.seed(sys.argv[3])
open(sys.argv[1], "wb").write(random.randbytes(int(sys.argv[2])))
' "$@"
}

# state FILE FLAGS [ BANK DATA ]...: sd_test.lua's state: the flags, then
# the 256 KB of cartridge RAM, random, with DATA from the start of each BANK.
# FILE may also be the state to change, in which case FLAGS may be -
state() {
    python3 -c '
import os, random, sys
path, flags = sys.argv[1], sys.argv[2]
if flags == "-":
    data = bytearray(open(path, "rb").read())
else:
    random.seed(path)
    data = bytearray([int(flags)]) + random.randbytes(256 * 1024)
args = sys.argv[3:]
for bank, src in zip(args[::2], args[1::2]):
    chunk = open(src, "rb").read()
    start = 1 + int(bank) * 8192
    data[start:start + len(chunk)] = chunk
open(path, "wb").write(data)
' "$@"
}

# run NAME IMAGE EXPECT BUTTONS...: presses each button (a, b, up, down,
# left, right, start) in turn from frame FIRST_PRESS, PRESS_GAP frames
# apart. The screen is logged after the last press. EXPECT is the file that
# a launch must load. The log is in NAME.log. The card image and state at
# launch or after the last press are in NAME.card and NAME.state, if
# SD_OUT is set, and the state starts from SD_STATE_IN if it is set
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
    rm -rf home "$name.card" "$name.state"
    local out=()
    if [ -n "$SD_OUT" ]
    then
        out=(SD_IMAGE_OUT="$name.card" SD_STATE_OUT="$name.state")
    fi
    env "${out[@]}" \
        SD_IMAGE="$img" SD_EXPECT="$expect" SD_SCREEN_FRAME=$frame \
        "$MESEN_AGENT" "$HERE/menu.nes" --home home \
        --frames $((frame + 20)) --timeout 60 "${inputs[@]}" \
        --lua "$HERE/sd_test.lua" --lua-allow-io > events.jsonl \
        2> stderr.log
    echo "exit $?" > "$name.log"
    lua_log events.jsonl >> "$name.log"
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

# want_save_launch FLAGS: the last run launched EXPECT with PRG RAM kept,
# and the flags FLAGS
want_launch_with() {
    if grep -q "^exit 0" "$current.log" &&
       grep -q "^LAUNCH value $1, .*MATCH, flags $2," "$current.log"
    then
        result ok "launch value $1, flags $2"
    else
        result FAIL "no launch with value $1, flags $2: $(grep -E \
            "^(LAUNCH|ERROR|exit)" "$current.log" | tr '\n' ' ')"
    fi
}

# want_end FLAGS WRITES: the last run ended without a launch, with the flags
# FLAGS, after WRITES block writes
want_end() {
    if grep -q "^END flags $1, [0-9]* reads, $2 writes" "$current.log" &&
       ! grep -q "^\(LAUNCH\|ERROR\)" "$current.log"
    then
        result ok "end flags $1, $2 writes"
    else
        result FAIL "not end flags $1, $2 writes: $(grep -E \
            "^(END|LAUNCH|ERROR|exit)" "$current.log" | tr '\n' ' ')"
    fi
}

# want_writes N: the last run wrote N blocks
want_writes() {
    local writes
    writes=$(grep -c "^write block" "$current.log")
    if [ "$writes" == "$1" ]
    then
        result ok "$1 writes"
    else
        result FAIL "$writes writes, not $1"
    fi
}

# want_file IMAGE PATH DATA: the file PATH in the filesystem IMAGE holds
# DATA
want_file() {
    rm -f got.bin
    if mcopy -n -i "$1" "::/$2" got.bin 2> /dev/null && cmp -s got.bin "$3"
    then
        result ok "$2 holds $(basename "$3")"
    else
        result FAIL "$2 does not hold $(basename "$3")"
    fi
}

# want_fsck IMAGE [ OFFSET ]: fsck.fat finds nothing wrong with the
# filesystem at block OFFSET of IMAGE
want_fsck() {
    local img=$1
    if [ -n "$2" ]
    then
        dd if="$1" of=part.img bs=512 skip="$2" status=none
        img=part.img
    fi
    if /usr/sbin/fsck.fat -n "$img" > fsck.log 2>&1
    then
        result ok "fsck clean"
    else
        result FAIL "fsck: $(tail -n +2 fsck.log | tr '\n' ' ')"
    fi
}

# want_ram STATE BANK DATA: the cartridge RAM in STATE holds DATA from the
# start of BANK
want_ram() {
    if python3 -c '
import sys
data = open(sys.argv[1], "rb").read()
want = open(sys.argv[3], "rb").read()
start = 1 + int(sys.argv[2]) * 8192
sys.exit(data[start:start + len(want)] != want)
' "$@"
    then
        result ok "RAM bank $2 holds $(basename "$3")"
    else
        result FAIL "RAM bank $2 does not hold $(basename "$3")"
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
fragment frag.img
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

# Saves. A battery game without a save, one with a save from an emulator,
# a game without a battery, and a NES 2.0 battery game without PRG NVRAM
fat save.img 16
rom_bat zelda.nes zelda
rom_bat icarus.nes icarus
rom plain.nes plain
rom_bat eeprom.nes eeprom 0
random_file icarus.sav 8192 icarus.sav
python3 -c 'open("zeros.sav", "wb").write(bytes(8192))'
random_file played.sav 8192 played
# A fixed serial number, which root.img does not have
printf '\x78\x56\x34\x12' | dd of=save.img bs=1 seek=$((0x27)) conv=notrunc \
    status=none
mcopy -i save.img zelda.nes "::/Zelda (U).nes"
mcopy -i save.img icarus.nes "::/Kid Icarus.nes"
mcopy -i save.img icarus.sav "::/KID ICARUS.SAV"
mcopy -i save.img plain.nes "::/Plain.nes"
mcopy -i save.img eeprom.nes "::/EEPROM.nes"
state random.state 0

# A new save is made, cleared and loaded
SD_OUT=1 SD_STATE_IN=random.state run save_new save.img zelda.nes a
want_launch_with 2 3
want_file save_new.card "Zelda (U).sav" zeros.sav
want_ram save_new.state 0 zeros.sav
want_fsck save_new.card

# Back from the game, PRG RAM is written to it, and the cursor is where it
# was
state save_new.state - 0 played.sav
SD_OUT=1 SD_STATE_IN=save_new.state FIRST_PRESS=40 run save_back \
    save_new.card zelda.nes
want_end 2 16
want_file save_back.card "Zelda (U).sav" played.sav
want_screen 4 "  >Zelda (U)"
want_fsck save_back.card

# The save is found again, and with a short name in other case
SD_OUT=1 SD_STATE_IN=save_back.state run save_again save_back.card zelda.nes a
want_launch_with 2 3
want_writes 0
want_ram save_again.state 0 played.sav

SD_OUT=1 SD_STATE_IN=save_back.state run save_found save_back.card \
    icarus.nes down a
want_launch_with 2 3
want_writes 0
want_ram save_found.state 0 icarus.sav

# A 2 KB save from an emulator: the rest of the 8 KB is cleared, and only
# 4 blocks are written back
head -c 2048 played.sav > small.sav
python3 -c 'open("small8k.sav", "wb").write(open("small.sav", "rb").read() + bytes(6144))'
cp save_back.card small_save.img
mcopy -i small_save.img small.sav "::/Plain.sav"
mcopy -i small_save.img plain.nes "::/Plain.nes"
rom_bat small_bat.nes small_bat
mdel -i small_save.img "::/Plain.nes"
mcopy -i small_save.img small_bat.nes "::/Plain.nes"
SD_OUT=1 SD_STATE_IN=random.state run small_save small_save.img \
    small_bat.nes down down a
want_launch_with 2 3
want_ram small_save.state 0 small8k.sav
state small_save.state - 0 played.sav
SD_OUT=1 SD_STATE_IN=small_save.state FIRST_PRESS=40 run small_back \
    small_save.card small_bat.nes
want_end 2 4
want_file small_back.card "Plain.sav" small.sav

# No save, but the cursor is kept
SD_OUT=1 SD_STATE_IN=random.state run no_battery save.img plain.nes \
    down down a
want_launch_with 0 2
want_writes 0
SD_STATE_IN=no_battery.state FIRST_PRESS=40 run no_battery_back save.img \
    plain.nes
want_end 2 0
want_screen 6 "  >Plain"

SD_OUT=1 SD_STATE_IN=random.state run no_nvram save.img eeprom.nes \
    down down down a
want_launch_with 0 2
want_writes 0

# A save waiting for another card is not written to this one
SD_STATE_IN=save_new.state run wrong_card root.img game1.nes
want_error 1D

# A 32 KB NES 2.0 save in four banks, with a long name, in a directory on
# FAT32
fat big_save.img 32 2048
part="big_save.img@@$((2048 * 512))"
rom_bat long.nes long 9
random_file long.sav 32768 long.sav
long="A battery game whose name is far longer than the screen"
mmd -i "$part" ::/Games
mcopy -i "$part" game1.nes "::/Games/First.nes"
mcopy -i "$part" long.nes "::/Games/$long.nes"
python3 -c 'open("zeros32.sav", "wb").write(bytes(32768))'
SD_OUT=1 SD_STATE_IN=random.state run long_new big_save.img long.nes \
    a down a
want_launch_with 2 3
want_file "long_new.card@@$((2048 * 512))" "Games/$long.sav" zeros32.sav
want_fsck long_new.card 2048
state long_new.state - 0 long.sav
SD_OUT=1 SD_STATE_IN=long_new.state FIRST_PRESS=60 run long_back \
    long_new.card long.nes
want_end 2 64
want_screen 2 "   Games/"
want_screen 5 "  >${long:0:27}"
want_file "long_back.card@@$((2048 * 512))" "Games/$long.sav" long.sav
want_fsck long_back.card 2048

# No room in a root directory of 16 entries
rm -f full.img
/usr/sbin/mkfs.fat -C -F 16 -s 1 -r 16 full.img 16384 > /dev/null 2>&1
mcopy -i full.img "$HERE/menu.nes" ::/MENU.NES
mcopy -i full.img zelda.nes "::/Zelda (U).nes"
echo small > small.bin
for n in $(seq 1 13)
do
    mcopy -i full.img small.bin ::/F$n.BIN
done
SD_OUT=1 run dir_full full.img zelda.nes a
want_error 1B
want_writes 0

# A save whose cluster chain is shorter than its size: nothing past the
# chain may be read or written
fat short.img 16
rom_bat short.nes short
mcopy -i short.img short.nes ::/SHORT.NES
mcopy -i short.img played.sav ::/SHORT.SAV
python3 -c '
import struct, sys
with open(sys.argv[1], "r+b") as f:
    boot = f.read(512)
    reserved, = struct.unpack_from("<H", boot, 0x0E)
    fats = boot[0x10]
    fat_size, = struct.unpack_from("<H", boot, 0x16)
    f.seek((reserved + fats * fat_size) * 512)
    root = f.read(16 * 512)
    entry = root.index(b"SHORT   SAV")
    clus, = struct.unpack_from("<H", root, entry + 26)
    for n in range(fats):
        f.seek((reserved + n * fat_size) * 512 + 2 * clus)
        f.write(b"\xff\xff")
' short.img
SD_OUT=1 run short_chain short.img short.nes a
want_error 18
want_writes 0

summary
