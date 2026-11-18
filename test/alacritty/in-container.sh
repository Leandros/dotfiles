#!/usr/bin/env bash
#
# Part 3 of test/alacritty/test.sh, inside fedora:45 with the repo files in
# /src: Alacritty 0.17 under Xvfb with the config linked as bootstrap does.
#
set -euo pipefail

failed=0
ok()   { printf 'ok:   %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; failed=1; }

# winit dlopens the X client libraries (desktops have them).
dnf install -y -q alacritty xorg-x11-server-Xvfb mesa-dri-drivers python3 \
    libXcursor libXi libXrandr libxkbcommon-x11 >/dev/null 2>&1 \
    || { echo "FAIL: dnf install"; exit 1; }
alacritty --version

export HOME=/root XDG_RUNTIME_DIR=/tmp/run DISPLAY=:1
mkdir -p "$XDG_RUNTIME_DIR" && chmod 0700 "$XDG_RUNTIME_DIR"
mkdir -p ~/.config/alacritty
ln -s /src/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
ln -s /src/.config/alacritty/themes ~/.config/alacritty/themes
ln -s /src/alacritty/linux.toml ~/.config/alacritty/linux.toml
# What bootstrap does before the first start: the link exists, dark.
ALACRITTY_THEME_LINK=~/.local/state/alacritty/theme.toml PATH=/usr/bin:/bin /src/bin/alacritty-theme apply

Xvfb :1 -screen 0 1280x800x24 >/dev/null 2>&1 &
for _ in $(seq 1 50); do [[ -e /tmp/.X11-unix/X1 ]] && break; sleep 0.1; done

log=/tmp/alacritty.log
alacritty -vv -e sleep 60 >"$log" 2>&1 &
apid=$!
sock=""
for _ in $(seq 1 100); do
    sock="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'Alacritty-*.sock' | head -n 1)"
    [[ -n "$sock" ]] && break
    sleep 0.1
done
if [[ -z "$sock" ]]; then
    fail "alacritty did not start: $(tail -n 5 "$log")"
    exit 1
fi
ok "alacritty runs under Xvfb"

# Config problems: Alacritty logs them as [ERROR] or [WARN] (a missing
# font, PragmataPro here, logs neither).
problems="$(grep -E '\[(ERROR|WARN)' "$log" || true)"
if [[ -z "$problems" ]]; then
    ok "no config warnings or errors"
else
    fail "log: $problems"
fi

get_config() { ALACRITTY_SOCKET="$sock" alacritty msg get-config; }
check_config() {
    python3 -I -c '
import json, sys
c = json.load(sys.stdin)
want_bg, want_dec = sys.argv[1], "None"
bg = c["colors"]["primary"]["background"]
dec = c["window"]["decorations"]
hints = len(c["hints"]["enabled"])
print(f"background={bg} decorations={dec} hints={hints}")
sys.exit(0 if (bg.lower() == want_bg and dec == want_dec and hints == 2) else 1)
' "$1"
}
if out="$(get_config | check_config '#002b36')"; then
    ok "runtime config: dark theme, linux.toml imported ($out)"
else
    fail "runtime config: $out"
fi

# The desktop turns light: the follower moves the link, Alacritty reloads.
mkdir -p /tmp/stub
printf '#!/bin/sh\necho "'"'"'prefer-light'"'"'"\n' >/tmp/stub/gsettings
chmod +x /tmp/stub/gsettings
PATH="/tmp/stub:/usr/bin:/bin" /src/bin/alacritty-theme apply
for _ in $(seq 1 50); do
    out="$(get_config | check_config '#fdf6e3')" && break
    sleep 0.1
done
if [[ "$out" == *"#fdf6e3"* || "$out" == *"#FDF6E3"* ]]; then
    ok "theme change reloads: light ($out)"
else
    fail "after the theme change: $out; log: $(grep -i reload "$log" | tail -n 2)"
fi
problems="$(grep -E '\[(ERROR|WARN)' "$log" || true)"
if [[ -z "$problems" ]]; then ok "no errors after the reload"; else fail "log after reload: $problems"; fi

kill "$apid" 2>/dev/null || true
exit "$failed"
