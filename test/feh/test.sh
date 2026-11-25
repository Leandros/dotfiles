#!/usr/bin/env bash
#
# .config/feh: feh (Fedora 45) on Xorg's dummy driver with the config as
# ~/.config/feh. The themes file's feh theme fits a small image to the
# window (zoom above 1); Ctrl+wheel up zooms in, Ctrl+wheel down out.
# The zoom is read from the window title (%z, 1 = 100 %).
#
# Usage: test/feh/test.sh   (needs docker; skips without it)
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO

if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available"
    exit 0
fi

read -r -d '' INNER <<'IN' || true
set -uo pipefail
dnf install -y -q --setopt=install_weak_deps=False feh xorg-x11-server-Xorg xorg-x11-drv-dummy \
    xdotool ImageMagick >/dev/null 2>&1 || { echo "FAIL: dnf install"; exit 1; }
FAILED=0
ok()   { echo "ok:   $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }

printf 'Section "Device"\n    Identifier "dummy"\n    Driver "dummy"\nEndSection\n' > /tmp/xorg.conf
Xorg :99 -config /tmp/xorg.conf -noreset -nolisten tcp -logfile /tmp/xorg.log >/dev/null 2>&1 &
export DISPLAY=:99
for _ in $(seq 50); do xdotool getdisplaygeometry >/dev/null 2>&1 && break; sleep 0.1; done
mkdir -p ~/.config
cp -r /src/feh ~/.config/feh
magick -size 100x100 xc:red /tmp/a.png
magick -size 100x100 xc:blue /tmp/b.png

feh --geometry 400x400 --title 'zoom=%z file=%n' /tmp/a.png /tmp/b.png &
for _ in $(seq 50); do win="$(xdotool search --name '^zoom=' 2>/dev/null | head -n 1)"; [[ -n "$win" ]] && break; sleep 0.1; done
title() { sleep 0.5; xdotool getwindowname "$win"; }
zoom() { title | sed -n 's/^zoom=\([0-9.]*\).*/\1/p'; }
xdotool mousemove --window "$win" 200 200

z0="$(zoom)"
if awk -v z="$z0" 'BEGIN { exit !(z > 1) }'; then ok "the feh theme fits a small image to the window (zoom $z0)"; else fail "fit: $(title)"; fi
xdotool keydown ctrl click 4 keyup ctrl
z1="$(zoom)"
if awk -v a="$z0" -v b="$z1" 'BEGIN { exit !(b > a) }'; then ok "Ctrl+wheel up zooms in ($z0 -> $z1)"; else fail "Ctrl+wheel up: $z0 -> $(title)"; fi
xdotool keydown ctrl click 5 keyup ctrl
xdotool keydown ctrl click 5 keyup ctrl
z2="$(zoom)"
if awk -v a="$z1" -v b="$z2" 'BEGIN { exit !(b < a) }'; then ok "Ctrl+wheel down zooms out ($z1 -> $z2)"; else fail "Ctrl+wheel down: $z1 -> $(title)"; fi
case "$(title)" in *file=a.png) ok "Ctrl+wheel stays on the image" ;; *) fail "Ctrl+wheel changed the image: $(title)" ;; esac
xdotool click 5
case "$(title)" in *file=b.png) ok "the wheel alone goes to the next image" ;; *) fail "wheel: $(title)" ;; esac
exit "$FAILED"
IN

docker run --rm --security-opt label=disable -v "$REPO/.config/feh:/src/feh:ro" fedora:45 bash -c "$INNER"
