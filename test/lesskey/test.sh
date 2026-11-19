#!/usr/bin/env bash
#
# less key bindings (.lesskey) on every distro: bootstrap's install_lesskey
# links ~/.lesskey; less 582+ reads that source file, older less (AL2: 458)
# only the binary ~/.less, which lesskey compiles from it. Runs less in a
# pseudo terminal (script) with 10 rows and types `(`, the repo's
# forw-screen key (unbound in plain less), then `q`: the screen must move
# to the lines after the first page.
#
# Usage: test/lesskey/test.sh [image ...]
#        (default: fedora:45 debian:12 amazonlinux:2)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT

images=("$@")
(( ${#images[@]} )) || images=(fedora:45 debian:12 amazonlinux:2)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
sed -n -e '/^readonly LESSKEY_SOURCE_MIN_VERSION=/p' -e '/^install_lesskey() {/,/^}/p' "$ROOT/bootstrap.sh" >"$TMP/install.sh"
if ! grep -q 'install_lesskey() {' "$TMP/install.sh"; then
    echo "FAIL: bootstrap.sh has no install_lesskey"
    exit 1
fi
cp "$ROOT/.lesskey" "$TMP/lesskey-src"

cat >"$TMP/run.sh" <<'EOF'
set -euo pipefail
if command -v apt-get >/dev/null; then
    apt-get update -qq >/dev/null && apt-get install -y -qq less bsdutils >/dev/null 2>&1
elif command -v dnf >/dev/null; then
    dnf install -y -q less util-linux-script >/dev/null 2>&1 || dnf install -y -q less util-linux >/dev/null 2>&1
else
    yum install -y -q less util-linux >/dev/null 2>&1
fi
useradd -m u
mkdir -p /src && cp /t/lesskey-src /src/.lesskey && chmod -R a+rX /src
cat >/home/u/t.sh <<'IN'
set -euo pipefail
DOTFILES_DIR=/src
HOME=/home/u
log() { echo "$*"; }
warn() { echo "warn: $*"; }
link() { mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; }
. /t/install.sh
install_lesskey
install_lesskey
seq -f 'line %03g' 200 >/home/u/f.txt
unset LESS
export TERM=xterm
{ sleep 1; printf '('; sleep 1; printf q; } |
    script -qec 'stty rows 10 cols 80; less /home/u/f.txt' /dev/null >/home/u/out 2>&1 || true
IN
su u -c 'bash /home/u/t.sh'
echo "less: $(less --version | sed -n 1p)"
[ -L /home/u/.lesskey ] && echo "link: ok" || echo "link: missing"
if grep -q 'line 015' /home/u/out; then echo "forward: ok"; else echo "forward: no"; fi
EOF

failed=0
for image in "${images[@]}"; do
    out="$(docker run --rm -v "$TMP:/t:ro,z" "$image" bash /t/run.sh 2>&1)" || true
    if grep -q '^link: ok' <<<"$out" && grep -q '^forward: ok' <<<"$out"; then
        printf 'ok:   %s (%s)\n' "$image" "$(sed -n 's/^less: //p' <<<"$out")"
    else
        printf 'FAIL: %s\n%s\n' "$image" "$out"
        failed=1
    fi
done
exit "$failed"
