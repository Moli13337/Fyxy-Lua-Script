---@class LStoryCameraEvent:LStoryEventBase
local LStoryCameraEvent = LxClass("LStoryCameraEvent",LStoryEventBase)

LXImport("LApp.gameplay.Common.LTimeLinePlayer")

function LStoryCameraEvent:LStoryCameraEvent()
    --self._type = LStoryEventType.CAMERA

end


function LStoryCameraEvent:OnStart()
    local cfg = self._eventCfg

    self._type = cfg.eventType

    local manager = self:GetManager()
    if self._type == LStoryEventType.CAMERA_FOLLOW then
        local heroId = tonumber(cfg.heroId)
        self._targetHero = heroId
        self:FollowHero()
    elseif self._type == LStoryEventType.CAMERA_SOLID then
        manager:StopMoveCamera()

        local coord = cfg.coordinate
        if not string.isempty(coord) then
            local startPos =LUtil.ConvertPixelPosToUnitPos(LxDataHelper.ParseVector(coord))
            manager:SetCameraPos(startPos)
        end

        coord = cfg.moveCoordinate
        if not string.isempty(coord) then
            local startPos = manager:GetCameraPos()

            local endPos =LUtil.ConvertPixelPosToUnitPos(LxDataHelper.ParseVector(coord))

            local speed = cfg.moveSpeed
            local dis = Vector3.Distance(startPos,endPos)
            local time = dis/speed
            if LOG_INFO_ENABLED then
                printInfoN("camera move time "..time)
            end
            manager:StartCameraMove(endPos,time)
        end
    elseif self._type == LStoryEventType.CAMERA_SHAKE then
        local duration = self._endTime - self._startTime
        local intense = cfg.multiple
        intense = intense== 0 and 1 or intense
        GF.ShakeMainScene(duration,0.1*intense, 0.1* intense)
    elseif self._type == LStoryEventType.CAMERA_TIMELINE then
        local timeLinePlayer = self._timeLinePlayer
        if not timeLinePlayer then
            timeLinePlayer = LTimeLinePlayer:New()
            self._timeLinePlayer = timeLinePlayer
        end

        local cameraGo = manager:GetCameraGo()
        self._timeLinePlayer:PlayTimeLine(cameraGo,cfg.act)
    end

end

function LStoryCameraEvent:OnEnd()
    if self._type == LStoryEventType.CAMERA_FOLLOW then
        self:GetManager():StopMoveCamera()
    end
end

function LStoryCameraEvent:OnRun(time)
    --if self._type ~= LStoryEventType.CAMERA_SOLID then
    --    return
    --end

    --local t = (time- self._startTime)/(self._endTime- self._startTime)
    --local pos = Vector3.Lerp(self._startPos,self._endPos,t)
    --self._manager:SetCameraPos(pos)
end

function LStoryCameraEvent:OnHeroLoaded(heroId)
    if heroId ~= self._targetHero then
        return
    end
    if self._type ~= LStoryEventType.CAMERA_FOLLOW then
        return
    end
    if self:IsEnd() then
        return
    end

    self:FollowHero()

end

function LStoryCameraEvent:FollowHero()
    local manager = self:GetManager()
    local objCtrl = manager:GetObjCtrl()
    local obj = objCtrl:GetObjByKey(self._targetHero)
    if not obj or not obj:IsReady() then

        return
    end

    local tran = obj:GetDisplayTrans()
    if not tran then
        return
    end
    manager:SetFollowCamera(tran)
end


return LStoryCameraEvent