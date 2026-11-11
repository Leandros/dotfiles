#!/bin/sh
#
# The session xrdp starts (its startwm.sh runs the distribution's Xsession
# without arguments, which runs this file). Local logins choose i3 at the
# login screen and startx reads ~/.xinitrc; neither runs this.
#
# Fedora's Xsession has loaded ~/.xprofile already (xinitrc.d hook, which
# sets XPROFILE_LOADED); Debian's does not.
# shellcheck source=/dev/null
[ -n "${XPROFILE_LOADED:-}" ] || { [ -f ~/.xprofile ] && . ~/.xprofile; }

exec i3
