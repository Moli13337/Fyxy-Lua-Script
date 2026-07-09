---
--- Created by Administrator.
--- DateTime: 2025/4/16 18:21:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivityGiftModel4Pop:LWnd
local UIActivityGiftModel4Pop = LxWndClass("UIActivityGiftModel4Pop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivityGiftModel4Pop:UIActivityGiftModel4Pop()
    self._uiCommonList = {}

    ---@type number
    self._pageId = nil

    ---@type table<number,StructActivityPage>
    self._pageDataMap = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivityGiftModel4Pop:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivityGiftModel4Pop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivityGiftModel4Pop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitStaticText()

    self:InitEvent()
    self:InitMsg()

    self:OnWndRefresh()
end

function UIActivityGiftModel4Pop:RefreshFuncBtnShow()
    if self._shopIconJump then
        local isShow = gModelFunctionOpen:CheckIsShow(self._shopIconJump)
        CS.ShowObject(self.mGiftImg, isShow)
    end
end

function UIActivityGiftModel4Pop:SetGiftBtnStatus()
    self:RefreshFuncBtnShow()
    self:RefreshShopRed()
end

function UIActivityGiftModel4Pop:SetPageScroll()
    local list = self:GetScrollList()
    -- 绘制这块的页面
    ---@type UIItemList
    local uiPageScroll = self._uiPageScroll
    if uiPageScroll then
        uiPageScroll:RefreshList(list)
        uiPageScroll:DrawAllItems()
    else
        uiPageScroll = self:GetUIScroll("pageScroll")
        self._uiPageScroll = uiPageScroll
        uiPageScroll:Create(self.mPageScroll, list, function(...)
            self:DrawPageListItem(...)
        end, UIItemList.SUPER)
        uiPageScroll:EnableScroll(true, true)
    end
end

function UIActivityGiftModel4Pop:OnClickGift()
    --特惠商店的跳轉
    local id = self._shopIconJump
    local isOpen = gModelFunctionOpen:CheckIsOpened(id, true)
    if not isOpen then return end

    gModelFunctionOpen:Jump(id, self:GetWndName())
end

function UIActivityGiftModel4Pop:OnInitActivityPanel(pb)
    local sid = pb.sid
    if self._sid ~= sid then return end

    --分页的服务器数据
    local pageDataMap = self._pageDataMap

    local needPop = not self._isPage1AllBuy

    local page1Id = ModelActivity.DAILY_GIFT_TYPE_COMMON
    local oldBuyNum = 0
    --- 计算是否一键购买，如果是一键购买完成，需要弹出积分礼包界面
    local oldPageDataMap = pageDataMap
    if oldPageDataMap and needPop then
        oldBuyNum = self:GetCurByNum(oldPageDataMap[page1Id])
    end


    if not pageDataMap then
        pageDataMap = {}
        self._pageDataMap = pageDataMap
    end
    local pageId = self._pageId
    for i, v in ipairs(pb.pages) do
        ---@type StructActivityPage
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        pageDataMap[page.pageId] = page

        if not pageId then
            pageId = page.pageId
            self._pageId = pageId
        end
    end

    local newPageData = pageDataMap[page1Id]
    if newPageData then
        local newBuyNum,allEntryCnt = self:GetCurByNum(newPageData)
        if newBuyNum >= oldBuyNum and newBuyNum >= allEntryCnt and needPop then
            --- 一键购买
            self:RefreshPage1AllBuy()
            if self._isPage1AllBuy then
                local actData = gModelActivity:GetActivityBySid(sid)
                if actData then
                    local func = gModelActivity:GetShowActivityFun(ModelActivity.MODEL_ACTIVITY_TYPE_164_1)
                    if func then
                        self._actFunc = function()
                            func(actData)
                        end
                    end
                end
            end
        end
    end

    self:SetPagePanel()
    -- 页面设置
    self:SetGiftBtnStatus()
    self:SetPageScroll()

    self:SetOneKeyBuyStatus()
    self:SetPageRedPoint()
end

function UIActivityGiftModel4Pop:OnClickPay(itemdata)
    ----点击购买
    --if self._bBuyAll then
    --    self._isClickBuy = true
    --    gModelActivity:OnActivitySpecialOpReq(self._sid, itemdata.pageId, itemdata.entryId, 3)
    --    return
    --end

    local expend2 = itemdata.expend2
    if expend2 == -1 then
        gModelActivity:OnActivityMarkeyBuyReq(self._sid, itemdata.pageId, itemdata.entryId)
        self._isClickBuy = true
        return
    end

    self._isClickBuy = true
    gModelPay:GiftPayCtrl(itemdata.entryId, expend2, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, itemdata.pageId)
end

function UIActivityGiftModel4Pop:CheckPageIdRedPoint(pageId)
    if self:CheckIsGiftPage(pageId) then
        local marketGiftData = self._marketGiftData or {}
        for i,v in ipairs(marketGiftData) do
            if v.expend2 == -1 and v.loseNum > 0 then
                return true
            end
        end
    else
        ---@type StructActivityPage
        local pageData = self._pageDataMap[pageId]
        local entry = pageData and pageData.entry
        if entry and #entry > 0 then
            local entry1 = entry[1]
            ---@type StructGoalData
            local goalData = entry1.goalData
            --状态(0-不可领取, 1-可领取，2-已领取)
            return goalData.status == 1
        end
    end
    return false
end

function UIActivityGiftModel4Pop:OnClickOneBuy()
    if self._bNoBuyAll then
        GF.ShowMessage(ccClientText(15621))
        return
    end
    if not self._isOneKeyBuy then
        GF.ShowMessage(ccClientText(15629))
        return
    end

    local pageId = self._pageId
    local pageData = self._pageDataMap[pageId]
    if not pageData then return end

    local entryIdList = {}
    local entry = pageData.entry or {}
    for i, v in ipairs(entry) do
        local MarketData = v.MarketData
        local personalGoal,personal = MarketData.personalGoal,MarketData.personal
        if personalGoal - personal > 0 then
            table.insert(entryIdList,v.entryId)
        end
    end
    self._isClickBuy = true
    local entryIdStr = table.concat(entryIdList,"#")
    gModelPay:GiftPayCtrl(entryIdStr, self._buyAllExpend, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, pageId)
end

---@param pageData StructActivityPage
function UIActivityGiftModel4Pop:GetCurByNum(pageData)
    if not pageData or #pageData.entry < 1 then return 0,0 end

    local allEntryCnt = 0
    local buyNum = 0
    ---@type StructActivityEntry[]
    local entry = pageData.entry
    for i,v in ipairs(entry) do
        ---@type StructMarketData
        local MarketData = v.MarketData
        local personalGoal = MarketData.personalGoal
        if personalGoal == 1 and personalGoal - MarketData.personal < 1 then
            buyNum = buyNum + 1
        end
        allEntryCnt = allEntryCnt + 1
    end
    return buyNum,allEntryCnt
end

function UIActivityGiftModel4Pop:SetOneKeyBuyStatus()
    if not self._isOpenOneKeyBuy then return end

    --这个面板只处理1的情况
    if self._isNotBuyAllType then return end

    local discount = 0
    local cost = self._cost or 0 -- 与礼包价格相关 在处理礼包时进行计算
    local buyAllExpend = nil
    local buyAllArr = self._buyAllExpend2 or {}
    for i, v in ipairs(buyAllArr) do
        local costArr = string.split(v, "=")
        local costNum = checknumber(costArr[1])
        buyAllExpend = checknumber(costArr[2])
        if costNum == cost then
            discount = checknumber(costArr[3])
            break
        end
    end
    self._buyAllExpend = buyAllExpend

    -- 描述  --UI无体现 屏蔽
    --local buyAllDescription2 = data.buyAllDescription2
    --if(buyAllDescription2)then
    --    local str = string.gsub(buyAllDescription2,"\\n",'\n')
    --end

    -- 按钮描述
    local payTextStr = ""
    if buyAllExpend then
        -- string.replace(ccClientText(15603),priceCost)
        payTextStr = string.replace(ccClientText(15603), gModelPay:GetShowByWelfareId(tonumber(buyAllExpend)))
    end
    self:SetWndText(self.mCurPrice, payTextStr)
    self:SetTextTile(self.mBuyBtn, self._oneKeyBuyStr)
end

function UIActivityGiftModel4Pop:DrawGiftListItem(list, item, itemdata, itempos)
    local Title = CS.FindTrans(item, "Title")
    local BuyBtn = CS.FindTrans(item, "BuyBtn")
    local Mask = CS.FindTrans(item, "Mask")
    local ItemList = CS.FindTrans(item, "ItemList")
    local payText = CS.FindTrans(BuyBtn, "UIText")
    --获取条目的配置信息
    --local pageId = itemdata.pageId
    --local entryId = itemdata.entryId
    --local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entryId)

    local bBuy = itemdata.loseNum > 0
    local personalGoal, personal = itemdata.personalGoal, itemdata.personal
    --标题 -- NumText 限购
    --local title = gModelActivity:GetLngNameById(entryCfg.name)
    --self:SetWndText(Title, title)
    local numTextStr = string.replace(ccClientText(15600), personalGoal - personal)
    self:SetWndText(Title, numTextStr)

    self:InitTaskItemList(ItemList,itemdata.items)

    --价格部分的设置
    local buyStr = ""
    local buyEnd = false
    local showRed = false
    local showMask = false
    local showBuyBtn = false
    if bBuy then
        --- 可以购买全部的情况下也需要显示价格
        --if self._bBuyAll then
        --    buyStr = ccClientText(15617)
        --else
        --end

        showRed = true
        local expend2 = itemdata.expend2
        if checknumber(expend2) == -1 then
            buyStr = ccClientText(10771)
        else
            buyStr = gModelPay:GetShowByWelfareId(tonumber(expend2))
        end
        showBuyBtn = true
    else
        buyStr = ccClientText(15618)
        buyEnd = true
        showMask = true
    end
    CS.ShowObject(Mask, showMask)
    CS.ShowObject(BuyBtn, showBuyBtn)

    self:SetWndText(payText, buyStr)

    self:SetWndClick(item, function(...)
        if bBuy then
            self:OnClickPay(itemdata)
        else
            GF.ShowMessage(ccClientText(15606))
        end
    end)
end

function UIActivityGiftModel4Pop:RefreshPage1AllBuy()
    self._isPage1AllBuy = false
    local actData = gModelActivity:GetActivityBySid(self._sid)
    if actData then
        local info = actData:GetMoreInfo()
        self._isPage1AllBuy = info.page1AllBuy or false
    end
end

--任务界面
function UIActivityGiftModel4Pop:SetTaskPagePanel()
    --取下对应的配置
    local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, self._pageId, 1)
    if not entryCfg then return end

    local rewards = LxDataHelper.ParseItem(entryCfg.reward)
    self:InitTaskItemList(self.mTaskItemList,rewards)

    local moreInfo = entryCfg.moreInfo
    local tempData = string.split(moreInfo, "|")
    local bg = tempData[1]
    --描述图部分
    if LxUiHelper.IsImgPathValid(bg) then
        self:SetWndEasyImage(self.mTaskDes, bg, nil, true)
    end

    local bgPos = LxDataHelper.ParseVector2NotEmpty2(tempData[2])
    self:SetAnchorPos(self.mTaskDes, bgPos)


    local taskProgressStr = ""
    local btnStr
    local bGray = false
    local showRed = false
    ---@type StructActivityPage
    local pageData = self._pageDataMap[self._pageId]
    ---@type StructActivityEntry[]
    local entry = pageData and pageData.entry
    if entry and #entry > 0 then
        local entry1 = entry[1]
        ---@type StructGoalData
        local goalData = entry1.goalData
        --状态(0-不可领取, 1-可领取，2-已领取)
        local status = goalData.status
        if status == 0 then
            btnStr = gModelActivity:GetLngNameById(entryCfg.jumpDesc)
        elseif status == 1 then
            btnStr = ccClientText(12207)
            showRed = true
        elseif status == 2 then
            btnStr = ccClientText(12208)
            bGray = true
        end

        local schedule = goalData.schedules[1]
        taskProgressStr = string.replace("#a1#/#a2#", schedule.schedule, schedule.goal)
    end
    self:SetWndImageGray(self.mGetBtn, bGray)
    self:SetTextTile(self.mGetBtn,btnStr)
    self:SetWndText(self.mTaskProgress,taskProgressStr)
    CS.ShowObject(CS.FindTrans(self.mGetBtn, "redPoint"), showRed)
end

function UIActivityGiftModel4Pop:DrawRewardListItem(list, item, itemdata, itempos)
    local ItemIconRoot = self:FindWndTrans(item, "ItemIconRoot")
    local itype, refId, count = itemdata.type or itemdata.itemType, itemdata.itemId, itemdata.count or itemdata.itemNum
    local formatData = {
        itemId = refId,
        itemType = itype,
        itemNum = count,
    }

    local InstanceID = ItemIconRoot:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(ItemIconRoot)
    baseClass:SetCommonReward(itype, refId, count)
    baseClass:DoApply()
    self:SetIconClickScale(ItemIconRoot, true)
    self:SetWndClick(ItemIconRoot, function()
        gModelGeneral:ShowCommonItemTipWnd(formatData)
    end)
end

function UIActivityGiftModel4Pop:OnPageItemClick(itemdata)
    if self:CheckIsSelPage(itemdata) then return end

    self._pageId = itemdata.pageId

    ---@type UIItemList
    local uiPageScroll = self._uiPageScroll
    uiPageScroll:DrawAllItems()

    self:SetPagePanel()
end

function UIActivityGiftModel4Pop:GetScrollList()
    local list = {}
    local pageList = self._pageList or {}
    for i,v in ipairs(pageList) do
        local pageId = v.pageId
        local isShowRed = self:CheckPageIdRedPoint(pageId)
        table.insert(list,{
            name = v.name,
            pageId = pageId,
            isShowRed = isShowRed
        })
    end
    return list
end

function UIActivityGiftModel4Pop:SetPagePanel()
    if self:CheckIsGiftPage() then
        CS.ShowObject(self.mGiftDiv, true)
        CS.ShowObject(self.mTaskDiv, false)
        self:SetGiftPagePanel()
    else
        CS.ShowObject(self.mGiftDiv, false)
        CS.ShowObject(self.mTaskDiv, true)
        self:SetTaskPagePanel()
    end
end

function UIActivityGiftModel4Pop:CheckIsGiftPage(pageId)
    pageId = pageId or self._pageId
    return pageId == ModelActivity.DAILY_GIFT_TYPE_COMMON
end

--endregion --------------------------------------------------------------------------------------

--region 界面设置 --------------------------------------------------------------------------------
function UIActivityGiftModel4Pop:InitStaticText()
    self:SetTextTile(self.mCompletionDes, ccClientText(15639))

    local uiText = LxUiHelper.FindXTextCtrl(CS.FindTrans(self.mCompletionDes, "UIText"))
    local width = uiText.preferredWidth
    width = math.floor(width / 2)
    local posx = 75 + width
    self:SetAnchorPos(self.mRightArrow, Vector2.New(posx, 0))
    self:SetAnchorPos(self.mLeftArrow, Vector2.New(-posx, 0))
end

--region 事件 --------------------------------------------------------------------------------
function UIActivityGiftModel4Pop:InitEvent()
    self:SetWndClick(self.mBgImage, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mGiftImg, function(...)
        self:OnClickGift()
    end)
    self:SetWndClick(self.mBuyBtn, function(...)
        self:OnClickOneBuy()
    end)

    self:SetWndClick(self.mGetBtn, function()
        ---@type StructActivityPage
        local pageData = self._pageDataMap[self._pageId]
        if not pageData then return end

        ---@type StructActivityEntry[]
        local entry = pageData.entry
        if not entry or #entry < 1 then return end

        local entry1 = entry[1]
        ---@type StructGoalData
        local goalData = entry1.goalData
        --状态(0-不可领取, 1-可领取，2-已领取)
        local status = goalData.status
        if status == 1 then
            gModelActivity:OnActivityReceiveGoalReq(self._sid,self._pageId,entry1.entryId)
        elseif status == 0 then
            --取下对应的配置
            local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, self._pageId, 1)
            if not entryCfg then return end

            --- 跳转的话，需要清掉之前的数据
            gModelFunctionOpen:Jump(entryCfg.jumpId)
        end
    end)

    self:SetWndClick(self.mHelpBtn, function(...)
        UIHelper.OnClickHelpBtn(self._sid)
    end, LSoundConst.CLICK_ERROR_COMMON)
end
--endregion --------------------------------------------------------------------------------------

--region 初始化 --------------------------------------------------------------------------------
function UIActivityGiftModel4Pop:InitPara()
    self._isPage1AllBuy = false

    local sid = self:GetWndArg("sid")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        sid = gModelActivity:GetSidByUniqueJump(subpage)
    end
    if not sid then return end

    self._sid = sid
    self:RefreshPage1AllBuy()
    gModelActivity:ReqActivityConfigData(sid)
end

function UIActivityGiftModel4Pop:CheckIsSelPage(itemdata)
    return itemdata.pageId == self._pageId
end

function UIActivityGiftModel4Pop:OnWndRefresh()
    self:InitPara()
end

function UIActivityGiftModel4Pop:SetPageRedPoint()
    self:SetPageScroll()
end

function UIActivityGiftModel4Pop:RefreshShopRed()
    --local isRed = gModelRedPoint:CheckActivityShowRed(self._sid)

    local isRed = gModelRedPoint:CheckShowRedPoint(10405111)
    --isRed = isRed or gModelRedPoint:CheckShowRedPoint(10405111)
    CS.ShowObject(self.mRedPoint, isRed)
end

function UIActivityGiftModel4Pop:OnActivityConfigData(data, sid)
    if not data then
        self:WndClose()
        RInfoS("UIActivityGiftModel4Pop", "not webData close wnd")
        return
    end

    if sid ~= self._sid then return end

    -- config数据的获取
    local config = data.config
    self._shopIconJump = config.shopIconJump

    local shopname = config.shopname or ""
    self:SetWndText(self.mGiftText, shopname)
    self:InitTextSizeWithLanguage(self.mGiftText, -2)
    self:InitTextLineWithLanguage(self.mGiftText, -30)

    local hasHelp = not string.isempty(config.helpTipsContent)
    CS.ShowObject(self.mHelpBtn, hasHelp)

    local isOpenOneKeyBuy = checknumber(config.buyAllLimit) == 1
    CS.ShowObject(self.mBuyBtn, isOpenOneKeyBuy)
    CS.ShowObject(self.mBuyDes, isOpenOneKeyBuy)
    self._isOpenOneKeyBuy = isOpenOneKeyBuy

    self._isNotBuyAllType = checknumber(config.buyAllType) ~= 1

    self._buyAllExpend2 = string.split(config.buyAllExpend2, ";")

    -- 下方tips描述
    self:SetWndText(self.mBuyDes, gModelActivity:GetLngNameById(config.buyAllJump2))

    local pageList = {}
    local taskPage = gModelActivity:GetLngNameById(config.taskPage)
    taskPage = string.split(taskPage, "|")
    for k, v in ipairs(taskPage) do
        v = string.split(v, "=")
        table.insert(pageList, {
            name = v[3],
            pageId = checknumber(v[2]),
        })
    end
    self._pageList = pageList

    local freeIcon, freeIconPosition = config.freeIcon, config.freeIconPosition
    if LxUiHelper.IsImgPathValid(freeIcon) then
        self:SetWndEasyImage(self.mGiftImg, freeIcon, function()
            CS.ShowObject(self.mGiftImg, true)
        end, true)
        if not string.isempty(freeIconPosition) then
            self:SetAnchorPos(self.mGiftImg, LxDataHelper.ParseVector2NotEmpty(freeIconPosition))
        end
    else
        CS.ShowObject(self.mGiftImg, false)
    end
    self:CreateWndEffect(self.mGiftEff, "fx_tehuishangdian", "fx_tehuishangdian", 100)

    gModelActivity:OnActivityPageReq(self._sid)
end

function UIActivityGiftModel4Pop:InitTaskItemList(listTrans,rewards)
    rewards = rewards or {}
    local listKey = listTrans:GetInstanceID()
    local uiList = self:FindUIScroll(listKey)
    if uiList then
        uiList:RefreshData(rewards)
        uiList:DrawAllItems()
    else
        uiList = self:GetUIScroll(listKey)
        uiList:Create(listTrans, rewards, function(...)
            self:DrawRewardListItem(...)
        end, UIItemList.SUPER)
        uiList:EnableScroll(true)
    end
end

function UIActivityGiftModel4Pop:OnTryRefreshRedPoint()
    self:RefreshShopRed()
end

function UIActivityGiftModel4Pop:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnInitActivityPanel(pb)
    end)

    self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function(...)
        self:SetPageRedPoint()
    end)

    self:WndEventRecv(EventNames.CLOSE_REWARD_WND, function(...)
        local actFunc = self._actFunc
        self._actFunc = nil
        if actFunc then
            actFunc()
        end
    end)


end

function UIActivityGiftModel4Pop:SetGiftPagePanel()
    ---@type StructActivityPage
    local pageData = self._pageDataMap[ModelActivity.DAILY_GIFT_TYPE_COMMON]
    if not pageData then return end

    local sid = self._sid
    local list = {}
    local value = 0
    local cost = 0
    local bNoBuyAll = true
    ---是否可以一键购买
    local isOneKeyBuy = true
    local entryCfg
    for i, v in ipairs(pageData.entry) do
        entryCfg = gModelActivity:GetWebActivityEntryData(sid, v.pageId, v.entryId)
        if entryCfg then
            local MarketData = v.MarketData
            local expend2 = checknumber(MarketData.expend2)

            --总的价值
            value = value + gModelPay:GetValueByWelfareId(expend2)

            local expend1 = MarketData.expend1
            local money
            if string.isempty(expend1) then
                money = gModelPay:GetRMBValueByWelfareId(expend2)
            else
                money = checknumber(expend1)
            end
            cost = cost + money

            local personalGoal, personal = MarketData.personalGoal, MarketData.personal
            local loseNum = personalGoal - personal
            if loseNum > 0 and bNoBuyAll then
                bNoBuyAll = false
            end

            if loseNum <= 0 and expend2 > 0 and isOneKeyBuy then
                isOneKeyBuy = false
            end

            table.insert(list, {
                pageId = v.pageId,
                entryId = v.entryId,
                title = entryCfg.name,
                items = LxDataHelper.SevenParseItems(v.items),
                MarketData = MarketData,
                moreInfo = entryCfg.moreInfo,
                expend1 = expend1,
                expend2 = expend2,
                personalGoal = personalGoal,
                personal = personal,
                loseNum = loseNum,
            })
        end
    end
    self._bNoBuyAll = bNoBuyAll
    self._isOneKeyBuy = isOneKeyBuy

    self._marketGiftData = list

    local symbol = gModelPay:GetMoneySymbol()
    local costStr = string.replace(ccClientText(15603), string.format("%s%s", symbol, value))
    self:SetWndText(self.mOldPrice, costStr)

    local isDmm = gLSdkImpl:CallMethod(LSdkMethod.IsDMMPlatform)
    if isDmm then
        CS.ShowObject(self.mOldPrice, false)
    end
    self._cost = cost

    local buyEnd = false
    local isGray = false
    local bBuyAll = false
    local oneKeyBuyStr = ccClientText(15638)
    if isOneKeyBuy then
        bBuyAll = true
        --oneKeyBuyStr = ccClientText(15623)
    elseif bNoBuyAll then
        isGray = true
        buyEnd = true
    end
    self._bBuyAll = bBuyAll
    self._oneKeyBuyStr = oneKeyBuyStr

    local bGray = not isOneKeyBuy or bNoBuyAll
    self:SetWndImageGray(self.mBuyBtn,bGray)

    local uiGiftScroll = self._uiGiftScroll
    if uiGiftScroll then
        uiGiftScroll:RefreshData(list)
        uiGiftScroll:DrawAllItems()
    else
        uiGiftScroll = self:GetUIScroll("uiGiftScroll")
        self._uiGiftScroll = uiGiftScroll
        uiGiftScroll:Create(self.mGiftScroll, list, function(...)
            self:DrawGiftListItem(...)
        end, UIItemList.SUPER)
        uiGiftScroll:EnableScroll(false, true)
    end

end

function UIActivityGiftModel4Pop:DrawPageListItem(list, item, itemdata, itempos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            SelectBg = CS.FindTrans(item, "SelectBg"),
            PageName = CS.FindTrans(item, "PageName"),
            redPoint = CS.FindTrans(item, "redPoint"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end

    CS.ShowObject(itemCache.SelectBg, self:CheckIsSelPage(itemdata))
    self:SetWndText(itemCache.PageName, itemdata.name)
    CS.ShowObject(itemCache.redPoint, itemdata.isShowRed)

    self:SetWndClick(item, function()
        self:OnPageItemClick(itemdata)
    end)
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIActivityGiftModel4Pop