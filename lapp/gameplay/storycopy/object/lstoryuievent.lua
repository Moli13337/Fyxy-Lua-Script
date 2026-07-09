---@class LStoryUIEvent:LStoryEventBase
local LStoryUIEvent = LxClass("LStoryUIEvent",LStoryEventBase)



function LStoryUIEvent:LStoryUIEvent()

end

function LStoryUIEvent:OnStart()
    local eventType = self._type

    if eventType == LStoryEventType.RENDER_GREY then
        local para = self._eventCfg.act
        local strs = string.split(para,'|')
        self._timeBefore = strs[1] and tonumber(strs[1]) or 0
        self._timeAfter = strs[2] and tonumber(strs[2]) or 0
        gLGamePostProcess:ShowSceneGray(self._timeBefore)
    else
        self:ShowStoryWnd(self._eventId)
    end

end

function LStoryUIEvent:OnEnd()
    local eventType = self._type
    if eventType == LStoryEventType.RENDER_GREY then
        gLGamePostProcess:HideSceneGray(self._timeAfter)
    else
        GF.OpenWnd("UISy",{operType = 2 ,para = self._type,eventId = self._eventId})
    end

end


function LStoryUIEvent:ShowStoryWnd(eventId)
    GF.OpenWnd("UISy",{operType = 1 ,para = eventId})
end

function LStoryUIEvent:OnDestroy()
    if self._type == LStoryEventType.RENDER_GREY then
        gLGamePostProcess:HideSceneGray(0)
    end
end



return LStoryUIEvent