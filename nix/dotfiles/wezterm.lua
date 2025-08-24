-- Import the wezterm module
local wezterm = require 'wezterm'
-- Creates a config object which we will be adding our config to
local config = wezterm.config_builder()

-- (This is where our config will go)
config.color_scheme = 'Tokyo Night'

config.font = wezterm.font({ family = 'JetBrainsMono Nerd Font Mono' })
config.font_size = 14
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  -- ... add these new entries to your config.keys table
  {
    -- I'm used to tmux bindings, so am using the quotes (") key to
    -- split horizontally, and the percent (%) key to split vertically.
    key = '"',
    -- Note that instead of a key modifier mapped to a key on your keyboard
    -- like CTRL or ALT, we can use the LEADER modifier instead.
    -- This means that this binding will be invoked when you press the leader
    -- (CTRL + A), quickly followed by quotes (").
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '%',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
}

-- Returns our config to be evaluated. We must always do this at the bottom of this file
return config