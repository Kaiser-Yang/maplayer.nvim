-- maplayer.nvim plugin entry point
-- This file is automatically loaded by Neovim when the plugin is installed

if vim.g.loaded_maplayer then
  return
end
vim.g.loaded_maplayer = 1

-- The plugin is designed to be explicitly set up via lua
-- Users should call require('maplayer').setup() in their config
