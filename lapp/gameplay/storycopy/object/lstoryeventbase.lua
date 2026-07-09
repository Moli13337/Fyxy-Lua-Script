---@class LStoryEventBase
local LStoryEventBase = LxClass("LStoryEventBase",nil)


function LStoryEventBase:LStoryEventBase(manager)
    self._startTime = nil
    self._endTime = nil

    self._state = LStoryEventState.BEFORE

    ---@type LStoryManager
    self._manager = manager
end

function LStoryEventBase:Create(eventData,curTime)
    self._startTime = eventData.startTime + curTime
    if eventData.endTime== -1 then
        self._endTime = -1
    else
        self._endTime = eventData.endTime + self._startTime
    end
    self._eventId = eventData.eventId
    self._eventCfg = gModelPlot:GetStoryEventRef(self._eventId)
    if not self._eventCfg then
        printErrorN(string.format("not story event cfg %s",self._eventId))
        return
    end

    self._type = self._eventCfg.eventType
end

function LStoryEventBase:Start()
    self._state = LStoryEventState.RUNNING
    if LOG_INFO_ENABLED then
        printInfoN("event start id "..self._eventId)
    end

    local sound = self._eventCfg.sound
    self._sound = sound
    --printInfoN("story sound "..sound)
    if not string.isempty(sound) then
        gLGameAudio:PlaySingleSound(sound)
    end
    self:OnStart()
end

function LStoryEventBase:End()
    if self._state == LStoryEventState.END then
        return
    end
    if LOG_INFO_ENABLED then
        printInfoN("event end id "..self._eventId)
    end
    self:OnEnd()
    --if string.isempty(self._sound) then
        --gLGameAudio:StopSingleSound()
    --end

    table.removeall(self)
    self._state = LStoryEventState.END
end

function LStoryEventBase:Run(time)

    if self._state == LStoryEventState.END then
        return
    end

    if time>self._startTime and self._state == LStoryEventState.BEFORE then
        self:Start()
    end

    if self._state == LStoryEventState.END then
        return
    end

    if self._endTime>0 and time>self._endTime then
        self:End()
    end

    if self._state == LStoryEventState.END then
        return
    end

    if self._state== LStoryEventState.RUNNING then
        self:OnRun(time)
    end
end

function LStoryEventBase:OnStart()

end

function LStoryEventBase:OnEnd()

end

function LStoryEventBase:OnRun(time)

end

function LStoryEventBase:OnDestroy()

end

function LStoryEventBase:IsEnd()
    return self._state == LStoryEventState.END
end

function LStoryEventBase:IsLoop()
    return self._endTime == -1
end

function LStoryEventBase:GetEventType()
    return self._type
end

function LStoryEventBase:GetEventId()
    return self._eventId
end

function LStoryEventBase:GetManager()
    return self._manager
end

function LStoryEventBase:Destroy()
    self:OnDestroy()
    table.removeall(self)
end






return LStoryEventBase