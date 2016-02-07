#!/bin/sh

! Custom keyboard layout
xmodmap $HOME/.Xmodmap

! Window manager, always last
exec i3
