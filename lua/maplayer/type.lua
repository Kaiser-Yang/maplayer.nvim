--- @alias MapLayer.HandlerReturn string|boolean|nil

--- @alias MapLayer.HandlerFunc fun(): MapLayer.HandlerReturn

--- @class MapLayer.KeySpec
--- @field key string The key to be mapped
--- @field mode? string|string[] Default to 'n'
--- @field desc? string Default to ''
--- @field condition? fun(): boolean Default to a function always returning true
--- @field priority? integer Default to 0
--- @field noremap? boolean Default to true
--- @field remap? boolean Default to false
--- @field replace_keycodes? boolean Default to true
--- @field handler MapLayer.HandlerFunc|string

--- @class MapLayer.LogConfig
--- @field enabled? boolean Enable or disable logging (default: false)
--- @field level? number|string Log level: 'DEBUG', 'INFO', 'WARN', 'ERROR', or number (default: 'INFO')

--- @class MapLayer.SetupOpts
--- @field log? MapLayer.LogConfig Logger configuration
--- @field [integer] MapLayer.KeySpec Array of keyspecs

--- @class MapLayer.MergedHandlerFunc
--- @field handler MapLayer.HandlerFunc
--- @field remap boolean
--- @field replace_keycodes boolean

--- @class MapLayer.MergedKeySpec
--- @field key string
--- @field mode string
--- @field desc string[]
--- @field handler MapLayer.MergedHandlerFunc[]

--- @class MapLayer.MapSetArg
--- @field mode string[]
--- @field lhs string
--- @field rhs function
--- @field opts vim.keymap.set.Opts
