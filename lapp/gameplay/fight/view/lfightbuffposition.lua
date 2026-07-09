---换位buff
---@class LFightBuffPosition
local LFightBuffPosition = LxClass("LFightBuffPosition",nil)
LFightBuffPosition.NONE = 0
LFightBuffPosition.RUNNING = 1
LFightBuffPosition.END = 2

function LFightBuffPosition:LFightBuffPosition()
    self._state = LFightBuffPosition.NONE
end


function LFightBuffPosition:Start(para)
    self._para = para
    self._endTime = para.endTime
    self:OnStart()
end

function LFightBuffPosition:OnRun(time)

    if self._state ~=  LFightBuffPosition.RUNNING then
        return
    end
    if time > self._endTime then
        self:OnEnd()
    end

end

function LFightBuffPosition:OnStart()
    self._state = LFightBuffPosition.RUNNING

    local side = self._para.side
    local effect = self._para.effect
    local duration = self._para.duration

    self._para.objCtrl:SwapHero(side,effect,duration)
end

function LFightBuffPosition:OnEnd()
    self._state = LFightBuffPosition.END
end

function LFightBuffPosition:IsEnd()
    return self._state == LFightBuffPosition.END
end


return LFightBuffPosition