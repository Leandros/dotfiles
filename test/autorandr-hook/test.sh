#!/usr/bin/env bash
#
# .config/autorandr/postswitch (autorandr's global hook) with stubs for
# xrdb and i3-msg: Xft.dpi from the profile's xft-dpi file, else from
# ~/.Xresources; i3 restarts (in place) only when the DPI changed and i3
# runs; nothing in an xrdp session.
#
# Usage: test/autorandr-hook/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOOK="$HERE/../../.config/autorandr/postswitch"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" HOME_DIR="$TMP/home"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: want '$want', got '$got'"; fi
}

write_stubs() {
    mkdir -p "$STUBS" "$HOME_DIR/.config/autorandr/desk" "$HOME_DIR/.config/autorandr/laptop"
    # xrdb: -query prints TMP/dpi; -merge records stdin and stores the DPI.
    cat > "$STUBS/xrdb" <<EOF
#!/bin/sh
case "\$1" in
    -query) printf 'Xft.dpi:\t%s\n' "\$(cat "$TMP/dpi")" ;;
    -merge) in="\$(cat)"; echo "xrdb -merge \$in" >> "$CALLS"; echo "\${in##* }" > "$TMP/dpi" ;;
esac
EOF
    # i3-msg: i3 runs unless TMP/no-i3.
    cat > "$STUBS/i3-msg" <<EOF
#!/bin/sh
[ -e "$TMP/no-i3" ] && exit 1
echo "i3-msg \$*" >> "$CALLS"
EOF
    chmod +x "$STUBS"/*
    printf '! Xft\nXft.dpi:                144\nXft.antialias:          true\n' > "$HOME_DIR/.Xresources"
    echo 120 > "$HOME_DIR/.config/autorandr/desk/xft-dpi"
}

# Runs the hook for profile $1 with the current DPI $2.
run() {
    echo "$2" > "$TMP/dpi"
    : > "$CALLS"
    HOME="$HOME_DIR" AUTORANDR_CURRENT_PROFILE="$1" PATH="$STUBS:$PATH" "$HOOK"
    paste -sd ';' "$CALLS"
}

main() {
    write_stubs
    expect "desk: its xft-dpi, i3 restarts" "xrdb -merge Xft.dpi: 120;i3-msg -t get_version;i3-msg -q restart" \
        "$(run desk 144)"
    expect "laptop: no xft-dpi, the one of ~/.Xresources" \
        "xrdb -merge Xft.dpi: 144;i3-msg -t get_version;i3-msg -q restart" "$(run laptop 120)"
    expect "same DPI: no restart" "xrdb -merge Xft.dpi: 120" "$(run desk 120)"
    touch "$TMP/no-i3"
    expect "before i3 (login): only the DPI" "xrdb -merge Xft.dpi: 120" "$(run desk 144)"
    rm "$TMP/no-i3"
    : > "$CALLS"
    XRDP_SESSION=1 HOME="$HOME_DIR" AUTORANDR_CURRENT_PROFILE=desk PATH="$STUBS:$PATH" "$HOOK"
    expect "xrdp session: nothing" "" "$(cat "$CALLS")"
    exit "$FAILED"
}

main "$@"
