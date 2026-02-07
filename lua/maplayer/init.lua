local M = {}
local util = require('maplayer.util')
local logger = require('maplayer.logger')

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
local function condition_wrap(mode, condition, handler, key, desc)
  return function()
    -- NOTE:
    -- We can not remove the check_mode here, because we can not bind only for Lang-Arg
    local mode_ok = check_mode(mode)
    logger.debug('Checking mode for key', key, 'desc:', desc, 'mode_ok:', mode_ok)
    if mode_ok then
      local cond_ok = condition()
      logger.debug('Checking condition for key', key, 'desc:', desc, 'condition:', cond_ok)
      if cond_ok then
        logger.debug('Executing handler for key', key, 'desc:', desc)
        local result = handler()
        logger.debug('Handler result for key', key, 'desc:', desc, 'result:', result)
        return result
      end
    end
  end
end

--- Normalise keys in a KeySpec, making sure '<C-A>' and '<c-a>' are treated the same.
--- @param t MapLayer.KeySpec[]
--- @return table<string, table<string, MapLayer.MergedKeySpec>>
local function normalise_key(t)
  for idx, key_spec in ipairs(t) do
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
    local original_desc = key_spec.desc or ''
    key_spec.desc = original_desc
    -- NOTE: Add idx here to make "sort" stable
    key_spec.priority = (key_spec.priority or 0) + idx
    key_spec.noremap = key_spec.noremap == nil and true or key_spec.noremap
    key_spec.remap = key_spec.remap or false
    key_spec.replace_keycodes = key_spec.replace_keycodes == nil and true or key_spec.replace_keycodes
    key_spec.count = key_spec.count or false

    -- Normalize condition: convert boolean to function
    local original_condition = key_spec.condition
    if original_condition == nil then
      key_spec.condition = function() return true end
    elseif type(original_condition) == 'boolean' then
      key_spec.condition = function() return original_condition end
    end

    -- Store original handler before wrapping
    if type(key_spec.handler) == 'string' then
      local value = tostring(key_spec.handler)
      key_spec.handler = function() return value end
    end
    key_spec.handler = condition_wrap(key_spec.mode, key_spec.condition, key_spec.handler, key_spec.key, original_desc)
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
          handler = {
            {
              handler = key_spec.handler,
              remap = key_spec.remap or key_spec.noremap == false,
              replace_keycodes = key_spec.replace_keycodes,
              count = key_spec.count,
              desc = key_spec.desc,
            },
          },
        }
      else
        assert(key == tmp[key].key)
        assert(m == tmp[key].mode)
        if not vim.tbl_contains(tmp[key].desc, key_spec.desc) then table.insert(tmp[key].desc, key_spec.desc) end
        table.insert(tmp[key].handler, {
          handler = key_spec.handler,
          remap = key_spec.remap or key_spec.noremap == false,
          replace_keycodes = key_spec.replace_keycodes,
          count = key_spec.count,
          desc = key_spec.desc,
        })
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
    logger.debug('Key pressed:', key_spec.key, 'in mode:', key_spec.mode)
    local ret
    for idx, handler in ipairs(key_spec.handler) do
      logger.debug('Trying handler', idx, 'for key', key_spec.key)
      ret = handler.handler()
      if ret then
        logger.debug('Handler', idx, 'succeeded for key', key_spec.key, 'return value:', ret)
        if type(ret) == 'string' then
          -- Prepend count if count flag is true and vim.v.count > 0
          local keys_to_feed = ret
          if handler.count and vim.v.count > 0 then
            keys_to_feed = tostring(vim.v.count) .. ret
            logger.debug('Prepending count:', vim.v.count, 'to keys:', ret)
          end
          logger.debug('Feeding keys:', keys_to_feed, 'remap:', handler.remap, 'replace_keycodes:', handler.replace_keycodes)
          util.feedkeys(keys_to_feed, (handler.remap and 'm' or 'n') .. 't', handler.replace_keycodes)
        end
        return
      end
      logger.debug('Handler', idx, 'declined for key', key_spec.key)
    end
    -- Always fallback to the default key when failure
    logger.debug('All handlers declined for key', key_spec.key, 'falling back to default behavior')
    util.feedkeys(key_spec.key, 'nt')
  end
end

--- @param opt MapLayer.SetupOpts
--- @return MapLayer.MapSetArg[]
function M.make(opt)
  --- @type MapLayer.MapSetArg[]
  local res = {}

  -- Extract keyspecs (array elements only, excluding log config)
  local keyspecs = {}
  for k, v in pairs(opt) do
    if type(k) == 'number' then table.insert(keyspecs, v) end
  end

  local normalized_opt = normalise_key(keyspecs)
  logger.debug('Normalized keybindings:', normalized_opt)
  for mode, spec in pairs(normalized_opt) do
    for key, key_spec in pairs(spec) do
      assert(key == key_spec.key)
      assert(mode == key_spec.mode)
      logger.debug('Registering key binding:', key, 'mode:', mode, 'descriptions:', key_spec.desc)
      table.insert(res, {
        mode = mode,
        lhs = key,
        rhs = handler_wrap(key_spec),
        opts = generate_opt(key_spec),
      })
    end
  end
  return res
end

--- @param opt MapLayer.SetupOpts
--- @return nil
function M.setup(opt)
  opt = opt or {}

  -- Extract and configure logger if log config is provided
  if opt.log then
    local log_opts = opt.log
    -- Convert string level to number if needed
    if type(log_opts.level) == 'string' then
      local level_num = logger.levels[log_opts.level:upper()]
      if level_num ~= nil then
        log_opts.level = level_num
      else
        log_opts.level = logger.levels.INFO
      end
    end
    logger.setup(log_opts)
  end

  for _, spec in ipairs(M.make(opt)) do
    vim.keymap.set(spec.mode, spec.lhs, spec.rhs, spec.opts)
  end
end

return M
