#!/usr/bin/env bash
#
# patches/alacritty-touchpad-scroll.patch against the pinned crate
# (ALACRITTY_VERSION in bootstrap.sh): it applies, and the crate's input
# tests pass, among them the patch's own. Alacritty 0.17 drops
# scrolling.multiplier for programs that read the mouse (mouse mode: Claude
# Code, nvim, less); with sway's touchpad scroll_factor 0.1 a swipe there
# was a report or two. The patch keeps the multiplier for touchpad (pixel)
# deltas; a wheel notch stays one report.
#
# Needs network (crates.io), cargo, and the font and xcb development files;
# skips without them.
#
# Usage: test/alacritty-patch/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO="$HERE/../.."
readonly PATCH="$REPO/patches/alacritty-touchpad-scroll.patch"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

main() {
    command -v cargo >/dev/null || { echo "SKIP: no cargo"; exit 0; }
    pkg-config --exists fontconfig freetype2 xcb xkbcommon 2>/dev/null ||
        { echo "SKIP: font, xcb or xkbcommon development files missing"; exit 0; }

    local version src
    version="$(sed -n 's/^readonly ALACRITTY_VERSION="\(.*\)"$/\1/p' "$REPO/bootstrap.sh")"
    curl -fsSL "https://static.crates.io/crates/alacritty/alacritty-$version.crate" | tar -xz -C "$TMP"
    src="$TMP/alacritty-$version"

    if patch -d "$src" -p1 -s --dry-run < "$PATCH" >/dev/null; then
        ok "patch applies to $version"
    else
        fail "patch does not apply to $version"
        exit "$FAILED"
    fi
    patch -d "$src" -p1 -s < "$PATCH"

    # --locked: the patch adds no dependency, so bootstrap's --locked
    # install still works.
    local out
    if out="$(cd "$src" && cargo test --locked --quiet -- input:: 2>&1)"; then
        ok "input tests pass with the patch ($(grep -o '[0-9]* passed' <<< "$out" | head -n 1))"
    else
        fail "input tests: $(grep -E 'panicked|left:|right:|error' <<< "$out" | head -n 6 | tr '\n' ' ')"
    fi
    if grep -q 'scroll_multiplier_in_mouse_mode \.\.\. ok\|test input::tests::scroll_multiplier_in_mouse_mode' <<< "$out" \
        || (cd "$src" && cargo test --locked --quiet -- --list 2>/dev/null | grep -q 'scroll_multiplier_in_mouse_mode'); then
        ok "the patch's test ran"
    else
        fail "scroll_multiplier_in_mouse_mode not found"
    fi
    exit "$FAILED"
}

main "$@"
