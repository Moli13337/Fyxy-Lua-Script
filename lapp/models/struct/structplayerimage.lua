---
--- Created by BY.
--- DateTime: 2023/10/1 14:23:34
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructPlayerImage
local StructPlayerImage = LxClass("StructPlayerImage", nil)
function StructPlayerImage:StructPlayerImage()
	self.playerId = ""
	self.playerName = ""
	self.image = 0
end

function StructPlayerImage:CreateByPb(pb)
    --token_variant_auto_export
	self.playerId=pb.playerId
	self.playerName=pb.playerName
	self.image=pb.image
--token_variant_auto_export
end


return StructPlayerImage