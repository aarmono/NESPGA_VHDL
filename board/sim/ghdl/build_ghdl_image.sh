#!/usr/bin/env bash

set -e

IMAGE=nespga-ghdl:7.0.0-dev-llvm-ubuntu-22.04

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker build -t "$IMAGE" "$SCRIPT_DIR"
