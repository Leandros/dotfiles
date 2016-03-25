#!/bin/sh

# Custom keyboard layout
xmodmap $HOME/.Xmodmap

# Custom Media keys
xbindkeys -p

# Key Repeat: xset r rate <delay before repeat> <repeat rate>
xset r rate 300 50

# Window manager, always last
exec i3
