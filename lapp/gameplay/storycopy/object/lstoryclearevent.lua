---清除指定事件
---@class LStoryClearEvent:LStoryEventBase
local LStoryClearEvent = LxClass("LStoryClearEvent",LStoryEventBase)



function LStoryClearEvent:LStoryClearEvent()
end

function LStoryClearEvent:OnStart()

    local cfg = self._eventCfg
    local refIdList = LxDataHelper.ParseNumber_Sign(cfg.heroId,'|')

    local eventCtrl = self:GetManager():GetEventCtrl()
    eventCtrl:ClearEvent(refIdList)
end

function LStoryClearEvent:OnEnd()

end



return LStoryClearEvent