---@class (exact) Quest
---@field mystery_data snow.quest.RandomMysteryQuestData
---@field mystery_seed snow.quest.RandomMysteryQuestSeed
---@field ems snow.enemy.EnemyDef.EmTypes[]
---@field total_memory number
---@field quest_no integer
---@field status string
---@field seed_status string
---@field seed_flag QuestCheckResult
---@field seed_memory number

---@class MysteryEditor
---@field filter MysterySearch
---@field current_quest Quest?
---@field quest_data table<integer, Quest>
---@field spoof_seed snow.quest.RandomMysteryQuestSeed?
---@field spoof_em snow.enemy.EnemyDef.EmTypes?
---@field size integer

local config = require("AnomalyInvestigationEditor.config.init")
local data = require("AnomalyInvestigationEditor.data.init")
local e = require("AnomalyInvestigationEditor.util.game.enum")
local m = require("AnomalyInvestigationEditor.util.ref.methods")
local s = require("AnomalyInvestigationEditor.util.ref.singletons")
local util_game = require("AnomalyInvestigationEditor.util.game.init")
local util_ref = require("AnomalyInvestigationEditor.util.ref.init")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")

local snow_map = data.snow.map

---@class MysteryEditor
local this = {
    quest_data = {},
    filter = require("AnomalyInvestigationEditor.filter"),
    size = 0,
}

---@protected
---@param mystery_data snow.quest.RandomMysteryQuestData
---@return Quest
function this._make_quest(mystery_data)
    local mystery_seed = s.get("snow.QuestManager")
        :getRandomQuestSeedFromQuestNo(mystery_data._QuestNo)

    ---@type Quest
    local quest = {
        mystery_data = mystery_data,
        mystery_seed = mystery_seed,
        total_memory = data.get_em_use_memory(mystery_seed),
        name = "",
        quest_no = mystery_data._QuestNo,
        ems = util_game.system_array_to_lua(mystery_seed:getEnemyTypes()),
        status = e.get("snow.quest.nRandomMysteryQuest.QuestCheckResult")[m.checkRandomMysteryQuestOrderBan(
            mystery_data,
            false
        )],
        seed_flag = 0,
        seed_status = "OK",
        seed_memory = 0,
    }

    quest.seed_flag = this.get_seed_flag(quest)
    quest.seed_memory = quest.total_memory

    return quest
end

---@protected
---@param quest Quest
function this._set_seed(quest)
    local o_seed = s.get("snow.QuestManager"):getRandomQuestSeedFromQuestNo(quest.quest_no)
    local save_data = s.get("snow.QuestManager"):get_SaveData()
    local mystery_seeds = save_data._RandomMysteryQuestSeed
    local index = mystery_seeds:IndexOf(o_seed)
    mystery_seeds:set_Item(index, quest.mystery_seed)
end

---@protected
---@param key string
---@param mystery_data snow.quest.RandomMysteryQuestData
---@return string
function this._key_to_quest_name_part(key, mystery_data)
    ---@type string
    local ret

    if key == "main_monster" then
        local main_em = mystery_data:getMainTargetEmType()
        ret = snow_map.em_data[main_em].name

        if mystery_data._HuntTargetNum > 1 then
            ret = string.format("%s, %s", ret, config.lang:tr("misc.text_etc"))
        end
    elseif key == "monster" then
        local names = {}
        util_game.do_something(mystery_data._BossEmType, function(_, index, value)
            if index > mystery_data._HuntTargetNum then
                return false
            end

            table.insert(names, snow_map.em_data[value].name)
        end)
        ret = table.concat(names, ", ")
    elseif key == "map" then
        ret = snow_map.map_data[mystery_data._MapNo].name
    elseif key == "level" then
        ret = tostring(mystery_data._QuestLv)
    elseif key == "player" then
        ret = tostring(mystery_data._QuestOrderNum)
    elseif key == "time" then
        ret = tostring(mystery_data._TimeLimit)
    elseif key == "life" then
        ret = tostring(mystery_data._QuestLife)
    elseif key == "tod" then
        ret = mystery_data._StartTime == e.get("snow.quest.StartTimeType").Day
                and config.lang:tr("misc.text_day")
            or config.lang:tr("misc.text_night")
    elseif key == "special" then
        ret = mystery_data._isSpecialQuestOpen and config.lang:tr("misc.text_yes")
            or config.lang:tr("misc.text_no")
    elseif key == "lock" then
        ret = mystery_data._IsLock and config.lang:tr("misc.text_yes")
            or config.lang:tr("misc.text_no")
    elseif key == "valid" then
        ret = mystery_data._IsValidQuest and config.lang:tr("misc.text_yes")
            or config.lang:tr("misc.text_no")
    elseif key == "rank" then
        local main_em = mystery_data:getMainTargetEmType()
        local rank = snow_map.em_data[main_em].quest_rank
        ret = string.format(
            "%s%s%s",
            config.lang:tr("misc.text_mystery_short"),
            config.lang:tr("misc.text_star"),
            rank + 1
        )
    elseif key == "target_num" then
        return tostring(mystery_data._HuntTargetNum)
    elseif key == "quest_id" then
        return tostring(mystery_data._QuestNo)
    end

    return ret
end

---@param format string
---@param quest Quest
function this.format_quest_name(format, quest)
    local ret = format

    ret = ret:gsub("%%([%w_]+)%%", function(key)
        return this._key_to_quest_name_part(key, quest.mystery_data) or ("%" .. key .. "%")
    end)
    return string.format("%s##%s", ret, quest.quest_no)
end

function this.reload()
    local mystery_quests = s.get("snow.QuestManager")._RandomMysteryQuestData
    this.quest_data = {}
    this.filter:clear()
    this.size = 0

    util_game.do_something(mystery_quests, function(_, _, value)
        local quest_no = value._QuestNo
        if quest_no <= 0 then
            return
        end

        local quest = this._make_quest(value)

        this.quest_data[quest_no] = quest
        this.filter:add(quest)
        this.size = this.size + 1
    end)

    if this.current_quest then
        this.current_quest = this.quest_data[this.current_quest.quest_no]
    end
end

---@param quest Quest
---@return number
function this.get_seed_memory(quest)
    quest.seed_memory = data.get_em_use_memory(quest.mystery_seed)
    return quest.seed_memory
end

---@param quest Quest
---@return QuestCheckResult
function this.get_seed_flag(quest)
    local m_data = util_ref.ctor("snow.quest.RandomMysteryQuestData")
    m_data:copyFromValue(quest.mystery_seed)

    -- checkRandomMysteryQuestOrderBan calls getRandomQuestSeedFromQuestNo which returns original seed instead of the one we are checking
    this.spoof_seed = quest.mystery_seed
    quest.seed_status =
        e.get("snow.quest.nRandomMysteryQuest.QuestCheckResult")[m.checkRandomMysteryQuestOrderBan(
            m_data,
            false
        )]
    if quest.seed_status ~= "OK" then
        quest.seed_flag = data.check_mystery_seed_cond(quest.mystery_seed)
            | data.check_mystery_seed_monster(quest.mystery_seed)
            | data.check_mystery_seed_level(quest.mystery_seed)
    else
        quest.seed_flag = 0
    end
    this.spoof_seed = nil

    quest.seed_memory = data.get_em_use_memory(quest.mystery_seed)
    return quest.seed_flag
end

---@param quest_no integer?
function this.swap_quest(quest_no)
    if this.current_quest then
        this.reset_to_original(this.current_quest)
    end
    this.current_quest = this.quest_data[quest_no]
    return this.current_quest
end

---@param quest Quest
function this.reset_to_original(quest)
    quest.mystery_seed = s.get("snow.QuestManager"):getRandomQuestSeedFromQuestNo(quest.quest_no)
    quest.seed_flag = this.get_seed_flag(quest)
    quest.seed_memory = quest.total_memory
end

---@param quest Quest
---@param map snow.QuestMapManager.MapNoType
---@param ems snow.enemy.EnemyDef.EmTypes[] -- 5 ems
function this.edit_ems(quest, map, ems)
    local system_array = util_game.lua_array_to_system_array(
        { ems[1], ems[2], ems[3], ems[4], 0, ems[5], 0 },
        "snow.enemy.EnemyDef.EmTypes"
    )
    quest.mystery_seed._MapNo = map
    quest.mystery_seed:setEnemyTypes(system_array)
end

---@param level integer?
---@param hunt_num integer?
---@param order_num integer?
---@param life integer?
---@param time integer?
---@param tod snow.quest.StartTimeType?
---@param is_special boolean?
---@param is_lock boolean?
---@param quest Quest
function this.edit_cond(level, hunt_num, order_num, life, time, tod, is_special, is_lock, quest)
    local m_seed = quest.mystery_seed
    if level then
        m_seed._QuestLv = level
        m_seed._MysteryLv = level
        m_seed._OriginQuestLv = 0
    end

    if hunt_num then
        m_seed._HuntTargetNum = hunt_num
    end

    if order_num then
        m_seed._QuestOrderNum = order_num
    end

    if life then
        m_seed._QuestLife = life
    end

    if time then
        m_seed._TimeLimit = time
    end

    if tod then
        m_seed._StartTime = tod
    end

    if is_special ~= nil then
        m_seed._isSpecialQuestOpen = is_special
    end

    if is_lock ~= nil then
        m_seed._IsLock = is_lock
    end

    m_seed._IsNewFlag = true
    if m_seed._isSpecialQuestOpen then
        m_seed._IsSpecialNewFlag = true
    end
end

---@param level integer?
---@param hunt_num integer?
---@param order_num integer?
---@param life integer?
---@param time integer?
---@param tod snow.quest.StartTimeType?
---@param is_special boolean?
---@param is_lock boolean?
---@param quests Quest[]
function this.edit_cond_many(
    level,
    hunt_num,
    order_num,
    life,
    time,
    tod,
    is_special,
    is_lock,
    quests
)
    for _, quest in pairs(quests) do
        this.edit_cond(level, hunt_num, order_num, life, time, tod, is_special, is_lock, quest)
    end
end

---@param quest Quest
function this.apply(quest)
    this.filter:remove(quest)
    this._validate_ems(quest)
    quest.mystery_data:copyFromValue(quest.mystery_seed)
    this._set_seed(quest)

    this.quest_data[quest.quest_no] = this._make_quest(quest.mystery_data)
    this.filter:add(quest)
    this.current_quest = nil
end

---@param quests Quest[]
function this.apply_many(quests)
    for _, quest in pairs(quests) do
        this.apply(quest)
    end
end

---@param quests Quest[]
function this.remove_many(quests)
    for _, quest in pairs(quests) do
        this.remove(quest)
    end
end

---@param quest Quest
function this.remove(quest)
    local size = util_table.size(this.quest_data)
    if size == 1 then
        return
    end

    this.filter:remove(quest)
    this.current_quest = nil
    this.quest_data[quest.mystery_data._QuestNo] = nil

    quest.mystery_seed:clear()
    quest.mystery_data:clear()
    this._set_seed(quest)
    this.size = this.size - 1
end

---@param index integer
---@param quest Quest
function this.is_em_disabled(index, quest)
    if index == 0 then
        return false
    end

    local target_num = quest.mystery_seed._HuntTargetNum

    if snow_map.map_data[quest.mystery_seed._MapNo].is_extra then
        return index >= target_num or index == 5
    end

    if index == 5 then
        return target_num > 2
    end

    if index == 3 then
        return target_num < 4
    end

    return false
end

---@protected
---@param quest Quest
function this._validate_ems(quest)
    local ems = quest.mystery_seed:getEnemyTypes()
    local target_num = quest.mystery_seed._HuntTargetNum
    local map_data = snow_map.map_data[quest.mystery_seed._MapNo]
    local quest_level = quest.mystery_seed._QuestLv
    local em_main =
        util_table.array_to_map(util_table.extract_values(map_data.available_em, function(_, value)
            local em_data = snow_map.em_data[value]
            return em_data.release_level_main ~= -1 and quest_level >= em_data.release_level_main
        end)) --[[@as table<snow.enemy.EnemyDef.EmTypes, any>]]
    local em_sub =
        util_table.array_to_map(util_table.extract_values(map_data.available_em, function(_, value)
            local em_data = snow_map.em_data[value]
            return em_data.release_level_sub ~= -1 and quest_level >= em_data.release_level_sub
        end)) --[[@as table<snow.enemy.EnemyDef.EmTypes, any>]]

    util_game.do_something(ems, function(system_array, index, value)
        if this.is_em_disabled(index, quest) then
            system_array:set_Item(index, 0)
            return
        end

        em_main[value] = nil
        em_sub[value] = nil

        for em2 in pairs(snow_map.additional_dups[value] or {}) do
            em_main[em2] = nil
            em_sub[em2] = nil
        end

        -- pick randomly if value is 'None'
        if index + 1 <= target_num and value == 0 then
            ---@type snow.enemy.EnemyDef.EmTypes
            local em
            if index == 0 then
                em = util_table.pick_random_key(em_main) or 0
                system_array:set_Item(index, em)
            else
                em = util_table.pick_random_key(em_sub) or 0
                system_array:set_Item(index, em)
            end

            for em2 in pairs(snow_map.additional_dups[em] or {}) do
                em_main[em2] = nil
                em_sub[em2] = nil
            end
        end
    end)

    quest.mystery_seed:setEnemyTypes(ems)
end

---@param count integer
---@param ems table<snow.quest.QuestLevel, snow.enemy.EnemyDef.EmTypes[]>
---@return boolean
function this.generate_quest(count, ems)
    local questman = s.get("snow.QuestManager")

    local max_indexes =
        math.min(count, snow_map.max_quest_count - questman:getEnableRandomMysteryQuestCount())
    if max_indexes <= 0 then
        return false
    end

    local mystery_quests = questman._RandomMysteryQuestData
    local quest_index_arr = questman:getFreeSpaceMysteryQuestIDXList(
        mystery_quests,
        questman:getFreeMysteryQuestNo(),
        max_indexes,
        true
    )
    local indexes = questman:getFreeMysteryQuestDataIdx2IndexList(quest_index_arr)

    local m_data = util_ref.ctor("snow.quest.RandomMysteryQuestData")
    m_data:add_ref()
    util_game.do_something(indexes, function(_, _, idx)
        local quest_no = questman:getFreeMysteryQuestNo() + snow_map.random_mystery_offset --[[@as integer]]
        local rank = util_table.pick_random_value(ems)
        local em = util_table.pick_random_value(rank)

        m_data._BossEmType:set_Item(0, em)
        m_data._QuestLv = snow_map.level_cap + 1
        this.spoof_em = em
        m.createRandomMysteryQuest(
            m_data,
            e.get("snow.quest.nRandomMysteryQuest.LotType").Random,
            idx,
            quest_no,
            true
        )
        m_data:clear()
    end)

    return true
end

return this
