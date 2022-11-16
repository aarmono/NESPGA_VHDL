#!/usr/bin/env bash

OAM_MEM=`find "$1" -name '*.dmp' -size 256c`
SEC_OAM_MEM=`find "$1" -name '*.dmp' -size 32c`
PPU_MEM=`find "$1" -name '*.dmp' -size 16384c`
BMP_PREFIX="$1"/frame

shift 1

make -f ppu_bench.Makefile &&
exec ./ppu_bench -gBMP_FILE_PREFIX="$BMP_PREFIX"       \
                 -gPPU_MEM_FILEPATH="$PPU_MEM"         \
                 -gOAM_MEM_FILEPATH="$OAM_MEM"         \
                 -gSEC_OAM_MEM_FILEPATH="$SEC_OAM_MEM" \
                 $@
