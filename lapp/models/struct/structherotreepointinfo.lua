---
--- Created by Administrator.
--- DateTime: 2023/10/19 18:10:04
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructHeroTreePointInfo
local StructHeroTreePointInfo = LxClass("StructHeroTreePointInfo", nil)
function StructHeroTreePointInfo:StructHeroTreePointInfo()
	self.pointRefId = 0		--技能节点refId
	self.lvRefId	= 0		--技能节点等级refId
	self.skillId	= 0		--选择的技能id 0表示无技能或者未选择
end

function StructHeroTreePointInfo:CreateByPb(pb)
	self.pointRefId=pb.pointRefId
	self.lvRefId=pb.lvRefId
	self.skillId=pb.skillId
end

function StructHeroTreePointInfo:IsHaveSkill()
	return self.skillId and self.skillId > 0
end

return StructHeroTreePointInfo