#!/usr/bin/env bash
#
# Tests the eww bar scripts (.config/eww/scripts) and ~/bin/bar with stubs:
# status-blocks drops the i3bar framing and keys the blocks by name, block-click does i3status-kb's
# clicks, block-tooltips (battery, VPN) and net-info build one JSON object
# per block, disk-info one entry per device, theme-mode and
# i3-workspaces follow changes, and bar opens one bar per output (tray on
# the primary one, height for Xft.dpi) and reopens them on output changes. cpu-info and
# mem-info read fake /proc and /sys files.
#
# Usage: test/eww/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPTS="$HERE/../../.config/eww/scripts"
readonly BAR="$HERE/../../bin/bar"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" HOME_DIR="$TMP/home"
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

# A stub that records "name args" and prints the file STUBS/name.out.
stub() {
    local name="$1" dir="${2:-$STUBS}"
    cat > "$dir/$name" <<EOF
#!/bin/sh
echo "$name \$*" >> "$CALLS"
[ -f "$STUBS/$name.out" ] && cat "$STUBS/$name.out"
exit 0
EOF
    chmod +x "$dir/$name"
}

# DISPLAY :7 and a runtime directory of the test: bar keeps its eww config
# per display there.
run() { HOME="$HOME_DIR" DISPLAY=:7 XDG_RUNTIME_DIR="$TMP/run" PATH="$STUBS:$PATH" "$@"; }

test_status_blocks() {
    # i3status-kb: header, "[", then status lines, later ones after ",".
    cat > "$HOME_DIR/bin/i3status-kb" <<'EOF'
#!/bin/sh
echo '{"version":1,"click_events":true}'
echo '['
echo '[{"name":"kb","full_text":"KB: de"}]'
echo ',[{"name":"kb","full_text":"KB: us"}]'
EOF
    chmod +x "$HOME_DIR/bin/i3status-kb"
    expect "status-blocks: one object per line, blocks by name" \
        '{"kb":{"name":"kb","full_text":"KB: de"}};{"kb":{"name":"kb","full_text":"KB: us"}}' \
        "$(run "$SCRIPTS/status-blocks" | paste -sd ';')"
}

test_block_click() {
    stub kb "$HOME_DIR/bin"
    stub i3-msg
    stub pkill
    : > "$CALLS"
    run "$SCRIPTS/block-click" kb left
    expect "kb left: next layout, then redraw" "kb next;pkill -USR1 -x i3status" "$(paste -sd ';' "$CALLS")"
    : > "$CALLS"
    run "$SCRIPTS/block-click" kb right
    expect "kb right: previous layout" "kb prev;pkill -USR1 -x i3status" "$(paste -sd ';' "$CALLS")"
    : > "$CALLS"
    run "$SCRIPTS/block-click" wireless left
    expect "wireless: nmrs-gui through i3" "i3-msg -q exec --no-startup-id nmrs-gui" "$(cat "$CALLS")"
    : > "$CALLS"
    run "$SCRIPTS/block-click" volume left
    expect "volume: pavucontrol through i3" "i3-msg -q exec --no-startup-id pavucontrol" "$(cat "$CALLS")"
    : > "$CALLS"
    run "$SCRIPTS/block-click" time left
    expect "other blocks: nothing" "" "$(cat "$CALLS")"
}

test_block_tooltips() {
    cat > "$STUBS/upower" <<'EOF'
#!/bin/sh
case "$1" in
    -e) echo /org/freedesktop/UPower/devices/battery_BAT0 ;;
    -i) printf '  state:               discharging\n  energy-rate:         7.5 W\n  time to empty:       3.2 hours\n  capacity:            95%%\n' ;;
esac
EOF
    printf '#!/bin/sh\necho 100.64.0.1\n' > "$STUBS/tailscale"
    chmod +x "$STUBS/upower" "$STUBS/tailscale"
    mkdir -p "$TMP/sys/class/power_supply/BAT0"
    echo 80 > "$TMP/sys/class/power_supply/BAT0/charge_control_end_threshold"

    local json
    json="$(BLOCK_TOOLTIPS_SYSFS="$TMP/sys" run "$SCRIPTS/block-tooltips")"
    expect "block-tooltips: battery and VPN only" "battery,vpn" "$(jq -r 'keys | join(",")' <<< "$json")"
    expect "battery tooltip" \
        "State:    discharging|Power:    7.5 W|Time to empty: 3.2 hours|Health:   95%|Limit:    80%" \
        "$(jq -r .battery <<< "$json" | paste -sd '|')"
    expect "vpn tooltip" "Tailscale: 100.64.0.1" "$(jq -r .vpn <<< "$json")"
}

test_net_info() {
    # nmcli answers by its arguments, as NetworkManager would.
    cat > "$STUBS/nmcli" <<'EOF'
#!/bin/sh
case "$*" in
    "-t -f DEVICE,TYPE,STATE device") printf 'wlan0:wifi:connected\neth0:ethernet:unavailable\n' ;;
    "-t -g GENERAL.CONNECTION device show wlan0") echo 'Home: 5G' ;;
    "-t -g IP4.ADDRESS device show wlan0") echo '192.168.1.23/24' ;;
    "-t -g IP4.GATEWAY device show wlan0") echo '192.168.1.1' ;;
    "-t -g IP4.DNS device show wlan0") echo '192.168.1.1 | 9.9.9.9' ;;
    "-t -g IP6.ADDRESS device show wlan0") echo 'fd00\:\:23/64 | fe80\:\:1/64' ;;
    *"device wifi list ifname wlan0"*) echo '*:71:5500 MHz:1170 Mbit/s' ;;
esac
EOF
    chmod +x "$STUBS/nmcli"
    # Byte counters: 2.5 MB down and 40 kB up during the sample; the fake
    # sleep moves them on.
    local stats="$TMP/sys/class/net/wlan0/statistics"
    mkdir -p "$stats"
    echo 1000000 > "$stats/rx_bytes"
    echo 500000 > "$stats/tx_bytes"
    cat > "$STUBS/sleep" <<EOF
#!/bin/sh
echo 3500000 > "$stats/rx_bytes"
echo 540000 > "$stats/tx_bytes"
EOF
    chmod +x "$STUBS/sleep"

    local json
    json="$(NET_INFO_SYSFS="$TMP/sys" NET_INFO_SAMPLE_S=1 run "$SCRIPTS/net-info")"
    rm -f "$STUBS/sleep"
    expect "net-info: connected devices only" "wireless" "$(jq -r 'keys | join(",")' <<< "$json")"
    expect "net-info: wireless" \
        "Home: 5G on wlan0|Signal:  71%, 5500 MHz, 1170 Mbit/s|Down:    2.5 MB/s|Up:      40 kB/s|IPv4:    192.168.1.23/24|Gateway: 192.168.1.1|DNS:     192.168.1.1 9.9.9.9|IPv6:    fd00::23/64" \
        "$(jq -r .wireless <<< "$json" | paste -sd '|')"
}

test_disk_info() {
    # df -P -T -k: two mounts of one btrfs device, and /boot.
    cat > "$STUBS/df" <<'EOF'
#!/bin/sh
cat <<'DF'
Filesystem     Type  1024-blocks     Used Available Capacity Mounted on
/dev/dm-0      btrfs   104857600 26214400  78643200      25% /
/dev/dm-0      btrfs   104857600 26214400  78643200      25% /home
/dev/nvme0n1p5 ext4      2097152  1887437    209715      90% /boot
DF
EOF
    chmod +x "$STUBS/df"
    expect "disk-info: one entry per device" \
        '{"mounts":"/ /home","used":"25 GiB","size":"100 GiB","pct":25};{"mounts":"/boot","used":"1.8 GiB","size":"2 GiB","pct":90}' \
        "$(run "$SCRIPTS/disk-info" | jq -c '.[]' | paste -sd ';')"
    rm -f "$STUBS/df"
}

test_cpu_info() {
    local proc="$TMP/proc" sys="$TMP/sys"
    mkdir -p "$proc" "$sys/class/hwmon/hwmon3"
    echo "0.52 0.61 0.70 2/300 1234" > "$proc/loadavg"
    echo coretemp > "$sys/class/hwmon/hwmon3/name"
    echo "Package id 0" > "$sys/class/hwmon/hwmon3/temp1_label"
    echo 61000 > "$sys/class/hwmon/hwmon3/temp1_input"
    # /proc/stat: the second sample adds 100 ticks per core, 25 and 100
    # of them busy. The fake sleep swaps the file between the samples.
    printf 'cpu  0 0 0 0 0 0 0 0\ncpu0 100 0 100 800 0 0 0 0\ncpu1 0 0 0 1000 0 0 0 0\n' > "$proc/stat"
    printf 'cpu  0 0 0 0 0 0 0 0\ncpu0 125 0 100 875 0 0 0 0\ncpu1 50 0 50 1000 0 0 0 0\n' > "$TMP/stat2"
    cat > "$STUBS/sleep" <<EOF
#!/bin/sh
cp "$TMP/stat2" "$proc/stat"
EOF
    chmod +x "$STUBS/sleep"

    local json
    json="$(CPU_INFO_PROC="$proc" CPU_INFO_SYSFS="$sys" run "$SCRIPTS/cpu-info")"
    rm -f "$STUBS/sleep"
    expect "cpu-info: load 1, 5, 15 min" "0.52  0.61  0.70" "$(jq -r .load <<< "$json")"
    expect "cpu-info: cores in rows, with values" '[[{"name":"cpu0","pct":25},{"name":"cpu1","pct":100}]]' "$(jq -c .cores <<< "$json")"
    expect "cpu-info: package temperature" "61 °C" "$(jq -r .temp <<< "$json")"
}

test_mem_info() {
    local proc="$TMP/proc-mem"
    mkdir -p "$proc"
    # In kB: 16 GiB total, 6 available (10 used), 2 free, 4 cache, swap 1 of
    # 8 GiB used.
    cat > "$proc/meminfo" <<'EOF'
MemTotal:       16777216 kB
MemFree:         2097152 kB
MemAvailable:    6291456 kB
Buffers:         1048576 kB
Cached:          3145728 kB
Unevictable:      524288 kB
SUnreclaim:       262144 kB
KernelStack:      131072 kB
PageTables:       131072 kB
SwapTotal:       8388608 kB
SwapFree:        7340032 kB
EOF
    expect "mem-info: used, available, cache, free, swap" \
        '{"used":"10.0 GiB","available":"6.0 GiB","cache":"4.0 GiB","free":"2.0 GiB","swap":"1.0 GiB / 8.0 GiB"}' \
        "$(MEM_INFO_PROC="$proc" run "$SCRIPTS/mem-info")"
}

test_theme_mode() {
    # gsettings: the value from GS, and one change on monitor.
    cat > "$STUBS/gsettings" <<EOF
#!/bin/sh
case "\$1" in
    get) cat "$TMP/gs" ;;
    monitor) echo "'prefer-light'" > "$TMP/gs"; echo "color-scheme: 'prefer-light'" ;;
esac
EOF
    chmod +x "$STUBS/gsettings"
    echo "'prefer-dark'" > "$TMP/gs"
    expect "theme-mode: now, then after the change" "dark;light" "$(run "$SCRIPTS/theme-mode" | paste -sd ';')"
}

test_i3_workspaces() {
    # One round: the list, one event and the list again; then X is gone.
    cat > "$STUBS/i3-msg" <<'EOF'
#!/bin/sh
case "$2" in
    get_workspaces) echo '[{"num":1}]' ;;
    subscribe) echo '{"change":"focus"}' ;;
esac
EOF
    cat > "$STUBS/xset" <<EOF
#!/bin/sh
[ -e "$TMP/x-gone" ] && exit 1
touch "$TMP/x-gone"
EOF
    chmod +x "$STUBS/i3-msg" "$STUBS/xset"
    rm -f "$TMP/x-gone"
    expect "i3-workspaces: list, again on a change, ends with X" '[{"num":1}];[{"num":1}]' \
        "$(I3_WORKSPACES_RETRY_S=0 run timeout 5 "$SCRIPTS/i3-workspaces" | paste -sd ';')"
}

test_i3_mode() {
    # The current mode, then one per mode event; "default" is empty (no
    # indicator, as in i3bar). Then X is gone.
    cat > "$STUBS/i3-msg" <<'EOF'
#!/bin/sh
case "$2" in
    get_binding_state) echo '{"name":"default"}' ;;
    subscribe) echo '{"change":"resize","pango_markup":false}'; echo '{"change":"default","pango_markup":false}' ;;
esac
EOF
    cat > "$STUBS/xset" <<EOF
#!/bin/sh
[ -e "$TMP/x-gone" ] && exit 1
touch "$TMP/x-gone"
EOF
    chmod +x "$STUBS/i3-msg" "$STUBS/xset"
    rm -f "$TMP/x-gone"
    expect "i3-mode: current mode, then each change; default is empty" ';resize;' \
        "$(I3_MODE_RETRY_S=0 run timeout 5 "$SCRIPTS/i3-mode" | paste -sd ';')"
}

test_bar() {
    stub eww
    # ~/bin/pkill-display: records its arguments.
    cat > "$HOME_DIR/bin/pkill-display" <<EOF
#!/bin/sh
echo "pkill-display \$*" >> "$CALLS"
exit 0
EOF
    chmod +x "$HOME_DIR/bin/pkill-display"
    # Two outputs, the primary one second; one output change (three events
    # at once, as when a monitor is plugged in) arrives while the watcher
    # runs, then X is gone.
    cat > "$STUBS/i3-msg" <<EOF
#!/bin/sh
echo "i3-msg \$*" >> "$CALLS"
case "\$*" in
    "-t get_outputs") echo '[{"name":"HDMI-1","active":true,"primary":false},{"name":"eDP-1","active":true,"primary":true},{"name":"DP-1","active":false,"primary":false}]' ;;
    "-t subscribe"*) printf '{"change":"unspecified"}\n{"change":"unspecified"}\n{"change":"unspecified"}\n' ;;
    # The docked bars, one per active output: heights from TMP/heights,
    # one line per check (the last one repeats), 34 without the file.
    # TMP/zombie: once, a second bar on eDP-1 (one eww lost track of).
    "-t get_tree")
        h=34
        if [ -s "$TMP/heights" ]; then
            h="\$(head -n 1 "$TMP/heights")"
            [ "\$(wc -l < "$TMP/heights")" -gt 1 ] && sed -i 1d "$TMP/heights"
        fi
        extra=""
        if [ -e "$TMP/zombie" ]; then
            rm "$TMP/zombie"
            extra=",{\"output\":\"eDP-1\",\"window_properties\":{\"class\":\"Eww\"},\"rect\":{\"height\":34}}"
        fi
        echo "{\"nodes\":[{\"output\":\"HDMI-1\",\"window_properties\":{\"class\":\"Eww\"},\"rect\":{\"height\":\$h}},{\"output\":\"eDP-1\",\"window_properties\":{\"class\":\"Eww\"},\"rect\":{\"height\":\$h}}\$extra]}" ;;
esac
exit 0
EOF
    # xrdb -query: the Xft.dpi of XFT_DPI.
    cat > "$STUBS/xrdb" <<'EOF'
#!/bin/sh
printf 'Xft.dpi:\t%s\n' "${XFT_DPI:-}"
EOF
    chmod +x "$STUBS/i3-msg" "$STUBS/xrdb"
    rm -f "$TMP/x-gone"
    : > "$CALLS"
    rm -f "$TMP/heights"
    XFT_DPI=144 BAR_RETRY_S=0 BAR_SIZE_CHECK_S=0 run timeout 5 "$BAR" watch || true

    expect "bars per active output, tray on the primary one" \
        "eww -c $TMP/run/eww/display7 --no-daemonize open bar --id bar-eDP-1 --screen eDP-1 --arg output=eDP-1 --arg height=34 --arg tray=true;eww -c $TMP/run/eww/display7 --no-daemonize open bar --id bar-HDMI-1 --screen HDMI-1 --arg output=HDMI-1 --arg height=34 --arg tray=false" \
        "$(grep ' open ' "$CALLS" | head -n 2 | paste -sd ';')"
    # Start, then once for the output change: its three events at once
    # reopen once.
    expect "bars reopened once when outputs change" "2" "$(grep -c ' close-all' "$CALLS")"
    # eww starts the hover polls with the window; a change of hover stops
    # them (:run-while), after the bars are open.
    expect "hover polls stopped after opening" \
        "update hover=none;update hover=" \
        "$(grep -o 'update hover=.*' "$CALLS" | head -n 2 | paste -sd ';')"
    # Two outputs: the first reset follows the second open.
    local reset_line open_line
    reset_line="$(grep -n ' update hover=none' "$CALLS" | head -n 1 | cut -d: -f1)"
    open_line="$(grep -n ' open ' "$CALLS" | sed -n 2p | cut -d: -f1)"
    if [[ "$reset_line" -gt "$open_line" ]]; then
        ok "hover reset after the bars open"
    else
        fail "hover reset before the bars open"
    fi

    : > "$CALLS"
    rm -f "$TMP/x-gone"
    XFT_DPI=96 BAR_RETRY_S=0 BAR_SIZE_CHECK_S=0 run timeout 5 "$BAR" watch || true
    # Every bar (2 outputs, opened at start and after the output change).
    expect "height for 96 dpi" "$(grep -c ' open ' "$CALLS")" "$(grep -c -- '--arg height=23 ' "$CALLS")"

    # A bar docked 0 px high is opened again, until it has a height.
    : > "$CALLS"
    rm -f "$TMP/x-gone"
    printf '0\n34\n' > "$TMP/heights"
    XFT_DPI=144 BAR_RETRY_S=0 BAR_SIZE_CHECK_S=0 run timeout 5 "$BAR" watch || true
    # Start: 0 px, then 34 (2 rounds); the output change: 1 round.
    expect "bar without height opened again" "3" "$(grep -c ' close-all' "$CALLS")"
    expect "bar without height: a new daemon first" "1" "$(grep -c ' kill$' "$CALLS")"

    # A second bar on one output: one of another eww daemon of this config
    # (an `eww open` that found none started its own), which close-all
    # and kill do not reach. Every eww process of the config goes, then a
    # new daemon (once it answers) gets the bars.
    local cfg="eww -c $TMP/run/eww/display7"
    : > "$CALLS"
    rm -f "$TMP/x-gone" "$TMP/heights"
    touch "$TMP/zombie"
    XFT_DPI=144 BAR_RETRY_S=0 BAR_SIZE_CHECK_S=0 run timeout 5 "$BAR" watch || true
    expect "two bars on one output: all eww of the config stopped, new daemon, bars again" \
        "$cfg kill;pkill-display -f eww -c $TMP/run/eww/display7 ;$cfg daemon;$cfg ping;$cfg close-all" \
        "$(grep -E ' (kill|daemon|ping|close-all)$|^pkill-display -f eww' "$CALLS" | sed -n '2,6p' | paste -sd ';')"

    # An eww open that hangs does not stop the watcher: the next output
    # gets its bar.
    cat > "$STUBS/eww" <<EOF
#!/bin/sh
echo "eww \$*" >> "$CALLS"
case "\$*" in *"open bar --id bar-eDP-1 "*) sleep 30 ;; esac
exit 0
EOF
    : > "$CALLS"
    rm -f "$TMP/x-gone"
    XFT_DPI=144 BAR_RETRY_S=0 BAR_SIZE_CHECK_S=0 BAR_OPEN_TIMEOUT_S=0.2 run timeout 5 "$BAR" watch || true
    # At start and after the output change.
    expect "a hanging open: the next bar opens" "2" "$(grep -c 'open bar --id bar-HDMI-1 ' "$CALLS")"
    stub eww

    # One eww daemon per X display (two sessions: local and xrdp). eww
    # names its socket by the resolved config path, so each display has a
    # config directory of its own, linking the real files.
    expect "per-display config links the eww files" "$HOME_DIR/.config/eww/eww.yuck" \
        "$(readlink "$TMP/run/eww/display7/eww.yuck")"
    : > "$CALLS"
    rm -f "$TMP/x-gone"
    HOME="$HOME_DIR" DISPLAY=:10.0 XDG_RUNTIME_DIR="$TMP/run" PATH="$STUBS:$PATH" BAR_RETRY_S=0 BAR_SIZE_CHECK_S=0 \
        timeout 5 "$BAR" watch || true
    # At start and after the output change of the stub.
    expect "another display, another config directory" "2" \
        "$(grep -c "^eww -c $TMP/run/eww/display10.0 close-all" "$CALLS")"

    # bar (start): a new daemon; a running one is replaced (it reads the
    # config again and drops windows it lost track of; eww does not see
    # edits behind the display directory's links). X is gone: the started
    # watcher ends at once.
    touch "$TMP/x-gone"
    : > "$CALLS"
    run "$BAR"
    expect "bar again: every eww of the config replaced by a new daemon" \
        "$cfg ping;$cfg kill;pkill-display -f eww -c $TMP/run/eww/display7 ;$cfg daemon;$cfg ping" \
        "$(grep -E ' (ping|kill|reload|daemon)$|^pkill-display -f eww' "$CALLS" | paste -sd ';')"
    # No daemon until `eww daemon` ran (TMP/up).
    cat > "$STUBS/eww" <<EOF
#!/bin/sh
echo "eww \$*" >> "$CALLS"
case "\$*" in
    *" ping") [ -e "$TMP/up" ] || exit 1 ;;
    *" daemon") touch "$TMP/up" ;;
esac
exit 0
EOF
    rm -f "$TMP/up"
    : > "$CALLS"
    run "$BAR"
    expect "bar: starts the daemon when none runs, waits until it answers" "$cfg ping;$cfg daemon;$cfg ping" \
        "$(grep -E ' (ping|reload|daemon)$' "$CALLS" | paste -sd ';')"
}

main() {
    command -v jq >/dev/null || { echo "SKIP: jq not installed"; exit 0; }
    mkdir -p "$STUBS" "$HOME_DIR/bin" "$HOME_DIR/.config/eww"
    touch "$HOME_DIR/.config/eww/eww.yuck" "$HOME_DIR/.config/eww/eww.scss"
    test_status_blocks
    test_block_click
    test_block_tooltips
    test_net_info
    test_disk_info
    test_cpu_info
    test_mem_info
    test_theme_mode
    test_i3_workspaces
    test_i3_mode
    test_bar
    exit "$FAILED"
}

main "$@"
