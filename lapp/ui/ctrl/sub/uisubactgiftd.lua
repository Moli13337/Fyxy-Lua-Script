---
--- Created by LCM.
--- DateTime: 2024/3/8 21:26:11
---
---活动98--通用礼包
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubActGiftD:LChildWnd
local UISubActGiftD = LxWndClass("UISubActGiftD", LChildWnd)

UISubActGiftD.TYPE_BUY_FREE = 0
UISubActGiftD.TYPE_BUY_ITEM = 1
UISubActGiftD.TYPE_BUY_RMB = 2

UISubActGiftD.SelGiftNum = 3

UISubActGiftD.TYPE_ONLAY_SHOP = 0    --- 有普通奖励，没有自选奖励（默认，没这个字段时取该值）
UISubActGiftD.TYPE_ALL = 1              --- 全都有
UISubActGiftD.TYPE_ONLAY_SEL = 2        --- 有自选奖励，没有普通奖励
local typeOfTextMesh = typeof(CS.TextMeshPro)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubActGiftD:UISubActGiftD()
    self._timerKey = "_timerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubActGiftD:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubActGiftD:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubActGiftD:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self._delayReqTimerKey = "delayActivityGiftDReqConfig"
    self:TimerStart(self._delayReqTimerKey, 0, false, 1)
    
end

function UISubActGiftD:SetCurrencyGroup(itemId)
    local itemIcon = self:FindWndTrans(self.mCurrencyGroup, "Icon")
    local num = self:FindWndTrans(self.mCurrencyGroup, "Num")
    itemId = itemId and tonumber(itemId) or self.currencyItemId
    self.currencyItemId = itemId
    local icon = gModelItem:GetItemImgByRefId(itemId)
    local itemNum = gModelItem:GetNumByRefId(itemId)
    self:SetWndEasyImage(itemIcon, icon)
    local numStr = LUtil.NumberCoversion(itemNum)
    self:SetWndText(num, numStr)
    -- self:SetWndClick(self.mCurrencyGroup, function()
    --     gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = "WndChildConstellationStoreGashapon" })
    -- end)
end

function UISubActGiftD:InitRewardList(trans, list, canScroll)
    if canScroll == nil then
        canScroll = false
    end
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawItemCell(...)
        end)
        uiList:EnableScroll(canScroll, true)
    end
end

function UISubActGiftD:OnClickHelpBtnFunc()
    if not self._title or not self._helpTipsContent then
        return
    end

    local para = {
        title = self._title,
        text = self._helpTipsContent
    }
    GF.OpenWnd("UIBzTips", para)
end

function UISubActGiftD:StarCountDown()
    if not self._endTime then
        self:SetWndText(self.mCountDonwTxt, "")
        CS.ShowObject(self.mCountDownDiv, false)
        self:TimerStop(self._timerKey)
        return
    end
    local lastTime = self._endTime - GetTimestamp()
    local str = nil
    if lastTime < 0 then
        str = ccClientText(14301)
        self:TimerStop(self._timerKey)
        self._isEnd = true
    else
        local timeStr = LUtil.FormatTimespanCn(lastTime)
        --timeStr = LUtil.FormatColorStr(timeStr,"green")
        --str = string.replace(ccClientText(21405),timeStr)
        str = string.replace(ccClientText(11637), timeStr)
    end
    str = LUtil.FormatColorStr(str, self._timeTextColor)
    self:SetWndText(self.mCountDonwTxt, str)

    CS.ShowObject(self.mCountDownDiv, true)
end

function UISubActGiftD:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        self:OnActivityResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function(pb)
        self:SetCurrencyGroup()
    end)
    -- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISubActGiftD:OnDrawSelGiftCell(list, item, itemdata, itempos)
    local CustomTrans = self:FindWndTrans(item, "Custom")
    local ImmobilizationTrans = self:FindWndTrans(item, "Immobilization")
    local isSel = itemdata.isSel
    CS.ShowObject(CustomTrans, isSel)
    CS.ShowObject(ImmobilizationTrans, not isSel)
    local height = item.sizeDelta.y
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
    if isSel then
        self:CreateCustom(CustomTrans, itemdata)
    else
        self:CreateImmobilization(ImmobilizationTrans, itemdata)
    end
end

function UISubActGiftD:OnActivityResp(pb)
    if self._sid ~= pb.sid then
        return
    end
end

-------------------------------- 花费类型 ----------------------------------------
function UISubActGiftD:IsSellOut(itemdata)
    local buyNum = itemdata.buyNum
    return buyNum < 1
end
-------------------------------- 花费类型 ----------------------------------------


-------------------------------- 通用购买逻辑 ----------------------------------------
function UISubActGiftD:CommonBuyFunc(itemdata, expendType)
    local callFunc, setTextStr, itemId
    local pageId, entryId = itemdata.pageId, itemdata.entryId
    if LOG_INFO_ENABLED then
        printInfoNR("pageId = " .. pageId .. ",entryId = " .. entryId .. ",expendType = " .. expendType)
    end
    if expendType == UISubActGiftD.TYPE_BUY_FREE then
        callFunc = function()
            gModelActivity:OnActivityMarkeyBuyReq(self._sid, pageId, entryId)
        end
        setTextStr = ccClientText(11913)
    elseif expendType == UISubActGiftD.TYPE_BUY_ITEM then
        local expend2 = itemdata.expend2
        local expend2List = string.split(expend2, "=")
        itemId = tonumber(expend2List[2])
        local needItemNum = tonumber(expend2List[3])
        callFunc = function()
            local dia = gModelItem:GetNumByRefId(itemId)
            local itemName = gModelItem:GetNameByRefId(itemId)
            -- 钻石购买
            local func = function()
                if dia >= needItemNum then
                    gModelActivity:OnActivityMarkeyBuyReq(self._sid, pageId, entryId)
                else
                    gModelGeneral:OpenGetWayWnd({ itemId = itemId })
                end
            end
            GF.OpenWnd("UIOrdinTip", { refId = 110005, func = func, para = { needItemNum .. itemName }, consume = { needItemNum, itemId } })
        end
        setTextStr = needItemNum
    elseif expendType == UISubActGiftD.TYPE_BUY_RMB then
        local expendId = tonumber(itemdata.expend2)
        setTextStr = gModelPay:GetShowByWelfareId(expendId)
        callFunc = function()
            gModelPay:GiftPayCtrl(entryId, expendId, ModelPay.PAY_TYPE_ACTIVITY, nil, self._sid, pageId)
        end
    end
    local isFreeBuy = expendType == UISubActGiftD.TYPE_BUY_FREE
    local buyNum = itemdata.buyNum
    local buyCountText = string.replace(ccClientText(23803), buyNum)
    local showItemList
    if itemdata.isSel then
        showItemList = itemdata.getItemList
    else
        showItemList = itemdata.fixReward
    end
    GF.OpenWnd("UIGiftBuyPop", {
        title = itemdata.title,
        desc = buyCountText,
        payStr = setTextStr,
        payItemId = not isFreeBuy and itemId or nil,
        payFunc = callFunc,
        itemList = showItemList,
        personalGoal = itemdata.personalGoal
    })
end

function UISubActGiftD:OnTimer(key)
    if key == self._delayReqTimerKey then
        self:TimerStop(self._delayReqTimerKey)
        gModelActivity:ReqActivityConfigData(self._sid)
    end
end
-------------------------------- 定制礼包 ----------------------------------------


-------------------------------- 商品条目数据 ----------------------------------------
function UISubActGiftD:CreateImmobilization(item, itemdata)
    local giftTransName
    for i = 1, UISubActGiftD.SelGiftNum do
        local data = itemdata[i]
        local showGift = data ~= nil
        giftTransName = "Gift" .. i .. "/BtnRoot"
        local giftTrans = self:FindWndTrans(item, giftTransName)
        if showGift and giftTrans then
            self:CreateGfit(giftTrans, data)
        end
        CS.ShowObject(giftTrans.parent, showGift)
    end
end
-------------------------------- 花费类型 ----------------------------------------

-------------------------------- 花费类型 ----------------------------------------
function UISubActGiftD:GetPayType(expendType, expend2)
    local txt
    local showIconImg = false
    local iconImg
    if expendType == UISubActGiftD.TYPE_BUY_FREE then
        txt = ccClientText(11913)
    elseif expendType == UISubActGiftD.TYPE_BUY_ITEM then
        showIconImg = true
        local expend2Info = string.split(expend2, "=")
        local itemId = tonumber(expend2Info[2])
        iconImg = gModelItem:GetItemIconByRefId(itemId)
        txt = tonumber(expend2Info[3])
    elseif expendType == UISubActGiftD.TYPE_BUY_RMB then
        txt = gModelPay:GetShowByWelfareId(tonumber(expend2))
    end
    return txt, showIconImg, iconImg
end

function UISubActGiftD:OnActivityConfigData(data, sid)
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

    self._giftOptional = tonumber(config.giftOptional)

    if (config.itemId) then
        self:SetCurrencyGroup(config.itemId)
    end
    CS.ShowObject(self.mCurrencyGroup, config.itemId ~= nil)
    self:TimerStop(self._timerKey)

    local color = config.timeTxtColor or "ffffff"
    self._timeTextColor = "#" .. color

    local showEndTime = config.endTime or 0
    local showEnd = showEndTime == 1
    if showEnd then
        local endTime = activityData.endTime
        if endTime == 0 then
            -- 永久生效
            self:SetWndText(self.mCountDonwTxt, "")
            showEnd = false
        else
            self._endTime = endTime
            local para = {
                key = self._timerKey,
                interval = 1,
                loopcnt = -1,
                callOnStart = true,
                func = function()
                    self:StarCountDown()
                end
            }
            self:TimerStartImpl(para)
        end
    end

    if not string.isempty(config.endTimePosition) then
        local pos = LxDataHelper.ParseVector2NotEmpty(config.endTimePosition)
        self:SetAnchorPos(self.mCountDownDiv, pos)
    end

    CS.ShowObject(self.mCountDownDiv, showEnd)

    local image = config.image
    if LxUiHelper.IsImgPathValid(image) then
        self:SetWndEasyImage(self.mGiftViewBg, image)
    end

    local descIcon = config.descIcon
    if LxUiHelper.IsImgPathValid(descIcon) then
        self:SetWndEasyImage(self.mGiftTitleImg, descIcon, function()
            CS.ShowObject(self.mGiftTitleImg, true)
        end, true)
    end

    local descIconPosition = config.descIconPosition
    if not string.isempty(descIconPosition) then
        self:SetAnchorPos(self.mGiftTitleImg, LxDataHelper.ParseVector2NotEmpty(descIconPosition))
    end

    local endTimePosition = config.endTimePosition
    if not string.isempty(endTimePosition) then
        self:SetAnchorPos(self.mCountDownDiv, LxDataHelper.ParseVector2NotEmpty(endTimePosition))
    end

    local helpTips = config.helpTips or 0
    local showHelpBtn = helpTips == 1
    if showHelpBtn then
        local helpTipsPosition = config.helpTipsPosition
        if not string.isempty(helpTipsPosition) then
            self:SetAnchorPos(self.mHelpDiv, LxDataHelper.ParseVector2NotEmpty(helpTipsPosition))
        end
    end
    CS.ShowObject(self.mHelpDiv, showHelpBtn)

    self._title = activityData.title
    self._helpTipsContent = config.helpTipsContent
    self:ShowActivityHero(self.mRolepart, config.ImageHero, config.ImageHeroPos)

    local isTurnRolepart = config.ImageHeroTurn and config.ImageHeroTurn == 1
    local rolePartScaleX = isTurnRolepart and -1 or 1
    self.mRolepart.localScale = Vector3(rolePartScaleX, 1, 1)
    self:ShowActivityHero(self.mRolepart, config.ImageHero, config.ImageHeroPos)


    --记录下对应的状态位置 -- cell使用
    self._cellBg = config.cellBg

    local cellTxtColor = config.cellTxtColor or "ffffff"
    self._cellTxtColor = "#" .. cellTxtColor

    --cell 按钮部分
    self._cellBtnImage = config.cellBtnImage

    --免费按钮特效
    self._cellBtnFx = config.cellBtnFx
    local cellBtnTxtColor = config.cellBtnTxtColor or "ffffff"
    self._cellBtnTxtColor = "#" .. cellBtnTxtColor

    local cellBtnTxtColorLine = config.cellBtnTxtColorLine
    if not string.isempty(cellBtnTxtColorLine) then
        self._cellBtnTxtColorLine = "SourceHanSerifCN_" .. cellBtnTxtColorLine
    end

    gModelActivity:OnActivityPageReq(sid)
end

function UISubActGiftD:OnDrawItemCell(list, item, itemdata, itempos)
    self:CreateItemShow(item, itemdata, {
        clickFunc = function()
            if itemdata.customType then
                if itemdata.status then
                    gModelGeneral:ShowCommonItemTipWnd(itemdata)
                    return
                end
                self:OpenCustomSelectWnd({
                    sid = self._sid,
                    pageId = itemdata.pageId,
                    entryId = itemdata.entryId,
                    itemIndex = itemdata.index,
                    giftData = itemdata,
                    title = itemdata.title,
                })
            else
                self:OpenCommonItemTipsWnd(itemdata)
            end
        end,
        isChange = not itemdata.isEmpty,
    })
end

function UISubActGiftD:InitData()
    local sid = self:GetWndArg("sid")
    local subPage = self:GetWndArg("subPage")
    if subPage then
        sid = gModelActivity:GetSidByUniqueJump(subPage)
    end
    self._sid = sid
end

function UISubActGiftD:OpenCommonItemTipsWnd(itemdata)
    gModelGeneral:ShowCommonItemTipWnd(itemdata)
end
-------------------------------- 定制礼包 ----------------------------------------
function UISubActGiftD:CreateCustom(item, itemdata)
    local OverImgTrans = self:FindWndTrans(item, "OverImg")

    local RewardMaskTrans = self:FindWndTrans(item, "RewardMask")
    local RewardDivTrans = self:FindWndTrans(RewardMaskTrans, "RewardDiv")

    local FixRewardListTrans = self:FindWndTrans(RewardDivTrans, "FixRewardList")
    local GameObjectTrans = self:FindWndTrans(RewardDivTrans, "GameObject")
    local RewardListTrans = self:FindWndTrans(RewardDivTrans, "RewardList")

    local AddImgTrans = self:FindWndTrans(item, "Image")

    local DiscountImgTrans = self:FindWndTrans(item, "DiscountImg")
    local DiscountTxtTrans = self:FindWndTrans(DiscountImgTrans, "DiscountTxt")

    local BuyBtnTrans = self:FindWndTrans(item, "BuyBtn")
    local AutoDivTrans = self:FindWndTrans(BuyBtnTrans, "AutoDiv")
    local IconImgTrans = self:FindWndTrans(AutoDivTrans, "Image")
    local BtnTxtTrans = self:FindWndTrans(AutoDivTrans, "Txt")
    local EffTrans = self:FindWndTrans(BuyBtnTrans, "Eff")

    local CountDownTxtTrans = self:FindWndTrans(item, "CountDownTxt")

    local TxtBgTrans = self:FindWndTrans(item, "TxtBg")
    local TxtTrans = self:FindWndTrans(TxtBgTrans, "Txt")

    self:SetWndEasyImage(TxtBgTrans, itemdata.icon)

    --设置标题颜色

    local str = LUtil.FormatColorStr(itemdata.title, self._cellTxtColor)
    self:SetWndText(TxtTrans, str)
    if gLGameLanguage:IsJapanRegion() then
        local isDmm = gLSdkImpl:CallMethod(LSdkMethod.IsDMMPlatform)
        if  isDmm and gLGameLanguage:IsJapanRegion() then
            self:SetWndTextMat(BtnTxtTrans, "SourceHanSerifJPBold_000000_2")
        end
    end


    --设置背景
    if LxUiHelper.IsImgPathValid(self._cellBg) then
        self:SetWndEasyImage(item, self._cellBg, nil, true)
    end

    local _cellBg  = self._pageData[itemdata.entryId]
    if LxUiHelper.IsImgPathValid(_cellBg) then
        self:SetWndEasyImage(item, _cellBg, nil, true)
    end

    --按钮样式
    if LxUiHelper.IsImgPathValid(self._cellBtnImage) then
        self:SetWndEasyImage(BuyBtnTrans, self._cellBtnImage, nil, true)
    end

    --设置外描边
    if not string.isempty(self._cellBtnTxtColorLine) then
        self:SetWndTextMat(BtnTxtTrans, self._cellBtnTxtColorLine)
    end

    local fixReward = itemdata.fixReward or {}
    local fixRewardLen = #fixReward
    local fixRewardEmpty = fixRewardLen < 1

    local buyNum = itemdata.buyNum

    local isNotLimit = itemdata.personLimit == -1
    local isEmpty = buyNum < 1 and (not isNotLimit)
    local show = not isEmpty

    local customGiftList = self:GetCustomList(itemdata.customGiftList, isEmpty)
    local customGiftLen = #customGiftList
    local haveGift = customGiftLen > 0
    CS.ShowObject(AddImgTrans, haveGift)
    CS.ShowObject(RewardListTrans, haveGift)
    if not fixRewardEmpty then
        self:InitRewardList(FixRewardListTrans, fixReward)
    end
    CS.ShowObject(FixRewardListTrans, not fixRewardEmpty)
    CS.ShowObject(GameObjectTrans, customGiftLen ~= 0)

    if haveGift then
        self:InitRewardList(RewardListTrans, customGiftList, customGiftLen > 3)
    end
    --CS.ShowObject(GameObjectTrans,customGiftLen>0)

    local showDis = false
    if show then
        local buyCountText = string.replace(ccClientText(20810), buyNum)
        self:SetWndText(CountDownTxtTrans, buyCountText)

        local expendType = itemdata.expendType
        local expend2 = itemdata.expend2
        local txt, showIconImg, iconImg = self:GetPayType(expendType, expend2)
        if iconImg then
            self:SetWndEasyImage(IconImgTrans, iconImg)
        end
        CS.ShowObject(IconImgTrans, showIconImg)

        txt = LUtil.FormatColorStr(txt, self._cellBtnTxtColor)
        self:SetWndText(BtnTxtTrans, txt)

        local isFree = expendType == UISubActGiftD.TYPE_BUY_FREE

        local effName = self._cellBtnFx

        if string.isempty(effName) then
            effName = "fx_anniu_02"
        end

        if isFree then
            local effKey = EffTrans:GetInstanceID()
            self:CreateWndEffect(EffTrans, effName, effKey, 100, false, false, 10)
        end
        CS.ShowObject(EffTrans, isFree)

        local discount = itemdata.discount
        showDis = discount > 0
        if showDis then
            self:SetWndText(DiscountTxtTrans, discount .. "%")
        end

        self:SetWndClick(BuyBtnTrans, function()
            self:OnClickCustomBtnFunc(itemdata)
        end)
    end
    CS.ShowObject(DiscountImgTrans, showDis)
    CS.ShowObject(OverImgTrans, isEmpty)
    CS.ShowObject(BuyBtnTrans, show)
    CS.ShowObject(CountDownTxtTrans, show and (not isNotLimit))
end

function UISubActGiftD:GetSelGiftList()
    local list = {}

    local giftOptional = self._giftOptional or UISubActGiftD.TYPE_ONLAY_SHOP
    local showShop = false
    local showSel = false
    if giftOptional == UISubActGiftD.TYPE_ALL then
        showShop = true
        showSel = true
    else
        showShop = giftOptional == UISubActGiftD.TYPE_ONLAY_SHOP
        showSel = giftOptional == UISubActGiftD.TYPE_ONLAY_SEL
    end

    --- 商品
    if showShop then
        local shopList = self:GetShopServerDataList()
        for i, v in ipairs(shopList) do
            table.insert(list, v)
        end
    end

    --- 定制礼包
    if showSel then
        local selGiftList = self:GetSelGiftServerDataList()
        for i, v in ipairs(selGiftList) do
            table.insert(list, v)
        end
    end

    return list
end

function UISubActGiftD:GetShopServerDataList()
    local activityData = self._activityData
    if not activityData then
        return {}
    end
    local shopPageId = ModelActivity.DAILY_GIFT_D_SHOPID
    local activCfg = gModelActivity:GetWebActivityDataById(self._sid)
    local itemCfgs = nil
    if activCfg.chunk and activCfg.chunk[shopPageId] then
        itemCfgs = activCfg.chunk[shopPageId].entries
    end
    local player = gModelPlayer:GetPlayerLv()
    local shopAllList = {}
    local shopServerDataList = activityData[shopPageId] or {}
    for i, v in ipairs(shopServerDataList) do
        local moreInfo = string.split(v.moreInfo, ";")
        local itemRef = itemCfgs and itemCfgs[v.entryId]
        local showLv = tonumber(moreInfo[2]) or 0
        if player >= showLv then
            local valuePercent = moreInfo[3]
            local typeId = tonumber(moreInfo[4])        -- 类型ID=礼包卡底资源图=售卖文本字色=售卖文本描边色
            local MarketData = v.MarketData
            local buyNum = v.buyNum
            local sellOut = buyNum > 0 and 1 or 0

            local commonGiftList = {}
            for idx, val in ipairs(v.items) do
                local curData = {
                    itemId = val.itemId,
                    itemType = val.itemType,
                    itemNum = val.itemNum,
                    notShowTips = true, --点击不显示道具tips，直接打开详情弹窗
                }
                table.insert(commonGiftList, curData)
            end

            table.insert(shopAllList, {
                isSel = false,
                fixReward = v.items,
                entryId = v.entryId,
                sort = v.sort,
                title = v.title,
                pageId = shopPageId,
                expend1 = MarketData.expend1,
                expend2 = MarketData.expend2,
                personal = v.personal,
                personalGoal = v.personalGoal,
                buyNum = buyNum,
                sellOut = sellOut,
                moreInfo = v.moreInfo,
                showLv = showLv,
                valuePercent = valuePercent,
                typeId = typeId,
                desc = v.desc,
                expendType = MarketData.expendType,
                commonGiftList = commonGiftList,
                canBuyMore = not string.isempty(itemRef.canBuyMore) and itemRef.canBuyMore or 0,
                condResetType = MarketData.condResetType,
            })
        end
    end

    local shopList = {}
    local index = 1
    for i, v in ipairs(shopAllList) do
        local indexList = shopList[index]
        if not indexList then
            indexList = {}
            shopList[index] = indexList
        end
        table.insert(indexList, v)
        if i % UISubActGiftD.SelGiftNum == 0 then
            index = index + 1
        end
    end
    return shopList
end
-------------------------------- 通用购买逻辑 ----------------------------------------

------------------------- List -------------------------
function UISubActGiftD:GetSelGiftServerDataList()
    local activityData = self._activityData
    if not activityData then
        return {}
    end
    -- local actiCfg = gModelActivity:GetWebActivityDataById(self._sid)

    local selGiftPageId = ModelActivity.DAILY_GIFT_D_SELGIFTID
    local selGiftList = {}
    local selGiftServerDataList = activityData[selGiftPageId] or {}
    local playerLv = gModelPlayer:GetPlayerLv()
    for i, v in ipairs(selGiftServerDataList) do
        local MarketData = v.MarketData
        local moreInfo = not string.isempty(v.moreInfo) and string.split(v.moreInfo,",")
        if not moreInfo or (moreInfo and tonumber(moreInfo[1]) <= playerLv and playerLv <= tonumber(moreInfo[2]))  then
            local customListStr = string.split(MarketData.customList, "|")
            local customList = LxDataHelper.ParseItem(MarketData.customList)
            local len = #customListStr
            local customGiftList = LxDataHelper.ParseItem(MarketData.customGift) or {}
            local entryId = v.entryId
            local title = v.title
            local items = v.items
            local buyNum = v.buyNum
            local sellOut = buyNum > 0 and 1 or 0
            local getItemList = {}
            for idx, val in ipairs(items) do
                table.insert(getItemList, val)
            end
            for idx = 1, len do
                local curData = customGiftList[idx]
                if not curData then
                    customGiftList[idx] = {
                        isEmpty = true,
                        itemId = 0,
                        itemNum = -1,
                    }
                else
                    table.insert(getItemList, curData)
                end
                    customGiftList[idx].pageId = selGiftPageId
                    customGiftList[idx].entryId = entryId
                    customGiftList[idx].title = title
                    customGiftList[idx].index = idx
                    customGiftList[idx].selList = customList
                    customGiftList[idx].MarketData = MarketData
                    customGiftList[idx].isSel = true
                    customGiftList[idx].canSel = buyNum > 0
                end
                table.insert(selGiftList, {
                    isSel = true,
                    customGiftList = customGiftList,
                    fixReward = items,
                    entryId = entryId,
                    sort = v.sort,
                    title = title,
                    pageId = selGiftPageId,
                    icon = v.icon,
                    personal = v.personal,
                    personalGoal = v.personalGoal,
                    buyNum = buyNum,
                    expend1 = MarketData.expend1,
                    expend2 = MarketData.expend2,
                    expendType = MarketData.expendType,
                    sellOut = sellOut,
                    discount = MarketData.discount,
                    getItemList = getItemList,
                    personLimit=v.personLimit,
                    moreInof = MarketData.moreInfo,
                })
            end
        end
    return selGiftList
end

function UISubActGiftD:GetCustomList(customGiftList, status)
    local list = {}
    for i, v in ipairs(customGiftList or {}) do
        v.status = status
        v.customType = true
        table.insert(list, v)
    end
    return list
end

function UISubActGiftD:InitEvent()
    self:SetWndClick(self.mHelpBtn, function()
        self:OnClickHelpBtnFunc()
    end)
end
function UISubActGiftD:DoBatchBuy(itemdata)
	local goodsData = {}
	goodsData.personalGoal = itemdata.personalGoal
	goodsData.personal = itemdata.personal
	local list = LxDataHelper.ParseItem(itemdata.expend2)
	goodsData.price = {itemPrices=list}

	goodsData.sid = self._sid
	goodsData.pageId = itemdata.pageId
	goodsData.entryId = itemdata.entryId

	goodsData.item = itemdata.fixReward[1]
	goodsData.resetType = itemdata.condResetType

	GF.OpenWnd("UIDianBuy",{goodsData =goodsData,shopType = ModelShop.ACTIVITY, bSupportMultiPrice = true})
end

function UISubActGiftD:CreateGfit(item, itemdata)
    local BgImgTrans = self:FindWndTrans(item, "BgImg")
    local BgTrans = self:FindWndTrans(item, "Bg")
    local BuyCountTrans = self:FindWndTrans(item, "BuyCount")
    local titleTrans = self:FindWndTrans(item, "title")

    local btnTrans = self:FindWndTrans(item, "btn")
    local btnTextTrans = self:FindWndTrans(btnTrans, "text")

    local btn1Trans = self:FindWndTrans(item, "btn1")
    local ContentTrans = self:FindWndTrans(btn1Trans, "Content")
    local IconImageTrans = self:FindWndTrans(ContentTrans, "Image")
    local btn1Text1Trans = self:FindWndTrans(ContentTrans, "text1")

    local rewardList1Trans = self:FindWndTrans(item, "rewardList1")
    local rewardList2Trans = self:FindWndTrans(item, "rewardList2")

    local DiscountImgTrans = self:FindWndTrans(item, "DiscountImg")
    local DiscountTxtTrans = self:FindWndTrans(DiscountImgTrans, "DiscountTxt")

    local redPointTrans = self:FindWndTrans(item, "redPoint")

    local EffRootTrans = self:FindWndTrans(item, "EffRoot")

    local ShowZSImgTrans = self:FindWndTrans(item, "ShowZSImg")
    local ZSNumTrans = self:FindWndTrans(ShowZSImgTrans, "ZSNum")

    local maskTrans = self:FindWndTrans(item, "mask")
    local ShowTrans = self:FindWndTrans(item, "Show")

    local buyNum = itemdata.buyNum
    local valuePercent = itemdata.valuePercent            -- 价格百分比
    local isHave = not string.isempty(valuePercent) and buyNum > 0 or false
    if isHave then
        local show = true
        if valuePercent == "0" then
            show = false
        end
        if show then
            self:SetWndText(DiscountTxtTrans, valuePercent)
        end
        isHave = show
    end
    CS.ShowObject(DiscountImgTrans, isHave)

    local dataTableData = string.split(itemdata.moreInfo, ";")
    local zsNum = tonumber(dataTableData[5])
    local showZSImg = zsNum and zsNum ~= 0 or false
    if showZSImg then
        self:SetWndText(ZSNumTrans, zsNum)
    end
    CS.ShowObject(ShowZSImgTrans, showZSImg)

    self:SetWndEasyImage(BgTrans, itemdata.desc, function()
        CS.ShowObject(BgTrans, true)
    end, true)

    local buyCountText = string.replace(ccClientText(20810), buyNum)
    self:SetWndText(BuyCountTrans, buyCountText)
    self:SetWndText(titleTrans, itemdata.title)
    CS.ShowObject(BuyCountTrans, itemdata.personalGoal ~= -1)
    local itemList = itemdata.commonGiftList
    local showMaxList = #itemList > 3
    local RewardList = showMaxList and rewardList2Trans or rewardList1Trans
    local hideRewardListTrans = showMaxList and rewardList1Trans or rewardList2Trans
    CS.ShowObject(RewardList, true)
    CS.ShowObject(hideRewardListTrans, false)
    self:InitRewardList(RewardList, itemList, showMaxList)

    local itemFunc
    local showBtnTrans = false
    local showBtn1Trans = false
    local buyEmpty = buyNum <= 0 and itemdata.personalGoal ~= -1
    if not buyEmpty then
        local expendType
        local expend2 = itemdata.expend2
        if expend2 == "-1" then
            expendType = UISubActGiftD.TYPE_BUY_FREE
            showBtnTrans = true
            self:SetWndText(btnTextTrans, ccClientText(11913))
        else
            local expend2List = string.split(expend2, "=")
            if #expend2List > 1 then
                expendType = UISubActGiftD.TYPE_BUY_ITEM
                showBtn1Trans = true
                local itemId = tonumber(expend2List[2])
                local itemNum = tonumber(expend2List[3])
                local icon = gModelItem:GetItemImgByRefId(itemId)
                self:SetWndEasyImage(IconImageTrans, icon)
                self:SetWndText(btn1Text1Trans, LUtil.NumberCoversion(itemNum))
            else
                expendType = UISubActGiftD.TYPE_BUY_RMB
                showBtnTrans = true
                local payMoney = gModelPay:GetShowByWelfareId(tonumber(expend2))
                self:SetWndText(btnTextTrans, payMoney)
            end
        end

        local InstanceID = EffRootTrans:GetInstanceID()
        CS.ShowObject(redPointTrans, false)
        self:DestroyWndEffectByKey(InstanceID)
        if expendType == UISubActGiftD.TYPE_BUY_FREE then
            --self:CreateWndEffect_Ex({
            --    trans = EffRootTrans,
            --    effKey = InstanceID,
            --    effName = "fx_libaomianfeilingqu",
            --    scale = Vector3(100, 100, 100)
            --})
            --
            CS.ShowObject(redPointTrans, true)
        end
        itemFunc = function()
            self:OnClickGiftBtnFunc(itemdata, expendType)
        end
    end

    self:SetWndClick(item, function()
        if itemFunc then
            itemFunc()
        end
    end)
    CS.ShowObject(btnTrans, showBtnTrans)
    CS.ShowObject(btn1Trans, showBtn1Trans)
    CS.ShowObject(ShowTrans, buyEmpty)
    CS.ShowObject(maskTrans, buyEmpty)
end

function UISubActGiftD:OnActivityPageResp(pb)
    if self._sid ~= pb.sid then
        return
    end
    local activityData = self._activityData
    if not activityData then
        activityData = {}
        self._activityData = activityData
    end
    local sid = self._sid
    local page, pageId, entryId, items, goalData
    local entryCfg, MarketData
    local moreInfo, personal, personalGoal, buyNum, sellOut
    local pages = pb.pages or {}

    self._pageData ={}


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
                buyNum = personalGoal - personal
                sellOut = (buyNum > 0 or personalGoal == -1) and 1 or 0
                moreInfo = entryCfg.moreInfo
                items = LxDataHelper.ParseItem(entryCfg.reward)
                goalData = val.goalData
                table.insert(pageEntryList, {
                    entryId = entryId,
                    pageId = pageId,
                    title = entryCfg.name,
                    desc = entryCfg.description,
                    icon = entryCfg.icon,
                    items = items,
                    goalData = goalData,
                    status = goalData.status,
                    MarketData = MarketData,
                    moreInfo = moreInfo,
                    personalGoal = personalGoal,
                    personal = personal,
                    buyNum = buyNum,
                    sellOut = sellOut,
                    sort = entryCfg.sort,
                    jumpId = entryCfg.jumpId,
                    jumpDesc = entryCfg.jumpDesc,
                    personLimit = entryCfg.personLimit
                })

                self._pageData[entryId] =entryCfg.description
            end
        end
        activityData[pageId] = pageEntryList


    end

    local sortFunc = function(a, b)
        local sellOutA, sellOutB = a.sellOut, b.sellOut
        if sellOutA ~= sellOutB then
            return sellOutA > sellOutB
        end
        return a.sort < b.sort
    end
    for tPageId, entryList in pairs(activityData) do
        table.sort(entryList, sortFunc)
    end

    self:InitSelGiftList()
end

function UISubActGiftD:OnClickGiftBtnFunc(itemdata, expendType)
    if self:IsSellOut(itemdata) and itemdata.personalGoal ~= -1 then
        GF.ShowMessage(ccClientText(20811))
        return
    end
    local buyMore = itemdata.canBuyMore
    if buyMore and buyMore>0 then
        self:DoBatchBuy(itemdata)
    else
        self:CommonBuyFunc(itemdata, expendType)
    end
end

function UISubActGiftD:OpenCustomSelectWnd(argList)
    GF.OpenWnd("UICumSelectNew", argList)
end

function UISubActGiftD:CreateItemShow(trans, itemdata, extraData)
    local IconTrans = self:FindWndTrans(trans, "itemRoot/Icon")
    local itemNumTrans = self:FindWndTrans(trans, "itemNum")
    local ShiftTrans = self:FindWndTrans(trans, "Shift")
    local EffTrans = self:FindWndTrans(trans, "Eff")

    local itemNum = itemdata.itemNum
    local instanceID = IconTrans:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    local showItemNum = itemNum > 0
    if showItemNum then
        self:SetWndText(itemNumTrans, LUtil.NumberCoversion(itemNum))
    end
    CS.ShowObject(itemNumTrans, showItemNum)

    extraData = extraData or {}
    local isChange = extraData.isChange
    CS.ShowObject(ShiftTrans, isChange)
    CS.ShowObject(EffTrans, false)

    local instanceId = trans:GetInstanceID()
    if itemdata.isShowEff then
        local quality = gModelGeneral:GetCommonItemQualityRef(itemdata)
        local eff = GameTable.RarityRef[quality].itemFx
        if not string.isempty(eff) then
            self:CreateWndEffect(IconTrans, eff, instanceId, 100, false, false)
        end
    else
        self:DestroyWndEffectByKey(instanceId)
    end

    local clickFunc = extraData.clickFunc
    if clickFunc then
        self:SetWndClick(IconTrans, function()
            clickFunc()
        end)
    end
end

function UISubActGiftD:InitSelGiftList()
    local list = self:GetSelGiftList()
    local uiSelGiftList = self._uiSelGiftList
    if uiSelGiftList then
        uiSelGiftList:RefreshData(list)
    else
        uiSelGiftList = self:GetUIScroll("uiSelGiftList")
        self._uiSelGiftList = uiSelGiftList
        uiSelGiftList:Create(self.mSelGiftList, list, function(...)
            self:OnDrawSelGiftCell(...)
        end, UIItemList.WRAP, false)
        local uiList = uiSelGiftList:GetList()
        uiList:RefreshList(UIListWrap.RefreshMode.Solid)
    end
end

function UISubActGiftD:OnClickCustomBtnFunc(itemdata)
    if self:IsSellOut(itemdata) and itemdata.personalGoal ~= -1 then
        GF.ShowMessage(ccClientText(20811))
        return
    end
    local fixReward = itemdata.fixReward or {}
    local costomGiftList = itemdata.customGiftList or {}
    local getItemList = itemdata.getItemList or {}
    local fixLen, costomLen, getItemLen = #fixReward, #costomGiftList, #getItemList
    local isSelFull = fixLen + costomLen == getItemLen
    local firstData = costomGiftList[1]
    if not isSelFull and firstData then
        self:OpenCustomSelectWnd({
            sid = self._sid,
            pageId = firstData.pageId,
            entryId = firstData.entryId,
            itemIndex = firstData.index,
            giftData = firstData,
            title = firstData.title,
        })
        return
    else
        self:CommonBuyFunc(itemdata, itemdata.expendType)
    end
end

-------------------------------- 商品条目数据 ----------------------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UISubActGiftD



