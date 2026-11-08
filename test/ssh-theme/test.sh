#!/usr/bin/env bash
#
# Runs the ssh wrapper from .zshrc in zsh with stubs for ssh and
# ~/bin/theme: it sends the light/dark setting as LC_COLOR_SCHEME, so tmux
# and nvim on the server can follow it, and passes a received one on.
#
# Usage: test/ssh-theme/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ZSHRC="$HERE/../../.zshrc"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" FUNC="$TMP/ssh.zsh"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then
        ok "$name"
    else
        fail "$name: want '$want', got '$got'"
    fi
}

# The function between its markers in .zshrc.
sed -n '/^# >>> ssh theme$/,/^# <<< ssh theme$/p' "$ZSHRC" > "$FUNC"

mkdir -p "$STUBS" "$TMP/home/bin"
# ssh prints the variable it received and its arguments.
# shellcheck disable=SC2016 # Expanded by the stub.
printf '#!/bin/sh\necho "${LC_COLOR_SCHEME:-unset}|$*"\n' > "$STUBS/ssh"
chmod +x "$STUBS/ssh"

# Runs `ssh host` through the wrapper; THEME is what ~/bin/theme shows
# ("none": no theme script, as on a server).
run() {
    local theme="$1" inherited="${2:-}"
    rm -f "$TMP/home/bin/theme"
    if [[ "$theme" != none ]]; then
        # shellcheck disable=SC2016 # $1 belongs to the stub.
        printf '#!/bin/sh\n[ "$1" = show ] && echo %s\n' "$theme" > "$TMP/home/bin/theme"
        chmod +x "$TMP/home/bin/theme"
    fi
    HOME="$TMP/home" PATH="$STUBS:$PATH" LC_COLOR_SCHEME="$inherited" \
        zsh -f -c "source '$FUNC'; [[ -z \$LC_COLOR_SCHEME ]] && unset LC_COLOR_SCHEME; ssh host"
}

main() {
    command -v zsh >/dev/null || { echo "SKIP: zsh not installed"; exit 0; }
    [[ -s "$FUNC" ]] || { fail "no ssh wrapper between '# >>> ssh theme' and '# <<< ssh theme' in .zshrc"; exit 1; }

    expect "desktop light: sends light" "light|-o SendEnv=LC_COLOR_SCHEME host" "$(run light)"
    expect "desktop dark: sends dark" "dark|-o SendEnv=LC_COLOR_SCHEME host" "$(run dark)"
    expect "server: passes a received setting on" "light|-o SendEnv=LC_COLOR_SCHEME host" "$(run none light)"
    expect "no setting at all: plain ssh" "unset|host" "$(run none)"
    expect "the desktop wins over a received setting" "dark|-o SendEnv=LC_COLOR_SCHEME host" "$(run dark light)"

    exit "$FAILED"
}

main "$@"
