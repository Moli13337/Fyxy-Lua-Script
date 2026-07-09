---
--- Created by LCM.
--- DateTime: 2024/3/26 10:06:39
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructGolemAttr
local StructGolemAttr = LxClass("StructGolemAttr", nil)
function StructGolemAttr:StructGolemAttr()

end

function StructGolemAttr:CreateByPb(pb)
    --token_variant_auto_export
	self.golemId = pb.golemId
	self.attr = pb.attr
--token_variant_auto_export
end


return StructGolemAttr