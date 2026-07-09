local LModel = LModel

------------------------------------------------------------------
---@class ModelWndPop:LModel
local ModelWndPop = LxClass("ModelWndPop", LModel)

ModelWndPop.UIWindowEjectRef = "UIWindowEjectRef"

ModelWndPop.LAYER_1 = 1
ModelWndPop.LAYER_2 = 2

--模块初始化入口
--注册事件监听
--注册协议监听
--预处理数据
function ModelWndPop:OnModelInit()
    --self._wndList = {}

    self._isAccountWnd = {
        ['UIOrdinResult'] = true,
        ['UIringFightResult'] = true,
        ['WndCrossServerBattleResult'] = true,
        ['UILvUp'] = true,
        ['UIGjAwardReceive'] = true,
        -- ['WndHighStageRaceBattleResult'] = true,
    }

    self._guideExceptWnd = {
        ['UI8LoginNew'] = true,
        ["UIAward"] = true,
    }

    self._forbidReward = {
        ['UIHuiY'] = true,
    }

    self._wndLayerMap = {
        ['UIHuiY'] = 2,
        ['UIAward'] = 2,
    }

    self._isResultWnd = {
        ['UIOrdinResult'] = true,
        ['UIringFightResult'] = true,
        ['WndCrossServerBattleResult'] = true,
        ['UIAward'] = true,
        -- ['WndHighStageRaceBattleResult'] = true,
    }

    ---提示条，不阻塞弹窗
    self._isTipsWnd = {
        ["UIAdLogNotion"] = true,
        ["UIGwthCapitalJumpPop"] = true,
    }

    self._isCombatWnd = {
        ['UIOrdinResult'] = true,
        ['UIringFightResult'] = true,
        ['WndCrossServerBattleResult'] = true,
        -- ['WndHighStageRaceBattleResult'] = true,
    }

    self._guildAllowPop = {
        ["UIAward"] = true,
        ['UIGjAwardReceive'] = true,
        ["UIHuiY"] = true,
        ["UIAdLogNotion"] = true,
        ["UIGwthCapitalJumpPop"] = true,
        ["UIAppsal"] = true,
        ["UIRiskRtUpLvl"] = true,
    }

    self._guideWaitPop = {
        ["UIAward"] = true,
        ['UIGjAwardReceive'] = true,
        ["UIHuiY"] = true,
        ["UIAppsal"] = true,
        ['UIOrdinResult'] = true,
        ['UIringFightResult'] = true,
        ['WndCrossServerBattleResult'] = true,
        ['UILvUp'] = true,
        -- ['WndHighStageRaceBattleResult'] = true,
    }

    self:ParseConfig()
    self:ModelEventRecv(EventNames.ON_WND_CLOSE, function(...)
        self:OnWndClose(...)
    end)
    self:ModelEventRecv(EventNames.ON_GUIDE_START, function(...)
        self:OnGuideStart(...)
    end)
    self:ModelEventRecv(EventNames.ON_CHANGE_MAIN_BTN, function(index)
        if index ~= LMainBtnIndexConst.CITY then
            return
        end
        self:CheckPopWnd()
    end)
end

--在协议数据处理完之后需要调用finish
function ModelWndPop:OnModelRequest()
    self:ModelFinish()
end

function ModelWndPop:OnModelClear()
end

function ModelWndPop:GetWndList()
    if not self._wndList then
        self._wndList = {}
    end

    return self._wndList
end

function ModelWndPop:CheckHadWnd(wndName)
    local wndList = self:GetWndList()
    for k, v in pairs(wndList) do
        local temp = v.uiName
        if temp == wndName then
            return true
        end
    end

    return false
end

function ModelWndPop:OnWndClose(wndName)
    local layer = self:GetWndBelongLayer(wndName)
    local curWndName = self:GetCurWndName(layer)
    if curWndName == wndName then
        self:DeleteWndName(layer)
    end
    curWndName = self:GetCurWndName(layer)
    if curWndName then
        return
    end

    if not self:HasAccountWnd() then
        FireEvent(EventNames.CHECK_SHOW_TASK_FINISH)
    end

    self:CheckPopWnd()

    self:CheckStartGuide()

end

function ModelWndPop:ParseConfig()
    local ref = self:GetModelConfig(ModelWndPop.UIWindowEjectRef)
    local sortMap = {}

    for k, v in pairs(ref) do
        local uiName = v.uiName
        local wndRefId = v.windowAttRefId
        local sort = v.sort
        local map = sortMap[uiName]
        if not map then
            map = {}
            sortMap[uiName] = map
        end
        map[wndRefId] = sort

    end

    self._wndSortMap = sortMap
end

function ModelWndPop:GetSort(uiName, attrId)
    attrId = attrId or 0
    local dataList = self._wndSortMap[uiName]
    if dataList then
        return dataList[attrId] or 99999999
    end

    return 99999999
end

function ModelWndPop:TryOpenPopWnd(uiName, para)
    self:InsertPopWnd(nil, uiName, para)
    self:CheckPopWnd()
end

function ModelWndPop:OpenWndImpl(data)
    local isIgnore = false
    if data.uiName == "UIActKeyRoom" then
        local _sid = data.para.sid
        isIgnore = not gModelActivity:GetAnswerIsRoom(_sid)

    elseif data.uiName == "WndPrePost" then
        local list = gModelFunctionOpen:GetPrePostList()
        isIgnore = not list or #list == 0
    end

    if isIgnore then
        self:CheckPopWnd()
        return
    end

    if data.para then
        data.para._isAboveWnd = true  ---添加标记

    else
        data.para = {
            _isAboveWnd = true
        }
    end

    self:SavePopWndName(data.uiName)
    --self._curWndName = data.uiName
    if data.uiName == "UIOrdinTip" then
        gModelGeneral:OpenUIOrdinTips(data.para)
    elseif self._isCombatWnd[data.uiName] then
        if gModelBattle:IsLittleTip(data.para.combatType) and not data.para.force and data.para.isFromBack then
            FireEvent(EventNames.RESULT_LITTLE_TIP, data.para)
        else
            gLGameUI:OpenWndWithLayer(data.uiLayer, data.uiName, data.para)
        end
    else
        gLGameUI:OpenWndWithLayer(data.uiLayer, data.uiName, data.para)
    end

    self:CheckPopWnd()
end

function ModelWndPop:IsForbidByCurShow(reqPopWnd)
    local layer = self:GetWndBelongLayer(reqPopWnd)
    local curWndName = self:GetCurWndName(layer)
    if string.isempty(curWndName) then
        --有弹窗未关闭
        return false
    end
    if self._isTipsWnd[curWndName] then
        self:DeleteWndName(layer)
        return false
    end
    local wnd = GF.FindFirstWndByName(curWndName)
    if not wnd then
        self:DeleteWndName(layer)
        return false
    end

    --if reqPopWnd == "UIAward" then
    --    if self._forbidReward[curWndName] then
    --        return true
    --    else
    --        return false
    --    end
    --elseif reqPopWnd == "UIHuiY" then
    --    return false
    --end

    printErrorN(string.format("有弹窗没关闭 %s", curWndName))
    return true
end

function ModelWndPop:GetCurWndName(layer)
    if not self._showedWndList then
        return
    end
    return self._showedWndList[layer]

end

function ModelWndPop:SavePopWndName(wndName)
    local layer = self:GetWndBelongLayer(wndName)
    if not self._showedWndList then
        self._showedWndList = {}
    end
    self._showedWndList[layer] = wndName
end

function ModelWndPop:DeleteWndName(layer)
    --local layer = self:GetWndBelongLayer(wndName)

    if self._showedWndList then
        self._showedWndList[layer] = nil
    end
end

function ModelWndPop:CheckPopAllow(data)

    if LOG_INFO_ENABLED then
        print("ModelWndPop:CheckPopAllow(data)" .. data.uiName)
    end

    if self:IsForbidByCurShow(data.uiName) then
        return
    end

    --self:DeleteWndName()

    local hasEnterMain = gModelGeneral:GetHasEnteredCityMap() --没进入主城之前
    if not hasEnterMain then
        printErrorN("还没进入主场景")
        return
    end
    if self._guildAllowPop[data.uiName] then
        return true
    end
    local inGuide = gModelGuide:IsInGuide()
    if inGuide then
        printErrorN("指引过程中...")
        return
    end

    local manager = gLGpManager:FindStoryCopyGp()
    if manager and manager:IsRunning() then
        printErrorN("剧情副本中...")
        return
    end

    -- local curMap = GF.GetCurMap()
    -- if curMap and curMap:IsSameMap("LPlotGameMap") then
    --     printErrorN("LPlotGameMap 中...")
    --     return
    -- end

    local isAccountWnd = self._isAccountWnd[data.uiName]
    if isAccountWnd then
        local isVideoAlive = gModelBattle:IsVideoAlive()  --正在播放战斗
        if isVideoAlive then
            printErrorN("正在播放战斗录像...")
            return
        end

        local combatType = data.combatType
        if not combatType and data.para then
            combatType = data.para.combatType
        end

        if combatType then
            local playModule = gLGameUI:GetPlayModule()
            local belongModule = gLFightManager:GetPlayModuleByCombat(combatType)
            if playModule ~= LPlayModuleConst.NONE then
                printErrorN("正处于玩法中 module " .. playModule)
                return belongModule == playModule
            end
        end
    else

        local isSkipGuide = false
        local isForeign = gLGameLanguage:IsForeignVersion()
        if PRODUCT_G_VER ~= 0 then
            -- 提审
            if isForeign then
                isSkipGuide = true
            end
        end

        if not gModelGuide:IsAllowPopWnd() and (not isSkipGuide) then
            if LOG_INFO_ENABLED then
                local tipsGuide = gModelGuide:GetGuidePara("tipsGuide")
                printErrorN("需要完成指引 " .. tostring(tipsGuide))
            end
            return
        end

        local hasWaitGuide = gModelGuide:HasWaitGuide()
        if hasWaitGuide then
            printErrorN("指引等待执行")
            return
        end

        local isStroyRunning = gLGpManager:FindStoryCopyGp():IsRunning()
        if isStroyRunning then
            printErrorN("剧情副本中")
            return
        end

        local isExistBattle = gModelBattle:ExistPositiveBattle()
        if isExistBattle then
            printErrorN("战斗中")
            return
        end

        local curMap = GF.GetCurMap()
        local ignoreMap = data.para and data.para.ignoreMap
        if not ignoreMap and not (curMap and curMap:IsSameMap("LCityMap")) then
            printErrorN("不在主城")
            return
        end

        local mainCity = GF.FindFirstWndByName("UIMCity")
        if not mainCity then
            printErrorN("不在主城")
            return
        end

        if mainCity:GetCurIndex() ~= LMainBtnIndexConst.CITY then
            printErrorN("不在主城")
            return
        end

        local ignoreWnd = data.para and data.para.ignoreWnd
        if not ignoreWnd and not gLGameUI:IsCurMainClean({ ["UIGjKillMon"] = true }) then
            printErrorN("有其他界面")
            return
        end

        local rejectWnd = data.para and data.para.rejectWnd
        if rejectWnd then
            if gLGameUI:IsExistOneWnd(rejectWnd) then
                return
            end
        end
    end

    return true
end

function ModelWndPop:CheckPopWnd()
    if gModelGuide:CheckIsJumpFeedScene() then
        LogWarn("检测成功 弹出优先检测")
        return
    end
    if gModelGuide:IsJumpFeedScene() then
        LogWarn("正在直流")
        return
    end
    local wndList = self:GetWndList()

    local index = nil
    for k, v in ipairs(wndList) do
        local isAccoutWnd = self._isResultWnd[v.uiName]
        if isAccoutWnd then
            if self:CheckPopAllow(v) then
                index = k
                break
            end
        else
            if self:CheckPopAllow(v) then
                index = k
            end
            break
        end
    end
    if not index then
        return
    end

    local nextWndData = wndList[index]
    if not nextWndData then
        return
    end
    table.remove(wndList, index)

    self:OpenWndImpl(nextWndData)
end

function ModelWndPop:HasLvWnd()
    local wndList = self:GetWndList()
    for k, v in ipairs(wndList) do
        local temp = v.uiName
        if temp == "UILvUp" then
            return true, v
        end
    end
    return false
end

function ModelWndPop:InsertPopWnd(uiLayer, uiName, para)
    para = para or {}
    uiLayer = uiLayer or LGameUI.UI_SORTLAYER_UIWND
    local wndList = self:GetWndList()
    if uiName == "UILvUp" then
        local has, oldPara = self:HasLvWnd()
        if has then
            oldPara.newLv = para.newLv
            return
        end
    elseif uiName == "UIOrdinTip" then
        for k, v in ipairs(wndList) do
            if v.uiName == "UIOrdinTip" and v.para.refId == para.refId then
                table.remove(wndList, k)
                break
            end
        end
    elseif uiName == "UIActRkTopThreePop" then

    elseif not self._isResultWnd[uiName] then
        local sidId = para and para.sid
        local isActivity = sidId ~= nil
        for k, v in ipairs(wndList) do
            if v.uiName == uiName then
                --开多个活动时，允许不同sid的活动，依次弹出
                if isActivity then
                    local curPara = v.para
                    if curPara then
                        local curSid = curPara.sid
                        if curSid == para.sid then
                            table.remove(wndList, k)
                            break
                        end
                    end
                else
                    table.remove(wndList, k)
                    break
                end
            end
        end
    end

    local attrId = uiName == "UIOrdinTip" and para.refId or 0
    local data = {
        uiLayer = uiLayer,
        uiName = uiName,
        attrId = attrId,
        para = para,
        time = GetTimestamp(),
        defaultSort = para.defaultSort or 0,
    }

    table.insert(wndList, data)
    table.sort(wndList, function(a, b)
        local defaultSortA = a.defaultSort
        local defaultSortB = b.defaultSort
        if defaultSortA ~= defaultSortB then
            return defaultSortA < defaultSortB
        end

        local aSort = self:GetSort(a.uiName, a.attrId)
        local bSort = self:GetSort(b.uiName, b.attrId)
        if aSort ~= bSort then
            return aSort < bSort
        end

        return a.time < b.time
    end)

end

function ModelWndPop:RemovePopWnd(uiName, para)
    local wndList = self:GetWndList()
    local cnt = #wndList
    if cnt == 0 then
        return
    end
    for k = cnt, 1, -1 do
        local v = wndList[k]
        local find = false
        if v.uiName == uiName then
            if para then
                if v.para and para.refId == v.para.refId then
                    find = true
                end
            else
                find = true
            end
        end

        if find then
            table.remove(wndList, k)
        end
    end
end

function ModelWndPop:HasPopWnd()
    local curWndName = self:GetCurWndName(ModelWndPop.LAYER_1)
    if curWndName then
        return true
    end
    curWndName = self:GetCurWndName(ModelWndPop.LAYER_2)
    if curWndName then
        return true
    end

    local wndList = self:GetWndList()
    if #wndList > 0 then
        return true
    end

    return false
end

function ModelWndPop:HasAccountWnd()
    local wndList = self:GetWndList()
    for k, v in ipairs(wndList) do
        local temp = v.uiName
        if self._isAccountWnd[temp] then
            return true
        end
    end
    return false
end

function ModelWndPop:CheckStartGuide()
    if gModelGuide:IsJumpFeedScene() then
        LogWarn("正在直流")
        return
    end
    local isVideoAlive = gModelBattle:IsVideoAlive()  --正在播放战斗
    if isVideoAlive then
        return
    end
    local curWndName = self:GetCurWndName(ModelWndPop.LAYER_1)
    if curWndName then
        return
    end

    curWndName = self:GetCurWndName(ModelWndPop.LAYER_2)
    if curWndName then
        return
    end

    local wndList = self:GetWndList()
    for k, v in ipairs(wndList) do
        local temp = v.uiName
        if self._guideWaitPop[temp] then
            return
        end
    end

    FireEvent(EventNames.CHECK_WAIT_GUIDE)

end

function ModelWndPop:OnGuideStart()
    local curWndName = self:GetCurWndName(ModelWndPop.LAYER_1)
    if curWndName and self:NeedCloseOnGuide(curWndName) then
        GF.CloseWndByName(curWndName)
    end

    curWndName = self:GetCurWndName(ModelWndPop.LAYER_2)
    if curWndName and self:NeedCloseOnGuide(curWndName) then
        GF.CloseWndByName(curWndName)
    end
end

function ModelWndPop:NeedCloseOnGuide(curWndName)
    if not self._isAccountWnd[curWndName] and not self._guideExceptWnd[curWndName] then
        return true
    end
end

function ModelWndPop:GetWndBelongLayer(wndName)
    return self._wndLayerMap[wndName] or ModelWndPop.LAYER_1
end

return ModelWndPop