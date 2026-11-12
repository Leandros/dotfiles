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
    # X tests first: not the caller's sway session.
    unset SWAYSOCK WAYLAND_DISPLAY
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
    test_sway
    exit "$FAILED"
}

# Starts NAME with WAYLAND_DISPLAY=$1 and DISPLAY=$2 (sway's Xwayland) and
# prints its pid.
start_wl() {
    WAYLAND_DISPLAY="$1" DISPLAY="$2" "$TMP/$NAME" 300 >/dev/null 2>&1 &
    echo $!
}

# sway (SWAYSOCK set) sets DISPLAY for Xwayland, so the key is
# WAYLAND_DISPLAY. A sway session and an X session can share a DISPLAY
# number over time; WAYLAND_DISPLAY tells them apart.
test_sway() {
    local a b x rc=0
    a="$(start_wl wayland-1 :0)"; b="$(start_wl wayland-2 :1)"; x="$(start :1)"
    PIDS+=("$a" "$b" "$x")
    sleep 0.3

    SWAYSOCK=/run/sway.sock WAYLAND_DISPLAY=wayland-1 DISPLAY=:1 "$SCRIPT" -x "$NAME" || rc=$?
    sleep 0.3
    if ! alive "$a"; then ok "sway: this session's process ends"; else fail "sway: wayland-1 still running"; fi
    if alive "$b"; then ok "sway: another sway session's process stays"; else fail "sway: wayland-2 was killed"; fi
    if alive "$x"; then ok "sway: an X process with the same DISPLAY stays"; else fail "sway: X :1 was killed"; fi
    if [[ "$rc" -eq 0 ]]; then ok "sway: exit 0 when it killed one"; else fail "sway: exit $rc after a kill"; fi

    if SWAYSOCK=/run/sway.sock env -u WAYLAND_DISPLAY DISPLAY=:1 "$SCRIPT" -x "$NAME" 2>/dev/null; then
        fail "sway: ran without WAYLAND_DISPLAY"
    else
        ok "sway: needs WAYLAND_DISPLAY"
    fi
    if alive "$x"; then ok "sway: no fallback to DISPLAY"; else fail "sway: X :1 killed without WAYLAND_DISPLAY"; fi
    # Without SWAYSOCK, as before: DISPLAY.
    env -u SWAYSOCK WAYLAND_DISPLAY=wayland-2 DISPLAY=:1 "$SCRIPT" -x "$NAME" || true
    sleep 0.3
    if ! alive "$x" && ! alive "$b"; then ok "X: DISPLAY, WAYLAND_DISPLAY ignored"; else fail "X: DISPLAY :1 not matched"; fi
}

main "$@"
