#!/usr/bin/env bash
#
# patches/sway-easyfocus-title-bar-x.patch against the pinned crate
# (SWAY_EASYFOCUS_VERSION in bootstrap.sh): it applies, and the crate's
# tests pass, among them the patch's own (labels of split, tabbed and
# untitled windows, from a real sway tree). Without the patch the label of
# a window at x = 1024 lands at 2054, off a 2048 px output.
#
# Needs network (crates.io), cargo, and the gtk4 and gtk4-layer-shell
# development files; skips without them.
#
# Usage: test/sway-easyfocus-patch/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO="$HERE/../.."
readonly PATCH="$REPO/patches/sway-easyfocus-title-bar-x.patch"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

main() {
    command -v cargo >/dev/null || { echo "SKIP: no cargo"; exit 0; }
    pkg-config --exists gtk4 gtk4-layer-shell-0 2>/dev/null ||
        { echo "SKIP: gtk4 or gtk4-layer-shell development files missing"; exit 0; }

    local version src
    version="$(sed -n 's/^readonly SWAY_EASYFOCUS_VERSION="\(.*\)"$/\1/p' "$REPO/bootstrap.sh")"
    curl -fsSL "https://static.crates.io/crates/sway-easyfocus/sway-easyfocus-$version.crate" |
        tar -xz -C "$TMP"
    src="$TMP/sway-easyfocus-$version"

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
    if out="$(cd "$src" && cargo test --locked --quiet 2>&1)"; then
        ok "crate tests pass with the patch ($(grep -o '[0-9]* passed' <<< "$out" | head -n 1))"
    else
        fail "crate tests: $(grep -E 'panicked|left:|right:|error' <<< "$out" | head -n 6 | tr '\n' ' ')"
    fi
    exit "$FAILED"
}

main "$@"
