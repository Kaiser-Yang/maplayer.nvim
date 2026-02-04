local M = {}
local util = require('maplayer.util')

--- Make letters inside angle brackets lowercase, except for
--- '<M-A>' or '<m-A>', which become '<m-A>',
--- which is because <m-a> and <M-a> are equivalent in Neovim,
--- but <m-a> and <m-A> are not.
--- @param s string
--- @return string
local function lower_bracket(s)
  local res, _ = s:gsub('%b<>', function(m)
    local inner = m:sub(2, -2)
    if inner:match('^[mM]%-%a$') then
      inner = 'm' .. inner:sub(2)
    else
      inner = inner:lower()
    end
    return '<' .. inner .. '>'
  end)
  return res
end

local m_map = {
  n = { 'n', 'niI', 'niR', 'niV', 'nt', 'ntT' },
  x = { 'v', 'V', '', 'vs', 'Vs', 's' },
  s = { 's', 'S', '' },
  o = { 'no', 'nov', 'noV', 'no' },
  i = { 'i', 'ic', 'ix' },
  c = { 'c', 'cr', 'cv', 'cvr' },
}
-- INFO:
-- This may be incorrect,
-- because Lang-Arg mode contains modes after hitting f, F, t and T in normal mode
m_map.l = { unpack(m_map.i), unpack(m_map.c), 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' }
--- @param mode string|string[]
--- @return boolean
local function check_mode(mode)
  -- We do not know how to check Lang-Arg mode, just return true
  if mode == 'l' then return true end
  local current_mode = vim.api.nvim_get_mode().mode
  for _, m in ipairs(util.ensure_list(mode)) do
    if m_map[m] and vim.tbl_contains(m_map[m], current_mode) then return true end
  end
  return false
end

--- @return MapLayer.HandlerFunc
local function condition_wrap(mode, condition, handler)
  return function()
    -- NOTE:
    -- We can not remove the check_mode here, because we can not bind only for Lang-Arg
    if check_mode(mode) and condition() then return handler() end
  end
end

--- Normalise keys in a KeySpec, making sure '<C-A>' and '<c-a>' are treated the same.
--- @param t MapLayer.KeySpec[]
--- @return table<string, table<string, MapLayer.MergedKeySpec>>
local function normalise_key(t)
  for _, key_spec in ipairs(t) do
    key_spec.key = lower_bracket(key_spec.key)
    --- @type string[]
    local mode_expanded = {}
    for _, m in ipairs(util.ensure_list(key_spec.mode or 'n')) do
      assert(type(m) == 'string')
      if m == '' then
        m = { 'n', 'x', 's', 'o' }
      elseif m == 'v' then
        m = { 's', 'x' }
      elseif m == '!' then
        m = { 'i', 'c' }
      end
      for _, mm in ipairs(util.ensure_list(m)) do
        table.insert(mode_expanded, mm)
      end
    end
    key_spec.mode = mode_expanded
    key_spec.desc = key_spec.desc or ''
    key_spec.priority = key_spec.priority or 0
    key_spec.noremap = key_spec.noremap == nil and true or key_spec.noremap
    key_spec.remap = key_spec.remap or false
    key_spec.condition = key_spec.condition or function() return true end
    if type(key_spec.handler) == 'string' then
      local value = tostring(key_spec.handler)
      key_spec.handler = function() return value end
    end
    key_spec.handler = condition_wrap(key_spec.mode, key_spec.condition, key_spec.handler)
  end
  table.sort(t, function(a, b)
    if a.key ~= b.key then return a.key < b.key end
    return a.priority > b.priority
  end)
  --- @type table<string, table<string, MapLayer.MergedKeySpec>>
  local res = {} -- temp[mode][key] = MergedKeySpec
  for _, key_spec in ipairs(t) do
    local mode = key_spec.mode
    assert(type(mode) == 'table')
    assert(type(key_spec.handler) == 'function')
    for _, m in ipairs(mode) do
      assert(type(m) == 'string')
      if not res[m] then res[m] = {} end
      --- @type table<string, MapLayer.MergedKeySpec>
      local tmp = res[m]
      local key = key_spec.key
      if not tmp[key] then
        tmp[key] = {
          key = key,
          mode = m,
          desc = { key_spec.desc },
          handler = { { handler = key_spec.handler, remap = key_spec.remap or key_spec.noremap == false } },
        }
      else
        assert(key == tmp[key].key)
        assert(m == tmp[key].mode)
        if not vim.tbl_contains(tmp[key].desc, key_spec.desc) then table.insert(tmp[key].desc, key_spec.desc) end
        table.insert(tmp[key].handler, { key_spec.handler, remap = key_spec.remap or key_spec.noremap == false })
      end
    end
  end
  return res
end
--- @param key_spec MapLayer.MergedKeySpec
--- @return vim.keymap.set.Opts
local function generate_opt(key_spec)
  return {
    desc = table.concat(vim.tbl_filter(function(value) return not value:match('^%s*$') end, key_spec.desc), '; '),
  }
end

--- @param key_spec MapLayer.MergedKeySpec
--- @return MapLayer.HandlerFunc
local function handler_wrap(key_spec)
  return function()
    local ret
    for _, handler in ipairs(key_spec.handler) do
      ret = handler.handler()
      if ret then
        if type(ret) == 'string' then util.feedkeys(ret, (handler.remap and 'm' or 'n') .. 't') end
        return
      end
    end
    -- Always fallback to the default key when failure
    util.feedkeys(key_spec.key, 'nt')
  end
end

--- @param opt MapLayer.KeySpec|MapLayer.KeySpec[]
--- @return nil
function M.setup(opt)
  opt = normalise_key(util.ensure_list(opt))
  for mode, spec in pairs(opt) do
    for key, key_spec in pairs(spec) do
      assert(key == key_spec.key)
      vim.keymap.set(mode, key, handler_wrap(key_spec), generate_opt(key_spec))
    end
  end
end

return M
