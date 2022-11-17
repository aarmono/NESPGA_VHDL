#!/usr/bin/env bash

NES_FILEPATH="$1"
OUTPUT_DIR=output/`basename "$1" .nes`
AU_FILEPATH="$OUTPUT_DIR"/audio.au
BMP_PREFIX="$OUTPUT_DIR"/frame
NES_SIZE=`wc -c "$1" | cut -d ' ' -f 1`

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*

shift 1

make -f nes_bench.Makefile &&
exec ./nes_bench -gAU_FILEPATH="$AU_FILEPATH"    \
                 -gBMP_FILE_PREFIX="$BMP_PREFIX" \
                 -gNES_FILEPATH="$NES_FILEPATH"  \
                 -gNES_FILE_BYTES="$NES_SIZE"    \
                 $@
