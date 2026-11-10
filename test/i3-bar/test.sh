#!/usr/bin/env bash
#
# The i3bar fallback: the i3 config includes ~/.config/i3-bar.d/*.conf,
# where bootstrap.sh links .config/i3/i3bar.conf only when eww (the bar,
# ~/bin/bar) is not installed. Without the link i3 has no bar; with it, i3bar
# runs i3status-kb with the colors of the main config (variables reach the
# included file). Runs i3 with the repo config on Xvfb in a Fedora container.
#
# Usage: test/i3-bar/test.sh   (needs docker; skips without it)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly I3_DIR="$HERE/../../.config/i3"
readonly IMAGE="fedora:45"

if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available"
    exit 0
fi

# Runs inside the container. Prints ok/FAIL lines; exits non-zero on a FAIL.
read -r -d '' INNER <<'EOF' || true
set -uo pipefail
dnf install -y -q i3 xorg-x11-server-Xvfb python3 >/dev/null 2>&1 || { echo "FAIL: dnf install"; exit 1; }
export DISPLAY=:1
Xvfb :1 -screen 0 1280x800x24 >/dev/null 2>&1 &
sleep 1

FAILED=0
ok()   { echo "ok:   $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }

# Starts i3 with ~/.config/i3/config, prints `i3-msg -t get_bar_config`
# of the first bar (or the empty list), then stops i3.
bars() {
    i3 >/tmp/i3.log 2>&1 &
    local pid=$!
    for _ in $(seq 1 50); do i3-msg -t get_version >/dev/null 2>&1 && break; sleep 0.1; done
    local ids
    ids="$(i3-msg -t get_bar_config)"
    if [[ "$ids" == "[]" ]]; then
        echo "[]"
    else
        i3-msg -t get_bar_config "$(python3 -c 'import json,sys; print(json.load(sys.stdin)[0])' <<< "$ids")"
    fi
    i3-msg -q exit >/dev/null 2>&1 || true
    wait "$pid" 2>/dev/null || true
}

# eww installed: no link, no i3bar.
got="$(bars)"
[[ "$got" == "[]" ]] && ok "without the include: no i3bar" || fail "without the include: $got"

# No eww: bootstrap links the i3bar config into the include directory.
mkdir -p ~/.config/i3-bar.d
ln -s ~/.config/i3/i3bar.conf ~/.config/i3-bar.d/i3bar.conf
got="$(bars)"
field() { python3 -c "import json,sys; d=json.load(sys.stdin); print($1)" <<< "$got"; }
[[ "$(field 'd["status_command"]')" == *"i3status-kb"* ]] && ok "with the include: i3bar runs i3status-kb" || fail "status_command: $got"
[[ "$(field 'd["colors"]["focused_workspace_bg"]')" == "#859900" ]] && ok "colors from the main config's variables" || fail "colors: $got"

grep -iE 'error|invalid' /tmp/i3.log | grep -v -i 'status_command\|i3status\|exec\|nagbar\|child\|stdin' | head -3 | sed 's/^/i3: /'
exit "$FAILED"
EOF

# The config goes to ~/.config/i3 inside the container before the test.
container="$(docker create "$IMAGE" bash -c "mkdir -p ~/.config && cp -r /tmp/i3 ~/.config/i3 && $INNER")"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT
# docker cp, not a bind mount: SELinux hosts would deny the container.
docker cp "$I3_DIR" "$container:/tmp/i3"
docker start -a "$container"
