---
--- Created by BY.
--- DateTime: 2023/10/9 18:20:09
---
---活动13 战令13
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkB:LChildWnd
local UISubPkB = LxWndClass("UISubPkB", LChildWnd)
UISubPkB.PAGE_BUY = 1                --档位购买
UISubPkB.PAGE_ELITE = 2            --普通版
UISubPkB.PAGE_ADVANCE = 3            --豪华版
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkB:UISubPkB()
    self._getBtnEff = "fx_anniu_02"
    self.pages = {}

    self._passKey = "_passBKey"

    self._timeLimitTimer = "_timeLimitTimer"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkB:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkB:OnCreate()
    LChildWnd.OnCreate(self)
    self._uiCommonList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkB:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

--领取奖励后，弹奖励获得弹窗
function UISubPkB:OnActivityABCDRewardResp(pb)
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

function UISubPkB:OnTimer(key)
    if key == self._passKey then
        self:SetTime()
    elseif key == self._timeLimitTimer then
        self:SetTimeLimit()
    end
end

------------------------------------------------------------------------------------------
function UISubPkB:OnClickGet(pageId, entryId)
    --领取
    gModelActivity:OnActivityReceiveGoalReq(self._sid, pageId, entryId)
end

function UISubPkB:InitEvent()
    self:SetWndClick(self.mHelpBtn, function(...)
        self:OnClickHelp()
    end)
    self:SetWndClick(self.mBuyBtn, function(...)
        self:OnClickBuyAdvance()
    end)
    self:SetWndClick(self.mDesText, function(...)
        self:OnClickGoOn()
    end)

end

---------------------------------------引导礼包购买弹窗----------------------------------------------
function UISubPkB:ShowGiftPop()
    --显示礼包购买弹窗界面
    self._needShowGift = false
    local entry = self.pages[UISubPkB.PAGE_BUY].entry

    local defaultIndex = 1
    local typeList = self._getGiftTypeList
    for i, v in ipairs(self._bGuys) do
        if (v == "0" and (not typeList or typeList[i])) then
            defaultIndex = i
            break
        end
    end

    --- 统一接口
    --local itemdata = entry[defaultIndex]
    --local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId, itemdata.entryId)
    --local moreInfo = string.split(entryCfg1.moreInfo, "|")
    --local reward1 = moreInfo[1]
    --local descStr = self._popDescStr
    --descStr = string.replace(ccClientText(15811), descStr)
    --local expend2 = tonumber(entryCfg1.expend2)
    --local buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
    --GF.OpenWnd("UIPkBuyPop",
    --        { sid = self._sid, entry = entry, reward1 = reward1,
    --          descStr = descStr, buyBtnStr = buyBtnStr, defaultIndex = defaultIndex })

    GF.OpenWnd("UIPkBuyPopBig",{
        sid = self._sid,
        entry = entry,
        grade = self._grade,
        index = defaultIndex,
        modelActivityType = ModelActivity.MODEL_PASSB,
        titleName = self._activityCfg.name,
    })
end

function UISubPkB:SetTimeLimit()
    local timeLimitInfo = self._timeLimitInfo
    if not timeLimitInfo then
        self:TimerStop(self._timeLimitTimer)
        CS.ShowObject(self.mLimitTimeDiv,false)
        return
    end
    local endTime = timeLimitInfo.endTime
    local curTime = GetTimestamp()
    local timeLeft = endTime - curTime
    local timeStr = ""
    if timeLeft > 0 then
        timeStr = string.format(timeLimitInfo.txt,LUtil.GetFormatCDTime(timeLeft))
    end
    self:SetWndText(self.mLimitTime,timeStr)
    CS.ShowObject(self.mLimitTimeDiv,true)
end

function UISubPkB:SetTime()
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
    else
        str = ccClientText(14302) .. timeStr
    end
    self:SetWndText(self.mTimeText, str)
    CS.ShowObject(self.mTimeBg, true)
end

function UISubPkB:InitMessage()
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

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if sid ~= self._sid then
            return
        end
        self:OnActivityConfigData()
    end)

    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(...)
        self:OnTargetWndClose(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityABCDRewardResp, function(pb)
        self:OnActivityABCDRewardResp(pb)
    end)
end

function UISubPkB:OnClickHelp()
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

function UISubPkB:CheckNeedShowGiftPop(getList)
    local canBuyIndex
    for i = 1, self._grade do
        local guyId = self._bGuys[i]
        if (guyId == "0") then
            canBuyIndex = i
            break
        end
    end

    --礼包已购买
    if not canBuyIndex then
        return false, nil
    end

    local haveLast = false
    local getIndex
    local getLastData
    local typeIndexList = {}
    for k, v in ipairs(getList) do
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(v.sid, v.pageId, v.entryId)
        local typeIndex = tonumber(entryCfg1.moreInfo)

        typeIndexList[typeIndex] = true

        --检测是否跨阶级领取了奖励
        if getIndex and getIndex < typeIndex then
            haveLast = true
            break
        end

        if canBuyIndex <= typeIndex then
            getIndex = typeIndex
            getLastData = v
        end
    end

    if not getLastData or haveLast then
        return haveLast, typeIndexList
    end

    --检测是否领取了当前阶级的最后一个
    local nextEntryCfg1 = gModelActivity:GetWebActivityEntryData(getLastData.sid, getLastData.pageId, getLastData.entryId + 1)
    if not nextEntryCfg1 then
        --为最后一个，没有下一个了
        return true, typeIndexList
    end

    local nextTypeIndex = tonumber(nextEntryCfg1.moreInfo)
    if nextTypeIndex > getIndex then
        haveLast = true, typeIndexList
    end

    return haveLast, typeIndexList
end

function UISubPkB:OnClickBuyAdvance(index)
    --购买进阶令
    local curPage = self.pages[UISubPkB.PAGE_BUY]
    if not curPage then return end

    local entry = curPage.entry
    local titleName = self._activityCfg.name
    GF.OpenWnd("UIPkBuyPopBig",{
        sid = self._sid,
        entry = entry,
        grade = self._grade,
        index = index,
        modelActivityType = ModelActivity.MODEL_PASSB,
        titleName = titleName
    })
end

function UISubPkB:ResetData(pb)
    local sid = pb.sid
    if (self._sid ~= sid) then
        return
    end
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        self.pages[v.pageId] = page
    end
    self:RefreshData()
    self:RefreshLimitTime()
end

function UISubPkB:OnTargetWndClose(wndName)
    if wndName == "UIAward" and self._needShowGift then
        --重新开启滑动
        self:ShowGiftPop()
    end
end

function UISubPkB:RefreshData()
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    local data = JSON.decode(activityData.moreInfo)
    local buyPassNum = data.buyPassNum
    self._bGuys = string.split(buyPassNum, ",")

    self._endTime = tonumber(activityData.endTime)
    if activityData.model == ModelActivity.MODEL_PASSC then
        self._endTime = data.playerEndTime / 1000
    end

    if not string.isempty(data.timePosition) then
        local pos = LxDataHelper.ParseVector2NotEmpty(data.timePosition)
        self:SetAnchorPos(self.mTimeBg, pos)
    end


    self:SetTime()
    if not self:IsTimerExist(self._passKey) then
        self:TimerStart(self._passKey, 1, false, -1)
    end
    self._timeDes = data.timeDes
    self._completeIndex = 0
    local schedule = 0
    local moreInfo = 10

    local eliteList = {}
    local advanceList = {}
    if self.pages[UISubPkB.PAGE_ELITE] then
        eliteList = self.pages[UISubPkB.PAGE_ELITE].entry
    end
    if self.pages[UISubPkB.PAGE_ADVANCE] then
        advanceList = self.pages[UISubPkB.PAGE_ADVANCE].entry
    end

    local showCheckBuyState=self._activityCfg.showMode==1


    local dataAList = {}
    self._grade = 1
    for i, v in ipairs(eliteList) do
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, v.entryId)
        local moreInfoIndex = tonumber(entryCfg1.moreInfo)
        if (moreInfo < moreInfoIndex) then
            break
        end

        --这里顺便判断对应的阶段  应该是上个阶段
        if showCheckBuyState then
            local buyIndex = moreInfoIndex - 1
            if buyIndex > 0 then
                local buyState = tonumber(self._bGuys[buyIndex])

                if buyState == 0 then
                    break
                end
            end
        end

        local data = advanceList[i]
        v.goalData2 = data.goalData
        v.moreInfo2 = data.moreInfo
        v.pageId2 = data.pageId
        v.entryId2 = data.entryId
        table.insert(dataAList, v)
        self._grade = moreInfoIndex
        if (v.goalData.status ~= 0) then
            self._completeIndex = i
        else
            moreInfo = moreInfoIndex
        end
        local scdle = tonumber(v.goalData.schedules[1].schedule)
        if (scdle > 0) then
            if (schedule < scdle) then
                schedule = scdle
            end
        end
    end

    CS.ShowObject(self.mUpRedImg, false)
    local isShowBuy = false
    for i = 1, self._grade do
        local guyId = self._bGuys[i]
        if (guyId == "0") then
            CS.ShowObject(self.mUpRedImg, true)
            local entry = self.pages[UISubPkB.PAGE_BUY].entry
            local data = entry[i]
            local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, data.pageId, data.entryId)
            local moreInfoArr = string.split(entryCfg1.moreInfo, "|")
            local str = moreInfoArr[2] or moreInfoArr[1]
            self:SetWndText(self.mUpRedTxt, str)

            local expend2 = tonumber(entryCfg1.expend2)
            str = gModelPay:GetShowByWelfareId(expend2)
            self:SetWndButtonText(self.mBuyBtn, str)
            isShowBuy = true
            break
        end
    end
    CS.ShowObject(self.mBuyBtn, isShowBuy)
    CS.ShowObject(self.mShowImg, not isShowBuy)
    CS.ShowObject(self.mTopTitle, true)

    local index = self._completeIndex - 1
    if (index < 4) then
        index = 0
    else
        index = index - 2
    end
    if (self._uiList) then
        self._uiList:RefreshData(dataAList)
        self._uiList:MoveToPos(index + 1)
        self._uiList:DrawAllItems(false)
    else
        self._uiList = self:GetUIScroll("cell")
        self._uiList:Create(self.mCellScroll, dataAList, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER_GRID, false)
        self._uiList:MoveToPos(index + 1)
        self._uiList:DrawAllItems(true)
    end
    --local list= self._uiList:GetList()

    --list:SetLoadAnimationScale(1)
    --list:EnableLoadAnimation(true, 0, 1)
    --list:RefreshList(UIListWrap.RefreshMode.Custom,index)


    local text = self._showItemDesc
    local pos = self._showItemDescPosition

    if text and text ~= "" then
        --self:SetWndText(self.mTimeText,string.replace(text,schedule))
        --CS.ShowObject(self.mTimeBg,true)
        --self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(pos))

        self:SetWndText(self.mScheduleText, string.replace(text, schedule))
        self:InitTextLineWithLanguage(self.mScheduleText, -30)
        self:InitTextSizeWithLanguage(self.mScheduleText, -2)
        CS.ShowObject(self.mScheduleText, true)
    end

    text = self._activityCfg.taskDesc
    if text then
        self:SetWndText(self.mDesText, text)
        CS.ShowObject(self.mDesText, true)
    end
end

function UISubPkB:RewardListItem(list, item, itemdata, itempos)
    local itemRoot = self:FindWndTrans(item, "itemRoot")
    local root = self:FindWndTrans(item, "itemRoot/Icon")
    local mask = self:FindWndTrans(item, "Mask")
    local itemNum = self:FindWndTrans(item, "itemNum")
    local EffTrans = self:FindWndTrans(item, "Eff")
    local showEff = true
    if (mask) then
        CS.ShowObject(mask, false)
    end
    if (not self._bGuys) then
        self._bGuys = {}
    end
    local bGuy = tonumber(self._bGuys[itemdata.moreInfo]) == 1

    if (itemdata.index == 2 and not bGuy) then
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
                self:CreateWndEffect(EffTrans, bgEff, instanceId, 78, false, false)
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
    self:SetWndText(itemNum, itemdata.itemNum)
    self:SetIconClickScale(root, true)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)

    --self:SetWndText(itemNum,LUtil.NumberCoversion(itemCount))
end

function UISubPkB:InitCommand()
    self._sid = self:GetWndArg("sid")
    local _sid = self._sid
    gModelActivity:ReqActivityConfigData(_sid)
end

function UISubPkB:ListItem(list, item, itemdata, itempos)
    local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId, itemdata.entryId)
    local entryCfg2 = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId2, itemdata.entryId2)
    if not entryCfg1 or not entryCfg2 then
        return
    end
    local numText = CS.FindTrans(item, "NumText")
    local rewardList1 = CS.FindTrans(item, "RewardList1")
    local rewardList2 = CS.FindTrans(item, "RewardList2")
    local btnBlue3 = CS.FindTrans(item, "BtnBlue3")
    local btnYellow3 = CS.FindTrans(item, "BtnYellow3")
    local payBtnEff = CS.FindTrans(btnYellow3, "Eff")
    local getImage = CS.FindTrans(item, "GetImage")
    local image = CS.FindTrans(item, "Image")
    local moreInfo = tonumber(entryCfg1.moreInfo)
    local iconStr = entryCfg1.icon
    local getIconPath = self._getIconPath
    local InstanceID = item:GetInstanceID()
    local reward1List = LxDataHelper.ParseItem(entryCfg1.reward)
    if (reward1List) then
        for i, v in ipairs(reward1List) do
            v.index = 1
            v.moreInfo = moreInfo
        end
    end
    local uiList = self:GetUIScroll(InstanceID .. "A")
    if (uiList:GetList()) then
        uiList:RefreshList(reward1List)
    else
        uiList:Create(rewardList1, reward1List, function(...)
            self:RewardListItem(...)
        end)
    end

    local uiList1 = self:GetUIScroll(InstanceID .. "B")
    local reward2List = LxDataHelper.ParseItem(entryCfg2.reward)
    if (reward2List) then
        for i, v in ipairs(reward2List) do
            v.index = 2
            v.moreInfo = moreInfo
        end
    end
    if (uiList1:GetList()) then
        uiList1:RefreshList(reward2List)
    else
        uiList1:Create(rewardList2, reward2List, function(...)
            self:RewardListItem(...)
        end)
    end
    local entryId = itemdata.entryId
    local status1 = itemdata.goalData.status
    local status2 = itemdata.goalData2.status
    local bGuy = tonumber(self._bGuys[moreInfo]) == 1
    local fun = function()
        self:OnClickGoOn(entryCfg1.jumpId)
    end
    local btnStr = ccClientText(15804)
    local isGray = false
    local isShowGetEff = false
    local hideBtn
    local payBtn
    if (status1 == 1) then
        payBtn = btnYellow3
        hideBtn = btnBlue3
        btnStr = ccClientText(15802)
        isShowGetEff = true
        fun = function()
            self:OnClickOneKeyGet(entryId)
        end
    elseif (status1 == 2) then
        payBtn = btnYellow3
        hideBtn = btnBlue3
        btnStr = ccClientText(15803)
        if (status2 == 2) then
            btnStr = ccClientText(15807)
            isGray = true
            fun = nil
        elseif (bGuy) then
            isShowGetEff = true
            fun = function()
                self:OnClickOneKeyGet(entryId)
            end
        else
            fun = function()
                self:OnClickBuyAdvance(moreInfo)
            end
        end
    else
        payBtn = btnBlue3
        hideBtn = btnYellow3
    end
    CS.ShowObject(getImage, isGray)
    CS.ShowObject(payBtn, not isGray)
    CS.ShowObject(hideBtn, false)

    if LxUiHelper.IsImgPathValid(getIconPath) then
        self:SetWndEasyImage(getImage, getIconPath, nil, true)
    end

    self:SetWndEasyImage(image, iconStr)
    self:SetWndButtonText(payBtn, btnStr)
    local str = string.gsub(entryCfg1.name, "\\n", "\n")
    self:SetWndText(numText, str)
    if (fun) then
        self:SetWndClick(payBtn, fun)
    end

    local instanceId = item:GetInstanceID()
    local effKey = self._getBtnEff .. instanceId
    self:DestroyWndEffectByKey(effKey)

    if isShowGetEff then
        self:CreateWndEffect(payBtnEff, self._getBtnEff, effKey, 100, false, false)
    end
    CS.ShowObject(payBtnEff, isShowGetEff)
end

function UISubPkB:OnClickOneKeyGet(entryId)
    --一键领取
    local list = {}
    local checkList = {}
    local getEntryIdList = {}
    local bGuys = self._bGuys
    local advanceList = self.pages[UISubPkB.PAGE_ADVANCE].entry

    for i, v in ipairs(self.pages[UISubPkB.PAGE_ELITE].entry) do
        local curEntryId = v.entryId
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, curEntryId)
        local status = v.goalData.status
        local classIndex = tonumber(entryCfg1.moreInfo)
        local curBGuy = bGuys[classIndex]
        local isBuy = curBGuy == "1"

        if (status == 1) then
            local data1 = { sid = self._sid, pageId = v.pageId, entryId = curEntryId }
            table.insert(list, data1)
            table.insert(checkList, data1)
            getEntryIdList[curEntryId] = true
        elseif not isBuy and status == 2 then
            getEntryIdList[curEntryId] = true
        end

        if isBuy then
            local advanceData = advanceList[i]
            local status2 = advanceData.goalData.status
            if status2 == 1 then
                local data2 = { sid = self._sid, pageId = advanceData.pageId, entryId = advanceData.entryId }
                table.insert(list, data2)
            end
        end
    end

    --检测是否要显示礼包购买弹窗
    self._needShowGift, self._getGiftTypeList = self:CheckNeedShowGiftPop(checkList)

    --检测是否显示战令奖励弹窗
    self._passRewardItemList = self:GetShowPassRewardList(getEntryIdList)

    gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UISubPkB:RefreshLimitTime()
    self:TimerStop(self._timeLimitTimer)
    local extraInfo = gModelActivity:GetModel13ConfigExtraInfo(self._sid)
    if not extraInfo then
        CS.ShowObject(self.mLimitTimeDiv,false)
        return
    end
    local pageBuy = self.pages[UISubPkB.PAGE_BUY]
    if not pageBuy then
        CS.ShowObject(self.mLimitTimeDiv,false)
        return
    end

    local cdInfo
    local entry = pageBuy.entry
    for i,v in ipairs(entry) do
        local entryId = v.entryId
        local entryInfo = extraInfo[entryId]
        if entryInfo then
            ---@type StructMarketData
            local MarketData = v.MarketData
            if MarketData then
                local loseCnt = MarketData.personalGoal - MarketData.personal
                if loseCnt > 0 then
                    cdInfo = {
                        txt = entryInfo.rewardText,
                        endTime = entryInfo.createRoleEndTime,
                    }
                    break
                end
            end
        end
    end
    if not cdInfo then
        self:SetWndText(self.mLimitTime,"")
        return
    end
    self._timeLimitInfo = cdInfo
    if not self:IsTimerExist(self._timeLimitTimer) then
        self:TimerStart(self._timeLimitTimer, 1, false, -1)
    end
end

---------------------------------------获得奖励弹窗----------------------------------------------
function UISubPkB:GetShowPassRewardList(getEntryIdList)
    --检测是否显示战令的特殊获得奖励弹窗
    local canBuyIndex
    for i = 1, self._grade do
        local guyId = self._bGuys[i]
        if (guyId == "0") then
            canBuyIndex = i
            break
        end
    end

    --礼包已购买
    if not canBuyIndex then
        return nil
    end

    local list = {}
    local buyIndexList = {}

    --可以领取的进阶版奖励
    for i, v in ipairs(self.pages[UISubPkB.PAGE_ADVANCE].entry) do
        local entryId = v.entryId
        if getEntryIdList[entryId] then
            local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, entryId)
            local buyIndex = tonumber(entryCfg1.moreInfo)
            if (self._bGuys[buyIndex] == "0") then
                buyIndexList[buyIndex] = true

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
    end

    --直购奖励
    for i, v in ipairs(self.pages[UISubPkB.PAGE_BUY].entry) do
        if buyIndexList[i] then
            local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, v.entryId)
            local itemList = LxDataHelper.ParseItem(entryCfg1.reward) or {}
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

    local resultList = {}
    for k, v in pairs(list) do
        table.insert(resultList, v)
    end

    return resultList
end

function UISubPkB:OnClickGoOn()
    --前往
    gModelFunctionOpen:Jump(self._jump, self:GetWndName())
end

function UISubPkB:OnActivityConfigData()
    local activityData = gModelActivity:GetWebActivityDataById(self._sid)
    local data = activityData.config
    self._activityCfg = data
    local path, pos, text
    pos = data.ReturnMultiplePosition
    text = data.ReturnMultiple
    path = data.timesIcon
    if (text and text ~= "") then
        self:SetWndText(self.mRatioText, LUtil.FormatHurtNumSpriteText(text))
        self:SetAnchorPos(self.mRatioText, LxDataHelper.ParseVector2NotEmpty(pos))
        if LxUiHelper.IsImgPathValid(path) then
            self:SetWndEasyImage(self.mRatioIcon, path, function()
                CS.ShowObject(self.mRatioIcon, true)
            end, true)
        end
    end

    path = data.buttonIcon
    pos = data.buttonPosition
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mBuyBtn, path, function()
        end, true)
        self:SetAnchorPos(self.mBuyBtn, LxDataHelper.ParseVector2NotEmpty(pos))
    end

    path = data.image
    if LxUiHelper.IsImgPathValid(path) then
        --self:SetWndEasyImage(self.mTop, path, nil, true)
        self:SetWndEasyImage(self.mTop, path, nil, false)
    end
    path = data.descIcon
    pos = data.descIconPosition
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mTextImg, path, function()
            CS.ShowObject(self.mTextImg, true)
        end, true)
        self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(pos))
    end

    path = data.activateIcon
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mShowImg, path, nil, true)
    end

    self._getIconPath = data.getIcon

    local showHelp = data.helpTips == 1
    CS.ShowObject(self.mHelpBtn, showHelp)
    pos = data.helpTipsPosition
    if showHelp then
        self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(pos))
    end
    text = data.listDesc
    if text then
        local listDescArr = string.split(text, "|")
        self:SetWndText(self.mText1, listDescArr[1])
        self:SetWndText(self.mText2, listDescArr[2])
        self._popDescStr = listDescArr[2]
    end

    pos = data.limitTimeDivPosition
    self:SetAnchorPos(self.mLimitTimeDiv, LxDataHelper.ParseVector2NotEmpty(pos))


    --self._timeDes = data.timeDes
    self._jump = data.jump
    self._showItemDesc = data.showItemDesc
    self._showItemDescPosition = data.showItemDescPosition

    gModelActivity:OnActivityPageReq(self._sid)
end
------------------------------------------------------------------
return UISubPkB