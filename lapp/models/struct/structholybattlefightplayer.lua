---@class StructHolyBattleFightPlayer
local StructHolyBattleFightPlayer = LxClass("StructHolyBattleFightPlayer", nil)

function StructHolyBattleFightPlayer:StructStrongholdInfo()
    self.guildName = 0
    self.guildBanner = 0
    self.playerId = 0
    self.playerName = 0
    self.playerPower = 0
    self.avatar = 0
    self.avatarFrame = 0
    self.lvl = 0
    self.robot = 0
    self.flagBgId = 0
end

function StructHolyBattleFightPlayer:CreateByPb(pb)
    self.guildName = pb.guildName
    self.guildBanner = pb.guildBanner
    self.playerId = pb.playerId
    self.playerName =  pb.playerName
    self.playerPower = pb.playerPower
    self.avatar =  pb.avatar
    self.avatarFrame =  pb.avatarFrame
    self.lvl =  pb.lvl
    self.robot =  pb.robot
    self.flagBgId = pb.flagBgId
    --if pb.robot == 1 then
    --    local headIcon, lv, name, image = gModelGuildHolyBattle:GetRobotData()
    --    self.name = name
    --    self.image = image
    --end
end



return StructHolyBattleFightPlayer