---
--- Created by Administrator.
--- DateTime: 2023/10/10 22:18:48
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActLimitWeekCard:LWnd
local UIActLimitWeekCard = LxWndClass("UIActLimitWeekCard", LWnd)

UIActLimitWeekCard.TYPE_BUY = 1
UIActLimitWeekCard.TYPE_GIFT = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActLimitWeekCard:UIActLimitWeekCard()
    self._endTimerKey = "_endTimeKey"
    self._signInDayTimerKey = "_signInDayTimerKey"
    self._boxOpenSineKey = "_boxOpenSineKey"
    self._cardListOpenSineKey = "_cardListOpenSineKey"
    self._showContentTime = "_showContentTime"
    self._boxOpenEffectKey = "_boxOpenEffectKey"
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActLimitWeekCard:OnWndClose()
    self:ClearEffectKeyList()

    if self._delayRefreshTimer then
        LxTimer.DelayTimeStop(self._delayRefreshTimer)
        self._delayRefreshTimer = nil
    end
    
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActLimitWeekCard:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActLimitWeekCard:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitStaticInfo()
    self:RefreshDayFirstRefPoint()
end

function UIActLimitWeekCard:OnDrawSignInDayCell(itempos)
    local item = self._rewardTransList[itempos]
    if not item then
        return
    end

    CS.ShowObject(item, true)

    local pageInfo = self._giftPageData
    if not pageInfo then
        return
    end

    local itemdata = pageInfo[itempos]
    if not itemdata then
        printInfoNR("self._giftPageData[itempos] is not find, itempos = " .. itempos)
        return
    end

    local status = itemdata.getStatus
    local dayIndex = tonumber(itemdata.moreInfo)
    local isNextDay = dayIndex == (self._openDay + 1)
    local notOpenDay = dayIndex > self._openDay
    local isOpenDay = not notOpenDay
    local hadGet = status == 2
    local canGet = status == 1

    local instanceId = item:GetInstanceID()

    self:SetWndClick(item, function()
        self:OnClickDayBtn(dayIndex)
    end)

    local rewards = itemdata.rewards
    local firstItem = rewards[1]
    local itemId = firstItem.itemId
    local itemType = firstItem.itemType
    local itemName
    if itemType == LItemTypeConst.TYPE_ITEM then
        itemName = gModelItem:GetNameByRefId(itemId)
    elseif itemType == LItemTypeConst.TYPE_HERO then
        local ref = gModelHero:GetHeroRef(itemId)
        itemName = gModelHero:GetHeroNameByRefId(ref.refId, ref.initStar)
    elseif itemType == LItemTypeConst.TYPE_EQUIP then
        local ref = gModelEquip:GetEquipRefByRefId(itemId)
        itemName = ccLngText(ref.name)
    else
        itemName = itemId
    end

    local IconTrans = self:FindWndTrans(item, "Icon")
    if IconTrans then
        local icon = gModelItem:GetItemIconByRefId(itemId)
        if LxUiHelper.IsImgPathValid(icon) then
            self:SetWndEasyImage(IconTrans, icon, function()
                CS.ShowObject(IconTrans, true)
            end, nil, true)
        end

        local showEffect = itemdata.showEffect
        if not string.isempty(showEffect) then
            local effectData = string.split(showEffect, '=')
            local effectName = effectData[1]
            local effectSize = tonumber(effectData[2]) or 1

            local key = effectName .. instanceId
            table.insert(self._effectKeyList, key)
            self:CreateWndEffect(IconTrans, effectName, key, effectSize * 100, false, false)
        end
    end

    local itemNum = firstItem.itemNum
    local ItemNumTrans = self:FindWndTrans(item, "ItemNum")
    if ItemNumTrans then
        self:SetWndText(ItemNumTrans, itemNum)
    end

    local ItemNameTrans = self:FindWndTrans(item, "ItemName")
    local isShowItemName = self._isShowItemName
    if ItemNameTrans then
        CS.ShowObject(ItemNameTrans, isShowItemName)
        if isShowItemName then
            self:SetWndText(ItemNameTrans, itemName)
            self:InitTextLineWithLanguage(ItemNameTrans, 30)
        end
    end

    local DayTxtTrans = self:FindWndTrans(item, "DayTxt")
    --if not isNextDay then
    local nameStr = string.replace(ccClientText(31102), LStringUtil.NumberToCN(itempos))
    self:SetWndText(DayTxtTrans, nameStr)
    --else
    --	self._signInNextDayTxt = DayTxtTrans
    --	if not self:IsTimerExist(self._signInDayTimerKey) then
    --		self:SignInNextDayTimeFunc()
    --		self:TimerStart(self._signInDayTimerKey, 1, false, -1)
    --	end
    --end
    CS.ShowObject(DayTxtTrans, true)

    local ClockTrans = self:FindWndTrans(item, "Clock")
    if ClockTrans then
        CS.ShowObject(ClockTrans, not isOpenDay)
    end

    local overBgTrans = self:FindWndTrans(item, "OverBg")
    local getBgTrans = self:FindWndTrans(item, "GetBg")
    local commonBgTrans = self:FindWndTrans(item, "CommonBg")
    CS.ShowObject(overBgTrans, hadGet)
    CS.ShowObject(getBgTrans, (isOpenDay and not hadGet) or canGet)
    CS.ShowObject(commonBgTrans, notOpenDay)

    local getImgTrans = self:FindWndTrans(item, "GetImg")
    if getImgTrans then
        CS.ShowObject(getImgTrans, hadGet)
    end
end

--#####################################################################################################################
--## View #############################################################################################################
--#####################################################################################################################
function UIActLimitWeekCard:ShowContent()
    CS.ShowObject(self.mContent, true)
end

function UIActLimitWeekCard:InitPara()
    self._sid = self:GetWndArg("sid")
    if not self._sid then
        local subpage = self:GetWndArg("subPage") --支持跳转
        if subpage then
            self._sid = gModelActivity:GetSidByUniqueJump(subpage)
        end
    end
    self._effectKeyList = {}
    self._isBuy = false
    self._rewardTransList = {}
    for i = 1, 7 do
        local trans = self:FindWndTrans(self.mRewardList, "ItemTemplate" .. i)
        table.insert(self._rewardTransList, trans)
    end

    gModelActivity:ReqActivityConfigData(self._sid)
end

--#####################################################################################################################
--## Spine ############################################################################################################
--#####################################################################################################################
function UIActLimitWeekCard:InitOpenSpine()
    -- self:CreateWndSpine(self.mBoxSpineRoot, "Haohuazhouka",self._boxOpenSineKey,false,function (spine)
    --     --spine:SetScale(1)
    -- 	spine:PlayAnimation(0,"open",false)
    -- 	spine:SetAnimationCompleteFunc(function()
    -- 		spine:PlayAnimation(0,"idle",true)
    -- 	end)

    -- 	self:TimerStart(self._showContentTime, 0.7, false,1)
    -- 	CS.ShowObject(self.mBoxSpineRoot, true)
    -- 	CS.ShowObject(self.mBoxEffRoot, true)
    -- end)


    -- self:CreateWndSpine(self.mCardSpineRoot, "fx_haohuakapai",self._cardListOpenSineKey,false,function (spine)
    -- 	--spine:SetScale(1)
    -- 	CS.ShowObject(self.mCardSpineRoot, true)
    -- end)
end

function UIActLimitWeekCard:ClearEffectKeyList()
    if not self._effectKeyList then
        return
    end
    for k, v in pairs(self._effectKeyList) do
        self:DestroyWndEffectByKey(v)
    end
    self._effectKeyList = {}
end

function UIActLimitWeekCard:AutoGetReward(isGet)
    if not self._isBuy then
        return false
    end

    local pageInfo = self._giftPageData
    if not pageInfo then
        return false
    end

    local data = {}
    for k, v in ipairs(pageInfo) do
        if v.getStatus == 1 then
            local curData = { sid = self._sid, pageId = v.pageId, entryId = v.entryId }
            table.insert(data, curData)
        end
    end

    if table.isempty(data) then
        return false
    end

    if isGet then
        gModelActivity:OnActivityReceiveGoalListReq(data)
    end

    return true
end

function UIActLimitWeekCard:SignInNextDayTimeFunc()
    if not CS.IsValidObject(self._signInNextDayTxt) then
        return
    end

    local endTime = LUtil.GetNextDayTimes(nil, 1)
    local timespan = endTime - GetTimestamp()
    if (timespan < 0) then
        return
    end
    local timeStr = LUtil.FormatTimespanNumber(timespan)
    self:SetWndText(self._signInNextDayTxt, timeStr)
end

function UIActLimitWeekCard:RefreshEndTime()
    local endTime = self._endTime
    local isShow = endTime and endTime > 0
    if not isShow then
        CS.ShowObject(self.mGiftEndTime, false)
        return
    end

    self:StarCountDown()
end

function UIActLimitWeekCard:InitData()
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end

    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end
    self._activityData = activityData
    local moreInfo = JSON.decode(activityData.moreInfo)

    local config = webData.config
    self._config = config

    self._endTime = activityData.endTime
    local openDay = moreInfo.openDay
    self._openDay = math.range(openDay, 1, 7)

    local itemName = config.itemName
    self._isShowItemName = not itemName or itemName == 1

    local path = config.image
    --if LxUiHelper.IsImgPathValid(path) then
    --	self:SetWndEasyImage(self.mViewBg, path,nil,true)
    --	CS.ShowObject(self.mViewBg, true)
    --end

    path = config.descIcon
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mTextImg, path, nil, true)
        CS.ShowObject(self.mTextImg, true)
    end

    local pos = config.descIconPosition
    if not string.isempty(pos) then
        self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(pos))
    end

    local helpTips = config.helpTips or 0
    local showHelp = helpTips == 1
    CS.ShowObject(self.mHelpBtn, showHelp)
    if showHelp then
        pos = config.helpTipsPosition
        if not string.isempty(pos) then
            self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(pos))
        end
    end

    -- local desText = config.desText
    -- if not string.isempty(desText) then
    -- 	self:SetWndText(self.mHelpTipStr, desText)
    -- end

    if not string.isempty(config.ImageHero) then
        local data = string.split(config.ImageHero, "=")
        if data[1] == "1" then
            self:SetWndEasyImage(self.mSpineImg, data[2])
        elseif data[1] == "2" then
            self:CreateWndSpine(self.mSpine, data[2], data[2], false)
        end
        CS.ShowObject(self.mSpineImg, data[1] == "1")
        CS.ShowObject(self.mSpine, data[1] == "2")
    end

    if not string.isempty(config.ImageHeroPos) then
        self:SetAnchorPos(self.mSpineImg, LxDataHelper.ParseVector2NotEmpty(config.ImageHeroPos))
        self:SetAnchorPos(self.mSpine, LxDataHelper.ParseVector2NotEmpty(config.ImageHeroPos))
    end

    if not string.isempty(config.privilegeHeroTurn) then
        local v = config.privilegeHeroTurn == "0" and 0 or 180
        self.mSpineImg.localRotation = Vector3.New(0, v, 0)
        self.mSpine.localRotation = Vector3.New(0, v, 0)
    end

    if not string.isempty(config.cost) then
        local text2 = CS.FindTrans(self.mBuyBtn, "Cost/Text2")
        self:SetWndText(text2, config.cost)
    end

    local countDown = config.countDown or 0
    local isShowEndTime = countDown == 1
    CS.ShowObject(self.mGiftEndTime, isShowEndTime)
    if isShowEndTime then
        self:RefreshEndTime()
        if self._endTime ~= 0 then
            self:TimerStart(self._endTimerKey, 1, false, -1)
        end
    end
end

function UIActLimitWeekCard:OnClickDayBtn(dayIndex)
    local pageData = self._giftPageData
    if table.isempty(pageData) then
        return
    end

    local entryData = pageData[dayIndex]
    if not entryData then
        printInfoNR("self._giftPageData[dayIndex] is a nil, dayIndex = " .. dayIndex)
        return
    end

    local str
    local status = entryData.getStatus
    if status == 0 then
        str = string.replace(ccClientText(31100), dayIndex)
        local itemInfo = entryData.rewards[1]
        gModelGeneral:ShowCommonItemTipWnd(itemInfo)
    elseif status == 1 then
        local data = {
            { sid = self._sid, pageId = entryData.pageId, entryId = entryData.entryId },
        }
        gModelActivity:OnActivityReceiveGoalListReq(data)
    elseif status == 2 then
        str = ccClientText(31101)
        local itemInfo = entryData.rewards[1]
        gModelGeneral:ShowCommonItemTipWnd(itemInfo)
    end

    if not string.isempty(str) then
        GF.ShowMessage(str)
    end
end

function UIActLimitWeekCard:InitEvent()
    self:SetWndClick(self.mBg, function()
        self:OnCloseFunc()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mHelpBtn, function()
        self:OnClickHelpBtn()
    end, LSoundConst.CLICK_ERROR_COMMON)
    self:SetWndClick(self.mBuyBtn, function(...)
        self:OnClickBuyBtn()
    end)
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIActLimitWeekCard:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end

    self:InitData()
    gModelActivity:OnActivityPageReq(self._sid)
end

function UIActLimitWeekCard:OnCloseFunc()
    self:WndClose()
end

function UIActLimitWeekCard:OnActivityPageResp(pb)
    local sid = pb.sid
    if sid ~= self._sid then
        return
    end

    self:ResetActivePageData(pb)

    local needAutoGet = false
    -- if self._isClickBuy and self._isBuy then
    -- needAutoGet = self:AutoGetReward(false)
    -- end

    if needAutoGet then
        return
    end

    self:RefreshView()
end

function UIActLimitWeekCard:StarCountDown()
    local lastTime = self._endTime - GetTimestamp()
    if lastTime < 0 then
        self:WndClose()
        return
    end

    local timeStr
    if lastTime > 86400 then
        --N天N小时
        timeStr = LUtil.FormatTimespanCn(lastTime)
    else
        --XX:XX:XX
        timeStr = LUtil.FormatTimespanNumber(lastTime)
    end

    timeStr = string.replace(ccClientText(31103), timeStr)
    self:SetWndText(self.mGiftEndTimeTxt, timeStr)
end

--#####################################################################################################################
--## Timer ############################################################################################################
--#####################################################################################################################
function UIActLimitWeekCard:OnTimer(key)
    if key == self._showContentTime then
        self:ShowContent()
    elseif key == self._endTimerKey then
        self:StarCountDown()
    elseif key == self._signInDayTimerKey then
        self:SignInNextDayTimeFunc()
    end
end

--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIActLimitWeekCard:ResetActivePageData(pb)
    if not self._activityPageData then
        self._activityPageData = {}
    end

    for k, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        if page then
            local pageId = v.pageId
            if pageId == UIActLimitWeekCard.TYPE_BUY then
                local entry = page.entry
                self._activityPageData[pageId] = entry
                for p, q in ipairs(entry) do
                    local personal = q.MarketData.personal or 0
                    self._isBuy = personal > 0

                    local text1 = CS.FindTrans(self.mBuyTips, "Text1")
                    local Space_en = CS.FindTrans(self.mBuyTips, "Space_en")
                    CS.ShowObject(Space_en,true)


                    local webConfig = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entry[1].entryId)
                    self:SetWndText(text1, webConfig.description)

                    self._delayRefreshTimer = LxTimer.DelayFrameCall(function()
                        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(text1)
                        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mBuyTips)
                    end, 1)


                    for i, v1 in ipairs(q.items) do
                        local icon = CS.FindTrans(self.mBuyTips, "Icon" .. i)
                        local text = CS.FindTrans(self.mBuyTips, "Text" .. i + 1)
                        if icon then
                            local res = gModelGeneral:GetCommonItemImgRef(v1)
                            self:SetWndEasyImage(icon, res)
                            self:SetWndText(text, "x" .. v1.count .. " ")

                            CS.ShowObject(icon, true)
                            CS.ShowObject(text, true)
                        end
                    end
                    CS.ShowObject(self.mBuyTips, true)
                end
            elseif pageId == UIActLimitWeekCard.TYPE_GIFT then
                self._activityPageData[pageId] = page
            end
        end
    end

    local page = self._activityPageData[UIActLimitWeekCard.TYPE_GIFT]
    local dataList = {}
    for p, q in ipairs(page.entry) do
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, q.entryId)
        if entryCfg then
            local entryId = q.entryId
            local status = q.status or q.goalData.status --(0-不可领取, 1-可领取，2-已领取)

            local data = {
                entryId = entryId,
                pageId = q.pageId,
                title = entryCfg.name,
                icon = entryCfg.icon,
                showEffect = entryCfg.showeffect,
                moreInfo = entryCfg.moreInfo,
                rewards = LxDataHelper.ParseItem(entryCfg.reward),
                getStatus = status,
                sort = entryCfg.sort,
            }

            table.insert(dataList, data)
        end
    end
    table.sort(dataList, function(a, b)
        local aSort = a.sort
        local bSort = b.sort
        if aSort ~= bSort then
            return a.sort < b.sort
        end

        return a.entryId < b.entryId
    end)
    self._giftPageData = dataList
end

function UIActLimitWeekCard:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        self:OnActivityListResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(...)
        self:OnTargetWndClose(...)
    end)
end

function UIActLimitWeekCard:OnActivityListResp(pb)
    local activities = pb.activities
    for i, v in ipairs(activities) do
        local sid = v.sid
        if self._sid == sid then
            self._activityData = gModelActivity:GetActivityBySid(self._sid)
            self._activityMoreInfo = JSON.decode(self._activityData.moreInfo)
            self:InitData()
            self:RefreshView()
            break
        end
    end
end

function UIActLimitWeekCard:OnClickHelpBtn()
    UIHelper.OnClickHelpBtn(self._sid)
end

function UIActLimitWeekCard:RefreshBuyBtn()
    local pageData = self._activityPageData[UIActLimitWeekCard.TYPE_BUY]
    if table.isempty(pageData) then
        return
    end

    local isShowBuy = not self._isBuy
    if isShowBuy then
        local entry = pageData[1]
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, entry.pageId, entry.entryId)
        if not entryCfg then
            return
        end

        local expend2 = tonumber(entryCfg.expend2)
        local str = gModelPay:GetShowByWelfareId(expend2)
        self:SetWndButtonText(self.mBuyBtn, str)
        if gLGameLanguage:IsJapanRegion()  then
            local isDmm = gLSdkImpl:CallMethod(LSdkMethod.IsDMMPlatform)
            if  isDmm  then
                local Cost = CS.FindTrans(self.mBuyBtn, "Cost")
                self:SetAnchorPos(Cost,Vector2.New(-100,0))
                self:SetWndButtonText(self.mBuyBtn, str,nil,-10,nil)

                local lightText = CS.FindTrans(self.mBuyBtn, "Light/Text")
                local grayText = CS.FindTrans(self.mBuyBtn, "Gray/Text")
                LxUiHelper.SetSizeWithCurAnchor(lightText,0,120)
                LxUiHelper.SetSizeWithCurAnchor(grayText,0,120)
                self:InitTextLineWithLanguage(lightText,-50,true)
                self:InitTextLineWithLanguage(grayText,-50,true)
            end
        end
    end
    CS.ShowObject(self.mBuyBtn, isShowBuy)
    CS.ShowObject(self.mBuyImg, not isShowBuy)

end

function UIActLimitWeekCard:InitStaticInfo()
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    -- self:SetWndText(CS.FindTrans(self.mBuyImg, "UIText"), ccClientText(11406))
    self:SetWndText(CS.FindTrans(self.mBuyBtn, "Cost/Text1"), ccClientText(14914))

    if gLGameLanguage:IsKoreaRegion() then
        local text = ccClientText(156)
        if not string.isempty(text) then
            self:SetWndText(self.mBuyTipsText, text)
            CS.ShowObject(self.mBuyTipsText, true)
        end
    end

    self:InitOpenEff()
    self:InitOpenSpine()
end

function UIActLimitWeekCard:RefreshView()
    local pageInfo = self._giftPageData
    if not pageInfo then
        return
    end

    CS.ShowObject(self.mRewardList, true)
    for i = 1, 7 do
        self:OnDrawSignInDayCell(i)
    end

    self:RefreshBuyBtn()
end

function UIActLimitWeekCard:RefreshDayFirstRefPoint()
    local _sid = self._sid
    local pageIndex = 1
    local bool = gModelRedPoint:GetActivityRedPointPage(_sid, pageIndex)
    if bool then
        gModelActivity:OnActivitySpecialOpReq(_sid, pageIndex, nil, ModelActivity.CANCEL_RED_POINT, "1")
    end
end

--#####################################################################################################################
--## Effect ###########################################################################################################
--#####################################################################################################################
function UIActLimitWeekCard:InitOpenEff()
    self:CreateWndEffect(self.mBoxEffRoot, "fx_ui_haohuazhounianka", self._boxOpenEffectKey, 100, false, false)
    CS.ShowObject(self.mBoxEffRoot, true)
end

function UIActLimitWeekCard:OnClickBuyBtn()
    local pageData = self._activityPageData[UIActLimitWeekCard.TYPE_BUY]
    if table.isempty(pageData) then
        return
    end

    local entry = pageData[1]

    local entryId = entry.entryId
    local expend2 = tonumber(entry.MarketData.expend2)
    local pageId = entry.pageId
    self._isClickBuy = true
    gModelPay:GiftPayCtrl(entryId, expend2, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, pageId)
end

function UIActLimitWeekCard:OnTargetWndClose(wndName)
    if wndName == "UIAward" then
        -- if self._isClickBuy and self._isBuy then
        -- self:AutoGetReward(true)
        -- end

        self._isClickBuy = false
    end
end

------------------------------------------------------------------
return UIActLimitWeekCard