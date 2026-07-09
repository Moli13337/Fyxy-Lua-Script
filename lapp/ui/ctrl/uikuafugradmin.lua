---
--- Created by LCM.
--- DateTime: 2024/3/17 21:10:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuGradMin:LWnd
local UIKuafuGradMin = LxWndClass("UIKuafuGradMin", LWnd)

UIKuafuGradMin.TYPE_SHOP = 1
UIKuafuGradMin.TYPE_RANK = 2
UIKuafuGradMin.TYPE_REWARD = 3
UIKuafuGradMin.TYPE_GROUP = 4
UIKuafuGradMin.TYPE_REPORT = 5
UIKuafuGradMin.TYPE_FORMATION = 6
UIKuafuGradMin.TYPE_TEST = 7
UIKuafuGradMin.TYPE_PK = 8

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuGradMin:UIKuafuGradMin()
    self._countDownKey = "countDownKey"
    self._btnCountDownKey = "_btnCountDownKey"

    self._checkEmptyFormation = "_checkEmptyFormation"

    self._formationEffKey = "_formationEffKey"
    self._startBattleEffKey = "_startBattleEffKey"

    self._firstOpenSave = true

    self._clickStart = false

    self._fingerEffName = gModelCrossGrading:GetConfigByKey("fingerEffName") or "fx_ui_shou_2"

    self._respStatus = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuGradMin:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuGradMin:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    self:SetHideHurdle()
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuGradMin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    -- gModelCrossServer:CloseUIring()
    --self:CreateWndSpine(self.mSpPos,"Duanweisaiqizhi","Duanweisaiqizhi",false)

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self._clickNoRefresh = false
    self:InitUIEffect()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:Refresh()
    gModelCrossGrading:OnCrossRankMatchInfoReq()
    self:RefreshForeign()
end

function UIKuafuGradMin:RefreshBtnTimer()
    local intervalTime = gModelCrossGrading:GetMatchIntervalTime()
    self:SetBtnCountDown()
    if intervalTime then
        self:TimerStop(self._btnCountDownKey)
        self:TimerStart(self._btnCountDownKey, 1, false, -1)
    end
end
function UIKuafuGradMin:RefreshForeign()
    if self._isVie then
        self:SetAnchorPos(self.mHelpBtn, Vector2.New(130, -50))
    end
end

function UIKuafuGradMin:RunCountDownTimer()
    self:TimerStart(self._countDownKey, 1, false, -1)
end

function UIKuafuGradMin:RefreshChallengeStatus()
    local list, isEndGet, endNum = gModelCrossGrading:GetChallengeRewardList()
    local canGetStatus = false
    local refId, finishCond
    for i, v in ipairs(list) do
        if v.status == 1 then
            canGetStatus = true
            refId = v.refId
            finishCond = v.finishCond
            break
        end
    end
    self._canGetRefId = refId
    self._canGetStatus = canGetStatus

    local str = ""

    --local effectKey = "fx_baoxiang_paiweisai01"
    local effectKey = "fx_richangbaoxiang"
    if canGetStatus then
        self:CreateWndEffect(self.mBoxEff, effectKey, effectKey, 100, false, false)
    else
        self:DestroyWndEffectByKey(effectKey)
    end

    local dayBattleCount = gModelCrossGrading:GetBattleCount()
    if isEndGet and not finishCond then
        finishCond = list[#list].finishCond
        dayBattleCount = finishCond
    end
    if dayBattleCount > endNum then
        dayBattleCount = endNum
    end
    if not finishCond then
        finishCond = list[1].finishCond
    end
    str = string.format("%s/%s", dayBattleCount, finishCond)
    self:SetWndText(self.mScheduleNum, str)
end

function UIKuafuGradMin:StarMatchFunc()
    if not self._respStatus then
        return
    end
    if self._gameStartState then
        if not self._clickStart then
            GF.OpenWnd("UICrossGradingMatchTime")
            gModelCrossGrading:OnCrossRankBattleReq(function()
                self._clickStart = true
            end)

            self._clickNoRefresh = true
        else
            GF.ShowMessage(ccClientText(21843))
        end
    else
        GF.ShowMessage(ccClientText(21842))
    end
end

-- 战报事件
function UIKuafuGradMin:OnClickReportFunc()
    GF.OpenWndBottom("UIKuafuGradRecord")
end

function UIKuafuGradMin:OnTextFunc()
    --GF.OpenWnd("UIKuafuGradSeasonIdSow")
end

function UIKuafuGradMin:InitData()
    self._topBtnInfoList = {
        {
            icon = "kf_ladder_btn_2",
            btnName = ccClientText(21803), -- 商店
            func = function()
                self:OnClickShopFunc()
            end,
            target = UIKuafuGradMin.TYPE_SHOP,
        },
        {
            icon = "trial_btn_icon_2",
            btnName = ccClientText(21804), -- 排行
            func = function()
                self:OnClickRankFunc()
            end,
            target = UIKuafuGradMin.TYPE_RANK,
        },
        {
            icon = "trial_btn_icon_1",
            btnName = ccClientText(21805), -- 奖励
            func = function()
                self:OnClickRewardFunc()
            end,
            target = UIKuafuGradMin.TYPE_REWARD,
        },
        {
            icon = "public_btn_icon_12",
            btnName = ccClientText(17982), -- 分组
            func = function()
                self:OpenGroupWndFunc()
            end,
            target = UIKuafuGradMin.TYPE_GROUP,
        },
        {
            icon = "crossGrading_icon_3",
            btnName = ccClientText(16400), --"切磋", 								-- 分组
            func = function()
                self:OpenLevelPk()
            end,
            target = UIKuafuGradMin.TYPE_PK,
        },
        --[[		{
                    icon = "xxxxx",
                    btnName = ccClientText(21810), 								-- 阵容
                    func = function() self:OnTextFunc() end,
                    target = UIKuafuGradMin.TYPE_TEST,
                },]]
    }

    self._botBtnInfoList = {
        {
            icon = "public_btn_icon_23_1",
            btnName = ccClientText(21809), -- 战报
            func = function()
                self:OnClickReportFunc()
            end,
            target = UIKuafuGradMin.TYPE_REPORT,
        },
        {
            icon = "fight_icon_btn_9",
            btnName = ccClientText(21810), -- 阵容
            func = function()
                self:OnClickFormationFunc()
            end,
            target = UIKuafuGradMin.TYPE_FORMATION,
        },
    }

    self._btnTransList = {}
end

function UIKuafuGradMin:GetBoxRewardFunc()
    if self._canGetStatus and self._canGetRefId then
        gModelCrossGrading:OnCrossRankReceiveReq(ModelCrossGrading.CHALLENGE_REWARD, self._canGetRefId)
    else
        self:OnClickRewardFunc()
    end
end

function UIKuafuGradMin:OnTimer(key)
    if key == self._countDownKey then
        self:SetCountDown()
    elseif key == self._checkEmptyFormation then
        self:CheckEmptyFormation()
    elseif key == self._btnCountDownKey then
        self:SetBtnCountDown()
    end
end

function UIKuafuGradMin:OnDrawCommonBtnCell(list, item, itemdata, itempos)
    local Icon = self:FindWndTrans(item, "Icon")
    local BtnName = self:FindWndTrans(item, "BtnName")
    local redPoint = self:FindWndTrans(item, "redPoint")

    CS.ShowObject(redPoint, false)

    local target = itemdata.target
    local btnTransList = self._btnTransList
    if not btnTransList then
        btnTransList = {}
        self._btnTransList = btnTransList
    end
    btnTransList[target] = item

    local func = itemdata.func

    self:SetWndEasyImage(Icon, itemdata.icon, nil, true)
    self:SetWndText(BtnName, itemdata.btnName)

    --self:InitTextLineWithLanguage(BtnName,-40)

    self:SetWndClick(item, function()
        if func then
            func()
        end
    end)
end

function UIKuafuGradMin:InitBtnList(trans, list, onDrawFunc)
    list = list or {}

    onDrawFunc = onDrawFunc or function(...)
        self:OnDrawCommonBtnCell(...)
    end

    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            onDrawFunc(...)
        end)
    end
end

function UIKuafuGradMin:RefreshCrossRankMatchInfoResp()
    self._respStatus = true
    self:RefreshBtnTimer()
    self._clickStart = false
    local state = gModelCrossGrading:GetState()
    local isStar = state == ModelCrossGrading.GAME_START

    self:TimerStop(self._countDownKey)
    if isStar then
        self:SetCountDown(true)
        self:RunCountDownTimer()
    else
        self:SetWndText(self.mTextTime, ccClientText(21842))
    end

    self._gameStartState = isStar

    local intervalTime = gModelCrossGrading:GetMatchIntervalTime()
    local isGray = not isStar
    if intervalTime then
        isGray = true
    end
    self:SetWndButtonGray(self.mStarMatch, isGray)

    local key = self.mStarMatch:GetInstanceID()
    if isStar then
        self:CreateWndEffect(self.mStarMatch, "fx_ui_duanweisai_kaishipipei", key, 100, false, false)
    else
        self:DestroyWndEffectByKey(key)
    end
    CS.ShowObject(self.mRankImg, false)
    CS.ShowObject(self.mRankEff_1, false)
    CS.ShowObject(self.mRankEff_2, false)

    local sjNum = gModelCrossGrading:GetSeasonId()
    local sjNumStr = LUtil.FormatPowerNumSpriteText(sjNum)
    self:SetWndText(self.mSJNum, sjNumStr)
    CS.ShowObject(self.mSJDiv, true)
    CS.ShowObject(self.mSJImage, not gLGameLanguage:IsForeignRegion())

    local curScore = gModelCrossGrading:GetScore()
    local rank = gModelCrossGrading:GetRank()
    local ref = gModelCrossGrading:GetCurCrossGradingIntervalRef(curScore, rank)
    if not ref then
        return
    end

    local showReachMaxTip = gModelCrossGrading:CheckIsReachMaxRank(curScore, rank)
    CS.ShowObject(self.mUpRankTxt, showReachMaxTip)

    local nextStage = ref.nextStage

    local curName = ccLngText(ref.name)
    local curRankColor = ref.nameColor
    if not string.isempty(curRankColor) then
        self:SetXUITextTransColor(self.mRankNameTxt, curRankColor)
    end
    self:SetWndText(self.mRankNameTxt, curName)

    local upStr = ""
    local nextRank = ""
    local nextRef = gModelCrossGrading:GetCrossGradingIntervalByRefId(nextStage)
    if nextRef then
        local nextName = ccLngText(nextRef.name)
        local nextRankColor = "#" .. nextRef.nameColor
        nextName = LUtil.FormatColorStr(nextName, nextRankColor)

        nextRank = string.replace(ccClientText(21806), nextName)
        upStr = string.replace(ccClientText(21807), nextName)
    else
        upStr = string.replace(ccClientText(21859))
    end

    if nextStage == 0 then
        nextStage = ref.refId
    end
    local nextRewardRef = gModelCrossGrading:GetCrossGradingIntervalSplitByRefId(nextStage)
    if nextRewardRef then
        local rewardList = nextRewardRef.rewardList
        self:InitRewardList(rewardList)
    end

    self:SetWndText(self.mUpTxt, upStr)
    self:SetWndText(self.mNextRankDesc, nextRank)
    self:InitTextLineWithLanguage(self.mNextRankDesc, -30)
    self:InitTextSizeWithLanguage(self.mNextRankDesc, -2)

    self:SetWndEasyImage(self.mRankImg, ref.icon, function()
        CS.ShowObject(self.mRankImg, true)
        CS.ShowObject(self.mCenterDiv, true)
        local effKey_1 = "iconEffect_1"
        local effKey_2 = "iconEffect_2"
        self:DestroyWndEffectByKey(effKey)

        local iconEffect = ref.iconEffect
        if not string.isempty(iconEffect) then
            local effect = string.split(iconEffect, ",")

            self:CreateWndEffect(self.mRankEff_1, effect[1], effKey_1, 100, false, false, 50, function(dpTrans)
                dpTrans.gameObject:SetActive(true)
                CS.ShowObject(self.mRankEff_1, true)
            end)

            self:CreateWndEffect(self.mRankEff_2, effect[2], effKey_2, 100, false, false, 2, function(dpTrans)
                dpTrans.gameObject:SetActive(true)
                CS.ShowObject(self.mRankEff_2, true)
            end)
        end
    end, true)

    local scoreDown = ref.scoreDown
    local scoreUp = ref.scoreUp
    local isMaxRank = scoreUp == ModelCrossGrading.SCOREUP_MAX
    local curNum = curScore - scoreDown
    local maxNum = scoreUp - scoreDown
    local percent = curNum / maxNum
    if isMaxRank then
        curNum = curScore
        maxNum = scoreDown
        scoreUp = scoreDown
        percent = 1
    end
    LxUiHelper.SetProgress(self.mBar, percent)

    --local numStr = string.format("%s / %s",curNum,maxNum)
    local numStr = string.format("%s / %s", curScore, scoreUp)
    self:SetWndText(self.mBarNum, numStr)

    local numScale = curScore / scoreUp
    numScale = numScale > 1 and 1 or numScale
    local width = 153 * numScale
    self.mBar.sizeDelta = Vector2.New(width, 17.1)

    local teamCount = gModelCrossGrading:GetTeamCount()
    local str = string.replace(ccClientText(21834), teamCount)
    self:SetWndText(self.mGroupNumTxt, str)

    self:RefreshChallengeStatus()

    self:RunCheckFormationTimer()

    if self._firstOpenSave then
        self._firstOpenSave = false
        local num = gModelCrossGrading:CheckIsUpScore()
        local effKey = "upKey"
        self:DestroyWndEffectByKey(effKey)
        if num == 1 then
            printInfoNR("================ 提升经验")
        end
    end

    local status = gModelCrossGrading:IsNeedShowCrossGradingSeasonId()
    if status then
        gModelCrossGrading:OnCrossRankBalanceInfoReq()
    else
        gModelCrossGrading:TryOpenGroupWndForeignPop()
    end
end

function UIKuafuGradMin:InitText()
    self:SetWndText(self.mTitle, ccClientText(21800))
    self:SetWndText(self.mScheduleDesc, ccClientText(21818))
    self:SetWndText(self.mUpRankTxt, ccClientText(21857))
    self:InitTextLineWithLanguage(self.mUpRankTxt, -30)
    self:InitTextSizeWithLanguage(self.mUpRankTxt, -2)
    self:RefreshBtnTimer()
end

function UIKuafuGradMin:OnDrawRewardCell(list, item, itemdata, itempos)
    local CommonIcon = self:FindWndTrans(item, "CommonIcon")
    local Icon = self:FindWndTrans(CommonIcon, "Icon")

    local itemType, itemId, itemNum = itemdata.itemType, itemdata.itemId, itemdata.itemNum
    local InstanceID = item:GetInstanceID()

    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(Icon)
    baseClass:SetCommonReward(itemType, itemId, itemNum)
    baseClass:DoApply()

    self:SetWndClick(CommonIcon, function()
        gModelGeneral:OpenItemInfoTipTop(itemId, itemNum)
    end)
end

-- 排行榜事件
function UIKuafuGradMin:OnClickRankFunc()
    GF.OpenWndBottom("UIRkPop", { refId = ModelRank.RANK_CROSSGRADING })
end

function UIKuafuGradMin:InitUIEffect()
    self:CreateWndEffect(self.mBg1, "fx_ui_duanweisai_beijing", "fx_ui_duanweisai_beijing", 90, false, false, 1, function(dpTrans)
        dpTrans.gameObject:SetActive(true)
    end)
end

function UIKuafuGradMin:RunCheckFormationTimer()
    self:DestroyWndEffectByKey(self._formationEffKey)
    self:DestroyWndEffectByKey(self._startBattleEffKey)
    local showFormationFingerTime = gModelCrossGrading:GetConfigByKey("fingerEffTime") or 5
    self:TimerStop(self._checkEmptyFormation)
    self:TimerStart(self._checkEmptyFormation, showFormationFingerTime, false, -1)
end

function UIKuafuGradMin:OpenLevelPk()
    GF.OpenWnd("UILvPk")
end

function UIKuafuGradMin:SetCountDown(isNotSend)
    local timeStr = ""
    local endTime = gModelCrossGrading:GetEndTime()
    if not endTime then
        self:SetWndText(self.mTextTime, timeStr)
        self:TimerStop(self._countDownKey)
        return
    end
    local curTime = GetTimestamp()
    local timeLeft = endTime - curTime
    if timeLeft <= 0 then
        self:SetWndText(self.mTextTime, timeStr)
        self:TimerStop(self._countDownKey)
        if not isNotSend then
            gModelCrossGrading:OnCrossRankMatchInfoReq()
        end
        return
    end
    local isOpen = gModelCrossGrading:IsCrossGradingOpen()
    if isOpen then
        timeStr = string.replace(ccClientText(17510), LUtil.FormatTimespanCn(timeLeft))
    else
        local isEnd = gModelCrossGrading:IsCrossGradingEnd()
        if isEnd then
            timeStr = ccClientText(21842)
            self:TimerStop(self._countDownKey)
        else
            timeStr = string.replace(ccClientText(17511), LUtil.FormatTimespanCn(timeLeft))
        end
    end
    self:SetWndText(self.mTextTime, timeStr)
end

function UIKuafuGradMin:Refresh()
    self:InitBtnList(self.mTopBtnList, self._topBtnInfoList)
    self:InitBtnList(self.mBotBtnList, self._botBtnInfoList)
end

-- 阵容事件
function UIKuafuGradMin:OnClickFormationFunc()
    local teamCount = gModelCrossGrading:GetTeamCount()
    local para = {
        teamCount = teamCount,
        setTargetType = LCombatTypeConst.COMBAT_CROSSGRADING_RANK,
        returnFunc = function()
            local returnFunc = gModelBattle:GetReturnFun(LCombatTypeConst.COMBAT_CROSSGRADING_RANK)
            if returnFunc then
                returnFunc()
            end
        end,
        retAfterSet = teamCount <= 1

    }
    gModelFormation:OpenMultiOnlySet(para)
end

function UIKuafuGradMin:OpenGroupWndFunc()
    gModelCrossGrading:OpenGroupWndPop()
end

-- 奖励事件
function UIKuafuGradMin:OnClickRewardFunc()
    GF.OpenWnd("UIKuafuGradAwardSow")
end

-- 商店事件
function UIKuafuGradMin:OnClickShopFunc()
    GF.OpenWndBottom("UIDian", { shopId = 2009 })
end

function UIKuafuGradMin:CheckEmptyFormation()
    if not self._gameStartState then
        self:TimerStop(self._checkEmptyFormation)
        return
    end
    local inGuide = gModelGuide:IsInGuide()
    if inGuide then
        self:TimerStop(self._checkEmptyFormation)
        return
    end
    local isCreateEff = false
    local isEmptyFormation = gModelCrossGrading:CheckIsEmptyFormation()
    if isEmptyFormation then
        local btnTransList = self._btnTransList
        if btnTransList then
            local btnTrans = btnTransList[UIKuafuGradMin.TYPE_FORMATION]
            if btnTrans and not CS.IsNullObject(btnTrans) then
                isCreateEff = true
                local effRoot = self:FindWndTrans(btnTrans, "GameObject")
                self:CreateWndEffect(effRoot, self._fingerEffName, self._formationEffKey, 100, false, false)
            end
        end
    else
        isCreateEff = true
        self:CreateWndEffect(self.mStarMatchEffRoot, self._fingerEffName, self._startBattleEffKey, 100, false, false)
    end
    if isCreateEff then
        self:TimerStop(self._checkEmptyFormation)
    end
end

function UIKuafuGradMin:SetBtnCountDown()
    local state = gModelCrossGrading:GetState()
    local isStar = state == ModelCrossGrading.GAME_START
    local intervalTime = gModelCrossGrading:GetMatchIntervalTime()
    local str = ccClientText(21808)
    local isGray = false
    if intervalTime then
        isGray = true
        str = string.replace(ccClientText(21854), intervalTime)
    else
        self:TimerStop(self._btnCountDownKey)
    end
    if not isStar then
        isGray = true
    end
    self:SetWndButtonText(self.mStarMatch, str)
    self:SetWndButtonGray(self.mStarMatch, isGray)
    CS.ShowObject(self.mStarMatch, true)
end

function UIKuafuGradMin:InitRewardList(list)
    list = list or {}
    local uiRewardList = self._uiRewardList
    if uiRewardList then
        uiRewardList:RefreshList(list)
    else
        uiRewardList = self:GetUIScroll("uiRewardList")
        self._uiRewardList = uiRewardList
        uiRewardList:Create(self.mRewardList, list, function(...)
            self:OnDrawRewardCell(...)
        end)
    end
end

function UIKuafuGradMin:InitMsg()
    self:WndNetMsgRecv(LProtoIds.CrossRankMatchInfoResp, function()
        if self._clickNoRefresh then
        else
            self:RefreshCrossRankMatchInfoResp()
        end
    end)
    self:WndNetMsgRecv(LProtoIds.CrossRankReceiveResp, function()
        gModelCrossGrading:OnCrossRankMatchInfoReq()
    end)
    self:WndEventRecv(EventNames.NET_ERROR_CODE, function(code, error, argList)
        self._clickStart = false
    end)
end

function UIKuafuGradMin:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        local isFromJump = self:GetWndArg("isFromJump")
        if not self:WndCloseAndBack() and isFromJump then
            -- gModelCrossServer:OpenUIring(ModelCrossServer.CROSS_GRADING)
        else
            GF.OpenWndBottom("UIOutts",{ childIndex = 2 })
            FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
            self:WndClose()
        end
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mStarMatch, function()
        self:StarMatchFunc()
    end)
    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 90 })
    end)
    self:SetWndClick(self.mRankImg, function()
        GF.OpenWnd("UIKuafuGradSowList")
    end)
    self:SetWndClick(self.mBoxDiv, function()
        self:GetBoxRewardFunc()
    end)
end
------------------------------------------------------------------
return UIKuafuGradMin

