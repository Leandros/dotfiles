#!/usr/bin/env bash
#
# Runs bin/theme with stubs for xrdb, gsettings and i3-msg and checks the X
# resources, the color-scheme and the i3 reload. Also checks that the i3
# config falls back to the dark palette.
#
# Usage: test/theme/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/theme"
readonly I3_CONFIG="$HERE/../../.config/i3/config"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" SCHEME="$TMP/scheme" RESOURCES="$TMP/resources"
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
    cat > "$STUBS/i3-msg" <<EOF
#!/bin/sh
echo "i3-msg \$*" >> "$CALLS"
EOF
    chmod +x "$STUBS/gsettings" "$STUBS/xrdb" "$STUBS/i3-msg"
}

# Runs theme with the color-scheme set to SCHEME_VALUE; prints its stdout.
run() {
    local scheme_value="$1"
    shift
    echo "$scheme_value" > "$SCHEME"
    : > "$CALLS"
    : > "$RESOURCES"
    DISPLAY=:99 XDG_CONFIG_HOME="$TMP/config" PATH="$STUBS:$PATH" "$SCRIPT" "$@"
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

    exit "$FAILED"
}

main "$@"
