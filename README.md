# maplayer.nvim

Make Vim/Neovim key mappings work like VS Code's

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

## License

MIT License - see [LICENSE](LICENSE) for details
