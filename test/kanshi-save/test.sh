#!/usr/bin/env bash
#
# Runs bin/kanshi-save with stubs for swaymsg (the outputs of a laptop at a
# desk, as sway 1.12 prints them), pgrep and kanshictl, and checks the
# profile it writes into ~/.config/kanshi/config: a profile of that name
# replaced in place, other profiles and lines kept, a new one appended,
# and kanshi reloaded only when it runs.
#
# Usage: test/kanshi-save/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/kanshi-save" WM_MSG="$HERE/../../bin/wm-msg"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" HOME_DIR="$TMP/home"
readonly CONFIG="$TMP/home/.config/kanshi/config"
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

# eDP-1 at scale 1.5 (60.001 Hz), a 4k monitor right of it at 59.997 Hz,
# rotated; HDMI-A-1 off. refresh is in mHz; rect is logical.
write_stubs() {
    mkdir -p "$STUBS" "$HOME_DIR/bin"
    ln -s "$(readlink -f "$WM_MSG")" "$HOME_DIR/bin/wm-msg"
    cat > "$STUBS/outputs.json" <<'EOF'
[
  {
    "id": 3,
    "type": "output",
    "rect": { "x": 0, "y": 0, "width": 1920, "height": 1200 },
    "name": "eDP-1",
    "primary": false,
    "make": "Samsung Display Corp.",
    "model": "ATNA40CU07-0",
    "serial": "Unknown",
    "modes": [ { "width": 2880, "height": 1800, "refresh": 120000 }, { "width": 2880, "height": 1800, "refresh": 60001 } ],
    "active": true,
    "scale": 1.5,
    "transform": "normal",
    "current_mode": { "width": 2880, "height": 1800, "refresh": 60001 }
  },
  {
    "id": 5,
    "type": "output",
    "rect": { "x": 1920, "y": 0, "width": 2160, "height": 3840 },
    "name": "DP-2",
    "primary": false,
    "make": "Dell Inc.",
    "model": "DELL U3223QE",
    "serial": "8ZYX123",
    "modes": [ { "width": 3840, "height": 2160, "refresh": 59997 } ],
    "active": true,
    "scale": 1.0,
    "transform": "90",
    "current_mode": { "width": 3840, "height": 2160, "refresh": 59997 }
  },
  {
    "type": "output",
    "name": "HDMI-A-1",
    "primary": false,
    "make": "Goldstar Company Ltd",
    "model": "LG HDR 4K",
    "serial": "",
    "modes": [],
    "active": false,
    "rect": { "x": 0, "y": 0, "width": 0, "height": 0 },
    "current_workspace": null
  }
]
EOF
    cat > "$STUBS/swaymsg" <<EOF
#!/bin/sh
echo "swaymsg \$*" >> "$CALLS"
[ "\$*" = "-t get_outputs" ] && cat "$STUBS/outputs.json"
EOF
    # pgrep finds kanshi when TMP/kanshi exists.
    cat > "$STUBS/pgrep" <<EOF
#!/bin/sh
[ -e "$TMP/kanshi" ] && echo 4242
EOF
    printf '#!/bin/sh\necho "kanshictl $*" >> "%s"\n' "$CALLS" > "$STUBS/kanshictl"
    chmod +x "$STUBS"/*
}

run() {
    : > "$CALLS"
    env -u XDG_CONFIG_HOME HOME="$HOME_DIR" SWAYSOCK=/run/sway.sock PATH="$STUBS:$PATH" "$SCRIPT" "$@"
}

readonly DESK='profile desk {
    output "Samsung Display Corp. ATNA40CU07-0 Unknown" enable mode 2880x1800@60.001Hz position 0,0 scale 1.5 transform normal
    output "Dell Inc. DELL U3223QE 8ZYX123" enable mode 3840x2160@59.997Hz position 1920,0 scale 1 transform 90
    output "Goldstar Company Ltd LG HDR 4K Unknown" disable
}'

readonly LAPTOP='profile laptop {
    output eDP-1 {
        enable
        scale 1.5
    }
}'

main() {
    write_stubs
    mkdir -p "$(dirname "$CONFIG")"
    # Two profiles; desk has a nested block and a brace in a comment.
    cat > "$CONFIG" <<EOF
# Machine-local monitor profiles.
include /etc/kanshi/config.d/*

profile desk { # old {
    output eDP-1 {
        disable
    }
    output DP-2 enable scale 2
}

$LAPTOP
EOF
    run desk > /dev/null
    expect "desk replaced in place, the rest kept" "# Machine-local monitor profiles.
include /etc/kanshi/config.d/*

$DESK

$LAPTOP" "$(cat "$CONFIG")"
    expect "no reload without kanshi" "swaymsg -t get_outputs" "$(cat "$CALLS")"

    touch "$TMP/kanshi"
    run home > /dev/null
    expect "a new profile at the end" "# Machine-local monitor profiles.
include /etc/kanshi/config.d/*

$DESK

$LAPTOP

${DESK/profile desk/profile home}" "$(cat "$CONFIG")"
    expect "kanshi reloaded when it runs" "kanshictl reload" "$(grep kanshictl "$CALLS")"

    rm -rf "$HOME_DIR/.config"
    run desk > /dev/null
    expect "no config yet: created" "$DESK" "$(cat "$CONFIG")"
    expect "no temporary files left" "config" "$(ls "$(dirname "$CONFIG")")"

    # Two monitors of one model without serial: the same description, so
    # their connector names.
    jq '.[1].serial = "Unknown" | .[1].model = "ATNA40CU07-0" | .[1].make = "Samsung Display Corp."' \
        "$STUBS/outputs.json" > "$TMP/twins.json"
    mv "$TMP/twins.json" "$STUBS/outputs.json"
    run twins > /dev/null
    expect "twins: by connector name" 'output "eDP-1" enable;output "DP-2" enable' \
        "$(sed -n '/^profile twins /,/^}/p' "$CONFIG" | grep -o 'output "[^"]*" enable' | paste -sd ';')"

    local name
    for name in "" "a b" "x}" "-x"; do
        if run "$name" > /dev/null 2>&1; then fail "name '$name' accepted"; else ok "name '$name' rejected"; fi
    done
    if env -u SWAYSOCK HOME="$HOME_DIR" PATH="$STUBS:$PATH" "$SCRIPT" desk > /dev/null 2>&1; then
        fail "ran without sway"
    else
        ok "needs sway"
    fi

    exit "$FAILED"
}

main "$@"
