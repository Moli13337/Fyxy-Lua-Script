---
--- Created by Administrator.
--- DateTime: 2023/10/10 10:38:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGeay:LWnd
local UIGeay = LxWndClass("UIGeay", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGeay:UIGeay()
    ---@type table<number, CommonIcon>
    self._commonIconTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGeay:OnWndClose()
    self:ClearCommonIconList(self._commonIconTbl)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGeay:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndMode(LWnd.WND_MODE_NONE)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGeay:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    local str = ccClientText(19800) --"获取来源"
    self:SetWndText(self.mTitle, str)

    self:InitData()
    self:InitEvent()
    self:SetWndClick(self.mBtnClose, function()
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_ITEM_GOTO, "close", self._itemRefId)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mMask, function()
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_ITEM_GOTO, "close", self._itemRefId)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:InitPara()
    self:RefreshUI()

end

function UIGeay:OnShopDataRet(pb)
    local shopId = pb.shopId
    if not self._reqList then
        return
    end
    local shopList = self._reqList[2]
    if not shopList then
        return
    end
    if shopList[shopId] == nil then
        return
    end
    shopList[shopId] = true

    local list = self._quickShopList[shopId]
    for k, v in ipairs(list) do
        local goodsId = v.goodsId
        local isLimit = gModelShop:IsLimitBuy(shopId, goodsId)
        v.isLimit = isLimit
    end

    self:CheckShow()
end

function UIGeay:OnActivityDataRet(pb)
    local sid = pb.sid
    if not self._reqList then
        return
    end
    local list = self._reqList[1]
    if not list then
        return
    end
    if list[sid] == nil then
        return
    end
    list[sid] = true

    self:SaveActivityData(pb)

    self:CheckShow()
end

function UIGeay:BuyShopGoods(shopId, goodsId, goods)
    local record = {
        reward = {},
        expend = {}
    }
    record.reward[tostring(goods.reward.itemId)] = goods.reward.itemNum
    record.expend[tostring(goods.price.itemId)] = goods.price.itemNum
    local attr1 = JSON.encode(record)
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_ITEM_GOTO, "buy", attr1)

    gModelShop:BuyGoods(shopId, goodsId, true, self:GetWndName(), self)
end

function UIGeay:OnDrawTabBtn(list, item, itemdata, itempos)
    local bg = self:FindWndTrans(item, "bg")
    local tab = self:FindWndTrans(bg, "BtnTab1")
    local bgRedPoint = self:FindWndTrans(bg, "redPoint")

    local tabState = self._itemRefId == itemdata and LWnd.StateOn or LWnd.StateOff
    self:SetWndTabStatus(tab, tabState)

    local itemName = gModelItem:GetNameByRefId(itemdata)
    self:SetWndTabText(tab, itemName, -2, -30)
    CS.ShowObject(bgRedPoint, false)

    self:SetWndClick(bg, function()
        self:OnClickTabBtn(itemdata)
    end)
end

function UIGeay:SetWayItem(list, item, itemdata, itempos)
    --local bg = self:FindWndTrans(item,"bg")
    local intro = self:FindWndTrans(item, "intro")
    local desc = self:FindWndTrans(item, "desc")
    local gotoBtn = self:FindWndTrans(item, "gotoBtn")
    local gotoBtnText = self:FindWndTrans(gotoBtn, "Text")



    --CS.ShowObject(recmd,itemdata.isRcmd)
    local functionId = itemdata.functionId
    local isOpen = itemdata.isOpen

    local name = itemdata.name

    local isCanSetClick = true
    if functionId == 10404101 then
        local pagePara = gModelFunctionOpen:ModifyWndPara(functionId)
        local subPage = pagePara.subPage or 0
        local sid = gModelActivity:GetSidByUniqueJump(subPage)
        if not sid then
            isCanSetClick = false
            isOpen = false
        end
    end

    local str = gModelItem:GetItemJumpDesc(itemdata.textId)
    self:SetWndText(desc, str)
    self:InitTextSizeWithLanguage(desc, -2)

    local imagePath = isOpen and itemdata.icons[1] or itemdata.icons[2]
    self:SetWndEasyImage(gotoBtn, "public_btn_2_1")
    local color = isOpen and "<#5C6D9A>" or "<#ffffff>"
    self:SetWndText(gotoBtnText, color .. ccClientText(15112) .. "</color>")
    self:SetBtnImageAndMat(gotoBtn, imagePath, nil, true)

    self:SetWndText(intro, name)
    local data = {
        name = name,
        pos = itempos,
    }

    if isCanSetClick then
        self:SetWndClick(gotoBtn, function()
            self:OnClickGoto(functionId, data)
        end)
    end
end

function UIGeay:SetPrivilegeItem(item, itemdata)
    local bg = self:FindWndTrans(item, "bg")
    local icon = self:FindWndTrans(item, "itemBg/Icon")
    local itemName = self:FindWndTrans(item, "itemName")
    local soldout = self:FindWndTrans(item, "soldout")
    local buyBtn = self:FindWndTrans(item, "buyBtn")
    local buyIcon = self:FindWndTrans(item, "buyBtn/layout/icon")
    local buyNum = self:FindWndTrans(item, "buyBtn/layout/num")
    local discountImg = self:FindWndTrans(item, "DiscountImg")
    local limit = self:FindWndTrans(item, "limit")

    self:SetWndEasyImage(icon, itemdata.icon)
    self:SetWndText(itemName, "")
    CS.ShowObject(soldout, false)
    CS.ShowObject(buyIcon, false)
    CS.ShowObject(discountImg, false)
    self:SetWndText(limit, "")

    local commodityId = tonumber(itemdata.commodityId)
    local privilegeRef = gModelNormalActivity:GetBIActivityPrivilegeRewardRefByRefId(commodityId)
    if privilegeRef then
        local privilegeData = gModelNormalActivity:GetPrivilegeGiftListByRefId(privilegeRef.type)
        if privilegeData then
            local refId = privilegeData.refId
            local remainTime = privilegeData.remainTime

            local dataRef = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(refId)
            local giftRef = gModelNormalActivity:GetBIActivityPrivilegeGiftRefByRefId(dataRef.type)
            local expend = string.split(dataRef.expend, "=")

            self:SetWndText(itemName, ccLngText(giftRef.name))
            CS.ShowObject(soldout, remainTime == 0)
            CS.ShowObject(buyIcon, expend[2])

            local isItemCost = string.find(dataRef.expend, "=")
            if isItemCost then
                local itemCost = LxDataHelper.ParseItem_3(dataRef.expend)
                local iconRes = gModelItem:GetItemImgByRefId(itemCost.refId)
                self:SetWndText(buyNum, ccLngText(dataRef.btnText))
            else
                local expendId

                -- 自动付费购买类型，使用expendExtra字段
                local isAuto = gModelNormalActivity:IsAutoGiftMgr(refId)
                if isAuto then
                    expendId = string.isempty(dataRef.expendExtra) and dataRef.expend or dataRef.expendExtra
                else
                    expendId = dataRef.expend
                end

                expendId = tonumber(expendId)

                local valueShow = gModelPay:GetShowByWelfareId(expendId)
                self:SetWndText(buyNum, valueShow)
            end

            --self:SetWndText(buyNum,ccLngText(dataRef.btnText))
            if remainTime >= 0 then
                local color
                if remainTime <= 0 then
                    color = "red"
                else
                    color = "green"
                end
                --local colorStr = string.replace(ccClientText(15905),LUtil.FormatColorStr(remainTime,color))
                --local colorStr = string.replace(ccClientText(15905),remainTime)
                local colorStr = ccClientText(15502) .. remainTime
                self:SetWndText(limit, colorStr)
            end
            if expend[2] then
                local iconStr = gModelItem:GetItemIconByRefId(tonumber(expend[2]))
                self:SetWndEasyImage(buyIcon, iconStr)
            end
            local func = function()
                if remainTime == 0 then
                    GF.ShowMessage(ccClientText(15517))
                    return
                end
                GF.OpenWnd("UIWishPrigeBuyPop", { ref = giftRef })
            end
            self:SetWndClick(bg, function()
                if func then
                    func()
                end
            end)
            self:SetWndClick(buyBtn, function()
                if func then
                    func()
                end
            end)
            self:SetWndClick(icon, function()
                if func then
                    func()
                end
            end)
        end
    end
end

function UIGeay:SetShopItem(item, itemdata)
    --local bg = self:FindWndTrans(item,"bg")
    local itemBg = self:FindWndTrans(item, "itemBg")
    --local itemBgIcon = self:FindWndTrans(itemBg,"Icon")
    local itemName = self:FindWndTrans(item, "itemName")
    local soldout = self:FindWndTrans(item, "soldout")
    --local soldoutIcon = self:FindWndTrans(soldout,"icon")
    local buyBtn = self:FindWndTrans(item, "buyBtn")
    local buyBtnLayout = self:FindWndTrans(buyBtn, "layout")
    local layoutIcon = self:FindWndTrans(buyBtnLayout, "icon")
    local layoutNum = self:FindWndTrans(buyBtnLayout, "num")
    --local buyBtnRedPoint = self:FindWndTrans(buyBtn,"redPoint")
    local DiscountImg = self:FindWndTrans(item, "DiscountImg")
    local DiscountImgText = self:FindWndTrans(DiscountImg, "text")
    local limit = self:FindWndTrans(item, "limit")

    CS.ShowObject(itemBg, false)
    local CommonUI = self:FindWndTrans(item, "CommonUI")
    CS.ShowObject(CommonUI, true)

    local shopId = itemdata.shopId
    local goodsId = itemdata.goodsId

    local itemdata = gModelShop:GetShopItemNetData(shopId, goodsId)
    if not itemdata then
        return
    end
    local goods = gModelShop:GetShopItemCfg(goodsId)
    local rewardData = goods.reward

    local instanceId = item:GetInstanceID()
    local iconTrans = CS.FindTrans(item, "CommonUI/Icon")

    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(iconTrans)
    baseClass:SetCommonReward(rewardData.itemType, rewardData.itemId, rewardData.itemNum)
    baseClass:EnableShowNum(true)
    baseClass:DoApply()

    self:SetIconClickScale(iconTrans, true)
    self:SetWndClick(iconTrans, function()
        gModelGeneral:ShowCommonItemTipWnd(rewardData)
    end)

    --local itemNameCfg =ccLngText(goods.default.itemName)
    --local nameCfg = gModelGeneral:GetCommonItemName(rewardData)
    --self:SetWndText(itemName,nameCfg)

    local isForeign = gLGameLanguage:IsForeignRegion()
    CS.ShowObject(itemName, not isForeign)
    if not isForeign then
        local shopName = gModelShop:GetShopShowName(shopId)
        self:SetWndText(itemName, shopName)
    end

    self:SetWndClick(buyBtn, function()
        self:BuyShopGoods(shopId, goodsId, goods)
    end)

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
    CS.ShowObject(layoutIcon, showIcon)

    local discountCfg = goods.default.fixDiscount
    local hasDis = false
    local str = ccLngText(discountCfg)
    if not string.isempty(str) then
        hasDis = true
        self:SetWndText(DiscountImgText, str)
    end

    CS.ShowObject(DiscountImg, hasDis)

    local limitCfg = goods.limitCount
    local isLimit = false
    local isSoldOut = false
    if limitCfg.itemNum ~= -1 then
        isLimit = true
    end
    if isLimit then
        local pre = ccClientText(gModelShop:GetLimitStr(limitCfg.itemId))
        local hasBuyNum = itemdata:GetHasBuyNum()
        local color
        if hasBuyNum >= limitCfg.itemNum then
            color = "red"
            isSoldOut = true
        else
            color = "green"
        end
        local str = hasBuyNum .. "/" .. limitCfg.itemNum
        local colorStr = pre .. LUtil.FormatColorStr(str, color)
        self:SetWndText(limit, colorStr)
    end
    CS.ShowObject(limit, isLimit)
    CS.ShowObject(soldout, isSoldOut)

    local isUnlock, tip = gModelShop:CheckItemIsUnlock(goodsId)
    if not isUnlock then
        self:SetWndText(limit, tip)
        CS.ShowObject(limit, true)
    end

    self:InitTextModeWithLanguage(limit)
    self:InitTextModeWithLanguage(itemName)

end

function UIGeay:OnClickTabBtn(itemRefId)
    self._itemRefId = itemRefId
    self:RefreshUI()
end

function UIGeay:RefreshUI()
    local refId = self._itemRefId
    local refIdType = self._refIdType
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_ITEM_GOTO, "open", refId)

    local isHero = refIdType == LItemTypeConst.TYPE_HERO
    local ref
    if refIdType == LItemTypeConst.TYPE_ITEM then
        ref = gModelItem:GetRefByRefId(refId)
    elseif isHero then
        ref = gModelHero:GetHeroRef(refId)
    end

    if not ref then
        return
    end

    self._itemRef = ref

    local iconTrans = CS.FindTrans(self.mItemRoot, "CommonUI/Icon")
    local instanceId = iconTrans:GetInstanceID()
    local commonIcon = self._commonIconTbl[instanceId]
    if not commonIcon then
        commonIcon = CommonIcon:New()
        self._commonIconTbl[instanceId] = commonIcon
        commonIcon:Create(iconTrans)
    end
    if isHero then
        local heroStar = self:GetWndArg("heroStar")
        commonIcon:SetHeroConfShowInfo(refId, heroStar)
    else
        commonIcon:SetCommonReward(refIdType, refId, -1)
    end
    commonIcon:EnableShowNum(true)
    commonIcon:DoApply()

    if refIdType == LItemTypeConst.TYPE_ITEM then
        self:GetItemQuickList(ref)
    elseif refIdType == LItemTypeConst.TYPE_HERO then
        CS.ShowObject(self.mQuickPart, false)
        self:ShowNormalPart()
    end

    self:ShowOwn()
    self:ShowTabPart()
end

function UIGeay:ReqData()

    if not self._reqCfgList then
        self._reqCfgList = {}
    end

    for k, v in pairs(self._reqList) do
        for k1, v1 in pairs(v) do
            if k == 1 then

                self._reqCfgList[k1] = true
                gModelActivity:ReqActivityConfigData(k1)
                --gModelActivity:OnActivityPageReq(k1)
            elseif k == 2 then
                gModelShop:ShopListReq(k1)
            end
        end

    end
end

function UIGeay:InitPara()
    self._itemRefId = self:GetWndArg("itemId")
    self._srcWnd = self:GetWndArg("srcWnd") --记录来源界面，如果跳转要打开的界面层级低于原界面，需要关闭原界面
    self._needNum = self:GetWndArg("needNum")

    local refIdType = self:GetWndArg("refIdType")
    if refIdType == nil then
        refIdType = LItemTypeConst.TYPE_ITEM
    end

    self._itemsRefId = self:GetWndArg("itemsRefId")
    self._refIdType = refIdType

    self._jumpCallBackFunc = self:GetWndArg("jumpCallBackFunc")
end
function UIGeay:OnClickGoto(functionId, data)
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_ITEM_GOTO, "goto", self._itemRefId, data.name, data.pos)

    printInfoN(string.format("functionid %s ,srcWnd %s", functionId, self._srcWnd))
    local isOpen = gModelFunctionOpen:CheckIsOpened(functionId, true)
    if not isOpen then
        return
    end

    local jumpCallBackFunc = self._jumpCallBackFunc
    self._jumpCallBackFunc = nil
    if jumpCallBackFunc then
        jumpCallBackFunc()
    end

    gModelFunctionOpen:Jump(functionId, self._srcWnd)
    local jumpBackCB = self:GetWndArg("jumpBackCB")
    if jumpBackCB then
        jumpBackCB()
    end

    GF.CloseWndByName("UIEqWear")
    GF.CloseWndByName("UIGeay")
end

function UIGeay:ShowTabPart()
    local refIdList = self._itemsRefId
    local refIdNum = refIdList and #refIdList or 0
    local isShow = refIdNum > 1
    CS.ShowObject(self.mTabPart, isShow)
    if not isShow then
        return
    end

    local key = "TabBtnList"
    local itemList = self._tabBtnList
    if not itemList then
        itemList = self:GetUIScroll(key)
        itemList:Create(self.mTabList, refIdList, function(...)
            self:OnDrawTabBtn(...)
        end)
        itemList:EnableScroll(true, true)
        self._tabBtnList = itemList
    else
        itemList:RefreshList(refIdList)
    end

    local index = 1
    for k, v in ipairs(self._itemsRefId) do
        if self._itemRefId == v then
            index = k
            break
        end
    end
    local uiList = itemList:GetList()
    uiList:DelayScrollTo(index)
end

function UIGeay:SetActGoods(item, itemdata)
    --local bg = self:FindWndTrans(item,"bg")
    local itemBg = self:FindWndTrans(item, "itemBg")
    local itemBgIcon = self:FindWndTrans(itemBg, "Icon")
    local itemName = self:FindWndTrans(item, "itemName")
    local soldout = self:FindWndTrans(item, "soldout")
    --local soldoutIcon = self:FindWndTrans(soldout,"icon")
    local btnGet = self:FindWndTrans(item, "BtnGet")
    local buyBtn = self:FindWndTrans(item, "buyBtn")
    local buyBtnLayout = self:FindWndTrans(buyBtn, "layout")
    local layoutIcon = self:FindWndTrans(buyBtnLayout, "icon")
    local layoutNum = self:FindWndTrans(buyBtnLayout, "num")
    --local buyBtnRedPoint = self:FindWndTrans(buyBtn,"redPoint")
    local DiscountImg = self:FindWndTrans(item, "DiscountImg")
    --local DiscountImgText = self:FindWndTrans(DiscountImg,"text")
    local limit = self:FindWndTrans(item, "limit")

    local entry = self:GetEntry(itemdata.sid, itemdata.pageId, itemdata.entryId)
    local entryCfg = gModelActivity:GetWebActivityEntryData(itemdata.sid, itemdata.pageId, itemdata.entryId)
    if not entryCfg then
        return
    end
    local activityData = gModelActivity:GetActivityBySid(itemdata.sid)
    local model = activityData.model

    local btnGetStr = ccClientText(28301)
    local isbtnGetGray = false

    if model == ModelActivity.MODEL_ACTIVITY_TYPE_78 then
        local moreInfo = JSON.decode(activityData.moreInfo)
        local buy_record = moreInfo["buy_record_" .. itemdata.entryId] or 0
        local moreInfos = entryCfg.moreInfo and string.split(entryCfg.moreInfo, ";") or {}
        local taskBuyNum = moreInfos[1] and tonumber(moreInfos[1]) or 99
        local bGetState = buy_record >= taskBuyNum
        local MarketData = entry.MarketData
        local personal, personalGoal = MarketData.personal, MarketData.personalGoal
        local last = personalGoal - personal
        if last <= 0 then
            btnGetStr = ccClientText(28302)
            isbtnGetGray = true
        end
        CS.ShowObject(btnGet, bGetState)
        CS.ShowObject(buyBtn, not bGetState)
        self:SetWndButtonGray(btnGet, isbtnGetGray)
        self:SetWndButtonText(btnGet, btnGetStr)
    end

    CS.ShowObject(itemBg, true)
    self:SetWndEasyImage(itemBgIcon, entryCfg.description)

    local isForeign = gLGameLanguage:IsUSARegion()
    CS.ShowObject(itemName, not isForeign)
    if not isForeign then
        local activity = gModelActivity:GetActivityBySid(itemdata.sid)
        local name = activity and activity.title or ""
        self:SetWndText(itemName, name)
    end

    --local marketData = entry.MarketData
    local expend = entryCfg.expend2
    local expend2List = string.split(expend, "=")
    local expendId
    local itemId, btnName, payMoney, isFree
    local showIcon = false
    if #expend2List > 1 then
        btnName = expend2List[3]
        itemId = tonumber(expend2List[2])
        showIcon = true
        local iconImg = gModelItem:GetItemImgByRefId(itemId)
        if iconImg then
            self:SetWndEasyImage(layoutIcon, iconImg)
        end
    else
        expendId = tonumber(expend2List[1])
        if expendId > 0 then
            payMoney = true
            --local rmb = gModelPay:GetRMBValueByWelfareId(expendId)
            btnName = gModelPay:GetShowByWelfareId(expendId) --string.replace(ccClientText(15601),rmb)
        else
            btnName = ccClientText(11913)
            isFree = true
        end
    end

    self:SetWndText(layoutNum, btnName)
    CS.ShowObject(layoutIcon, showIcon)
    local MarketData = entry.MarketData
    local personal, personalGoal = MarketData.personal, MarketData.personalGoal
    local last = personalGoal - personal
    --local str = string.replace(ccClientText(15905),last)
    local str = ccClientText(15502) .. last
    local isSoldOut = last <= 0
    CS.ShowObject(soldout, isSoldOut)
    self:SetWndText(limit, str)
    CS.ShowObject(limit, not isSoldOut)
    CS.ShowObject(DiscountImg, false)

    self:SetWndClick(item, function()
        if model == ModelActivity.MODEL_ACTIVITY_TYPE_78 then
            self:OnClickActivity78(itemdata)
            return
        end
        self:ShowActDetail(itemdata)
    end)

    self:SetWndClick(buyBtn, function()
        if model == ModelActivity.MODEL_ACTIVITY_TYPE_78 then
            self:OnClickActivity78(itemdata)
            return
        end
        self:ShowActDetail(itemdata)
    end)
    self:SetWndClick(btnGet, function()
        if model == ModelActivity.MODEL_ACTIVITY_TYPE_78 then
            self:OnClickActivity78(itemdata)
            return
        end
    end)
end

function UIGeay:OnDrawQuickItem(list, item, itemdata, itempos)
    local btnGet = self:FindWndTrans(item, "BtnGet")
    local buyBtn = self:FindWndTrans(item, "buyBtn")

    CS.ShowObject(btnGet, false)
    CS.ShowObject(buyBtn, true)
    local instanceId = item:GetInstanceID()
    self:DeleteCommonIcon(instanceId)

    local type = itemdata.type
    if type == 1 then
        self:SetActGoods(item, itemdata)
    elseif type == 2 then
        self:SetShopItem(item, itemdata)
    elseif type == 3 then
        self:SetUseItem(item, itemdata)
    elseif type == 4 then
        self:SetPrivilegeItem(item, itemdata)
    end
end
function UIGeay:ShowOwn()
    if self._refIdType == LItemTypeConst.TYPE_ITEM then
        local itemNum = gModelItem:GetNumByRefId(self._itemRefId)
        itemNum = LUtil.NumberCoversion(itemNum)
        local str = string.replace(ccClientText(19801), itemNum)
        self:SetWndText(self.mOwn, str)
    end
end

function UIGeay:ShowActDetail(itemdata)

    local sid, pageId, entryId = itemdata.sid, itemdata.pageId, itemdata.entryId

    local entry = self:GetEntry(sid, pageId, entryId)

    local MarketData = entry.MarketData
    local personal, personalGoal = MarketData.personal, MarketData.personalGoal
    local last = personalGoal - personal
    if last <= 0 then
        GF.ShowMessage(ccClientText(15517))
        return
    end

    local entryCfg = gModelActivity:GetWebActivityEntryData(itemdata.sid, itemdata.pageId, itemdata.entryId)
    if not entryCfg then
        return
    end
    local rewards = LxDataHelper.ParseItem(entryCfg.reward)
    local record = {
        reward = {},
        expend = {}
    }
    for k, v in ipairs(rewards) do
        record.reward[tostring(v.itemId)] = v.itemNum
    end

    local expend = entryCfg.expend2
    local expend2List = string.split(expend, "=")
    local isFree, payMoney, expendId, itemId, itemNum, priceStr

    if #expend2List > 1 then
        itemId = tonumber(expend2List[2])
        itemNum = tonumber(expend2List[3])
        --itemName = gModelItem:GetNameByRefId(itemId)
        priceStr = itemNum

        record.expend[tostring(itemId)] = itemNum
    else
        expendId = tonumber(expend2List[1])
        if expendId > 0 then
            payMoney = true
            local rmb = gModelPay:GetRMBValueByWelfareId(expendId)
            priceStr = gModelPay:GetShowByWelfareId(expendId) --string.replace(ccClientText(15601),rmb)
            record.expend["cny"] = rmb
        else
            record.expend["cny"] = 0
            isFree = true
        end
    end

    local attr1 = JSON.encode(record)
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_ITEM_GOTO, "buy", attr1)

    local buyFun = function()
        if isFree then
            if pageId and entryId then
                gModelActivity:OnActivityMarkeyBuyReq(sid, pageId, entryId)
            end
        else
            if payMoney then
                -- 付费购买
                gModelPay:GiftPayCtrl(entryId, expendId, ModelPay.PAY_TYPE_ACTIVITY, nil, sid, pageId)
            else
                local dia = gModelItem:GetNumByRefId(itemId)
                local value = itemNum
                -- 钻石购买
                local func = function()
                    if dia >= value then
                        gModelActivity:OnActivityMarkeyBuyReq(sid, pageId, entryId)
                    else
                        gModelGeneral:OpenGetWayWnd({ itemId = itemId }, self:GetWndSortLayer())
                    end
                end
                gModelGeneral:OpenUIOrdinTips({ refId = 110006, func = func, para = { priceStr }, consume = { value, itemId } }, true)
            end
        end
    end




    --local activityName = gModelActivity:GetLngNameByActivitySid(sid)
    --local entryName = entry.title

    --local para
    --if isFree then
    --	para ={
    --		refId = 52302,
    --		func=buyFun,
    --		itemList=rewards,
    --		para ={activityName,entryName}
    --	}
    --else
    --	para ={
    --		refId = 52301,
    --		func=buyFun,
    --		itemList=rewards,
    --		para ={priceStr,activityName,entryName}
    --	}
    --end



    GF.OpenWndUp("UIGiftBuyPop", {
        title = entryCfg.name,
        desc = ccClientText(15502) .. last,
        payStr = priceStr,
        payItemId = not isFree and itemId or nil,
        payFunc = buyFun,
        itemList = rewards,
    })


end

function UIGeay:InitData()

    self._actGoodsMap = {}
end

function UIGeay:ShowNormalPart()
    local refIdType = self._refIdType
    ---@type V_HeroRef
    local itemCfg = self._itemRef
    local itemRefId = self._itemRefId
    CS.ShowObject(self.mOwn, true)

    local jumpId = itemCfg.jump
    local itemName, desc
    if refIdType == LItemTypeConst.TYPE_ITEM then
        local ref = gModelItem:GetRefByRefId(itemRefId)
        if ref.type == 9999 then
            CS.ShowObject(self.mOwn, false)
        end
        itemName = gModelItem:GetItemNameRichText(itemRefId)
        desc = ccLngText(itemCfg.description)
    elseif refIdType == LItemTypeConst.TYPE_HERO then
        itemName = gModelHero:GetHeroNameByRefId(itemRefId)
        local qualityRef = gModelHero:GetHeroQualityRefByRefId(itemRefId)
        desc = qualityRef and ccLngText(qualityRef.desc) or ""
        local heroStar = self:GetWndArg("heroStar")
        local heroStarRef = gModelHero:GetHeroStarRef(itemRefId, nil, heroStar)
        if heroStarRef then
            jumpId = heroStarRef.jump
        end
    end
    self:SetWndText(self.mItemName, itemName)
    self:SetWndText(self.mItemDesc, desc)

    local jumpDataList = gModelItem:ParseJump(jumpId)

    local shieldJumpMap = {}
    if gLGameLanguage:IsChinaRegion() and CS.IsWebGL() and LWxHelper.IsWxPlatform() then
        if PRODUCT_G_VER ~= 0 then
            -- 国服 ios 微小 屏蔽储值跳转
            if itemRefId == ModelItem.ITEM_DIAMOND then
                shieldJumpMap[23] = true
            end
        end
    end
    local dataList = {}
    for k, v in ipairs(jumpDataList) do
        if not shieldJumpMap[v.jumpId] then
            local jumpCfg = gModelGeneral:GetJumpConfig(v.jumpId)
            if jumpCfg then
                local data = {}
                data.jumpId = v.jumpId
                data.name = ccLngText(jumpCfg.name)
                data.functionId = jumpCfg.functionId
                data.isOpen = gModelFunctionOpen:CheckIsOpened(data.functionId)
                data.textId = v.textId
                data.index = k
                data.icons = string.split(jumpCfg.icon, '|')
                table.insert(dataList, data)
            end
        end
    end
    table.sort(dataList, function(a, b)
        local aOpen = a.isOpen and 0 or 1
        local bOpen = b.isOpen and 0 or 1
        if aOpen ~= bOpen then
            return aOpen < bOpen
        end

        return a.index < b.index
    end)

    local itemList = self:FindUIScroll("UIItemList")
    if not itemList then
        itemList = self:GetUIScroll("UIItemList")
        itemList:Create(self.mWayList, dataList, function(...)
            self:SetWayItem(...)
        end)
    else
        itemList:RefreshList(dataList)
    end
    if #dataList >= 3 then
        itemList:EnableScroll(true, false)
    end

end

function UIGeay:InitEvent()
    self:WndEventRecv(EventNames.ON_SHOP_DATA_RETURN, function(...)
        self:OnShopDataRet(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:OnActivityDataRet(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PrivilegeGiftResp, function(...)
        self:CheckShow(...)
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityWebData(...)
    end)

    self:WndEventRecv(EventNames.ON_SHOP_BUY_RETURN, function()
        self:CheckShow()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:ShowOwn()

        self:RefreshUI()
    end)
end

function UIGeay:GetEntry(sid, pageId, entryId)
    local pageList = self._activityPageMap and self._activityPageMap[sid]
    if not pageList then
        return
    end
    local page = pageList[pageId]
    if not page then
        return
    end
    return page:GetEntry(entryId)
end

function UIGeay:CheckShow()

    if self._reqList then
        for k, v in pairs(self._reqList) do
            for k1, v1 in pairs(v) do
                if not v1 then
                    return
                end
            end
        end
    end

    local dataList = {}
    for k, v in pairs(self._quickShopList) do
        for k1, v1 in pairs(v) do
            table.insert(dataList, v1)
        end
    end

    for k, v in pairs(self._quickActList) do
        for i, j in ipairs(v) do
            local pageId = j.pageId
            for k1, v1 in ipairs(j.goodsList) do
                local entry = self:GetEntry(k, pageId, v1)
                if entry then
                    local data = {
                        type = 1,
                        sid = k,
                        pageId = pageId,
                        entryId = v1,
                        sort = j.sort,
                        icon = j.icon,
                    }

                    local marketData = entry.MarketData
                    local personal, personalGoal = marketData.personal, marketData.personalGoal
                    data.isLimit = personalGoal <= personal

                    table.insert(dataList, data)
                end
            end
        end
    end

    for k, v in pairs(self._quickUseList) do
        table.insert(dataList, v)
    end
    for i, v in pairs(self._quickPrivilegeList) do
        local commodityId = tonumber(v.commodityId)
        local privilegeRef = gModelNormalActivity:GetBIActivityPrivilegeRewardRefByRefId(commodityId)
        if privilegeRef then
            local isHave = gModelNormalActivity:GetPrivilegeGiftListByRefId(privilegeRef.type)
            if isHave then
                table.insert(dataList, v)
            end
        end
    end

    local hasQuick = #dataList > 0
    if hasQuick then
        table.sort(dataList, function(a, b)
            --if a.type ~= b.type then
            --	return a.type<b.type
            --end
            local isALimit = a.isLimit and 1 or 0
            local isBLimit = b.isLimit and 1 or 0
            if isALimit ~= isBLimit then
                return isALimit < isBLimit
            end

            return a.sort < b.sort
        end)

        local uiList = self:FindUIScroll("quickList")
        if uiList then
            uiList:RefreshList(dataList)
        else
            uiList = self:GetUIScroll("quickList")
            uiList:Create(self.mQuickList, dataList, function(...)
                self:OnDrawQuickItem(...)
            end, UIItemList.WRAP)
        end
        uiList:EnableScroll(#dataList > 3, true)
    end

    CS.ShowObject(self.mQuickPart, hasQuick)
    self:ShowNormalPart()
end

function UIGeay:GetItemQuickList(itemRef)
    local idList = LxDataHelper.ParseNumber_Sign(itemRef.quickBuy, ",")
    --if #idList==0 then
    --	return
    --end
    local _shopId = gModelBackflow:RegressionConfigRefByKey("shopId")
    local quickShopList = {}
    local quickActList = {}
    local quickUseList = {}
    local quickPrivilegeList = {}
    for k, v in ipairs(idList) do
        local ref = gModelItem:GetItemQuickRef(v)
        if ref then
            local type = ref.type

            if type == 1 then
                local strs = string.split(ref.commodityId, "=")
                if #strs >= 3 then
                    local uniqueId = tonumber(strs[1])
                    local pageId = tonumber(strs[2])
                    local goodsList = LxDataHelper.ParseNumber_Sign(strs[3], ",")
                    local sid = gModelActivity:GetSidByUniqueJump(uniqueId)
                    if sid then
                        local activity = gModelActivity:GetActivityBySid(sid)
                        if activity and activity.status ~= 3 then
                            local list = quickActList[sid]
                            if not list then
                                list = {}
                                quickActList[sid] = list
                            end
                            local data = {
                                type = 1,
                                sid = sid,
                                pageId = pageId,
                                goodsList = goodsList,
                                sort = ref.sort,
                                icon = ref.icon,
                            }
                            table.insert(list, data)
                        end
                    end
                end
            elseif type == 2 then
                local shopId = ref.secondaryType
                local shopCfg = gModelShop:GetShopRef(shopId)
                local funcId = shopCfg.functionOpenRefId
                local isOpen = gModelFunctionOpen:CheckIsOpened(funcId, false)
                if isOpen and shopId == _shopId then
                    isOpen = gModelBackflow:GetBackShopIsOpent()
                end
                if isOpen then
                    local goodsId = tonumber(ref.commodityId)
                    local isUnlock, tip = gModelShop:CheckItemIsUnlock(goodsId) --是否解锁
                    if isUnlock then
                        local list = quickShopList[shopId]
                        if not list then
                            list = {}
                            quickShopList[shopId] = list
                        end
                        local data = {
                            type = 2,
                            shopId = shopId,
                            goodsId = goodsId,
                            sort = ref.sort
                        }
                        table.insert(list, data)
                    end
                end
            elseif type == 3 then

                local itemId = tonumber(ref.commodityId)

                if itemId then
                    local itemNum = gModelItem:GetNumByRefId(itemId)
                    if itemNum > 0 then
                        local data = {
                            type = 3,
                            itemId = itemId,
                            itemNum = itemNum,
                            sort = ref.sort,
                        }

                        table.insert(quickUseList, data)
                    end
                end
            elseif type == 4 then
                table.insert(quickPrivilegeList, ref)
            end
        end

    end

    self._quickShopList = quickShopList
    self._quickActList = quickActList
    self._quickUseList = quickUseList
    self._quickPrivilegeList = quickPrivilegeList
    for i, v in pairs(quickPrivilegeList) do
        local commodityId = tonumber(v.commodityId)
        local privilegeRef = gModelNormalActivity:GetBIActivityPrivilegeRewardRefByRefId(commodityId)
        if privilegeRef then
            local isHave = gModelNormalActivity:GetPrivilegeGiftListByRefId(privilegeRef.type)
            if not isHave then
                gModelNormalActivity:OnPrivilegeGiftReq()
                break
            end
        end
    end

    local reqList = {}
    for k, v in pairs(quickActList) do
        local list = reqList[1]
        if not list then
            list = {}
            reqList[1] = list
        end
        list[k] = false
    end

    for k, v in pairs(quickShopList) do
        local list = reqList[2]
        if not list then
            list = {}
            reqList[2] = list
        end
        list[k] = false
    end

    self._reqList = reqList

    if table.isempty(reqList) then
        self:CheckShow()
        return
    end

    self:ReqData()
end

function UIGeay:GetEntryCfg(sid, pageId, entrrId)

end

function UIGeay:OnClickActivity78(itemdata)
    local activityDataW = gModelActivity:GetWebActivityDataById(itemdata.sid)
    local config = activityDataW.config
    local entryCfg = gModelActivity:GetWebActivityEntryData(itemdata.sid, itemdata.pageId, itemdata.entryId)
    local activityDataS = gModelActivity:GetActivityBySid(itemdata.sid)
    local moreInfo = JSON.decode(activityDataS.moreInfo)
    local buy_record = moreInfo["buy_record_" .. itemdata.entryId] or 0
    local moreInfos = entryCfg.moreInfo and string.split(entryCfg.moreInfo, ";") or {}
    local taskBuyNum = moreInfos[1] and tonumber(moreInfos[1]) or 99
    local bGetState = buy_record >= taskBuyNum
    local entry = self:GetEntry(itemdata.sid, itemdata.pageId, itemdata.entryId)
    local MarketData = entry.MarketData
    local personal, personalGoal = MarketData.personal, MarketData.personalGoal
    local last = personalGoal - personal
    local expendId = tonumber(MarketData.expend2)
    if last <= 0 then
        if bGetState then
            GF.ShowMessage(ccClientText(28304))
        else
            GF.ShowMessage(ccClientText(28303))
        end
        return
    end
    if bGetState then
        gModelActivity:OnActivitySpecialOpReq(itemdata.sid, itemdata.pageId, itemdata.entryId, nil, nil, ModelActivity.SUPER_PRIVILEGE_FREE_BUY)
    else
        local callFunc = function()
            gModelPay:GiftPayCtrl(itemdata.entryId, expendId, ModelPay.PAY_TYPE_ACTIVITY, nil, itemdata.sid, itemdata.pageId)
        end
        local rewardList = LxDataHelper.ParseItem(entryCfg.reward)
        local name = entryCfg.name
        local residueTaskNum = taskBuyNum - buy_record
        local dayDesStr = string.replace(config.signTips2, residueTaskNum)
        local payStr = gModelPay:GetShowByWelfareId(expendId)
        GF.OpenWnd("UIGiftBuyPop", {
            title = name,
            desc = dayDesStr,
            payStr = payStr,
            payFunc = callFunc,
            itemList = rewardList,
            sid = itemdata.sid,
            noShowHero = true,
        })
    end
end

function UIGeay:SetUseItem(item, itemdata)
    --local bg = self:FindWndTrans(item,"bg")
    local itemBg = self:FindWndTrans(item, "itemBg")
    --local itemBgIcon = self:FindWndTrans(itemBg,"Icon")
    local itemName = self:FindWndTrans(item, "itemName")
    local soldout = self:FindWndTrans(item, "soldout")
    --local soldoutIcon = self:FindWndTrans(soldout,"icon")
    local buyBtn = self:FindWndTrans(item, "buyBtn")
    local buyBtnLayout = self:FindWndTrans(buyBtn, "layout")
    local layoutIcon = self:FindWndTrans(buyBtnLayout, "icon")
    local layoutNum = self:FindWndTrans(buyBtnLayout, "num")
    --local buyBtnRedPoint = self:FindWndTrans(buyBtn,"redPoint")
    local DiscountImg = self:FindWndTrans(item, "DiscountImg")
    local DiscountImgText = self:FindWndTrans(DiscountImg, "text")
    local limit = self:FindWndTrans(item, "limit")

    CS.ShowObject(itemBg, false)
    local CommonUI = self:FindWndTrans(item, "CommonUI")
    CS.ShowObject(CommonUI, true)

    local rewardData = {
        itemType = CommonIcon.ICON_TYPE_ITEM,
        itemId = itemdata.itemId,
        itemNum = itemdata.itemNum,
    }

    local instanceId = item:GetInstanceID()
    local iconTrans = CS.FindTrans(item, "CommonUI/Icon")

    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(iconTrans)

    baseClass:SetCommonReward(rewardData.itemType, rewardData.itemId, rewardData.itemNum)
    baseClass:EnableShowNum(true)
    baseClass:DoApply()

    self:SetIconClickScale(iconTrans, true)
    self:SetWndClick(iconTrans, function()
        gModelGeneral:ShowCommonItemTipWnd(rewardData)
    end)

    local isForeign = gLGameLanguage:IsForeignRegion()
    CS.ShowObject(itemName, not isForeign)
    if not isForeign then
        local shopName = gModelGeneral:GetCommonItemName(rewardData)
        self:SetWndText(itemName, shopName)
    end

    self:SetWndClick(buyBtn, function()
        --判断下是否为 116类型
        local ref = gModelItem:GetRefByRefId(rewardData.itemId)
        local getType = ref.type

        if getType == ModelItem.Item_ONHOOK then
            gModelGeneral:OpenItemInfoTip(rewardData.itemId)
            return
        end

        if self._needNum and self._needNum >= 0 then
            --构建useInfo
            local info = {}
            local str = self._itemRefId .. "=" .. self._needNum

            --解析下换算的对应的数量
            local datalist = gModelItem:GetTypeDataByRefId(rewardData.itemId)
            local changeNum = 0
            for k, v in ipairs(datalist) do
                if checknumber(v.refId) == self._itemRefId then
                    changeNum = v.num
                    break
                end
            end

            if changeNum == 0 then
                printInfoNR2("道具配置", "配置出错--" .. rewardData.itemId)
                return
            end

            local needNum = math.floor(self._needNum / changeNum)
            local leftNum = self._needNum % changeNum
            if leftNum > 0 then
                needNum = needNum + 1
            end

            --要是数量不足与兑换的话就打开对应的窗口
            if rewardData.itemNum >= needNum then
                local para_1 = needNum
                local para_2 = gModelItem:GetNameByRefId(rewardData.itemId)
                local para_3 = changeNum * needNum
                local para_4 = gModelItem:GetNameByRefId(self._itemRefId)

                gModelGeneral:ShowUIOrdinTipLazy(53502, function()
                    str = self._itemRefId .. "=" .. needNum
                    table.insert(info, { refId = rewardData.itemId, num = needNum, params = str })
                    gModelItem:OnItemUseReq(info)
                    self:WndClose()
                end, { para = { para_1, para_2, para_3, para_4 } })


            else
                gModelGeneral:OpenItemInfoTip(rewardData.itemId)
            end
        else
            gModelGeneral:OpenItemInfoTip(rewardData.itemId)
        end

    end)

    CS.ShowObject(layoutIcon, false)
    self:SetWndText(layoutNum, ccClientText(10230))

    CS.ShowObject(DiscountImg, false)

    CS.ShowObject(limit, false)
    CS.ShowObject(soldout, false)

    self:InitTextModeWithLanguage(itemName)

end

function UIGeay:OnActivityWebData(data, sid)
    if not self._reqCfgList then
        return
    end

    if self._reqCfgList[sid] then
        gModelActivity:OnActivityPageReq(sid)
    end
end

function UIGeay:SaveActivityData(pb)
    local sid = pb.sid
    local list = self._quickActList[sid]
    if list then
        for k, v in ipairs(list) do
            local pageId = v.pageId
            local pageData = pb.pages[pageId]
            local pageStruct = gModelActivity:GenerateActivePageDataFromPb(pageData)

            local activityPageMap = self._activityPageMap
            if not activityPageMap then
                activityPageMap = {}
                self._activityPageMap = activityPageMap
            end
            local pageMap = activityPageMap[sid]
            if not pageMap then
                pageMap = {}
                activityPageMap[sid] = pageMap
            end
            pageMap[pageId] = pageStruct
        end
    end
end
------------------------------------------------------------------
return UIGeay


