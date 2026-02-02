--- @alias MapLayer.KeyHandlerReturn string|boolean|nil

--- @alias MapLayer.KeyHandlerFunc fun(): MapLayer.KeyHandlerReturn

--- @class MapLayer.KeySpec
--- @field key string The key to be mapped
--- @field mode? string|string[] Default to 'n'
--- @field desc? string Default to ''
--- @field condition? fun(): boolean Default to a function always returning true
--- @field priority? integer Default to 0
--- @field handler MapLayer.KeyHandlerFunc|string

--- @class MapLayer.MergedKeySpec
--- @field key string
--- @field mode string[]
--- @field desc string[]
--- @field handler MapLayer.KeyHandlerFunc[]
