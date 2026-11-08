#!/usr/bin/env bash
#
# Runs bin/touchpad with an xinput stub (a touchpad and a TrackPoint) and
# checks that it switches tap-to-click on touchpads only. Also checks the
# macOS-style defaults in xorg-conf.
#
# Usage: test/touchpad/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/touchpad"
readonly CONF="$HERE/../../xorg-conf/40-touchpad.conf"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" TAP="$TMP/tap" CALLS="$TMP/calls"
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

# Device 6 is a touchpad with its tapping state in TAP; device 13 (the
# TrackPoint) has no tapping property.
write_stubs() {
    mkdir -p "$STUBS"
    cat > "$STUBS/xinput" <<EOF
#!/bin/sh
echo "xinput \$*" >> "$CALLS"
case "\$1 \$2" in
    "list --id-only") printf '2\n6\n13\n' ;;
    "list-props 6")   printf 'Device:\n\tlibinput Tapping Enabled (315):\t%s\n\tlibinput Tapping Enabled Default (316):\t0\n' "\$(cat "$TAP")" ;;
    "list-props "*)   printf 'Device:\n\tlibinput Accel Speed (300):\t0.0\n' ;;
    "set-prop 6")     echo "\$4" > "$TAP" ;;
    "set-prop "*)     exit 1 ;;
esac
EOF
    chmod +x "$STUBS/xinput"
}

run() {
    : > "$CALLS"
    DISPLAY=:99 PATH="$STUBS:$PATH" "$SCRIPT" "$@"
}

main() {
    write_stubs

    echo 0 > "$TAP"
    expect "show: tapping off is click" "click" "$(run show)"
    run tap > /dev/null
    expect "tap enables tapping" "1" "$(cat "$TAP")"
    expect "show after tap" "tap" "$(run show)"
    run tap > /dev/null
    if grep -q 'set-prop 13' "$CALLS"; then fail "tap touched the TrackPoint"; else ok "tap leaves the TrackPoint alone"; fi

    run click > /dev/null
    expect "click disables tapping" "0" "$(cat "$TAP")"
    run toggle > /dev/null
    expect "toggle from click is tap" "1" "$(cat "$TAP")"
    run toggle > /dev/null
    expect "toggle from tap is click" "0" "$(cat "$TAP")"

    if run bogus > /dev/null 2>&1; then fail "unknown command accepted"; else ok "unknown command rejected"; fi

    # macOS defaults for every touchpad.
    local option
    for option in '"ClickMethod" "clickfinger"' '"Tapping" "off"' '"TappingDrag" "off"' '"AccelProfile" "custom"'; do
        if grep -q "Option $option" "$CONF"; then ok "xorg-conf $option"; else fail "xorg-conf misses $option"; fi
    done

    exit "$FAILED"
}

main "$@"
