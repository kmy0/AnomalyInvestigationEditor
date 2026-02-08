local this = {
    snow = require("AnomalyInvestigationEditor.data.snow"),
    mod = require("AnomalyInvestigationEditor.data.mod"),
}

local config = require("AnomalyInvestigationEditor.config.init")
local e = require("AnomalyInvestigationEditor.util.game.enum")
---@class MethodUtil
local m = require("AnomalyInvestigationEditor.util.ref.methods")
local s = require("AnomalyInvestigationEditor.util.ref.singletons")
local util_game = require("AnomalyInvestigationEditor.util.game.init")
local util_misc = require("AnomalyInvestigationEditor.util.misc.init")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")

local snow_map = this.snow.map
local mod_enum = this.mod.enum

---@return table<snow.enemy.EnemyDef.MysteryRank, System.UInt32>
local function make_extra_release_level_data()
    ---@type table<snow.enemy.EnemyDef.MysteryRank, System.UInt32>
    local ret = {}
    local rank_release_data = s.get("snow.QuestManager")._randomMysteryReleaseRankData
    -- 0 = main, 1 = extra
    local release_data = rank_release_data._ReleaseLevelData[1]

    util_game.do_something(release_data:get_ParamData(), function(_, _, param)
        ret[param:get_MonsterRank()] = param:get_ReleaseLevel()
    end)
    return ret
end

local function make_mystery_rank_data()
    --FIXME: this is the only way I could find to coorelate momsters to A2, A5 etc. rank...
    ---@type table<integer, snow.quest.QuestLevel>
    local fixed_mystery = {}
    local max = sdk.find_type_definition("snow.quest.QuestLevel"):get_field("EX_MAX"):get_data() --[[@as snow.quest.QuestLevel]]
    local questman = s.get("snow.QuestManager")
    ---@type table<snow.enemy.EnemyDef.EmTypes, snow.quest.QuestLevel>
    local ret = {}
    local enum = e.new("snow.quest.QuestCategory")

    for quest_level = 0, max - 1 do
        local quest_nos = questman:getQuestNumberArray(enum.Mystery, quest_level)
        util_game.do_something(quest_nos, function(_, _, quest_no)
            fixed_mystery[quest_no] = quest_level
        end)
    end

    -- questman:get_QuestData(quest_no) just throws?
    local quest_dict = s.get("snow.QuestManager")._QuestDataDictionary
    util_game.do_something_dict(quest_dict, function(_, quest_no, quest_data)
        if not fixed_mystery[quest_no] then
            return
        end

        local param = quest_data:get_RawNormal()
        local em = param._TgtEmType:get_Item(0)
        ret[em] = fixed_mystery[quest_no]
    end)

    return ret
end

---@return table<snow.enemy.EnemyDef.EmTypes, EmData>, table<snow.quest.QuestLevel, snow.enemy.EnemyDef.EmTypes[]>, table<snow.enemy.EnemyDef.EmTypes, table<snow.enemy.EnemyDef.EmTypes, boolean>>
local function make_em_data()
    local enemy_data = s.get("snow.QuestManager")._randomMysteryLotEnemyData
    ---@type table<snow.enemy.EnemyDef.EmTypes, EmData>
    local em_data = {}
    local release_extra = make_extra_release_level_data()
    local quest_rank_data = make_mystery_rank_data()
    ---@type table<snow.QuestMapManager.MapNoType, integer>
    local all_maps = {}

    util_game.do_something(enemy_data._LotEnemyList, function(_, _, value)
        if not value:isValid() then
            return
        end

        local em_type = value:get_EmType()
        em_data[em_type] = {
            em_type = em_type,
            quest_rank = quest_rank_data[em_type] or -1,
            release_level_main = s.get("snow.QuestManager")
                :getRandomMysteryAppearanceMainEmLevel(em_type),
            release_level_sub = s.get("snow.QuestManager")
                :getRandomMysteryAppearanceSubEmLevel(em_type),
            release_level_extra = release_extra[value:get_NormalRank()] or -1,
            available_map = util_game.system_array_to_lua(value:getStageLotTable(true)),
            name = s.get("snow.gui.MessageManager"):getEnemyNameMessage(em_type),
            memory = util_misc.round(
                s.get("snow.enemy.EnemyManager"):getEnemyUseMemory(em_type),
                1
            ),
        }

        all_maps = util_table.merge_t(
            all_maps,
            util_table.map_table(em_data[em_type].available_map, function(o)
                return em_data[em_type].available_map[o]
            end)
        )
    end)

    local em_type = 0 --[[@as snow.enemy.EnemyDef.EmTypes]]
    em_data[em_type] = {
        em_type = em_type,
        quest_rank = -1,
        release_level_main = -1,
        release_level_extra = -1,
        release_level_sub = -1,
        available_map = util_table.keys(all_maps),
        name = config.lang:tr("misc.text_none"),
        memory = -1,
    }

    ---@type table<snow.quest.QuestLevel, snow.enemy.EnemyDef.EmTypes[]>
    local quest_level_to_em = {}
    for em, quest_level in pairs(quest_rank_data) do
        util_table.insert_nested_value(quest_level_to_em, { quest_level }, em)
    end

    local additional_dups = {
        -- Risen Kushala Daora
        [2072] = { [24] = true },
        -- Risen Chameleos
        [2073] = { [25] = true },
        -- Risen Teostra
        [2075] = { [27] = true },
        -- Risen Shagaru Magala
        [2120] = { [1351] = true, [72] = true, [71] = true },
        -- Risen Crimson Glow Valstrax
        [2134] = { [1366] = true },
        -- Chaotic Gore Magala
        [1351] = { [72] = true, [71] = true },
        -- Shagaru Magala
        [72] = { [71] = true },
    }

    for em1, other in pairs(additional_dups) do
        for em2, _ in pairs(other) do
            util_table.set_nested_value(additional_dups, { em2, em1 }, true)
        end
    end

    return em_data, quest_level_to_em, additional_dups
end

---@param em_datas table<snow.enemy.EnemyDef.EmTypes, EmData>
---@return table<snow.QuestMapManager.MapNoType, MapData>, table<integer, table<integer, boolean>>, integer[]
local function make_map_data(em_datas)
    ---@type table<snow.QuestMapManager.MapNoType, MapData>
    local map_data = {}
    ---@type table<snow.QuestMapManager.MapNoType, snow.enemy.EnemyDef.EmTypes[]>
    local maps = {}
    ---@type table<integer, table<integer, boolean>>
    local hunt_num_data = {}
    ---@type table<integer, boolean>
    local hunt_num_map = {}
    local buffer = 10.0 -- MonsterHunterRise.exe+3C37B49 7FF6184FB878

    for em, em_data in pairs(em_datas) do
        for _, map in pairs(em_data.available_map) do
            util_table.insert_nested_value(maps, { map }, em)
        end
    end

    for map, ems in pairs(maps) do
        map_data[map] = {
            map_type = map,
            available_em = ems,
            hunt_num = {},
            name = s.get("snow.gui.MessageManager"):getMapNameMessage(map),
            is_extra = s.get("snow.QuestManager"):isExtraStage(map),
            memory_limit = s.get("snow.enemy.EnemyManager"):getEnemyMapMaxMemory(map) + buffer,
            release_level = 0,
        }

        ---@type snow.quest.RandomMysteryLotHuntNumData | snow.quest.randomMysteryExtraStageData
        local lot_hunt_num_data

        if map_data[map].is_extra then
            lot_hunt_num_data = s.get("snow.QuestManager")._randomMysteryExtraStageData
            map_data[map].release_level = lot_hunt_num_data._EnableLotExtraStageLevel
        else
            lot_hunt_num_data = s.get("snow.QuestManager")._randomMysteryLotHuntNumData
        end

        util_game.do_something(lot_hunt_num_data._LotHuntNumTable, function(_, _, lot_data)
            local level_border = lot_data:get_ApplyLevel()
            hunt_num_data[level_border] = {}

            util_game.do_something(lot_data:get_LotTable(), function(_, _, table_data)
                util_game.do_something(table_data:get_LotProb(), function(_, num, prob)
                    if prob > 0 then
                        hunt_num_data[level_border][num + 1] = true
                        map_data[map].hunt_num[num + 1] = true
                        hunt_num_map[num + 1] = true
                    end
                end)
            end)
        end)
    end

    return map_data, hunt_num_data, util_table.sort(util_table.keys(hunt_num_map))
end

---@return table<integer, table<integer, boolean>>, System.Array<System.Int32>, integer[]
local function make_order_num_data()
    local order_num_data = s.get("snow.QuestManager")._randomMysteryLotOrderNumData
    local order_num_arr = sdk.find_type_definition("snow.quest.nRandomMysteryQuest")
        :get_field("OrderNumTable")
        :get_data() --[[@as System.Array<System.Int32>]]
    ---@type table<integer, table<integer, boolean>>
    local ret = {}
    ---@type table<integer, boolean>
    local order_num_list = {}

    util_game.do_something(order_num_data._LotOrderNumTable, function(_, _, num_table)
        local level_border = num_table:get_ApplyLevel()
        ret[level_border] = {}
        util_game.do_something(num_table:get_LotTable(), function(_, _, lot_table)
            util_game.do_something(lot_table:get_LotProb(), function(_, index, prob)
                if prob > 0 then
                    local num = order_num_arr:get_Item(index)
                    ret[level_border][order_num_arr:get_Item(index)] = true
                    order_num_list[num] = true
                end
            end)
        end)
    end)

    return ret, order_num_arr, util_table.sort(util_table.keys(order_num_list))
end

---@return table<integer, table<integer, boolean>>, System.Array<System.Int32>
local function make_quest_life_data()
    local quest_life_data = s.get("snow.QuestManager")._randomMysteryLotLifeData
    local quest_life_array =
        sdk.find_type_definition("snow.quest.nRandomMysteryQuest"):get_field("LifeTable"):get_data() --[[@as System.Array<System.Int32>]]
    ---@type table<integer, table<integer, boolean>>
    local ret = {}

    util_game.do_something(quest_life_data._LotQuestLifeTable, function(_, _, life_table)
        local level_border = life_table:get_ApplyLevel()
        ret[level_border] = {}
        util_game.do_something(life_table:get_LotTable(), function(_, _, lot_table)
            util_game.do_something(lot_table:get_LotProb(), function(_, index, prob)
                if prob > 0 then
                    ret[level_border][quest_life_array:get_Item(index)] = true
                end
            end)
        end)
    end)

    return ret, quest_life_array
end

---@return snow.quest.StartTimeType[]
local function make_start_time_data()
    local ret = {}

    -- snow.quest.nRandomMysteryQuest.lotStartTime(snow.enemy.EnemyDef.EmTypes[]) returns index + 1
    util_game.do_something(
        sdk.find_type_definition("snow.quest.nRandomMysteryQuest")
            :get_field("LotStartTimeTable")
            :get_data() --[[@as System.Array<System.Int32>]],
        function(_, index, prob)
            if prob > 0 then
                table.insert(ret, index + 1)
            end
        end
    )

    return ret
end

---@return table<integer, table<integer, boolean>>, System.Array<System.Int32>
local function make_time_limit_data()
    local time_limit_data = s.get("snow.QuestManager")._randomMysteryLotTimeLimitData
    local time_limit_array = sdk.find_type_definition("snow.quest.nRandomMysteryQuest")
        :get_field("LimitTimeTable")
        :get_data() --[[@as System.Array<System.Int32>]]
    ---@type table<integer, table<integer, boolean>>
    local ret = {}

    util_game.do_something(time_limit_data._LotTimeLimitTable, function(_, _, time_table)
        local level_border = time_table:get_ApplyLevel()
        ret[level_border] = {}
        util_game.do_something(time_table:get_LotTable(), function(_, _, lot_table)
            util_game.do_something(lot_table:get_LotProb(), function(_, index, prob)
                if prob > 0 then
                    ret[level_border][time_limit_array:get_Item(index)] = true
                end
            end)
        end)
    end)

    return ret, time_limit_array
end

local function check_cond(hunt_num, quest_life, time_limit, mystery_rank, is_extra_map)
    -- snow.quest.nRandomMysteryQuest.checkQuestCond(snow.quest.RandomMysteryQuestData)
    local ret = mod_enum.quest_check_result.OK
    if hunt_num == 4 and is_extra_map then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.HUNT_NUM
    end

    if
        hunt_num == 4
        and (
            quest_life == snow_map.quest_life_array:get_Item(0)
            or quest_life == snow_map.quest_life_array:get_Item(1)
        )
    then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.LIFE
    end

    if mystery_rank > 1 and quest_life == snow_map.quest_life_array:get_Item(0) then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.LIFE
    end

    if
        (hunt_num == 2 and time_limit == snow_map.time_limit_array:get_Item(3))
        or (
            (hunt_num == 3 or hunt_num == 4)
            and time_limit ~= snow_map.time_limit_array:get_Item(0)
        )
    then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.TIME
    end

    return ret
end

---@return table<integer, integer[]>, table<integer, integer[]>
local function make_hunt_num_data()
    ---@type table<integer, integer[]>
    local ret = {}
    ---@type table<integer, integer[]>
    local ret2 = {}
    local keys = util_table.sort(util_table.keys(snow_map.hunt_num_data))

    for _, hunt_num in pairs(snow_map.hunt_num_list) do
        for _, time_limit in pairs(snow_map.time_limit_list) do
            if
                mod_enum.quest_check_result.TIME & check_cond(hunt_num, 3, time_limit, 2, false)
                ~= mod_enum.quest_check_result.TIME
            then
                util_table.insert_nested_value(ret, { hunt_num }, time_limit)
            end
        end

        for _, quest_life in pairs(snow_map.quest_life_list) do
            local max_level = snow_map.quest_life_to_max_level[quest_life]
            local key = util_table.binary_search(max_level, keys)

            if
                key
                and snow_map.hunt_num_data[key][hunt_num]
                and mod_enum.quest_check_result.LIFE
                        & check_cond(hunt_num, quest_life, 50, 1, false)
                    ~= mod_enum.quest_check_result.LIFE
            then
                util_table.insert_nested_value(ret2, { hunt_num }, quest_life)
            end
        end
    end

    return ret, ret2
end

---@param cond_data table<integer, table<integer, boolean>>
---@return table<integer, integer>, table<integer, integer>
local function make_cond_to_level(cond_data)
    ---@type table<integer, integer[]>
    local cond_to_min_level = {}
    ---@type table<integer, integer[]>
    local cond_to_max_level = {}
    for level, cond in pairs(cond_data) do
        for cond_value in pairs(cond) do
            util_table.insert_nested_value(cond_to_min_level, { cond_value }, level)

            for _level, _cond in pairs(cond_data) do
                if _level > level and not _cond[cond_value] then
                    util_table.insert_nested_value(cond_to_max_level, { cond_value }, _level - 1)
                end
            end

            if not cond_to_max_level[cond_value] then
                cond_to_max_level[cond_value] = { snow_map.level_cap }
            end
        end
    end

    ---@type table<integer, integer>
    local ret = {}
    ---@type table<integer, integer>
    local ret2 = {}
    for cond_value, levels in pairs(cond_to_min_level) do
        ret[cond_value] = math.min(table.unpack(levels))
    end

    for cond_value, levels in pairs(cond_to_max_level) do
        ret2[cond_value] = math.min(table.unpack(levels))
    end

    return ret, ret2
end

---@return QuestCheckResult
function this.em_index_to_flag(index)
    return mod_enum.quest_check_result["EM" .. index]
end

---@param mystery_seed snow.quest.RandomMysteryQuestSeed
---@return number
function this.get_em_use_memory(mystery_seed)
    local index_max = mystery_seed._HuntTargetNum < 3 and 2 or 1
    local ret = 0
    util_game.do_something(mystery_seed:getEnemyTypes(), function(_, index, em_type)
        if em_type == 0 then
            return
        end

        if index <= index_max then
            ret = ret + snow_map.em_data[em_type].memory
        end
    end)
    return ret
end

---@param mystery_seed snow.quest.RandomMysteryQuestSeed
---@return QuestCheckResult
function this.check_mystery_seed_level(mystery_seed)
    local ret = mod_enum.quest_check_result.OK
    local hunt_num = mystery_seed._HuntTargetNum
    local quest_level = mystery_seed._QuestLv
    local map = mystery_seed._MapNo
    local quest_life = mystery_seed._QuestLife
    local order_num = mystery_seed._QuestOrderNum
    local time_limit = mystery_seed._TimeLimit
    local target_num = mystery_seed._HuntTargetNum

    if quest_level < snow_map.map_data[map].release_level then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.MAP
    end

    local keys = util_table.sort(util_table.keys(snow_map.hunt_num_data))
    local key = util_table.binary_search(quest_level, keys)

    if key and not snow_map.hunt_num_data[key][hunt_num] then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.HUNT_NUM
    end

    keys = util_table.sort(util_table.keys(snow_map.order_num_data))
    key = util_table.binary_search(quest_level, keys)

    if key and not snow_map.order_num_data[key][order_num] then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.ORDER_NUM
    end

    keys = util_table.sort(util_table.keys(snow_map.quest_life_data))
    key = util_table.binary_search(quest_level, keys)

    if
        not (target_num ~= 4 and quest_life == 5)
        and key
        and not snow_map.quest_life_data[key][quest_life]
    then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.LIFE
    end

    keys = util_table.sort(util_table.keys(snow_map.time_limit_data))
    key = util_table.binary_search(quest_level, keys)

    if key and not snow_map.time_limit_data[key][time_limit] then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.TIME
    end

    return ret
end

---@param mystery_seed snow.quest.RandomMysteryQuestSeed
---@return QuestCheckResult
function this.check_mystery_seed_monster(mystery_seed)
    local ret = mod_enum.quest_check_result.OK
    ---@type table<snow.enemy.EnemyDef.EmTypes, integer[]>
    local em_to_index = {}
    local hunt_num = mystery_seed._HuntTargetNum
    local quest_level = mystery_seed._QuestLv
    local map = mystery_seed._MapNo

    util_game.do_something(mystery_seed:getEnemyTypes(), function(_, index, em_type)
        if em_type == 0 then
            return
        end

        util_table.insert_nested_value(em_to_index, { em_type }, index)
        for em, _ in pairs(snow_map.additional_dups[em_type] or {}) do
            util_table.insert_nested_value(em_to_index, { em }, index)
        end

        local em_data = snow_map.em_data[em_type]

        if
            index == 0
            and (em_data.release_level_main == -1 or quest_level < em_data.release_level_main)
        then
            ---@diagnostic disable-next-line: no-unknown
            ret = ret | this.em_index_to_flag(index)
        elseif (index >= 1 and index <= 3) or index == 5 then
            if
                (
                    index + 1 <= hunt_num
                    and (em_data.release_level_sub == -1 or quest_level < em_data.release_level_sub)
                )
                or (
                    index + 1 > hunt_num
                    and (
                        em_data.release_level_extra == -1
                        or quest_level < em_data.release_level_extra
                    )
                )
            then
                ---@diagnostic disable-next-line: no-unknown
                ret = ret | this.em_index_to_flag(index)
            end
        end
    end)

    local total_memory = this.get_em_use_memory(mystery_seed)
    if total_memory > snow_map.map_data[map].memory_limit then
        ---@diagnostic disable-next-line: no-unknown
        ret = ret | mod_enum.quest_check_result.MEMORY
    end

    for _, indexes in pairs(em_to_index) do
        if #indexes > 1 then
            for _, i in pairs(indexes) do
                ---@diagnostic disable-next-line: no-unknown
                ret = ret | this.em_index_to_flag(i)
            end
        end
    end

    return ret
end

---@param mystery_seed snow.quest.RandomMysteryQuestSeed
---@return QuestCheckResult
function this.check_mystery_seed_cond(mystery_seed)
    local quest_life = mystery_seed._QuestLife
    local mystery_rank = mystery_seed:getMysteryRank():get_Item(0)
    local hunt_num = mystery_seed._HuntTargetNum
    local time_limit = mystery_seed._TimeLimit
    local map = mystery_seed._MapNo

    return check_cond(
        hunt_num,
        quest_life,
        time_limit,
        mystery_rank,
        snow_map.map_data[map].is_extra
    )
end

---@return boolean
function this.init()
    if
        not s.get("snow.QuestManager")
        or not s.get("snow.enemy.EnemyManager")
        or not s.get("snow.gui.MessageManager")
    then
        return false
    end

    e.new("snow.quest.StartTimeType")
    e.new("snow.quest.nRandomMysteryQuest.QuestCheckResult")
    e.new("snow.quest.nRandomMysteryQuest.LotType")
    e.new("snow.quest.nRandomMysteryQuest.LotEmType")

    if util_table.any(e.enums, function(_, value)
        return not value.ok
    end) then
        return false
    end

    snow_map.level_cap = s.get("snow.progress.ProgressManager"):getCapMysteryResearchLevel()
    snow_map.em_data, snow_map.quest_level_to_em, snow_map.additional_dups = make_em_data()
    snow_map.map_data, snow_map.hunt_num_data, snow_map.hunt_num_list =
        make_map_data(snow_map.em_data)
    snow_map.order_num_data, snow_map.order_num_array, snow_map.order_num_list =
        make_order_num_data()
    snow_map.max_quest_count = sdk.find_type_definition("snow.quest.nRandomMysteryQuest")
        :get_field("RandomMysteryQuestMax")
        :get_data()
    snow_map.start_time_list = make_start_time_data()
    snow_map.quest_life_data, snow_map.quest_life_array = make_quest_life_data()
    snow_map.quest_life_list =
        util_table.sort(util_game.system_array_to_lua(snow_map.quest_life_array))
    snow_map.time_limit_data, snow_map.time_limit_array = make_time_limit_data()
    snow_map.time_limit_list =
        util_table.sort(util_game.system_array_to_lua(snow_map.time_limit_array))
    snow_map.hunt_num_to_min_level = make_cond_to_level(snow_map.hunt_num_data)
    snow_map.time_limit_to_min_level = make_cond_to_level(snow_map.time_limit_data)
    snow_map.quest_life_to_min_level, snow_map.quest_life_to_max_level =
        make_cond_to_level(snow_map.quest_life_data)
    snow_map.hunt_num_to_time_limit, snow_map.hunt_num_to_life_limit = make_hunt_num_data()
    snow_map.order_num_to_min_level = make_cond_to_level(snow_map.order_num_data)
    return true
end

return this
