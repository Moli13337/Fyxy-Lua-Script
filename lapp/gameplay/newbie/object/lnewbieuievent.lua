local LNewbieEventBase = LXImport(".LNewbieEventBase")
---@class LNewbieUIEvent:LNewbieEventBase
local LNewbieUIEvent = LxClass("LNewbieUIEvent",LNewbieEventBase)

function LNewbieUIEvent:LNewbieUIEvent()

end

function LNewbieUIEvent:OnStart()
    FireEvent(EventNames.ON_NEW_BIE_EVENT_START, self._eventId)
    local eventType = self._type
    if eventType == LNewbieEventType.CREATE_ROLE then
        if gModelPlayer:IsNoName() then
            GF.OpenWnd('UIPerCreateName', {isNew = true,FromNewbieEventId = self._eventId})
        else
            self:End()
        end
    elseif eventType == LNewbieEventType.JUMP then
        local windowRefId = tonumber(self._eventCfg.parameter)
        if windowRefId and gModelGuide:IsMeetJumpNewPlot() then
            local func = function()
                gModelGuide:GuideJumpReq(1,1)
            end
            local cancelFunc = function()
                self:End()
            end
            gModelGeneral:OpenUIOrdinTips({refId = windowRefId,func = func, leftFunc = cancelFunc, closeFunc = cancelFunc}, true, true)
        else
            self:End()
        end
    else
        self:ShowStoryWnd()
    end
end

function LNewbieUIEvent:OnEnd()
    if self._type == LNewbieEventType.CREATE_ROLE then
        GF.CloseWndByName("UIPerCreateName")
    else
        GF.OpenWnd("UINeie",{operType = 2 ,eventId = self._eventId})
    end
end

function LNewbieUIEvent:ShowStoryWnd()
    GF.OpenWnd("UINeie",{operType = 1 , eventId = self._eventId})
end

function LNewbieUIEvent:OnDestroy()

end

return LNewbieUIEvent