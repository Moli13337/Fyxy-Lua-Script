---
--- Created by BY.
--- DateTime: 2023/10/30 16:09:23
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructHeroCoreActivityInfo
local StructHeroCoreActivityInfo = LxClass("StructHeroCoreActivityInfo", nil)
function StructHeroCoreActivityInfo:StructHeroCoreActivityInfo()
	--[[
	 	//开始时间
 		optional int64 startTime = 1;
 		//结束时间
 		optional int64 endTime = 2;
 		//领取记录
 		repeated int32 receiveIds = 3;
 		//开服天数
 		optional int32 openDay = 4;
	]]
end

function StructHeroCoreActivityInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.startTime=pb.startTime
	self.endTime=pb.endTime
	self.receiveIds=pb.receiveIds
	self.openDay=pb.openDay
--token_variant_auto_export
end


return StructHeroCoreActivityInfo