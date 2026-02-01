---@class MainConfig : ConfigBase
---@field current MainSettings
---@field default MainSettings
---
---@field lang Language
---@field gui GuiConfig
---
---@field version string
---@field commit string
---@field name string
---
---@field hud_default_path string
---@field option_default_path string
---@field default_config_path string
---
---@field grid_size integer
---@field porter_timeout number
---@field handler_timeout number

local config_base = require("AnomalyInvestigationEditor.util.misc.config_base")
local lang = require("AnomalyInvestigationEditor.config.lang")
local util_misc = require("AnomalyInvestigationEditor.util.misc.init")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")
local version = require("AnomalyInvestigationEditor.config.version")

local mod_name = "AnomalyInvestigationEditor"
local config_path = util_misc.join_paths(mod_name, "config.json")

---@class MainConfig
local this = config_base:new(require("AnomalyInvestigationEditor.config.defaults.mod"), config_path)

this.version = version.version
this.commit = version.commit
this.name = mod_name

this.default_config_path = config_path

this.gui = config_base:new(
    require("AnomalyInvestigationEditor.config.defaults.gui"),
    util_misc.join_paths(this.name, "other_configs", "gui.json")
) --[[@as GuiConfig]]
this.lang = lang:new(
    require("AnomalyInvestigationEditor.config.defaults.lang"),
    util_misc.join_paths(this.name, "lang"),
    "en-us.json",
    this
)

function this:load()
    local loaded_config = json.load_file(self.path) --[[@as MainSettings?]]
    if loaded_config then
        self.current = util_table.merge_t(self.default, loaded_config)
    else
        self.current = util_table.deep_copy(self.default)
        self:save_no_timer()
    end
end

---@return string
function this:get_backup_path()
    return util_misc.join_paths(
        self.name,
        "backups",
        string.format(
            "%s_backup_v%s_%s",
            os.time(),
            self.current.version,
            util_misc.get_file_name(self.path)
        )
    )
end

function this:backup()
    self:save_no_timer(self:get_backup_path())
end

---@return boolean
function this.init()
    this:load()
    this.gui:load()
    this.lang:load()

    return true
end

return this
