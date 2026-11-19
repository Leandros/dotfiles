#!/usr/bin/env bash
#
# bin/term with stub terminals: alacritty by default, wezterm after
# `term --use wezterm` (stored in $XDG_STATE_HOME/term); `-e PROG ARGS`
# (fuzzel) in each one's syntax; the other terminal when the chosen one is
# not installed.
#
# Usage: test/term/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TERM_BIN="$HERE/../../bin/term"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls"
export XDG_STATE_HOME="$TMP/state"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }
expect() {
    if [[ "$3" == "$2" ]]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi
}

mkdir -p "$STUBS"
for t in alacritty wezterm; do
    printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$t" "$CALLS" > "$STUBS/$t"
done
chmod +x "$STUBS"/*
# PATH: the stubs and what term itself needs, no real terminals.
mkdir -p "$TMP/bin"
for c in bash mkdir cat dirname mv; do ln -s "$(command -v "$c")" "$TMP/bin/$c"; done
term() { : > "$CALLS"; PATH="$STUBS:$TMP/bin" "$TERM_BIN" "$@"; }

term
expect "default: alacritty" "alacritty " "$(cat "$CALLS")"
term -e prog --flag
expect "default -e: alacritty -e" "alacritty -e prog --flag" "$(cat "$CALLS")"
expect "show: alacritty" "alacritty" "$(term --show)"

term --use wezterm
expect "use wezterm: stored" "wezterm" "$(cat "$XDG_STATE_HOME/term")"
expect "show: wezterm" "wezterm" "$(term --show)"
# Every window a process of its own (xrdp, sway: see bin/term).
term
expect "wezterm: a process of its own" "wezterm start --always-new-process" "$(cat "$CALLS")"
# wezterm's -e is an alias of start, so the program goes after --.
term -e prog --flag
expect "wezterm -e: the program after --" "wezterm start --always-new-process -- prog --flag" "$(cat "$CALLS")"

rm "$STUBS/wezterm"
term
expect "wezterm missing: alacritty" "alacritty " "$(cat "$CALLS")"

term --use alacritty
expect "use alacritty: stored" "alacritty" "$(cat "$XDG_STATE_HOME/term")"
if term --use xterm 2>/dev/null; then fail "--use xterm accepted"; else ok "--use xterm refused"; fi
expect "refused choice not stored" "alacritty" "$(cat "$XDG_STATE_HOME/term")"

exit "$FAILED"
