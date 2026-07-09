---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:34:55
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructTowerDefencePassInfo
local StructTowerDefencePassInfo = LxClass("StructTowerDefencePassInfo", nil)

LXImport(".StructTowerDefenceHeroInfo")

function StructTowerDefencePassInfo:StructTowerDefencePassInfo()

end

function StructTowerDefencePassInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.nodeId=pb.nodeId
	self.passTime=pb.passTime
	self.time=pb.time
	self.heroId=pb.heroId
	self.heroInfo=pb.heroInfo
	self.talentId=pb.talentId
--token_variant_auto_export

	local heroId = {}
	for k,v in ipairs(pb.heroId) do
		table.insert(heroId, v)
	end

	local heroInfo = {}
	for k,v in ipairs(pb.heroInfo) do
		local struct = StructTowerDefenceHeroInfo:New()
		struct:CreateByPb(v)
		table.insert(heroInfo, struct)
	end

	local talentId = {}
	for k,v in ipairs(pb.talentId) do
		table.insert(talentId, v)
	end

	self.heroId = heroId
	self.heroInfo = heroInfo
	self.talentId = talentId
end


return StructTowerDefencePassInfo