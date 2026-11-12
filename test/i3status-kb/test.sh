#!/usr/bin/env bash
#
# Feeds i3bar click events to bin/i3status-kb with stubs for i3status, kb,
# i3-msg and swaymsg (through bin/wm-msg), and checks which commands the
# clicks run.
#
# Usage: test/i3status-kb/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/i3status-kb"
readonly WM_MSG="$HERE/../../bin/wm-msg"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly CALLS="$TMP/calls" ACTIVE="$TMP/active" TAILSCALE="$TMP/tailscale"
readonly SETTLE_S=0.5
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

write_stubs() {
    mkdir -p "$TMP/home/bin" "$TMP/stubs"
    cat > "$TMP/stubs/i3status" <<'EOF'
#!/bin/sh
echo '{"version":1}'
echo '['
echo '[{"name":"wireless","instance":"_first_","full_text":"W: up"}]'
while sleep 1; do echo ',[{"name":"wireless","instance":"_first_","full_text":"W: up"}]'; done
EOF
    # shellcheck disable=SC2016 # $* and $1 belong to the stub.
    printf '#!/bin/sh\necho "kb $*" >> %s\n[ "$1" = show ] && echo us\nexit 0\n' "$CALLS" > "$TMP/home/bin/kb"
    # One field per argument: i3-msg reads options anywhere in its arguments.
    local tool
    for tool in i3-msg swaymsg; do
        cat > "$TMP/stubs/$tool" <<EOF
#!/bin/sh
{ printf '$tool'; printf '|%s' "\$@"; echo; } >> "$CALLS"
EOF
        chmod +x "$TMP/stubs/$tool"
    done
    ln -sf "$(readlink -f "$WM_MSG")" "$TMP/home/bin/wm-msg"
    # nmcli prints the active connections from ACTIVE (`nmcli -t` format);
    # "fail" makes it fail like a system without NetworkManager.
    cat > "$TMP/stubs/nmcli" <<EOF
#!/bin/sh
[ "\$(cat "$ACTIVE")" = fail ] && exit 1
cat "$ACTIVE"
EOF
    printf 'Wired:802-3-ethernet\npvpn-killswitch-ipv6:dummy\n' > "$ACTIVE"
    # tailscale prints its BackendState from TAILSCALE; "none" makes it fail
    # like a stopped or missing tailscaled.
    cat > "$TMP/stubs/tailscale" <<EOF
#!/bin/sh
state="\$(cat "$TAILSCALE")"
[ "\$state" = none ] && exit 1
printf '{\n  "Version": "1.90.0",\n  "BackendState": "%s",\n  "Peer": {}\n}\n' "\$state"
EOF
    echo none > "$TAILSCALE"
    chmod +x "$TMP/stubs/i3status" "$TMP/home/bin/kb" "$TMP/stubs/nmcli" "$TMP/stubs/tailscale"
}

click() {
    printf '{"name":"%s","instance":"%s","button":%s,"modifiers":[],"x":10,"y":5}\n' "$1" "$2" "$3"
}

# The first status array the script prints. MODE is what `pwr mode` prints;
# empty makes it fail like a system without a power profile daemon.
# BACKLIGHT is "<brightness> <max_brightness>" for a fake backlight device;
# empty means none.
status_line() {
    local mode="$1" backlight="${2:-}"
    rm -rf "$TMP/sys"
    mkdir -p "$TMP/sys/class/backlight"
    if [[ -n "$backlight" ]]; then
        mkdir -p "$TMP/sys/class/backlight/intel_backlight"
        echo "${backlight% *}" > "$TMP/sys/class/backlight/intel_backlight/brightness"
        echo "${backlight#* }" > "$TMP/sys/class/backlight/intel_backlight/max_brightness"
    fi
    if [[ -n "$mode" ]]; then
        # shellcheck disable=SC2016 # $1 belongs to the stub.
        printf '#!/bin/sh\n[ "$1" = mode ] && echo %s\n' "$mode" > "$TMP/home/bin/pwr"
    else
        printf '#!/bin/sh\nexit 1\n' > "$TMP/home/bin/pwr"
    fi
    chmod +x "$TMP/home/bin/pwr"
    I3STATUS_KB_SYSFS="$TMP/sys" HOME="$TMP/home" PATH="$TMP/stubs:${SYSTEM_PATH:-$PATH}" timeout 3 "$SCRIPT" < /dev/null 2>/dev/null | sed -n 3p || true
}

# Runs i3status-kb with the given click lines on stdin; prints the calls
# made other than `kb show`. An X session; sway too when SWAYSOCK is set.
run_clicks() {
    : > "$CALLS"
    {
        echo '['
        local line
        for line in "$@"; do
            echo "$line,"
            sleep 0.1
        done
        sleep "$SETTLE_S"
    } | env -u SWAYSOCK DISPLAY=:0 ${SWAYSOCK:+SWAYSOCK="$SWAYSOCK"} HOME="$TMP/home" PATH="$TMP/stubs:$PATH" \
        timeout 5 "$SCRIPT" > /dev/null 2>&1 || true
    grep -v '^kb show' "$CALLS" | tr '\n' ';' | sed 's/;$//'
}

main() {
    write_stubs
    local nmrs="i3-msg|-q|exec --no-startup-id nmrs-gui"

    expect "left click on wireless opens nmrs-gui" "$nmrs" "$(run_clicks "$(click wireless _first_ 1)")"
    expect "left click on ethernet opens nmrs-gui" "$nmrs" "$(run_clicks "$(click ethernet _first_ 1)")"
    expect "right click on wireless does nothing" "" "$(run_clicks "$(click wireless _first_ 3)")"
    expect "click on another block does nothing" "" "$(run_clicks "$(click battery _first_ 1)")"
    expect "left click on volume opens pavucontrol" "i3-msg|-q|exec --no-startup-id pavucontrol" \
        "$(run_clicks "$(click volume default.Master.0 1)")"
    expect "right click on volume does nothing" "" "$(run_clicks "$(click volume default.Master.0 3)")"
    # sway accepts --no-startup-id and ignores it.
    expect "sway: nmrs-gui through swaymsg" "swaymsg|-q|exec --no-startup-id nmrs-gui" \
        "$(SWAYSOCK=/run/sway.sock run_clicks "$(click wireless _first_ 1)")"
    expect "sway: pavucontrol through swaymsg" "swaymsg|-q|exec --no-startup-id pavucontrol" \
        "$(SWAYSOCK=/run/sway.sock run_clicks "$(click volume default.Master.0 1)")"
    expect "left click on kb still cycles the layout" "kb next" "$(run_clicks "$(click kb "" 1)")"
    expect "right click on kb still goes back" "kb prev" "$(run_clicks "$(click kb "" 3)")"

    local wireless='{"name":"wireless","instance":"_first_","full_text":"W: up"}'
    local vpn_off='{"name":"vpn","full_text":"VPN: off"}'
    local kb='{"name":"kb","full_text":"KB: us"}'
    expect "the power mode follows the layout block" \
        "[{\"name\":\"kb\",\"full_text\":\"KB: us\"},{\"name\":\"power_mode\",\"full_text\":\"PWR: battery\"},$vpn_off,$wireless]" \
        "$(status_line battery)"
    expect "no power mode block without a daemon" \
        "[{\"name\":\"kb\",\"full_text\":\"KB: us\"},$vpn_off,$wireless]" \
        "$(status_line "")"
    expect "the screen brightness follows the power mode, rounded" \
        "[{\"name\":\"kb\",\"full_text\":\"KB: us\"},{\"name\":\"power_mode\",\"full_text\":\"PWR: battery\"},{\"name\":\"backlight\",\"full_text\":\"☀: 80%\"},$vpn_off,$wireless]" \
        "$(status_line battery "31024 38787")"

    printf 'Wired:802-3-ethernet\nProtonVPN DE#853:wireguard\npvpn-killswitch-ipv6:dummy\n' > "$ACTIVE"
    expect "an active WireGuard connection is the VPN, in green" \
        "[$kb,{\"name\":\"vpn\",\"full_text\":\"VPN: ProtonVPN DE#853\",\"color\":\"#859900\"},$wireless]" \
        "$(status_line "")"
    printf 'Work\\:"office":vpn\n' > "$ACTIVE"
    expect "an OpenVPN connection; colon and quotes kept" \
        "[$kb,{\"name\":\"vpn\",\"full_text\":\"VPN: Work:\\\"office\\\"\",\"color\":\"#859900\"},$wireless]" \
        "$(status_line "")"
    echo Running > "$TAILSCALE"
    printf 'Wired:802-3-ethernet\nProtonVPN DE#853:wireguard\n' > "$ACTIVE"
    expect "Tailscale next to another VPN" \
        "[$kb,{\"name\":\"vpn\",\"full_text\":\"VPN: ProtonVPN DE#853, Tailscale\",\"color\":\"#859900\"},$wireless]" \
        "$(status_line "")"
    printf 'Wired:802-3-ethernet\n' > "$ACTIVE"
    expect "Tailscale alone" \
        "[$kb,{\"name\":\"vpn\",\"full_text\":\"VPN: Tailscale\",\"color\":\"#859900\"},$wireless]" \
        "$(status_line "")"
    echo Stopped > "$TAILSCALE"
    expect "stopped Tailscale is off" "[$kb,$vpn_off,$wireless]" "$(status_line "")"

    # ~/bin/syncthing-status: its text after the VPN; no block when it
    # fails (Syncthing not installed).
    printf '#!/bin/sh\necho "42%%"\n' > "$TMP/home/bin/syncthing-status"
    chmod +x "$TMP/home/bin/syncthing-status"
    expect "Syncthing after the VPN" "[$kb,$vpn_off,{\"name\":\"syncthing\",\"full_text\":\"ST: 42%\"},$wireless]" \
        "$(status_line "")"
    printf '#!/bin/sh\nexit 1\n' > "$TMP/home/bin/syncthing-status"
    expect "no Syncthing block without Syncthing" "[$kb,$vpn_off,$wireless]" "$(status_line "")"
    rm "$TMP/home/bin/syncthing-status"
    echo none > "$TAILSCALE"

    echo fail > "$ACTIVE"
    # Only the stubs and basic tools on PATH: a real tailscale must not count.
    mv "$TMP/stubs/tailscale" "$TMP/tailscale.off"
    mkdir -p "$TMP/sysbin"
    local tool
    for tool in env bash timeout grep mkfifo mktemp rm sleep cat; do ln -sf "$(command -v "$tool")" "$TMP/sysbin/$tool"; done
    expect "no VPN block without NetworkManager and Tailscale" "[$kb,$wireless]" "$(SYSTEM_PATH="$TMP/sysbin" status_line "")"
    mv "$TMP/tailscale.off" "$TMP/stubs/tailscale"

    exit "$FAILED"
}

main "$@"
