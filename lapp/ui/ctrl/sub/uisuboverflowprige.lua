---
--- Created by BY.
--- DateTime: 2023/10/16 17:28:08
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubOverflowPrige:LChildWnd
local UISubOverflowPrige = LxWndClass("UISubOverflowPrige", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubOverflowPrige:UISubOverflowPrige()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubOverflowPrige:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubOverflowPrige:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubOverflowPrige:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:RefreshForeign()
end

function UISubOverflowPrige:OnClickOneKey()
    gModelActivity:OnActivitySpecialOpReq(self._sid, 1, -1, nil, nil, ModelActivity.SUPER_PRIVILEGE_FREE_BUY)
end
function UISubOverflowPrige:RefreshData()
    local sid = self._sid
    local _pages = self._pages
    local activityDataS = gModelActivity:GetActivityBySid(sid)
    if not _pages or not activityDataS then
        return
    end
    local moreInfoS = JSON.decode(activityDataS.moreInfo)
    local _page = _pages[1]
    local entry = _page.entry
    local playerLv = gModelPlayer:GetPlayerLv()
    local list = {}
    for i, v in ipairs(entry) do
        local entryCfg = gModelActivity:GetWebActivityEntryData(sid, v.pageId, v.entryId)
        if not string.isempty(entryCfg.moreInfo) then
            local moreInfo = string.split(entryCfg.moreInfo, ";")
            if not string.isempty(moreInfo[3]) then
                local lvArr = string.split(moreInfo[3], ",")
                if tonumber(lvArr[1]) <= playerLv and playerLv <= tonumber(lvArr[2]) then
                    v.entryCfg = entryCfg
                    table.insert(list, v)
                end
            else
                v.entryCfg = entryCfg
                table.insert(list, v)
            end
        end
    end
    local isOneKey = false
    local keyDayList = {}
    for i = 1, #list do
        local data = list[i]
        local buy_record = moreInfoS["buy_record_" .. data.entryId]
        keyDayList[data.entryId] = buy_record
        if not isOneKey then
            local marketData = data.MarketData
            local personalGoal = marketData.personalGoal
            local personal = marketData.personal
            local dayBuyNum = personalGoal - personal
            local moreInfos = data.entryCfg.moreInfo and string.split(data.entryCfg.moreInfo, ";") or {}
            local taskBuyNum = tonumber(moreInfos[1])
            local buyNum = buy_record
            local residueTaskNum = taskBuyNum - buyNum

            local bGBState = residueTaskNum <= 0            --true 领取；false 购买
            local bOnGBState = dayBuyNum <= 0            --true 已领取 or 已购买；false 未领取 or 未购买
            if bGBState and not bOnGBState then
                isOneKey = true
            end
        end
    end
    self._keyDayList = keyDayList
    table.sort(list, function(a, b)
        local aMarketData = a.MarketData
        local aPersonalGoal = aMarketData.personalGoal
        local aPersonal = aMarketData.personal
        local aDayBuyNum = aPersonalGoal - aPersonal > 0 and 1 or 0

        local bMarketData = b.MarketData
        local bPersonalGoal = bMarketData.personalGoal
        local bPersonal = bMarketData.personal
        local bDayBuyNum = bPersonalGoal - bPersonal > 0 and 1 or 0
        if aDayBuyNum ~= bDayBuyNum then
            return aDayBuyNum > bDayBuyNum
        end

        local aEntryId = a.entryId
        local aEntryCfg = a.entryCfg
        local aMoreInfos = aEntryCfg.moreInfo and string.split(aEntryCfg.moreInfo, ";") or {}
        local aTaskBuyNum = tonumber(aMoreInfos[1])
        local aBuyNum = keyDayList[aEntryId] or 0
        local aGet = aTaskBuyNum - aBuyNum <= 0 and 1 or 0

        local bEntryId = b.entryId
        local bEntryCfg = b.entryCfg
        local bMoreInfos = bEntryCfg.moreInfo and string.split(bEntryCfg.moreInfo, ";") or {}
        local bTaskBuyNum = tonumber(bMoreInfos[1])
        local bBuyNum = keyDayList[bEntryId] or 0
        local bGet = bTaskBuyNum - bBuyNum <= 0 and 1 or 0

        if aGet ~= bGet then
            return aGet > bGet
        end
        return aEntryId < bEntryId
    end)

    CS.ShowObject(self.mBtnOneKey, isOneKey)

    local _uiCellList = self._uiCellList
    if not _uiCellList then
        _uiCellList = self:GetUIScroll("UISubOverflowPrige_mCellSuper")
        self._uiCellList = _uiCellList
        _uiCellList:Create(self.mCellSuper, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
    else
        _uiCellList:RefreshList(list)
    end
    _uiCellList:DrawAllItems()
end
function UISubOverflowPrige:ResetData(pb)
    local _pages = self._pages or {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        local pageId = page.pageId
        _pages[pageId] = page
    end
    self._pages = _pages
    self:RefreshData()
end
function UISubOverflowPrige:OnActivityConfigData()
    local sid = self._sid
    local activityData = gModelActivity:GetWebActivityDataById(sid)
    local data = activityData.config

    local image, imagePos, descIconA, descIconAPos, descIconB, descIconBPos, helpTips = data.image, data.imagePos, data.descIconA, data.descIconAPos, data.descIconB, data.descIconBPos, data.helpTips
    self._signTips1, self._signTips2 = data.signTips1, data.signTips2

    if not string.isempty(image) then
        local heroImageArr = string.split(image, "=")
        local type = heroImageArr[1]
        local heroImage = heroImageArr[2] or image
        local parent
        if type == "1" or not heroImageArr[2] then
            parent = self.mHeroImg
            self:SetWndEasyImage(parent, heroImage)
        else
            parent = self.mHeroSpine
            self:CreateWndSpine(parent, heroImage, heroImage, false)
        end
        --parent.localScale = Vector2.New(showSize/10,showSize/10)
        CS.ShowObject(parent, true)
        if not string.isempty(imagePos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(imagePos)
            self:SetAnchorPos(parent, pos)
        end
    end
    if not string.isempty(descIconA) then
        local parent = self.mTitleImg
        CS.ShowObject(parent, true)
        self:SetWndEasyImage(parent, descIconA, nil, true)
        if not string.isempty(descIconAPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(descIconAPos)
            self:SetAnchorPos(parent, pos)
        end
    end
    if not string.isempty(descIconB) then
        local parent = self.mDesText
        CS.ShowObject(self.mDesBg, true)
        local str = string.gsub(descIconB, "\\n", "\n")
        self:SetWndText(parent, str)
        self:InitTextLineWithLanguage(parent, -30)
        self:InitTextSizeWithLanguage(parent, -2)
        if not string.isempty(descIconBPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(descIconBPos)
            self:SetAnchorPos(self.mDesBg, pos)
        end
    end
    local isShowHelp = helpTips and helpTips == 1
    CS.ShowObject(self.mBtnHelp, isShowHelp)
    gModelActivity:OnActivityPageReq(self._sid)
end

function UISubOverflowPrige:RefreshForeign()
    if self._isVie then
        self:InitTextSizeWithLanguage(self.mOneKeyText, -4)
    end
end

function UISubOverflowPrige:InitIconEasyList(key, root, rewardList)
    local uiList1 = self._uiCellList:GetItemCls(key)
    if not uiList1 then
        uiList1 = UIIconEasyList:New(self)
        self._uiCellList:SetItemCls(key, uiList1)
        uiList1:Create(self, root)
        uiList1:SetIconParentPath("Root/CommonUI/Icon")
    end
    uiList1:RefreshList(rewardList)
    uiList1:EnableScroll(#rewardList > 3, true)
end

function UISubOverflowPrige:ListItem(list, item, itemdata, itempos)
    local sid = self._sid
    local pageId = itemdata.pageId
    local entryId = itemdata.entryId
    local entryCfg = itemdata.entryCfg
    local root = self:FindWndTrans(item, "Root")
    local titleText = self:FindWndTrans(root, "TitleBg/TitleText")
    local upTab = self:FindWndTrans(root, "UpTab")
    local tabText = self:FindWndTrans(root, "UpTab/TabText")
    local itemScroll = self:FindWndTrans(root, "ItemScroll")
    local numText = self:FindWndTrans(root, "NumText")
    local btnBuy = self:FindWndTrans(root, "BtnBuy")
    local buyText = self:FindWndTrans(root, "BuyText")
    local btnEff = self:FindWndTrans(root, "Eff")

    local instanceID = item:GetInstanceID()

    local name = entryCfg.name
    local moreInfos = entryCfg.moreInfo and string.split(entryCfg.moreInfo, ";") or {}
    local taskBuyNum = tonumber(moreInfos[1])

    local marketData = itemdata.MarketData
    local personalGoal = marketData.personalGoal
    local personal = marketData.personal
    local dayBuyNum = personalGoal - personal

    local expend2 = marketData.expend2
    local payStr, expendId
    local isFree = string.isempty(expend2)

    --local rewardList = LxDataHelper.ParseItem(entryCfg.reward)

    if isFree then
        payStr = ccClientText(11913)
    else
        expendId = tonumber(marketData.expend2)
        payStr = gModelPay:GetShowByWelfareId(expendId)
    end

    local _keyDayList = self._keyDayList or {}
    local buyNum = _keyDayList[itemdata.entryId] or 0
    local residueTaskNum = taskBuyNum - buyNum
    local dayNumDStr = string.format("(%s/%s)", dayBuyNum, personalGoal)
    dayNumDStr = LUtil.FormatColorStr(dayNumDStr, dayBuyNum <= 0 and "red" or "green")
    local dayNumStr = string.replace(self._signTips1, dayNumDStr)
    local dayDesStr = string.replace(self._signTips2, residueTaskNum)
    local bGBState = residueTaskNum <= 0            --true 领取；false 购买
    local bOnGBState = dayBuyNum <= 0            --true 已领取 or 已购买；false 未领取 or 未购买
    local btnStr = ""

    local rewardList = bGBState and LxDataHelper.ParseItem(entryCfg.freeReward) or LxDataHelper.ParseItem(entryCfg.reward)

    if not bGBState then
        if bOnGBState then
            btnStr = ccClientText(28300)
        else
            btnStr = payStr
        end
    else
        if bOnGBState then
            btnStr = ccClientText(28302)
        else
            btnStr = ccClientText(28301)
        end
    end

    self:SetWndText(titleText, name)
    local upTabStr = moreInfos[2]
    local isShowUpTabStr = not string.isempty(upTabStr)
    CS.ShowObject(upTab, isShowUpTabStr)
    if isShowUpTabStr then
        self:SetWndText(tabText, upTabStr)
        self:InitTextSizeWithLanguage(tabText, -4)
    end
    self:InitIconEasyList(instanceID, itemScroll, rewardList)
    self:SetWndText(numText, dayNumStr)
    CS.ShowObject(buyText, not bGBState)
    if not bGBState then
        self:SetWndText(buyText, dayDesStr)
    end
    self:SetWndButtonText(btnBuy, btnStr)
    self:SetWndButtonGray(btnBuy, bOnGBState)
    CS.ShowObject(btnEff, bGBState and not bOnGBState)
    if bGBState and not bOnGBState then
        self:CreateWndEffect(btnEff, "fx_anniu_03", instanceID, 100)
    end
    self:SetWndClick(btnBuy, function()
        if not bGBState then
            if bOnGBState then
                GF.ShowMessage(ccClientText(28303))
                return
            end
            local callFunc = function()
                gModelPay:GiftPayCtrl(entryId, expendId, ModelPay.PAY_TYPE_ACTIVITY, nil, sid, pageId)
            end
            GF.OpenWnd("UIGiftBuy78Pop", {
                title = name,
                desc = dayDesStr,
                payStr = payStr,
                payFunc = callFunc,
                itemList = rewardList,
                sid = sid,
                noShowHero = true,
            })
        else
            if bOnGBState then
                GF.ShowMessage(ccClientText(28304))
                return
            end
            gModelActivity:OnActivitySpecialOpReq(sid, pageId, entryId, nil, nil, ModelActivity.SUPER_PRIVILEGE_FREE_BUY)
        end
    end)
end
function UISubOverflowPrige:InitCommand()
    self:SetWndText(self.mOneKeyText, ccClientText(32913))
    local sid = self:GetWndArg("sid")
    self._sid = sid

    gModelActivity:ReqActivityConfigData(sid)
end
function UISubOverflowPrige:InitEvent()
    self:SetWndClick(self.mBtnHelp, function()
        UIHelper.OnClickHelpBtn(self._sid)
    end)
    self:SetWndClick(self.mBtnOneKey, function()
        self:OnClickOneKey()
    end)
end
function UISubOverflowPrige:InitMessage()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if sid ~= self._sid then
            return
        end
        self:OnActivityConfigData()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        local sid = pb.sid
        if self._sid ~= sid then
            return
        end
        self:ResetData(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        local sid = pb.sid
        if self._sid ~= sid then
            return
        end
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        local activities = pb.activities
        for i, v in ipairs(activities) do
            local sid = v.sid
            if self._sid == sid then
                self:RefreshData()
            end
        end
    end)
end
------------------------------------------------------------------
return UISubOverflowPrige


