#!/usr/bin/env bash
#
# Inside the dotfiles-eww-sway container (test/eww-sway/test.sh copies it
# in, with bin/bar, bin/pkill-display, bin/wm-msg and .config/eww for user
# t): headless sway with two outputs, then ~/bin/bar, and checks of the
# bars through sway's workspace rects (layer surfaces are not in its tree;
# a bar's exclusive zone moves the workspace of its output down).
#
# Usage: in-container.sh   (as root)
#
set -euo pipefail

readonly USER_NAME="t" USER_HOME="/home/t" RUNTIME="/tmp/xdg-t"
readonly SWAY_CONFIG="/tmp/sway.conf" SWAY_LOG="/tmp/sway.log"
# The bar height on sway: logical pixels, for 96 dpi (bin/bar).
readonly BAR_HEIGHT=23
readonly WAIT_S=30 SETTLE_S=2
readonly EWW_CONFIG="$RUNTIME/eww/wayland-1"
FAILED=0
SOCK=""

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

as_user() {
    runuser -u "$USER_NAME" -- env HOME="$USER_HOME" XDG_RUNTIME_DIR="$RUNTIME" WAYLAND_DISPLAY=wayland-1 \
        SWAYSOCK="$SOCK" DBUS_SESSION_BUS_ADDRESS="unix:path=$RUNTIME/bus" "$@"
}

start_sway() {
    echo "# dotfiles test/eww-sway" > "$SWAY_CONFIG"
    chmod 644 "$SWAY_CONFIG"
    runuser -u "$USER_NAME" -- env HOME="$USER_HOME" XDG_RUNTIME_DIR="$RUNTIME" WLR_BACKENDS=headless \
        WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 setsid sway -c "$SWAY_CONFIG" \
        > "$SWAY_LOG" 2>&1 < /dev/null &
    local i
    for ((i = 0; i < WAIT_S * 10; i++)); do
        SOCK="$(ls "$RUNTIME"/sway-ipc.*.sock 2>/dev/null || true)"
        [[ -n "$SOCK" ]] && as_user swaymsg -t get_version > /dev/null 2>&1 && return 0
        sleep 0.1
    done
    cat "$SWAY_LOG"
    echo "sway did not start" >&2
    exit 1
}

# "<output>=<workspace top - output top>" for every active output, sorted.
zones() {
    local outputs
    outputs="$(as_user swaymsg -t get_outputs)"
    as_user swaymsg -t get_workspaces | jq -r --argjson outputs "$outputs" '
        . as $ws
        | [$outputs[] | select(.active) | .name as $n | .rect.y as $top
            | "\($n)=\([$ws[] | select(.visible and .output == $n) | .rect.y - $top] | first)"]
        | sort | join(" ")'
}

# Waits until zones prints WANT, and still does SETTLE_S later: while bar
# opens the bars again (its check, a late output event) zones are 0 for a
# moment, and a late second bar shows only after a while. Prints the last
# zones.
wait_zones() {
    local want="$1" got="" i
    for ((i = 0; i < WAIT_S * 2; i++)); do
        got="$(zones)"
        if [[ "$got" == "$want" ]]; then
            sleep "$SETTLE_S"
            got="$(zones)"
            [[ "$got" == "$want" ]] && break
        fi
        sleep 0.5
    done
    echo "$got"
}

eww_() { as_user eww -c "$EWW_CONFIG" "$@"; }

windows() { eww_ active-windows 2>/dev/null | cut -d: -f1 | sort | paste -sd ' '; }

# The window opened with tray=true: its scope in `eww debug` has the
# window id as its name, then the arguments. Other scopes, and the window
# list at the end (no ids), do not count.
tray_window() {
    eww_ debug 2>/dev/null | awk '
        /^[[:space:]]*name: / {
            win = ""
            if (match($0, /"bar-[^"]+"/)) { win = substr($0, RSTART + 1, RLENGTH - 2) }
        }
        win != "" && /VarName\(tray\): "true"/ { print win }' | sort -u
}

daemons() { pgrep -u "$USER_NAME" -c -f "^eww -c $EWW_CONFIG daemon" || true; }

main() {
    chown -R "$USER_NAME:" "$USER_HOME"
    start_sway
    as_user swaymsg -q create_output
    as_user dbus-daemon --session --fork --address="unix:path=$RUNTIME/bus" > /dev/null

    local both="HEADLESS-1=$BAR_HEIGHT HEADLESS-2=$BAR_HEIGHT"
    # sway without Xwayland: no DISPLAY.
    as_user env -u DISPLAY "$USER_HOME/bin/bar" || fail "bar exited $?"
    expect "one bar per output (exclusive zone of one bar height)" "$both" "$(wait_zones "$both")"
    expect "bars by connector name" "bar-HEADLESS-1 bar-HEADLESS-2" "$(windows)"
    expect "one eww daemon" "1" "$(daemons)"
    expect "the tray on the first output" "bar-HEADLESS-1" "$(tray_window)"

    # :monitor by connector name: closing one bar frees its own output.
    eww_ close bar-HEADLESS-2 > /dev/null
    expect "bar-HEADLESS-2 is on HEADLESS-2" "HEADLESS-1=$BAR_HEIGHT HEADLESS-2=0" \
        "$(wait_zones "HEADLESS-1=$BAR_HEIGHT HEADLESS-2=0")"

    as_user swaymsg -q output HEADLESS-2 disable
    expect "output disabled: a bar on the other one" "HEADLESS-1=$BAR_HEIGHT" "$(wait_zones "HEADLESS-1=$BAR_HEIGHT")"
    expect "output disabled: its bar closed" "bar-HEADLESS-1" "$(windows)"
    as_user swaymsg -q output HEADLESS-2 enable
    expect "output enabled again: a bar on each" "$both" "$(wait_zones "$both")"
    expect "output enabled again: both bars" "bar-HEADLESS-1 bar-HEADLESS-2" "$(windows)"

    # bar again (as after a config edit): a new daemon, no stacked bars.
    as_user env -u DISPLAY "$USER_HOME/bin/bar" || fail "bar (again) exited $?"
    expect "bar again: one bar per output" "$both" "$(wait_zones "$both")"
    expect "bar again: one eww daemon" "1" "$(daemons)"
    expect "bar again: one watcher" "1" "$(pgrep -u "$USER_NAME" -c -f '/bin/bar watch$' || true)"

    if [[ "$FAILED" -ne 0 ]]; then
        echo "--- sway log"
        tail -n 20 "$SWAY_LOG"
        echo "--- eww log"
        as_user timeout 2 eww -c "$EWW_CONFIG" logs 2>&1 | tail -n 40 || true
    fi
    exit "$FAILED"
}

main "$@"
