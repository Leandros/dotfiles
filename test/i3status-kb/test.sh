#!/usr/bin/env bash
#
# Feeds i3bar click events to bin/i3status-kb with stubs for i3status, kb
# and i3-msg, and checks which commands the clicks run.
#
# Usage: test/i3status-kb/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/i3status-kb"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly CALLS="$TMP/calls"
readonly SETTLE_S=0.5
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

write_stubs() {
    mkdir -p "$TMP/home/bin" "$TMP/stubs"
    cat > "$TMP/stubs/i3status" <<'EOF'
#!/bin/sh
echo '{"version":1}'
echo '['
echo '[{"name":"wireless","instance":"_first_","full_text":"W: up"}]'
while sleep 1; do echo ',[{"name":"wireless","instance":"_first_","full_text":"W: up"}]'; done
EOF
    # shellcheck disable=SC2016 # $* and $1 belong to the stub.
    printf '#!/bin/sh\necho "kb $*" >> %s\n[ "$1" = show ] && echo us\nexit 0\n' "$CALLS" > "$TMP/home/bin/kb"
    # One field per argument: i3-msg reads options anywhere in its arguments.
    cat > "$TMP/stubs/i3-msg" <<EOF
#!/bin/sh
{ printf 'i3-msg'; printf '|%s' "\$@"; echo; } >> "$CALLS"
EOF
    chmod +x "$TMP/stubs/i3status" "$TMP/home/bin/kb" "$TMP/stubs/i3-msg"
}

click() {
    printf '{"name":"%s","instance":"%s","button":%s,"modifiers":[],"x":10,"y":5}\n' "$1" "$2" "$3"
}

# Runs i3status-kb with the given click lines on stdin; prints the calls
# made other than `kb show`.
run_clicks() {
    : > "$CALLS"
    {
        echo '['
        local line
        for line in "$@"; do
            echo "$line,"
            sleep 0.1
        done
        sleep "$SETTLE_S"
    } | HOME="$TMP/home" PATH="$TMP/stubs:$PATH" timeout 5 "$SCRIPT" > /dev/null 2>&1 || true
    grep -v '^kb show' "$CALLS" | tr '\n' ';' | sed 's/;$//'
}

main() {
    write_stubs
    local nmrs="i3-msg|-q|exec --no-startup-id nmrs-gui"

    expect "left click on wireless opens nmrs-gui" "$nmrs" "$(run_clicks "$(click wireless _first_ 1)")"
    expect "left click on ethernet opens nmrs-gui" "$nmrs" "$(run_clicks "$(click ethernet _first_ 1)")"
    expect "right click on wireless does nothing" "" "$(run_clicks "$(click wireless _first_ 3)")"
    expect "click on another block does nothing" "" "$(run_clicks "$(click battery _first_ 1)")"
    expect "left click on kb still cycles the layout" "kb next" "$(run_clicks "$(click kb "" 1)")"
    expect "right click on kb still goes back" "kb prev" "$(run_clicks "$(click kb "" 3)")"

    exit "$FAILED"
}

main "$@"
