---@class (exact) SnowData
---@field map SnowMap

---@class (exact) SnowMap
---@field em_data table<snow.enemy.EnemyDef.EmTypes, EmData>
---@field map_data table<snow.QuestMapManager.MapNoType, MapData>
---@field quest_life_array System.Array<System.UInt32>
---@field quest_life_list integer[]
---@field time_limit_array System.Array<System.UInt32>
---@field time_limit_list integer[]
---@field hunt_num_list integer[]
---@field time_limit_data table<integer, table<integer, boolean>>
---@field order_num_data table<integer, table<integer, boolean>>
---@field order_num_array System.Array<System.UInt32>
---@field order_num_list integer[]
---@field hunt_num_data table<integer, table<integer, boolean>>
---@field quest_life_data table<integer, table<integer, boolean>>
---@field start_time_list snow.quest.StartTimeType[]
---@field max_quest_count integer
---@field hunt_num_to_time_limit table<integer, integer[]>
---@field hunt_num_to_life_limit table<integer, integer[]>
---@field level_cap integer
---@field random_mystery_offset integer
---@field quest_level_to_em table<snow.quest.QuestLevel, snow.enemy.EnemyDef.EmTypes[]>
---@field hunt_num_to_min_level table<integer, integer>
---@field time_limit_to_min_level table<integer, integer>
---@field quest_life_to_min_level table<integer, integer>
---@field quest_life_to_max_level table<integer, integer>
---@field order_num_to_min_level table<integer, integer>
---@field additional_dups table<snow.enemy.EnemyDef.EmTypes, table<snow.enemy.EnemyDef.EmTypes, boolean>>

---@class (exact) EmData
---@field em_type snow.enemy.EnemyDef.EmTypes
---@field release_level_main integer
---@field release_level_sub integer
---@field release_level_extra integer
---@field available_map snow.QuestMapManager.MapNoType[]
---@field name string
---@field memory number
---@field quest_rank snow.quest.QuestLevel

---@class (exact) MapData
---@field map_type snow.QuestMapManager.MapNoType
---@field available_em snow.enemy.EnemyDef.EmTypes[]
---@field release_level integer
---@field name string
---@field hunt_num table<integer, boolean>
---@field is_extra boolean
---@field memory_limit number

---@class SnowData
local this = {
    map = {
        em_data = {},
        map_data = {},
        quest_life_list = {},
        order_num_data = {},
        time_limit_list = {},
        start_time_list = {},
        max_quest_count = -1,
        hunt_num_to_time_limit = {},
        time_limit_data = {},
        hunt_num_data = {},
        quest_life_data = {},
        hunt_num_list = {},
        quest_life_array = {},
        time_limit_array = {},
        level_cap = 0,
        order_num_array = {},
        order_num_list = {},
        random_mystery_offset = 700000,
        quest_level_to_em = {},
        hunt_num_to_min_level = {},
        hunt_num_to_life_limit = {},
        time_limit_to_min_level = {},
        quest_life_to_min_level = {},
        quest_life_to_max_level = {},
        order_num_to_min_level = {},
        additional_dups = {},
    },
}

return this
