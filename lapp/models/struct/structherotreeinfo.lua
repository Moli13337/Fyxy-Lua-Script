---
--- Created by Administrator.
--- DateTime: 2023/10/19 18:08:43
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructHeroTreeInfo
local StructHeroTreeInfo = LxClass("StructHeroTreeInfo", nil)
LXImport(".StructHeroTreePointInfo")

function StructHeroTreeInfo:StructHeroTreeInfo()
	self.treeRefId = 0		--技能树refId
	---@type StructHeroTreePointInfo[]
	self.points = {}		--技能节点refId--玩家已经激活的节点数据
	---@type table<number,StructHeroTreePointInfo>
	self.pointMap = {}

	self.extraSkillCostRefId = {}
	self.extraSkillCostRefIdMap = {}
end

function StructHeroTreeInfo:CreateByPb(pb)
	if not pb then return end
	self.treeRefId  = pb.treeRefId

	self.points = {}
	self.pointMap = {}
	if pb.points then
		for k,v in ipairs(pb.points) do
			---@type StructHeroTreePointInfo
			local pointInfo = StructHeroTreePointInfo:New()
			pointInfo:CreateByPb(v)
			table.insert(self.points, pointInfo)
			self.pointMap[pointInfo.pointRefId] = pointInfo
		end
	end

	self.extraSkillCostRefId = {}
	self.extraSkillCostRefIdMap = {}
	local extraSkillCostRefId = pb.extraSkillCostRefId or {}
	for i,v in ipairs(extraSkillCostRefId) do
		table.insert(self.extraSkillCostRefId,v)
		self.extraSkillCostRefIdMap[v] = v
	end
end

function StructHeroTreeInfo:IsAwakenActivate()
	if not self.treeRefId or self.treeRefId == 0 then
		return false
	end

	return #self.points > 0
end

function StructHeroTreeInfo:GetAwakenSkillNum()
	local num = 0
	for k,v in pairs(self.points) do
		if v:IsHaveSkill() then
			num = num + 1
		end
	end

	return num
end

function StructHeroTreeInfo:GetAwakenAllLv()
	local allLvl = 0
	for k,v in ipairs(self.points) do
		local lvRefId = v.lvRefId
		local ref 	  = gModelHero:GetHeroTreePointLvRef(lvRefId)
		allLvl 		  = allLvl + ref.lv
	end

	return allLvl
end

function StructHeroTreeInfo:IsExtraSkillActive(refId)
	return self.extraSkillCostRefIdMap[refId] ~= nil
end

function StructHeroTreeInfo:GetTreeRefId()
	return self.treeRefId
end

return StructHeroTreeInfo