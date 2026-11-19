#!/usr/bin/env bash
#
# Runs bin/ws-pick with stubs for wm-msg (in a fake HOME), fuzzel and dmenu
# and checks the commands it sends: the menu (fuzzel under sway, dmenu
# under X) lists the workspaces, a pick goes there (a number by number, a
# name exactly, quoted), --rename renames the focused workspace, --go is
# the bar's click, and a cancel sends nothing.
#
# Usage: test/ws-pick/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/ws-pick"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" FAKE_HOME="$TMP/home" CALLS="$TMP/calls" PICK="$TMP/pick" MENU="$TMP/menu"
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

# wm-msg answers get_workspaces (sway 1.12's shape, trimmed) and records
# commands; fuzzel and dmenu keep their input and print PICK (without PICK
# they were cancelled: fuzzel exits 2, dmenu 1).
write_stubs() {
    mkdir -p "$STUBS" "$FAKE_HOME/bin"
    cat > "$FAKE_HOME/bin/wm-msg" <<EOF
#!/bin/sh
if [ "\$1" = "-t" ] && [ "\$2" = "get_workspaces" ]; then
    printf '%s\n' '[{"num":1,"name":"1"},{"num":3,"name":"3: web"},{"num":-1,"name":"mail"}]'
    exit 0
fi
printf 'wm-msg' >> "$CALLS"
for a in "\$@"; do printf ' <%s>' "\$a" >> "$CALLS"; done
echo >> "$CALLS"
EOF
    local menu
    for menu in fuzzel:2 dmenu:1; do
        cat > "$STUBS/${menu%:*}" <<EOF
#!/bin/sh
echo "${menu%:*} \$*" >> "$CALLS"
cat > "$MENU"
[ -e "$PICK" ] || exit ${menu#*:}
cat "$PICK"
EOF
    done
    chmod +x "$STUBS"/* "$FAKE_HOME/bin/wm-msg"
}

# Runs ws-pick in sway (sway) or X (x); prints its exit status and output.
run() {
    local session="$1" rc=0 out
    shift
    : > "$CALLS"
    rm -f "$MENU"
    local -a env=(HOME="$FAKE_HOME" PATH="$STUBS:$PATH")
    if [[ "$session" == sway ]]; then
        env+=(SWAYSOCK=/run/sway.sock DISPLAY=:1)
    else
        env+=(DISPLAY=:0)
    fi
    out="$(env -u SWAYSOCK -u DISPLAY "${env[@]}" "$SCRIPT" "$@" 2>&1)" || rc=$?
    echo "$rc${out:+ $out}"
}

# The command ws-pick sent, or "" for none.
sent() { grep '^wm-msg' "$CALLS" || true; }

main() {
    write_stubs

    echo "3: web" > "$PICK"
    expect "sway: exit 0, quiet" "0" "$(run sway)"
    expect "sway: fuzzel" "1" "$(grep -c '^fuzzel --dmenu' "$CALLS")"
    expect "the menu lists the workspaces" $'1\n3: web\nmail' "$(cat "$MENU")"
    expect "a listed name: exactly" 'wm-msg <-q> <workspace "3: web">' "$(sent)"

    expect "X: exit 0, quiet" "0" "$(run x)"
    expect "X: dmenu" "1" "$(grep -c '^dmenu ' "$CALLS")"
    expect "X: the same command" 'wm-msg <-q> <workspace "3: web">' "$(sent)"

    echo 3 > "$PICK"
    run sway > /dev/null
    expect "a number: by number" 'wm-msg <-q> <workspace number 3>' "$(sent)"

    printf '%s\n' 'say "hi" \o/' > "$PICK"
    run sway > /dev/null
    expect "a new name: quotes escaped" 'wm-msg <-q> <workspace "say \"hi\" \\o/">' "$(sent)"

    rm "$PICK"
    expect "cancelled: exit 0, quiet" "0" "$(run sway)"
    expect "cancelled: nothing sent" "" "$(sent)"
    expect "X cancelled: exit 0, quiet" "0" "$(run x)"
    expect "X cancelled: nothing sent" "" "$(sent)"

    : > "$PICK"
    run sway > /dev/null
    expect "empty pick: nothing sent" "" "$(sent)"

    echo "notes" > "$PICK"
    expect "rename: exit 0, quiet" "0" "$(run sway --rename)"
    expect "rename: a prompt, no list" "1" "$(grep -c '^fuzzel --dmenu --prompt-only' "$CALLS")"
    expect "rename: empty menu input" "" "$(cat "$MENU")"
    expect "rename: the focused workspace" 'wm-msg <-q> <rename workspace to "notes">' "$(sent)"
    run x --rename > /dev/null
    expect "X rename: dmenu" "1" "$(grep -c '^dmenu ' "$CALLS")"
    expect "X rename: the same command" 'wm-msg <-q> <rename workspace to "notes">' "$(sent)"

    rm "$PICK"
    run sway --rename > /dev/null
    expect "rename cancelled: nothing sent" "" "$(sent)"

    expect "--go: exit 0, quiet" "0" "$(run sway --go mail)"
    expect "--go: no menu" "" "$(grep -E '^(fuzzel|dmenu)' "$CALLS" || true)"
    expect "--go NAME: exactly" 'wm-msg <-q> <workspace "mail">' "$(sent)"
    run sway --go "3: web" > /dev/null
    expect "--go: a numbered name exactly" 'wm-msg <-q> <workspace "3: web">' "$(sent)"

    expect "unknown option: usage, exit 2" "2" "$(run sway --nope | cut -d' ' -f1)"

    exit "$FAILED"
}

main "$@"
