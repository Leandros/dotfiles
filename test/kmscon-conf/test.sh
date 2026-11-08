#!/usr/bin/env bash
#
# Runs kmscon_conf from bootstrap.sh with an fc-list stub: kmscon.conf gets
# the font size, the Solarized palette, and PragmataPro Mono only where
# fontconfig finds it (a commercial font, missing on most machines).
#
# Usage: test/kmscon-conf/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BOOTSTRAP="$HERE/../../bootstrap.sh"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" FUNCS="$TMP/funcs.sh"
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

{
    grep -E '^readonly KMSCON_(CONF_MARKER|PALETTE|FONT)=' "$BOOTSTRAP"
    sed -n '/^kmscon_conf() {$/,/^}$/p' "$BOOTSTRAP"
} > "$FUNCS"

mkdir -p "$STUBS"
# fc-list prints a match when "$TMP/font" exists.
cat > "$STUBS/fc-list" <<EOF
#!/bin/sh
[ -e "$TMP/font" ] && echo "/usr/local/share/fonts/PragmataPro_Mono_R_0830.ttf: PragmataPro Mono:style=Regular"
exit 0
EOF
chmod +x "$STUBS/fc-list"

conf() { PATH="$STUBS:$PATH" bash -c "source '$FUNCS'; kmscon_conf $1"; }

marker="# Written by bootstrap.sh; edit the dotfiles instead."
expect "without PragmataPro: size and palette" \
    "$marker"$'\nfont-size=24\npalette=solarized' "$(conf 24)"
touch "$TMP/font"
expect "with PragmataPro: also the font" \
    "$marker"$'\nfont-size=24\npalette=solarized\nfont-name=PragmataPro Mono' "$(conf 24)"
rm -f "$TMP/font"

exit "$FAILED"
