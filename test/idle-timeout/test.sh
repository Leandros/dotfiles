#!/usr/bin/env bash
#
# Runs bin/idle-timeout with stubs (xidlehook, swayidle, setsid, and
# ~/bin/pkill-display in a fake HOME) and checks: the times come from
# ~/.config/idle.conf (bootstrap.sh), `set` overrides them in
# $XDG_STATE_HOME and restarts the session's idle daemon with them,
# `reset` drops the override, bad values are refused, and xrdp sessions get
# no daemon (an idle remote session would suspend the machine).
#
# Usage: test/idle-timeout/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/idle-timeout"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" FAKE_HOME="$TMP/home" CALLS="$TMP/calls" STATE_DIR="$TMP/state"
readonly OVERRIDE="$STATE_DIR/idle-timeout"
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

# Each stub records "name|arg1|arg2", one argument per field. setsid -f
# runs its command (in the foreground: the stubs only record).
write_stubs() {
    mkdir -p "$STUBS" "$FAKE_HOME/bin" "$FAKE_HOME/.config"
    local file
    for file in "$STUBS/xidlehook" "$STUBS/swayidle" "$FAKE_HOME/bin/pkill-display"; do
        cat > "$file" <<EOF
#!/bin/sh
line="${file##*/}"
for a in "\$@"; do line="\$line|\$a"; done
printf '%s\n' "\$line" >> "$CALLS"
EOF
    done
    cat > "$STUBS/setsid" <<EOF
#!/bin/sh
[ "\$1" = -f ] && shift
exec "\$@"
EOF
    chmod +x "$STUBS"/* "$FAKE_HOME/bin"/*
    printf '# Written by bootstrap.sh.\nIDLE_LOCK_MINUTES=5\nIDLE_SUSPEND_MINUTES=12\n' \
        > "$FAKE_HOME/.config/idle.conf"
}

# run SESSION ARGS...: SESSION is x, sway, xrdp or none. Prints the exit
# status and the output.
run() {
    local session="$1" rc=0 out
    shift
    : > "$CALLS"
    local -a env=(HOME="$FAKE_HOME" PATH="$STUBS:/usr/bin:/bin" XDG_RUNTIME_DIR="$TMP/run"
        XDG_STATE_HOME="$STATE_DIR")
    case "$session" in
        x)    env+=(DISPLAY=:0) ;;
        sway) env+=(DISPLAY=:1 SWAYSOCK=/run/sway.sock WAYLAND_DISPLAY=wayland-1) ;;
        xrdp) env+=(DISPLAY=:10 XRDP_SESSION=1) ;;
    esac
    out="$(env -i "${env[@]}" /bin/bash "$SCRIPT" "$@" 2>&1)" || rc=$?
    echo "$rc${out:+ $out}"
}

calls() { grep "^$1" "$CALLS" || true; }

readonly XIDLEHOOK_5_12="xidlehook|--not-when-audio|--not-when-fullscreen|--detect-sleep|--socket|$TMP/run/xidlehook.sock|--timer|300|loginctl lock-session||--timer|420|systemctl suspend|"
readonly SWAYIDLE_LOCKER="lock|~/bin/pwr lock|before-sleep|~/bin/pwr lock"

test_start() {
    expect "X start: exit 0, quiet" "0" "$(run x start)"
    expect "X: the old xidlehook of this display stops" "pkill-display|-x|xidlehook" "$(calls pkill)"
    # Timers chain: suspend 7 min after the lock (12 in total).
    expect "X: xidlehook from idle.conf" "$XIDLEHOOK_5_12" "$(calls xidlehook)"

    expect "sway start: exit 0, quiet" "0" "$(run sway start)"
    expect "sway: the old swayidle of this session stops" "pkill-display|-x|swayidle" "$(calls pkill)"
    # Each timeout counts from the last input.
    expect "sway: swayidle from idle.conf" \
        "swayidle|-w|timeout|300|loginctl lock-session|timeout|720|systemctl suspend|$SWAYIDLE_LOCKER" \
        "$(calls swayidle)"

    expect "xrdp start: exit 0, quiet" "0" "$(run xrdp start)"
    expect "xrdp: no daemon" "" "$(calls 'xidlehook\|swayidle')"

    mv "$FAKE_HOME/.config/idle.conf" "$TMP/idle.conf"
    run sway start > /dev/null
    expect "sway without idle.conf: only the locker" "swayidle|-w|$SWAYIDLE_LOCKER" "$(calls swayidle)"
    run x start > /dev/null
    expect "X without idle.conf: no xidlehook" "" "$(calls xidlehook)"
    mv "$TMP/idle.conf" "$FAKE_HOME/.config/idle.conf"
}

test_set() {
    expect "show: idle.conf" "0 lock after 5 min, suspend after 12 min" "$(run none)"

    expect "set: exit 0, says so" "0 lock after 2 min, suspend after 12 min" "$(run sway set 2)"
    expect "set keeps the suspend time" \
        "swayidle|-w|timeout|120|loginctl lock-session|timeout|720|systemctl suspend|$SWAYIDLE_LOCKER" \
        "$(calls swayidle)"
    expect "set: override in the state directory" \
        $'IDLE_LOCK_MINUTES=2\nIDLE_SUSPEND_MINUTES=12' "$(cat "$OVERRIDE")"
    expect "idle.conf untouched" "IDLE_LOCK_MINUTES=5" "$(grep LOCK "$FAKE_HOME/.config/idle.conf")"
    expect "show: the override" "0 lock after 2 min, suspend after 12 min (set; idle-timeout reset for 5/12)" \
        "$(run none show)"

    run x set 3 30 > /dev/null
    expect "set both, X" \
        "xidlehook|--not-when-audio|--not-when-fullscreen|--detect-sleep|--socket|$TMP/run/xidlehook.sock|--timer|180|loginctl lock-session||--timer|1620|systemctl suspend|" \
        "$(calls xidlehook)"
    run x start > /dev/null
    expect "a later start (next login) keeps the override" "|180|" "$(calls xidlehook | grep -o '|180|')"

    expect "no session: saved, no daemon" \
        "0 lock after 4 min, suspend after 30 min (from the next login)" "$(run none set 4)"
    expect "no session: nothing started" "" "$(calls 'xidlehook\|swayidle\|pkill')"

    expect "xrdp set: saved, no daemon" \
        "0 lock after 4 min, suspend after 31 min (no idle daemon in xrdp)" "$(run xrdp set 4 31)"
    expect "xrdp set: nothing started" "" "$(calls 'xidlehook\|swayidle')"

    local before
    before="$(cat "$OVERRIDE")"
    expect "lock not before suspend: refused" "1" "$(run x set 40 | cut -d' ' -f1)"
    expect "refused: no daemon restart" "" "$(calls xidlehook)"
    expect "refused: override kept" "$before" "$(cat "$OVERRIDE")"
    expect "zero: refused" "1" "$(run x set 0 5 | cut -d' ' -f1)"
    expect "not a number: refused" "1" "$(run x set 5m | cut -d' ' -f1)"
    expect "leading zero: refused" "1" "$(run x set 05 | cut -d' ' -f1)"

    expect "reset: back to idle.conf" "0 lock after 5 min, suspend after 12 min" "$(run x reset)"
    if [[ -e "$OVERRIDE" ]]; then fail "reset left the override"; else ok "reset removes the override"; fi
    expect "reset restarts with idle.conf" "$XIDLEHOOK_5_12" "$(calls xidlehook)"

    expect "unknown command: usage, exit 2" "2" "$(run x bogus | cut -d' ' -f1)"
}

main() {
    write_stubs
    test_start
    test_set
    exit "$FAILED"
}

main "$@"
