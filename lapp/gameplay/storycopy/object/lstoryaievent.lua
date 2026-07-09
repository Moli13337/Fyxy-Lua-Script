---@class LStoryAiEvent:LStoryEventBase
local LStoryAiEvent = LxClass("LStoryAiEvent",LStoryEventBase)

function LStoryAiEvent:LStoryCameraEvent()
    --self._type = LStoryEventType.START_AI

end

function LStoryAiEvent:OnStart()
    local objctrl = self._manager:GetObjCtrl()
    objctrl:StartAllAI()
end

function LStoryAiEvent:OnEnd()
    local objctrl = self._manager:GetObjCtrl()
    objctrl:StopAllAI()
end

return LStoryAiEvent