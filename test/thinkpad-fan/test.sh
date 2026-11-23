#!/usr/bin/env bash
#
# ThinkPad fan control:
#   - install_thinkpad_fan (bootstrap.sh) puts modprobe-conf/thinkpad-fan.conf
#     (thinkpad_acpi fan_control=1) into modprobe.d on ThinkPads only (DMI
#     product_version), and restores its SELinux label also when current;
#   - bin/fan against a fake /proc/acpi/ibm/fan, module option and hwmon:
#     show prints the level and both fans' speed; max sets full-speed, then
#     the 120 s watchdog (the firmware goes back to auto when no command
#     follows); auto sets auto and turns the watchdog off; with fan control
#     off it explains and writes nothing; a file it cannot write goes
#     through sudo.
#
# Usage: test/thinkpad-fan/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
readonly FAN="$ROOT/bin/fan" CONF="$ROOT/modprobe-conf/thinkpad-fan.conf"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }
expect() {
    if [[ "$2" == "$3" ]]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi
}

# --- bootstrap -------------------------------------------------------------

run_install() {
    [[ "${1:-}" == keep ]] || { rm -rf "$TMP/out"; mkdir -p "$TMP/out/modprobe.d"; }
    : > "$TMP/out/calls"
    HAVE_RESTORECON="${HAVE_RESTORECON:-0}" bash -c '
        set -euo pipefail
        SUDO="" DOTFILES_DIR="$1" DMI_ID_DIR="$2/dmi" MODPROBE_CONF_DIR="$2/out/modprobe.d"
        THINKPAD_FAN_MODPROBE_CONF_NAME=thinkpad-fan.conf CALLS="$2/out/calls"
        log() { :; }
        have() { [[ "$1" == restorecon && "$HAVE_RESTORECON" == 1 ]]; }
        restorecon() { echo "restorecon $*" >> "$CALLS"; }
        source "$2/funcs.sh"
        install_thinkpad_fan
    ' _ "$ROOT" "$TMP"
}

test_install() {
    [[ -f "$CONF" ]] || { fail "modprobe-conf/thinkpad-fan.conf missing"; return; }
    expect "the option enables fan control" "options thinkpad_acpi fan_control=1" "$(grep -v '^#' "$CONF")"
    sed -n '/^is_thinkpad() {$/,/^}$/p;/^install_modprobe_conf() {$/,/^}$/p;/^install_thinkpad_fan() {$/,/^}$/p' \
        "$ROOT/bootstrap.sh" > "$TMP/funcs.sh"
    mkdir -p "$TMP/dmi"
    echo "Latitude 7440" > "$TMP/dmi/product_version"
    run_install
    if [[ -e "$TMP/out/modprobe.d/thinkpad-fan.conf" ]]; then
        fail "installed on a laptop that is no ThinkPad"
    else
        ok "no ThinkPad: not installed"
    fi
    echo "ThinkPad P14s Gen 6" > "$TMP/dmi/product_version"
    run_install
    if cmp -s "$CONF" "$TMP/out/modprobe.d/thinkpad-fan.conf"; then
        ok "ThinkPad: installed"
    else
        fail "ThinkPad: not installed"
    fi
    HAVE_RESTORECON=1 run_install keep
    expect "current file: label restored" "restorecon $TMP/out/modprobe.d/thinkpad-fan.conf" "$(cat "$TMP/out/calls")"
}

# --- bin/fan ---------------------------------------------------------------

# fake_fan <fan_control Y|N>: the driver's files as on the P14s Gen 6.
fake_fan() {
    rm -rf "$TMP/fan"
    mkdir -p "$TMP/fan/sys/module/thinkpad_acpi/parameters" "$TMP/fan/sys/class/hwmon/hwmon5" \
        "$TMP/fan/sys/class/hwmon/hwmon2" "$TMP/fan/bin"
    echo "$1" > "$TMP/fan/sys/module/thinkpad_acpi/parameters/fan_control"
    printf 'status:\t\tenabled\nspeed:\t\t2516\nlevel:\t\tauto\n' > "$TMP/fan/proc"
    echo coretemp > "$TMP/fan/sys/class/hwmon/hwmon2/name"
    echo thinkpad > "$TMP/fan/sys/class/hwmon/hwmon5/name"
    echo 2516 > "$TMP/fan/sys/class/hwmon/hwmon5/fan1_input"
    echo 2400 > "$TMP/fan/sys/class/hwmon/hwmon5/fan2_input"
    # sudo: records the call, then runs it with the file it gets.
    cat > "$TMP/fan/bin/sudo" <<EOF
#!/bin/sh
echo "sudo \$*" >> "$TMP/fan/sudo-calls"
exec "\$@"
EOF
    chmod +x "$TMP/fan/bin/sudo"
}

fan() {
    PATH="$TMP/fan/bin:$PATH" FAN_PROC="$TMP/fan/proc" FAN_SYSFS="$TMP/fan/sys" "$FAN" "$@"
}

# The commands written after the driver's own three lines.
commands() { tail -n +4 "$TMP/fan/proc" | paste -sd ';'; }

test_fan() {
    [[ -f "$FAN" ]] || { fail "bin/fan missing"; return; }
    fake_fan Y
    expect "show: level and both fans" "level auto, 2516, 2400 rpm" "$(fan show)"
    expect "no argument: show" "level auto, 2516, 2400 rpm" "$(fan)"

    fan max > /dev/null
    expect "max: full speed, then the watchdog" "level full-speed;watchdog 120" "$(commands)"

    fake_fan Y
    fan auto > /dev/null
    expect "auto: firmware control, watchdog off" "level auto;watchdog 0" "$(commands)"

    fake_fan N
    local rc=0 err
    err="$(fan max 2>&1 >/dev/null)" || rc=$?
    expect "fan control off: max fails" "1" "$rc"
    if grep -q 'fan_control=1' <<< "$err"; then ok "fan control off: says how to enable it"; else fail "fan control off: message '$err'"; fi
    expect "fan control off: nothing written" "" "$(commands)"

    fake_fan Y
    chmod 0444 "$TMP/fan/proc"
    # A read-only file even for root would stop the test's own sudo stub:
    # it runs tee as the caller, so make the file writable for tee only.
    cat > "$TMP/fan/bin/tee" <<EOF
#!/bin/sh
chmod u+w "$TMP/fan/proc"
exec $(command -v tee) "\$@"
EOF
    chmod +x "$TMP/fan/bin/tee"
    if [[ "$(id -u)" -ne 0 ]]; then
        fan max > /dev/null
        expect "not writable: through sudo" "sudo tee -a $TMP/fan/proc" "$(sort -u "$TMP/fan/sudo-calls")"
        expect "not writable: commands written" "level full-speed;watchdog 120" "$(commands)"
    fi

    local usage_rc=0
    fan sideways > /dev/null 2>&1 || usage_rc=$?
    expect "unknown command: usage, status 2" "2" "$usage_rc"
}

test_install
test_fan
exit "$FAILED"
