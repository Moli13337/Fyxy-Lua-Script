---
--- Created by BY.
--- DateTime: 2023/10/22 20:13:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWishColleWin:LWnd
local UIWishColleWin = LxWndClass("UIWishColleWin", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWishColleWin:UIWishColleWin()
    self._dreamSchoolTimeKey = "dreamSchoolTimeKey"
    self._tabTransList = {}
    self._tabList = {}
    self._redThemeList = {}
    self._logCellH = 26
    self._logSlideTime = "logSlideTime"
    self._moveKey = "moveKey"
    self._showYLZXEffKey = "_showYLZXEffKey"
    self._moveSpeed = 0.5
    self._runSpine = "runSpine"
    self._spineSpeed = 0.3
    self._taskSuperSpList = {}
    self._taskSuperSpineWaitTimeKey = "taskSuperSpineWaitTimeKey"
    self._taskSuperSpineShowTimeKey = "_taskSuperSpineShowTimeKey"
    self._taskSuperSpineShowTimeFuncList = {}
    self._taskSuperSpName = "Mengjingxueyuan_tiezhi"
    --self._needPlayTaskSuperSp = true
    self._taskSuperSpNum = 0
    --self._isFirstLoad = true
    self._rankKeyTime = "_rankKeyTime"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWishColleWin:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWishColleWin:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWishColleWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    
    self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsJapanVersion()
    self._isJapaness  =gLGameLanguage:IsJapanVersion()
    if self._isEnus or self._isJapaness then 
        self:SetAnchorPos(self.mRankTimeDiv,Vector2.New(9.5,-40))
    end


    self._isVie = gLGameLanguage:IsVieVersion()
    if gModelCallHero:CheckIsExamineSex(self:GetWndName()) then
        --todo 暂时屏蔽
        CS.ShowObject(self.mSpine1,false)
        CS.ShowObject(self.mSpine2,false)
    end
    
    self:SetWndText(self.mTitle, ccClientText(20300))
    LxUiHelper.PlayAudioSoundName(LSoundConst.DREAM_SCHOOL_TASK)
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    FireEvent(EventNames.ON_OPEN_DREAM_COLLEGE)
    self:RegisterRedPointFunc(ModelRedPoint.DREAM_SCHOOL_THEME, function()
        self:RefreshThemeRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.DREAM_SCHOOL_TASK, function()
        self:RefreshThemeRed()
    end)
end

function UIWishColleWin:InitEvent()
    self:SetWndClick(self.mBtnHelp, function(...)
        self:OnClickHelp()
    end)
    self:SetWndClick(self.mBtnRank, function(...)
        self:OnClickRank()
    end)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnBox, function()
        self:OnClickBox()
    end)

    self:SetWndText(self.mTxtClose, ccClientText(30205))
end

function UIWishColleWin:SetMaskDate(item, itemdata, itempos)
    local mask = CS.FindTrans(item, "Mask")
    local isGet = gModelDreamSchool:GetIsGetGoalRewardByRefId(itemdata.refId)
    CS.ShowObject(mask, isGet)
end

function UIWishColleWin:RefreshDate()
    local refId = self._refId
    if not refId then
        return
    end

    local ref = gModelDreamSchool:GetSchoolThemeRefByRefId(refId)
    if not ref then
        return
    end

    local showRank = gModelDreamSchool:CheckShowRank(refId)

    self._ref = ref
    local showLH = string.split(ref.showLH, "|")
    self:SetSpine(self.mSpine1, showLH[1], ref, 1)
    if #showLH > 1 then
        self:SetSpine(self.mSpine2, showLH[2], ref, 2)
    end
    self._redTaskList = {}

    local itemId = ref.itemId
    local itemNum = gModelItem:GetNumByRefId(itemId)
    local stateEndRef = gModelDreamSchool:GetStageEndByThemeStage(ref.refId, 1)

    local _stageType = self._stageType
    if _stageType == nil then
        if not stateEndRef then
            self._stageType = 1
        else
            local isState = itemNum >= stateEndRef.target
            self._stageType = isState and 2 or 1
            self:OnRefreshItemList()
        end
    end

    self._olditemNum = itemNum

    local list = gModelDreamSchool:GetSchoolThemeQuestRefs(ref.refId)
    self._taskTypeList = list
    if self._uiTaskTypeList then
        self._uiTaskTypeList:RefreshList(list)
    else
        self._uiTaskTypeList = self:GetUIScroll("taskType")
        self._uiTaskTypeList:Create(self.mTaskTypeSuper, list, function(...)
            self:TaskTypeListItem(...)
        end, UIItemList.SUPER)
        self._uiTaskTypeList:EnableScroll(false, false)
    end
    self._uiTaskTypeList:MoveToPos()

    self:RefreshTaskTypeRed()
    self:SetTaskItemDate(ref)

    if self._isFirstLoad then
        if not self._taskRefId then
            self._taskRefId = list[1].refId
        end
        self:TimerStart(self._taskSuperSpineWaitTimeKey, 0.4, false, 1)
    else
        self:OnClickTaskType(self._taskRefId or list[1].refId)
    end

    local _schoolInfos = gModelDreamSchool:GetSchoolInfos()
    local _schoolInfo = _schoolInfos[ref.refId]
    if not _schoolInfo then
        return
    end
    self._schoolInfo = _schoolInfo
    if ref.rankId > 0 and showRank then
        local rankRef = gModelRank:GetRankingRefData(ref.rankId)
        self:SetWndText(self.mRankName, ccLngText(rankRef.nameTitle))
        self:InitTextLineWithLanguage(self.mRankName, -30)
        self:InitTextLineWithLanguage(self.mRankText, -30)
        self:TimerStop(self._rankKeyTime)
        self:TimerStart(self._rankKeyTime, 1, false, -1)
        self:SetRankTime()
    end
    if self._isVie then
        self:InitTextLineWithLanguage(self.mRankName, 20)
    end
    CS.ShowObject(self.mBtnRank, ref.rankId > 0 and showRank)
    self._endTime = _schoolInfo.goalEndTime
    self:RefreshItemList()
    self:RefreshBox()
end

function UIWishColleWin:OnRefreshItemList()
    self:RefreshItemList()
end

function UIWishColleWin:ChangeSpine(key, bool)
    local dpSpine = self:FindWndSpineByKey(key)
    if dpSpine then
        local dpTrans = dpSpine:GetDisplayTrans()
        CS.ShowObject(dpTrans, bool)
    end
end

function UIWishColleWin:SetIconDate(item, itemdata, itempos)
    local itemIcon = CS.FindTrans(item, "ItemIcon")
    if not itemIcon then
        return
    end
    local isSpecail = false
    if itempos == 6 then
        local time = GetTimestamp()
        local endTime = self._endTime or 0
        local timespan = endTime / 1000 - time
        if (timespan > 0) then
            isSpecail = true
        end
    end
    local itemList = LxDataHelper.ParseItem(itemdata.rewardGeneral)
    local itemInfo = itemList[1]
    local icon = ""
    if isSpecail then
        icon = itemdata.rewardSpecailIcon
    else
        icon = gModelItem:GetItemIconByRefId(itemInfo.itemId)
        if itempos == 6 then
            itemIcon.sizeDelta = Vector2.New(70, 70)
        end
    end
    self:SetWndEasyImage(itemIcon, icon)
end

function UIWishColleWin:OnClickRank()
    --点击限时排行榜
    local rankRefId = self._ref and self._ref.rankId
    local refId = self._ref and self._ref.refId
    local _schoolInfo = self._schoolInfo
    if not rankRefId or not _schoolInfo then
        return
    end
    local func = function()
        GF.OpenWnd("UIWishColleWin")
    end
    local endTime = _schoolInfo.settlementRankTime / 1000
    local rewardList = gModelDreamSchool:GetSchoolRankRewardByTheme(refId)
    GF.OpenWndBottom("UIRkPop", { refId = rankRefId, rewardList = rewardList, callFunc = func, endTime = endTime })
    self:WndClose()
end

function UIWishColleWin:RunSpine()
    local _spineKeyList = self._spineKeyList
    if not _spineKeyList then
        return
    end
    if self._spine1key then
        self:SetRunSpineAin(self._spine1key)
    end
    if self._spine2key then
        self:SetRunSpineAin(self._spine2key)
    end
end

function UIWishColleWin:SetLogItem(item, itemdata, itempos)
    local text = CS.FindTrans(item, "UIText")
    local ref = gModelDreamSchool:GetSchoolTargetRefByRefId(itemdata.targetId)
    local playerName = itemdata.playerName
    local isGoalReward = itemdata.isGoalReward

    local str = ""
    local img = "dreamcollege_ui_1_2"
    if isGoalReward == 1 and ref.rewardSpecail ~= "" then
        img = "dreamcollege_ui_1_1"
        str = string.replace(ccClientText(20318), playerName, ccLngText(ref.rewardSpecailName))
    else
        local itemList = LxDataHelper.ParseItem(ref.rewardGeneral)
        local itemdate = itemList[1]
        local itemName = gModelItem:GetNameByRefId(itemdate.itemId)
        str = string.replace(ccClientText(20318), playerName, itemName .. "*" .. itemdate.itemNum)
    end
    self:SetWndText(text, str)
    --self:SetWndEasyImage(item,img)
end

function UIWishColleWin:InitItemList(list)
    local uiList = self:FindUIScroll("itemList")
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("itemList")
        uiList:Create(self.mItemList, list, function(...)
            self:OnDrawItemCell(...)
        end)
    end
    uiList:EnableScroll(true, true)
    if self._ref then
        local itemId = self._ref.itemId
        local num = gModelItem:GetNumByRefId(itemId)
        local index, isGet, isGetIndex
        for i, v in ipairs(list) do
            isGet = gModelDreamSchool:GetIsGetGoalRewardByRefId(v.refId)
            if num >= v.target and not isGet then
                index = i
                break
            end
            if isGet then
                isGetIndex = i
            end
        end
        if index and index > 5 then
            uiList:MoveToPos(index)
        elseif isGetIndex and isGetIndex > 5 then
            uiList:MoveToPos(isGetIndex)
        end
    end
end

function UIWishColleWin:ListItem(list, item, itemdata, itempos)
    local InstanceID = item:GetInstanceID()
    local bgImg = self:FindWndTrans(item, "Image")
    local spineRoot = self:FindWndTrans(item, "SpineRoot")
    local contentTrans = self:FindWndTrans(item, "Content")
    local contentMar = CS.FindTrans(contentTrans, "ContentMar")
    local titleText = CS.FindTrans(contentMar, "TitleText")
    local bar = CS.FindTrans(contentMar, "Bar")
    local scheduleText = CS.FindTrans(contentMar, "ScheduleText")
    local rewardList = CS.FindTrans(contentMar, "RewardList1")
    local btnGoTo = CS.FindTrans(contentMar, "BtnGoTo")
    local btnGet = CS.FindTrans(contentMar, "BtnGet")
    local btnMask = CS.FindTrans(contentMar, "BtnMask")
    local eff = CS.FindTrans(contentMar, "Eff")
    local slider = self:FindWndSlider(bar)

    local nullMar = CS.FindTrans(item, "Content/NullMar")
    local nullText = CS.FindTrans(nullMar, "NullText")

    local isPlaySpine = self._needPlayTaskSuperSp
    CS.ShowObject(contentTrans, not isPlaySpine)
    CS.ShowObject(bgImg, not isPlaySpine)
    CS.ShowObject(spineRoot, isPlaySpine)
    local timeKey = self._taskSuperSpineShowTimeKey .. itempos
    self:TimerStop(timeKey)
    if isPlaySpine then
        self._taskSuperSpNum = self._taskSuperSpNum - 1
        local pageSp = self._taskSuperSpList[itempos]
        if not pageSp then
            local spineName = self._taskSuperSpName
            pageSp = self:CreateWndSpine(spineRoot, spineName, spineName .. itempos, false)
            self._taskSuperSpList[itempos] = pageSp
            pageSp:SetAnimationCompleteFunc(function()

            end)
        end
        pageSp:PlayAnimationSolid("idle", false)
        local taskSuperSpineShowTimeFunc = function()
            CS.ShowObject(bgImg, true)
            CS.ShowObject(contentTrans, true)
            CS.ShowObject(spineRoot, false)
            self:TweenSeq_AlphaCanvasTrans("taskSuperAlpha" .. itempos, contentTrans, 0, 1, 0.4)
            if self._taskSuperSpNum <= 0 then
                self._needPlayTaskSuperSp = false
            end
        end
        self._taskSuperSpineShowTimeFuncList[timeKey] = taskSuperSpineShowTimeFunc
        self:TimerStart(timeKey, 0.6, false, 1)
    end

    CS.ShowObject(contentMar, true)
    CS.ShowObject(nullMar, false)
    self:SetWndClick(bgImg, function()
    end)

    if itemdata.type and itemdata.type == 2 then
        CS.ShowObject(contentMar, false)
        CS.ShowObject(nullMar, true)
        self:SetWndText(nullText, ccClientText(20324))
        return
    end

    local state = itemdata._state
    local ref = gModelQuest:GetTaskConfig(itemdata._refId)
    self:SetWndText(titleText, ccLngText(ref.description))



    if gLGameLanguage:IsUSARegion() then
        self:InitTextModeWithLanguage(titleText)
    elseif gLGameLanguage:IsJapanRegion() then
        self:InitTextLineWithLanguage(titleText, -32)
        self:InitTextSizeWithLanguage(titleText, -2)
    else
        self:InitTextLineWithLanguage(titleText, -22)
    end

    slider.maxValue = itemdata._goal
    slider.value = itemdata._schedule
    self:SetWndText(scheduleText, string.replace(ccClientText(20312), itemdata._schedule, LUtil.NumberCoversion(itemdata._goal)))
    CS.ShowObject(btnGoTo, state == 0)
    CS.ShowObject(eff, state == 1)
    if state == 1 then
        self:CreateWndEffect(eff, "fx_anniu_02", InstanceID, 100)
    end
    CS.ShowObject(btnGet, state == 1)
    CS.ShowObject(btnMask, state == 2)

    if state == 0 then
        self:SetWndButtonText(btnGoTo, ccClientText(20307))
        self:SetWndClick(btnGoTo, function()
            self:OnClickBtnGoTo(itemdata)
        end)
    elseif state == 1 then
        self:SetWndButtonText(btnGet, ccClientText(20316))
        local t = function()
            local refId = itemdata._refId
            gModelQuest:OnQuestReceiveReq(refId)
            self:ShowGetEff(btnGet)
        end
        self:SetWndClick(btnGet, function()
            if t then
                t()
            end
        end)
        self:SetWndClick(bgImg, function()
            if t then
                t()
            end
        end)
    end

    local itemList = LxDataHelper.ParseItem(ref.reward)
    local uiIconEasyList2 = self._uiList:GetItemCls(InstanceID)
    if (not uiIconEasyList2) then
        uiIconEasyList2 = UIIconEasyList:New()
        self._uiList:SetItemCls(InstanceID, uiIconEasyList2)
        uiIconEasyList2:Create(self, rewardList)
        uiIconEasyList2:SetIconClickPath("CommonUI")
        uiIconEasyList2:SetIconParentPath("CommonUI/Icon")
    end
    --uiIconEasyList2:SetShowMaskIndex(1, "CommonUI/mask")
    uiIconEasyList2:SetShowMask(state == 2, "CommonUI/mask")
    uiIconEasyList2:RefreshList(itemList)
end

function UIWishColleWin:RefreshThemeRed()
    for i, v in pairs(self._redThemeList) do
        local showRed = gModelRedPoint:CheckShowIdMapRedByRedId(ModelRedPoint.DREAM_SCHOOL_THEME, i)
        if not showRed then
            showRed = gModelRedPoint:CheckShowIdMapRedByRedId(ModelRedPoint.DREAM_SCHOOL_TASK, i)
        end
        CS.ShowObject(v, showRed)
    end
end

function UIWishColleWin:OnDrawItemCell(list, item, itemdata, itempos)
    if not self._ref then
        return
    end
    local InstanceID = item:GetInstanceID()

    local Item_Bar = self:FindWndTrans(item, "Item_Bar")

    local CommonUI = self:FindWndTrans(item, "CommonUI")
    local Icon = self:FindWndTrans(CommonUI, "Icon")
    local Eff = self:FindWndTrans(CommonUI, "Eff")
    local redPoint = self:FindWndTrans(CommonUI, "redPoint")
    local Mask = self:FindWndTrans(item, "Mask")
    local UIText = self:FindWndTrans(item, "UIText")
    local _ref = self._ref

    local isSpecail = false
    local isBigPrize = false
    if itempos == 6 then
        if itemdata.rewardSpecail and itemdata.rewardSpecail ~= "" then
            isBigPrize = true
            local time = GetTimestamp()
            local endTime = self._endTime or 0
            local timespan = endTime / 1000 - time
            if (timespan > 0) then
                isSpecail = true
            end
        end
    end
    local itemList = LxDataHelper.ParseItem(itemdata.rewardGeneral)
    local itemInfo = itemList[1]

    local icon
    if isSpecail and not string.isempty(itemdata.rewardSpecailIcon) then
        icon = itemdata.rewardSpecailIcon
    end

    local num = gModelItem:GetNumByRefId(_ref.itemId)
    local isTarget = num >= itemdata.target
    local isGet = gModelDreamSchool:GetIsGetGoalRewardByRefId(itemdata.refId)
    local color = "lightBlue"
    if isTarget then
        --local effName = "fx_mjxy_lingqu"
        ----if itempos == 6 then
        ----    effName = "fx_mjxy_dajianglingqu"
        ----end
        --self:CreateWndEffect(Eff,effName,effName..itempos,100)
    end
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(Icon)
    baseClass:SetCommonReward(itemInfo.itemType, itemInfo.itemId, itemInfo.itemNum)
    baseClass:EnableShowNum(not isSpecail)
    if icon then
        baseClass:SetItemIconPath(icon)
    end
    baseClass:DoApply()
    --self:SetWndText(UIText,LUtil.FormatColorStr(itemdata.target,color))
    self:SetWndText(UIText, itemdata.target)

    local curTarget = itemdata.curTarget
    local beforeTarget = itemdata.beforeTarget
    local target = itemdata.target
    self:SetWndSliderPara(Item_Bar, curTarget, beforeTarget, target)

    CS.ShowObject(Mask, isGet)
    local showEff = isTarget and not isGet
    CS.ShowObject(Eff, showEff)
    CS.ShowObject(redPoint, showEff)
    self:SetWndClick(item, function()
        if isTarget and not isGet then
            gModelDreamSchool:OnSchoolGoalRewardReq(itemdata.refId)
            return
        end
        if isBigPrize then
            self:OnClickTips(itemdata.refId)
        else
            gModelGeneral:ShowCommonItemTipWnd(itemInfo, { showSkinCode = true })
        end
    end)
end

function UIWishColleWin:SetTaskItemDate(ref)
    local item = self.mItemMag
    local itemIcon = CS.FindTrans(item, "ItemBg/ItemIcon")
    local numText = CS.FindTrans(item, "ItemBg/NumText")
    local valueText = CS.FindTrans(item, "ValueBg/ValueText")

    local itemId = ref.itemId
    --local icon = gModelItem:GetItemIconByRefId(itemId)
    --self:SetWndEasyImage(itemIcon,icon)
    CS.ShowObject(itemIcon, false)
    --local name = gModelItem:GetNameByRefId(itemId)
    self:SetWndText(numText, ccClientText(20325))
    local itemNum = gModelItem:GetNumByRefId(itemId)
    --self:SetWndText(valueText,LUtil.FormatColorStr(itemNum,"lightBlue"))
    self:SetWndText(valueText, itemNum)

    self:SetWndClick(item, function()
        local itemInfo = {
            itemNum = itemNum,
            itemId = itemId,
            itemType = 1,
        }
        gModelGeneral:ShowCommonItemTipWnd(itemInfo, { showSkinCode = true })
    end)
end

function UIWishColleWin:OnClickBtnGoTo(itemdata)
    local historyList = LWnd.GetHistory(self)
    local wndArgList = historyList.wndArgList
    wndArgList.taskRefId = self._taskRefId
    wndArgList.refId = self._refId
    gModelQuest:TaskGoto(itemdata._refId, self:GetWndName())
    self:WndClose()
end
function UIWishColleWin:OnClickBox()
    local isBox = gModelDreamSchool:GetGiftDaily() == 1
    if not isBox then
        GF.ShowMessage(ccClientText(20327))
        local giftDaily = gModelDreamSchool:GetSchoolConfigRefByKey("giftDaily")
        local rewardList = LxDataHelper.ParseItem(giftDaily)
        GF.OpenWnd("UIringBoxDetail", { self.mBtnBox, rewardList })
    else
        gModelDreamSchool:OnSchoolGiftDailyReq()
    end
end

function UIWishColleWin:TaskTypeListItem(list, item, itemdata, itempos)
    local btnTab = CS.FindTrans(item, "BtnTab")
    local redPoint = CS.FindTrans(item, "redPoint")
    local refId = itemdata.refId

    self._tabList[itemdata.refId] = btnTab
    self._redTaskList[itemdata.refId] = redPoint
    self:SetWndTabText(btnTab, ccLngText(itemdata.name))
    self:SetWndTabStatus(btnTab, 1)
    self:SetWndClick(item, function()
        if self._taskRefId == refId then
            return
        end
        --self._needPlayTaskSuperSp = true
        self:OnClickTaskType(refId)
    end)
end

function UIWishColleWin:RefreshTabSuper()
    local list = {}
    local refs = gModelDreamSchool:GetSchoolThemeRef()
    local infos = gModelDreamSchool:GetSchoolInfos()
    for i, v in ipairs(refs) do
        local info = infos[v.refId]
        if info and info.isStart ~= 0 then
            table.insert(list, v)
        end
    end

    local _uiList = self._tabUIList
    if _uiList then
        _uiList:RefreshList(list)
        local _uiListSuper = _uiList:GetList()
        _uiListSuper:DrawAllItems()
        if self._refId then
            self:OnClickTab(self._refId)
        end
    else
        _uiList = self:GetUIScroll("tab")
        _uiList:Create(self.mTabSuper, list, function(...)
            self:TabListItem(...)
        end)
        _uiList:EnableScroll(false, false)
        _uiList:MoveToPos()
        self._tabUIList = _uiList

        --- 打开红点的
        if #list >= 1 then
            local recordRedMap = {}
            local recordRedList = {}
            local tempRefId
            for i,v in ipairs(list) do
                tempRefId = v.refId
                local showRed = gModelRedPoint:CheckShowIdMapRedByRedId(ModelRedPoint.DREAM_SCHOOL_THEME, tempRefId)
                if not showRed then
                    showRed = gModelRedPoint:CheckShowIdMapRedByRedId(ModelRedPoint.DREAM_SCHOOL_TASK, tempRefId)
                end
                if showRed then
                    recordRedMap[tempRefId] = true
                    table.insert(recordRedList, tempRefId)
                end
            end
            local refId = nil
            local oldRefId = self._refId
            if oldRefId and oldRefId > 0 and self._isJump then
                self._isJump = false
                refId = oldRefId
            else
                if #recordRedList > 0 then
                    refId = recordRedList[1]
                else
                    refId = list[1].refId
                end
            end
            refId = refId or list[1].refId
            print("refId = " .. refId)
            self:OnClickTab(refId)
        end
    end
end

function UIWishColleWin:InitMessage()
    self:WndNetMsgRecv(LProtoIds.SchoolInfoListResp, function(...)
        self:RefreshTabSuper()
        self:RefreshDate()
        self:RefreshThemeRed()
    end)
    self:WndNetMsgRecv(LProtoIds.SchoolGiftDailyResp, function(...)
        self:RefreshBox()
    end)
    self:WndNetMsgRecv(LProtoIds.SchoolInfoChangeResp, function(...)
        self:RefreshDate()
    end)
    self:WndNetMsgRecv(LProtoIds.QuestReceiveResp, function(...)
        self:RefreshDate()
        self._oldTaskRedId = nil
    end)
    self:WndNetMsgRecv(LProtoIds.SchoolRewardNoticeInfoListResp, function(...)
        self:RefreshNotice()
    end)
    self:WndNetMsgRecv(LProtoIds.SchoolGoalRewardResp, function(pb)
        local refId = pb.refId
        local ref = gModelDreamSchool:GetSchoolTargetRefByRefId(refId)
        if ref.stage == 1 and ref.stageEnd == 1 then
            self:OnRefreshItemList()
        end
        --gModelDreamSchool:OnSchoolRewardNoticeInfoListReq()
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self._stageType = nil
        self:RefreshTabSuper()
        self:RefreshDate()
        self:RefreshThemeRed()
    end)
end

function UIWishColleWin:InitCommand()
    self._wight = 400--self.mPop.rect.width
    self:SetWndText(self.mTaskText, ccClientText(20304))

    local taskRefId = self:GetWndArg("taskRefId")
    self._taskRefId = taskRefId

    local jumpTaskRefId
    local isJumpTask = false
    if taskRefId and taskRefId > 0 then
        isJumpTask = true
        jumpTaskRefId = taskRefId
    end
    self._isJumpTask = isJumpTask
    self._jumpTaskRefId = jumpTaskRefId

    local refId = self:GetWndArg("refId")
    self._refId = refId
    local isJump = false
    if refId and refId > 0 then
        isJump = true
    end
    self._isJump = isJump

    gModelDreamSchool:OnSchoolInfoListReq()
    --gModelDreamSchool:OnSchoolRewardNoticeInfoListReq()
    if LPlayerPrefs.dreamSchoolBEff == "true" then
        LPlayerPrefs.SetDreamSchoolBEff("false")
        FireEvent(EventNames.ON_ACTIVITY_DREAMSCHOOL_CHANGE)
    end
    self._rewardRollDuration = gModelDreamSchool:GetSchoolConfigRefByKey("rewardRoll") or 5
end

function UIWishColleWin:RefreshBox()
    local isBox = gModelDreamSchool:GetGiftDaily() == 1
    CS.ShowObject(self.mBtnBox, true)
    self:SetWndEasyImage(self.mBtnBox, isBox and "quest_icon_box_3" or "quest_icon_box_2")
    CS.ShowObject(self.mBoxEff, isBox)
    if isBox then
        self:CreateWndEffect(self.mBoxEff, "fx_richangbaoxiang", "UIWishColleWin_fx_richangbaoxiang", 100)
    end
end

function UIWishColleWin:OnClickTaskType(taskRefId)
    if self._taskRefId then
        self:ChangeTaskType(self._tabList[self._taskRefId], false)
    end
    self._taskRefId = taskRefId
    self:ChangeTaskType(self._tabList[taskRefId], true)
    local ref = gModelDreamSchool:GetSchoolThemeQuestRefByRefId(taskRefId)
    local list = {}
    local tasks = gModelQuest:GetTaskKeyList(ref.questType)
    for i, v in pairs(tasks) do
        table.insert(list, v)
    end
    table.sort(list, function(a, b)
        if a._sort and b._sort then
            return a._sort < b._sort
        end
    end)
    local itemNum = #list
    local noItems = itemNum <= 0
    CS.ShowObject(self.mNoRecord, noItems)
    if (noItems) then
        self:CreateEmptyShow(21001)
    end

    if self._needPlayTaskSuperSp then
        self._taskSuperSpNum = itemNum
    end

    if itemNum > 0 and itemNum < 3 then
        for i = 1, 3 do
            if not list[i] then
                table.insert(list, { type = 2 })
            end
        end
    end

    local _uiList = self._uiList
    if not _uiList then
        _uiList = self:GetUIScroll("cell")
        _uiList:Create(self.mTaskSuper, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
        self._uiList = _uiList
        _uiList:EnableScroll(false, false)
    else
        _uiList:RefreshList(list)
    end
    _uiList:MoveToPos()
end

function UIWishColleWin:CreateEmptyShow(refId)
    local data = {
        refId = refId,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
    if self._isJapaness then
        self:InitTextSizeWithLanguage(self.mEmptyText,-2)
        self:SetAnchorPos(self.mEmptyTextBg,Vector2.New(0,-100))
    end
end

function UIWishColleWin:ShowGetEff(root)
    local _getAnimList = self._getAnimList or {}
    local item, key
    local index = 0
    for i, v in pairs(_getAnimList) do
        if v.bool == true then
            key = i
            item = v
        end
        index = index + 1
    end
    if not item then
        key = index + 1
        local effTrans = CS.FindTrans(self.mEffPool, key)
        if not effTrans then
            effTrans = CS.NewObject(key, self.mEffPool)
        end
        self:CreateWndEffect(effTrans, "fx_chengjiu_jifen_2", key, 100, false, false)
        item = {
            dpTrans = effTrans,
            bool = false
        }
        _getAnimList[key] = item
        self._getAnimList = _getAnimList
    end

    local seqTween
    self:TweenSeqKill(key)
    if not seqTween then
        seqTween = self:TweenSeqCreate(key, function(seq)
            item.bool = false
            local targetPos = root.position
            local dpTrans = item.dpTrans
            CS.ShowObject(dpTrans, true)
            dpTrans.position = Vector3.New(targetPos.x, targetPos.y, 0)

            local endPos = self.mItemMag.position
            local tween = dpTrans:DOMove(endPos, 0.5)
            seq:Append(tween)
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(key)
        item.bool = true
        CS.ShowObject(item.dpTrans, false)
        self:CreateWndEffect(self.mItemMag, "fx_chengjiu_jifen_3", "fx_chengjiu_jifen_3" .. key, 100, false, false)
    end)
end

function UIWishColleWin:TabListItem(list, item, itemdata, itempos)
    local redPoint = CS.FindTrans(item, "redPoint")
    local refId = itemdata.refId
    self._redThemeList[itemdata.refId] = redPoint
    self._tabTransList[itemdata.refId] = item
    self:ChangeTab(refId, false)
    self:SetWndClick(item, function()
        if refId == self._refId then
            return
        end
        self:OnClickTab(refId)
    end)
end

function UIWishColleWin:MovePage(moveY, moveTime)
    local _logCellList = self._logCellList
    if not _logCellList then
        return
    end
    local seqTween
    self:TweenSeqKill(self._moveKey)

    local list = gModelDreamSchool:GetNotices()
    local index = self._logIndex + 1
    if index > #list then
        index = 1
    end
    self._logIndex = index
    local log = list[index]
    local cellMaxNum = #_logCellList
    self:SetLogItem(_logCellList[cellMaxNum], log)

    if not seqTween then
        seqTween = self:TweenSeqCreate(self._moveKey, function(seq)
            for i, v in ipairs(_logCellList) do
                CS.ShowObject(v, true)
                local vec = Vector2.New(v.localPosition.x, v.localPosition.y - moveY)
                local tweener = v:DOLocalMove(vec, moveTime)
                seq:Join(tweener)

                local text = self:FindWndTrans(v, "UIText")
                local canvasGroup = text:GetComponent(typeofCanvasGroup)
                if canvasGroup then
                    local taskAlpha = 1
                    if i == 1 then
                        taskAlpha = 0.8
                    elseif i == 2 then
                        taskAlpha = 0.6
                    elseif i == 3 then
                        taskAlpha = 0
                    end
                    local tween = canvasGroup:DOFade(taskAlpha, 1)
                    seq:Join(tween)
                end

            end
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._moveKey)
        local transList = {}
        local oneTrans = _logCellList[4]
        for i = 1, 3 do
            transList[i + 1] = _logCellList[i]
        end
        transList[1] = oneTrans
        self._logCellList = transList
        local endTrans = self._logCellList[1]
        self._logCellList[4].localPosition = Vector2.New(endTrans.localPosition.x, endTrans.localPosition.y + self._logCellH)

        self:SetItemAlpha(self._logCellList[1], 1)
    end)
end

function UIWishColleWin:RefreshTaskTypeRed()
    local taskList = {}
    for k, v in pairs(self._redTaskList) do
        table.insert(taskList, {
            refId = k,
            item = v,
        })
    end
    table.sort(taskList, function(a, b)
        return a.refId < b.refId
    end)
    local oldTaskRedId = self._oldTaskRedId
    local taskRedMap = {}
    local taskRedList = {}
    local ref,tasks,refId
    for i,v in ipairs(taskList) do
        refId = v.refId
        ref = gModelDreamSchool:GetSchoolThemeQuestRefByRefId(refId)
        tasks = gModelQuest:GetTaskKeyList(ref.questType)
        local bool = false
        for j, k in pairs(tasks) do
            if k._state == 1 then
                bool = true
                taskRedMap[refId] = true
                table.insert(taskRedList,refId)
                break
            end
        end
        CS.ShowObject(v.item, bool)
    end
    local taskRefId
    local jumpTaskRefId = self._jumpTaskRefId
    if jumpTaskRefId and jumpTaskRefId > 0 then
        taskRefId = jumpTaskRefId
        self._jumpTaskRefId = nil
    else
        if oldTaskRedId and oldTaskRedId > 0 and taskRedMap[oldTaskRedId] then
            taskRefId = oldTaskRedId
        else
            local temp = self._taskRefId
            if temp and temp > 0 and taskRedMap[temp] then
                taskRefId = temp
            else
                if self._isJumpTask then
                    taskRefId = temp
                    self._isJumpTask = false
                else
                    if #taskRedList > 0 then
                        taskRefId = taskRedList[1]
                    else
                        if #taskList > 0 then
                            taskRefId = taskList[1].refId
                        end
                    end
                end
            end
        end
    end
    self._taskRefId = taskRefId
end

function UIWishColleWin:ChangeTab(refId, bool)
    local item = self._tabTransList[refId]
    local itemdata = gModelDreamSchool:GetSchoolThemeRefByRefId(refId)
    local OnBg = CS.FindTrans(item, "OnBg")

    local icon = itemdata.img2
    CS.ShowObject(OnBg, bool)
    self:SetWndTabStatus(item, bool and LWnd.StateOn or LWnd.StateOff)
    self:SetWndTabIcon(item, icon)
    self:SetWndTabText(item, ccLngText(itemdata.name))
end

function UIWishColleWin:RefreshNotice()
    local list = gModelDreamSchool:GetNotices()
    local len = #list
    local logSuper =self.mLogSuper
    if self._isEnus then
        logSuper=self.mLogSuper_enus
    end
    CS.ShowObject(logSuper, len > 0)


    if len <= 0 then
        return
    end
    local _logCellList = self._logCellList
    if not _logCellList then
        _logCellList = {}
        local logCellPosList = {}
        for i = 1, 4 do
            local cell = CS.FindTrans(logSuper, "LogCell" .. i)
            table.insert(_logCellList, cell)
            table.insert(logCellPosList, cell.localPosition)
        end
        self._logCellList = _logCellList
        self._logCellPosList = logCellPosList
    end
    local logIndex = 0
    local cellLen = #_logCellList
    for i = 1, cellLen do
        local log = list[cellLen - (i - 1)]
        if len < cellLen then
            log = list[len - (i - 1)]
        end
        --local v = _logCellList[len - (i - 1)]
        local v = _logCellList[i]
        if log and v then
            self:SetLogItem(v, log, i)
            logIndex = i
            CS.ShowObject(v, true)
        elseif v then
            CS.ShowObject(v, false)
        end
    end
    self._logIndex = logIndex
    if cellLen == 2 then
        local item = _logCellList[1]
        self:SetItemAlpha(item, 0.6)
    elseif cellLen > 2 then
        local item = _logCellList[1]
        self:SetItemAlpha(item, 1)
        item = _logCellList[2]
        self:SetItemAlpha(item, 0.8)
        item = _logCellList[3]
        self:SetItemAlpha(item, 0.6)
    end
    local poPos = 25
    if logIndex == 1 then
        poPos = -30
    elseif logIndex == 2 then
        poPos = 0
    else
        if logIndex > 3 then
            if not self:IsTimerExist(self._logSlideTime) then
                self:TimerStart(self._logSlideTime, self._rewardRollDuration, false, -1)
            end
        end
        return
    end
    --for i, v in ipairs(_logCellList) do
    --	local y = poPos - ((i - 1) * self._logCellH)
    --	v.anchoredPosition = Vector2.New(v.anchoredPosition.x,y)
    --end
end

function UIWishColleWin:SetItemDate(item, itemdata, itempos)
    local itemIcon = CS.FindTrans(item, "ItemBg/ItemIcon")
    local numText = CS.FindTrans(item, "ItemBg/ItemIcon/NumText")
    local valueText = CS.FindTrans(item, "ValueBg/ValueText")
    local mask = CS.FindTrans(item, "ItemBg/ItemIcon/Mask")
    local eff = CS.FindTrans(item, "ItemBg/Eff")
    local _ref = self._ref
    if not _ref then
        return
    end
    CS.ShowObject(itemIcon, true)
    local isSpecail = false
    local isBigPrize = false
    if itempos == 6 then
        if itemdata.rewardSpecail and itemdata.rewardSpecail ~= "" then
            isBigPrize = true
            local time = GetTimestamp()
            local endTime = self._endTime or 0
            local timespan = endTime / 1000 - time
            if (timespan > 0) then
                isSpecail = true
            end
        end
    end

    local itemList = LxDataHelper.ParseItem(itemdata.rewardGeneral)
    local itemInfo = itemList[1]

    CS.ShowObject(numText, not isSpecail)
    local icon = ""
    if isSpecail then
        icon = itemdata.rewardSpecailIcon
    else
        icon = gModelItem:GetItemIconByRefId(itemInfo.itemId)
        self:SetWndText(numText, itemInfo.itemNum)
        if itempos == 6 then
            itemIcon.sizeDelta = Vector2.New(70, 70)
        end
    end
    self:SetWndEasyImage(itemIcon, icon)

    local num = gModelItem:GetNumByRefId(_ref.itemId)
    local isTarget = num >= itemdata.target
    local isGet = gModelDreamSchool:GetIsGetGoalRewardByRefId(itemdata.refId)
    local color = "lightBlue"
    --local color = "yellow_2"
    if isTarget then
        --local effName = "fx_mjxy_lingqu"
        ----if itempos == 6 then
        ----    effName = "fx_mjxy_dajianglingqu"
        ----end
        --self:CreateWndEffect(eff,effName,effName..itempos,100)
    end
    --self:SetWndText(valueText,LUtil.FormatColorStr(itemdata.target,color))
    self:SetWndText(valueText, itemdata.target)
    CS.ShowObject(mask, isGet)
    CS.ShowObject(eff, isTarget and not isGet)
    self:SetWndClick(item, function()
        if isTarget and not isGet then
            gModelDreamSchool:OnSchoolGoalRewardReq(itemdata.refId)
            return
        end
        if isBigPrize then
            self:OnClickTips(itemdata.refId)
        else
            gModelGeneral:ShowCommonItemTipWnd(itemInfo, { showSkinCode = true })
        end
    end)
end

function UIWishColleWin:ChangeTaskType(trans, bool)
    self:SetWndTabStatus(trans, bool and 0 or 1)
end

function UIWishColleWin:RefreshTaskRed()
    local ref = gModelDreamSchool:GetSchoolThemeRefByRefId(self._refId)
    if not ref then
        return
    end
    local showRed = gModelRedPoint:CheckShowIdMapRedByRedId(ModelRedPoint.DREAM_SCHOOL_TASK, self._refId)
    CS.ShowObject(self.mTaskRedPoint, showRed)

    if ref.showAd then
        self:SetWndEasyImage(self.mPublicityImg, ref.showAd, nil, true)
    end
end

function UIWishColleWin:OnTimer(key)
    if (self._dreamSchoolTimeKey == key) then
        self:SetTime()
    elseif self._logSlideTime == key then
        self:MovePage(self._logCellH, self._moveSpeed)
    elseif self._runSpine == key then
        self:RunSpine()
    elseif self._taskSuperSpineWaitTimeKey == key then
        self._isFirstLoad = false
        self:OnClickTaskType(self._taskRefId)
    elseif self._taskSuperSpineShowTimeFuncList[key] then
        self._taskSuperSpineShowTimeFuncList[key]()
    elseif self._rankKeyTime == key then
        self:SetRankTime()
    end
end

function UIWishColleWin:InitLogCellList()
    self:TweenSeqKill(self._moveKey)
    self:TimerStop(self._logSlideTime)
    local _logCellList = self._logCellList
    local _logCellPosList = self._logCellPosList
    if not _logCellList or not _logCellPosList then
        return
    end
    for i, v in ipairs(_logCellList) do
        local pos = _logCellPosList[i]
        v.localPosition = pos
    end
end

function UIWishColleWin:OnClickHelp()
    GF.OpenWnd("UIBzTips", { refId = 200 })
end

function UIWishColleWin:OnClickTips()
    local _schoolInfo = self._schoolInfo
    if not _schoolInfo then
        return
    end
    GF.OpenWnd("UIWishColleTipsPop", { refId = _schoolInfo.refId, stage = 1 })
end

function UIWishColleWin:SpineMove(pos, key, speedTime)
    local seqTween
    self:TweenSeqKill(key)
    if not seqTween then
        seqTween = self:TweenSeqCreate(key, function(seq)
            local initPosX, spineTrans
            if pos == 1 then
                initPosX = -self._wight
                spineTrans = self.mSpine1
            else
                initPosX = self._wight
                spineTrans = self.mSpine2
            end
            spineTrans.localPosition = Vector2.New(initPosX, 0)
            local tweener = spineTrans:DOLocalMove(Vector3.zero, speedTime)
            seq:Join(tweener)
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(key)
    end)
end

function UIWishColleWin:RefreshItemList()
    local refId = self._refId
    if not refId then
        return
    end

    local ref = gModelDreamSchool:GetSchoolThemeRefByRefId(refId)
    if not ref then
        return
    end

    local _stageType = self._stageType or 1

    local stage = _stageType
    local startValue = 0
    if _stageType ~= 1 then
        local itemId = ref.itemId
        local itemNum = gModelItem:GetNumByRefId(itemId)
        local stateEndRef = gModelDreamSchool:GetStageEndByThemeStage(ref.refId, 1)
        startValue = stateEndRef.target
        if itemNum >= stateEndRef.target then
            stage = nil
        end
    end

    local itemId = ref.itemId
    local itemNum = gModelItem:GetNumByRefId(itemId)

    local beforeTarget = 0
    local showItemList = {}
    local itemList = gModelDreamSchool:GetSchoolTargetRefByType(ref.refId, stage)
    local len = #itemList
    for i, v in ipairs(itemList) do
        if i == len then
            if not v.rewardSpecail or v.rewardSpecail == "" then
                self:TimerStop(self._dreamSchoolTimeKey)
                CS.ShowObject(self.mTimeBg, false)
            else
                self:SetTime()
                if not self:IsTimerExist(self._dreamSchoolTimeKey) then
                    self:TimerStart(self._dreamSchoolTimeKey, 1, false, -1)
                end
            end
        end
        --[[		local item = CS.FindTrans(self.mItemList,"Item"..i)
                if not item then break end
                self:SetItemDate(item,v,i)]]
        table.insert(showItemList, {
            refId = v.refId,
            theme = v.theme,
            stage = v.stage,
            stageEnd = v.stageEnd,
            target = v.target,
            rewardGeneral = v.rewardGeneral,
            rewardSpecail = v.rewardSpecail,
            rewardSpecailIcon = v.rewardSpecailIcon,
            rewardSpecailName = v.rewardSpecailName,
            rewardRecord = v.rewardRecord,
            beforeTarget = beforeTarget,
            curTarget = itemNum
        })
        beforeTarget = v.target
    end

    self:InitItemList(showItemList)

    printInfoN("cur item num " .. itemNum)
    --local dataList = {}
    --
    --for k,v in ipairs(itemList) do
    --	table.insert(dataList,v.target)
    --end

    --local curValue = itemNum
    --local percent = LUtil.GetCurPercent(dataList,curValue,startValue)
    --
    --self:SetWndSliderPara(self.mItem_Bar,percent,0,1)
end

function UIWishColleWin:SetItemAlpha(item, alpha)
    if not item then
        return
    end
    local text = self:FindWndTrans(item, "UIText")
    local canvasGroup = text:GetComponent(typeofCanvasGroup)
    if canvasGroup then
        canvasGroup.alpha = alpha
    end
end

function UIWishColleWin:SetRankTime()
    local schoolInfo = self._schoolInfo
    if not schoolInfo then
        return
    end
    local settlementRankTime = schoolInfo.settlementRankTime
    local time = GetTimestamp()
    local timespan = settlementRankTime / 1000 - time
    local timeStr = ""
    local showTimeDiv = timespan >= 0
    if showTimeDiv then
        timeStr = LUtil.FormatTimespanCn(timespan)
        --timeStr = string.replace(ccClientText(20328),timeStr)
    end
    self:SetWndText(self.mRankText, timeStr)
    CS.ShowObject(self.mRankTimeDiv, showTimeDiv)
end

function UIWishColleWin:SetRunSpineAin(key, isOne)
    local dpSpine = self:FindWndSpineByKey(key)
    if not dpSpine:IsDpValid() then
        return
    end
    local entryName = dpSpine:GetCurTrackEntryName()
    if entryName ~= "attack1" and entryName ~= "start" then
        local name = isOne and "idle" or "attack1"
        dpSpine:PlayAnimation(0, name, false)
        dpSpine:SetAnimationCompleteFunc(function(ainName)
            if ainName == name then
                dpSpine:PlayAnimation(0, "idle", true)
            end
        end)
    end
end

function UIWishColleWin:SetTime()
    --设置时间
    local time = GetTimestamp()
    local endTime = self._endTime
    if not endTime then
        return
    end

    local timespan = endTime / 1000 - time
    if (timespan <= 0) then
        self:TimerStop(self._dreamSchoolTimeKey)
        CS.ShowObject(self.mTimeBg, false)
        return
    end

    local timeStr = string.replace(ccClientText(20329), LUtil.FormatTimespanCn(timespan))
    --self:SetWndText(self.mTimeText,string.replace(ccClientText(20302),timeStr))
    CS.ShowObject(self.mTimeBg, true)
    self:SetWndText(self.mTimeText, timeStr)
    if self._isJapaness then
        self:InitTextSizeWithLanguage(self.mTimeText,-4)
    end
end

--设置形象
function UIWishColleWin:SetSpine(paintTans, prefabName, ref, pos)
    if not ref then
        return
    end
    local spine = prefabName
    local key = spine .. pos
    if pos == 1 then
        self._spine1key = key
    else
        self._spine2key = key
    end

    local keylist = self._spineKeyList or {}
    local list = keylist[pos]
    if not list then
        list = {}
        keylist[pos] = list
        self._spineKeyList = keylist
    end
    for i, v in pairs(list) do
        self:ChangeSpine(i, false)
    end
    if list[key] then
        self:ChangeSpine(key, true)
        return
    end
    list[key] = key
    --self:SpineMove(pos,key,self._spineSpeed)
    self:CreateWndSpine(paintTans, spine, key, false, function(dpSpine)
        local dpTrans = dpSpine and dpSpine:GetDisplayTrans()
        if dpTrans then
            dpTrans.anchorMin = Vector2.New(0.5, 0.5)
            dpTrans.anchorMax = Vector2.New(0.5, 0.5)
            local flip = string.split(ref.showLHflip, "|")
            local scaleX = (flip[pos] == "1" and -1 or 1)
            local showIconSize = string.split(ref.showLHSize, "|")
            local scale = tonumber(showIconSize[pos])
            dpTrans.localScale = Vector3(scale * scaleX, scale, scale)
            local showIconPosArr = string.split(ref.showLHPos, "|")
            local showIconPos = string.split(showIconPosArr[pos], ",")
            dpTrans.localPosition = Vector2.New(tonumber(showIconPos[1]), tonumber(showIconPos[2]))
            --self:SetWndClick(dpTrans,function ()
            --	self:SetRunSpineAin(key)
            --end)
            --self:SetRunSpineAin(key,true)
        end
    end)
    --if not self:IsTimerExist(self._runSpine) then
    --	self:TimerStart(self._runSpine,10,false,-1)
    --end

end

function UIWishColleWin:OnClickTab(refId)
    if self._refId then
        self:ChangeTab(self._refId, false)
    end
    --self._needPlayTaskSuperSp = true
    self._refId = refId
    self:ChangeTab(refId, true)
    self._oldTaskRedId = self._taskRefId
    --self._taskRefId = nil
    self._stageType = nil
    self:RefreshDate()
    self:ReleaseRedPointSingleFunc(ModelRedPoint.DREAM_SCHOOL_TASK, function()
        self:RefreshTaskRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.DREAM_SCHOOL_TASK, function()
        self:RefreshTaskRed()
    end)
    self:InitLogCellList()
    gModelDreamSchool:OnSchoolRewardNoticeInfoListReq(refId)
end
------------------------------------------------------------------
return UIWishColleWin


