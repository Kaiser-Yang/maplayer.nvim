--- @alias MapLayer.HandlerReturn string|boolean|nil

--- @alias MapLayer.HandlerFunc fun(): MapLayer.HandlerReturn

--- @class MapLayer.FallbackTable
--- @field key string The key to feedkeys
--- @field replace_keycodes boolean Whether to replace keycodes
--- @field remap? boolean Whether to allow remapping (default: false)

--- @alias MapLayer.FallbackFunc fun(): string|MapLayer.FallbackTable|nil

--- Fallback behavior when all handlers decline for a key.
--- Can be one of the following:
--- - boolean: true (default) = fallback to original key, false = no fallback
--- - string: feedkeys this string (always with replace_keycodes=true, remap=false)
--- - table: {key: string, replace_keycodes: boolean, remap: boolean} for custom feedkeys behavior
--- - function: executed to return string (replace_keycodes=true, remap=false), table, or nil (no fallback)
--- @alias MapLayer.Fallback boolean|string|MapLayer.FallbackTable|MapLayer.FallbackFunc

--- @class MapLayer.KeySpec
--- @field key string The key to be mapped
--- @field mode? string|string[] Default to 'n'
--- @field desc? string Default to ''
--- @field condition? fun(): boolean|boolean Default to a function always returning true
--- @field priority? integer Default to 0
--- @field noremap? boolean Default to true
--- @field remap? boolean Default to false
--- @field expr? boolean Default to false
--- @field replace_keycodes? boolean Default to true
--- @field count? boolean Default to false. When true, prepends vim.v.count to the returned string when vim.v.count > 0
--- @field fallback? MapLayer.Fallback Default to true. Controls fallback behavior when all handlers decline
--- @field handler MapLayer.HandlerFunc|string

--- @class MapLayer.LogConfig
--- @field enabled? boolean Enable or disable logging (default: false)
--- @field level? number|string Log level: 'DEBUG', 'INFO', 'WARN', 'ERROR', or number (default: 'INFO')

--- @class MapLayer.SetupOpts : MapLayer.KeySpec[]
--- @field log? MapLayer.LogConfig Logger configuration

--- @class MapLayer.MergedHandlerFunc
--- @field handler MapLayer.HandlerFunc
--- @field remap boolean
--- @field replace_keycodes boolean
--- @field count boolean
--- @field desc string Original description for debugging

--- @class MapLayer.MergedKeySpec
--- @field key string
--- @field mode string
--- @field desc string[]
--- @field expr? boolean
--- @field handler MapLayer.MergedHandlerFunc[]
--- @field fallback? MapLayer.Fallback The fallback option (uses the one from the highest priority handler)

--- @class MapLayer.MapSetArg
--- @field mode string[]
--- @field lhs string
--- @field rhs function
--- @field opts vim.keymap.set.Opts
