#!/usr/bin/env bash
#
# Tests xrdp_drop_privileges from bootstrap.sh on copies of xrdp.ini: xrdp
# 0.10 (Fedora, EPEL) runs as root unless runtime_user and runtime_group
# are set in [Globals] (the packages ship them commented out). Debian and
# Ubuntu (0.9) run it as User=xrdp from the systemd unit instead.
#
# Usage: test/xrdp-conf/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BOOTSTRAP="$HERE/../../bootstrap.sh"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly FUNCS="$TMP/funcs.sh" INI="$TMP/xrdp.ini"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: want '$want', got '$got'"; fi
}

{
    grep -E '^readonly XRDP_RUNTIME_USER=' "$BOOTSTRAP" || true
    sed -n '/^xrdp_drop_privileges() {$/,/^}$/p' "$BOOTSTRAP"
} > "$FUNCS"

# Runs xrdp_drop_privileges on INI; prints "changed" or "unchanged".
run() {
    bash -c "
        set -euo pipefail
        SUDO=''
        source '$FUNCS'
        if xrdp_drop_privileges '$INI'; then echo changed; else echo unchanged; fi
    "
}

# Globals keys, then the first key of the next section.
globals() { awk '/^\[/ { s = $0 } s == "[Globals]" && /^runtime_/' "$INI" | paste -sd ';'; }

main() {
    # As Fedora ships it: commented out in [Globals].
    printf '[Globals]\nport=3389\n#runtime_user=xrdp\n#runtime_group=xrdp\n\n[Logging]\nLogLevel=INFO\n' > "$INI"
    expect "commented: changed" "changed" "$(run)"
    expect "commented: set in [Globals]" "runtime_user=xrdp;runtime_group=xrdp" "$(globals)"
    expect "second run: unchanged" "unchanged" "$(run)"
    expect "other sections untouched" "LogLevel=INFO" "$(grep '^LogLevel' "$INI")"

    # Missing lines: added to [Globals], not at the end of the file.
    printf '[Globals]\nport=3389\n\n[Logging]\nLogLevel=INFO\n' > "$INI"
    expect "missing: changed" "changed" "$(run)"
    expect "missing: added to [Globals]" "runtime_user=xrdp;runtime_group=xrdp" "$(globals)"
    expect "no copies elsewhere" "2" "$(grep -c '^runtime_' "$INI")"

    exit "$FAILED"
}

main "$@"
