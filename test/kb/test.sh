#!/usr/bin/env bash
#
# Runs bin/kb with stubs for the X, sway and console tools: inside X it
# changes only the session's X keyboard, in sway only sway's keyboards
# (--console also the console); on a tty (no DISPLAY) only the console.
# The console path writes the system-wide keymap (localectl, which is also
# the X server default the login screen uses) or the kernel keymap
# (loadkeys), so a session must not touch it by itself. sway also sets
# DISPLAY (Xwayland): SWAYSOCK selects the sway path.
#
# Usage: test/kb/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/kb"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
# The bar's state of display :99; each X display has its own (two sessions,
# e.g. a local one and xrdp, can use different layouts). sway's is keyed by
# its Wayland display.
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" STATE="$TMP/run/kb-layout-:99"
readonly SWAY_STATE="$TMP/run/kb-layout-wayland-1" OUT="$TMP/out"
# Survives `swaymsg reload`: the sway config includes ~/.config/sway.d/*.conf.
readonly SWAY_CONF="$TMP/home/.config/sway.d/kb.conf"
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

# Each tool records its call. systemctl lists a kmscon unit and kmscon exists
# when "$TMP/kmscon" exists (Fedora 45 consoles); otherwise fbcon (loadkeys).
write_stubs() {
    mkdir -p "$STUBS" "$TMP/home"
    echo "! test xmodmap" > "$TMP/home/.Xmodmap"
    local cmd
    for cmd in setxkbmap xmodmap loadkeys localectl; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$STUBS/$cmd"
    done
    # xkbcomp: `xkbcomp -w0 <display> <file>` dumps the server keymap.
    cat > "$STUBS/xkbcomp" <<EOF
#!/bin/sh
echo "xkbcomp \$*" >> "$CALLS"
for last; do :; done
case "\$last" in *.tmp) echo dump > "\$last" ;; esac
EOF
    # sudo runs the command, so its stub records it.
    # shellcheck disable=SC2016 # $1 and $@ belong to the stub.
    printf '#!/bin/sh\n[ "$1" = -n ] && shift\nexec "$@"\n' > "$STUBS/sudo"
    cat > "$STUBS/systemctl" <<EOF
#!/bin/sh
[ -e "$TMP/kmscon" ] && echo "kmsconvt@tty2.service loaded active running"
exit 0
EOF
    # swaymsg as sway 1.12 answers when stdout is not a terminal: get_inputs
    # prints "$TMP/inputs.json"; with "$TMP/swaymsg-fail" a command fails as
    # for a layout libxkbcommon cannot find (exit 2).
    cat > "$STUBS/swaymsg" <<EOF
#!/bin/sh
echo "swaymsg \$*" >> "$CALLS"
case "\$*" in
    *get_inputs*) cat "$TMP/inputs.json" 2>/dev/null || echo '[]'; exit 0 ;;
esac
if [ -e "$TMP/swaymsg-fail" ]; then
    printf '%s\n' '[ { "success": false, "parse_error": false, "error": "Failed to compile keymap: [XKB-338] Couldn'"'"'t find file \"symbols\/bone2\" in include paths" } ]'
    exit 2
fi
echo '[ { "success": true } ]'
EOF
    chmod +x "$STUBS"/*
}

# sway's get_inputs: a touchpad, a virtual keyboard without a layout name,
# then the keyboards with layout name $1.
inputs() {
    cat > "$TMP/inputs.json" <<EOF
[
  { "identifier": "1267:12608:Touchpad", "type": "touchpad" },
  { "identifier": "0:0:wlr_virtual_keyboard_v1", "type": "keyboard", "xkb_active_layout_name": null },
  { "identifier": "1:1:AT_Translated_Set_2_keyboard", "type": "keyboard", "xkb_active_layout_name": "$1" },
  { "identifier": "1:1:Other_keyboard", "type": "keyboard", "xkb_active_layout_name": "Other" }
]
EOF
}

# kb in a session ($1: "x", "sway" or "tty") with the remaining arguments.
# sway also sets DISPLAY for Xwayland.
run() {
    local where="$1"
    shift
    : > "$CALLS"
    local session=()
    case "$where" in
        x) session=(DISPLAY="${KB_DISPLAY:-:99}") ;;
        sway) session=(DISPLAY=:0 SWAYSOCK="$TMP/sway-ipc.sock" WAYLAND_DISPLAY="${KB_WAYLAND_DISPLAY:-wayland-1}") ;;
    esac
    rm -f "$STUBS/kmscon"
    if [[ -e "$TMP/kmscon" ]]; then
        printf '#!/bin/sh\nexit 0\n' > "$STUBS/kmscon"
        chmod +x "$STUBS/kmscon"
    fi
    env -u DISPLAY -u SWAYSOCK -u WAYLAND_DISPLAY ${session[@]+"${session[@]}"} HOME="$TMP/home" XDG_RUNTIME_DIR="$TMP/run" \
        XDG_CACHE_HOME="$TMP/cache" PATH="$STUBS:$PATH" "$SCRIPT" "$@" < /dev/null > "$OUT" 2>&1 || echo "rc=$?" >> "$CALLS"
}

# The calls of one tool, joined.
calls() { { grep "^$1" "$CALLS" || true; } | tr '\n' ';' | sed 's/;$//'; }

main() {
    write_stubs

    # Inside X: the session's X keyboard only.
    run x de
    expect "X: de sets the X layout" "setxkbmap -layout de -option terminate:ctrl_alt_bksp" "$(calls setxkbmap)"
    expect "X: no console keymap" "" "$(calls loadkeys)$(calls localectl)"
    expect "X: the bar's state" "de" "$(cat "$STATE")"

    run x bone2
    expect "X: bone2 loads the xmodmap" "xmodmap $TMP/home/.Xmodmap" "$(calls xmodmap)"
    expect "X: bone2 leaves the console" "" "$(calls loadkeys)$(calls localectl)"

    # Inside X with --console: X and the console (fbcon: loadkeys).
    run x --console de
    expect "X --console: X layout" "setxkbmap -layout de -option terminate:ctrl_alt_bksp" "$(calls setxkbmap)"
    expect "X --console: fbcon keymap" "loadkeys -u -q de-latin1" "$(calls loadkeys)"
    run x bone2 --console
    expect "X --console after the layout works too" "loadkeys -u -q $(cd "$HERE/../.." && pwd)/console/bone2.map" "$(calls loadkeys)"

    # kmscon consoles follow localed: only with --console, never from X alone.
    touch "$TMP/kmscon"
    run x de
    expect "X, kmscon: localectl untouched" "" "$(calls localectl)"
    run x --console bone2
    expect "X --console, kmscon: localectl de bone" "localectl --no-convert set-x11-keymap de  bone" "$(calls localectl)"
    rm -f "$TMP/kmscon"

    # Another X session (display :98) keeps its own layout.
    run x de
    KB_DISPLAY=:98 run x us
    expect "second display: its own state" "us" "$(cat "$TMP/run/kb-layout-:98" 2>/dev/null)"
    expect "second display: the first one's state stays" "de" "$(cat "$STATE")"
    KB_DISPLAY=:98 run x show
    expect "kb show per display" "" "$(calls rc=)"

    # On a tty: the console only; the bar's X state stays.
    echo de > "$STATE"
    run tty bone2
    expect "tty: console keymap" "loadkeys -u -q $(cd "$HERE/../.." && pwd)/console/bone2.map" "$(calls loadkeys)"
    expect "tty: no X tools" "" "$(calls setxkbmap)$(calls xkbcomp)$(calls xmodmap)"
    expect "tty: the X state is kept" "de" "$(cat "$STATE")"
    run tty --console us
    expect "tty --console: console only" "loadkeys -u -q us" "$(calls loadkeys)"

    # sway: its keyboards only, even with DISPLAY (Xwayland) set.
    run sway bone2
    expect "sway: bone2 via swaymsg" "swaymsg input type:keyboard xkb_layout bone2" "$(calls swaymsg)"
    expect "sway: no X tools" "" "$(calls setxkbmap)$(calls xkbcomp)$(calls xmodmap)"
    expect "sway: no console keymap" "" "$(calls loadkeys)$(calls localectl)"
    expect "sway: state per Wayland display" "bone2" "$(cat "$SWAY_STATE" 2>/dev/null)"
    expect "sway: no state for Xwayland's display" "" "$(cat "$TMP/run/kb-layout-:0" 2>/dev/null)"
    expect "sway: the layout survives swaymsg reload" "input type:keyboard xkb_layout bone2" "$(cat "$SWAY_CONF" 2>/dev/null)"

    # A layout sway cannot compile (bone2 not in ~/.config/xkb): an error; state and reload file stay.
    touch "$TMP/swaymsg-fail"
    run sway us
    rm -f "$TMP/swaymsg-fail"
    expect "sway: a failed swaymsg fails kb" "rc=1" "$(calls rc=)"
    if grep -q "layout us: Failed to compile keymap: \[XKB-338\] Couldn't find file \"symbols/bone2\"" "$OUT"; then
        ok "sway: the error gives sway's reason"
    else
        fail "sway: error: $(cat "$OUT")"
    fi
    expect "sway: state kept after a failure" "bone2" "$(cat "$SWAY_STATE" 2>/dev/null)"
    expect "sway: reload file kept after a failure" "input type:keyboard xkb_layout bone2" "$(cat "$SWAY_CONF" 2>/dev/null)"

    # Another sway session keeps its own state.
    KB_WAYLAND_DISPLAY=wayland-2 run sway us
    expect "second Wayland display: its own state" "us" "$(cat "$TMP/run/kb-layout-wayland-2" 2>/dev/null)"
    expect "second Wayland display: the first one's state stays" "bone2" "$(cat "$SWAY_STATE" 2>/dev/null)"

    # sway with --console: sway and the console (fbcon, then kmscon).
    run sway --console de
    expect "sway --console: sway layout" "swaymsg input type:keyboard xkb_layout de" "$(calls swaymsg)"
    expect "sway --console: fbcon keymap" "loadkeys -u -q de-latin1" "$(calls loadkeys)"
    touch "$TMP/kmscon"
    run sway --console bone2
    expect "sway --console, kmscon: localectl de bone" "localectl --no-convert set-x11-keymap de  bone" "$(calls localectl)"
    run sway us
    expect "sway, kmscon: localectl untouched" "" "$(calls localectl)"
    rm -f "$TMP/kmscon"

    # Without a state file (first call after login) kb show asks sway: the
    # first keyboard with a layout name.
    local pair name
    for pair in "English (US)=us" "German=de" "Bone 2 (dotfiles)=bone2" "French=?"; do
        name="${pair%=*}"
        rm -f "$SWAY_STATE"
        inputs "$name"
        run sway show
        expect "sway show without state: $name" "${pair##*=}" "$(cat "$OUT")"
    done
    expect "sway show reads get_inputs" "swaymsg -t get_inputs" "$(calls swaymsg)"
    inputs "German"
    run sway show
    expect "sway show keeps the detected layout" "de" "$(cat "$SWAY_STATE" 2>/dev/null)"
    run sway next
    expect "sway next after de" "swaymsg input type:keyboard xkb_layout bone2" "$(calls swaymsg)"

    run x --bogus de
    if grep -q '^rc=' "$CALLS"; then ok "unknown option rejected"; else fail "unknown option accepted"; fi
    run x
    if grep -q '^rc=' "$CALLS"; then ok "no layout without a terminal: error"; else fail "no layout accepted"; fi

    exit "$FAILED"
}

main "$@"
