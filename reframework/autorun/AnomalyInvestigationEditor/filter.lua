---@class MysterySearch : SearchBase
---@field data FilterData
---@field all_items table<integer, boolean>
---@field query fun(self: MysterySearch, query: string): integer[]

---@class (exact) FilterData
---@field main_monster table<string, table<integer, boolean>>
---@field monster table<string, table<integer, boolean>>
---@field level table<integer, table<integer, boolean>>
---@field player table<integer, table<integer, boolean>>
---@field time table<integer, table<integer, boolean>>
---@field life table<integer, table<integer, boolean>>
---@field tod table<string, table<integer, boolean>>
---@field map table<integer, table<integer, boolean>>
---@field special table<string, table<integer, boolean>>
---@field lock table<string, table<integer, boolean>>
---@field valid table<string, table<integer, boolean>>
---@field rank table<integer, table<integer, boolean>>
---@field target_num table<integer, table<integer, boolean>>
---@field quest_id table<integer, table<integer, boolean>>
---@field extra_map table<string, table<integer, boolean>>
---@field invader table<string, table<integer, boolean>>

local config = require("AnomalyInvestigationEditor.config.init")
local data = require("AnomalyInvestigationEditor.data.init")
local game_data = require("AnomalyInvestigationEditor.util.game.data")
local search_base = require("AnomalyInvestigationEditor.util.misc.search_base")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")

local snow_map = data.snow.map
local snow_enum = data.snow.enum
local rl = game_data.reverse_lookup

---@class MysterySearch
local this = search_base:new({
    main_monster = {},
    monster = {},
    map = {},
    level = {},
    player = {},
    time = {},
    life = {},
    tod = {},
    special = {},
    lock = {},
    valid = {},
    rank = {},
    target_num = {},
    quest_id = {},
    extra_map = {},
    invader = {},
})

---@param quest Quest
function this:remove(quest)
    local filter_data = self.data --[[@as table<string, table<any, table<integer, any>>>]]

    for _, category in pairs(filter_data) do
        for _, category_data in pairs(category) do
            category_data[quest.quest_no] = nil
        end
    end

    for _, category_data in pairs(self.all_text) do
        category_data[quest.quest_no] = nil
    end

    self.all_items[quest.quest_no] = nil
end

---@param quest Quest
function this:add(quest)
    local m_data = quest.mystery_data
    local no = quest.quest_no

    local main_em = m_data:getMainTargetEmType()
    local main_em_name = snow_map.em_data[main_em].name:lower()
    util_table.set_nested_value(self.data.main_monster, { main_em_name, no }, true)
    util_table.set_nested_value(self.data.monster, { main_em_name, no }, true)
    util_table.set_nested_value(self.all_text, { main_em_name, no }, true)

    local ems = quest.mystery_seed:getEnemyTypes()
    for i = 0, m_data._HuntTargetNum do
        local em = ems:get_Item(i)

        if em ~= 0 then
            local em_name = snow_map.em_data[em].name:lower()
            util_table.set_nested_value(self.data.monster, { em_name, no }, true)
        end
    end

    util_table.set_nested_value(self.data.invader, {
        (
            ems:get_Item(5) ~= 0 and config.lang:tr("misc.text_yes")
            or config.lang:tr("misc.text_no")
        ):lower(),
        no,
    }, true)
    util_table.set_nested_value(
        self.data.map,
        { snow_map.map_data[m_data._MapNo].name:lower(), no },
        true
    )
    util_table.set_nested_value(self.data.extra_map, {
        (
            snow_map.map_data[m_data._MapNo].is_extra and config.lang:tr("misc.text_yes")
            or config.lang:tr("misc.text_no")
        ):lower(),
        no,
    }, true)
    util_table.set_nested_value(
        self.all_text,
        { snow_map.map_data[m_data._MapNo].name:lower(), no },
        true
    )
    util_table.set_nested_value(self.data.level, { m_data._QuestLv, no }, true)
    util_table.set_nested_value(self.data.player, { m_data._QuestOrderNum, no }, true)
    util_table.set_nested_value(self.data.time, { m_data._TimeLimit, no }, true)
    util_table.set_nested_value(self.data.life, { m_data._QuestLife, no }, true)
    util_table.set_nested_value(self.data.target_num, { m_data._HuntTargetNum, no }, true)
    util_table.set_nested_value(self.data.quest_id, { no, no }, true)
    util_table.set_nested_value(
        self.data.rank,
        { snow_map.em_data[main_em].quest_rank + 1, no },
        true
    )
    util_table.set_nested_value(self.data.special, {
        (m_data._isSpecialQuestOpen and config.lang:tr("misc.text_yes") or config.lang:tr(
            "misc.text_no"
        )):lower(),
        no,
    }, true)
    util_table.set_nested_value(self.data.lock, {
        (m_data._IsLock and config.lang:tr("misc.text_yes") or config.lang:tr("misc.text_no")):lower(),
        no,
    }, true)
    util_table.set_nested_value(self.data.tod, {
        (
            m_data._StartTime == rl(snow_enum.tod, "Day") and config.lang:tr("misc.text_day")
            or config.lang:tr("misc.text_night")
        ):lower(),
        no,
    }, true)
    util_table.set_nested_value(self.data.valid, {
        (
            m_data._IsValidQuest and config.lang:tr("misc.text_yes")
            or config.lang:tr("misc.text_no")
        ):lower(),
        no,
    }, true)

    self.all_items[no] = true
end

return this
