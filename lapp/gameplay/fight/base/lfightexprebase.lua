

---@class LFightExpreBase
local LFightExpreBase = LxClass("LFightExpreBase",nil)

LFightExpreBase.NONE = -1
LFightExpreBase.WAIT = 0
LFightExpreBase.START = 1
LFightExpreBase.END = 2
LFightExpreBase.DESTROY = 3
LFightExpreBase.PERSISTENCEWAIT = 4

function LFightExpreBase:LFightExpreBase(manager)
    self._manager = manager

    self._state = LFightExpreBase.NONE

    ---@type boolean 是否持久
    self._isPersistence = false
end

function LFightExpreBase:Create(expre)
    self._effData = expre
end

function LFightExpreBase:Preload()
    local effData = self._effData

    local effRes = effData.effRes --光效名字
    --local playTime = effData.playTime --光效持续时间
    --local dissipateTime = effData.dissipateTime --光效消散时间
    --local offset = effData.effOffsetStart --偏移
    local resType = 1
    if effData.effType == LSkillEffConst.PLAY_EFF_DRAWING then
        resType = 2
    end

    local effectCtrl = self._manager:GetEffectCtrl()
    local effTrans = self._manager:GetEffectRootTrans()
    effectCtrl:PreloadEffectObject(effTrans,effRes,resType)

end

function LFightExpreBase:BeginRunning(data)
    self._runningData = data

    local effData = self._effData
    local showLoop = effData.showLoop or 0
    self._isPersistence = showLoop == 1

    self._startTime = data.curTime + effData.delayTime
    self._endTime = self._startTime + effData.playTime

    self._state = LFightExpreBase.WAIT
end

function LFightExpreBase:Run(time)
    if self._state >= LFightExpreBase.END or self._state< LFightExpreBase.WAIT  then
        return
    end

    if self._state == LFightExpreBase.WAIT and time > self._startTime then
        self:Start()
    end

    if self._state == LFightExpreBase.START and time > self._endTime then
        if not self._isPersistence then
            self:End()
        else
            self._state = LFightExpreBase.PERSISTENCEWAIT
        end
    end
end

function LFightExpreBase:Start()
    self._state = LFightExpreBase.START

    self:OnStart()
end

function LFightExpreBase:End()
    self:OnEnd()

    self._state = LFightExpreBase.END
end

function LFightExpreBase:IsEnd()
    return self._state == LFightExpreBase.END
end

function LFightExpreBase:IsPersistenceWait()
    return self._state == LFightExpreBase.PERSISTENCEWAIT
end

function LFightExpreBase:Destroy()
    self:OnDestroy()
    table.removeall(self)
    self._state = LFightExpreBase.DESTROY
end

function LFightExpreBase:OnDestroy()

end

function LFightExpreBase:OnStart()

end

function LFightExpreBase:OnEnd()

end

function LFightExpreBase:OnRecycle()
    self._state = LFightExpreBase.NONE
end

function LFightExpreBase:GetType()
    return self._type
end

function LFightExpreBase:GetEffectData()
    return self._effData
end

function LFightExpreBase:GetEffTarget()
    local effData = self._effData
    return effData and effData.effTarget
end

function LFightExpreBase:RecycleEnd()
    self._isPersistence = false
    self:End()
end

function LFightExpreBase:SetVisible()

end

return LFightExpreBase