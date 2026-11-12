#!/usr/bin/env bash
#
# Runs bin/wm-msg with stubs for swaymsg and i3-msg: swaymsg in a sway
# session (SWAYSOCK set; sway sets DISPLAY too, for Xwayland), else
# i3-msg, with the same arguments and exit status.
#
# Usage: test/wm-msg/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/wm-msg"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then
        ok "$name"
    else
        fail "$name: want '$want', got '$got'"
    fi
}

# One field per argument; exit status from TMP/rc.
write_stubs() {
    mkdir -p "$STUBS"
    local tool
    for tool in swaymsg i3-msg; do
        cat > "$STUBS/$tool" <<EOF
#!/bin/sh
{ printf '$tool'; printf '|%s' "\$@"; echo; } >> "$CALLS"
exit "\$(cat "$TMP/rc" 2>/dev/null || echo 0)"
EOF
        chmod +x "$STUBS/$tool"
    done
}

# Runs wm-msg with the session variables before "--"; prints the call.
run() {
    local vars=()
    while [[ "$1" != -- ]]; do
        vars+=("$1")
        shift
    done
    shift
    : > "$CALLS"
    env -u SWAYSOCK -u DISPLAY ${vars[@]+"${vars[@]}"} PATH="$STUBS:$PATH" "$SCRIPT" "$@" || true
    cat "$CALLS"
}

main() {
    write_stubs

    expect "sway: swaymsg, arguments kept" "swaymsg|-q|exec --no-startup-id nmrs-gui" \
        "$(run SWAYSOCK=/run/sway.sock -- -q "exec --no-startup-id nmrs-gui")"
    expect "sway with Xwayland DISPLAY: still swaymsg" "swaymsg|-t|get_outputs" \
        "$(run SWAYSOCK=/run/sway.sock DISPLAY=:0 -- -t get_outputs)"
    expect "X: i3-msg" "i3-msg|-t|get_outputs" "$(run DISPLAY=:0 -- -t get_outputs)"
    expect "no session: i3-msg (its own error)" "i3-msg|reload" "$(run -- reload)"
    expect "empty SWAYSOCK is not sway" "i3-msg|reload" "$(run SWAYSOCK= DISPLAY=:0 -- reload)"

    echo 2 > "$TMP/rc"
    local rc=0
    SWAYSOCK=/run/sway.sock PATH="$STUBS:$PATH" "$SCRIPT" reload || rc=$?
    expect "exit status of swaymsg" "2" "$rc"
    rc=0
    env -u SWAYSOCK PATH="$STUBS:$PATH" "$SCRIPT" reload || rc=$?
    expect "exit status of i3-msg" "2" "$rc"

    exit "$FAILED"
}

main "$@"
