---@class LStoryBuffEvent:LStoryEventBase
local LStoryBuffEvent = LxClass("LStoryBuffEvent",LStoryEventBase)



function LStoryBuffEvent:LStoryBuffEvent()
    --self._type = LStoryEventType.EFFECT
end



function LStoryBuffEvent:OnStart()
    local cfg = self._eventCfg

    local buffId = tonumber(cfg.effectName)

    local buffRef = gModelSkill:GetBuffRef(buffId)
    local buffEff = buffRef.buffEffShow
    local buffMat = buffRef.buffMaterial
    local isFreeze = gModelBattle:IsFreezeBuff(buffId)

    self._heroId = tonumber(cfg.heroId)
    self._scaleSize = cfg.multiple

    self._scaleSize = self._scaleSize == 0 and 1 or self._scaleSize
    self._buffEff = buffEff
    self._buffMat = buffMat
    self._isFreeze = isFreeze

    self._timeSpan = self._endTime - self._startTime

    local para = self._eventCfg.act
    local strs = string.split(para,'|')
    self._timeBefore = strs[1] and tonumber(strs[1]) or 0
    self._timeAfter = strs[2] and tonumber(strs[2]) or 0

    self:ApplyBuff()
end

function LStoryBuffEvent:OnEnd()
    if self._effRecord then
        for k,v in pairs(self._effRecord) do
            v:Destroy()
        end

        self._effRecord = nil
    end

    local obj = self:GetObj()
    if obj then
        obj:SetDefaultMat(self._timeAfter)
        if self._isFreeze then
            obj:TimeResume()
        end
    end


end

function LStoryBuffEvent:OnHeroLoaded(heroId)
    if self._heroId ~= heroId then
        return
    end

    self:ApplyBuff()
end

function LStoryBuffEvent:ApplyBuff()
    local effectCtrl = self:GetManager():GetEffCtrl()
    local rootTrans = nil
    local pos = nil
    if not self._heroId  then
        return
    end
    local obj = self:GetObj()
    if not obj or not obj:IsReady() then
        return
    end
    rootTrans = obj:GetDisplayTrans()
    pos = rootTrans.position

    local effRes =self._buffEff
    local timeSpan = self._timeSpan

    local effect = effectCtrl:MakeEffectObject(rootTrans, effRes, pos, nil, 0, timeSpan, 0)
    effect:SetScaleSize(self._scaleSize)
    effectCtrl:AddEffect(effect)

    if not self._effRecord then
        self._effRecord = {}
    end

    table.insert(self._effRecord,effect)

    if not string.isempty(self._buffMat) then
        obj:ChangeMat(self._buffMat,self._timeBefore)
    end

    if self._isFreeze then
        obj:TimePause()
    end
end


---@return LStoryObject
function LStoryBuffEvent:GetObj(heroId)
    local tarId = heroId or self._heroId
    local objCtrl = self._manager:GetObjCtrl()
    local obj = objCtrl:GetObjByKey(tarId)
    return obj
end


return LStoryBuffEvent