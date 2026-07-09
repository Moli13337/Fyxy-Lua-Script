local StartCtrlBase = LXImport(".StartCtrlBase")
---guideType 1
---@class StartCtrlOne
local StartCtrlOne = LxClass("StartCtrlOne", StartCtrlBase)

function StartCtrlOne:StartCtrlOne()

end

function StartCtrlOne:OnSceneLoaded()
    self._doAfter = false

    if gLGameLogin:GetPlayCartoon() then --未创角
        local stepId = gModelPlot:GetCartoonStep()
        GF.OpenWnd('UIMCity')
        GF.OpenWndTop("UISayFlow")
        GF.OpenUIGue("UICartront",{stepId= stepId})
        return "LStoryMap"
    end

    if gModelPlayer:IsNoName() then --未取名
        GF.OpenWnd('UIMCity')
        GF.OpenWndTop("UISayFlow")
        GF.OpenWnd('UIPerCreateName', {isNew = true})
        return "LStoryMap"
    end

    if not gModelPlot:IsStartPlayed() or not gModelPlot:IsStartPlayEnded() then
        GF.OpenWnd('UIMCity')
        GF.OpenWndTop("UISayFlow")

        self._doAfter = true
        return "LStoryMap"
    end

    return "LCityMap"

end

function StartCtrlOne:OnSceneEnterFinished()
    if not self._doAfter then
        return
    end

    if not gModelPlot:IsStartPlayed() then --开始剧情
        FireEvent(EventNames.ON_CREATE_NAME_END)
        return
    end

    if not gModelPlot:IsStartPlayEnded() then
        local has,refId,type = gModelPlot:CheckRestartStory() --剧情重登
        if has then
            gModelPlot:TryRestartStory(type,refId)
        end
    end
end



return  StartCtrlOne