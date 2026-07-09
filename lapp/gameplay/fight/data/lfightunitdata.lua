---@class LFightUnitData
local LFightUnitData = LxClass("LFightUnitData",nil)

function LFightUnitData:LFightUnitData()

end

function LFightUnitData:CreateByPb(pb)
    self.id = pb.id
    self.type = pb.type
    self.refId = pb.refId
    self.campSkillIdList = pb.campSkillIdList
    self.data = JSON.decode(pb.data)
end

return LFightUnitData