#!/usr/bin/env bash
#
# rio/rio, installed as $PREFIX/bin/rio: starts the Wayland build of Rio in
# a Wayland session and the X11 build otherwise (each build supports only
# its own backend). Stubs stand in for both builds in a fake prefix.
#
# Usage: test/rio-launcher/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

failed=0
ok()   { printf 'ok:   %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; failed=1; }
expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then
        ok "$name"
    else
        fail "$name: want '$want', got '$got'"
    fi
}

P="$TMP/prefix"
mkdir -p "$P/bin" "$P/libexec/rio"
cp "$ROOT/rio/rio" "$P/bin/rio"
for build in wayland x11; do
    printf '#!/usr/bin/env bash\necho "%s $*"\n' "$build" >"$P/libexec/rio/rio-$build"
    chmod +x "$P/libexec/rio/rio-$build"
done
ln -s "$P/bin/rio" "$TMP/rio-link"

run() { env -u WAYLAND_DISPLAY -u WAYLAND_SOCKET "$@"; }

expect "wayland session" "wayland -e htop" "$(run WAYLAND_DISPLAY=wayland-1 "$P/bin/rio" -e htop)"
expect "WAYLAND_SOCKET only" "wayland " "$(run WAYLAND_SOCKET=3 "$P/bin/rio")"
expect "X session (DISPLAY only)" "x11 --working-dir=/tmp" "$(run DISPLAY=:0 "$P/bin/rio" --working-dir=/tmp)"
expect "sway with xwayland-satellite's DISPLAY" "wayland " \
    "$(run DISPLAY=:1 WAYLAND_DISPLAY=wayland-1 "$P/bin/rio")"
expect "through a symlink" "x11 a b" "$(run DISPLAY=:0 "$TMP/rio-link" a b)"

exit "$failed"
