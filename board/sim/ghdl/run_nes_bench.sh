#!/usr/bin/env bash

NES_FILEPATH="$1"
AU_FILEPATH="$2"/audio.au
BMP_PREFIX="$2"/frame
NES_SIZE=`wc -c "$1" | cut -d ' ' -f 1`

shift 2

make -f nes_bench.Makefile &&
exec ./nes_bench -gAU_FILEPATH="$AU_FILEPATH"    \
                 -gBMP_FILE_PREFIX="$BMP_PREFIX" \
                 -gNES_FILEPATH="$NES_FILEPATH"  \
                 -gNES_FILE_BYTES="$NES_SIZE"    \
                 $@
