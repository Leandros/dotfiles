# Installed by bootstrap.sh into /etc/X11/xinit/xinitrc.d/.
# Fedora's Xsession, lightdm's session wrapper, sources this directory but
# not ~/.xprofile. startx reads ~/.xinitrc instead, which sources
# ~/.xprofile itself and skips this directory, so it never runs twice.
# lightdm runs Wayland sessions (sway) through Xsession too; ~/.xprofile is
# for X sessions only.
# shellcheck shell=sh source=/dev/null
[ "${XDG_SESSION_TYPE:-}" = wayland ] || { [ -r "$HOME/.xprofile" ] && . "$HOME/.xprofile"; }
