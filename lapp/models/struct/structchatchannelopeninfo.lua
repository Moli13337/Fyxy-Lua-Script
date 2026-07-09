---
--- Created by BY.
--- DateTime: 2023/10/10 10:32:33
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructChatChannelOpenInfo
local StructChatChannelOpenInfo = LxClass("StructChatChannelOpenInfo", nil)
function StructChatChannelOpenInfo:StructChatChannelOpenInfo()

end

function StructChatChannelOpenInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.channel=pb.channel
	self.openTIme=pb.openTIme
	self.endTIme=pb.endTIme
--token_variant_auto_export
end


return StructChatChannelOpenInfo