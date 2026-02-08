local config = require("AnomalyInvestigationEditor.config.init")
local data = require("AnomalyInvestigationEditor.data.init")
local e = require("AnomalyInvestigationEditor.util.game.enum")
local mystery = require("AnomalyInvestigationEditor.mystery")
local s = require("AnomalyInvestigationEditor.util.ref.singletons")
local state = require("AnomalyInvestigationEditor.gui.state")
local timer = require("AnomalyInvestigationEditor.util.misc.timer")
local util_gui = require("AnomalyInvestigationEditor.gui.util")
local util_imgui = require("AnomalyInvestigationEditor.util.imgui.init")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")

local mod = data.mod
local snow = data.snow
local set = state.set

local this = {}
local boot = true
local button_apply_timer = timer:new(1, nil, nil, nil, true)

---@return boolean
local function button_apply()
    local text = config.lang:tr("mod.button_apply")
    local size = imgui.calc_text_size(text)
    -- padding
    size.x = size.x + 9
    size.y = size.y + 6

    local active = button_apply_timer:active()
    imgui.begin_disabled(active)
    local ret = imgui.button(
        string.format(
            "%s##%s",
            active and config.lang:tr("misc.text_success") or config.lang:tr("mod.button_apply"),
            "mod.button_apply"
        ),
        size
    )
    imgui.end_disabled()
    if ret then
        button_apply_timer:restart()
    end
    return ret
end

local function is_delete_disabled()
    local size = 0
    for _ in pairs(mystery.quest_data) do
        size = size + 1

        if size >= 2 then
            break
        end
    end

    return size == 1
end

---@return fun(): integer?
local function iter_em_index()
    local i = 1
    local indexes = { 0, 1, 2, 3, 5 }

    return function()
        local item = indexes[i]
        i = i + 1
        return item
    end
end

---@param map snow.QuestMapManager.MapNoType
local function swap_ems_by_map(map)
    local config_mod = config.current.mod
    local ems = util_table.map_value_to_value(snow.map.map_data[map].available_em)

    for i in iter_em_index() do
        local key = "em" .. i
        config_mod.combo[key] = (state.combo[key] --[[@as Combo]]):swap(ems, config_mod.combo[key])
    end
end

---@param quest Quest
local function swap_ems_by_quest(quest)
    local config_mod = config.current.mod
    local ems =
        util_table.map_value_to_value(snow.map.map_data[quest.mystery_data._MapNo].available_em)

    for i in iter_em_index() do
        local key = "em" .. i
        local em_combo = state.combo[key] --[[@as Combo]]
        em_combo:swap(ems)
        config_mod.combo[key] = em_combo:get_index(quest.ems[i + 1])
    end
end

---@param quest Quest
local function swap_cond(quest)
    local config_slider = config.current.mod.slider
    local m_seed = quest.mystery_seed

    config_slider.level = m_seed._QuestLv
    config_slider.target_num = util_table.index(snow.map.hunt_num_list, m_seed._HuntTargetNum) --[[@as integer]]
    config_slider.player = util_table.index(snow.map.order_num_list, m_seed._QuestOrderNum) --[[@as integer]]
    config_slider.life = util_table.index(snow.map.quest_life_list, m_seed._QuestLife) --[[@as integer]]
    config_slider.time = util_table.index(snow.map.time_limit_list, m_seed._TimeLimit) --[[@as integer]]
    config_slider.tod = m_seed._StartTime
    config_slider.special = m_seed._isSpecialQuestOpen and 1 or 2
    config_slider.lock = m_seed._IsLock and 1 or 2
end

---@param quest_no integer?
local function swap_quest_settings(quest_no)
    local config_mod = config.current.mod
    mystery.swap_quest(quest_no)
    local quest = mystery.current_quest

    if quest then
        local map = quest.mystery_data._MapNo
        config_mod.combo.map = state.combo.map:get_index(map) --[[@as integer]]
        swap_ems_by_quest(quest)
        swap_cond(quest)
    end
end

---@param query string
local function apply_query(query)
    local config_mod = config.current.mod
    local res = query ~= "" and mystery.filter:query(query) or util_table.keys(mystery.quest_data)
    local quests = util_table.extract_keys(mystery.quest_data, res)
    local index = state.combo.quest:swap(quests, config_mod.combo.quest)

    if not boot then
        config_mod.combo.quest = index or 1
    end

    if config_mod.combo.mode == mod.enum.mode.ONE then
        swap_quest_settings(state.combo.quest:get_key(config_mod.combo.quest))
    end
end

---@param f fun(): boolean
---@param flag QuestCheckResult
---@return boolean
local function highlight(f, flag)
    if not mystery.current_quest or flag == 0 or flag & mystery.current_quest.seed_flag ~= flag then
        return f()
    end

    local height = imgui.get_cursor_screen_pos().y
    local ret = f()
    height = imgui.get_cursor_screen_pos().y - height
    util_imgui.highlight(state.colors.bad, 0, -height)
    return ret
end

---@param f fun(): boolean
---@param flag QuestCheckResult
---@param checkbox_key string
---@return boolean
local function slider_cond(f, flag, checkbox_key)
    local config_mod = config.current.mod
    if config_mod.combo.mode == mod.enum.mode.ALL then
        set:checkbox("##" .. checkbox_key, checkbox_key)
        imgui.same_line()
    end

    imgui.begin_disabled(
        config_mod.combo.mode ~= mod.enum.mode.ONE and not config:get(checkbox_key)
    )
    local ret = highlight(f, flag)
    imgui.end_disabled()

    return ret
end

---@return boolean
local function draw_edit_ems()
    local config_mod = config.current.mod
    local changed = false
    local quest = mystery.current_quest

    if not quest then
        return false
    end

    imgui.separator()

    local m_seed = quest.mystery_seed
    ---@type [string, string|number, number?][]
    local table_data = {
        {
            config.lang:tr("misc.text_memory"),
            string.format(
                "%s / %s",
                quest.seed_memory,
                snow.map.map_data[m_seed._MapNo].memory_limit
            ),
            quest.seed_memory <= snow.map.map_data[m_seed._MapNo].memory_limit
                    and state.colors.good
                or state.colors.bad,
        },
        {
            config.lang:tr("misc.text_auth"),
            quest.seed_status,
            quest.seed_status == "OK" and state.colors.good or state.colors.bad,
        },
    }

    if imgui.begin_table("seed_info", 2, imgui.TableFlags.BordersInnerV) then
        imgui.table_setup_column("##seed_info0", imgui.ColumnFlags.WidthFixed)
        imgui.table_setup_column("##seed_info1")
        for i = 1, #table_data do
            local row = table_data[i]

            imgui.table_next_row()
            imgui.table_set_column_index(0)
            imgui.text_colored(row[1], state.colors.info)
            imgui.table_set_column_index(1)

            if row[3] then
                imgui.text_colored(row[2], row[3])
            else
                imgui.text(row[2])
            end
        end

        imgui.end_table()
    end

    imgui.separator()

    changed = highlight(function()
        return set:combo(
            util_gui.tr("misc.text_map", "edit_map"),
            "mod.combo.map",
            state.combo.map.values
        )
    end, mod.enum.quest_check_result.MAP) or changed

    if changed then
        swap_ems_by_map(state.combo.map:get_key(config_mod.combo.map))
    end

    imgui.separator()

    for i in iter_em_index() do
        local name = ""

        if i == 0 then
            name = util_gui.tr("misc.text_main", "edit_m" .. i)
        elseif i < 5 then
            name = util_gui.tr(
                m_seed._HuntTargetNum > i and "misc.text_sub" or "misc.text_extra",
                "edit_m" .. i
            )
        else
            name = util_gui.tr("misc.text_invader", "edit_m" .. i)
        end

        imgui.begin_disabled(mystery.is_em_disabled(i, quest))
        changed = highlight(function()
            return set:combo(name, "mod.combo.em" .. i, state.combo["em" .. i].values)
        end, data.em_index_to_flag(i)) or changed
        imgui.end_disabled()
    end

    return changed
end

---@return boolean
local function draw_edit_cond()
    local config_mod = config.current.mod
    local changed = false

    imgui.separator()

    local item_config_key = "mod.slider.level"
    changed = slider_cond(function()
        return set:slider_int(
            util_gui.tr("misc.text_level", "edit_level"),
            item_config_key,
            1,
            snow.map.level_cap
        )
    end, mod.enum.quest_check_result.LEVEL, "mod.edit_level")

    item_config_key = "mod.slider.target_num"
    changed = slider_cond(function()
        return set:slider_int(
            util_gui.tr("misc.text_target_num", "edit_target_num"),
            item_config_key,
            1,
            #snow.map.hunt_num_list,
            ---@diagnostic disable-next-line: param-type-mismatch
            snow.map.hunt_num_list[config:get(item_config_key)]
        )
    end, mod.enum.quest_check_result.HUNT_NUM, "mod.edit_target_num") or changed

    item_config_key = "mod.slider.player"
    changed = slider_cond(function()
        return set:slider_int(
            util_gui.tr("misc.text_player", "edit_player"),
            item_config_key,
            1,
            #snow.map.order_num_list,
            ---@diagnostic disable-next-line: param-type-mismatch
            snow.map.order_num_list[config:get(item_config_key)]
        )
    end, mod.enum.quest_check_result.ORDER_NUM, "mod.edit_player") or changed

    item_config_key = "mod.slider.life"
    changed = slider_cond(function()
        return set:slider_int(
            util_gui.tr("misc.text_life", "edit_life"),
            item_config_key,
            1,
            #snow.map.quest_life_list,
            ---@diagnostic disable-next-line: param-type-mismatch
            snow.map.quest_life_list[config:get(item_config_key)]
        )
    end, mod.enum.quest_check_result.LIFE, "mod.edit_life") or changed

    item_config_key = "mod.slider.time"
    changed = slider_cond(function()
        return set:slider_int(
            util_gui.tr("misc.text_time", "edit_time"),
            item_config_key,
            1,
            #snow.map.time_limit_list,
            ---@diagnostic disable-next-line: param-type-mismatch
            snow.map.time_limit_list[config:get(item_config_key)]
        )
    end, mod.enum.quest_check_result.TIME, "mod.edit_time") or changed

    item_config_key = "mod.slider.tod"
    changed = slider_cond(function()
        return set:slider_int(
            util_gui.tr("misc.text_tod", "edit_tod"),
            item_config_key,
            1,
            2,
            e.get("snow.quest.StartTimeType")[config:get(item_config_key)] == "Day"
                    and config.lang:tr("misc.text_day")
                or config.lang:tr("misc.text_night")
        )
    end, 0, "mod.edit_tod") or changed

    imgui.begin_disabled(
        not s.get("snow.QuestManager"):isOpenSpecialRandomMysteryQuest()
            or config_mod.slider.level ~= snow.map.level_cap
    )
    item_config_key = "mod.slider.special"
    changed = slider_cond(function()
        return set:slider_int(
            util_gui.tr("misc.text_special", "edit_special"),
            item_config_key,
            1,
            2,
            config:get(item_config_key) == 1 and config.lang:tr("misc.text_yes")
                or config.lang:tr("misc.text_no")
        )
    end, 0, "mod.edit_special") or changed
    imgui.end_disabled()

    if config_mod.slider.level < snow.map.level_cap then
        config_mod.slider.special = 2
    end

    item_config_key = "mod.slider.lock"
    changed = slider_cond(function()
        return set:slider_int(
            util_gui.tr("misc.text_lock", "edit_lock"),
            item_config_key,
            1,
            2,
            config:get(item_config_key) == 1 and config.lang:tr("misc.text_yes")
                or config.lang:tr("misc.text_no")
        )
    end, 0, "mod.edit_lock") or changed

    return changed
end

---@return boolean, boolean, boolean
local function draw_buttons()
    local config_mod = config.current.mod

    imgui.separator()

    imgui.begin_disabled(config_mod.combo.mode == mod.enum.mode.ALL and not util_table.any({
        config_mod.edit_level,
        config_mod.edit_life,
        config_mod.edit_lock,
        config_mod.edit_player,
        config_mod.edit_target_num,
        config_mod.edit_time,
        config_mod.edit_tod,
        config_mod.edit_special
            and s.get("snow.QuestManager"):isOpenSpecialRandomMysteryQuest()
            and config_mod.slider.level == snow.map.level_cap,
    }))
    local is_apply = button_apply()
    imgui.end_disabled()

    imgui.same_line()

    imgui.begin_disabled(config_mod.combo.mode == mod.enum.mode.ALL)
    local is_reset = imgui.button(util_gui.tr("mod.button_reset"))
    imgui.end_disabled()

    imgui.same_line()

    local is_delete = false
    imgui.begin_disabled(is_delete_disabled())
    local delete_button = imgui.button(util_gui.tr("mod.button_delete"))
    util_imgui.tooltip(config.lang:tr("mod.tooltip_delete"))
    if delete_button then
        if not config_mod.disable_delete_confirm then
            util_imgui.open_popup("action_delete", 62, 30)
        else
            is_delete = true
        end
    end
    imgui.end_disabled()

    if
        util_imgui.popup_yesno(
            "action_delete",
            config.lang:tr("misc.text_rusure"),
            config.lang:tr("misc.text_yes"),
            config.lang:tr("misc.text_no")
        )
    then
        is_delete = true
    end

    return is_apply, is_reset, is_delete
end

local function draw_edit_one()
    local config_mod = config.current.mod
    local quest = mystery.current_quest
    local changed = false

    if quest then
        if draw_edit_ems() then
            changed = true
            local config_combo = config_mod.combo
            local combo = state.combo

            mystery.edit_ems(quest, state.combo.map:get_key(config_combo.map), {
                combo.em0:get_key(config_combo.em0),
                combo.em1:get_key(config_combo.em1),
                combo.em2:get_key(config_combo.em2),
                combo.em3:get_key(config_combo.em3),
                combo.em5:get_key(config_combo.em5),
            })
        end

        if draw_edit_cond() then
            changed = true
            local config_slider = config_mod.slider

            mystery.edit_cond(
                config_slider.level,
                snow.map.hunt_num_list[config_slider.target_num],
                snow.map.order_num_list[config_slider.player],
                snow.map.quest_life_list[config_slider.life],
                snow.map.time_limit_list[config_slider.time],
                config_slider.tod,
                config_slider.special == 1,
                config_slider.lock == 1,
                quest
            )
        end

        if changed then
            mystery.get_seed_flag(quest)
        end

        local is_apply, is_reset, is_delete = draw_buttons()

        if is_apply then
            mystery.apply(quest --[[@as Quest]])
            config_mod.combo.quest =
                state.combo.quest:swap(mystery.quest_data, config_mod.combo.quest) --[[@as integer]]
            swap_quest_settings(state.combo.quest:get_key(config_mod.combo.quest))
            _G._AUTO_QUEST_RELOAD = true
        elseif is_reset then
            mystery.reset_to_original(quest --[[@as Quest]])
            swap_quest_settings(state.combo.quest:get_key(config_mod.combo.quest))
        elseif is_delete then
            mystery.remove(quest --[[@as Quest]])
            config_mod.combo.quest =
                state.combo.quest:swap(mystery.quest_data, config_mod.combo.quest) --[[@as integer]]
            apply_query(config_mod.filter)
            _G._AUTO_QUEST_RELOAD = true
        end
    end
end

local function draw_edit_all()
    local config_mod = config.current.mod

    if util_table.empty(state.combo.quest.values) then
        return
    end

    draw_edit_cond()
    local is_apply, _, is_delete = draw_buttons()

    if is_apply then
        local quests = util_table.extract_values(mystery.quest_data, state.combo.quest.keys)
        local config_slider = config_mod.slider
        ---@type boolean?
        local is_lock
        ---@type boolean?
        local is_special

        if config_mod.edit_lock then
            is_lock = config_slider.lock == 1
        end

        if config_mod.edit_special or config_mod.slider.level < snow.map.level_cap then
            is_special = config_slider.special == 1
        end

        mystery.edit_cond_many(
            config_mod.edit_level and config_mod.slider.level or nil,
            config_mod.edit_target_num and snow.map.hunt_num_list[config_slider.target_num] or nil,
            config_mod.edit_player and snow.map.order_num_list[config_slider.player] or nil,
            config_mod.edit_life and snow.map.quest_life_list[config_slider.life] or nil,
            config_mod.edit_time and snow.map.time_limit_list[config_slider.time] or nil,
            config_mod.edit_tod and config_slider.tod or nil,
            is_special,
            is_lock,
            quests
        )
        mystery.apply_many(quests)
        _G._AUTO_QUEST_RELOAD = true
        config_mod.combo.quest = state.combo.quest:swap(mystery.quest_data, config_mod.combo.quest) --[[@as integer]]
    elseif is_delete then
        mystery.remove_many(util_table.extract_values(mystery.quest_data, state.combo.quest.keys))
        config_mod.combo.quest = state.combo.quest:swap(mystery.quest_data, config_mod.combo.quest) --[[@as integer]]
        apply_query(config_mod.filter)
        _G._AUTO_QUEST_RELOAD = true
    end
end

function this.reload()
    local config_mod = config.current.mod
    mystery.reload()
    apply_query(config_mod.filter)
    config_mod.combo.quest = 1
    swap_quest_settings(state.combo.quest:get_key(config_mod.combo.quest))
end

function this.draw()
    local config_mod = config.current.mod

    if mod.do_reload then
        mystery.reload()
        apply_query(config_mod.filter)
        boot = false
        mod.do_reload = false
    end

    if set:combo(util_gui.tr("mod.combo_mode"), "mod.combo.mode", state.combo.mode.values) then
        swap_quest_settings(
            config_mod.combo.mode == mod.enum.mode.ONE
                    and state.combo.quest:get_key(config_mod.combo.quest)
                or nil
        )
    end

    if set:input_text(util_gui.tr("mod.input_filter"), "mod.filter") then
        apply_query(config_mod.filter)
    end

    local changed =
        set:combo(util_gui.tr("mod.combo_quest"), "mod.combo.quest", state.combo.quest.values)
    if config_mod.filter == "" then
        util_imgui.tooltip(
            string.format("%s: %s", config.lang:tr("misc.text_quests"), mystery.size)
        )
    else
        util_imgui.tooltip(
            string.format(
                "%s: %s, %s: %s",
                config.lang:tr("misc.text_quests"),
                mystery.size,
                config.lang:tr("misc.text_filtered"),
                util_table.size(state.combo.quest.values)
            )
        )
    end

    if changed and config_mod.combo.mode == mod.enum.mode.ONE then
        swap_quest_settings(state.combo.quest:get_key(config_mod.combo.quest))
    end

    if config_mod.combo.mode == mod.enum.mode.ONE then
        draw_edit_one()
    elseif config_mod.combo.mode == mod.enum.mode.ALL then
        draw_edit_all()
    end
end

return this
