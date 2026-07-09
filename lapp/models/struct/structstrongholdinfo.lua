---@class StructStrongholdInfo
local StructStrongholdInfo = LxClass("StructStrongholdInfo", nil)

function StructStrongholdInfo:StructStrongholdInfo()
    self.playerId = 0
    self.image = 0
    self.name = 0
    self.power = 0
    self.star = 0
    self.robot = 0
    self.refId = 0
    self.sweep = 0
end

function StructStrongholdInfo:CreateByPb(pb)
    self.playerId = pb.playerId
    self.image = pb.image
    self.name = pb.name
    self.power = pb.power
    self.star = pb.star
    self.robot = pb.robot
    self.refId = pb.refId
    self.sweep = pb.sweep

    if pb.robot == 1 then
        local headIcon, lv, name, image = gModelGuildHolyBattle:GetRobotData()
        self.name = name
        self.image = image
    end
end



return StructStrongholdInfo