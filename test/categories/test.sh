#!/usr/bin/env bash
#
# Tests the install category choice of bootstrap.sh: BOOTSTRAP_CATEGORIES,
# the BOOTSTRAP_XORG=1 handling, the menu (keys typed into a pseudo terminal),
# the distros that get each desktop, and the basic-only default without a
# terminal. Runs the functions from bootstrap.sh, nothing is installed.
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
    grep -E '^readonly (XORG_DISTROS|RHEL_XORG_MAX_MAJOR|WAYLAND_[A-Z_]+|OPTIONAL_CATEGORIES|ESC|CLEAR_LINE|ARROW_[A-Z_]+|KEY_[A-Z_]+)=' "$BOOTSTRAP"
    sed -n '/^xorg_supported() {$/,/^}$/p; /^wayland_supported() {$/,/^}$/p; /^menu_select() {$/,/^}$/p' "$BOOTSTRAP"
    sed -n '/^category_[a-z_]*() {$/,/^}$/p; /^[a-z]*_categories() {$/,/^}$/p' "$BOOTSTRAP"
} > "$FUNCS"

# A current release of each distro; Fedora 43 is the first with sway support.
default_major() {
    case "$1" in
        fedora) echo 43 ;;
        rhel)   echo 9 ;;
        debian) echo 12 ;;
        ubuntu) echo 22 ;;
        amzn2)  echo 2 ;;
        *)      echo 2023 ;;
    esac
}

# Runs bash code with the functions loaded; DISTRO as given, DISTRO_MAJOR
# from default_major unless the caller passes DISTRO_MAJOR=<n>.
# Unset BOOTSTRAP_* unless the caller passes them.
run() {
    local distro="$1" code="$2"
    shift 2
    env -u BOOTSTRAP_CATEGORIES -u BOOTSTRAP_XORG -u DISTRO_MAJOR "$@" bash -c "
        set -euo pipefail
        DISTRO='$distro' DISTRO_MAJOR=\"\${DISTRO_MAJOR:-$(default_major "$distro")}\" CATEGORIES=''
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
expect "parse keeps a fixed order" "devtools desktop desktop-wayland" "$(parse "desktop-wayland desktop devtools")"
expect "parse all" "devtools desktop desktop-wayland" "$(parse "all")"
expect "parse desktop-wayland alone" "desktop-wayland" "$(parse "desktop-wayland")"
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
expect "env all" "CAT=devtools desktop desktop-wayland" "$(choose fedora BOOTSTRAP_CATEGORIES=all)"
expect "env desktop-wayland" "CAT=desktop-wayland" "$(choose fedora BOOTSTRAP_CATEGORIES=desktop-wayland)"
expect "env empty means basic only" "CAT=" "$(choose fedora BOOTSTRAP_CATEGORIES=)"
expect "BOOTSTRAP_XORG=1 alone is desktop" "CAT=desktop" "$(choose fedora BOOTSTRAP_XORG=1)"
expect "BOOTSTRAP_XORG=1 adds desktop" "CAT=devtools desktop" \
    "$(choose fedora BOOTSTRAP_XORG=1 BOOTSTRAP_CATEGORIES=devtools)"
expect "BOOTSTRAP_XORG=1 keeps desktop-wayland" "CAT=desktop desktop-wayland" \
    "$(choose fedora BOOTSTRAP_XORG=1 BOOTSTRAP_CATEGORIES=desktop-wayland)"
expect "BOOTSTRAP_XORG=0 adds nothing" "CAT=devtools" \
    "$(choose fedora BOOTSTRAP_XORG=0 BOOTSTRAP_CATEGORIES=devtools)"

out="$(choose amzn2 BOOTSTRAP_CATEGORIES=all)"
if [[ "$out" == *"desktop:"*"skipping"* && "$out" == *"desktop-wayland:"*"skipping"* && "$out" == *"CAT=devtools" ]]; then
    ok "desktops on an unsupported distro: warn and skip"
else
    fail "desktops on amzn2: $out"
fi
# shellcheck disable=SC2016 # $CATEGORIES expands in the inner bash.
out="$(run rhel 'DISTRO_MAJOR=10; choose_categories </dev/null; echo "CAT=$CATEGORIES"' BOOTSTRAP_CATEGORIES=desktop 2>&1)"
if [[ "$out" == *"skipping"* && "$out" == *"CAT=" ]]; then ok "desktop on RHEL 10 skipped"; else fail "desktop on RHEL 10: $out"; fi

# sway: Fedora 43 and newer only. The Xorg desktop stays where it is supported.
for entry in debian:12:desktop ubuntu:22:desktop rhel:9:desktop amzn2:2: amzn2023:2023: fedora:42:desktop; do
    IFS=: read -r distro major want <<< "$entry"
    out="$(choose "$distro" BOOTSTRAP_CATEGORIES="desktop desktop-wayland" DISTRO_MAJOR="$major" || true)"
    if [[ "$out" == *"desktop-wayland:"*"skipping"* && "$out" == *"CAT=$want" ]]; then
        ok "desktop-wayland on $distro $major: warn and skip"
    else
        fail "desktop-wayland on $distro $major: $out"
    fi
done
for major in 43 44 45; do
    expect "desktop-wayland on fedora $major" "CAT=desktop-wayland" \
        "$(choose fedora BOOTSTRAP_CATEGORIES=desktop-wayland DISTRO_MAJOR="$major")"
done

# No environment and no terminal: basic only, without a prompt.
out="$(choose fedora)"
expect "no env, no terminal: basic only" "CAT=" "$(grep '^CAT=' <<< "$out")"
if [[ "$out" == *"select"* ]]; then fail "prompted without a terminal: $out"; else ok "no prompt without a terminal"; fi

# The menu needs a terminal: script(1) runs the code in a pseudo terminal and
# types the keys after a second. Unset BOOTSTRAP_* unless the caller passes
# them. Prints what the terminal showed, without CR.
readonly UP=$'\033[A' UP_APP=$'\033OA' DOWN=$'\033[B' ENTER=$'\r'
if ! command -v script >/dev/null; then
    fail "script(1) missing: the menu tests need a terminal"
    exit "$FAILED"
fi

in_terminal() {
    local keys="$1" code="$2"
    shift 2
    { sleep 1; printf '%s' "$keys"; } \
        | env -u BOOTSTRAP_CATEGORIES -u BOOTSTRAP_XORG "$@" \
            script -qec "bash -c 'set -euo pipefail; CATEGORIES=; source $FUNCS; $code'" /dev/null 2>&1 \
        | tr -d '\r'
}

# prompt_categories on distro $1 (major $3, default_major without it) after
# the keys $2; prints "CAT=<result>.".
menu() {
    in_terminal "$2" "DISTRO=$1 DISTRO_MAJOR=${3:-$(default_major "$1")}; echo CAT=\$(prompt_categories)." \
        | grep -ao 'CAT=[a-z -]*\.'
}

out="$(in_terminal " $ENTER" "DISTRO=fedora DISTRO_MAJOR=43; echo CAT=\$(prompt_categories).")"
if [[ "$out" == *"basic is always installed"* && "$out" == *"Up/Down: move"* \
    && "$out" == *"> [ ] dev tools"* && "$out" == *"  [ ] desktop environment (Xorg, i3)"* \
    && "$out" == *"  [ ] desktop environment (Wayland, sway)"* ]]; then
    ok "menu lists the categories, cursor on the first"
else
    fail "menu list: $out"
fi
if [[ "$out" == *"> [x] dev tools"* ]]; then ok "Space shows the selection at once"; else fail "no [x] after Space: $out"; fi

expect "menu Enter: basic only" "CAT=." "$(menu fedora "$ENTER")"
expect "menu Space: dev tools" "CAT=devtools." "$(menu fedora " $ENTER")"
expect "menu Down Space: desktop" "CAT=desktop." "$(menu fedora "$DOWN $ENTER")"
expect "menu Down Down Space: desktop-wayland" "CAT=desktop-wayland." "$(menu fedora "$DOWN$DOWN $ENTER")"
expect "menu both" "CAT=devtools desktop." "$(menu fedora " $DOWN $ENTER")"
expect "menu all three" "CAT=devtools desktop desktop-wayland." "$(menu fedora " $DOWN $DOWN $ENTER")"
expect "menu Space Space: unselected" "CAT=." "$(menu fedora "  $ENTER")"
expect "menu Up in application mode" "CAT=devtools." "$(menu fedora "$DOWN$UP_APP $ENTER")"
expect "menu stops at the bottom" "CAT=desktop-wayland." "$(menu fedora "$DOWN$DOWN$DOWN $ENTER")"
expect "menu stops at the top" "CAT=devtools." "$(menu fedora "$UP $ENTER")"

# Where the desktop cannot be installed it is not offered.
out="$(in_terminal "$ENTER" "DISTRO=amzn2 DISTRO_MAJOR=2; prompt_categories >/dev/null")"
if [[ "$out" == *"dev tools"* && "$out" != *"desktop environment"* ]]; then
    ok "amzn2 menu offers no desktop"
else
    fail "amzn2 menu: $out"
fi
expect "amzn2 menu Down Space: dev tools" "CAT=devtools." "$(menu amzn2 "$DOWN $ENTER")"

# sway only on Fedora 43 and newer; the Xorg desktop stays.
for entry in debian:12 ubuntu:22 rhel:9 fedora:42; do
    IFS=: read -r distro major <<< "$entry"
    out="$(in_terminal "$ENTER" "DISTRO=$distro DISTRO_MAJOR=$major; prompt_categories >/dev/null")"
    if [[ "$out" == *"(Xorg, i3)"* && "$out" != *"Wayland"* ]]; then
        ok "$distro $major menu offers no desktop-wayland"
    else
        fail "$distro $major menu: $out"
    fi
    expect "$distro $major menu stops at desktop" "CAT=desktop." "$(menu "$distro" "$DOWN$DOWN $ENTER" "$major")"
done
out="$(in_terminal "$ENTER" "DISTRO=amzn2023 DISTRO_MAJOR=2023; prompt_categories >/dev/null")"
if [[ "$out" == *"dev tools"* && "$out" != *"desktop environment"* ]]; then
    ok "amzn2023 menu offers no desktop"
else
    fail "amzn2023 menu: $out"
fi

# With a terminal and no environment, choose_categories shows the menu.
out="$(in_terminal " $ENTER" "DISTRO=fedora DISTRO_MAJOR=43; choose_categories; echo CAT=\$CATEGORIES.")"
if [[ "$out" == *"Up/Down: move"* && "$out" == *"CAT=devtools."* ]]; then
    ok "terminal without env: menu"
else
    fail "terminal menu: $out"
fi

# BOOTSTRAP_XORG=1 selects desktop but still asks for the others.
out="$(in_terminal " $ENTER" "DISTRO=fedora DISTRO_MAJOR=43; choose_categories; echo CAT=\$CATEGORIES." BOOTSTRAP_XORG=1)"
if [[ "$out" == *"Up/Down: move"* && "$out" == *"CAT=devtools desktop."* ]]; then
    ok "BOOTSTRAP_XORG=1 on a terminal: menu, plus desktop"
else
    fail "BOOTSTRAP_XORG=1 terminal menu: $out"
fi

exit "$FAILED"
