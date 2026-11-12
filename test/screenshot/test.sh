#!/usr/bin/env bash
#
# bin/screenshot with stubs: in sway grim (and slurp for an area), in X
# maim (-s for an area); the PNG goes to ~/Pictures/Screenshots and to the
# clipboard (wl-copy or xclip), with a notification. A cancelled area
# selection saves nothing and is no error.
#
# Usage: test/screenshot/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/screenshot"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" FAKE_HOME="$TMP/home"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: want '$want', got '$got'"; fi
}

write_stubs() {
    mkdir -p "$STUBS" "$FAKE_HOME"
    # grim and maim write their last argument; slurp prints a geometry, or
    # fails like a cancelled selection (TMP/cancel); maim -s fails then too.
    cat > "$STUBS/grim" <<EOF
#!/bin/sh
echo "grim \$*" >> "$CALLS"
for f; do :; done; echo png > "\$f"
EOF
    cat > "$STUBS/slurp" <<EOF
#!/bin/sh
echo "slurp \$*" >> "$CALLS"
[ -e "$TMP/cancel" ] && exit 1
echo "10,20 300x200"
EOF
    cat > "$STUBS/maim" <<EOF
#!/bin/sh
echo "maim \$*" >> "$CALLS"
[ -e "$TMP/cancel" ] && [ "\$1" = -s ] && exit 1
for f; do :; done; echo png > "\$f"
EOF
    # The clipboard tools record what they read.
    # shellcheck disable=SC2016 # $* and $(cat) belong to the stubs.
    printf '#!/bin/sh\necho "wl-copy $* $(cat)" >> "%s"\n' "$CALLS" > "$STUBS/wl-copy"
    # shellcheck disable=SC2016 # as above.
    printf '#!/bin/sh\necho "xclip $* $(cat)" >> "%s"\n' "$CALLS" > "$STUBS/xclip"
    printf '#!/bin/sh\necho "notify-send $*" >> "%s"\n' "$CALLS" > "$STUBS/notify-send"
    printf '#!/bin/sh\necho 2026-11-12_10-00-00\n' > "$STUBS/date"
    chmod +x "$STUBS"/*
}

# Runs the script in sway (SWAYSOCK) or X; prints its exit status.
run() {
    local session="$1"; shift
    : > "$CALLS"
    rm -rf "$FAKE_HOME/Pictures"
    local rc=0 env=(HOME="$FAKE_HOME" PATH="$STUBS:/usr/bin:/bin")
    if [[ "$session" == sway ]]; then env+=(SWAYSOCK=/run/sway.sock WAYLAND_DISPLAY=wayland-1); else env+=(DISPLAY=:0); fi
    env -i "${env[@]}" "$SCRIPT" "$@" >/dev/null 2>&1 || rc=$?
    echo "$rc"
}

main() {
    write_stubs
    local file="$FAKE_HOME/Pictures/Screenshots/2026-11-12_10-00-00.png"

    expect "sway: exits 0" 0 "$(run sway)"
    expect "sway: grim, clipboard, notification" \
        "grim $file;wl-copy --type image/png png;notify-send -a screenshot Screenshot $file" \
        "$(paste -sd ';' "$CALLS")"
    expect "sway: saved" png "$(cat "$file" 2>/dev/null)"

    run sway --area >/dev/null
    expect "sway area: slurp, then grim -g" "slurp ;grim -g 10,20 300x200 $file" \
        "$(grep -E '^(slurp|grim)' "$CALLS" | paste -sd ';')"

    expect "X: exits 0" 0 "$(run x)"
    expect "X: maim, clipboard, notification" \
        "maim $file;xclip -selection clipboard -t image/png png;notify-send -a screenshot Screenshot $file" \
        "$(paste -sd ';' "$CALLS")"

    run x --area >/dev/null
    expect "X area: maim -s" "maim -s $file" "$(grep '^maim' "$CALLS")"

    touch "$TMP/cancel"
    expect "sway area cancelled: exits 0" 0 "$(run sway --area)"
    expect "sway area cancelled: no grim, no clipboard" "slurp " "$(paste -sd ';' "$CALLS")"
    expect "X area cancelled: exits 0" 0 "$(run x --area)"
    expect "X area cancelled: no clipboard, no file" "maim -s $file;" \
        "$(paste -sd ';' "$CALLS");$(ls "$FAKE_HOME/Pictures/Screenshots" 2>/dev/null)"
    rm "$TMP/cancel"

    exit "$FAILED"
}

main "$@"
