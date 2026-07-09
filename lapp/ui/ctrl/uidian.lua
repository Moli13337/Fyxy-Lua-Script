---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDian:LWnd
local UIDian = LxWndClass("UIDian", LWnd)
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)

UIDian.NORMAL = 1
UIDian.SIMULATE = 2



local adMethodId_201 = ModelAds.TYPE_ADS_201
local adMethodId_202 = ModelAds.TYPE_ADS_202
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDian:UIDian()
    ---@type table<number, CommonIcon>
    self._commonIconTbl = {}
    self:SetHideHurdle()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDian:OnWndClose()
    self:ClearCommonIconList(self._commonIconTbl)
    self._commonIconTbl = nil

    gModelShop:SetCurShopId(nil)
    gModelActivity:RecordActivityShop(nil)

    local func = self:GetWndArg("jumpCallback")
    if func then
        func()
    end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDian:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDian:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:SetTextTile(self.mDetailsBtn,ccClientText(21813))			-- 详情
    self:InitData()
    self:SetStaticContent()
    self:WndEventRecv(EventNames.ON_SHOP_DATA_RETURN, function(...)
        self:OnShopListResp(...)
    end)
    self:WndEventRecv(EventNames.ON_SHOP_BUY_RETURN, function(...)
        self:OnShopBuyResp(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:OnActivityPageResp(...)
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:OnItemChange()
        self:SetRefreshContent()
    end)
    self:WndNetMsgRecv(LProtoIds.ShopRefreshResp, function()
        self:ShowShopDesc()
    end)
    self:WndNetMsgRecv(LProtoIds.ShopAutoBuySetResp, function(...)
        self:OnShopAutoBuySetResp(...)
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if self._curShopType ~= ModelShop.ACTIVITY then
            return
        end

        if self._curShopId ~= sid then
            return
        end
        self:SetShopContent()
    end)

    self:InitUIEvent()

    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function()
        self:WndClose()
    end)
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self._func = nil
    end)

    self._func = self:GetWndArg("func")
    self:RefreshUI()
    self:OnWndRefreshDetailsBtn()

    self:RegisterShopRed()

    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:RefreshShopOnZero()
    end)

    self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE, function()
        if self._curShopType ~= ModelShop.ACTIVITY then
            self:InitBottomBtnList()
        end
    end)

    self:WndEventRecv(EventNames.REFRESH_SKIN_INFO, function()
        local itemList = self:FindUIScroll(self._goodsListKey)
        if itemList then
            itemList:DrawAllItems(false)
        end
    end)
    self:WndEventRecv(EventNames.REFRESH_ADS, function()
        self:RefreshShop()
    end)

    self:SendTaInfo()

    -- local priviCom = self:GetPrivilegeCom()
    -- priviCom:Create(self.mBtnPrivile, 11, self)

    if self._isEnus then
        self:InitTextSizeWithLanguage(self.mMoneyNum, -4)
    end
end

function UIDian:OnWndRefresh()
    self._func = self:GetWndArg("func")
    self:RefreshUI()
end

function UIDian:OnSelectShop(shopId)
    local isOpened = gModelShop:CheckIsShopOpen(shopId, true)

    if not isOpened then
        return
    end

    gModelRedPoint:SetMultiIdRedClicked(ModelRedPoint.SHOP, shopId)

    if self._curShopId == shopId then
        return
    end
    local item = self._uiShopTypeList[shopId]
    if item then
        self:SetTypeBtnSelected(item, shopId)
    end
    item = self._uiShopTypeList[self._curShopId]
    if item then
        self:SetTypeBtnDeseleted(item, self._curShopId)
    end
    self._curShopId = shopId

    self._curFilterType = 0

    self:SetTextContent()
    self:InitCurrencyList()
    self:InitScreenPageList()
    self:ShowJumpBtn()
    self:OnShopListReq()

    local argList = self:GetWndArgList() or {}
    argList["page"] = self._curShopType
    argList["subPage"] = self._curShopId
    self:SetWndArg(argList)
end

function UIDian:OnSelectActShop(shopData)
    local shopId = shopData.shopId
    if self._curShopId == shopId then
        return
    end
    local item = self._uiShopTypeList[shopId]
    if item then
        self:SetTypeBtnSelected(item, shopId, true)
    end
    item = self._uiShopTypeList[self._curShopId]
    if item then
        self:SetTypeBtnDeseleted(item, self._curShopId, true)
    end
    --self:OnDeSelectShop(self._curShopId)
    self._curShopId = shopId
    --self._curShopShowId = shopData.shopShowId
    self._curShopShowId = shopData.pageId

    --self:ShowActivityShopTitle()
    --self:InitActivityCurrencyList()
    --self:HideFilter()
    --self:ShowJumpBtn()
    --self:OnActivityPageReq()

    self._curFilterType = 0
    gModelActivity:ReqActivityConfigData(shopId)
end

function UIDian:CheckOwnEnough(itemId, itemNum)
    return gModelGeneral:CheckItemEnough(itemId, itemNum, true, self:GetWndName())
end

function UIDian:ShowAd()
    local curShopId = self._curShopId
    local config = gModelAds:GetAdConfigByParam({
        adMethodId = adMethodId_202,
        refId = curShopId,
    })
    if config then
        gModelAds:OpenAdByCommonTips(490003,{
            adMethodId = adMethodId_202,
            refId = curShopId,
            shopId = curShopId,
            openADFunc = function()
                gModelAds:OpenAd({
                    refId = config.refId,
                })
            end,
            jumpCB = function()
                self:WndClose()
            end,
        })
        return true
    end
    return false
end

function UIDian:SetStoreTypeBtn()
    local shopType = self._curShopType
    local stateList = { 0, 0, 0 }
    if shopType == 1 then
        stateList = { 0, 1, 1 }
    elseif shopType == 2 then
        stateList = { 1, 0, 1 }
    elseif shopType == 3 then
        stateList = { 1, 1, 0 }
    end

    local tabBtn = self:FindWndTrans(self.mShopBtn, "BtnTab3")
    self:SetWndTabStatus(tabBtn, stateList[1])
    tabBtn = self:FindWndTrans(self.mScoreBtn, "BtnTab3")
    self:SetWndTabStatus(tabBtn, stateList[2])
    tabBtn = self:FindWndTrans(self.mActivityBtn, "BtnTab3")
    self:SetWndTabStatus(tabBtn, stateList[3])
end

function UIDian:SendTaInfo()
    local shopId = self._curShopId
    local isAct = self._curShopType == ModelShop.ACTIVITY
    if isAct then
        local activityData = gModelActivity:GetActivityBySid(shopId)
        gLxTKData:OnActivityShopClick(activityData)
    else
        local ref = gModelShop:GetShopRef(shopId)
        gLxTKData:OnBaseShopClick(ref)
    end
    self:OnWndRefreshDetailsBtn()
end

function UIDian:GetShowShopId(shopStoreType, index)
    local shopList = gModelShop:GetShopShow(shopStoreType) --直接选中第一个

    local shopData = shopList[index]
    if not shopData then
        printErrorN("no shop data index " .. index)
        shopData = shopList[1]
    end
    local shopId = shopData.refId
    return shopId
end

function UIDian:BuyActGoods(itemdata)
    if not string.isempty(itemdata.unlock) then
        local isUnlock, tip = gModelShop:CheckIsUnlock(itemdata.unlock, itemdata.unlockTxt)
        if not isUnlock then
            GF.ShowMessage(tip)
            return
        end
    end
    local isLimit = false
    local limitNum = itemdata.personalGoal
    local canBuyNum = -1
    if limitNum ~= -1 then
        isLimit = true
    end
    if isLimit then
        local hasBuyNum = itemdata.personal
        canBuyNum = limitNum - hasBuyNum
        if hasBuyNum >= limitNum then
            local str = ccClientText(11406)--"已售罄,不可兑换")
            GF.ShowMessage(str)
            return
        end
    end

    if limitNum == 1 then
        local isSkinItem, stateCode, skinRefId = gModelHero:GetSkinStateByItemId(itemdata.item)
        if isSkinItem then
            if stateCode == 3 or stateCode == 2 then
                gModelHero:ActiveOrWearSkin(skinRefId)
                return
            elseif stateCode == 4 then
                return
            end
        end
    end

    local priceItemId = itemdata.price.itemId
    local priceItemNum = itemdata.price.itemNum

    if not self:CheckOwnEnough(priceItemId, priceItemNum) then
        return
    end

    GF.OpenWnd("UIDianBuy", { goodsData = itemdata, shopType = ModelShop.ACTIVITY })

end

function UIDian:OnClickShop()
    gLxTKData:OnUIBtnClick("UIDian", 1)
    self:ChangeStoreType(ModelShop.NORMAL)

end

function UIDian:RefreshShopOnZero()
    if self._curShopType == ModelShop.ACTIVITY then
        self:OnActivityPageReq()
    else
        self:OnShopListReq()
    end
end

function UIDian:InitBottomBtnList()

    self._uiShopTypeList = {}

    local shopList = gModelShop:GetShopShow(self._curShopType)

    local key = "shopTypeList"
    local itemList = self:GetUIScroll(key)

    local ref = gModelFish:GetConfigRef()
    local fishShopId = ref.fishingShop
    local isFish = self:GetWndArg("isFish") -- 鱼商店，只能在鱼那里打开
    local index = 1
    local idList = {}
    for k, v in ipairs(shopList) do
        local shopId = v.refId
        local isOpen = gModelShop:CheckIsShopOpen(shopId)--优化需求 #11262 隐藏商店未开启页签
        --if(isOpen or self._curShopType~= ModelShop.NORMAL)then
        if (isOpen) then
            if isFish then
                table.insert(idList, shopId)
            elseif shopId ~= fishShopId then
                table.insert(idList, shopId)
            end
            if self._curShopId == shopId then
                index = k
            end
        end
    end
    itemList:Create(self.mShopTypeList, idList, function(...)
        self:OnDrawShopTypeBtn(...)
    end)
    itemList:EnableScroll(true, true)
    local uiList = itemList:GetList()
    uiList:DelayScrollTo(index)

end

function UIDian:ShowJumpBtn()
    if self._curShopType == ModelShop.ACTIVITY then
        CS.ShowObject(self.mJumpBtn, false)
        return
    end
    local showBtn = false
    local shopCfg = gModelShop:GetShopRef(self._curShopId)
    if shopCfg then
        local jumpId = shopCfg.jumpId
        if jumpId > 0 and not self:IsIosForbid(jumpId) then
            showBtn = true
        end
        local jumpDesc = ccLngText(shopCfg.jumpDes)
        self:SetWndButtonText(self.mJumpBtn, jumpDesc)
    end

    CS.ShowObject(self.mJumpBtn, showBtn)
end

function UIDian:InitActivityCurrencyList()
    self._uiCurrencyItem = {}
    local activityCfg = gModelActivity:GetWebActivityDataById(self._curShopId)
    if not activityCfg then
        return
    end
    local data = activityCfg.config
    local itemId = tostring(data.itemId)
    local currencyCfg = {}
    local itemIdList = string.split(itemId, "|")
    for i, v in ipairs(itemIdList) do
        table.insert(currencyCfg, tonumber(v))
    end

    if #currencyCfg == 0 then
        CS.ShowObject(self.mMoneyList, false)
        CS.ShowObject(self.mShopDesc, false)
        self:ShowDi(1)
        return
    end

    self:SetMoneyList(currencyCfg)
end

function UIDian:OnClickJump()
    if self._curShopType == ModelShop.ACTIVITY then
        return
    end
    local shopCfg = gModelShop:GetShopRef(self._curShopId)
    if shopCfg then
        local jumpId = shopCfg.jumpId
        if jumpId > 0 then
            gModelFunctionOpen:Jump(jumpId, self:GetWndName())
        end

    end
end

function UIDian:CheckShowRefreshAdBtn()
    return gModelAds:CheckHasAdViewCount({
        adMethodId = adMethodId_202,
        refId = self._curShopId,
    })
end

function UIDian:OnShopListReq()
    gModelShop:SetCurShopId(self._curShopId)
    gModelShop:ShopListReq(self._curShopId)
end

function UIDian:ShowActCountdown()
    CS.ShowObject(self.mBottomBg, true)
    CS.ShowObject(self.mRefreshBtn, false)
    CS.ShowObject(self.mRefreshTimes, false)

    local shopData = gModelActivity:GetShopDataBySid(self._curShopId)
    if not shopData then
        return
    end
    local showEndTime = shopData.showEndTime
    local timeLeft = showEndTime - GetTimestamp()
    if showEndTime <= 0 then
        self:TimerStop(self._activityTimer)
        self:SetWndText(self.mTimerText, "")
    elseif timeLeft < 0 then
        self:TimerStop(self._activityTimer)
        local str = ccClientText(16802) --"兑换时间已结束"
        self:SetWndText(self.mTimerText, str)
    else
        local timeStr = LUtil.FormatTimeSpanShop(timeLeft)
        timeStr = LUtil.FormatColorStr(timeStr, "green")
        local str = ccClientText(16803) .. timeStr   --"兑换倒计时: "..timeStr
        self:SetWndText(self.mTimerText, str)
        return true
    end


end

function UIDian:OnSelectFilterType(filterType)
    if self._curFilterType == filterType then
        return
    end
    local item = self._filterUIItemList[filterType]
    if item then
        local select = self:FindWndTrans(item, "select")
        CS.ShowObject(select, true)
    end
    item = self._filterUIItemList[self._curFilterType]
    if item then
        local select = self:FindWndTrans(item, "select")
        CS.ShowObject(select, false)
    end
    self._curFilterType = filterType

    self:RefreshItemList()
end

function UIDian:OnDrawFilterBtn(list, item, itemdata, itempos)
    local icon = self:FindWndTrans(item, "icon")
    local select = self:FindWndTrans(item, "select")
    local isSelect = itemdata.filterType == self._curFilterType
    CS.ShowObject(select, isSelect)
    self:SetWndEasyImage(icon, itemdata.iconPath)
    self:SetWndClick(icon, function()
        self:OnSelectFilterType(itemdata.filterType)
    end)
    self._filterUIItemList[itemdata.filterType] = item

    icon.sizeDelta = Vector2(70, 70)
    if itempos > 1 then
        if self._curShopType == ModelShop.SCORE then
            icon.sizeDelta = Vector2(54, 54)
        end

    end
end

function UIDian:SetTypeBtnSelected(item, shopId, isAct)
    local tab = self:FindWndTrans(item, "bg/BtnTab1")
    self:SetWndTabStatus(tab, 0)

    --if isAct then
    --	local activityData = gModelActivity:GetActivityBySid(shopId)
    --	gLxTKData:OnActivityShopClick(activityData)
    --else
    --	local ref = gModelShop:GetShopRef(shopId)
    --	gLxTKData:OnBaseShopClick(ref)
    --end
end

function UIDian:ModifyContentSize()
    self:RefreshBackTime()
    local showBottom
    if self._curShopType == ModelShop.ACTIVITY then
        showBottom = self:IsShowTimeRefresh()
    else
        local hasRefresh = self:IsShowTimeRefresh()

        local showBackTime = self:IsShowBackShopTime()
        local hasFilter = false
        local sreenPages = gModelShop:GetShopScreenPageCfg(self._curShopId)
        if not table.isempty(sreenPages) then
            hasFilter = true
        end
        showBottom = hasFilter or hasRefresh or showBackTime
    end

    local size = Vector2.New(594, 695)
    if showBottom then
        size = Vector2.New(594, 626)
    end

    local minHeight = 25
    if showBottom then
        minHeight = 14
    end

    local layoutEle = self.mEmpty:GetComponent(typeLayoutElement)
    if layoutEle then
        layoutEle.minHeight = minHeight
        layoutEle.preferredHeight = minHeight
    end

    --[[    local size = Vector2.New(-46, -480)
        if showBottom then
            size = Vector2.New(-46, -480)
        end
        self.mDi.sizeDelta = size]]

end

function UIDian:OnShopBuyResp(pb)
    local shopId = pb.shopId
    if shopId ~= self._curShopId then
        return
    end

    self:RefreshItemList(true)

    --local itemList = self:FindUIScroll(self._goodsListKey)
    --if itemList then
    --	--local list = itemList:GetList()
    --	itemList:DrawAllItems(false)
    --end


end

function UIDian:ShowActivityShopTitle()
    local shopName = gModelActivity:GetLngNameByActivitySid(self._curShopId)
    local addLine = -30
    if gLGameLanguage:IsThaiVersion() then
        addLine = -50
    end

    local shopNameStr = string.gsub(shopName, "<br>", '')
    self:SetWndText(self.mTitle, shopNameStr)
    self:InitTextLineWithLanguage(self.mTitle, addLine)
end

function UIDian:GetTestCurTime()
    return GetTimestamp() + 109 * 60
end

function UIDian:OnClickAdd(itemId)

    if self._curShopType == ModelShop.ACTIVITY then
        local shopData = gModelActivity:GetShopDataBySid(self._curShopId)
        if not shopData then
            GF.ShowMessage(ccClientText(16802))
            return
        end
        -- local model = shopData or shopData.model
        -- if model == ModelActivity.ACTIVITY_EXCHANGEITEM then
        -- 	GF.ShowMessage(ccClientText(18370))
        -- 	return
        -- end
    end

    local wndName = self:GetWndName()
    gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = wndName })
end

function UIDian:SetShopContent()

    local showActShop = gModelActivity:CheckShowShop()
    CS.ShowObject(self.mActivityBtn, showActShop)

    self:SetStoreTypeBtn()
    if self._curShopType == ModelShop.ACTIVITY then
        gModelShop:SetCurShopId(nil)
        self:ShowActivityShopTitle()
        self:InitActivityCurrencyList()
        self:InitActBottomBtnList()
        self:HideFilter()
        self:OnActivityPageReq()


    else
        gModelActivity:RecordActivityShop(nil)
        self:SetTextContent()
        self:InitCurrencyList()
        self:InitBottomBtnList()
        self:InitScreenPageList()
        self:OnShopListReq()
    end

    self:ShowJumpBtn()
end

function UIDian:OnDrawActGoods(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    --local AniRootBg = self:FindWndTrans(AniRoot,"bg")
    local AniRootItemName = self:FindWndTrans(AniRoot, "itemName")
    local AniRootSoldout = self:FindWndTrans(AniRoot, "soldout")
    --local soldoutIcon = self:FindWndTrans(AniRootSoldout,"icon")
    local AniRootBuyBtn = self:FindWndTrans(AniRoot, "buyBtn")
    local buyBtnLayout = self:FindWndTrans(AniRootBuyBtn, "layout")
    local layoutIcon = self:FindWndTrans(buyBtnLayout, "icon")
    local layoutNum = self:FindWndTrans(buyBtnLayout, "num")
    local buyBtnRedPoint = self:FindWndTrans(AniRootBuyBtn, "redPoint")
    local AniRootWearTag = self:FindWndTrans(AniRoot, "wearTag")
    local AniRootDiscountImg = self:FindWndTrans(AniRoot, "DiscountImg")
    local DiscountImgText = self:FindWndTrans(AniRootDiscountImg, "text")
    local AniRootLimit = self:FindWndTrans(AniRoot, "limit")

    local goods = itemdata.item

    local iconTrans = CS.FindTrans(item, "AniRoot/CommonUI/Icon")

    self:CreateCommonIconImpl(iconTrans, goods, { checkActive = true })

    self:SetIconClickScale(iconTrans, true)
    self:SetWndClick(iconTrans, function()
        gModelGeneral:ShowCommonItemTipWnd(goods)
    end)

    local nameCfg = gModelGeneral:GetCommonItemName(goods)
    self:SetWndText(AniRootItemName, nameCfg)

    self:SetWndClick(AniRootBuyBtn, function()
        self:BuyActGoods(itemdata)
    end)
    self:SetWndClick(AniRoot, function()
        self:BuyActGoods(itemdata)
    end)

    local priceId = itemdata.price.itemId
    local priceNum = itemdata.price.itemNum
    local priceIcon, priceIconBg = gModelItem:GetItemImgByRefId(priceId)
    if priceIcon then
        self:SetWndEasyImage(layoutIcon, priceIcon)
    end
    local showIcon = priceIcon ~= nil
    --CS.ShowObject(layoutIcon,priceIcon ~= nil)
    local priceNumStr = nil
    if priceId == 101001 then
        priceNumStr = LUtil.NumberCoversion(priceNum)
    else
        priceNumStr = LUtil.AddNumberSeparate(priceNum)
    end

    self:SetWndText(layoutNum, priceNumStr)

    local isFree = false
    if priceNum <= 0 then
        local str = ccClientText(11913)
        self:SetWndText(layoutNum, str)
        if showIcon then
            showIcon = false
        end
        isFree = true

    end

    local disText = itemdata.disText
    local showDis = false
    if not string.isempty(disText) then
        self:SetWndText(DiscountImgText, disText)
        --self:SetWndEasyImage(discount,disIcon)
        showDis = true
    end
    CS.ShowObject(AniRootDiscountImg, showDis)

    local limitType = itemdata.resetType
    local isLimit = false
    local isSoldOut = false
    local limitNum = itemdata.personalGoal
    if limitNum ~= -1 then
        isLimit = true
    end
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
        local hasBuyNum = itemdata.personal
        local color
        if hasBuyNum >= limitNum then
            color = "red"
            isSoldOut = true
        else
            color = "green"
        end
        local hasBuyNumStr = math.range(hasBuyNum, 0, limitNum)
        local str = string.format("%s/%s", hasBuyNumStr, LUtil.NumberCoversion(limitNum))
        local colorStr = pre .. LUtil.FormatColorStr(str, color)
        self:SetWndText(AniRootLimit, colorStr)
    end
    CS.ShowObject(AniRootLimit, isLimit)
    CS.ShowObject(AniRootSoldout, isSoldOut)
    CS.ShowObject(buyBtnRedPoint, not isSoldOut and isFree)

    if not string.isempty(itemdata.unlock) then
        local isUnlock, tip = gModelShop:CheckIsUnlock(itemdata.unlock, itemdata.unlockTxt)
        if not isUnlock then
            self:SetWndText(AniRootLimit, tip)
            CS.ShowObject(AniRootLimit, true)
        end
    end

    if gLGameLanguage:IsForeignRegion() and not gLGameLanguage:IsJapanRegion() then
        self:SetAnchorPos(AniRootBuyBtn, self._foreignContentItemPosLit.buyBtnPos)
        self:SetAnchorPos(AniRootLimit, self._foreignContentItemPosLit.limitPos)
    end

    if gLGameLanguage:IsJapanRegion() then

    elseif gLGameLanguage:IsForeignRegion() then
        self:InitTextShowWithLanguage(AniRootItemName)
    else
        self:InitTextModeWithLanguage(AniRootItemName, nil, true)
    end

    --self:InitTextModeWithLanguage(AniRootLimit)
    local limitTextAddSize = -2
    if gLGameLanguage:IsGermanVersion() then
        limitTextAddSize = -4
    end
    self:InitTextSizeWithLanguage(AniRootLimit, limitTextAddSize)
    self:InitTextLineWithLanguage(AniRootLimit, -30)

    local image = "public_btn_2_1"
    local showWear = false
    local isOwn = false
    if limitNum == 1 then
        local isSkinItem, stateCode = gModelHero:GetSkinStateByItemId(goods)
        if isSkinItem then
            isOwn = stateCode > 1
            if stateCode == 4 then
                showWear = true
            elseif stateCode == 3 then
                showIcon = false
                image = "public_btn_2_2"
                self:SetWndText(layoutNum, ccClientText(17421))
            elseif stateCode == 2 then
                showIcon = false
                image = "public_btn_2_2"
                self:SetWndText(layoutNum, ccClientText(17422))
            end
        end
    end

    CS.ShowObject(AniRootBuyBtn, not showWear)
    CS.ShowObject(AniRootWearTag, showWear)
    CS.ShowObject(layoutIcon, showIcon)
    --self:SetBtnImageAndMat(AniRootBuyBtn, image, layoutNum)
    CS.ShowObject(AniRootWearTag, showWear)

    if isOwn then
        CS.ShowObject(AniRootLimit, false)
        CS.ShowObject(AniRootSoldout, true)
    end
end

function UIDian:OnClickDetailsBtnFunc()
    --GF.OpenWnd("UIYellHRew",{extractType = 2,viewType = 1})
    GF.OpenWnd("UIYellHRew",{ShopGl = self.ShopGl, curShopId = self._curShopId ,viewType = 8})
end

function UIDian:OnItemChange()
    for k, v in pairs(self._uiCurrencyItem) do
        local refId = k
        local item = v
        local count = gModelItem:GetNumByRefId(refId)
        count = LUtil.NumberCoversion(count)

        local num = self:FindWndTrans(item, "num")
        self:SetWndText(num, count)
    end

    local itemList = self:FindUIScroll(self._goodsListKey)
    if itemList then
        itemList:DrawAllItems(false)
    end

end

function UIDian:InitActBottomBtnList()
    self._uiShopTypeList = {}
    local shopList = gModelActivity:GetShopDataList()
    local key = "shopTypeList"
    local itemList = self:GetUIScroll(key)

    local index = 1
    local shopDataList = {}
    for k, v in ipairs(shopList) do
        local shopId = v.sid
        local shop = {
            shopId = shopId,
            pageId = v.pageId,
        }
        table.insert(shopDataList, shop)
        if self._curShopId == shopId then
            index = k
        end
    end
    itemList:Create(self.mShopTypeList, shopDataList, function(...)
        self:OnDrawActShopType(...)
    end)
    itemList:EnableScroll(true, true)
    local uiList = itemList:GetList()
    uiList:DelayScrollTo(index)
end

function UIDian:ShowShopDesc()
    if self._curShopType == ModelShop.ACTIVITY then

    else
        local currencyCfg = gModelShop:GetShopCurrencyCfg(self._curShopId)
        if #currencyCfg > 0 then
            return
        end
    end

    CS.ShowObject(self.mMoneyList, false)

    self:ShowDi(1)

    local shopId = self._curShopId
    local curDescId = self._shopDescId
    local desc, id = gModelShop:GetShopDesc(shopId, curDescId)
    self._shopDescId = id
    self:SetWndText(self.mShopDesc, desc)
    CS.ShowObject(self.mShopDesc, true)
end

function UIDian:RefreshShop()
    self:RefreshItemList()
    self:SetRefreshContent()
    self:ModifyContentSize()
end

function UIDian:OnWndRefreshDetailsBtn()
    local show = false
    if self._curShopType ~= ModelShop.ACTIVITY then
        local ProbabilityShow = gModelShop:GetShopProbabilityShow(self._curShopId)
        local RandomShop = gModelShop:IsRandomShop(self._curShopId)
        if ProbabilityShow and ProbabilityShow > 0 and RandomShop then
            show = true
        end
    end
    CS.ShowObject(self.mDetailsBtn,show)
end

function UIDian:OnShopListResp(pb)
    local shopId = pb.shopId
    local autoBuy = pb.autoBuy
    if shopId ~= self._curShopId then
        return
    end
    if autoBuy and autoBuy == 0 then
        local ref = gModelShop:GetShopRef(shopId)
        if ref.isAuto == 1 then
            local buySet = pb.buySet
            if buySet and buySet.open == 1 then
                gModelShop:ShopAutoBuyReq(shopId)
            end
        end
    end
    self:RefreshShop()
end
function UIDian:OnClickAutoBuy()
    GF.OpenWnd("UIDianAutoPop", { shopId = self._curShopId })
end

function UIDian:ShowActRefreshContent()
    CS.ShowObject(self.mBottomBg, true)
    CS.ShowObject(self.mRefreshBtn, false)
    CS.ShowObject(self.mRefreshTimes, false)
    CS.ShowObject(self.mBtnAutoBuy, false)
    self:TimerStop(self._refreshTimerKey)
    local show = self:ShowActCountdown()
    if show then
        self:TimerStart(self._activityTimer, 1, false, -1)
    end

end

function UIDian:OnClickRefresh()
    local curShopId = self._curShopId
    local refreshTime = gModelShop:GetShopRefreshTime(curShopId)
    local isAdsShow = self:CheckShowRefreshAdBtn()
    if refreshTime == -1 then
        if gModelShop:IsRandomShop(curShopId) and isAdsShow then
            if self:ShowAd() then return end
        end
        return
    end

    local netData = gModelShop:GetShopNetData(curShopId)
    if not netData then
        return
    end
    local refresh = netData.refresh
    if not refresh then
        return
    end
    local freeNum = refresh.freeNum
    if freeNum > 0 then
        gModelShop:ShopRefreshReq(curShopId)
    else
        if isAdsShow then
            if self:ShowAd() then return end
        end

        local costNum = refresh.costNum
        local isCostMax = false
        local costMax = gModelShop:GetShopMaxRefreshTime(curShopId)
        if costMax >= 0 and costNum >= costMax then
            GF.ShowMessage(ccClientText(11404))
            return
        end

        local itemId
        local sendShopRefresh = false
        local nextTimes = costNum + 1
        local refreshNeed = gModelShop:GetShopRefreshNeed(curShopId, nextTimes)
        if refreshNeed then
            itemId = refreshNeed.itemId
            local ownNum = gModelItem:GetNumByRefId(itemId)
            local needNum = refreshNeed.itemNum
            sendShopRefresh = ownNum >= needNum and not isCostMax
        end
        if sendShopRefresh then
            gModelShop:ShopRefreshReq(curShopId)
        else
            if itemId and itemId > 0 then
                local wndName = self:GetWndName()
                gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = wndName })
            end
        end
    end

end

function UIDian:SetRefreshContent()
    self:TimerStop(self._activityTimer)
    self:TimerStop(self._refreshTimerKey)
    local canRefresh = self:IsShowTimeRefresh()
    CS.ShowObject(self.mBottomBg, canRefresh)
    if not canRefresh then return end

    local curShopId = self._curShopId
    local isAuto = gModelShop:GetShopIsAuto(curShopId)
    CS.ShowObject(self.mBtnAutoBuy, isAuto)
    local shopAutoBuySet = gModelShop:GetShopAutoBuySetList(curShopId)
    local isAutoOpen = shopAutoBuySet and shopAutoBuySet.open == 1
    CS.ShowObject(self.mAutoEff, isAutoOpen)
    if isAutoOpen then
        --self:CreateWndSpine(self.mAutoEff,"fx_ui_zidonggoumai","fx_ui_zidonggoumai")
        self:CreateWndEffect(self.mAutoEff, "fx_ui_zidonggoumai_tx", "fx_ui_zidonggoumai_tx", 100)
    end

    local netData = gModelShop:GetShopNetData(curShopId)
    if not netData then
        return
    end

    local refresh = netData.refresh
    if not refresh then
        return
    end

    local moneyStr = ""
    local adStr = ""
    local showAdBtn = false
    local freeNum = refresh.freeNum
    local hasFreeNum = freeNum > 0
    local showRP = false
    local showIcon = true
    if hasFreeNum then
        showIcon = false
        showRP = true
        moneyStr = string.replace(ccClientText(11409), freeNum)
    else
        local costNum = refresh.costNum
        local nextTimes = costNum + 1
        local showAdStr = false
        local adConfig = {
            adMethodId = adMethodId_202,
            refId = curShopId,
        }
        local config = gModelAds:GetAdConfigByParam(adConfig)
        local refreshNeedItem = gModelShop:GetShopRefreshNeed(curShopId, nextTimes)
        if refreshNeedItem then
            local color = "red"
            local ownNum = gModelItem:GetNumByRefId(refreshNeedItem.itemId)
            local itemNum = refreshNeedItem.itemNum
            local hasCount = ownNum >= itemNum
            if hasCount then
                color = "white"
            end

            local isCostMax = false
            local refreshCountMax = gModelShop:GetShopMaxRefreshTime(curShopId)
            if refreshCountMax and refreshCountMax > 0 then
                if costNum >= refreshCountMax then
                    isCostMax = true
                end
            end

            if self:CheckShowRefreshAdBtn() then
                --- 当商店存在“免费手动刷新”或“付费手动刷新”，则免费次数和付费次数均用完后刷新按钮替换为“广告”按钮
                --- 反馈表：当道具不足时显示“观看广告”刷新，当广告次数不足时，显示正常的刷新消耗
                --if isCostMax or not hasCount then
                --    showAdBtn = true
                --end
                --- 广告商城调整 —— 商店刷新的“观看广告”出现时机调整为“免费次数消耗完毕后，显示“观看广告”按钮，广告次数消耗完毕后，再显示钻石刷新”
                showAdBtn = true
            end

            if showAdBtn and config then
                --- 取消红点
                gModelRedPoint:SetAdsRedPointClick(config.redPointConfig)
                local loseTime = gModelAds:GetHasAdViewCount(adConfig) or 0
                local hasCnt = loseTime > 0
                adStr = LUtil.FormatColorStr(string.replace(ccClientText(11409),loseTime), hasCnt and "white" or "red")
                showRP = hasCnt
                showAdStr = true
            end
            if not showAdStr then
                moneyStr = LUtil.FormatColorStr(itemNum, color)
            end
        elseif gModelShop:IsRandomShop(curShopId) then
            if self:CheckShowRefreshAdBtn() and config then
                showAdBtn = true
                --- 取消红点
                gModelRedPoint:SetAdsRedPointClick(config.redPointConfig)
                local loseTime = gModelAds:GetHasAdViewCount(adConfig) or 0
                local hasCnt = loseTime > 0
                adStr = LUtil.FormatColorStr(string.replace(ccClientText(11409),loseTime),hasCnt and "white" or "red")
                showRP = hasCnt
            end
        end
    end
    self:SetWndText(self.mMoneyNum,moneyStr)
    self:SetWndText(self.mAdNum,adStr)

    CS.ShowObject(self.mMoneyIcon, showIcon)
    CS.ShowObject(self.mRefreshBtnRP,showRP)


    local iconPath
    if showAdBtn then
        iconPath = "adShop_btn_1"
    elseif not hasFreeNum then
        local refreshNeed = gModelShop:GetShopRefreshNeed(curShopId, 1)
        local icon, iconBg = gModelItem:GetItemImgByRefId(refreshNeed.itemId)
        if icon then
            iconPath = icon
        end
    end
    if iconPath then
        self:SetWndEasyImage(self.mMoneyIcon, iconPath,function()
            CS.ShowObject(self.mMoneyIcon,true)
        end)
    else
        CS.ShowObject(self.mMoneyIcon,false)
    end

    local refreshCount = gModelShop:GetShopRefreshCount(curShopId)
    if freeNum < refreshCount then
        self._lastAddTime = refresh.freeTime / 1000
        self._curRefreshNum = freeNum
        self:SetCountDown()
        self:TimerStop(self._refreshTimerKey)
        self:TimerStart(self._refreshTimerKey, 1, false, -1)
    else
        self:TimerStop(self._refreshTimerKey)
        local timeStr = LUtil.FormatTimespanNumber(0)
        timeStr = LUtil.FormatColorStr(timeStr, "green")
        self:SetWndText(self.mTimerText, ccClientText(11411) .. timeStr)
    end

    local costMax = gModelShop:GetShopMaxRefreshTime(curShopId)
    local showRefreshTimes = false
    if costMax > 0 then
        showRefreshTimes = true
    end
    local str = ccClientText(11418)
    str = string.replace(str, refresh.costNum, costMax)
    self:SetWndText(self.mRefreshTimes, str)

    CS.ShowObject(self.mRefreshTimes, showRefreshTimes)
    CS.ShowObject(self.mRefreshBtn, true)
    CS.ShowObject(self.mTimerText, true)
    CS.ShowObject(self.mMoneyNum, true)
    CS.ShowObject(self.mAdNum, true)
end

function UIDian:BuyGoods(goodsId)
    if not self:CanBuyGoods(true) then
        return
    end

    gModelShop:BuyGoods(self._curShopId, goodsId, false, self:GetWndName())
end

function UIDian:InitData()
    self._shopTypeBtnIconPath = {
        [1] = "public_btn_tab_off",
        [2] = "public_btn_tab_on",
    }
    --self._shopScoreIconPath =
    --{
    --	[1]= "public_btn_1_3",
    --	[2]= "public_btn_1_1",
    --}

    self._discountIconPathList = {
        [1] = "shop_txt_sale_1",
        [2] = "shop_txt_sale_2",
        [3] = "shop_txt_sale_3",
        [4] = "shop_txt_sale_4",
        [5] = "shop_txt_sale_5",
        [6] = "shop_txt_sale_6",
        [7] = "shop_txt_sale_7",
        [8] = "shop_txt_sale_8",
        [9] = "shop_txt_sale_9",
    }

    self._limitTypeText = gModelShop:GetLimitStrList()

    self._shopTypeName = {
        [1] = ccClientText(11407),
        [2] = ccClientText(11408),
        [3] = ccClientText(11419),
    }

    --self._noSelTxtList = {
    --	CS.FindTrans(self.mScoreBtn, "selText"),
    --	CS.FindTrans(self.mShopBtn, "selText"),
    --	CS.FindTrans(self.mActivityBtn, "selText"),
    --}

    --self._shopIdRecord={}

    self._filterUIItemList = {}
    self._uiShopTypeList = {}

    self._uiShopItemList = {} --商品uiitem
    self._uiShopItemTranList = {} --商品uiitem transform
    self._refreshTimerKey = "refreshTimer"
    self._uiCurrencyItem = {}
    self._curFilterType = 0

    self._currencyListKey = "_currencyListKey"
    self._shopTypeListKey = "_currencyListKey"
    self._goodsListKey = "_goodsListKey"

    self._activityTimer = "_activityTimer"
    self._backTimer = "_backTimer"
    self._delayRefresh = "_delayRefresh"
    self._delayGuideTips = "_delayGuideTips"

    self._checkEffHide = "_checkEffHide"
    self._fingerEff = "_fingerEff"

    self._simuTimer = "_simuTimer"
    self._darkItemCd = "_darkItemCd"

    self._foreignContentItemPosLit = {
        buyBtnPos = Vector2.New(0, -50),
        limitPos = Vector2.New(0, -94),
    }

    local ref = gModelShop:GetShopTypeRef(ModelShop.NORMAL)
    if ref then
        local show = gModelFunctionOpen:CheckIsShow(ref.functionOpenRefId)
        CS.ShowObject(self.mShopBtn,show)
    end
    ref = gModelShop:GetShopTypeRef(ModelShop.SCORE)
    if ref then
        local show = gModelFunctionOpen:CheckIsShow(ref.functionOpenRefId)
        CS.ShowObject(self.mScoreBtn,show)
    end
end

function UIDian:RefreshItemList(noAni)

    self:TimerStop(self._darkItemCd)

    local curShopId = self._curShopId
    local data = gModelShop:GetShopNetData(curShopId)
    if not data then
        return
    end

    local isRandom = gModelShop:IsRandomShop(curShopId)

    local filteredGoods = self:FilterGoods(data.goodsList)

    if not isRandom then
        table.sort(filteredGoods, function(a, b)
            return a.seq < b.seq
        end)
    end

    local dataList = {}

    local adShopList = {}
    local configs = gModelAds:GetAdConfigsByParam({
        adMethodId = adMethodId_201,
        refId = curShopId
    })
    if configs and #configs > 0 then
        for k,v in pairs(configs) do
            local configByModule1Data = v.configByModule1Data
            table.insert(adShopList,{
                adConfig = v,
                adViewInfo = gModelAds:GetAdsViewInfo(v.refId),
                sort = configByModule1Data.sort,
                isAd = true,
            })
        end
        table.sort(adShopList,function(a,b) return a.sort < b.sort end)

        for i,v in ipairs(adShopList) do
            table.insert(dataList,v)
        end
    end


    for k, v in ipairs(filteredGoods) do
        table.insert(dataList, {
            goodsId = v.goodsId,
            isAd = false,
        })
    end




    printInfoN("UIDian:RefreshItemList(noAni)")

    self:DestroyWndEffectByKey(self._fingerEff)
    self:TimerStop(self._checkEffHide)

    local itemList = self:FindUIScroll(self._goodsListKey)
    local setFunc = function(...)
        self:OnDrawGoods(...)
    end

    self._uiItemRecord = {}

    if not itemList then
        itemList = self:GetUIScroll(self._goodsListKey)
        local para = {
            root = self.mItemList,
            dataList = dataList,
            setFunc = setFunc,
            type = UIItemList.SUPER_GRID,
        }
        itemList:InitListData(para)
        self.ShopGl = dataList
    else
        local list = itemList:GetList()
        list:SetFuncOnItemDraw(setFunc)
        itemList:RefreshList(dataList)
    end
    self:RefreshSimuTime()

    self:TimerStart(self._darkItemCd, 1, false, -1)

    if noAni then
        itemList:DrawAllItems(false)
        return
    end
    self:TimerStop(self._delayRefresh)
    self:TimerStart(self._delayRefresh, 0, false, 1)

    if self._isFromBubble then
        self:TimerStop(self._delayGuideTips)
        self:TimerStart(self._delayGuideTips, 0.5, false, 1)
        self._isFromBubble = false
    end

end

function UIDian:InitScreenPageList()
    local hasFilter = false
    local sreenPages = gModelShop:GetShopScreenPageCfg(self._curShopId)
    if not table.isempty(sreenPages) then
        hasFilter = true
    end

    CS.ShowObject(self.mFilter, hasFilter)
    if hasFilter then
        local filterList = self._filterList
        if not filterList then
            filterList = UIListEasy:New()
            filterList:Create(self, self.mTypeBtnList)
            filterList:SetFuncOnItemDraw(function(...)
                self:OnDrawFilterBtn(...)
            end)
            self._filterList = filterList
        end
        filterList:RemoveAll()
        for k, v in ipairs(sreenPages) do
            filterList:AddData(k, v)
        end
        filterList:RefreshList()
    end
end

function UIDian:OnDrawShopTypeBtn(list, item, itemdata, itempos)
    local bg = self:FindWndTrans(item, "bg")
    local tab = self:FindWndTrans(bg, "BtnTab1")
    local bgRedPoint = self:FindWndTrans(bg, "redPoint")
    --local name = self:FindWndTrans(item,"name")

    self._uiShopTypeList[itemdata] = item
    if self._curShopId == itemdata then
        gModelRedPoint:SetMultiIdRedClicked(ModelRedPoint.SHOP, itemdata)
        self:SetTypeBtnSelected(item, itemdata, false)
    else
        self:SetTypeBtnDeseleted(item, itemdata, false)
    end

    local nameCfg = ccLngText(gModelShop:GetShopName(itemdata))
    --if self._curShopType == ModelShop.ACTIVITY then
    --	local shopData = gModelActivity:GetShopDataBySid(itemdata)
    --	nameCfg = shopData.name
    --else
    --	nameCfg = ccLngText(gModelShop:GetShopName(itemdata))
    --end

    local addFontLine = -20
    local addFontSize = -4
    if gLGameLanguage:IsJapanVersion() then
        addFontSize = -6
    end
    self:SetWndTabText(tab, nameCfg, addFontSize, addFontLine)

    local isOpen = gModelShop:CheckIsShopOpen(itemdata)
    if not isOpen then
        self:SetWndTabStatus(tab, LWnd.StateGray)
    end
    self:OnWndRefreshDetailsBtn()
    local showRed = gModelRedPoint:CheckSingleShopRedPoint(itemdata)
    CS.ShowObject(bgRedPoint, showRed)
    self:SetWndClick(bg, function()
        LxUiHelper.FilterScrollItem(self.mShopTypeList, itempos - 1)
        self:OnSelectShop(itemdata)
        self:SendTaInfo()
    end)
end

function UIDian:SetTextContent()
    local shopName = ccLngText(gModelShop:GetShopName(self._curShopId))
    local addLine = -30
    if gLGameLanguage:IsThaiVersion() then
        addLine = -50
    end
    self:SetWndText(self.mTitle, shopName)
    self:InitTextLineWithLanguage(self.mTitle, addLine)
end

function UIDian:HideFilter()
    CS.ShowObject(self.mFilter, false)
end

function UIDian:IsShowBackShopTime()

    local shopIdKey = gModelBackflow:RegressionConfigRefByKey("shopId")
    if shopIdKey ~= self._curShopId then
        return
    end

    local showEndTime = gModelBackflow:GetShopEndTime()
    if showEndTime <= 0 then
        return
    end

    return true
end

function UIDian:RefreshRed()

    local shopList = gModelShop:GetShopShow(ModelShop.NORMAL)
    local showRed = false
    for k, v in pairs(shopList) do
        local refId = v.refId
        showRed = gModelRedPoint:CheckSingleShopRedPoint(refId)
        if showRed then
            break
        end
    end

    local redTran = self:FindWndTrans(self.mShopBtn, "redPoint")
    CS.ShowObject(redTran, showRed)

    shopList = gModelShop:GetShopShow(ModelShop.SCORE)
    showRed = false
    for k, v in pairs(shopList) do
        local refId = v.refId
        showRed = gModelRedPoint:CheckSingleShopRedPoint(refId)
        if showRed then
            break
        end
    end

    local redTran = self:FindWndTrans(self.mScoreBtn, "redPoint")
    CS.ShowObject(redTran, showRed)

    if self._curShopType == ModelShop.ACTIVITY then
        return
    end

    for k, v in pairs(self._uiShopTypeList) do
        local showRed = gModelRedPoint:CheckSingleShopRedPoint(k)
        local redTran = self:FindWndTrans(v, "bg/redPoint")
        CS.ShowObject(redTran, showRed)
    end


end

function UIDian:OnClickActivity()
    if self._curShopType == ModelShop.ACTIVITY then
        return
    end
    CS.ShowObject(self.mDetailsBtn,false)
    gLxTKData:OnUIBtnClick("UIDian", 3)

    self._curShopType = ModelShop.ACTIVITY

    local shopDataList = gModelActivity:GetShopDataList()
    local data = shopDataList[1]
    self._curShopId = data.sid

    self:SetShopContent()

    self:SendTaInfo()
end

function UIDian:IsShowTimeRefresh()

    if self._curShopType == ModelShop.ACTIVITY then
        return true
    else
        local refreshTime = gModelShop:GetShopRefreshTime(self._curShopId)
        local canRefresh = refreshTime ~= -1
        return canRefresh or self:CheckShowRefreshAdBtn()
    end
end

function UIDian:ShowActGoods(pageData)
    local dataList = gModelActivity:FormatActGoodsList(pageData)

    local setFunc = function(...)
        self:OnDrawActGoods(...)
    end
    local itemList = self:FindUIScroll(self._goodsListKey)
    if not itemList then
        itemList = self:GetUIScroll(self._goodsListKey)
        itemList:Create(self.mItemList, dataList, setFunc, UIItemList.SUPER_GRID)
    else
        local list = itemList:GetList()
        list:SetFuncOnItemDraw(setFunc)
        itemList:RefreshList(dataList)
    end

    self:TimerStop(self._delayRefresh)
    self:TimerStart(self._delayRefresh, 0, false, 1)
end

function UIDian:ShowBackCountdown()
    CS.ShowObject(self.mBottomBg, true)
    CS.ShowObject(self.mRefreshBtn, false)
    CS.ShowObject(self.mRefreshTimes, false)

    local showEndTime = gModelBackflow:GetShopEndTime()
    if showEndTime <= 0 then
        return
    end
    local timeLeft = showEndTime - GetTimestamp()
    if timeLeft < 0 then
        self:TimerStop(self._backTimer)
        local str = ccClientText(16802) --"兑换时间已结束"
        self:SetWndText(self.mTimerText, str)
    else
        local timeStr = LUtil.FormatTimeSpanShop(timeLeft)
        timeStr = LUtil.FormatColorStr(timeStr, "green")
        local str = ccClientText(16803) .. timeStr   --"兑换倒计时: "..timeStr
        self:SetWndText(self.mTimerText, str)
        return true
    end
end

function UIDian:SetSimulateCountDown()
    local openTime = gModelSimuFight:GetShopOpenTime()
    if openTime == 0 or openTime > GetTimestamp() then
        --local timeLeft = openTime - GetTimestamp()
        local str = ccClientText(25270) --"后可以兑换商品"
        --local timeStr = string.replace(str,LUtil.FormatTimeToCn3(timeLeft))
        self:SetWndText(self.mSimuTime, str)
        return false
    end

    local endTime = gModelSimuFight:GetShopEndTime()
    if endTime > GetTimestamp() then
        local timeLeft = endTime - GetTimestamp()
        local str = ccClientText(25271) --"剩余兑换时间：%s"
        local timeStr = string.replace(str, LUtil.FormatTimeToCn3(timeLeft))
        self:SetWndText(self.mSimuTime, timeStr)
        return true
    end

    local str = ccClientText(25272) --"兑换已结束"
    self:SetWndText(self.mSimuTime, str)
    self:TimerStop(self._simuTimer)

end

function UIDian:ShowAllCountDown()
    if not self._uiItemRecord then
        return
    end
    for k, v in pairs(self._uiItemRecord) do
        self:ShowItemCountDown(v.item, v.itemdata)
    end
end

function UIDian:InitUIEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:OnClickReturnBtn()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mShopBtn, function()
        self:OnClickShop()
    end, LSoundConst.CLICK_PAGE_COMMON)
    self:SetWndClick(self.mScoreBtn, function()
        self:OnClickScore()
    end, LSoundConst.CLICK_PAGE_COMMON)
    self:SetWndClick(self.mActivityBtn, function()
        self:OnClickActivity()
    end, LSoundConst.CLICK_PAGE_COMMON)
    self:SetWndClick(self.mRefreshBtn, function()
        self:OnClickRefresh()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mJumpBtn, function()
        self:OnClickJump()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mBtnAutoBuy, function()
        self:OnClickAutoBuy()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mDetailsBtn,function()
        self:OnClickDetailsBtnFunc()
    end)
end

function UIDian:SetTypeBtnDeseleted(item, shopId)
    local tab = self:FindWndTrans(item, "bg/BtnTab1")
    self:SetWndTabStatus(tab, 1)
end

function UIDian:ChangeStoreType(shopType)
    if self._curShopType == shopType then
        return
    end

    self._curShopType = shopType
    self._curShopId = self:GetShowShopId(shopType, 1)

    self:SetShopContent()
    self:SendTaInfo()
end

function UIDian:OnDrawCurrency(list, item, itemdata, itempos)
    --local bg = self:FindWndTrans(item,"bg")
    local icon = self:FindWndTrans(item, "icon")
    local num = self:FindWndTrans(item, "num")
    local addBtn = self:FindWndTrans(item, "addBtn")

    local iconPath, iconBgPath = gModelItem:GetItemImgByRefId(itemdata)
    self:SetWndEasyImage(icon, iconPath)
    self:SetWndClick(addBtn, function()
        self:OnClickAdd(itemdata)
    end, LSoundConst.CLICK_BUTTON_COMMON)
    local count = gModelItem:GetNumByRefId(itemdata)

    count = LUtil.NumberCoversion(count)

    self:SetWndText(num, count)

    self._uiCurrencyItem[itemdata] = item
end

function UIDian:InitCurrencyList()
    self:ShowShopDesc()

    self._uiCurrencyItem = {}
    local currencyCfg = gModelShop:GetShopCurrencyCfg(self._curShopId)
    if #currencyCfg == 0 then
        return
    end
    self:SetMoneyList(currencyCfg)
end

function UIDian:RefreshSimuTime()
    local isSimuShop = self._curShopId == 2015 or self._curShopId == 2016
    CS.ShowObject(self.mSimuPart, isSimuShop)
    self:TimerStop(self._simuTimer)

    if not isSimuShop then
        return
    end

    if self:SetSimulateCountDown() then
        self:TimerStart(self._simuTimer, 1, false, -1)
    end

end

function UIDian:SetStaticContent()
    local text = self:FindWndTrans(self.mShopBtn, "BtnTab3")
    self:SetWndTabText(text, ccClientText(11407))

    text = self:FindWndTrans(self.mScoreBtn, "BtnTab3")
    self:SetWndTabText(text, ccClientText(11408))

    text = self:FindWndTrans(self.mActivityBtn, "BtnTab3")
    self:SetWndTabText(text, ccClientText(11419))

    self:SetWndText(self.mAutoBuyText, ccClientText(11422))
end

function UIDian:OnClickBtnAd(itemdata)
    local adConfig = itemdata.adConfig
    local configByModule2Data = adConfig.configByModule2Data
    gModelAds:OpenAdByCommonTips(490002,{
        openADFunc = function()
            gModelAds:OpenAd({
                refId = adConfig.refId,
            })
        end,
        adMethodId = adMethodId_201,
        refId = self._curShopId,
        reward = configByModule2Data.reward,
        jumpCB = function()
            self:WndClose()
        end,
    })
end

function UIDian:RefreshBackTime()
    local shopIdKey = gModelBackflow:RegressionConfigRefByKey("shopId")
    local timeKey = self._backTimer
    self:TimerStop(timeKey)
    if shopIdKey ~= self._curShopId then
        return
    end
    self:TimerStop(self._activityTimer)
    self:TimerStop(self._refreshTimerKey)

    local show = self:ShowBackCountdown()
    if show then
        self:TimerStart(timeKey, 1, false, -1)
    end
end

function UIDian:IsIosForbid(jumpId)
    if PRODUCT_G_VER == 1 then
        return jumpId == 10402101 --ios 写死屏蔽时光衣柜
    end
    return false
end

function UIDian:OnDrawGoods(list, item, itemdata, itempos)
    --return self:SetGoodsItem(item,itemdata)

    local AniRoot = self:FindWndTrans(item, "AniRoot")
    --local AniRootBg = self:FindWndTrans(AniRoot,"bg")
    local AniRootItemName = self:FindWndTrans(AniRoot, "itemName")
    local AniRootSoldout = self:FindWndTrans(AniRoot, "soldout")
    --local soldoutIcon = self:FindWndTrans(AniRootSoldout,"icon")
    local AniRootBuyBtn = self:FindWndTrans(AniRoot, "buyBtn")
    local buyBtnLayout = self:FindWndTrans(AniRootBuyBtn, "layout")
    local layoutIcon = self:FindWndTrans(buyBtnLayout, "icon")
    local layoutNum = self:FindWndTrans(buyBtnLayout, "num")
    local buyBtnRedPoint = self:FindWndTrans(AniRootBuyBtn, "redPoint")
    local AniRootWearTag = self:FindWndTrans(AniRoot, "wearTag")
    local AniRootDiscountImg = self:FindWndTrans(AniRoot, "DiscountImg")
    local DiscountImgText = self:FindWndTrans(AniRootDiscountImg, "text")
    local AniRootLimit = self:FindWndTrans(AniRoot, "limit")

    local iconTrans = CS.FindTrans(AniRoot, "CommonUI/Icon")

    local isAd = itemdata.isAd
    if isAd then
        local adConfig = itemdata.adConfig

        --- 取消红点
        gModelRedPoint:SetAdsRedPointClick(adConfig.redPointConfig)

        local rewardName = ""
        local configByModule2Data = adConfig.configByModule2Data
        local reward = configByModule2Data.reward
        local showReward = reward and #reward > 0
        if showReward then
            local itemData = reward[1]
            self:CreateCommonIconImpl(iconTrans, itemData, { checkActive = true })

            rewardName = gModelGeneral:GetCommonItemName(itemData)
        end
        CS.ShowObject(iconTrans,showReward)

        self:SetWndText(AniRootItemName, rewardName)

        local limitStr = ""
        ---@type StructAdsViewInfo
        local adViewInfo = itemdata.adViewInfo
        local viewCount = adViewInfo and adViewInfo.viewCount or 0
        local times = adConfig.times
        local hasCnt = times - viewCount
        local soldOut = hasCnt < 1
        CS.ShowObject(buyBtnRedPoint,not soldOut)
        local resetType = adConfig.resetType
        local pre = ""
        local limitTypeText = self._limitTypeText
        if limitTypeText[resetType] then
            pre = ccClientText(limitTypeText[resetType])
        else
            pre = ccClientText(limitTypeText[0])
        end
        local color = soldOut and "red" or "green"
        local colorStr = string.replace("#a1#/#a2#",hasCnt,times)
        colorStr = LUtil.FormatColorStr(colorStr, color)
        limitStr = string.replace("#a1##a2#",pre,colorStr)

        CS.ShowObject(AniRootSoldout,soldOut)

        self:SetWndText(AniRootLimit, limitStr)
        CS.ShowObject(AniRootLimit, true)

        CS.ShowObject(AniRootDiscountImg, false)
        CS.ShowObject(AniRootWearTag, false)

        self:SetWndEasyImage(layoutIcon,"adShop_btn_1",function()
            CS.ShowObject(layoutIcon,true)
        end)
        self:SetWndText(layoutNum, ccClientText(11913))

        self:SetWndClick(AniRootBuyBtn, function()
            self:OnClickBtnAd(itemdata)
        end)
        self:SetWndClick(AniRoot, function()
            self:OnClickBtnAd(itemdata)
        end)

    else
        local goodsId = itemdata.goodsId
        local goodData = gModelShop:GetShopItemNetData(self._curShopId, goodsId)
        if not goodData then return end

        local goods = gModelShop:GetShopItemCfg(goodsId)
        local rewardData = goods.reward

        local forceNoShowBtn = false
        local itemType = gModelItem:GetType(rewardData.itemId)
        if itemType then
            if itemType == ModelItem.TTEM_TYPE_BADGE then
                forceNoShowBtn = true
            end
        end
        self:CreateCommonIconImpl(iconTrans, rewardData,{checkActive = true},{forceNoShowBtn = forceNoShowBtn})

        local nameCfg = gModelGeneral:GetCommonItemName(rewardData)
        self:SetWndText(AniRootItemName, nameCfg)

        self:SetWndClick(AniRootBuyBtn, function()
            self:BuyGoods(goodsId)
        end)
        self:SetWndClick(AniRoot, function()
            self:BuyGoods(goodsId)
        end)

        if self._targetGoodsId == goodsId then
            self._targetTran = AniRoot
        end

        local price = goods.price
        local showIcon = false
        local priceNum = price.itemNum
        local isFree = false
        if priceNum > 0 then
            showIcon = true
            local priceIcon, priceIconBg = gModelItem:GetItemImgByRefId(price.itemId)
            if priceIcon then
                self:SetWndEasyImage(layoutIcon, priceIcon)
            end

            local priceStr = nil
            if price.itemId == 101001 then
                priceStr = LUtil.NumberCoversion(priceNum)
            else
                priceStr = LUtil.AddNumberSeparate(priceNum)
            end

            self:SetWndText(layoutNum, priceStr)
        else
            isFree = true
            local str = ccClientText(11913)
            self:SetWndText(layoutNum, str)
        end

        local discountCfg = goods.default.fixDiscount
        local hasDis = false
        local str = ccLngText(discountCfg)
        if not string.isempty(str) then
            hasDis = true
            self:SetWndText(DiscountImgText, str)
            self:InitTextLineWithLanguage(DiscountImgText, -30)
            self:InitTextSizeWithLanguage(DiscountImgText, -2)
        end

        CS.ShowObject(AniRootDiscountImg, hasDis)

        local limitCfg = goods.limitCount
        local isLimit = false
        local isSoldOut = false
        if limitCfg.itemNum ~= -1 then
            isLimit = true
        end

        if isLimit then
            local pre = ccClientText(self._limitTypeText[limitCfg.itemId])
            local hasBuyNum = goodData:GetHasBuyNum()
            local allBuyNum = limitCfg.itemNum
            local color
            if hasBuyNum >= allBuyNum then
                color = "red"
                isSoldOut = true
            else
                color = "green"
            end
            local hasBuyNumStr = math.range(hasBuyNum, 0, allBuyNum)
            local str = string.format("%s/%s", hasBuyNumStr, LUtil.NumberCoversion(allBuyNum))
            local colorStr = pre .. LUtil.FormatColorStr(str, color)
            self:SetWndText(AniRootLimit, colorStr)
        end
        CS.ShowObject(AniRootLimit, isLimit)
        CS.ShowObject(AniRootSoldout, isSoldOut)

        local isUnlock, tip = gModelShop:CheckItemIsUnlock(goodsId)
        if not isUnlock then
            self:SetWndText(AniRootLimit, tip)
            CS.ShowObject(AniRootLimit, true)

            local instanceId = item:GetInstanceID()
            self._uiItemRecord[instanceId] = { itemdata = goodsId, item = item }
        end

        local limitTextAddSize = -2
        if gLGameLanguage:IsGermanVersion() then
            limitTextAddSize = -4
        end
        self:InitTextSizeWithLanguage(AniRootLimit, limitTextAddSize)

        if self._isEnus then
            self:InitTextLineWithLanguage(AniRootLimit, 0)
        else
            self:InitTextLineWithLanguage(AniRootLimit, -30)
        end


        CS.ShowObject(buyBtnRedPoint, isFree and not isSoldOut)

        if not gLGameLanguage:IsJapanRegion() then
            self:InitTextShowWithLanguage(AniRootItemName)
        end

        local canBuy = self:CanBuyGoods()
        local image = canBuy and "public_btn_2_2" or "public_btn_ash_2"
        local showWear = false
        local isOwn = false
        if limitCfg.itemNum == 1 then
            local isSkinItem, stateCode = gModelHero:GetSkinStateByItemId(rewardData)
            if isSkinItem then
                isOwn = stateCode > 1
                if stateCode == 4 then
                    showWear = true
                elseif stateCode == 3 then
                    showIcon = false
                    image = "public_btn_2_2"
                    self:SetWndText(layoutNum, ccClientText(17421))
                elseif stateCode == 2 then
                    showIcon = false
                    image = "public_btn_2_2"
                    self:SetWndText(layoutNum, ccClientText(17422))
                end
            end
        end

        CS.ShowObject(AniRootBuyBtn, not showWear)
        CS.ShowObject(AniRootWearTag, showWear)
        CS.ShowObject(layoutIcon, showIcon)
        self:SetWndEasyImage(AniRootBuyBtn, image)

        if gLGameLanguage:IsForeignRegion() and not gLGameLanguage:IsJapanRegion() then
            self:SetAnchorPos(AniRootBuyBtn, self._foreignContentItemPosLit.buyBtnPos)
            self:SetAnchorPos(AniRootLimit, self._foreignContentItemPosLit.limitPos)
        end

        if not gLGameLanguage:IsJapanRegion() then
            self:InitTextShowWithLanguage(AniRootItemName)
        end

        if isOwn then
            CS.ShowObject(AniRootLimit, false)
            CS.ShowObject(AniRootSoldout, true)
        end

        if not gLGameLanguage:IsForeignRegion() then
            self:InitTextModeWithLanguage(AniRootItemName, nil, true)
        end
    end
end

function UIDian:OnDeSelectShop(shopId)
    local item = self._uiShopTypeList[shopId]
    if item then
        self:SetTypeBtnDeseleted(item, shopId)
    end
end

function UIDian:ShowItemCountDown(item, itemdata)
    local unlock, tip, msg, type = gModelShop:CheckItemIsUnlock(itemdata)
    if type ~= 5 then
        return
    end
    local str = ""
    if not unlock then
        str = tip
    end
    local textTran = self:FindWndTrans(item, "AniRoot/limit")
    self:SetWndText(textTran, str)
end

function UIDian:FilterGoods(itemList)

    local needFilter = true

    local curShopId = self._curShopId
    local sreenPages = gModelShop:GetShopScreenPageCfg(curShopId)
    if table.isempty(sreenPages) then
        needFilter = false
    end

    if self._curFilterType == 0 then
        needFilter = false
    end

    local t = {}


    for k, v in ipairs(itemList) do
        local goodsId = v:GetId()

        local hasBuyNum = v:GetHasBuyNum()

        local cfg = gModelShop:GetShopItemCfg(goodsId)
        if cfg then

            local limitCfg = cfg.limitCount
            if limitCfg.itemId == 4 and hasBuyNum >= limitCfg.itemNum and limitCfg.itemNum ~= -1 then
            else
                local data = {}
                data.seq = cfg.default.sequence
                data.goodsId = goodsId

                if needFilter then
                    local filterType = cfg.default.pageType
                    if filterType == self._curFilterType then
                        table.insert(t, data)
                    end
                else
                    table.insert(t, data)
                end
            end
        else
            LogError("not cfg " .. goodsId)
        end

    end
    return t

end

function UIDian:OnShopAutoBuySetResp(pb)
    local buySet = pb.buySet
    local open = buySet.open
    local shopId = buySet.shopId
    if open == 1 and self._curShopId == shopId then
        gModelShop:ShopAutoBuyReq(shopId)
    end
    local shopAutoBuySet = gModelShop:GetShopAutoBuySetList(self._curShopId)
    local isAutoOpen = shopAutoBuySet and shopAutoBuySet.open == 1
    CS.ShowObject(self.mAutoEff, isAutoOpen)
    if isAutoOpen then
        --self:CreateWndSpine(self.mAutoEff,"fx_ui_zidonggoumai","fx_ui_zidonggoumai")
        self:CreateWndEffect(self.mAutoEff, "fx_ui_zidonggoumai_tx", "fx_ui_zidonggoumai_tx", 100)
    end
end

function UIDian:OnDrawActShopType(list, item, itemdata, itempos)
    local bg = self:FindWndTrans(item, "bg")
    local tab = self:FindWndTrans(bg, "BtnTab1")

    local shopId = itemdata.shopId
    self._uiShopTypeList[shopId] = item
    if self._curShopId == shopId then
        --self._curShopShowId = itemdata.shopShowId
        self._curShopShowId = itemdata.pageId
        self:SetTypeBtnSelected(item, shopId, true)
    else
        self:SetTypeBtnDeseleted(item, shopId, true)
    end
    --local shopData = gModelActivity:GetShopDataBySid(shopId)
    local name = gModelActivity:GetLngNameByActivitySid(shopId)

    local addFontLine = -20
    local addFontSize = -4
    if gLGameLanguage:IsJapanVersion() then
        addFontSize = -6
    end
    self:SetWndTabText(tab, name, addFontSize, addFontLine)

    self:SetWndClick(bg, function()
        LxUiHelper.FilterScrollItem(self.mShopTypeList, itempos - 1)
        self:OnSelectActShop(itemdata)
        self:SendTaInfo()

    end)
end

function UIDian:SetCountDown()
    local curTime = GetTimestamp()
    --local curTime =self:GetTestCurTime()
    local timePast = curTime - self._lastAddTime
    local shopRefreshTime = gModelShop:GetShopRefreshTime(self._curShopId)
    local timeLeft = shopRefreshTime - timePast
    if timeLeft < 0 then
        self._curRefreshNum = self._curRefreshNum + 1
        local refreshCount = gModelShop:GetShopRefreshCount(self._curShopId)
        local showTimer = true
        if self._curRefreshNum >= refreshCount then
            --showTimer = false
            self:TimerStop(self._refreshTimerKey)
            local timeStr = LUtil.FormatTimespanNumber(0)
            timeStr = LUtil.FormatColorStr(timeStr, "green")
            self:SetWndText(self.mTimerText, ccClientText(11411) .. timeStr)
        else
            self._lastAddTime = curTime
            timeLeft = shopRefreshTime
        end
        self:SetWndText(self.mMoneyNum, string.replace(ccClientText(11409), self._curRefreshNum))
        self:SetWndText(self.mAdNum,"")

        CS.ShowObject(self.mMoneyIcon, self._curRefreshNum > 1)
        CS.ShowObject(self.mTimer, showTimer)
    end

    local timeStr = LUtil.FormatTimeSpanShop(timeLeft)
    timeStr = LUtil.FormatColorStr(timeStr, "green")
    self:SetWndText(self.mTimerText, ccClientText(11411) .. " " .. timeStr)
end
function UIDian:OnClickScore()
    gLxTKData:OnUIBtnClick("UIDian", 2)

    self:ChangeStoreType(ModelShop.SCORE)
end

function UIDian:SetMoneyList(list)
    CS.ShowObject(self.mMoneyList, true)
    CS.ShowObject(self.mShopDesc, false)
    self:ShowDi(2)

    local itemList = self:GetUIScroll(self._currencyListKey)
    itemList:Create(self.mMoneyList, list, function(...)
        self:OnDrawCurrency(...)
    end)
end

function UIDian:ShowDi(state)
    CS.ShowObject(self.mDi1,state == 1)
    CS.ShowObject(self.mDi2,state == 2)
end

function UIDian:CanBuyGoods(showTips)
    if self._curShopType ~= ModelShop.SIMULATE then
        return true
    end

    local openTime = gModelSimuFight:GetShopOpenTime()
    if openTime == 0 then
        if showTips then
            local str = ccClientText(25267) --"尚未到兑换阶段,无法兑换商品奖励"
            GF.ShowMessage(str)
        end

        return false
    end

    local endTime = gModelSimuFight:GetShopEndTime()
    if endTime < 0 or endTime < GetTimestamp() then
        if showTips then
            local str = ccClientText(25268) -- "兑换已结束,无法兑换商品奖励"
            GF.ShowMessage(str)
        end
        return false
    end

    if self._curShopId == 2012 then
        local canbuy = gModelSimuFight:CanBuyRareGoods()
        if not canbuy and showTips then
            local str = ccClientText(25269) -- "64强才能兑换珍稀商品"
            GF.ShowMessage(str)
        end

        return canbuy
    end

    return true
end

function UIDian:RegisterShopRed()
    self:RegisterRedPointFunc(ModelRedPoint.SHOP, function()
        self:RefreshRed()
    end)
end

function UIDian:OnClickReturnBtn()
    -- if self._page == ModelShop.ACTIVITY then
    -- local sidId = self._subPage
    -- local model =  gModelActivity:GetActivityModeIdBySid(sidId)
    -- if model and model == ModelActivity.ACTIVITY_FAIRY_TALE then
    -- 	local openWndFunc = gModelActivity:GetShowActivityFun(model)
    -- 	local activeData  = gModelActivity:GetActivityBySid(sidId)
    -- 	if openWndFunc and activeData then
    -- 		openWndFunc(activeData)
    -- 	end
    -- end
    -- end
    if self._func then
        self._func()
    end
    self:WndCloseAndBack()
end

function UIDian:RefreshUI()
    local shopId = self:GetWndArg("shopId")
    local page = self:GetWndArg("page")
    local subPage = self:GetWndArg("subPage")

    self._page = page
    self._subPage = subPage
    self._isFromBubble = self:GetWndArg("isFromBubble")
    self._targetGoodsId = self:GetWndArg("goodsId")

    local shopType = nil
    if page and subPage then
        shopType = page
        shopId = subPage
        --if page== ModelShop.ACTIVITY then  --活动商店
        --	shopId = subPage
        --else
        --	shopId = subPage
        --end
    end
    if not shopId then
        shopId = self:GetShowShopId(1, 1)
        shopType = 1
    end
    self._curShopId = shopId
    if shopType then
        self._curShopType = shopType
        --self:ChangeTxt()
    else
        self._curShopType = gModelShop:GetShopStoreType(shopId)
    end

    gLxTKData:OnUIBtnClick("UIDian", shopType)

    local isSimulate = self._curShopType == ModelShop.SIMULATE

    CS.ShowObject(self.mBtnRoot, not isSimulate)

    if self._curShopType == ModelShop.ACTIVITY then
        local shopData = gModelActivity:GetShopDataBySid(shopId)
        if not shopData then
            return
        end
        self._curShopShowId = shopData.pageId
        gModelActivity:ReqActivityConfigData(shopId)
        return
    end
    self:SetShopContent()
end

function UIDian:OnActivityPageResp(pb)
    if self._curShopType ~= ModelShop.ACTIVITY then
        return
    end
    local sid = pb.sid
    local shopId = self._curShopId
    --local shopData = gModelActivity:GetShopDataBySid(shopId)
    --local curSid = shopData.sid
    if sid ~= shopId then
        return
    end

    local pageData = nil
    for k, v in ipairs(pb.pages) do
        if self._curShopShowId == v.pageId then
            pageData = v
            break
        end
    end
    if not pageData then
        for k, v in ipairs(pb.pages) do
            local pageType = v.pageType
            if pageType == ModelActivity.PAGETYPE_MARKEPAGE then
                pageData = v
                break
            end
        end
    end

    if not pageData then
        return
    end

    local pageStruct = StructActivityPage:New()
    pageStruct:CreateByPb(pageData)

    self:ShowActGoods(pageStruct)
    self:ShowActRefreshContent()
    self:ModifyContentSize()
end

function UIDian:OnActivityPageReq()
    local shopId = self._curShopId
    --local shopData = gModelActivity:GetShopDataBySid(shopId)
    --local sid = shopData.sid
    gModelActivity:RecordActivityShop(shopId)
    gModelActivity:OnActivityPageReq(shopId)
end

function UIDian:OnTimer(key)
    if self._refreshTimerKey == key then
        self:SetCountDown()
    elseif self._activityTimer == key then
        self:ShowActCountdown()
    elseif self._backTimer == key then
        self:ShowBackCountdown()
    elseif self._delayRefresh == key then
        local list = self:FindUIScroll(self._goodsListKey)
        if list then
            list:DrawAllItems()
            self:DelaySendFinish(0.4)
        end
    elseif key == self._checkEffHide then
        local effect = self:FindWndEffectByKey(self._fingerEff)
        if effect then
            local dpTrans = effect:GetDisplayTrans()
            if CS.IsValidObject(dpTrans) then
                local pos = dpTrans.position
                printInfoN("pos " .. pos.y)
                if pos.y > 0.7 then
                    self:DestroyWndEffectByKey(self._fingerEff)
                    self:TimerStop(self._checkEffHide)
                end
            end
        end
    elseif key == self._simuTimer then
        self:SetSimulateCountDown()
    elseif key == self._delayGuideTips then
        GF.OpenUIGue('UIGueTip', { targetTran = self._targetTran })
    end
end

------------------------------------------------------------------
return UIDian