#!/usr/bin/env bash
#
# Runs bin/sunshine-session with a stub sunshine and a fake sysfs. In a sway
# session (SWAYSOCK set; DISPLAY is set there too) it must start Sunshine
# with wlroots capture and VA-API on the render node of the boot GPU, which
# sway renders on: nvenc cannot import sway's dmabufs, and the ScreenCast
# portal waits for an output picker. In an X session it must start Sunshine
# with its own settings. Arguments pass through.
#
# Usage: test/sunshine-session/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/sunshine-session"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly CALLS="$TMP/calls" SYSFS="$TMP/sys"
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

# add_gpu <render node> <boot_vga>
add_gpu() {
    mkdir -p "$SYSFS/class/drm/$1/device"
    echo "$2" > "$SYSFS/class/drm/$1/device/boot_vga"
}

# One field per argument.
write_stub() {
    cat > "$TMP/sunshine" <<EOF
#!/bin/sh
{ printf 'sunshine'; printf '|%s' "\$@"; echo; } > "$CALLS"
EOF
    chmod +x "$TMP/sunshine"
}

# run <env assignments...>: prints the stub's call.
run() {
    rm -f "$CALLS"
    env -u SWAYSOCK -u DISPLAY -u WAYLAND_DISPLAY \
        SUNSHINE_BIN="$TMP/sunshine" SUNSHINE_SESSION_SYSFS="$SYSFS" "$@" \
        "$SCRIPT" extra=1 > /dev/null 2>&1 || echo "exit $?" > "$CALLS"
    cat "$CALLS" 2>/dev/null
}

main() {
    write_stub
    # Intel boot GPU second in the list, NVIDIA first.
    add_gpu renderD128 0
    add_gpu renderD129 1

    expect "sway: wlr capture, vaapi on the boot GPU" \
        "sunshine|capture=wlr|encoder=vaapi|adapter_name=/dev/dri/renderD129|extra=1" \
        "$(run SWAYSOCK=/run/user/1000/sway-ipc.sock WAYLAND_DISPLAY=wayland-1 DISPLAY=:1)"
    expect "X: Sunshine's own settings" \
        "sunshine|extra=1" \
        "$(run DISPLAY=:0)"
    # sway-autostart's end_session_with_sway leaves it empty in D-Bus.
    expect "X: empty SWAYSOCK is no sway session" \
        "sunshine|extra=1" \
        "$(run SWAYSOCK= DISPLAY=:0)"

    rm -rf "$SYSFS"
    add_gpu renderD128 0
    expect "sway without a boot GPU: no adapter" \
        "sunshine|capture=wlr|encoder=vaapi|extra=1" \
        "$(run SWAYSOCK=/run/user/1000/sway-ipc.sock WAYLAND_DISPLAY=wayland-1)"

    exit "$FAILED"
}

main "$@"
