--- 道具额外数据
--- Created by Ease.
--- DateTime: 2023/10/18 15:58
---@class StructItemExtraInfo
local StructItemExtraInfo = LxClass("StructItemExtraInfo", nil)

function StructItemExtraInfo:StructItemExtraInfo()
	self.id = 0
	self.refId = 0
	self.type = 0
	self.createTime = 0
	self.rewardDays = 0
	self.extra = 0
end

function StructItemExtraInfo:CreateByPb(pb)
	self.id = pb.id
	self.refId = pb.refId
	self.type = pb.type
	self.createTime = pb.createTime
	self.rewardDays = {}
	for i, v in ipairs(pb.rewardDays) do
		table.insert(self.rewardDays,v)
	end
	self.extra = JSON.decode(pb.extra)
end

return StructItemExtraInfo