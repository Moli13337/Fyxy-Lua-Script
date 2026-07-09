---
--- Created by BY.
--- DateTime: 2022/7/12 10:05:18
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructSorceryCard
local StructSorceryCard = LxClass("StructSorceryCard", nil)
function StructSorceryCard:StructSorceryCard()

end

function StructSorceryCard:CreateByPb(pb)
    --token_variant_auto_export
	self.scRefId=pb.scRefId
	self.heroId=pb.heroId
	self.level=pb.level
--token_variant_auto_export
end


return StructSorceryCard