#!/usr/bin/env bash
#
# Checks that the i3 session activates graphical-session.target, which
# xdg-desktop-portal requires since Fedora 45 (Requisite=). Without it the
# portal does not start and Firefox does not follow `theme`.
#
# Usage: test/i3-session/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="$HERE/../.."
readonly TARGET="$ROOT/.config/systemd/user/i3-session.target"
readonly XPROFILE="$ROOT/.xprofile"
readonly I3_CONFIG="$ROOT/.config/i3/config"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

has() {
    local name="$1" file="$2" pattern="$3"
    if [[ -f "$file" ]] && grep -qE "$pattern" "$file"; then ok "$name"; else fail "$name"; fi
}

has "target binds graphical-session.target" "$TARGET" '^BindsTo=graphical-session\.target$'
has "target pulls in graphical-session-pre.target" "$TARGET" '^Wants=graphical-session-pre\.target$'
if [[ -f "$TARGET" ]] && command -v systemd-analyze >/dev/null; then
    if out="$(systemd-analyze --user verify "$TARGET" 2>&1)"; then ok "systemd-analyze verify"; else fail "systemd-analyze: $out"; fi
fi

# DISPLAY reaches the user manager in xinitrc.d (50-systemd-user.sh) before
# the 90-xprofile hook, so the portal backends can open the display.
has ".xprofile starts the target" "$XPROFILE" '^systemctl --user --no-block start i3-session\.target'
has "exiting i3 stops the target first" "$I3_CONFIG" "systemctl --user stop i3-session\.target; i3-msg exit"

exit "$FAILED"
