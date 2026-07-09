---
--- Created by BY.
--- DateTime: 2023/10/4 11:38:42
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructActivityVillainPositionInfo
local StructActivityVillainPositionInfo = LxClass("StructActivityVillainPositionInfo", nil)
function StructActivityVillainPositionInfo:StructActivityVillainPositionInfo()

end

function StructActivityVillainPositionInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.name=pb.name
	self.image=pb.image
	self.imageType=pb.imageType
	self.position=pb.position
	self.pid=pb.pid
	self.gender=pb.gender
	self.refreshTime=pb.refreshTime
	self.head=pb.head
	self.headFrame=pb.headFrame
	self.level=pb.level
--token_variant_auto_export
end

function StructActivityVillainPositionInfo:GetPrefab()
	if not self.prefab then
		if self.imageType == 1 then
			self.prefab = gModelHero:GetHeroEffectPrefab(self.image)
		elseif self.imageType == 2 then
			self.prefab = gModelPlayer:GetRoleAdventurePrefab(self.image)
		end
	end

	return self.prefab
end
return StructActivityVillainPositionInfo