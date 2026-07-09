---@class LFightHurtCounter
local LFightHurtCounter = LxClass("LFightHurtCounter",nil)

function LFightHurtCounter:LFightHurtCounter()

end

function LFightHurtCounter:StartCounter(side)
    self._side = side
end

function LFightHurtCounter:AddHurtCount(side,isHurt,hurt)
    if side ~= self._side then
        return
    end

    if self._isHurt== nil then
        self._isHurt = isHurt
    else
        if self._isHurt~= isHurt then
            self._isHurt = isHurt
            FireEvent(EventNames.BATTLE_HURT_COUNT_UPDATE,1,0)
        end
    end
    --print(string.format("siHurt %s ,hurt %s",isHurt,hurt))
    FireEvent(EventNames.BATTLE_HURT_COUNT_UPDATE,isHurt,hurt)
end

function LFightHurtCounter:EndCounter()
    FireEvent(EventNames.BATTLE_HURT_COUNT_UPDATE,1,0)
end

return LFightHurtCounter