---@class (exact) SimpleJsonCache : JsonCache

local json_cache = require("AnomalyInvestigationEditor.util.misc.json_cache")

---@class SimpleJsonCache
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = json_cache })

---@param path string
---@return SimpleJsonCache
function this:new(path)
    local o = json_cache.new(self, path)
    setmetatable(o, self)
    ---@cast o SimpleJsonCache

    return o
end

function this:dump()
    json.dump_file(self.path, self._json_map)
end

---@return boolean
function this:init()
    local t = json.load_file(self.path)
    if not t then
        self:dump()
    else
        self._json_map = t
    end

    return true
end

return this
