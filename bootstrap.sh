#!/usr/bin/env bash
#
# bootstrap.sh - install Arvid's environment on a fresh machine.
#
# Supported: Debian 12+, Ubuntu 22.04+, Fedora 41+, RHEL 9+ and clones
#            (Rocky, Alma, CentOS Stream), Amazon Linux 2, Amazon Linux 2023
#            (x86_64 and aarch64), macOS on Apple Silicon.
#
# Usage:
#   curl -fsSLo bootstrap.sh https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master/bootstrap.sh
#   bash bootstrap.sh
#
# Do not pipe into bash: prompts (sudo password, dpkg) would read the script.
#
# Re-running is safe: tools whose stamp matches the pinned version are skipped,
# others are updated. Tools go to /usr/local (all users), configs to $HOME.
#
# Env:
#   BOOTSTRAP_SKIP="tmux nnn"        skip steps by name (see run_all)
#   BOOTSTRAP_DOTFILES_REPO=<url>    dotfiles source (default: GitHub)
#   BOOTSTRAP_DOTFILES_REF=<branch>  dotfiles branch (default: master)
#   BOOTSTRAP_NONINTERACTIVE=1       allow a non-tty stdin (CI, tests)
#   BOOTSTRAP_XORG=1                 also set up an Xorg/i3 desktop (Debian, Ubuntu, Fedora, RHEL 9)
#   BOOTSTRAP_DPI_SCALE=1|1.5|1.75|2 display scale for the desktop; prompted when unset
#
set -euo pipefail

# =============================================================================
# Versions
# =============================================================================
# https://github.com/neovim/neovim/releases
readonly NVIM_VERSION="0.12.6"
# https://github.com/tmux/tmux/releases
readonly TMUX_VERSION_LINUX="3.5a"
readonly TMUX_VERSION_MACOS="3.4"
# https://www.zsh.org/pub/
readonly ZSH_VERSION_PIN="5.9.2"
# https://github.com/junegunn/fzf/releases
readonly FZF_VERSION="0.74.5"
# https://github.com/ajeetdsouza/zoxide/releases
readonly ZOXIDE_VERSION="0.10.0"
# https://github.com/sxyazi/yazi/releases
readonly YAZI_VERSION="26.9.1"
# https://github.com/jesseduffield/lazygit/releases
readonly LAZYGIT_VERSION="0.66.1"
# https://github.com/astral-sh/uv/releases
readonly UV_VERSION="0.13.1"
# https://github.com/sharkdp/fd/releases
readonly FD_VERSION="10.5.0"
# https://github.com/BurntSushi/ripgrep/releases
readonly RIPGREP_VERSION="15.2.0"
# https://github.com/sharkdp/bat/releases
readonly BAT_VERSION="0.26.1"
# https://github.com/vadimcn/codelldb/releases
readonly CODELLDB_VERSION="1.12.3"
# https://github.com/jdx/mise/releases
readonly MISE_VERSION="2026.10.10"
# https://github.com/direnv/direnv/releases
readonly DIRENV_VERSION="2.38.2"
# https://github.com/jarun/nnn/releases (nnn/nnn-keybindings.patch must apply)
readonly NNN_VERSION="5.3"
# https://nodejs.org/dist/index.json (v20.x)
# AL2 x86_64: https://unofficial-builds.nodejs.org/download/release/
readonly NODE_VERSION="20.20.2"
# Newest official node with glibc 2.17 support. AL2 aarch64 has no node 20.
readonly NODE_VERSION_AL2_AARCH64="16.20.2"
# https://www.npmjs.com/package/neovim
readonly NODE_NEOVIM_VERSION="5.5.0"
# https://github.com/astral-sh/python-build-standalone/releases (via uv)
readonly PYTHON_VERSION="3.12"
# https://pypi.org/project/pynvim/
readonly PYNVIM_VERSION="0.6.0"
# https://github.com/libevent/libevent/releases
readonly LIBEVENT_VERSION="2.1.12-stable"
# Xorg desktop only. Rolling nightly, so no version is pinned; the installed
# build is tracked by the package version.
# Debian/Ubuntu: https://github.com/wezterm/wezterm/releases/tag/nightly
readonly WEZTERM_RELEASE="nightly"
# Fedora/RHEL: https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/
readonly WEZTERM_COPR="wezfurlong/wezterm-nightly"
# https://github.com/xremap/xremap/releases (Xorg desktop only)
readonly XREMAP_VERSION="0.15.15"
# https://github.com/rust-lang/rust/releases
readonly RUST_TOOLCHAIN="1.99.0"
# https://github.com/tree-sitter/tree-sitter/releases
# Release binaries need glibc 2.39; built with cargo instead.
readonly TREE_SITTER_VERSION="0.27.1"

# Git commits. Bump with: git ls-remote <url> HEAD
# https://github.com/ohmyzsh/ohmyzsh
readonly OHMYZSH_REF="964ddf789b022b6958b27d02d7fa54f552de21e9"
# https://github.com/zsh-users/zsh-autosuggestions
readonly ZSH_AUTOSUGGESTIONS_REF="85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5"
# https://github.com/zsh-users/zsh-syntax-highlighting
readonly ZSH_SYNTAX_HIGHLIGHTING_REF="e6683f20e5c38d3e5447f45845d04ddda75d0f23"
# https://github.com/zdharma-continuum/fast-syntax-highlighting
readonly FAST_SYNTAX_HIGHLIGHTING_REF="4672ad5dd9ad68a7effc1476d65afb7c584ce2b3"
# https://github.com/tmux-plugins/tpm
readonly TPM_REF="e261deb1b47614eed3400089ce7197dc68acc4eb"

# Overridable so test/bootstrap can install from a local snapshot.
readonly DOTFILES_REPO="${BOOTSTRAP_DOTFILES_REPO:-https://github.com/Leandros/dotfiles.git}"
readonly DOTFILES_REF="${BOOTSTRAP_DOTFILES_REF:-master}"

# =============================================================================
# Constants
# =============================================================================
readonly PREFIX="/usr/local"
readonly STAMP_DIR="$PREFIX/share/bootstrap"
readonly DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotbackup/$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR
readonly NVIM_VENV="$HOME/.local/share/nvim/python3-venv"
readonly GITHUB="https://github.com"
readonly USER_NAME="${USER:-$(id -un)}"

WORK_DIR=""
SUDO=""
OS=""        # linux | macos
DISTRO=""    # debian | ubuntu | fedora | rhel | amzn2 | amzn2023 | macos
DISTRO_MAJOR=""  # major version number (linux only)
ARCH=""      # x86_64 | aarch64
GLIBC=""     # e.g. 2.26 (linux only)
GO_ARCH=""   # amd64 | arm64
RUST_TARGET_LINUX_MUSL=""
RUST_TARGET_DARWIN=""
DPI_SCALE=""      # chosen Xorg display scale (xorg step only)

# =============================================================================
# Helpers
# =============================================================================
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

cleanup() {
    [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] || return 0
    # Root-owned files appear after "make install" runs in the build tree.
    rm -rf "$WORK_DIR" 2>/dev/null || $SUDO rm -rf "$WORK_DIR"
}
trap cleanup EXIT

nproc_safe() {
    if have nproc; then
        nproc
    else
        sysctl -n hw.ncpu
    fi
}

fetch() {
    local url="$1" out="$2"
    curl -fsSL --retry 3 --retry-delay 2 -o "$out" "$url"
}

# Download and unpack an archive into a fresh directory, print the directory.
fetch_unpack() {
    local url="$1" dir
    dir="$(mktemp -d "$WORK_DIR/unpack.XXXXXX")"
    case "$url" in
        *.zip)
            fetch "$url" "$dir/archive.zip"
            unzip -q "$dir/archive.zip" -d "$dir"
            rm -f "$dir/archive.zip"
            ;;
        *.tar.xz|*.txz)
            fetch "$url" "$dir/archive.tar.xz"
            tar -xJf "$dir/archive.tar.xz" -C "$dir"
            rm -f "$dir/archive.tar.xz"
            ;;
        *)
            fetch "$url" "$dir/archive.tar.gz"
            tar -xzf "$dir/archive.tar.gz" -C "$dir"
            rm -f "$dir/archive.tar.gz"
            ;;
    esac
    echo "$dir"
}

# Find the single top-level directory of an unpacked archive.
unpacked_root() {
    local dir="$1"
    find "$dir" -mindepth 1 -maxdepth 1 -type d | head -n 1
}

# Run a noisy build command; show output only on failure.
quiet() {
    local log="$WORK_DIR/build.log"
    if ! "$@" >"$log" 2>&1; then
        tail -n 40 "$log" >&2
        die "command failed: $*"
    fi
}

install_bin() {
    local src="$1" name="$2"
    $SUDO install -m 0755 "$src" "$PREFIX/bin/$name"
}

# Locate an executable by name inside an unpacked tree and install it.
install_bin_from() {
    local dir="$1" name="$2" src
    src="$(find "$dir" -type f -name "$name" | head -n 1)"
    [[ -n "$src" ]] || die "$name not found in archive"
    install_bin "$src" "$name"
}

stamp_path() { echo "$STAMP_DIR/$1"; }

is_current() {
    local name="$1" version="$2" bin="$3" stamp
    stamp="$(stamp_path "$name")"
    [[ -x "$bin" ]] || return 1
    [[ -f "$stamp" ]] || return 1
    [[ "$(cat "$stamp")" == "$version" ]]
}

mark_current() {
    local name="$1" version="$2"
    $SUDO mkdir -p "$STAMP_DIR"
    echo "$version" | $SUDO tee "$(stamp_path "$name")" >/dev/null
}

# Symlink src to dst. Existing non-symlink targets go to BACKUP_DIR.
link() {
    local src="$1" dst="$2"
    [[ -e "$src" ]] || die "link source missing: $src"
    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        ln -sfn "$src" "$dst"
        return
    fi

    if [[ -e "$dst" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
        log "backed up $dst"
    fi

    ln -s "$src" "$dst"
}

# Check out a repository at a fixed commit. Fetches only that commit.
git_pin() {
    local url="$1" dir="$2" ref="$3"

    if [[ ! -d "$dir/.git" ]]; then
        mkdir -p "$dir"
        git -C "$dir" init -q
    fi
    if ! git -C "$dir" remote get-url origin >/dev/null 2>&1; then
        git -C "$dir" remote add origin "$url"
    fi

    if [[ "$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)" == "$ref" ]]; then
        return
    fi

    git -C "$dir" fetch -q --depth 1 origin "$ref"
    git -C "$dir" checkout -q --detach FETCH_HEAD
}

run_root_env() {
    # -H: keep root from writing caches into the caller's HOME.
    # sudo resets PATH; pass it explicitly.
    local sudo_h=()
    [[ -n "$SUDO" ]] && sudo_h=("$SUDO" -H)
    "${sudo_h[@]+"${sudo_h[@]}"}" env PATH="$PREFIX/bin:$PATH" "$@"
}

skip_step() {
    local name="$1"
    [[ " ${BOOTSTRAP_SKIP:-} " == *" $name "* ]]
}

step() {
    local name="$1"
    shift
    if skip_step "$name"; then
        log "skip $name"
        return
    fi
    log "$name"
    "$@"
}

version_ge() {
    # Returns 0 when $1 >= $2 (dotted numeric versions).
    [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" == "$2" ]]
}

# =============================================================================
# Detection
# =============================================================================
detect_platform() {
    case "$(uname -s)" in
        Linux)  OS="linux" ;;
        Darwin) OS="macos" ;;
        *)      die "unsupported OS: $(uname -s)" ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)  ARCH="x86_64"; GO_ARCH="amd64" ;;
        aarch64|arm64) ARCH="aarch64"; GO_ARCH="arm64" ;;
        *)             die "unsupported arch: $(uname -m)" ;;
    esac

    RUST_TARGET_LINUX_MUSL="$ARCH-unknown-linux-musl"
    RUST_TARGET_DARWIN="$ARCH-apple-darwin"

    if [[ "$OS" == "macos" ]]; then
        DISTRO="macos"
        [[ "$ARCH" == "aarch64" ]] || die "macOS: only Apple Silicon is supported"
        return
    fi

    [[ -r /etc/os-release ]] || die "/etc/os-release missing"
    local id id_like version_id
    # shellcheck disable=SC1091
    id="$(. /etc/os-release && echo "$ID")"
    # shellcheck disable=SC1091
    id_like="$(. /etc/os-release && echo "${ID_LIKE:-}")"
    # shellcheck disable=SC1091
    version_id="$(. /etc/os-release && echo "${VERSION_ID:-}")"
    DISTRO_MAJOR="${version_id%%.*}"
    case "$id" in
        debian) DISTRO="debian" ;;
        ubuntu) DISTRO="ubuntu" ;;
        fedora) DISTRO="fedora" ;;
        rhel|centos|rocky|almalinux) DISTRO="rhel" ;;
        amzn)
            case "$version_id" in
                2)    DISTRO="amzn2" ;;
                2023) DISTRO="amzn2023" ;;
                *)    die "unsupported Amazon Linux: $version_id" ;;
            esac
            ;;
        *)
            # Other RHEL rebuilds (Oracle, Alibaba) declare their lineage here.
            if [[ " $id_like " == *" rhel "* ]]; then
                DISTRO="rhel"
            else
                die "unsupported distro: $id"
            fi
            ;;
    esac

    GLIBC="$(getconf GNU_LIBC_VERSION | awk '{print $2}')"
}

detect_sudo() {
    if [[ "$(id -u)" -eq 0 ]]; then
        SUDO=""
        return
    fi
    have sudo || die "sudo required"
    SUDO="sudo"
}

# =============================================================================
# System packages
# =============================================================================
install_system_packages() {
    case "$DISTRO" in
        debian|ubuntu)
            # sudo resets the environment, so DEBIAN_FRONTEND must be passed
            # through it. confold keeps existing config files (sshd_config)
            # instead of prompting.
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get update -qq
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
                -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
                build-essential autoconf automake pkg-config cmake bison \
                git rsync openssh-client tree wget curl ca-certificates \
                file unzip xz-utils patch gettext locales \
                libevent-dev libncurses-dev libreadline-dev
            ensure_locale
            ;;
        amzn2)
            $SUDO yum install -y -q \
                gcc gcc-c++ make binutils autoconf automake pkgconfig cmake3 bison \
                git rsync openssh-clients tree wget curl \
                file unzip xz tar gzip patch gettext gettext-devel which \
                ncurses-devel readline-devel
            ;;
        amzn2023|fedora|rhel)
            # curl-minimal is preinstalled and conflicts with curl.
            $SUDO dnf install -y -q \
                gcc gcc-c++ make binutils autoconf automake pkgconf-pkg-config cmake bison \
                git rsync openssh-clients tree wget \
                file unzip xz tar gzip patch gettext gettext-devel which \
                glibc-langpack-en libevent-devel ncurses-devel readline-devel
            ;;
        macos)
            have brew || die "Homebrew required: https://brew.sh"
            xcode-select -p >/dev/null 2>&1 || die "run: xcode-select --install"
            brew install -q \
                autoconf automake pkg-config cmake \
                git rsync tree wget curl gettext \
                libevent ncurses readline utf8proc
            ;;
    esac
}

ensure_locale() {
    if locale -a 2>/dev/null | grep -qi 'en_US.utf8'; then
        return
    fi
    $SUDO localedef -i en_US -f UTF-8 en_US.UTF-8
}

# =============================================================================
# Home directory
# =============================================================================
# A previous "sudo <tool>" can leave root-owned dirs in HOME.
fix_home_ownership() {
    local dir
    for dir in "$HOME/.local" "$HOME/.config" "$HOME/.cache"; do
        mkdir -p "$dir" 2>/dev/null || true
        [[ -d "$dir" ]] || continue
        if [[ -n "$(find "$dir" -maxdepth 1 ! -user "$USER_NAME" -print -quit)" ]]; then
            log "chown $dir"
            $SUDO chown -R "$USER_NAME" "$dir"
        fi
    done
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.config"
}

# =============================================================================
# Dotfiles
# =============================================================================
# Discard local edits to lazy-lock.json, keeping a copy in BACKUP_DIR.
reset_lazy_lock() {
    local lock="$DOTFILES_DIR/lazy-lock.json"
    git -C "$DOTFILES_DIR" diff --quiet HEAD -- lazy-lock.json && return
    mkdir -p "$BACKUP_DIR"
    cp "$lock" "$BACKUP_DIR/lazy-lock.json"
    git -C "$DOTFILES_DIR" checkout -q HEAD -- lazy-lock.json
    log "reset lazy-lock.json (local copy in $BACKUP_DIR)"
}

clone_dotfiles() {
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        git clone -q --branch "$DOTFILES_REF" "$DOTFILES_REPO" "$DOTFILES_DIR"
        return
    fi

    # nvim rewrites lazy-lock.json on its own (e.g. lazy.nvim bumping
    # hererocks). The repo copy is authoritative, so reset it instead of
    # letting it block the update.
    reset_lazy_lock

    # The clone must match the script that links its files, so local edits
    # are stashed around the update rather than blocking it.
    local changes stashed=0
    changes="$(git -C "$DOTFILES_DIR" status --porcelain)"
    if [[ -n "$changes" ]]; then
        log "dotfiles has local changes, stashing for the update:"
        printf '%s\n' "$changes" >&2
        git -C "$DOTFILES_DIR" stash push -q -u -m "bootstrap $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        stashed=1
    fi

    git -C "$DOTFILES_DIR" fetch -q origin "$DOTFILES_REF"
    git -C "$DOTFILES_DIR" checkout -q "$DOTFILES_REF"
    git -C "$DOTFILES_DIR" merge -q --ff-only "origin/$DOTFILES_REF" \
        || die "dotfiles: $DOTFILES_DIR has commits not on origin/$DOTFILES_REF; rebase or push them first"

    (( stashed )) || return 0
    if git -C "$DOTFILES_DIR" stash pop -q; then
        log "dotfiles: local changes restored"
        return
    fi
    # A failed pop keeps the stash; drop the half-applied merge so the links
    # point at a consistent tree.
    git -C "$DOTFILES_DIR" reset -q --hard
    git -C "$DOTFILES_DIR" clean -fdq
    warn "dotfiles: local changes conflict with the update; kept in 'git -C $DOTFILES_DIR stash list'"
}

# =============================================================================
# Compiled tools
# =============================================================================
install_zsh() {
    if [[ "$OS" == "macos" ]]; then
        # macOS ships zsh 5.9.
        return
    fi
    is_current zsh "$ZSH_VERSION_PIN" "$PREFIX/bin/zsh" && return

    local dir
    dir="$(fetch_unpack "https://www.zsh.org/pub/zsh-$ZSH_VERSION_PIN.tar.xz")"
    (
        cd "$(unpacked_root "$dir")"
        # --with-tcsetpgrp: configure cannot test it without a tty.
        quiet ./configure --prefix="$PREFIX" --with-tcsetpgrp --enable-multibyte
        quiet make -j "$(nproc_safe)"
        quiet $SUDO make install
    )
    mark_current zsh "$ZSH_VERSION_PIN"
}

# AL2 ships libevent 2.0, which tmux 3.5 does not accept.
install_libevent_al2() {
    is_current libevent "$LIBEVENT_VERSION" "$PREFIX/lib/libevent.a" && return

    local dir
    dir="$(fetch_unpack "$GITHUB/libevent/libevent/releases/download/release-$LIBEVENT_VERSION/libevent-$LIBEVENT_VERSION.tar.gz")"
    (
        cd "$(unpacked_root "$dir")"
        quiet ./configure --prefix="$PREFIX" --disable-openssl --disable-shared --with-pic
        quiet make -j "$(nproc_safe)"
        quiet $SUDO make install
    )
    mark_current libevent "$LIBEVENT_VERSION"
}

tmux_version() {
    if [[ "$OS" == "macos" ]]; then
        echo "$TMUX_VERSION_MACOS"
    else
        echo "$TMUX_VERSION_LINUX"
    fi
}

install_tmux() {
    local version
    version="$(tmux_version)"
    is_current tmux "$version" "$PREFIX/bin/tmux" && return

    local configure_flags=() pkg_config_path="${PKG_CONFIG_PATH:-}"
    if [[ "$DISTRO" == "amzn2" ]]; then
        install_libevent_al2
        pkg_config_path="$PREFIX/lib/pkgconfig:$pkg_config_path"
    fi
    if [[ "$OS" == "macos" ]]; then
        pkg_config_path="$(brew --prefix libevent)/lib/pkgconfig:$(brew --prefix ncurses)/lib/pkgconfig:$(brew --prefix utf8proc)/lib/pkgconfig:$pkg_config_path"
        configure_flags+=(--enable-utf8proc)
    fi

    local dir
    dir="$(fetch_unpack "$GITHUB/tmux/tmux/releases/download/$version/tmux-$version.tar.gz")"
    (
        cd "$(unpacked_root "$dir")"
        export PKG_CONFIG_PATH="$pkg_config_path"
        quiet ./configure --prefix="$PREFIX" "${configure_flags[@]+"${configure_flags[@]}"}"
        quiet make -j "$(nproc_safe)"
        quiet $SUDO make install
    )
    mark_current tmux "$version"
}

install_nnn() {
    [[ "$OS" == "linux" ]] || return 0
    is_current nnn "$NNN_VERSION" "$PREFIX/bin/nnn" && return

    local dir
    dir="$(fetch_unpack "$GITHUB/jarun/nnn/archive/refs/tags/v$NNN_VERSION.tar.gz")"
    (
        cd "$(unpacked_root "$dir")"
        patch -p1 -s < "$DOTFILES_DIR/nnn/nnn-keybindings.patch"
        quiet make -j "$(nproc_safe)" O_NERD=1 PREFIX="$PREFIX"
        quiet $SUDO make install O_NERD=1 PREFIX="$PREFIX"
    )
    mark_current nnn "$NNN_VERSION"
}

# =============================================================================
# Neovim
# =============================================================================
readonly NVIM_HOME="$PREFIX/lib/nvim"
# Release tarballs for 0.11+ need glibc 2.34.
readonly NVIM_TARBALL_MIN_GLIBC="2.34"

install_nvim() {
    is_current nvim "$NVIM_VERSION" "$PREFIX/bin/nvim" && return

    if [[ "$OS" == "linux" ]] && ! version_ge "$GLIBC" "$NVIM_TARBALL_MIN_GLIBC"; then
        build_nvim
    else
        unpack_nvim
    fi

    $SUDO ln -sfn "$NVIM_HOME/bin/nvim" "$PREFIX/bin/nvim"
    mark_current nvim "$NVIM_VERSION"
}

unpack_nvim() {
    local asset
    if [[ "$OS" == "macos" ]]; then
        asset="nvim-macos-arm64"
    elif [[ "$ARCH" == "x86_64" ]]; then
        asset="nvim-linux-x86_64"
    else
        asset="nvim-linux-arm64"
    fi

    local dir
    dir="$(fetch_unpack "$GITHUB/neovim/neovim/releases/download/v$NVIM_VERSION/$asset.tar.gz")"
    $SUDO rm -rf "$NVIM_HOME"
    $SUDO mkdir -p "$PREFIX/lib"
    $SUDO mv "$dir/$asset" "$NVIM_HOME"
}

build_nvim() {
    local dir
    dir="$(fetch_unpack "$GITHUB/neovim/neovim/archive/refs/tags/v$NVIM_VERSION.tar.gz")"
    (
        cd "$(unpacked_root "$dir")"
        quiet make -j "$(nproc_safe)" CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$NVIM_HOME"
        $SUDO rm -rf "$NVIM_HOME"
        quiet $SUDO make install
    )
}

# =============================================================================
# Binary releases
# =============================================================================
install_fzf() {
    is_current fzf "$FZF_VERSION" "$PREFIX/bin/fzf" && return
    local os="linux"
    [[ "$OS" == "macos" ]] && os="darwin"
    local dir
    dir="$(fetch_unpack "$GITHUB/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-${os}_$GO_ARCH.tar.gz")"
    install_bin_from "$dir" fzf
    mark_current fzf "$FZF_VERSION"
}

install_zoxide() {
    is_current zoxide "$ZOXIDE_VERSION" "$PREFIX/bin/zoxide" && return
    local target="$RUST_TARGET_LINUX_MUSL"
    [[ "$OS" == "macos" ]] && target="$RUST_TARGET_DARWIN"
    local dir
    dir="$(fetch_unpack "$GITHUB/ajeetdsouza/zoxide/releases/download/v$ZOXIDE_VERSION/zoxide-$ZOXIDE_VERSION-$target.tar.gz")"
    install_bin_from "$dir" zoxide
    mark_current zoxide "$ZOXIDE_VERSION"
}

install_yazi() {
    is_current yazi "$YAZI_VERSION" "$PREFIX/bin/yazi" && return
    local target="$RUST_TARGET_LINUX_MUSL"
    [[ "$OS" == "macos" ]] && target="$RUST_TARGET_DARWIN"
    local dir
    dir="$(fetch_unpack "$GITHUB/sxyazi/yazi/releases/download/v$YAZI_VERSION/yazi-$target.zip")"
    install_bin_from "$dir" yazi
    install_bin_from "$dir" ya
    mark_current yazi "$YAZI_VERSION"
}

install_lazygit() {
    is_current lazygit "$LAZYGIT_VERSION" "$PREFIX/bin/lazygit" && return
    local asset
    if [[ "$OS" == "macos" ]]; then
        asset="darwin_arm64"
    else
        asset="linux_$ARCH"
        [[ "$ARCH" == "aarch64" ]] && asset="linux_arm64"
    fi
    local dir
    dir="$(fetch_unpack "$GITHUB/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION/lazygit_${LAZYGIT_VERSION}_$asset.tar.gz")"
    install_bin_from "$dir" lazygit
    mark_current lazygit "$LAZYGIT_VERSION"
}

install_uv() {
    is_current uv "$UV_VERSION" "$PREFIX/bin/uv" && return
    local target="$RUST_TARGET_LINUX_MUSL"
    [[ "$OS" == "macos" ]] && target="$RUST_TARGET_DARWIN"
    local dir
    dir="$(fetch_unpack "$GITHUB/astral-sh/uv/releases/download/$UV_VERSION/uv-$target.tar.gz")"
    install_bin_from "$dir" uv
    install_bin_from "$dir" uvx
    mark_current uv "$UV_VERSION"
}

install_fd() {
    is_current fd "$FD_VERSION" "$PREFIX/bin/fd" && return
    local target="$RUST_TARGET_LINUX_MUSL"
    [[ "$OS" == "macos" ]] && target="$RUST_TARGET_DARWIN"
    local dir
    dir="$(fetch_unpack "$GITHUB/sharkdp/fd/releases/download/v$FD_VERSION/fd-v$FD_VERSION-$target.tar.gz")"
    install_bin_from "$dir" fd
    mark_current fd "$FD_VERSION"
}

install_ripgrep() {
    is_current ripgrep "$RIPGREP_VERSION" "$PREFIX/bin/rg" && return
    local target="$RUST_TARGET_LINUX_MUSL"
    [[ "$OS" == "macos" ]] && target="$RUST_TARGET_DARWIN"
    local dir
    dir="$(fetch_unpack "$GITHUB/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/ripgrep-$RIPGREP_VERSION-$target.tar.gz")"
    install_bin_from "$dir" rg
    mark_current ripgrep "$RIPGREP_VERSION"
}

install_bat() {
    is_current bat "$BAT_VERSION" "$PREFIX/bin/bat" && return
    local target="$RUST_TARGET_LINUX_MUSL"
    [[ "$OS" == "macos" ]] && target="$RUST_TARGET_DARWIN"
    local dir
    dir="$(fetch_unpack "$GITHUB/sharkdp/bat/releases/download/v$BAT_VERSION/bat-v$BAT_VERSION-$target.tar.gz")"
    install_bin_from "$dir" bat
    mark_current bat "$BAT_VERSION"
}

install_mise() {
    if ! is_current mise "$MISE_VERSION" "$PREFIX/bin/mise"; then
        local asset
        if [[ "$OS" == "macos" ]]; then
            asset="macos-arm64"
        elif [[ "$ARCH" == "x86_64" ]]; then
            asset="linux-x64-musl"
        else
            asset="linux-arm64-musl"
        fi
        fetch "$GITHUB/jdx/mise/releases/download/v$MISE_VERSION/mise-v$MISE_VERSION-$asset" "$WORK_DIR/mise"
        install_bin "$WORK_DIR/mise" mise
        mark_current mise "$MISE_VERSION"
    fi

    # .zshrc activates mise only from this path.
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$PREFIX/bin/mise" "$HOME/.local/bin/mise"
}

install_direnv() {
    is_current direnv "$DIRENV_VERSION" "$PREFIX/bin/direnv" && return
    local os="linux"
    [[ "$OS" == "macos" ]] && os="darwin"
    fetch "$GITHUB/direnv/direnv/releases/download/v$DIRENV_VERSION/direnv.$os-$GO_ARCH" "$WORK_DIR/direnv"
    install_bin "$WORK_DIR/direnv" direnv
    mark_current direnv "$DIRENV_VERSION"
}

# =============================================================================
# Rust
# =============================================================================
readonly CARGO_HOME_DIR="${CARGO_HOME:-$HOME/.cargo}"
readonly RUSTUP_HOME_DIR="${RUSTUP_HOME:-$HOME/.rustup}"

install_rust() {
    export CARGO_HOME="$CARGO_HOME_DIR" RUSTUP_HOME="$RUSTUP_HOME_DIR"
    local rustup="$CARGO_HOME_DIR/bin/rustup"

    if [[ ! -x "$rustup" ]]; then
        fetch https://sh.rustup.rs "$WORK_DIR/rustup-init.sh"
        quiet sh "$WORK_DIR/rustup-init.sh" -y -q --no-modify-path \
            --profile minimal --default-toolchain "$RUST_TOOLCHAIN"
        return
    fi

    if ! "$rustup" run "$RUST_TOOLCHAIN" rustc --version >/dev/null 2>&1; then
        quiet "$rustup" toolchain install --profile minimal "$RUST_TOOLCHAIN"
    fi
    if ! "$rustup" default >/dev/null 2>&1; then
        quiet "$rustup" default "$RUST_TOOLCHAIN"
    fi
}

# nvim-treesitter (main) needs the CLI to build parsers.
install_tree_sitter() {
    is_current tree-sitter "$TREE_SITTER_VERSION" "$PREFIX/bin/tree-sitter" && return

    export CARGO_HOME="$CARGO_HOME_DIR" RUSTUP_HOME="$RUSTUP_HOME_DIR"
    quiet "$CARGO_HOME_DIR/bin/cargo" "+$RUST_TOOLCHAIN" install -q --locked \
        --root "$WORK_DIR/tree-sitter" "tree-sitter-cli@$TREE_SITTER_VERSION"
    install_bin "$WORK_DIR/tree-sitter/bin/tree-sitter" tree-sitter
    mark_current tree-sitter "$TREE_SITTER_VERSION"
}

# =============================================================================
# Node
# =============================================================================
readonly NODE_HOME="$PREFIX/lib/nodejs"

node_version() {
    if [[ "$DISTRO" == "amzn2" && "$ARCH" == "aarch64" ]]; then
        echo "$NODE_VERSION_AL2_AARCH64"
    else
        echo "$NODE_VERSION"
    fi
}

node_url() {
    local version="$1"
    if [[ "$OS" == "macos" ]]; then
        echo "https://nodejs.org/dist/v$version/node-v$version-darwin-arm64.tar.xz"
    elif [[ "$DISTRO" == "amzn2" && "$ARCH" == "x86_64" ]]; then
        # Official node 20 needs glibc 2.28; this build targets 2.17.
        echo "https://unofficial-builds.nodejs.org/download/release/v$version/node-v$version-linux-x64-glibc-217.tar.xz"
    elif [[ "$ARCH" == "x86_64" ]]; then
        echo "https://nodejs.org/dist/v$version/node-v$version-linux-x64.tar.xz"
    else
        echo "https://nodejs.org/dist/v$version/node-v$version-linux-arm64.tar.xz"
    fi
}

install_node() {
    local version
    version="$(node_version)"
    if ! is_current node "$version" "$PREFIX/bin/node"; then
        local dir
        dir="$(fetch_unpack "$(node_url "$version")")"
        $SUDO rm -rf "$NODE_HOME"
        $SUDO mkdir -p "$PREFIX/lib"
        $SUDO mv "$(unpacked_root "$dir")" "$NODE_HOME"
        local bin
        for bin in node npm npx corepack; do
            $SUDO ln -sfn "$NODE_HOME/bin/$bin" "$PREFIX/bin/$bin"
        done
        mark_current node "$version"
    fi

    is_current node-neovim "$NODE_NEOVIM_VERSION" "$PREFIX/bin/neovim-node-host" && return
    quiet run_root_env npm_config_update_notifier=false \
        "$PREFIX/bin/npm" install -g --quiet --no-fund --no-audit \
        --prefix "$PREFIX" "neovim@$NODE_NEOVIM_VERSION"
    mark_current node-neovim "$NODE_NEOVIM_VERSION"
}

# =============================================================================
# CodeLLDB
# =============================================================================
# Debug adapter for rustaceanvim/vimspector. The nvim config expects the
# unpacked vsix "extension" directory at this per-user path, inside the
# vimspector plugin checkout (vimspector's own gadget directory).
codelldb_dir() {
    local os="linux"
    [[ "$OS" == "macos" ]] && os="macos"
    echo "$HOME/.local/share/nvim/lazy/vimspector/gadgets/$os/CodeLLDB"
}

install_codelldb() {
    local dir version_file
    dir="$(codelldb_dir)"
    version_file="$dir/.bootstrap-version"
    if [[ -x "$dir/adapter/codelldb" && -f "$version_file" \
        && "$(cat "$version_file")" == "$CODELLDB_VERSION" ]]; then
        return
    fi

    local asset
    if [[ "$OS" == "macos" ]]; then
        asset="darwin-arm64"
    elif [[ "$ARCH" == "x86_64" ]]; then
        asset="linux-x64"
    else
        asset="linux-arm64"
    fi

    local vsix="$WORK_DIR/codelldb.vsix" unpack="$WORK_DIR/codelldb"
    fetch "$GITHUB/vadimcn/codelldb/releases/download/v$CODELLDB_VERSION/codelldb-$asset.vsix" "$vsix"
    mkdir -p "$unpack"
    unzip -q "$vsix" -d "$unpack"

    rm -rf "$dir"
    mkdir -p "$(dirname "$dir")"
    mv "$unpack/extension" "$dir"
    echo "$CODELLDB_VERSION" > "$version_file"
}

# =============================================================================
# Python
# =============================================================================
readonly UV_SYSTEM_PYTHON_DIR="$PREFIX/share/uv/python"

install_python() {
    # Installs python3.X into PREFIX/bin for all users. System python untouched.
    run_root_env \
        UV_PYTHON_INSTALL_DIR="$UV_SYSTEM_PYTHON_DIR" \
        UV_PYTHON_BIN_DIR="$PREFIX/bin" \
        "$PREFIX/bin/uv" python install -q --no-cache "$PYTHON_VERSION"
}

setup_nvim_python() {
    local python="$PREFIX/bin/python$PYTHON_VERSION"
    [[ -x "$python" ]] || die "missing $python"
    uv venv -q --allow-existing --python "$python" "$NVIM_VENV"
    uv pip install -q --python "$NVIM_VENV/bin/python" "pynvim==$PYNVIM_VERSION"
}

# =============================================================================
# Configuration
# =============================================================================
lazygit_config_dir() {
    if [[ "$OS" == "macos" ]]; then
        echo "$HOME/Library/Application Support/lazygit"
    else
        echo "${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
    fi
}

tmux_conf_dir() {
    if [[ "$OS" == "macos" ]]; then
        echo "$DOTFILES_DIR/tmux/tmux_macOS_$TMUX_VERSION_MACOS"
    else
        echo "$DOTFILES_DIR/tmux/tmux_linux_$TMUX_VERSION_LINUX"
    fi
}

link_dotfiles() {
    local d="$DOTFILES_DIR"

    link "$d/.zsh" "$HOME/.zsh"
    link "$d/.gitconfig" "$HOME/.gitconfig"
    link "$d/.gitignore_global" "$HOME/.gitignore_global"
    link "$d/.committemplate.txt" "$HOME/.committemplate.txt"

    # Only init.lua and the lockfile; the repo's .config/nvim holds legacy vim files.
    link "$d/.vim.init.lua" "$HOME/.config/nvim/init.lua"
    link "$d/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
    link "$d/.vsnip" "$HOME/.vsnip"

    link "$(tmux_conf_dir)/.tmux.conf" "$HOME/.tmux.conf"
    link "$d/.tmux/custom" "$HOME/.tmux/custom"

    link "$d/.config/yazi" "$HOME/.config/yazi"
    link "$d/AppData/Roaming/lazygit/config.yml" "$(lazygit_config_dir)/config.yml"
}

# =============================================================================
# Xorg / i3 desktop (opt-in)
# =============================================================================
# Fedora has everything. RHEL 9 gets i3 and friends from EPEL (xbindkeys is
# missing there); RHEL 10 ships no Xorg server or i3 at all.
readonly XORG_DISTROS=" debian ubuntu fedora rhel "
readonly RHEL_XORG_MAX_MAJOR=9

xorg_requested() {
    [[ "${BOOTSTRAP_XORG:-0}" == "1" ]]
}

xorg_supported() {
    [[ "$XORG_DISTROS" == *" $DISTRO "* ]] || return 1
    if [[ "$DISTRO" == "rhel" && "$DISTRO_MAJOR" -gt "$RHEL_XORG_MAX_MAJOR" ]]; then
        return 1
    fi
}

# Tools referenced by .xprofile, .xbindkeysrc and the i3 config. Versions
# matter little here, so the distro repositories are fine.
install_xorg_packages() {
    case "$DISTRO" in
        debian|ubuntu)
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
                -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
                xorg xinit x11-xserver-utils xbindkeys \
                i3 i3status suckless-tools \
                alsa-utils brightnessctl \
                kbd console-data
            ;;
        fedora)
            $SUDO dnf install -y -q \
                xorg-x11-server-Xorg xorg-x11-xinit xset xsetroot setxkbmap xmodmap xbindkeys \
                i3 i3status dmenu \
                alsa-utils brightnessctl kbd
            ;;
        rhel)
            $SUDO dnf install -y -q epel-release
            $SUDO dnf config-manager --set-enabled crb
            # xbindkeys is not packaged for EL9; .xprofile tolerates its absence.
            $SUDO dnf install -y -q \
                xorg-x11-server-Xorg xorg-x11-xinit xset xsetroot setxkbmap xmodmap \
                i3 i3status dmenu \
                alsa-utils brightnessctl kbd
            ;;
    esac
}

# One nightly .deb serves Debian 12 and Ubuntu 22.04 and newer releases of
# the same family, since glibc only grows.
wezterm_deb_asset() {
    local arch_suffix=""
    [[ "$ARCH" == "aarch64" ]] && arch_suffix=".arm64"
    case "$DISTRO" in
        debian) echo "wezterm-$WEZTERM_RELEASE.Debian12$arch_suffix.deb" ;;
        ubuntu) echo "wezterm-$WEZTERM_RELEASE.Ubuntu22.04$arch_suffix.deb" ;;
        *)      die "wezterm: no .deb for $DISTRO" ;;
    esac
}

install_wezterm_deb() {
    local asset pkg version
    asset="$(wezterm_deb_asset)"
    pkg="$WORK_DIR/$asset"
    fetch "$GITHUB/wezterm/wezterm/releases/download/$WEZTERM_RELEASE/$asset" "$pkg"
    version="$(dpkg-deb -f "$pkg" Version)"
    is_current wezterm "$version" "/usr/bin/wezterm" && return

    # apt resolves the file's dependencies; dpkg -i would not.
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
        -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold --allow-downgrades "$pkg"
    mark_current wezterm "$version"
}

# Fedora resolves its copr chroot itself. RHEL clones report their own name
# (rocky, almalinux) and must be told the rhel-<major> chroot explicitly.
install_wezterm_copr() {
    local chroot=()
    [[ "$DISTRO" == "rhel" ]] && chroot=("rhel-$DISTRO_MAJOR-$ARCH")

    $SUDO dnf install -y -q dnf-plugins-core
    quiet $SUDO dnf copr enable -y "$WEZTERM_COPR" "${chroot[@]+"${chroot[@]}"}"
    # The copr tracks upstream; dnf upgrades in place when a newer build exists.
    quiet $SUDO dnf install -y -q --allowerasing wezterm
    quiet $SUDO dnf upgrade -y -q --allowerasing wezterm

    # The copr build reports the rpm version verbatim (underscores).
    mark_current wezterm "$(rpm -q --qf '%{VERSION}' wezterm)"
}

# Key remapper below the keymap; the config swaps left Alt and Ctrl. Runs as
# the user from ~/.xprofile, which needs read access to the event devices
# and write access to uinput.
readonly XREMAP_UDEV_RULE="/etc/udev/rules.d/99-xremap-uinput.rules"
readonly XREMAP_INPUT_GROUP="input"

install_xremap() {
    if ! is_current xremap "$XREMAP_VERSION" "$PREFIX/bin/xremap"; then
        local dir
        dir="$(fetch_unpack "$GITHUB/xremap/xremap/releases/download/v$XREMAP_VERSION/xremap-linux-$ARCH-x11.zip")"
        install_bin_from "$dir" xremap
        mark_current xremap "$XREMAP_VERSION"
    fi

    local rule='KERNEL=="uinput", GROUP="input", TAG+="uaccess", MODE:="0660", OPTIONS+="static_node=uinput"'
    if [[ "$(cat "$XREMAP_UDEV_RULE" 2>/dev/null)" != "$rule" ]]; then
        $SUDO install -d /etc/udev/rules.d /etc/modules-load.d
        echo "$rule" | $SUDO tee "$XREMAP_UDEV_RULE" >/dev/null
        echo uinput | $SUDO tee /etc/modules-load.d/uinput.conf >/dev/null
        # Best effort without a reboot; udev may be absent in containers.
        $SUDO modprobe uinput 2>/dev/null || true
        $SUDO udevadm control --reload-rules 2>/dev/null || true
        $SUDO udevadm trigger 2>/dev/null || true
    fi
    if ! id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx "$XREMAP_INPUT_GROUP"; then
        $SUDO usermod -aG "$XREMAP_INPUT_GROUP" "$USER_NAME"
        log "added $USER_NAME to group $XREMAP_INPUT_GROUP; log in again for it to apply"
    fi
}

# Console font matching the display scale, applied at boot. The Terminus
# console fonts come in the four sizes the scales need.
readonly CONSOLE_FONT_BASE_PX=16
readonly KMSCON_CONF="/etc/kmscon/kmscon.conf"
readonly KMSCON_CONF_MARKER="# Written by bootstrap.sh; edit the dotfiles instead."

# Set KEY=value in a shell-style config file, replacing or appending.
set_config_var() {
    local file="$1" key="$2" value="$3"
    if $SUDO grep -q "^$key=" "$file" 2>/dev/null; then
        $SUDO sed -i "s|^$key=.*|$key=$value|" "$file"
    else
        echo "$key=$value" | $SUDO tee -a "$file" >/dev/null
    fi
}

configure_console_font() {
    local scale="$1" px
    px="$(awk "BEGIN { print int($CONSOLE_FONT_BASE_PX * $scale) }")"

    case "$DISTRO" in
        debian|ubuntu)
            # console-setup.service renders this on boot; Terminus is bundled.
            set_config_var /etc/default/console-setup FONTFACE '"Terminus"'
            set_config_var /etc/default/console-setup FONTSIZE "\"$((px / 2))x$px\""
            ;;
        fedora|rhel)
            # systemd-vconsole-setup applies FONT on boot; ter-1NNn is Terminus
            # normal weight at NN pixels.
            set_config_var /etc/vconsole.conf FONT "ter-1${px}n"
            ;;
    esac
    log "console font: Terminus ${px}px (${scale}x)"

    # kmscon (Fedora 45+) renders with freetype and takes a pixel size. Only a
    # file written by this script is replaced.
    [[ -d "$(dirname "$KMSCON_CONF")" ]] || return 0
    if [[ -f "$KMSCON_CONF" ]] && ! head -n 1 "$KMSCON_CONF" | grep -qxF "$KMSCON_CONF_MARKER"; then
        warn "kmscon: $KMSCON_CONF exists and is not managed; set font-size=$px yourself"
        return
    fi
    printf '%s\nfont-size=%s\n' "$KMSCON_CONF_MARKER" "$px" | $SUDO tee "$KMSCON_CONF" >/dev/null
    log "kmscon font-size=$px"
}

# Server-side input defaults; they also cover devices added after login.
readonly XORG_CONF_DIR="/etc/X11/xorg.conf.d"

install_xorg_conf() {
    local src dst
    for src in "$DOTFILES_DIR"/xorg-conf/*.conf; do
        dst="$XORG_CONF_DIR/$(basename "$src")"
        cmp -s "$src" "$dst" 2>/dev/null && continue
        $SUDO install -D -m 0644 "$src" "$dst"
        log "installed $dst"
    done
}

install_wezterm() {
    case "$DISTRO" in
        debian|ubuntu) install_wezterm_deb ;;
        fedora|rhel)   install_wezterm_copr ;;
        *)             die "wezterm: no build for $DISTRO" ;;
    esac
}

# Xft.dpi for the chosen scale, relative to the X default of 96.
readonly BASE_DPI=96
readonly DPI_SCALES=(1 1.5 1.75 2)

choose_dpi_scale() {
    local scale="${BOOTSTRAP_DPI_SCALE:-}"
    if [[ -z "$scale" ]]; then
        local i
        echo "Display scale for the Xorg desktop:" >&2
        for i in "${!DPI_SCALES[@]}"; do
            printf '  %d) %sx (%s dpi)\n' "$((i + 1))" "${DPI_SCALES[$i]}" \
                "$(awk "BEGIN { print $BASE_DPI * ${DPI_SCALES[$i]} }")" >&2
        done
        local reply
        read -r -p "scale [1-${#DPI_SCALES[@]}]: " reply
        [[ "$reply" =~ ^[0-9]+$ && "$reply" -ge 1 && "$reply" -le "${#DPI_SCALES[@]}" ]] \
            || die "invalid scale choice: $reply"
        scale="${DPI_SCALES[$((reply - 1))]}"
    fi
    [[ " ${DPI_SCALES[*]} " == *" $scale "* ]] || die "unsupported DPI scale: $scale (one of: ${DPI_SCALES[*]})"
    echo "$scale"
}

# ~/.Xresources is rendered from the repo template; the DPI is machine specific.
write_xresources() {
    local scale="$1" dpi tmp="$WORK_DIR/Xresources"
    dpi="$(awk "BEGIN { print $BASE_DPI * $scale }")"
    sed -e "s|##XFT_DPI##|$dpi|g" "$DOTFILES_DIR/.Xresources" > "$tmp"

    if [[ -f "$HOME/.Xresources" ]] && cmp -s "$tmp" "$HOME/.Xresources"; then
        return
    fi
    if [[ -e "$HOME/.Xresources" && ! -L "$HOME/.Xresources" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$HOME/.Xresources" "$BACKUP_DIR/.Xresources"
        log "backed up $HOME/.Xresources"
    fi
    rm -f "$HOME/.Xresources"
    cp "$tmp" "$HOME/.Xresources"
    log "Xft.dpi set to $dpi (${scale}x)"
}

link_xorg_dotfiles() {
    local d="$DOTFILES_DIR"
    link "$d/.wezterm.lua" "$HOME/.wezterm.lua"
    # Layout switcher: `kb` (us, de, bone2) for X and the console; ~/bin is on
    # PATH in .zshrc. The bone2 console map is read from the clone.
    link "$d/bin/kb" "$HOME/bin/kb"
    link "$d/bin/i3status-kb" "$HOME/bin/i3status-kb"
    link "$d/.xinitrc" "$HOME/.xinitrc"
    link "$d/.xprofile" "$HOME/.xprofile"
    link "$d/.Xmodmap" "$HOME/.Xmodmap"
    link "$d/.xbindkeysrc" "$HOME/.xbindkeysrc"
    link "$d/.backlight.sh" "$HOME/.backlight.sh"
    link "$d/.config/i3" "$HOME/.config/i3"
    link "$d/.config/xremap" "$HOME/.config/xremap"
    link "$d/.config/i3status" "$HOME/.config/i3status"
}

setup_xorg() {
    if ! xorg_requested; then
        return
    fi
    if ! xorg_supported; then
        warn "xorg: no i3 packages for $DISTRO, skipping"
        return
    fi
    install_xorg_packages
    install_wezterm
    install_xremap
    install_xorg_conf
    link_xorg_dotfiles
    write_xresources "$DPI_SCALE"
    configure_console_font "$DPI_SCALE"
}

write_zshrc() {
    local tmp="$WORK_DIR/zshrc"
    sed -e "s|##NEWHOME##|$HOME|g" -e "s|##NEWUSER##|$USER_NAME|g" \
        "$DOTFILES_DIR/.zshrc" > "$tmp"

    if [[ -f "$HOME/.zshrc" ]] && cmp -s "$tmp" "$HOME/.zshrc"; then
        return
    fi
    if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
        log "backed up $HOME/.zshrc"
    fi
    rm -f "$HOME/.zshrc"
    cp "$tmp" "$HOME/.zshrc"
}

setup_ohmyzsh() {
    local zsh_dir="$HOME/.oh-my-zsh" plugins="$HOME/.oh-my-zsh/custom/plugins"
    git_pin "$GITHUB/ohmyzsh/ohmyzsh.git" "$zsh_dir" "$OHMYZSH_REF"
    git_pin "$GITHUB/zsh-users/zsh-autosuggestions.git" "$plugins/zsh-autosuggestions" "$ZSH_AUTOSUGGESTIONS_REF"
    git_pin "$GITHUB/zsh-users/zsh-syntax-highlighting.git" "$plugins/zsh-syntax-highlighting" "$ZSH_SYNTAX_HIGHLIGHTING_REF"
    git_pin "$GITHUB/zdharma-continuum/fast-syntax-highlighting.git" "$plugins/fast-syntax-highlighting" "$FAST_SYNTAX_HIGHLIGHTING_REF"

    link "$DOTFILES_DIR/.oh-my-zsh/custom/git-flow-completion.zsh" "$zsh_dir/custom/git-flow-completion.zsh"
    link "$DOTFILES_DIR/.oh-my-zsh/custom/plugins/git-machete" "$plugins/git-machete"
}

zsh_path() {
    if [[ "$OS" == "macos" ]]; then
        echo "/bin/zsh"
    else
        echo "$PREFIX/bin/zsh"
    fi
}

current_shell() {
    if [[ "$OS" == "macos" ]]; then
        dscl . -read "/Users/$USER_NAME" UserShell | awk '{print $2}'
    else
        getent passwd "$USER_NAME" | cut -d: -f7
    fi
}

set_login_shell() {
    local shell
    shell="$(zsh_path)"

    if [[ "$OS" == "linux" ]] && ! grep -qx "$shell" /etc/shells; then
        echo "$shell" | $SUDO tee -a /etc/shells >/dev/null
    fi

    [[ "$(current_shell)" == "$shell" ]] && return

    if [[ "$OS" == "linux" ]]; then
        $SUDO usermod -s "$shell" "$USER_NAME"
    else
        chsh -s "$shell"
    fi
}

setup_tmux_plugins() {
    local tpm="$HOME/.tmux/plugins/tpm"
    git_pin "$GITHUB/tmux-plugins/tpm.git" "$tpm" "$TPM_REF"
    # Installs plugins listed in .tmux.conf. Needs a tmux server; tolerate failure.
    "$tpm/bin/install_plugins" >/dev/null 2>&1 || warn "tpm: plugin install failed, run prefix+I in tmux"
}

setup_nvim_plugins() {
    # Restores plugins to lazy-lock.json. The treesitter config blocks until
    # all parsers are built when running headless.
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || warn "nvim: plugin restore failed, run :Lazy restore"
    # Restore can rewrite the lockfile; keep the repo clean so the next run
    # is not blocked by "local changes".
    reset_lazy_lock
}

# =============================================================================
# Report
# =============================================================================
print_version() {
    local name="$1"
    shift
    local out
    if out="$("$@" 2>&1 | head -n 1)"; then
        printf '  %-12s %s\n' "$name" "$out"
    else
        printf '  %-12s MISSING\n' "$name"
    fi
}

report() {
    log "installed"
    print_version zsh "$(zsh_path)" --version
    print_version tmux tmux -V
    print_version nvim nvim --version
    print_version fzf fzf --version
    print_version zoxide zoxide --version
    print_version yazi bash -c 'yazi --version | sed -n "2s/^ *//p"'
    print_version lazygit lazygit --version
    print_version uv uv --version
    print_version fd fd --version
    print_version rg rg --version
    print_version bat bat --version
    print_version mise mise --version
    print_version direnv direnv version
    print_version rustc "$CARGO_HOME_DIR/bin/rustc" --version
    print_version tree-sitter tree-sitter --version
    print_version node node --version
    print_version python "$PREFIX/bin/python$PYTHON_VERSION" --version
    if [[ "$OS" == "linux" ]]; then
        print_version nnn nnn -V
    fi
    print_version codelldb cat "$(codelldb_dir)/.bootstrap-version"
    if xorg_requested && xorg_supported; then
        print_version wezterm wezterm --version
    fi
    if [[ -d "$BACKUP_DIR" ]]; then
        log "backups in $BACKUP_DIR"
    fi
}

# =============================================================================
# Main
# =============================================================================
run_all() {
    step packages install_system_packages
    step home fix_home_ownership
    step dotfiles clone_dotfiles

    step zsh install_zsh
    step tmux install_tmux
    step nvim install_nvim
    step fzf install_fzf
    step zoxide install_zoxide
    step yazi install_yazi
    step lazygit install_lazygit
    step uv install_uv
    step fd install_fd
    step ripgrep install_ripgrep
    step bat install_bat
    step mise install_mise
    step direnv install_direnv
    step rust install_rust
    step tree-sitter install_tree_sitter
    step node install_node
    step python install_python
    step nnn install_nnn

    step link link_dotfiles
    step xorg setup_xorg
    step zshrc write_zshrc
    step ohmyzsh setup_ohmyzsh
    step shell set_login_shell
    step nvim-python setup_nvim_python
    step nvim-plugins setup_nvim_plugins
    # After nvim-plugins: lazy.nvim replaces the vimspector checkout it lives in.
    step codelldb install_codelldb
    step tmux-plugins setup_tmux_plugins

    report
}

# With "curl ... | bash" the script arrives on stdin, so every prompt (sudo
# password, dpkg dialog) would consume script text and hang. Refuse that;
# README shows the download-then-run form.
require_tty_stdin() {
    [[ -t 0 || "${BOOTSTRAP_NONINTERACTIVE:-0}" == "1" ]] && return
    die "stdin is not a terminal. Run: curl -fsSLo bootstrap.sh <url> && bash bootstrap.sh"
}

main() {
    require_tty_stdin
    detect_platform
    detect_sudo
    # Ask up front so the run does not stall on a prompt after minutes of installs.
    if xorg_requested && xorg_supported; then
        DPI_SCALE="$(choose_dpi_scale)"
    fi
    WORK_DIR="$(mktemp -d)"
    export PATH="$PREFIX/bin:$PATH"
    log "platform: $DISTRO $ARCH${GLIBC:+ glibc $GLIBC}"
    run_all
}

main "$@"
