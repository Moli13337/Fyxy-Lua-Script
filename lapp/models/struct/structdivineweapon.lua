
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructDivineWeapon
local StructDivineWeapon = LxClass("StructDivineWeapon", nil)


function StructDivineWeapon:StructDivineWeapon()
    -- 圣武refId
    self.refId = nil;
    --圣武星级refId
    self.starRefId = 0;
    --圣武等级refId
    self.levelRefId = 0;
    --附技圣武id
    self.linkRefId = 0;
    --是否上陣
    self.isDeploy = 0
    --当前星级
    self.star = 0
    ---等级
    self.level = 0
    --最大星级
    self.maxStar = nil
    -- 附技触发概率
    self.skillRate = nil
end

function StructDivineWeapon:CreateByPb(pb)
   -- 圣武refId
   self.refId = pb.refId;
   --圣武星级refId
   self.starRefId = pb.starRefId;
   --圣武等级refId
   self.levelRefId = pb.levelRefId;
   --附技圣武id
   self.linkRefId = pb.linkRefId; 
   self.isDeploy = pb.isDeploy
   --星级
   local starCfg = GameTable.DivineWeaponStarRef[self.starRefId]
   self.star = starCfg and starCfg.rankNow
   local levelCfg = GameTable.DivineWeaponLevelRef[self.levelRefId]
   self.level = levelCfg and levelCfg.level
   self.skillRate = starCfg and starCfg.linkRate
end
return StructDivineWeapon