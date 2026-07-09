
local LFightExpreBase = LXImport("..Base.LFightExpreBase")
---@class LFightExpreEffect
local LFightExpreEffect = LxClass("LFightExpreEffect",LFightExpreBase)

function LFightExpreEffect:LFightExpreEffect()
    self._type = LSkillEffConst.PLAY_EFF_EFFECT
end

function LFightExpreEffect:Preload()
    LFightExpreBase.Preload(self)
end

function LFightExpreEffect:OnStart()
    local effData = self._effData
    local effRes = effData.effRes --光效名字
    local playTime = effData.playTime --光效持续时间
    local dissipateTime = effData.dissipateTime --光效消散时间
    local offset = effData.effOffsetStart --偏移
    --local excursionIObject = effData.excursionIObject

    local offsetX = offset.x
    local offsetY = offset.y

    local runningData = self._runningData
    local dataList = runningData.dataList
    --local scale = runningData.scale
    local isUpperLayer = runningData.isUpperLayer
    --local bulletTarPos = runningData.bulletTarPos
    --local effTarget = effData.effTarget
    local buffEffShowType = runningData.buffEffShowType or -1

    local showLoop = effData.showLoop or 0
    local isPersistence = showLoop == 1

    ---@type LFightEffect[]
    local recordEffectList = {}
    ---@type LFightEffectCtrl
    local effectCtrl = self._manager:GetEffectCtrl()
    for k, v in ipairs(dataList) do
        local rootTrans = v.trans
        local pos = v.pos
        local dir = v.dir

        if dir == LFightConst.DIRECTION_LEFT then
            pos.x = pos.x - offsetX
        else
            pos.x = pos.x + offsetX
        end
        pos.y = pos.y + offsetY
        pos.z = 0

        ---根据子弹落点
        --if excursionIObject == 1 and bulletTarPos then
        --    pos = bulletTarPos
        --    pos.z = 0
        --end

        local targetObj = nil
        local boneName = effData.boneName
        if not string.isempty(boneName) and v.targetObj then
            targetObj = v.targetObj
        end
        ---@type LFightEffect
        local effect = effectCtrl:MakeEffectObject(rootTrans, effRes, pos, dir, 0, playTime,dissipateTime)
        local para = {
            isUpperLayer = isUpperLayer,
            scale = 1,
            boneName = boneName,
            targetObj = targetObj,
            isPersistence = isPersistence,
            buffEffShowType = buffEffShowType,
        }
        effect:SetEffectPara(para)
        effectCtrl:AddEffect(effect)

        table.insert(recordEffectList,effect)
    end
    self._recordEffectList = recordEffectList
end

function LFightExpreEffect:RecycleEnd()
    ---@type LFightEffect[]
    local recordEffectList = self._recordEffectList
    if recordEffectList and #recordEffectList > 0 then
        for i,v in ipairs(recordEffectList) do
            if not v:IsDestroy() then
                v:SetPersistenceStatus(false)
            end
        end
    end
    LFightExpreBase.RecycleEnd(self)
end

function LFightExpreEffect:SetVisible(bShow)
    ---@type LFightEffect[]
    local recordEffectList = self._recordEffectList
    if recordEffectList and #recordEffectList > 0 then
        for i,v in ipairs(recordEffectList) do
            if not v:IsDestroy() then
                v:SetVisible(bShow)
            end
        end
    end

    LFightExpreBase.SetVisible(self)
end

return LFightExpreEffect