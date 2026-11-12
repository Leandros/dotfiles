#!/usr/bin/env bash
#
# Runs `pwr lock` and `pwr sleep` (bin/pwr) with stubs for swaylock, i3lock,
# kb, loginctl, systemctl and pgrep, in sway and X sessions, and checks the
# locker, its arguments, and that the password layout (bone2) is set while
# the screen is locked and restored after.
#
# Usage: test/pwr-lock/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PWR="$HERE/../../bin/pwr"
TMP="$(mktemp -d)"
readonly TMP
readonly BIN="$TMP/bin" STUBS="$TMP/stubs" CALLS="$TMP/calls" PROCS="$TMP/procs" LAYOUT="$TMP/layout"
# How long a stub locker keeps the screen locked. pwr waits for the forked
# locker with `tail --pid`, which looks once a second.
readonly LOCK_S=0.5 SETTLE_S=2
trap 'reset; rm -rf "$TMP"' EXIT
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

# pwr finds kb next to itself: a copy of pwr with a kb stub. The lockers
# record their arguments; with -f (swaylock) or without --nofork (i3lock)
# they leave a process that holds the lock for LOCK_S, else they hold it
# themselves. pgrep -x NAME finds the pid in PROCS/NAME.
write_stubs() {
    mkdir -p "$BIN" "$STUBS" "$PROCS"
    cp "$PWR" "$BIN/pwr"
    cat > "$BIN/kb" <<EOF
#!/bin/sh
echo "kb \$*" >> "$CALLS"
case "\$1" in
    show) cat "$LAYOUT" ;;
    *) echo "\$1" > "$LAYOUT" ;;
esac
EOF
    local tool
    for tool in swaylock i3lock; do
        cat > "$STUBS/$tool" <<EOF
#!/bin/sh
echo "$tool \$*" >> "$CALLS"
case " \$* " in
    *" -f "*|*" --color "*)
        case " \$* " in *" --nofork "*) sleep $LOCK_S; exit 0 ;; esac
        sleep $LOCK_S &
        echo \$! > "$PROCS/$tool"
        ;;
    *) sleep $LOCK_S ;;
esac
EOF
    done
    cat > "$STUBS/pgrep" <<EOF
#!/bin/sh
for name; do :; done
[ -s "$PROCS/\$name" ] || exit 1
pid="\$(cat "$PROCS/\$name")"
kill -0 "\$pid" 2>/dev/null || exit 1
echo "\$pid"
EOF
    for tool in loginctl systemctl; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$tool" "$CALLS" > "$STUBS/$tool"
    done
    chmod +x "$BIN/kb" "$STUBS"/*
}

# Marks NAME as running (a sleep, not a job of this shell: no job messages
# when reset stops it) until the next reset.
running() {
    (sleep 30 >/dev/null 2>&1 & echo $! > "$PROCS/$1")
}

reset() {
    local file
    for file in "$PROCS"/*; do
        [[ -e "$file" ]] || continue
        kill "$(cat "$file")" 2>/dev/null || true
        rm -f "$file"
    done
    echo "${1:-us}" > "$LAYOUT"
    : > "$CALLS"
}

# Runs pwr in a sway session (sway sets DISPLAY for Xwayland) or in X, then
# waits until a forked locker has ended; prints the calls.
pwr_sway() {
    SWAYSOCK=/run/sway.sock WAYLAND_DISPLAY=wayland-1 DISPLAY=:0 PATH="$STUBS:$PATH" "$BIN/pwr" "$@" \
        || fail "pwr $* (sway) exited $?"
    sleep "$SETTLE_S"
    paste -sd ';' "$CALLS"
}

pwr_x() {
    env -u SWAYSOCK -u WAYLAND_DISPLAY DISPLAY=:0 PATH="$STUBS:$PATH" "$BIN/pwr" "$@" || fail "pwr $* (X) exited $?"
    sleep "$SETTLE_S"
    paste -sd ';' "$CALLS"
}

test_sway() {
    reset us
    # xss-lock may run in an X session of the same user; sway ignores it.
    running xss-lock
    expect "sway: swaylock forks, bone2 while locked, the layout back after" \
        "kb show;kb bone2;swaylock -f -c 073642;kb us" "$(pwr_sway lock)"

    reset bone2
    expect "sway: in bone2 already: no switch" "kb show;swaylock -f -c 073642" "$(pwr_sway lock)"

    # Idle lock, then swayidle's before-sleep: sway allows one lock client.
    reset us
    running swaylock
    expect "sway: locked already: no second swaylock" "" "$(pwr_sway lock)"

    reset us
    expect "sway: --nofork: swaylock in the foreground" "kb show;kb bone2;swaylock -c 073642;kb us" \
        "$(pwr_sway lock --nofork)"

    # swayidle locks before sleep (before-sleep runs `pwr lock`).
    reset us
    running swayidle
    expect "sway: sleep with swayidle: suspend only" "systemctl suspend" "$(pwr_sway sleep)"
    reset us
    expect "sway: sleep without swayidle: lock first" "kb show;kb bone2;swaylock -f -c 073642;systemctl suspend;kb us" \
        "$(pwr_sway sleep)"
}

test_x() {
    reset us
    running xss-lock
    expect "X: with xss-lock: through logind" "loginctl lock-session" "$(pwr_x lock)"

    reset us
    expect "X: without xss-lock: i3lock forks, bone2 while locked" "kb show;kb bone2;i3lock --color 073642;kb us" \
        "$(pwr_x lock)"

    reset us
    expect "X: --nofork (xss-lock locker)" "kb show;kb bone2;i3lock --nofork --color 073642;kb us" \
        "$(pwr_x lock --nofork)"

    reset us
    running xss-lock
    expect "X: sleep with xss-lock: suspend only" "systemctl suspend" "$(pwr_x sleep)"
}

main() {
    write_stubs
    test_sway
    test_x
    exit "$FAILED"
}

main "$@"
