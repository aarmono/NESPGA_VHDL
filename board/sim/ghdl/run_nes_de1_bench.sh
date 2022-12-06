#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [ -n NES_FILEPATH ] [ -o OUTPUT_DIR ] [ -i FM2_FILEPATH ] [ -t SIMULATION_TIME ]"
}

exit_abnormal() {
    usage
    exit 1
}

while getopts n:o:i:t:h flag
do
    case "${flag}" in
        n) NES_FILEPATH="${OPTARG}";;
        o) OUTPUT_DIR="${OPTARG}";;
        t) SIMULATION_TIME="${OPTARG}";;
        h) usage
           exit 0;;
        :) echo "Error: -${OPTARG} requires an argument."
           exit_abnormal;;
        ?) echo "Error: Unknown argument -${OPTARG}"
           exit_abnormal;;
    esac
done

if [ "$NES_FILEPATH" == "" ]
then
    echo "Missing NES Filepath argument"
    exit_abnormal
fi

if [ "$OUTPUT_DIR" == "" ]
then
    OUTPUT_DIR=`basename "$NES_FILEPATH"`
fi

AU_FILEPATH="$OUTPUT_DIR"/audio.au
BMP_PREFIX="$OUTPUT_DIR"/frame
NES_SIZE=`wc -c "$NES_FILEPATH" | cut -d ' ' -f 1`

if [ "$SIMULATION_TIME" != "" ]
then
    TIME_PARM="--stop-time=$SIMULATION_TIME"
fi

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*

make -s -f nes_de1_bench.Makefile &&
exec ./nes_de1_bench -gAU_FILEPATH="$AU_FILEPATH"    \
                     -gBMP_FILE_PREFIX="$BMP_PREFIX" \
                     -gNES_FILEPATH="$NES_FILEPATH"  \
                     -gNES_FILE_BYTES="$NES_SIZE"    \
                     $TIME_PARM                      \
                     --unbuffered
