---
--- Created by Administrator.
--- DateTime: 2024/5/15 16:57:02
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubOpenSerGift:LChildWnd
local UISubOpenSerGift = LxWndClass("UISubOpenSerGift", LChildWnd)
------------------------------------------------------------------
--local BtnPos = {
--	{{1.5,169.5}},
--	{{-60,156},  {60,156}},
--	{{-115,145}, {1.5,169.5},{116,145}},
--	{{-176,99},  {-60,156},  {60,156},   {176,99}},
--	{{-202.5,91},{-115,145}, {1.5,169.5},{116,145},  {202,91}},
--	{{-260.5,15},{-176,99},  {-60,156},  {60,156},   {176,99}, {260.5,15}},
--	{{-260.5,2}, {-202.5,91},{-115,145}, {1.5,169.5},{116,145},{202,91},{260.5,2}},
--}

local BtnPos = { { { 8.4, -26.7 } }, }
local BtnOffset = 81.6
local _buyTypeText = {
    [0] = ccClientText(42500),
    [1] = ccClientText(42501), -- 每日限购
    [2] = ccClientText(42502), -- 每周限购
    [3] = ccClientText(42503), -- 每月限购
    [4] = ccClientText(42504), -- 每月限购
}
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubOpenSerGift:UISubOpenSerGift()
    self.entryId = nil
    self.entryMoreInfo = {}
    self._showTimeKey = "_endTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubOpenSerGift:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubOpenSerGift:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubOpenSerGift:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self._isEnus = gLGameLanguage:IsForeignVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self.sid = self:GetWndArg("sid")

    gModelActivity:ReqActivityConfigData(self.sid)

    self.sid = self:GetWndArg("sid")
    self.pageId = self:GetWndArg("pageId")
    self.entryId = self:GetWndArg("entryId")
    self.entryIndx = 1
    self:OnEventCliclk()
    self:OnUpdatePanel()

end
function UISubOpenSerGift:OnUpdateBtnArrow()
    local leng = #self.activityPageData.entries
    --CS.ShowObject(self.mBtnLeft, self.entryIndx > 1)
    --CS.ShowObject(self.mBtnRight, self.entryIndx < leng)
end
function UISubOpenSerGift:OnTimer(key)
    if (key == self._showTimeKey) then
        -- self:SetTimeTxt()
    end

end
function UISubOpenSerGift:SetTimeTxt()
    local nowTime = GetTimestamp()
    local timeDif = os.difftime(self._endTime, nowTime)
    if timeDif < 0 then
        self:TimerStop(self._showTimeKey)
        return
    end
    local timeStr = LUtil.FormatTimespanCn(timeDif)
    timeStr = string.replace(ccClientText(39002), timeStr)
    self:SetWndText(self.mTxtTime, timeStr)
end
function UISubOpenSerGift:OnClickItem(item, itemdata, index)
    local isLock = self._lockData[self.entryIndx]
    local selectTranName = isLock and "ImgSelect_Lock" or "ImgSelect"
    local oldSelect = self:FindWndTrans(self.selectItem, selectTranName)
    CS.ShowObject(oldSelect, false)

    self.selectCustom = nil
    self.selectItem = item
    self.entryIndx = index
    self.entryId = itemdata.id

    isLock = self._lockData[index]
    selectTranName = isLock and "ImgSelect_Lock" or "ImgSelect"
    local ImgSelect = self:FindWndTrans(self.selectItem, selectTranName)
    CS.ShowObject(ImgSelect, true)
    self:OnUpateItemPoint(self.entryIndx)
    --self:OnUpdateBtnArrow()
    self:OnUpdateRwdList()
    self:ContentPanel()
end

function UISubOpenSerGift:ContentPanel()
    local entry = self.activityPageData.entries[self.entryIndx]

    local entryMoreInfo = self:GetEntryMoreInfo(entry)
    self:SetWndEasyImage(self.mImgBigBg, entryMoreInfo[3])
    local spineStr = entryMoreInfo[4]--self.entryMoreInfo[self.entryId][4]
    local sparam4 = string.split(spineStr, "=")
    local pos = string.split(sparam4[3], ",")
    if tonumber(sparam4[1]) == 0 then
        CS.ShowObject(self.mHeroLiHuiPos, false)
        CS.ShowObject(self.mHeroSpineBg, true)
        self:SetWndEasyImage(self.mHeroSpineBg, sparam4[2])
        local csImage = LxUiHelper.FindImageCtrl(self.mHeroSpineBg)
        csImage:SetNativeSize()
        local localPos = self.mHeroSpineBg.localPosition
        if tonumber(pos[1]) ~= nil then
            localPos.x = tonumber(pos[1])
        end
        if tonumber(pos[2]) ~= nil then
            localPos.y = tonumber(pos[2])
        end
        self.mHeroSpineBg.localPosition = localPos
    else
        --lihui
        CS.ShowObject(self.mHeroLiHuiPos, true)
        CS.ShowObject(self.mHeroSpineBg, false)
        self:DestroyWndSpineByKey("openServerGift")
        local heroRef = GameTable.CharacterEffectRef[tonumber(sparam4[2])]
        local dpSpine = self:CreateWndSpine(self.mHeroLiHuiPos, heroRef.heroDrawing or "LH_Hudie01", "openServerGift", true, function(dpLoaded)
            dpLoaded:SetScale(1)
            dpLoaded:PlayAnimation(0, "idle", true)
        end, true)
        dpSpine:StartLoad()
        local localPos = self.mHeroLiHuiPos.localPosition
        if tonumber(pos[1]) ~= nil then
            localPos.x = tonumber(pos[1])
        end
        if tonumber(pos[2]) ~= nil then
            localPos.y = tonumber(pos[2])
        end
        self.mHeroLiHuiPos.localPosition = localPos
    end
    local sparam5 = string.split(entryMoreInfo[5], "=")
    self:SetWndEasyImage(self.mImgTxt, sparam5[1], nil, true)

    if self._isEnus then
        self.mImgTxt.localScale= Vector3.one * 0.7
        self:SetAnchorPos(self.mImgDiscount,Vector2.New(107.7,-280))
    end

    pos = string.split(sparam5[2], ",")
    local localPos = self.mImgTxt.localPosition
    if tonumber(pos[1]) ~= nil then
        localPos.x = tonumber(pos[1])
    end
    if tonumber(pos[2]) ~= nil then
        localPos.y = tonumber(pos[2])
    end
    self.mImgTxt.localPosition = localPos
    ---@type StructActivityEntry
    local entryInfo = self.activityPageData.entries[self.entryIndx]
    local descs = string.split(entryInfo.description, "|")
    self:SetWndText(self.mTxtDesc, descs[1])
    local serPageData = gModelActivity:GetActivityPagesBySid(self.sid,self.pageId)
    local serEntryInfo = serPageData and serPageData.entry[self.entryIndx]
    ---@type StructMarketData
    local marketData = serEntryInfo.MarketData
    local leftNum = marketData.personalGoal - marketData.personal
    --self:SetWndText(self.mTxtLimit, _buyTypeText[marketData.condResetType] .. "：" .. marketData.personal .. "/" .. marketData.personalGoal)
    self:SetWndText(self.mTxtLimit, _buyTypeText[marketData.condResetType] .. "：" .. leftNum)
    CS.ShowObject(self.mTxtLimit, marketData.condResetType ~= 0)
    self:SetWndText(self.mTxtDiscountDes, ccClientText(14914))
    self:SetWndText(self.mTxtDiscount, marketData.discount .. "%")
    CS.ShowObject(self.mImgDiscount, marketData.discount > 0)
    self:SetWndButtonGray(self.mBtnUse, marketData.personal >= marketData.personalGoal)
    if marketData.expendType == 1 then
        self:SetCostItem(marketData)
        self:SetWndButtonText(self.mBtnUse, "")
    elseif marketData.expendType == 2 then


        --local num= LUtil.FormatHurtNumSpriteText(checknumber(marketData.expend2))
        --local symbol=gModelPay:GetMoneySymbol()
        local str = gModelPay:GetPayType(2, checknumber(marketData.expend2))
        self:SetWndButtonText(self.mBtnUse, str)
        if self.jpj then
            local text1 = CS.FindTrans(self.mBtnUse,"Light/Text")
            self:InitTextCharacterWithLanguage(text1,8)
            local text2 = CS.FindTrans(self.mBtnUse,"Gray/Text")
            self:InitTextCharacterWithLanguage(text2,8)
        end

        --
        --local light= CS.FindTrans(self.mBtnUse,"Light/Text")
        --self:SetWndText(light, symbol)
        --local numTran= CS.FindTrans(self.mBtnUse,"Light/BtnNumber")
        --self:SetWndText(numTran,num)
        --
        --local gray= CS.FindTrans(self.mBtnUse,"Gray/Text")
        --
        --self:SetWndText(gray, symbol..marketData.expend2)
    else
        local str = ccClientText(42505)
        self:SetWndButtonText(self.mBtnUse, str)
    end
    CS.ShowObject(self.mTxtCost, marketData.expendType == 1)

    CS.ShowObject(self.mImgDiscount, true)
    local curTime = GetTimestamp()
    local activityTime = math.ceil((curTime - self.activityData.startTime) / 86400)
    if tonumber(entryMoreInfo[1]) > activityTime then
        self:SetWndButtonGray(self.mBtnUse, true)
        self:SetWndButtonText(self.mBtnUse, descs[2])
        CS.ShowObject(self.mImgDiscount, false)
    end

    self:SetWndEasyImage(self.mPanelIcon, entry.icon, nil, true)

    --获取背景
    local desPanelBg = entryMoreInfo[7]
    if not string.isempty(desPanelBg) then
        self.SetWndEasyImage(self.mDesBg, desPanelBg)
    end

    self:SetWndText(self.mDesBgUIText, ccClientText(45305))
    if self.jpj then
        self:InitTextSizeWithLanguage(self.mDesBgUIText,-2)
    end
end
function UISubOpenSerGift:OnUpdatePanel()
    self.activityPageData = gModelActivity:GetWebActivityPageData(self.sid,self.pageId) --gModelActivity:GetActivityPagesBySid(self.sid, self.pageId)
    if not self.mTabItems or not self.activityPageData then
        return
    end
    self.activityData = gModelActivity:GetActivityBySid(self.sid)
    if not self.entryId then
        self.entryId = self.activityPageData.entries[1].id
        local curTime = GetTimestamp()
        local openDay = math.ceil((curTime - self.activityData.startTime) / 86400)
        for k, v in pairs(self.activityPageData.entries) do
            local moreInfo = self:GetEntryMoreInfo(v)
            if tonumber(moreInfo[1]) == openDay then
                self.entryId = v.id
                break
            end
        end
    end
    if self.activityData and self.activityData.endTime > 0 then
        self._endTime = self.activityData.endTime
        -- self:TimerStart(self._showTimeKey, 1, false, -1)
    end
    self:OnUpdateBtnItems()
    self:OnUpdateRwdList()
    self:ContentPanel()
    self:OnUpateItemPoint(self.entryIndx)
    --self:OnUpdateBtnArrow()
end

function UISubOpenSerGift:GetEntryMoreInfo(entry)
    local moreInfos = self.entryMoreInfo[self.pageId]
    if not moreInfos then
        moreInfos = {}
        self.entryMoreInfo[self.pageId] = moreInfos
    end
    local moreInfo = moreInfos[entry.id]
    if moreInfo then
        return moreInfo
    end
    moreInfo = string.split(entry.moreInfo, "|")
    moreInfos[entry.id] = moreInfo
    return moreInfo
end

function UISubOpenSerGift:OnClickBuy()
    ---@type StructActivityEntry
    local entryInfo = self.activityPageData.entries[self.entryIndx]
    local moreInfo = self:GetEntryMoreInfo(entryInfo)
    local curTime = GetTimestamp()
    local activityTime = math.ceil((curTime - self.activityData.startTime) / 86400)
    if curTime >= self.activityData.endTime then
        GF.ShowMessage(ccClientText(29200))
        return
    end
    if tonumber(moreInfo[1]) > activityTime then
        local strs = string.split(entryInfo.description, "|")
        GF.ShowMessage(strs[1])
        return
    end
    local pageData = gModelActivity:GetActivityPagesBySid(self.sid,self.pageId)
    local serEntryInfo = pageData and pageData.entry[self.entryIndx]
    local customList = string.split(serEntryInfo.MarketData.customList, "|")
    local customGift = string.split(serEntryInfo.MarketData.customGift or "", ",")
    if #customList > #customGift then
        GF.OpenWnd("UICumSelectNew", { sid = self.sid, pageId = self.pageId, entryId = self.entryId,
                                           itemIndex = 1, giftData = serEntryInfo, title = entryInfo.name })
        return
    end
    ---@type StructMarketData
    local marketData = serEntryInfo.MarketData
    if marketData.personal >= marketData.personalGoal then
        GF.ShowMessage(ccClientText(42506))
    else
        if marketData.expendType == 1 then
            local costItemData = LxDataHelper.ParseItem_4(marketData.expend2)
            local haveCount = gModelItem:GetNumByRefId(costItemData.itemId)
            if costItemData.itemNum > haveCount then
                gModelGeneral:OpenGetWayWnd({ itemId = costItemData.itemId })
            else
                gModelActivity:OnActivityMarkeyBuyReq(self.sid, self.pageId, entryInfo.id)
            end
        elseif marketData.expendType == 2 then
            gModelPay:GiftPayCtrl(entryInfo.id, tonumber(marketData.expend2), ModelPay.PAY_TYPE_ACTIVITY, nil, self.sid, self.pageId)
        else
            gModelActivity:OnActivityMarkeyBuyReq(self.sid, self.pageId, entryInfo.id)
        end
    end
end
function UISubOpenSerGift:OnClickArrow(num)
    self.entryIndx = self.entryIndx + num
    local entrys = self.activityPageData.entries[self.entryIndx]
    self.entryId = entrys.id
    local item = self.mTabItems:GetChild(self.entryIndx - 1)
    self:OnClickItem(item, entrys, self.entryIndx)
end
function UISubOpenSerGift:SetData(params)
    if not params.sid or not params.pageId then
        return
    end
    self.sid = params.sid
    self.pageId = params.pageId
    self.entryId = params.entryId
    self.entryIndx = 1
    self:OnUpdatePanel()
end

function UISubOpenSerGift:OnUpdateRwdList()
    local serPageData = gModelActivity:GetActivityPagesBySid(self.sid,self.pageId)
    local items = serPageData.entry[self.entryIndx].items
    local list = {}
    for i, v in ipairs(items) do
        table.insert(list, v)
    end
    ---@type StructMarketData
    local marketData = serPageData.entry[self.entryIndx].MarketData
    local customList = string.split(marketData.customList, "|")
    local customGift = string.split(marketData.customGift, ",")
    if customList and #customList > 0 then
        local giftLen = #customGift
        for k, v in ipairs(customList) do
            if k > giftLen then
                table.insert(list, { custom = true, items = v, customIndx = k })
            else
                local itemdata = LxDataHelper.ParseItem_4(customGift[k])
                itemdata.item = true
                itemdata.custom = true
                itemdata.customIndx = k
                table.insert(list, itemdata)
            end
        end
    end
    local uiRwdList = self._uiRwdList
    if uiRwdList then
        uiRwdList:RefreshList(list)
    else
        uiRwdList = self:GetUIScroll("openserverList")
        self._uiRwdList = uiRwdList
        uiRwdList:Create(self.mListReward, list, function(...)
            self:OnDrawRwdItem(...)
        end)
    end
end
function UISubOpenSerGift:OnUpdateBtnItems()
    local activityPageData = self.activityPageData
    local entrys = activityPageData and activityPageData.entries
    --local _btnPos = BtnPos[#entrys] or {}

    local _btnPos = BtnPos[1]
    local offset = BtnOffset

    local childCount = self.mTabItems.transform.childCount
    for i = 1, childCount, 1 do
        local btnItem = self.mTabItems:GetChild(i - 1)
        local point = self.mItemPoints:GetChild(i - 1)
        local entryData = entrys[i]
        CS.ShowObject(btnItem, not not entryData)
        CS.ShowObject(point, not not entryData)
        if entryData then
            local pos = btnItem.localPosition
            pos.x = _btnPos[1][1]
            pos.y = _btnPos[1][2] - (i - 1) * offset
            btnItem.localPosition = pos
            self:UpdateBtnItem(btnItem, entryData, i)
            if self.entryId == entryData.id then
                self.entryIndx = i
            end
        end
    end


end

function UISubOpenSerGift:OnUpateItemPoint(index)
    local oldPoint = self.selectPoint
    if oldPoint then
        self:SetWndEasyImage(oldPoint, "hero_star_eq_2")
    end
    self.selectPoint = self.mItemPoints:GetChild(index - 1)
    self:SetWndEasyImage(self.selectPoint, "hero_star_eq_1")
end
function UISubOpenSerGift:OnEventCliclk()
    self:SetWndClick(self.mBtnUse, function()
        self:OnClickBuy()
    end)
    -- self:WndNetMsgRecv(LProtoIds.ActivityMarkeyBuyResp,function (pb)
    -- end)
    self:SetWndClick(self.mBtnLeft, function()
        self:OnClickArrow(-1)
    end)
    self:SetWndClick(self.mBtnRight, function()
        self:OnClickArrow(1)
    end)
    -- self:WndEventRecv(EventNames.ON_ACTIVITY_PAGE_CHANGE,function() self:OnUpdatePanel() end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function(data,sid)
        if sid ~= self.sid then return end
        self:OnUpdatePanel()
    end)
end

function UISubOpenSerGift:UpdateBtnItem(item, itemdata, index)
    local Di = self:FindWndTrans(item, "Di")
    local ImgSelect = self:FindWndTrans(item, "ImgSelect")
    local ImgSelect_Lock = self:FindWndTrans(item, "ImgSelect_Lock")
    local TxtDay = self:FindWndTrans(item, "TxtDay")
    local Des = self:FindWndTrans(item, "Des")
    local Lock = self:FindWndTrans(item, "Lock")
    --self:SetWndEasyImage(item, itemdata.icon)


    --获取解析的moreInfo 设置其他的数据
    local entryInfo = itemdata --self.activityPageData.entry[index]
    local moreInfo = self:GetEntryMoreInfo(entryInfo)

    --开服天数

    local openDay = checknumber(moreInfo[1])
    local curTime = GetTimestamp()
    local activityTime = math.ceil((curTime - self.activityData.startTime) / 86400)
    local isLock = false
    if openDay > activityTime then
        isLock = true
    end

    self:SetWndText(TxtDay, itemdata.name)
    ImgSelect = isLock and ImgSelect_Lock or ImgSelect
    CS.ShowObject(ImgSelect, itemdata.id == self.entryId)

    --缓存一次lock
    self._lockData = self._lockData or {}
    self._lockData[index] = isLock

    CS.ShowObject(Di, not isLock)
    CS.ShowObject(Lock, isLock)

    local desStr = moreInfo[6]
    local isDesStr = not string.isempty(desStr)
    if isDesStr then
        self:SetWndText(Des, ccLngText(desStr))
    end
    CS.ShowObject(Des, isDesStr)

    if itemdata.id == self.entryId then
        self.selectItem = item
    end

    self:SetWndClick(item, function()
        self:OnClickItem(item, itemdata, index)
    end)
end

--设置消耗道具
function UISubOpenSerGift:SetCostItem(marketData)
    local costItemData = LxDataHelper.ParseItem_4(marketData.expend2)
    local itemIconPath = gModelItem:GetItemImgByRefId(costItemData.itemId)
    self:SetWndEasyImage(self.mImgCost, itemIconPath)
    self:SetWndText(self.mTxtCost, costItemData.itemNum)

end

function UISubOpenSerGift:OnDrawRwdItem(list, item, itemData, itempos)
    local CommonUIIcon = self:FindWndTrans(item, "Icon")
    local ImgSelect = self:FindWndTrans(item, "ImgSelect")
    local ImgAdd = self:FindWndTrans(item, "ImgAdd")
    local id = itemData.itemId
    local type = itemData.type or itemData.itemType
    local count = itemData.count or itemData.itemNum
    if itemData.type or itemData.itemType then
        local instanceId = item:GetInstanceID()
        local baseClass = self:GetCommonIcon(instanceId)
        baseClass:Create(CommonUIIcon)
        baseClass:SetCommonReward(type, id, count)
        baseClass:DoApply()
    end

    CS.ShowObject(ImgSelect, false)
    CS.ShowObject(ImgAdd, itemData.custom and not itemData.item)
    CS.ShowObject(CommonUIIcon, not not type)

    self:SetWndClick(item, function()
        if not itemData.custom then
            gModelGeneral:ShowCommonItemTipWnd(itemData)
        else
            CS.ShowObject(ImgSelect, true)
            if self.selectCustom then
                local oldImgSelect = self:FindWndTrans(self.selectCustom, "ImgSelect")
                CS.ShowObject(oldImgSelect, false)
            end
            self.selectCustom = item
            local entry = self.activityPageData.entries[self.entryIndx]
            local serPageData = gModelActivity:GetActivityPagesBySid(self.sid,self.pageId)
            local serEntry = serPageData and serPageData.entry
            GF.OpenWnd("UICumSelectNew", { sid = self.sid, pageId = self.pageId, entryId = self.entryId,
                                               itemIndex = itemData.customIndx, giftData = serEntry, title = entry.title })
        end
    end)
end
------------------------------------------------------------------
return UISubOpenSerGift