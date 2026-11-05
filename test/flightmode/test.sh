#!/usr/bin/env bash
#
# Runs bin/flightmode with stubs for rfkill and ~/bin/pwr and checks the
# radio blocks and the power mode it sets and restores.
#
# Usage: test/flightmode/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/flightmode"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" RADIOS="$TMP/radios" MODE="$TMP/mode" CALLS="$TMP/calls"
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

# rfkill keeps one SOFT state per radio in RADIOS; pwr keeps the mode in
# MODE ("none" makes `pwr mode` fail like a system without a daemon).
write_stubs() {
    mkdir -p "$STUBS" "$TMP/home/bin" "$TMP/run"
    cat > "$STUBS/rfkill" <<EOF
#!/bin/sh
echo "rfkill \$*" >> "$CALLS"
case "\$1" in
    block)   sed -i 's/.*/blocked/' "$RADIOS" ;;
    unblock) sed -i 's/.*/unblocked/' "$RADIOS" ;;
    *)       cat "$RADIOS" ;;
esac
EOF
    cat > "$TMP/home/bin/pwr" <<EOF
#!/bin/sh
echo "pwr \$*" >> "$CALLS"
if [ "\$1" = mode ]; then
    [ "\$(cat "$MODE")" = none ] && exit 1
    cat "$MODE"
else
    echo "\$1" > "$MODE"
fi
EOF
    chmod +x "$STUBS/rfkill" "$TMP/home/bin/pwr"
}

# Radios as SOFT states, one per line; the power mode.
setup() {
    local states
    read -r -a states <<< "$1"
    printf '%s\n' "${states[@]}" > "$RADIOS"
    echo "$2" > "$MODE"
}

run() {
    : > "$CALLS"
    HOME="$TMP/home" XDG_RUNTIME_DIR="$TMP/run" PATH="$STUBS:$PATH" "$SCRIPT" "$@"
}

radios() { tr '\n' ' ' < "$RADIOS" | sed 's/ $//'; }

main() {
    write_stubs

    setup "unblocked unblocked unblocked" balanced
    expect "show: radios on is off" "off" "$(run show)"
    run on > /dev/null
    expect "on blocks every radio" "blocked blocked blocked" "$(radios)"
    expect "on selects the battery mode" "battery" "$(cat "$MODE")"
    expect "show after on" "on" "$(run show)"

    run off > /dev/null
    expect "off unblocks every radio" "unblocked unblocked unblocked" "$(radios)"
    expect "off restores the earlier mode" "balanced" "$(cat "$MODE")"

    setup "unblocked" balanced
    run on > /dev/null
    run on > /dev/null
    run off > /dev/null
    expect "a second on keeps the mode to restore" "balanced" "$(cat "$MODE")"

    setup "unblocked unblocked" performance
    run toggle > /dev/null
    expect "toggle from off is on" "blocked blocked" "$(radios)"
    run toggle > /dev/null
    expect "toggle from on is off" "unblocked unblocked" "$(radios)"
    expect "toggle restores the mode" "performance" "$(cat "$MODE")"

    setup "blocked unblocked" balanced
    expect "show: one radio on is off" "off" "$(run show)"

    # Without a saved mode (after a reboot) off leaves the mode alone.
    setup "blocked blocked" battery
    rm -f "$TMP/run/flightmode-mode"
    run off > /dev/null
    expect "off without a saved mode keeps it" "battery" "$(cat "$MODE")"

    setup "unblocked" none
    if run on > /dev/null 2>&1; then
        ok "on works without a power profile daemon"
    else
        fail "on failed without a power profile daemon"
    fi
    expect "radios off without a daemon" "blocked" "$(radios)"

    setup "" balanced
    : > "$RADIOS"
    expect "show: no radios is off" "off" "$(run show)"

    if run bogus > /dev/null 2>&1; then fail "unknown command accepted"; else ok "unknown command rejected"; fi

    exit "$FAILED"
}

main "$@"
