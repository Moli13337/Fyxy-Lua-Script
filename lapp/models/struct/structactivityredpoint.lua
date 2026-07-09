---
--- Created by BY.
--- DateTime: 2023/10/15 9:37:21
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructActivityRedPoint
local StructActivityRedPoint = LxClass("StructActivityRedPoint", nil)
function StructActivityRedPoint:StructActivityRedPoint()

end

function StructActivityRedPoint:CreateByPb(pb)
    --token_variant_auto_export
	self.sid=pb.sid
	self.pageList=pb.pageList
	self.otherInfo = pb.otherInfo
--token_variant_auto_export

	local pageIdMap = {}
	for k,v in ipairs(pb.pageList) do
		pageIdMap[v] = true
	end

	self.pageIdMap = pageIdMap

	local otherMap = {}

	local strs = string.split(pb.otherInfo,'|')
	for k,v in ipairs(strs) do
		otherMap[v] = true
	end

	self.otherMap = otherMap
	local entryList = pb.entryList or {}
	local _entryList = {}
	for i, v in ipairs(entryList) do
		local pageId = v.pageId
		local entrys = v.entryList
		local list = _entryList[pageId] or {}
		for j, k in ipairs(entrys) do
			list[k] = true
		end
		_entryList[pageId] = list
	end
	self.entryList = _entryList
end

function StructActivityRedPoint:IsPageRed(pageId)
	return self.pageIdMap and self.pageIdMap[pageId]
end

function StructActivityRedPoint:IsOtherRed(key)
	return self.otherMap and self.otherMap[key]
end

function StructActivityRedPoint:IsEntryListRed(pageId,entryId)
	local entryList = self.entryList
	if not entryList then
		return false
	end
	local list = entryList[pageId]
	return list and list[entryId]
end
return StructActivityRedPoint