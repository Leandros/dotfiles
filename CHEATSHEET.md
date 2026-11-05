# Cheat sheet

## i3

Letters are keys of the active layout, bone2 after login. `b n r s` (left,
down, up, right) are on the keys labeled `h j k l` on QWERTY.

### Modifiers

xremap swaps the left Alt and Ctrl keys. Right modifiers do not change.

| Sheet | Physical key |
|---|---|
| `Mod` | Win |
| `Ctrl` | left Alt, next to Space |
| `Alt` | left Ctrl, in the corner |

### Programs

| Key | Action |
|---|---|
| `Mod+Return` | Terminal (wezterm) |
| `Mod+i` | Program menu (i3-dmenu-desktop) |
| `Mod+c` | Clipboard history (CopyQ), at the pointer |
| `Mod+Shift+j` | Close window |

### Focus and move

| Key | Action |
|---|---|
| `Mod+b` / `n` / `r` / `s` | Focus left / down / up / right |
| `Mod+Shift+b` / `n` / `r` / `s` | Move window left / down / up / right |
| `Mod+arrow`, `Mod+Shift+arrow` | Same with arrow keys |
| `Mod+h` / `Mod+l` | Focus parent / child container |
| `Mod+space` | Focus between tiling and floating windows |

### Layout

| Key | Action |
|---|---|
| `Mod+v` | Next window opens to the right |
| `Mod+f` | Next window opens below |
| `Mod+e` | Fullscreen on/off |
| `Mod+t` | Stacked layout |
| `Mod+d` | Tabbed layout |
| `Mod+u` | Split layout, toggle direction |
| `Mod+Shift+space` | Floating on/off |

### Workspaces

| Key | Action |
|---|---|
| `Mod+1` ... `Mod+0` | Go to workspace 1 ... 10 |
| `Mod+Shift+1` ... `Mod+Shift+0` | Move window to workspace 1 ... 10 |
| `Ctrl+digit`, `Ctrl+Shift+digit` | Same as `Mod` (physical left Alt; xremap) |

### Scratchpad

| Key | Action |
|---|---|
| `Mod+Shift+z` | Move window to the scratchpad |
| `Mod+z` | Show / hide / cycle scratchpad windows |

### Resize mode

`Mod+a` starts resize mode. `Return` or `Escape` stops it.

| Key | Action |
|---|---|
| `b` / `s` | Width -10 / +10 |
| `r` / `n` | Height -10 / +10 |
| arrows | Same |

### Session

| Key | Action |
|---|---|
| `Mod+Shift+w` | Reload config |
| `Mod+Shift+a` | Restart i3, keep the layout |
| `Mod+Shift+u` | Exit i3 (asks first) |
| `Ctrl+Alt+Backspace` | Kill X at once |

### Mouse

| Input | Action |
|---|---|
| `Mod+left drag` | Move floating window |
| `Mod+right drag` | Resize floating window |
| Bar `KB:` left / right click | Next / previous keyboard layout |
| Bar network block, left click | Network settings (nmrs) |
| Bar tray | Bluetooth (blueman), clipboard (CopyQ) |

### Hardware keys

| Key | Action |
|---|---|
| Volume up / down | +5% / -5% |
| Mute | Mute on/off |
| Brightness up / down | Screen brightness |
| Keyboard light up / down | Keyboard backlight |

### Commands without a key

| Command | Action |
|---|---|
| `pwr lock` / `sleep` / `hibernate` | Lock / suspend / hibernate now |
| `pwr performance` / `balanced` / `battery` | Power mode (Fedora/EL) |
| `kb us` / `de` / `bone2` | Keyboard layout |
| `arandr`, `autorandr --save NAME` | Arrange and save monitor layouts |
