---
--- Created by Administrator.
--- DateTime: 2023/10/26 17:37:14
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructCombatOperateReport
local StructCombatOperateReport = LxClass("StructCombatOperateReport", nil)
-- LXImport("LApp.gameplay.PetBattle.Data.LPetBattleInit")
-- LXImport("LApp.gameplay.PetBattle.Data.LPetBouts")

StructCombatOperateReport.INIT = 0
StructCombatOperateReport.ROUND = 1
StructCombatOperateReport.BOUT = 2
StructCombatOperateReport.END = 3

function StructCombatOperateReport:StructCombatOperateReport()

end

function StructCombatOperateReport:CreateByPb(pb)
	--token_variant_auto_export
	self.types=pb.types
	self.reportInit=pb.reportInit
	self.round=pb.round
	self.bout=pb.bout
	self.reportEnd=pb.reportEnd
	--token_variant_auto_export

	local record = {}
	for k,v in ipairs(self.types) do
		record[v] = true
	end

	-- 【C宠物系统】删掉宠物系统相关
	-- local data = LPetBattleInit:New()
	-- data:CreateByPb(self.reportInit)
	-- self.reportInit = data

	-- local data = LPetBouts:New()
	-- data:CreateByPb(pb.bout)

	-- self.bout = data

	self._dataTag = record
end

-- 【C宠物系统】删掉宠物系统相关
-- ---@return LPetBattleInit
-- function StructCombatOperateReport:GetInitData()
-- 	if self._dataTag[StructCombatOperateReport.INIT] then
-- 		return self.reportInit
-- 	end
-- end

function StructCombatOperateReport:GetRoundData()
	if self._dataTag[StructCombatOperateReport.ROUND] then
		return self.round
	end
end

-- 【C宠物系统】删掉宠物系统相关
-- ---@return LPetBouts
-- function StructCombatOperateReport:GetBoutData()
-- 	if self._dataTag[StructCombatOperateReport.BOUT] then
-- 		return self.bout
-- 	end
-- end

function StructCombatOperateReport:GetEndData()
	if self._dataTag[StructCombatOperateReport.END] then
		return self.reportEnd
	end
end


return StructCombatOperateReport