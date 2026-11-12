#!/usr/bin/env bash
#
# Runs .xprofile with only stubs on PATH and checks the keyboard layout at
# login: de, set after xremap's virtual keyboard exists. A keyboard added
# later gets the X server default instead of the layout kb set, so the bar
# (kb show) would name a layout nobody types with.
#
# Usage: test/xprofile/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly XPROFILE="$HERE/../../.xprofile"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" DEVICE="$TMP/xremap-device"
# xremap creates its keyboard this long after it starts.
readonly XREMAP_DELAY_S=0.5
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

# Every command .xprofile runs records its arguments. PATH holds only the
# stubs, so nothing reaches the real session.
write_stubs() {
    mkdir -p "$STUBS" "$TMP/home/bin" "$TMP/home/.config"
    local cmd
    for cmd in systemctl autorandr xset setxkbmap xmodmap pkill xss-lock blueman-applet picom lxpolkit dunst; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$STUBS/$cmd"
    done
    # xrdb -query prints the Xft.dpi of XFT_DPI (unset: none), like the
    # rendered ~/.Xresources.
    cat > "$STUBS/xrdb" <<EOF
#!/bin/sh
echo "xrdb \$*" >> "$CALLS"
# The DPI autorandr's hook set (TMP/hook-dpi) wins.
[ "\$1" = -query ] && [ -s "$TMP/hook-dpi" ] && { read -r d < "$TMP/hook-dpi"; printf 'Xft.dpi:\t%s\n' "\$d"; exit 0; }
[ "\$1" = -query ] && [ -n "\${XFT_DPI:-}" ] && printf 'Xft.dpi:\t%s\n' "\$XFT_DPI"
exit 0
EOF
    # theme records the Qt scaling it inherits: programs started after it see
    # the same environment.
    cat > "$TMP/home/bin/theme" <<EOF
#!/bin/sh
echo "theme \$*" >> "$CALLS"
echo "qt \${QT_SCALE_FACTOR:-unset} \${QT_FONT_DPI:-unset}" >> "$CALLS"
echo "lang \${LANG:-unset}" >> "$CALLS"
echo "loaded \${XPROFILE_LOADED:-unset}" >> "$CALLS"
EOF
    for cmd in kb input-restore bar pkill-display xrdp-keys; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$TMP/home/bin/$cmd"
    done
    printf '#!/bin/sh\nexec /usr/bin/sleep "$@"\n' > "$STUBS/sleep"
    printf '#!/bin/sh\nexec /usr/bin/grep "$@"\n' > "$STUBS/grep"
    printf '#!/bin/sh\nexec /usr/bin/awk "$@"\n' > "$STUBS/awk"
    # copyq records the CopyQ session it starts (COPYQ_SESSION_NAME).
    cat > "$STUBS/copyq" <<EOF
#!/bin/sh
echo "copyq \$* session=\${COPYQ_SESSION_NAME:-}" >> "$CALLS"
EOF
    # xidlehook records one argument per field, so empty ones stay visible.
    cat > "$STUBS/xidlehook" <<EOF
#!/bin/sh
{ printf xidlehook; printf '|%s' "\$@"; echo; } >> "$CALLS"
EOF
    # The IDLE_* settings bootstrap.sh writes.
    printf 'IDLE_LOCK_MINUTES=5\nIDLE_SUSPEND_MINUTES=12\n' > "$TMP/home/.config/idle.conf"
    # xremap: the virtual keyboard appears after a delay, unless XREMAP_FAILS.
    cat > "$STUBS/xremap" <<EOF
#!/bin/sh
echo "xremap \$*" >> "$CALLS"
[ -n "\${XREMAP_FAILS:-}" ] && exit 1
/usr/bin/sleep $XREMAP_DELAY_S
echo "xremap device ready" >> "$CALLS"
: > "$DEVICE"
EOF
    cat > "$STUBS/xinput" <<EOF
#!/bin/sh
echo pointer
[ -e "$DEVICE" ] && echo xremap
exit 0
EOF
    chmod +x "$STUBS"/* "$TMP/home/bin"/*
}

run() {
    : > "$CALLS"
    rm -f "$DEVICE"
    # Without the Qt variables of the session running the test. LANG as
    # lightdm sets it from the AccountsService language (German here).
    env -u QT_SCALE_FACTOR -u QT_FONT_DPI LANG=de_DE.utf8 \
        HOME="$TMP/home" XDG_RUNTIME_DIR="$TMP/run" PATH="$STUBS" DISPLAY=:99 XFT_DPI="${XFT_DPI:-}" /bin/sh "$XPROFILE"
    wait 2>/dev/null || true
}

# Line number of the first call matching PATTERN, or 0.
line_of() { grep -n -m 1 -E "$1" "$CALLS" | cut -d: -f1 || echo 0; }

main() {
    write_stubs

    run
    expect "logs in with de" "kb de" "$(grep '^kb ' "$CALLS" | head -n 1)"
    if grep -q '^kb bone2' "$CALLS"; then fail "still selects bone2"; else ok "no bone2 at login"; fi
    local ready layout
    ready="$(line_of '^xremap device ready')"
    layout="$(line_of '^kb de')"
    if [[ "$ready" -gt 0 && "$layout" -gt "$ready" ]]; then
        ok "layout set after the xremap keyboard exists"
    else
        fail "order: device line $ready, layout line $layout: $(tr '\n' ';' < "$CALLS")"
    fi

    # input-restore keeps the layout and tap-to-click when X re-adds devices.
    local watcher
    watcher="$(line_of '^input-restore')"
    if [[ "$watcher" -gt 0 && "$watcher" -gt "$layout" ]]; then
        ok "input-restore starts after the layout is set"
    else
        fail "input-restore line $watcher, layout line $layout"
    fi
    # A re-login replaces the old watcher (of this display only: a second
    # session, xrdp, must not stop the first one's); it runs as "bash", so
    # not -x.
    if grep -qF 'pkill-display -f /bin/input-restore$' "$CALLS"; then
        ok "the old watcher is stopped by command line"
    else
        fail "no pkill-display -f for input-restore: $(grep pkill "$CALLS" | tr '\n' ';')"
    fi

    # picom: tear-free drawing (vsync); a re-login replaces the old one.
    expect "picom starts as a daemon" "picom -b" "$(grep '^picom' "$CALLS")"
    if grep -qx 'pkill-display -x picom' "$CALLS"; then ok "the old picom is stopped"; else fail "no pkill-display -x picom"; fi

    # Local session: the default CopyQ server, no xrdp key setup.
    expect "local: CopyQ default session" "copyq  session=" "$(grep '^copyq' "$CALLS")"
    if grep -q '^xrdp-keys' "$CALLS"; then fail "local: xrdp-keys started"; else ok "local: no xrdp-keys"; fi

    # lxpolkit: the polkit agent that asks for the password (firewall-config
    # and other GUIs run as the user); a re-login replaces the old one.
    expect "polkit agent starts" "lxpolkit " "$(grep '^lxpolkit' "$CALLS")"
    if grep -qx 'pkill-display -x lxpolkit' "$CALLS"; then ok "the old polkit agent is stopped"; else fail "no pkill-display -x lxpolkit"; fi
    # dunst: notifications (screenshot, notify-send); one per display.
    expect "notification daemon starts" "dunst " "$(grep '^dunst' "$CALLS")"
    if grep -qx 'pkill-display -x dunst' "$CALLS"; then ok "the old notification daemon is stopped"; else fail "no pkill-display -x dunst"; fi

    # The eww bar starts its tray before the tray apps register (blueman,
    # CopyQ); otherwise they use i3bar's, which bar hides.
    local bar blueman
    bar="$(line_of '^bar')"
    blueman="$(line_of '^blueman-applet')"
    if [[ "$bar" -gt 0 && "$blueman" -gt "$bar" ]]; then
        ok "bar starts before the tray apps"
    else
        fail "bar line $bar, blueman line $blueman"
    fi

    # Idle: xidlehook locks after 5 min and suspends 7 min later (12 in
    # all), not while audio plays or a window is fullscreen (video). The X
    # screensaver timer is off: xss-lock would lock on it regardless.
    expect "idle timers" \
        "xidlehook|--not-when-audio|--not-when-fullscreen|--detect-sleep|--socket|$TMP/run/xidlehook.sock|--timer|300|loginctl lock-session||--timer|420|systemctl suspend|" \
        "$(grep '^xidlehook' "$CALLS")"
    if grep -qx 'xset s off' "$CALLS"; then ok "X screensaver timer off"; else fail "no xset s off: $(grep '^xset' "$CALLS" | tr '\n' ';')"; fi
    if grep -qx 'pkill-display -x xidlehook' "$CALLS"; then ok "the old xidlehook is stopped"; else fail "no pkill-display -x xidlehook"; fi
    if grep -q '^pkill ' "$CALLS"; then fail "plain pkill (all displays): $(grep '^pkill ' "$CALLS" | tr '\n' ';')"; else ok "no plain pkill"; fi

    # Marks itself loaded for ~/.xsession (xrdp), which loads it only where
    # the session script has not (Debian).
    expect "exports XPROFILE_LOADED" "loaded 1" "$(grep '^loaded ' "$CALLS")"

    # English programs (arandr, pavucontrol, blueman), whatever language
    # lightdm took from AccountsService.
    expect "programs start in English" "lang en_US.UTF-8" "$(grep '^lang ' "$CALLS")"

    # Qt scaling from Xft.dpi (bootstrap's scale): QT_SCALE_FACTOR plus
    # QT_FONT_DPI=96, or Qt 6 (already scaled by Xft.dpi) doubles and Qt 5
    # scales its fonts twice.
    expect "Qt scaling at 1.5x (144 dpi)" "qt 1.5 96" "$(XFT_DPI=144 run; grep '^qt ' "$CALLS")"
    expect "Qt scaling at 1.75x (168 dpi)" "qt 1.75 96" "$(XFT_DPI=168 run; grep '^qt ' "$CALLS")"
    # autorandr's hook sets the profile's DPI (desk: 120); Qt follows it.
    printf '#!/bin/sh\necho "autorandr $*" >> "%s"\necho 120 > "%s"\n' "$CALLS" "$TMP/hook-dpi" > "$STUBS/autorandr"
    expect "Qt scaling from the DPI autorandr's profile set" "qt 1.25 96" "$(XFT_DPI=144 run; grep '^qt ' "$CALLS")"
    printf '#!/bin/sh\necho "autorandr $*" >> "%s"\n' "$CALLS" > "$STUBS/autorandr"
    rm -f "$TMP/hook-dpi"
    expect "no Xft.dpi: Qt left alone" "qt unset unset" "$(run; grep '^qt ' "$CALLS")"

    # Without xremap (no input group) the layout is still set, and soon.
    local start elapsed
    start="$(date +%s)"
    XREMAP_FAILS=1 run
    elapsed=$(( $(date +%s) - start ))
    expect "layout set without xremap" "kb de" "$(grep '^kb ' "$CALLS" | head -n 1)"
    if [[ "$elapsed" -le 4 ]]; then ok "login waits at most a few seconds ($elapsed s)"; else fail "login waited $elapsed s"; fi

    # An xrdp session (XRDP_SESSION) next to the local one: nothing that
    # works on the machine's hardware or on per-user services the local
    # session already runs (xremap would grab the local keyboards, xidlehook
    # suspend the laptop when the remote side idles, CopyQ and blueman talk
    # to the local instances). The rest as usual.
    start="$(date +%s)"
    XRDP_SESSION=1 run
    elapsed=$(( $(date +%s) - start ))
    local skipped=""
    for cmd in xremap input-restore xidlehook picom autorandr blueman-applet; do
        grep -q "^$cmd\|-x $cmd\$\|/bin/$cmd" "$CALLS" && skipped+=" $cmd"
    done
    expect "xrdp: no local-only programs" "" "$skipped"
    # The RDP client sets the layout; the session does not change it.
    expect "xrdp: layout left to the client" "" "$(grep '^kb \|^setxkbmap -layout' "$CALLS")"
    # Right Shift (keycode 62) as $mod: xrdp-keys sets it, again after a reconnect
    # reloads the keymap.
    if grep -q '^xrdp-keys' "$CALLS"; then ok "xrdp: xrdp-keys started"; else fail "xrdp: no xrdp-keys"; fi
    # CopyQ: a server of its own (session "xrdp"); i3's copyq toggle
    # inherits the name, so $mod+c no longer opens the local window.
    expect "xrdp: CopyQ session of its own" "copyq  session=xrdp" "$(grep '^copyq' "$CALLS")"
    if grep -q '^bar' "$CALLS" && grep -q '^xss-lock' "$CALLS" && grep -q '^lxpolkit' "$CALLS"; then
        ok "xrdp: bar, locker and polkit agent start"
    else
        fail "xrdp: missing bar, xss-lock or lxpolkit: $(tr '\n' ';' < "$CALLS")"
    fi
    if [[ "$elapsed" -le 1 ]]; then ok "xrdp: no wait for xremap ($elapsed s)"; else fail "xrdp: waited $elapsed s"; fi

    exit "$FAILED"
}

main "$@"
