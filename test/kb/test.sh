#!/usr/bin/env bash
#
# Runs bin/kb with stubs for the X and console tools: inside X it changes
# only the session's X keyboard (--console also the console); on a tty
# (no DISPLAY) only the console. The console path writes the system-wide
# keymap (localectl, which is also the X server default the login screen
# uses) or the kernel keymap (loadkeys), so X must not touch it by itself.
#
# Usage: test/kb/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/kb"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" STATE="$TMP/run/kb-layout"
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

# Each tool records its call. systemctl lists a kmscon unit and kmscon exists
# when "$TMP/kmscon" exists (Fedora 45 consoles); otherwise fbcon (loadkeys).
write_stubs() {
    mkdir -p "$STUBS" "$TMP/home"
    echo "! test xmodmap" > "$TMP/home/.Xmodmap"
    local cmd
    for cmd in setxkbmap xmodmap loadkeys localectl; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$CALLS" > "$STUBS/$cmd"
    done
    # xkbcomp: `xkbcomp -w0 <display> <file>` dumps the server keymap.
    cat > "$STUBS/xkbcomp" <<EOF
#!/bin/sh
echo "xkbcomp \$*" >> "$CALLS"
for last; do :; done
case "\$last" in *.tmp) echo dump > "\$last" ;; esac
EOF
    # sudo runs the command, so its stub records it.
    # shellcheck disable=SC2016 # $1 and $@ belong to the stub.
    printf '#!/bin/sh\n[ "$1" = -n ] && shift\nexec "$@"\n' > "$STUBS/sudo"
    cat > "$STUBS/systemctl" <<EOF
#!/bin/sh
[ -e "$TMP/kmscon" ] && echo "kmsconvt@tty2.service loaded active running"
exit 0
EOF
    chmod +x "$STUBS"/*
}

# kb with DISPLAY ($1: "x" or "tty") and the remaining arguments.
run() {
    local where="$1"
    shift
    : > "$CALLS"
    local display=()
    [[ "$where" == x ]] && display=(DISPLAY=:99)
    rm -f "$STUBS/kmscon"
    if [[ -e "$TMP/kmscon" ]]; then
        printf '#!/bin/sh\nexit 0\n' > "$STUBS/kmscon"
        chmod +x "$STUBS/kmscon"
    fi
    env -u DISPLAY "${display[@]}" HOME="$TMP/home" XDG_RUNTIME_DIR="$TMP/run" \
        XDG_CACHE_HOME="$TMP/cache" PATH="$STUBS:$PATH" "$SCRIPT" "$@" < /dev/null > /dev/null 2>&1 || echo "rc=$?" >> "$CALLS"
}

# The calls of one tool, joined.
calls() { { grep "^$1" "$CALLS" || true; } | tr '\n' ';' | sed 's/;$//'; }

main() {
    write_stubs

    # Inside X: the session's X keyboard only.
    run x de
    expect "X: de sets the X layout" "setxkbmap -layout de -option terminate:ctrl_alt_bksp" "$(calls setxkbmap)"
    expect "X: no console keymap" "" "$(calls loadkeys)$(calls localectl)"
    expect "X: the bar's state" "de" "$(cat "$STATE")"

    run x bone2
    expect "X: bone2 loads the xmodmap" "xmodmap $TMP/home/.Xmodmap" "$(calls xmodmap)"
    expect "X: bone2 leaves the console" "" "$(calls loadkeys)$(calls localectl)"

    # Inside X with --console: X and the console (fbcon: loadkeys).
    run x --console de
    expect "X --console: X layout" "setxkbmap -layout de -option terminate:ctrl_alt_bksp" "$(calls setxkbmap)"
    expect "X --console: fbcon keymap" "loadkeys -u -q de-latin1" "$(calls loadkeys)"
    run x bone2 --console
    expect "X --console after the layout works too" "loadkeys -u -q $(cd "$HERE/../.." && pwd)/console/bone2.map" "$(calls loadkeys)"

    # kmscon consoles follow localed: only with --console, never from X alone.
    touch "$TMP/kmscon"
    run x de
    expect "X, kmscon: localectl untouched" "" "$(calls localectl)"
    run x --console bone2
    expect "X --console, kmscon: localectl de bone" "localectl --no-convert set-x11-keymap de  bone" "$(calls localectl)"
    rm -f "$TMP/kmscon"

    # On a tty: the console only; the bar's X state stays.
    echo de > "$STATE"
    run tty bone2
    expect "tty: console keymap" "loadkeys -u -q $(cd "$HERE/../.." && pwd)/console/bone2.map" "$(calls loadkeys)"
    expect "tty: no X tools" "" "$(calls setxkbmap)$(calls xkbcomp)$(calls xmodmap)"
    expect "tty: the X state is kept" "de" "$(cat "$STATE")"
    run tty --console us
    expect "tty --console: console only" "loadkeys -u -q us" "$(calls loadkeys)"

    run x --bogus de
    if grep -q '^rc=' "$CALLS"; then ok "unknown option rejected"; else fail "unknown option accepted"; fi
    run x
    if grep -q '^rc=' "$CALLS"; then ok "no layout without a terminal: error"; else fail "no layout accepted"; fi

    exit "$FAILED"
}

main "$@"
