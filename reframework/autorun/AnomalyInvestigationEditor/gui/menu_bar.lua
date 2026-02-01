local config = require("AnomalyInvestigationEditor.config.init")
local data = require("AnomalyInvestigationEditor.data.init")
local gui_mystery = require("AnomalyInvestigationEditor.gui.mystery")
local gui_util = require("AnomalyInvestigationEditor.gui.util")
local mystery = require("AnomalyInvestigationEditor.mystery")
local state = require("AnomalyInvestigationEditor.gui.state")
local util_imgui = require("AnomalyInvestigationEditor.util.imgui.init")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")

local mod = data.mod
local snow_map = data.snow.map
local set = state.set

local this = {}

---@param label string
---@param draw_func fun()
---@param enabled_obj boolean?
---@param text_color integer?
---@param size number[]?
---@return boolean
local function draw_menu(label, draw_func, enabled_obj, text_color, size)
    enabled_obj = enabled_obj == nil and true or enabled_obj

    if text_color then
        imgui.push_style_color(0, text_color)
    end

    if size then
        imgui.set_next_window_size(size)
    end

    local menu = imgui.begin_menu(label, enabled_obj)

    if text_color then
        imgui.pop_style_color(1)
    end

    if menu then
        draw_func()
        imgui.end_menu()
    end

    return menu
end

local function draw_quest_name_format_menu()
    imgui.spacing()
    imgui.indent(1)

    if set:input_text("##input_quest_name_format", "mod.quest_name_format") then
        state.combo.quest:translate()
    end

    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_quest_name_format"))

    imgui.same_line()
    imgui.invisible_button("input_quest_name_format_gap", { 1, 0 })
    imgui.same_line()

    if imgui.button(gui_util.tr("menu.config.button_reset")) then
        config.current.mod.quest_name_format = config.default.mod.quest_name_format
        config:save()
    end

    imgui.spacing()
    imgui.unindent(1)
end

local function draw_mod_menu()
    imgui.push_style_var(14, Vector2f.new(0, 2))
    set:menu_item(gui_util.tr("mod.box_allow_invalid"), "mod.allow_invalid_quests")
    set:menu_item(gui_util.tr("mod.box_disable_delete_confirm"), "mod.disable_delete_confirm")
    draw_menu(gui_util.tr("menu.config.quest_name_format"), draw_quest_name_format_menu)
    imgui.pop_style_var(1)
end

local function draw_lang_menu()
    local config_lang = config.current.mod.lang
    imgui.push_style_var(14, Vector2f.new(0, 2))

    for i = 1, #config.lang.sorted do
        local menu_item = config.lang.sorted[i]
        if util_imgui.menu_item(menu_item, config_lang.file == menu_item) then
            config_lang.file = menu_item
            config.lang:change()
            state.translate_combo()
            config:save()
        end
    end

    imgui.separator()

    set:menu_item(gui_util.tr("menu.language.fallback"), "mod.lang.fallback")
    util_imgui.tooltip(config.lang:tr("menu.language.fallback_tooltip"))

    imgui.pop_style_var(1)
end

local function draw_quest_gen_menu()
    local config_mod = config.current.mod

    imgui.spacing()
    imgui.indent(2)

    set:combo(
        gui_util.tr("mod.combo_quest_gen_rank"),
        "mod.combo.quest_gen_rank",
        state.combo.quest_gen.values
    )
    set:slider_int(
        gui_util.tr("mod.slider_quest_gen_count"),
        "mod.slider.quest_gen_count",
        1,
        snow_map.max_quest_count
    )
    if imgui.button(gui_util.tr("mod.button_generate")) then
        local key = state.combo.quest_gen:get_key(config_mod.combo.quest_gen_rank)
        local ems = key == -1 and snow_map.quest_level_to_em
            or util_table.extract_keys(snow_map.quest_level_to_em, { key })

        if mystery.generate_quest(config_mod.slider.quest_gen_count, ems) then
            gui_mystery.reload()
            _G._AUTO_QUEST_RELOAD = true
        end
    end

    imgui.unindent(2)
    imgui.spacing()
end

local function draw_help_menu()
    local config_gui = config.gui.current.gui
    local config_mod = config.current.mod
    imgui.push_style_var(14, Vector2f.new(0, 2))

    if util_imgui.menu_item(gui_util.tr("mod.button_rules"), nil, nil, true) then
        if not config_gui.rules.is_opened then
            config_mod.combo.map_rules = config_mod.combo.map
        end

        config_gui.rules.is_opened = true
    end

    if util_imgui.menu_item(gui_util.tr("mod.button_filter"), nil, nil, true) then
        config_gui.filter.is_opened = true
    end

    imgui.pop_style_var(1)
end

function this.draw()
    draw_menu(gui_util.tr("menu.config.name"), draw_mod_menu)
    draw_menu(gui_util.tr("menu.language.name"), draw_lang_menu)
    imgui.begin_disabled(not mod.ok)
    draw_menu(gui_util.tr("menu.quest_gen.name"), draw_quest_gen_menu)
    imgui.end_disabled()
    draw_menu(gui_util.tr("menu.help.name"), draw_help_menu)
end

return this
