---
--- Created by Administrator.
--- DateTime: 2023/10/9 11:27:12
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructFormationData
local StructFormationData = LxClass("StructFormationData", nil)
function StructFormationData:StructFormationData()

end

function StructFormationData:CreateByPb(pb)
    --token_variant_auto_export
	self.formationType=pb.formationType
	self.teamIndex=pb.teamIndex
	self.formationRefId=pb.formationRefId
	self.grids=pb.grids
	-- self.artifactId=pb.artifactId【G公共支持】删除神器功能相关数据
	self.power=pb.power
	
	self.tactics=pb.tactics or 0
	self.treasurePassiveSkill=pb.treasurePassiveSkill or {}

--token_variant_auto_export

	local grids = {}
	for k,v in ipairs(pb.grids or {}) do
		local data =
		{
			id = v.id,
			grid = v.grid
		}
		table.insert(grids,data)
	end
	self.grids = grids

	local list = {}
	for k,v in ipairs(pb.draconicStarRefIds or {}) do
		table.insert(list,v)
	end
	--龍紋 
	self.treasureSkilIds = list


	local list = {}
	for k,v in ipairs(pb.treasurePassiveSkill or {}) do
		table.insert(list,v)
	end
	self.treasurePassiveSkill = list
	
	local divineList = {}
	for k,v in ipairs(pb.divineWeaponStarRefIds or {}) do
		table.insert(divineList,v)
	end
	--聖武
	self.divineWeaponStarRefIds = divineList

	-- 【C宠物系统】删掉宠物系统相关
	-- self.petFights,self.petHelps = {},{}
	-- for i = 1, 2 do
	-- 	if(pb.petFights)then
	-- 		self.petFights[i] = pb.petFights[i]
	-- 	end
	-- 	if(pb.petHelps)then
	-- 		self.petHelps[i] = pb.petHelps[i]
	-- 	end
	-- end
end

function StructFormationData.Clone(src)
	local data = StructFormationData:New()
	data:CreateByPb(src)
	return data
end

return StructFormationData