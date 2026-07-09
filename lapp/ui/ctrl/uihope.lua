---
--- Created by Administrator.
--- DateTime: 2023/10/27 16:41:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHope:LWnd
local UIHope = LxWndClass("UIHope", LWnd)
local typeof = typeof
local CS = CS
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

UIHope.BTN_SC = 1
UIHope.BTN_TS = 2
UIHope.BTN_XQ = 3
UIHope.BTN_PH = 4
UIHope.BTN_ALLSHOW = 5
UIHope.BTN_SHOP = 6

UIHope.ICON_NUM = 20

--- 单次创建 icon 的个数
UIHope.ICON_ONCECREATENUM = 7

UIHope.ICON_POINTS = {
    Vector3(0.022, -0.028, 0),
    Vector3(-0.037, -0.021, 0),
    Vector3(-0.060, 0.042, 0),
    Vector3(0.010, 0.031, 0),
    Vector3(0.050, 0.010, 0),
}


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHope:UIHope()
    self._countDownKey = "_countDownKey"
    self._effectKey = "_effectKey"
    self._effectForkKey = "_effectForkKey"
    self._showYLZXEffKey = "_showYLZXEffKey"
    self._onDragCameraKey = "onDragCameraKey"
    self._updateShowRewardTimeKey = "_updateShowRewardTimeKey"

    self._isDoInit = true

    self._errorClickNum = 0

    ---@type UIObjPool
    self._objPool = nil

    ---@type UIObjPool
    self._objRewardPool = nil

    ---@type table
    self._objRewardMap = {}

    self:SetHideHurdle()
    self:SetHideTop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHope:OnWndClose()
    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end

    if gLGameTouch then
        gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_WONDER)
    end

    if self._objPool then
        self._objPool:DestroyAllObj()
        self._objPool = nil
    end

    if self._objRewardPool then
        self._objRewardPool:DestroyAllObj()
        self._objRewardPool = nil
    end

    if self._roleObj then
        self._roleObj:Destroy()
        self._roleObj = nil
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHope:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHope:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitText()
    self:InitEffect()
    self:InitChuanDuoSp()
    self:InitDragCameraTimer()

    self:CreateObjPool()

    self:InitData()
    self:InitEvent()
    self:InitMsg()
    self:InitBtnList()
    self:Refresh()
    CS.ShowObject(self.mBoxBg, false)
    -- local priviCom = self:GetPrivilegeCom()
    -- priviCom:Create(self.mBtnPrivile, 3, self)
    self:RefreshSettingAutoRunStatus()
    self:RefreshForeign()
end

--- 自动奖励 移动
function UIHope:OnFDTEventMovePos(rollData)
    if not rollData then return end
    if not self:IsWndValid() then return end
    self:PlayForkMoveAni(rollData, function()
        gLGpManager:FindFastDreamTripGp():SetRollPathMovePlayer(rollData)
    end)
end

function UIHope:DreamItemWnd()
    --[[	local index = math.random(6,119)
        FireEvent(EventNames.ON_DREAMTRIP_TEST,index)]]
end

function UIHope:DreamHelpWnd()
    GF.OpenWnd("UIHopeGameBz")
end

function UIHope:CreateObjPool()
    self._iconTempList = {}

    self._objPool = UIObjPool:New()
    self._objPool:Create(self.mIconTempRoot, self.mMoveIconTemp)

    self._objRewardPool = UIObjPool:New()
    self._objRewardPool:Create(self.mShowRewardTempRoot, self.mShowRewardTemp)
end

function UIHope:PlayNumShow(rollData)
    if not self:IsWndValid() then return end
    local seqTween
    self:TweenSeqKill(self._effectKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._effectKey, function(seq)
            local effectVanish = self:GetEffectVanish()
            seq:AppendInterval(effectVanish)
            seq:AppendCallback(function()
                CS.ShowObject(self.mChuanduo, false)
            end)
            --[[local trans = self.mGoToNumBg
            local showTxtTime = 0.1
            local Ease = DG.Tweening.Ease.OutCubic
            local canvasGroup = trans:GetComponent(typeofCanvasGroup)
            seq:AppendCallback(function()
                CS.ShowObject(trans,true)
            end)
            local show = YXTween.TweenFloat(0, 1, showTxtTime, function(ival)
                canvasGroup.alpha = ival
            end):SetEase(Ease)
            seq:Append(show)]]
            seq:AppendCallback(function()
                gLGpManager:FindFastDreamTripGp():SetRollPlayer(rollData)
            end)
            seq:AppendInterval(0.8)
            --[[			local hide = YXTween.TweenFloat(1, 0, showTxtTime, function(ival)
                            canvasGroup.alpha = ival
                        end):SetEase(Ease)
                        seq:Append(hide)]]
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._effectKey)
        CS.ShowObject(self.mGoToNumBg, false)
    end)
end

function UIHope:DreamShopWnd()
    GF.OpenWnd("UIDian", { shopId = 2013 })
end

function UIHope:GetPlayModuleBelong()
    return LPlayModuleConst.TRAVEL
end

function UIHope:CloseWnd()
    GF.ChangeMap("LCityMap")
    if not self:WndCloseAndBack() then
        GF.OpenWndBottom("UIOutts")
        local ref = GameTable.DailyGamePlayRef[103]
        local group = ref and ref.group
        if group and group > 0 then
            GF.OpenWnd("UIOuttsList", { listRefId = group })
        end
    end
    self:WndClose()
end

function UIHope:ClearDreamTrip()
    gModelFastDreamTrip:StartReqDreamTripInfo()
    self:CloseWnd()
end

function UIHope:OnFDTRefreshEventInfo(config)
    gLGpManager:FindFastDreamTripGp():UpdateUnitViewGridData(config)
end

function UIHope:InitData()

    self._mapId = self:GetWndArg("mapId")
    local themeCfg = gModelFastDreamTrip:GetMapRefByMapId(self._mapId)
    local str = ccClientText(20400)
    if themeCfg then
        str = ccLngText(themeCfg.name)
    end
    self:SetWndText(self.mTitle, str)

    self._btnInfoList = {
        {
            btnImg = "trial_btn_icon_2",
            btnName = ccClientText(20401),
            index = UIHope.BTN_SC,
            func = function()
                self:DreamHelpWnd()
            end,
        },
        --[[		{
                    btnImg = "public_btn_icon_17",
                    btnName = ccClientText(20402),
                    index = UIHope.BTN_TS,
                    func = function() self:ShowNewGoToNumEff(6,4) end,
                },]]
        --[[		{
                    btnImg = "timecopy_icon_4",
                    btnName = ccClientText(20403),
                    index = UIHope.BTN_XQ,
                    func = function() self:DreamHeroWnd() end,
                },]]
    }


    --[[	if gModelFunctionOpen:CheckIsShow(17100100) then
            table.insert(self._btnInfoList, {
                btnImg = "trial_btn_icon_2",
                btnName = ccClientText(20404),
                index = UIHope.BTN_PH,
                func = function() self:DreamRankWnd() end,
            })
        end]]

    local otherBtnInfo = {
        btnImg = "trial_btn_icon_1",
        btnName = ccClientText(20477),
        index = UIHope.BTN_ALLSHOW,
        func = function()
            self:DreamAllShowWnd()
        end,
    }
    table.insert(self._btnInfoList, otherBtnInfo)

    --[[	local shopBtnInfo = {
            btnImg = "wonderland_icon_btn_2",
            btnName = ccClientText(20487),
            index = UIHope.BTN_SHOP,
            func = function() self:DreamShopWnd() end,
        }
        table.insert(self._btnInfoList, shopBtnInfo)]]

    self._isForeign = gLGameLanguage:IsForeignVersion()

    self:SetCountDown()
    local endTime = gModelFastDreamTrip:GetCountDownTime()
    if endTime then
        endTime = tonumber(endTime) / 1000
        if endTime > GetTimestamp() then
            self:TimerStop(self._countDownKey)
            self:TimerStart(self._countDownKey, 1, false, -1)
        end
    end
    self:SetWndText(self.mMapLv, string.replace("Lv.#a1#", gModelFastDreamTrip:GetDreamTripMapLevel()))
end

function UIHope:OnFDTEventFinish(recordFinishMap, pb, hasAutoGet)
    --if hasAutoGet then
    --end
    self._saveItemNum = gModelItem:GetNumByRefId(ModelItem.ITEM_DIAMOND)
    if LOG_INFO_ENABLED then
        printInfoNR2("梦境之旅：","当前数量：" .. self._saveItemNum)
    end
    gLGpManager:FindFastDreamTripGp():ShowBattleTargetShow()
end

function UIHope:InitEvent()
    self:SetWndClick(self.mBoxBg, function()
        self:OnClickBoxBgFunc()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mReturnBtn, function()
        self:CloseWnd()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mDiceBtn, function()
        self:OnClickDiceBtnFunc()
    end)
    -- 帮助文档
    self:SetWndClick(self.mHelpBtn, function()
        gModelFastDreamTrip:OpenMapHelpTips(self._mapId)
    end)
    self:SetWndClick(self.mShowItemDiv, function()
        gModelGeneral:OpenGetWayWnd({
            itemId = gModelFastDreamTrip:GetMainWndShowPayItem(),
            srcWnd = self:GetWndName()
        })
    end)
    self:SetWndClick(self.mDirIcon, function()
        self:GoToPlayerPos()
    end)
end

--- 摇骰子动画
function UIHope:PlayRollAni(rollNum, func)
    local chuandaoSp = self._chuandaoSp
    if chuandaoSp then
        local callBackFunc = function()
            if not self:IsWndValid() then return end

            local spName = "fx_" .. rollNum
            chuandaoSp:PlayAnimationSolid(spName, false)
            chuandaoSp:SetAnimationCompleteFunc(func)
        end
        CS.ShowObject(self.mChuanduo, true)
        chuandaoSp:PlayAnimationSolid("fx_diuchu", false)
        chuandaoSp:SetAnimationCompleteFunc(callBackFunc)
    end
end

function UIHope:RefreshForeign()
    if self._isVie then
        local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)
        local itemRoot =CS.FindTrans(self.mBtnList,"ItemRoot")
        local csLayoutGrid = itemRoot:GetComponent(typeVerticalLayoutGroup)
        csLayoutGrid.spacing =30
    end
end

function UIHope:OnDragMap()
    if not gLGpManager then
        return
    end

    local rolePosition = gLGpManager:FindFastDreamTripGp():GetPlayerPosition()
    if not rolePosition then
        return
    end

    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local uiSceneCamrea = LGameUI.GetUICamera()
    local nodeViewPos = uiSceneCamrea:WorldToViewportPoint(self.mDirNode.position)
    local roleViewPos = sceneCamera:WorldToViewportPoint(rolePosition)
    local dirPos = roleViewPos - nodeViewPos

    local dirEulerAngles = self.mDirNode.eulerAngles
    dirEulerAngles.z = Mathf.Atan2(dirPos.y, dirPos.x) * Mathf.Rad2Deg - 90
    self.mDirNode.eulerAngles = dirEulerAngles
end

function UIHope:OnTimer(key)
    if key == self._countDownKey then
        self:SetCountDown()
    elseif key == self._onDragCameraKey then
        self:OnDragMap()
    elseif key == self._updateShowRewardTimeKey then
        self:UpdateShowRewardPos()
    end
end

function UIHope:InitText()
    self:SetWndText(self.mAutoRunTxt, ccClientText(36422))

    self:SetTextTile(self.mDiceBtn, ccClientText(41413))
end

function UIHope:Refresh(showNum)
    local refId = gModelFastDreamTrip:GetMainWndShowPayItem()
    if not self._initIcon then
        local icon = gModelItem:GetItemIconByRefId(refId)
        if icon then
            self:SetWndEasyImage(self.mItemIcon, icon)
        end
        self._initIcon = true
    end
    local haveNum = showNum or gModelItem:GetNumByRefId(refId)
    self:SetWndText(self.mItemNumTxt, haveNum)
end

--- 摇骰子 移动
function UIHope:OnFDTRollNormal(rollData)
    self:ShowNewGoToNumEff(rollData)
end

function UIHope:OnClickDiceBtnFunc()
    if self._isDoInit then
        if gLGpManager:FindFastDreamTripGp():GetLoadFinishState() then
            self._isDoInit = false
        else
            if self._errorClickNum < 2 then
                self._errorClickNum = self._errorClickNum + 1
                GF.ShowMessage(ccClientText(20458))
                return
            end
        end
    end
    if not gLGpManager:FindFastDreamTripGp():CheckIsCanRoll() then
        GF.ShowMessage(ccClientText(20459))
        return
    end
    gLGpManager:FindFastDreamTripGp():MoveCameraToPlayer()
    if gModelFastDreamTrip:CheckIsExecute() then
        local index = gModelFastDreamTrip:GetDreamTripIndex()
        gLGpManager:FindFastDreamTripGp():ExecuteClick(index)
        return
    end

    -- 骰子声音
    local isDice2 = gModelFastDreamTrip:CheckCurMapIsDice2()
    local soundRefId = isDice2 and 303 or 302
    gModelFastDreamTrip:PlayDreamTripSound(soundRefId)

    gModelFastDreamTrip:OnDreamTripRollReq()
end

function UIHope:SetGoToNumStr(rollData, params)
    --- 仅需要摇骰子动画，无飘字
    if true then
        return
    end
    local str
    local isSwamp = rollData.isSwamp == 1 and true or false
    if isSwamp then
        params = params or {}
        local faceNum = params.faceNum or 0
        local lastIndex = params.lastIndex or 0
        str = string.replace(ccClientText(20481), faceNum, faceNum, faceNum - lastIndex)
    else
        if not rollData.roll then
            return false
        end
        str = string.replace(ccClientText(20433), rollData.roll)
    end
    self:SetWndText(self.mGoToNum, str)
    self:SetWndText(self.mGoToNumEn, str)

    CS.ShowObject(self.mGoToNumEn, self._isForeign)
    CS.ShowObject(self.mGoToNum, not self._isForeign)
    return true
end

function UIHope:RefreshEndMapReward()
    --- 终点事件变成打怪
    local status = gModelFastDreamTrip:IsLastGrid()
    if status then
        self:ShowBoxEff()
    end
end

function UIHope:GoToPlayerPos()
    if not gLGpManager then
        return
    end

    local rolePosition = gLGpManager:FindFastDreamTripGp():GetPlayerPosition()
    if not rolePosition then
        return
    end

    local pos, func = gLGpManager:FindFastDreamTripGp():GetPlayerPositionAndMoveFunc()
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local roleViewPos = sceneCamera:WorldToViewportPoint(rolePosition)
    local runFunc = true
    if self._oldPos then
        local tpos = sceneCamera:WorldToViewportPoint(pos)
        if tpos == self._oldPos then
            runFunc = false
        end
    end
    if runFunc then
        if func then
            func()
        end
    else
        GF.ShowMessage(ccClientText(20467))
    end
    roleViewPos = sceneCamera:WorldToViewportPoint(rolePosition)
    self._oldPos = roleViewPos
end

function UIHope:ShowGetEff(data)
    data = data or {}

    local isNotTarget = data.isNotTarget
    if not isNotTarget then
        --- 动画自己播自己的，下一步也可以继续执行
        gLGpManager:FindFastDreamTripGp():SetFSMNormalState()
        self:CheckHasDiceCount()
    end

    CS.ShowObject(self.mShowRewardDiv, false)

    local rewardList = data.rewardList
    local showRewardDiv
    local showRewardDivTrans
    local needHide = rewardList and #rewardList > 0
    local hasItemNum = 0
    local showNum
    if needHide then
        local firstData = rewardList[1]
        local itemId = firstData.itemId
        showRewardDiv = self._objRewardPool:GetObj()
        if showRewardDiv then
            hasItemNum = self._recordHasNum
            if not hasItemNum then
                hasItemNum = self._saveItemNum or gModelItem:GetNumByRefId(itemId)
            end

            showNum = firstData.itemNum
            if LOG_INFO_ENABLED then
                printInfoNR2("梦境之旅：", "itemId = " .. itemId .. ",hasItemNum = " .. hasItemNum .. ",showNum = " .. showNum ..
                        ",加成功后 = " .. showNum + hasItemNum)
            end

            showRewardDivTrans = showRewardDiv.transform
            showRewardDivTrans:SetParent(self.mShowRewardTempRoot, false)
            local iconPath = gModelItem:GetItemIconByRefId(itemId)
            local ShowRewardIcom = self:FindWndTrans(showRewardDivTrans, "GameObject/GameObject/ShowRewardIcom")
            self:SetWndEasyImage(ShowRewardIcom, iconPath, function()
                CS.ShowObject(ShowRewardIcom, true)
            end, true)
            local ShowRewardNum = self:FindWndTrans(showRewardDivTrans, "GameObject/ShowRewardNum")
            self:SetWndText(ShowRewardNum, string.replace("+#a1#", LUtil.NumberCoversion(showNum)))
            CS.ShowObject(showRewardDivTrans, true)
        end


        --[[		local iconPath = gModelItem:GetItemIconByRefId(itemId)
                self:SetWndEasyImage(self.mShowRewardIcom,iconPath,function()
                    CS.ShowObject(self.mShowRewardIcom,true)
                end,true)
                self:SetWndText(self.mShowRewardNum,string.replace("+#a1#",firstData.itemNum))
                CS.ShowObject(self.mShowRewardDiv,true)]]
    end

    showNum = showNum + hasItemNum

    if data.autoGet then
        self._recordHasNum = showNum
    end

    local transKey
    local scale = 0.5
    --self:SetIconTempPos()
    local key = GetTimestamp()
    local seqTween
    self:TweenSeqKill(key)
    local recordIconList = {}
    if not seqTween then
        local unitTransPosition
        if data.index then
            unitTransPosition = gLGpManager:FindFastDreamTripGp():GetGridUnitPosByIndex(data.index)
        else
            unitTransPosition = gLGpManager:FindFastDreamTripGp():GetPlayerPosition()
        end
        local sceneCamera = gLGameScene:GetCurrentSceneCamera()
        local uiSceneCamrea = LGameUI.GetUICamera()
        local screenPos = sceneCamera:WorldToScreenPoint(unitTransPosition)
        local worldPos = uiSceneCamrea:ScreenToWorldPoint(screenPos)
        local nodeX, nodeY, nodeZ = worldPos.x, worldPos.y, 0
        --self.mShowRewardDiv.position = Vector3(nodeX,nodeY + 0.25,nodeZ)
        if showRewardDivTrans then
            showRewardDivTrans.position = Vector3(nodeX, nodeY + 0.1, nodeZ)
            if data.index then
                transKey = showRewardDivTrans:GetInstanceID()
                self._objRewardMap[transKey] = {
                    index = data.index,
                    trans = showRewardDivTrans,
                    obj = showRewardDiv
                }
            end
        end
        local endPos = self.mEndPos.position
        local moveTime1 = 0.5
        local moveTime2 = moveTime1 + 0.2
        local pos = UIHope.ICON_POINTS
        seqTween = self:TweenSeqCreate(key, function(seq)
            CS.ShowObject(self.mIconTempRoot, true)
            CS.ShowObject(self.mShowRewardTempRoot, true)
            local iconScaleTime = 0.1
            local tempTime = 0
            local addPos, tempPos
            local index = 1

            seq:InsertCallback(0.5, function()
                if showRewardDivTrans then
                    CS.ShowObject(showRewardDivTrans, false)
                end
                if transKey then
                    if self._objRewardMap[transKey] and self._objRewardMap[transKey].obj then
                        self._objRewardPool:ReturnObj(self._objRewardMap[transKey].obj)
                    end
                    self._objRewardMap[transKey] = nil
                end
            end)

            local refId = gModelFastDreamTrip:GetMainWndShowPayItem()
            local icon = gModelItem:GetItemIconByRefId(refId)

            for i = 1, UIHope.ICON_ONCECREATENUM do
                local itemNew = self._objPool:GetObj()
                table.insert(recordIconList, itemNew)
                local itemTrans = itemNew.transform

                itemTrans:SetParent(self.mIconTempRoot, false)
                CS.ShowObject(itemTrans, false)
                self:SetWndEasyImage(itemTrans, icon)
                itemTrans.localScale = Vector3.zero
                itemTrans.position = Vector3(nodeX, nodeY, nodeZ)

                tempTime = iconScaleTime * (i - 1)

                CS.ShowObject(itemTrans, true)

                seq:Insert(tempTime, itemTrans:DOScale(Vector3(scale, scale, scale), 0.5))
                if not pos[index] then
                    index = 1
                end
                addPos = pos[index]
                tempPos = Vector3(addPos.x + nodeX, addPos.y + nodeY, addPos.z + nodeZ)
                seq:Insert(tempTime, itemTrans:DOMove(tempPos, moveTime1))
                seq:Insert(tempTime + moveTime2, itemTrans:DOMove(endPos, 1))
                index = index + 1
            end

            gModelFastDreamTrip:PlayDreamTripSound(308)

            --[[			for i,v in ipairs(self._iconTempList) do
                            v.position = Vector3(nodeX,nodeY,nodeZ)
                            tempTime = iconScaleTime * i
                            seq:Insert(tempTime,v:DOScale(Vector3(scale,scale,scale),0.5))
                            if not pos[index] then
                                index = 1
                            end
                            addPos = pos[index]
                            tempPos = Vector3(addPos.x + nodeX,addPos.y + nodeY,addPos.z + nodeZ)
                            CS.ShowObject(v,true)
                            seq:Insert(tempTime,v:DOMove(tempPos,moveTime1))
                            seq:Insert(tempTime + moveTime2,v:DOMove(endPos,1))
                            index = index + 1
                        end]]
            return seq
        end)
    end
    seqTween:OnComplete(function()
        self:Refresh(showNum)
        self:TweenSeqKill(key)
        for i, v in ipairs(recordIconList) do
            CS.ShowObject(v, false)
            self._objPool:ReturnObj(v)
        end
        if data.isEnd then
            self._recordHasNum = nil
        end
        --CS.ShowObject(self.mIconTempRoot,false)
        --CS.ShowObject(self.mShowRewardDiv,false)
    end)
    seqTween:PlayForward()
end

function UIHope:UpdateShowRewardPos()
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local uiSceneCamrea = LGameUI.GetUICamera()
    for k, v in pairs(self._objRewardMap) do
        local unitTransPosition = gLGpManager:FindFastDreamTripGp():GetGridUnitPosByIndex(v.index)
        local screenPos = sceneCamera:WorldToScreenPoint(unitTransPosition)
        local worldPos = uiSceneCamrea:ScreenToWorldPoint(screenPos)
        local nodeX, nodeY, nodeZ = worldPos.x, worldPos.y, 0
        v.trans.position = Vector3(nodeX, nodeY + 0.25, nodeZ)
    end
end

function UIHope:OnDreamTripGridAniEnd()
    self._isDoInit = false

    if gModelFastDreamTrip:CheckIsMapUpLevelState(self._mapId) then
        --gModelFastDreamTrip:SetMapUpLevelState(self._mapId)
        --gModelFastDreamTrip:RecordDTMapInfo()
        CS.ShowObject(self.mMapLvTxtImg, true)
        local aniKey = "mapDTUpLevel"
        local seqCom = self:GetSeqCom()
        local seq = seqCom:CreateSeq(aniKey)
        seq:AppendInterval(2)
        seq:OnComplete(function()
            CS.ShowObject(self.mMapLvTxtImg, false)
            self:TweenSeqKill(aniKey)
            self:CheckHasDiceCount()
        end)
        seq:PlayForward()
    else
        if not gModelFastDreamTrip:CheckIsExecute() then
            self:CheckHasDiceCount()
        end
        if gModelFastDreamTrip:CheckCurMapIsDice2() then
            self:CheckHasDiceCount()
        end
    end
    gModelFastDreamTrip:CheckIsEndPointFinish()
end

function UIHope:GetSettingAutoRunStatus()
    return gModelGameHelperAlleviation:CheckDreamTripIsAutoRun()
end

function UIHope:InitEffect()
    local starEff = "fx_chengjiu_jifen_1"
    self:CreateWndEffect(self.mStarPos, starEff, starEff, 100, false, false)
    local moveEff = "fx_chengjiu_jifen_2"
    self:CreateWndEffect(self.mMovePos, moveEff, moveEff, 100, false, false)
    local endEff = "fx_chengjiu_jifen_3"
    self:CreateWndEffect(self.mEndPos, endEff, endEff, 100, false, false)
    local upEff = "fx_ui_zuanshimijing_ditushengji"
    self:CreateWndEffect(self.mMapLvTxtImg, upEff, upEff, 100, false, false)
end

function UIHope:ShowBoxEff()
    if self:GetSettingAutoRunStatus() then
        return
    end
    CS.ShowObject(self.mBoxBg, true)
    local key = "boxEffKey"
    self:DestroyWndEffectByKey(key)
    self:CreateWndEffect(self.mBoxBg, "fx_qjtx_baoxiang", key, 100)
end

function UIHope:PlayForkMoveAni(rollData, moveFunc)
    if not self:IsWndValid() then return end

    local isShowRollAni = gModelFastDreamTrip:IsNeedShowRollAni()
    if isShowRollAni and rollData.isFlight then
        --- 飞行状态不做动画
        isShowRollAni = false
    end
    if isShowRollAni then
        self:SetGoToNumStr(rollData)
    end

    local forkTweeenFunc = function()
        if not self:IsWndValid() then return end

        local seqTween
        self:TweenSeqKill(self._effectForkKey)
        if not seqTween then
            seqTween = self:TweenSeqCreate(self._effectForkKey, function(seq)
                local effectVanish = self:GetEffectVanish()
                seq:AppendInterval(effectVanish)
                seq:AppendCallback(function()
                    CS.ShowObject(self.mChuanduo, false)
                end)

                --local trans = self.mGoToNumBg
                --local Ease = DG.Tweening.Ease.OutCubic
                --local canvasGroup = trans:GetComponent(typeofCanvasGroup)
                --seq:AppendCallback(function()
                --	CS.ShowObject(trans,true)
                --end)
                --local show = YXTween.TweenFloat(0, 1, 0.1, function(ival)
                --	canvasGroup.alpha = ival
                --end):SetEase(Ease)
                --seq:Append(show)

                seq:AppendCallback(function()
                    if moveFunc then
                        moveFunc()
                    end
                end)
                seq:AppendInterval(0.8)

                --local hide = YXTween.TweenFloat(1, 0, 0.1, function(ival)
                --	canvasGroup.alpha = ival
                --end):SetEase(Ease)
                --seq:Append(hide)

                return seq
            end)
        end
        seqTween:PlayForward()
        seqTween:OnComplete(function()
            self:TweenSeqKill(self._effectForkKey)
            CS.ShowObject(self.mGoToNumBg, false)
        end)
    end

    if isShowRollAni then
        self:PlayRollAni(rollData.roll, forkTweeenFunc)
    else
        moveFunc()
    end
end

function UIHope:InitMsg()
    --self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function (...)
    --	self:WndClose()
    --end)
    --self:WndEventRecv(EventNames.ON_DREAMTRIP_SHOWGOTONUM,function(num,faceNum,func,isSwamp)
    --	self:ShowNewGoToNumEff(num,faceNum,func,isSwamp)
    --end)
    --self:WndEventRecv(EventNames.On_Item_Change,function()
    --	self:Refresh()
    --end)
    --self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
    --	self._roll = false
    --end)
    --self:WndNetMsgRecv(LProtoIds.DreamTripRollResp,function()
    --end)
    --self:WndNetMsgRecv(LProtoIds.DreamTripHeroInfoResp,function()
    --	self:Refresh()
    --end)
    --
    --self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...)
    --	self:OnTargetWndClose(...)
    --end)
    --self:WndEventRecv(EventNames.ON_DREAMTRIP_REFRESHROLL,function (...)
    --	self._roll = false
    --end)
    self:WndEventRecv(EventNames.ON_DREAMTRIP_SHOWGET, function(...)
        self:ShowGetEff(...)
    end)
    self:WndEventRecv(EventNames.ON_DREAMTRIP_GRIDANIEND, function()
        self:OnDreamTripGridAniEnd()
    end)
    self:WndEventRecv(EventNames.ON_FDT_EVENT_BOMB, function(...)
        self:OnFDTEventBomb(...)
    end)
    self:WndEventRecv(EventNames.ON_FDT_REFRESH_EVENTINFO, function(...)
        self:OnFDTRefreshEventInfo(...)
    end)
    self:WndEventRecv(EventNames.ON_FDT_FORK_ENDFUNC, function(...)
        self:RefreshEndMapReward()
    end)
    self:WndEventRecv(EventNames.ON_FDT_EVENT_CLOSEUI, function(...)
        self:OnFDTEventCloseUI(...)
    end)
    self:WndEventRecv(EventNames.ON_FDT_EVENT_FINISH, function(...)
        self:OnFDTEventFinish(...)
    end)
    self:WndEventRecv(EventNames.ON_ACCOUNT_RELA_WND_CLOSE, function(...)
        self:OnBattleResult(...)
    end)



    self:WndEventRecv(EventNames.ON_FDT_EVENT_MOVEPOS, function(...)
        self:OnFDTEventMovePos(...)
    end)
    self:WndEventRecv(EventNames.ON_FDT_ROLL_NORMAL, function(...)
        self:OnFDTRollNormal(...)
    end)
    self:WndEventRecv(EventNames.ON_FDT_EVENT_FORKMP, function(...)
        self:OnFDTEventFormMP(...)
    end)
    self:WndEventRecv(EventNames.ON_FDT_FORK_MOVE, function(...)
        self:OnFDTForkMove(...)
    end)
end

function UIHope:InitDragCameraTimer()
    self:TimerStop(self._onDragCameraKey)
    self:TimerStart(self._onDragCameraKey, 0.1, false, -1)
    self:TimerStop(self._updateShowRewardTimeKey)
    self:TimerStart(self._updateShowRewardTimeKey, 0, false, -1)
end

function UIHope:ShowNewGoToNumEff(rollData)
    local isShowRollAni = gModelFastDreamTrip:IsNeedShowRollAni()
    if isShowRollAni and rollData.isFlight then
        --- 飞行状态不做动画
        isShowRollAni = false
    end
    if isShowRollAni then
        self:SetGoToNumStr(rollData, {
            faceNum = rollData.moveEndIdx - rollData.lastIndex,
            lastIndex = rollData.lastIndex,
        })
    end

    local playFunc = function()
        if not self:IsWndValid() then return end
        self:PlayNumShow(rollData)
    end
    if isShowRollAni then
        local roll = rollData.roll
        if not roll or roll < 0 then
            roll = rollData.moveEndIdx - rollData.lastIndex
        end
        self:PlayRollAni(roll, playFunc)
    else
        playFunc()
    end
end

function UIHope:SetIconTempPos()
    self.mIconTempRoot.localPosition = Vector3.zero
    for i, v in ipairs(self._iconTempList) do
        v.position = Vector3.zero
        v.localScale = Vector3.zero
    end
end

function UIHope:GetEffectVanish()
    local effectVanish = gModelFastDreamTrip:GetConfigByKey("effectVanish")
    effectVanish = effectVanish > 0 and effectVanish or 1
    return effectVanish
end

function UIHope:OnDrawBtnCell(list, item, itemdata, itempos)
    local Image = self:FindWndTrans(item, "Image")
    local icon = self:FindWndTrans(item, "icon")
    local UIText = self:FindWndTrans(item, "UIText")
    local redPoint = self:FindWndTrans(item, "redPoint")
    if Image then
        self:SetWndClick(Image, function()
            local func = itemdata.func
            if func then
                func()
            end
        end)
    end
    if icon then
        self:SetWndEasyImage(icon, itemdata.btnImg)
    end
    if UIText then
        self:SetWndText(UIText, itemdata.btnName)
    end
    if redPoint then
        local show = false
        CS.ShowObject(redPoint, show)
    end
end

function UIHope:DreamAllShowWnd()
    GF.OpenWnd("UIHopeAmass")
end

function UIHope:SetCountDown()
    local endTime = gModelFastDreamTrip:GetCountDownTime()
    if not endTime then
        self:SetWndText(self.mCountDown, "")
        self:TimerStop(self._countDownKey)
        self:ClearDreamTrip()
        return
    end
    endTime = tonumber(endTime) / 1000
    local timeLeft = endTime - GetTimestamp()
    if timeLeft < 0 then
        if LOG_INFO_ENABLED then
            printInfoN2("梦境之旅", ">> 结束时间小于当前系统时间，界面关闭 endTime:" .. endTime .. ",当前系统时间:" .. GetTimestamp())
        end
        self:TimerStop(self._countDownKey)
        self:ClearDreamTrip()
        return
    end

    local timeStr = LUtil.FormatTimespanNumber(timeLeft)
    --timeStr = LUtil.FormatColorStr(timeStr,"lightGreen")
    local str = ccClientText(16702) -- #a1#  後重置
    str = string.replace(str, timeStr)
    self:SetWndText(self.mCountDown, str)
end

--- 岔路 有自动奖励时 移动
function UIHope:OnFDTEventFormMP(rollData)
    if not rollData then return end
    if not self:IsWndValid() then return end
    self:PlayForkMoveAni(rollData, function()
        gLGpManager:FindFastDreamTripGp():SetRollPathListMovePlayer(rollData)
    end)
end

function UIHope:DreamHeroWnd()
    GF.OpenWnd("UIHopeSagaDet")
end

function UIHope:OnFDTEventCloseUI()
    self:CheckHasDiceCount()
    gModelFastDreamTrip:CheckIsEndPointFinish()
end

function UIHope:RefreshSettingAutoRunStatus()
    local isShowMask = self:GetSettingAutoRunStatus()
    CS.ShowObject(self.mSettingAutoRunMask, isShowMask)
    local aniKey = "autoTipsABCDEFGTween"
    local seqCom = self:GetSeqCom()
    local canvasGroup = self:GetCanvasGroup(self.mAutoRunTxtBg)
    if isShowMask then
        local seq = seqCom:CreateSeq(aniKey)
        canvasGroup.alpha = 0.5
        local tween = canvasGroup:DOFade(1, 0.5):SetEase(DG.Tweening.Ease.InSine)
        seq:Append(tween)
        tween = canvasGroup:DOFade(0.5, 0.5):SetEase(DG.Tweening.Ease.InSine)
        seq:Append(tween)
        seq:SetLoops(-1)
        seq:PlayForward()
    else
        canvasGroup.alpha = 0
        seqCom:DeleteSeq(aniKey)
    end
end

--- 岔路 移动
function UIHope:OnFDTForkMove(rollData)
    if not self:IsWndValid() then return end

    self:PlayForkMoveAni(rollData, function()
        gLGpManager:FindFastDreamTripGp():SetRollForkPlayer(rollData)
    end)
end

function UIHope:CheckHasDiceCount()
    printInfoNR2("梦境之旅:", "剩余骰子点数：" .. gModelFastDreamTrip:GetDreamTripDiceCount())
    gModelFastDreamTrip:CheckIsSaveRollCb()
end

function UIHope:OnFDTEventBomb(config)
    gLGpManager:FindFastDreamTripGp():SetFSMTPState()
    gLGpManager:FindFastDreamTripGp():DoPlayerTPAni(config)
end

function UIHope:OnClickBoxBgFunc()
    GF.OpenWnd("UIHopeEndAward")
    CS.ShowObject(self.mBoxBg, false)
end

function UIHope:OnBattleResult()
    self:Refresh(gModelItem:GetNumByRefId(ModelItem.ITEM_DIAMOND))
end

function UIHope:DreamRankWnd()
    GF.OpenWndBottom("UIRkPop", { refId = 1400, showRankType = 1 })
end

function UIHope:InitChuanDuoSp()
    local isDice2 = gModelFastDreamTrip:CheckCurMapIsDice2()
    local spineName = isDice2 and "Shaizidonghua_gaoji" or "Shaizidonghua"
    self._chuandaoSp = self:CreateWndSpine(self.mChuanduo, spineName, spineName, false, function()
        CS.ShowObject(self.mChuanduo, false)
    end)
end

function UIHope:InitBtnList()
    local uiBtnList = self._uiBtnList
    local list = self._btnInfoList

    --local tran = self._isEnus and self.mBtnList_enus or self.mBtnList

    local tran = self.mBtnList
    CS.ShowObject(tran, true)
    if uiBtnList then
        uiBtnList:RefreshList(list)
    else
        uiBtnList = self:GetUIScroll("uiBtnList")
        self._uiBtnList = uiBtnList
        uiBtnList:Create(tran, list, function(...)
            self:OnDrawBtnCell(...)
        end)
    end
end

------------------------------------------------------------------
return UIHope


