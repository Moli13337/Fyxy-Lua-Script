---@class LStoryEffectEvent:LStoryEventBase
local LStoryEffectEvent = LxClass("LStoryEffectEvent",LStoryEventBase)



function LStoryEffectEvent:LStoryEffectEvent()
    --self._type = LStoryEventType.EFFECT
end



function LStoryEffectEvent:OnStart()
    local cfg = self._eventCfg

    self._effectRes= cfg.effectName
    self._heroId = tonumber(cfg.heroId)
    self._pos = LxDataHelper.ParseVector(cfg.coordinate)
    self._pos = LUtil.ConvertPixelPosToUnitPos(self._pos)
    self._scaleSize = cfg.multiple

    self._timeSpan = self._endTime - self._startTime

    self:CreateEffect()
end

function LStoryEffectEvent:OnEnd()
    if self._effRecord then
        for k,v in pairs(self._effRecord) do
            v:Destroy()
        end

        self._effRecord = nil
    end
end

function LStoryEffectEvent:OnHeroLoaded(heroId)
    if self._heroId ~= heroId then
        return
    end

    self:CreateEffect()
end

function LStoryEffectEvent:CreateEffect()
    local effectCtrl = self:GetManager():GetEffCtrl()
    local rootTrans = nil
    local pos = nil
    local manager = self:GetManager()
    if self._type == LStoryEventType.EFFECT_HERO then
        if self._heroId  then
            local objCtrl = manager:GetObjCtrl()
            local obj = objCtrl:GetObjByKey(self._heroId)
            if not obj or not obj:IsReady() then

                return
            end

            rootTrans = obj:GetDisplayTrans()
            if not rootTrans then
                return
            end
            pos = rootTrans.position

        end
    elseif self._type == LStoryEventType.EFFECT_SCENE then
        rootTrans = manager:GetEffectRootTrans()
        pos = self._pos
    elseif self._type == LStoryEventType.EFFECT_GUIDE then
        local tran = nil
        if self._heroId  then
            local objCtrl = manager:GetObjCtrl()
            local obj = objCtrl:GetObjByKey(self._heroId)
            if not obj or not obj:IsReady() then
                return
            end

            tran = obj:GetDisplayTrans()
        end

        local guideId = tonumber(self._eventCfg.act)
        gModelGuide:StartStoryGuide(guideId,tran,function ()
            if not manager:IsRunning() then
                return
            end
            local eventCtrl = manager:GetEventCtrl()
            eventCtrl:ClearEvent({self._eventId})
        end)

        return
    end

    local effRes =self._effectRes
    local timeSpan = self._timeSpan

    local effect = effectCtrl:MakeEffectObject(rootTrans, effRes, pos, nil, 0, timeSpan, 0)
    effect:SetScaleSize(self._scaleSize)
    effectCtrl:AddEffect(effect)

    if not self._effRecord then
        self._effRecord = {}
    end

    table.insert(self._effRecord,effect)
end



return LStoryEffectEvent