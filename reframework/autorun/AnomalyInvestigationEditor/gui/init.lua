---@class Gui
---@field window GuiWindow
---@field state GuiState

---@class (exact) GuiWindow
---@field flags integer
---@field condition integer

local config = require("AnomalyInvestigationEditor.config.init")
local data = require("AnomalyInvestigationEditor.data.init")
local gui_mystery = require("AnomalyInvestigationEditor.gui.mystery")
local menu_bar = require("AnomalyInvestigationEditor.gui.menu_bar")
local state = require("AnomalyInvestigationEditor.gui.state")
local util_imgui = require("AnomalyInvestigationEditor.util.imgui.init")

---@class Gui
local this = {
    window = {
        flags = 1024,
        condition = 2,
    },
    state = state,
    help = require("AnomalyInvestigationEditor.gui.help.init"),
}

function this.draw()
    local config_gui = config.gui.current.gui
    local gui_main = config_gui.main

    imgui.set_next_window_pos(Vector2f.new(gui_main.pos_x, gui_main.pos_y), this.window.condition)
    imgui.set_next_window_size(
        Vector2f.new(gui_main.size_x, gui_main.size_y),
        this.window.condition
    )

    if config.lang.font then
        imgui.push_font(config.lang.font)
    end

    gui_main.is_opened = imgui.begin_window(
        string.format("%s %s", config.name, config.commit),
        gui_main.is_opened,
        this.window.flags
    )

    util_imgui.set_win_state(gui_main)

    if not gui_main.is_opened then
        if config.lang.font then
            imgui.pop_font()
        end

        config_gui.filter.is_opened = false
        config_gui.rules.is_opened = false
        config.save_global()
        imgui.end_window()
        return
    end

    if imgui.begin_menu_bar() then
        menu_bar.draw()
        imgui.end_menu_bar()
    end

    imgui.spacing()
    imgui.indent(2)

    if data.mod.ok then
        gui_mystery.draw()
    else
        imgui.text_colored(config.lang:tr("misc.text_cant_use"), state.colors.bad)
    end

    imgui.unindent(2)

    if config.lang.font then
        imgui.pop_font()
    end

    imgui.spacing()
    imgui.end_window()
end

---@return boolean
function this.init()
    state.init()
    return true
end

return this
