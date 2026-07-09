---
--- Created by Administrator.
--- DateTime: 2023/10/5 11:00:24
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructSimulateFlowerInfo
local StructSimulateFlowerInfo = LxClass("StructSimulateFlowerInfo", nil)
function StructSimulateFlowerInfo:StructSimulateFlowerInfo()

end

function StructSimulateFlowerInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.playerId=pb.playerId
	self.type=pb.type
	self.round=pb.round
	self.targetId=pb.targetId
	self.result=pb.result
	self.reward=pb.reward
	self.attackInfo=pb.attackInfo
	self.defenceInfo=pb.defenceInfo
	self.reportId=pb.reportId
	self.groupId=pb.groupId
	self.id=pb.id
	self.attackFlower=pb.attackFlower
	self.defenceFlower=pb.defenceFlower
	self.emoImg=pb.emoImg
	self.groupIndex = pb.groupIndex
--token_variant_auto_export

	self.attackInfo = StructPlayerData:New()
	self.attackInfo:CreateByPb(pb.attackInfo)
	self.defenceInfo = StructPlayerData:New()
	self.defenceInfo:CreateByPb(pb.defenceInfo)
end


return StructSimulateFlowerInfo