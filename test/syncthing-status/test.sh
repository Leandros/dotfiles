#!/usr/bin/env bash
#
# bin/syncthing-status with stubs for syncthing (its GUI config) and curl
# (Syncthing's REST API, answered from fixture files): the bar text (idle,
# percent done, off, nothing without Syncthing) and the --details hover
# text (rates from two connection samples, needed files and bytes,
# errors, devices, folder states). The API key goes to curl on stdin,
# never in its arguments.
#
# Usage: test/syncthing-status/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/syncthing-status"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" API="$TMP/api" CALLS="$TMP/calls" SYSBIN="$TMP/sysbin"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: want '$want', got '$got'"; fi
}

write_stubs() {
    mkdir -p "$STUBS" "$API" "$SYSBIN"
    # syncthing: the GUI config; fails while TMP/down exists (not running).
    cat > "$STUBS/syncthing" <<STUB
#!/bin/sh
[ -e "$TMP/down" ] && exit 1
[ "\$*" = "cli config gui dump-json" ] || exit 2
cat "$TMP/gui.json"
STUB
    # curl: records its arguments and the key header from stdin, answers
    # from API/<path>, "?" as "_". system/connections counts up: the
    # second sample has 1 MB more down and 40 kB more up.
    cat > "$STUBS/curl" <<STUB
#!/bin/bash
url="\${*: -1}"
echo "curl \$* key=\$(grep -o 'X-API-Key: .*' || true)" >> "$CALLS"
path="\${url#*/rest/}"
if [[ "\$path" == system/connections ]]; then
    n=\$(cat "$TMP/samples" 2>/dev/null || echo 0); echo \$((n + 1)) > "$TMP/samples"
    printf '{"total":{"inBytesTotal":%d,"outBytesTotal":%d},"connections":{"A":{"connected":true},"B":{"connected":false}}}' \
        \$((1000 + n * 1000000)) \$((500 + n * 40000))
    exit 0
fi
f="$API/\${path//[?\/=]/_}"
[ -f "\$f" ] || exit 22
cat "\$f"
STUB
    chmod +x "$STUBS"/*
    # Only the stubs and basic tools: a real syncthing must not count.
    local tool
    for tool in bash env jq awk cat sleep timeout grep sed printf; do
        ln -sf "$(command -v "$tool")" "$SYSBIN/$tool"
    done
}

run() { PATH="$STUBS:$SYSBIN" SYNCTHING_STATUS_SAMPLE_S=1 "$SCRIPT" "$@"; }

main() {
    command -v jq >/dev/null || { echo "SKIP: jq not installed"; exit 0; }
    write_stubs
    echo '{"address":"127.0.0.1:8384","useTLS":false,"apiKey":"k3y"}' > "$TMP/gui.json"
    echo '{"completion":100,"needBytes":0,"needItems":0}' > "$API/db_completion"

    : > "$CALLS"
    expect "idle when complete" "idle" "$(run)"
    expect "key on stdin, not in the arguments" \
        "curl -fsS --max-time 2 -H @- http://127.0.0.1:8384/rest/db/completion key=X-API-Key: k3y" \
        "$(cat "$CALLS")"

    echo '{"completion":42.7,"needBytes":5,"needItems":1}' > "$API/db_completion"
    expect "percent done while syncing, rounded down" "42%" "$(run)"

    echo '{"address":"0.0.0.0:8443","useTLS":true,"apiKey":"k3y"}' > "$TMP/gui.json"
    : > "$CALLS"
    run > /dev/null
    expect "TLS: https, its own certificate" \
        "curl -fsS --max-time 2 -k -H @- https://0.0.0.0:8443/rest/db/completion key=X-API-Key: k3y" \
        "$(cat "$CALLS")"
    echo '{"address":"127.0.0.1:8384","useTLS":false,"apiKey":"k3y"}' > "$TMP/gui.json"

    touch "$TMP/down"
    expect "off when Syncthing does not answer" "off" "$(run)"
    rm "$TMP/down"
    echo '{"address":"127.0.0.1:8384","useTLS":false,"apiKey":"k3y"}' > "$TMP/gui.json"
    mv "$API/db_completion" "$TMP/completion.off"
    expect "off when the API fails" "off" "$(run)"
    mv "$TMP/completion.off" "$API/db_completion"

    mv "$STUBS/syncthing" "$TMP/syncthing.off"
    local out rc=0
    out="$(run)" || rc=$?
    expect "nothing without Syncthing" "1:" "$rc:$out"
    mv "$TMP/syncthing.off" "$STUBS/syncthing"

    echo '[{"id":"ws","label":"Workspace"},{"id":"ph","label":""}]' > "$API/config_folders"
    echo '{"state":"syncing","needFiles":2,"needBytes":2000000,"errors":1}' > "$API/db_status_folder_ws"
    echo '{"state":"idle","needFiles":1,"needBytes":500000,"errors":0}' > "$API/db_status_folder_ph"
    echo '{"errors":[{"message":"x"}]}' > "$API/system_error"
    rm -f "$TMP/samples"
    expect "details" \
        "State:   syncing (42%)|Down:    1.0 MB/s|Up:      40 kB/s|Needed:  3 files, 2.5 MB|Errors:  2|Devices: 1 of 2 connected|Folders: Workspace: syncing|         ph: idle" \
        "$(run --details | paste -sd '|')"
    echo '{"errors":null}' > "$API/system_error"
    echo '{"completion":100,"needBytes":0,"needItems":0}' > "$API/db_completion"
    rm -f "$TMP/samples"
    expect "details: idle, no system errors" "State:   idle|Errors:  1" \
        "$(run --details | grep -E '^(State|Errors):' | paste -sd '|')"
    touch "$TMP/down"
    expect "details: off" "State:   off" "$(run --details)"
    rm "$TMP/down"

    exit "$FAILED"
}

main "$@"
