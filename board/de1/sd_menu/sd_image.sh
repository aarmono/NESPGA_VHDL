#!/usr/bin/env bash
#
# Makes an SD card image for ROM_SD_MENU builds: an MBR with one FAT32
# partition (type 0x0C) at block 8192, as on a factory-formatted SDHC card,
# holding MENU.NES. Write it to a card with dd, Raspberry Pi Imager or
# balenaEtcher, then copy .nes files onto the card. The partition is only
# as large as the image; grow it (gparted, or Disks) to use the whole card.
# Needs sfdisk, mkfs.fat (dosfstools) and mtools. Run make first.
#
# Usage: sd_image.sh [ -s SIZE_MB ] [ -m MENU_NES ] IMAGE

set -euo pipefail

HERE=$(cd "$(dirname "$0")"; pwd)
SIZE_MB=256
MENU=$HERE/menu.nes
START=8192
export MTOOLS_SKIP_CHECK=1
PATH=$PATH:/usr/sbin:/sbin

usage() {
    echo "Usage: $0 [ -s SIZE_MB ] [ -m MENU_NES ] IMAGE" >&2
    exit 1
}

while getopts "s:m:" opt
do
    case $opt in
        s) SIZE_MB=$OPTARG ;;
        m) MENU=$OPTARG ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
[ $# == 1 ] || usage
IMG=$1

# FAT32 needs at least 65525 clusters; mkfs.fat picks 512 B clusters below
# 260 MB, so 64 MB is about the smallest that works
if [ "$SIZE_MB" -lt 64 ]
then
    echo "$0: SIZE_MB must be at least 64" >&2
    exit 1
fi
[ -f "$MENU" ] || { echo "$0: no $MENU; run make first" >&2; exit 1; }

part_blocks=$((SIZE_MB * 2048 - START))

rm -f "$IMG"
truncate -s "${SIZE_MB}M" "$IMG"
printf "start=%d, size=%d, type=c\n" $START $part_blocks |
    sfdisk -q --label dos "$IMG" > /dev/null
mkfs.fat -F 32 -n NESPGA --offset $START "$IMG" $((part_blocks / 2)) \
    > /dev/null
mcopy -i "$IMG@@$((START * 512))" "$MENU" ::/MENU.NES

# Check that MENU.NES reads back
check=$(mktemp)
trap 'rm -f "$check"' EXIT
mcopy -n -i "$IMG@@$((START * 512))" ::/MENU.NES "$check"
cmp -s "$MENU" "$check" || { echo "$0: MENU.NES does not match" >&2; exit 1; }

echo "$IMG: $SIZE_MB MB, FAT32 at block $START, MENU.NES $(stat -c %s "$MENU") bytes"
