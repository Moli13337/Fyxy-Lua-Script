local LFightExpreBase = LXImport("..Base.LFightExpreBase")

local LFightExpreDrawing = LxClass("LFightExpreDrawing",LFightExpreBase)

function LFightExpreDrawing:LFightExpreDrawing()
    self._type = LSkillEffConst.PLAY_EFF_DRAWING
end

function LFightExpreDrawing:Preload()
    LFightExpreBase.Preload(self)
end

function LFightExpreDrawing:OnStart()
    local effData = self._effData

    local effRes = effData.effRes --光效名字
    local playTime = effData.playTime --光效持续时间
    local dissipateTime = effData.dissipateTime --光效消散时间
    local offset = effData.effOffsetStart --偏移
    local offsetType = effData.effStartType or 1
    local isUpperLayer = effData.battleHierarchy == 0

    local obj = self._runningData.atkObj
    local atkPos = obj:GetPosition()
    local atkSide = obj:GetSide()

    local eObj = self._runningData.targetObj
    local ePos = eObj:GetPosition()
    local eIndex = eObj:GetIndex()
    local eSide = eObj:GetSide()

    local pos = self:GetEffStartPos(offsetType,atkSide,eSide,atkPos,ePos,eIndex)
    local actOffset = offset
    if atkSide == LFightConst.SIDE_TEAM_B then
        actOffset = Vector3.New(-offset.x,offset.y,0)
    end
    local effPos = offset + pos
    local effectCtrl = self._manager:GetEffectCtrl()

    local rootTrans = self._manager:GetEffectRootTrans()
    local effect = effectCtrl:MakeEffectObject(rootTrans, effRes, effPos, LFightConst.DIRECTION_LEFT, 0, playTime,dissipateTime,LFightEffect.SPINE)
    local para =
    {
        scale = 1,
        localPos = nil,
        isUpperLayer = isUpperLayer,
        onStartCall = function()
            self:HideAllBlood()
        end,
        onEndCall = function()
            self:RecoverBloodShow()
        end
    }
    effect:SetEffectPara(para)
    effectCtrl:AddEffect(effect)
end

function LFightExpreDrawing:GetEffStartPos(offsetType,selfSide,tarSide,selfPos,targetPos,tarIndex)

    targetPos = targetPos or Vector3.zero

    local battleUnit = self._manager
    local tempPos = selfPos
    if offsetType == LFightConst.EFFECT_TO_SELF then
        --1=自身
        tempPos = selfPos
    elseif offsetType == LFightConst.EFFECT_TO_EVERY_TAR then
        --2=针对指定单位
        tempPos = targetPos
    elseif offsetType == LFightConst.EFFECT_TO_TARGET_CENTER then
        --3=目标群体中心
        tempPos = targetPos
    elseif offsetType == LFightConst.EFFECT_TO_SELF_TEAM_CENTER then
        --4=我方九宫中心格
        tempPos = battleUnit:GetFormationCenterPosition(selfSide):Clone()
    elseif offsetType == LFightConst.EFFECT_TO_ENEMY_TEAM_CENTER then
        --5=敌方九宫中心格
        tempPos = battleUnit:GetFormationCenterPosition(tarSide):Clone()
    elseif offsetType == LFightConst.EFFECT_TO_OFF_SCREEN_DOWN then
        --6=屏幕外下方
        tempPos = battleUnit:GetFormationOffScreenDownPosition(tarSide):Clone()
    elseif offsetType == LFightConst.EFFECT_TO_ZERO then
        --7=原点
        tempPos = Vector3.zero
    elseif offsetType == LFightConst.EFFECT_TO_ROW_CENTER then
        --9=目标排中心
        tempPos = battleUnit:GetRowCenterPos(tarSide,tarIndex):Clone()
    end

    return tempPos
end

function LFightExpreDrawing:HideAllBlood()
    self._manager:HideAllBlood()
end

function LFightExpreDrawing:RecoverBloodShow()
    self._manager:RecoverBloodShow()
end

return LFightExpreDrawing