# Shared by stub_test.sh and menu_test.sh, which source it

# lua_log EVENTS: the text that sd_test.lua logged, from mesen-agent's
# events
lua_log() {
    python3 -c '
import json, sys
for line in open(sys.argv[1]):
    event = json.loads(line)
    if event.get("event") == "lua_log":
        print(event["text"], end="")
' "$1"
}

# fragment IMAGE: fills IMAGE, an empty filesystem with 1 block clusters,
# with 130 small files, then deletes every other one, so that the next file
# copied to it is in more than 64 extents
fragment() {
    local img=$1 n
    local files=() odd=()
    for n in $(seq 1 130)
    do
        echo small > F$n.BIN
        files+=(F$n.BIN)
        (( n % 2 )) && odd+=(::/F$n.BIN)
    done
    MTOOLS_SKIP_CHECK=1 mcopy -i "$img" "${files[@]}" ::/
    MTOOLS_SKIP_CHECK=1 mdel -i "$img" "${odd[@]}"
}

# summary: PASS, or the number of failures and exit status 1
summary() {
    if [ "$failures" == 0 ]
    then
        echo "PASS"
    else
        echo "$failures FAILED"
        exit 1
    fi
}
