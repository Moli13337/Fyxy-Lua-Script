---
--- Created by BY.
--- DateTime: 2023/10/22 18:20:50
---
------------------------------------------------------------------
local LWnd = LWnd
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
---@class UIGdDonatePop:LWnd
local UIGdDonatePop = LxWndClass("UIGdDonatePop", LWnd)
------------------------------------------------------------------

local adMethodId = ModelAds.TYPE_ADS_101

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdDonatePop:UIGdDonatePop()
    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdDonatePop:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdDonatePop:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdDonatePop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:RefreshForeign()
end

function UIGdDonatePop:OnTryTcpReconnect()
    gModelGuild:OnGuildDailyBoxInfoReq()
end
function UIGdDonatePop:OnClickRank()
    local minRankScore = gModelGuild:GetGuildConfigRefByKey("minRankScore")
    local _integral = gModelGuild:GetWeekIntegral()                                                --玩家周累积捐献积分
    if _integral < minRankScore then
        GF.ShowMessage(string.replace(ccClientText(28108), minRankScore))
    end
    GF.OpenWndBottom("UIGdRk", { refId = 1101, callFunc = function()
        GF.OpenWnd("UIGdDonatePop")
    end })
    self:WndClose()
end
function UIGdDonatePop:InitMessage()
    self:WndNetMsgRecv(LProtoIds.GuildDailyBoxInfoResp, function(pb)
        local rewards = pb.rewards
        local boxList = {}
        for i, v in ipairs(rewards) do
            local boxRefId = v.boxRefId
            local reward = LxDataHelper.ParseItem(v.reward)
            boxList[boxRefId] = reward
        end
        self._boxList = boxList
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildBoxReceiveResp, function()
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildInfoResp, function()
        self:RefreshData()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:RefreshData()
    end)

    self:WndEventRecv(EventNames.REFRESH_ADS, function()
        gModelGuild:OnGuildDailyBoxInfoReq()
    end)
end
function UIGdDonatePop:InitCommand()
    self:SetWndText(self.mLblBiaoti, ccClientText(12434))
    self:SetWndText(self.mLblBiaoti_enus, ccClientText(12434))

    CS.ShowObject(self.mLblBiaoti_enus, self._isEnus)
    CS.ShowObject(self.mLblBiaoti, not self._isEnus)

    self:SetWndText(self.mLogText, ccClientText(28104))
    self:SetWndText(self.mRankText, ccClientText(28105))

    self:SetWndText(self.mBotText, ccClientText(12648))
    self:SetWndText(self.mBotText_enus, ccClientText(12648))

    CS.ShowObject(self.mBotText_enus, self._isEnus)
    CS.ShowObject(self.mBotText, not self._isEnus)

    gModelGuild:OnGuildDailyBoxInfoReq()

    CS.ShowObject(self.mBtnRank, PRODUCT_G_VER ~= 1)
end

function UIGdDonatePop:OnClickBox(root, itemdata, state)
    --点击领取宝箱
    if state ~= 1 then
        local boxList = self._boxList or {}
        local addRwards = boxList[itemdata.refId] or {}
        local rewardList = gModelGeneral:GetParseItem(itemdata.reward)
        if #addRwards > 0 then
            rewardList = LxDataHelper.MergeTwoRewardList(rewardList, addRwards)
        end
        GF.OpenWnd("UIringBoxDetail", { root, rewardList })
        return
    end
    gModelGuild:OnGuildBoxReceiveReq(itemdata.refId)
end

function UIGdDonatePop:RewardListItem(list, item, itemdata, itempos)
    local icon = self:FindWndTrans(item, "Icon")
    local numText = self:FindWndTrans(item, "NumText")

    local iconStr = gModelItem:GetItemIconByRefId(itemdata.itemId)
    self:SetWndEasyImage(icon, iconStr)
    self:SetWndText(numText, itemdata.itemNum)
    self:SetWndClick(icon, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
end
function UIGdDonatePop:OnClickDonate(itemdata, price)
    local isEnough = gModelGeneral:CheckItemEnough(price.itemId, price.itemNum, true)
    if not isEnough then
        return
    end
    gModelGuild:OnGuildDonateReq(itemdata.refId)
end
function UIGdDonatePop:ListItem(list, item, itemdata, itempos)
    local iconImage = CS.FindTrans(item, "IconImage")
    --local desText = CS.FindTrans(item,"ImageT/DesText")
    local nameText = CS.FindTrans(item, "ImageN/NameText")
    local awardScroll = CS.FindTrans(item, "AwardScroll")
    local moneyText = CS.FindTrans(item, "MoneyText")
    local moneyImage = CS.FindTrans(item, "MoneyText/MoneyImage")
    local btnDonate = CS.FindTrans(item, "BtnDonate")

    local instanceID = item:GetInstanceID()
    local rewardList = string.split(itemdata.reward, "|")
    local num = gModelGuild:GetDonateNumByRefId(itemdata.refId)
    local rewardIndex = num >= #rewardList and #rewardList or num + 1
    local rewardArr = gModelGeneral:GetParseItem(rewardList[rewardIndex])
    local priceArr = {}
    local refPrice = string.split(itemdata.price, "|")
    for i, v in ipairs(refPrice) do
        local price = gModelGeneral:GetParseItem_3(v)
        table.insert(priceArr, price)
    end
    local len = #priceArr
    local price = num < len and priceArr[num + 1] or priceArr[len]
    local timeLimit = itemdata.timeLimit
    local residueNum = timeLimit - num >= 0 and timeLimit - num or 0

    self:SetWndEasyImage(iconImage, itemdata.icon)
    --self:SetWndText(desText,ccLngText(itemdata.description))
    self:SetWndText(nameText, ccLngText(itemdata.name))
    self:SetWndEasyImage(moneyImage, gModelItem:GetItemIconByRefId(price.itemId))
    local bagItemNum = gModelItem:GetNumByRefId(price.itemId)
    local moneyStr = LUtil.FormatColorStr(LUtil.NumberCoversion(bagItemNum), bagItemNum >= price.itemNum and "green" or "red")
    moneyStr = string.format("%s/%s", moneyStr, LUtil.NumberCoversion(price.itemNum))
    self:SetWndText(moneyText, moneyStr)
    self:SetWndButtonText(btnDonate, string.replace(ccClientText(28103), residueNum))
    self:SetWndButtonGray(btnDonate, residueNum <= 0)

    local _uiList = self:GetUIScroll("_uiList" .. instanceID)
    if _uiList:GetList() then
        _uiList:RefreshList(rewardArr)
    else
        _uiList:Create(awardScroll, rewardArr, function(...)
            self:RewardListItem(...)
        end)
        _uiList:EnableScroll(false)
    end

    self:SetWndClick(btnDonate, function()
        if residueNum <= 0 then
            GF.ShowMessage(ccClientText(28107))
            return
        end
        self:OnClickDonate(itemdata, price)
    end)
end

function UIGdDonatePop:BoxListItem(list, item, itemdata, itempos)
    local boxIcon = self:FindWndTrans(item, "BoxIcon")
    local numBg = self:FindWndTrans(item, "NumBg")
    local numText = self:FindWndTrans(item, "NumBg/NumText")
    local redPoint = self:FindWndTrans(item, "redPoint")
    local eff = self:FindWndTrans(item, "Eff")

    local numBgCanvas = numBg:GetComponent(typeof(UnityEngine.Canvas))
    numBgCanvas.sortingOrder = self:GetWndSortOrder() + 4
    numBgCanvas.sortingLayerName = self:GetWndSortLayer()

    local finishCond = itemdata.finishCond
    local _integral = self._integral
    local box = string.split(itemdata.box, ",")
    local isAlreadyGet = gModelGuild:GetGuilReceiveIdByRefId(itemdata.refId)
    local state = isAlreadyGet and 2 or (_integral >= finishCond and 1 or 0)

    self:SetWndText(numText, finishCond)
    local boxStr = box[state + 1]
    self:SetWndEasyImage(boxIcon, boxStr)
    CS.ShowObject(redPoint, state == 1)
    if state == 1 then
        self:CreateWndEffect(eff, "fx_richangbaoxiang", "fx_richangbaoxiang" .. itempos, 110, false, false)
    else
        self:DestroyWndEffectByKey("fx_richangbaoxiang" .. itempos)
    end

    self:SetWndClick(boxIcon, function()
        self:OnClickBox(boxIcon, itemdata, state)
    end)
end

function UIGdDonatePop:SetBoxItem(item, data, itempos)
    local boxIcon = self:FindWndTrans(item, "BoxIcon")
    local isGet = self:FindWndTrans(item, "IsGet")
    local numBg = self:FindWndTrans(item, "NumBg")
    local numText = self:FindWndTrans(item, "NumBg/NumText")
    -- local redPoint = self:FindWndTrans(item, "redPoint")
    local eff = self:FindWndTrans(item, "Eff")

    local numBgCanvas = numBg:GetComponent(typeof(UnityEngine.Canvas))
    numBgCanvas.sortingOrder = self:GetWndSortOrder() + 4
    numBgCanvas.sortingLayerName = self:GetWndSortLayer()

    local finishCond = data.finishCond
    local _integral = self._integral
    local box = string.split(data.box, ",")
    local isAlreadyGet = gModelGuild:GetGuilReceiveIdByRefId(data.refId)
    local state = isAlreadyGet and 2 or (_integral >= finishCond and 1 or 0)

    self:SetWndText(numText, finishCond)
    local index = state + 1 == 3 and 1 or state + 1
    local boxStr = box[index]
    self:SetWndEasyImage(boxIcon, boxStr, nil, true)

    -- CS.ShowObject(redPoint, state == 1)
    CS.ShowObject(isGet, state == 2)
    if state == 1 then
        self:CreateWndEffect(eff, "fx_ui_gonghuibaoxiang_0" .. itempos, "fx_ui_gonghuibaoxiang_0" .. itempos, 110, false, false)
    else
        self:DestroyWndEffectByKey("fx_ui_gonghuibaoxiang_0" .. itempos)
    end

    self:SetWndClick(item, function()
        self:OnClickBox(boxIcon, data, state)
    end)
end
function UIGdDonatePop:InitEvent()
    self:SetWndClick(self.mCloseBtn, function(...)
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBgImage, function(...)
        self:OnClickClose()
    end)
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function(index)
        if index == 4 then
            self:OnClickClose()
        end
    end)
    self:SetWndClick(self.mBtnLog, function(...)
        self:OnClickRecord()
    end)
    self:SetWndClick(self.mBtnRank, function(...)
        self:OnClickRank()
    end)
    self:SetWndClick(self.mHelpBtn, function(...)
        self:OnClickHelp()
    end)
end

function UIGdDonatePop:DrawCell(_, item, data, index)
    local bg = CS.FindTrans(item, "Image")
    local iconImage = CS.FindTrans(item, "IconImage")
    local nameText = CS.FindTrans(item, "NameText")
    local awardList = CS.FindTrans(item, "AwardList")
    local moneyText = CS.FindTrans(item, "MoneyText")
    local moneyImage = CS.FindTrans(item, "MoneyText/MoneyImage")
    local btnDonate = CS.FindTrans(item, "BtnDonate")
    local BtnCommonAd = CS.FindTrans(item,"BtnCommonAd")
    local ADRedPoint = CS.FindTrans(item,"ADRedPoint")

    local refId = data.refId
    local rewardList = string.split(data.reward, "|")
    local num = gModelGuild:GetDonateNumByRefId(refId)
    local rewardIndex = num >= #rewardList and #rewardList or num + 1
    local rewardArr = gModelGeneral:GetParseItem(rewardList[rewardIndex])
    local priceArr = {}
    local refPrice = string.split(data.price, "|")
    for i, v in ipairs(refPrice) do
        local price = gModelGeneral:GetParseItem_3(v)
        table.insert(priceArr, price)
    end
    local len = #priceArr
    local price = num < len and priceArr[num + 1] or priceArr[len]
    local timeLimit = data.timeLimit
    local residueNum = timeLimit - num >= 0 and timeLimit - num or 0

    self:SetWndTabAdBtnInfo({
        btnTrans = BtnCommonAd,
        redPoint = ADRedPoint,
    },{
        adMethodId = adMethodId,
        refId = refId,
        checkHasCount = true,
        wndId = 490001,
        textId = 28103,
    })

    if self._isVie then

        local uiText = LxUiHelper.FindXTextCtrl(nameText)
        uiText.characterSpacing = -7
        self:InitTextSizeWithLanguage(nameText, -1)
    end

    self:SetWndEasyImage(bg, data.cellBg)
    self:SetWndEasyImage(iconImage, data.icon)
    self:SetWndText(nameText, ccLngText(data.name))
    self:SetWndEasyImage(moneyImage, gModelItem:GetItemIconByRefId(price.itemId))
    local bagItemNum = gModelItem:GetNumByRefId(price.itemId)
    local moneyStr = LUtil.FormatColorStr(LUtil.NumberCoversion(bagItemNum), bagItemNum >= price.itemNum and "#68e6ac" or "red")
    moneyStr = string.format("%s/%s", moneyStr, LUtil.NumberCoversion(price.itemNum))
    self:SetWndText(moneyText, moneyStr)
    self:SetWndButtonText(btnDonate, string.replace(ccClientText(28103), residueNum))
    self:SetWndButtonGray(btnDonate, residueNum <= 0)

    for i = 1, 3 do
        local tran = CS.FindTrans(awardList, "Award" .. i)
        self:RewardListItem(nil, tran, rewardArr[i])
    end

    self:SetWndClick(btnDonate, function()
        if residueNum <= 0 then
            GF.ShowMessage(ccClientText(28107))
            return
        end
        self:OnClickDonate(data, price)
    end)
end
function UIGdDonatePop:OnClickHelp()
    GF.OpenWnd("UIBzTips", { refId = 16 })
end

function UIGdDonatePop:RefreshData()
    local guildInfo = gModelGuild:GetGuildInfo()
    local selfGuildInfo = gModelGuild:GetSelfGuildInfo()
    if not guildInfo or not selfGuildInfo then
        return
    end
    local level = guildInfo.level
    local exp = guildInfo.exp
    local nexExp = gModelGuild:GetGuildExpByLv(level)
    -- local flagBgRef = gModelGuild:GetGuildFlagRefByRefId(guildInfo.flagBgId)
    -- local flagIconRef = gModelGuild:GetGuildFlagRefByRefId(guildInfo.flagId)
    -- local donateExp = gModelGuild:GetGuildEverydayExp()                                             --公会每日捐献经验
    -- local guildExpMaxFromContri = gModelGuild:GetGuildConfigRefByKey("guildExpMaxFromContri") or 0  --每天通过捐献获取的联盟经验上限
    local _integral = gModelGuild:GetGuildIntegral()                                                --玩家单日累积捐献积分
    local _donateChestList = gModelGuild:GetGuildDonateChestRefDataList()
    self.maxExp = _donateChestList[#_donateChestList].finishCond                                   --捐献宝箱最大值
    local remainDonateExpCount = gModelGuild:GetRemainDonateExpCount()

    -- if flagBgRef then self:SetWndEasyImage(self.mFlagBg,flagBgRef.res) end
    -- if flagIconRef then self:SetWndEasyImage(self.mFlagIcon,flagIconRef.res) end
    self:SetWndText(self.mGuildLvText, string.replace(ccClientText(28101), level))
    self.mGuildExpBar.maxValue = nexExp == -1 and exp or nexExp
    self.mGuildExpBar.value = exp
    self:SetWndText(self.mBarText, nexExp == -1 and ccClientText(12611) or string.format("%s/%s", exp, nexExp))
    self:SetWndText(self.mStatisticsText, string.replace(ccClientText(28100), remainDonateExpCount))
    self:InitTextLineWithLanguage(self.mStatisticsText, -30)
    self:InitTextSizeWithLanguage(self.mStatisticsText, -2)
    -- self:SetWndText(self.mIntegralText,_integral)

    local scoreText1 = CS.FindTrans(self.mScore, "Text1")
    local scoreText2 = CS.FindTrans(self.mScore, "Text2")
    self:SetWndText(scoreText1, ccClientText(12407))
    self:SetWndText(scoreText2, _integral)
    LayoutRebuilder.ForceRebuildLayoutImmediate(scoreText1)
    LayoutRebuilder.ForceRebuildLayoutImmediate(scoreText2)
    local giveText = self._isEnus and self.mGiveText_en or self.mGiveText

    self:SetWndText(giveText, string.replace(ccClientText(12408), remainDonateExpCount, gModelGuild:GetGuildNumByLv(guildInfo.level)))

    self.mExpBar.maxValue = 1
    local dataList = {}
    for k, v in ipairs(_donateChestList) do
        table.insert(dataList, v.finishCond)
    end

    local getPecent = function()
        local maxV = { 0.1, 0.37, 0.66, 0.94, 1 }
        for i, v in ipairs(dataList) do
            if _integral <= v then
                local max = maxV[i]
                local min = maxV[i - 1] or 0
                local s = max - min
                return _integral / v * s + min
            end
        end
        return 1
    end

    -- local boxValue = LUtil.GetCurPercent(dataList,_integral)
    local boxValue = getPecent()
    self.mExpBar.value = boxValue

    self._integral = _integral
    -- local _uiBoxList = self._uiBoxList
    -- if _uiBoxList then
    --     _uiBoxList:RefreshList(_donateChestList)
    -- else
    --     _uiBoxList = self:GetUIScroll("UIGdDonatePop_mBoxList")
    --     self._uiBoxList = _uiBoxList
    --     _uiBoxList:Create(self.mBoxList,_donateChestList,function (...) self:BoxListItem(...) end)
    -- end
    for i, v in ipairs(_donateChestList) do
        local tran = CS.FindTrans(self.mBoxList, "Box" .. i)
        if tran then
            self:SetBoxItem(tran, v, i)
        end
    end

    local list = gModelGuild:GetGuildDonateRefDataList()
    -- local _uiList = self._uiList
    -- if _uiList then
    --     _uiList:RefreshList(list)
    -- else
    --     _uiList = self:GetUIScroll("UIGdDonatePop_mCellScroll")
    --     self._uiList = _uiList
    --     _uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
    --     _uiList:EnableScroll(true,false)
    -- end

    if self.cellList then
        self.cellList:RefreshList(list)
        self.cellList:DrawAllItems()
    else
        self.cellList = self:GetUIScroll("mCellList")
        self.cellList:Create(self.mCellList, list, function(...)
            self:DrawCell(...)
        end, UIItemList.SUPER_GRID)
    end
end
function UIGdDonatePop:OnClickRecord()
    --点击公会日志
    GF.OpenWnd("UIGdLogPop", { tabIndex = 2 })
end
function UIGdDonatePop:OnClickClose()
    if not self:WndCloseAndBack() then
        GF.OpenWnd("UIGdWin")
    end
end

function UIGdDonatePop:RefreshForeign()
    if self._isVie then
        self:SetAnchorPos(self.mGuildLvText, Vector2.New(-218, -104.5))
        self:SetAnchorPos(self.mScore, Vector2.New(-218, 0))
        self:SetAnchorPos(self.mBotText_enus, Vector2.New(-70, 0))

        LxUiHelper.SetSizeWithCurAnchor(self.mRankText, 0, 50)
        LxUiHelper.SetSizeWithCurAnchor(self.mLogText, 0, 50)
        LxUiHelper.SetSizeWithCurAnchor(self.mBotText_enus, 0, 420)
        local textTran = LxUiHelper.FindXTextCtrl(self.mRankText)
        textTran .enableWordWrapping = true

        textTran = LxUiHelper.FindXTextCtrl(self.mLogText)
        textTran .enableWordWrapping = true

        textTran = LxUiHelper.FindXTextCtrl(self.mBotText_enus)
        textTran .enableWordWrapping = true

    end
end
------------------------------------------------------------------
return UIGdDonatePop


