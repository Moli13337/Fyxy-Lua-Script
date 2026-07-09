---@class StartCtrlBase
local StartCtrlBase = LxClass("StartCtrlBase", nil)

function StartCtrlBase:StartCtrlBase(guideType)

    self._guideType=guideType
end

function StartCtrlBase:OnSceneLoaded()

end

function StartCtrlBase:OnSceneEnterFinished()

end

return StartCtrlBase
