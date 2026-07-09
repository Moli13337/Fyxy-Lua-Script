
local LFightExpreBase = LXImport("..Base.LFightExpreBase")

local LFightExpreRoleAct = LxClass("LFightExpreRoleAct",LFightExpreBase)

function LFightExpreRoleAct:LFightExpreRoleAct()
    self._type = LSkillEffConst.PLAY_EFF_ANI
end

function LFightExpreRoleAct:Preload()

end

function LFightExpreRoleAct:OnStart()
    local runningData = self._runningData

    ---@type LFightObject
    local obj = runningData.targetObj

    obj:SetSkillPlaying(true)

    local effData = self._effData
    --动作名字
    local ani = effData.effRes
    --动作时间
    local time = effData.playTime
    time = effData.actionReset == 0 and time or 0
    --printInfoN(string.format("play ani %s,time %s",ani,time))

    local showLoop = effData.showLoop or 0
    local isLoopAni = showLoop == 1

    obj:PlayAni(ani, isLoopAni, time)

    if isLoopAni then
        obj:SetReplaceIdle(ani)
    end

    local soundName = effData.soundBattle
    if not string.isempty(soundName) then
        gLGameAudio:PlaySound(soundName)
    end


end



return LFightExpreRoleAct