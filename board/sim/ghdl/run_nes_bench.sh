#!/usr/bin/env bash

NES_FILEPATH="$1"
if [ "$2" != "" ]
then
    OUTPUT_DIR="$2"
    shift 2
else
    OUTPUT_DIR=`basename "$1"`
    shift 1
fi
AU_FILEPATH="$OUTPUT_DIR"/audio.au
BMP_PREFIX="$OUTPUT_DIR"/frame
NES_SIZE=`wc -c "$NES_FILEPATH" | cut -d ' ' -f 1`

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*

make -s -f nes_bench.Makefile &&
exec ./nes_bench -gAU_FILEPATH="$AU_FILEPATH"    \
                 -gBMP_FILE_PREFIX="$BMP_PREFIX" \
                 -gNES_FILEPATH="$NES_FILEPATH"  \
                 -gNES_FILE_BYTES="$NES_SIZE"    \
                 $@
