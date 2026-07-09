local StartCtrlBase = LXImport(".StartCtrlBase")
---guideType 5
---@class StartCtrlFour
local StartCtrlFour = LxClass("StartCtrlFour", StartCtrlBase)

function StartCtrlFour:StartCtrlFour()

end

function StartCtrlFour:OnSceneLoaded()

    self._doAfter = false

    if gLGameLogin:GetPlayCartoon() then --未创角
        local stepId = gModelPlot:GetCartoonStep()
        GF.OpenWnd('UIMCity')
        GF.OpenWnd("UISayFlow")
        GF.OpenUIGue("UICartront",{stepId= stepId})
        return "LFightIdleMap"
    end

    if gModelPlayer:IsNoName() then --未取名
        GF.OpenWnd('UIMCity')
        GF.OpenWnd("UISayFlow")
        GF.OpenWnd('UIPerCreateName', {isNew = true})
        return "LFightIdleMap"
    end

    if not gModelPlot:IsStartPlayed() or not gModelPlot:IsStartPlayEnded() then
        GF.OpenWnd('UIMCity')
        GF.OpenWnd("UISayFlow")

        self._doAfter = true
        return "LFightIdleMap"
    end

    local battleNode = gModelInstance:GetBattleNode()
    if gModelPlot:IsStoryInstanceInternal(battleNode) then
        GF.OpenWnd('UIMCity')
        GF.OpenWnd("UISayFlow")
        return "LFightIdleMap"
    end


    return "LCityMap"

end

function StartCtrlFour:OnSceneEnterFinished()
    if not self._doAfter then return end

    if not gModelPlot:IsStartPlayed() then --未开始剧情
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



return  StartCtrlFour