#!/usr/bin/env bash
#
# The xrdp session helpers with stubs. bin/xrdp-keys makes keycode 62
# (right Shift; the Mac sends it for Cmd) Super_L in Mod4, i3's $mod, out of
# Shift, and sets it again when
# xrdp loaded a fresh keymap (on every reconnect); a keymap
# that has it already is left alone. It checks every few seconds: xev gets
# no MappingNotify (XKB). bin/term starts wezterm as a process
# of its own in xrdp (a running GUI instance may be the local session's)
# and as usual otherwise.
#
# Usage: test/xrdp/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BIN="$HERE/../../bin"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" KEYMAP="$TMP/keymap"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: want '$want', got '$got'"; fi
}

write_stubs() {
    mkdir -p "$STUBS"
    # xmodmap: -pm prints the Mod4 line of KEYMAP ("62" when set) and fails
    # once X is gone (TMP/x-gone); -e records the change and sets it.
    cat > "$STUBS/xmodmap" <<STUB
#!/bin/sh
[ -e "$TMP/x-gone" ] && exit 1
case "\$1" in
    -pm)
        if grep -q 62 "$KEYMAP"; then
            echo "mod4        Super_L (0x3e),  Super_L (0x73)"
        else
            echo "mod4        Super_L (0x73)"
        fi
        ;;
    -e)
        echo "xmodmap \$*" >> "$CALLS"
        echo 62 > "$KEYMAP"
        ;;
esac
STUB
    # sleep: the watcher's poll. The first one is a reconnect (xrdp loads a
    # fresh keymap), the third one ends the X session.
    cat > "$STUBS/sleep" <<STUB
#!/bin/sh
n=\$(cat "$TMP/sleeps" 2>/dev/null || echo 0); n=\$((n + 1)); echo \$n > "$TMP/sleeps"
[ "\$n" -eq 1 ] && : > "$KEYMAP"
[ "\$n" -ge 3 ] && touch "$TMP/x-gone"
exit 0
STUB
    printf '#!/bin/sh\necho "wezterm $*" >> "%s"\n' "$CALLS" > "$STUBS/wezterm"
    chmod +x "$STUBS"/*
}

run() { rm -f "$TMP/sleeps" "$TMP/x-gone"; DISPLAY=:10 PATH="$STUBS:$PATH" "$@"; }

main() {
    write_stubs

    # A fresh xrdp keymap: keycode 62 is Shift_R, in Shift.
    : > "$KEYMAP"
    : > "$CALLS"
    run timeout 5 "$BIN/xrdp-keys" || true
    expect "right Shift becomes Super_L in Mod4 (start, after the reconnect)" \
        "xmodmap -e remove shift = Shift_R -e keycode 62 = Super_L -e add mod4 = Super_L;xmodmap -e remove shift = Shift_R -e keycode 62 = Super_L -e add mod4 = Super_L" \
        "$(paste -sd ';' "$CALLS")"
    if [[ -e "$TMP/x-gone" ]]; then ok "ends with the X session"; else fail "still running"; fi

    # Already set and no reconnect: nothing to do.
    echo 62 > "$KEYMAP"
    : > "$CALLS"
    rm -f "$TMP/sleeps" "$TMP/x-gone"
    echo 1 > "$TMP/sleeps"
    DISPLAY=:10 PATH="$STUBS:$PATH" timeout 5 "$BIN/xrdp-keys" || true
    expect "a keymap with it is left alone" "" "$(cat "$CALLS")"

    : > "$CALLS"
    XRDP_SESSION=1 run "$BIN/term"
    expect "xrdp: wezterm as a process of its own" "wezterm start --always-new-process" "$(cat "$CALLS")"
    : > "$CALLS"
    env -u XRDP_SESSION DISPLAY=:0 PATH="$STUBS:$PATH" "$BIN/term"
    expect "local: wezterm as usual (joins the running GUI)" "wezterm " "$(cat "$CALLS")"

    # ~/.xsession, which xrdp's session script starts: .xprofile once (Fedora's
    # Xsession loads it already and sets XPROFILE_LOADED; Debian's does not),
    # then i3.
    local home="$TMP/xs-home"
    mkdir -p "$home"
    printf 'echo xprofile >> "%s"\nXPROFILE_LOADED=1\n' "$CALLS" > "$home/.xprofile"
    printf '#!/bin/sh\necho i3 >> "%s"\n' "$CALLS" > "$STUBS/i3"
    chmod +x "$STUBS/i3"
    : > "$CALLS"
    env -u XPROFILE_LOADED HOME="$home" PATH="$STUBS:$PATH" sh "$HERE/../../.xsession"
    expect "xsession without .xprofile loaded: loads it, then i3" "xprofile;i3" "$(paste -sd ';' "$CALLS")"
    : > "$CALLS"
    XPROFILE_LOADED=1 HOME="$home" PATH="$STUBS:$PATH" sh "$HERE/../../.xsession"
    expect "xsession after Fedora's Xsession: only i3" "i3" "$(paste -sd ';' "$CALLS")"

    exit "$FAILED"
}

main "$@"
