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
  in the same block.

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
| `.wezterm.lua`, `.xinitrc`, `.xprofile`, `.Xmodmap`, `.config/{i3,i3status,xremap}` | `$HOME`, links, Xorg only |
| `bin/{kb,i3status-kb,pwr,theme,flightmode}` | `~/bin`, links, Xorg only |
| `bin/fzf-cache` | `~/bin`, link, always |
| `xorg-conf/*.conf` | `/etc/X11/xorg.conf.d/` (root copy) |
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
  steps. Env: `BOOTSTRAP_XORG=1`, `BOOTSTRAP_DPI_SCALE`, `BOOTSTRAP_NONINTERACTIVE=1`,
  `BOOTSTRAP_DOTFILES_REPO`, `BOOTSTRAP_DOTFILES_REF`.
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
- Xorg (`setup_xorg`) runs only with `BOOTSTRAP_XORG=1` on debian, ubuntu,
  fedora, rhel <= 9.

New tool: version constant with URL, install function with stamp, `step` in
`run_all`, `print_version` in `report`, `check_version` in `verify.sh`, README.
New link or system file: install function, `check_link` or `cmp` check in
`verify.sh`, README.

### Package quirks

- Fedora: blueman needs `gobject-introspection` (xlib typelib); arandr needs
  `gtk3`. `/usr/local/sbin` is a link to `/usr/local/bin`.
- EL9 has no xss-lock, xautolock, blueman, arandr, autorandr.
  `.xprofile` must work without them. RHEL 10 has no Xorg or i3.
- CopyQ: Debian/Ubuntu only if the candidate is >= `COPYQ_MIN_VERSION`
  (8.0.0); older versions keep passwords from password managers.
- tuned-ppd: `dnf install --allowerasing` replaces power-profiles-daemon.
  Skip if `tlp` is installed.
- nmrs-gui: built with `cargo install` (needs the pinned Rust); desktop file in
  `/usr/local/share/applications/nmrs.desktop`.
- wmfocus (`$mod+j`): `cargo install --features i3`. Build needs the
  cairo-gobject, fontconfig, freetype and expat headers; without the last two
  its crates build them with cmake. Escape is hard-coded as exit; with
  `--exit-keys` set, a wrong key no longer closes it. Missing font family:
  falls back to the first monospace font.
- tree-sitter CLI: built with cargo; release binaries need glibc 2.39.
- rust-analyzer and rust-src: rustup components of the pinned toolchain. Their
  builds need glibc 2.17 at most and run on AL2 (tested: analysis-stats in the
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
  fedora44 rocky9 al2 al2023`. Snapshots the working tree (uncommitted files
  too) into a git repo mounted at `/src`, runs bootstrap twice with
  `BOOTSTRAP_XORG=1 BOOTSTRAP_DPI_SCALE=1.5`, then `verify.sh`. Log:
  `test/bootstrap/logs/<distro>.log`. Runs take minutes; run in background
  and tail the log. Run one distro at a time with pauses: parallel runs get
  GitHub 403 (rate limit).
- Fast nvim-only container run: `BOOTSTRAP_SKIP` with every step except
  `packages home dotfiles nvim link nvim-plugins`, in image
  `dotfiles-bootstrap-<distro>` (built by `run.sh`), with the snapshot at
  `/src` and test files mounted at another path.
- Unit tests with stubs and fake sysfs: `test/fzf-cache/test.sh`,
  `test/i3status-kb/test.sh`, `test/power-mode/test.sh`,
  `test/system-sleep/power-button-wake.sh`. Add new tests in this style.
- X programs: Xorg dummy driver in a container. i3 bindings: Xvfb + i3 with
  the repo config in a Fedora image, `xdotool key super+j`, then read the
  started program's `/proc/<pid>/cmdline`. `bin/theme light` switches the
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
  switches `us de bone2` in X and on the console (kmscon: `localectl` with
  `de(bone)`).
- Floating windows need `for_window` rules: nmrs (`class`), `blueman-*`,
  copyq (`move position mouse`), arandr and pavucontrol (`instance`).
- No `tray_output`: with `primary`, the tray vanishes when no output is
  primary. i3bar shows the tray on one output only.
- `i3-msg` exec needs one string: `i3-msg -q "exec --no-startup-id nmrs-gui"`.
- `status_command` is `~/bin/i3status-kb`: adds `KB:`, `PWR:` and `☀:` (backlight, `I3STATUS_KB_SYSFS` for tests) blocks and
  click handling around i3status.
- lightdm on Fedora/EL does not source `~/.xprofile`; the xinitrc.d hook does.
- Key repeat is set in `xorg-conf/50-keyboard-repeat.conf`; `xset r rate` does
  not reach the xremap device.
- Idle: `.xprofile` sources `~/.config/idle.conf` (written from the
  `IDLE_*` settings), runs `xss-lock` (`pwr lock --nofork`) and `xautolock`
  (`-detectsleep`) for suspend. autorandr runs before i3.
- `pwr lock|sleep|hibernate|performance|balanced|battery|mode`. Modes use
  busctl `org.freedesktop.UPower.PowerProfiles` (tuned-ppd).
  `power-mode-auto` selects performance on AC and battery on battery.
- Sleep hook: only LNXPWRBN, PNP0C0C, intel-hid and intel-vbtn may wake.
  Fedora hibernation: zram swap only, and Secure Boot lockdown blocks it.

## tmux and wezterm

- tmux: one config per tmux version; a version bump needs a new
  `tmux/tmux_linux_<ver>/` directory. `prefix T` runs
  `.tmux/custom/toggle-dark-mode`. tpm is pinned (`TPM_REF`); a failed plugin
  install only warns (`prefix I` in tmux).
- wezterm: Xorg only, rolling nightly (GitHub `.deb` on Debian/Ubuntu, COPR on
  Fedora/EL). It reads the DPI from `~/.Xresources`.
- nvim, tmux and wezterm all use Solarized dark and light. Keep their colors
  the same. nvim has `EnableDarkMode()` and `EnableLightMode()`.
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
