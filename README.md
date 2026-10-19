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
the keyboard layout (`us`, `de`, `bone2`). The script asks for a display scale
(1x, 1.5x, 1.75x, 2x) and renders `~/.Xresources` with the matching `Xft.dpi`;
set `BOOTSTRAP_DPI_SCALE` to skip the prompt. Start with `startx`.

Test in Docker: `test/bootstrap/run.sh [debian12|ubuntu2204|fedora44|rocky9|al2|al2023]`.


### Quick Init on ephemeral Linux machines (bash + vim only)

```
curl -SsL "https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master/init.sh" | bash
```
