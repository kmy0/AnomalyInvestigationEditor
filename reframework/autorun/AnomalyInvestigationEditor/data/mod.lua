---@class ModData
---@field enum ModEnum
---@field ok boolean
---@field do_reload boolean
---@field initialized boolean

---@class (exact) ModEnum
---@field quest_check_result QuestCheckResult.*
---@field mode ModMode.*

local s = require("AnomalyInvestigationEditor.util.ref.singletons")

---@class ModData
local this = {
    ---@diagnostic disable-next-line: missing-fields
    enum = {},
}

---@enum QuestCheckResult
this.enum.quest_check_result = { ---@class QuestCheckResult.*
    OK = 0,
    MEMORY = 1 << 2,
    HUNT_NUM = 1 << 3,
    ORDER_NUM = 1 << 4,
    LIFE = 1 << 5,
    LEVEL = 1 << 6,
    TIME = 1 << 7,
    EM0 = 1 << 8,
    EM1 = 1 << 9,
    EM2 = 1 << 10,
    EM3 = 1 << 11,
    EM5 = 1 << 12,
    MAP = 1 << 13,
}
---@enum ModMode
this.enum.mode = { ---@class ModMode.*
    ONE = 1,
    ALL = 2,
}

---@return boolean
function this.init()
    this.initialized = true
    return true
end

---@return boolean, boolean -- is_ok, changed
function this.is_ok()
    local ret = not s.get_no_cache("snow.gui.fsm.questcounter.GuiQuestCounterFsmManager")
        and not s.get_no_cache("snow.gui.fsm.title.GuiTitleMenuFsmManager")
        and not s.get("snow.QuestManager"):isActiveQuest()
    local changed = this.ok ~= ret

    if changed then
        this.do_reload = true
    end

    this.ok = ret
    return ret, changed
end

return this
