#!/usr/bin/env bash
#
# Runs install_swaytiles from bootstrap.sh with stubs: in a running sway
# session (sway-session.target active) it starts the user unit, and
# restarts it after an install or update, so the new version runs. Enabling
# alone waits for the next login, and without the daemon the layout chosen
# in the $mod+t menu went nowhere. Outside a sway session (i3, no user
# manager) it only enables the unit.
#
# Usage: test/swaytiles/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }
expect() { if [[ "$3" == "$2" ]]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi; }

sed -n '/^install_swaytiles() {$/,/^}$/p' "$ROOT/bootstrap.sh" >"$TMP/funcs.sh"
[[ -s "$TMP/funcs.sh" ]] || { echo "FAIL: install_swaytiles missing in bootstrap.sh"; exit 1; }

# run CURRENT MANAGER TARGET: CURRENT 1 when the stamp and launcher are
# current, MANAGER 1 when the user manager answers, TARGET 1 when
# sway-session.target is active. Prints the systemctl calls that change
# something (not the queries).
run() {
    : >"$TMP/calls"
    CURRENT="$1" MANAGER="$2" TARGET="$3" bash -c '
        set -euo pipefail
        T="$2"
        SUDO="" PREFIX="$T/prefix" DOTFILES_DIR="$1" GITHUB=https://github.com SWAYTILES_REF=abc
        SWAYTILES_PATCH="$(sed -n "s/^readonly SWAYTILES_PATCH=\"\(.*\)\"\$/\1/p" "$1/bootstrap.sh")"
        die() { echo "die: $*" >&2; exit 1; }
        CALLS="$T/calls"
        is_current() { [[ "$CURRENT" == 1 ]]; }
        cmp() { [[ "$CURRENT" == 1 ]]; }
        fetch_unpack() { echo "$T/unpack"; }
        unpacked_root() { echo "$T/unpack"; }
        install() { :; }
        patch() { cat > "$T/patched"; }
        python3() { :; }
        mark_current() { :; }
        link() { :; }
        have() { [[ "$1" == systemctl ]]; }
        systemctl() {
            case "$*" in
                "--user show-environment") [[ "$MANAGER" == 1 ]] ;;
                "--user is-active -q sway-session.target") [[ "$TARGET" == 1 ]] ;;
                "--user daemon-reload") ;;
                *) echo "systemctl $*" >>"$CALLS" ;;
            esac
        }
        source "$T/funcs.sh"
        install_swaytiles
    ' _ "$ROOT" "$TMP"
    tr '\n' ';' <"$TMP/calls"
}

enable="systemctl --user enable -q swaytiles.service;"
rm -f "$TMP/patched"
expect "sway session, new install: restarted (the new version runs)" \
    "${enable}systemctl --user restart swaytiles.service;" "$(run 0 1 1)"
if cmp -s "$ROOT/patches/swaytiles-master-right-tabs.patch" "$TMP/patched"; then
    ok "install applies patches/swaytiles-master-right-tabs.patch"
else
    fail "patch not applied"
fi
if grep -q '^readonly SWAYTILES_PATCH="master-right-tabs"$' "$ROOT/bootstrap.sh"; then
    ok "SWAYTILES_PATCH names the patch (part of the stamp)"
else
    fail "SWAYTILES_PATCH missing"
fi
expect "sway session, current: started (no-op when it runs)" \
    "${enable}systemctl --user start swaytiles.service;" "$(run 1 1 1)"
expect "no sway session (i3): only enabled" "$enable" "$(run 0 1 0)"
expect "no user manager: only enabled" "$enable" "$(run 0 0 1)"

exit "$FAILED"
