local config = require("AnomalyInvestigationEditor.config.init")
local data = require("AnomalyInvestigationEditor.data.init")
local state = require("AnomalyInvestigationEditor.gui.state")
local util_gui = require("AnomalyInvestigationEditor.gui.util")
local util_imgui = require("AnomalyInvestigationEditor.util.imgui.init")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")

local set = state.set
local snow_map = data.snow.map

local this = {
    window = {
        flags = 0,
        condition = 2,
    },
    table = {
        name = "rules_monster",
        flags = imgui.TableFlags.Sortable
            | imgui.TableFlags.BordersH
            | imgui.TableFlags.BordersV
            | imgui.TableFlags.ScrollY --[[@as ImGuiTableFlags]],
        ---@type EmData[]
        data = {},
        ---@type snow.QuestMapManager.MapNoType
        map = -1,
        headers = {
            "name",
            "quest_rank",
            "release_level_main",
            "release_level_sub",
            "release_level_extra",
            "memory",
        },
    },
    table_max_y = 250,
}

---@param map_data MapData
local function draw_condition_table(map_data)
    local flags = imgui.TableFlags.BordersH
        | imgui.TableFlags.BordersV
        | imgui.TableFlags.SizingFixedFit
        | imgui.TableFlags.NoHostExtendX --[[@as ImGuiTableFlags]]

    if imgui.begin_table("table_hunt_num", 4, flags) then
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_hunt_num"))
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_min_level"))
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_time_limit"))
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_life_limit"))
        imgui.table_headers_row()

        for i = 1, #snow_map.hunt_num_list do
            local hunt_num = snow_map.hunt_num_list[i]
            local time_limit = util_table.sort(snow_map.hunt_num_to_time_limit[hunt_num])
            local life_limit = util_table.sort(snow_map.hunt_num_to_life_limit[hunt_num])
            imgui.table_next_row()

            imgui.table_set_column_index(0)
            imgui.text(hunt_num)
            imgui.table_set_column_index(1)

            if map_data.hunt_num[hunt_num] then
                imgui.text(snow_map.hunt_num_to_min_level[hunt_num])
                imgui.table_set_column_index(2)
                imgui.text(table.concat(time_limit, ", "))
                imgui.table_set_column_index(3)
                imgui.text(table.concat(life_limit, ", "))
            else
                imgui.text(config.lang:tr("misc.text_na"))
                imgui.table_set_column_index(2)
                imgui.text(config.lang:tr("misc.text_na"))
                imgui.table_set_column_index(3)
                imgui.text(config.lang:tr("misc.text_na"))
            end
        end

        imgui.end_table()
    end

    imgui.same_line()

    if imgui.begin_table("table_time_limit", 2, flags) then
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_time_limit"))
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_min_level"))
        imgui.table_headers_row()

        for i = 1, #snow_map.time_limit_list do
            local time_limit = snow_map.time_limit_list[i]
            imgui.table_next_row()

            imgui.table_set_column_index(0)
            imgui.text(time_limit)
            imgui.table_set_column_index(1)
            imgui.text(snow_map.time_limit_to_min_level[time_limit])
        end

        imgui.end_table()
    end

    if imgui.begin_table("table_quest_life", 3, flags) then
        imgui.table_setup_column(config.lang:tr("help.table_cond.header_life_limit") .. " (?)")
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_min_level"))
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_max_level"))

        imgui.table_next_row(1)
        for i = 0, 2 do
            imgui.table_set_column_index(i)
            imgui.table_header(imgui.table_get_column_name(i))
            util_imgui.tooltip(config.lang:tr("help.table_cond.tooltip_quest_life"))
        end

        for i = 1, #snow_map.quest_life_list do
            local quest_life = snow_map.quest_life_list[i]
            imgui.table_next_row()

            imgui.table_set_column_index(0)
            imgui.text(quest_life)
            imgui.table_set_column_index(1)
            imgui.text(snow_map.quest_life_to_min_level[quest_life])
            imgui.table_set_column_index(2)
            imgui.text(snow_map.quest_life_to_max_level[quest_life])
        end

        imgui.end_table()
    end

    imgui.same_line()

    if imgui.begin_table("table_order_num", 2, flags) then
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_order_num"))
        imgui.table_setup_column(util_gui.tr("help.table_cond.header_min_level"))
        imgui.table_headers_row()

        for i = 1, #snow_map.order_num_list do
            local order_num = snow_map.order_num_list[i]
            imgui.table_next_row()

            imgui.table_set_column_index(0)
            imgui.text(order_num)
            imgui.table_set_column_index(1)
            imgui.text(snow_map.order_num_to_min_level[order_num])
        end

        imgui.end_table()
    end
end

---@param map_data MapData
local function draw_monster_table(map_data)
    imgui.text(string.format("%s: %s", config.lang:tr("help.text_memory"), map_data.memory_limit))
    util_imgui.tooltip(config.lang:tr("help.tooltip_memory_limit"), true)

    if map_data.is_extra then
        imgui.text(
            string.format("%s: %s", config.lang:tr("help.text_min_level"), map_data.release_level)
        )
    end

    if
        imgui.begin_table(this.table.name, 6, this.table.flags, Vector2f.new(0, this.table_max_y))
    then
        local sort_specs = imgui.table_get_sort_specs() --[[@as ImGuiTableSortSpecs]]

        if this.table.map ~= map_data.map_type then
            this.table.data = util_table.extract_values(snow_map.em_data, map_data.available_em)
            sort_specs.specs_dirty = true
            this.table.map = map_data.map_type
        end

        if sort_specs.specs_dirty then
            local specs = sort_specs:get_specs()[1]
            local key = this.table.headers[specs.column_index + 1]
            local op_fn = util_imgui.get_sort_op(specs.sort_direction)

            table.sort(this.table.data, function(a, b)
                ---@diagnostic disable-next-line: no-unknown
                local a_key, b_key = a[key], b[key]
                local ret = op_fn(a_key, b_key)

                if a_key == -1 then
                    return false
                elseif b_key == -1 then
                    return true
                end

                return ret
            end)

            sort_specs.specs_dirty = false
        end

        imgui.table_setup_column(
            util_gui.tr("help.table_monster.header_name"),
            imgui.ColumnFlags.DefaultSort
        )
        imgui.table_setup_column(util_gui.tr("help.table_monster.header_quest_rank"))
        imgui.table_setup_column(util_gui.tr("help.table_monster.header_main"))
        imgui.table_setup_column(util_gui.tr("help.table_monster.header_sub"))
        imgui.table_setup_column(util_gui.tr("help.table_monster.header_extra"))
        imgui.table_setup_column(util_gui.tr("help.table_monster.header_memory"))

        imgui.table_next_row(1)
        for i = 0, 5 do
            imgui.table_set_column_index(i)
            imgui.table_header(imgui.table_get_column_name(i))
            if i > 1 and i < 5 then
                util_imgui.tooltip(config.lang:tr("help.table_monster.tooltip_header_level"))
            end
        end

        for _, em in pairs(this.table.data) do
            if em.em_type == 0 then
                goto continue
            end

            imgui.table_next_row()

            for i = 1, #this.table.headers do
                local key = this.table.headers[i]
                ---@diagnostic disable-next-line: no-unknown
                local value = em[key]
                local text = ""

                if key == "quest_rank" and value ~= -1 then
                    text = string.format(
                        "%s%s%s",
                        config.lang:tr("misc.text_mystery_short"),
                        config.lang:tr("misc.text_star"),
                        value + 1
                    )
                else
                    text = value == -1 and config.lang:tr("misc.text_na") or value
                end

                imgui.table_set_column_index(i - 1)
                imgui.text(text)
            end

            ::continue::
        end

        imgui.end_table()
    end
end

function this.draw()
    local gui_rules = config.gui.current.gui.rules

    imgui.set_next_window_pos(Vector2f.new(gui_rules.pos_x, gui_rules.pos_y), this.window.condition)
    imgui.set_next_window_size(
        Vector2f.new(gui_rules.size_x, gui_rules.size_y),
        this.window.condition
    )

    if config.lang.font then
        imgui.push_font(config.lang.font)
    end

    gui_rules.is_opened = imgui.begin_window(
        config.lang:tr("mod.button_rules"),
        gui_rules.is_opened,
        this.window.flags
    )

    util_imgui.set_win_state(gui_rules)

    if not gui_rules.is_opened then
        if config.lang.font then
            imgui.pop_font()
        end

        imgui.end_window()
        return
    end

    imgui.spacing()
    imgui.indent(2)

    set:combo(
        util_gui.tr("help.combo_map_rules"),
        "mod.combo.map_rules",
        state.combo.map_rules.values
    )

    local map = state.combo.map_rules:get_key(config.current.mod.combo.map_rules) --[[@as integer]]
    local map_data = snow_map.map_data[map]

    draw_monster_table(map_data)
    draw_condition_table(map_data)

    imgui.unindent(2)

    if config.lang.font then
        imgui.pop_font()
    end

    imgui.spacing()
    imgui.end_window()
end

return this
