---@class GuiState
---@field combo GuiCombo
---@field set ImguiConfigSet

---@class (exact) GuiCombo
---@field mode Combo
---@field quest Combo
---@field map Combo
---@field em0 Combo
---@field em1 Combo
---@field em2 Combo
---@field em3 Combo
---@field em5 Combo
---@field quest_gen Combo
---@field map_rules Combo

local combo = require("AnomalyInvestigationEditor.gui.combo")
local config = require("AnomalyInvestigationEditor.config.init")
local config_set = require("AnomalyInvestigationEditor.util.imgui.config_set")
local data = require("AnomalyInvestigationEditor.data.init")
local game_data = require("AnomalyInvestigationEditor.util.game.data")
local mystery = require("AnomalyInvestigationEditor.mystery")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")

local snow_map = data.snow.map
local mod = data.mod
local rl = game_data.reverse_lookup

---@class GuiState
local this = {
    combo = {
        mode = combo:new(mod.enum.mode, function(a, b)
            return mod.enum.mode[a.key] < mod.enum.mode[b.key]
        end, function(value)
            return rl(mod.enum.mode, value)
        end, function(key)
            return config.lang:tr("mod.combo_mode_values." .. key)
        end),
        quest = combo:new(nil, function(a, b)
            return a.key > b.key
        end, function(value)
            return value.quest_no
        end, function(key)
            return mystery.format_quest_name(
                config.current.mod.quest_name_format,
                mystery.quest_data[key]
            )
        end),
        map = combo:new(nil, function(a, b)
            return a.value < b.value
        end, function(value)
            return value.map_type
        end, function(key)
            return snow_map.map_data[key].name
        end),
        map_rules = combo:new(nil, function(a, b)
            return a.value < b.value
        end, function(value)
            return value.map_type
        end, function(key)
            return snow_map.map_data[key].name
        end),
        em0 = combo:new(
            nil,
            function(a, b)
                if a.key == 0 then
                    return true
                elseif b.key == 0 then
                    return false
                end
                return a.value < b.value
            end,
            nil,
            function(key)
                return snow_map.em_data[key].name
            end
        ),
        em1 = combo:new(
            nil,
            function(a, b)
                if a.key == 0 then
                    return true
                elseif b.key == 0 then
                    return false
                end
                return a.value < b.value
            end,
            nil,
            function(key)
                return snow_map.em_data[key].name
            end
        ),
        em2 = combo:new(
            nil,
            function(a, b)
                if a.key == 0 then
                    return true
                elseif b.key == 0 then
                    return false
                end
                return a.value < b.value
            end,
            nil,
            function(key)
                return snow_map.em_data[key].name
            end
        ),
        em3 = combo:new(
            nil,
            function(a, b)
                if a.key == 0 then
                    return true
                elseif b.key == 0 then
                    return false
                end
                return a.value < b.value
            end,
            nil,
            function(key)
                return snow_map.em_data[key].name
            end
        ),
        em5 = combo:new(
            nil,
            function(a, b)
                if a.key == 0 then
                    return true
                elseif b.key == 0 then
                    return false
                end
                return a.value < b.value
            end,
            nil,
            function(key)
                return snow_map.em_data[key].name
            end
        ),
        quest_gen = combo:new(
            nil,
            function(a, b)
                return a.key < b.key
            end,
            nil,
            function(key)
                if key == -1 then
                    return config.lang:tr("misc.text_random")
                end
                return string.format(
                    "%s%s%s",
                    config.lang:tr("misc.text_mystery_short"),
                    config.lang:tr("misc.text_star"),
                    key + 1
                )
            end
        ),
    },
    set = config_set:new(config),
}
---@enum GuiColors
this.colors = {
    bad = 0xff1947ff,
    good = 0xff47ff59,
    info = 0xff27f3f5,
}

function this.translate_combo()
    this.combo.mode:translate()
    this.combo.quest_gen:translate()
end

function this.init()
    this.combo.map:swap(snow_map.map_data)
    this.combo.map_rules:swap(snow_map.map_data)
    local key_to_value = util_table.deep_copy(snow_map.quest_level_to_em)
    ---@diagnostic disable-next-line: no-unknown
    key_to_value[-1] = {}
    this.combo.quest_gen:swap(key_to_value)
    this.translate_combo()
end

return this
