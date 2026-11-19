#!/usr/bin/env bash
#
# Runs kmscon_conf from bootstrap.sh with an fc-list stub: kmscon.conf gets
# the font size, the Solarized palette, no mouse (no-mouse), and PragmataPro
# Mono only where fontconfig finds it (a commercial font, missing on most
# machines).
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
    grep -E '^readonly (KMSCON_(CONF_MARKER|PALETTE|FONT)|CONSOLE_XKB_OPTIONS)=' "$BOOTSTRAP"
    sed -n '/^kmscon_conf() {$/,/^}$/p' "$BOOTSTRAP"
    sed -n '/^kmscon_swap_ctrl_alt() {$/,/^}$/p' "$BOOTSTRAP"
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
expect "without PragmataPro: size, palette, no mouse" \
    "$marker"$'\nfont-size=24\npalette=solarized\nno-mouse' "$(conf 24)"
touch "$TMP/font"
expect "with PragmataPro: also the font" \
    "$marker"$'\nfont-size=24\npalette=solarized\nno-mouse\nfont-name=PragmataPro Mono' "$(conf 24)"
rm -f "$TMP/font"

# kmscon_swap_ctrl_alt: localectl status prints "$TMP/status"; other calls
# are recorded in "$TMP/calls".
cat > "$STUBS/localectl" <<EOF
#!/bin/sh
if [ "\$1" = status ]; then cat "$TMP/status"; else echo "localectl \$*" >> "$TMP/calls"; fi
EOF
chmod +x "$STUBS/localectl"
swap() {
    : > "$TMP/calls"
    PATH="$STUBS:$PATH" SUDO="" bash -c "have() { command -v \"\$1\" >/dev/null; }
        log() { :; }; warn() { echo \"warn: \$*\"; }
        source '$FUNCS'; kmscon_swap_ctrl_alt"
}
printf '   System Locale: LANG=en_US.UTF-8\n       VC Keymap: de\n      X11 Layout: de\n     X11 Variant: bone\n' > "$TMP/status"
swap >/dev/null
expect "swap: added, layout and variant kept" \
    "localectl --no-convert set-x11-keymap de  bone ctrl:swap_lalt_lctl" "$(cat "$TMP/calls")"
printf '      X11 Layout: de\n     X11 Variant: bone\n     X11 Options: ctrl:swap_lalt_lctl\n' > "$TMP/status"
swap >/dev/null
expect "swap: already set, localed untouched" "" "$(cat "$TMP/calls")"
for status in '       VC Keymap: de\n' '      X11 Layout: n/a\n'; do
    printf '%b' "$status" > "$TMP/status"
    out="$(swap)"
    expect "swap: no X11 layout ($status), untouched" "" "$(cat "$TMP/calls")"
    if [[ "$out" == warn:* ]]; then ok "swap: no X11 layout, warns"; else fail "swap: no warning: $out"; fi
done

exit "$FAILED"
