#!/usr/bin/env bash
#
# Firefox's scroll and swipe prefs for sway (firefox/): bootstrap installs
# an autoconfig file that sets them only when Firefox starts in sway
# (SWAYSOCK set), where the touchpad's scroll_factor is 0.1. Runs Fedora
# 45's Firefox headless with the files at bootstrap's paths, once with and
# once without SWAYSOCK, and reads the prefs it ended up with.
#
# Usage: test/firefox-prefs/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
readonly IMAGE="fedora:45"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }
expect() { if [[ "$3" == "$2" ]]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi; }

# Paths from bootstrap.sh, so the test follows them.
dst_of() { sed -n "s|^    \"$1:\([^:]*\):.*|\1|p" "$ROOT/bootstrap.sh"; }
PREF_DST="$(dst_of autoconfig.js)"
CFG_DST="$(dst_of dotfiles.cfg)"
readonly PREF_DST CFG_DST

read -r -d '' INNER <<'EOF' || true
set -euo pipefail
dnf install -y -q firefox >/dev/null 2>&1
[ -f /autoconfig.js ] && install -D -m 0644 /autoconfig.js "$PREF_DST"
[ -f /dotfiles.cfg ] && install -D -m 0644 /dotfiles.cfg "$CFG_DST"
# A probe after the real file: pref() saves the effective values as user
# prefs, which Firefox writes to prefs.js on exit.
if [ -f "$CFG_DST" ]; then
    cat >> "$CFG_DST" <<'P'
var names = ["mousewheel.default.delta_multiplier_y", "widget.swipe.page-size", "widget.swipe.pixel-size"];
pref("dotfiles.probe", names.map(function (n) { return n + "=" + getPref(n); }).join(" "));
P
fi
probe() {
    rm -rf /tmp/profile; mkdir /tmp/profile
    env "$@" firefox --headless --profile /tmp/profile --screenshot /tmp/shot.png about:blank >/dev/null 2>&1 || true
    sed -n 's/^user_pref("dotfiles.probe", "\(.*\)");$/\1/p' /tmp/profile/prefs.js
}
echo "sway: $(probe SWAYSOCK=/run/user/1000/sway-ipc.sock)"
echo "other: $(probe -u SWAYSOCK)"
EOF

main() {
    local name want got out f
    name="dotfiles-firefox-prefs-$$"
    docker create --name "$name" -e PREF_DST="$PREF_DST" -e CFG_DST="$CFG_DST" \
        "$IMAGE" bash -c "$INNER" > /dev/null
    trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT
    for f in autoconfig.js dotfiles.cfg; do
        [[ -f "$ROOT/firefox/$f" ]] && docker cp "$ROOT/firefox/$f" "$name:/$f"
    done
    out="$(docker start -a "$name" 2>&1 | tail -n 20 || true)"

    if [[ -n "$PREF_DST" && -n "$CFG_DST" ]]; then
        ok "bootstrap.sh names both paths"
    else
        fail "bootstrap.sh: no paths for autoconfig.js and dotfiles.cfg"
    fi

    want="mousewheel.default.delta_multiplier_y=500 widget.swipe.page-size=8.0 widget.swipe.pixel-size=220.0"
    got="$(sed -n 's/^sway: //p' <<< "$out")"
    [[ -n "$got" ]] || printf '%s\n' "$out"
    expect "sway: scroll 500, swipe 8 / 220" "$want" "$got"

    want="mousewheel.default.delta_multiplier_y=100 widget.swipe.page-size=40.0 widget.swipe.pixel-size=1100.0"
    got="$(sed -n 's/^other: //p' <<< "$out")"
    expect "other sessions: Firefox's defaults" "$want" "$got"
    exit "$FAILED"
}

main "$@"
