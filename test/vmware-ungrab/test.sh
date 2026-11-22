#!/usr/bin/env bash
#
# bin/vmware-ungrab:
#   - watch: from sway's focus events (a fake swaymsg prints them), it
#     releases VMware's grab once each time the focus leaves a VMware
#     window (by window focus or by a workspace switch), never while the
#     focus stays on VMware or moves between other windows;
#   - release (fedora:45, Xvfb): a client that holds the pointer grab, as
#     VMware Workstation does while the guest has the input, sees a motion
#     outside its window; with no point outside, nothing moves.
#
# Needs docker for the X part.
#
# Usage: test/vmware-ungrab/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
readonly SCRIPT="$ROOT/bin/vmware-ungrab"
readonly IMAGE="fedora:45"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }
expect() {
    if [[ "$2" == "$3" ]]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi
}

# A window focus event for a window (app_id, X11 class).
window_event() {
    printf '{"change":"focus","container":{"id":%s,"type":"con","focused":true,"app_id":%s,"window_properties":%s,"nodes":[],"floating_nodes":[]}}\n' \
        "$1" "$2" "$3"
}

# A workspace focus event; the new workspace's focused leaf has app_id $2,
# or the workspace itself is focused (empty) when $2 is "empty".
workspace_event() {
    local leaf
    if [[ "$2" == empty ]]; then
        printf '{"change":"focus","current":{"id":%s,"type":"workspace","focused":true,"nodes":[],"floating_nodes":[]}}\n' "$1"
        return
    fi
    leaf="{\"id\":$(($1 + 100)),\"type\":\"con\",\"focused\":true,\"app_id\":$2,\"nodes\":[],\"floating_nodes\":[]}"
    printf '{"change":"focus","current":{"id":%s,"type":"workspace","focused":false,"nodes":[{"id":%s,"type":"con","focused":false,"nodes":[%s],"floating_nodes":[]}],"floating_nodes":[]}}\n' \
        "$1" "$(($1 + 50))" "$leaf"
}

# Runs the watcher on the events in $TMP/events; prints how often it
# released.
run_watch() {
    mkdir -p "$TMP/bin"
    printf '#!/bin/sh\ncat "%s"\n' "$TMP/events" > "$TMP/bin/swaymsg"
    printf '#!/bin/sh\necho release >> "%s"\n' "$TMP/releases" > "$TMP/bin/release"
    chmod +x "$TMP/bin/swaymsg" "$TMP/bin/release"
    : > "$TMP/releases"
    PATH="$TMP/bin:$PATH" VMWARE_UNGRAB_RELEASE="$TMP/bin/release" python3 -I "$SCRIPT" watch
    wc -l < "$TMP/releases" | tr -d ' '
}

test_watch() {
    {
        window_event 1 '"Alacritty"' 'null'
        window_event 2 '"Vmware"' 'null'
        window_event 2 '"Vmware"' 'null'
        window_event 3 '"Alacritty"' 'null'
    } > "$TMP/events"
    expect "focus from VMware to another window: one release" "1" "$(run_watch)"

    {
        window_event 2 '"Vmware"' 'null'
        workspace_event 10 '"firefox"'
    } > "$TMP/events"
    expect "workspace switch away from VMware: one release" "1" "$(run_watch)"

    {
        window_event 2 '"Vmware"' 'null'
        workspace_event 11 empty
    } > "$TMP/events"
    expect "switch to an empty workspace: one release" "1" "$(run_watch)"

    {
        window_event 2 '"Vmware"' 'null'
        window_event 4 '"Vmware"' 'null'
        workspace_event 12 '"Vmware"'
    } > "$TMP/events"
    expect "focus stays on VMware windows: no release" "0" "$(run_watch)"

    {
        window_event 1 '"Alacritty"' 'null'
        workspace_event 10 '"firefox"'
        window_event 3 '"foot"' 'null'
    } > "$TMP/events"
    expect "focus between other windows: no release" "0" "$(run_watch)"

    # sway's own Xwayland: no app_id, the X11 class instead.
    {
        window_event 2 'null' '{"class":"Vmware","instance":"vmware"}'
        window_event 3 '"Alacritty"' 'null'
    } > "$TMP/events"
    expect "VMware on sway's Xwayland (class): one release" "1" "$(run_watch)"
}

# The X part, inside the container: Xvfb at 3072x1920, a window with
# VMware's class at 0,0 3066x1845 that holds the pointer grab, then
# release. The grabbing client prints the root position of the motion.
read -r -d '' INNER <<'EOF' || true
set -euo pipefail
dnf install -y -q python3 python3-xlib xorg-x11-server-Xvfb >/dev/null 2>&1
Xvfb :5 -screen 0 3072x1920x24 >/dev/null 2>&1 &
export DISPLAY=:5
for _ in $(seq 50); do python3 -I -c 'from Xlib import display; display.Display()' 2>/dev/null && break; sleep 0.1; done
cat > /tmp/grabber.py <<'PY'
import sys
from Xlib import X, display
w_width, w_height = int(sys.argv[1]), int(sys.argv[2])
d = display.Display()
root = d.screen().root
w = root.create_window(0, 0, w_width, w_height, 0, X.CopyFromParent)
w.set_wm_class("vmware", "Vmware")
w.map()
d.sync()
status = w.grab_pointer(False, X.PointerMotionMask, X.GrabModeAsync, X.GrabModeAsync, X.NONE, X.NONE, X.CurrentTime)
print("grab", status == X.GrabSuccess, flush=True)
d.sync()
while True:
    e = d.next_event()
    if e.type == X.MotionNotify:
        print("motion", e.root_x, e.root_y, flush=True)
        break
PY
echo "== partial"
timeout 5 python3 -I /tmp/grabber.py 3066 1845 > /tmp/partial.out &
grabber=$!
sleep 1
python3 -I /src/vmware-ungrab release
wait "$grabber" || true
cat /tmp/partial.out
echo "== full"
timeout 3 python3 -I /tmp/grabber.py 3072 1920 > /tmp/full.out &
grabber=$!
sleep 1
python3 -I /src/vmware-ungrab release 2>&1 || echo "release failed"
wait "$grabber" || true
cat /tmp/full.out
EOF

test_release() {
    command -v docker >/dev/null || { echo "SKIP: no docker for the X part"; return; }
    local name out
    name="dotfiles-vmware-ungrab-$$"
    docker create --name "$name" "$IMAGE" bash -c "$INNER" > /dev/null
    # Copied, not mounted: SELinux denies bind mounts.
    mkdir -p "$TMP/src"
    cp "$SCRIPT" "$TMP/src/"
    docker cp "$TMP/src" "$name:/src" > /dev/null
    out="$(docker start -a "$name" 2>&1)"
    docker rm -f "$name" > /dev/null 2>&1 || true
    local partial full
    partial="$(sed -n '/^== partial$/,/^== full$/p' <<< "$out")"
    full="$(sed -n '/^== full$/,$p' <<< "$out")"
    expect "the test client holds the pointer grab" "grab True" "$(grep '^grab' <<< "$partial")"
    # Bottom right, the corner VMware's window does not cover.
    expect "release: motion outside VMware's window" "motion 3071 1919" "$(grep '^motion' <<< "$partial")"
    expect "window covers the screen: no motion" "" "$(grep '^motion' <<< "$full" || true)"
    if grep -q 'release failed' <<< "$full"; then
        fail "release fails when no point is outside: $full"
    else
        ok "release succeeds without a point outside (nothing to do)"
    fi
}

main() {
    if [[ ! -f "$SCRIPT" ]]; then
        fail "bin/vmware-ungrab is missing"
        exit 1
    fi
    test_watch
    test_release
    exit "$FAILED"
}

main "$@"
