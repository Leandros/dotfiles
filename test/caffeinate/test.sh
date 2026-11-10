#!/usr/bin/env bash
#
# Runs bin/caffeinate with stubs for xidlehook-client and xset, stops it
# like Ctrl-C would, and checks that idle suspend (and with `display` the
# lock and blanking) is held off only while it runs. xidlehook (.xprofile)
# has two timers: 0 locks, 1 suspends.
#
# Usage: test/caffeinate/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/caffeinate"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls"
readonly SOCK="$TMP/xidlehook.sock"
readonly CLIENT="xidlehook-client --socket $SOCK control"
# Short interval so the test sees several screensaver resets.
readonly INTERVAL_S=0.2 RUN_S=1
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
    mkdir -p "$STUBS"
    local tool
    for tool in xidlehook-client xset; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$tool" "$CALLS" > "$STUBS/$tool"
        chmod +x "$STUBS/$tool"
    done
}

# Runs caffeinate for RUN_S, then sends SIGNAL; prints its exit code.
# timeout, not `&`: a background job of a script ignores SIGINT.
run() {
    local signal="$1" rc=0
    shift
    : > "$CALLS"
    DISPLAY=:99 XDG_RUNTIME_DIR="$TMP" CAFFEINATE_INTERVAL_S="$INTERVAL_S" PATH="$STUBS:$PATH" \
        timeout --preserve-status -s "$signal" "$RUN_S" "$SCRIPT" "$@" > /dev/null || rc=$?
    echo "$rc"
}

count() { grep -cx "$1" "$CALLS" || true; }

main() {
    write_stubs

    local rc
    rc="$(run INT)"
    expect "Ctrl-C exit code" "130" "$rc"
    # Only the suspend timer: the screen still locks.
    expect "disables idle suspend once" "1" "$(count "$CLIENT --action disable --timer 1")"
    expect "enables idle suspend on exit" "1" "$(count "$CLIENT --action enable --timer 1")"
    expect "enable comes last" "$CLIENT --action enable --timer 1" "$(tail -n 1 "$CALLS")"
    expect "leaves the lock alone" "0" "$(grep -c -e 'disable$' -e 'timer 0' "$CALLS" || true)"
    expect "leaves the screensaver alone" "0" "$(count 'xset s reset')"

    run INT display > /dev/null
    local resets
    resets="$(count 'xset s reset')"
    if [[ "$resets" -ge 3 ]]; then ok "display resets the screensaver ($resets times)"; else fail "display: $resets resets"; fi
    # All timers: no lock and no suspend.
    expect "display disables lock and suspend" "1" "$(count "$CLIENT --action disable")"
    expect "display enables them on exit" "$CLIENT --action enable" "$(tail -n 1 "$CALLS")"

    rc="$(run HUP)"
    expect "hangup (terminal closed) enables idle suspend" "$CLIENT --action enable --timer 1" "$(tail -n 1 "$CALLS")"
    expect "hangup exit code" "129" "$rc"

    if DISPLAY=:99 PATH="$STUBS:$PATH" "$SCRIPT" bogus > /dev/null 2>&1; then
        fail "unknown argument accepted"
    else
        ok "unknown argument rejected"
    fi
    if env -u DISPLAY PATH="$STUBS:$PATH" "$SCRIPT" > /dev/null 2>&1; then
        fail "ran without X"
    else
        ok "needs X"
    fi

    exit "$FAILED"
}

main "$@"
