---
--- Created by Administrator.
--- DateTime: 2023/10/20 11:06:10
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructReportRecord
local StructReportRecord = LxClass("StructReportRecord", nil)
function StructReportRecord:StructReportRecord()

end

function StructReportRecord:CreateByPb(pb)
    --token_variant_auto_export
	self.campRefId=pb.campRefId
	self.killScore=pb.killScore
	self.fightTime=pb.fightTime
	self.killReward=pb.killReward
	self.win=pb.win
	self.playerId=pb.playerId
	self.playerName=pb.playerName
	self.guildId=pb.guildId
	self.guildName=pb.guildName
--token_variant_auto_export

	local strs = string.split(self.killReward,'|')
	self.rewardList = LxDataHelper.ParseItem(strs[1]) or {}
	self.fightState =strs[2] and tonumber(strs[2]) or 1  --1 进攻,2 防守
end


return StructReportRecord