# maplayer.nvim

Make Vim/Neovim key mappings work like VS Code's

## Features

- Simple and intuitive API for creating keymaps
- Helper functions for different modes (normal, visual, insert)
- Configurable default options for all keymaps
- Lightweight and fast

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Kaiser-Yang/maplayer.nvim",
  config = function()
    require("maplayer").setup({
      -- your configuration here
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "Kaiser-Yang/maplayer.nvim",
  config = function()
    require("maplayer").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'Kaiser-Yang/maplayer.nvim'
```

Then in your `init.lua`:
```lua
require("maplayer").setup()
```

## Configuration

Default configuration:

```lua
require("maplayer").setup({
  -- Enable the plugin (default: true)
  enabled = true,
  -- Default options for all keymaps
  default_opts = {
    noremap = true,
    silent = true,
  },
})
```

## Usage

### Basic keymap creation

```lua
local maplayer = require("maplayer")

-- Create a keymap for any mode
maplayer.map("n", "<leader>w", ":w<CR>", { desc = "Save file" })

-- Use helper functions for specific modes
maplayer.nmap("<leader>q", ":q<CR>", { desc = "Quit" })
maplayer.vmap("<leader>y", '"+y', { desc = "Copy to clipboard" })
maplayer.imap("jk", "<Esc>", { desc = "Exit insert mode" })
```

### VS Code-like keymaps

```lua
local maplayer = require("maplayer")

-- File operations
maplayer.nmap("<C-s>", ":w<CR>", { desc = "Save" })
maplayer.imap("<C-s>", "<Esc>:w<CR>a", { desc = "Save" })

-- Navigation
maplayer.nmap("<C-p>", ":Telescope find_files<CR>", { desc = "Find files" })
maplayer.nmap("<C-f>", ":Telescope live_grep<CR>", { desc = "Search in files" })

-- Editor
maplayer.nmap("<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
```

## API Reference

### `setup(opts)`

Initialize the plugin with optional configuration.

- `opts` (table, optional): Configuration options

### `map(mode, lhs, rhs, opts)`

Create a keymap for the specified mode.

- `mode` (string): Mode shortname (e.g., 'n', 'i', 'v')
- `lhs` (string): Left-hand side of the mapping
- `rhs` (string|function): Right-hand side of the mapping
- `opts` (table, optional): Additional options

### `nmap(lhs, rhs, opts)`

Create a normal mode keymap.

### `vmap(lhs, rhs, opts)`

Create a visual mode keymap.

### `imap(lhs, rhs, opts)`

Create an insert mode keymap.

## License

MIT License - see [LICENSE](LICENSE) for details
