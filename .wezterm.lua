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

-- Font
config.font = wezterm.font('PragmataProMonoLiga Nerd Font')

-- For example, changing the color scheme:
config.color_scheme = 'Solarized Dark (Gogh)'
-- config.color_scheme = 'Solarized (dark) (terminal.sexy)'
-- config.color_scheme = 'Solarized (light) (terminal.sexy)'

-- and finally, return the configuration to wezterm
return config
