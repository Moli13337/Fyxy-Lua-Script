---
--- Created by BY.
--- DateTime: 2023/10/16 17:33:21
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructCrusadeAgainstInfo
local StructCrusadeAgainstInfo = LxClass("StructCrusadeAgainstInfo", nil)
function StructCrusadeAgainstInfo:StructCrusadeAgainstInfo()

end

function StructCrusadeAgainstInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.refId=pb.refId
	self.nodeId=pb.nodeId
	self.passCount=pb.passCount
--token_variant_auto_export
end


return StructCrusadeAgainstInfo