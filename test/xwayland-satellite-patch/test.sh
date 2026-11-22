#!/usr/bin/env bash
#
# patches/xwayland-satellite-clipboard-timestamp.patch against the pinned
# release (XWAYLAND_SATELLITE_VERSION in bootstrap.sh), in a fedora:45
# container: the patch applies, the release builds as bootstrap builds it
# (no .git), and the patch's integration test passes: a clipboard taken
# from Wayland answers TIMESTAMP with the time satellite took it, later
# than the X client's before it; PRIMARY answers none. VMware Workstation
# picks the selection it copies into the guest by these times.
#
# Only that test: upstream's other integration tests wait 50 to 100 ms for
# events and fail or hang now and then on a loaded machine, with and
# without the patch.
#
# Needs docker and network (GitHub, crates.io).
#
# Usage: test/xwayland-satellite-patch/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
readonly IMAGE="fedora:45"
readonly PATCH="$ROOT/patches/xwayland-satellite-clipboard-timestamp.patch"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

VERSION="$(sed -n 's/^readonly XWAYLAND_SATELLITE_VERSION="\(.*\)"$/\1/p' "$ROOT/bootstrap.sh")"
readonly VERSION

read -r -d '' INNER <<'EOF' || true
set -euo pipefail
dnf install -y -q cargo rust gcc patch libxcb-devel xcb-util-cursor-devel clang-devel \
    xorg-x11-server-Xwayland >/dev/null 2>&1
mkdir /build
curl -fsSL "https://github.com/Supreeeme/xwayland-satellite/archive/refs/tags/v$VERSION.tar.gz" |
    tar -xz -C /build
cd "/build/xwayland-satellite-$VERSION"
if patch -p1 -s --dry-run < /patch >/dev/null; then echo "== applies"; else echo "== no-apply"; exit 0; fi
patch -p1 -s < /patch
cargo build -q --locked >/build/log 2>&1 && echo "== builds" || { echo "== no-build"; tail -n 20 /build/log; exit 0; }
echo "== version $(target/debug/xwayland-satellite -version 2>&1)"
mkdir -m 0700 /tmp/runtime
export XDG_RUNTIME_DIR=/tmp/runtime
cargo test -q --locked --test integration -- --exact clipboard_timestamp_from_wayland 2>&1 | tail -n 15
EOF

main() {
    command -v docker >/dev/null || { echo "SKIP: no docker"; exit 0; }
    local name out
    name="dotfiles-xwayland-satellite-$$"
    docker create --name "$name" -e VERSION="$VERSION" "$IMAGE" bash -c "$INNER" > /dev/null
    trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT
    # Copied, not mounted: SELinux denies bind mounts.
    docker cp "$PATCH" "$name:/patch" > /dev/null
    out="$(docker start -a "$name" 2>&1)"

    if grep -qx '== applies' <<< "$out"; then
        ok "patch applies to $VERSION"
    else
        fail "patch does not apply to $VERSION"
        exit "$FAILED"
    fi
    if grep -qx '== builds' <<< "$out"; then
        ok "builds without .git"
    else
        fail "build: $(sed -n '/^== no-build/,$p' <<< "$out" | tail -n 8 | tr '\n' ' ')"
        exit "$FAILED"
    fi
    if grep -qx "== version $VERSION" <<< "$out"; then
        ok "-version prints $VERSION"
    else
        fail "-version: $(grep '^== version' <<< "$out")"
    fi
    if grep -q 'test result: ok. 1 passed' <<< "$out"; then
        ok "clipboard TIMESTAMP test passes"
    else
        fail "clipboard TIMESTAMP test: $(grep -E 'panicked|clipboard taken|assert|No X11' <<< "$out" | head -n 4 | tr '\n' ' ')"
    fi
    exit "$FAILED"
}

main "$@"
