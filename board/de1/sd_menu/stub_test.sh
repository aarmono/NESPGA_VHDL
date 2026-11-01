#!/usr/bin/env bash
#
# Runs the boot stub in Mesen (mesen-agent) on SD card images of each layout
# it must handle, made by simulation/sd_card/fat_image.py and mtools, with
# sd_test.lua standing in for sd_menu's registers. MENU.NES is ROM
# (default: an instr_test-v5 ROM). Each case must launch MENU.NES with
# extents that hold it, or show the error color it expects. Run make first.
#
# Usage: stub_test.sh [ ROM ]

HERE=$(cd "$(dirname "$0")"; pwd)
REPO=$(cd "$HERE/../../.."; pwd)
MESEN_AGENT=${MESEN_AGENT:-$HOME/.local/bin/mesen-agent}
. "$HERE/sd_test_lib.sh"
ROM=${1:-$REPO/nes-test-roms/instr_test-v5/rom_singles/01-basics.nes}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

failures=0

image() {
    python3 -B "$REPO/simulation/sd_card/fat_image.py" "$@" > /dev/null ||
        exit 1
}

# check NAME RESULT IMAGE [ ENV... ]. RESULT is launch or an error color
check() {
    local name=$1 want=$2 img=$3
    shift 3
    rm -rf home
    env "$@" SD_IMAGE="$img" SD_EXPECT="$ROM" "$MESEN_AGENT" \
        "$HERE/stub.nes" --home home --frames 20 --timeout 60 \
        --lua "$HERE/sd_test.lua" --lua-allow-io > events.jsonl \
        2> stderr.log
    local code=$?
    local result
    result=$(lua_log events.jsonl | grep -E "^(LAUNCH|ERROR)" | head -1)

    local status=FAIL
    if [ "$want" == launch ]
    then
        [ $code == 0 ] && status=ok
    elif [ $code == 2 ] && [[ "$result" == "ERROR color \$$want "* ]]
    then
        status=ok
    fi
    [ $status == ok ] || failures=$((failures + 1))
    printf "%-4s %-20s %s\n" $status "$name" "${result:-exit $code}"
}

image fat16.img ext "$ROM" --name MENU.NES
check fat16 launch fat16.img

image fat16_frag.img ext "$ROM" --name MENU.NES --cluster-blocks 4 \
    --size-kb 12288 --root-fill 40 --decoys --run 2 --gap 1
check fat16_frag launch fat16_frag.img

image fat16_total32.img ext "$ROM" --name MENU.NES --size-kb 40960 \
    --cluster-blocks 2
check fat16_total32 launch fat16_total32.img

image fat16_mbr.img ext "$ROM" --name MENU.NES --mbr-start 100000 \
    --part-type 0x06 --root-fill 20
check fat16_mbr launch fat16_mbr.img

image fat16_mbr_04.img ext "$ROM" --name MENU.NES --mbr-start 63 \
    --part-type 0x04 --cluster-blocks 8 --size-kb 20480
check fat16_mbr_04 launch fat16_mbr_04.img

image fat32.img ext "$ROM" --name MENU.NES --fat 32 --size-kb 8192 \
    --root-fill 40 --decoys
check fat32 launch fat32.img

image fat32_mbr.img ext "$ROM" --name MENU.NES --fat 32 --size-kb 8192 \
    --mbr-start 8192 --cluster-blocks 8
check fat32_mbr launch fat32_mbr.img

image fat32_frag.img ext "$ROM" --name MENU.NES --fat 32 --size-kb 8192 \
    --mbr-start 70000 --part-type 0x0B --cluster-blocks 2 --run 1 --gap 1 \
    --root-fill 70 --decoys
check fat32_frag launch fat32_frag.img

check card_failed 11 fat16.img SD_FAIL=1

head -c 1048576 /dev/urandom > random.img
check no_signature 12 random.img

image gpt.img ext "$ROM" --name MENU.NES --mbr-start 2048 --gpt
check gpt 13 gpt.img

image ntfs.img ext "$ROM" --name MENU.NES --mbr-start 2048 --part-type 0x07
check partition_type 14 ntfs.img

# The partition's first block without its jump
cp fat16_mbr.img no_boot.img
printf '\x00\x00\x00' |
    dd of=no_boot.img bs=1 seek=$((100000 * 512)) conv=notrunc status=none
check no_boot_sector 15 no_boot.img

/usr/sbin/mkfs.fat -C -F 12 fat12.img 4096 > /dev/null 2>&1
check fat12 16 fat12.img

image not_found.img ext "$ROM" --name OTHER.NES --root-fill 30
check not_found 17 not_found.img

image not_found32.img ext "$ROM" --name OTHER.NES --fat 32 --size-kb 8192 \
    --root-fill 30
check not_found_fat32 17 not_found32.img

# MENU.NES as an empty file, which has no clusters
cp fat16.img empty.img
python3 - <<'PY'
import struct
image = bytearray(open("empty.img", "rb").read())
reserved, = struct.unpack_from("<H", image, 0x0E)
fats = image[0x10]
entries, = struct.unpack_from("<H", image, 0x11)
fat_size, = struct.unpack_from("<H", image, 0x16)
root = (reserved + fats * fat_size) * 512
for i in range(entries):
    offset = root + 32 * i
    if image[offset:offset + 11] == b"MENU    NES":
        image[offset + 26:offset + 32] = bytes(6)
open("empty.img", "wb").write(image)
PY
check empty_file 18 empty.img

# MENU.NES with more than 64 extents: 1 block clusters, every other one free
/usr/sbin/mkfs.fat -C -F 16 -s 1 frag.img 16384 > /dev/null 2>&1
fragment frag.img
cat "$ROM" "$ROM" "$ROM" "$ROM" > big.nes
MTOOLS_SKIP_CHECK=1 mcopy -i frag.img big.nes ::/MENU.NES
check fragmented 19 frag.img

summary
