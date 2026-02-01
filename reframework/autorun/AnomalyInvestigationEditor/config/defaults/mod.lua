---@class (exact) MainSettings : SettingsBase
---@field version string
---@field mod ModSettings

---@class (exact) ModLanguage
---@field file string
---@field fallback boolean

---@class (exact) ModSettings
---@field allow_invalid_quests boolean
---@field disable_delete_confirm boolean
---@field quest_name_format string
---@field filter string
---@field edit_level boolean
---@field edit_tod boolean
---@field edit_special boolean
---@field edit_lock boolean
---@field edit_target_num boolean
---@field edit_life boolean
---@field edit_time boolean
---@field edit_player boolean
---@field combo {
--- mode: integer,
--- quest: integer,
--- map: integer,
--- em0: integer,
--- em1: integer,
--- em2: integer,
--- em3: integer,
--- em5: integer,
--- quest_gen_rank: integer,
--- map_rules: integer,
--- }
---@field slider {
--- tod: integer,
--- special: integer,
--- level: integer,
--- target_num: integer,
--- life: integer,
--- time: integer,
--- player: integer,
--- lock: integer,
--- quest_gen_count: integer,
--- }
---@field lang ModLanguage

local version = require("AnomalyInvestigationEditor.config.version")

---@type MainSettings
return {
    version = version.version,
    mod = {
        lang = {
            file = "en-us",
            fallback = true,
        },
        combo = {
            mode = 1,
            quest = 1,
            map = 1,
            em0 = 1,
            em1 = 1,
            em2 = 1,
            em3 = 1,
            em5 = 1,
            quest_gen_rank = 1,
            map_rules = 1,
        },
        slider = {
            tod = 1,
            special = 1,
            level = 1,
            target_num = 1,
            life = 1,
            time = 1,
            player = 1,
            lock = 1,
            quest_gen_count = 1,
        },
        quest_name_format = "%main_monster% | %map% | %level%",
        filter = "",
        edit_level = false,
        edit_tod = false,
        edit_special = false,
        edit_lock = false,
        edit_target_num = false,
        edit_life = false,
        edit_time = false,
        edit_player = false,
        allow_invalid_quests = false,
        disable_delete_confirm = false,
    },
}
