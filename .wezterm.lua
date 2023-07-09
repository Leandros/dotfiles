-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

config.disable_default_key_bindings = true
config.use_dead_keys = false
config.enable_csi_u_key_encoding = true -- not sure if required ..
config.send_composed_key_when_left_alt_is_pressed = true -- Required to enable Bone2 layout

-- TODO: Fix input in neovim when <Option> <Space> are pressed.

local act = wezterm.action
config.keys = {
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
}


-- Font
config.font = wezterm.font_with_fallback {
    'PragmataPro Mono Liga',
    -- We swap the patched and non-patched font around, otherwise some things are
    -- not correctly displayed, such as: ']]' (two ] ] (without space)).
    'PragmataProMonoLiga Nerd Font',
    'Apple Color Emoji',
}

-- For example, changing the color scheme:
config.color_scheme = 'Solarized Dark (Gogh)'
-- config.color_scheme = 'Solarized (dark) (terminal.sexy)'
-- config.color_scheme = 'Solarized (light) (terminal.sexy)'

-- and finally, return the configuration to wezterm
return config
