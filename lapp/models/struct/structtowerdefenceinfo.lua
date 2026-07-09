---
--- Created by By.
--- DateTime: 2023/10/6 11:57:34
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructTowerDefenceInfo
local StructTowerDefenceInfo = LxClass("StructTowerDefenceInfo", nil)
function StructTowerDefenceInfo:StructTowerDefenceInfo()

end

function StructTowerDefenceInfo:CreateByPb(pb)

	self.chapterId=pb.chapterId
	--当前已经通关关卡
	self.battleNode=pb.battleNode
	self.callLevel=pb.callLevel
	self.placeTime=pb.placeTime
	self.quickFreeCount=pb.quickFreeCount
	self.quickCount=pb.quickCount
	self.privilegeTime=pb.privilegeTime

	self:InitHeroIds(pb.heroIds)
	self:InitHeroInfos(pb.infos)
	self:InitTalentInfos(pb.talentInfos)

	self.useQuickFreeCount = pb.useQuickFreeCount
	self.useQuickCount = pb.useQuickCount

	self.maxPower = tonumber(pb.maxPower)
	self.maxBattleNode = pb.maxBattleNode

	self:InitFaultNode(pb.faultNode)

	self.privilegeBuyCount = pb.privilegeBuyCount
	self.talentReset = pb.talentReset
	self.openTime = pb.openTime
end

function StructTowerDefenceInfo:InitFaultNode(pbFaultNode)
	pbFaultNode = pbFaultNode or {}
	local faultNode = {}
	self.faultNode = faultNode
	for k,v in ipairs(pbFaultNode) do
		faultNode[v] = true
	end
end

function StructTowerDefenceInfo:InitHeroIds(pbHeroIds)
	local heroIds = {}
	self.heroIds = heroIds
	for k,v in ipairs(pbHeroIds) do
		table.insert(heroIds, v)
	end
end

function StructTowerDefenceInfo:InitHeroInfos(pbHeroInfos)
	local infos = {}
	self.infos = infos

	for k,v in ipairs(pbHeroInfos) do
		local info = StructTowerDefenceHeroInfo:New()
		info:CreateByPb(v)
		infos[info.heroId] = info
	end



end

function StructTowerDefenceInfo:GetIndexToHero()
	if not self.infos then
		return
	end

	local indexToHero = {}
	for k,v in pairs(self.infos) do
		indexToHero[v.index] = v
	end

	return indexToHero
end

function StructTowerDefenceInfo:InitTalentInfos(pbTalentInfos)
	local infos  = {}
	self.talentInfos = infos
	for k ,v in ipairs(pbTalentInfos) do
		table.insert(infos, v)
	end
end

function StructTowerDefenceInfo:UpdateSingleHero(pb)
	local info = StructTowerDefenceHeroInfo:New()
	info:CreateByPb(pb)
	if not self.infos then
		self.infos = {}
	end

	self.infos[info.heroId] = info
end


function StructTowerDefenceInfo:InitTestData()
	self.chapterId=1
	self.battleNode=10001
	self.callLevel=1
	self.placeTime=0
	self.quickFreeCount=5
	self.quickCount=5
	self.privilegeTime=0

	self:InitHeroIds({})
	self:InitHeroInfos({})
	self:InitTalentInfos({})

	self.useQuickFreeCount = 0
	self.useQuickCount = 0
end

return StructTowerDefenceInfo