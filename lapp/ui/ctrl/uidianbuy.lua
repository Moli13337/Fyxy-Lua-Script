---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDianBuy:LWnd
local UIDianBuy = LxWndClass("UIDianBuy", LWnd)
local CS = CS
local UnityEngine = UnityEngine
local typeof = typeof
local typeUISlider = typeof(UnityEngine.UI.Slider)

UIDianBuy.NORMAL = 1
UIDianBuy.TREASURE_TICKET = 2
UIDianBuy.GROUP_BUY = 3        --团购
UIDianBuy.ACTIVITY_SELL = 4        -- 活动出售
UIDianBuy.CrusadeAgainst = 5        --梦境讨伐
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDianBuy:UIDianBuy()
    ---@type CommonIcon
    self._iconCls = nil
    self._buyNum = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDianBuy:OnWndClose()
    if self._iconCls then
        self._iconCls:Destroy()
        self._iconCls = nil
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDianBuy:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDianBuy:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    --self:SetWndClick(self.mCloseBtn,function () self:WndClose() end)
    self:InitUIEvent()
    self:InitItem()
    self:SetPara()
    self:InitData()
    self:SetStaticContent()

    local _wndType = self._wndType
    if _wndType == UIDianBuy.NORMAL then
        if self._shopType == ModelShop.ACTIVITY then
            self:ShowActGoods()
        else
            self:RefreshUI()
        end
    elseif _wndType == UIDianBuy.GROUP_BUY then
        self:ShowGroupBuy()
    elseif _wndType == UIDianBuy.ACTIVITY_SELL then
        self:ShowActivitySell()
    elseif _wndType == UIDianBuy.CrusadeAgainst then
        self:ShowCrusadeAgainst()
    else
        self:ShowTreasureBuy()
    end

    self:InitEvent()
end

function UIDianBuy:SetStaticContent()
    local showTitle = self:GetWndArg("showTitle") or ccClientText(11412)
    self:SetWndText(self.mLblBiaoti, showTitle)

    local UITextTrans = CS.FindTrans(self.mTextTitle, "UIText")
    local textTitle = self:GetWndArg("textTitle") or ccClientText(11413)
    self:SetWndText(UITextTrans, textTitle)

    self:SetWndText(self.mTotalPriceText, ccClientText(11414))
    self:SetWndButtonText(self.mOkBtn, ccClientText(11415))
    self:SetWndButtonText(self.mCancelBtn, ccClientText(11416))
    self:SetWndText(self.mCloseTip, ccClientText(10505))

    local priceTxt = self:GetWndArg("priceTxt") or ccClientText(11420)
    self:SetWndText(self.mPriceText, priceTxt)
end
function UIDianBuy:RefreshPriceListTotalBuyContent()
    local buyNum = self._buyNum
    local _priceList = self._price
    local price = _priceList[1]
    self:SetWndText(self.mNum, buyNum)

    local totalPrice = 0
    for i = 1, buyNum do
        local buyCount = i + self.buyCount
        local priceItem = _priceList[buyCount] or _priceList[#_priceList]
        totalPrice = totalPrice + priceItem.itemNum
    end

    local ownNum = gModelItem:GetNumByRefId(price.itemId)
    local color = "green"
    if ownNum < totalPrice then
        color = "red"
    end
    local priceNumStr = nil
    if price.itemId == 101001 then
        priceNumStr = LUtil.NumberCoversion(totalPrice)
    else
        priceNumStr = LUtil.AddNumberSeparate(totalPrice)
    end
    self:SetWndText(self.mPriceNum, LUtil.FormatColorStr(priceNumStr, color))

    local progress = 0
    if self._limitNum > 0 then
        progress = buyNum / self._limitNum
    end

    self._buyNumSlider:SetSliderDelegate(nil)
    self._buyNumSlider:SetUIProgress(progress)
    self._buyNumSlider:SetSliderDelegate(function(value)
        self:OnValueChange(value)
    end)
end

function UIDianBuy:OnClickOk()
    local func = function()
        local _wndType = self._wndType
        if _wndType == UIDianBuy.TREASURE_TICKET then
            self:OnClickOkTreasure()
        elseif _wndType == UIDianBuy.GROUP_BUY then
            local _callFunc = self._callFunc
            if _callFunc then
                _callFunc(self._buyNum)
            end
        elseif _wndType == UIDianBuy.ACTIVITY_SELL then
            local _callFunc = self._callFunc
            if _callFunc then
                _callFunc(self._buyNum)
            end
        elseif _wndType == UIDianBuy.CrusadeAgainst then
            local _callFunc = self._callFunc
            if _callFunc then
                _callFunc(self._buyNum)
            end
        else
            if self._shopType == ModelShop.ACTIVITY then
                local sid = self._goodsData.sid
                local pageId = self._goodsData.pageId
                local entryId = self._goodsData.entryId
                local count = self._buyNum
                if count > 0 then
                    local consumeDetail
                    if (self._goodsData.price and self._goodsData.price.itemPrices) then
                        consumeDetail = gModelActivity:GetConsumeDetail(self._goodsData.price.itemPrices, count)
                    end
                    gModelActivity:OnActivityMarkeyBuyReq(sid, pageId, entryId, count, nil, consumeDetail)
                end
            else
                local goodsId = self._goodsData:GetId()
                local num = self._buyNum
                if num > 0 then
                    gModelShop:ShopBuyReq(self._shopId, goodsId, num, self._isQuick)
                end
            end
        end
        self:WndClose()
    end
    if gLGameLanguage:IsJapanRegion() and self._priceItemId and self._priceItemId == ModelItem.ITEM_DIAMOND then
        local isNeed = gModelGeneral:IsNeedShowCheckMasonryNumTips(self._priceItemId, self._totalPrice)
        if isNeed then
            gModelGeneral:ShowCheckMasonryNumTips(self._totalPrice, func)
            return
        end
    end

    func()
end

function UIDianBuy:OnClickSub()
    if self._buyNum <= 1 then
        return
    end
    self._buyNum = self._buyNum - 1

    self:SetTotalBuyContent()
end

function UIDianBuy:RefreshActivityTotalBuyContent()
    self:SetWndText(self.mNum, self._buyNum)
    local showItemInfo = self._showItemInfo
    local price = self._price
    local totalPrice = self._buyNum * price.itemNum

    local showItemId = showItemInfo.itemId
    local ownNum = gModelItem:GetNumByRefId(showItemId)
    local color = "green"
    if ownNum < totalPrice then
        color = "red"
    end

    local priceNumStr = nil
    if showItemId == 101001 then
        priceNumStr = LUtil.NumberCoversion(totalPrice)
    else
        priceNumStr = LUtil.AddNumberSeparate(totalPrice)
    end
    self:SetWndText(self.mPriceNum, LUtil.FormatColorStr(priceNumStr, color))
    self._totalPrice = totalPrice
    self._priceItemId = showItemId
    self:UpdateSlider()
end

function UIDianBuy:ShowActGoods()

    local goodsData = self._goodsData

    local price = goodsData.price
    --local goods = goodsData.item
    --local itemId = goods.itemId
    --local itemNum = goods.itemNum
    --local itemType = goods.itemType
    --local itemdata =
    --{
    --	itemId = itemId,
    --	itemNum = itemNum,
    --	itemType = itemType,
    --}

    self:ShowRewardAndPrice(goodsData.item, price)

    if goodsData.item.itemType == LItemTypeConst.TYPE_ITEM then

        local rewardItemId = goodsData.item.itemId
        if not self:GetDropInfo(rewardItemId) then
            self:RefreshItemDesc(rewardItemId)
        end

        --local ref = gModelItem:GetRefByRefId(goodsData.item.itemId)
        --self:SetWndText(self.mDesText,ccLngText(ref.description))
    end
    local limitType = goodsData.resetType
    local personalGoal = goodsData.personalGoal
    local isLimit = false
    if personalGoal ~= -1 then
        isLimit = true
    end
    local limitNum = nil
    if isLimit then

        local txtId = nil
        if limitType == 1 then
            txtId = self._limitTypeText[1]
        elseif limitType == 2 then
            txtId = self._limitTypeText[2]
        elseif limitType == 3 then
            txtId = self._limitTypeText[3]
        elseif limitType == 4 then
            txtId = self._limitTypeText[0]
        end

        local pre = ccClientText(txtId)
        local hasBuyNum = goodsData.personal
        limitNum = personalGoal - hasBuyNum
        local color
        if hasBuyNum >= personalGoal then
            color = "red"
        else
            color = "green"
        end
        local str = hasBuyNum .. "/" .. personalGoal
        local colorStr = pre .. LUtil.FormatColorStr(str, color)
        self:SetWndText(self.mLimit, colorStr)
    end
    local canBuy = self:CalcCanBuyNum(price)
    if limitNum then
        if canBuy > 0 then
            self._limitNum = math.min(canBuy, limitNum)
            LogWarn("canBuy > 0")
        else
            self._limitNum = limitNum
            LogWarn("canBuy <= 0")
        end
    else
        self._limitNum = canBuy
    end

    CS.ShowObject(self.mLimit, isLimit)

    self._buyNum = 0
    if self._limitNum > 0 then
        self._buyNum = 1
    end

    self._buyNumSlider = self:UIProgressFind(self.mNumSlider, self._numSliderKey, 0)

    self._buyNumSlider:SetSliderDelegate(function(value)
        self:OnValueChange(value)
    end)
    self:SetTotalBuyContent()
end

function UIDianBuy:InitEvent()
    self:WndNetMsgRecv(LProtoIds.ItemDropReplaceInfoResp, function(pb)
        local dropInfo = pb.dropInfo
        local refId = dropInfo.refId
        if self._waitItemId ~= refId then
            return
        end

        self:RefreshItemDesc(refId, dropInfo)
    end)
end

function UIDianBuy:RefreshUI()
    local goodsId = self._goodsData:GetId()
    if not goodsId then
        return
    end
    local goods = gModelShop:GetShopItemCfg(goodsId)
    self:ShowRewardAndPrice(goods.reward, goods.price)
    if goods.reward.itemType == LItemTypeConst.TYPE_ITEM then
        local rewardItemId = goods.reward.itemId
        if not self:GetDropInfo(rewardItemId) then
            self:RefreshItemDesc(rewardItemId)
        end

    elseif goods.reward.itemType == LItemTypeConst.TYPE_EQUIP then
        --如果是装备类型则去装备表找描述
        local rewardItemId = goods.reward.itemId

        local equipRef  =gModelEquip:GetEquipRefByRefId(rewardItemId)
        self:SetWndText(self.mDesText, equipRef.des)

    end

    local price = goods.price
    local limitCfg = goods.limitCount
    local isLimit = false
    if limitCfg.itemNum ~= -1 then
        isLimit = true
    end
    local limitNum = nil
    if isLimit then
        local pre = ccClientText(self._limitTypeText[limitCfg.itemId])
        local hasBuyNum = self._goodsData:GetHasBuyNum()
        limitNum = limitCfg.itemNum - hasBuyNum
        local color
        if hasBuyNum >= limitCfg.itemNum then
            color = "red"
        else
            color = "green"
        end
        local str = hasBuyNum .. "/" .. limitCfg.itemNum
        local colorStr = pre .. LUtil.FormatColorStr(str, color)
        self:SetWndText(self.mLimit, colorStr)
    end

    local canBuy = self:CalcCanBuyNum(price)
    if self.staticShop then
        local haveMaxNumLimit = self.canBuyMoreMax > 0
        if haveMaxNumLimit and canBuy >= self.canBuyMoreMax then
            canBuy = self.canBuyMoreMax
        end
    end
    if limitNum then
        self._limitNum = math.min(canBuy, limitNum)
    else
        self._limitNum = canBuy
    end

    CS.ShowObject(self.mLimit, isLimit)

    self._buyNum = 0
    if self._limitNum > 0 then
        self._buyNum = 1
    end

    self._buyNumSlider = self:UIProgressFind(self.mNumSlider, self._numSliderKey, 0)

    self._buyNumSlider:SetSliderDelegate(function(value)
        self:OnValueChange(value)
    end)
    self:SetTotalBuyContent()

end

function UIDianBuy:RefreshCommonTotalBuyContent()
    self:RefreshLimit()
    local price = self._price

    self:SetWndText(self.mNum, self._buyNum)

    if self._bSupportMultiPrice then
        self:SetMultiTotalPriceNum(price, self._buyNum)
    else
        local totalPrice = self._buyNum * price.itemNum
        local ownNum = gModelItem:GetNumByRefId(price.itemId)
        local color = "green"
        if ownNum < totalPrice then
            color = "red"
        end

        local priceNumStr = nil
        if price.itemId == 101001 then
            priceNumStr = LUtil.NumberCoversion(totalPrice)
        else
            priceNumStr = LUtil.AddNumberSeparate(totalPrice)
        end

        self:SetWndText(self.mPriceNum, LUtil.FormatColorStr(priceNumStr, color))
        self._totalPrice = totalPrice
        self._priceItemId = price.itemId
    end

    local progress = 0
    if self._limitNum > 0 then
        progress = self._buyNum / self._limitNum
    end

    self._buyNumSlider:SetSliderDelegate(nil)
    self._buyNumSlider:SetUIProgress(progress)
    self._buyNumSlider:SetSliderDelegate(function(value)
        self:OnValueChange(value)
    end)
end

function UIDianBuy:SetTotalBuyContent()
    local _wndType = self._wndType
    if _wndType == UIDianBuy.ACTIVITY_SELL then
        self:RefreshActivityTotalBuyContent()
    elseif _wndType == UIDianBuy.CrusadeAgainst then
        self:RefreshPriceListTotalBuyContent()
    else
        self:RefreshCommonTotalBuyContent()
    end
end
function UIDianBuy:ShowCrusadeAgainst()
    local goodsData = self._goodsData
    local price = goodsData.price
    self._price = price
    if goodsData.item.itemType == LItemTypeConst.TYPE_ITEM then
        local rewardItemId = goodsData.item.itemId
        if not self:GetDropInfo(rewardItemId) then
            self:RefreshItemDesc(rewardItemId)
        end
    end
    self:MakeIconCls(goodsData.item)
    local nameStr = gModelGeneral:GetCommonItemColorNameNoNum(goodsData.item)

    self:SetWndText(self.mName, nameStr)

    CS.ShowObject(self.mPriceLayout, false)

    local pre = ccClientText(11400)
    local buyCount = goodsData.buyCount
    self.buyCount = buyCount
    local buyLimit = goodsData.buyLimit
    local limitNum = buyLimit - buyCount
    self._limitNum = limitNum
    local color
    if limitNum <= 0 then
        color = "red"
    else
        color = "green"
    end
    local str = buyCount .. "/" .. buyLimit
    local colorStr = pre .. LUtil.FormatColorStr(str, color)
    self:SetWndText(self.mLimit, colorStr)
    CS.ShowObject(self.mLimit, true)

    self._buyNum = 0
    if self._limitNum > 0 then
        self._buyNum = 1
    end
    self._buyNumSlider = self:UIProgressFind(self.mNumSlider, self._numSliderKey, 0)

    self._buyNumSlider:SetSliderDelegate(function(value)
        self:OnValueChange(value)
    end)
    self:SetTotalBuyContent()
end

function UIDianBuy:InitSlider()
    self._sliderComponent = self.mNumSlider:GetComponent(typeUISlider)
    if (not self._sliderComponent) then
        self._sliderComponent = self.mNumSlider:AddComponent(typeUISlider)
    end

    LxUiHelper.SetProgress_ValueChanged(self.mNumSlider, function()
        local value = self._sliderComponent.value
        local num = math.floor(value)
        self._buyNum = num
        self:RefreshActivityTotalBuyContent()
    end)
    self._sliderComponent.minValue = self._buyNum
    self._sliderComponent.maxValue = self._limitNum
end

function UIDianBuy:OpenKeyboard()
    local min, max, default = 0, 0, 0
    if self._limitNum > 0 then
        min = 1
        max = self._limitNum
        default = 1
    end
    local func = function(input, cmd)

        if self:IsWndClosed() then
            return
        end

        self._buyNum = tonumber(input)
        self:SetTotalBuyContent()
    end
    local layer = self:GetWndSortLayer()
    gLGameUI:OpenWndWithLayer(layer, "UINuoardUI", { minNum = min, maxNum = max, defaultNum = default, inputFunc = func, inputTran = self.mNum })

    --GF.OpenWndUp("UINuoardUI",{minNum = min,maxNum = max,defaultNum = default,inputFunc = func,inputTran = self.mNum})
end

function UIDianBuy:InitUIEvent()
    self:SetWndClick(self.mAddBtn, function()
        self:OnClickAdd()
    end)
    self:SetWndClick(self.mSubBtn, function()
        self:OnClickSub()
    end)
    self:SetWndClick(self.mOkBtn, function()
        self:OnClickOk()
    end)
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mCancelBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mNum, function()
        self:OpenKeyboard()
    end)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)

end

--组合消耗显示
function UIDianBuy:SetMultiRewardAndPrice(priceData)
    local itemPriceList = priceData.itemPrices

    local priceItemTransList = self._priceItemTransList
    local totalPriceItemTransList = self._totalPriceItemTransList
    local priceItem
    local totalPriceItem
    local moneyIconTrans
    local priceIconTrans
    local priceTextTrans
    for i, itemPrice in ipairs(itemPriceList) do
        moneyIconTrans = nil
        priceIconTrans = nil
        priceTextTrans = nil

        --单价图标显示
        priceItem = priceItemTransList[i]
        if priceItem then
            moneyIconTrans = self:FindWndTrans(priceItem, "moneyIcon")
            priceTextTrans = self:FindWndTrans(priceItem, "price")
            CS.ShowObject(priceItem.gameObject, true)
        end

        --总价图标显示
        totalPriceItem = totalPriceItemTransList[i]
        if totalPriceItem then
            priceIconTrans = self:FindWndTrans(totalPriceItem, "priceIcon")
            CS.ShowObject(totalPriceItem.gameObject, true)
        end

        --单价数量显示
        if priceTextTrans then
            local priceNumStr = nil
            if itemPrice.itemId == 101001 then
                priceNumStr = LUtil.NumberCoversion(itemPrice.itemNum)
            else
                priceNumStr = LUtil.AddNumberSeparate(itemPrice.itemNum)
            end
            self:SetWndText(priceTextTrans, priceNumStr)
        end

        local heroIconRoot = self:FindWndTrans(priceItem, "HeroIconRoot")
        local tolHeroIconRoot = self:FindWndTrans(totalPriceItem, "HeroIconRoot")
        if (itemPrice.itemType == LItemTypeConst.TYPE_HERO) then
            self:SetHeroItem(heroIconRoot, itemPrice.itemId)
            self:SetHeroItem(tolHeroIconRoot, itemPrice.itemId)
        else
            local priceIcon = gModelItem:GetItemImgByRefId(itemPrice.itemId)
            if priceIcon then
                if moneyIconTrans then
                    self:SetWndEasyImage(moneyIconTrans, priceIcon)
                end
                if priceIconTrans then
                    self:SetWndEasyImage(priceIconTrans, priceIcon)
                end
            end
        end
        CS.ShowObject(heroIconRoot, itemPrice.itemType == LItemTypeConst.TYPE_HERO)
        CS.ShowObject(tolHeroIconRoot, itemPrice.itemType == LItemTypeConst.TYPE_HERO)
        if (moneyIconTrans) then
            CS.ShowObject(moneyIconTrans, itemPrice.itemType ~= LItemTypeConst.TYPE_HERO)
        end
        if (priceIconTrans) then
            CS.ShowObject(priceIconTrans, itemPrice.itemType ~= LItemTypeConst.TYPE_HERO)
        end
    end
end

function UIDianBuy:InitData()
    self._limitTypeText = gModelShop:GetLimitStrList()
    self._numSliderKey = "_numSliderKey"
    self._commonIconTbl = {}
    self.staticShop = false
    if self._goodsData._goodsId ~= nil then
        self.staticShop = true
    end
    if self.staticShop then
        self.canBuyMoreMax = tonumber(gModelShop:GetCanBuyMoreMaxByRefId(self._goodsData._goodsId))
    end
end

function UIDianBuy:UpdateSlider()
    self._sliderComponent.value = self._buyNum
end

function UIDianBuy:InitNumSlider()

    self._buyNumSlider = self:UIProgressFind(self.mNumSlider, self._numSliderKey, 0)

    self._buyNumSlider:SetSliderDelegate(function(value)
        self:OnValueChange(value)
    end)
    self:SetTotalBuyContent()

end

function UIDianBuy:OnValueChange(value)
    local num = math.floor(value * self._limitNum)
    if self._limitNum > 0 then
        num = num < 1 and 1 or num
    end
    self._buyNum = num
    self:SetTotalBuyContent()
end

function UIDianBuy:OnClickAdd()

    if self._buyNum >= self._limitNum then
        return
    end
    self._buyNum = self._buyNum + 1

    self:SetTotalBuyContent()
end

function UIDianBuy:RefreshItemDesc(refId, dropInfo)

    local ref = gModelItem:GetRefByRefId(refId)
    if not ref then
        return
    end
    local desc = ccLngText(ref.description)
    if dropInfo then
        local group = dropInfo.group
        local typeDate = string.split(ref.typeDate, "|")
        local refGroup = tonumber(typeDate[1])
        if group == refGroup then
            desc = string.replace(desc, dropInfo.num)
        end

    end

    self:SetWndText(self.mDesText, desc)
end

function UIDianBuy:GetDropInfo(itemId)
    self._waitItemId = nil
    local ref = gModelItem:GetRefByRefId(itemId)
    local type = ref.type
    if type == ModelItem.Item_DROPITEMTYPE then
        gModelItem:OnItemDropReplaceInfoReq(itemId)
        self._waitItemId = itemId
        return true
    end
end

--多消耗总价
function UIDianBuy:SetMultiTotalPriceNum(priceData, buyNum)
    local itemPriceList = priceData.itemPrices
    local totalPriceItemTransList = self._totalPriceItemTransList
    local totalPriceItem
    local priceTextTrans
    for i, itemPrice in ipairs(itemPriceList) do
        --总价显示
        totalPriceItem = totalPriceItemTransList[i]
        if totalPriceItem then
            local totalPrice = buyNum * itemPrice.itemNum
            local ownNum = gModelItem:GetNumByRefId(itemPrice.itemId, nil, itemPrice.itemType)
            local color = "green"
            if ownNum < totalPrice then
                color = "red"
            end
            local priceNumStr = nil
            if itemPrice.itemId == 101001 then
                priceNumStr = LUtil.NumberCoversion(totalPrice)
            else
                priceNumStr = LUtil.AddNumberSeparate(totalPrice)
            end
            priceTextTrans = self:FindWndTrans(totalPriceItem, "priceNum")
            self:SetWndText(priceTextTrans, LUtil.FormatColorStr(priceNumStr, color))
        end
    end
end

function UIDianBuy:SetPara()
    self._goodsData = self:GetWndArg("goodsData")
    self._shopId = self:GetWndArg("shopId")
    self._shopType = self:GetWndArg("shopType")
    self._limitNum = self:GetWndArg("limit")
    self._isQuick = self:GetWndArg("quick")
    self._bSupportMultiPrice = self:GetWndArg("bSupportMultiPrice")
    self._callFunc = self:GetWndArg("callFunc")
    self._wndType = self:GetWndArg("wndType") or UIDianBuy.NORMAL
end

function UIDianBuy:InitItem()
    local priceLayout = self.mPriceLayout
    local priceItem
    local priceItemTransList = {}
    for i = 0, 3 do
        priceItem = self:FindWndTrans(priceLayout, "priceItem" .. i)
        table.insert(priceItemTransList, priceItem)
    end
    priceItem = priceItemTransList[1]
    self.mMoneyIcon = self:FindWndTrans(priceItem, "moneyIcon")
    self.mPrice = self:FindWndTrans(priceItem, "price")
    self._priceItemTransList = priceItemTransList

    local totalPriceLayout = self.mTotalPriceLayout
    local totalPriceItem
    local totalPriceItemTransList = {}
    for i = 0, 3 do
        totalPriceItem = self:FindWndTrans(totalPriceLayout, "totalPriceItem" .. i)
        table.insert(totalPriceItemTransList, totalPriceItem)
    end
    totalPriceItem = totalPriceItemTransList[1]
    self.mPriceIcon = self:FindWndTrans(totalPriceItem, "priceIcon")
    self.mPriceNum = self:FindWndTrans(totalPriceItem, "priceNum")

    self._totalPriceItemTransList = totalPriceItemTransList
end

function UIDianBuy:ShowTreasureBuy()
    local data = self._goodsData
    local itemdata = data.rewards
    local price = data.price
    local limit = data.limit
    local leftTimes = data.leftTimes    --剩余次数
    self._treasureType = data.type
    self:ShowRewardAndPrice(itemdata, price)
    self._buyNum = 1
    local str = ccClientText(19433) --"日剩余:%s"
    str = string.replace(str, LUtil.FormatColorStr(leftTimes, "green"))
    self:SetWndText(self.mLimit, str)
    self._limitNum = limit
    self._buyNumSlider = self:UIProgressFind(self.mNumSlider, self._numSliderKey, 0)
    self._buyNumSlider:SetSliderDelegate(function(value)
        self:OnValueChange(value)
    end)
    self:SetTotalBuyContent()


end

function UIDianBuy:RefreshLimit()
    local _wndType = self._wndType
    if _wndType ~= UIDianBuy.GROUP_BUY then
        return
    end
    local _goodsData = self._goodsData
    local limit = _goodsData.limit
    local _buyNum = self._buyNum or 1
    local color
    if _buyNum >= limit then
        color = "red"
    else
        color = "green"
    end
    local str = _buyNum .. "/" .. limit
    local colorStr = ccClientText(11400) .. LUtil.FormatColorStr(str, color)
    self:SetWndText(self.mLimit, colorStr)
end
function UIDianBuy:ShowGroupBuy()
    local _goodsData = self._goodsData
    local reward = _goodsData.reward
    local price = _goodsData.price
    local limit = _goodsData.limit

    self._price = price
    local canBuy = self:CalcCanBuyNum(price)
    if limit then
        self._limitNum = math.min(canBuy, limit)
    else
        self._limitNum = canBuy
    end

    self:ShowRewardAndPrice(reward, price)
    if reward.itemType == LItemTypeConst.TYPE_ITEM then
        local rewardItemId = reward.itemId
        if not self:GetDropInfo(rewardItemId) then
            self:RefreshItemDesc(rewardItemId)
        end
    end

    self:InitNumSlider()
end

function UIDianBuy:ShowActivitySell()
    local showItemInfo = self:GetWndArg("showItemInfo")
    self._showItemInfo = showItemInfo

    local price = self:GetWndArg("price")
    self._price = price or showItemInfo

    self:ShowRewardAndPrice(showItemInfo, price)

    --- 限购描述
    local limitStr = self:GetWndArg("limitStr")
    --- 已经选择的数量
    local selBuyNum = self:GetWndArg("selBuyNum") or 1
    --- 拥有总数量
    local allBuyNum = self:GetWndArg("allBuyNum") or 1
    local color
    if selBuyNum > allBuyNum then
        color = "red"
    else
        color = "green"
    end
    local str = selBuyNum .. "/" .. allBuyNum
    local colorStr = string.replace(limitStr, LUtil.FormatColorStr(str, color))
    self:SetWndText(self.mLimit, colorStr)

    self:InitSlider()

    local showItemId = showItemInfo.itemId
    if not self:GetDropInfo(showItemId) then
        self:RefreshItemDesc(showItemId)
    end
    self:RefreshActivityTotalBuyContent()
end

function UIDianBuy:OnValueActivitySellChange()

end

function UIDianBuy:CalcCanBuyNum(priceData)
    if self._bSupportMultiPrice then
        local itemPriceList = priceData.itemPrices
        local canBuy = nil
        for k, itemPrice in ipairs(itemPriceList) do
            local ownNum
            if (itemPrice.itemType == LItemTypeConst.TYPE_HERO) then
                local beCapableOfHeroList = gModelHeroExtra:GetBeCapableOfSellHeroIdList(itemPrice.itemId)
                ownNum = #beCapableOfHeroList
            else
                ownNum = gModelItem:GetNumByRefId(itemPrice.itemId)
            end
            if itemPrice.itemNum == 0 then return 0 end
            local tmpCanBuy = math.floor(ownNum / itemPrice.itemNum)
            if not canBuy then
                canBuy = tmpCanBuy
            else
                canBuy = math.min(canBuy, tmpCanBuy)
            end
        end
        return canBuy
    else
        if priceData.itemNum == 0 then return 0 end
        local ownNum = gModelItem:GetNumByRefId(priceData.itemId)
        local canBuy = math.floor(ownNum / priceData.itemNum)
        return canBuy
    end
end

function UIDianBuy:OnClickOkTreasure()
    local num = self._buyNum
    if num > 0 then
        --todo
        gModelTreaFind:OnFindTreasureBuyReq(self._treasureType, num)
    end
end

function UIDianBuy:ShowRewardAndPrice(itemdata, price)
    self:MakeIconCls(itemdata)

    local nameStr = gModelGeneral:GetCommonItemColorNameNoNum(itemdata)

    self:SetWndText(self.mName, nameStr)

    self._price = price

    if self._bSupportMultiPrice then
        self:SetMultiRewardAndPrice(price)
        return
    end
    local priceIcon = gModelItem:GetItemImgByRefId(price.itemId)
    if priceIcon then
        self:SetWndEasyImage(self.mMoneyIcon, priceIcon)
        self:SetWndEasyImage(self.mPriceIcon, priceIcon)
    end

    local priceNumStr = nil
    if price.itemId == 101001 then
        priceNumStr = LUtil.NumberCoversion(price.itemNum)
    else
        priceNumStr = LUtil.AddNumberSeparate(price.itemNum)
    end
    self:SetWndText(self.mPrice, priceNumStr)
end
function UIDianBuy:SetHeroItem(root, refId)
    local herodata = {}
    local heroRef = gModelHero:GetHeroRef(refId)    --道具图标
    herodata.refId = heroRef.refId
    herodata.star = heroRef.initStar
    local instanceId = root:GetInstanceID()
    local heroIconCls = self._commonIconTbl[instanceId]
    if not heroIconCls then
        heroIconCls = CommonIcon:New()
        self._commonIconTbl[instanceId] = heroIconCls
        heroIconCls:Create(root)
    end
    heroIconCls:SetHeroDataSet(herodata)
    heroIconCls:SetNoShowLv(true)
    heroIconCls:DoApply()
end

function UIDianBuy:MakeIconCls(itemdata)
    local iconTrans = CS.FindTrans(self.mItemInfo, "CommonUI/Icon")
    local uicommon = self._iconCls
    if not uicommon then
        uicommon = CommonIcon:New()
        self._iconCls = uicommon
        uicommon:Create(iconTrans)
    end
    uicommon:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    uicommon:EnableShowNum(true)
    uicommon:DoApply()

    self:SetIconClickScale(iconTrans, true)
    self:SetWndClick(iconTrans, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
end
------------------------------------------------------------------
return UIDianBuy


