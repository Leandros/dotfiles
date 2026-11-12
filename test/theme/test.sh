#!/usr/bin/env bash
#
# Runs bin/theme with stubs for xrdb, gsettings, i3-msg and swaymsg and
# checks the X resources, the color-scheme and the i3 reload; the sway
# colors (~/.config/sway.d/theme.conf) and fuzzel colors
# (~/.local/state/theme/fuzzel.ini) in both sessions, and the sway reload
# without xrdb. Also checks that the i3 and sway configs fall back to the
# dark palette.
#
# Usage: test/theme/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/theme"
readonly I3_CONFIG="$HERE/../../.config/i3/config"
readonly SWAY_CONFIG="$HERE/../../.config/sway/config" WM_MSG="$HERE/../../bin/wm-msg"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" SCHEME="$TMP/scheme" RESOURCES="$TMP/resources"
readonly HOME_DIR="$TMP/home"
readonly SWAY_THEME="$TMP/home/.config/sway.d/theme.conf" FUZZEL_THEME="$TMP/home/.local/state/theme/fuzzel.ini"
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

# gsettings keeps the color-scheme in a file; xrdb saves what it merges.
write_stubs() {
    mkdir -p "$STUBS"
    cat > "$STUBS/gsettings" <<EOF
#!/bin/sh
echo "gsettings \$*" >> "$CALLS"
case "\$1" in
    get) cat "$SCHEME" ;;
    set) echo "'\$4'" > "$SCHEME" ;;
esac
EOF
    cat > "$STUBS/xrdb" <<EOF
#!/bin/sh
echo "xrdb \$*" >> "$CALLS"
cat > "$RESOURCES"
EOF
    local tool
    for tool in i3-msg swaymsg; do
        cat > "$STUBS/$tool" <<EOF
#!/bin/sh
echo "$tool \$*" >> "$CALLS"
EOF
    done
    chmod +x "$STUBS/gsettings" "$STUBS/xrdb" "$STUBS/i3-msg" "$STUBS/swaymsg"
    mkdir -p "$HOME_DIR/bin"
    ln -sf "$(readlink -f "$WM_MSG")" "$HOME_DIR/bin/wm-msg"
}

# Runs theme with the color-scheme set to SCHEME_VALUE; prints its stdout.
run() {
    local scheme_value="$1"
    shift
    echo "$scheme_value" > "$SCHEME"
    : > "$CALLS"
    : > "$RESOURCES"
    env -u SWAYSOCK ${SESSION_ENV[@]+"${SESSION_ENV[@]}"} HOME="$HOME_DIR" DISPLAY=:99 XDG_CONFIG_HOME="$TMP/config" \
        PATH="$STUBS:$PATH" "$SCRIPT" "$@"
}

# Extra variables for run: a sway session (sway sets DISPLAY for Xwayland).
SESSION_ENV=()
readonly SWAY_ENV=(SWAYSOCK=/run/sway.sock WAYLAND_DISPLAY=wayland-1 DISPLAY=:0)

# Prints the "name value" pairs of the "set $name #hex" lines in FILE.
# shellcheck disable=SC2016 # $ of sway variables.
sway_sets() { sed -En 's/^set \$([A-Za-z0-9]+)[[:space:]]+(#[0-9a-f]+)[[:space:]]*$/\1 \2/p' "$1"; }

# The value of KEY in the fuzzel colors.
fuzzel() { sed -n "s/^$1=//p" "$FUZZEL_THEME"; }

# A sway config as ~/.config/sway/config: themed colors in top-level lines
# (one continued), and in lines that must not run again (set, include,
# exec, comments, blocks); $baseA2x is not a themed variable.
write_sway_config() {
    mkdir -p "$HOME_DIR/.config/sway"
    cat > "$HOME_DIR/.config/sway/config" <<'EOF'
# Colors: $baseA2 and the rest.
set $green #859900
set $baseA2 #073642
include ~/.config/sway.d/*.conf
output * bg $baseA2 solid_color
client.unfocused            $baseA2 $baseA2 $baseB1 $baseA1
  client.focused              $green  $green  $baseB3 $blue
exec swaybg -c $baseA3
exec_always notify-send $baseA3
bindsym $mod+j exec sway-easyfocus --label-background-color '$baseA2' \
    --focused-text-color '$baseB3' focus
bindsym $mod+Return exec ~/bin/term
input type:touchpad {
    tap disabled
}
bar {
    colors {
        background $baseA3
    }
}
client.urgent $baseA2x $baseA2x $baseA2x $baseA2x
EOF
}

test_sway() {
    rm -rf "$HOME_DIR/.config" "$HOME_DIR/.local" "$TMP/config"
    write_sway_config
    SESSION_ENV=("${SWAY_ENV[@]}")
    run "'prefer-dark'" light > /dev/null
    SESSION_ENV=()
    expect "sway: light sets the color-scheme" "'prefer-light'" "$(cat "$SCHEME")"
    expect "sway: no xrdb (Xwayland)" "" "$(grep '^xrdb' "$CALLS" || true)"
    # A reload would drop what was set at runtime (kanshi's monitor layout,
    # keyboard layout, touchpad tapping): the colors, then the config lines
    # that use them, again.
    local sets
    sets="$(sed 's/^/swaymsg -q /' "$SWAY_THEME")"
    expect "sway: no reload, no i3; the colors, then the lines that use them" "$sets
swaymsg -q output * bg \$baseA2 solid_color
swaymsg -q client.unfocused            \$baseA2 \$baseA2 \$baseB1 \$baseA1
swaymsg -q client.focused              \$green  \$green  \$baseB3 \$blue
swaymsg -q bindsym \$mod+j exec sway-easyfocus --label-background-color '\$baseA2' --focused-text-color '\$baseB3' focus" \
        "$(grep -E '^(swaymsg|i3-msg)' "$CALLS")"
    expect "sway: light GTK 3" $'[Settings]\ngtk-application-prefer-dark-theme=0' "$(gtk_ini 3.0)"

    # The same palette as the X resources, in the order of the i3 config.
    run "'prefer-dark'" light > /dev/null
    local want
    want="$(sed 's/^i3wm\.\([A-Za-z0-9]*\): /\1 /' "$RESOURCES")"
    expect "sway colors: light, as the X resources" "$want" "$(sway_sets "$SWAY_THEME")"
    expect "sway colors: only the 9 set lines" "9" "$(wc -l < "$SWAY_THEME")"
    expect "light fuzzel: colors section first" "[colors]" "$(head -n 1 "$FUZZEL_THEME")"
    # Entries as unfocused window titles, the selection as the focused one.
    expect "light fuzzel: background is base2" "eee8d5ff" "$(fuzzel background)"
    expect "light fuzzel: text is base01" "586e75ff" "$(fuzzel text)"
    expect "light fuzzel: selection is green" "859900ff" "$(fuzzel selection)"
    expect "light fuzzel: selection text is base03" "002b36ff" "$(fuzzel selection-text)"
    expect "light fuzzel: border is green" "859900ff" "$(fuzzel border)"
    expect "light fuzzel: match is orange" "cb4b16ff" "$(fuzzel match)"
    local bad
    bad="$(grep -vE '^\[colors\]$|^[a-z-]+=[0-9a-f]{8}$' "$FUZZEL_THEME" || true)"
    expect "fuzzel: RRGGBBAA values only" "" "$bad"

    # X too: a sway login after a switch in i3 gets the colors.
    run "'prefer-light'" dark > /dev/null
    want="$(sed 's/^i3wm\.\([A-Za-z0-9]*\): /\1 /' "$RESOURCES")"
    expect "X writes the sway colors too: dark" "$want" "$(sway_sets "$SWAY_THEME")"
    expect "dark fuzzel: background is base02" "073642ff" "$(fuzzel background)"
    expect "dark fuzzel: text is base1" "93a1a1ff" "$(fuzzel text)"
    expect "dark fuzzel: selection text is base3" "fdf6e3ff" "$(fuzzel selection-text)"
    expect "X: reloads i3 only" "i3-msg -q reload" "$(grep -E '^(swaymsg|i3-msg)' "$CALLS")"
    local file files=()
    for file in "$HOME_DIR/.config/sway.d"/* "$HOME_DIR/.local/state/theme"/*; do
        files+=("${file##*/}")
    done
    expect "no temporary files left" "fuzzel.ini;theme.conf" "$(printf '%s\n' "${files[@]}" | sort | paste -sd ';')"

    # The sway config (session) before ~/.config/sway.d: dark defaults.
    if [[ ! -f "$SWAY_CONFIG" ]]; then
        echo "skip: no .config/sway/config"
        return
    fi
    local name fallback count=0
    while read -r name fallback; do
        count=$((count + 1))
        expect "sway default $name is dark" "$(sed -n "s/^set \\\$$name //p" "$SWAY_THEME")" "$fallback"
    done < <(sed -n '/^include ~\/.config\/sway.d/q; p' "$SWAY_CONFIG" | sway_sets /dev/stdin \
        | grep -E '^(baseA[0-3]|baseB[0-3]|custom) ')
    expect "sway config has every themed color" "9" "$count"
}

resource() { sed -n "s/^i3wm\.$1: //p" "$RESOURCES"; }

gtk_ini() { cat "$TMP/config/gtk-$1/settings.ini"; }

main() {
    write_stubs

    expect "show: no preference is dark" "dark" "$(run "'default'" show)"
    expect "show: prefer-light is light" "light" "$(run "'prefer-light'" show)"
    expect "show: prefer-dark is dark" "dark" "$(run "'prefer-dark'" show)"

    run "'prefer-dark'" light > /dev/null
    expect "light sets the color-scheme" "'prefer-light'" "$(cat "$SCHEME")"
    expect "light: background is base3" "#fdf6e3" "$(resource baseA3)"
    expect "light: text is base03" "#002b36" "$(resource baseB3)"
    if grep -qx 'i3-msg -q reload' "$CALLS"; then ok "light reloads i3"; else fail "light did not reload i3"; fi

    expect "light: GTK 3 prefers light" $'[Settings]\ngtk-application-prefer-dark-theme=0' "$(gtk_ini 3.0)"
    expect "light: GTK 4 prefers light" $'[Settings]\ngtk-application-prefer-dark-theme=0' "$(gtk_ini 4.0)"

    run "'prefer-light'" dark > /dev/null
    expect "dark sets the color-scheme" "'prefer-dark'" "$(cat "$SCHEME")"
    expect "dark: background is base03" "#002b36" "$(resource baseA3)"
    expect "dark: GTK 3 prefers dark" $'[Settings]\ngtk-application-prefer-dark-theme=1' "$(gtk_ini 3.0)"

    # Other settings stay; the key goes into the [Settings] section.
    printf '[Settings]\ngtk-font-name=Menlo 10\n\n[Other]\nx=1\n' > "$TMP/config/gtk-3.0/settings.ini"
    run "'prefer-light'" dark > /dev/null
    expect "dark keeps other GTK settings" \
        $'[Settings]\ngtk-application-prefer-dark-theme=1\ngtk-font-name=Menlo 10\n\n[Other]\nx=1' "$(gtk_ini 3.0)"
    run "'prefer-dark'" light > /dev/null
    expect "light replaces the key in place" \
        $'[Settings]\ngtk-application-prefer-dark-theme=0\ngtk-font-name=Menlo 10\n\n[Other]\nx=1' "$(gtk_ini 3.0)"
    printf '[Other]\nx=1\n' > "$TMP/config/gtk-3.0/settings.ini"
    run "'prefer-light'" dark > /dev/null
    expect "dark adds a missing [Settings] section" \
        $'[Other]\nx=1\n[Settings]\ngtk-application-prefer-dark-theme=1' "$(gtk_ini 3.0)"

    run "'prefer-light'" toggle > /dev/null
    expect "toggle from light is dark" "'prefer-dark'" "$(cat "$SCHEME")"
    run "'default'" toggle > /dev/null
    expect "toggle from no preference is light" "'prefer-light'" "$(cat "$SCHEME")"

    run "'default'" restore > /dev/null
    expect "restore writes the dark preference" "'prefer-dark'" "$(cat "$SCHEME")"
    expect "restore merges the dark resources" "#002b36" "$(resource baseA3)"

    if run "'default'" blue > /dev/null 2>&1; then
        fail "unknown theme accepted"
    else
        ok "unknown theme rejected"
    fi

    # Before `theme restore` runs (or without X resources) i3 uses the
    # fallbacks; they must be the dark palette.
    run "'default'" dark > /dev/null
    local name fallback count=0
    while read -r name fallback; do
        count=$((count + 1))
        expect "i3 fallback $name is dark" "$(resource "$name")" "$fallback"
    done < <(sed -n 's/^set_from_resource \$\([A-Za-z0-9]*\) i3wm\.[A-Za-z0-9]* \(#[0-9a-f]*\)$/\1 \2/p' "$I3_CONFIG")
    expect "i3 config reads every themed color" "9" "$count"

    test_sway
    exit "$FAILED"
}

main "$@"
