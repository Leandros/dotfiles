#!/usr/bin/env bash
#
# Runs .tmux/custom/follow-system-theme and toggle-dark-mode with stubs for
# tmux and gsettings: the tmux colors follow the desktop color-scheme (set
# by ~/bin/theme) at start and on every change, and one watcher runs per
# tmux server.
#
# Usage: test/tmux-theme/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIR="$HERE/../../.tmux/custom"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" OPTS="$TMP/opts" SCHEME="$TMP/scheme" CHANGES="$TMP/changes"
readonly DARK="fg=#93a1a1,bg=default" LIGHT="fg=#586e75,bg=default"
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

# tmux keeps each global option in a file under OPTS. gsettings `get` prints
# SCHEME; `monitor` prints the lines of CHANGES, one per 0.2 s, then waits
# like the real one.
write_stubs() {
    mkdir -p "$STUBS" "$OPTS"
    cat > "$STUBS/tmux" <<EOF
#!/usr/bin/env bash
case "\$1" in
    has-session) [[ ! -e "$TMP/server-gone" ]] ;;
    # The session environment: SESSION_ENV holds "LC_COLOR_SCHEME=<mode>".
    show-environment)
        [[ "\$*" == *"-t work"* ]] || exit 1
        cat "$TMP/session-env" 2>/dev/null || echo "-LC_COLOR_SCHEME" ;;
    set) shift; [[ "\$1" == -g ]] && shift; printf '%s' "\$2" > "$OPTS/\$1" ;;
    show) opt="\${*: -1}"; cat "$OPTS/\$opt" 2>/dev/null; echo ;;
esac
EOF
    cat > "$STUBS/gsettings" <<EOF
#!/bin/sh
case "\$1" in
    get) [ "\$(cat "$SCHEME")" = fail ] && exit 1; cat "$SCHEME" ;;
    monitor)
        while read -r line; do sleep 0.2; echo "color-scheme: \$line"; done < "$CHANGES"
        exec sleep 30 ;;
esac
EOF
    chmod +x "$STUBS"/*
}

opt() { cat "$OPTS/$1" 2>/dev/null || true; }

main() {
    write_stubs
    export PATH="$STUBS:$PATH"

    # toggle-dark-mode with an explicit mode.
    "$DIR/toggle-dark-mode" light > /dev/null
    expect "toggle-dark-mode light" "$LIGHT" "$(opt status-style)"
    "$DIR/toggle-dark-mode" dark > /dev/null
    expect "toggle-dark-mode dark" "$DARK" "$(opt status-style)"
    "$DIR/toggle-dark-mode" > /dev/null
    expect "toggle-dark-mode without argument toggles" "$LIGHT" "$(opt status-style)"

    # The watcher: light at start, then dark, then light again.
    echo "'prefer-light'" > "$SCHEME"
    printf "'prefer-dark'\n'prefer-light'\n" > "$CHANGES"
    FOLLOW_THEME_CHECK_S=0.5 "$DIR/follow-system-theme" &
    local pid=$!
    sleep 0.1
    expect "start: follows a light desktop" "$LIGHT" "$(opt status-style)"
    sleep 0.2
    expect "change to dark" "$DARK" "$(opt status-style)"
    sleep 0.2
    expect "change back to light" "$LIGHT" "$(opt status-style)"

    # A config reload starts it again; the second one exits at once.
    if timeout 2 "$DIR/follow-system-theme"; then ok "second watcher exits"; else fail "second watcher did not exit"; fi
    expect "the first watcher is recorded" "$pid" "$(opt @theme_watcher)"

    # The watcher ends soon after the server, without a theme change.
    touch "$TMP/server-gone"
    local i=0
    while kill -0 "$pid" 2>/dev/null && [[ $i -lt 30 ]]; do sleep 0.1; i=$((i + 1)); done
    if kill -0 "$pid" 2>/dev/null; then
        fail "watcher still runs after the server is gone"
        kill "$pid" 2>/dev/null || true
    else
        ok "watcher ends with the server"
    fi
    rm -f "$TMP/server-gone"

    # A server reached over ssh: no desktop setting, LC_COLOR_SCHEME from the
    # ssh wrapper in .zshrc. The desktop setting wins when there is one.
    rm -f "$OPTS/@theme_watcher"
    : > "$CHANGES"
    echo fail > "$SCHEME"
    LC_COLOR_SCHEME=light timeout 1 "$DIR/follow-system-theme" || true
    expect "no desktop setting: LC_COLOR_SCHEME=light" "$LIGHT" "$(opt status-style)"
    rm -f "$OPTS/@theme_watcher"
    timeout 1 "$DIR/follow-system-theme" || true
    expect "no desktop setting, no variable: dark" "$DARK" "$(opt status-style)"
    echo "'prefer-dark'" > "$SCHEME"
    rm -f "$OPTS/@theme_watcher"
    LC_COLOR_SCHEME=light timeout 1 "$DIR/follow-system-theme" || true
    expect "the desktop setting wins over LC_COLOR_SCHEME" "$DARK" "$(opt status-style)"

    # On attach: the attaching client's LC_COLOR_SCHEME (update-environment
    # copies it into the session environment).
    echo fail > "$SCHEME"
    echo "LC_COLOR_SCHEME=light" > "$TMP/session-env"
    "$DIR/follow-system-theme" apply work
    expect "attach applies the session's LC_COLOR_SCHEME" "$LIGHT" "$(opt status-style)"
    echo "LC_COLOR_SCHEME=dark" > "$TMP/session-env"
    "$DIR/follow-system-theme" apply work
    expect "attach with dark" "$DARK" "$(opt status-style)"
    rm -f "$TMP/session-env"

    # Without gsettings (macOS, minimal systems) it does nothing.
    rm -f "$OPTS/@theme_watcher" "$STUBS/gsettings"
    local tool
    for tool in bash dirname readlink; do ln -s "$(command -v "$tool")" "$STUBS/$tool"; done
    if PATH="$STUBS" "$(command -v timeout)" 2 "$DIR/follow-system-theme"; then ok "no gsettings: exits"; else fail "no gsettings: failed"; fi
    expect "no gsettings: no watcher recorded" "" "$(opt @theme_watcher)"
    rm -f "$OPTS/status-style"
    PATH="$STUBS" LC_COLOR_SCHEME=light "$(command -v timeout)" 2 "$DIR/follow-system-theme" || true
    expect "no gsettings, LC_COLOR_SCHEME=light (Debian server)" "$LIGHT" "$(opt status-style)"

    exit "$FAILED"
}

main "$@"
