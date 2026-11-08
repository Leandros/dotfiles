#!/usr/bin/env bash
#
# Runs fetch_unpack from bootstrap.sh with a failing curl stub: a failed
# download must stop the caller with the URL in the error. fetch_unpack runs
# in $(...), where bash does not apply set -e, so tar and ./configure used to
# fail on the missing file instead (GitHub 502 in the debian12 run).
#
# Usage: test/fetch/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BOOTSTRAP="$HERE/../../bootstrap.sh"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" FUNCS="$TMP/funcs.sh"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

# die, fetch and fetch_unpack, as defined in bootstrap.sh.
{
    grep '^die() ' "$BOOTSTRAP"
    sed -n '/^fetch() {$/,/^}$/p; /^fetch_unpack() {$/,/^}$/p' "$BOOTSTRAP"
} > "$FUNCS"

mkdir -p "$STUBS" "$TMP/work"
# curl fails like a server error after its retries.
printf '#!/bin/sh\necho "curl: (22) The requested URL returned error: 502" >&2\nexit 22\n' > "$STUBS/curl"
chmod +x "$STUBS/curl"

# A caller as in bootstrap.sh: set -e, the result assigned on its own line.
out="$(PATH="$STUBS:$PATH" WORK_DIR="$TMP/work" bash -c "
    set -euo pipefail
    source '$FUNCS'
    install_x() {
        local dir
        dir=\"\$(fetch_unpack https://example.invalid/x-1.0.tar.gz)\"
        echo 'continued after a failed download'
    }
    install_x
" 2>&1)" && rc=0 || rc=$?

if [[ $rc -ne 0 ]]; then ok "a failed download stops the caller"; else fail "caller went on (rc 0)"; fi
if [[ "$out" == *"continued after a failed download"* ]]; then fail "caller went on: $out"; else ok "nothing runs after the failed download"; fi
if [[ "$out" == *"download failed: https://example.invalid/x-1.0.tar.gz"* ]]; then ok "error names the URL"; else fail "error: $out"; fi
if [[ "$out" == *"Cannot open"* || "$out" == *"tar (child)"* ]]; then fail "tar ran on the missing file: $out"; else ok "tar does not run"; fi

exit "$FAILED"
