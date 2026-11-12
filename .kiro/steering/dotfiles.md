# Dotfiles: context for changes

Read before changes to `bootstrap.sh`, its tests, or any tool config. The
`AGENTS.md` rules also apply; this file does not repeat them.

## Workflow

- The user commits. Do not commit. Commit subjects in the log are short,
  lower case, imperative ("install arandr and autorandr").
- Red/green: write or extend a test, see it fail, then change the code.
- Keep `README.md` in sync. It documents every desktop feature and every test
  command.
- Keep `CHEATSHEET.md` in sync with key bindings in the i3, tmux and nvim
  configs.
- `bootstrap.sh` is fetched from GitHub `master`. Changes reach a machine only
  after the user pushes. Tests use the local working tree.
- Bash: `set -euo pipefail`, shellcheck clean. POSIX sh files (`.xprofile`)
  need `-s sh`. Shellcheck command (no local install):
  `docker run --rm -v "$PWD:/mnt:ro" -w /mnt koalaman/shellcheck:stable <files>`
- Agent tool calls in one block run in parallel. Never put dependent calls
  in the same block. That includes several edits of one file, and a read or
  command that needs an edit: edits can overwrite each other, and a read can
  see the old file.

## Known failures that are not regressions

- `FAIL: .zshrc HOME not set to /home/arvid`: the working tree `.zshrc` has a
  local edit that replaced the `##NEWHOME##` placeholder.
- Ubuntu: `console keymap: unknown keysym 'dead_abovedot' (bone2.map)`.

## Repository layout

| Source | Target |
|---|---|
| `.vim.init.lua` | `~/.config/nvim/init.lua` (link) |
| `.vsnip` | `~/.vsnip` (link); public snippets only. Internal ones go in `~/.vsnip-internal` (0700, outside the repo; `:VsnipOpen` writes there) |
| `lazy-lock.json` | `~/.config/nvim/lazy-lock.json` (link) |
| `.config/nvim/` | legacy vim files, not used by nvim |
| `tmux/tmux_linux_<TMUX_VERSION_LINUX>/.tmux.conf`, `tmux/tmux_macOS_<ver>/` | `~/.tmux.conf`; one directory per tmux version |
| `.tmux/custom` | `~/.tmux/custom` |
| `.zshrc` | `~/.zshrc`, rendered copy (`##NEWHOME##`, `##NEWUSER##`) |
| `.Xresources` | `~/.Xresources`, rendered copy (`##XFT_DPI##`) |
| `.wezterm.lua`, `.xinitrc`, `.xprofile`, `.xsession`, `.Xmodmap`, `.config/{i3,i3status,xremap,picom,eww}`, `.config/autorandr/postswitch` (the file only: profiles are per machine), `.config/systemd/user/i3-session.target` | `$HOME`, links, Xorg only |
| `bin/{kb,i3status-kb,pwr,theme,flightmode,touchpad,charge,caffeinate,smb,input-restore,bar,pkill-display,term,xrdp-keys,syncthing-status}` | `~/bin`, links, Xorg only |
| `bin/fzf-cache` | `~/bin`, link, always |
| `.config/{sway,fuzzel,sway-easyfocus}`, `.config/systemd/user/sway-session.target`, `xkb` (as `~/.config/xkb`) | `$HOME`, links, desktop-wayland only |
| `bin/{wm-msg,sway-autostart,kanshi-save,clip-pick}` | `~/bin`, links; `wm-msg` also for desktop (the eww scripts and i3status-kb use it) |
| `wayland-session/sway-session` | `/usr/local/bin/sway-session` (root copy, 0755; the lightdm session's wrapper) |
| `wayland-session/sway-dotfiles.desktop` | `/usr/share/wayland-sessions/` (root copy, 0644; lightdm reads only `/usr/share`) |
| `~/.config/sway.d/` | real directory, never a link: `output.conf` (bootstrap), `theme.conf` (`bin/theme`), `kb.conf` (`bin/kb`) |
| `xkb/symbols/bone2` | generated from `.Xmodmap` by `xkb/xmodmap-to-xkb.py`; regenerate when `.Xmodmap` changes |
| `xorg-conf/*.conf` | `/etc/X11/xorg.conf.d/` (root copy) |
| `sshd-conf/50-color-scheme.conf` | `/etc/ssh/sshd_config.d/` (root copy, Linux, where sshd_config includes the directory; not AL2) |
| `logind-conf/50-lid-suspend.conf` | `/etc/systemd/logind.conf.d/` (root copy, applies after reboot) |
| `system-sleep/power-button-wake` | `/usr/lib/systemd/system-sleep/` (root copy) |
| `xinitrc-d/90-xprofile.sh` | `/etc/X11/xinit/xinitrc.d/` (root copy, Fedora/EL) |
| `power-mode/*` | `/usr/local/libexec`, `/etc/systemd/system`, `/etc/udev/rules.d` (root copies, Fedora/EL) |
| `lspmux.service` | `/etc/systemd/system/` (rendered root copy, runs as the user, Linux) |
| `console/bone2.map` | generated from `.Xmodmap` by `console/xmodmap-to-console.py`; regenerate when `.Xmodmap` changes |

Root-run files are root-owned copies, never links into `$HOME`.

The target desktop is a ThinkPad P14s Gen 6 with Fedora and i3.

## bootstrap.sh

Sections in order: Settings, Versions, Constants, Helpers, Detection, steps,
Report, Main.

- Settings (`IDLE_LOCK_MINUTES`, `IDLE_SUSPEND_MINUTES`) and all versions are
  `readonly` at the top. Each version has its release URL in a comment above.
  Git pins are `*_REF` commits (bump with `git ls-remote <url> HEAD`).
- `verify.sh` evals lines that match
  `readonly NAME_(VERSION|VERSION_PIN|REF|VERSION_LINUX|VERSION_MACOS|VERSION_AL2_AARCH64|TOOLCHAIN)=`.
  Name new pins with one of these suffixes.
- `run_all` lists `step <name> <function>`. `BOOTSTRAP_SKIP="name ..."` skips
  steps. Env: `BOOTSTRAP_CATEGORIES`, `BOOTSTRAP_XORG=1` (adds `desktop`;
  the prompt still runs), `BOOTSTRAP_DPI_SCALE`, `BOOTSTRAP_NONINTERACTIVE=1`,
  `BOOTSTRAP_DOTFILES_REPO`, `BOOTSTRAP_DOTFILES_REF`.
- Categories: `basic` always; `devtools` (lazygit, direnv, rust-analyzer,
  lspmux, codelldb), `desktop` (the Xorg/i3 desktop) and `desktop-wayland`
  (sway, Fedora 43+ only: `wayland_supported`) are optional; both desktops
  can be installed together. `choose_categories` in `main` sets `CATEGORIES` from `BOOTSTRAP_CATEGORIES`
  (`all`, `""`), else a menu on a terminal, else basic only. Desktop is not
  offered and is dropped with a warning where `xorg_supported` fails, and
  desktop-wayland where `wayland_supported` fails (`category_drop` removes
  whole words: `desktop` is a prefix of `desktop-wayland`). Steps
  of a category: `category_step <category> <name> <function>`; other code
  checks `category_selected`. A run with fewer categories removes nothing.
  Rust stays in basic: tree-sitter (basic) and nmrs-gui/wmfocus (desktop)
  build with cargo. Test: `test/categories/test.sh` (pulls the functions out
  with `sed`; also passes with AL2's bash 4.2).
- Menu: `menu_select` (pure bash, draws on stderr, prints the chosen
  indices; Up/Down as CSI and SS3, Space, Enter); `prompt_categories` maps
  them to names. Tests run it in a pseudo terminal with `script -qec` and
  piped keys. Tested on bash 3.2, 4.2 and 5.2 (docker `bash:<ver>`).
- bash 4.2 (AL2) fails on `"${a[@]}"` of an empty array under `set -u`; use
  `${a[@]+"${a[@]}"}`.
- Ask all prompts in `main` before the installs, so a run does not stall
  after minutes of work. Validate static settings there too
  (`check_idle_settings`).
- Idempotent: tools use `is_current`/`mark_current` stamps in
  `/usr/local/share/bootstrap`. `link` backs up real files to
  `~/.dotbackup/<timestamp>`. Root copies: `cmp -s` first, then
  `$SUDO install -D -m <mode>`, then `restorecon` if present (SELinux).
- systemd: always `systemctl enable`. Run `start`, `daemon-reload` and
  `udevadm control --reload-rules` only if `/run/systemd/system` exists
  (containers have no systemd).
- AL2's systemd 219 has no user instances (`user@.service`). Services for the
  user are system units with `User=`, rendered from `##...##` placeholders
  (`lspmux.service`).
- Distro cases: `debian|ubuntu`, `fedora`, `rhel` (EL9 clones; EPEL and CRB),
  `amzn2`, `amzn2023`, `macos`. Tools go to `/usr/local`.
- `clone_dotfiles` resets `lazy-lock.json`, stashes local edits around a
  fast-forward update, and dies on local commits.
- Xorg (`setup_xorg`) runs only with the `desktop` category on debian, ubuntu,
  fedora, rhel <= 9.
- sway (`setup_wayland`, step `wayland`, after `xorg`) runs only with
  `desktop-wayland` on Fedora >= 43. It calls the shared install functions
  too (wezterm, Sunshine, nmrs-gui, eww, logind, sleep hook, power modes,
  Bluetooth, Syncthing, idle.conf, console font), none of the X-only ones
  (xremap, xidlehook, wmfocus, rrandr, xorg-conf, xprofile hook, autorandr,
  xrdp, .Xresources, CopyQ). `main` asks the display scale and checks the
  idle settings once when either desktop is selected; for sway the scale
  becomes `output * scale` in `~/.config/sway.d/output.conf`.
- verify.sh: `check_desktop_shared` (either desktop), the Xorg block, and
  `check_wayland`; absence checks for the categories not selected.

New tool: choose its category first. Version constant with URL, install
function with stamp, `step` (basic) or `category_step` in `run_all`,
`print_version` in `report` (in the category's block), `check_version` in
`verify.sh` (dev tools in `check_devtools`, plus an absence check in
`check_no_devtools`), README.
New link or system file: install function, `check_link` or `cmp` check in
`verify.sh`, README.

### Package quirks

- sway desktop (Fedora 43+):
  - Fedora's `/usr/bin/sway` has the file capability `cap_sys_nice=ep`:
    in docker without `--cap-add SYS_NICE` it fails with "Operation not
    permitted". verify.sh validates the config (`sway -C`) with a copy of
    the binary (no capabilities), a private 0700 `XDG_RUNTIME_DIR` and
    `WLR_BACKENDS=headless WLR_RENDERER=pixman` (else it fails on the DRM
    session). `report` uses `rpm -q sway`. kanshi has no `--version`.
  - sway 1.12 has no `accel_profile custom` (only adaptive|flat;
    swaywm/sway#8488, PR #8592): the X touchpad curve is a comment in the
    sway config. Speeds set by feel on the P14s Gen 6: touchpad
    `pointer_accel 0.3`, TrackPoint and mice `pointer_accel -0.17`, both
    `scroll_factor 0.5`. The touchpad's adaptive speed is a factor `(s+1)^2.38 *
    0.95 + 0.05` (libinput 1.32): `pointer_accel 1` was 5 times the
    default, "way too fast". swaymsg reads a negative value as an option:
    `swaymsg -- input ... pointer_accel -0.2`.
  - xremap of an i3 session outlives the logout (logind keeps the user's
    processes); in sway it cancels the XKB Alt/Ctrl swap (swapped twice).
    `sway-autostart` stops it (`pkill -u $UID -x xremap`, the one plain
    pkill: xremap holds the machine's keyboards).
  - cliphist: Fedora 43 has no package; the pinned release binary
    (`CLIPHIST_VERSION`, x86_64) on every release. CopyQ 17 under sway
    stores data marked `x-kde-passwordManagerHint` (tested with a GTK
    clipboard owner); cliphist with wl-clipboard 2.3 skips it. So no CopyQ
    on sway.
  - sway-easyfocus (`SWAY_EASYFOCUS_VERSION`, cargo; gtk4-devel,
    gtk4-layer-shell-devel; Rust edition 2024). 1.0.1 ignores its whole
    yaml on an unknown key or without `show_confirmation`; colors come on
    the command line from sway variables.
  - sway-audio-idle-inhibit (`SWAY_AUDIO_IDLE_INHIBIT_VERSION`, meson from
    the tag, `-Dwerror=false`; libpulse, libsystemd): no `--version` (stamp
    and `ldd`), no systemd unit; holds a logind idle lock (not Wayland), so
    it stays after a logout: sway-autostart stops the old one
    (`pkill-display -f`, the name is longer than `pgrep -x`'s 15 characters).
  - eww is built with default features (X11 and Wayland in one binary;
    gtk-layer-shell dev package on every desktop distro). The stamp is
    `$EWW_REF+wayland`, so machines with the X11-only build rebuild once.
    eww picks the backend at start from `XDG_SESSION_TYPE` and
    `WAYLAND_DISPLAY`; one yuck file holds both property sets.
- Fedora: blueman needs `gobject-introspection` (xlib typelib); arandr needs
  `gtk3`. `/usr/local/sbin` is a link to `/usr/local/bin`.
- picom: only for tear-free drawing (`backend = "glx"`, `vsync`; Xorg 21.1
  modesetting has no TearFree, xf86-video-intel no Arrow Lake). Config keeps
  to options picom 9 (Debian/Ubuntu) and 13 (Fedora) share; `.xprofile`
  runs `picom -b`.
- Sunshine (Moonlight remote-desktop host): Fedora + Xorg only, from the
  `lizardbyte/stable` copr (`SUNSHINE_COPR`, package `Sunshine`; chroots
  fedora-43..45). Installed only: not started, no firewall ports opened.
- Syncthing (desktop): distro package (Fedora 2.x; Debian 12 1.19, Ubuntu
  22.04 1.18; not in EPEL 9, so not on EL9). `enable_syncthing` enables
  the package's user unit `syncthing.service` (`systemctl --user enable`
  works without a running user manager) and starts it only where the
  user manager answers. One instance per user, outside the X sessions.
  Devices and folders are set up by hand in its web UI (127.0.0.1:8384).
- lxpolkit: polkit agent, started by `.xprofile` (`pkill -x` first). Without
  an agent in i3, polkit refuses silently: firewall-config and other GUIs
  that run as the user cannot change anything. Not in EL9 EPEL (it has
  mate-polkit, polkit-gnome, xfce-polkit).
- EL9 has no xss-lock, blueman, arandr, autorandr, picom, syncthing,
  lxpolkit, rrandr.
  `.xprofile` must work without them. RHEL 10 has no Xorg or i3.
- CopyQ: Debian/Ubuntu only if the candidate is >= `COPYQ_MIN_VERSION`
  (8.0.0); older versions keep passwords from password managers.
- tuned-ppd: `dnf install --allowerasing` replaces power-profiles-daemon.
  Skip if `tlp` is installed.
- nmrs-gui: built with `cargo install` (needs Rust 1.95+); desktop file in
  `/usr/local/share/applications/nmrs.desktop`.
- wmfocus (`$mod+j`): `cargo install --features i3`. Build needs the
  cairo-gobject, fontconfig, freetype and expat headers; without the last two
  its crates build them with cmake. Escape is hard-coded as exit; with
  `--exit-keys` set, a wrong key no longer closes it. Missing font family:
  falls back to the first monospace font.
- rrandr (desktop): monitor layout GUI with refresh rate (arandr has none).
  No release or crate: `cargo install --git --rev "$RRANDR_REF"`. Needs
  GTK >= 4.6 (Ubuntu 22.04 has 4.6.9), pango >= 1.50 (EL9 has 1.48: not
  built there), `glib-compile-resources` and `msgfmt` at build time. No `--version`: verify checks the stamp and `ldd`. WM_CLASS
  `rrandr`, `rrandr` (checked under Xvfb). No profiles; autorandr saves them.
- kmscon.conf (`kmscon_conf`): `font-size`, `palette=solarized` (libtsm
  built-in; also `solarized-black`, `solarized-white`), and
  `font-name=PragmataPro Mono` only where `fc-list` finds it (commercial font;
  Mono: the console does no shaping). kmscon reads it at console start and
  does not follow `theme`. Test: `test/kmscon-conf/test.sh`.
- tree-sitter CLI: built with cargo; release binaries need glibc 2.39.
- Rust is not pinned: `install_rust` runs `rustup toolchain install stable`
  (installs or updates) and `rustup default stable` on every run. The
  `rust-analyzer` in `~/.cargo/bin` is a rustup proxy that runs the default
  toolchain's component; with another default it failed ("Unknown binary
  'rust-analyzer' in official toolchain").
- rust-analyzer, rust-src and llvm-tools (devtools): rustup components of
  stable. Their builds need glibc 2.17 at most and run on AL2 (tested: analysis-stats in the
  AL2 image). A toolchain binary copied out of its toolchain fails: it loads
  `librustc_driver` from the toolchain.
- AL2 aarch64: node 16 (`NODE_VERSION_AL2_AARCH64`).
- sudo resets PATH to `secure_path` (`/sbin:/bin:/usr/sbin:/usr/bin` on AL2,
  no `/usr/local/bin`, no `~/bin`). Build as the user; run only the install
  as root (`cmake --install`), never `sudo make install`: make runs again
  and can select other tools. nvim builds from source where glibc < 2.34
  (AL2); its Makefile selects Ninja when `ninja` is in PATH.
- lazy.nvim before v11.17.5 misreads `"lua==5.1"` in rustaceanvim's rockspec
  and then needs luarocks, which Fedora does not ship. `pin_lazy_nvim` checks
  out the lockfile's lazy.nvim before `Lazy! restore`, because nvim rewrites
  the lock at startup. Other plugins move with `Lazy! restore`.

## Tests

- `test/bootstrap/run.sh <distro>`: distros `debian12 ubuntu2204 fedora43
  fedora44 fedora45 rocky9 al2 al2023`. Snapshots the working tree (uncommitted files
  too) into a git repo mounted at `/src`, runs bootstrap twice with
  `BOOTSTRAP_CATEGORIES` (default `"devtools desktop"`; `BOOTSTRAP_CATEGORIES=
  run.sh <distro>` for basic only) and `BOOTSTRAP_DPI_SCALE=1.5`, then
  `verify.sh`, which reads the same variable. Log:
  `test/bootstrap/logs/<distro>-<categories>.log` (`fedora43-devtools-desktop.log`,
  `fedora43-basic.log`). Runs take minutes; run in background
  and tail the log. Run one distro at a time with pauses: parallel runs get
  GitHub 403 (rate limit).
- Fast nvim-only container run: `BOOTSTRAP_SKIP` with every step except
  `packages home dotfiles nvim link nvim-plugins`, in image
  `dotfiles-bootstrap-<distro>` (built by `run.sh`), with the snapshot at
  `/src` and test files mounted at another path.
- Unit tests with stubs and fake sysfs: `test/fzf-cache/test.sh`,
  `test/i3status-kb/test.sh`, `test/power-mode/test.sh`, `test/i3-session/test.sh`,
  `test/xprofile/test.sh` (runs `.xprofile` with only stubs on PATH),
  `test/tmux-plugins/test.sh` (fake HOME, private tmux sockets; never the
  caller's server),
  `test/idle-settings/test.sh`, `test/caffeinate/test.sh`, `test/eww/test.sh`,
  `test/pkill-display/test.sh`, `test/i3-bar/test.sh`, `test/xrdp/test.sh`,
  `test/xrdp-conf/test.sh`, `test/syncthing-status/test.sh`,
  `test/autorandr-hook/test.sh`,
  `test/input-restore/test.sh`,
  `test/fetch/test.sh` (`fetch_unpack` must die on a failed download: it runs
  in `$(...)`, where `set -e` does not apply),
  `test/system-sleep/power-button-wake.sh`. Add new tests in this style.
- X programs: Xorg dummy driver in a container. i3 bindings: Xvfb + i3 with
  the repo config in a Fedora image, `xdotool key super+j`, then read the
  started program's `/proc/<pid>/cmdline`. `test/i3-swap/test.sh` does this for the
  window swap (`$mod+m` mark `swap`, shown in the title; `_` marks are hidden; `$mod+Shift+m` swap) with `docker cp` (SELinux). `bin/theme light` switches the
  colors there too (gsettings fails, xrdb and the i3 reload work).
- Put no dependent tool calls in one block: an edit and the command that
  needs it run in parallel, and the command sees the old file.
- Docker pitfalls: `pkill -f` kills its own `bash -c`, use `pkill -x`. Root
  that reads another user's `/proc/*/environ` needs `--cap-add SYS_PTRACE`.
  A `-v` bind of a missing host path creates a root-owned directory there.
  The host has cgroup v1: only old systemd (AL2 image) boots as PID 1 in a
  `--privileged` container.
- Fast lspmux check: bootstrap with `BOOTSTRAP_SKIP` for all steps except
  `packages home dotfiles rust lspmux`, then `verify.sh | grep lspmux`.
- sway tests: `test/sway/test.sh` (fedora:45, headless sway, `docker
  create --cap-add SYS_NICE` + `docker cp`): config validation, bindings
  through `wtype` with stubs on sway's PATH, swap, Ctrl+digit, window
  rules by app_id and class, idle inhibit, swaybar fallback, fuzzel,
  Ctrl+Alt+Backspace. `test/eww-sway/test.sh` (image `dotfiles-eww-sway`,
  eww built at `EWW_REF`): one bar per output, tray on the first, reopen
  after an output change. `test/sway-session/test.sh` (lightdm's Xsession
  wrapper runs sway in English; `~/.xprofile` does not run).
  `test/xkb-bone2/test.sh` (regenerate check, libxkbcommon levels against
  `.Xmodmap`). Stub tests: `test/sway-autostart`, `test/wm-msg`,
  `test/kanshi-save`, `test/clip-pick`, `test/pwr-lock`.
- Headless sway in a container: `WLR_BACKENDS=headless WLR_RENDERER=pixman
  WLR_LIBINPUT_NO_DEVICES=1`, a user with a 0700 `XDG_RUNTIME_DIR`,
  `--cap-add SYS_NICE`. `wtype -M logo j -m logo` triggers bindings; a
  client that grabs the keyboard needs `wtype -s 1500`. fuzzel needs
  `--no-exit-on-keyboard-focus-loss` (wtype's keyboard takes the focus).
  Layer surfaces (bars) are not in `get_tree`; the workspace rect moves by
  the exclusive zone. sway's `/proc/<pid>/environ` is not readable (file
  capabilities): ask a child (`swaymsg exec 'echo "$DISPLAY" > file'`).
  Stubs that run at the same time must write each line in one call.
  `systemd-analyze --user verify` fails on the AL2 host (systemd 219):
  `test/i3-session` fails there for that reason only.

## Neovim (`.vim.init.lua`)

- Format with stylua (`.stylua.toml`: width 140, `collapse_simple_statement
  = "Always"`). The file has old stylua diffs. Check only the changed lines;
  do not reformat the file.
- Keyboard layout is Bone 2 (some comments wrongly say Colemak): `b r n s` =
  left up down right, `gn`/`gr` = `gj`/`gk`, `(`/`)` = half page, `S-n`/`S-r`
  scroll, `S-b`/`S-s` word back/forward, `w` = `e`. Leader is Space,
  `timeoutlen` 500.
- Plugin buffers that map these keys or `<Space>` need a remap. Pattern:
  `FileType` autocmd, `vim.schedule` (plugins set maps after `filetype`),
  `nvim_buf_call`, read `maparg(..., true).callback`, move it. Examples:
  `gitsigns-blame` (`r` to `<C-r>`), `gitsigns-diff` (`<Space>` to `-`).
- New `<leader>` groups go in the which-key `wk.add` list.
- Theme: solarized.nvim, `init_solarized_scheme()` `on_highlights`, `is_dark`.
  `signcolumn = "number"` and `cursorline`, so sign groups need `Cul` variants.
  Plugin groups (flash.nvim) go in `on_highlights`: a mode change loads the
  colorscheme again and drops groups set once in a plugin config (light mode
  lost the flash backdrop). Test: `test/nvim-theme/test.sh`.
- gitsigns:
  - Pin >= `ef707fb`. It has `75a6649`: before it, one error in the watcher
    handler stopped all refreshes of the buffer until `:e`.
  - `show(revision, opts, callback)`. A file at a revision is `"HEAD:%"`;
    `show("HEAD")` opens the commit.
  - Hunk keys: buffer-local `<leader>s*` in `on_attach`. `<leader>sd` is
    global: `diff(nil, nil, { diff = "none" })`, the changed-files panel with
    index and worktree status columns.
  - Staged signs: `▌`, `#859900` (green) on dark, `#6c71c4` (violet) on light.
    Green on light has 3:1 contrast and is the unstaged add color there. The
    gitsigns default (`fg_factor` 0.5) gave 1.3-1.6:1.
- nvim-tree: `keep_layout` saves the window layout per tab, and a
  `WinClosed` autocmd restores it (q, `:q`, `quit_on_open`).
  `:NvimTreeKeepLayoutToggle` turns it off. Cause: `adaptive_size` and
  nvim-tree's `vsp` + `wincmd H`; `noequalalways` does not help.
- Neogit is installed. Diffview is a Neogit dependency only; upstream has no
  commits since 2024-06-13.
- Headless tests: `nvim --headless +"luafile t.lua"` loads the full config.
  After bootstrap, `~/.config/nvim/init.lua` links to the `~/.dotfiles`
  clone, not the working repo; test working-repo edits with
  `nvim -u <repo>/.vim.init.lua`.
  `+` commands run before VimEnter, so which-key maps (`wk.add` with rhs) and
  VeryLazy plugins are missing. For those use
  `--cmd 'autocmd VimEnter * ++once lua vim.defer_fn(function() dofile("t.lua") end, 2000)'`.
  Use throwaway repos in `/tmp`. Wait with `vim.wait`; gitsigns buffer maps
  appear after `b:gitsigns_status_dict`. Call maps through
  `vim.fn.maparg(lhs, "n", false, true).callback()`; `feedkeys` is unreliable
  with async UIs. A plugin prints a deprecation message without a newline;
  pipe output through `sed 's/information/information\n/'`.

## i3 and X

- `$mod` is Mod4. xremap swaps left Alt and Ctrl for all layouts. `kb`
  switches `us de bone2`: inside X only the session's X keyboard, with
  `--console` also the console; on a tty (no DISPLAY) only the console
  (kmscon: `localectl` with `de(bone)`, which is also the X server default:
  login screen, added keyboards; fbcon: `loadkeys`). Some of the user's
  keyboards make bone2 in firmware: never use XKB groups. Test:
  `test/kb/test.sh`. Login layout is `de`: `.xprofile` starts xremap, waits (max
  3 s) for its virtual keyboard in `xinput`, then runs `kb de`. A keyboard
  added later gets the server default from `00-keyboard.conf` (`kb` changes
  it only with `--console` or on a tty), not kb's layout, and the bar would
  be wrong.
  `bin/input-restore` (started by `.xprofile`, stopped with `pkill -f`: it runs
  as `bash`) watches `udevadm monitor` input add/change events and, once they
  settle, runs `kb <kb show>` and `touchpad restore` (the session's last
  choice). Installers that run `udevadm trigger` re-add every input device.
- i3status `wireless`: `W: %essid (%quality)`, `format_quality = "%d%s"`
  (no padding).
- xrdp (desktop): packages `xrdp xorgxrdp` (Debian/Ubuntu, 0.9: the unit
  runs it as `User=xrdp`), `xrdp xorgxrdp-glamor` (Fedora, EPEL 9; 0.10:
  root unless `runtime_user`/`runtime_group` are set; the packages ship
  them commented out, with the `xrdp` user, `root:xrdp` 0640 key files
  and sesman's `SessionSockdirGroup=xrdp`). `install_xrdp`:
  `xrdp_drop_privileges` edits `[Globals]` of `/etc/xrdp/xrdp.ini` in place
  (no include directory), restorecon, `systemctl enable`, restart on a
  change. No firewall rule (port 3389), as for Sunshine. Test:
  `test/xrdp-conf/test.sh`; verify checks `/etc/X11/xrdp/xorg.conf`
  (without xorgxrdp the session's Xorg failed on the real GPU).
- Two X sessions at once (local plus xrdp, which starts its own session:
  startwm.sh runs Xsession without arguments, which runs `~/.xsession`:
  `.xprofile` unless `XPROFILE_LOADED` (Fedora's xinitrc.d hook loaded it;
  Debian's Xsession does not), then `exec i3`): `.xprofile` and `bar` stop old instances with
  `bin/pkill-display -x|-f` (only processes whose `/proc/<pid>/environ`
  has the caller's DISPLAY; plain pkill stopped the other session's
  xremap, picom, xidlehook, ...). With `XRDP_SESSION` set, `.xprofile`
  skips autorandr, xremap (it grabs the machine's keyboards), input-restore,
  xidlehook (a remote idle would suspend the laptop), picom, blueman and
  `kb de` (the RDP client sets the layout; the user wants it kept). CopyQ:
  `COPYQ_SESSION_NAME=xrdp` (exported before i3) gives the session its own
  server; i3's `copyq toggle` inherits it. $mod over RDP from the Mac
  (Royal TSx): Cmd loses key-ups of keys pressed with it (macOS; they stay
  pressed in X and i3's grab keeps the keyboard), Ctrl with "Windows Keys
  Passthrough" arrives as Super only on release, Ctrl without it not at all
  (client keylayout 0); F19 and Ctrl-with-passthrough arrive as a tap when
  pressed, the Application key as scancode 0. xorgxrdp turns every
  repeated key-down of an ordinary key into release + press
  (`sendDownUpKeyEvent`, rdpKeyboard.c); only Shift, Caps, Ctrl, Alt, Win,
  Menu and Meta pass unchanged. So right Shift (keycode 62) is $mod in
  xrdp: Karabiner (Royal TSx only) sends right Shift for Cmd and left Shift
  for the physical right Shift; `bin/xrdp-keys` removes Shift_R from Shift,
  makes keycode 62 Super_L in Mod4 and checks `xmodmap -pm` every 2 s
  (xrdp loads a fresh keymap per connect; xev has no mapping mask and gets
  no core MappingNotify under XKB). `bin/term` ($mod+Return): `wezterm start
  --always-new-process` in xrdp, else plain `wezterm` (joins the running
  GUI, which may be the other session's). Test: `test/xrdp/test.sh`.
  `kb` keeps its state per display
  (`kb-layout-$DISPLAY`). eww: one daemon per display, see Bar. xrdp needs
  `xorgxrdp` (or `xorgxrdp-glamor`), else Xorg finds no `xrdp/xorg.conf`
  and fails on the real GPU. Tests: `test/pkill-display/test.sh` (real
  processes), `test/xprofile/test.sh`, `test/kb/test.sh`.
- Floating windows need `for_window` rules: nmrs (`class`), `blueman-*`,
  copyq (`move position mouse`), arandr, rrandr and pavucontrol (`instance`).
- Bar: eww (`.config/eww`, linked; `install_eww`, desktop, commit
  `EWW_REF`, `--no-default-features --features x11`: release 0.6.0 pins
  Rust 1.76). `bin/bar` (run by `.xprofile` before the tray apps) starts the
  daemon, waiting until it answers (a running one is replaced: eww does
  not see edits behind the per-display links, an i3 restart does not
  restart eww, and `eww reload` stacked bars, see below), then `bar watch` (stopped with `pkill -f '/bin/bar watch$'`)
  waits for i3, opens `bar` per active output (`--arg output/height/tray`;
  tray on the primary one; height 34 px at 144 dpi, scaled by `Xft.dpi`)
  and reopens on output events. One daemon per X display: eww names its
  socket by the canonical config path, so `bar` points it at
  `$XDG_RUNTIME_DIR/eww/display<N>/`, a real directory of links to
  `~/.config/eww/*` (a symlinked directory would resolve to the same path;
  a changed XDG_RUNTIME_DIR would leak into kb and the other scripts). i3bar is only the fallback: its block is
  `.config/i3/i3bar.conf`, the i3 config has `include
  ~/.config/i3-bar.d/*.conf` (variables of the main config reach it), and
  bootstrap's `select_bar` links it there only without `$PREFIX/bin/eww`
  (removes the link otherwise). Test: `test/i3-bar/test.sh` (i3 on Xvfb,
  `get_bar_config`). An `eww open` that finds no daemon (not up yet, busy
  in a reload) forks a daemon of its own (eww 0.6 main.rs; its process
  keeps the `open` command line): it takes the socket, the old daemon
  keeps its bars, and close-all and kill reach only one. Outputs had up
  to five bars stacked, or none. So `open` runs with `--no-daemonize`
  (then it fails) and `timeout` (a hung open blocked the watcher), only
  `start_daemon` starts one, and a restart stops every eww process of the
  display's config (`pkill-display -f "eww -c <config> "`). After opening,
  `bar` checks that i3 docks exactly one eww bar with a height per active
  output (a bar was sometimes 0 px high too), else restarts the daemon
  and opens again, at most 3 times. Output events are debounced
  (`BAR_SETTLE_S`, 1 s): a plugged monitor sends several. Scripts in `scripts/`:
  `status-blocks` reads `~/bin/i3status-kb` (own process group: it exits
  with `kill 0`) and keys the blocks by name: the bar draws each block in
  its own widget, in i3status order, hidden while missing. No `for` over
  blocks: eww rebuilds a `for` body on every update, so a tooltip graph lost
  its history every 5 s, and a widget after a `for` in the same box was not
  drawn. `block-click` repeats its clicks, `block-tooltips` (battery,
  VPN) is one JSON object per block name (`BLOCK_TOOLTIPS_SYSFS` for tests),
  `net-info` (network blocks: addresses, down/up rate from two
  `/sys/class/net/*/statistics` samples), `disk-info` (`df`, one entry per
  device: btrfs `/` and `/home` share one), `theme-mode` follows gsettings (class `bar dark|light`), `i3-workspaces`
  reconnects after an i3 restart, `i3-mode` too (binding mode, empty for
  `default`; label after the workspaces in the urgent colors, as i3bar). Syncthing: `i3status-kb` adds `ST: idle`,
  `ST: <percent>%` (db/completion of the local copy, rounded down) or
  `ST: off` from `~/bin/syncthing-status`, no block without Syncthing;
  the tooltip polls `syncthing-status --details` (state, down/up rate
  from two `system/connections` samples, needed files and bytes, folder
  and system errors, devices, folder states). It reads address and API
  key with `syncthing cli config gui dump-json` and gives the key to curl
  on stdin (`-H @-`), never in arguments. Tooltips are their own windows, so one
  look for both themes. Tray: StatusNotifierItem only (eww is the watcher).
  CPU, RAM and time have widget tooltips (`tooltip`: content built once,
  so the CPU `graph` keeps 5 min of history from the i3status value, via
  `replace(blocks?.cpu_usage?.full_text, ...)`, no extra polling). The
  graph needs `:width`/`:height` (it requests only its line thickness; CSS
  min-width does not apply); 0-100 %, not scaled to the peak (the user's
  choice). Cores are colored by value (green, yellow from 50 %, red from
  80 %), disks by usage (75 %, 90 %). Every tooltip is a widget tooltip:
  with a label `:tooltip` text the bar sometimes came up 0 px high, and the
  reopen guard reopening too early made it worse (`BAR_SIZE_CHECK_S`).
  Each `for` sits in a box of its own (no widget after it). All details,
  network, battery and VPN included, poll only while hovered; the bar
  text is i3status (`disk "/"` for `D:`). Their details (`cpu-info`,
  `mem-info`, `uptime -p`, date for `calendar`) poll only while hovered:
  eventbox `onhover` sets `hover`, polls use `:run-while`. eww ignores
  `:run-while` when a window opens and starts every poll the window uses;
  `bar` sets hover twice after opening to stop them. Load: 1, 5, 15 min
  (the kernel has no 30). "Wired" (macOS term): Unevictable + SUnreclaim +
  KernelStack + PageTables; dropped from the RAM tooltip (used, available,
  cached, free, swap).
  Test: `test/eww/test.sh`.
- i3bar fallback (`.config/i3/i3bar.conf`): no `tray_output`: with `primary`, the tray vanishes when no output is
  primary. i3bar shows the tray on one output only.
- `i3-msg` exec needs one string: `i3-msg -q "exec --no-startup-id nmrs-gui"`.
- `status_command` is `~/bin/i3status-kb`: adds `KB:`, `PWR:`, `☀:` (backlight, `I3STATUS_KB_SYSFS` for tests) and `VPN:`
  (NetworkManager `vpn`/`wireguard` connections via `nmcli`, Tailscale via
  `tailscale status --json` BackendState) blocks and
  click handling around i3status.
- lightdm on Fedora/EL does not source `~/.xprofile`; the xinitrc.d hook does.
- Language: `.xprofile` exports `LANG=en_US.UTF-8` before i3. lightdm sets
  LANG from the AccountsService language, which came back as `de_DE.utf8`
  after `SetLanguage en_US.UTF-8` (greeter suspected); arandr, pavucontrol
  and blueman were German. Test: `test/xprofile/test.sh`.
- Qt scaling: `.xprofile` exports `QT_SCALE_FACTOR=Xft.dpi/96` and
  `QT_FONT_DPI=96`. Qt 6 already scales by `Xft.dpi` (alone, QT_SCALE_FACTOR
  doubles it to 2.25); Qt 5 (Resolve bundles 5.15) scales only fonts by it.
  Measured with PyQt5/PyQt6 `devicePixelRatio`/`logicalDotsPerInch`.
- `.xprofile` starts `i3-session.target` (`.config/systemd/user/`, linked);
  it binds `graphical-session.target`, which xdg-desktop-portal requires since
  Fedora 45. The i3 exit binding stops it. Without it the portal does not
  start and Firefox ignores `theme`.
- Scale per monitor setup: X has one Xft.dpi for all screens. autorandr's
  global hook `.config/autorandr/postswitch` sets Xft.dpi from the
  profile's `xft-dpi` file (`~/.config/autorandr/<profile>/xft-dpi`), else
  from `~/.Xresources`, and restarts i3 in place when it changed (the bar
  reopens on the output event at the new height). Laptop desk: profile
  `desk`, 120 (1.25x; 32" 4k DP-2 and eDP-1 at scale 1, the 1440p DP-1
  `--scale 1.25`); elsewhere 144. `.xprofile` runs autorandr before it
  computes the Qt scale. Running apps keep their DPI; `autorandr --load`
  of the current profile skips hooks ("Config already loaded").
- Key repeat is set in `xorg-conf/50-keyboard-repeat.conf`; `xset r rate` does
  not reach the xremap device.
- Idle: `.xprofile` sources `~/.config/idle.conf` (written from the
  `IDLE_*` settings; `check_idle_settings` needs suspend > lock, test
  `test/idle-settings/test.sh`). xidlehook (cargo, desktop) runs both
  timers, `--not-when-audio --not-when-fullscreen --detect-sleep`: timer 0
  `loginctl lock-session` after the lock minutes, timer 1 `systemctl
  suspend` after the difference (timers chain). Socket
  `$XDG_RUNTIME_DIR/xidlehook.sock`; `caffeinate` disables timer 1 (with
  `display` all) through `xidlehook-client`. `xss-lock` (`pwr lock
  --nofork`) is only the locker (before suspend, on lock-session); `xset s
  off`, because it would lock on X's timer during video. Replaced xautolock:
  in i3 nothing implements Firefox's idle inhibit (no
  `org.freedesktop.ScreenSaver`, no GNOME session manager). xidlehook's last
  release is 0.10.0 (2021); links libxcb and libpulse. One crate, two
  binaries: `xidlehook-client --version` prints the crate name (`xidlehook
  0.10.0`), so verify.sh matches the version only; a missing client
  installs the crate again. autorandr runs before i3.
- `pwr lock|sleep|hibernate|performance|balanced|battery|mode`. Modes use
  busctl `org.freedesktop.UPower.PowerProfiles` (tuned-ppd).
  `power-mode-auto` selects performance on AC and battery on battery, only
  when the AC state changed since its last run (`/run/power-mode-auto/ac`), so
  a replayed udev event keeps a mode set with `pwr`.
- Sleep hook: only LNXPWRBN, PNP0C0C, intel-hid and intel-vbtn may wake.
  Fedora hibernation: zram swap only, and Secure Boot lockdown blocks it.

## sway (desktop-wayland)

- Session: lightdm, entry "Sway (dotfiles)" -> `/usr/local/bin/sway-session`
  (exports LANG=en_US.UTF-8, the XDG desktop/session variables, Electron
  and Java hints; not `QT_QPA_PLATFORM`: Qt picks Wayland from
  `XDG_SESSION_TYPE`, and old bundled Qt 5 aborts on a list). lightdm runs
  Wayland sessions through `/etc/X11/xinit/Xsession` too, so
  `xinitrc-d/90-xprofile.sh` skips `~/.xprofile` when `XDG_SESSION_TYPE` is
  `wayland`. lightdm sets `XDG_SESSION_DESKTOP` to the entry's file name.
- `.config/sway/config` is the i3 config ported; order: dark color
  defaults, the input blocks, `include ~/.config/sway.d/*.conf` (so
  `kb.conf` wins over the default `xkb_layout de`), the rest, `exec
  ~/bin/sway-autostart`, `include ~/.config/sway-bar.d/*.conf` (swaybar,
  linked only without eww). Colors only in top-level lines: `bin/theme`
  sets the variables at runtime and runs those lines again, without
  `reload` (a sway 1.12 reload drops runtime output and input settings:
  kanshi's layout, touchpad tapping). Differences from i3: fuzzel
  (`$mod+i`), `clip-pick` (`$mod+c`, cliphist), sway-easyfocus (`$mod+j`),
  wdisplays (XF86Display), `$mod+Shift+a` reloads, swaynag exit,
  `Ctrl+Alt+BackSpace` exits, `Ctrl+N` / `Ctrl+Shift+N` workspace bindings
  (physical Alt+digit, which xremap maps in X).
- No xremap on sway: `xkb_options ctrl:swap_lalt_lctl` (applies to new
  keyboards too). sway applies `input type:...` settings, also runtime
  `swaymsg input` ones, to devices plugged in later: no `input-restore`.
- `bin/sway-autostart` is the `.xprofile` of sway: imports
  `WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY`
  into systemd and D-Bus, starts `sway-session.target` (graphical-session
  for xdg-desktop-portal), theme restore, `kb de`, kanshi (only with
  `~/.config/kanshi/config`), swayidle, sway-audio-idle-inhibit, `wl-paste
  --watch cliphist store`, the bar, blueman-applet, lxpolkit. A watcher
  stops the target and removes the variables when sway ends (D-Bus gets
  empty values): the user manager outlives a logout while ssh or lingering
  keeps it, and a later i3 login would see `SWAYSOCK`.
- Session detection in every script: `SWAYSOCK` before `DISPLAY` (sway sets
  `DISPLAY` for Xwayland). Per-session keys use `WAYLAND_DISPLAY` (state
  files, eww's config directory `$XDG_RUNTIME_DIR/eww/wayland-N`,
  `pkill-display`). `bin/wm-msg` runs `swaymsg` in sway, else `i3-msg`.
- Idle: swayidle timeouts count from the last input (not chained):
  `loginctl lock-session` after IDLE_LOCK_MINUTES, `systemctl suspend`
  after IDLE_SUSPEND_MINUTES; `lock` and `before-sleep` run `pwr lock`
  (swaylock). `inhibit_idle fullscreen` for all windows.
  `caffeinate` takes a logind inhibitor (`systemd-inhibit --what=sleep`,
  with `display` also `idle`); swayidle honours it, and `pwr sleep` is
  refused meanwhile (lid close still suspends).
- Bar: the same eww config (Wayland properties `:exclusive`, `:focusable`,
  `:namespace` next to the X11 ones). On sway: 23 logical px high (sway
  scales), tray on the first active output, `bars_ok` checks that each
  output's workspace rect starts one bar height below the output top
  (assumes no top gaps).
- Keyboard: `xkb/symbols/bone2` (one group, eight levels; Neo Mod3 =
  level 3, Mod4 = level 5; name "Bone 2 (dotfiles)"); libxkbcommon finds it
  in `~/.config/xkb`. Differences from the X keymap: Mod4+Space gives 0,
  Mod4+Return KP_Enter, Mod4 on the keypad navigation, both orders lock
  Mod4, no mouse keys; the Neo Mod4 lock uses the NumLock modifier (do not
  set `xkb_numlock enabled`). `kb` on sway: `swaymsg input type:keyboard
  xkb_layout`, plus `~/.config/sway.d/kb.conf` for reloads.
- Monitors: kanshi profiles in `~/.config/kanshi/config` (the user's file,
  not in the repo); `kanshi-save NAME` writes the current outputs (matched
  by make, model, serial) and runs `kanshictl reload`.
- Known gaps: XWayland apps (Qt 5, DaVinci Resolve) are blurry at a
  fractional scale; no xrdp (it stays with the i3 session); no mouse keys;
  the X touchpad curve. lxpolkit (GTK 2) runs on Xwayland.

## tmux and wezterm

- tmux: one config per tmux version; a version bump needs a new
  `tmux/tmux_linux_<ver>/` directory. `prefix T` runs
  `.tmux/custom/toggle-dark-mode`. tpm is pinned (`TPM_REF`); the `@plugin`
  lines are not. `setup_tmux_plugins` runs tpm's `install_plugins` in a
  private server (`env -u TMUX`, own `TMUX_TMPDIR`): tpm reads its plugin
  path from the server, and in a server without tpm loaded it aborted
  ("Tmux Plugin Manager not configured"). Then it runs `source-file
  ~/.tmux.conf` in a running server, which loads new plugins. A failed
  install warns with tpm's output. Test: `test/tmux-plugins/test.sh`.
- tmux-fastcopy (`prefix f`, replaces find-window): tpm plugin, binary from
  the GitHub release (`TMUX_FASTCOPY_VERSION`, static); the plugin falls back
  to `tmux-fastcopy` on PATH, else builds with Go at every start. Action
  `tmux load-buffer -w -` (clipboard too). Its `--version` prints several
  lines: `| head -n 1` under pipefail failed 21 of 300 times (SIGPIPE); use
  `sed -n 1p`.
- tmux-flash (`prefix g` the active pane, `prefix G` all panes of the
  window): Rust, its own repository
  <https://github.com/Leandros/tmux-flash> (locally
  `~/github/tmux-flash`, with its own steering file; read it before changes
  there). Bootstrap step `tmux-flash` (basic, next to `tmux-fastcopy`, no
  cargo): the release archive `tmux-flash-<target>.tar.gz` of
  `TMUX_FLASH_VERSION` (`RUST_TARGET_LINUX_MUSL`: static, also on AL2;
  `RUST_TARGET_DARWIN`: Apple Silicon only). Also on crates.io and with
  `cargo binstall tmux-flash`. Bindings: `run-shell -b 'tmux-flash
  --multi-pane off|on --pane ... --client ...'` (the popup needs the client;
  the flag overrides the `@flash-multi-pane` option, which is not set;
  `--multi-pane` needs 0.2.0). `@flash-labels` in the tmux
  configs sets the Bone 2 labels of the nvim flash config (the default is
  QWERTY). `toggle-dark-mode` sets `@color-mode dark|light` for its colors.
  verify.sh types `prefix g`, `alpi`, Enter through a second tmux server as
  the client and checks the copy-mode cursor; checks that `prefix g` has
  `--multi-pane off`; then in a window with two panes types `prefix G`,
  `om` and the label it reads from the client screen, and checks that the
  right pane is active in copy mode.
- tmux-jump (Ruby) was its predecessor. Removed from this machine (the AL2
  dev box, the only one that ran it): the private Ruby, the stamp and the
  plugin. bootstrap removes nothing.
- wezterm: Xorg only, rolling nightly (GitHub `.deb` on Debian/Ubuntu, COPR on
  Fedora/EL). It reads the DPI from `~/.Xresources`. On Linux its scheme
  follows `gsettings get ... color-scheme` (set by `theme`), read in the
  config; `wezterm.gui.get_appearance()` only without gsettings: it returned
  Light in every other config evaluation on a dark desktop (nightly
  20261108). wezterm still reloads the config when the portal setting
  changes. `test/wezterm/test.sh` loads `.wezterm.lua`
  with a fake `wezterm` module in `nvim -l`.
- wezterm copy mode (`Leader+[`) mirrors tmux's copy-mode keys. `set_keys`
  replaces default entries with the same key and modifiers. While a search
  pattern is edited, wezterm uses the `search_mode` table, not `copy_mode`
  (copy.rs `update_key_table`), and only `AcceptPattern` ends editing: Enter
  = PriorMatch + AcceptPattern, Escape = ClearPattern + AcceptPattern.
  `config.key_tables` must list `search_mode` too. wezterm keeps the last
  pattern per tab (`SAVED_PATTERN`); a new copy mode with one shows the search
  bar and jumps to its first match, so every exit (q, Ctrl+c, Ctrl+g, Y) runs
  `ClearPattern` first (`leave_copy_mode`). The config also runs in LuaJIT
  (tests): no `table.unpack`. Check with
  `wezterm show-keys --lua --key-table copy_mode|search_mode`.
- nvim, tmux and wezterm all use Solarized dark and light. Keep their colors
  the same. nvim has `EnableDarkMode()` and `EnableLightMode()`.
- On Linux all three follow `theme` by reading the desktop, never by `theme`
  writing their configs. tmux: `.tmux.conf` runs `.tmux/custom/follow-system-theme`
  (`gsettings monitor` color-scheme, then `toggle-dark-mode dark|light`; one
  per server via `@theme_watcher`, ends with the server; checked every 60 s).
  nvim: `desktop_color_mode()` (`gsettings get`) sets `background` before the
  colorscheme loads; a `gsettings monitor` job started at VimEnter calls
  `set_color_mode`. Tests: `test/tmux-theme/test.sh`, `test/nvim-theme/test.sh`
  (headless, needs the plugins installed).
- Over ssh: the zsh `ssh` function sends `LC_COLOR_SCHEME` (`theme show`, else
  the received value) with `-o SendEnv`. sshd needs `AcceptEnv` (Fedora/EL
  accept only listed `LC_*` names): bootstrap step `sshd` installs the drop-in.
  Without a desktop preference, tmux and nvim use `LC_COLOR_SCHEME`; tmux adds
  it to `update-environment` and a `client-attached` hook runs
  `follow-system-theme apply <session>`. Test: `test/ssh-theme/test.sh`.
- `theme dark|light|toggle|show|restore`: i3 base colors are
  `set_from_resource $<name> i3wm.<name> <dark fallback>`, merged with xrdb,
  then `i3-msg reload`. The choice lives in gsettings
  `org.gnome.desktop.interface color-scheme` (portal, Firefox). GTK 3/4 on
  X11 ignore it: `theme` sets `gtk-application-prefer-dark-theme` in
  `~/.config/gtk-{3.0,4.0}/settings.ini`, read at app start; `.xprofile`
  runs `theme restore` before i3. i3 cannot use variables set in an included
  file, so the theme is not an include.

## Shell

- fzf CTRL-T: `.zshrc` sets `FZF_CTRL_T_COMMAND` to `fzf-cache show` and binds
  `load:unbind(load)+reload-sync(fzf-cache update ...)`. `fzf-cache` refreshes
  in its own process group (fzf kills the reload group), locks per directory
  and command, and prunes caches older than `MAX_AGE_DAYS`.
- `.zshrc` loads the oh-my-zsh `direnv` plugin only when `direnv` is on
  PATH (`${commands[direnv]:+direnv}` in `plugins`): without the devtools
  category the plugin printed a warning in every shell. `verify.sh` checks
  `zsh -i` for it.
