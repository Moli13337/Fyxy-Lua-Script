---
--- Created by BY.
--- DateTime: 2023/10/19 16:12:27
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructSweetsCountryLogInfo
local StructSweetsCountryLogInfo = LxClass("StructSweetsCountryLogInfo", nil)
function StructSweetsCountryLogInfo:StructSweetsCountryLogInfo()

end

function StructSweetsCountryLogInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.playerId=pb.playerId
	self.head=pb.head
	self.headFrame=pb.headFrame
	self.playerName=pb.playerName
	self.consume=pb.consume
	self.time=pb.time
--token_variant_auto_export
end


return StructSweetsCountryLogInfo