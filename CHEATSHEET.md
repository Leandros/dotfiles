# Cheat sheet

Letters are keys of the active layout, bone2 after login. `b n r s` (left,
down, up, right) are on the keys labeled `h j k l` on QWERTY. i3, tmux and
Neovim use them the same way.

## Modifiers

In X, xremap swaps the left Alt and Ctrl keys. Right modifiers do not change.

| Sheet | Physical key |
|---|---|
| `Mod` | Win |
| `Ctrl` | left Alt, next to Space |
| `Alt` | left Ctrl, in the corner |

## i3

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
| `Mod+j` | Label every window; type a label (`n r s g b e i t c o`) to focus it, `Escape` cancels |

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
| Bar `♪` block, left click | Audio devices and app streams (pavucontrol) |
| Bar tray | Bluetooth (blueman), clipboard (CopyQ) |

### Hardware keys

| Key | Action |
|---|---|
| Volume up / down | +5% / -5% |
| Mute | Mute on/off |
| Mic mute | Selected microphone mute on/off |
| Display | Monitor layout (arandr) |
| Brightness up / down | Screen brightness |
| Keyboard light up / down | Keyboard backlight |

### Commands without a key

| Command | Action |
|---|---|
| `pwr lock` / `sleep` / `hibernate` | Lock / suspend / hibernate now |
| `pwr performance` / `balanced` / `battery` | Power mode (Fedora/EL) |
| `kb us` / `de` / `bone2` | Keyboard layout |
| `touchpad tap` / `click` / `toggle` | Tap to click / press to click (until logout) |
| `caffeinate` / `caffeinate display` | No idle suspend (and no lock or blanking) until Ctrl-C |
| `smb` | Find SMB shares on the network, pick one, mount it at `~/mnt/<host>-<share>` |
| `remmina` | Remote desktop (RDP, VNC, SSH) with saved connections |
| `btop` | CPU, memory, disks, network, temperatures, battery |
| `dua i` | Disk usage, interactive (like WinDirStat) |
| `charge limit` / `full` / `toggle` | Battery charges to 80% / to 100% |
| `flightmode on` / `off` / `toggle` | All radios off and battery power mode / back |
| `theme dark` / `light` / `toggle` | Solarized dark or light: i3 colors, Firefox, GTK apps (on next start) |
| `arandr`, `autorandr --save NAME` | Arrange and save monitor layouts |

## tmux

The prefix is `Ctrl+e`. `Prefix x` means: press `Ctrl+e`, release, press `x`.
`Prefix Ctrl+e` sends `Ctrl+e` to the program.

### Session

| Key | Action |
|---|---|
| `Prefix d` | Detach |
| `Prefix w` | Tree of sessions and windows |
| `Prefix $` | Rename session |
| `Prefix a` | Reload config |
| `Prefix T` | Dark / light status bar |
| `Prefix :` | Command prompt |
| `Prefix ?` | List all keys |

### Windows

| Key | Action |
|---|---|
| `Prefix c` | New window in the current directory |
| `Prefix Ctrl+b` / `Ctrl+s` | Previous / next window, repeatable |
| `Prefix l` | Last window |
| `Prefix 1` ... `9` | Window 1 ... 9 |
| `Prefix >` / `<` | Move window left / right, repeatable |
| `Prefix U` | Swap window with window 1 |
| `Prefix ,` | Rename window |
| `Prefix &` | Close window (asks first) |

### Panes

| Key | Action |
|---|---|
| `Prefix i` | Split, new pane on the right |
| `Prefix t` | Split, new pane below |
| `Prefix b` / `n` / `r` / `s` | Focus left / down / up / right |
| `Prefix arrow` | Same with arrow keys |
| `Prefix B` / `N` / `R` / `S` | Resize by 10 to the left / down / up / right |
| `Prefix q` | Show pane numbers until a key press; a digit selects |
| `Prefix o` / `;` | Next / last pane |
| `Prefix z` | Zoom on/off |
| `Prefix {` / `}` | Swap with previous / next pane |
| `Prefix Space` | Next layout |
| `Prefix !` | Move pane to a new window |
| `Prefix x` | Close pane (asks first) |

### Copy mode

`Prefix [`, `Prefix PageUp` or the mouse wheel starts copy mode. `q` stops it.

| Key | Action |
|---|---|
| `b` / `n` / `r` / `s` | Cursor left / down / up / right |
| `N` / `R` | Scroll one line down / up |
| `(` / `)` | Page down / up |
| `B` / `S` | Previous / next word |
| `e` | End of word |
| `g` / `G` | Top / bottom of history |
| `f` | Search down (prompt) |
| `/` | Search up (prompt) |
| `?` / `-` | Next / previous match; no wrap at the end |
| `v` / `V` / `Ctrl+v` | Select characters / lines / block |
| `y` | Copy, stay in copy mode |
| `Y` or `Enter` | Copy and stop copy mode |
| `Prefix ]` | Paste |

Copies also reach the clipboard of the local terminal (OSC 52), through SSH
and mosh too.

### Mouse

| Input | Action |
|---|---|
| Click | Focus pane |
| Drag border | Resize pane |
| Wheel | Scroll (starts copy mode) |
| Drag | Select and copy |

## Neovim

`Space` is the leader key. `Space ff` means: press `Space`, `f`, `f`.
which-key shows the possible next keys after a short wait.

### Motions

| Key | Action |
|---|---|
| `b` / `n` / `r` / `s` | Left / down / up / right |
| `gn` / `gr` | Down / up by screen line |
| `B` / `S` | Previous / next word start |
| `w` | Next word end |
| `(` / `)` | Half page down / up |
| `N` / `R` | Scroll one line down / up |
| `t` | Jump: type characters, then the label (flash) |
| `T` | Search, then select the Treesitter node of a match (flash) |
| `f` / `F` / `;` | Find character forward / backward / again (flash) |
| `z(` / `z)` | Next / previous fold |

### Search and jumps

| Key | Action |
|---|---|
| `?` / `-` | Next / previous match, centered |
| `Ctrl+d` | Clear search highlight |
| `Ctrl+o` | Older cursor position |
| `Space h` / `Space l` | Older / newer cursor position |
| `Space gh` / `Space gl` | Same, in this buffer only |
| `g;` / `g,` | Older / newer change |
| `Space .` | Back in the tag stack |

### Editing

| Key | Action |
|---|---|
| `u` / `j` | Undo / redo |
| `d` `D` `c` `C` | Delete / change; registers and clipboard do not change |
| `x` (visual) | Cut |
| `y` / `Y` | Copy / copy to end of line |
| `Alt+p` / `Alt+P` | After a paste: use the older / newer copy instead |
| `"` / `@` | Show registers before use (peekaboo) |
| `<` / `>` (visual) | Indent, keep the selection |
| `Ctrl+a` / `Ctrl+x` | Increment / decrement number or date |
| `ga` + motion | Align (EasyAlign) |
| `gc` + motion, `gcc` | Comment on/off; `gcc` for one line |
| `ys` + motion + char, `yss` + char | Add surround; `yss` for the line |
| `cs` + old + new, `ds` + char | Change / delete surround |
| `gS` + char (visual) | Surround the selection |
| `ge` + `c` `p` `s` `d` `n` `l` `u` | Word to camelCase / PascalCase / snake_case / dash-case / CONSTANT_CASE / lower / UPPER |
| `geo` + letter + motion | Same, as an operator |
| `ge` + upper-case letter | Same, as an LSP rename |
| `ge.` | Pick the case from a list |
| `Ctrl+a` (insert) | Insert a register (`Ctrl+r`) |
| `Ctrl+f` | Format the file (visual: selection, C family only) |
| `:w!!` | Write with sudo |

### Multiple cursors

| Key | Action |
|---|---|
| `Ctrl+g` | Select word under cursor; again: add next match |
| `Ctrl+h` / `Ctrl+l` | Add cursor down / up |

With cursors active:

| Key | Action |
|---|---|
| `h` / `l` | Add next / previous match |
| `]` / `[` | Go to next / previous cursor |
| `q` / `Q` | Skip / remove current cursor |
| `u` / `j` | Undo / redo |
| `Ctrl+a` / `Ctrl+x` | Same increment at every cursor |
| `g Ctrl+a` / `g Ctrl+x` | Sequence: first cursor stays, next +1, +2, ... |
| `Enter` | Multi-cursor keys on/off |
| `Ctrl+c` | Stop |

### Windows and tabs

| Key | Action |
|---|---|
| `Ctrl+i` / `Ctrl+t` | Split side by side / one above the other |
| `Ctrl+b` / `n` / `r` / `s` | Focus left / down / up / right |
| `Ctrl+p` | Focus next window |
| `Ctrl+w B` / `N` / `R` / `S` | Move window to the far left / bottom / top / right |
| `!` / `=` | Width -5 / +5 |
| `<` / `>` | Height +5 / -5 |
| `Ctrl+y w` | All windows equal size |
| `Ctrl+y m` | Maximum height |
| `Ctrl+y t` | Move window to a new tab |
| `Space ,` / `Ctrl+y l` | Zoom on/off |
| `Space m`, then `Space u` | Swap two windows: mark one, swap from the other |
| `Ctrl+q` | Close buffer, keep window |
| `Space w` | Close all other buffers |
| `Ctrl+u n` / `Ctrl+u c` | New / close tab |
| `Ctrl+u b` / `Ctrl+u s` | Previous / next tab |
| `Space 1` ... `9` | Tab 1 ... 9 |

### Files

| Key | Action |
|---|---|
| `Space e` | File tree on/off |
| `Space ff` / `Space o` | Find files (Telescope / LeaderF) |
| `Space z` | Recent files in this directory |
| `Space fb` / `Space bb` | Open buffers (Telescope / LeaderF) |
| `Space fg` | Grep; the prompt takes rg arguments |
| `Space fs` | Search in this buffer |
| `Space fh` | Help |
| `Space fm` | Marks |
| `Space fn` | Open the last picker again |
| `Space p` | Clipboard history |
| `,cd` | Change directory to the file's directory |

### File tree

Opening a file closes the tree. With more than one window, letters mark the
windows and their borders: a window letter opens the file there, a border
letter opens a new split at that border.

| Key | Action |
|---|---|
| `Enter` / `o` | Open |
| `Tab` | Preview |
| `Ctrl+v` / `Ctrl+x` / `Ctrl+t` | Open in vertical split / horizontal split / tab |
| `e` | Show the file of the last buffer |
| `C` / `u` | Directory as root / root one level up |
| `P` / `Backspace` | Go to parent / close directory |
| `a` | Create (end with `/` for a directory) |
| `R` | Rename |
| `d` / `D` | Delete / move to trash |
| `x` / `c` / `p` | Cut / copy / paste |
| `y` / `Y` / `gy` | Copy name / relative path / absolute path |
| `H` / `I` | Dotfiles / gitignored files on/off |
| `f` / `F` | Filter / clear filter |
| `W` / `E` | Collapse / expand all |
| `[c` / `]c` | Previous / next Git change |
| `Ctrl+a` | Refresh |
| `s` | Open with the system program |
| `q` | Close |
| `g?` | All keys |

### LSP

| Key | Action |
|---|---|
| `K` | Documentation (Rust: with actions) |
| `Ctrl+k` | Signature (normal and insert mode) |
| `Ctrl+]` | Go to definition |
| `Space ca` | Code actions (visual: for the selection) |
| `Space re` | Rename |
| `Space gr` / `Space gi` / `Space gt` | List references / implementations / type definitions |
| `Space gg` / `Space ge` | Symbols in file / workspace |
| `Space v` | Treesitter symbols |
| `Space sP` | Highlight groups under the cursor |
| `Space dv` | Documentation in a split; follows the cursor |
| `Space t` | Symbol tree (Navbuddy) |
| `Space dd` / `dy` / `di` / `dg` / `dr` | Preview definition / type / implementation / declaration / references |
| `Space dq` | Close all previews |
| `Space gs` | Switch source / header (C, C++) |

### Diagnostics and quickfix

| Key | Action |
|---|---|
| `Space k` | Diagnostics of this line |
| `[e` / `]e` | Next / previous diagnostic |
| `]d` / `[d` | Next / previous diagnostic |
| `Space gn` / `Space gd` | List diagnostics of file / workspace |
| `Space xd` | Diagnostics list on/off (Trouble) |
| `Space dt` | Diagnostics on/off |
| `Space q` | Quickfix list on/off |
| `>` / `<` (quickfix) | More / less context lines |
| `]q` / `[q` | Next / previous quickfix entry |

In the Trouble list:

| Key | Action |
|---|---|
| `n` / `r` | Next / previous item |
| `Enter` | Go to item / fold file |
| `o` | Go to item, close the list |
| `Ctrl+i` / `Ctrl+t` | Open item side by side / one above the other |
| `p` / `P` | Preview / automatic preview on/off |
| `s` | Severity filter |
| `A` | Refresh |
| `?` | All keys |
| `q` | Close |

### Completion and snippets

Insert mode.

| Key | Action |
|---|---|
| `Ctrl+n` | Open menu / next item |
| `Ctrl+r` | Previous item |
| `Tab` / `Shift+Tab` | Next / previous item or snippet field |
| `Enter` | Accept the selected item |
| `Ctrl+j` | Close menu |
| `Ctrl+,` / `Ctrl+.` | Scroll documentation |
| `Ctrl+s` | Expand snippet or go to next field |

### Git

Signs: `│` unstaged, `▌` staged.

| Key | Action |
|---|---|
| `Space sn` / `Space sr` | Next / previous hunk |
| `Space sp` | Preview hunk |
| `Space ss` | Stage hunk (visual: lines) |
| `Space su` | Undo last stage |
| `Space sa` | Reset hunk (visual: lines) |
| `Space sS` / `Space sU` | Stage / unstage file |
| `Space sA` | Reset file |
| `Space sb` | Blame line |
| `Space sB` / `Space sH` | Blame file / file at HEAD |
| `Space sd` | Panel of changed files |
| `Space sg` | All gitsigns actions |
| `:Neogit` | Git status buffer |

Panel of changed files (`Space sd`):

| Key | Action |
|---|---|
| `Enter` | Open file / fold directory |
| `Shift+Enter` | Open file, stay in the panel |
| `]f` / `[f` | Next / previous file, also from the file window |
| `-` / `s` / `u` | Toggle / stage / unstage file or directory |
| `o` / `O` | Show file / base version in a tab |
| `gu` | Unified diff on/off |
| `g?` | All keys |
| `q` | Close |

In the blame window, `Ctrl+r` blames again at the commit of the line.

Neogit status buffer:

| Key | Action |
|---|---|
| `n` / `r` | Down / up |
| `Tab` | Fold on/off |
| `s` / `u` | Stage / unstage |
| `S` / `U` | Stage all unstaged / unstage all staged |
| `x` | Discard |
| `Enter` | Open file |
| `c` / `P` / `p` / `f` | Commit / push / pull / fetch |
| `b` / `m` / `Z` | Branch / merge / stash |
| `l` / `d` | Log / diff |
| `?` | All keys |
| `q` | Close |

In the Neogit rebase editor, `gr` / `gn` move a commit up / down.

### Debugger

| Key | Action |
|---|---|
| `Space bl` | Launch |
| `Space bc` / `F5` | Continue (`F5` also launches) |
| `F6` | Pause |
| `Space bd` / `F3` | Stop |
| `Space bz` / `F4` | Restart |
| `Space bq` | Reset, close the debugger windows |
| `Space br` / `F9` | Breakpoint on/off |
| `Space F9` | Conditional breakpoint |
| `F8` | Function breakpoint |
| `Space bt` / `Space F8` | Run to cursor |
| `Space bn` / `F10` | Step over |
| `Space bsi` / `F11` | Step into |
| `Space bso` / `F12` | Step out |
| `Space be` / `Space bw` | Evaluate / watch an expression |
| `Space bi` | Value under cursor (visual: selection) |
| `Space bo` | Output |
| `Space ab` | All debugger actions |

### Tests

| Key | Action |
|---|---|
| `Space xx` / `Space xa` | Run nearest test / file |
| `Space xw` | Attach to the running test |
| `Space xo` | Output of the test |
| `Space xp` / `Space xq` | Output panel on/off / clear |

### Terminal

These also work in a terminal window, except `,t` and `,i`.

| Key | Action |
|---|---|
| `,a` | New floating terminal |
| `,n` | Show / hide terminal |
| `,b` / `,s` | Previous / next terminal |
| `,q` / `,Q` | Hide / close terminal |
| `,t` / `,i` | New terminal in a horizontal / vertical split |
| `,e` | Go to the next window |
| `,d` | Normal mode (terminal only) |
| `,,` | Type `,` (terminal only) |

### Bookmarks

| Key | Action |
|---|---|
| `mm` / `mi` | Bookmark on/off / with a note |
| `mn` / `mr` | Next / previous |
| `ma` | List all bookmarks |
| `mA` | List Vim marks (Telescope) |
| `md` / `mx` | Clear in buffer / everywhere |
| `mh` / `ml` / `mg` | Move bookmark up / down / to line |

### Comments

| Key | Action |
|---|---|
| `Space ng` / `nf` / `nc` | Doc comment for function / file / class |
| `Space cb` / `cbl` / `cbs` | Title box: heavy / left / light |
| `Space ct` / `ctl` | Title line: centered / left |
| `Space cl` | Line |
| `Space cm` | Box around the text |
| `Space cx` | Remove box |

### Cargo.toml

| Key | Action |
|---|---|
| `Space cv` / `cf` / `cd` | Crate versions / features / dependencies |

In the popup: `Enter` selects or toggles, `Ctrl+n` / `Ctrl+r` go forward /
back, `yy` copies, `q` closes.

### Pickers

Telescope:

| Key | Action |
|---|---|
| `Ctrl+n` / `Ctrl+r` | Next / previous |
| `Enter` | Open |
| `Ctrl+x` / `Ctrl+v` / `Ctrl+t` | Open in split / vertical split / tab |
| `Ctrl+q` | All results to quickfix |
| `Ctrl+k` / `Ctrl+i` (grep) | Quote the prompt / quote and add `--iglob` |
| `Esc` | Close |

LeaderF:

| Key | Action |
|---|---|
| `Ctrl+n` / `Ctrl+r` | Next / previous |
| `Ctrl+e` | Fuzzy / regex search |
| `Ctrl+t` / `Ctrl+i` / `Ctrl+x` | Open in split / vertical split / tab |
| `Ctrl+d` | Clear selections |
| `Ctrl+z` | Refresh file list |
| `Esc` | Close |

Navbuddy (`Space t`):

| Key | Action |
|---|---|
| `n` / `r` | Next / previous symbol |
| `b` / `s` | Parent / children |
| `Enter` / `o` | Go to symbol |
| `v` / `V` | Select name / scope |
| `y` / `Y` | Copy name / scope |
| `i` / `a` | Insert at start / end of name |
| `x` / `d` / `c` | Rename / delete / comment scope |
| `N` / `R` | Move symbol down / up |
| `t` | Search |
| `g?` | All keys |
| `q` / `Esc` | Close |

### Commands

| Command | Action |
|---|---|
| `:StripWhitespace` / `:StripAnsi` | Remove trailing spaces / ANSI colors |
| `:JsonMinify` | Remove spaces and line breaks |
| `:Shell cmd` / `:Make args` | Output of `cmd` / `make` in a split |
| `:EnableDarkMode` / `:EnableLightMode` | Color mode |
| `:MarkWindowSwap`, then `:DoWindowSwap` | Swap two windows |
| `:CloseAllFloatingWindows` | Close popups |
| `:RefreshLSP` / `:LspStopAll` | Restart / stop all language servers |
| `:CargoReload` | Reload the Cargo workspace (rust-analyzer) |
| `:RebuildRustWorkspace` | Reload the Cargo workspace and rebuild proc macros (Rust buffers) |
| `:NvimTreeKeepLayoutToggle` | Keep the split sizes around the tree on/off |
| `:Lazy` | Plugins; `gr` resets a plugin to the lock file |
