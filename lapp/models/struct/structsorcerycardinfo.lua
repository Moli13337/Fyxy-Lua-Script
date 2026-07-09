---
--- Created by BY.
--- DateTime: 2022/8/30 10:00:12
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructSorceryCardInfo
local StructSorceryCardInfo = LxClass("StructSorceryCardInfo", nil)
function StructSorceryCardInfo:StructSorceryCardInfo()

end

function StructSorceryCardInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.scRefId=pb.scRefId
	self.level=pb.level
--token_variant_auto_export
end


return StructSorceryCardInfo