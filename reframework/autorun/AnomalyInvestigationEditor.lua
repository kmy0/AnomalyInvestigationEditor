local config = require("AnomalyInvestigationEditor.config.init")
local config_menu = require("AnomalyInvestigationEditor.gui.init")
local data = require("AnomalyInvestigationEditor.data.init")
local hook = require("AnomalyInvestigationEditor.hook")
local util = require("AnomalyInvestigationEditor.util.init")
local logger = util.misc.logger.g

local init =
    util.misc.init_chain:new("MAIN", config.init, data.init, config_menu.init, data.mod.init)
init.max_retries = 999
---@class MethodUtil
local m = util.ref.methods

m.checkRandomMysteryQuestOrderBan = m.wrap(
    m.get(
        "snow.quest.nRandomMysteryQuest.checkRandomMysteryQuestOrderBan(snow.quest.RandomMysteryQuestData, System.Boolean)"
    )
) --[[@as fun(quest_data: snow.quest.RandomMysteryQuestData, is_guest: System.Boolean): snow.quest.nRandomMysteryQuest.QuestCheckResult]]
m.createRandomMysteryQuest = m.wrap(
    m.get(
        "snow.quest.nRandomMysteryQuest.CreateRandomMysteryQuest(snow.quest.RandomMysteryQuestData, snow.quest.nRandomMysteryQuest.LotType, System.Int32, System.Int32, System.Boolean)"
    )
) --[[@as fun(lot_data: snow.quest.RandomMysteryQuestData, lot_type: snow.quest.nRandomMysteryQuest.LotType, index: System.Int32, quest_no: System.Int32, is_onwer: System.Boolean)]]

m.hook(
    "snow.quest.nRandomMysteryQuest.checkRandomMysteryQuestOrderBan(snow.quest.RandomMysteryQuestData, System.Boolean)",
    nil,
    hook.check_order_ban_post
)
m.hook(
    "snow.QuestManager.getRandomQuestSeedFromQuestNo(System.Int32)",
    nil,
    hook.get_quest_seed_post
)
m.hook("snow.quest.RandomMysteryQuestSeed.isValid()", nil, hook.is_valid_seed_post)
m.hook(
    "snow.quest.nRandomMysteryQuest.lotEnemy(snow.enemy.EnemyDef.MysteryRank, System.Collections.Generic.List`1<snow.enemy.EnemyDef.EmTypes>, snow.quest.nRandomMysteryQuest.LotEmType, snow.QuestMapManager.MapNoType, System.Single, System.Int32)",
    hook.lot_enemy_pre,
    hook.lot_enemy_post
)

re.on_draw_ui(function()
    if imgui.button(string.format("%s %s", config.name, config.commit)) and init.ok then
        local gui_main = config.gui.current.gui.main
        gui_main.is_opened = not gui_main.is_opened
    end

    if not init.failed then
        local errors = logger:format_errors()
        if errors then
            imgui.same_line()
            imgui.text_colored("Error!", config_menu.state.colors.bad)
            util.imgui.tooltip_exclamation(errors)
        elseif not init.ok then
            imgui.same_line()
            imgui.text_colored("Initializing...", config_menu.state.colors.info)
        end
    else
        imgui.same_line()
        imgui.text_colored("Init failed!", config_menu.state.colors.bad)
    end
end)

re.on_application_entry("BeginRendering", function()
    init:init() -- reframework does not like nested re.on_frame
end)

re.on_frame(function()
    if not init.ok then
        return
    end

    data.mod.is_ok()
    local config_gui = config.gui.current.gui

    if not reframework:is_drawing_ui() then
        config_gui.main.is_opened = false
        config_gui.filter.is_opened = false
        config_gui.rules.is_opened = false
    end

    if config_gui.main.is_opened then
        config_menu.draw()
    end

    if config_gui.filter.is_opened then
        config_menu.help.filter.draw()
    end

    if config_gui.rules.is_opened then
        config_menu.help.rules.draw()
    end

    config.run_save()
end)

re.on_config_save(function()
    if data.mod.initialized then
        config.save_no_timer_global()
    end
end)
