#!/usr/bin/env bash
#
# Runs inside the container after bootstrap.sh. Asserts pinned versions,
# symlinks, login shell, and that zsh/nvim start cleanly.
#
set -euo pipefail

readonly SRC="${1:-/src}"
FAILED=0

# Pull the pinned versions from the script itself.
eval "$(grep -E '^readonly [A-Z_0-9]+_(VERSION|VERSION_PIN|REF|VERSION_LINUX|VERSION_MACOS|VERSION_AL2_AARCH64|TOOLCHAIN)=' "$SRC/bootstrap.sh")"

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

check_version() {
    local name="$1" want="$2"
    shift 2
    local out
    out="$("$@" 2>&1 | head -n 2 | tr '\n' ' ' || true)"
    if [[ "$out" == *"$want"* ]]; then
        ok "$name $want"
    else
        fail "$name: want '$want', got '$out'"
    fi
}

check_link() {
    local dst="$1" src="$2"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        ok "link $dst"
    else
        fail "link $dst -> $(readlink "$dst" 2>/dev/null || echo MISSING)"
    fi
}

check_pin() {
    local dir="$1" ref="$2"
    if [[ "$(git -C "$dir" rev-parse HEAD 2>/dev/null)" == "$ref" ]]; then
        ok "pin $dir"
    else
        fail "pin $dir not at $ref"
    fi
}

export PATH="/usr/local/bin:$PATH"
arch="$(uname -m)"
is_al2=0
grep -q 'VERSION_ID="2"' /etc/os-release && is_al2=1

# The categories bootstrap.sh installed: BOOTSTRAP_CATEGORIES from run.sh,
# "all", and the BOOTSTRAP_XORG=1 alias for desktop.
categories=" ${BOOTSTRAP_CATEGORIES:-} "
[[ "$categories" == *" all "* ]] && categories=" devtools desktop "
[[ "${BOOTSTRAP_XORG:-0}" == "1" ]] && categories+="desktop "
has_category() { [[ "$categories" == *" $1 "* ]]; }

# For a category that was not selected: its files must not exist.
check_absent() {
    local category="$1" path="$2"
    if [[ -e "$path" || -L "$path" ]]; then
        fail "$path exists without $category"
    else
        ok "no $path without $category"
    fi
}

node_want="$NODE_VERSION"
if [[ $is_al2 -eq 1 && "$arch" == "aarch64" ]]; then
    node_want="$NODE_VERSION_AL2_AARCH64"
fi

check_version zsh     "zsh $ZSH_VERSION_PIN" /usr/local/bin/zsh --version
check_version tmux    "tmux $TMUX_VERSION_LINUX" tmux -V
check_version nvim    "NVIM v$NVIM_VERSION" nvim --version
check_version fzf     "$FZF_VERSION" fzf --version
check_version zoxide  "zoxide $ZOXIDE_VERSION" zoxide --version
check_version yazi    "Version: $YAZI_VERSION" yazi --version
check_version uv      "uv $UV_VERSION" uv --version
check_version fd      "fd $FD_VERSION" fd --version
check_version dua     "dua $DUA_VERSION" dua --version
check_version rg      "ripgrep $RIPGREP_VERSION" rg --version
check_version bat     "bat $BAT_VERSION" bat --version
check_version mise    "$MISE_VERSION" mise --version
check_version rustc   "rustc $RUST_TOOLCHAIN" "$HOME/.cargo/bin/rustc" --version
check_version tree-sitter "tree-sitter $TREE_SITTER_VERSION" tree-sitter --version
check_version node    "v$node_want" node --version
check_version python  "Python $PYTHON_VERSION" "/usr/local/bin/python$PYTHON_VERSION" --version
check_version nnn     "$NNN_VERSION" nnn -V

check_version pynvim  "$PYNVIM_VERSION" \
    "$HOME/.local/share/nvim/python3-venv/bin/python" -c 'import importlib.metadata as m; print(m.version("pynvim"))'
check_version node-neovim "neovim@$NODE_NEOVIM_VERSION" npm ls -g --prefix /usr/local neovim --depth=0 --parseable --long

D="$HOME/.dotfiles"
check_link "$HOME/.zsh" "$D/.zsh"
check_link "$HOME/.gitconfig" "$D/.gitconfig"
check_link "$HOME/.config/nvim/init.lua" "$D/.vim.init.lua"
check_link "$HOME/.config/nvim/lazy-lock.json" "$D/lazy-lock.json"
check_link "$HOME/.tmux.conf" "$D/tmux/tmux_linux_$TMUX_VERSION_LINUX/.tmux.conf"
check_link "$HOME/.tmux/custom" "$D/.tmux/custom"
check_link "$HOME/.config/yazi" "$D/.config/yazi"
check_link "$HOME/bin/fzf-cache" "$D/bin/fzf-cache"
check_link "$HOME/.vsnip" "$D/.vsnip"
vsnip_internal="$HOME/.vsnip-internal"
if [[ -d "$vsnip_internal" && ! -L "$vsnip_internal" && "$(stat -c %a "$vsnip_internal")" == "700" ]]; then
    ok "internal snippet directory $vsnip_internal"
else
    fail "internal snippet directory missing, a link or not owner-only: $vsnip_internal"
fi

# sshd accepts LC_COLOR_SCHEME (light/dark from the ssh wrapper in .zshrc)
# where it reads sshd_config.d. AL2's sshd has no Include.
# sudo: Fedora/EL keep sshd_config at mode 600.
if [[ -d /etc/ssh/sshd_config.d ]] && sudo -n grep -qE '^Include .*sshd_config\.d' /etc/ssh/sshd_config 2>/dev/null; then
    if sudo -n cmp -s "$D/sshd-conf/50-color-scheme.conf" /etc/ssh/sshd_config.d/50-color-scheme.conf; then
        ok "sshd accepts LC_COLOR_SCHEME"
    else
        fail "sshd_config.d/50-color-scheme.conf missing or differs"
    fi
    # sshd -T needs a host key; a throwaway one keeps the system unchanged.
    # Debian/Ubuntu sshd also needs /run/sshd, which ssh.service creates; a
    # container never started the service.
    sshd_bin="$(command -v sshd || echo /usr/sbin/sshd)"
    [[ -d /run/sshd ]] || sudo -n mkdir -p /run/sshd
    key_dir="$(mktemp -d)"
    ssh-keygen -q -t ed25519 -N '' -f "$key_dir/key"
    # Captured first: `| grep -q` exits early, and pipefail would report
    # sshd's SIGPIPE as a failure.
    sshd_config="$(sudo -n "$sshd_bin" -T -h "$key_dir/key" -C user=root,host=x,addr=127.0.0.1 2>/dev/null || true)"
    if grep -qi '^acceptenv.*lc_color_scheme' <<< "$sshd_config"; then
        ok "sshd -T shows AcceptEnv LC_COLOR_SCHEME"
    else
        fail "sshd -T: no AcceptEnv LC_COLOR_SCHEME"
    fi
    rm -rf "$key_dir"
fi

# Dev tools: only with the devtools category.
check_devtools() {
    check_version lazygit "version=$LAZYGIT_VERSION" lazygit --version
    check_version direnv  "$DIRENV_VERSION" direnv version
    check_version rust-analyzer "rust-analyzer $RUST_TOOLCHAIN" "$HOME/.cargo/bin/rust-analyzer" --version
    if [[ -d "$("$HOME/.cargo/bin/rustc" --print sysroot 2>/dev/null)/lib/rustlib/src/rust/library/std" ]]; then
        ok "rust-src (std sources for rust-analyzer)"
    else
        fail "rust-src missing"
    fi
    check_version lspmux  "lspmux $LSPMUX_VERSION" lspmux --version
    check_link "$HOME/.config/lazygit/config.yml" "$D/AppData/Roaming/lazygit/config.yml"

    local codelldb_dir="$HOME/.local/share/nvim/lazy/vimspector/gadgets/linux/CodeLLDB"
    if [[ -x "$codelldb_dir/adapter/codelldb" && -f "$codelldb_dir/lldb/lib/liblldb.so" ]] \
        && "$codelldb_dir/adapter/codelldb" --help >/dev/null 2>&1; then
        ok "codelldb $CODELLDB_VERSION"
    else
        fail "codelldb missing or not runnable in $codelldb_dir"
    fi

    # lspmux: owner-only Unix socket, no TCP port, service enabled.
    local lspmux_dir="$HOME/.local/state/lspmux"
    local lspmux_sock="$lspmux_dir/lspmux.sock"
    local lspmux_conf="$HOME/.config/lspmux/config.toml"
    if grep -qx "listen = \"$lspmux_sock\"" "$lspmux_conf" 2>/dev/null \
        && grep -qx "connect = \"$lspmux_sock\"" "$lspmux_conf"; then
        ok "lspmux config uses $lspmux_sock"
    else
        fail "lspmux config: $(cat "$lspmux_conf" 2>/dev/null || echo MISSING)"
    fi
    if [[ "$(stat -c %a "$lspmux_dir" 2>/dev/null)" == "700" ]]; then
        ok "lspmux socket directory is owner-only"
    else
        fail "lspmux socket directory mode: $(stat -c %a "$lspmux_dir" 2>/dev/null || echo MISSING)"
    fi
    local lspmux_unit="/etc/systemd/system/lspmux.service"
    if grep -qx "User=$USER" "$lspmux_unit" 2>/dev/null && ! grep -qE '##[A-Z_]+##' "$lspmux_unit"; then
        ok "lspmux service runs as $USER"
    else
        fail "lspmux service missing or not filled in: $lspmux_unit"
    fi
    if ! command -v systemctl >/dev/null; then
        ok "lspmux service enable skipped (no systemctl)"
    elif [[ "$(readlink /etc/systemd/system/default.target.wants/lspmux.service)" == "$lspmux_unit" ]]; then
        ok "lspmux service enabled"
    else
        fail "lspmux service not enabled"
    fi
    # No user manager runs in the container; start the server by hand.
    lspmux server >/tmp/lspmux.log 2>&1 &
    local lspmux_pid=$!
    for _ in $(seq 50); do
        [[ -S "$lspmux_sock" ]] && break
        sleep 0.1
    done
    if lspmux status >/tmp/lspmux-status.log 2>&1; then
        ok "lspmux server answers on its socket"
    else
        fail "lspmux status: $(head -n 3 /tmp/lspmux-status.log)"
    fi
    if (exec 3<>/dev/tcp/127.0.0.1/27631) 2>/dev/null; then
        fail "lspmux listens on TCP 127.0.0.1:27631"
    else
        ok "lspmux has no TCP port"
    fi
    kill "$lspmux_pid" 2>/dev/null || true
    wait "$lspmux_pid" 2>/dev/null || true
}

check_no_devtools() {
    local path
    for path in /usr/local/bin/lazygit /usr/local/bin/direnv /usr/local/bin/lspmux \
        "$HOME/.config/lazygit/config.yml" "$HOME/.config/lspmux/config.toml" \
        /etc/systemd/system/lspmux.service "$HOME/.local/share/nvim/lazy/vimspector/gadgets/linux/CodeLLDB"; do
        check_absent devtools "$path"
    done
    if "$HOME/.cargo/bin/rustup" component list --installed --toolchain "$RUST_TOOLCHAIN" 2>/dev/null \
        | grep -q '^rust-analyzer'; then
        fail "rust-analyzer component installed without devtools"
    else
        ok "no rust-analyzer component without devtools"
    fi
}

if has_category devtools; then
    check_devtools
else
    check_no_devtools
fi

# Xorg checks: distros where bootstrap installs the desktop (RHEL only up to 9).
xorg_expected=0
# shellcheck disable=SC1091
os_id="$(. /etc/os-release && echo "$ID")"
# shellcheck disable=SC1091
os_major="$(. /etc/os-release && echo "${VERSION_ID%%.*}")"
if has_category desktop; then
    case "$os_id" in
        debian|ubuntu|fedora) xorg_expected=1 ;;
        rocky|almalinux|centos|rhel) [[ "$os_major" -le 9 ]] && xorg_expected=1 ;;
    esac
else
    check_absent desktop "$HOME/.xinitrc"
    check_absent desktop /usr/local/bin/wmfocus
fi
if [[ $xorg_expected -eq 1 ]]; then
    check_link "$HOME/.xinitrc" "$D/.xinitrc"
    check_link "$HOME/.xprofile" "$D/.xprofile"
    check_link "$HOME/bin/kb" "$D/bin/kb"
    check_link "$HOME/bin/i3status-kb" "$D/bin/i3status-kb"
    check_link "$HOME/bin/pwr" "$D/bin/pwr"
    check_link "$HOME/bin/theme" "$D/bin/theme"
    check_link "$HOME/bin/flightmode" "$D/bin/flightmode"
    check_link "$HOME/bin/touchpad" "$D/bin/touchpad"
    check_link "$HOME/bin/charge" "$D/bin/charge"
    check_link "$HOME/bin/caffeinate" "$D/bin/caffeinate"
    check_link "$HOME/bin/smb" "$D/bin/smb"
    check_link "$HOME/bin/input-restore" "$D/bin/input-restore"
    theme_out="$("$HOME/bin/theme" show 2>&1 || true)"
    if [[ "$theme_out" == "dark" ]]; then
        ok "theme defaults to dark"
    else
        fail "theme show: $theme_out"
    fi
    check_link "$HOME/.config/xremap" "$D/.config/xremap"
    eval "$(grep -E '^readonly IDLE_[A-Z_]+_MINUTES=' "$SRC/bootstrap.sh")"
    idle_want="IDLE_LOCK_MINUTES=$IDLE_LOCK_MINUTES IDLE_SUSPEND_MINUTES=$IDLE_SUSPEND_MINUTES "
    idle_have="$(grep -v '^#' "$HOME/.config/idle.conf" 2>/dev/null | tr '\n' ' ')"
    if [[ "$idle_have" == "$idle_want" ]]; then
        ok "idle.conf ($idle_want)"
    else
        fail "idle.conf: want '$idle_want', got '$idle_have'"
    fi
    if cmp -s "$D/logind-conf/50-lid-suspend.conf" /etc/systemd/logind.conf.d/50-lid-suspend.conf; then
        ok "logind.conf.d lid suspend installed"
    else
        fail "logind.conf.d/50-lid-suspend.conf missing or differs"
    fi
    if cmp -s "$D/system-sleep/power-button-wake" /usr/lib/systemd/system-sleep/power-button-wake \
        && [[ -x /usr/lib/systemd/system-sleep/power-button-wake ]]; then
        ok "system-sleep power-button-wake hook installed"
    else
        fail "system-sleep/power-button-wake missing, differs or not executable"
    fi
    pwr_out="$("$HOME/bin/pwr" --bogus 2>&1 || true)"
    if [[ "$pwr_out" == "usage: pwr lock [--nofork] | sleep | hibernate | performance | balanced | battery | mode" ]]; then
        ok "pwr rejects an unknown command"
    else
        fail "pwr: $pwr_out"
    fi
    # Power modes: tuned with its power-profiles-daemon API on Fedora and EL.
    case "$os_id" in
        fedora|rocky|almalinux|centos|rhel)
            if cmp -s "$D/xinitrc-d/90-xprofile.sh" /etc/X11/xinit/xinitrc.d/90-xprofile.sh \
                && [[ -x /etc/X11/xinit/xinitrc.d/90-xprofile.sh ]]; then
                ok "xinitrc.d sources ~/.xprofile"
            else
                fail "xinitrc.d/90-xprofile.sh missing, differs or not executable"
            fi
            if rpm -q tuned tuned-ppd >/dev/null; then ok "tuned and tuned-ppd installed"; else fail "tuned or tuned-ppd missing"; fi
            enabled="$(systemctl is-enabled tuned.service tuned-ppd.service power-mode-auto.service 2>&1 | tr '\n' ' ' || true)"
            if [[ "$enabled" == "enabled enabled enabled " ]]; then
                ok "tuned, tuned-ppd and power-mode-auto enabled"
            else
                fail "units not enabled: $enabled"
            fi
            for pair in "power-mode-auto:/usr/local/libexec/power-mode-auto" \
                "power-mode-auto.service:/etc/systemd/system/power-mode-auto.service" \
                "90-power-mode-auto.rules:/etc/udev/rules.d/90-power-mode-auto.rules"; do
                if cmp -s "$D/power-mode/${pair%%:*}" "${pair#*:}"; then
                    ok "installed ${pair#*:}"
                else
                    fail "${pair#*:} missing or differs"
                fi
            done
            if [[ -x /usr/local/libexec/power-mode-auto && ! -L /usr/local/libexec/power-mode-auto ]]; then
                ok "power-mode-auto is a root-owned copy"
            else
                fail "power-mode-auto not an executable copy"
            fi
            ;;
    esac
    # 1.5x -> 24 px Terminus
    case "$os_id" in
        debian|ubuntu) font_line="$(grep -E '^FONT(FACE|SIZE)=' /etc/default/console-setup | tr '\n' ' ')"; font_want='FONTFACE="Terminus" FONTSIZE="12x24" ' ;;
        *)             font_line="$(grep -E '^FONT=' /etc/vconsole.conf)"; font_want='FONT=ter-124n' ;;
    esac
    if [[ "$font_line" == "$font_want" ]]; then
        ok "console font for 1.5x ($font_want)"
    else
        fail "console font: want '$font_want', got '$font_line'"
    fi
    if [[ "$os_id" == fedora ]]; then
        if [[ "$(sed -n 2p /etc/kmscon/kmscon.conf 2>/dev/null)" == "font-size=24" ]]; then
            ok "kmscon.conf font-size=24"
        else
            fail "kmscon.conf: $(cat /etc/kmscon/kmscon.conf 2>&1)"
        fi
        if grep -qx 'palette=solarized' /etc/kmscon/kmscon.conf 2>/dev/null; then
            ok "kmscon.conf palette=solarized"
        else
            fail "kmscon.conf has no palette=solarized"
        fi
        # PragmataPro only where fontconfig finds it (not in the test images).
        kmscon_font="$(grep '^font-name=' /etc/kmscon/kmscon.conf 2>/dev/null || true)"
        if [[ -n "$(fc-list ':family=PragmataPro Mono' 2>/dev/null)" ]]; then
            kmscon_font_want="font-name=PragmataPro Mono"
        else
            kmscon_font_want=""
        fi
        if [[ "$kmscon_font" == "$kmscon_font_want" ]]; then
            ok "kmscon.conf font: '${kmscon_font_want:-default}'"
        else
            fail "kmscon.conf font: want '$kmscon_font_want', got '$kmscon_font'"
        fi
    fi
    if cmp -s "$D/xorg-conf/40-touchpad.conf" /etc/X11/xorg.conf.d/40-touchpad.conf; then
        ok "xorg.conf.d touchpad installed"
    else
        fail "xorg.conf.d/40-touchpad.conf missing or differs"
    fi
    if cmp -s "$D/xorg-conf/50-keyboard-repeat.conf" /etc/X11/xorg.conf.d/50-keyboard-repeat.conf; then
        ok "xorg.conf.d keyboard repeat installed"
    else
        fail "xorg.conf.d/50-keyboard-repeat.conf missing or differs"
    fi
    check_version xremap "xremap $XREMAP_VERSION" xremap --version
    if [[ -f /etc/udev/rules.d/99-xremap-uinput.rules ]] && grep -q uinput /etc/modules-load.d/uinput.conf 2>/dev/null; then
        ok "xremap udev rule and uinput module config"
    else
        fail "xremap udev/uinput config missing"
    fi
    if id -nG "$USER" | tr ' ' '\n' | grep -qx input; then
        ok "user in input group"
    else
        fail "user not in input group: $(id -nG "$USER")"
    fi
    # Third line is the first status array; it must start with the kb block.
    status_line="$(timeout 5 "$HOME/bin/i3status-kb" </dev/null 2>/dev/null | sed -n 3p || true)"
    if [[ "$status_line" == '[{"name":"kb","full_text":"KB: '* ]]; then
        ok "i3status-kb emits the keyboard block"
    else
        fail "i3status-kb: ${status_line:-no output}"
    fi
    if [[ -f "$HOME/.Xresources" && ! -L "$HOME/.Xresources" ]] && grep -qE '^Xft\.dpi:\s+144$' "$HOME/.Xresources" \
        && ! grep -q '##XFT_DPI##' "$HOME/.Xresources"; then
        ok ".Xresources rendered with Xft.dpi 144 (1.5x)"
    else
        fail ".Xresources: $(grep -E '^Xft\.dpi' "$HOME/.Xresources" 2>/dev/null || echo missing)"
    fi
    kb_out="$("$HOME/bin/kb" xx 2>&1 || true)"
    if [[ "$kb_out" == *"unknown layout: xx"* ]]; then
        ok "kb rejects an unknown layout"
    else
        fail "kb: $kb_out"
    fi
    # No console in the container: compile the keymaps instead of loading them.
    for keymap in us de-latin1 "$D/console/bone2.map"; do
        if loadkeys -u -m "$keymap" >/dev/null 2>&1; then
            ok "console keymap compiles: ${keymap##*/}"
        else
            fail "console keymap: $(loadkeys -u -m "$keymap" 2>&1 >/dev/null | head -n 1) (${keymap##*/})"
        fi
    done
    check_link "$HOME/.Xmodmap" "$D/.Xmodmap"
    check_link "$HOME/.config/i3" "$D/.config/i3"
    check_link "$HOME/.config/i3status" "$D/.config/i3status"
    check_link "$HOME/.config/picom" "$D/.config/picom"
    check_link "$HOME/.config/systemd/user/i3-session.target" "$D/.config/systemd/user/i3-session.target"
    check_link "$HOME/.wezterm.lua" "$D/.wezterm.lua"
    wezterm_stamp="$(cat /usr/local/share/bootstrap/wezterm 2>/dev/null || true)"
    check_version wezterm "wezterm $wezterm_stamp" wezterm --version
    if [[ "$wezterm_stamp" == 2026* || "$wezterm_stamp" == 2027* ]]; then
        ok "wezterm is a recent nightly ($wezterm_stamp)"
    else
        fail "wezterm stamp not a nightly build: '$wezterm_stamp'"
    fi
    check_version nmrs-gui "nmrs-gui $NMRS_GUI_VERSION" nmrs-gui --version
    check_version wmfocus "wmfocus $WMFOCUS_VERSION" wmfocus --version
    if grep -qx 'Exec=nmrs-gui' /usr/local/share/applications/nmrs.desktop 2>/dev/null; then
        ok "nmrs.desktop installed"
    else
        fail "nmrs.desktop missing in /usr/local/share/applications"
    fi
    for bin in i3 i3status dmenu xsetroot xset setxkbmap xmodmap amixer pavucontrol brightnessctl xinput rfkill smbclient mount.cifs btop remmina startx xclip i3lock; do
        if command -v "$bin" >/dev/null; then ok "xorg bin $bin"; else fail "xorg bin missing: $bin"; fi
    done
    # firewalld's GUI and Sunshine (lizardbyte copr): Fedora only.
    if [[ "$os_id" == fedora ]]; then
        for bin in firewall-config sunshine; do
            if command -v "$bin" >/dev/null; then ok "xorg bin $bin"; else fail "xorg bin missing: $bin"; fi
        done
    fi
    # Not packaged for EL9.
    if grep -qE '^ID=(debian|ubuntu|fedora)$' /etc/os-release; then
        for bin in xss-lock xautolock blueman-applet blueman-manager picom; do
            if command -v "$bin" >/dev/null; then ok "xorg bin $bin"; else fail "xorg bin missing: $bin"; fi
        done
        # Imports all its GObject libraries; Fedora's package misses one.
        if blueman-applet --help >/dev/null 2>/tmp/blueman.log; then
            ok "blueman-applet starts"
        else
            fail "blueman-applet: $(tail -n 1 /tmp/blueman.log)"
        fi
        bt_enabled="$(systemctl is-enabled bluetooth.service 2>&1 || true)"
        if ! command -v systemctl >/dev/null; then
            ok "bluetooth.service: no systemctl in this image"
        elif [[ "$bt_enabled" == "enabled" ]]; then
            ok "bluetooth.service enabled"
        else
            fail "bluetooth.service: $bt_enabled"
        fi
        # The tray needs no primary output; arandr and autorandr use xrandr.
        if command -v xrandr >/dev/null; then ok "xorg bin xrandr"; else fail "xorg bin missing: xrandr"; fi
        # Monitor layout: arandr to arrange, autorandr to store and reapply.
        for bin in arandr autorandr; do
            if command -v "$bin" >/dev/null; then ok "xorg bin $bin"; else fail "xorg bin missing: $bin"; fi
        done
        # Imports GTK 3; Fedora's arandr package does not depend on it.
        if arandr --help 2>/dev/null | grep -q '^Usage: arandr'; then
            ok "arandr starts"
        else
            fail "arandr: $(arandr --help 2>&1 | tail -n 1)"
        fi
        ar_enabled="$(systemctl is-enabled autorandr.service 2>&1 || true)"
        if ! command -v systemctl >/dev/null; then
            ok "autorandr.service: no systemctl in this image"
        elif [[ "$ar_enabled" == "enabled" ]]; then
            ok "autorandr.service enabled (runs after resume)"
        else
            fail "autorandr.service: $ar_enabled"
        fi
    fi
    # CopyQ keeps password-manager copies out of its history only since 8.0.0;
    # bootstrap skips older Debian/Ubuntu packages. CopyQ 8 (EL9) needs a
    # Qt platform even for --version.
    copyq_version="$(QT_QPA_PLATFORM=offscreen copyq --version 2>/dev/null | sed -n 's/^CopyQ Clipboard Manager v\{0,1\}\([0-9.]*\).*/\1/p' | head -n 1 || true)"
    case "$os_id" in
        fedora|rocky|almalinux|centos|rhel)
            if [[ -n "$copyq_version" ]]; then ok "copyq $copyq_version"; else fail "copyq missing"; fi ;;
        *)
            if [[ -z "$copyq_version" ]]; then ok "copyq skipped (distro package too old)"; else ok "copyq $copyq_version"; fi ;;
    esac
    if [[ -n "$copyq_version" ]] && [[ "$(printf '%s\n8.0.0\n' "$copyq_version" | sort -V | head -n 1)" != "8.0.0" ]]; then
        fail "copyq $copyq_version is older than 8.0.0"
    fi
    if grep -qE '^\s*tray_output' "$HOME/.config/i3/config"; then
        fail "i3 bar sets tray_output; the tray vanishes without a primary output"
    else
        ok "i3 bar shows the tray on the first active output"
    fi
    # i3 validates its config without a display.
    if i3 -C -c "$HOME/.config/i3/config" >/tmp/i3.log 2>&1; then
        ok "i3 config valid"
    else
        fail "i3 config: $(head -n 2 /tmp/i3.log)"
    fi
fi

check_pin "$HOME/.oh-my-zsh" "$OHMYZSH_REF"
check_pin "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$ZSH_AUTOSUGGESTIONS_REF"
check_pin "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "$ZSH_SYNTAX_HIGHLIGHTING_REF"
check_pin "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" "$FAST_SYNTAX_HIGHLIGHTING_REF"
check_pin "$HOME/.tmux/plugins/tpm" "$TPM_REF"

if grep -q '##NEW' "$HOME/.zshrc"; then
    fail ".zshrc still has placeholders"
else
    ok ".zshrc placeholders replaced"
fi
if grep -q "^export HOME=$HOME\$" "$HOME/.zshrc"; then
    ok ".zshrc HOME"
else
    fail ".zshrc HOME not set to $HOME"
fi

if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "/usr/local/bin/zsh" ]]; then
    ok "login shell"
else
    fail "login shell is $(getent passwd "$USER" | cut -d: -f7)"
fi

if /usr/local/bin/zsh -i -c 'exit 0' >/tmp/zsh.log 2>&1; then
    ok "zsh -i starts"
else
    fail "zsh -i: $(head -n 3 /tmp/zsh.log)"
fi
# .zshrc loads the oh-my-zsh direnv plugin only when direnv (devtools) exists.
if grep -q 'direnv not found' /tmp/zsh.log; then
    fail "zsh -i warns: $(grep 'direnv not found' /tmp/zsh.log | head -n 1)"
else
    ok "zsh -i: no direnv warning"
fi

if nvim --headless -c 'lua if vim.fn.filereadable(vim.g.python3_host_prog) == 0 then os.exit(1) end' +qa >/tmp/nvim.log 2>&1; then
    ok "nvim python3_host_prog"
else
    fail "nvim python3_host_prog: $(head -n 3 /tmp/nvim.log)"
fi

if [[ -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]]; then
    ok "lazy.nvim installed"
else
    fail "lazy.nvim missing"
fi

# lazy.nvim may leave the checkout detached; compare against the lockfile pin.
ts_want="$(sed -nE 's/.*"nvim-treesitter": \{ "branch": "main", "commit": "([0-9a-f]+)".*/\1/p' "$SRC/lazy-lock.json")"
ts_have="$(git -C "$HOME/.local/share/nvim/lazy/nvim-treesitter" rev-parse HEAD 2>/dev/null || true)"
if [[ -n "$ts_want" && "$ts_have" == "$ts_want" ]]; then
    ok "nvim-treesitter at main pin $ts_want"
else
    fail "nvim-treesitter: want main@$ts_want got $ts_have"
fi

# lazy.nvim before v11.17.5 misreads "lua==5.1" in rockspecs (rustaceanvim)
# as a rock and then needs luarocks, which Fedora does not ship.
lazy_want="$(sed -nE 's/.*"lazy.nvim": \{ "branch": "[^"]+", "commit": "([0-9a-f]+)".*/\1/p' "$SRC/lazy-lock.json")"
lazy_have="$(git -C "$HOME/.local/share/nvim/lazy/lazy.nvim" rev-parse HEAD 2>/dev/null || true)"
if [[ -n "$lazy_want" && "$lazy_have" == "$lazy_want" ]]; then
    ok "lazy.nvim at pin $lazy_want"
else
    fail "lazy.nvim: want $lazy_want got $lazy_have"
fi
# shellcheck disable=SC2016
rocks_out="$(nvim --headless -c 'lua
  local names = {}
  for name, plugin in pairs(require("lazy.core.config").plugins) do
    if plugin.build == "rockspec" then names[#names + 1] = name end
  end
  table.sort(names)
  io.stdout:write("rockspec=" .. table.concat(names, ",") .. "\n")' +qa 2>&1 | grep -ao 'rockspec=.*' || true)"
if [[ "$rocks_out" == "rockspec=" ]]; then
    ok "no plugin needs luarocks"
else
    fail "plugins built with luarocks: ${rocks_out:-no output}"
fi

parser_dir="$HOME/.local/share/nvim/site/parser"
missing_parsers=""
for lang in c cpp cmake rust json json5 javascript typescript tsx vim lua go haskell bash markdown markdown_inline python html regex yaml zig; do
    [[ -f "$parser_dir/$lang.so" ]] || missing_parsers="$missing_parsers $lang"
done
if [[ -z "$missing_parsers" ]]; then
    ok "treesitter parsers built"
else
    fail "treesitter parsers missing:$missing_parsers"
fi

# The hover window renders markdown with injections; this is what broke on master.
# shellcheck disable=SC2016
if nvim --headless -c 'set ft=markdown' -c 'call setline(1, ["```rust", "fn main() {}", "```"])' \
    -c 'lua vim.treesitter.get_parser(0):parse(true)' +qa! >/tmp/ts.log 2>&1; then
    ok "markdown injection parse"
else
    fail "markdown injection parse: $(head -n 2 /tmp/ts.log)"
fi

# checkhealth probes providers asynchronously; retry if the report came back empty.
python_section=""
for _ in 1 2 3; do
    rm -f /tmp/health.txt
    nvim --headless -c 'checkhealth vim.provider' -c 'w! /tmp/health.txt' +qa >/dev/null 2>&1 || true
    python_section="$(awk '/Python 3 provider/{p=1} /Ruby provider/{p=0} p' /tmp/health.txt 2>/dev/null)"
    [[ -n "$python_section" ]] && break
    sleep 2
done
if [[ "$python_section" == *"OK"* && "$python_section" != *"ERROR"* ]]; then
    ok "nvim :checkhealth python3 provider"
else
    fail "nvim python3 provider: $(printf '%s' "$python_section" | grep -E 'ERROR|WARNING' | head -n 2)"
fi

exit "$FAILED"
