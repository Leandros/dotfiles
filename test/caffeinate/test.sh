#!/usr/bin/env bash
#
# Runs bin/caffeinate with stubs for xidlehook-client and xset, stops it
# like Ctrl-C would, and checks that idle suspend (and with `display` the
# lock and blanking) is held off only while it runs. xidlehook (.xprofile)
# has two timers: 0 locks, 1 suspends. Under sway the same with a logind
# inhibitor (systemd-inhibit stub).
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
    # X tests first: not the caller's sway session.
    unset SWAYSOCK
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

    test_sway
    exit "$FAILED"
}

# systemd-inhibit: records its arguments and the pid that holds the lock,
# then runs the command, as the real one does (TMP/inhibit-fails: no
# logind).
write_inhibit_stub() {
    cat > "$STUBS/systemd-inhibit" <<EOF
#!/bin/sh
echo "systemd-inhibit \$*" >> "$CALLS"
[ -e "$TMP/inhibit-fails" ] && exit 1
echo \$\$ > "$TMP/holder"
while [ "\${1#--}" != "\$1" ]; do shift; done
exec "\$@"
EOF
    chmod +x "$STUBS/systemd-inhibit"
}

# As run, in sway without Xwayland.
run_sway() {
    local signal="$1" rc=0
    shift
    : > "$CALLS"
    rm -f "$TMP/holder"
    env -u DISPLAY SWAYSOCK=/run/sway.sock XDG_RUNTIME_DIR="$TMP" CAFFEINATE_INTERVAL_S="$INTERVAL_S" \
        PATH="$STUBS:$PATH" timeout --preserve-status -s "$signal" "$RUN_S" "$SCRIPT" "$@" > /dev/null 2>&1 || rc=$?
    echo "$rc"
}

holder_gone() {
    sleep 0.2
    [[ -s "$TMP/holder" ]] && ! kill -0 "$(cat "$TMP/holder")" 2>/dev/null
}

# sway: swayidle skips its timeouts while logind has an idle inhibitor, and
# logind refuses its suspend while a sleep inhibitor blocks it. The lock
# lives as long as systemd-inhibit.
test_sway() {
    write_inhibit_stub
    local why="--who=caffeinate --why="
    local rc
    rc="$(run_sway INT)"
    expect "sway: Ctrl-C exit code" "130" "$rc"
    expect "sway: a sleep inhibitor only (the screen still locks)" \
        "systemd-inhibit --what=sleep ${why}no idle suspend sleep infinity" "$(cat "$CALLS")"
    if holder_gone; then ok "sway: inhibitor released on exit"; else fail "sway: inhibitor still held"; fi

    run_sway INT display > /dev/null
    expect "sway: display inhibits idle (lock, blanking) and sleep" \
        "systemd-inhibit --what=idle:sleep ${why}no idle suspend, lock or blanking sleep infinity" "$(cat "$CALLS")"
    if holder_gone; then ok "sway: display: inhibitor released on exit"; else fail "sway: display: inhibitor still held"; fi

    rc="$(run_sway HUP)"
    expect "sway: hangup exit code" "129" "$rc"
    if holder_gone; then ok "sway: hangup releases the inhibitor"; else fail "sway: hangup: inhibitor still held"; fi
    expect "sway: no xidlehook or xset" "" "$(grep -v '^systemd-inhibit' "$CALLS" || true)"

    touch "$TMP/inhibit-fails"
    rc="$(run_sway INT)"
    rm "$TMP/inhibit-fails"
    if [[ "$rc" -ne 0 && "$rc" -ne 130 ]]; then ok "sway: fails without logind ($rc)"; else fail "sway: exit $rc without logind"; fi
}

main "$@"
