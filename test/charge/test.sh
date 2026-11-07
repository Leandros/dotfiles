#!/usr/bin/env bash
#
# Runs bin/charge with a busctl stub that writes the thresholds to a fake
# sysfs battery, as UPower does, and checks the limit it sets and shows.
#
# Usage: test/charge/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/charge"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" SYSFS="$TMP/sys" CALLS="$TMP/calls"
readonly BAT="$SYSFS/class/power_supply/BAT0"
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

# EnableChargeThreshold true writes 75/80, false 0/100 (UPower 1.90+).
write_stubs() {
    mkdir -p "$STUBS"
    cat > "$STUBS/busctl" <<EOF
#!/bin/sh
echo "busctl \$*" >> "$CALLS"
for last; do :; done
case "\$last" in
    true)  echo 75 > "$BAT/charge_control_start_threshold"; echo 80 > "$BAT/charge_control_end_threshold" ;;
    false) echo 0 > "$BAT/charge_control_start_threshold"; echo 100 > "$BAT/charge_control_end_threshold" ;;
esac
EOF
    chmod +x "$STUBS/busctl"
}

battery() {
    rm -rf "$SYSFS"
    mkdir -p "$BAT"
    echo Battery > "$BAT/type"
    echo "$1" > "$BAT/charge_control_start_threshold"
    echo "$2" > "$BAT/charge_control_end_threshold"
}

run() {
    : > "$CALLS"
    CHARGE_SYSFS="$SYSFS" PATH="$STUBS:$PATH" "$SCRIPT" "$@"
}

end() { cat "$BAT/charge_control_end_threshold"; }

main() {
    write_stubs

    battery 76 80
    expect "show: firmware limit" "limit" "$(run show)"
    run full > /dev/null
    expect "full charges to 100%" "100" "$(end)"
    if grep -q 'EnableChargeThreshold b false$' "$CALLS"; then ok "full disables the UPower limit"; else fail "full: $(cat "$CALLS")"; fi
    expect "show after full" "full" "$(run show)"

    run limit > /dev/null
    expect "limit stops at 80%" "80" "$(end)"
    if grep -q '/org/freedesktop/UPower/devices/battery_BAT0' "$CALLS"; then ok "uses the BAT0 device"; else fail "device: $(cat "$CALLS")"; fi
    expect "show after limit" "limit" "$(run show)"

    run toggle > /dev/null
    expect "toggle from limit is full" "100" "$(end)"
    run toggle > /dev/null
    expect "toggle from full is limit" "80" "$(end)"

    if run bogus > /dev/null 2>&1; then fail "unknown command accepted"; else ok "unknown command rejected"; fi

    # Without a battery with thresholds (desktop) it says so.
    rm -rf "$SYSFS"
    mkdir -p "$SYSFS/class/power_supply/AC"
    if run show > /dev/null 2>&1; then fail "show without a battery succeeded"; else ok "no battery is an error"; fi

    exit "$FAILED"
}

main "$@"
