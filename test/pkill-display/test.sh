#!/usr/bin/env bash
#
# Tests bin/pkill-display with real processes: copies of sleep under their
# own name run on two X displays (DISPLAY in their environment); only the
# ones of the caller's display may end. .xprofile and bar use it, so a
# second session (xrdp) does not stop the first one's programs.
#
# Usage: test/pkill-display/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/pkill-display"
TMP="$(mktemp -d)"
readonly TMP
readonly NAME="pkdtest$$"
PIDS=()
trap 'kill "${PIDS[@]}" 2>/dev/null || true; rm -rf "$TMP"' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

alive() { kill -0 "$1" 2>/dev/null; }

# Starts NAME (a copy of sleep) with DISPLAY=$1 and prints its pid.
start() {
    # No inherited stdout: $(start ...) would wait for it.
    DISPLAY="$1" "$TMP/$NAME" 300 >/dev/null 2>&1 &
    echo $!
}

main() {
    cp "$(command -v sleep)" "$TMP/$NAME"
    local a b c rc=0
    a="$(start :91)"; b="$(start :92)"; c="$(start :91)"
    PIDS=("$a" "$b" "$c")
    sleep 0.3

    DISPLAY=:91 "$SCRIPT" -x "$NAME" || rc=$?
    sleep 0.3
    if ! alive "$a" && ! alive "$c"; then ok "-x: this display's processes end"; else fail "-x: :91 still running"; fi
    if alive "$b"; then ok "-x: the other display's process stays"; else fail "-x: :92 was killed"; fi
    if [[ "$rc" -eq 0 ]]; then ok "exit 0 when it killed one"; else fail "exit $rc after a kill"; fi

    rc=0
    DISPLAY=:93 "$SCRIPT" -f "$NAME 300\$" || rc=$?
    if alive "$b"; then ok "-f: nothing on another display"; else fail "-f: :92 killed from :93"; fi
    if [[ "$rc" -eq 1 ]]; then ok "exit 1 when none matched, as pkill"; else fail "exit $rc without a match"; fi

    DISPLAY=:92 "$SCRIPT" -f "$NAME 300\$" || true
    sleep 0.3
    if ! alive "$b"; then ok "-f: a command line pattern"; else fail "-f: :92 still running"; fi

    if env -u DISPLAY "$SCRIPT" -x "$NAME" 2>/dev/null; then fail "ran without DISPLAY"; else ok "needs DISPLAY"; fi
    exit "$FAILED"
}

main "$@"
