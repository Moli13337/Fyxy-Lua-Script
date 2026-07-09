---
--- Created by Administrator.
--- DateTime: 2023/10/23 9:42:05
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructOccupiedCampReward
local StructOccupiedCampReward = LxClass("StructOccupiedCampReward", nil)
function StructOccupiedCampReward:StructOccupiedCampReward()

end

function StructOccupiedCampReward:CreateByPb(pb)
    --token_variant_auto_export
	self.occupiedTime=pb.occupiedTime
	self.lastReceiveTime=pb.lastReceiveTime
	self.campRefId=pb.campRefId
	self.receiveState=pb.receiveState
--token_variant_auto_export

	self.lastReceiveTime = self.lastReceiveTime/1000

	-- 【G公共支持】删除暗黑战争相关数据
	-- self._timeMax = gModelDarkWar:GetPara("roleRewardNum") *3600
end

function StructOccupiedCampReward:GetTimeCount()
	--local fightEndTime = gModelDarkWar:GetFightEndTime()
	--local maxEndTime = math.min(GetTimestamp(),fightEndTime)
	local timepast = GetTimestamp() - self.lastReceiveTime
	timepast = Mathf.Clamp(timepast,0,self._timeMax)
	return timepast
end

return StructOccupiedCampReward