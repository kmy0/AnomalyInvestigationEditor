local config = require("AnomalyInvestigationEditor.config.init")
local data = require("AnomalyInvestigationEditor.data.init")
local e = require("AnomalyInvestigationEditor.util.game.enum")
local mystery = require("AnomalyInvestigationEditor.mystery")
local util_ref = require("AnomalyInvestigationEditor.util.ref.init")

local this = {}

function this.check_order_ban_post(_)
    if
        config.current.mod.allow_invalid_quests
        and (not config.gui.current.gui.main.is_opened or not data.mod.ok)
    then
        return false
    end
end

function this.get_quest_seed_post(_)
    if mystery.spoof_seed then
        return mystery.spoof_seed:get_address()
    end
end

function this.is_valid_seed_post(_)
    if mystery.spoof_seed then
        return true
    end
end

function this.lot_enemy_pre(args)
    if
        mystery.spoof_em
        and util_ref.to_int(args[4]) == e.get("snow.quest.nRandomMysteryQuest.LotEmType").Main
    then
        util_ref.thread_store(true)
    end
end

function this.lot_enemy_post(_)
    if mystery.spoof_em and util_ref.thread_get() then
        local ret = mystery.spoof_em
        mystery.spoof_em = nil
        return ret
    end
end

return this
