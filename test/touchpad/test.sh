#!/usr/bin/env bash
#
# Runs bin/touchpad with an xinput stub (a touchpad and a TrackPoint) and
# checks that it switches tap-to-click on touchpads only; under sway the
# same through a swaymsg stub. Also checks the macOS-style defaults in
# xorg-conf.
#
# Usage: test/touchpad/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/touchpad"
readonly CONF="$HERE/../../xorg-conf/40-touchpad.conf"
readonly WM_MSG="$HERE/../../bin/wm-msg"
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
    env -u SWAYSOCK DISPLAY=:99 XDG_RUNTIME_DIR="$TMP/run" HOME="$TMP/home" PATH="$STUBS:$PATH" "$SCRIPT" "$@"
}

# sway without Xwayland (no DISPLAY); no xinput.
run_sway() {
    : > "$CALLS"
    env -u DISPLAY SWAYSOCK=/run/sway.sock XDG_RUNTIME_DIR="$TMP/run" HOME="$TMP/home" PATH="$STUBS:$PATH" \
        "$SCRIPT" "$@"
}

# swaymsg: get_inputs lists a keyboard, a TrackPoint and (without
# TMP/no-touchpad) a touchpad with its tap state from TAP, as sway 1.12
# prints them; `input type:touchpad tap enabled|disabled` sets TAP.
write_sway_stub() {
    cat > "$STUBS/swaymsg" <<EOF
#!/bin/sh
echo "swaymsg \$*" >> "$CALLS"
case "\$*" in
    "-t get_inputs")
        touchpad=""
        if [ ! -e "$TMP/no-touchpad" ]; then
            [ "\$(cat "$TAP")" = 1 ] && tap=enabled || tap=disabled
            touchpad=",
  {
    \"identifier\": \"1267:12699:ELAN0672:00_04F3:3149_Touchpad\",
    \"name\": \"ELAN0672:00 04F3:3149 Touchpad\",
    \"type\": \"touchpad\",
    \"libinput\": {
      \"send_events\": \"enabled\",
      \"tap\": \"\$tap\",
      \"tap_button_map\": \"lrm\",
      \"click_method\": \"clickfinger\"
    }
  }"
        fi
        cat <<JSON
[
  {
    "identifier": "1:1:AT_Translated_Set_2_keyboard",
    "type": "keyboard",
    "libinput": { "send_events": "enabled" }
  },
  {
    "identifier": "2:10:TPPS/2_Elan_TrackPoint",
    "type": "pointer",
    "libinput": { "send_events": "enabled", "accel_profile": "adaptive" }
  }\$touchpad
]
JSON
        ;;
    "-q input type:touchpad tap enabled") echo 1 > "$TAP" ;;
    "-q input type:touchpad tap disabled") echo 0 > "$TAP" ;;
    *) exit 2 ;;
esac
EOF
    chmod +x "$STUBS/swaymsg"
    mkdir -p "$TMP/home/bin"
    ln -sf "$(readlink -f "$WM_MSG")" "$TMP/home/bin/wm-msg"
}

test_sway() {
    write_sway_stub
    rm -rf "$TMP/run"
    echo 0 > "$TAP"
    expect "sway: show: tapping off is click" "click" "$(run_sway show)"
    run_sway tap > /dev/null
    expect "sway: tap enables tapping" "1" "$(cat "$TAP")"
    expect "sway: show after tap" "tap" "$(run_sway show)"
    run_sway click > /dev/null
    expect "sway: click disables tapping" "0" "$(cat "$TAP")"
    run_sway toggle > /dev/null
    expect "sway: toggle from click is tap" "1" "$(cat "$TAP")"
    expect "sway: no xinput" "" "$(grep '^xinput' "$CALLS" || true)"

    run_sway click > /dev/null
    echo 1 > "$TAP"
    run_sway restore > /dev/null
    expect "sway: restore re-applies click" "0" "$(cat "$TAP")"

    touch "$TMP/no-touchpad"
    if run_sway show > /dev/null 2>&1; then fail "sway: show without a touchpad"; else ok "sway: show needs a touchpad"; fi
    rm "$TMP/no-touchpad"
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

    # restore (input-restore, after X re-adds the touchpad): the last choice.
    run tap > /dev/null
    echo 0 > "$TAP"
    run restore > /dev/null
    expect "restore re-applies tap" "1" "$(cat "$TAP")"
    run click > /dev/null
    echo 1 > "$TAP"
    run restore > /dev/null
    expect "restore re-applies click" "0" "$(cat "$TAP")"
    rm -rf "$TMP/run"
    echo 1 > "$TAP"
    run restore > /dev/null
    expect "restore without a choice keeps the device as is" "1" "$(cat "$TAP")"

    if run bogus > /dev/null 2>&1; then fail "unknown command accepted"; else ok "unknown command rejected"; fi

    # macOS defaults for every touchpad.
    local option
    for option in '"ClickMethod" "clickfinger"' '"Tapping" "off"' '"TappingDrag" "off"' '"AccelProfile" "custom"'; do
        if grep -q "Option $option" "$CONF"; then ok "xorg-conf $option"; else fail "xorg-conf misses $option"; fi
    done

    test_sway
    exit "$FAILED"
}

main "$@"
