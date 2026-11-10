#!/usr/bin/env bash
#
# Tests check_idle_settings from bootstrap.sh: whole positive minutes, and
# the suspend after the lock. .xprofile hands xidlehook the difference as
# the suspend timer, which must be positive.
#
# Usage: test/idle-settings/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BOOTSTRAP="$HERE/../../bootstrap.sh"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly FUNCS="$TMP/funcs.sh"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

{
    grep -E '^(log|warn|die)\(\) ' "$BOOTSTRAP"
    sed -n '/^check_idle_settings() {$/,/^}$/p' "$BOOTSTRAP"
} > "$FUNCS"

# Exit code of check_idle_settings with these settings.
check() {
    local rc=0
    bash -c "
        set -euo pipefail
        IDLE_LOCK_MINUTES='$1' IDLE_SUSPEND_MINUTES='$2'
        source '$FUNCS'
        check_idle_settings
    " >/dev/null 2>&1 || rc=$?
    echo "$rc"
}

expect_ok()   { if [[ "$(check "$2" "$3")" == 0 ]]; then ok "$1"; else fail "$1: rejected"; fi; }
expect_fail() { if [[ "$(check "$2" "$3")" != 0 ]]; then ok "$1"; else fail "$1: accepted"; fi; }

main() {
    expect_ok   "lock 5, suspend 10" 5 10
    expect_fail "suspend equal to the lock" 10 10
    expect_fail "suspend before the lock" 10 5
    expect_fail "zero minutes" 0 10
    expect_fail "not a number" five 10
    exit "$FAILED"
}

main "$@"
