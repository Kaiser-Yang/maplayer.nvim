local function run()
  vim.opt.runtimepath:prepend(vim.fn.getcwd())
  local maplayer = require('maplayer')
  local util = require('maplayer.util')
  local function make(opts)
    local mappings = maplayer.make({ vim.tbl_extend('force', { key = '<BS>', mode = 'n' }, opts) })
    assert(#mappings == 1)
    return mappings[1]
  end

  -- Verify that direct results stay in the input parser instead of being fed again.
  local feedkeys, fed = util.feedkeys, {}
  util.feedkeys = function(keys, mode, replace) fed[#fed + 1] = { keys, mode, replace } end
  local direct = make({ expr = true, direct = true, handler = function() return '<Del>' end })
  assert(direct.opts.expr and direct.opts.replace_keycodes)
  assert(direct.rhs() == '<Del>' and #fed == 0)
  for _, result in ipairs({ true, false, '' }) do
    local noop = make({ expr = true, direct = true, handler = function() return result end })
    assert(noop.rhs() == '' and #fed == 0)
  end
  assert(make({ expr = true, direct = true, handler = function() end }).rhs() == '')
  local declined = make({ expr = true, direct = true, condition = false, handler = function() error('not called') end })
  assert(declined.rhs() == '' and #fed == 0)
  local raw = make({
    expr = true,
    direct = true,
    remap = true,
    replace_keycodes = false,
    handler = function() return '<Del>' end,
  })
  assert(raw.opts.remap and raw.opts.replace_keycodes == false and raw.rhs() == '<Del>')
  local existing = make({ expr = true, handler = function() return '<Tab>' end })
  existing.rhs()
  assert(#fed == 1 and fed[1][1] == '<Tab>' and fed[1][2] == 'n')
  local fallback = make({ expr = true, fallback = true, handler = function() return false end })
  fallback.rhs()
  assert(#fed == 2 and fed[2][1] == '<bs>')
  util.feedkeys = feedkeys

  assert(not pcall(make, { direct = true, handler = function() return '' end }))
  assert(not pcall(make, { direct = true, expr = true, fallback = true, handler = function() return '' end }))
  for _, priority in ipairs({ -1, 1 }) do
    assert(not pcall(maplayer.make, {
      { key = '<BS>', direct = true, expr = true, priority = priority, handler = function() return '' end },
      { key = '<BS>', expr = true, handler = function() return '' end },
    }))
  end

  maplayer.setup({
    {
      key = '<BS>',
      mode = 'nx',
      expr = true,
      direct = true,
      handler = function() return vim.v.count > 0 and '<Del>' or '' end,
    },
  })
  local lines = {}
  for i = 1, 200 do
    lines[i] = '1234567890 abcdefghij'
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.fn.setreg('"', 'unchanged register')
  local function keys(input) vim.api.nvim_feedkeys(vim.keycode(input), 'xt', false) end
  local function check(input, row, mode)
    keys('<Esc>')
    vim.api.nvim_win_set_cursor(0, { 10, 4 })
    keys(input)
    assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { row, 4 }), input)
    assert(vim.api.nvim_get_mode().mode == mode, input .. ': selection changed')
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), lines), input .. ': text changed')
    assert(vim.fn.getreg('"') == 'unchanged register', input .. ': register changed')
  end
  check('<BS>', 10, 'n')
  check('<BS><BS>j', 11, 'n')
  check('12<BS>j', 11, 'n')
  check('123<BS><BS>j', 11, 'n')
  check('12<BS>3j', 23, 'n')
  check('12<BS><BS><BS>j', 11, 'n')
  check('100<BS>j', 20, 'n')
  check('v<BS>j', 11, 'v')
  check('v12<BS>j', 11, 'v')
  check('v12<BS>3j', 23, 'v')
  check('v12<BS><BS><BS>j', 11, 'v')
  check('V123<BS>j', 22, 'V')
  check('<C-v>12<BS>j', 11, '\22')
  keys('<Esc>')

  -- Remapping and literal key strings must still follow the declared options.
  vim.keymap.set('n', 'Q', 'j')
  local remapped = make({ expr = true, direct = true, remap = true, handler = function() return 'Q' end })
  vim.keymap.set(remapped.mode, remapped.lhs, remapped.rhs, remapped.opts)
  vim.api.nvim_win_set_cursor(0, { 10, 4 })
  keys('<BS>')
  assert(vim.api.nvim_win_get_cursor(0)[1] == 11)
  local literal = make({
    key = '<F3>',
    mode = 'i',
    expr = true,
    direct = true,
    replace_keycodes = false,
    handler = function() return '<Del>' end,
  })
  vim.keymap.set(literal.mode, literal.lhs, literal.rhs, literal.opts)
  vim.api.nvim_win_set_cursor(0, { 10, 4 })
  keys('i<F3><Esc>')
  assert(vim.api.nvim_get_current_line() == '1234<Del>567890 abcdefghij', 'Literal key string was replaced')

  print(
    'Direct expression mappings: count editing, no-op, condition, remap, keycodes, validation, and compatibility passed'
  )
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd('cquit 1')
end
vim.cmd('qa!')
