# maplayer.nvim

Make Vim/Neovim key mappings work like VS Code's - A powerful keybinding manager that solves the conflicts problem with a chain of responsibility pattern.

## The Problem with Traditional Neovim Keybindings

In Neovim, managing keybindings across multiple plugins can quickly become a nightmare:

- **Keybinding Conflicts**: Different plugins often want to use the same keys, forcing you to choose one or manually resolve conflicts
- **Context-Unaware Bindings**: Traditional `vim.keymap.set()` doesn't provide an easy way to conditionally execute different actions based on context
- **Mode Isolation Complexity**: While Vim modes naturally separate keybindings, managing multiple context-dependent actions for the same key in the same mode is difficult
- **Priority Management**: No built-in mechanism to specify which handler should be tried first when multiple conditions could be satisfied
- **Maintenance Overhead**: As your configuration grows, tracking which keys are mapped where becomes increasingly complex

## The maplayer.nvim Solution

**maplayer.nvim** implements a **chain of responsibility pattern** for keybindings, inspired by VS Code's keybinding system. This allows you to:

✨ **Bind multiple handlers to the same key** - Each with its own condition, handler, and priority  
🎯 **Conditional execution** - Handlers are evaluated in priority order until one succeeds  
🔒 **Natural mode isolation** - Keybindings in different modes are automatically kept separate  
🎨 **Conflict-free configuration** - Multiple plugins can register handlers for the same key without conflicts  
⚡ **Fallback behavior** - If no handler succeeds, the original key action is executed

### Chain of Responsibility Pattern

When you press a key, maplayer:
1. Checks all registered handlers for that key in the current mode
2. Evaluates them in priority order (higher priority first)
3. Runs the first handler whose condition returns true
4. If no handler succeeds, falls back to the default key behavior

This means you can have:
- A file explorer plugin that handles `<CR>` when hovering over a file
- An LSP plugin that handles `<CR>` when hovering over a code action
- A completion plugin that handles `<CR>` when the completion menu is open
- Default `<CR>` behavior in all other cases

All without any conflicts! 🎉

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'Kaiser-Yang/maplayer.nvim',
  config = function()
    require('maplayer').setup({
      -- Your keybinding specs here
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'Kaiser-Yang/maplayer.nvim',
  config = function()
    require('maplayer').setup({
      -- Your keybinding specs here
    })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'Kaiser-Yang/maplayer.nvim'
```

Then in your `init.lua`:

```lua
require('maplayer').setup({
  -- Your keybinding specs here
})
```

## Usage

maplayer.nvim provides two main functions:

### `setup(keyspecs)` - Create and Register Keybindings

Use `setup()` to immediately create and register keybindings with Neovim:

```lua
require('maplayer').setup({
  {
    key = '<CR>',
    mode = 'n',
    desc = 'Confirm completion',
    condition = function()
      return vim.fn.pumvisible() == 1
    end,
    handler = function()
      return '<C-y>'
    end,
    priority = 100,
  },
  {
    key = '<CR>',
    mode = 'n',
    desc = 'Open file in explorer',
    condition = function()
      return vim.bo.filetype == 'netrw'
    end,
    handler = function()
      -- Custom logic here
      return true
    end,
    priority = 50,
  },
})
```

### `make(keyspecs)` - Generate Keymap Arguments

Use `make()` to generate argument tables for `vim.keymap.set()` without registering them:

```lua
local keymaps = require('maplayer').make({
  {
    key = '<leader>ff',
    mode = 'n',
    desc = 'Find files',
    handler = function()
      require('telescope.builtin').find_files()
      return true
    end,
  },
})

-- Later, manually register them
for _, spec in ipairs(keymaps) do
  vim.keymap.set(spec.mode, spec.lhs, spec.rhs, spec.opts)
end
```

This is useful when you need more control over when or how keybindings are registered.

## KeySpec API

Each keybinding specification is a table with the following fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | **required** | The key sequence to map (e.g., `'<CR>'`, `'<leader>ff'`, `'<C-n>'`) |
| `mode` | `string \| string[]` | `'n'` | Vim mode(s): `'n'`, `'i'`, `'v'`, `'x'`, `'s'`, `'o'`, `'c'`, `'t'`, `'l'`, or mode aliases `''`, `'!'`, `'v'` |
| `desc` | `string` | `''` | Description of the keybinding (shown in which-key, etc.) |
| `condition` | `function` | `function() return true end` | Function that returns `true` if this handler should execute |
| `handler` | `function \| string` | **required** | Function to execute, or string to feed as keys. Return value determines behavior (see below) |
| `priority` | `number` | `0` | Higher priority handlers are evaluated first |
| `noremap` | `boolean` | `true` | Whether to use non-recursive mapping |
| `remap` | `boolean` | `false` | Whether to allow remapping (opposite of `noremap`) |
| `replace_keycodes` | `boolean` | `true` | Whether to replace keycodes in returned strings |

### Handler Return Values

The `handler` function's return value determines what happens next:

- **`true`**: Handler succeeded, stop processing, don't execute default key behavior
- **`false` or `nil`**: Handler declined, try the next handler in the chain
- **`string`**: Handler succeeded, feed the returned string as keys (respects `remap` and `replace_keycodes`)

### Mode Specification

The `mode` field accepts:

- Single mode: `'n'`, `'i'`, `'v'`, `'x'`, `'s'`, `'o'`, `'c'`, `'t'`, `'l'`
- Array of modes: `{ 'n', 'v' }`
- Mode aliases:
  - `''` - Normal, Visual, Select, and Operator-pending modes
  - `'!'` - Insert and Command-line modes  
  - `'v'` - Visual and Select modes

## Examples

### Basic Usage: Simple Keybinding

```lua
require('maplayer').setup({
  {
    key = '<leader>w',
    mode = 'n',
    desc = 'Save file',
    handler = function()
      vim.cmd('write')
      return true
    end,
  },
})
```

### Multiple Handlers for One Key

This is where maplayer.nvim really shines - handling the same key differently based on context:

```lua
require('maplayer').setup({
  -- Highest priority: Accept completion when popup is visible
  {
    key = '<CR>',
    mode = 'i',
    desc = 'Accept completion',
    priority = 100,
    condition = function()
      return vim.fn.pumvisible() == 1
    end,
    handler = function()
      return '<C-y>'
    end,
  },
  
  -- Medium priority: Auto-pair brackets when completing
  {
    key = '<CR>',
    mode = 'i',
    desc = 'Auto-pair on completion',
    priority = 50,
    condition = function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      return line:sub(col, col) == ')'
    end,
    handler = function()
      return '<CR><Esc>O'
    end,
  },
  
  -- Fallback: Normal Enter behavior
  -- (no need to define, will fallback automatically)
})
```

### Context-Aware Navigation

```lua
require('maplayer').setup({
  {
    key = '<C-j>',
    mode = 'n',
    desc = 'Next item in quickfix',
    priority = 100,
    condition = function()
      return vim.fn.getqflist({winid = 0}).winid ~= 0
    end,
    handler = function()
      vim.cmd('cnext')
      return true
    end,
  },
  {
    key = '<C-j>',
    mode = 'n',
    desc = 'Next diagnostic',
    priority = 50,
    condition = function()
      return #vim.diagnostic.get(0) > 0
    end,
    handler = function()
      vim.diagnostic.goto_next()
      return true
    end,
  },
  {
    key = '<C-j>',
    mode = 'n',
    desc = 'Move down',
    priority = 0,
    handler = function()
      return 'gj'
    end,
  },
})
```

### LSP-Aware Keybindings

```lua
require('maplayer').setup({
  {
    key = 'K',
    mode = 'n',
    desc = 'LSP hover documentation',
    condition = function()
      return #vim.lsp.get_active_clients({ bufnr = 0 }) > 0
    end,
    handler = function()
      vim.lsp.buf.hover()
      return true
    end,
    priority = 100,
  },
  {
    key = 'gd',
    mode = 'n',
    desc = 'LSP go to definition',
    condition = function()
      return #vim.lsp.get_active_clients({ bufnr = 0 }) > 0
    end,
    handler = function()
      vim.lsp.buf.definition()
      return true
    end,
  },
})
```

### Plugin-Specific Keybindings

Perfect for plugin configurations that don't interfere with each other:

```lua
-- In your telescope config
require('maplayer').setup({
  {
    key = '<leader>ff',
    desc = 'Find files',
    handler = function()
      require('telescope.builtin').find_files()
      return true
    end,
  },
  {
    key = '<leader>fg',
    desc = 'Live grep',
    handler = function()
      require('telescope.builtin').live_grep()
      return true
    end,
  },
})

-- In your nvim-tree config (same key, no conflict!)
require('maplayer').setup({
  {
    key = '<leader>ff',
    desc = 'Find file in tree',
    priority = 50, -- Lower priority, won't override telescope
    condition = function()
      return vim.bo.filetype == 'NvimTree'
    end,
    handler = function()
      require('nvim-tree.api').tree.find_file()
      return true
    end,
  },
})
```

### String Handlers

For simple key remapping, use string handlers:

```lua
require('maplayer').setup({
  {
    key = 'j',
    mode = 'n',
    desc = 'Move down (display line)',
    handler = 'gj', -- String is fed as keys
  },
  {
    key = 'k',
    mode = 'n',
    desc = 'Move up (display line)',
    handler = 'gk',
  },
})
```

### Multiple Modes

```lua
require('maplayer').setup({
  {
    key = '<Esc>',
    mode = { 'i', 'v' },
    desc = 'Exit to normal mode',
    handler = function()
      vim.cmd('stopinsert')
      return true
    end,
  },
})
```

## Migration from Traditional Keymaps

### Before (traditional approach)

```lua
-- Conflicts and complex conditional logic
vim.keymap.set('n', '<CR>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-y>'
  elseif vim.bo.filetype == 'netrw' then
    -- handle netrw
    return '<CR>'
  else
    return '<CR>'
  end
end, { expr = true })
```

### After (maplayer approach)

```lua
require('maplayer').setup({
  {
    key = '<CR>',
    mode = 'n',
    desc = 'Accept completion',
    priority = 100,
    condition = function() return vim.fn.pumvisible() == 1 end,
    handler = function() return '<C-y>' end,
  },
  {
    key = '<CR>',
    mode = 'n',
    desc = 'Open in netrw',
    priority = 50,
    condition = function() return vim.bo.filetype == 'netrw' end,
    handler = function() return '<CR>' end,
  },
})
```

Much cleaner, more maintainable, and easier to extend! ✨

## Advanced Tips

### Stable Sorting with Priority

Priority values are used for sorting, and the order of definition provides stable sort:

```lua
-- If two handlers have the same priority, 
-- the one defined first will be evaluated first
require('maplayer').setup({
  { key = '<leader>f', priority = 10, desc = 'First', handler = ... },
  { key = '<leader>f', priority = 10, desc = 'Second', handler = ... },
})
-- "First" will be tried before "Second"
```

### Using `make()` for Lazy Loading

```lua
-- Generate but don't register yet
local keymaps = require('maplayer').make({
  {
    key = '<leader>l',
    desc = 'Lazy load feature',
    handler = function()
      require('heavy.plugin').do_something()
      return true
    end,
  },
})

-- Register later when needed
for _, spec in ipairs(keymaps) do
  vim.keymap.set(spec.mode, spec.lhs, spec.rhs, spec.opts)
end
```

### Debugging Keybindings

Check which handler is being executed:

```lua
require('maplayer').setup({
  {
    key = '<leader>d',
    desc = 'Debug handler',
    handler = function()
      print('Handler executed!')
      return true
    end,
  },
})
```

## How It Works

Internally, maplayer:

1. **Normalizes** all keyspecs (handles mode expansion, case-insensitive keys, etc.)
2. **Sorts** handlers by key and priority (with stable sort)
3. **Merges** multiple handlers for the same key+mode into a chain
4. **Wraps** handlers with condition checks
5. **Generates** a single function that iterates through the chain
6. **Registers** the final handler with `vim.keymap.set()`

When you press a key:
- The wrapped function executes
- Each handler's condition is checked in priority order
- The first handler whose condition returns true is executed
- If the handler returns a value, the chain stops
- If no handler succeeds, the original key is fed back (fallback)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Related Projects

- [which-key.nvim](https://github.com/folke/which-key.nvim) - Shows keybindings in a popup
- [lazy.nvim](https://github.com/folke/lazy.nvim) - Modern plugin manager for Neovim

## Credits

Inspired by VS Code's keybinding system and the chain of responsibility design pattern.
