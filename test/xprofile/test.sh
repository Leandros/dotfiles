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
    for cmd in systemctl autorandr xset setxkbmap xmodmap pkill xss-lock xautolock blueman-applet copyq picom lxpolkit; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$STUBS/$cmd"
    done
    # xrdb -query prints the Xft.dpi of XFT_DPI (unset: none), like the
    # rendered ~/.Xresources.
    cat > "$STUBS/xrdb" <<EOF
#!/bin/sh
echo "xrdb \$*" >> "$CALLS"
[ "\$1" = -query ] && [ -n "\${XFT_DPI:-}" ] && printf 'Xft.dpi:\t%s\n' "\$XFT_DPI"
exit 0
EOF
    # theme records the Qt scaling it inherits: programs started after it see
    # the same environment.
    cat > "$TMP/home/bin/theme" <<EOF
#!/bin/sh
echo "theme \$*" >> "$CALLS"
echo "qt \${QT_SCALE_FACTOR:-unset} \${QT_FONT_DPI:-unset}" >> "$CALLS"
EOF
    for cmd in kb input-restore; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$TMP/home/bin/$cmd"
    done
    printf '#!/bin/sh\nexec /usr/bin/sleep "$@"\n' > "$STUBS/sleep"
    printf '#!/bin/sh\nexec /usr/bin/grep "$@"\n' > "$STUBS/grep"
    printf '#!/bin/sh\nexec /usr/bin/awk "$@"\n' > "$STUBS/awk"
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
    # Without the Qt variables of the session running the test.
    env -u QT_SCALE_FACTOR -u QT_FONT_DPI \
        HOME="$TMP/home" PATH="$STUBS" DISPLAY=:99 XFT_DPI="${XFT_DPI:-}" /bin/sh "$XPROFILE"
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
    # A re-login replaces the old watcher; it runs as "bash", so not pkill -x.
    if grep -qF 'pkill -f /bin/input-restore$' "$CALLS"; then
        ok "the old watcher is stopped by command line"
    else
        fail "no pkill -f for input-restore: $(grep pkill "$CALLS" | tr '\n' ';')"
    fi

    # picom: tear-free drawing (vsync); a re-login replaces the old one.
    expect "picom starts as a daemon" "picom -b" "$(grep '^picom' "$CALLS")"
    if grep -qx 'pkill -x picom' "$CALLS"; then ok "the old picom is stopped"; else fail "no pkill -x picom"; fi

    # lxpolkit: the polkit agent that asks for the password (firewall-config
    # and other GUIs run as the user); a re-login replaces the old one.
    expect "polkit agent starts" "lxpolkit " "$(grep '^lxpolkit' "$CALLS")"
    if grep -qx 'pkill -x lxpolkit' "$CALLS"; then ok "the old polkit agent is stopped"; else fail "no pkill -x lxpolkit"; fi

    # Qt scaling from Xft.dpi (bootstrap's scale): QT_SCALE_FACTOR plus
    # QT_FONT_DPI=96, or Qt 6 (already scaled by Xft.dpi) doubles and Qt 5
    # scales its fonts twice.
    expect "Qt scaling at 1.5x (144 dpi)" "qt 1.5 96" "$(XFT_DPI=144 run; grep '^qt ' "$CALLS")"
    expect "Qt scaling at 1.75x (168 dpi)" "qt 1.75 96" "$(XFT_DPI=168 run; grep '^qt ' "$CALLS")"
    expect "no Xft.dpi: Qt left alone" "qt unset unset" "$(run; grep '^qt ' "$CALLS")"

    # Without xremap (no input group) the layout is still set, and soon.
    local start elapsed
    start="$(date +%s)"
    XREMAP_FAILS=1 run
    elapsed=$(( $(date +%s) - start ))
    expect "layout set without xremap" "kb de" "$(grep '^kb ' "$CALLS" | head -n 1)"
    if [[ "$elapsed" -le 4 ]]; then ok "login waits at most a few seconds ($elapsed s)"; else fail "login waited $elapsed s"; fi

    exit "$FAILED"
}

main "$@"
