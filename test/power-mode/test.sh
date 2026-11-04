#!/usr/bin/env bash
#
# Tests the power modes of bin/pwr and power-mode/power-mode-auto against a
# stub busctl that keeps the active profile in a file, and a fake sysfs.
#
# Usage: test/power-mode/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PWR="$HERE/../../bin/pwr"
readonly AUTO="$HERE/../../power-mode/power-mode-auto"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly CALLS="$TMP/calls" STATE="$TMP/profile" STUBS="$TMP/stubs" SYSFS="$TMP/sys"
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
    # busctl [--timeout=N] get-property|set-property BUS PATH IFACE PROP [s VALUE]
    cat > "$STUBS/busctl" <<EOF
#!/usr/bin/env bash
echo "busctl \$*" >> "$CALLS"
[[ -f "$TMP/down" ]] && { echo "Unit tuned-ppd.service not found." >&2; exit 1; }
args=()
for a in "\$@"; do [[ "\$a" == --* ]] || args+=("\$a"); done
case "\${args[0]}" in
    get-property) printf 's "%s"\n' "\$(cat "$STATE")" ;;
    set-property) echo "\${args[6]}" > "$STATE" ;;
esac
EOF
    printf '#!/bin/sh\necho "pkill $*" >> "%s"\n' "$CALLS" > "$STUBS/pkill"
    chmod +x "$STUBS/busctl" "$STUBS/pkill"
}

pwr() { PATH="$STUBS:$PATH" "$PWR" "$@" || fail "pwr $* exited $?"; }
auto() { POWER_MODE_SYSFS="$SYSFS" PATH="$STUBS:$PATH" "$AUTO" || fail "power-mode-auto exited $?"; }

# add_supply NAME TYPE ONLINE
add_supply() {
    local dir="$SYSFS/class/power_supply/$1"
    mkdir -p "$dir"
    echo "$2" > "$dir/type"
    echo "$3" > "$dir/online"
}

test_pwr() {
    echo balanced > "$STATE"
    : > "$CALLS"
    pwr performance
    expect "pwr performance sets the performance profile" "performance" "$(cat "$STATE")"
    expect "pwr mode prints performance" "performance" "$(pwr mode)"
    if grep -q "pkill -USR1 -x i3status" "$CALLS"; then
        ok "pwr redraws the bar after a switch"
    else
        fail "pwr did not signal i3status: $(cat "$CALLS")"
    fi

    pwr battery
    expect "pwr battery sets power-saver" "power-saver" "$(cat "$STATE")"
    expect "pwr mode prints battery for power-saver" "battery" "$(pwr mode)"

    pwr balanced
    expect "pwr balanced sets balanced" "balanced" "$(cat "$STATE")"
    expect "pwr mode prints balanced" "balanced" "$(pwr mode)"

    : > "$CALLS"
    pwr mode > /dev/null
    if grep -q "^busctl --timeout=" "$CALLS"; then
        ok "pwr mode cannot hang the bar"
    else
        fail "pwr mode calls busctl without a timeout: $(cat "$CALLS")"
    fi

    touch "$TMP/down"
    local out status=0
    out="$(PATH="$STUBS:$PATH" "$PWR" mode 2>/dev/null)" || status=$?
    rm -f "$TMP/down"
    expect "pwr mode without a daemon prints nothing" "" "$out"
    if [[ $status -ne 0 ]]; then
        ok "pwr mode without a daemon fails"
    else
        fail "pwr mode without a daemon exited 0"
    fi

    expect "pwr rejects extra arguments" \
        "usage: pwr lock [--nofork] | sleep | hibernate | performance | balanced | battery | mode" \
        "$(PATH="$STUBS:$PATH" "$PWR" battery now 2>&1 || true)"
}

test_auto() {
    add_supply BAT0 Battery 1
    add_supply AC Mains 1
    echo balanced > "$STATE"
    auto
    expect "on AC: performance" "performance" "$(cat "$STATE")"

    echo 0 > "$SYSFS/class/power_supply/AC/online"
    auto
    expect "on battery: power-saver" "power-saver" "$(cat "$STATE")"

    # A USB-C port that powers a phone is not the laptop's power source.
    add_supply ucsi-source-psy-USBC000:001 USB 1
    auto
    expect "a USB supply does not count as AC" "power-saver" "$(cat "$STATE")"

    rm -rf "$SYSFS"
    add_supply BAT0 Battery 1
    echo balanced > "$STATE"
    : > "$CALLS"
    auto
    expect "without an AC adapter nothing changes" "balanced" "$(cat "$STATE")"
    expect "without an AC adapter busctl is not called" "" "$(cat "$CALLS")"
}

main() {
    write_stubs
    test_pwr
    test_auto
    exit "$FAILED"
}

main "$@"
