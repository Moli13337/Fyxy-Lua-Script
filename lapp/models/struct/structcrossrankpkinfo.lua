---
--- Created by Administrator.
--- DateTime: 2023/10/10 16:51:05
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructCrossRankPkInfo
local StructCrossRankPkInfo = LxClass("StructCrossRankPkInfo", nil)
function StructCrossRankPkInfo:StructCrossRankPkInfo()

end

function StructCrossRankPkInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.playerId=pb.playerId
	self.power=pb.power
	self.rank=pb.rank
	self.score=pb.score
	self.serverId=pb.serverId
	self.head=pb.head
	self.headFrame=pb.headFrame
	self.level=pb.level
	self.playerName=pb.playerName
--token_variant_auto_export
end


return StructCrossRankPkInfo