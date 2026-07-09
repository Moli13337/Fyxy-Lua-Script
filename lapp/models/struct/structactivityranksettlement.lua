---
--- Created by BY.
--- DateTime: 2023/10/7 17:11:17
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructActivityRankSettlement
LXImport(".StructRankInfo")
LXImport(".StructActivityEntry")
local StructActivityRankSettlement = LxClass("StructActivityRankSettlement", nil)
function StructActivityRankSettlement:StructActivityRankSettlement()

end

function StructActivityRankSettlement:CreateByPb(pb)
    --token_variant_auto_export
	self.sid=pb.sid
	self.pageId=pb.pageId
	self.activityModel = pb.activityModel
	self.rankType=pb.rankType
	local infos = pb.infos
	local _infos = {}
	for i, v in ipairs(infos) do
		local rankInfo=StructRankInfo:New()
		rankInfo:CreateByPb(v)
		table.insert(_infos,rankInfo)
	end
	self.infos = _infos
--token_variant_auto_export
end


return StructActivityRankSettlement