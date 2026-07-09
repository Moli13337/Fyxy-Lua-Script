
---@class LFightDecoCtrl
local LFightDecoCtrl = LxClass("LFightDecoCtrl",nil)

function LFightDecoCtrl:LFightDecoCtrl()
    self._effectMap= {}
end

function LFightDecoCtrl:CreateEffect(effectData)

    local effectKey = effectData.effectKey
    local oldEffect = self._effectMap[effectKey]
    if oldEffect then
        if oldEffect.isLoaded then
            if effectData and effectData.loadedCall then
                effectData.loadedCall(oldEffect.effect)
            end
        else
            oldEffect.effectData = effectData
        end
        return
    end

    local dp = LDisplayEffect:New()

    self._effectMap[effectKey] = {isLoaded = false,effect = dp,effectData= effectData}

    local failCallback = effectData.failCallback

    local root = effectData.root
    local resName = effectData.resName
    dp:CreateEffect(root, resName)
    dp:SetResTag(CS.RES_TAG_SCENE)
    dp:SetLoadFailFunc(failCallback)
    dp:SetLoadedFunction(function(effect)
       self:OnLoaded(effectKey)
    end)
    dp:StartLoadEffect()

end

function LFightDecoCtrl:OnLoaded(key)
    local info = self:FindEffectInfoByKey(key)
    if not info then
        return
    end

    info.isLoaded = true
    local effectdata = info.effectData
    if effectdata and effectdata.loadedCall then
        effectdata.loadedCall(info.effect)
    end
end

function LFightDecoCtrl:FindEffectInfoByKey(key)
    return self._effectMap[key]
end

function LFightDecoCtrl:DeleteEffect(key)
    local info = self._effectMap[key]
    self._effectMap[key] = nil
    if not info then
        return
    end

    local effect = info.effect
    if effect then
        effect:Destroy()
    end
end

function LFightDecoCtrl:ClearAllEffect()
    for k,v in pairs(self._effectMap) do
        local effect = v.effect
        if effect then
            effect:Destroy()
        end
    end
    self._effectMap = {}
end


function LFightDecoCtrl:Destroy()
    self:ClearAllEffect()

    self._effectMap = nil

    table.removeall(self)
end

return LFightDecoCtrl