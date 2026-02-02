# maplayer.nvim
Make Vim/Neovim key mappings work like VS Code's

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'Kaiser-Yang/maplayer.nvim',
  config = function()
    require('maplayer').setup({})
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'Kaiser-Yang/maplayer.nvim',
  config = function()
    require('maplayer').setup({})
  end
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'Kaiser-Yang/maplayer.nvim'
```

Then in your `init.lua`:

```lua
require('maplayer').setup({})
```

## Configuration

The plugin requires calling `setup({})` to initialize. Currently, no configuration options are available, but they will be added in the future.

```lua
require('maplayer').setup({
  -- Configuration options will be available here in the future
})
```
