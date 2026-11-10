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
| `.wezterm.lua`, `.xinitrc`, `.xprofile`, `.Xmodmap`, `.config/{i3,i3status,xremap,picom}`, `.config/systemd/user/i3-session.target` | `$HOME`, links, Xorg only |
| `bin/{kb,i3status-kb,pwr,theme,flightmode,touchpad,charge,caffeinate,smb,input-restore}` | `~/bin`, links, Xorg only |
| `bin/fzf-cache` | `~/bin`, link, always |
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
  lspmux, codelldb) and `desktop` (the Xorg/i3 desktop) are optional.
  `choose_categories` in `main` sets `CATEGORIES` from `BOOTSTRAP_CATEGORIES`
  (`all`, `""`), else a menu on a terminal, else basic only. Desktop is not
  offered and is dropped with a warning where `xorg_supported` fails. Steps
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

New tool: choose its category first. Version constant with URL, install
function with stamp, `step` (basic) or `category_step` in `run_all`,
`print_version` in `report` (in the category's block), `check_version` in
`verify.sh` (dev tools in `check_devtools`, plus an absence check in
`check_no_devtools`), README.
New link or system file: install function, `check_link` or `cmp` check in
`verify.sh`, README.

### Package quirks

- Fedora: blueman needs `gobject-introspection` (xlib typelib); arandr needs
  `gtk3`. `/usr/local/sbin` is a link to `/usr/local/bin`.
- picom: only for tear-free drawing (`backend = "glx"`, `vsync`; Xorg 21.1
  modesetting has no TearFree, xf86-video-intel no Arrow Lake). Config keeps
  to options picom 9 (Debian/Ubuntu) and 13 (Fedora) share; `.xprofile`
  runs `picom -b`.
- Sunshine (Moonlight remote-desktop host): Fedora + Xorg only, from the
  `lizardbyte/stable` copr (`SUNSHINE_COPR`, package `Sunshine`; chroots
  fedora-43..45). Installed only: not started, no firewall ports opened.
- lxpolkit: polkit agent, started by `.xprofile` (`pkill -x` first). Without
  an agent in i3, polkit refuses silently: firewall-config and other GUIs
  that run as the user cannot change anything. Not in EL9 EPEL (it has
  mate-polkit, polkit-gnome, xfce-polkit).
- EL9 has no xss-lock, xautolock, blueman, arandr, autorandr, picom,
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
- Floating windows need `for_window` rules: nmrs (`class`), `blueman-*`,
  copyq (`move position mouse`), arandr, rrandr and pavucontrol (`instance`).
- No `tray_output`: with `primary`, the tray vanishes when no output is
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
- Key repeat is set in `xorg-conf/50-keyboard-repeat.conf`; `xset r rate` does
  not reach the xremap device.
- Idle: `.xprofile` sources `~/.config/idle.conf` (written from the
  `IDLE_*` settings), runs `xss-lock` (`pwr lock --nofork`) and `xautolock`
  (`-detectsleep`) for suspend. autorandr runs before i3.
- `pwr lock|sleep|hibernate|performance|balanced|battery|mode`. Modes use
  busctl `org.freedesktop.UPower.PowerProfiles` (tuned-ppd).
  `power-mode-auto` selects performance on AC and battery on battery, only
  when the AC state changed since its last run (`/run/power-mode-auto/ac`), so
  a replayed udev event keeps a mode set with `pwr`.
- Sleep hook: only LNXPWRBN, PNP0C0C, intel-hid and intel-vbtn may wake.
  Fedora hibernation: zram swap only, and Secure Boot lockdown blocks it.

## tmux and wezterm

- tmux: one config per tmux version; a version bump needs a new
  `tmux/tmux_linux_<ver>/` directory. `prefix T` runs
  `.tmux/custom/toggle-dark-mode`. tpm is pinned (`TPM_REF`); a failed plugin
  install only warns (`prefix I` in tmux).
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
