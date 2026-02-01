local config = require("AnomalyInvestigationEditor.config.init")
local util_gui = require("AnomalyInvestigationEditor.gui.util")
local util_imgui = require("AnomalyInvestigationEditor.util.imgui.init")

local this = {
    window = {
        flags = 0,
        condition = 2,
    },
}

local function draw_table()
    local flags = imgui.TableFlags.BordersH
        | imgui.TableFlags.BordersV
        | imgui.TableFlags.SizingFixedFit
        | imgui.TableFlags.NoHostExtendX --[[@as ImGuiTableFlags]]

    if imgui.begin_table("table_hunt_num", 3, flags) then
        imgui.table_setup_column(util_gui.tr("help.table_filter.header_search_field"))
        imgui.table_setup_column(util_gui.tr("help.table_filter.header_type"))
        imgui.table_setup_column(util_gui.tr("help.table_filter.header_data"))
        imgui.table_headers_row()

        local table_data = {
            {
                "main_monster",
                config.lang:tr("misc.text_string"),
                config.lang:tr("misc.text_main"),
            },
            {
                "monster",
                config.lang:tr("misc.text_string"),
                string.format(
                    "%s/%s",
                    config.lang:tr("misc.text_main"),
                    config.lang:tr("misc.text_sub")
                ),
            },
            {
                "map",
                config.lang:tr("misc.text_string"),
                config.lang:tr("misc.text_map"),
            },
            { "level", config.lang:tr("misc.text_number"), config.lang:tr("misc.text_level") },
            { "rank", config.lang:tr("misc.text_number"), config.lang:tr("misc.text_rank") },
            {
                "target_num",
                config.lang:tr("misc.text_number"),
                config.lang:tr("misc.text_target_num"),
            },
            {
                "quest_id",
                config.lang:tr("misc.text_number"),
                config.lang:tr("misc.text_quest_id"),
            },
            { "player", config.lang:tr("misc.text_number"), config.lang:tr("misc.text_player") },
            { "time", config.lang:tr("misc.text_number"), config.lang:tr("misc.text_time") },
            { "life", config.lang:tr("misc.text_number"), config.lang:tr("misc.text_life") },
            {
                "tod",
                string.format(
                    "%s/%s",
                    config.lang:tr("misc.text_day"),
                    config.lang:tr("misc.text_night")
                ),
                config.lang:tr("misc.text_tod"),
            },
            {
                "extra_map",
                string.format(
                    "%s/%s",
                    config.lang:tr("misc.text_yes"),
                    config.lang:tr("misc.text_no")
                ),
                config.lang:tr("misc.text_map"),
            },
            {
                "invader",
                string.format(
                    "%s/%s",
                    config.lang:tr("misc.text_yes"),
                    config.lang:tr("misc.text_no")
                ),
                config.lang:tr("misc.text_invader"),
            },
            {
                "special",
                string.format(
                    "%s/%s",
                    config.lang:tr("misc.text_yes"),
                    config.lang:tr("misc.text_no")
                ),
                config.lang:tr("misc.text_special"),
            },
            {
                "lock",
                string.format(
                    "%s/%s",
                    config.lang:tr("misc.text_yes"),
                    config.lang:tr("misc.text_no")
                ),
                config.lang:tr("misc.text_lock"),
            },
            {
                "valid",
                string.format(
                    "%s/%s",
                    config.lang:tr("misc.text_yes"),
                    config.lang:tr("misc.text_no")
                ),
                config.lang:tr("misc.text_auth"),
            },
        }

        for i = 1, #table_data do
            local d = table_data[i]
            imgui.table_next_row()

            imgui.table_set_column_index(0)
            imgui.text(d[1])
            imgui.table_set_column_index(1)
            imgui.text(d[2])
            imgui.table_set_column_index(2)
            imgui.text(d[3])
        end

        imgui.end_table()
    end
end

function this.draw()
    local gui_filter = config.gui.current.gui.filter

    imgui.set_next_window_pos(
        Vector2f.new(gui_filter.pos_x, gui_filter.pos_y),
        this.window.condition
    )
    imgui.set_next_window_size(
        Vector2f.new(gui_filter.size_x, gui_filter.size_y),
        this.window.condition
    )

    if config.lang.font then
        imgui.push_font(config.lang.font)
    end

    gui_filter.is_opened = imgui.begin_window(
        config.lang:tr("mod.button_filter"),
        gui_filter.is_opened,
        this.window.flags
    )

    util_imgui.set_win_state(gui_filter)

    if not gui_filter.is_opened then
        if config.lang.font then
            imgui.pop_font()
        end

        imgui.end_window()
        return
    end

    imgui.spacing()
    imgui.indent(2)

    draw_table()
    imgui.text(config.lang:tr("help.text_case"))
    imgui.text(string.format("%s:", config.lang:tr("help.text_example")))
    imgui.input_text_multiline("##filter_example", config.lang:tr("help.text_queries"), nil, 1 << 9)

    imgui.unindent(2)

    if config.lang.font then
        imgui.pop_font()
    end

    imgui.spacing()
    imgui.end_window()
end

return this
