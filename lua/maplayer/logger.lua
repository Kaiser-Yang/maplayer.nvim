local M = {}

--- Log levels
M.levels = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
  OFF = 5,
}

--- Default configuration
local config = {
  enabled = false,
  level = M.levels.INFO,
  prefix = '[maplayer]',
}

--- Initialize the logger with configuration
--- @param opts? MapLayer.LogConfig Configuration options
function M.setup(opts)
  opts = opts or {}
  config.enabled = opts.enabled ~= nil and opts.enabled or false
  config.level = opts.level or M.levels.INFO
end

--- Check if a log level is enabled
--- @param level number The log level to check
--- @return boolean
local function should_log(level) return config.enabled and level >= config.level end

local function _write(level, msg)
  if not should_log(level) then return end
  local f, err = io.open(vim.fn.stdpath('log') .. '/maplayer.log', 'a')
  if not f then
    vim.notify(string.format('Failed to open log file %s: %s', M.filepath, err), vim.log.levels.ERROR)
    return
  end
  f:write(msg .. '\n')
  f:close()
end

--- Format a log message
--- @param level_name string The log level name
--- @param ... any The message parts
--- @return string
local function format_message(level_name, ...)
  local parts = { ... }
  local message = table.concat(
    vim.tbl_map(function(v)
      if type(v) == 'table' then
        return vim.inspect(v)
      else
        return tostring(v)
      end
    end, parts),
    ' '
  )
  return string.format('%s [%s] %s', config.prefix, level_name, message)
end

--- Log a debug message
--- @param ... any Message parts
function M.debug(...) _write(M.levels.DEBUG, format_message('DEBUG', ...)) end

--- Log an info message
--- @param ... any Message parts
function M.info(...) _write(M.levels.INFO, format_message('INFO', ...)) end

--- Log a warning message
--- @param ... any Message parts
function M.warn(...) _write(M.levels.WARN, format_message('WARN', ...)) end

--- Log an error message
--- @param ... any Message parts
function M.error(...) _write(M.levels.ERROR, format_message('ERROR', ...)) end

return M
