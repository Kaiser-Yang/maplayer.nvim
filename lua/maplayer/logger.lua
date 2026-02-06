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
--- @param opts? table Configuration options
--- @param opts.enabled? boolean Enable or disable logging (default: false)
--- @param opts.level? number|string Log level (default: INFO)
function M.setup(opts)
  opts = opts or {}
  config.enabled = opts.enabled ~= nil and opts.enabled or false
  config.level = opts.level or M.levels.INFO
end

--- Check if a log level is enabled
--- @param level number The log level to check
--- @return boolean
local function should_log(level) return config.enabled and level >= config.level end

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
function M.debug(...)
  if should_log(M.levels.DEBUG) then print(format_message('DEBUG', ...)) end
end

--- Log an info message
--- @param ... any Message parts
function M.info(...)
  if should_log(M.levels.INFO) then print(format_message('INFO', ...)) end
end

--- Log a warning message
--- @param ... any Message parts
function M.warn(...)
  if should_log(M.levels.WARN) then vim.notify(format_message('WARN', ...), vim.log.levels.WARN) end
end

--- Log an error message
--- @param ... any Message parts
function M.error(...)
  if should_log(M.levels.ERROR) then vim.notify(format_message('ERROR', ...), vim.log.levels.ERROR) end
end

--- Check if logging is enabled
--- @return boolean
function M.is_enabled() return config.enabled end

--- Get the current log level
--- @return number
function M.get_level() return config.level end

return M
