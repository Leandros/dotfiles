#!/usr/bin/env bash
#
# The sway session at the login screen: the session entry lightdm lists
# (wayland-session/sway-dotfiles.desktop), the wrapper it runs
# (wayland-session/sway-session: English, the Wayland environment, the X
# display of xwayland-satellite, then sway) and the systemd target that
# activates graphical-session.target, which xdg-desktop-portal requires
# since Fedora 45.
#
# With docker it also runs the wrapper the way Fedora 45's lightdm does:
# through its session-wrapper (Xsession, which sources xinitrc.d) with the
# environment lightdm sets for a Wayland session, and validates the entry
# with desktop-file-validate.
#
# Usage: test/sway-session/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
readonly TARGET="$ROOT/.config/systemd/user/sway-session.target"
readonly WRAPPER="$ROOT/wayland-session/sway-session"
readonly ENTRY="$ROOT/wayland-session/sway-dotfiles.desktop"
readonly AUTOSTART="$ROOT/bin/sway-autostart"
readonly SWAY_CONFIG="$ROOT/.config/sway/config"
readonly XPROFILE_HOOK="$ROOT/xinitrc-d/90-xprofile.sh"
readonly IMAGE="fedora:45"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

has() {
    local name="$1" file="$2" pattern="$3"
    if [[ -f "$file" ]] && grep -qE "$pattern" "$file"; then ok "$name"; else fail "$name"; fi
}

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: want '$want', got '$got'"; fi
}

check_target() {
    has "target binds graphical-session.target" "$TARGET" '^BindsTo=graphical-session\.target$'
    has "target pulls in graphical-session-pre.target" "$TARGET" '^Wants=graphical-session-pre\.target$'
    has "target starts after graphical-session-pre.target" "$TARGET" '^After=graphical-session-pre\.target$'
    # test/sway-autostart checks that it starts the target.
    has "sway-autostart names the target" "$AUTOSTART" '^readonly SESSION_TARGET="sway-session\.target"$'
    has "exiting sway stops the target first" "$SWAY_CONFIG" "systemctl --user stop sway-session\.target; swaymsg exit"
}

check_entry() {
    has "entry: name" "$ENTRY" '^Name=Sway \(dotfiles\)$'
    has "entry: runs the wrapper" "$ENTRY" '^Exec=/usr/local/bin/sway-session$'
    has "entry: type" "$ENTRY" '^Type=Application$'
    # lightdm sets XDG_CURRENT_DESKTOP from it; xdg-desktop-portal then
    # reads sway-portals.conf (sway package).
    has "entry: desktop name" "$ENTRY" '^DesktopNames=sway$'
}

# Runs the wrapper with a stub sway that prints its arguments and
# environment. Extra arguments are the environment of the caller.
run_wrapper() {
    mkdir -p "$TMP/bin"
    cat > "$TMP/bin/sway" <<'EOF'
#!/bin/sh
echo "args=$*"
env
EOF
    chmod +x "$TMP/bin/sway"
    mkdir -p "$TMP/x11/.X11-unix"
    env -i PATH="$TMP/bin:/usr/bin:/bin" HOME="$TMP" X11_TMPDIR="$TMP/x11" "$@" /bin/sh "$WRAPPER" -d
}

check_wrapper() {
    if [[ ! -f "$WRAPPER" ]]; then
        fail "wayland-session/sway-session is missing"
        return
    fi
    if [[ -x "$WRAPPER" ]]; then ok "wrapper is executable"; else fail "wrapper is not executable"; fi

    # As lightdm starts it: LANG from the AccountsService language
    # (German), the session name as XDG_SESSION_DESKTOP.
    local out
    out="$(run_wrapper LANG=de_DE.UTF-8 XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=sway \
        XDG_SESSION_DESKTOP=sway-dotfiles)"
    get() { sed -n "s/^$1=//p" <<< "$out"; }
    expect "execs sway with the arguments" "-d" "$(get args)"
    expect "LANG English" "en_US.UTF-8" "$(get LANG)"
    expect "XDG_CURRENT_DESKTOP" "sway" "$(get XDG_CURRENT_DESKTOP)"
    expect "XDG_SESSION_DESKTOP as the upstream session" "sway" "$(get XDG_SESSION_DESKTOP)"
    expect "XDG_SESSION_TYPE" "wayland" "$(get XDG_SESSION_TYPE)"
    # Electron < 38 runs on Xwayland without it; later versions use
    # XDG_SESSION_TYPE and ignore it.
    expect "Electron on Wayland" "auto" "$(get ELECTRON_OZONE_PLATFORM_HINT)"
    # Java AWT draws empty windows on Xwayland without it (sway does not
    # reparent).
    expect "Java AWT" "1" "$(get _JAVA_AWT_WM_NONREPARENTING)"
    # Qt 5.12+ and 6 select "wayland;xcb" from XDG_SESSION_TYPE; Qt before
    # 5.12 (bundled in some programs) aborts on a QT_QPA_PLATFORM list.
    expect "QT_QPA_PLATFORM not set" "" "$(get QT_QPA_PLATFORM)"

    # X11 programs: xwayland-satellite listens on DISPLAY (the sway config
    # disables sway's own Xwayland). sway cannot change its environment
    # later, so its bindings and fuzzel get DISPLAY only from here. With
    # DISPLAY set and no WLR_BACKENDS, wlroots would run sway nested in
    # that X server.
    expect "DISPLAY: the first free X display" ":0" "$(get DISPLAY)"
    expect "WLR_BACKENDS: as wlroots selects on a console" "libinput,drm" "$(get WLR_BACKENDS)"
    # A socket of a running X server, the lock file of one that starts.
    : > "$TMP/x11/.X11-unix/X0"
    : > "$TMP/x11/.X1-lock"
    out="$(run_wrapper)"
    expect "DISPLAY: skips displays in use" ":2" "$(get DISPLAY)"
    out="$(run_wrapper WLR_BACKENDS=headless)"
    expect "WLR_BACKENDS of the caller stays" "headless" "$(get WLR_BACKENDS)"

    # Started from a virtual console: logind's type is tty and no
    # desktop is set; programs still see a Wayland session.
    out="$(run_wrapper XDG_SESSION_TYPE=tty)"
    expect "tty: XDG_SESSION_TYPE" "wayland" "$(get XDG_SESSION_TYPE)"
    expect "tty: XDG_CURRENT_DESKTOP" "sway" "$(get XDG_CURRENT_DESKTOP)"
}

# Runs inside the container. Prints ok/FAIL lines; exits non-zero on a FAIL.
read -r -d '' INNER <<'EOF' || true
set -uo pipefail
dnf install -y -q --setopt=install_weak_deps=False lightdm xorg-x11-xinit desktop-file-utils util-linux \
    >/dev/null 2>&1 || { echo "FAIL: dnf install"; exit 1; }
FAILED=0
ok()   { echo "ok:   $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }

# DesktopNames is lightdm's key (as in the upstream sway.desktop), not one
# of the desktop entry specification; every other message is an error.
out="$(desktop-file-validate /src/sway-dotfiles.desktop 2>&1 | grep -v 'key "DesktopNames" in group "Desktop Entry"')"
[ -z "$out" ] && ok "desktop-file-validate" || fail "desktop-file-validate: $out"

useradd -m t
install -d -m 0700 -o t /tmp/xdg-t
# Without man pages (container image): no check of Documentation=.
if out="$(runuser -u t -- env XDG_RUNTIME_DIR=/tmp/xdg-t systemd-analyze --user --man=no verify /src/sway-session.target 2>&1)"; then
    ok "systemd-analyze verify"
else
    fail "systemd-analyze: $out"
fi

# As bootstrap.sh installs them.
install -D -m 0755 /src/sway-session /usr/local/bin/sway-session
install -D -m 0644 /src/sway-dotfiles.desktop /usr/share/wayland-sessions/sway-dotfiles.desktop
install -D -m 0644 /src/90-xprofile.sh /etc/X11/xinit/xinitrc.d/90-xprofile.sh

# ~/.xprofile records that it ran; a stub sway records its environment.
cat > /home/t/.xprofile <<'X'
echo loaded > /tmp/xprofile-loaded
X
install -d /usr/local/libexec/stub
cat > /usr/local/libexec/stub/sway <<'S'
#!/bin/sh
env > /tmp/sway-env
S
chmod +x /usr/local/libexec/stub/sway
chown -R t /home/t

# lightdm runs every session through its session-wrapper, Wayland ones too.
wrapper="$(sed -n 's/^session-wrapper=//p' /usr/share/lightdm/lightdm.conf.d/*.conf /etc/lightdm/lightdm.conf | tail -n 1)"
[ -n "$wrapper" ] && ok "lightdm session-wrapper: $wrapper" || fail "no lightdm session-wrapper"
# The environment lightdm sets for this session (seat.c configure_session,
# wayland-session.c), with the AccountsService language.
runuser -u t -- env -i HOME=/home/t USER=t SHELL=/bin/bash PATH=/usr/local/libexec/stub:/usr/bin:/bin \
    XDG_SESSION_TYPE=wayland XDG_SESSION_DESKTOP=sway-dotfiles DESKTOP_SESSION=sway-dotfiles \
    GDMSESSION=sway-dotfiles XDG_CURRENT_DESKTOP=sway LANG=de_DE.UTF-8 \
    "$wrapper" "$(sed -n 's/^Exec=//p' /usr/share/wayland-sessions/sway-dotfiles.desktop)" >/tmp/session.log 2>&1

if [ -f /tmp/sway-env ]; then ok "lightdm's wrapper starts sway"; else fail "sway not started: $(tail -n 3 /tmp/session.log)"; fi
grep -qx 'LANG=en_US.UTF-8' /tmp/sway-env 2>/dev/null && ok "sway in English after the wrapper" || fail "LANG: $(grep '^LANG=' /tmp/sway-env)"
# Xsession runs before the wrapper: its xinitrc.d scripts never see the
# display of xwayland-satellite, and wlroots selects DRM.
grep -qE '^DISPLAY=:[0-9]+$' /tmp/sway-env 2>/dev/null && ok "sway gets an X display" || fail "DISPLAY: $(grep '^DISPLAY=' /tmp/sway-env)"
grep -qx 'WLR_BACKENDS=libinput,drm' /tmp/sway-env 2>/dev/null && ok "sway gets WLR_BACKENDS" || fail "WLR_BACKENDS: $(grep '^WLR_BACKENDS=' /tmp/sway-env)"
# ~/.xprofile is the X session (xremap, xrdb, i3-session.target, ...);
# Xsession sources xinitrc.d for Wayland sessions too.
[ -f /tmp/xprofile-loaded ] && fail "~/.xprofile ran in the sway session (xinitrc-d/90-xprofile.sh)" || ok "no ~/.xprofile in the sway session"
exit "$FAILED"
EOF

check_container() {
    if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
        echo "SKIP: docker not available (desktop-file-validate, lightdm wrapper)"
        return
    fi
    [[ -f "$WRAPPER" && -f "$ENTRY" && -f "$TARGET" ]] || return 0
    local container rc=0
    container="$(docker create "$IMAGE" bash -c "$INNER")"
    mkdir -p "$TMP/src"
    cp "$WRAPPER" "$ENTRY" "$XPROFILE_HOOK" "$TARGET" "$TMP/src/"
    # docker cp, not a bind mount: SELinux hosts would deny the container.
    docker cp "$TMP/src" "$container:/src"
    docker start -a "$container" || rc=$?
    docker rm -f "$container" >/dev/null 2>&1 || true
    [[ "$rc" -eq 0 ]] || FAILED=1
}

main() {
    check_target
    check_entry
    check_wrapper
    check_container
    exit "$FAILED"
}

main "$@"
