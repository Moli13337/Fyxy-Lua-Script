---
--- Created by BY.
--- DateTime: 2023/10/28 18:26:12
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructAnswerRoomMember
local StructAnswerRoomMember = LxClass("StructAnswerRoomMember", nil)
function StructAnswerRoomMember:StructAnswerRoomMember()
	--[[
		required int64 playerId = 1;
		/**形象*/
		optional int32 figure = 2;
		/**成员状态（0=正常，1=淘汰）*/
		optional int32 disuse = 3;
		/**当前题目给出的答案（1-N）*/
		optional int32 answerIndex = 4;
		/**玩家名称*/
		optional string name = 5;
	--]]
end

function StructAnswerRoomMember:CreateByPb(pb)
    --token_variant_auto_export
	self.playerId=pb.playerId
	self.figure=pb.figure
	self.disuse=pb.disuse
	self.answerIndex=pb.answerIndex
	self.name=pb.name
--token_variant_auto_export
end


return StructAnswerRoomMember