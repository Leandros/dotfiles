#!/usr/bin/env bash
#
# Runs system-sleep/vmware-suspend against a fake /proc with stub runuser,
# vmrun and timeout. Before sleep it must suspend each running VM as the
# owner of its vmware-vmx process (vmx paths with spaces) and nothing else;
# after sleep, or without vmrun, it must do nothing. A failed suspend must
# not stop the sleep or the other VMs. vmrun gets the password of an
# encrypted VM on stdin from <vmx name>.pw, only if the file is the hook
# user's and not readable by others.
#
# Usage: test/system-sleep/vmware-suspend.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOOK="$HERE/../../system-sleep/vmware-suspend"
FAKE="$(mktemp -d)"
readonly FAKE
trap 'rm -rf "$FAKE"' EXIT
export CALLS="$FAKE/calls"
USER_NAME="$(id -un)"
readonly USER_NAME
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

# add_process <pid> <comm> <args...>
add_process() {
    local dir="$FAKE/proc/$1" comm="$2"
    shift 2
    mkdir -p "$dir"
    echo "$comm" > "$dir/comm"
    printf '%s\0' "$@" > "$dir/cmdline"
}

make_stubs() {
    mkdir -p "$FAKE/bin"
    # Records the user, the vmrun arguments and stdin, one call per line.
    cat > "$FAKE/bin/runuser" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == "-u" && "$3" == "--" ]] || { echo "runuser: bad args $*" >&2; exit 2; }
user="$2"; shift 3
VMRUN_USER="$user" exec "$@"
EOF
    cat > "$FAKE/bin/vmrun" <<'EOF'
#!/usr/bin/env bash
in="$(cat)"
printf '%s|%s|%s\n' "$VMRUN_USER" "$*" "$in" >> "$CALLS"
[[ "$*" != *broken* ]]
EOF
    cat > "$FAKE/bin/timeout" <<'EOF'
#!/usr/bin/env bash
shift
exec "$@"
EOF
    chmod +x "$FAKE/bin"/*
}

build_proc() {
    add_process 100 vmware-vmx /usr/lib/vmware/bin/vmware-vmx -s vmx.stdio.keep=TRUE \
        "-@" "duplex=3;msgs=ui" "/home/u/vmware/Windows11/Windows 11 x64.vmx"
    add_process 200 vmware-vmx /usr/lib/vmware/bin/vmware-vmx "/home/u/vmware/broken/broken.vmx"
    add_process 300 vmware-vmx /usr/lib/vmware/bin/vmware-vmx "/home/u/vmware/linux/linux.vmx"
    add_process 400 mksSandbox /usr/lib/vmware/bin/mksSandbox --pipeInfo 3
    add_process 500 vmware /usr/lib/vmware/bin/vmware "/home/u/vmware/other/other.vmx"
    add_process 600 vmware-vmx
    mkdir -p "$FAKE/proc/self"
    mkdir -p "$FAKE/pw"
    echo 'pass word' > "$FAKE/pw/Windows 11 x64.pw"
    chmod 0600 "$FAKE/pw/Windows 11 x64.pw"
    echo 'leaked' > "$FAKE/pw/linux.pw"
    chmod 0644 "$FAKE/pw/linux.pw"
}

run_hook() {
    : > "$CALLS"
    VMWARE_SUSPEND_PROC="$FAKE/proc" VMWARE_SUSPEND_PASSWORDS="$FAKE/pw" PATH="$FAKE/bin:$PATH" \
        "$HOOK" "$@" < /dev/null > "$FAKE/out" 2>&1
}

main() {
    make_stubs
    build_proc

    run_hook pre suspend || fail "pre: exit $?"
    local want
    want="$(printf '%s\n' \
        "$USER_NAME|-T ws suspend /home/u/vmware/Windows11/Windows 11 x64.vmx hard|pass word" \
        "$USER_NAME|-T ws suspend /home/u/vmware/broken/broken.vmx hard|" \
        "$USER_NAME|-T ws suspend /home/u/vmware/linux/linux.vmx hard|")"
    if [[ "$(sort "$CALLS")" == "$(sort <<< "$want")" ]]; then
        ok "pre: suspends each VM as its owner, password file on stdin"
    else
        fail "pre: calls:"; cat "$CALLS"
    fi
    if grep -q 'cannot suspend /home/u/vmware/broken/broken.vmx' "$FAKE/out"; then
        ok "pre: reports a failed suspend"
    else
        fail "pre: no message for the failed suspend"; cat "$FAKE/out"
    fi
    if grep -q "not using $FAKE/pw/linux.pw" "$FAKE/out"; then
        ok "pre: refuses a password file readable by others"
    else
        fail "pre: no message for the open password file"; cat "$FAKE/out"
    fi

    run_hook post suspend || fail "post: exit $?"
    if [[ ! -s "$CALLS" ]]; then ok "post: no change"; else fail "post: called vmrun"; fi

    # Only stubs and the tools the hook needs: the real vmrun is in /usr/bin.
    rm "$FAKE/bin/vmrun"
    local tool
    for tool in bash cat stat; do
        ln -s "$(command -v "$tool")" "$FAKE/bin/$tool"
    done
    : > "$CALLS"
    VMWARE_SUSPEND_PROC="$FAKE/proc" VMWARE_SUSPEND_PASSWORDS="$FAKE/pw" PATH="$FAKE/bin" \
        "$HOOK" pre suspend < /dev/null > "$FAKE/out" 2>&1 || fail "no vmrun: exit $?"
    if [[ ! -s "$FAKE/out" ]]; then ok "no vmrun: nothing to do"; else fail "no vmrun:"; cat "$FAKE/out"; fi

    exit "$FAILED"
}

main "$@"
