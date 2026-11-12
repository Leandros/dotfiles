#!/usr/bin/env bash
#
# Runs bin/clip-pick with stubs for cliphist, fuzzel and wl-copy and checks
# that the picked history entry goes to the clipboard, and that nothing
# happens (quietly, exit 0) when fuzzel is cancelled or the input matches
# no entry.
#
# Usage: test/clip-pick/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/clip-pick"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" CLIPBOARD="$TMP/clipboard" PICK="$TMP/pick"
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

# cliphist list: "<id>\t<preview>", newest first; decode: the entry of the
# id in front of its input line. fuzzel prints the line in PICK (without
# PICK it was cancelled, exit 2) and keeps its input; wl-copy keeps stdin.
write_stubs() {
    mkdir -p "$STUBS"
    cat > "$STUBS/cliphist" <<EOF
#!/bin/sh
echo "cliphist \$*" >> "$CALLS"
case "\$1" in
    list) printf '12\tssh-ed25519 AAAA\n7\tline one\n' ;;
    decode)
        read -r line
        case "\$line" in
            "12	"*) printf 'ssh-ed25519 AAAA' ;;
            "7	"*) printf 'line one\nline two\n' ;;
            *) echo "cliphist: input not prefixed with id" >&2; exit 1 ;;
        esac ;;
esac
EOF
    cat > "$STUBS/fuzzel" <<EOF
#!/bin/sh
echo "fuzzel \$*" >> "$CALLS"
cat > "$TMP/menu"
[ -e "$PICK" ] || exit 2
cat "$PICK"
EOF
    cat > "$STUBS/wl-copy" <<EOF
#!/bin/sh
echo "wl-copy \$*" >> "$CALLS"
cat > "$CLIPBOARD"
EOF
    chmod +x "$STUBS"/*
}

# Runs clip-pick; prints its exit status and output.
run() {
    : > "$CALLS"
    rm -f "$CLIPBOARD"
    local rc=0 out
    out="$(PATH="$STUBS:$PATH" "$SCRIPT" 2>&1)" || rc=$?
    echo "$rc${out:+ $out}"
}

main() {
    write_stubs

    printf '7\tline one\n' > "$PICK"
    expect "a pick: exit 0, quiet" "0" "$(run)"
    expect "the picked entry, as stored, to the clipboard" $'line one\nline two' "$(cat "$CLIPBOARD")"
    expect "fuzzel gets the history" $'12\tssh-ed25519 AAAA\n7\tline one' "$(cat "$TMP/menu")"
    expect "fuzzel shows the previews only" "1" "$(grep -c '^fuzzel --dmenu .*--with-nth=2' "$CALLS")"

    rm "$PICK"
    expect "cancelled: exit 0, quiet" "0" "$(run)"
    if [[ -e "$CLIPBOARD" ]]; then fail "cancelled: clipboard changed"; else ok "cancelled: clipboard kept"; fi

    # fuzzel prints the typed text when it matches no entry.
    echo "typed text" > "$PICK"
    expect "no entry: exit 0, quiet" "0" "$(run)"
    if [[ -e "$CLIPBOARD" ]]; then fail "no entry: clipboard changed"; else ok "no entry: clipboard kept"; fi

    : > "$PICK"
    expect "empty pick: exit 0, quiet" "0" "$(run)"
    expect "empty pick: no decode" "" "$(grep -E 'decode|wl-copy' "$CALLS" || true)"

    exit "$FAILED"
}

main "$@"
