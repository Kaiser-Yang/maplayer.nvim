# maplayer.nvim

[中文文档](README-zh.md)

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
      {
        key = '<leader>ff',
        mode = 'n',
        desc = 'Find files',
        handler = function()
          require('telescope.builtin').find_files()
          return true
        end,
      },
      -- Add more keybinding specs here
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
      {
        key = '<leader>ff',
        mode = 'n',
        desc = 'Find files',
        handler = function()
          require('telescope.builtin').find_files()
          return true
        end,
      },
      -- Add more keybinding specs here
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
  {
    key = '<leader>ff',
    mode = 'n',
    desc = 'Find files',
    handler = function()
      require('telescope.builtin').find_files()
      return true
    end,
  },
  -- Add more keybinding specs here
})
```

> **⚠️ Important**: `setup()` and `make()` should only be called **once globally** in your configuration. Multiple calls will **overwrite** previous keybindings rather than merging them, which can cause unexpected behavior. Choose either one `setup()` call or one `make()` call for all your keybindings.

> **💡 Best Practice**: When using maplayer.nvim, you should **disable plugin-level keybindings** as much as possible and use maplayer.nvim for global binding management instead. This prevents conflicts and gives you centralized control over all keybindings. The exception is when you are certain that a plugin's bindings will only take effect on specific buffers, and you don't want to extend or customize that plugin's keybinding functionality.

> **🔗 Integration with which-key.nvim**: If you use [which-key.nvim](https://github.com/folke/which-key.nvim), see [Using `make()` for Delayed Binding](#using-make-for-delayed-binding) to learn how to integrate maplayer with which-key's interface while maintaining the chain of responsibility pattern.

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
| `count` | `boolean` | `false` | When `true` and handler returns a non-empty string, prepends `vim.v.count` to the string before feeding keys (only when `vim.v.count > 0`). Useful for `<Plug>` mappings that support count |

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

## Example: A Super Super Tab

This comprehensive example demonstrates the power of maplayer.nvim by creating an intelligent Tab key that handles multiple scenarios with proper priority ordering. This is a real-world example showing how multiple plugins can cooperate on the same key without conflicts:

```lua
require('maplayer').setup({
  -- Priority 100: Accept completion from blink.cmp
  {
    key = '<Tab>',
    mode = 'i',
    desc = 'Accept completion',
    priority = 100,
    condition = function()
      -- Check if blink.cmp completion menu is visible and item is selected
      local blink = require('blink.cmp')
      return blink.is_visible() and blink.get_selected_item() ~= nil
    end,
    handler = function()
      require('blink.cmp').accept()
      return true
    end,
  },
  
  -- Priority 90: Accept AI suggestions from copilot
  {
    key = '<Tab>',
    mode = 'i',
    desc = 'Accept Copilot suggestion',
    priority = 90,
    condition = function()
      -- Check if copilot has a suggestion
      return vim.fn['copilot#GetDisplayedSuggestion']().text ~= ''
    end,
    handler = function()
      vim.fn['copilot#Accept']()
      return true
    end,
  },
  
  -- Priority 80: Jump to next snippet placeholder
  {
    key = '<Tab>',
    mode = 'i',
    desc = 'Jump to next snippet placeholder',
    priority = 80,
    condition = function()
      local blink = require('blink.cmp')
      return blink.snippet_active({ direction = 1 })
    end,
    handler = function()
      require('blink.cmp').snippet_forward()
      return true
    end,
  },
  
  -- Priority 70: Jump out of brackets with tabout.nvim
  {
    key = '<Tab>',
    mode = 'i',
    desc = 'Tab out of brackets',
    priority = 70,
    condition = function()
      -- Check if cursor is before a closing bracket/quote
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local char = line:sub(col + 1, col + 1)
      return char:match('[%)%]%}"\']') ~= nil
    end,
    handler = function()
      require('tabout').tabout()
      return true
    end,
  },
  
  -- Priority 60: Auto-indent when current line indent is less than previous line
  {
    key = '<Tab>',
    mode = 'i',
    desc = 'Auto indent to match previous line',
    priority = 60,
    condition = function()
      local current_line = vim.api.nvim_get_current_line()
      local line_num = vim.api.nvim_win_get_cursor(0)[1]
      if line_num == 1 then return false end
      
      local prev_line = vim.api.nvim_buf_get_lines(0, line_num - 2, line_num - 1, false)[1]
      local current_indent = current_line:match('^%s*'):len()
      local prev_indent = prev_line:match('^%s*'):len()
      
      return current_indent < prev_indent
    end,
    handler = function()
      return '<C-f>' -- Use built-in Ctrl-f for auto-indent
    end,
  },
  
  -- Default Tab behavior will fallback automatically when no condition matches
})
```

This example showcases:
- **Multiple handlers** for the same key with different priorities
- **Conditional execution** based on various plugin states
- **Fallback behavior** when no condition matches
- **Clean separation of concerns** - each handler has a single responsibility

### Design Principles

**maplayer.nvim** follows solid software engineering principles:

- **Open-Closed Principle**: Add new functionality by adding new handlers, not modifying existing ones. When you need new behavior for a key, simply add a new handler with appropriate condition and priority.
  
- **Single Responsibility Principle**: Each handler does exactly one thing. This makes handlers easy to understand, test, and maintain.

> **⚠️ Important Reminder**: Remember to call `setup()` or `make()` only **once globally** with all your keybinding specifications. Multiple calls will overwrite previous configurations instead of merging them.

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
  { key = '<leader>f', priority = 10, desc = 'First', handler = function() return true end },
  { key = '<leader>f', priority = 10, desc = 'Second', handler = function() return true end },
})
-- "First" will be tried before "Second"
```

### Using `make()` for Delayed Binding

The `make()` function generates keymap specifications without immediately registering them. This is primarily useful for **delayed binding**, which allows you to use [which-key.nvim](https://github.com/folke/which-key.nvim)'s interface for keybinding registration.

Here's an example of using `make()` with which-key:

```lua
-- Generate keymap specs with maplayer
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
  {
    key = '<leader>fg',
    mode = 'n',
    desc = 'Live grep',
    handler = function()
      require('telescope.builtin').live_grep()
      return true
    end,
  },
  {
    key = '<leader>fb',
    mode = 'n',
    desc = 'Find buffers',
    handler = function()
      require('telescope.builtin').buffers()
      return true
    end,
  },
})

-- Register with which-key
local wk = require('which-key')
for _, spec in ipairs(keymaps) do
  wk.add({
    spec.lhs,
    spec.rhs,
    mode = spec.mode,
    desc = spec.opts.desc,
  })
end
```

This delayed binding approach lets you:
- Use which-key's registration interface while benefiting from maplayer's conditional handler chains
- Organize keybindings with which-key's grouping and display features
- Maintain maplayer's chain of responsibility pattern for the actual key handling logic

### Lazy Loading Plugins with maplayer

**maplayer.nvim** enables lazy loading for most plugins that don't rely on `autocmd` events. By deferring plugin loading until the first key press, you can significantly improve Neovim's startup time.

#### How It Works

When using [lazy.nvim](https://github.com/folke/lazy.nvim), you can:
1. Set `lazy = true` for the plugin
2. Disable the plugin's default keybindings
3. Use maplayer handlers that `require()` the plugin only when needed
4. Return the plugin's key sequence (like `<Plug>` mappings)

On first keypress, lazy.nvim loads the plugin automatically when `require()` is called.

#### Example: Lazy Loading nvim-surround

[nvim-surround](https://github.com/kylechui/nvim-surround) provides `<Plug>` mappings for text surrounding operations. Here's how to lazy load it with maplayer:

```lua
-- In your lazy.nvim config
{
  'kylechui/nvim-surround',
  lazy = true,
  opts = {
    keymaps = {
      -- Disable all default keymaps
      insert = false,
      insert_line = false,
      normal = false,
      normal_cur = false,
      normal_line = false,
      normal_cur_line = false,
      visual = false,
      visual_line = false,
      delete = false,
      change = false,
      change_line = false,
    },
  },
}

-- In your maplayer setup
require('maplayer').setup({
  {
    key = 'ys',
    mode = 'n',
    desc = 'Add surround',
    handler = function()
      require('nvim-surround')  -- Lazy loads the plugin
      return '<Plug>(nvim-surround-normal)'
    end,
  },
  {
    key = 'yss',
    mode = 'n',
    desc = 'Add surround to line',
    handler = function()
      require('nvim-surround')
      return '<Plug>(nvim-surround-normal-cur)'
    end,
  },
  {
    key = 'ds',
    mode = 'n',
    desc = 'Delete surround',
    handler = function()
      require('nvim-surround')
      return '<Plug>(nvim-surround-delete)'
    end,
  },
  {
    key = 'cs',
    mode = 'n',
    desc = 'Change surround',
    handler = function()
      require('nvim-surround')
      return '<Plug>(nvim-surround-change)'
    end,
  },
  {
    key = 'S',
    mode = 'x',
    desc = 'Add surround in visual mode',
    handler = function()
      require('nvim-surround')
      return '<Plug>(nvim-surround-visual)'
    end,
  },
})
```

This approach works for any plugin that provides `<Plug>` mappings or command sequences.

#### Example: Using Count with Plug Mappings

Many Vim plugins provide `<Plug>` mappings that support Vim's count feature. The `count` parameter is particularly useful for these mappings, such as those from [dial.nvim](https://github.com/monaqa/dial.nvim) for incrementing/decrementing, or other plugins with count-aware operations.

Here's an example of lazy loading a plugin with count-aware `<Plug>` mappings:

```lua
-- In your lazy.nvim config
{
  'monaqa/dial.nvim',
  lazy = true,
}

-- In your maplayer setup
require('maplayer').setup({
  {
    key = '<C-a>',
    mode = 'n',
    desc = 'Increment number',
    count = true,  -- Enable count support
    handler = function()
      require('dial.map')  -- Lazy loads the plugin
      return '<Plug>(dial-increment)'
    end,
  },
  {
    key = '<C-x>',
    mode = 'n',
    desc = 'Decrement number',
    count = true,  -- Enable count support
    handler = function()
      require('dial.map')
      return '<Plug>(dial-decrement)'
    end,
  },
})
```

**Why use `count = true`?**

When you set `count = true`, typing `3<C-a>` will:
1. Capture the count value `3` from `vim.v.count`
2. Execute the handler which returns `'<Plug>(dial-increment)'`
3. Prepend the count to create `'3<Plug>(dial-increment)'`
4. Feed this combined string to Vim

This allows the `<Plug>` mapping to receive the count, enabling operations like "increment 3 times" or "decrement 5 times" to work correctly. Without `count = true`, the count would be lost and the `<Plug>` mapping would only execute once.

**When to use `count = true`:**

Use this parameter when:
- The `<Plug>` mapping or command accepts a count prefix
- You want to preserve Vim's count behavior (e.g., `5j` to move down 5 lines)
- The underlying operation should be repeated or scaled by the count value

**Example with autopairs:**

If you're using a plugin like nvim-autopairs with custom `<Plug>` mappings that support count, you would also set `count = true`:

```lua
require('maplayer').setup({
  {
    key = '<M-e>',
    mode = 'i',
    desc = 'Fast wrap',
    -- Only set count = true if your specific <Plug> mapping supports it
    handler = function()
      require('nvim-autopairs.fastwrap').setup({})
      return '<Plug>(fastwrap)'
    end,
  },
})

### What maplayer Doesn't Do

**maplayer is designed for global keybindings management.** It doesn't support buffer-local mappings directly (i.e., `buffer = true` option), as this would complicate the global keybinding coordination.

#### Buffer-Local Mappings with make()

If you need buffer-local keybindings, you can use `make()` to generate keymaps and register them with `autocmd`:

```lua
local maplayer = require('maplayer')

-- Generate keymaps for a specific filetype
local markdown_maps = maplayer.make({
  {
    key = '<CR>',
    mode = 'n',
    desc = 'Follow link',
    handler = function()
      -- Markdown-specific logic
      vim.cmd('normal! gx')
      return true
    end,
  },
})

-- Remove buffer field from opts and register with autocmd
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(args)
    for _, spec in ipairs(markdown_maps) do
      -- Clear the buffer field if it exists in opts
      local opts = vim.tbl_extend('force', spec.opts, { buffer = args.buf })
      vim.keymap.set(spec.mode, spec.lhs, spec.rhs, opts)
    end
  end,
})
```

This pattern allows you to:
- Use maplayer's conditional handler chains for buffer-local keybindings
- Maintain the chain of responsibility pattern
- Set keybindings only for specific buffers via autocmd

### Debugging

maplayer.nvim includes a built-in logging system to help you debug your keybinding configurations.

#### Enabling Logging

To enable logging, pass a `log` configuration in the `setup()` function:

```lua
require('maplayer').setup({
  -- Optional: Enable logging
  log = {
    enabled = true,
    level = 'DEBUG',  -- Options: 'DEBUG', 'INFO', 'WARN', 'ERROR'
  },
  -- Your keybindings
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
```

#### Log Levels

The logger supports four levels of verbosity:

- **`DEBUG`**: Most verbose - logs every condition check, handler execution, and return value
- **`INFO`**: Logs key presses and which handlers succeed (not used by default)
- **`WARN`**: Logs warnings only
- **`ERROR`**: Logs errors only

**Note**: By default, only DEBUG level logging is used for detailed troubleshooting.

#### Log Output

When logging is enabled, messages are written to Neovim's log file. You can view the log file location with `:lua print(vim.fn.stdpath('log'))` or check messages with `:messages`.

Example log messages:

```
[maplayer] [DEBUG] Registering key binding: <Tab> mode: i descriptions: { "Accept completion", "Jump to next snippet placeholder" }
[maplayer] [DEBUG] Key pressed: <Tab> in mode: i
[maplayer] [DEBUG] Trying handler 1 for key <Tab>
[maplayer] [DEBUG] Checking mode for key <Tab> desc: Accept completion mode_ok: true
[maplayer] [DEBUG] Checking condition for key <Tab> desc: Accept completion condition: true
[maplayer] [DEBUG] Executing handler for key <Tab> desc: Accept completion
[maplayer] [DEBUG] Handler result for key <Tab> desc: Accept completion result: true
[maplayer] [DEBUG] Handler 1 succeeded for key <Tab> return value: true
```

**Note**: DEBUG level messages are logged to the Neovim log file and can be viewed with `:messages`. WARN and ERROR messages will also appear as notifications in the editor.

#### Advanced Usage

You can also add custom logging in your handlers:

```lua
require('maplayer').setup({
  {
    key = '<leader>d',
    desc = 'Debug handler',
    handler = function()
      print('Handler executed!')
      print('Current buffer:', vim.api.nvim_get_current_buf())
      print('Current filetype:', vim.bo.filetype)
      -- Your actual handler logic here
      return true
    end,
  },
})
```

## How It Works

Internally, maplayer:

1. **Normalizes** all keyspecs (handles mode expansion, case normalization for angle-bracketed keys like `<C-A>` and `<c-a>`, etc.)
2. **Sorts** handlers by key and priority (with stable sort)
3. **Wraps** each handler with its condition check
4. **Merges** the condition-wrapped handlers for the same key+mode into a chain
5. **Generates** a single function that iterates through the chain
6. **Registers** the final handler with `vim.keymap.set()`

When you press a key:
- The merged function executes
- Condition-wrapped handlers are evaluated in priority order (higher priority first)
- The first handler whose condition returns true is executed
- If the handler returns a value, the chain stops
- If no handler succeeds, the original key is fed back (fallback)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Inspired by VS Code's keybinding system and the chain of responsibility design pattern.
