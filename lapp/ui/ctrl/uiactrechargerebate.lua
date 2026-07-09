---
--- Created by LCM.
--- DateTime: 2024/3/6 20:51:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActRechargeRebate:LWnd
local UIActRechargeRebate = LxWndClass("UIActRechargeRebate", LWnd)

UIActRechargeRebate.TYPE_PAGE_SIGNIN_REWARD = 1
UIActRechargeRebate.TYPE_PAGE_ACTIVATE_REWARD = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActRechargeRebate:UIActRechargeRebate()
    self._timerKey = "_timerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActRechargeRebate:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActRechargeRebate:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActRechargeRebate:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    gModelActivity:ReqActivityConfigData(self._sid)
end

----------------------------------------------------------------
--- 激活奖励
function UIActRechargeRebate:GetActivityPageList()
    return self._activityPageList
end

function UIActRechargeRebate:OnActivityPageResp(pb)
    if self._sid ~= pb.sid then
        return
    end

    local sid = self._sid
    local activityData = self._activityData
    if not activityData then
        activityData = {}
        self._activityData = activityData
    end
    local page, entryCfg
    local pageId, entryId
    local MarketData
    local first
    local personal, personalGoal, moreInfo, items, goalData, status, schedules, schedule, goal
    local pages = pb.pages or {}
    for i, v in ipairs(pages) do
        page = gModelActivity:GenerateActivePageDataFromPb(v)
        pageId = page.pageId
        local pageEntryList = {}
        for idx, val in ipairs(page.entry) do
            entryId = val.entryId
            entryCfg = gModelActivity:GetWebActivityEntryData(sid, val.pageId, entryId)
            if entryCfg then
                MarketData = val.MarketData
                personal, personalGoal = MarketData.personal, MarketData.personalGoal
                moreInfo = entryCfg.moreInfo
                items = LxDataHelper.ParseItem(entryCfg.reward)
                goalData = val.goalData
                status = goalData.status
                schedules = goalData.schedules
                first = schedules[1]
                schedule = first.schedule
                goal = tonumber(first.goal)
                table.insert(pageEntryList, {
                    entryId = entryId,
                    pageId = pageId,
                    title = entryCfg.name,
                    desc = entryCfg.description,
                    icon = entryCfg.icon,
                    items = items,

                    --- 目标条目进度数据
                    goalData = goalData,
                    status = status,
                    schedule = schedule,
                    goal = goal,
                    schedules = schedules,

                    --- 购买条目数据
                    MarketData = MarketData,
                    personalGoal = personalGoal,
                    personal = personal,

                    sort = entryCfg.sort,
                    moreInfo = moreInfo,
                    jumpId = entryCfg.jumpId,
                    jumpDesc = entryCfg.jumpDesc,
                })
            end
        end
        activityData[pageId] = pageEntryList
    end

    self:InitSignInDayReward()
    self:InitActivityDayReweard()

    if not self._initPageStatus then
        self._initPageStatus = true
        self:ChangePageIndex()
    end

    self:RefreshShow()

    self:InitBotList()
    self:InitActivityList(true)
end

function UIActRechargeRebate:AllReceiveGoalReward()
    local sid = self._sid
    local list = {}
    local pageActList = self:GetSignInPageData(self._page) or {}
    for i, v in ipairs(pageActList) do
        if v.status == 1 then
            table.insert(list, {
                sid = sid,
                pageId = v.pageId,
                entryId = v.entryId,
            })
        end
    end
    if #list < 1 then
        return
    end
    gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UIActRechargeRebate:OnClickGoToPayBtnFunc()
    if not self._jumpId then
        return
    end
    local jumpId = self._jumpId
    local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId, true)
    if not isOpen then
        return
    end
    gModelFunctionOpen:Jump(jumpId, self:GetWndName())
end

function UIActRechargeRebate:InitBotList()
    local list = self:GetBotList()
    local uiBotList = self._uiBotList
    if uiBotList then
        uiBotList:RefreshList(list)
    else
        uiBotList = self:GetUIScroll("uiBotList")
        self._uiBotList = uiBotList
        uiBotList:Create(self.mTabScroll, list, function(...)
            self:OnDrawBotCell(...)
        end)
    end
end

function UIActRechargeRebate:OpenCommonItemTipsWnd(itemdata)
    gModelGeneral:ShowCommonItemTipWnd(itemdata)
end

function UIActRechargeRebate:CheckBotPageIsLock(page)
    --- 第一天默认开启
    if page ~= self._firstPage then
        return self:CheckActivityIsLock(page)
    end
    return false
end

function UIActRechargeRebate:GetActivityReward()
    local activityData = self._activityData
    if not activityData then
        return
    end
    return activityData[UIActRechargeRebate.TYPE_PAGE_ACTIVATE_REWARD]
end

function UIActRechargeRebate:GetSignInReward()
    local activityData = self._activityData
    if not activityData then
        return
    end
    return activityData[UIActRechargeRebate.TYPE_PAGE_SIGNIN_REWARD]
end

function UIActRechargeRebate:InitText()
    self:SetTextTile(self.mBoxBtn, ccClientText(31801))
    self:SetWndButtonText(self.mGoToPayBtn, ccClientText(31803))

    self:SetWndText(self.mTxtClose, ccClientText(30205))
end

function UIActRechargeRebate:GetActivityStatus(page)
    local activityData = self:GetActivityPageData(page)
    if not activityData then
        return false
    end
    return activityData.status
end

------------------------- List -------------------------
function UIActRechargeRebate:GetActivityList()
    local list = self:GetSignInPageData(self._page) or {}
    return list
end

function UIActRechargeRebate:OnClickBoxBtnFunc()
    local activityData = self:GetActivityPageData(self._page)
    if not activityData then
        return
    end
    local sid = self._sid
    local status = activityData.status
    if status == 1 then
        gModelActivity:OnActivityReceiveGoalReq(sid, activityData.pageId, activityData.entryId)
        return
    end
    local okBtnName
    if status == 2 then
        okBtnName = ccClientText(31805)
    end
    local rewardList = activityData.items
    GF.OpenWnd("UIBandThemeSignPop", {
        sid = sid,
        bigGiftStatus = status,
        itemList = rewardList,
        signBoxState = self._signBoxStateList,
        okBtnName = okBtnName,
        bigGiftPosY = 0,
        bigGiftScale = 0.8,
        text2 = self:GetDescTxt(self._bigTipsTxtKeyList),
    })
end

function UIActRechargeRebate:InitSignInDayReward()
    local signInReward = self:GetSignInReward()
    if not signInReward then
        return
    end
    local list = {}
    local page
    for i, v in ipairs(signInReward) do
        page = v.moreInfo
        local pageList = list[page]
        if not pageList then
            pageList = {}
            list[page] = pageList
        end
        table.insert(pageList, v)
    end
    for pageIdx, pageList in pairs(list) do
        table.sort(pageList, function(a, b)
            return a.sort < b.sort
        end)
    end
    self._signInPageList = list
end

function UIActRechargeRebate:InitEvent()
    self:SetWndClick(self.mHelpBtn, function()
        self:OnClickHelpBtnFunc()
    end)
    self:SetWndClick(self.mGoToPayBtn, function()
        self:OnClickGoToPayBtnFunc()
    end)
    self:SetWndClick(self.mBoxBtn, function()
        self:OnClickBoxBtnFunc()
    end)
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIActRechargeRebate:GetBotList()
    local taskPageList = self._taskPageList or {}
    local list = {}
    for i, v in ipairs(taskPageList) do
        table.insert(list, {
            page = v.page,
            pageName = v.pageName,
            pageIcon = v.pageIcon,
        })
    end
    table.sort(list, function(a, b)
        return a.page < b.page
    end)
    return list
end

function UIActRechargeRebate:OneReceiveGoalReward(itemdata)
    local sid = self._sid
    local pageId = itemdata.pageId
    local entryId = itemdata.entryId
    gModelActivity:OnActivityReceiveGoalReq(sid, pageId, entryId)
end

function UIActRechargeRebate:OnDrawActivityCell(list, item, itemdata, itempos)
    local ItemNameTrans = self:FindWndTrans(item, "ItemName")
    local DayNumTrans = self:FindWndTrans(item, "DayNum")
    local BtnTrans = self:FindWndTrans(item, "Btn")
    local CommonUITrans = self:FindWndTrans(item, "CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans, "Icon")
    local EffRootTrans = self:FindWndTrans(CommonUITrans, "EffRoot")
    local redPointTrans = self:FindWndTrans(CommonUITrans, "redPoint")
    local ItemNumTrans = self:FindWndTrans(item, "ItemNum")

    local items = itemdata.items[1]
    local itemNum = items.itemNum
    local itemId = items.itemId
    local instanceID = IconTrans:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(items.itemType, itemId, itemNum)
    baseClass:EnableShowNum(false)
    baseClass:SetShowGouImg(itemdata.status == 2)
    baseClass:DoApply()

    local dayStr = string.replace(ccClientText(31800), itemdata.sort)
    self:SetWndText(DayNumTrans, dayStr)

    self:SetWndText(ItemNumTrans, LUtil.NumberCoversion(itemNum))

    local itemName = gModelItem:GetNameByRefId(itemId)
    self:SetWndText(ItemNameTrans, itemName)

    local showRedPoint = self:CheckSignInRedPoint(itemdata)
    if showRedPoint then
        local key = EffRootTrans:GetInstanceID()
        self:CreateWndEffect(EffRootTrans, "fx_ui_qiandao_lingqutishi", key, 100, false, false)
    end
    CS.ShowObject(EffRootTrans, showRedPoint)
    CS.ShowObject(redPointTrans, showRedPoint)

    self:SetWndClick(IconTrans, function()
        if self:CheckSignInRedPoint(itemdata) then
            self:OnClickActivityBtnFunc(itemdata)
            return

        end
        self:OpenCommonItemTipsWnd(items)
    end)

    self:SetWndClick(BtnTrans, function()
        self:OnClickActivityBtnFunc(itemdata)
    end)
end

function UIActRechargeRebate:CheckIsShowRedPoint(page)
    if self:CheckBotPageIsLock(page) then
        return false
    end
    local actStatus = self:GetActivityStatus(page)
    if actStatus ~= 0 then
        if actStatus == 1 then
            return true
        end

        if self:CheckIsSignInRedPoint(page) then
            return true
        end
    end
    return false
end

function UIActRechargeRebate:UnLockTips(page)
    local taskPageKeyList = self._taskPageKeyList
    if not taskPageKeyList then
        return
    end
    local beforePage = page - 1
    local beforeInfo = taskPageKeyList[beforePage]
    if not beforeInfo then
        return
    end
    local pageName = beforeInfo.pageName
    local tips = string.replace(ccClientText(31804), pageName)
    GF.ShowMessage(tips)
end

function UIActRechargeRebate:OnClickBotBtnFunc(itemdata)
    local page = itemdata.page
    if self._page == page then
        return
    end
    if self:CheckBotPageIsLock(page) then
        self:UnLockTips(page)
        return
    end

    self:SetWndTabStatus(self.tabBtn[self._page], 1)
    self:SetWndTabStatus(self.tabBtn[page], 0)

    self._page = page
    local uiBotList = self._uiBotList
    if uiBotList then
        local uiList = uiBotList:GetList()
        uiList:RefreshList()
    end
    self:InitActivityList()
    self:RefreshShow()
end

----------------------------------------------------------------
--- 签到奖励
function UIActRechargeRebate:GetSignInPageList()
    return self._signInPageList
end

function UIActRechargeRebate:OnTimer(key)
    if key == self._timerKey then
        self:StarCountDown()
    end
end

function UIActRechargeRebate:OnClickActivityBtnFunc(itemdata)
    local status = itemdata.status
    if status == 0 then
        if self._isEnd then
            GF.ShowMessage(ccClientText(14301))
        else
            self:OpenCommonItemTipsWnd(itemdata.items[1])
        end
    elseif status == 1 then
        --self:OneReceiveGoalReward(itemdata)
        self:AllReceiveGoalReward()
    elseif status == 2 then
        GF.ShowMessage(ccClientText(12208))
    end
end

function UIActRechargeRebate:RefreshShow()
    local page = self._page
    if not page then
        return
    end

    local activityData = self:GetActivityPageData(page)
    if not activityData then
        return
    end

    local goal = self:GetPageGold()
    if not goal then
        return
    end

    local tipsTxtKeyList = self._tipsTxtKeyList
    if not tipsTxtKeyList then
        return
    end

    local pageTxtInfo = tipsTxtKeyList[page]
    if not pageTxtInfo then
        return
    end

    local str = self:GetDescTxt()
    self:SetWndText(self.mDescTxt, str)
    self:InitTextLineWithLanguage(self.mDescTxt, -30)
    self:InitTextSizeWithLanguage(self.mDescTxt, -2)

    local status = activityData.status
    local signBoxStateList = self._signBoxStateList
    local icon
    if status == 0 then
        icon = signBoxStateList[1]
    elseif status == 2 then
        icon = signBoxStateList[3]
    end
    self:SetWndEasyImage(self.mBtnImg, icon)

    local showEff = status == 1
    if showEff then
        self:CreateWndEffect(self.mBtnEffRoot, "fx_tehuishangdian", "fx_tehuishangdian", 60, false, false)
    end
    CS.ShowObject(self.mBtnEffRoot, showEff)
    --CS.ShowObject(self.mBtnImg, not showEff)

    local showGoToGetReward = status ~= 0
    CS.ShowObject(self.mGoToGetReward, showGoToGetReward)
    CS.ShowObject(self.mGoToPayBtn, not showGoToGetReward)
end

function UIActRechargeRebate:GetPageGold()
    local page = self._page
    if not page then
        return
    end

    local activityData = self:GetActivityPageData(page)
    if not activityData then
        return
    end
    return activityData.goal
end

function UIActRechargeRebate:OnDrawBotCell(list, item, itemdata, itempos)


    --
    --self:SetWndEasyImage(IconTrans,itemdata.pageIcon,function()
    --    CS.ShowObject(IconTrans,true)
    --end)
    --
    --local pageName = itemdata.pageName
    --self:SetWndText(NoSelTxtTrans,pageName)
    --self:SetWndText(SelTxtTrans,pageName)
    --
    --
    --CS.ShowObject(NoSelTxtTrans,not isSel)
    --CS.ShowObject(SelTxtTrans,isSel)
    --


    local SelBgTrans = self:FindWndTrans(item, "OnBg")
    local On = self:FindWndTrans(item, "On")
    local Off = self:FindWndTrans(item, "Off")
    local Gray = self:FindWndTrans(item, "Gray")
    local redPointTrans = self:FindWndTrans(item, "redPoint")
    local LockBgTrans = self:FindWndTrans(item, "Lock")

    local page = itemdata.page
    local isSel = self._page == page

    self:SetWndEasyImage(On, itemdata.pageIcon)
    self:SetWndEasyImage(Off, itemdata.pageIcon)
    self:SetWndEasyImage(Gray, itemdata.pageIcon)
    self:SetWndTabText(item, itemdata.pageName)

    self:SetWndTabStatus(item, isSel and 0 or 1)
    CS.ShowObject(SelBgTrans, isSel)

    local isLock = self:CheckBotPageIsLock(page)
    CS.ShowObject(LockBgTrans, isLock)

    local showRedPoint = self:CheckIsShowRedPoint(page)
    CS.ShowObject(redPointTrans, showRedPoint)

    if not self.tabBtn then
        self.tabBtn = {}
    end
    self.tabBtn[itemdata.page] = item
    self:SetWndClick(item, function()
        self:OnClickBotBtnFunc(itemdata)
    end)
end

function UIActRechargeRebate:InitActivityDayReweard()
    local activityReward = self:GetActivityReward()
    if not activityReward then
        return
    end
    local list = {}
    for i, v in ipairs(activityReward) do
        list[v.entryId] = v
    end
    self._activityPageList = list
end

function UIActRechargeRebate:GetSignInPageData(page)
    local signInPageList = self:GetSignInPageList()
    if not signInPageList then
        return
    end
    return signInPageList[page]
end

function UIActRechargeRebate:OnActivityListResp(pb)
    local sid = self._sid
    local activities = pb.activities
    for i, v in ipairs(activities) do
        if sid == v.sid then
            gModelActivity:ReqActivityConfigData(sid)
            return
        end
    end
end

function UIActRechargeRebate:OnActivityResp(pb)
    if self._sid ~= pb.sid then
        return
    end
    gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActRechargeRebate:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        self:OnActivityResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        self:OnActivityListResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)
    end)

    -- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIActRechargeRebate:CheckActivityIsLock(page)
    local activityData = self:GetActivityPageData(page)
    if not activityData then
        return true
    end
    local curIsNotAct = activityData.status == 0
    local before = page - 1
    local beforeActivityData = self:GetActivityPageData(before)
    if curIsNotAct and beforeActivityData then
        if beforeActivityData.status ~= 0 then
            curIsNotAct = false
        end
    end
    return curIsNotAct
end

function UIActRechargeRebate:GetDescTxt(bigTipsTxtKeyList)
    local page = self._page
    if not page then
        return ""
    end
    local goal = self:GetPageGold()
    if not goal then
        return ""
    end
    local tipsTxtKeyList = bigTipsTxtKeyList or self._tipsTxtKeyList
    if not tipsTxtKeyList then
        return ""
    end

    local pageTxtInfo = tipsTxtKeyList[page]
    if not pageTxtInfo then
        return ""
    end
    local t = {}
    t["a" .. page] = goal
    local pageTxt = pageTxtInfo.pageTxt
    local str = string.gsub(pageTxt, "#(%w+)#", t)
    return str
end

function UIActRechargeRebate:InitData()
    self._sid = self:GetWndArg("sid")
    self._page = 1
    self._signBoxStateList = {
        "activity_magicSchool_icon_1",
        "activity_magicSchool_icon_2",
        "activity_magicSchool_icon_3",
    }
end

function UIActRechargeRebate:OnClickHelpBtnFunc()
    if not self._title then
        if LOG_INFO_ENABLED then
            printInfoNR("没有配置标题")
        end
        return
    end
    if not self._helpTipsContent then
        if LOG_INFO_ENABLED then
            printInfoNR("没有配置 helpTipsContent 字段")
        end
        return
    end

    local gold = self:GetPageGold() or ""
    local str = string.replace(self._helpTipsContent, gold)

    local para = {
        title = self._title,
        text = str
    }
    GF.OpenWnd("UIBzTips", para)
end

function UIActRechargeRebate:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end
    local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
    if not activityWebData then
        return
    end
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end

    local config = activityWebData.config
    self._jumpId = config.jumpId

    self._title = activityData.title
    self._helpTipsContent = config.helpTipsContent

    local helpTips = config.helpTips or 0
    local showHelpBtn = helpTips == 1
    if showHelpBtn then
        local helpTipsPosition = config.helpTipsPosition
        if not string.isempty(helpTipsPosition) then
            self:SetAnchorPos(self.mHelpDiv, LxDataHelper.ParseVector2NotEmpty(helpTipsPosition))
        end
    end
    CS.ShowObject(self.mHelpDiv, showHelpBtn)

    local heroCollect = config.heroCollect
    local isShowHero = not string.isempty(heroCollect)
    if isShowHero then
        local heroCollectTurn = config.heroCollectTurn or 0
        local heroCollectPos = config.heroCollectPos
        if not string.isempty(heroCollectPos) then
            self:SetAnchorPos(self.mHeroRoot, LxDataHelper.ParseVector2NotEmpty(heroCollectPos))
        end
        self:CreateWndSpine(self.mHeroRoot, heroCollect, heroCollect, false, function(spine)
            if heroCollectTurn == 1 then
                spine:SetFlipX(true)
            end
        end)
    end
    CS.ShowObject(self.mHeroRoot, isShowHero)

    local image = config.image
    self:SetWndEasyImage(self.mBg, image, function()
        CS.ShowObject(self.mBg, true)
    end)

    self:TimerStop(self._timerKey)
    local endTime = activityData.endTime
    if endTime == 0 then
        -- 永久生效
        --self:SetWndText(self.mCountDown,"")
        CS.ShowObject(self.mCountDown.parent, false)
    else
        local conversionTimePos = config.conversionTimePos
        if not string.isempty(conversionTimePos) then
            --- 时间坐标
            self:SetAnchorPos(self.mCountDown.parent, LxDataHelper.ParseVector2NotEmpty(conversionTimePos))
        end

        self:SetWndText(self.mCountDown, "")
        CS.ShowObject(self.mCountDown.parent, true)
        self._endTime = endTime
        self:TimerStart(self._timerKey, 1, false, -1)
        self:StarCountDown()
    end

    local descIcon = config.descIcon
    local showDescIcon = not string.isempty(descIcon)
    if showDescIcon then
        self:SetWndEasyImage(self.mTxtImg, descIcon, function()
            CS.ShowObject(self.mTxtImg, true)
        end)
    else
        CS.ShowObject(self.mTxtImg, false)
    end

    --- banner区，提示文本，支持富文本，激活奖励序号id=富文本，多个用【|】分割（前端显示）
    local tipsTxtList = self._tipsTxtList
    if not tipsTxtList then
        tipsTxtList = {}
        self._tipsTxtList = tipsTxtList

        local tipsTxtKeyList = {}
        self._tipsTxtKeyList = tipsTxtKeyList

        local tipsTxtPage
        local tipsTxt = string.split(config.tipsTxt, "|")
        for i, v in ipairs(tipsTxt) do
            v = string.split(v, "=")
            tipsTxtPage = tonumber(v[1])

            local tData = {
                page = tipsTxtPage,
                pageTxt = v[2],
            }

            tipsTxtKeyList[tipsTxtPage] = tData
            table.insert(tipsTxtList, tData)
        end
    end

    local bigTipsTxtList = self._bigTipsTxtList
    if not bigTipsTxtList then
        bigTipsTxtList = {}
        self._bigTipsTxtList = bigTipsTxtList

        local bigTipsTxtKeyList = {}
        self._bigTipsTxtKeyList = bigTipsTxtKeyList

        local tipsTxtPage
        local bigTipsTxt = string.split(config.bigTipsTxt, "|")
        for i, v in ipairs(bigTipsTxt) do
            v = string.split(v, "=")
            tipsTxtPage = tonumber(v[1])

            local tData = {
                page = tipsTxtPage,
                pageTxt = v[2],
            }

            bigTipsTxtKeyList[tipsTxtPage] = tData
            table.insert(bigTipsTxtList, tData)
        end
    end

    --- 团购界面：团购的页签表格，配置格式：激活奖励序号id=名称=分表图标，多个用【|】分割（前端显示）
    local taskPageList = self._taskPageList
    if not taskPageList then
        taskPageList = {}
        self._taskPageList = taskPageList

        local taskPageKeyList = {}
        self._taskPageKeyList = taskPageKeyList

        local page
        local taskPage = string.split(config.taskPage, "|")
        for i, v in ipairs(taskPage) do
            v = string.split(v, "=")
            page = tonumber(v[1])

            if not self._firstPage then
                self._firstPage = page
            end

            local tData = {
                page = page,
                pageName = v[2],
                pageIcon = v[3],
            }

            taskPageKeyList[page] = tData
            table.insert(taskPageList, tData)
        end
    end

    gModelActivity:OnActivityPageReq(sid)
end

function UIActRechargeRebate:StarCountDown()
    if not self._endTime then
        self:SetWndText(self.mCountDown, "")
        self:TimerStop(self._timerKey)
        return
    end
    local lastTime = self._endTime - GetTimestamp()
    if lastTime < 0 then
        self:SetWndText(self.mCountDown, ccClientText(14301))
        self:TimerStop(self._timerKey)
        self._isEnd = true
    else
        local timeStr = LUtil.FormatTimespanCn(lastTime)
        --timeStr = LUtil.FormatColorStr(timeStr,"green")
        timeStr = string.replace(ccClientText(21405), timeStr)
        self:SetWndText(self.mCountDown, timeStr)
    end
end

function UIActRechargeRebate:CheckIsSignInRedPoint(page)
    local list = self:GetSignInPageData(page) or {}
    for i, v in ipairs(list) do
        if v.status == 1 then
            return true
        end
    end
    return false
end

function UIActRechargeRebate:ChangePageIndex()
    local activityPageList = self:GetActivityPageList()
    if not activityPageList then
        return
    end
    local activityPageStatusList = {}
    for pageIndex, pageData in pairs(activityPageList) do
        table.insert(activityPageStatusList, {
            entryId = pageData.entryId,
            status = pageData.status,
        })
    end
    table.sort(activityPageStatusList, function(a, b)
        return a.entryId < b.entryId
    end)
    for i, v in ipairs(activityPageStatusList) do
        if not self:CheckBotPageIsLock(v.entryId) then
            if self:CheckIsSignInRedPoint(v.entryId) then
                self._page = v.entryId
                break
            end
        end
    end
end

function UIActRechargeRebate:CheckSignInRedPoint(itemdata)
    local actStatus = self:GetActivityStatus(self._page)
    if not actStatus then
        return false
    end
    if actStatus == 0 then
        return false
    end
    return itemdata.status == 1
end

function UIActRechargeRebate:InitActivityList(refreshData)
    local list = self:GetActivityList()
    local uiActivityList = self._uiActivityList
    if uiActivityList then
        if refreshData then
            uiActivityList:RefreshData(list)
        else
            uiActivityList:RefreshList(list)
        end
    else
        uiActivityList = self:GetUIScroll("uiActivityList")
        self._uiActivityList = uiActivityList
        uiActivityList:Create(self.mActivityList, list, function(...)
            self:OnDrawActivityCell(...)
        end, UIItemList.WRAP)
    end
end

function UIActRechargeRebate:GetActivityPageData(page)
    local activityPageList = self:GetActivityPageList()
    if not activityPageList then
        return
    end
    return activityPageList[page]
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIActRechargeRebate



