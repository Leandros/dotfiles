#!/usr/bin/env bash
#
# Runs install_nvidia_power from bootstrap.sh against a fake PCI sysfs:
# modprobe-conf/nvidia-power.conf goes to modprobe.d only where a display
# controller (PCI class 0x03xxxx) from NVIDIA (vendor 0x10de) exists, and
# the driver's suspend units are enabled where they are installed
# (PreserveVideoMemoryAllocations needs them, else suspend fails).
# restorecon runs on every call, also when the file is current: a file
# with the wrong SELinux label (made by hand with the same contents) is
# not readable to systemd-modules-load.
#
# Usage: test/nvidia-power/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

[[ -f "$ROOT/modprobe-conf/nvidia-power.conf" ]] || fail "modprobe-conf/nvidia-power.conf missing"
grep -qE '^readonly NVIDIA_MODPROBE_CONF_NAME="nvidia-power.conf"$' "$ROOT/bootstrap.sh" \
    || fail "NVIDIA_MODPROBE_CONF_NAME missing"
sed -n '/^has_nvidia_gpu() {$/,/^}$/p;/^install_nvidia_power() {$/,/^}$/p' "$ROOT/bootstrap.sh" >"$TMP/funcs.sh"

# pci <name> <vendor> <class>
pci() { mkdir -p "$TMP/pci/$1"; echo "$2" >"$TMP/pci/$1/vendor"; echo "$3" >"$TMP/pci/$1/class"; }

# run [keep]: keep leaves the installed file from the last run.
run() {
    if [[ "${1:-}" != keep ]]; then
        rm -rf "$TMP/out" && mkdir -p "$TMP/out/modprobe.d"
    fi
    : >"$TMP/out/calls"
    HAVE_RESTORECON="${HAVE_RESTORECON:-0}" bash -c '
        set -euo pipefail
        SUDO="" DOTFILES_DIR="$1" PCI_DEVICES_DIR="$2/pci" MODPROBE_CONF_DIR="$2/out/modprobe.d"
        SYSTEMD_UNIT_DIR="$2/units" NVIDIA_MODPROBE_CONF_NAME=nvidia-power.conf
        CALLS="$2/out/calls"
        log() { :; }
        have() { [[ "$1" == restorecon && "$HAVE_RESTORECON" == 1 ]]; }
        systemctl() { echo "systemctl $*" >>"$CALLS"; }
        restorecon() { echo "restorecon $*" >>"$CALLS"; }
        source "$2/funcs.sh"
        install_nvidia_power
    ' _ "$ROOT" "$TMP"
}
installed() { cmp -s "$ROOT/modprobe-conf/nvidia-power.conf" "$TMP/out/modprobe.d/nvidia-power.conf"; }

mkdir -p "$TMP/units"
pci 0000:00:02.0 0x8086 0x030000
pci 0000:00:1f.3 0x10de 0x040300    # an NVIDIA audio function: not a GPU
run
if [[ ! -e "$TMP/out/modprobe.d/nvidia-power.conf" ]]; then ok "no NVIDIA GPU: not installed"; else fail "installed without NVIDIA GPU"; fi

pci 0000:01:00.0 0x10de 0x030200
run
if installed; then ok "NVIDIA GPU: installed"; else fail "NVIDIA GPU: not installed"; fi
if [[ ! -s "$TMP/out/calls" ]]; then ok "no driver units: none enabled"; else fail "enabled missing units: $(cat "$TMP/out/calls")"; fi

touch "$TMP/units/nvidia-suspend.service" "$TMP/units/nvidia-resume.service" "$TMP/units/nvidia-hibernate.service"
run
want="systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service"
got="$(cat "$TMP/out/calls")"
if [[ "$got" == "$want" ]]; then ok "driver units enabled"; else fail "units: want '$want', got '$got'"; fi

rm "$TMP"/units/*
HAVE_RESTORECON=1 run keep
want="restorecon $TMP/out/modprobe.d/nvidia-power.conf"
got="$(cat "$TMP/out/calls")"
if [[ "$got" == "$want" ]]; then ok "current file: label restored"; else fail "current file: want '$want', got '$got'"; fi

exit "$FAILED"
