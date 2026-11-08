#!/usr/bin/env bash
#
# Swap two windows with the i3 bindings: $mod+m marks the focused window
# (the title bar shows [swap]), $mod+Shift+m swaps the focused window with
# the marked one and clears the mark. Runs i3 with the repo config on Xvfb in a Fedora container and
# presses the keys with xdotool.
#
# Usage: test/i3-swap/test.sh   (needs docker; skips without it)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG="$HERE/../../.config/i3/config"
readonly IMAGE="fedora:45"

if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available"
    exit 0
fi

# Runs inside the container. Prints ok/FAIL lines; exits non-zero on a FAIL.
read -r -d '' INNER <<'EOF' || true
set -uo pipefail
dnf install -y -q i3 xorg-x11-server-Xvfb xterm xdotool python3 >/dev/null 2>&1 || { echo "FAIL: dnf install"; exit 1; }
export DISPLAY=:1
Xvfb :1 -screen 0 1280x800x24 >/dev/null 2>&1 &
sleep 1
i3 -c /tmp/i3config >/tmp/i3.log 2>&1 &
for _ in $(seq 1 50); do i3-msg -t get_version >/dev/null 2>&1 && break; sleep 0.1; done

FAILED=0
ok()   { echo "ok:   $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }
# Window titles of the current workspace, left to right.
order() {
    i3-msg -t get_tree | python3 -c '
import json, sys
def leaves(n):
    if n.get("window") and n.get("name"): yield n["name"]
    for c in n.get("nodes", []): yield from leaves(c)
tree = json.load(sys.stdin)
ws = [w for o in tree["nodes"] for c in o["nodes"] for w in c["nodes"] if w.get("type") == "workspace"]
print(" ".join(t for w in ws for t in leaves(w) if t in ("A", "B")))'
}
marks() { i3-msg -t get_marks | tr -d '[]"'; }

xterm -T A -e sleep 600 & sleep 1
xterm -T B -e sleep 600 & sleep 1
[[ "$(order)" == "A B" ]] && ok "start: A B" || fail "start: $(order)"

i3-msg -q '[title="^A$"] focus'
xdotool key super+m; sleep 0.3
# No leading underscore: i3 hides such marks, and the title shows [swap].
[[ "$(marks)" == "swap" ]] && ok "Mod+m marks the focused window, visibly" || fail "marks: $(marks)"

i3-msg -q '[title="^B$"] focus'
xdotool key super+shift+m; sleep 0.3
[[ "$(order)" == "B A" ]] && ok "Mod+Shift+m swaps the windows" || fail "after swap: $(order)"
[[ -z "$(marks)" ]] && ok "the mark is gone after the swap" || fail "marks left: $(marks)"

i3-msg -q '[title="^A$"] focus'
xdotool key super+m; sleep 0.3; xdotool key super+m; sleep 0.3
[[ -z "$(marks)" ]] && ok "Mod+m again removes the mark" || fail "toggle: $(marks)"

grep -i 'error' /tmp/i3.log | grep -v -i 'status_command\|i3status\|exec' | head -3 | sed 's/^/i3: /'
exit "$FAILED"
EOF

container="$(docker create "$IMAGE" bash -c "$INNER")"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT
# docker cp, not a bind mount: SELinux hosts would deny the container.
docker cp "$CONFIG" "$container:/tmp/i3config"
docker start -a "$container"
