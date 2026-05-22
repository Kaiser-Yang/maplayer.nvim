# maplayer.nvim

[English Documentation](README.md)

让 Vim/Neovim 按键映射像 VS Code 一样工作 - 一个强大的按键绑定管理器，通过责任链模式解决冲突问题。

## 传统 Neovim 按键绑定的问题

在 Neovim 中，管理多个插件的按键绑定很快就会变成噩梦：

- **按键绑定冲突**：不同的插件经常想使用相同的按键，迫使你只能选择一个或手动解决冲突
- **缺乏上下文感知**：传统的 `vim.keymap.set()` 没有提供简单的方法来根据上下文有条件地执行不同的操作
- **模式隔离的复杂性**：虽然 Vim 模式自然地分离了按键绑定，但在同一模式下管理同一按键的多个上下文相关操作是困难的
- **优先级管理**：没有内置机制来指定当多个条件可能满足时应该首先尝试哪个处理器
- **维护开销**：随着配置的增长，跟踪哪些键在哪里被映射变得越来越复杂

## maplayer.nvim 的解决方案

**maplayer.nvim** 为按键绑定实现了**责任链模式**，灵感来自 VS Code 的按键绑定系统。这允许你：

✨ **为同一个按键绑定多个处理器** - 每个都有自己的条件、处理器和优先级  
🎯 **条件执行** - 处理器按优先级顺序评估，直到一个成功  
🔒 **自然的模式隔离** - 不同模式下的按键绑定自动保持分离  
🎨 **无冲突配置** - 多个插件可以为同一个按键注册处理器而不会冲突  
⚡ **回退行为** - 如果没有处理器成功，则执行原始按键操作

### 责任链模式

当你按下一个按键时，maplayer：
1. 检查当前模式下该按键的所有已注册处理器
2. 按优先级顺序评估它们（优先级高的先评估）
3. 运行第一个条件返回 true 的处理器
4. 如果没有处理器成功，则回退到默认按键行为

这意味着你可以拥有：
- 一个文件浏览器插件，当悬停在文件上时处理 `<CR>`
- 一个 LSP 插件，当悬停在代码操作上时处理 `<CR>`
- 一个补全插件，当补全菜单打开时处理 `<CR>`
- 在所有其他情况下使用默认的 `<CR>` 行为

所有这些都不会有任何冲突！🎉

## 安装

### 使用 [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'Kaiser-Yang/maplayer.nvim',
  config = function()
    require('maplayer').setup({
      {
        key = '<leader>ff',
        mode = 'n',
        desc = '查找文件',
        handler = function()
          require('telescope.builtin').find_files()
          return true
        end,
      },
      -- 在这里添加更多按键绑定规格
    })
  end
}
```

### 使用 [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'Kaiser-Yang/maplayer.nvim',
  config = function()
    require('maplayer').setup({
      {
        key = '<leader>ff',
        mode = 'n',
        desc = '查找文件',
        handler = function()
          require('telescope.builtin').find_files()
          return true
        end,
      },
      -- 在这里添加更多按键绑定规格
    })
  end
}
```

### 使用 [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'Kaiser-Yang/maplayer.nvim'
```

然后在你的 `init.lua` 中：

```lua
require('maplayer').setup({
  {
    key = '<leader>ff',
    mode = 'n',
    desc = '查找文件',
    handler = function()
      require('telescope.builtin').find_files()
      return true
    end,
  },
  -- 在这里添加更多按键绑定规格
})
```

> **⚠️ 重要提示**：`setup()` 和 `make()` 应该在你的配置中**只调用一次**。多次调用会**覆盖**之前的按键绑定而不是合并它们，这可能导致意外行为。选择一次 `setup()` 调用或一次 `make()` 调用来配置所有按键绑定。

> **💡 最佳实践**：使用 maplayer.nvim 时，应该**尽可能禁用插件层面的按键绑定**，转而使用 maplayer.nvim 进行全局绑定管理。这样可以防止冲突，并让你能集中控制所有按键绑定。除非你确定插件的绑定只会对特定的 buffer 生效，而你也不想扩展或自定义该插件的按键绑定功能。

> **🔗 与 which-key.nvim 集成**：如果你使用 [which-key.nvim](https://github.com/folke/which-key.nvim)，请查看[使用 `make()` 进行延迟绑定](#使用-make-进行延迟绑定)了解如何在保持责任链模式的同时将 maplayer 与 which-key 的界面集成。

## 使用方法

maplayer.nvim 提供两个主要函数：

### `setup(keyspecs)` - 创建并注册按键绑定

使用 `setup()` 立即创建并向 Neovim 注册按键绑定：

```lua
require('maplayer').setup({
  {
    key = '<CR>',
    mode = 'n',
    desc = '确认补全',
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
    desc = '在浏览器中打开文件',
    condition = function()
      return vim.bo.filetype == 'netrw'
    end,
    handler = function()
      -- 自定义逻辑
      return true
    end,
    priority = 50,
  },
})
```

### `make(keyspecs)` - 生成键映射参数

使用 `make()` 生成 `vim.keymap.set()` 的参数表而不注册它们：

```lua
local keymaps = require('maplayer').make({
  {
    key = '<leader>ff',
    mode = 'n',
    desc = '查找文件',
    handler = function()
      require('telescope.builtin').find_files()
      return true
    end,
  },
})

-- 稍后手动注册它们
for _, spec in ipairs(keymaps) do
  vim.keymap.set(spec.mode, spec.lhs, spec.rhs, spec.opts)
end
```

这在你需要更多控制何时或如何注册按键绑定时很有用。

## KeySpec API

每个按键绑定规格都是一个包含以下字段的表：

| 字段 | 类型 | 默认值 | 描述 |
|-------|------|---------|-------------|
| `key` | `string` | **必需** | 要映射的按键序列（例如，`'<CR>'`, `'<leader>ff'`, `'<C-n>'`） |
| `mode` | `string \| string[]` | `'n'` | Vim 模式：`'n'`, `'i'`, `'v'`, `'x'`, `'s'`, `'o'`, `'c'`, `'t'`, `'l'`，或模式别名 `''`, `'!'`, `'v'` |
| `desc` | `string` | `''` | 按键绑定的描述（在 which-key 等中显示） |
| `condition` | `function` | `function() return true end` | 如果此处理器应该执行，则返回 `true` 的函数 |
| `handler` | `function \| string` | **必需** | 要执行的函数，或作为按键输入的字符串。返回值决定行为（见下文） |
| `priority` | `number` | `0` | 优先级高的处理器先评估 |
| `noremap` | `boolean` | `true` | 是否使用非递归映射 |
| `remap` | `boolean` | `false` | 是否允许重新映射（与 `noremap` 相反） |
| `replace_keycodes` | `boolean` | `true` | 是否替换返回字符串中的键码 |
| `fallback` | `boolean \| string \| table \| function` | `true` | 控制所有处理器拒绝时的回退行为（见[回退行为](#回退行为)） |

### 处理器返回值

`handler` 函数的返回值决定接下来会发生什么：

- **`true`**：处理器成功，停止处理，不执行默认按键行为
- **`false` 或 `nil`**：处理器拒绝，尝试链中的下一个处理器
- **`string`**：处理器成功，将返回的字符串作为按键输入（遵守 `remap` 和 `replace_keycodes`）

### 模式规格

`mode` 字段接受：

- 单一模式：`'n'`, `'i'`, `'v'`, `'x'`, `'s'`, `'o'`, `'c'`, `'t'`, `'l'`
- 模式数组：`{ 'n', 'v' }`
- 模式别名：
  - `''` - 普通、可视、选择和操作待定模式
  - `'!'` - 插入和命令行模式
  - `'v'` - 可视和选择模式

### 回退行为

`fallback` 字段控制当所有处理器都拒绝时会发生什么。它支持多种类型：

#### 布尔类型
- **`true`**：回退到原始按键的默认行为
- **`false`**（默认）：无回退 - 当所有处理器拒绝时，按键不执行任何操作

```lua
{
  key = '<leader>x',
  fallback = false,  -- 如果处理器拒绝则不执行任何操作
  handler = function() ... end,
}
```

#### 字符串类型
当所有处理器拒绝时，将指定的字符串作为按键输入。始终使用 `replace_keycodes=true` 和 `remap=false` 以方便使用。

```lua
{
  key = '<leader>x',
  fallback = 'i回退文本！<Esc>',  -- 插入文本作为回退
  handler = function() ... end,
}
```

#### 表类型
提供对回退行为的完全控制，包含以下字段：
- `key`（字符串，**必需**）：要输入的按键序列
- `replace_keycodes`（布尔，默认 `true`）：是否替换像 `<CR>`、`<Esc>` 等的键码
- `remap`（布尔，默认 `false`）：是否允许重新映射

```lua
{
  key = '<leader>x',
  fallback = {
    key = 'dd',  -- 删除行（使用现有的 dd 映射）
    replace_keycodes = true,
    remap = true,  -- 如果 dd 被自定义映射，允许重新映射
  },
  handler = function() ... end,
}
```

#### 函数类型
执行函数以动态确定回退行为。函数可以返回：
- **`string`**：输入该字符串（使用 `replace_keycodes=true`、`remap=false`）
- **`table`**：与上述表回退格式相同
- **`nil`**：无回退

```lua
{
  key = '<leader>x',
  fallback = function()
    -- 基于上下文的动态回退
    if vim.fn.line('.') == 1 then
      return 'i第一行！<Esc>'
    elseif vim.bo.filetype == 'lua' then
      return { key = 'dd', remap = true }  -- 如果可用，使用重映射的 dd
    else
      return nil  -- 其他情况下无回退
    end
  end,
  handler = function() ... end,
}
```

**注意**：当为同一个按键定义多个具有不同优先级的处理器时，使用**最高优先级处理器**的回退。

## 示例：超级超级 Tab 键

这个综合示例展示了 maplayer.nvim 的强大功能，通过创建一个智能的 Tab 键来处理多种场景并保持适当的优先级顺序。这是一个真实世界的示例，展示了多个插件如何在同一个按键上协作而不会冲突：

```lua
require('maplayer').setup({
  -- 优先级 100：接受 blink.cmp 的补全
  {
    key = '<Tab>',
    mode = 'i',
    desc = '接受补全',
    priority = 100,
    condition = function()
      -- 检查 blink.cmp 补全菜单是否可见且已选择项目
      local blink = require('blink.cmp')
      return blink.is_visible() and blink.get_selected_item() ~= nil
    end,
    handler = function()
      require('blink.cmp').accept()
      return true
    end,
  },
  
  -- 优先级 90：接受 copilot 的 AI 建议
  {
    key = '<Tab>',
    mode = 'i',
    desc = '接受 Copilot 建议',
    priority = 90,
    condition = function()
      -- 检查 copilot 是否有建议
      return vim.fn['copilot#GetDisplayedSuggestion']().text ~= ''
    end,
    handler = function()
      vim.fn['copilot#Accept']()
      return true
    end,
  },
  
  -- 优先级 80：跳转到下一个代码片段占位符
  {
    key = '<Tab>',
    mode = 'i',
    desc = '跳转到下一个代码片段占位符',
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
  
  -- 优先级 70：使用 tabout.nvim 跳出括号
  {
    key = '<Tab>',
    mode = 'i',
    desc = 'Tab 跳出括号',
    priority = 70,
    condition = function()
      -- 检查光标是否在闭合括号/引号之前
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
  
  -- 优先级 60：当当前行缩进少于上一行时自动缩进
  {
    key = '<Tab>',
    mode = 'i',
    desc = '自动缩进以匹配上一行',
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
      return '<C-f>' -- 使用内置的 Ctrl-f 进行自动缩进
    end,
  },
  
  -- 当没有条件匹配时，默认的 Tab 行为会自动回退
})
```

这个示例展示了：
- 同一个按键的**多个处理器**具有不同的优先级
- 基于各种插件状态的**条件执行**
- 当没有条件匹配时的**回退行为**
- **关注点清晰分离** - 每个处理器都有单一职责

### 设计原则

**maplayer.nvim** 遵循扎实的软件工程原则：

- **开闭原则**：通过添加新的处理器来添加新功能，而不是修改现有的处理器。当你需要为一个按键添加新行为时，只需添加一个具有适当条件和优先级的新处理器。
  
- **单一职责原则**：每个处理器只做一件事。这使得处理器易于理解、测试和维护。

> **⚠️ 重要提醒**：记住只**全局调用一次** `setup()` 或 `make()`，并包含所有按键绑定规格。多次调用会覆盖之前的配置而不是合并它们。

## 从传统键映射迁移

### 之前（传统方法）

```lua
-- 冲突和复杂的条件逻辑
vim.keymap.set('n', '<CR>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-y>'
  elseif vim.bo.filetype == 'netrw' then
    -- 处理 netrw
    return '<CR>'
  else
    return '<CR>'
  end
end, { expr = true })
```

### 之后（maplayer 方法）

```lua
require('maplayer').setup({
  {
    key = '<CR>',
    mode = 'n',
    desc = '接受补全',
    priority = 100,
    condition = function() return vim.fn.pumvisible() == 1 end,
    handler = function() return '<C-y>' end,
  },
  {
    key = '<CR>',
    mode = 'n',
    desc = '在 netrw 中打开',
    priority = 50,
    condition = function() return vim.bo.filetype == 'netrw' end,
    handler = function() return '<CR>' end,
  },
})
```

更清晰、更易维护、更容易扩展！✨

## 高级技巧

### 优先级的稳定排序

优先级值用于排序，定义的顺序提供稳定的排序：

```lua
-- 如果两个处理器具有相同的优先级，
-- 先定义的将先被评估
require('maplayer').setup({
  { key = '<leader>f', priority = 10, desc = '第一个', handler = function() return true end },
  { key = '<leader>f', priority = 10, desc = '第二个', handler = function() return true end },
})
-- "第一个"将在"第二个"之前尝试
```

### 使用 `make()` 进行延迟绑定

`make()` 函数生成键映射规格而不立即注册它们。这主要用于**延迟绑定**，允许你使用 [which-key.nvim](https://github.com/folke/which-key.nvim) 的界面进行按键绑定注册。

以下是使用 `make()` 与 which-key 的示例：

```lua
-- 使用 maplayer 生成键映射规格
local keymaps = require('maplayer').make({
  {
    key = '<leader>ff',
    mode = 'n',
    desc = '查找文件',
    handler = function()
      require('telescope.builtin').find_files()
      return true
    end,
  },
  {
    key = '<leader>fg',
    mode = 'n',
    desc = '实时 grep',
    handler = function()
      require('telescope.builtin').live_grep()
      return true
    end,
  },
  {
    key = '<leader>fb',
    mode = 'n',
    desc = '查找缓冲区',
    handler = function()
      require('telescope.builtin').buffers()
      return true
    end,
  },
})

-- 使用 which-key 注册
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

这种延迟绑定方法让你可以：
- 使用 which-key 的注册界面，同时受益于 maplayer 的条件处理器链
- 使用 which-key 的分组和显示功能组织按键绑定
- 为实际的按键处理逻辑保持 maplayer 的责任链模式

### 使用 maplayer 实现插件懒加载

**maplayer.nvim** 可以为大多数不依赖 `autocmd` 事件的插件实现懒加载。通过延迟插件加载直到第一次按键，你可以显著提升 Neovim 的启动速度。

#### 工作原理

使用 [lazy.nvim](https://github.com/folke/lazy.nvim) 时，你可以：
1. 为插件设置 `lazy = true`
2. 禁用插件的默认按键绑定
3. 使用 maplayer 处理器，仅在需要时 `require()` 插件
4. 返回插件的按键序列（如 `<Plug>` 映射）

在首次按键时，lazy.nvim 会在调用 `require()` 时自动加载插件。

#### 示例：懒加载 nvim-surround

[nvim-surround](https://github.com/kylechui/nvim-surround) 提供用于文本环绕操作的 `<Plug>` 映射。以下是如何使用 maplayer 懒加载它：

```lua
-- 在你的 lazy.nvim 配置中
{
  'kylechui/nvim-surround',
  lazy = true,
  opts = {
    keymaps = {
      -- 禁用所有默认按键映射
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

-- 在你的 maplayer 设置中
require('maplayer').setup({
  {
    key = 'ys',
    mode = 'n',
    desc = '添加环绕',
    handler = function()
      require('nvim-surround')  -- 懒加载插件
      return '<Plug>(nvim-surround-normal)'
    end,
  },
  {
    key = 'yss',
    mode = 'n',
    desc = '为整行添加环绕',
    handler = function()
      require('nvim-surround')
      return '<Plug>(nvim-surround-normal-cur)'
    end,
  },
  {
    key = 'ds',
    mode = 'n',
    desc = '删除环绕',
    handler = function()
      require('nvim-surround')
      return '<Plug>(nvim-surround-delete)'
    end,
  },
  {
    key = 'cs',
    mode = 'n',
    desc = '更改环绕',
    handler = function()
      require('nvim-surround')
      return '<Plug>(nvim-surround-change)'
    end,
  },
  {
    key = 'S',
    mode = 'x',
    desc = '在可视模式下添加环绕',
    handler = function()
      require('nvim-surround')
      return '<Plug>(nvim-surround-visual)'
    end,
  },
})
```

这种方法适用于任何提供 `<Plug>` 映射或命令序列的插件。

### maplayer 不做什么

**maplayer 设计用于全局按键绑定管理。** 它不直接支持缓冲区局部映射（即 `buffer = true` 选项），因为这会使全局按键绑定协调变得复杂。

#### 使用 make() 实现缓冲区局部映射

如果你需要缓冲区局部按键绑定，可以使用 `make()` 生成按键映射并通过 `autocmd` 注册它们：

```lua
local maplayer = require('maplayer')

-- 为特定文件类型生成按键映射
local markdown_maps = maplayer.make({
  {
    key = '<CR>',
    mode = 'n',
    desc = '跟随链接',
    handler = function()
      -- Markdown 特定逻辑
      vim.cmd('normal! gx')
      return true
    end,
  },
})

-- 从 opts 中移除 buffer 字段并使用 autocmd 注册
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(args)
    for _, spec in ipairs(markdown_maps) do
      -- 如果 opts 中存在 buffer 字段，清除它
      local opts = vim.tbl_extend('force', spec.opts, { buffer = args.buf })
      vim.keymap.set(spec.mode, spec.lhs, spec.rhs, opts)
    end
  end,
})
```

这种模式允许你：
- 为缓冲区局部按键绑定使用 maplayer 的条件处理器链
- 保持责任链模式
- 通过 autocmd 仅为特定缓冲区设置按键绑定

### 调试

maplayer.nvim 包含内置的日志系统，帮助你调试按键绑定配置。

#### 启用日志

要启用日志，在 `setup()` 函数中传入 `log` 配置：

```lua
require('maplayer').setup({
  -- 可选：启用日志
  log = {
    enabled = true,
    level = 'DEBUG',  -- 选项: 'DEBUG', 'INFO', 'WARN', 'ERROR'
  },
  -- 你的按键绑定
  {
    key = '<leader>ff',
    mode = 'n',
    desc = '查找文件',
    handler = function()
      require('telescope.builtin').find_files()
      return true
    end,
  },
})
```

#### 日志级别

日志系统支持四个详细程度级别：

- **`DEBUG`**：最详细 - 记录每次条件检查、处理器执行和返回值
- **`INFO`**：记录按键按下和哪些处理器成功（默认不使用）
- **`WARN`**：仅记录警告
- **`ERROR`**：仅记录错误

**注意**：默认情况下，仅使用 DEBUG 级别的日志进行详细故障排除。

#### 日志输出

启用日志后，消息将写入到 Neovim 的日志文件。你可以使用 `:lua print(vim.fn.stdpath('log'))` 查看日志文件位置，或使用 `:messages` 查看消息。

示例日志消息：

```
[maplayer] [DEBUG] Registering key binding: <Tab> mode: i descriptions: { "接受补全", "跳转到下一个代码片段占位符" }
[maplayer] [DEBUG] Key pressed: <Tab> in mode: i
[maplayer] [DEBUG] Trying handler 1 for key <Tab>
[maplayer] [DEBUG] Checking mode for key <Tab> desc: 接受补全 mode_ok: true
[maplayer] [DEBUG] Checking condition for key <Tab> desc: 接受补全 condition: true
[maplayer] [DEBUG] Executing handler for key <Tab> desc: 接受补全
[maplayer] [DEBUG] Handler result for key <Tab> desc: 接受补全 result: true
[maplayer] [DEBUG] Handler 1 succeeded for key <Tab> return value: true
```

**注意**：DEBUG 级别的消息会记录到 Neovim 日志文件中，也可以通过 `:messages` 查看。WARN 和 ERROR 消息还会在编辑器中显示为通知。

#### 高级用法

你也可以在处理器中添加自定义日志：

```lua
require('maplayer').setup({
  {
    key = '<leader>d',
    desc = '调试处理器',
    handler = function()
      print('处理器已执行！')
      print('当前缓冲区：', vim.api.nvim_get_current_buf())
      print('当前文件类型：', vim.bo.filetype)
      -- 你的实际处理器逻辑在这里
      return true
    end,
  },
})
```

## 工作原理

在内部，maplayer：

1. **规范化**所有 keyspecs（处理模式扩展、尖括号键如 `<C-A>` 和 `<c-a>` 的大小写规范化等）
2. **排序**按键和优先级的处理器（稳定排序）
3. **包装**每个处理器及其条件检查
4. **合并**相同键+模式的条件包装处理器到一个链中
5. **生成**一个迭代遍历链的单一函数
6. **注册**最终处理器到 `vim.keymap.set()`

当你按下一个按键时：
- 合并的函数执行
- 条件包装的处理器按优先级顺序评估（优先级高的先）
- 执行第一个条件返回 true 的处理器
- 如果处理器返回一个值，链停止
- 如果没有处理器成功，则回退原始按键（回退）

## 贡献

欢迎贡献！请随时提交问题或拉取请求。

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 致谢

灵感来自 VS Code 的按键绑定系统和责任链设计模式。
