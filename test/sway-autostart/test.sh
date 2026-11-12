#!/usr/bin/env bash
#
# Runs bin/sway-autostart (the .xprofile of the sway session) with only
# stubs on PATH and checks what it starts, in which order and with which
# arguments: the session environment for systemd and D-Bus before the
# session target, the idle timeouts from ~/.config/idle.conf, kanshi only
# with a config, xwayland-satellite where no X server listens on DISPLAY,
# the bar before the tray apps, and nothing of the X session.
#
# Usage: test/sway-autostart/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/sway-autostart"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" FAKE_HOME="$TMP/home"
# X11_TMPDIR of the script: the X sockets are in .X11-unix below it.
readonly X11_TMP="$TMP/x11"
readonly X11_SOCKET="$X11_TMP/.X11-unix/X9"
readonly SESSION_VARS="WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY"
# Programs of the X session; none may start in sway.
readonly X_ONLY=(xset setxkbmap xmodmap xremap picom xss-lock xidlehook copyq autorandr xinput)
# Programs started in the background record their call later than the script
# returns; this long is enough for a stub that only appends a line.
readonly SETTLE_S=0.5
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

# A stub that records one argument per field, so arguments with spaces
# stay visible: "name|arg1|arg2".
write_stub() {
    local file="$1" name="$2"
    cat > "$file" <<EOF
#!/bin/sh
# One write per call: background stubs run at the same time.
line="$name"
for a in "\$@"; do line="\$line|\$a"; done
printf '%s\n' "\$line" >> "$CALLS"
EOF
    chmod +x "$file"
}

write_stubs() {
    mkdir -p "$STUBS" "$FAKE_HOME/bin" "$FAKE_HOME/.config"
    local cmd
    for cmd in systemctl dbus-update-activation-environment kanshi swayidle sway-audio-idle-inhibit \
        wl-paste cliphist blueman-applet lxpolkit dunst pkill "${X_ONLY[@]}"; do
        write_stub "$STUBS/$cmd" "$cmd"
    done
    for cmd in theme kb bar pkill-display pwr; do
        write_stub "$FAKE_HOME/bin/$cmd" "$cmd"
    done
    # swaymsg: the subscription returns at once, and sway is gone.
    write_stub "$STUBS/swaymsg" swaymsg
    # xrdb: also records what it reads from stdin.
    write_stub "$STUBS/xrdb" xrdb
    # shellcheck disable=SC2016 # $l belongs to the stub.
    printf 'while IFS= read -r l; do printf "%%s\\n" "$l"; done > "%s"\n' "$TMP/xrdb-in" >> "$STUBS/xrdb"
    printf 'case "$*" in *get_version*) exit 1 ;; esac\n' >> "$STUBS/swaymsg"
    # xwayland-satellite: its Xwayland creates the socket a moment later.
    # The line first: the script may see the socket at once.
    write_stub "$STUBS/xwayland-satellite" xwayland-satellite
    # shellcheck disable=SC2016 # $1 belongs to the stub.
    printf 'sleep 0.3\necho x11-socket >> "%s"\n: > "%s/.X11-unix/X${1#:}"\n' "$CALLS" "$X11_TMP" \
        >> "$STUBS/xwayland-satellite"
    ln -s "$(command -v sleep)" "$STUBS/sleep"
    # The IDLE_* settings bootstrap.sh writes.
    printf 'IDLE_LOCK_MINUTES=5\nIDLE_SUSPEND_MINUTES=12\n' > "$FAKE_HOME/.config/idle.conf"
}

# Runs the script as sway does: the session variables set, PATH with the
# stubs only. With "xwayland", sway's own Xwayland listens on DISPLAY (the
# sway config enables it); without, no X server does. Prints the exit
# status.
run() {
    local x_server="${1:-none}"
    : > "$CALLS"
    rm -rf "$X11_TMP"
    mkdir -p "$X11_TMP/.X11-unix"
    [[ "$x_server" != xwayland ]] || : > "$X11_SOCKET"
    local rc=0
    env -i HOME="$FAKE_HOME" PATH="$STUBS" XDG_RUNTIME_DIR="$TMP/run" X11_TMPDIR="$X11_TMP" \
        WAYLAND_DISPLAY=wayland-9 SWAYSOCK="$TMP/run/sway-ipc.sock" DISPLAY=:9 \
        XDG_CURRENT_DESKTOP=sway XDG_SESSION_TYPE=wayland \
        /bin/bash "$SCRIPT" >/dev/null 2>"$TMP/stderr" || rc=$?
    sleep "$SETTLE_S"
    echo "$rc"
}

# Line number of the first call matching PATTERN, or 0.
line_of() { grep -n -m 1 -E "$1" "$CALLS" | cut -d: -f1 || echo 0; }

before() {
    local name="$1" first second
    first="$(line_of "$2")"
    second="$(line_of "$3")"
    if [[ "$first" -gt 0 && "$second" -gt "$first" ]]; then
        ok "$name"
    else
        fail "$name: lines $first and $second: $(tr '\n' ';' < "$CALLS")"
    fi
}

called() { grep -qE "$1" "$CALLS"; }

main() {
    if [[ ! -f "$SCRIPT" ]]; then
        fail "bin/sway-autostart is missing"
        exit 1
    fi
    write_stubs

    expect "exits 0" "0" "$(run)"

    # User services (xdg-desktop-portal, its backends) need the Wayland
    # display; graphical-session.target, which the portal requires since
    # Fedora 45, binds the session target.
    local vars="${SESSION_VARS// /|}"
    expect "systemd gets the session environment" \
        "systemctl|--user|import-environment|$vars" "$(grep -m 1 '^systemctl|--user|import' "$CALLS")"
    expect "D-Bus activation gets the session environment" \
        "dbus-update-activation-environment|--systemd|$vars" "$(grep -m 1 '^dbus-update' "$CALLS")"
    expect "starts the session target" \
        "systemctl|--user|--no-block|start|sway-session.target" "$(grep -m 1 '|start|' "$CALLS")"
    before "environment before the session target" '^systemctl\|--user\|import' '\|start\|sway-session'
    before "D-Bus environment before the session target" '^dbus-update' '\|start\|sway-session'

    # When sway ends (the stub's subscription returns, get_version fails),
    # the user manager forgets the session: it outlives a logout while an
    # ssh login or lingering keeps it, and an i3 login after this one would
    # see SWAYSOCK and take the sway paths of kb, theme and bar.
    expect "sway gone: systemd forgets the session environment" \
        "systemctl|--user|unset-environment|$vars" "$(grep -m 1 '^systemctl|--user|unset-environment' "$CALLS")"
    expect "sway gone: D-Bus activation forgets it too (empty values)" \
        "dbus-update-activation-environment|${SESSION_VARS// /=|}=" \
        "$(grep '^dbus-update' "$CALLS" | sed -n 2p)"
    expect "sway gone: the session target stops" \
        "systemctl|--user|stop|sway-session.target" "$(grep -m 1 '^systemctl|--user|stop' "$CALLS")"

    # Colors (theme writes sway.d/theme.conf and sets them in the session),
    # then the layout the bar shows.
    expect "theme restore" "theme|restore" "$(grep -m 1 '^theme' "$CALLS")"
    expect "keyboard layout de" "kb|de" "$(grep -m 1 '^kb' "$CALLS")"
    before "theme after the session target" '\|start\|sway-session' '^theme\|restore'

    # Idle: lock after 5 min, suspend at 12 min. swayidle counts each
    # timeout from the last input, so the suspend timeout is not the
    # difference (as for the chained xidlehook timers).
    expect "idle timeouts from idle.conf" \
        "swayidle|-w|timeout|300|loginctl lock-session|timeout|720|systemctl suspend|lock|~/bin/pwr lock|before-sleep|~/bin/pwr lock" \
        "$(grep '^swayidle' "$CALLS")"

    # sway-audio-idle-inhibit holds a logind idle lock while audio plays.
    # It has no Wayland connection and stays after a logout: the old one
    # stops first. Its name is longer than the 15 characters pgrep -x sees.
    expect "audio idle inhibitor starts" "sway-audio-idle-inhibit" "$(grep '^sway-audio' "$CALLS")"
    before "the old audio idle inhibitor stops first" \
        '^pkill-display\|-f\|.*sway-audio-idle-inhibit' '^sway-audio-idle-inhibit'
    if called '^pkill-display\|-x\|sway-audio-idle-inhibit'; then
        fail "pkill-display -x with a name longer than 15 characters matches nothing"
    else
        ok "no pkill-display -x for the audio idle inhibitor"
    fi
    if grep -E '^pkill\|' "$CALLS" | grep -vqxF "pkill|-u|$(id -u)|-x|xremap"; then
        fail "plain pkill (all sessions): $(grep -E '^pkill\|' "$CALLS" | tr '\n' ';')"
    else
        ok "no plain pkill, except for xremap"
    fi

    # xremap of an i3 session outlives the logout (logind keeps the user's
    # processes) and swaps Alt and Ctrl below the keymap: with the XKB swap
    # of the sway config they would be swapped twice.
    expect "stops the user's xremap" "pkill|-u|$(id -u)|-x|xremap" "$(grep -m 1 '^pkill|' "$CALLS")"
    before "xremap stops before the layout is set" '^pkill\|.*xremap' '^kb\|de'

    # Clipboard history; cliphist skips data marked as a password.
    expect "clipboard history" "wl-paste|--watch|cliphist|store" "$(grep '^wl-paste' "$CALLS")"

    # The eww bar is the tray; the tray apps register with it.
    before "bar starts before blueman-applet" '^bar' '^blueman-applet'
    before "bar starts before lxpolkit" '^bar' '^lxpolkit'

    # dunst: notifications (screenshot, notify-send); a Wayland client, so
    # it ends with sway.
    expect "notification daemon starts" "dunst" "$(grep '^dunst' "$CALLS")"

    # X11 programs: no X server listens on DISPLAY (the sway config
    # disables sway's Xwayland), so xwayland-satellite starts there. It
    # sets Xft.dpi from the output scale: no xrdb.
    expect "xwayland-satellite on the session's display" "xwayland-satellite|:9" \
        "$(grep '^xwayland-satellite' "$CALLS")"
    before "satellite starts before the bar" '^xwayland-satellite' '^bar'
    before "lxpolkit (X11) waits for the X server" '^x11-socket' '^lxpolkit'
    if called '^xrdb'; then fail "xrdb with xwayland-satellite"; else ok "no xrdb with xwayland-satellite"; fi

    local cmd started=""
    for cmd in "${X_ONLY[@]}"; do
        called "^$cmd(\||$)" && started+=" $cmd"
    done
    expect "no programs of the X session" "" "$started"

    # sway's own Xwayland: DPI 96 (sway scales its windows). Without
    # resources Xlib reads ~/.Xdefaults, whose Xft.dpi (192) made X apps'
    # text 2x on top.
    run xwayland >/dev/null
    if called '^xwayland-satellite'; then fail "satellite next to sway's Xwayland"; else ok "no satellite with sway's Xwayland"; fi
    expect "Xwayland gets X resources" "xrdb|-nocpp|-merge" "$(grep '^xrdb' "$CALLS")"
    expect "Xwayland DPI 96" "Xft.dpi: 96" "$(cat "$TMP/xrdb-in" 2>/dev/null)"

    # kanshi only with a profile file; it exits at once without one.
    if called '^kanshi'; then fail "kanshi without a config"; else ok "no kanshi without a config"; fi
    mkdir -p "$FAKE_HOME/.config/kanshi"
    : > "$FAKE_HOME/.config/kanshi/config"
    run >/dev/null
    if called '^kanshi'; then ok "kanshi with a config"; else fail "no kanshi with a config"; fi

    # Without idle.conf: no timeouts, but still the locker before sleep and
    # on `loginctl lock-session` (as xss-lock in X).
    rm "$FAKE_HOME/.config/idle.conf"
    run >/dev/null
    expect "no idle.conf: only the locker" \
        "swayidle|-w|lock|~/bin/pwr lock|before-sleep|~/bin/pwr lock" "$(grep '^swayidle' "$CALLS")"

    # Every optional program missing: the rest still runs.
    for cmd in kanshi swayidle sway-audio-idle-inhibit wl-paste cliphist blueman-applet lxpolkit \
        dbus-update-activation-environment xwayland-satellite; do
        rm "$STUBS/$cmd"
    done
    expect "optional programs missing: exits 0" "0" "$(run)"
    if called '^systemctl\|--user\|--no-block\|start' && called '^bar'; then
        ok "optional programs missing: target and bar start"
    else
        fail "optional programs missing: $(tr '\n' ';' < "$CALLS") $(cat "$TMP/stderr")"
    fi
    if called '^pkill-display'; then
        fail "stops an audio idle inhibitor that is not installed"
    else
        ok "no audio idle inhibitor: nothing to stop"
    fi

    exit "$FAILED"
}

main "$@"
