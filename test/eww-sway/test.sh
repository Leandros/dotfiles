#!/usr/bin/env bash
#
# Runs bin/bar and the repo's eww config under a real headless sway with
# two outputs, in a fedora:45 container with eww built at EWW_REF
# (bootstrap.sh) with both backends: one bar per output, each on its
# output by connector name, the tray on the first one, and bars again
# after an output is disabled and enabled, and after bar runs again.
#
# The image (dotfiles-eww-sway, test/eww-sway/Dockerfile) is built once
# per EWW_REF; the eww build takes some minutes.
#
# Usage: test/eww-sway/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
readonly HERE REPO
readonly IMAGE="dotfiles-eww-sway"
readonly CONTAINER="dotfiles-eww-sway-$$"
readonly USER_HOME="/home/t"

eww_ref() { sed -n 's/^readonly EWW_REF="\(.*\)"$/\1/p' "$REPO/bootstrap.sh"; }

build_image() {
    local ref
    ref="$(eww_ref)"
    [[ -n "$ref" ]] || { echo "no EWW_REF in bootstrap.sh" >&2; exit 1; }
    if [[ "$(docker image inspect -f '{{index .Config.Labels "eww-ref"}}' "$IMAGE" 2>/dev/null)" == "$ref" ]]; then
        return
    fi
    echo "building $IMAGE (eww $ref)"
    docker build -q -t "$IMAGE" --build-arg EWW_REF="$ref" "$HERE" > /dev/null
}

# docker cp, not bind mounts: SELinux labels on the host.
copy_files() {
    local file
    docker exec "$CONTAINER" mkdir -p "$USER_HOME/bin" "$USER_HOME/.config"
    for file in bar pkill-display wm-msg; do
        docker cp "$REPO/bin/$file" "$CONTAINER:$USER_HOME/bin/$file"
    done
    docker cp "$REPO/.config/eww" "$CONTAINER:$USER_HOME/.config/eww"
    docker cp "$HERE/in-container.sh" "$CONTAINER:/tmp/in-container.sh"
}

main() {
    command -v docker > /dev/null || { echo "SKIP: docker not installed"; exit 0; }
    build_image
    # --init reaps orphans: the checks count processes.
    docker create --init --cap-add SYS_NICE --name "$CONTAINER" "$IMAGE" sleep infinity > /dev/null
    trap 'docker rm -f "$CONTAINER" > /dev/null 2>&1 || true' EXIT
    docker start "$CONTAINER" > /dev/null
    copy_files
    docker exec "$CONTAINER" bash /tmp/in-container.sh
}

main "$@"
