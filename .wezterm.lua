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

-- Command palette
config.command_palette_font_size = 11.0

-- Windows specific changes
local ctrlkey
local launch_menu = {}

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  -- Use ctrl over SUPER (which is the WIN key) on Windows only.
  ctrlkey = 'CTRL'
  config.use_ime = false

	table.insert(launch_menu, {
	  label = "Git Bash",
	  args = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login", "-i" },
    domain = { DomainName = 'local' },
  })

  table.insert(launch_menu, {
    label = 'WSL Ubuntu',
    domain = { DomainName = 'WSL:Ubuntu' },
  })

  table.insert(launch_menu, {
    label = 'Command Prompt',
    args = { 'cmd.exe' },
    domain = { DomainName = 'local' },
  })

	table.insert(launch_menu, {
		label = "PowerShell",
		args = { "powershell.exe" },
    domain = { DomainName = 'local' },
	})

  -- Find installed visual studio version(s) and add their compilation
  -- environment command prompts to the menu
  for _, vsvers in
    ipairs(
      wezterm.glob('Microsoft Visual Studio/*', 'C:/Program Files')
    )
  do
    local year = vsvers:gsub('Microsoft Visual Studio/', '')
    table.insert(launch_menu, {
      label = 'x64 Native Tools VS ' .. year,
      args = {
        'cmd.exe',
        '/k',
        'C:/Program Files/Microsoft Visual Studio/'
        .. year
        .. '/Community/Common7/Tools/VsDevCmd.bat',
        '-startdir=none', '-arch=x64', '-host_arch=x64',
      },
      domain = { DomainName = 'local' },
    })
  end

  -- By default, launch in git bash.
	config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login", "-i" }

  -- By default, launch a shell in WSL.
  -- config.default_domain = "WSL:Ubuntu"
else
  ctrlkey = 'SUPER'
end

config.launch_menu = launch_menu

-- Keybindings:
config.disable_default_key_bindings = true
config.use_dead_keys = false
config.enable_csi_u_key_encoding = true -- not sure if required ..
config.send_composed_key_when_left_alt_is_pressed = true -- Required to enable Bone2 layout
config.send_composed_key_when_right_alt_is_pressed = true -- Required to enable Bone2 layout

local act = wezterm.action

local general_keys = {
    { key = '1', mods = ctrlkey, action = act.ActivateTab(0) },
    { key = '2', mods = ctrlkey, action = act.ActivateTab(1) },
    { key = '3', mods = ctrlkey, action = act.ActivateTab(2) },
    { key = '4', mods = ctrlkey, action = act.ActivateTab(3) },
    { key = '5', mods = ctrlkey, action = act.ActivateTab(4) },
    { key = '6', mods = ctrlkey, action = act.ActivateTab(5) },
    { key = '7', mods = ctrlkey, action = act.ActivateTab(6) },
    { key = '8', mods = ctrlkey, action = act.ActivateTab(7) },
    { key = '9', mods = ctrlkey, action = act.ActivateTab(-1) },

    { key = 't', mods = ctrlkey .. '|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w', mods = ctrlkey .. '|SHIFT', action = act.CloseCurrentTab{ confirm = true } },
    { key = 'n', mods = ctrlkey .. '|SHIFT', action = act.SpawnWindow },
    { key = 'q', mods = ctrlkey .. '|SHIFT', action = act.QuitApplication },
    { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },

    { key = 'c', mods = ctrlkey .. '|SHIFT', action = act.CopyTo 'ClipboardAndPrimarySelection', },
    { key = 'v', mods = ctrlkey .. '|SHIFT', action = act.PasteFrom 'Clipboard' },

    { key = 'c', mods = ctrlkey .. '|SHIFT', action = act.CopyTo 'ClipboardAndPrimarySelection', },
    { key = 'v', mods = ctrlkey .. '|SHIFT', action = act.PasteFrom 'Clipboard' },

    -- We need to rebind OPT + Space otherwise odd things are happenings:
    { key = ' ', mods = 'OPT', action = act.SendKey { key = ' ' } },
}

-- Tmux Replacement:
local tmux_keys_enabled = true
local tmux_keys = {}
if tmux_keys_enabled then
    local launcher_choices = {}
    for id, item in ipairs(launch_menu) do
      table.insert(launcher_choices, {
        id = tostring(id),
        label = item.label,
      })
    end

    config.leader = { key = 'e', mods = 'ALT', timeout_milliseconds = 1000 }
    tmux_keys = {
        --{ key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
        --{ key = 'i', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        --{ key = 't', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

        { key = 'c', mods = 'LEADER', action = act.InputSelector {
          action = wezterm.action_callback(function(window, pane, id, label)
            if not id and not label then return end
            for _, item in ipairs(launch_menu) do
              if item.label == label then
                window:perform_action(act.SpawnCommandInNewTab(item), pane)
                return
              end
            end
          end),
          title = 'Select shell',
          fuzzy = false,
          alphabet = '1234567890ctieobsgjduaxphlmwfvüäöyz,.k',
          choices = launcher_choices,
        }},
        { key = 'i', mods = 'LEADER', action = act.InputSelector {
          action = wezterm.action_callback(function(window, pane, id, label)
            if not id and not label then return end
            for _, item in ipairs(launch_menu) do
              if item.label == label then
                window:perform_action(act.SplitHorizontal(item), pane)
                return
              end
            end
          end),
          title = 'Select shell',
          fuzzy = false,
          alphabet = '1234567890ctieobsgjduaxphlmwfvüäöyz,.k',
          choices = launcher_choices,
        }},
        { key = 't', mods = 'LEADER', action = act.InputSelector {
          action = wezterm.action_callback(function(window, pane, id, label)
            if not id and not label then return end
            for _, item in ipairs(launch_menu) do
              if item.label == label then
                window:perform_action(act.SplitVertical(item), pane)
                return
              end
            end
          end),
          title = 'Select shell',
          fuzzy = false,
          alphabet = '1234567890ctieobsgjduaxphlmwfvüäöyz,.k',
          choices = launcher_choices,
        }},

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

        { key = 'o', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS' }},
        { key = 'g', mods = 'LEADER', action = wezterm.action_callback(function(window, pane)

          window:perform_action(
            act.InputSelector {
              action = wezterm.action_callback(function(window, pane, id, label)
                if not id and not label then return end
                for _, item in ipairs(launch_menu) do
                  if item.label == label then
                    window:perform_action(act.SplitHorizontal(item), pane)
                    return
                  end
                end
              end),
              title = 'Select default shell',
              fuzzy = false,
              alphabet = '1234567890ctieobsgjduaxphlmwfvüäöyz,.k',
              choices = choices,
            },
            pane)
        end)
        }
    }
end

-- Set keys:
config.keys = TableConcat(general_keys, tmux_keys)

local copy_mode = nil
if wezterm.gui then
  copy_mode = wezterm.gui.default_key_tables().copy_mode
  TableConcat(copy_mode, {
    { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
    { key = 'n', mods = 'NONE', action = act.CopyMode 'MoveDown' },
    { key = 'r', mods = 'NONE', action = act.CopyMode 'MoveUp' },
    { key = 's', mods = 'NONE', action = act.CopyMode 'MoveRight' },
  })
end
config.key_tables = {
  copy_mode = copy_mode,
}

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

-- Custom events
wezterm.on("toggle-dark-mode", function(window)
  local overrides = window:get_config_overrides() or {}
  if (overrides.color_scheme == 'Solarized Light')
  then
    overrides.color_scheme = 'Solarized Dark'
  else
    overrides.color_scheme = 'Solarized Light'
  end
  window:set_config_overrides(overrides)
end)

-- Custom commands
wezterm.on('augment-command-palette', function(window, pane)
  return {
    {
      brief = 'Toggle Dark Mode / Light Mode',
      icon = 'cod_color_mode',
      action = act.EmitEvent 'toggle-dark-mode',
    },
  }
end)

-- and finally, return the configuration to wezterm
return config
