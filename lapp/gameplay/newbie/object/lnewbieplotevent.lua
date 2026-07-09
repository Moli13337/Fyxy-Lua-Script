local LNewbieEventBase = LXImport(".LNewbieEventBase")
---@class LNewbiePlotEvent:LNewbieEventBase
local LNewbiePlotEvent = LxClass("LNewbiePlotEvent",LNewbieEventBase)

function LNewbiePlotEvent:LNewbiePlotEvent()

end

function LNewbiePlotEvent:OnStart()
    local plot = tonumber(self._eventCfg.parameter)
    gModelPlot:StartPlotPara({plot=plot, endCall=function()
        if self._isDestroy then return end
        self:End()
    end})
end

function LNewbiePlotEvent:OnEnd()

end

function LNewbiePlotEvent:OnDestroy()

end

return LNewbiePlotEvent