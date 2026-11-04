#!/usr/bin/env bash
#
# Runs system-sleep/power-button-wake against a fake sysfs tree. Before sleep
# every wakeup source except the power buttons must end disabled; after
# sleep nothing may change.
#
# Usage: test/system-sleep/power-button-wake.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOOK="$HERE/../../system-sleep/power-button-wake"
FAKE="$(mktemp -d)"
readonly FAKE
trap 'rm -rf "$FAKE"' EXIT
FAILED=0

readonly ACPI="LNXSYSTM:00/LNXSYBUS:00"
readonly KEPT=(
    "LNXSYSTM:00/LNXPWRBN:00"
    "$ACPI/PNP0C0C:00"
    "platform/INTC1078:00"
    "$ACPI/INTC1078:00"
    "platform/INT33D6:00"
)
readonly DISABLED=(
    "$ACPI/PNP0C0D:00"
    "$ACPI/PNP0C0E:00"
    "$ACPI/PNP0C0A:00"
    "platform/i8042/serio0"
    "platform/i8042/serio1"
    "pci0000:00/0000:00:14.0"
    "pci0000:00/0000:00:14.0/usb1/1-3"
    "pci0000:00/0000:00:1f.6"
    "pnp0/00:01"
)

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

add_device() {
    local dev="$FAKE/devices/$1" state="$2"
    mkdir -p "$dev/power"
    echo "$state" > "$dev/power/wakeup"
}

bind_driver() {
    local dev="$FAKE/devices/$1" driver="$FAKE/bus/platform/drivers/$2"
    mkdir -p "$driver"
    ln -s "$driver" "$dev/driver"
}

wakeup_of() { cat "$FAKE/devices/$1/power/wakeup"; }

build_tree() {
    local dev
    for dev in "${KEPT[@]}" "${DISABLED[@]}"; do
        add_device "$dev" enabled
    done
    bind_driver "platform/INTC1078:00" intel-hid
    bind_driver "platform/INT33D6:00" intel-vbtn
    # The ACPI companion of intel-hid points at its platform device.
    ln -s "$FAKE/devices/platform/INTC1078:00" "$FAKE/devices/$ACPI/INTC1078:00/physical_node"
    # Not wakeup capable: an empty attribute must stay untouched.
    mkdir -p "$FAKE/devices/platform/empty/power"
    : > "$FAKE/devices/platform/empty/power/wakeup"
}

check_states() {
    local phase="$1" dev
    for dev in "${KEPT[@]}"; do
        [[ "$(wakeup_of "$dev")" == enabled ]] || fail "$phase: $dev disabled"
    done
    for dev in "${DISABLED[@]}"; do
        [[ "$(wakeup_of "$dev")" == disabled ]] || fail "$phase: $dev still enabled"
    done
    [[ -z "$(wakeup_of platform/empty)" ]] || fail "$phase: empty attribute written"
}

main() {
    build_tree

    POWER_BUTTON_WAKE_SYSFS="$FAKE" "$HOOK" pre suspend || fail "pre: exit $?"
    check_states pre
    [[ $FAILED -eq 0 ]] && ok "pre: only power buttons can wake"

    # After resume the hook must not touch anything.
    add_device "pci0000:00/0000:00:1f.6" enabled
    POWER_BUTTON_WAKE_SYSFS="$FAKE" "$HOOK" post suspend || fail "post: exit $?"
    if [[ "$(wakeup_of "pci0000:00/0000:00:1f.6")" == enabled ]]; then
        ok "post: no change"
    else
        fail "post: changed a wakeup source"
    fi

    exit "$FAILED"
}

main "$@"
