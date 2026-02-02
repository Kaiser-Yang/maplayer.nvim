-- maplayer.nvim - Make Vim/Neovim key mappings work like VS Code's
local M = {}

-- Default configuration
M.config = {
  -- Enable the plugin by default
  enabled = true,
  -- Default options for keymaps
  default_opts = {
    noremap = true,
    silent = true,
  },
}

-- Setup function to initialize the plugin
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if not M.config.enabled then
    return
  end

  -- Plugin initialization logic goes here
  -- This is where you would set up keymaps, autocmds, etc.
end

-- Helper function to create a keymap with default options
function M.map(mode, lhs, rhs, opts)
  opts = vim.tbl_deep_extend("force", {}, M.config.default_opts, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Helper function to create a normal mode keymap
function M.nmap(lhs, rhs, opts)
  M.map("n", lhs, rhs, opts)
end

-- Helper function to create a visual mode keymap
function M.vmap(lhs, rhs, opts)
  M.map("v", lhs, rhs, opts)
end

-- Helper function to create an insert mode keymap
function M.imap(lhs, rhs, opts)
  M.map("i", lhs, rhs, opts)
end

return M