#!/usr/bin/env bash
#
# Tests the install category choice of bootstrap.sh: BOOTSTRAP_CATEGORIES,
# the BOOTSTRAP_XORG=1 alias, the prompt, and the basic-only default without
# a terminal. Runs the functions from bootstrap.sh, nothing is installed.
#
# Usage: test/categories/test.sh
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

# The category functions and what they use, as defined in bootstrap.sh.
{
    grep -E '^(log|warn|die)\(\) ' "$BOOTSTRAP"
    grep -E '^readonly (XORG_DISTROS|RHEL_XORG_MAX_MAJOR|OPTIONAL_CATEGORIES)=' "$BOOTSTRAP"
    sed -n '/^xorg_supported() {$/,/^}$/p' "$BOOTSTRAP"
    sed -n '/^category_[a-z_]*() {$/,/^}$/p; /^[a-z]*_categories() {$/,/^}$/p' "$BOOTSTRAP"
} > "$FUNCS"

# Runs bash code with the functions loaded; DISTRO and DISTRO_MAJOR as given.
# Unset BOOTSTRAP_* unless the caller passes them.
run() {
    local distro="$1" code="$2"
    shift 2
    env -u BOOTSTRAP_CATEGORIES -u BOOTSTRAP_XORG "$@" bash -c "
        set -euo pipefail
        DISTRO='$distro' DISTRO_MAJOR=9 CATEGORIES=''
        source '$FUNCS'
        $code
    "
}

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: want '$want', got '$got'"; fi
}

# parse_categories: order follows OPTIONAL_CATEGORIES, duplicates collapse.
parse() { run fedora "parse_categories '$1'" 2>&1; }
expect "parse devtools desktop" "devtools desktop" "$(parse "devtools desktop")"
expect "parse keeps a fixed order" "devtools desktop" "$(parse "desktop devtools")"
expect "parse all" "devtools desktop" "$(parse "all")"
expect "parse basic is implied" "" "$(parse "basic")"
expect "parse empty" "" "$(parse "")"
expect "parse duplicates" "devtools" "$(parse "devtools devtools")"
out="$(parse "devtools bogus")" && rc=0 || rc=$?
if [[ $rc -ne 0 && "$out" == *"unknown category: bogus"* ]]; then
    ok "unknown category stops"
else
    fail "unknown category (rc $rc): $out"
fi

# choose_categories from the environment: no prompt, even with a terminal.
# shellcheck disable=SC2016 # $CATEGORIES expands in the inner bash.
choose() { run "$1" 'choose_categories </dev/null; echo "CAT=$CATEGORIES"' "${@:2}" 2>&1; }
expect "env devtools" "CAT=devtools" "$(choose fedora BOOTSTRAP_CATEGORIES=devtools)"
expect "env all" "CAT=devtools desktop" "$(choose fedora BOOTSTRAP_CATEGORIES=all)"
expect "env empty means basic only" "CAT=" "$(choose fedora BOOTSTRAP_CATEGORIES=)"
expect "BOOTSTRAP_XORG=1 alone is desktop" "CAT=desktop" "$(choose fedora BOOTSTRAP_XORG=1)"
expect "BOOTSTRAP_XORG=1 adds desktop" "CAT=devtools desktop" \
    "$(choose fedora BOOTSTRAP_XORG=1 BOOTSTRAP_CATEGORIES=devtools)"
expect "BOOTSTRAP_XORG=0 adds nothing" "CAT=devtools" \
    "$(choose fedora BOOTSTRAP_XORG=0 BOOTSTRAP_CATEGORIES=devtools)"

out="$(choose amzn2 BOOTSTRAP_CATEGORIES=all)"
if [[ "$out" == *"desktop"*"skipping"* && "$out" == *"CAT=devtools" ]]; then
    ok "desktop on an unsupported distro: warn and skip"
else
    fail "desktop on amzn2: $out"
fi
# shellcheck disable=SC2016 # $CATEGORIES expands in the inner bash.
out="$(run rhel 'DISTRO_MAJOR=10; choose_categories </dev/null; echo "CAT=$CATEGORIES"' BOOTSTRAP_CATEGORIES=desktop 2>&1)"
if [[ "$out" == *"skipping"* && "$out" == *"CAT=" ]]; then ok "desktop on RHEL 10 skipped"; else fail "desktop on RHEL 10: $out"; fi

# No environment and no terminal: basic only, without a prompt.
out="$(choose fedora)"
expect "no env, no terminal: basic only" "CAT=" "$(grep '^CAT=' <<< "$out")"
if [[ "$out" == *"select"* ]]; then fail "prompted without a terminal: $out"; else ok "no prompt without a terminal"; fi

# prompt_categories reads the numbers of the offered categories.
prompt() { run "$1" "prompt_categories <<< '$2'" 2>&1; }
out="$(prompt fedora "1 2")"
if [[ "$out" == *"1) dev tools"* && "$out" == *"2) desktop environment"* && "$out" == *"basic is always installed"* ]]; then
    ok "prompt lists the categories"
else
    fail "prompt list: $out"
fi
expect "prompt 1 2" "devtools desktop" "$(tail -n 1 <<< "$out")"
expect "prompt 2" "desktop" "$(prompt fedora "2" | tail -n 1)"
expect "prompt empty: basic only" "" "$(prompt fedora "" | tail -n 1)"
out="$(prompt fedora "3")" && rc=0 || rc=$?
if [[ $rc -ne 0 && "$out" == *"invalid category choice: 3"* ]]; then ok "prompt rejects 3"; else fail "prompt 3 (rc $rc): $out"; fi
out="$(prompt fedora "x")" && rc=0 || rc=$?
if [[ $rc -ne 0 && "$out" == *"invalid category choice: x"* ]]; then ok "prompt rejects x"; else fail "prompt x (rc $rc): $out"; fi

# Where the desktop cannot be installed it is not offered.
out="$(prompt amzn2 "1")"
if [[ "$out" == *"1) dev tools"* && "$out" != *"desktop environment"* ]]; then
    ok "amzn2 prompt offers no desktop"
else
    fail "amzn2 prompt: $out"
fi
expect "amzn2 prompt 1" "devtools" "$(tail -n 1 <<< "$out")"
out="$(prompt amzn2 "2")" && rc=0 || rc=$?
if [[ $rc -ne 0 ]]; then ok "amzn2 prompt rejects 2"; else fail "amzn2 prompt 2 accepted: $out"; fi

# With a terminal and no environment, choose_categories prompts.
if command -v script >/dev/null; then
    out="$(printf '1\n' | env -u BOOTSTRAP_CATEGORIES -u BOOTSTRAP_XORG script -qec "bash -c '
        set -euo pipefail
        DISTRO=fedora DISTRO_MAJOR=43 CATEGORIES=
        source $FUNCS
        choose_categories
        echo CAT=\$CATEGORIES.
    '" /dev/null 2>&1 | tr -d '\r')"
    if [[ "$out" == *"select"* && "$out" == *"CAT=devtools."* ]]; then
        ok "terminal without env: prompt"
    else
        fail "terminal prompt: $out"
    fi

    # BOOTSTRAP_XORG=1 selects desktop but still asks for the others.
    out="$(printf '1\n' | env -u BOOTSTRAP_CATEGORIES BOOTSTRAP_XORG=1 script -qec "bash -c '
        set -euo pipefail
        DISTRO=fedora DISTRO_MAJOR=43 CATEGORIES=
        source $FUNCS
        choose_categories
        echo CAT=\$CATEGORIES.
    '" /dev/null 2>&1 | tr -d '\r')"
    if [[ "$out" == *"select"* && "$out" == *"CAT=devtools desktop."* ]]; then
        ok "BOOTSTRAP_XORG=1 on a terminal: prompt, plus desktop"
    else
        fail "BOOTSTRAP_XORG=1 terminal prompt: $out"
    fi
fi

exit "$FAILED"
