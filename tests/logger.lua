local inspect = vim.inspect
local stdpath = vim.fn.stdpath
local log_dir = vim.fn.tempname()

local function run()
  vim.opt.runtimepath:prepend(vim.fn.getcwd())
  local logger = require('maplayer.logger')
  vim.fn.mkdir(log_dir, 'p')
  vim.fn.stdpath = function(kind)
    if kind == 'log' then return log_dir end
    return stdpath(kind)
  end
  local inspections = 0
  vim.inspect = function(...)
    inspections = inspections + 1
    return inspect(...)
  end
  local function log_all()
    for _, level in ipairs({ 'debug', 'info', 'warn', 'error' }) do
      logger[level]({ suppressed = true })
    end
  end
  local function lines() return vim.fn.readfile(log_dir .. '/maplayer.log') end

  -- Disabled messages must not serialize large keybinding tables.
  logger.setup()
  log_all()
  assert(inspections == 0, 'Disabled logging formatted its arguments')
  assert(vim.fn.filereadable(log_dir .. '/maplayer.log') == 0)

  -- Enabled logging must still filter levels before formatting and preserve output.
  logger.setup({ enabled = true, level = logger.levels.INFO })
  logger.debug({ suppressed = true })
  assert(inspections == 0, 'A filtered debug message formatted its arguments')
  logger.info('enabled', { answer = 42 })
  logger.warn('warning')
  logger.error('error')
  local output = table.concat(lines(), '\n')
  assert(inspections == 1)
  assert(output:find('[maplayer] [INFO] enabled', 1, true))
  assert(output:find('answer = 42', 1, true))
  assert(output:find('[maplayer] [WARN] warning', 1, true))
  assert(output:find('[maplayer] [ERROR] error', 1, true))

  logger.setup({ enabled = true, level = logger.levels.OFF })
  log_all()
  assert(inspections == 1, 'OFF logging formatted its arguments')
  assert(table.concat(lines(), '\n') == output)

  logger.setup({ enabled = true, level = logger.levels.DEBUG })
  logger.debug({ active = true })
  assert(inspections == 2)
  assert(table.concat(lines(), '\n'):find('[maplayer] [DEBUG]', 1, true))
  local enabled_output = table.concat(lines(), '\n')

  logger.setup({ enabled = false, level = logger.levels.DEBUG })
  log_all()
  assert(inspections == 2, 'Disabling a configured logger still formatted messages')
  assert(table.concat(lines(), '\n') == enabled_output)
  print('Logger filtering: disabled and filtered messages skip serialization; enabled output is preserved')
end

local ok, err = xpcall(run, debug.traceback)
vim.inspect = inspect
vim.fn.stdpath = stdpath
vim.fn.delete(log_dir, 'rf')
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd('cquit 1')
end
vim.cmd('qa!')
