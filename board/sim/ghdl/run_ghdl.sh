#!/usr/bin/env bash

set -e

IMAGE=ghdl/ghdl:ubuntu22-llvm-11

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

DOCKER_ARGS=(
    --rm
    --init
    -v "$REPO_ROOT:$REPO_ROOT"
    -w "$SCRIPT_DIR"
)

if [ -t 0 ] && [ -t 1 ]
then
    DOCKER_ARGS+=(-it)
fi

if [ $# -eq 0 ]
then
    exec docker run "${DOCKER_ARGS[@]}" "$IMAGE" bash
else
    exec docker run "${DOCKER_ARGS[@]}" "$IMAGE" "$@"
fi
