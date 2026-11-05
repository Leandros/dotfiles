#!/usr/bin/env bash
#
# Checks that i3 alone binds the media keys. X lets one client grab a key;
# a second key daemon (xbindkeys) took them from i3 and its brightness
# binds needed sudo, which has no password prompt from a hotkey.
#
# Usage: test/media-keys/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="$HERE/../.."
readonly I3_CONFIG="$ROOT/.config/i3/config"
readonly XPROFILE="$ROOT/.xprofile"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

# Prints the command i3 runs for a bare key, or nothing.
i3_bind() {
    sed -n "s/^bindsym $1 exec //p" "$I3_CONFIG"
}

expect_bind() {
    local key="$1" want="$2" got
    got="$(i3_bind "$key")"
    if [[ "$got" == "$want" ]]; then
        ok "i3 $key"
    else
        fail "i3 $key: want '$want', got '$got'"
    fi
}

# USR1 makes i3status redraw, so the bar shows the new brightness now.
expect_bind XF86MonBrightnessUp "brightnessctl set +5% && pkill -USR1 -x i3status"
expect_bind XF86MonBrightnessDown "brightnessctl set 5%- && pkill -USR1 -x i3status"
expect_bind XF86AudioRaiseVolume "amixer set Master 5%+"
expect_bind XF86AudioLowerVolume "amixer set Master 5%-"
expect_bind XF86AudioMute "amixer set Master toggle"
# Capture is the default source through PipeWire, so this mutes the
# selected microphone.
expect_bind XF86AudioMicMute "amixer set Capture toggle"
# arandr sends no startup notification; without --no-startup-id the cursor
# spins for a minute.
expect_bind XF86Display "--no-startup-id arandr"

if grep -qE '^[^#]*\bxbindkeys\b' "$XPROFILE"; then
    fail ".xprofile starts xbindkeys, which takes the media keys from i3"
else
    ok ".xprofile starts no second key daemon"
fi

if grep -qx 'for_window \[instance="^pavucontrol$"\] floating enable' "$I3_CONFIG"; then
    ok "pavucontrol floats"
else
    fail "no floating rule for pavucontrol"
fi

for f in .xbindkeysrc .backlight.sh; do
    if [[ -e "$ROOT/$f" ]]; then fail "$f still in the repository"; else ok "$f removed"; fi
done

exit "$FAILED"
