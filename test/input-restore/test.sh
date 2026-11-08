#!/usr/bin/env bash
#
# Runs bin/input-restore with stubs for udevadm, kb, touchpad and xset: a
# burst of input events (`udevadm trigger` from an installer re-adds every
# keyboard and the touchpad with X defaults) re-applies the keyboard layout
# and tap-to-click once, after the events settle.
#
# Usage: test/input-restore/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/input-restore"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" EVENTS="$TMP/events"
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

# udevadm monitor prints the lines of EVENTS, 0.05 s apart, then waits.
# xset fails once "$TMP/x-gone" exists (the X session ended).
write_stubs() {
    mkdir -p "$STUBS" "$TMP/home/bin"
    cat > "$STUBS/udevadm" <<EOF
#!/bin/sh
echo "monitor will print the received events for:"
while IFS= read -r line; do sleep 0.05; echo "\$line"; done < "$EVENTS"
exec sleep 30
EOF
    printf '#!/bin/sh\n[ -e "%s/x-gone" ] && exit 1\nexit 0\n' "$TMP" > "$STUBS/xset"
    # shellcheck disable=SC2016 # $* and $1 belong to the stubs.
    printf '#!/bin/sh\necho "kb $*" >> "%s"\n[ "$1" = show ] && echo bone2\nexit 0\n' "$CALLS" > "$TMP/home/bin/kb"
    # shellcheck disable=SC2016
    printf '#!/bin/sh\necho "touchpad $*" >> "%s"\n' "$CALLS" > "$TMP/home/bin/touchpad"
    chmod +x "$STUBS"/* "$TMP/home/bin"/*
}

# Runs input-restore for RUN_S; prints the calls other than `kb show`.
run() {
    local run_s="$1"
    : > "$CALLS"
    HOME="$TMP/home" PATH="$STUBS:$PATH" INPUT_RESTORE_SETTLE_S=0.3 INPUT_RESTORE_CHECK_S=0.5 \
        timeout "$run_s" "$SCRIPT" > /dev/null 2>&1 || true
    { grep -v '^kb show' "$CALLS" || true; } | tr '\n' ';' | sed 's/;$//'
}

main() {
    write_stubs

    {
        echo "UDEV  [100.000001] change   /devices/platform/i8042/serio0/input/input3 (input)"
        echo "UDEV  [100.000002] change   /devices/platform/i8042/serio0/input/input3/event3 (input)"
        echo "UDEV  [100.000003] change   /devices/pci0000:00/i2c/SYNA8022:00/input/input6 (input)"
        echo "UDEV  [100.000004] add      /devices/virtual/input/input30 (input)"
        echo "UDEV  [100.000005] remove   /devices/virtual/input/input29 (input)"
    } > "$EVENTS"
    expect "a burst re-applies the layout and tap-to-click once" "kb bone2;touchpad restore" "$(run 2)"

    echo "UDEV  [100.000006] remove   /devices/virtual/input/input29 (input)" > "$EVENTS"
    expect "a removal alone changes nothing" "" "$(run 1.5)"

    : > "$EVENTS"
    expect "no events: nothing" "" "$(run 1)"

    # It ends with the X session.
    touch "$TMP/x-gone"
    local start elapsed
    start="$(date +%s)"
    run 10 > /dev/null
    elapsed=$(( $(date +%s) - start ))
    if [[ $elapsed -le 3 ]]; then ok "exits when X is gone (${elapsed} s)"; else fail "still ran after X ended (${elapsed} s)"; fi

    exit "$FAILED"
}

main "$@"
