---
--- Created by BY.
--- DateTime: 2023/10/19 16:12:27
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructHelpPictureInfo
local StructHelpPictureInfo = LxClass("StructHelpPictureInfo", nil)
function StructHelpPictureInfo:StructHelpPictureInfo()

end

function StructHelpPictureInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.refId = pb.refId  --refId是 数组
--token_variant_auto_export
end


return StructHelpPictureInfo