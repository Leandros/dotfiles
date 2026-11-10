#!/usr/bin/env bash
#
# Tests the tmux-plugins step of bootstrap.sh: tpm installs the plugins from
# ~/.tmux.conf also inside a tmux server that did not load tpm, a running
# server loads them, and a failed install shows tpm's output. Uses a fake
# HOME, a private tmux socket directory and a local plugin repository; tpm
# comes from GitHub at TPM_REF.
#
# Usage: test/tmux-plugins/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BOOTSTRAP="$HERE/../../bootstrap.sh"
TMP="$(mktemp -d)"
readonly TMP
readonly SOCK_DIR="$TMP/sock"
readonly FUNCS="$TMP/funcs.sh"
readonly PLUGIN_REPO="$TMP/fake-plugin"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

# tmux of the test only: never the caller's server.
ttmux() {
    env -u TMUX -u TMUX_PANE -u TMUX_PLUGIN_MANAGER_PATH TMUX_TMPDIR="$SOCK_DIR" tmux "$@"
}

trap 'ttmux kill-server >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT

mkdir -p "$SOCK_DIR"

# The step and what it uses, as defined in bootstrap.sh.
{
    grep -E '^(log|warn|die)\(\) ' "$BOOTSTRAP"
    grep -E '^readonly (GITHUB|TPM_REF)=' "$BOOTSTRAP"
    sed -n '/^git_pin() {$/,/^}$/p' "$BOOTSTRAP"
    sed -n '/^[a-z_]*tmux[a-z_]*() {$/,/^}$/p' "$BOOTSTRAP"
} > "$FUNCS"

# A plugin that marks the server that loaded it.
mkdir -p "$PLUGIN_REPO"
cat > "$PLUGIN_REPO/fake.tmux" <<'EOF'
#!/usr/bin/env bash
tmux set-option -g @fake-loaded yes
EOF
chmod +x "$PLUGIN_REPO/fake.tmux"
git -C "$PLUGIN_REPO" init -q
git -C "$PLUGIN_REPO" add fake.tmux
git -C "$PLUGIN_REPO" -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false \
    commit -q -m init

# Fake HOME with a .tmux.conf that lists one plugin.
make_home() {
    local home="$1" plugin="$2"
    mkdir -p "$home"
    cat > "$home/.tmux.conf" <<EOF
set -g @plugin '$plugin'
run '~/.tmux/plugins/tpm/tpm'
EOF
}

# Runs setup_tmux_plugins with HOME as given; extra env assignments follow.
setup() {
    local home="$1"
    shift
    mkdir -p "$TMP/work"
    env -u TMUX -u TMUX_PANE -u TMUX_PLUGIN_MANAGER_PATH -u XDG_CONFIG_HOME \
        HOME="$home" TMUX_TMPDIR="$SOCK_DIR" "$@" bash -c "
        set -euo pipefail
        WORK_DIR='$TMP/work'
        source '$FUNCS'
        setup_tmux_plugins
    " 2>&1
}

# Inside a tmux server that started without tpm (bootstrap run in tmux).
home="$TMP/home-in-tmux"
make_home "$home" "file://$PLUGIN_REPO"
HOME="$home" ttmux -f /dev/null new-session -d -s user
sock="$(ttmux display-message -p '#{socket_path}')"
pid="$(ttmux display-message -p '#{pid}')"
out="$(setup "$home" TMUX="$sock,$pid,0")" || true
if [[ -x "$home/.tmux/plugins/fake-plugin/fake.tmux" ]]; then
    ok "install inside a server without tpm"
else
    fail "install inside a server without tpm: $out"
fi
loaded="$(ttmux show-option -gqv @fake-loaded)"
if [[ "$loaded" == "yes" ]]; then
    ok "running server loads the new plugin"
else
    fail "running server did not load the plugin (@fake-loaded '$loaded'): $out"
fi
ttmux kill-server

# No tmux server: install, and no server stays behind.
home="$TMP/home-no-server"
make_home "$home" "file://$PLUGIN_REPO"
out="$(setup "$home")" || true
if [[ -x "$home/.tmux/plugins/fake-plugin/fake.tmux" ]]; then
    ok "install without a server"
else
    fail "install without a server: $out"
fi
if ttmux has-session >/dev/null 2>&1; then
    fail "a tmux server stays behind"
else
    ok "no server stays behind"
fi

# A failed install warns with tpm's output.
home="$TMP/home-bad-plugin"
make_home "$home" "file://$TMP/missing-plugin"
out="$(setup "$home")" || true
if [[ "$out" == *"download fail"* ]]; then
    ok "failed install shows tpm's output"
else
    fail "failed install output: $out"
fi

exit "$FAILED"
