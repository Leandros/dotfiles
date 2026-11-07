#!/usr/bin/env bash
#
# Runs bin/smb against a fake network: hosts .20 (guest shares) and .30
# (needs a login) answer on port 445. Checks the listed shares and the
# mount command for the chosen one.
#
# Usage: test/smb/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/smb"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" RUN="$TMP/run"
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

write_stubs() {
    mkdir -p "$STUBS" "$RUN"
    cat > "$STUBS/ip" <<'EOF'
#!/bin/sh
echo "1.1.1.1 via 192.168.188.1 dev wlp0s20f3 src 192.168.188.173 uid 1000"
EOF
    # Port probes: `timeout <s> bash -c '...' _ <ip>`; .20, .30 and our own
    # address answer.
    cat > "$STUBS/timeout" <<'EOF'
#!/bin/sh
for last; do :; done
case "$last" in
    192.168.188.20|192.168.188.30|192.168.188.173) exit 0 ;;
    *) exit 1 ;;
esac
EOF
    cat > "$STUBS/smbclient" <<EOF
#!/bin/sh
echo "smbclient \$* PASSWD=\${PASSWD:-}" >> "$CALLS"
case "\$*" in
    *//192.168.188.20*)
        printf 'Disk|media|Movies\nDisk|backup|\nIPC|IPC\$|IPC Service\nDisk|print\$|Drivers\n' ;;
    *//192.168.188.30*)
        if [ "\${PASSWD:-}" = secret ]; then
            printf 'Disk|Users|\nDisk|C\$|Default share\nDisk|ADMIN\$|Remote Admin\n'
        else
            echo "session setup failed: NT_STATUS_ACCESS_DENIED" >&2; exit 1
        fi ;;
esac
EOF
    cat > "$STUBS/getent" <<'EOF'
#!/bin/sh
case "$2" in
    192.168.188.20) echo "192.168.188.20  nas.fritz.box" ;;
    192.168.188.30) echo "192.168.188.30  desktop.fritz.box" ;;
    *) exit 2 ;;
esac
EOF
    # sudo records the mount and the credentials file it was given.
    cat > "$STUBS/sudo" <<EOF
#!/bin/sh
echo "sudo \$*" >> "$CALLS"
case "\$*" in
    *credentials=*) a="\$*"; f="\${a##*credentials=}"; f="\${f%%,*}"; cp "\$f" "$TMP/creds" ;;
esac
EOF
    chmod +x "$STUBS"/*
}

# Runs smb with INPUT on stdin; prints its stdout.
run() {
    : > "$CALLS"
    rm -f "$TMP/creds"
    printf '%b' "$1" | HOME="$TMP/home" XDG_RUNTIME_DIR="$RUN" PATH="$STUBS:$PATH" "$SCRIPT" 2>&1
}

main() {
    write_stubs
    local out

    # Guest: empty user; .30 refuses, .20 lists two shares. Choose 2 (backup).
    out="$(run '\n2\n')"
    if [[ "$out" == *"1) nas.fritz.box (192.168.188.20)  media"* && "$out" == *"2) nas.fritz.box (192.168.188.20)  backup"* ]]; then
        ok "lists the guest shares"
    else
        fail "guest list: $out"
    fi
    if [[ "$out" == *'IPC$'* || "$out" == *'print$'* ]]; then fail "lists admin shares"; else ok "hides admin shares"; fi
    if [[ "$out" == *"desktop.fritz.box (192.168.188.30): needs a login"* ]]; then ok "names the host that needs a login"; else fail "login note: $out"; fi
    if grep -q '//192.168.188.173' "$CALLS"; then fail "asked its own address"; else ok "skips its own address"; fi
    expect "guest mount" \
        "sudo mount -t cifs //192.168.188.20/backup $TMP/home/mnt/nas-backup -o guest,uid=$(id -u),gid=$(id -g)" \
        "$(grep '^sudo' "$CALLS")"
    if [[ -d "$TMP/home/mnt/nas-backup" ]]; then ok "creates the mount point"; else fail "no mount point"; fi

    # Login: user and password; .30 now lists Users. Choose it (3rd entry).
    out="$(run 'arvid\nsecret\n3\n')"
    if [[ "$out" == *"3) desktop.fritz.box (192.168.188.30)  Users"* ]]; then ok "lists shares after login"; else fail "login list: $out"; fi
    if grep '^sudo' "$CALLS" | grep -q 'secret'; then fail "password on the command line"; else ok "password not on the command line"; fi
    if grep -q '^sudo mount -t cifs //192.168.188.30/Users '"$TMP"'/home/mnt/desktop-Users -o credentials=' "$CALLS"; then
        ok "login mount uses a credentials file"
    else
        fail "login mount: $(grep '^sudo' "$CALLS")"
    fi
    expect "credentials file content" $'username=arvid\npassword=secret' "$(cat "$TMP/creds" 2>/dev/null)"
    if compgen -G "$RUN/smb-cred.*" > /dev/null; then fail "credentials file left behind"; else ok "credentials file removed"; fi

    out="$(run '\n9\n' || true)"
    if [[ "$out" == *"invalid choice"* ]]; then ok "rejects a choice out of range"; else fail "bad choice: $out"; fi
    if grep -q '^sudo' "$CALLS"; then fail "mounted after a bad choice"; else ok "no mount after a bad choice"; fi

    exit "$FAILED"
}

main "$@"
