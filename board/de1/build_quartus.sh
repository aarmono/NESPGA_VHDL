#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [ -r ]"
    echo "  -r  Don't compile. Print a report of the last compile, then exit"
    echo
    echo "Compiles the NES Quartus project in this directory using a Quartus"
    echo "13.0sp1 docker image, producing NES.sof and NES.pof, and writes the"
    echo "detailed timing reports of timing_report.tcl into timing/"
    echo
    echo "When the compile finishes, a Markdown report of the resource usage"
    echo "and timing slack is printed. The exit status is nonzero if the"
    echo "compile failed or any timing requirement is not met"
}

exit_abnormal() {
    usage
    exit 1
}

# Pinned by digest since this is a third party image
IMAGE=ghcr.io/raetro/quartus@sha256:a4ec6693b1a33c96a64e0e37df7f9f4af7ac272c22eb77901bb28421c951fa40

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

REPORT_ONLY=0

while getopts "rh" opt; do
    case "$opt" in
        r) REPORT_ONLY=1 ;;
        h) usage; exit 0 ;;
        *) exit_abnormal ;;
    esac
done

# Prints the Multicorner Timing Analysis Summary of the timing analyzer
# report as a Markdown table. Exits nonzero if any worst-case slack is
# negative
timing_report() {
    awk '
        /^; Multicorner Timing Analysis Summary/ { in_table = 1; next }
        !in_table { next }
        /^$/ { exit }
        !/^;/ { next }
        {
            n = split($0, cells, ";")
            row = "|"
            for (i = 2; i < n; i++) {
                cell = cells[i]
                indent = (i == 2 && cell ~ /^  /)
                gsub(/^ +| +$/, "", cell)
                gsub(/\|/, "\\|", cell)
                if (indent) cell = "&emsp;" cell
                else if (i == 2 && rows > 0) cell = "**" cell "**"
                row = row " " cell " |"
            }
            print row
            if (rows++ == 0) {
                sep = "|"
                for (i = 2; i < n; i++) sep = sep " --- |"
                print sep
            }
            if (cells[2] ~ /Worst-case Slack/ ||
                (in_slack && cells[2] ~ /^  /)) {
                in_slack = 1
                for (i = 3; i < n; i++) if (cells[i] + 0 < 0) failed = 1
            } else {
                in_slack = 0
            }
        }
        END { exit failed }
    ' "$SCRIPT_DIR/NES.sta.rpt"
}

report() {
    if [ ! -f "$SCRIPT_DIR/NES.fit.summary" ] || [ ! -f "$SCRIPT_DIR/NES.sta.rpt" ]; then
        echo "No compile results found in $SCRIPT_DIR"
        return 1
    fi

    echo "## Quartus build"
    echo
    echo '```'
    cat "$SCRIPT_DIR/NES.fit.summary"
    echo '```'
    echo
    echo "### Timing"
    echo
    if timing_report; then
        echo
        echo "All timing requirements met"
    else
        echo
        echo "**Timing requirements not met**"
        return 1
    fi
}

if [ "$REPORT_ONLY" -eq 0 ]; then
    # Runs as the current user so the outputs aren't owned by root. Quartus
    # writes its settings into HOME, which doesn't exist in the image for
    # an arbitrary user
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        -v "$REPO_DIR":/build \
        -w /build/board/de1 \
        "$IMAGE" \
        sh -c 'quartus_sh --flow compile NES && quartus_sta -t timing_report.tcl' ||
        exit 1
    echo
fi

report
