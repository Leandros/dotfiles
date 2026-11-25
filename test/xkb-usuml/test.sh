#!/usr/bin/env bash
#
# usuml (xkb/symbols/usuml): the US layout with ä ö ü (Ä Ö Ü with Shift) on
# right Alt + a, o, u, for keyboards that send US keys (the ErgoDox).
# In a Fedora container:
#   sway: libxkbcommon compiles it from ~/.config/xkb without warnings;
#         the umlauts are on AC01/AD09/AD07 level 3 and 4, right Alt is
#         level 3, and every ASCII character is typed as in us.
#   X:    `kb usuml` on Xorg (dummy driver; Xvfb ignores every keymap
#         change, setxkbmap's too) loads it (xkbcomp -I); the keymap equals
#         `setxkbmap us` except the three letter keys and right Alt, which
#         is ISO_Level3_Shift on mod5; `kb show` detects it without state.
#
# Usage: test/xkb-usuml/test.sh   (needs docker; skips without it)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
readonly HERE REPO
readonly IMAGE="fedora:45"

if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available"
    exit 0
fi

read -r -d '' INNER <<'EOF' || true
set -uo pipefail
dnf install -y -q --setopt=install_weak_deps=False libxkbcommon-utils xkeyboard-config \
    xorg-x11-server-Xorg xorg-x11-drv-dummy setxkbmap xkbcomp xmodmap diffutils >/dev/null 2>&1 \
    || { echo "FAIL: dnf install"; exit 1; }
FAILED=0
ok()   { echo "ok:   $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }
expect() { if [[ "$3" == "$2" ]]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi; }

mkdir -p ~/.config
cp -r /src/xkb ~/.config/xkb

# --- sway (libxkbcommon) ---
if XKB_LOG_LEVEL=warning xkbcli compile-keymap --layout usuml > /tmp/keymap 2> /tmp/log; then
    ok "libxkbcommon compiles usuml from ~/.config/xkb"
else
    fail "compile: $(head -n 3 /tmp/log)"
fi
# Warnings about xkeyboard-config's own files (unknown XF86 keysyms) are not ours.
if grep -v '^xkbcommon: WARNING: \[XKB-107\] inet:' /tmp/log | grep . >/dev/null; then
    fail "warnings: $(grep -v 'inet:' /tmp/log | head -n 3)"
else
    ok "no warnings for usuml"
fi
if grep -F '"English (US, umlauts on AltGr)"' /tmp/keymap >/dev/null; then
    ok "the layout name (kb show in sway reads it)"
else
    fail "the layout name: $(grep -o 'name\[[^;]*' /tmp/keymap | head -n 1)"
fi

# The first way to type $2 in layout $1: keycode, level, modifiers (the
# layout name column dropped). Further lines differ only in listing: us
# keys are ALPHABETIC, the umlaut keys FOUR_LEVEL_SEMIALPHABETIC, whose
# explicit Shift+Lock entry how-to-type lists as one more way.
how() {
    xkbcli how-to-type --disable-compose --layout "$1" "$2" 2>/dev/null \
        | awk '$1 ~ /^[0-9]+$/ { sub(/^.*\[/, "["); print $0; exit }'
}
# keycode, key name, layout, level, modifiers per line.
for pair in adiaeresis=38:AC01:3 Adiaeresis=38:AC01:4 odiaeresis=32:AD09:3 Odiaeresis=32:AD09:4 \
    udiaeresis=30:AD07:3 Udiaeresis=30:AD07:4; do
    sym="${pair%=*}" want="${pair#*=}"
    got="$(xkbcli how-to-type --disable-compose --keysym --layout usuml "$sym" 2>/dev/null \
        | awk '$1 ~ /^[0-9]+$/ { for (i = 3; i <= NF; i++) if ($i == "[") { print $1 ":" $2 ":" $(i - 1); exit } }')"
    expect "$sym on ${want%%:*}" "$want" "$got"
done
[[ -n "$(how us 0x61)" ]] || fail "how-to-type printed nothing for a"
same=1
for ((c = 0x20; c <= 0x7e; c++)); do
    hex="$(printf '0x%x' "$c")"
    if [[ "$(how us "$hex")" != "$(how usuml "$hex")" ]]; then
        fail "ASCII $hex types differently from us: $(how usuml "$hex" | head -n 2)"
        same=0
    fi
done
((same)) && ok "every ASCII character is typed as in us"
if xkbcli how-to-type --disable-compose --keysym --layout usuml ISO_Level3_Shift 2>/dev/null | grep '^108 *RALT ' >/dev/null; then
    ok "right Alt is ISO_Level3_Shift (sway)"
else
    fail "right Alt is not ISO_Level3_Shift (sway)"
fi

# --- X (Xorg's dummy driver, the real kb) ---
printf 'Section "Device"\n    Identifier "dummy"\n    Driver "dummy"\nEndSection\n' > /tmp/xorg.conf
Xorg :99 -config /tmp/xorg.conf -noreset -nolisten tcp -logfile /tmp/xorg.log >/dev/null 2>&1 &
for _ in $(seq 50); do xmodmap -display :99 -pm >/dev/null 2>&1 && break; sleep 0.1; done
export DISPLAY=:99 HOME=/root XDG_RUNTIME_DIR=/tmp/run XDG_CACHE_HOME=/tmp/cache
mkdir -p /tmp/run
# key <RALT> of the server keymap (xkbcomp's dump).
ralt() { xkbcomp -w0 :99 - 2>/dev/null | awk '/^ *key <RALT> \{/, /\};/'; }
/src/bin/kb de >/dev/null 2>&1
ralt > /tmp/de.ralt
/src/bin/kb us >/dev/null 2>&1
xmodmap -pke > /tmp/us.pke
if out="$(/src/bin/kb usuml 2>&1)"; then ok "kb usuml (X)"; else fail "kb usuml: $out"; fi
xmodmap -pke > /tmp/usuml.pke
expect "X: only a, o, u and right Alt differ from us" "30 32 38 108" \
    "$(diff /tmp/us.pke /tmp/usuml.pke | awk '/^> keycode/ { print $3 }' | tr '\n' ' ' | sed 's/ $//')"
expect "X: keycode 38" "a A a A adiaeresis Adiaeresis" "$(awk '$2 == 38 { print $4, $5, $6, $7, $8, $9 }' /tmp/usuml.pke)"
expect "X: keycode 32" "o O o O odiaeresis Odiaeresis" "$(awk '$2 == 32 { print $4, $5, $6, $7, $8, $9 }' /tmp/usuml.pke)"
expect "X: keycode 30" "u U u U udiaeresis Udiaeresis" "$(awk '$2 == 30 { print $4, $5, $6, $7, $8, $9 }' /tmp/usuml.pke)"
# The modifier map lists only the LVL3 key for mod5 (as in de): right Alt
# gets level 3 from its action, the same as de's AltGr.
ralt > /tmp/usuml.ralt
if [[ -s /tmp/de.ralt ]] && diff /tmp/de.ralt /tmp/usuml.ralt >/dev/null; then
    ok "X: right Alt is de's AltGr"
else
    fail "X: right Alt: $(diff /tmp/de.ralt /tmp/usuml.ralt | head -n 6)"
fi
rm -f "/tmp/run/kb-layout-:99"
expect "X: kb show detects usuml" "usuml" "$(/src/bin/kb show 2>&1)"
/src/bin/kb us >/dev/null 2>&1
rm -f "/tmp/run/kb-layout-:99"
expect "X: kb show after us" "us" "$(/src/bin/kb show 2>&1)"
exit "$FAILED"
EOF

docker run --rm --security-opt label=disable \
    -v "$REPO/xkb:/src/xkb:ro" -v "$REPO/bin:/src/bin:ro" -v "$REPO/console:/src/console:ro" \
    "$IMAGE" bash -c "$INNER"
