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

--- @return MapLayer.KeyHandlerFunc
local function condition_wrap(mode, condition, handler)
  return function()
    -- NOTE:
    -- We can not remove the check_mode here, because we can not bind only for Lang-Arg
    if check_mode(mode) and condition() then return handler() end
  end
end

--- Normalise keys in a KeySpec, making sure '<C-A>' and '<c-a>' are treated the same.
--- @param t MapLayer.KeySpec[]
--- @return table<string, MapLayer.MergedKeySpec>
local function normalise_key(t)
  --- @type table<string, MapLayer.MergedKeySpec>
  local res = {}
  for _, key_spec in ipairs(t) do
    key_spec.key = lower_bracket(key_spec.key)
    key_spec.mode = key_spec.mode or 'n'
    key_spec.desc = key_spec.desc or ''
    key_spec.priority = key_spec.priority or 0
    key_spec.condition = key_spec.condition or function() return true end
    if type(key_spec.handler) == 'string' then
      local value = key_spec.handler
      key_spec.handler = function()
        ---@diagnostic disable-next-line: return-type-mismatch
        return value
      end
    end
    key_spec.handler = condition_wrap(key_spec.mode, key_spec.condition, key_spec.handler)
  end
  table.sort(t, function(a, b)
    if a.key ~= b.key then return a.key < b.key end
    return a.priority > b.priority
  end)
  for _, key_spec in ipairs(t) do
    if not res[key_spec.key] then
      res[key_spec.key] = {
        key = key_spec.key,
        mode = util.ensure_list(key_spec.mode),
        desc = util.ensure_list(key_spec.desc),
        handler = util.ensure_list(key_spec.handler),
      }
    else
      local key = key_spec.key
      assert(key == res[key].key)
      for _, mode in ipairs(util.ensure_list(key_spec.mode)) do
        table.insert(res[key].mode, mode)
      end
      for _, desc in ipairs(util.ensure_list(key_spec.desc)) do
        table.insert(res[key].desc, desc)
      end
      for _, handler in ipairs(util.ensure_list(key_spec.handler)) do
        table.insert(res[key].handler, handler)
      end
    end
  end
  for _, v in pairs(res) do
    v.mode = util.unique(v.mode)
    v.desc = util.unique(v.desc)
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
--- @return MapLayer.KeyHandlerFunc
local function handler_wrap(key_spec)
  return function()
    local ret
    for _, handler in ipairs(key_spec.handler) do
      ret = handler()
      if ret then
        if type(ret) == 'string' then util.feedkeys(ret, 'nt') end
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
  for _, key_spec in pairs(opt) do
    vim.keymap.set(key_spec.mode, key_spec.key, handler_wrap(key_spec), generate_opt(key_spec))
  end
end

return M
