local config = require("AnomalyInvestigationEditor.config.init")
local data = require("AnomalyInvestigationEditor.data.init")
local game_data = require("AnomalyInvestigationEditor.util.game.data")
local mystery = require("AnomalyInvestigationEditor.mystery")
local util_ref = require("AnomalyInvestigationEditor.util.ref.init")

local snow_enum = data.snow.enum
local rl = game_data.reverse_lookup

local this = {}

function this.check_order_ban_post(retval)
    if
        config.current.mod.allow_invalid_quests
        and (not config.gui.current.gui.main.is_opened or not data.mod.ok)
    then
        return false
    end
end

function this.get_quest_seed_post(retval)
    if mystery.spoof_seed then
        return mystery.spoof_seed:get_address()
    end
end

function this.is_valid_seed_post(retval)
    if mystery.spoof_seed then
        return true
    end
end

function this.lot_enemy_pre(args)
    if
        mystery.spoof_em
        and util_ref.to_int(args[4]) == rl(snow_enum.random_mystery_lot_em_type, "Main")
    then
        util_ref.thread_store(true)
    end
end

function this.lot_enemy_post(retval)
    if mystery.spoof_em and util_ref.thread_get() then
        local ret = mystery.spoof_em
        mystery.spoof_em = nil
        return ret
    end
end

return this
