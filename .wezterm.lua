-- Pull in the wezterm API
local wezterm = require 'wezterm'

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- Hyperlinks:
--
-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Tabbar:
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.window_frame = {
    font = wezterm.font_with_fallback {
        'PragmataPro Mono Liga',
        -- We swap the patched and non-patched font around, otherwise some things are
        -- not correctly displayed, such as: ']]' (two ] ] (without space)).
        'PragmataProMonoLiga Nerd Font',
        'Apple Color Emoji',
    },
    font_size = 14.0,
}

-- Keybindings:
config.disable_default_key_bindings = true
config.use_dead_keys = false
config.enable_csi_u_key_encoding = true -- not sure if required ..
config.send_composed_key_when_left_alt_is_pressed = true -- Required to enable Bone2 layout
config.send_composed_key_when_right_alt_is_pressed = true -- Required to enable Bone2 layout

-- TODO: Fix input in neovim when <Option> <Space> are pressed.

local act = wezterm.action
local general_keys = {
    { key = '1', mods = 'SUPER', action = act.ActivateTab(0) },
    { key = '2', mods = 'SUPER', action = act.ActivateTab(1) },
    { key = '3', mods = 'SUPER', action = act.ActivateTab(2) },
    { key = '4', mods = 'SUPER', action = act.ActivateTab(3) },
    { key = '5', mods = 'SUPER', action = act.ActivateTab(4) },
    { key = '6', mods = 'SUPER', action = act.ActivateTab(5) },
    { key = '7', mods = 'SUPER', action = act.ActivateTab(6) },
    { key = '8', mods = 'SUPER', action = act.ActivateTab(7) },
    { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) },

    { key = 't', mods = 'SUPER', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w', mods = 'SUPER', action = act.CloseCurrentTab{ confirm = true } },
    { key = 'n', mods = 'SUPER', action = act.SpawnWindow },
    { key = 'q', mods = 'SUPER', action = act.QuitApplication },
    { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },

    { key = 'c', mods = 'SUPER|SHIFT', action = act.CopyTo 'ClipboardAndPrimarySelection', },
    { key = 'v', mods = 'SUPER|SHIFT', action = act.PasteFrom 'Clipboard' },

    { key = 'c', mods = 'SUPER', action = act.CopyTo 'ClipboardAndPrimarySelection', },
    { key = 'v', mods = 'SUPER', action = act.PasteFrom 'Clipboard' },

    -- We need to rebind OPT + Space otherwise odd things are happenings:
    { key = ' ', mods = 'OPT', action = act.SendKey { key = ' ' } },
}

-- Tmux Replacement:
local tmux_keys_enabled = false
local tmux_keys = {}
if tmux_keys_enabled then
    config.leader = { key = 'e', mods = 'CTRL', timeout_milliseconds = 1000 }
    tmux_keys = {
        { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
        { key = 'i', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 't', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = 'b', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
        { key = 's', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
        { key = 'n', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
        { key = 'r', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },

        { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
        { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
        { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
        { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
        { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
        { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
        { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
        { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
        { key = '9', mods = 'LEADER', action = act.ActivateTab(-1) },

        { key = 'B', mods = 'LEADER', action = act.AdjustPaneSize{'Left', 10} },
        { key = 'S', mods = 'LEADER', action = act.AdjustPaneSize{'Right', 10} },
        { key = 'N', mods = 'LEADER', action = act.AdjustPaneSize{'Down', 10} },
        { key = 'R', mods = 'LEADER', action = act.AdjustPaneSize{'Up', 10} },

        { key = 't', mods = 'LEADER|CTRL', action = act.QuickSelect },
        { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },

        { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
    }
end

-- Set keys:
config.keys = TableConcat(general_keys, tmux_keys)

-- Font
config.font = wezterm.font_with_fallback {
    {
        family = 'PragmataPro Mono Liga',
        weight = 'Regular',
        -- available features in PragmataPro: `calt` ligatures.
        -- `ss13` is git tree
        harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0', 'ss13=1' },
    },
    -- We swap the patched and non-patched font around, otherwise some things are
    -- not correctly displayed, such as: ']]' (two ] ] (without space)).
    -- Further, the sizes of the glyphs is off when the patched font is used.
    -- {
    --     family = 'PragmataProMonoLiga Nerd Font',
    --     weight = 'Regular',
    --     -- available features in PragmataPro: `calt` ligatures.
    --     harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
    -- },
    'Apple Color Emoji',
}
config.bold_brightens_ansi_colors = 'BrightAndBold'
config.font_size = 14.0
config.allow_square_glyphs_to_overflow_width = 'Never'

-- Disable on newest nightlies (from 20230712-072601-f4abf8fd)
-- config.anti_alias_custom_block_glyphs = false
-- config.freetype_load_target = 'Light'
-- config.freetype_render_target = 'HorizontalLcd'

local base03  = '#002b36'
local base02  = '#073642'
local base01  = '#586e75'
local base00  = '#657b83'
local base0   = '#839496'
local base1   = '#93a1a1'
local base2   = '#eee8d5'
local base3   = '#fdf6e3'
local yellow  = '#b58900'
local orange  = '#cb4b16'
local red     = '#dc322f'
local magenta = '#d33682'
local violet  = '#6c71c4'
local blue    = '#268bd2'
local cyan    = '#2aa198'
local green   = '#859900'

-- Fixing the theme.
local dark_scheme = wezterm.color.get_builtin_schemes()['Solarized Dark (Gogh)']
dark_scheme.foreground = base0
dark_scheme.background = base03
dark_scheme.cursor_bg = base1
dark_scheme.cursor_border = base1
dark_scheme.cursor_fg = base03
dark_scheme.selection_bg = base3
dark_scheme.selection_fg = base01

dark_scheme.ansi = {
    base02,  -- black
    red,     -- red
    green,   -- green
    yellow,  -- yellow
    blue,    -- blue
    magenta, -- magenta
    cyan,    -- cyan
    base3,   -- white
}

-- brights are just bold ...
dark_scheme.brights = {
    base02,  -- black
    red,     -- red
    green,   -- green
    yellow,  -- yellow
    blue,    -- blue
    magenta, -- magenta
    cyan,    -- cyan
    base3,   -- white
}
-- original:
--dark_scheme.brights = {"#002b36","#cb4b16","#586e75","#657b83","#839496","#6c71c4","#93a1a1","#fdf6e3"}
-- from solarized site:
--dark_scheme.brights = {base03, orange, base01, base00, base0, violet, base1, base3}

local light_scheme = wezterm.color.get_builtin_schemes()['Solarized Light (Gogh)']
light_scheme.foreground = base00
light_scheme.background = base3
light_scheme.cursor_bg = base01
light_scheme.cursor_border = base01
light_scheme.cursor_fg = base3
light_scheme.selection_bg = base03
light_scheme.selection_fg = base1

light_scheme.ansi = {
    base2,   -- black
    red,     -- red
    green,   -- green
    yellow,  -- yellow
    blue,    -- blue
    magenta, -- magenta
    cyan,    -- cyan
    base3,   -- white
}
-- omitted:
-- brights = ["#002b36","#cb4b16","#586e75","#657b83","#839496","#6c71c4","#93a1a1","#fdf6e3"]

config.color_schemes = {
    ['Solarized Dark'] = dark_scheme,
    ['Solarized Light'] = light_scheme,
}
config.color_scheme = 'Solarized Dark'

-- and finally, return the configuration to wezterm
return config
