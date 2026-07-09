---
--- Created by BY.
--- DateTime: 2023/10/11 16:09:33
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructGuildNewBraveLog
local StructGuildNewBraveLog = LxClass("StructGuildNewBraveLog", nil)
function StructGuildNewBraveLog:StructGuildNewBraveLog()

end

function StructGuildNewBraveLog:CreateByPb(pb)
    --token_variant_auto_export
	self.info=pb.info
	self.hurt=pb.hurt
	self.time=pb.time
--token_variant_auto_export
end


return StructGuildNewBraveLog