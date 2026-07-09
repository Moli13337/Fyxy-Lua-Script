---@class LNewbieEventBase
local LNewbieEventBase = LxClass("LNewbieEventBase",nil)
function LNewbieEventBase:LNewbieEventBase(manager)
    self._startTime = nil
    self._endTime = nil

    self._state = LNewbieEventState.BEFORE

    ---@type LNewbieManager
    self._manager = manager
end

function LNewbieEventBase:Create(eventId,curTime)
    self._startTime = curTime
    self._eventId = eventId
    self._endTime = 0
    self._eventCfg = gModelPlot:GetStoryNewbieRef(eventId)
    if not self._eventCfg then
        printErrorN(string.format("not storynewbie cfg %s",eventId))
        return
    end
    self._type = self._eventCfg.type
end

function LNewbieEventBase:Start()
    self._state = LNewbieEventState.RUNNING
    if LOG_INFO_ENABLED then
        printInfoN("[newbie]event start id "..self._eventId)
    end

    if self._manager:IsCanRecord() then
        if self._eventCfg.server > 0 then
            gModelPlot:OnSceneSystemLookReq(self._eventId, ModelPlot.START_TYPE_2)
        end
    end
    gLxTKData:OnStoryStep(self._eventId)


    self:OnStart()
end

function LNewbieEventBase:End()
    if self._state == LNewbieEventState.END then
        return
    end
    if LOG_INFO_ENABLED then
        printInfoN("[newbie]event end id "..self._eventId)
    end
    local eventId = self._eventId
    self:OnEnd()
    table.removeall(self)
    self._state = LNewbieEventState.END
    self._eventId = eventId
end

function LNewbieEventBase:Run(time)

    if self._state == LNewbieEventState.END then
        return
    end

    if time>self._startTime and self._state == LNewbieEventState.BEFORE then
        self:Start()
    end

    if self._state == LNewbieEventState.END then
        return
    end

    if self._endTime>0 and time>self._endTime then
        self:End()
    end

    if self._state == LNewbieEventState.END then
        return
    end

    if self._state== LNewbieEventState.RUNNING then
        self:OnRun(time)
    end
end

function LNewbieEventBase:OnStart()

end

function LNewbieEventBase:OnEnd()

end

function LNewbieEventBase:OnRun(time)

end

function LNewbieEventBase:OnDestroy()

end

function LNewbieEventBase:IsEnd()
    return self._state == LNewbieEventState.END
end

function LNewbieEventBase:IsLoop()
    return self._endTime == -1
end

function LNewbieEventBase:GetEventType()
    return self._type
end

function LNewbieEventBase:GetEventId()
    return self._eventId
end

function LNewbieEventBase:GetManager()
    return self._manager
end

function LNewbieEventBase:Destroy()
    self:OnDestroy()
    table.removeall(self)
    self._isDestroy = true
end


return LNewbieEventBase