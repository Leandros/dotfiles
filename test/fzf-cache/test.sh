#!/usr/bin/env bash
#
# Tests bin/fzf-cache with a fake list command in place of fd.
#
# Usage: test/fzf-cache/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CACHE="$HERE/../../bin/fzf-cache"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
FAILED=0

export XDG_CACHE_HOME="$TMP/cache" XDG_RUNTIME_DIR="$TMP/run"
mkdir -p "$XDG_RUNTIME_DIR"
readonly CACHE_DIR="$XDG_CACHE_HOME/fzf-cache"
readonly LOCK_DIR="$XDG_RUNTIME_DIR/fzf-cache-locks"
readonly RUNS="$TMP/runs" LIST="$TMP/list.sh"
export RUNS

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

# Joins the lines of a command's output with spaces.
words() { "$@" | tr '\n' ' ' | sed 's/ $//'; }
runs() { wc -l < "$RUNS" | tr -d ' '; }

# Waits until no refresh holds a lock.
wait_idle() {
    local _
    for _ in $(seq 100); do
        [[ -z "$(ls -A "$LOCK_DIR" 2>/dev/null)" ]] && return
        sleep 0.1
    done
    fail "a refresh still holds a lock"
}

# Lists the current directory after LIST_DELAY seconds and counts its runs.
write_list() {
    cat > "$LIST" <<'EOF'
#!/usr/bin/env bash
echo run >> "$RUNS"
sleep "${LIST_DELAY:-0}"
ls
EOF
    chmod +x "$LIST"
}

test_basic() {
    touch a b
    expect "show without a cache runs the command" "a b" "$(words "$CACHE" show "$LIST")"
    wait_idle
    expect "update prints the fresh list" "a b" "$(words "$CACHE" update "$LIST")"

    touch c
    : > "$RUNS"
    expect "show prints the cached list" "a b" "$(words "$CACHE" show "$LIST")"
    expect "show with a cache does not run the command" "0" "$(runs)"
    expect "update replaces it with the fresh list" "a b c" "$(words "$CACHE" update "$LIST")"
    expect "show sees the new cache" "a b c" "$(words "$CACHE" show "$LIST")"
}

# Two terminals at once share one refresh.
test_concurrent() {
    touch d
    : > "$RUNS"
    LIST_DELAY=1 "$CACHE" update "$LIST" > "$TMP/first" &
    local first=$!
    sleep 0.3
    LIST_DELAY=1 "$CACHE" update "$LIST" > "$TMP/second"
    wait "$first"
    expect "concurrent updates run the command once" "1" "$(runs)"
    expect "the waiting update prints the fresh list" "a b c d" "$(words cat "$TMP/second")"
}

# fzf kills the process group of its reload command on exit.
test_killed() {
    touch e
    set -m
    LIST_DELAY=1 "$CACHE" update "$LIST" > /dev/null &
    local group=$!
    set +m
    sleep 0.3
    kill -KILL -- "-$group" 2>/dev/null || true
    wait "$group" 2>/dev/null || true
    wait_idle
    expect "the refresh outlives a killed update" "a b c d e" "$(words "$CACHE" show "$LIST")"
}

# A lock from a refresh that died (kill -9) must not block.
test_stale_lock() {
    touch f
    sh -c 'exit 0' &
    local dead=$!
    wait "$dead"
    local key
    key="$(ls "$CACHE_DIR")"
    ln -s "$dead" "$LOCK_DIR/$key"
    expect "update ignores a stale lock" "a b c d e f" "$(words timeout 5 "$CACHE" update "$LIST")"
}

test_keys() {
    touch g
    expect "other arguments use another cache" "a b c d e f g" "$(words "$CACHE" show "$LIST" x)"
    wait_idle
    expect "the first cache is unchanged" "a b c d e f" "$(words "$CACHE" show "$LIST")"

    mkdir -p "$TMP/other"
    (
        cd "$TMP/other"
        touch z
        expect "other directory, other cache" "z" "$(words "$CACHE" show "$LIST")"
    )
    wait_idle
}

test_prune() {
    touch -t 202001010000 "$CACHE_DIR/old"
    "$CACHE" update "$LIST" > /dev/null
    if [[ ! -e "$CACHE_DIR/old" ]]; then
        ok "update deletes old caches"
    else
        fail "old cache not deleted"
    fi
}

# fd exits 1 for unreadable directories but lists the rest; a command that
# cannot run (126, 127) must not leave an empty cache.
test_status() {
    local partial="$TMP/partial.sh"
    printf '#!/bin/sh\necho listed\nexit 1\n' > "$partial"
    chmod +x "$partial"
    expect "output of exit status 1 is cached" "listed" "$(words "$CACHE" update "$partial")"

    local before after
    before="$(find "$CACHE_DIR" -type f | wc -l)"
    "$CACHE" update "$TMP/missing-command" > /dev/null 2>&1 || true
    "$CACHE" show "$TMP/missing-command" > /dev/null 2>&1 || true
    wait_idle
    after="$(find "$CACHE_DIR" -type f | wc -l)"
    expect "a command that cannot run leaves no cache" "$before" "$after"
}

test_misc() {
    expect "cache directory is private" "700" "$(stat -c '%a' "$CACHE_DIR")"
    expect "unknown mode is rejected" "usage: fzf-cache show|update COMMAND [ARG...]" "$("$CACHE" bogus 2>&1 || true)"
    expect "missing command is rejected" "usage: fzf-cache show|update COMMAND [ARG...]" "$("$CACHE" show 2>&1 || true)"
}

main() {
    write_list
    mkdir -p "$TMP/work"
    cd "$TMP/work"
    : > "$RUNS"

    test_basic
    test_concurrent
    test_killed
    test_stale_lock
    test_keys
    test_prune
    test_status
    test_misc

    exit "$FAILED"
}

main "$@"
