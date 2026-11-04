#!/usr/bin/env bash
#
# Writes a CPU bus trace of a ROM from AprVisual, a switch-level simulation of
# the 2A03 and 2C02 netlists (Visual2A03/Visual2C02 by way of MetalNES), for
# comparing with nes_bench's -gTRACE_FILEPATH trace using trace_diff.py.
#
# The first run fetches AprVisual and MetalNES at the commits below into the
# work directory, adds aprvisual_pin_trace.patch (a --pin-trace mode that
# samples the 2A03's pins once per M2 cycle), puts the netlist data together
# with AprVisual's 2A03 netlist patch, and builds it in the .NET SDK docker
# image, again whenever the patch changes. The netlist data is CC-BY-NC-SA, so
# it stays out of this repository.
#
# -v also writes the 2C02's video output per PPU dot, for comparing with
# nes_bench's -gVIDEO_TRACE_FILEPATH trace using video_diff.py.
#
# AprVisual only has NROM and CNROM boards. It runs about 3000 CPU cycles a
# second, about 10 seconds per frame.

set -e -o pipefail

usage() {
    echo "Usage: $0 [ -w WORK_DIR ] [ -c CYCLES ] [ -k HALF_CYCLES ] [ -v VIDEO_OUT ] [ -f FM2 ] [ -n ] ROM OUT [ ARGS... ]"
    echo "  -w  where AprVisual is built (default ~/.cache/nespga_aprvisual)"
    echo "  -c  CPU cycles to trace from power up (default 100000)"
    echo "  -k  extra half-cycles of reset (default 1), which picks one of the"
    echo "      4 CPU-PPU clock alignments; AprVisual's tests use 1, the one"
    echo "      blargg's ppu_vbl_nmi NMI timing tests pass on (0 fails them)"
    echo "  -v  also write the video output, 4 bytes per PPU dot (see the patch)"
    echo "  -f  play controller 1 of an FM2 movie, timed as nes_bench plays it"
    echo "  -n  no shims: the raw netlist, without AprVisual's power up state"
    echo "      and its corrections for analog effects"
    echo "  ARGS are passed to AprVisual, such as --pin-probe NODES --pin-probe-from"
    echo "  CYCLE --pin-probe-to CYCLE to print nodes each half-cycle (see the patch)"
}

APRVISUAL_COMMIT=ced0e1d53357b85ab1dbbc047c0bfd0fcc70130e
METALNES_COMMIT=6acddfb97f49c54fc68349ae76ea2da3dfd2d715
IMAGE=mcr.microsoft.com/dotnet/sdk:11.0

WORK_DIR="$HOME/.cache/nespga_aprvisual"
CYCLES=100000
RESET_HOLD=1
VIDEO_OUT=
FM2=
RUN_ARGS=()
SHIM_ARGS=()

while getopts w:c:k:v:f:nh flag
do
    case "${flag}" in
        w) WORK_DIR="${OPTARG}";;
        c) CYCLES="${OPTARG}";;
        k) RESET_HOLD="${OPTARG}";;
        v) VIDEO_OUT="${OPTARG}";;
        f) FM2="${OPTARG}";;
        n) SHIM_ARGS=(--no-shims);;
        h) usage
           exit 0;;
        *) usage
           exit 1;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 2 ]
then
    usage
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$WORK_DIR" "$(dirname "$2")"
WORK_DIR="$(realpath "$WORK_DIR")"
ROM="$(realpath "$1")"
OUT="$(realpath "$2")"
MOUNTS=(-v "$WORK_DIR:$WORK_DIR" -v "$(dirname "$ROM"):$(dirname "$ROM"):ro"
        -v "$(dirname "$OUT"):$(dirname "$OUT")")
if [ -n "$VIDEO_OUT" ]
then
    mkdir -p "$(dirname "$VIDEO_OUT")"
    VIDEO_OUT="$(realpath "$VIDEO_OUT")"
    RUN_ARGS=(--pin-video "$VIDEO_OUT")
    MOUNTS+=(-v "$(dirname "$VIDEO_OUT"):$(dirname "$VIDEO_OUT")")
fi
if [ -n "$FM2" ]
then
    FM2="$(realpath "$FM2")"
    RUN_ARGS+=(--pin-fm2 "$FM2")
    MOUNTS+=(-v "$(dirname "$FM2"):$(dirname "$FM2"):ro")
fi

fetch() {
    local dir="$1" url="$2" commit="$3"
    if [ ! -d "$dir" ]
    then
        git init -q "$dir"
        git -C "$dir" fetch -q --depth 1 "$url" "$commit"
        git -C "$dir" checkout -q FETCH_HEAD
    fi
}

dotnet() {
    docker run --rm --init -u "$(id -u):$(id -g)" \
        -e HOME=/tmp -e DOTNET_CLI_TELEMETRY_OPTOUT=1 \
        -e NUGET_PACKAGES="$WORK_DIR/nuget" \
        "${MOUNTS[@]}" -w "$WORK_DIR" "$IMAGE" dotnet "$@"
}

APR="$WORK_DIR/AprVisual"
SYSDEF="$WORK_DIR/system-def"
BIN="$WORK_DIR/bin"

PATCH="$SCRIPT_DIR/aprvisual_pin_trace.patch"
if [ ! -f "$BIN/AprVisual.S1.dll" ] || ! cmp -s "$PATCH" "$WORK_DIR/applied.patch"
then
    fetch "$APR" https://github.com/erspicu/AprVisual.git "$APRVISUAL_COMMIT"
    fetch "$WORK_DIR/metalnes" https://github.com/iaddis/metalnes.git "$METALNES_COMMIT"

    git -C "$APR" reset -q --hard
    git -C "$APR" clean -q -fd src
    git -C "$APR" apply "$PATCH"

    rm -rf "$SYSDEF"
    cp -r "$WORK_DIR/metalnes/data/system-def" "$SYSDEF"
    cp "$APR/src/AprVisual.S1/data/system-def/nes-pad-behavioral.js" "$SYSDEF"
    python3 -I "$APR/tools/netlist/apply_2a03_patches.py" "$SYSDEF/2a03"

    dotnet build -c Release -o "$BIN" "$APR/src/AprVisual.S1/AprVisual.S1.csproj" |
        grep -E ' error |Error\(s\)'
    cp "$PATCH" "$WORK_DIR/applied.patch"
fi

dotnet "$BIN/AprVisual.S1.dll" --system-def-dir "$SYSDEF" "${SHIM_ARGS[@]}" \
    --reset-hold-extra "$RESET_HOLD" "${RUN_ARGS[@]}" \
    --pin-trace "$ROM" --pin-out "$OUT" --pin-cycles "$CYCLES" "${@:3}" 2>&1 |
    grep -v 'already maps'
