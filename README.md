dotfiles
========

My dotfiles

### Fonts

All fonts are patched to work with powerline / airline.


### Bootstrap a new machine

Debian 12+, Ubuntu 22.04+, Fedora 41+, RHEL 9+ and clones (Rocky, Alma,
CentOS Stream), Amazon Linux 2 / 2023 (x86_64, aarch64), macOS (Apple Silicon):

```
curl -fsSLo bootstrap.sh "https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master/bootstrap.sh" && \
    chmod +x ./bootstrap.sh && \
    ./bootstrap.sh
```

Set `BOOTSTRAP_XORG=1` to also bootstrap Xorg.

Download first; piping into `bash` leaves prompts (sudo password, dpkg
dialogs) reading from the script and the script refuses to run.

Installs pinned tool versions to `/usr/local`, clones this repository to
`~/.dotfiles`, and symlinks the configs. Safe to re-run; versions are pinned
at the top of `bootstrap.sh`.

For an Xorg/i3 desktop (Debian, Ubuntu, Fedora, RHEL 9) run with `BOOTSTRAP_XORG=1`;
this installs i3, i3status, dmenu, the wezterm nightly and the X utilities
and links `.xinitrc`, `.xprofile`, `.Xresources`, `.Xmodmap`,
`.wezterm.lua`, `.config/i3` and `.config/i3status`, plus `~/bin/kb` to switch
the keyboard layout (`us`, `de`, `bone2`) in X and on the Linux console; the
i3 bar shows the layout and cycles it on click (left: next, right: previous), the
screen brightness (`☀: 65%`) and CPU and RAM use (`C: 12% R: 40%`); a click on
the volume block opens pavucontrol to pick the audio input and output.
`~/bin/theme dark|light|toggle` switches i3 between Solarized dark and light and
sets the desktop color-scheme that Firefox follows and the GTK 3/4 dark preference
(dark by default; GTK apps pick it up when they start). `~/bin/flightmode on`
blocks all radios with rfkill and selects the battery power mode; `off` undoes both.
Touchpads work as on macOS (`xorg-conf/40-touchpad.conf`): press to click, two-finger
click for right click, and a macOS-like acceleration curve; `~/bin/touchpad tap|click`
switches tap-to-click until logout. `~/bin/charge full` lets the battery charge to
100% through UPower's charge limit; `charge limit` goes back to 80%.
`~/bin/caffeinate` keeps the machine from suspending on idle until Ctrl-C;
`caffeinate display` also keeps the screen on and unlocked. `~/bin/smb` scans the
local /24 for SMB servers, lists their shares and mounts the chosen one under `~/mnt`. The
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
Media keys (volume, mute, screen brightness) are bound in i3 only; check with `test/media-keys/test.sh`.


### Quick Init on ephemeral Linux machines (bash + vim only)

```
curl -SsL "https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master/init.sh" | bash
```
