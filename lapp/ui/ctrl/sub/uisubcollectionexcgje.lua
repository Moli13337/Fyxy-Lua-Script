--- 模板94 集字活动 - 兑换商店
--- Created by Ease.
--- DateTime: 2023/10/8 17:29:43
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubCollectionExcGje:LChildWnd
local UISubCollectionExcGje = LxWndClass("UISubCollectionExcGje", LChildWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubCollectionExcGje:UISubCollectionExcGje()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubCollectionExcGje:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubCollectionExcGje:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubCollectionExcGje:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    self:InitMessage()
    self:RefreshDayFirstRefPoint()
end

function UISubCollectionExcGje:ShowTimerFunc()
    local nowTime = GetTimestamp()
    local timeDif = os.difftime(self._endTime, nowTime)
    if timeDif <= 0 then
        self:SetWndText(self.mTimeTxt, "")
        self:StopShowTimer()
        return
    end
    local timeStr = LUtil.FormatTimespanCn(timeDif)
    timeStr = string.replace(ccClientText(11637), timeStr)
    self:SetWndText(self.mTimeTxt, timeStr)
end

function UISubCollectionExcGje:InitData()
    self._sid = self:GetWndArg("sid")
    self._pbData = self:GetWndArg("pbData")
    local pbEntries = table.clone(self._pbData.entry)
    self._pbEntries = {}
    for i, v in pairs(pbEntries) do
        self._pbEntries[v.entryId] = v
    end
    self._activityWebData = self:GetWndArg("activityWebData")
    self._endActivityTime = self:GetWndArg("endTime") --活动结束事件
    self._showEndActivityTime = self:GetWndArg("showEndTime") --活动延迟展示时间
    self._showTimeKey = "_endTimeKey"
    self._pageId = self:GetWndArg("pageId")
    self._config = self._activityWebData.config--配置表
    self._chunk = self._activityWebData.chunk[self._pageId] --分页表
    self._pageType = self._chunk.type
    self._commonIconTbl = {}
    local dropItemIdMap = {}

    if self._config then
        local dropItemId = self._config.dropItemId
        local dropArr = string.split(dropItemId, "|")
        for i, v in ipairs(dropArr) do
            v = tonumber(v)
            dropItemIdMap[v] = v
        end

        self:SetWndText(CS.FindTrans(self.mGoBtn, "Text"), self._config.jumpTxt)

        self._pageJumpIds = {
            [1] = self._config.jump,
            [2] = self._config.jump2,
            [3] = self._config.jump3,
            [4] = self._config.jump4,
            [5] = self._config.jump5,
        }

    end
    self._dropItemIdMap = dropItemIdMap

    local entries = table.clone(self._chunk.entries)
    self._entries = self:GetDisplayEntryList(entries)
    self:EntriesSort(self._entries)
    self._moveToIndex = 1
    self:SetUI()
end

function UISubCollectionExcGje:ChackItemIsLack(expendArr)
    for i, v in pairs(expendArr) do
        local needArr = string.split(v, "=")
        local needRewardType = tonumber(needArr[1])
        local isHeroItem = needRewardType == 2
        local needId = tonumber(needArr[2])
        local needCnt = needArr[3]
        local hadCnt = 0
        if (isHeroItem) then
            local heroList = gModelHero:GetHeroList()
            for i, v in pairs(heroList) do
                local heroData = v
                local heroRefId = v:GetRefId()
                if (heroRefId == needId and gModelHeroExtra:CheckBeCapableOfSellHero(heroData)) then
                    hadCnt = hadCnt + 1
                end
            end
        else
            hadCnt = gModelItem:GetNumByRefId(needId)
        end
        if (tonumber(hadCnt) < tonumber(needCnt)) then
            return true
        end
    end
end
function UISubCollectionExcGje:OnExchangeIconList(list, item, itemdata, itempos)
    local cntTxt = self:FindWndTrans(item, "CntTxt")
    local icon = self:FindWndTrans(item, "Icon")
    local heroIconRoot = self:FindWndTrans(item, "HeroIconRoot")
    local root = self:FindWndTrans(item, "Root")
    local expend = itemdata
    local needArr = string.split(expend, "=")
    local needRewardType = tonumber(needArr[1])
    local needId = tonumber(needArr[2])
    local needCnt = tonumber(needArr[3])
    local isHeroItem = needRewardType == 2
    local hadCnt = 0
    if (isHeroItem) then
        local heroList = gModelHero:GetHeroList()
        for i, v in pairs(heroList) do
            local heroData = v
            local heroRefId = v:GetRefId()
            if (heroRefId == needId and gModelHeroExtra:CheckBeCapableOfSellHero(heroData)) then
                hadCnt = hadCnt + 1
            end
        end
    else
        hadCnt = gModelItem:GetNumByRefId(needId)
    end
    CS.ShowObject(heroIconRoot, isHeroItem)
    -- local numStr = tostring(hadCnt)
    -- local coversionHadCnt
    -- if(#numStr >= 9)then
    -- 	local displayNum =  math.floor(hadCnt / math.pow(10,8))
    -- 	coversionHadCnt = displayNum .. ccClientText(2014)--"亿"
    -- elseif(#numStr >= 5)then
    -- 	local displayNum =  math.floor(hadCnt / math.pow(10,4))
    -- 	coversionHadCnt = displayNum .. ccClientText(2013)--"万"
    -- else
    -- 	coversionHadCnt = tostring(hadCnt)
    -- end
    local isLack = tonumber(hadCnt) < needCnt
    local hasCntColor = not isLack and "<color=#30e055>#a1#</color>" or "<color=#ff2929>#a1#</color>"
    local hasCntStr = string.replace(hasCntColor, LUtil.NumberCoversion(hadCnt))
    local needTxtStr = hasCntStr .. "/" .. LUtil.NumberCoversion(needCnt)
    self:SetWndText(cntTxt, needTxtStr)

    -- if (not isHeroItem) then
    --     local iconRef = gModelItem:GetRefByRefId(needId)    --道具图标
    --     local iconPath = iconRef.icon
    --     self:SetWndEasyImage(icon, iconPath, nil, true)
    -- else
    --     local herodata = {}
    --     local heroRef = gModelHero:GetHeroRef(needId)    --道具图标
    --     herodata.refId = heroRef.refId
    --     herodata.star = heroRef.initStar
    --     local instanceId = heroIconRoot:GetInstanceID()
    --     local heroIconCls = self._commonIconTbl[instanceId]
    --     if not heroIconCls then
    --         heroIconCls = CommonIcon:New()
    --         self._commonIconTbl[instanceId] = heroIconCls
    --         heroIconCls:Create(heroIconRoot)
    --     end
    --     heroIconCls:SetHeroDataSet(herodata)
    --     heroIconCls:SetNoShowLv(true)
    --     heroIconCls:DoApply()
    --     self:SetWndClick(heroIconRoot, function()
    --         gModelGeneral:OpenGetWayWnd({ itemId = needId, refIdType = needRewardType })
    --     end)
    -- end

    -- local itemInfo = {
    --     itemId = needId,
    --     itemNum = needCnt,
    --     itemType = isHeroItem and LItemTypeConst.TYPE_HERO or LItemTypeConst.TYPE_ITEM,
    -- }
    -- local dropItemIdMap = self._dropItemIdMap or {}
    -- local showIconBg = dropItemIdMap[needId] and true or false
    -- local IconBg = self:FindWndTrans(item, "IconBg")
    -- if showIconBg and not isHeroItem then
    --     local iconBg
    --     local iconRef = gModelItem:GetRefByRefId(needId)    --道具图标
    --     local quaId = iconRef.quality
    --     if quaId then
    --         iconBg = gModelItem:GetIconBgByQualityId(quaId)
    --     end
    --     self:SetWndEasyImage(IconBg, iconBg, nil, true)
    -- end
    -- CS.ShowObject(IconBg, showIconBg)

    -- self:SetWndClick(icon, function()
    --     --gModelGeneral:ShowCommonItemTipWnd(itemInfo,true)
    --     gModelGeneral:OpenGetWayWnd({ itemId = itemInfo.itemId, refIdType = itemInfo.itemType })
    -- end)

    local data = LxDataHelper.ParseItem_4(expend)
    local instanceId = heroIconRoot:GetInstanceID()
    if not self._commonIconTbl[instanceId] then
		self._commonIconTbl[instanceId] = CommonIcon:New()
		self._commonIconTbl[instanceId]:Create(root)
	end
	self._commonIconTbl[instanceId]:SetCommonReward(data.itemType, data.itemId)
	self._commonIconTbl[instanceId]:EnableShowNum(false)
	self._commonIconTbl[instanceId]:DoApply()
    self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
    CS.ShowObject(root, true)
end
function UISubCollectionExcGje:EntriesSort(entries)
    table.sort(entries, function(a, b)
        local aCanBuy = self:CheckBuy(a) and 1 or 0
        local bCanBuy = self:CheckBuy(b) and 1 or 0
        if (aCanBuy ~= bCanBuy) then
            return aCanBuy < bCanBuy
        end
        return a.sort < b.sort
    end)
end
function UISubCollectionExcGje:SetIconList(itemListTrans, itemdata)
    local expendArr = string.split(itemdata.expend2, ",")
    local list = expendArr
    local key = itemListTrans:GetInstanceID()
    local itemList = self:FindUIScroll(key)
    if itemList then
        itemList:RefreshList(list)
    else
        itemList = self:GetUIScroll(key)
        itemList:Create(itemListTrans, list, function(...)
            self:OnExchangeIconList(...)
        end)
        itemList:EnableScroll(false, true)
    end
end

function UISubCollectionExcGje:OnTimer(key)
    if key == self._showTimeKey then
        self:ShowTimerFunc()
    end
end
function UISubCollectionExcGje:SetHeroSpine(heroId, heroPos, isTurn)
    --local effectId = tonumber(heroId)
    --local effRef = gModelHero:GetShowEffectById(effectId)
    --local spineName = effRef.heroDrawing
    local spineName = heroId
    CS.ShowObject(self.mHeroPaint, spineName)
    self:CreateWndSpine(self.mHeroPaint, spineName, spineName, false, function(dpSpine)
        dpSpine:SetIgnoreTimeScale(true)
    end)
    if heroPos then
        local posArr = string.split(heroPos, "|")
        local v2 = Vector2.New(tonumber(posArr[1]), tonumber(posArr[2]))
        self:SetAnchorPos(self.mHeroPaint, v2)
    end
    if isTurn == 1 then
        self.mHeroPaint.localScale = Vector3.New(-1, 1, 1)
    end
end
function UISubCollectionExcGje:StopShowTimer()
    self:TimerStop(self._showTimeKey)
    --self:WndClose()
end
function UISubCollectionExcGje:GetDisplayEntryList(entries)
    local list = {}
    for i, v in pairs(entries) do
        local moreInfoArr = string.split(v.moreInfo, "|")
        local lvLimitArr = string.split(moreInfoArr[1], ",")
        local playerLV = gModelPlayer:GetPlayerLv()
        if (lvLimitArr and playerLV >= tonumber(lvLimitArr[1]) and playerLV <= tonumber(lvLimitArr[2])) then
            table.insert(list, v)
        end
    end
    return list
end
function UISubCollectionExcGje:OnExchangeList(list, item, itemdata, itempos)
    local iconRoot = self:FindWndTrans(item, "IconRoot")
    local itemList = self:FindWndTrans(item, "ItemList")--所需道具列表
    local exchangeCntTxt = self:FindWndTrans(item, "ExchangeCntTxt")--可兑换文本
    local supplicationBtn = self:FindWndTrans(item, "SupplicationBtn")--可兑换按钮
    -- local supplicationTxt = self:FindWndTrans(supplicationBtn, "BtnNameTxt")
    --local lightBtn = self:FindWndTrans(supplicationBtn, "Light")--可兑换按钮
    local redPoint = self:FindWndTrans(supplicationBtn, "redPoint")
    local spreeImg = self:FindWndTrans(item, "SpreeImg")
    local effTrans = self:FindWndTrans(supplicationBtn, "eff")

    local reward = LxDataHelper.ParseItem(itemdata.reward)[1]


    if gLGameLanguage:IsJapanRegion() then
        LxUiHelper.SetLayoutPadding(CS.FindTrans(itemList,"ItemRoot"), Vector4.New(30, 10, 0, 0))
    end

    local InstanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(iconRoot)
    baseClass:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
    baseClass:DoApply()
    self:SetWndClick(iconRoot, function()
        gModelGeneral:ShowCommonItemTipWnd(reward)
    end)
    local moreInfoArr = string.split(itemdata.moreInfo, "|")
    CS.ShowObject(spreeImg, moreInfoArr[2] and moreInfoArr[2] ~= "")
    self:SetIconList(itemList, itemdata)

    local needArr = string.split(itemdata.expend2, ",")

    local pbEntryData = self._pbEntries[itemdata.id]
    local marketData = pbEntryData.MarketData
    local exCnt = marketData.personal
    local totalExCnt = marketData.personalGoal
    local isLack = self:ChackItemIsLack(needArr)
    local isBuy = self:CheckBuy(itemdata)
    local canBuy = totalExCnt - exCnt ~= 0 or totalExCnt == -1
    --CS.ShowObject(exchangeCntTxt, canBuy)
    local showRedPoint = canBuy and not isLack
    CS.ShowObject(redPoint, false)

    local key = effTrans:GetInstanceID()
    self:DestroyWndEffectByKey(key)
    if showRedPoint then
        self:CreateWndEffect(effTrans, "fx_anniu_03", key, 100, false, false)
    end
    CS.ShowObject(effTrans, showRedPoint)

    self:SetWndButtonText(supplicationBtn, ccClientText(30707))
    local hasCntColor = canBuy and "<color=#30e055>#a1#</color>" or "<color=#ff2929>#a1#</color>"
    local exCntColorStr = string.replace(hasCntColor, tostring(totalExCnt - exCnt))
    local exchangeStr = string.replace(ccClientText(22203), exCntColorStr, totalExCnt)--"可兑换"..exCnt.."/"..totalExCnt
    self:SetWndText(exchangeCntTxt, exchangeStr)
    --local sBtnImg = isLack and "public_btn_2_1" or "public_btn_2_2"
    --self:SetWndEasyImage(lightBtn, sBtnImg)
    self:SetWndButtonGray(supplicationBtn, not canBuy or isLack)
    self:SetWndClick(supplicationBtn, function()
        if (isBuy) then
            GF.ShowMessage(ccClientText(22204))
        elseif (isLack) then
            GF.ShowMessage(ccClientText(22206))
        else
            local goodsData = {}
            goodsData.personalGoal = totalExCnt
            goodsData.personal = exCnt
            local list = LxDataHelper.ParseItem(marketData.expend2)
            goodsData.price = { itemPrices = list }
            goodsData.sid = self._sid
            goodsData.entryId = itemdata.id
            goodsData.pageId = self._pageId
            local item = pbEntryData.items[1]
            goodsData.item = {
                itemId = item.itemId,
                itemNum = item.count,
                itemType = item.type,
            }
            goodsData.resetType = marketData.condResetType
            if (itemdata.canBuyMore == 0) then
                local consumeDetail = gModelActivity:GetConsumeDetail(list)
                gModelActivity:OnActivityMarkeyBuyReq(self._sid, self._pageId, itemdata.id, nil, nil, consumeDetail)
            else
                GF.OpenWnd("UIDianBuy", {
                    goodsData = goodsData,
                    shopType = ModelShop.ACTIVITY,
                    bSupportMultiPrice = true
                })
            end
        end
    end)
end

function UISubCollectionExcGje:RefreshDayFirstRefPoint()
	local _sid = self._sid
	local pageIndex = 1
	local bool = gModelRedPoint:GetActivityRedPointPage(_sid, self._pageId)
	if bool then
		gModelActivity:OnActivitySpecialOpReq(_sid, self._pageId, nil, ModelActivity.CANCEL_RED_POINT, "1")
	end
end
function UISubCollectionExcGje:OnWndRefresh()
    self:InitData()
    self:RefreshDayFirstRefPoint()
end
--收集兑换列表
function UISubCollectionExcGje:SetExchangeList()
    local list = self._entries--self._exchangeDataList
    local itemList = self._exchangeList
    if itemList then
        itemList:RefreshList(list)
    else
        itemList = self:GetUIScroll("mItemList")
        itemList:Create(self.mItemList, list, function(...)
            self:OnExchangeList(...)
        end)
        self._exchangeList = itemList
        self._exchangeList:EnableScroll(true, false)
    end
end

--region 活动倒计时
function UISubCollectionExcGje:RefreshShowTime()
    local timeValue = self._endActivityTime or 0
    local showEndActivityTime = self._showEndActivityTime
    if showEndActivityTime and showEndActivityTime > timeValue then
        timeValue = showEndActivityTime
    end
    self._endTime = timeValue
    local showTime = self._endTime > 0
    if (self._config.conversionTimePos) then
        local pos = LxDataHelper.ParseVector2NotEmpty2(self._config.conversionTimePos)
        self:SetAnchorPos(self.mTimeBg, pos)
    end
    CS.ShowObject(self.mTimeBg, showTime)
    if not showTime then
        return
    end
    self:ShowTimerFunc()
    self:TimerStart(self._showTimeKey, 1, false, -1)
end
function UISubCollectionExcGje:SetUI()
    self:SetWndEasyImage(self.mBgImg, self._config.conversionImage)
    self:SetWndText(self.mDialogueTxt, self._config.conversionDropTxt)
    self:SetHeroSpine(self._config.heroCollect, self._config.heroCollectPos, self._config.heroCollectTurn)
    self:SetDesBg(self._config.dropTxtPos)
    --self:SetDesBg("1|0,0")
    self:SetExchangeList()
    self:RefreshShowTime()
end
function UISubCollectionExcGje:SetDesBg(dropTxtPos)
    local arr = string.split(dropTxtPos, "|")
    local isScale = arr[1] and arr[1] == "1"
    if isScale then
        self.mDialogueBg.localScale = Vector2(-1, 1)
    end
    if arr[2] then
        local pos = string.split(arr[2], ",")
        self.mDesBg.anchoredPosition = Vector2(tonumber(pos[1]), tonumber(pos[2]))
    end
end

function UISubCollectionExcGje:InitMessage()
    --self:WndNetMsgRecv(LProtoIds.ActivityMarkeyBuyResp,function (pb)
    --	self:InitData()
    --end)
    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function(pb)
        self:SetExchangeList()
    end)

    self:SetWndClick(self.mGoBtn, function()

        local jumpIds = self._pageJumpIds[self._pageId]
        if jumpIds then
            gModelFunctionOpen:Jump(jumpIds, self:GetWndName())
        else
            if self._config and self._config.jump then
                gModelFunctionOpen:Jump(self._config.jump, self:GetWndName())
            end
        end
    end)
end
function UISubCollectionExcGje:CheckBuy(data)
    local marketData = self._pbEntries[data.id].MarketData
    local exCnt = marketData.personal
    local totalExCnt = marketData.personalGoal
    return totalExCnt - exCnt == 0 and totalExCnt ~= -1
end
--endregion
------------------------------------------------------------------
return UISubCollectionExcGje


