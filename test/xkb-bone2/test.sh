#!/usr/bin/env bash
#
# bone2 as an XKB layout for sway (Wayland has no xmodmap):
# xkb/symbols/bone2 is generated from .Xmodmap by xkb/xmodmap-to-xkb.py and
# must equal a fresh run. In a Fedora container libxkbcommon then compiles
# it from ~/.config/xkb (bootstrap links xkb/ there; sway finds it there)
# with one group only, and check.py presses the modifier keys and compares
# every key and level with its .Xmodmap column.
#
# Usage: test/xkb-bone2/test.sh   (the container part needs docker; skips without it)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
readonly HERE REPO
readonly GENERATOR="$REPO/xkb/xmodmap-to-xkb.py" SYMBOLS="$REPO/xkb/symbols/bone2"
readonly IMAGE="fedora:45"
TMP="$(mktemp -d)"
readonly TMP
container=""
trap 'rm -rf "$TMP"; [[ -z "$container" ]] || docker rm -f "$container" >/dev/null 2>&1 || true' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

# The committed layout is the generator's output, as for console/bone2.map.
if python3 "$GENERATOR" "$REPO/.Xmodmap" > "$TMP/fresh" 2> "$TMP/gen.err" \
    && diff -u "$SYMBOLS" "$TMP/fresh" > "$TMP/diff" 2>&1; then
    ok "xkb/symbols/bone2 equals a fresh generator run"
else
    fail "xkb/symbols/bone2 is not the generator's output: $(cat "$TMP/gen.err" "$TMP/diff" 2>/dev/null | head -c 600)"
fi

if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available (compile and level checks)"
    exit "$FAILED"
fi

# Runs inside the container. Prints ok/FAIL lines; exits non-zero on a FAIL.
read -r -d '' INNER <<'EOF' || true
set -uo pipefail
dnf install -y -q --setopt=install_weak_deps=False libxkbcommon-utils xkeyboard-config python3 >/dev/null 2>&1 \
    || { echo "FAIL: dnf install"; exit 1; }
FAILED=0
ok()   { echo "ok:   $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }

mkdir -p ~/.config
cp -r /tmp/src/xkb ~/.config/xkb 2>/dev/null

# The default include path, as in sway; the sway config adds the option.
for options in "" ctrl:swap_lalt_lctl; do
    label="libxkbcommon compiles bone2 from ~/.config/xkb${options:+ with $options}"
    if ! XKB_LOG_LEVEL=warning xkbcli compile-keymap --layout bone2 --options "$options" > /tmp/keymap 2> /tmp/log; then
        fail "$label: $(head -n 3 /tmp/log)"
        continue
    fi
    ok "$label"
    if grep -i bone2 /tmp/log >/dev/null; then
        fail "warnings for bone2${options:+ with $options}: $(grep -i bone2 /tmp/log | head -n 3)"
    fi
done

if [[ ! -s /tmp/keymap ]]; then
    fail "no keymap to check for groups"
elif grep -E 'symbols\[(2|Group2)\]' /tmp/keymap >/dev/null; then
    fail "the keymap has a second group"
else
    ok "the keymap has no second group"
fi

python3 /tmp/src/check.py /tmp/src/.Xmodmap || FAILED=1
exit "$FAILED"
EOF

mkdir -p "$TMP/src"
cp "$REPO/.Xmodmap" "$HERE/check.py" "$TMP/src/"
[[ ! -d "$REPO/xkb" ]] || cp -r "$REPO/xkb" "$TMP/src/xkb"
container="$(docker create "$IMAGE" bash -c "$INNER")"
# docker cp, not a bind mount: SELinux hosts would deny the container.
docker cp "$TMP/src" "$container:/tmp/src"
docker start -a "$container" || FAILED=1
exit "$FAILED"
