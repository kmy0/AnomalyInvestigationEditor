---@meta

---@class snow.BehaviorRoot : via.Behavior
---@class snow.SnowSingletonBehaviorRoot : snow.BehaviorRoot
---@class snow.SaveDataBase : via.clr.ManagedObject

---@class snow.quest.RandomMysteryQuestData : via.clr.ManagedObject
---@field clear fun(self: snow.quest.RandomMysteryQuestData)
---@field getMainTargetEmType fun(self: snow.quest.RandomMysteryQuestData): snow.enemy.EnemyDef.EmTypes
---@field copyFromValue fun(self: snow.quest.RandomMysteryQuestData, seed: snow.quest.RandomMysteryQuestSeed)
---@field _QuestNo System.Int32
---@field _QuestType snow.quest.QuestType
---@field _QuestLv System.Int32
---@field _HuntTargetNum System.Int32
---@field _isSpecialQuestOpen System.Boolean
---@field _MapNo snow.QuestMapManager.MapNoType
---@field _QuestOrderNum System.UInt32
---@field _StartTime snow.quest.StartTimeType
---@field _TimeLimit System.UInt32
---@field _QuestLife System.UInt32
---@field _IsLock System.Boolean
---@field _IsValidQuest System.Boolean
---@field _BossEmType System.Array<snow.enemy.EnemyDef.EmTypes>

---@class snow.quest.RandomMysteryQuestSeed : System.ValueType
---@field clear fun(self: snow.quest.RandomMysteryQuestSeed)
---@field setEnemyTypes fun(self: snow.quest.RandomMysteryQuestSeed, ems: System.Array<snow.enemy.EnemyDef.EmTypes>)
---@field getEnemyTypes fun(self: snow.quest.RandomMysteryQuestSeed): System.Array<snow.enemy.EnemyDef.EmTypes>
---@field getMysteryRank fun(self: snow.quest.RandomMysteryQuestSeed): System.Array<snow.enemy.EnemyDef.MysteryRank>
---@field Clone fun(self: snow.quest.RandomMysteryQuestSeed): snow.quest.RandomMysteryQuestSeed
---@field _MapNo snow.QuestMapManager.MapNoType
---@field _QuestOrderNum System.UInt32
---@field _StartTime snow.quest.StartTimeType
---@field _HuntTargetNum System.Int32
---@field _QuestLife System.UInt32
---@field _TimeLimit System.UInt32
---@field _MysteryLv System.Int32
---@field _QuestLv System.UInt32
---@field _isSpecialQuestOpen System.Boolean
---@field _IsLock System.Boolean
---@field _OriginQuestLv System.UInt32
---@field _IsNewFlag System.Boolean
---@field _IsSpecialNewFlag System.Boolean
---@field _QuestNo System.Int32

---@class snow.QuestManager : snow.SnowSingletonBehaviorRoot
---@field isExtraStage fun(self: snow.QuestManager, map_type: snow.QuestMapManager.MapNoType): System.Boolean
---@field getRandomMysteryAppearanceMainEmLevel fun(self: snow.QuestManager, em_type: snow.enemy.EnemyDef.EmTypes): System.Int32
---@field getRandomMysteryAppearanceSubEmLevel fun(self: snow.QuestManager, em_type: snow.enemy.EnemyDef.EmTypes): System.Int32
---@field getRandomQuestSeedFromQuestNo fun(self: snow.QuestManager, quest_no: System.Int32): snow.quest.RandomMysteryQuestSeed
---@field isOpenSpecialRandomMysteryQuest fun(self: snow.QuestManager): System.Boolean
---@field get_SaveData fun(self: snow.QuestManager): snow.QuestManager.QuestSaveData
---@field isActiveQuest fun(self: snow.QuestManager): System.Boolean
---@field getFreeMysteryQuestNo fun(self: snow.QuestManager): System.Int32
---@field getEnableRandomMysteryQuestCount fun(self: snow.QuestManager): System.Int32
---@field getFreeSpaceMysteryQuestIDXList fun(self: snow.QuestManager, quest_datas: System.Array<snow.quest.RandomMysteryQuestData>, quest_no: snow.quest.QuestNo, quest_num: System.Int32, is_clear: System.Boolean): System.Array<System.Int32>
---@field getQuestNumberArray fun(self: snow.QuestManager, quest_category: snow.quest.QuestCategory, quest_level: snow.quest.QuestLevel): System.Array<System.Int32>
---@field getFreeMysteryQuestDataIdx2IndexList fun(self: snow.QuestManager, quest_idx_list: System.Array<System.Int32>): System.Array<System.Int32>
---@field _randomMysteryLotEnemyData snow.quest.RandomMysteryLotEnemyData
---@field _randomMysteryLotHuntNumData snow.quest.RandomMysteryLotHuntNumData
---@field _randomMysteryExtraStageData snow.quest.randomMysteryExtraStageData
---@field _randomMysteryReleaseRankData snow.quest.RandomMysteryRankReleaseData
---@field _randomMysteryLotOrderNumData snow.quest.RandomMysteryLotOrderNumData
---@field _randomMysteryLotLifeData snow.quest.RandomMysteryLotLifeData
---@field _randomMysteryLotTimeLimitData snow.quest.RandomMysteryLotTimeLimitData
---@field _RandomMysteryQuestData System.Array<snow.quest.RandomMysteryQuestData>
---@field _QuestDataDictionary System.Dictionary<System.Int32, snow.quest.QuestData>

---@class snow.quest.RandomMysteryLotEnemyData : via.UserData
---@field _LotEnemyList System.Array<snow.quest.RandomMysteryLotEnemyData.LotEnemyData>

---@class snow.quest.RandomMysteryLotEnemyData.LotEnemyData : via.clr.ManagedObject
---@field get_EmType fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): snow.enemy.EnemyDef.EmTypes
---@field get_MysteryRank fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): snow.enemy.EnemyDef.MysteryRank
---@field get_NormalRank fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): snow.enemy.EnemyDef.MysteryRank
---@field get_ReleaseLevelMystery fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): System.Int32
---@field get_ReleaseLevelNormal fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): System.Int32
---@field get_IsMystery fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): System.Boolean
---@field get_IsEnableSub fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): System.Boolean
---@field get_IsEnableExtra fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): System.Boolean
---@field get_IsIntrusion fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): System.Boolean
---@field isValid fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData): System.Boolean
---@field getStageLotTable fun(self: snow.quest.RandomMysteryLotEnemyData.LotEnemyData, is_extra_stage: System.Boolean): System.Array<snow.QuestMapManager.MapNoType>

---@class snow.gui.MessageManager : via.clr.ManagedObject
---@field getMapNameMessage fun(self: snow.gui.MessageManager, map_id: snow.QuestMapManager.MapNoType): System.String
---@field getEnemyNameMessage fun(self: snow.gui.MessageManager ,em_type: snow.enemy.EnemyDef.EmTypes): System.String

---@class snow.quest.RandomMysteryLotHuntNumData : via.UserData
---@field _LotHuntNumTable System.Array<snow.quest.RandomMysteryLotHuntNumData.LotData>

---@class snow.quest.RandomMysteryLotHuntNumData.LotData : via.clr.ManagedObject
---@field get_ApplyLevel fun(self: snow.quest.RandomMysteryLotHuntNumData.LotData): System.UInt32
---@field get_LotTable fun(self: snow.quest.RandomMysteryLotHuntNumData.LotData): System.Array<snow.quest.RandomMysteryLotHuntNumData.TableData>

---@class snow.quest.RandomMysteryLotHuntNumData.TableData : via.clr.ManagedObject
---@field get_LotProb fun(self: snow.quest.RandomMysteryLotHuntNumData.TableData): System.Array<System.Int32>

---@class snow.enemy.EnemyManager : snow.SnowSingletonBehaviorRoot
---@field getEnemyMapMaxMemory fun(self: snow.enemy.EnemyManager, map_type: snow.QuestMapManager.MapNoType): System.Single
---@field getEnemyUseMemory fun(self: snow.enemy.EnemyManager, em_type: snow.enemy.EnemyDef.EmTypes): System.Single

---@class snow.quest.RandomMysteryRankReleaseData : via.UserData
---@field _ReleaseLevelData System.Array<snow.quest.RandomMysteryRankReleaseData.ReleaseData>

---@class snow.quest.RandomMysteryRankReleaseData.ReleaseData : via.clr.ManagedObject
---@field get_ParamData fun(self: snow.quest.RandomMysteryRankReleaseData.ReleaseData): System.Array<snow.quest.RandomMysteryRankReleaseData.Param>

---@class snow.quest.RandomMysteryRankReleaseData.Param : via.clr.ManagedObject
---@field get_MonsterRank fun(self: snow.quest.RandomMysteryRankReleaseData.Param): snow.enemy.EnemyDef.MysteryRank
---@field get_ReleaseLevel fun(self: snow.quest.RandomMysteryRankReleaseData.Param): System.UInt32

---@class snow.quest.RandomMysteryLotOrderNumData : via.UserData
---@field _LotOrderNumTable System.Array<snow.quest.RandomMysteryLotOrderNumData.LotData>

---@class snow.quest.RandomMysteryLotOrderNumData.LotData : via.clr.ManagedObject
---@field get_ApplyLevel fun(self: snow.quest.RandomMysteryLotOrderNumData.LotData): System.UInt32
---@field get_LotTable fun(self: snow.quest.RandomMysteryLotOrderNumData.LotData): System.Array<snow.quest.RandomMysteryLotOrderNumData.TableData>

---@class snow.quest.RandomMysteryLotOrderNumData.TableData : via.clr.ManagedObject
---@field get_LotProb fun(self: snow.quest.RandomMysteryLotOrderNumData.TableData): System.Array<System.Int32>

---@class snow.quest.RandomMysteryLotLifeData : via.clr.ManagedObject
---@field _LotQuestLifeTable System.Array<snow.quest.RandomMysteryLotLifeData.LotData>

---@class snow.quest.RandomMysteryLotLifeData.LotData : via.clr.ManagedObject
---@field get_ApplyLevel fun(self: snow.quest.RandomMysteryLotLifeData.LotData): System.UInt32
---@field get_LotTable fun(self: snow.quest.RandomMysteryLotLifeData.LotData): System.Array<snow.quest.RandomMysteryLotLifeData.TableData>

---@class snow.quest.RandomMysteryLotLifeData.TableData : via.clr.ManagedObject
---@field get_LotProb fun(self: snow.quest.RandomMysteryLotLifeData.TableData): System.Array<System.Int32>

---@class snow.quest.RandomMysteryLotTimeLimitData : via.UserData
---@field _LotTimeLimitTable System.Array<snow.quest.RandomMysteryLotTimeLimitData.LotData>
---@field _LotTimeLimitTable_MultiTarget System.Array<snow.quest.RandomMysteryLotTimeLimitData.LotData>

---@class snow.quest.RandomMysteryLotTimeLimitData.LotData: via.clr.ManagedObject
---@field get_ApplyLevel fun(self: snow.quest.RandomMysteryLotTimeLimitData.LotData): System.UInt32
---@field get_LotTable fun(self: snow.quest.RandomMysteryLotTimeLimitData.LotData): System.Array<snow.quest.RandomMysteryLotTimeLimitData.TableData>

---@class snow.quest.RandomMysteryLotTimeLimitData.TableData : via.clr.ManagedObject
---@field get_LotProb fun(self: snow.quest.RandomMysteryLotTimeLimitData.TableData): System.Array<System.Int32>

---@class snow.QuestManager.QuestSaveData : snow.SaveDataBase
---@field _RandomMysteryQuestSeed System.Array<snow.quest.RandomMysteryQuestSeed>

---@class snow.progress.ProgressManager : snow.SnowSingletonBehaviorRoot
---@field getCapMysteryResearchLevel fun(self: snow.progress.ProgressManager): System.Int32

---@class snow.quest.randomMysteryExtraStageData : via.UserData
---@field _EnableLotExtraStageLevel System.Int32
---@field _LotHuntNumTable System.Array<snow.quest.randomMysteryExtraStageData.LotData>

---@class snow.quest.randomMysteryExtraStageData.LotData : via.clr.ManagedObject
---@field get_ApplyLevel fun(self: snow.quest.randomMysteryExtraStageData.LotData): System.UInt32
---@field get_LotTable fun(self: snow.quest.randomMysteryExtraStageData.LotData): System.Array<snow.quest.randomMysteryExtraStageData.TableData>

---@class snow.quest.randomMysteryExtraStageData.TableData : via.clr.ManagedObject
---@field get_LotProb fun(self: snow.quest.randomMysteryExtraStageData.TableData): System.Array<System.Int32>

---@class snow.quest.QuestData : via.clr.ManagedObject
---@field get_RawNormal fun(self: snow.quest.QuestData): snow.quest.NormalQuestData.Param

---@class snow.quest.NormalQuestData.Param : via.clr.ManagedObject
---@field _TgtEmType System.Array<snow.enemy.EnemyDef.EmTypes>
