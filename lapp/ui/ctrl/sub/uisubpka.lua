---
--- Created by BY.
--- DateTime: 2023/10/8 11:37:27
---
---活动12， 日常战令
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkA:LChildWnd
local UISubPkA = LxWndClass("UISubPkA", LChildWnd)
UISubPkA.PAGE_BUY = 1                --档位购买
UISubPkA.PAGE_ELITE = 2            --精英战令
UISubPkA.PAGE_ADVANCE = 3            --进阶战令
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkA:UISubPkA()
    self.pages = {}
    self._uiCommonList = {}
    self._bGuy = false                --是否购买战令
    self._passKey = "_passAKey"
    self._quickEffectKey = "quickEffect"
    self._getBtnEff = "fx_anniu_02"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkA:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkA:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkA:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

---------------------------------------点击----------------------------------------------
function UISubPkA:OnClickGet(pageId, entryId)
    --领取
    gModelActivity:OnActivityReceiveGoalReq(self._sid, pageId, entryId)
end

function UISubPkA:OnClickGoOn()
    --前往
    gModelFunctionOpen:Jump(self._jump, self:GetWndName())
end

function UISubPkA:SetTime()
    --设置时间
    local time = GetTimestamp()
    local timespan = self._endTime - time
    if (timespan <= 0) then
        self:TimerStop(self._passKey)
        CS.ShowObject(self.mTimeBg, false)
        return
    end
    local timeStr = LUtil.FormatTimespanCn(timespan)
    local str = ""
    local _timeDes = self._timeDes
    if not string.isempty(_timeDes) then
        str = string.replace(_timeDes, timeStr)
    end
    self:SetWndText(self.mTimeText, str)
    CS.ShowObject(self.mTimeBg, true)
end

function UISubPkA:OnActivityConfigData()
    local activityData = gModelActivity:GetWebActivityDataById(self._sid)
    local data = activityData.config
    self._activityCfg = data
    local path, pos, text
    path = data.image
    if LxUiHelper.IsImgPathValid(path) then
        --self:SetWndEasyImage(self.mTop, path, nil, true)
        self:SetWndEasyImage(self.mTop, path, nil)
    end
    path = data.descIcon
    pos = data.descIconPosition
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mTextImg, path, function()
            CS.ShowObject(self.mTextImg, true)
        end, true)
        self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(pos))
    end
    local showHelp = data.helpTips == 1
    pos = data.helpTipsPosition
    CS.ShowObject(self.mHelpBtn, showHelp)
    if showHelp and pos then
        self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(pos))
    end
    path = data.buttonIcon
    pos = data.buttonDescPosition
    if LxUiHelper.IsImgPathValid(path) and pos then
        self:SetWndEasyImage(self.mBuyBtn, path, function()
            CS.ShowObject(self.mBuyBtn, true)
        end, true)
        self:SetAnchorPos(self.mBuyBtn, LxDataHelper.ParseVector2NotEmpty(pos))
    end

    path = data.activateIcon
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mShowImg, path, nil, true)
    end

    self._getIconPath = data.getIcon

    local desc = data.listDesc
    if desc then
        local strArr = string.split(desc, "|")
        self:SetWndText(self.mText1, strArr[1])
        self:SetWndText(self.mText2, strArr[2])
        self._popDescStr = strArr[2]
    end

    self._quickBuyDay = data.quickBuyDay
    pos = data.timePosition
    if pos then
        CS.ShowObject(self.mTimeBg, true)
        self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(pos))
    end

    self._showItemDesc = data.showItemDesc
    self._timeDes = data.timeDes

    self._jump = data.jump
    self._titleName = data.name

    gModelActivity:OnActivityPageReq(self._sid)
end

function UISubPkA:InitMessage()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if sid ~= self._sid then
            return
        end
        self:OnActivityConfigData()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:ResetData(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        local activities = pb.activities
        for i, v in ipairs(activities) do
            local sid = v.sid
            if sid == self._sid then
                self:RefreshData()
                return
            end
        end
    end)

    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(...)
        self:OnTargetWndClose(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityABCDRewardResp, function(pb)
        self:OnActivityABCDRewardResp(pb)
    end)
end

function UISubPkA:OnClickHelp()
    --点击帮助
    local _sid = self._sid
    local activityData = gModelActivity:GetWebActivityDataById(_sid)
    if not activityData then
        return
    end
    local data = activityData.config
    local title = gModelActivity:GetLngNameByActivitySid(_sid)
    local content = data.helpTipsContent
    GF.OpenWnd("UIBzTips", { title = title, text = content })
end

function UISubPkA:OnClickOneKeyGet()
    --一键领取
    local list = {}
    local checkList = {}
    local getEntryIdList = {}
    local isBuy = self._bGuy

    for i, v in ipairs(self.pages[UISubPkA.PAGE_ELITE].entry) do
        local status = v.goalData.status
        local entryId = v.entryId
        if status == 1 then
            local data1 = { sid = self._sid, pageId = v.pageId, entryId = entryId }
            table.insert(list, data1)
            table.insert(checkList, data1)
            getEntryIdList[entryId] = true
        elseif not isBuy and status == 2 then
            getEntryIdList[entryId] = true
        end
    end

    if (isBuy) then
        for i, v in ipairs(self.pages[UISubPkA.PAGE_ADVANCE].entry) do
            if (v.goalData.status == 1) then
                local data1 = { sid = self._sid, pageId = v.pageId, entryId = v.entryId }
                table.insert(list, data1)
            end
        end
    end

    --检测是否要显示礼包购买弹窗
    self._needShowGift = self:CheckNeedShowGiftPop(checkList)

    --检测是否显示战令奖励弹窗
    self._passRewardItemList = self:GetShowPassRewardList(getEntryIdList)

    gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UISubPkA:CheckNeedQuick()
    if not self._quickBuyDay then
        return false
    end
    local time = GetTimestamp()
    local timespan = (self._endTime - time) / 86400
    local isOpen = timespan <= self._quickBuyDay
    if not isOpen then
        return false
    end

    local eliteList = self.pages[UISubPkA.PAGE_ELITE].entry
    local haveNoGet = false
    for i, v in ipairs(eliteList) do
        local goalData = v.goalData
        if (goalData.status == 0) then
            haveNoGet = true
            break
        end
    end

    return haveNoGet
end

function UISubPkA:OnTimer(key)
    self:SetTime()
end

function UISubPkA:ResetData(pb)
    local sid = pb.sid
    if (self._sid ~= sid) then
        return
    end
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        self.pages[v.pageId] = page
    end
    self:RefreshData()
end

function UISubPkA:CheckNeedShowGiftPop(getList)
    if self._bGuy then
        return false
    end

    local getLastData = getList[#getList]
    if not getLastData then
        return false
    end

    --检测是否领取了当前阶级的最后一个
    local nextEntryCfg1 = gModelActivity:GetWebActivityEntryData(getLastData.sid, getLastData.pageId, getLastData.entryId)
    local nextEntryCfg2 = gModelActivity:GetWebActivityEntryData(getLastData.sid, getLastData.pageId, getLastData.entryId + 1)
    if not nextEntryCfg2 then
        --为最后一个，没有下一个了
        return true
    end

    if nextEntryCfg1.moreInfo ~= nextEntryCfg2.moreInfo then
        --为最后一个，下一个是另一种循环类型
        return true
    end

    return false
end

---------------------------------------获得奖励弹窗----------------------------------------------
function UISubPkA:GetShowPassRewardList(getEntryIdList)
    --检测是否显示战令的特殊获得奖励弹窗
    --礼包已购买
    if self._bGuy then
        return nil
    end

    local list = {}

    --可以领取的进阶版奖励
    for i, v in ipairs(self.pages[UISubPkA.PAGE_ADVANCE].entry) do
        local entryId = v.entryId
        if getEntryIdList[entryId] then
            local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, entryId)
            local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
            for p, q in ipairs(itemList) do
                local itemId = q.itemId
                if list[itemId] then
                    local oldItemNum = list[itemId].itemNum
                    list[itemId].itemNum = oldItemNum + q.itemNum
                else
                    list[itemId] = q
                end
            end
        end
    end

    --直购奖励
    local data = self.pages[UISubPkA.PAGE_BUY].entry[1]
    local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, data.pageId, data.entryId)
    local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
    for p, q in ipairs(itemList) do
        local itemId = q.itemId
        if list[itemId] then
            local oldItemNum = list[itemId].itemNum
            list[itemId].itemNum = oldItemNum + q.itemNum
        else
            list[itemId] = q
        end
    end

    local resultList = {}
    for k, v in pairs(list) do
        table.insert(resultList, v)
    end

    return resultList
end

function UISubPkA:InitCommand()
    self._sid = self:GetWndArg("sid")
    local _sid = self._sid
    gModelActivity:ReqActivityConfigData(_sid)
end

function UISubPkA:RefreshData()
    if table.isempty(self.pages) then
        return
    end
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    local data = JSON.decode(activityData.moreInfo)
    self._endTime = (tonumber(data.playerEndTime) / 1000) or tonumber(activityData.endTime)
    self:SetTime()
    if not self:IsTimerExist(self._passKey) then
        self:TimerStart(self._passKey, 1, false, -1)
    end

    self._bGuy = data.buyPassNum > 0
    CS.ShowObject(self.mUpRedImg, not self._bGuy)
    if (not self._bGuy) then
        local entry = self.pages[UISubPkA.PAGE_BUY].entry
        local data = entry[1]
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, data.pageId, data.entryId)
        local str = entryCfg1.moreInfo
        self:SetWndText(self.mUpRedTxt, str)

        local expend2 = tonumber(entryCfg1.expend2)
        str = gModelPay:GetShowByWelfareId(expend2)
        self._buyBtnStr = str
        self:SetWndButtonText(self.mBuyBtn, str)
    end

    self._needQuick = self:CheckNeedQuick()
    CS.ShowObject(self.mQuickBtn, self._needQuick)
    if self._needQuick then
        self:CreateWndEffect(self.mQuickBtn, "fx_ui_tubiaorukou", self._quickEffectKey, 100, false, false)
    else
        self:DestroyWndEffectByKey(self._quickEffectKey)
    end

    local schedule = 0
    local eliteList = self.pages[UISubPkA.PAGE_ELITE].entry
    local advanceList = self.pages[UISubPkA.PAGE_ADVANCE].entry
    self._completeIndex = 0
    for i, v in ipairs(eliteList) do
        local data = advanceList[i]
        v.goalData2 = data.goalData
        v.pageId2 = data.pageId
        v.entryId2 = data.entryId
        if (v.goalData.status ~= 0) then
            self._completeIndex = i
        end
        local scdle = tonumber(v.goalData.schedules[1].schedule)
        if (scdle > 0 and schedule < scdle) then
            schedule = scdle
        end
    end

    local index = self._completeIndex - 1
    if (index < 4) then
        index = 0
    else
        index = index - 2
    end

    if (self._uiList) then
        self._uiList:RefreshData(eliteList)
        self._uiList:MoveToPos(index + 1)
        self._uiList:DrawAllItems(false)
    else
        self._uiList = self:GetUIScroll("cell")
        self._uiList:Create(self.mCellScroll, eliteList, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER_GRID, false)
        self._uiList:MoveToPos(index + 1)
        self._uiList:DrawAllItems(true)
    end

    local text = self._showItemDesc

    if text then
        if self._isEnus then
            self:SetWndText(self.mScheduleText_En, string.replace(text, schedule))
            CS.ShowObject(self.mScheduleText_En, true)
        else
            self:SetWndText(self.mScheduleText, string.replace(text, schedule))
            CS.ShowObject(self.mScheduleText, true)
        end
    end

    text = self._activityCfg.taskDesc
    if text then

        if self._isEnus then
            CS.ShowObject(self.mDescBg, false)
            self:SetWndText(self.mDesText_En, text)
            CS.ShowObject(self.mDesText_En, true)
            CS.ShowObject(self.mDescBg_En, true)
        else
            self:SetWndText(self.mDesText, text)
            CS.ShowObject(self.mDesText, true)

        end
    end

    CS.ShowObject(self.mShowImg, self._bGuy)
    CS.ShowObject(self.mBuyBtn, not self._bGuy)
end

function UISubPkA:OnClickShowQuickPop()
    GF.OpenWnd("UIPkQukBuyPop", { sid = self._sid })
end

function UISubPkA:InitEvent()
    self:SetWndClick(self.mHelpBtn, function(...)
        self:OnClickHelp()
    end)
    self:SetWndClick(self.mBuyBtn, function(...)
        self:OnClickBuyAdvance()
    end)
    self:SetWndClick(self.mQuickBtn, function(...)
        self:OnClickShowQuickPop()
    end)
    self:SetWndClick(self.mDesText, function(...)
        self:OnClickGoOn()
    end)
    self:SetWndClick(self.mDesText_En, function(...)
        self:OnClickGoOn()
    end)
end

---------------------------------------引导礼包购买弹窗----------------------------------------------
function UISubPkA:ShowGiftPop()
    --显示礼包购买弹窗界面
    self._needShowGift = false
    local entry = self.pages[UISubPkA.PAGE_BUY].entry
    local reward1 = self._activityCfg.popupShowItem
    local buyBtnStr = self._buyBtnStr or ""
    local descStr = self._popDescStr
    descStr = string.replace(ccClientText(15811), descStr)

    GF.OpenWnd("UIPkBuyPop",
            { sid = self._sid, entry = entry, reward1 = reward1,
              descStr = descStr, buyBtnStr = buyBtnStr })
end

function UISubPkA:ListItem(list, item, itemdata, itempos)
    local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId, itemdata.entryId)
    local entryCfg2 = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId2, itemdata.entryId2)
    if not entryCfg1 or not entryCfg2 then
        return
    end
    local wire1 = CS.FindTrans(item, "Wire1")
    local wire2 = CS.FindTrans(item, "Wire2")
    local numText = CS.FindTrans(item, "NumBg/NumText")
    local rewardList1 = CS.FindTrans(item, "RewardList1")
    local rewardList2 = CS.FindTrans(item, "RewardList2")
    local payBtn = CS.FindTrans(item, "PayBtn")
    local payBtnEff = CS.FindTrans(payBtn, "Eff")
    local goBtn = CS.FindTrans(item, "GoBtn")
    local getImage = CS.FindTrans(item, "GetImage")
    local TitleBg = CS.FindTrans(item, "TitleBg")
    local StarOn = CS.FindTrans(item, "Star/StarOn")

    local iconStr = entryCfg1 and entryCfg1.icon or ""
    CS.ShowObject(wire1, itempos ~= 1)
    local reward1List = LxDataHelper.ParseItem(entryCfg1.reward)
    local InstanceID = item:GetInstanceID()
    for i, v in ipairs(reward1List) do
        v.index = 1
    end
    local uiList = self:GetUIScroll(InstanceID .. "A")
    if (uiList:GetList()) then
        uiList:RefreshList(reward1List)
    else
        uiList:Create(rewardList1, reward1List, function(...)
            self:RewardListItem(...)
        end)
    end
    local reward2List = LxDataHelper.ParseItem(entryCfg2.reward)
    for i, v in ipairs(reward2List) do
        v.index = 2
    end
    local uiList1 = self:GetUIScroll(InstanceID .. "B")
    if (uiList1:GetList()) then
        uiList1:RefreshList(reward2List)
    else
        uiList1:Create(rewardList2, reward2List, function(...)
            self:RewardListItem(...)
        end)
    end

    local goal = itemdata.goalData.schedules[1].goal
    local status1 = itemdata.goalData.status
    local status2 = itemdata.goalData2.status
    local wireStr = "activity152_barbg"
    local wireStr2 = "activity152_barbg"
    local getIconPath = self._getIconPath

    local btnStr = ccClientText(15804)
    --local scoreStr = ccClientText(15806)
    local fun = function()
        self:OnClickGoOn(entryCfg1.jumpId)
    end
    local isGray = false
    local completeIndex = self._completeIndex or 0
    if (itempos < completeIndex) then
        wireStr2 = "activity152_bar"
    end

    local isShowGetEff = false
    if (status1 == 0) then
        CS.ShowObject(StarOn, false)
        if self._needQuick then
            btnStr = ccClientText(15803)
            fun = function()
                self:OnClickShowQuickPop()
            end
        end
    else
        wireStr = "activity152_bar"
        CS.ShowObject(StarOn, true)
        --scoreStr = ccClientText(15805)
        btnStr = ccClientText(15802)
        if (status1 == 2) then
            if (status2 == 2) then
                btnStr = ccClientText(15807)
                isGray = true
                fun = nil
            elseif (self._bGuy) then
                btnStr = ccClientText(15802)
                isShowGetEff = true
                fun = function()
                    self:OnClickOneKeyGet()
                end
            else
                btnStr = ccClientText(15803)
                fun = function()
                    self:OnClickBuyAdvance()
                end
            end
        else
            isShowGetEff = true
            fun = function()
                self:OnClickOneKeyGet()
            end
        end
    end
    CS.ShowObject(getImage, isGray)

    self:SetWndEasyImage(wire1, wireStr)
    self:SetWndEasyImage(wire2, wireStr2)
    if LxUiHelper.IsImgPathValid(getIconPath) then
        self:SetWndEasyImage(getImage, getIconPath, nil, true)
    end
    if LxUiHelper.IsImgPathValid(iconStr) then
        self:SetWndEasyImage(TitleBg, iconStr, nil)
    end

    self:SetWndButtonText(payBtn, btnStr)
    self:SetWndButtonText(goBtn, btnStr)
    CS.ShowObject(payBtn, (status1 == 0 and self._needQuick) or (status1 ~= 0 and not isGray))
    CS.ShowObject(goBtn, status1 == 0 and not self._needQuick)
    self:SetWndText(numText, goal)
    if (fun) then
        self:SetWndClick(payBtn, fun)
        self:SetWndClick(goBtn, fun)
    end

    local instanceId = item:GetInstanceID()
    local effKey = self._getBtnEff .. instanceId
    self:DestroyWndEffectByKey(effKey)

    if isShowGetEff then
        self:CreateWndEffect(payBtnEff, self._getBtnEff, effKey, 100, false, false)
    end
    CS.ShowObject(payBtnEff, isShowGetEff)
end

function UISubPkA:RewardListItem(list, item, itemdata, itempos)
    local itemRoot = self:FindWndTrans(item, "itemRoot")
    local root = self:FindWndTrans(item, "itemRoot/Icon")
    local mask = self:FindWndTrans(item, "Mask")
    local itemNum = self:FindWndTrans(item, "itemNum")
    local EffTrans = self:FindWndTrans(item, "Eff")
    local showEff = true
    if (mask) then
        CS.ShowObject(mask, false)
    end
    if (itemdata.index == 2 and not self._bGuy) then
        showEff = false
        CS.ShowObject(mask, true)
    end
    if EffTrans then
        local show = false
        if itemdata.itemType == LItemTypeConst.TYPE_ITEM and showEff then
            LxResUtil.DestroyChildImmediate(EffTrans)
            local itemRef = gModelItem:GetRefByRefId(itemdata.itemId)
            local bgEff = itemRef and itemRef.bgEff or nil
            if not string.isempty(bgEff) then
                show = true
                local instanceId = item:GetInstanceID()
                self:CreateWndEffect(EffTrans, bgEff, instanceId, 66, false, false)
            end
        end
        CS.ShowObject(EffTrans, show)
    end

    local uiCommonList = self._uiCommonList
    local InstanceID = item:GetInstanceID()
    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()
    self:SetIconClickScale(root, true)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)

    self:SetWndText(itemNum, LUtil.NumberCoversion(itemdata.itemNum))
end

function UISubPkA:OnTargetWndClose(wndName)
    if wndName == "UIAward" and self._needShowGift then
        --重新开启滑动
        self:ShowGiftPop()
    end
end

function UISubPkA:OnClickBuyAdvance()
    --购买进阶令
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end
    local curPage = self.pages[UISubPkA.PAGE_BUY]
    if not curPage then
        return
    end
    local entry = curPage.entry[1]
    GF.OpenWnd("UIPkBuyPopBig",
            { sid = self._sid, entry = entry, modelActivityType = ModelActivity.MODEL_PASSA, titleName = self._titleName })
end

--领取奖励后，弹奖励获得弹窗
function UISubPkA:OnActivityABCDRewardResp(pb)
    if pb.sid ~= self._sid then
        return
    end

    local reward = pb.itemList
    local itemList = {}
    for k, v in ipairs(reward) do
        local tab = {
            itype = tonumber(v.type),
            itemId = tonumber(v.itemId),
            count = tonumber(v.count),
        }
        table.insert(itemList, tab)
    end

    local isShowPassReward = not table.isempty(self._passRewardItemList)
    if isShowPassReward and not self._needShowGift then
        GF.OpenWnd("UIPkAward", {
            itemList = itemList,
            passItemList = self._passRewardItemList,
            passDesc = ccClientText(15813),
            btnTextList = { ccClientText(10102), ccClientText(15812) },
            func = function()
                self:OnClickBuyAdvance()
            end,
        })
    else
        gModelWndPop:TryOpenPopWnd("UIAward", { itemList = itemList })
    end
end

------------------------------------------------------------------
return UISubPkA


