---
--- Created by Administrator.
--- DateTime: 2023/10/12 10:51:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UI8Login:LWnd
local UI8Login = LxWndClass("UI8Login", LWnd)

UI8Login.PAGE_SIGN = 1
UI8Login.PAGE_GIFT = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UI8Login:UI8Login()
    self._nextGetTimer = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UI8Login:OnWndClose()
    if self._func then
        self._func()
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UI8Login:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UI8Login:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    --self:DoWndStartScale(0,self.mTopView)
    self:InitData()
    self:InitEvent()
    self:InitMsg()
    self:InitPara()

    --self:SetWndTabStatus(self.mBtnTab1,LWnd.StateOff)
    --self:SetWndTabStatus(self.mBtnTab1,LWnd.StateOff)

    --if self._net then
    --	local pbData = gModelActivity:GetActivityPageBySid(self._sid)
    --	if pbData then
    --		self:OnActivityPageResp(pbData)
    --	end
    --end
    self:SetWndText(self.mTxtReturn, ccClientText(20723))
    gModelGeneral:RemoveEightLogin()
end

function UI8Login:OnActivityPageResp(pb, ret)
    local sid = pb.sid
    if sid ~= self._sid then
        return
    end

    local pageList = self._pageList or {}

    for k, v in ipairs(pb.pages or {}) do
        local pageId = v.pageId
        local pageData = gModelActivity:GenerateActivePageDataFromPb(v)

        local temp = {
            sid = sid,
            pageId = pageId,
            entry = {},
        }

        local isPageSign = pageId == UI8Login.PAGE_SIGN
        local entryList = temp.entry
        for k1, v1 in ipairs(pageData.entry) do
            local entryCfg = gModelActivity:GetWebActivityEntryData(sid, pageId, v1.entryId)
            if entryCfg then
                local data = {
                    entryId = v1.entryId,
                    title = entryCfg.name,
                    desc = entryCfg.description,
                    MarketData = v1.MarketData,
                    moreInfo = entryCfg.moreInfo,
                }
                local moreInfo = entryCfg.moreInfo
                local status = v1.status or v1.goalData.status  --(0-不可领取, 1-可领取，2-已领取)
                if isPageSign then
                    data.icon = entryCfg.icon
                else
                    local tmoreInfo = string.split(moreInfo, ",")
                    local personalGoal = v1.MarketData.personalGoal
                    if personalGoal == -1 then
                        status = 1
                    else
                        local day = tonumber(tmoreInfo[3])
                        if personalGoal - v1.MarketData.personal <= 0 then
                            status = 2
                        elseif day > self._day then
                            status = 0
                        else
                            status = 1
                        end
                    end

                    data.expend2 = tonumber(v1.MarketData.expend2)
                    data.personal = v1.MarketData.personal
                    data.personalGoal = v1.MarketData.personalGoal
                    data.icon = tmoreInfo[4]
                end
                data.status = status
                data.rewards = LxDataHelper.ParseItem(entryCfg.reward)
                data.sort = entryCfg.sort
                data.isPageSign = isPageSign

                table.insert(entryList, data)
            end

        end

        table.sort(entryList, function(a, b)
            return a.sort < b.sort
        end)

        pageList[pageId] = temp
    end

    self._pageList = pageList

    self:RefreshBtnSelect()
    self:RefreshUI()
    self:ShowRedPoint()

    CS.ShowObject(self.mBgImg, true)
    CS.ShowObject(self.mTopMar, true)
    CS.ShowObject(self.mTopView, true)
    CS.ShowObject(self.mBottonView, true)
end

function UI8Login:ViewImageChangeAnim()
    if not self._curShowViewImageIndex then
        self._curShowViewImageIndex = 0
    end

    self.mTopCanvasGroup.alpha = 0

    local imgList = self._img1List
    local imgMaxNum = #imgList
    local nextIndex = self._curShowViewImageIndex + 1
    if nextIndex > imgMaxNum then
        nextIndex = 1
    end
    self._curShowViewImageIndex = nextIndex
    local imgPath = imgList[nextIndex]
    if LxUiHelper.IsImgPathValid(imgPath) then
        self:SetWndEasyImage(self.mView, imgPath, function()
            if not self.mTopCanvasGroup.gameObject.activeSelf then
                CS.ShowObject(self.mTopCanvasGroup, true)
            end
        end, true)
        self:RefreshTopHeroName(imgPath)
    end

    self:TweenSeq_AlphaCanvasTrans(self._viewImageScrollTweenKey, self.mTopCanvasGroup_1, 0, 1, 0.5)
end

function UI8Login:RefreshBtnSelect()
    local status1 = self._page == UI8Login.PAGE_SIGN and 0 or 1
    local status2 = self._page == UI8Login.PAGE_GIFT and 0 or 1
    self:SetWndTabStatus(self.mBtnTab1, status1)
    self:SetWndTabStatus(self.mBtnTab2, status2)
end

function UI8Login:OnDrawItem(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "Root")
    local CommonUITrans = CS.FindTrans(RootTrans, "CommonUI")
    local IconTrans = CS.FindTrans(CommonUITrans, "Icon")

    local formatData = {
        itemId = itemdata.itemId,
        itemType = itemdata.type or itemdata.itemType,
        itemNum = itemdata.count or itemdata.itemNum,
    }
    self:CreateCommonIconImpl(IconTrans, formatData)

    item.transform.localScale =    Vector3.New(0.6,0.6,0.6)
end

function UI8Login:StopNextGetTimer()
    CS.ShowObject(self.mNextTime, false)
    self:TimerStop(self._nextGetTimeKey)
end

function UI8Login:BtnEvent(index)
    if index == self._page then
        return
    end

    local functionOpenId = self._tabFuncOpenIdList[index]
    if not string.isempty(functionOpenId) then
        local checkOpenId = tonumber(functionOpenId)
        if checkOpenId > 0 and not gModelFunctionOpen:CheckIsOpened(checkOpenId, true) then
            return
        end
    end

    self._page = index
    self._curSelect = math.min(self._day, 8)
    self:RefreshBtnSelect()
    self:RefreshUI()

    --if index == 2 then
    --gModelActivity:CheckActivityClickRed(self._pageList[2].entry, ModelActivity.EIGHTLOGIN)
    --	self:ShowRedPoint()
    --end
end
---------------------------------------- 点击登录Icon ----------------------------------------
function UI8Login:InitLoginList(dataList)
    local uiList = self._loginRewardList
    if not uiList then
        uiList = self:GetUIScroll("_loginRewardList")
        self._loginRewardList = uiList
        uiList:Create(self.mLoginRewardList, dataList, function(...)
            self:OnDrawCell(...)
        end, UIItemList.NORMAL)
    else
        uiList:RefreshList(dataList)
    end
    self:InitItemList()
end

function UI8Login:OnTryTcpReconnect()
    gModelActivity:ReqActivityConfigData(self._sid)
end

---- 下次登录领取奖励时间 ------------------------------------------
function UI8Login:RefreshNextGetTime()
    --不是八天登录页
    --有可领取的
    local canGetNum = self._getRewardList and #self._getRewardList or 0
    if canGetNum > 0 then
        self:StopNextGetTimer()
        return
    end
    --已经是最后一天
    local page = self._pageList[UI8Login.PAGE_SIGN]
    if not page then
        return
    end
    local maxDay = #page.entry
    if self._day >= maxDay then
        self:StopNextGetTimer()
        return
    end
    --显示时间
    local now = GetTimestamp()
    local date = LUtil.OSDate("*t", now)
    self._endTime = LUtil.OSTime({ year = date.year, month = date.month, day = date.day + 1, hour = 0, min = 0, sec = 0 })  --凌晨0点为刷新点

    CS.ShowObject(self.mNextTime, true)
    self:NextGetTimerFunc()
    self:TimerStop(self._nextGetTimeKey)
    self:TimerStart(self._nextGetTimeKey, 1, false, -1)
end

function UI8Login:GetBoxInfo()
    local giftPageData = self._pageList[UI8Login.PAGE_GIFT]
    if not giftPageData then
        return
    end

    local dataList = giftPageData.entry

    if not dataList then
        return
    end
    local cnt = 0
    local totalCnt = #dataList
    for k, v in ipairs(dataList) do
        if v.status == 2 then
            cnt = cnt + 1
        end
    end
    local actData = gModelActivity:GetActivityBySid(self._sid)

    local moreInfo = JSON.decode(actData.moreInfo)
    local status = tonumber(moreInfo.all_box_state) or 0
    local str = ""
    local rStatus = 0
    if status == 0 then
        local canGet = cnt >= totalCnt
        if canGet then
            rStatus = 1
            str = ccClientText(16207) -- '可领取'
        else
            str = string.format("%s/%s", cnt, totalCnt)
        end

    else
        rStatus = 2
        str = ccClientText(16208) --"已领取"
    end

    return rStatus, str
end

function UI8Login:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end
    self:SetTop()
    gModelActivity:OnActivityPageReq(self._sid)
end

function UI8Login:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)


    for i, v in ipairs(self._btnList) do
        self:SetWndClick(v, function()
            self:BtnEvent(i)
        end, LSoundConst.CLICK_BUTTON_COMMON)
    end
    self:SetWndClick(self.mBtn, function()
        self:SendMsg()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mBtnHelp, function()
        local str = self._helpTipsContent
        GF.OpenWndUp("UIBzTips", { title = self._helpTipsTitle, text = str })
    end)
end

function UI8Login:RefreshUI()
    self._getRewardList = {}
    local page = self._pageList[self._page]
    if not page or not page.entry then
        return
    end
    local dataList = page.entry

    for i, v in ipairs(dataList) do
        local status = v.status
        if status == 1 and v.isPageSign then
            table.insert(self._getRewardList, { sid = page.sid, pageId = page.pageId, entryId = v.entryId })
        end
    end

    self:InitLoginList(dataList)
    self:RefreshNextGetTime()

    self:RefreshTopContent()
    self:RefreshContent()
end

function UI8Login:InitPara()
    self._func = self:GetWndArg("func")
    self._sid = self:GetWndArg("sid")

    --local page = self:GetWndArg("page")
    --self._page = page or UI8Login.PAGE_SIGN
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        self._sid = gModelActivity:GetSidByUniqueJump(subpage)
    end

    gModelActivity:ReqActivityConfigData(self._sid)
end

function UI8Login:SetTime()
    --设置时间
    local time = GetTimestamp()
    local timespan = self._endActivityTime - time
    if (timespan <= 0) then
        self:TimerStop(self._activityTimeKey)
        CS.ShowObject(self.mTimeBg, false)
        return
    end
    local timeStr = LUtil.FormatTimespanCn(timespan, { hTextId = 10371 })
    local str = ""
    local _timeDes = self._timeDes
    if not string.isempty(_timeDes) then
        str = string.replace(_timeDes, timeStr)
    end
    self:SetWndText(self.mTextTime, str)
end

function UI8Login:OnClickReward()
    local status, progress = self:GetBoxInfo()
    if status == 1 then
        gModelActivity:OnActivitySpecialOpReq(self._sid, UI8Login.PAGE_GIFT, nil, nil, nil, ModelActivity.EIGHT_DAY_BUY_ALL_RECEIVE)
        return
    elseif status == 2 then
        local str = ccClientText(16218) --"奖励已领取"
        GF.ShowMessage(str)
    end

    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end
    local itemList = LxDataHelper.ParseItem(webData.config.treasureChestReward)

    local text1 = nil
    if status == 0 then
        local str = LUtil.FormatColorStr(progress, "red")
        text1 = string.replace(webData.config.TipsContent1, str)
    else
        if status == 1 then
            text1 = LUtil.FormatColorStr(progress, "green")
        else
            text1 = progress
        end
    end

    local text2 = webData.config.TipsContent2
    GF.OpenWnd("UIringBoxDetail",{self.mBoxIcon,itemList})
    --GF.OpenWnd("UIBandThemeSignPop", {
    --    bigGiftStatus = status,
    --    itemList = itemList,
    --    text1 = text1,
    --    text2 = text2
    --})
end

function UI8Login:HasAllBuyBox()
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end
    local data = webData.config
    local treasureChest = data.treasureChest or 0
    local hasBox = tonumber(treasureChest) == 1
    return hasBox
end

function UI8Login:ShowRedPoint()
    if not self._pageList or table.isempty(self._pageList) then
        return
    end

    local pageSign = self._pageList[UI8Login.PAGE_SIGN] or {}
    local dataListSign = pageSign.entry or {}

    local showRed = false
    -- 八天登陆
    if dataListSign then
        for i, v in ipairs(dataListSign) do
            local status = v.status  --(0-不可领取, 1-可领取，2-已领取)
            if status == 1 then
                showRed = true
                break
            end
        end
    end

    CS.ShowObject(self._btnRedPointList[1], showRed)

    local limitBuy = false
    -- 限时特惠
    local haxBox = self:HasAllBuyBox()
    if haxBox then
        local status, _ = self:GetBoxInfo()
        limitBuy = status == 1
    end

    printInfoN2("八天登录", string.format("限时特惠红点 %s,hasbox %s", limitBuy, haxBox))

    CS.ShowObject(self._btnRedPointList[2], limitBuy)

    local isNotRedPoint = (not showRed) and (not limitBuy)
    if isNotRedPoint then
        local webData = gModelActivity:GetWebActivityDataById(self._sid)
        if webData then
            local data = webData.config
            local treasureChest = data.treasureChest or 0
            treasureChest = tonumber(treasureChest)
            local notShow = treasureChest == 0
            if notShow then
                gModelRedPoint:SetActivityRedClicked(self._sid)
            end
        end
    end

end

function UI8Login:RefreshTopContent()
    local isPageGift = self._page == UI8Login.PAGE_GIFT
    local hasBox = self:HasAllBuyBox()

    local showBoxPart = hasBox and isPageGift

    self:ShowRedPoint()

    CS.ShowObject(self.mView, not showBoxPart)
    CS.ShowObject(self.mBoxPart, showBoxPart)

    if not showBoxPart then
        return
    end

    local status, str = self:GetBoxInfo()
    local color = "red_1"
    if status == 1 then
        color = "lightGreen"
    elseif status == 2 then
        color = "lightGreen"
    end
    str = LUtil.FormatColorStr(str, color)
    self:SetWndText(self.mProgress, str)

    local eff = "fx_ui_baoxiang_guanbi"
    local iconPath = "activity_music1_icon_2_1"
    if status == 1 then
        iconPath = "activity_music1_icon_2_2"
        eff = "fx_ui_baoxiang_bankai"
    elseif status == 2 then
        iconPath = "activity_music1_icon_2_3"
        eff = "fx_ui_baoxiang_quankai"
    end

    local effKey = "boxEffKey"
    self:DestroyWndEffectByKey(effKey)
    self:CreateWndEffect(self.mBoxIcon, eff, effKey, 100)
    self:SetWndEasyImage(self.mBoxIcon, iconPath, nil, true)

    self:SetWndClick(self.mBoxPart, function()
        self:OnClickReward()
    end)

    local iconPath = "activity_16box"
    if status == 1 then
        iconPath = "activity_16box"
    elseif status == 2 then
        iconPath = "activity_16box_1"
    end

    self:SetWndEasyImage(self.mBoxIcon, iconPath, nil, true)
    CS.ShowObject(self.mView,false)
end
---------------------------------------- 点击天数Icon ----------------------------------------
function UI8Login:ClickLoginCell(index)
    if self._curSelect == index then
        return
    end
    local old = self._curSelect
    local list = self._loginRewardList:GetList()
    self._curSelect = index
    list:DrawItemByKey(old)
    list:DrawItemByKey(index)
    self:InitItemList()

    self:RefreshContent()
end

function UI8Login:SetTop()
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end

    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end

    local activityMoreInfo = JSON.decode(activityData.moreInfo)
    local data = webData.config

    local isHideShop = data.isHideShop or 0
    CS.ShowObject(self.mBotBtnBg, isHideShop == 0)

    self:SetDissImgList(data.publicityMapOne)
    self:SetDissImgList(data.publicityMapTwo)
    self:SetDissImgList(data.publicityMapThree)
    self.buyDescription = data.buyDescription or ""
    self.signTips = data.signTips or ""
    self.buyTips = data.buyTips or ""
    self._helpTipsContent = data.helpTipsContent or ""
    self._helpTipsTitle = activityData.title
    self._endActivityTime = activityData.endTime
    self._timeDes = data.timeDes
    self._posList = {
        [1] = data.position1,
        [2] = data.position2,
        [3] = data.position3,
    }
    self._heroNamePosList = {}
    for i = 1, 8 do
        local heroNamePos = data["heroNamePos" .. i]
        self:SetHeroNamePosList(heroNamePos)
    end

    self._day = tonumber(activityMoreInfo.receiveCount)
    self._curSelect = math.min(self._day, 8)

    printInfoN2("八天登录", string.format("当前天数 %s", self._day))

    local endType = data.endType or 0
    self:SetTime()
    self:TimerStop(self._activityTimeKey)
    self:TimerStart(self._activityTimeKey, 1, false, -1)

    local showTime = endType == 1
    CS.ShowObject(self.mTimeBg, endType == 1)
    if showTime then
        local timePos = data.timePos
        if timePos then
            self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(timePos))
        end

        local timeImg = data.timeImg
        if LxUiHelper.IsImgPathValid(timeImg) then
            self:SetWndEasyImage(self.mTimeBg, timeImg)
        end
    end

    self._tabFuncOpenIdList = string.split(data.tabFuncOpenId, '|')
    local tabName = data.tabName or ""
    local tabNameData = string.split(tabName, '|')
    for k, v in ipairs(self._btnList) do
        local curTabData = tabNameData[k]
        if not curTabData then
            local nameStrKey = self._defaultTabNameKey[k]
            self:SetWndTabText(v, ccClientText(nameStrKey))
        else
            local tabDataList = string.split(curTabData, '=')
            local nameStr = tabDataList[2]
            local offIconPath = tabDataList[3]
            local onIconPath = tabDataList[4]
            self:SetWndTabText(v, nameStr)

            if LxUiHelper.IsImgPathValid(offIconPath) then
                local offIconTrans = self:FindWndTrans(v, "Off")
                self:SetWndEasyImage(offIconTrans, offIconPath)
            end

            if LxUiHelper.IsImgPathValid(onIconPath) then
                local onIconTrans = self:FindWndTrans(v, "On/Icon")
                self:SetWndEasyImage(onIconTrans, onIconPath)
            end
        end
    end

    local unlock = data.unlock or 0
    unlock = tonumber(unlock)
    local showSign = unlock == 0 or unlock == 1
    local showGift = unlock == 0 or unlock == 2

    CS.ShowObject(self.mBtnTab1, showSign)
    CS.ShowObject(self.mBtnTab2, showGift)

    local ShowTwoBtn = showSign and showGift
    CS.ShowObject(self.mBotBtnBg,ShowTwoBtn)

    if not self._page then
        local page = self:GetWndArg("page") or UI8Login.PAGE_SIGN
        if not showSign then
            page = UI8Login.PAGE_GIFT
        end

        self._page = page
    end

    local topImgShow = data.TopImgShow or 0
    CS.ShowObject(self.mTopMarImage, topImgShow == 1)

end
---------------------------------------- 底部奖励栏 ----------------------------------------
function UI8Login:InitItemList()
    local page = self._pageList[self._page]
    if not page then
        return
    end
    local dataList = page.entry
    local itemdata = dataList[self._curSelect].rewards

    local uiList = self._itemUIList
    if not uiList then
        uiList = self:GetUIScroll("_key_itemUIList")
        self._itemUIList = uiList
        uiList:Create(self.mItemList, itemdata, function(...)
            self:OnDrawItem(...)
        end, UIItemList.NORMAL)
    else
        uiList:RefreshList(itemdata)
    end

end

function UI8Login:OnTimer(key)
    if key == self._nextGetTimeKey then
        self:NextGetTimerFunc()
    elseif key == self._activityTimeKey then
        self:SetTime()
    elseif key == self._viewImageScrollTimeKey then
        self:ViewImageChangeAnim()
    end
end

function UI8Login:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:OnActivityPageResp(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        local activity = pb.activity
        if not activity or self._sid ~= activity.sid then
            return
        end
        local status = activity.status
        if status == 3 then
            self:WndClose()
            return
        end
        self:SetTop()
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(...)
        self:SetTop()
    end)

    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp, function(pb)
        if pb.sid ~= self._sid then
            return
        end

        self:RefreshTopContent()

    end)
end

function UI8Login:SendMsg()
    local page = self._pageList[self._page]
    if not page then
        return
    end
    local pageData = page.entry
    if pageData then
        local entryData = pageData[self._curSelect]
        local status = entryData.status
        if status == 0 then
            local str = ccClientText(16209)
            if self._page == UI8Login.PAGE_GIFT then
                str = ccClientText(16210)
            end
            str = string.replace(str, self._curSelect)
            GF.ShowMessage(str)
        elseif status == 1 then
            if self._page == UI8Login.PAGE_SIGN then
                gModelActivity:OnActivityReceiveGoalListReq(self._getRewardList)
            else
                local price, entryId = tonumber(entryData.expend2), entryData.entryId
                gModelPay:GiftPayCtrl(entryId, price, ModelPay.PAY_TYPE_ACTIVITY, nil, self._sid, self._page)
            end
        elseif status == 2 then
            local str = ccClientText(16214)
            if self._page == UI8Login.PAGE_GIFT then
                str = ccClientText(16213)
            end
            GF.ShowMessage(str)
        end
    end
end

function UI8Login:InitData()
    self._net = true
    self._dissImgList = {}                    -- 宣传图列表
    self._curSelect = 1
    self._pageList = {}
    self._btnList = { self.mBtnTab1, self.mBtnTab2 }
    self._btnRedPointList = { self.mBtn1RedPoint, self.mBtn2RedPoint }
    self._btnStrs = {
        [0] = ccClientText(16206), -- 	"不可领取"
        [1] = ccClientText(16207), --	"可领取"
        [2] = ccClientText(16208), --	"已领取"
    }
    self._getRewardList = {}
    self._nextGetTimeKey = "_nextGetTime"
    self._activityTimeKey = "activityTimeKey"
    self._viewImageScrollTimeKey = "_viewImageScrollTimeKey"
    self._viewImageScrollTweenKey = "_viewImageScrollTweenKey"
    self._endTime = 0
    self._endActivityTime = 0

    self._defaultTabNameKey = { 16200, 16201 }
end

function UI8Login:OnDrawCell(list, item, itemdata, itempos)
    local NoSelImg = self:FindWndTrans(item, "NoSelImg")
    local NoSelImgImage = self:FindWndTrans(NoSelImg, "Image")
    local SelImg = self:FindWndTrans(item, "SelImg")
    local Icon = self:FindWndTrans(item, "Icon")
    local ItemName = self:FindWndTrans(item, "ItemName")
    local DayTxt = self:FindWndTrans(item, "DayTxt")
    local StatesImg = self:FindWndTrans(item, "StatesImg")
    local OnSelImg = self:FindWndTrans(item, "OnSelImg")

    local isCur = itempos == self._curSelect
    CS.ShowObject(OnSelImg, isCur)
    self:SetWndClick(item, function()
        self:ClickLoginCell(itempos)
    end)

    local status = itemdata.status
    local moreInfo = string.split(itemdata.moreInfo, ",")
    local commonImgPath, completeImgPath
    local isPageSign = itemdata.isPageSign
    if isPageSign then
        commonImgPath = moreInfo[3]
        completeImgPath = moreInfo[4]
    else
        commonImgPath = moreInfo[6]
        completeImgPath = moreInfo[7]
    end

    self:SetWndEasyImage(Icon, itemdata.icon, nil, true)
    self:SetWndText(ItemName, itemdata.desc)
    self:InitTextLineWithLanguage(ItemName, -40)
    self:SetWndText(DayTxt, itemdata.title)

    --local imgName = isPageSign and "public_txt_13_1" or "public_txt_4_1"
    --
    --self:SetWndEasyImage(StatesImg, imgName, nil, true)
    CS.ShowObject(StatesImg, status == 2)

    CS.ShowObject(NoSelImg, status == 0)
    CS.ShowObject(SelImg, status ~= 0)

    if status == 0 and commonImgPath and LxUiHelper.IsImgPathValid(commonImgPath) then
        self:SetWndEasyImage(NoSelImg, commonImgPath, function()
            --CS.ShowObject(NoSelImgImage, false)
        end, true)
    end

    if status ~= 0 and completeImgPath and LxUiHelper.IsImgPathValid(completeImgPath) then
        self:SetWndEasyImage(SelImg, completeImgPath, nil, true)
    end
end

function UI8Login:SetHeroNamePosList(heroNamePosStr)
    if string.isempty(heroNamePosStr) then
        return
    end

    local heroNamePosData = string.split(heroNamePosStr, '|')
    local imgName = heroNamePosData[1]
    for i = 2, #heroNamePosData do
        local posData = string.split(heroNamePosData[i], '=')
        local data = {
            heroId = tonumber(posData[1]),
            namePos = LxDataHelper.ParseVector2NotEmpty(posData[2]),
        }
        if not self._heroNamePosList[imgName] then
            self._heroNamePosList[imgName] = {}
        end
        table.insert(self._heroNamePosList[imgName], data)
    end
end

function UI8Login:NextGetTimerFunc()
    local now = GetTimestamp()
    local timeDif = os.difftime(self._endTime, now)
    if timeDif <= 0 then
        self:StopNextGetTimer()
        return
    end
    local timeStr = LUtil.FormatTimespanNumber(timeDif)
    if self._page == UI8Login.PAGE_SIGN then
        timeStr = string.replace(self.signTips, timeStr)
    else
        timeStr = string.replace(self.buyTips, timeStr)
    end
    self:SetWndText(self.mNextTime, timeStr)
end

function UI8Login:OnDrawHeroNameItem(item, itemdata)
    local isShow = not table.isempty(itemdata)
    CS.ShowObject(item, isShow)
    if not isShow then
        return
    end

    local nameText = self:FindWndTrans(item, "NameText")
    local raceIcon = self:FindWndTrans(item, "RaceIcon")

    local heroId = itemdata.heroId
    local ref = gModelHero:GetHeroRef(heroId)
    if not ref then
        return
    end

    local effRef = gModelHero:GetHeroEffectRef(heroId)
    local name = ccLngText(effRef.name)
    self:SetWndText(nameText, name)

    local raceType = ref.raceType
    local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
    local icon = raceRef.icon
    if LxUiHelper.IsImgPathValid(icon) then
        self:SetWndEasyImage(raceIcon, icon)
    end

    local pos = itemdata.namePos
    self:SetAnchorPos(item, pos)
end

function UI8Login:SetDissImgList(mapData)
    local index, img1, img2, img3, img4, img5, img6
    local publicityMap = mapData
    local publicityMapArr = string.split(publicityMap, "=")
    index, img1, img2, img3, img4, img5, img6 = tonumber(publicityMapArr[1]), publicityMapArr[2], publicityMapArr[3], publicityMapArr[4], publicityMapArr[5], publicityMapArr[6], publicityMapArr[7]
    self._dissImgList[index] = { img1 = img1, img2 = img2, img3 = img3, img4 = img4, img5 = img5, img6 = img6, }
end

function UI8Login:RefreshTopHeroName(viewImgName)
    if not viewImgName then
        return
    end

    local dataList = self._heroNamePosList[viewImgName] or {}
    for i = 1, self.mHeroName.childCount do
        local data = dataList[i]
        self:OnDrawHeroNameItem(self["mHeroName" .. i], data)
    end
end

function UI8Login:RefreshContent()
    local page = self._pageList[self._page]
    if not page then
        return
    end
    local dataList = page.entry
    --local dataList = self._pageServerList[self._page]
    if not dataList then
        return
    end
    local itemdata = dataList[self._curSelect]
    local moreInfo = string.split(itemdata.moreInfo, ",")
    local imgIndex, heroRefId = tonumber(moreInfo[1]), tonumber(moreInfo[2])

    local imgtab = self._dissImgList[imgIndex]
    local _posList = self._posList[imgIndex]
    if imgtab and _posList then
        local posArr = string.split(_posList, "=")
        local img1, img2, img3, img4, img5, img6 = imgtab.img1, imgtab.img2, imgtab.img3, imgtab.img4, imgtab.img5, imgtab.img6
        local img1List = string.split(img1, '|')
        local viewImageScrollTimeKey = self._viewImageScrollTimeKey
        local needViewScrollAnim = #img1List > 1
        self._curShowViewImageIndex = nil
        self:TimerStop(viewImageScrollTimeKey)
        self:TweenSeqKill(self._viewImageScrollTweenKey)
        local viewImgPath
        if needViewScrollAnim then
            --多个图片，需要轮播展示
            self._img1List = img1List
            viewImgPath = img1List[1]
            self._curShowViewImageIndex = 1
            self:TimerStart(viewImageScrollTimeKey, 5, false, -1)
        else
            viewImgPath = img1
        end

        if LxUiHelper.IsImgPathValid(viewImgPath) then
            self:SetWndEasyImage(self.mView, viewImgPath, function()
                CS.ShowObject(self.mTopCanvasGroup, true)
                self.mTopCanvasGroup.alpha = 1
            end, true)
            self:RefreshTopHeroName(viewImgPath)

            local imgPos = posArr[2]
            if not string.isempty(imgPos) then
                self:SetAnchorPos(self.mView, LxDataHelper.ParseVector2NotEmpty(imgPos))
            end

            CS.ShowObject(self.mView,false)
        else
            CS.ShowObject(self.mTopCanvasGroup, false)
        end

        self:SetWndEasyImage(self.mBgImg, img2)
        local bgImgPosStr = posArr[3]
        if bgImgPosStr then
            self:SetAnchorPos(self.mBgImg, LxDataHelper.ParseVector2NotEmpty(bgImgPosStr))
        end

        self:SetWndEasyImage(self.mMaskBg, img3)
        self:SetWndEasyImage(self.mTextImg, img4, function()
            CS.ShowObject(self.mTextImg, true)
            local textPos = posArr[1]
            self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(textPos))
        end, true)
        self:SetWndEasyImage(self.mDescBg1, img5)
        self:SetWndEasyImage(self.mDescBg2, img5)
        self:SetWndEasyImage(self.mItemBg, img6, function()
            CS.ShowObject(self.mItemBg, true)
        end,true)
        self._heroRefId = heroRefId
    end

    local isExpend2 = itemdata.expend2
    local descStr = ""
    if isExpend2 then
        descStr = self.buyDescription
    else
        local chienesNum = ccClientText(2000 + self._curSelect)
        descStr = string.replace(ccClientText(16203), chienesNum)
    end
    self:SetWndText(self.mDesc, descStr)
    local imgStr = "public_txt_13_1"
    local isShowUpRed = false
    local str
    local status = itemdata.status
    if itemdata.isPageSign then
        str = self._btnStrs[status]
    else
        imgStr = "public_txt_4_1"
        if status == 2 then
            str = ccClientText(15808)
        else
            local price = itemdata.expend2
            str = gModelPay:GetShowByWelfareId(price)
            local upRedStr = moreInfo[5] or ""
            isShowUpRed = not string.isempty(upRedStr) and upRedStr ~= "0"
            self:SetWndText(self.mUpRedTxt, upRedStr)
        end
    end
    local isShowEff = self._page == UI8Login.PAGE_SIGN and status == 1
    CS.ShowObject(self.mEffBtn, isShowEff)
    if isShowEff then
        self:CreateWndEffect(self.mEffBtn, "fx_shouchong_anniu", "fx_shouchong_anniu", 100, false, false)
    end
    CS.ShowObject(self.mUpRedImg, isShowUpRed)
    self:SetWndButtonText(self.mBtn, str)
    self:SetWndButtonGray(self.mBtn, status ~= 1)
    CS.ShowObject(self.mBtn, status ~= 2)
    self:SetWndEasyImage(self.mImgBtnEnd, imgStr, nil, true)
    CS.ShowObject(self.mImgBtnEnd, status == 2)

end
------------------------------------------------------------------
return UI8Login


