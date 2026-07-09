---
--- Created by By.
--- DateTime: 2023/10/6 11:57:25
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructTowerDefenceHeroInfo
local StructTowerDefenceHeroInfo = LxClass("StructTowerDefenceHeroInfo", nil)
function StructTowerDefenceHeroInfo:StructTowerDefenceHeroInfo()

end

function StructTowerDefenceHeroInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.heroId=pb.heroId
	self.refId=pb.refId
	self.level=pb.level
	self.index=pb.index
--token_variant_auto_export
end


return StructTowerDefenceHeroInfo