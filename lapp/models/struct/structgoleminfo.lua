---
--- Created by LCM.
--- DateTime: 2024/3/20 20:36:04
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructGolemInfo
local StructGolemInfo = LxClass("StructGolemInfo", nil)
function StructGolemInfo:StructGolemInfo()
	self.itype = 6
	self.state = 0
end

function StructGolemInfo:CreateByPb(pb)
    --token_variant_auto_export
	self.id = pb.id
	self.refId = pb.refId
	self.lvlRefId = pb.lvlRefId
	self.exp = pb.exp

	self.mainAttrGroup = {}
	for i,v in ipairs(pb.mainAttrGroup) do
		table.insert(self.mainAttrGroup,v)
	end

	self.viceAttrGroup = {}
	for i,v in ipairs(pb.viceAttrGroup) do
		table.insert(self.viceAttrGroup,v)
	end

	local heroId = pb.heroId
	if heroId and tonumber(heroId) == 0 then
		heroId = ""
	end
	self.heroId = heroId
	self.lockState = pb.lockState or 0
--token_variant_auto_export

	--- 1=锁定中
	local isLock = self.lockState == 1
	self.isLock = isLock

	local state = pb.state or 0
	self.state = state



	self.recastMainAttr = {}
	for i,v in ipairs(pb.recastMainAttr) do
		table.insert(self.recastMainAttr,v)
	end

	self.recastViceAttrGroup = {}
	for i,v in ipairs(pb.recastViceAttrGroup) do
		table.insert(self.recastViceAttrGroup,v)
	end

	self.lockInfo = {}
	for i,v in ipairs(pb.lockInfo) do
		local golemLockInfo = StructGolemLockInfo:New()
		golemLockInfo:CreateByPb(v)
		table.insert(self.lockInfo,golemLockInfo)
	end

	self._lv = gModelGolem:GetGolemLvByLevelRefId(self.lvlRefId)
	self._star = gModelGolem:GetGolemElementStarByRefId(self.refId)
end

function StructGolemInfo:GetLv()
	return self._lv
end

function StructGolemInfo:GetStar()
	return self._star
end

function StructGolemInfo:IsEquip()
	return not string.isempty(self.heroId)
end

function StructGolemInfo:IsLock()
	return self.isLock
end

function StructGolemInfo:IsRecasting()
	return #self.recastMainAttr > 0 or #self.recastViceAttrGroup> 0
end

function StructGolemInfo:GetDefaultData()
	local info = StructGolemInfo:New()
	info.refId = self.refId
	local lvRef = gModelGolem:GetDefaultLvRef(self.refId)
	info.lvlRefId= lvRef.refId
	info._lv = 0
	info.exp = 0
	self._star = self._star

	info.mainAttrGroup = {}
	for i,v in ipairs(self.mainAttrGroup) do
		local ref = gModelGolem:GetDefaultAttrRef(v,0)
		if ref then
			table.insert(info.mainAttrGroup,ref.refId)
		end
	end

	info.viceAttrGroup = {}
	for i,v in ipairs(self.viceAttrGroup) do
		local ref = gModelGolem:GetDefaultAttrRef(v,1)
		if ref then
			table.insert(info.viceAttrGroup,ref.refId)
		end
	end

	return info

end

return StructGolemInfo