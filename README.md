dotfiles
========

My dotfiles

### Fonts

All fonts are patched to work with powerline / airline.


### Bootstrap a new machine

Debian 12+, Ubuntu 22.04+, Fedora 41+, RHEL 9+ and clones (Rocky, Alma,
CentOS Stream), Amazon Linux 2 / 2023 (x86_64, aarch64), macOS (Apple Silicon):

```
curl -fsSLo bootstrap.sh "https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master/bootstrap.sh"
bash bootstrap.sh
```

Download first; piping into `bash` leaves prompts (sudo password, dpkg
dialogs) reading from the script and the script refuses to run.

Installs pinned tool versions to `/usr/local`, clones this repository to
`~/.dotfiles`, and symlinks the configs. Safe to re-run; versions are pinned
at the top of `bootstrap.sh`.

For an Xorg/i3 desktop (Debian, Ubuntu, Fedora, RHEL 9) run with `BOOTSTRAP_XORG=1`;
this installs i3, i3status, dmenu, xbindkeys, the wezterm nightly and the X utilities
and links `.xinitrc`, `.xprofile`, `.Xresources`, `.Xmodmap`, `.xbindkeysrc`,
`.wezterm.lua`, `.config/i3` and `.config/i3status`, plus `~/bin/kb` to switch
the keyboard layout (`us`, `de`, `bone2`) in X and on the Linux console; the
i3 bar shows the layout and cycles it on click (left: next, right: previous). The
console bone2 keymap is `console/bone2.map`, generated from `.Xmodmap` with
`console/xmodmap-to-console.py`; regenerate it when `.Xmodmap` changes. On a
kmscon console (Fedora 45+) `kb` sets the layout through `localectl` instead,
with the stock `de(bone)` variant standing in for bone2. In X,
`xremap` (started from `.xprofile`, config `.config/xremap/config.yml`) swaps the
left Alt and Ctrl keys for every layout: Alt acts as Ctrl, Ctrl as Alt, and
Alt+digit still switches the i3 workspace; i3 itself is driven with the Win key.
The bootstrap adds the user to the `input` group, which needs a new login. The script asks for a display scale
(1x, 1.5x, 1.75x, 2x) and renders `~/.Xresources` with the matching `Xft.dpi`;
the same scale picks the console font at boot (Terminus 16/24/28/32 px via
`console-setup` or `/etc/vconsole.conf`, and `font-size` in
`/etc/kmscon/kmscon.conf`). Set `BOOTSTRAP_DPI_SCALE` to skip the prompt. Start with `startx`.

Test in Docker: `test/bootstrap/run.sh [debian12|ubuntu2204|fedora44|rocky9|al2|al2023]`.


### Quick Init on ephemeral Linux machines (bash + vim only)

```
curl -SsL "https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master/init.sh" | bash
```
