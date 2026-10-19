#!/usr/bin/env bash
#
# Runs bootstrap.sh inside Docker for each supported Linux distro, twice
# (fresh install, then re-run), then runs verify.sh.
#
# Usage:
#   test/bootstrap/run.sh                 all distros
#   test/bootstrap/run.sh al2 debian12    subset (debian12 ubuntu2204 fedora44 rocky9 al2 al2023)
#
# The working tree (including uncommitted changes) is snapshotted into a
# temporary git repository that bootstrap.sh clones from, so the test covers
# exactly the files on disk.
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
readonly HERE REPO
readonly LOG_DIR="$HERE/logs"
readonly ALL_DISTROS="debian12 ubuntu2204 fedora44 rocky9 al2 al2023"
readonly IMAGE_PREFIX="dotfiles-bootstrap"

base_image() {
    case "$1" in
        debian12)   echo "debian:12" ;;
        ubuntu2204) echo "ubuntu:22.04" ;;
        fedora44)   echo "fedora:44" ;;
        rocky9)     echo "rockylinux:9" ;;
        al2)        echo "amazonlinux:2" ;;
        al2023)     echo "amazonlinux:2023" ;;
        *) echo "unknown distro: $1" >&2; exit 1 ;;
    esac
}

# Only what a minimal VM image is expected to have: sudo and user tooling.
pkg_cmd() {
    case "$1" in
        debian12|ubuntu2204) echo "apt-get update -q && apt-get install -y -q --no-install-recommends sudo && rm -rf /var/lib/apt/lists/*" ;;
        al2)                 echo "yum install -y -q sudo shadow-utils && yum clean all" ;;
        al2023|fedora44|rocky9) echo "dnf install -y -q sudo shadow-utils && dnf clean all" ;;
    esac
}

snapshot_repo() {
    local snap="$1"
    rm -rf "$snap"
    mkdir -p "$snap"
    # The container user must be able to read it.
    chmod 755 "$snap"
    git -C "$REPO" ls-files -co --exclude-standard -z \
        | rsync -a --files-from=- --from0 "$REPO/" "$snap/"
    git -C "$snap" init -q -b master
    git -C "$snap" -c user.name=test -c user.email=test@localhost add -A
    git -C "$snap" -c user.name=test -c user.email=test@localhost commit -q -m snapshot
}

run_distro() {
    local distro="$1" snap="$2"
    local image="$IMAGE_PREFIX-$distro" log="$LOG_DIR/$distro.log"
    local base
    base="$(base_image "$distro")"

    echo "== $distro: build image"
    docker build -q -t "$image" \
        --build-arg BASE="$base" \
        --build-arg PKG_CMD="$(pkg_cmd "$distro")" \
        "$HERE" >/dev/null

    echo "== $distro: bootstrap (log: $log)"
    if docker run --rm \
        -v "$snap:/src:ro" \
        -e BOOTSTRAP_DOTFILES_REPO=/src \
        -e BOOTSTRAP_DOTFILES_REF=master \
        -e BOOTSTRAP_NONINTERACTIVE=1 \
        -e BOOTSTRAP_XORG=1 \
        -e BOOTSTRAP_DPI_SCALE=1.5 \
        "$image" bash -c '
            set -euo pipefail
            # /src is owned by the host user; git refuses it otherwise.
            printf "[safe]\n\tdirectory = *\n" > /tmp/gitconfig
            export GIT_CONFIG_GLOBAL=/tmp/gitconfig
            echo "##### run 1"; time bash /src/bootstrap.sh
            echo "##### run 2"; time bash /src/bootstrap.sh
            echo "##### verify"; bash /src/test/bootstrap/verify.sh /src
        ' >"$log" 2>&1; then
        echo "== $distro: PASS"
    else
        echo "== $distro: FAIL (see $log)"
        return 1
    fi
}

main() {
    local distros="${*:-$ALL_DISTROS}" snap failed=0
    mkdir -p "$LOG_DIR"
    snap="$(mktemp -d)"
    trap 'rm -rf "$snap"' EXIT
    snapshot_repo "$snap"

    local d
    for d in $distros; do
        run_distro "$d" "$snap" || failed=1
    done
    exit "$failed"
}

main "$@"
