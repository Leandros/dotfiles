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
    for cmd in xrdb systemctl autorandr xset setxkbmap xmodmap pkill xss-lock xautolock blueman-applet copyq; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$STUBS/$cmd"
    done
    for cmd in kb theme; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$TMP/home/bin/$cmd"
    done
    printf '#!/bin/sh\nexec /usr/bin/sleep "$@"\n' > "$STUBS/sleep"
    printf '#!/bin/sh\nexec /usr/bin/grep "$@"\n' > "$STUBS/grep"
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
    HOME="$TMP/home" PATH="$STUBS" DISPLAY=:99 /bin/sh "$XPROFILE"
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
