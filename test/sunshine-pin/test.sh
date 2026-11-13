#!/usr/bin/env bash
#
# Runs bin/sunshine-pin with a stub curl. It must POST {"pin","name"} as
# JSON on stdin (never in arguments) to Sunshine's /api/pin with the web UI
# user (curl asks for the password), succeed only on "status":true, and
# refuse a PIN that is not 4 digits without calling curl.
#
# Usage: test/sunshine-pin/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/sunshine-pin"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" BODY="$TMP/body"
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

# Records one field per argument and the body; prints TMP/reply.
write_stub() {
    mkdir -p "$STUBS"
    cat > "$STUBS/curl" <<EOF
#!/bin/sh
{ printf 'curl'; printf '|%s' "\$@"; echo; } > "$CALLS"
cat > "$BODY"
cat "$TMP/reply"
EOF
    chmod +x "$STUBS/curl"
}

# run <reply> <args...>: prints the exit status.
run() {
    local reply="$1"
    shift
    rm -f "$CALLS" "$BODY"
    printf '%s' "$reply" > "$TMP/reply"
    local rc=0
    env -u SUNSHINE_USER -u SUNSHINE_URL PATH="$STUBS:$PATH" USER=alice \
        "$SCRIPT" "$@" > "$TMP/out" 2>&1 || rc=$?
    echo "$rc"
}

main() {
    write_stub

    expect "paired: exit 0" 0 "$(run '{"status":true}' 1234 'Mac "Work"')"
    expect "paired: curl call" \
        "curl|-sSk|--fail-with-body|-u|alice|-H|Content-Type: application/json|--data-binary|@-|https://localhost:47990/api/pin" \
        "$(cat "$CALLS")"
    expect "paired: JSON body, name escaped" '{"pin":"1234","name":"Mac \"Work\""}' "$(cat "$BODY")"

    run '{"status":true}' 0042 > /dev/null
    expect "default name: host name" "{\"pin\":\"0042\",\"name\":\"$(hostname)\"}" "$(cat "$BODY")"

    SUNSHINE_USER=admin SUNSHINE_URL=https://localhost:1234 \
        PATH="$STUBS:$PATH" "$SCRIPT" 1111 x > /dev/null 2>&1 < /dev/null || true
    expect "SUNSHINE_USER and SUNSHINE_URL" \
        "curl|-sSk|--fail-with-body|-u|admin|-H|Content-Type: application/json|--data-binary|@-|https://localhost:1234/api/pin" \
        "$(cat "$CALLS")"

    expect "status false: exit 1" 1 "$(run '{"status":false}' 1234)"
    if grep -q 'not paired' "$TMP/out"; then ok "status false: message"; else fail "status false: $(cat "$TMP/out")"; fi

    expect "bad PIN: exit 2" 2 "$(run '{"status":true}' 12a4)"
    if [[ ! -e "$CALLS" ]]; then ok "bad PIN: no curl"; else fail "bad PIN: curl called"; fi
    expect "no PIN: exit 2" 2 "$(run '{"status":true}')"

    exit "$FAILED"
}

main "$@"
