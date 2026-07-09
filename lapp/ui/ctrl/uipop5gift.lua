---
--- Created by BY.
--- DateTime: 2023/10/19 16:58:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPop5Gift:LWnd
local UIPop5Gift = LxWndClass("UIPop5Gift", LWnd)
local typeof = typeof
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeUIText = typeof(CS.YXUIText)
local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPop5Gift:UIPop5Gift()
    self._timeKey = "timeKey"
    self._giftIndex = 0
    self._giftTransList = {}
    self._tabIndex = 0
    self._tabTransList = {}
    self._iceCountDown = "_iceCountDown"

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPop5Gift:OnWndClose()
    FireEvent(EventNames.ON_MAIN_GIFT_SHOW, false)
    self:StopDelayTimer()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPop5Gift:OnCreate()
    FireEvent(EventNames.ON_MAIN_GIFT_SHOW, true)
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPop5Gift:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()



    self.jpj = gLGameLanguage:IsJapanVersion()
    --缓存一些初始数据
    self:InitWndData()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:InitText()
    gModelWndPop:RemovePopWnd("UIPop5Gift")
end

function UIPop5Gift:SetTime()
    --拿下时间那些

    local _gift = self._dataList[self._giftIndex][1]

    local time = GetTimestamp()

    local groupCount = _gift.ref.giftGroup
    local groupData = self._groupData[groupCount]
    local endTime = groupData.endTime / 1000
    if _gift.sid and _gift.sid > 0 then
        local activityData = gModelActivity:GetActivityBySid(_gift.sid)
        if activityData and activityData.status ~= ModelActivity.STATUS_NO_SHOW then
            if activityData.endTime < endTime then
                endTime = activityData.endTime
            end
        end
    end
    local timespan = endTime - time
    if (timespan <= 0) then
        self:TimerStop(self._timeKey)
        if (_gift.isActivity) then
            self:OnClickClose()
        end
        return
    end

    local timeStr = LUtil.FormatTimespanNumber(timespan)

    local desText = self.mCutTime

    local description = ccClientText(45301)
    local str = string.replace(description, timeStr)
    self:UpdateResultText(desText, str)
end

function UIPop5Gift:JumpTargetGiftDelay(giftPos)
    if not self._uiGiftList2 then
        local list = self._uiGiftList2:GetList()
        if (not list) then
            return
        end
        list:DelayScrollTo(giftPos, UIListEasy.SCROLL_CENTER)
    end
end

function UIPop5Gift:UpdateResultText(ResultText, text)
    self:SetWndText(ResultText, text)

end

function UIPop5Gift:StopDelayTimer()
    if self._delayUpdateScrollTimer then
        LxTimer.DelayTimeStop(self._delayUpdateScrollTimer)
        self._delayUpdateScrollTimer = nil
    end
end

function UIPop5Gift:SetMarketList()
    local showListData = self._dataList[self._giftIndex]

    local marketList = self._marketList
    if marketList then
        marketList:RefreshList(showListData)
        --marketList:DrawAllItems()
    else


        marketList = self:GetUIScroll("marketList")
        marketList:Create(self.mGiftList_2, showListData, function(...)
            self:DrawMarketItem(...)
        end, UIItemList.NORMAL, false)

        marketList:EnableLoadAnimation(true, 0, 1)
        local uiList = marketList:GetList()
        uiList:RefreshList()

        self._marketList = marketList
    end
    --售卖情况   当前
    local groupData = self._groupData[showListData[1].giftGroup]

    local moveindex = 0
    for k, v in ipairs(showListData) do
        if v.ref.refId == groupData.curCanBuyRefId then
            moveindex = k - 1
        end
    end

    self._marketList:EnableScroll(true, false)

    self._marketList:MoveToPos(moveindex)
    self._marketList:DrawAllItems()
end

--get
function UIPop5Gift:GetCurActiveGift()
    local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)

    if not gift then
        gift = self._dataList[self._giftIndex][1]
    end

    if not gift then
        gift = self._curActiveGift
    end

    return gift
end

--endregion --------------------------------------------------------------------------------------

--region 面板方法 --------------------------------------------------------------------------------
--下方列表
function UIPop5Gift:InitGiftList()
    local list = self._dataList

    if (#list < 1) then
        self:WndClose()
        return true
    end

    --相关控件的显隐
    CS.ShowObject(self.mGiftScroll1, false)
    CS.ShowObject(self.mGiftScroll2, false)
    CS.ShowObject(self.mLeftBtn, false)
    CS.ShowObject(self.mRightBtn, false)
    CS.ShowObject(self.mGiftBg, #list > 1)

    self._giftTransList = {}
    if (#list <= 4) then
        -- 列表少于4个
        local _uiGiftList1 = self._uiGiftList1
        if (_uiGiftList1) then
            _uiGiftList1:RefreshList(list)
        else
            _uiGiftList1 = self:GetUIScroll("GiftScroll1")
            _uiGiftList1:Create(self.mGiftScroll1, list, function(...)
                self:GiftListItem(...)
            end)
            self._uiGiftList1 = _uiGiftList1
        end
        _uiGiftList1:EnableScroll(false)
        CS.ShowObject(self.mGiftScroll1, #list > 1)
    else
        CS.ShowObject(self.mLeftBtn, true)
        CS.ShowObject(self.mRightBtn, true)
        local _uiGiftList2 = self._uiGiftList2
        if (_uiGiftList2) then
            _uiGiftList2:RefreshList(list)
        else
            _uiGiftList2 = self:GetUIScroll("GiftScroll2")
            _uiGiftList2:Create(self.mGiftScroll2, list, function(...)
                self:GiftListItem(...)
            end, UIItemList.NORMAL)
            self._uiGiftList2 = _uiGiftList2
            _uiGiftList2:EnableScroll(true, true)
            self:JumpTargetGiftDelay(self._index)
        end
        CS.ShowObject(self.mGiftScroll2, #list > 1)

        _uiGiftList2:MoveToPos(self._index)
    end
end

-- ui
function UIPop5Gift:OnClickClose()
    local gift = self:GetCurActiveGift()
    local giftGroupCount = gift.ref.giftGroupCount
    local attr1 = gModelPopupGift:FormatPopGiftStr(gift, giftGroupCount)
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "close", attr1)

    self:WndClose()
end

function UIPop5Gift:OnClickGift(itempos, needJump)
    self._curRefId = nil
    self:OnSelectIndex(itempos, needJump)
    self:RefreshTopContent()
    self:ChackHadActivityItem()
end

function UIPop5Gift:InitCommand()
    local curId = self:GetWndArg("id")
    local index = self:GetWndArg("index")
    local dataList = self:GetWndArg("dataList")
    index = self:SetDataList(dataList, curId)
    self._index = index or 1
    local needJump = #self._dataList > 5

    self:InitGiftList()
    self:OnClickGift(self._index, needJump)


end

function UIPop5Gift:SetDataList(dataList, curId)
    local curId = curId
    local index = self:GetWndArg("index")
    if not dataList then
        dataList, index = gModelPopupGift:GetPopGiftShowList(curId, 2)
    end
    --每次都清空
    self._dataList = {}
    self._groupData = {}
    self._haveData = { }
    self._haveGroup = {}
    local groupkeyMap = {}

    --整组的数据 不做区分了 制作 缺少的信息的补充  -- 这里等会看下
    for k, v in ipairs(dataList) do
        --记录每一个分组的信息
        for i, j in ipairs(v) do
            local temp_data = j
            if not self._groupData[temp_data.giftGroup] then
                local data = {}
                data.endTime = temp_data.endTime
                data.curCanBuyRefId = temp_data.refId
                data.curCanBuyPos = i

                self._groupData[temp_data.giftGroup] = data
                table.insert(self._haveGroup, temp_data.giftGroup)
            else
                if self._groupData[temp_data.giftGroup].curCanBuyRefId > temp_data.refId then
                    self._groupData[temp_data.giftGroup].curCanBuyRefId = temp_data.refId

                end
            end

            self._haveData[j.refId] = true
        end
        groupkeyMap[v[1].giftGroup] = k
    end

    self._dataList = dataList

    --这里进行其他的数据的插入
    for k, v in ipairs(self._haveGroup) do
        local list_temp = gModelPopupGift:GetGiftByGroup_NoSid(v)
        for i, j in ipairs(list_temp) do
            if not self._haveData[j.refId] then
                --该礼包没有过数据 进行构建
                local data = {}

                data.ref = j
                data.buyNum = 0
                data.giftGroup = j.giftGroup
                data.id = "-1"  -- 没有礼包的数据  客户端构建
                data.endTime = self._groupData[j.giftGroup].endTime
                data.heroRefId = 0
                data.reward = ""
                data.refId = j.refId

                local key = groupkeyMap[j.giftGroup]
                table.insert(self._dataList[key], data)
            end

        end

    end

    for k, v in ipairs(self._dataList) do
        table.sort(v, function(a, b)
            return a.ref.giftGroupCount < b.ref.giftGroupCount
        end)
    end

    return index
end

function UIPop5Gift:InitText()

    self:SetWndText(self.mBottom_Tips, ccClientText(45306))
end

function UIPop5Gift:OnPopupDataListChange()
    local curId = 0
    if self._curRefId then
        local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
        if gift then
            curId = gift.id
        else
            local ref = gModelPopupGift:GetPopupGiftRefByRefId(self._curRefId, self._curSid)
            gift = gModelPopupGift:GetGiftByGroup(ref.giftGroup, self._curSid)
            if gift then
                curId = gift.id
                self._curRefId = ref.refId
                self._curSid = ref.sid
                self._curGiftGroup = ref.giftGroup

            end
        end
    end
    local index = self:SetDataList(nil, curId)

    index = index or 1
    self._index = index or 1
    self:InitGiftList()

    local needJump = #self._dataList > 5
    self:OnSelectIndex(index, needJump)
    self:RefreshTopContent()
end

function UIPop5Gift:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:OnClickClose()
    end)

    self:SetWndClick(self.mBtn_Close, function(...)
        self:OnClickClose()
    end)

    self:SetWndClick(self.mLeftBtn, function(...)
        local _index = self._index
        if _index - 1 >= 1 then
            self._index = _index - 1
            self._tabIndex = 1
            self:OnClickGift(self._index, true)
        end
    end)
    self:SetWndClick(self.mRightBtn, function(...)
        local _index = self._index
        if _index + 1 <= #list then
            self._index = _index + 1
            self._tabIndex = 1
            self:OnClickGift(self._index, true)
        end
    end)


end
--endregion --------------------------------------------------------------------------------------

--region common方法 --------------------------------------------------------------------------------
--check
--检查活动弹框是否购买前置礼包
function UIPop5Gift:CheckActivityIsBuyPrior(giftList, curRefId)

end

function UIPop5Gift:SetPayBtn(item, ref, limitdesStr)
    local TextMg = self:FindWndTrans(item, "TextMg")
    local TextMgPayText1 = self:FindWndTrans(TextMg, "PayText1")
    local TextMgPayIcon = self:FindWndTrans(TextMg, "PayIcon")
    local TextMgPayText2 = self:FindWndTrans(TextMg, "PayText2")

    CS.ShowObject(TextMgPayIcon, false)

    if limitdesStr then
        self:SetWndText(TextMgPayText2, limitdesStr)
        return
    end

    local payStr = ""
    if (ref.buyType == ModelPopupGift.BUYTYPE_JEWEL or ref.buyType == ModelPopupGift.BUYTYPE_CURRENCY) then
        CS.ShowObject(TextMgPayIcon, true)
        local item = LxDataHelper.ParseItem_3(ref.expend)
        local icon = gModelItem:GetItemIconByRefId(item.itemId)
        self:SetWndEasyImage(TextMgPayIcon, icon)
        payStr = item.itemNum
    elseif (ref.buyType == ModelPopupGift.BUYTYPE_MONEY) then
        payStr = gModelPay:GetShowByWelfareId(tonumber(ref.expend))
    elseif (ref.buyType == ModelPopupGift.BUYTYPE_FREE) then
        payStr = ccClientText(14903)
    end
    local btnStr = ref.isActivity and ref.buyBtnTxt or ccLngText(ref.buyBtnTxt)
    self:SetWndText(TextMgPayText2, payStr)
    self:SetWndText(TextMgPayText1, btnStr)
end


--中间的道具设置
function UIPop5Gift:ShowRewardList(ref, root, isNew)
    local dataList = {}
    if not string.isempty(ref.reward) then
        local itemList = LxDataHelper.ParseItem(ref.reward)
        for k, v in ipairs(itemList) do
            local data = {
                rewardType = 1,
                itemdata = v
            }
            table.insert(dataList, data)
        end
    end

    local giftData = gModelPopupGift:GetGiftByRefId(ref.refId, self._curSid)

    if not string.isempty(ref.rewardFree) then
        local freeList = string.split(ref.rewardFree, '|')
        local cnt = #freeList

        local record = {}
        local rewardStr = nil
        if giftData then
            if (ref.isActivity) then
                if (self._activityPageKeyList) then
                    if (not self._activityPageKeyList[self._curSid]) then
                        return
                    else
                        rewardStr = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
                    end
                end
            else
                rewardStr = giftData.reward
            end
        else
            rewardStr = gModelPopupGift:GetSelectReward(ref.refId)
        end
        record = LxDataHelper.ParseItem(rewardStr, ',') or {}

        for k = 1, cnt do
            local data = {
                rewardType = 2,
                index = k,
                itemdata = record[k],
            }

            table.insert(dataList, data)
        end
    end

    local isMore = #dataList > 4

    if isNew then
        local instanceId = root:GetInstanceID()

        local list = self:FindUIScroll(instanceId)
        if not list then
            list = self:GetUIScroll(instanceId)
            list:Create(root, dataList, function(...)
                self:OnDrawItem(...)
            end)
        else
            list:RefreshList(dataList)
        end
        list:EnableScroll(true, true)
        return
    end

    local minRoot = CS.FindTrans(root, "ItemScroll_3")
    local moreRoot_1 = CS.FindTrans(root, "ItemScroll_1")
    local moreRoot_2 = CS.FindTrans(root, "ItemScroll_2")
    CS.ShowObject(minRoot, not isMore)
    CS.ShowObject(moreRoot_1, isMore)
    CS.ShowObject(moreRoot_2, isMore)
    if isMore then
        --拆分数据
        local len = #dataList

        local showData_1 = {}
        local showData_2 = {}
        for i = 1, 3 do
            table.insert(showData_1, dataList[i])
        end

        for i = 4, len do
            table.insert(showData_2, dataList[i])
        end

        local instanceId = moreRoot_1:GetInstanceID()

        local list = self:FindUIScroll(instanceId)
        if not list then
            list = self:GetUIScroll(instanceId)
            list:Create(moreRoot_1, showData_1, function(...)
                self:OnDrawItem(...)
            end)
        else
            list:RefreshList(showData_1)
        end
        list:EnableScroll(false, true)

        --这里设置位置
        local x = 100 + (4 - #showData_1) * 50
        self:SetAnchorPos(moreRoot_1, Vector2.New(x, moreRoot_1.anchoredPosition.y))

        instanceId = moreRoot_2:GetInstanceID()

        list = self:FindUIScroll(instanceId)
        if not list then
            list = self:GetUIScroll(instanceId)
            list:Create(moreRoot_2, showData_2, function(...)
                self:OnDrawItem(...)
            end)
        else
            list:RefreshList(showData_2)
        end
        list:EnableScroll(false, true)

        x = 100 + (4 - #showData_2) * 50
        self:SetAnchorPos(moreRoot_2, Vector2.New(x, moreRoot_2.anchoredPosition.y))
    else
        local instanceId = minRoot:GetInstanceID()

        local list = self:FindUIScroll(instanceId)
        if not list then
            list = self:GetUIScroll(instanceId)
            list:Create(minRoot, dataList, function(...)
                self:OnDrawItem(...)
            end)
        else
            list:RefreshList(dataList)
        end
        --这里设置位置
        local x = 100 + (4 - #dataList) * 50
        self:SetAnchorPos(minRoot, Vector2.New(x, minRoot.anchoredPosition.y))
        list:EnableScroll(false, true)
    end
end

--设置面板的信息
function UIPop5Gift:ShowIcePart()
    --
    CS.ShowObject(self.mIcePart_New, true)
    self:TimerStop(self._timeKey)

    --设置标题信息
    local gift = self._dataList[self._giftIndex][1]
    local giftRef = gift.ref
    self:SetWndText(self.mTitle, ccLngText(giftRef.giftName))

    --设置人物
    self:SetSpine(giftRef.showHero, giftRef.showXY, self.mSpPos, giftRef.showScale)

    --设置时间

    --设置商品信息
    self:SetMarketList()
end

function UIPop5Gift:SetIceCountDown()
    local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)

    if not gift then
        gift = self._dataList[self._giftIndex][1]
    end

    if not gift then
        self:TimerStop(self._iceCountDown)
        return
    end

    local endTime = gift.isActivity and gift.endTime or gift.endTime / 1000
    local timespan = math.ceil(endTime - GetTimestamp())
    if timespan > 0 then
        local timeStr = LUtil.FormatTimespanNumber(timespan)
        local description = ccClientText(45301)
        local str = string.replace(description, timeStr)
        self:SetWndText(self.mCutDownTime, str)
    else
        self:TimerStop(self._iceCountDown)
    end
end

--是否有激活的礼包
function UIPop5Gift:ChackHadActivityItem()
    if (self._dataList and self._dataList[self._index] and self._dataList[self._index][1]) then
        local curData = self._dataList[self._index][1]
        if (curData.isActivity) then
            gModelActivity:OnActivityPageReq(curData.sid)
        end
    end
end

function UIPop5Gift:SetBuyLimitTxt(hasBuyTime)
    if (not self.buyLimitTxt) then
        return
    end
    if (not hasBuyTime) then
        self:SetWndText(self.buyLimitTxt, "")
        return
    end
    local limitColor = hasBuyTime > 0 and "<#139057>" or "<#c81212>"
    local buyLimitStr = hasBuyTime == -1 and "" or string.format("%s%s%s%s", ccClientText(31700), limitColor, tostring(hasBuyTime), "</color>")
    self:SetWndText(self.buyLimitTxt, buyLimitStr)
    CS.ShowObject(self.payMask, hasBuyTime == 0 and hasBuyTime ~= -1)
    CS.ShowObject(self.payBtn, hasBuyTime ~= 0)
end
--endregion --------------------------------------------------------------------------------------

--region 计时器 --------------------------------------------------------------------------------
function UIPop5Gift:OnTimer(key)
    if (key == self._timeKey) then
        self:SetTime()
    elseif key == self._iceCountDown then
        self:SetIceCountDown()

    end
end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
-- event
function UIPop5Gift:OnActivityPageResp(pb, ret)
    local modelId = gModelActivity:GetActivityModeIdBySid(pb.sid)
    if (modelId == ModelActivity.MODEL_ACTIVITY_TYPE_93) then
        local _activityPageList = {}
        local _activityPageKeyList = self._activityPageKeyList or {}
        for i, v in ipairs(pb.pages) do
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            _activityPageList[page.pageId] = page
        end
        _activityPageKeyList[pb.sid] = _activityPageList
        self._activityPageKeyList = _activityPageKeyList
        self:RefreshUIByActivityPageResp()
    end
end

function UIPop5Gift:GiftListItem(list, item, itemdata, itempos)
    self._giftTransList[itempos] = item
    local InstanceID = item:GetInstanceID()
    self:ChangeGiftImage(item, false, true)
    local RootTrans = self:FindWndTrans(item, "Root")
    local icon = self:FindWndTrans(RootTrans, "Icon")
    local nameListRoot = self:FindWndTrans(item, "NameList")
    local nameText = self:FindWndTrans(nameListRoot, "NameText")
    local SelNameText = self:FindWndTrans(nameListRoot, "SelNameText")
    local rateText = self:FindWndTrans(RootTrans, "RateBg/RateText")
    local eff = self:FindWndTrans(nameListRoot, "EffParent/Eff")

    local giftData = itemdata[1]

    local ref = giftData.ref
    self:SetWndEasyImage(icon, ref.icon, function()
        CS.ShowObject(icon, true)
    end)
    --local giftName = ref.isActivity and ref.giftName or ccLngText(ref.giftName)
    local giftName = ccLngText(ref.giftName)
    self:SetWndText(nameText, giftName)
    self:SetWndText(SelNameText, giftName)

    local discount = ref.discount
    for k, v in ipairs(itemdata) do
        if v.ref.discount > discount then
            discount = v.ref.discount
        end
    end

    self:SetWndText(rateText, discount .. "%+")

    local isShowEff = false

    CS.ShowObject(eff, isShowEff)
    if isShowEff then
        self:CreateWndEffect(eff, "fx_zuanshilibao", InstanceID, 100, false, false)
    end
    self:SetWndClick(item, function()
        self._index = itempos
        self._tabIndex = 1

        local attr1 = gModelPopupGift:FormatPopGiftStr(giftData, itempos)
        local attr2, attr3 = gModelPopupGift:GetAllIdStr()
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "gift_select", attr1, attr2, attr3)

        self:OnClickGift(itempos)
    end)
end

--设置形象
function UIPop5Gift:SetSpine(showHero, showXY, spPos, showScale)
    local showSpineNode = not string.isempty(showHero)
    CS.ShowObject(self.mSpPos, showSpineNode)
    if not showSpineNode then
        return
    end
    spPos = spPos or self.mSpPos
    local x, y
    if not string.isempty(showXY) then
        local showXYInfo = string.split(showXY, ",")
        x, y = tonumber(showXYInfo[1]), tonumber(showXYInfo[2])
    else
        local recordSpinePox = self._recordSpinePox
        x, y = recordSpinePox.x, recordSpinePox.y
    end

    local spine = showHero
    local key = "spine"
    if (self._oldSpine and self._oldSpine ~= spine and self._oldKey and self._oldKey == key) then
        self:DestroyWndSpineByKey(key)
    end
    ---@param dpSpine LDisplaySpine
    self:CreateWndSpine(spPos, spine, key, false, function(dpSpine)
        local dpTrans = dpSpine:GetDisplayTrans()

        dpTrans.anchorMin = Vector2.New(0.5, 0.5)
        dpTrans.anchorMax = Vector2.New(0.5, 0.5)
        self:SetAnchorPos(spPos, Vector2(x, y))
        if showScale and showScale > 0 then
            dpSpine:SetScale(showScale)
        end
    end)
    self._oldKey = key
    self._oldSpine = spine
end
--当前的组是否卖完
function UIPop5Gift:CheckSoleGroupOver(giftGroup, sid)

end

function UIPop5Gift:OnDrawItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "root")
    local rootClick = self:FindWndTrans(root, "click")
    local clickItem = self:FindWndTrans(rootClick, "item")
    local itemAdd = self:FindWndTrans(clickItem, "add")
    local itemIcon = self:FindWndTrans(clickItem, "icon")
    local itemShift = self:FindWndTrans(clickItem, "shift")

    local showShift = false
    local showItem = false
    if itemdata.rewardType == 1 then
        self:CreateCommonIconImpl(itemIcon, itemdata.itemdata, { noClick = true })

        self:SetWndClick(rootClick, function()
            local gift = self:GetCurActiveGift()
            local giftGroupCount = gift.giftGroupCount
            local attr1 = gModelPopupGift:FormatPopGiftStr(gift, giftGroupCount)
            local attr2 = tostring(itemdata.itemId)
            gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "reward_preview", attr1, attr2)
            gModelGeneral:ShowCommonItemTipWnd(itemdata.itemdata, { showSkinCode = true })
        end)
        showItem = true
    else
        self:SetWndClick(rootClick, function()
            self:OpenCustomWnd(itemdata.index)
        end)

        if itemdata.itemdata then
            self:CreateCommonIconImpl(itemIcon, itemdata.itemdata, { noClick = true })
        end
        showShift = itemdata.itemdata ~= nil
        showItem = showShift

    end
    CS.ShowObject(itemShift, showShift)
    CS.ShowObject(itemIcon, showItem)
    item.localScale = Vector3.New(0.9, 0.9, 0.9)
end

function UIPop5Gift:OnSelectIndex(itempos, needJump)
    if self._giftIndex > 0 then
        local trans = self._giftTransList[self._giftIndex]
        self:ChangeGiftImage(trans, false, true)
    end
    local trans = self._giftTransList[itempos]
    self:ChangeGiftImage(trans, true, true)
    self._giftIndex = itempos

    if needJump and (self._uiGiftList1 or self._uiGiftList2) then
        self:JumpTargetGift(itempos)
    end
end

--上方的信息部分
function UIPop5Gift:RefreshTopContent()
    local gift = nil
    if self._curRefId then
        gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
    end

    if not gift then
        local gifts = self._dataList[self._giftIndex]
        if not gifts then
            return
        end

        local group = nil
        for k, v in pairs(gifts) do
            local tempGroup = v.ref.giftGroupCount
            if not group or group > tempGroup then
                group = tempGroup
                gift = v
            end
        end

        if not gift then
            return
        end
    end
    self._curActiveGift = gift
    self._curRefId = gift.ref.refId
    self._curSid = gift.ref.sid
    self._curGiftGroup = gift.ref.giftGroup
    self._curGiftShowType = gift.ref.giftShowType

    self:ShowIcePart()

    self:SetTime()
    self:TimerStart(self._timeKey, 1, false, -1)
end

function UIPop5Gift:ChangeGiftImage(trans, bool, isGift)
    if not trans then
        return
    end
    local RootTrans = self:FindWndTrans(trans, "Root")
    if not RootTrans then
        RootTrans = trans
    end
    local selImage = self:FindWndTrans(RootTrans, "SelImage")

    local nameText, SelNameText
    if isGift then
        local nameListRoot = self:FindWndTrans(trans, "NameList")
        nameText = self:FindWndTrans(nameListRoot, "NameText")
        SelNameText = self:FindWndTrans(nameListRoot, "SelNameText")
    else
        nameText = self:FindWndTrans(RootTrans, "NameText")
        SelNameText = self:FindWndTrans(RootTrans, "SelNameText")
    end

    local Image = self:FindWndTrans(RootTrans, "Image")
    CS.ShowObject(Image, not bool)
    CS.ShowObject(selImage, bool)
    CS.ShowObject(nameText, not bool)
    CS.ShowObject(SelNameText, bool)
end

function UIPop5Gift:DrawMarketItem(list, item, itemdata, index)
    local Item_Bg = CS.FindTrans(item, "Item_Bg")
    local ItemScroll_1 = CS.FindTrans(item, "ItemScroll_1")
    local ZKDiv = CS.FindTrans(item, "ZKDiv")
    local ZKTxt = CS.FindTrans(ZKDiv, "ZKTxt")
    local Arrow = CS.FindTrans(item, "Arrow")
    local SellOutTag = CS.FindTrans(item, "SellOutTag")
    local PayInfoDiv = CS.FindTrans(item, "PayInfoDiv")
    local Lock = CS.FindTrans(PayInfoDiv, "Lock")
    local PriceInfo = CS.FindTrans(PayInfoDiv, "PriceInfo")
    local Price = CS.FindTrans(PriceInfo, "Price")
    local Icon = CS.FindTrans(PriceInfo, "Icon")
    local Limit = CS.FindTrans(PayInfoDiv, "Limit")

    local Limit_En = CS.FindTrans(PayInfoDiv, "Limit_En")

    local ref = itemdata.ref
    --物品
    CS.ShowObject(ItemScroll_1, true)
    self:ShowRewardList(ref, ItemScroll_1, true)

    --超值
    local isZero  =checknumber(ref.discount)  == 0
    CS.ShowObject(ZKDiv,not isZero)
    self:SetWndText(ZKTxt, ref.discount .. "%+")
    if self.jpj then
        self:InitTextSizeWithLanguage(ZKTxt,-2)
        self:SetAnchorPos(ZKTxt,Vector2.New(0,3))
        ZKDiv.sizeDelta = Vector2.New(110,36)
        self:InitTextSizeWithLanguage(self.mTitle,-6)
    end


    --箭头是否显示
    CS.ShowObject(Arrow, index > 1)

    --售卖情况   当前
    local groupData = self._groupData[ref.giftGroup]
    local curCanBuyRefId = groupData.curCanBuyRefId

    --售卖信息
    ---价格
    local payStr = ""
    CS.ShowObject(Icon, false)
    if (ref.buyType == ModelPopupGift.BUYTYPE_JEWEL or ref.buyType == ModelPopupGift.BUYTYPE_CURRENCY) then
        CS.ShowObject(TextMgPayIcon, true)
        local item = LxDataHelper.ParseItem_3(ref.expend)
        local icon = gModelItem:GetItemIconByRefId(item.itemId)
        self:SetWndEasyImage(Icon, icon, function()
            CS.ShowObject(Icon, true)
        end, false)
        payStr = item.itemNum
    elseif (ref.buyType == ModelPopupGift.BUYTYPE_MONEY) then
        payStr = gModelPay:GetShowByWelfareId(tonumber(ref.expend))
    elseif (ref.buyType == ModelPopupGift.BUYTYPE_FREE) then
        payStr = ccClientText(14903)
    end
    self:SetWndText(Price, payStr)
    ---限购
    local curCanBuy = ref.limit > 0 and ref.limit or ref.lifetimeLimit
    curCanBuy = curCanBuy - itemdata.buyNum

    local limitTran =self._isEnus and Limit_En or Limit


    if curCanBuy > 0 then
        local str = ref.limit > 0 and ccClientText(45303) or ccClientText(45304)
        str = string.replace(str, curCanBuy)
        self:SetWndText(limitTran, str)
        CS.ShowObject(limitTran, true)
    else
        CS.ShowObject(limitTran, false)
    end



    self:SetWndEasyImage(Item_Bg, "limitGift_bg_2")
    CS.ShowObject(SellOutTag, false)
    CS.ShowObject(PayInfoDiv, false)
    --  -1 买过了  0  可以购买  1 下一档
    local isCanbuy = -1
    if ref.refId > curCanBuyRefId then
        --下一档
        CS.ShowObject(PayInfoDiv, true)
        CS.ShowObject(Lock, true)
        isCanbuy = 1
    elseif ref.refId == curCanBuyRefId then
        --当前
        CS.ShowObject(PayInfoDiv, true)
        CS.ShowObject(Lock, false)
        self:SetWndEasyImage(Item_Bg, "limitGift_bg_2_on")
        isCanbuy = 0
    elseif ref.refId < curCanBuyRefId then
        --卖完
        CS.ShowObject(SellOutTag, true)
        isCanbuy = -1
    end


    --是否能够购买
    self:SetWndClick(Item_Bg, function()


        if isCanbuy == 0 then
            local wndName = self:GetWndName()

            local customReward = self._curSid and "" or nil
            if (self._curSid and self._activityPageKeyList) then
                customReward = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
            end

            gModelPopupGift:BuyGift(itemdata.refId, wndName, self._curSid, customReward)
        elseif isCanbuy == -1 then
        elseif isCanbuy == 1 then
        end
        --local customReward = self._curSid and "" or nil
        --if (self._curSid and self._activityPageKeyList) then
        --    customReward = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
        --end
        --gModelPopupGift:BuyGift(refId, wndName, self._curSid, customReward)
    end)
end

function UIPop5Gift:InitMessage()
    self:WndNetMsgRecv(LProtoIds.PopupGiftNowListResp, function(...)
        self:OnPopupDataListChange()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:OnActivityPageResp(...)
    end)
end

--region 初始化 --------------------------------------------------------------------------------
function UIPop5Gift:InitWndData()
    self._recordSpinePox = self.mSpPos.anchoredPosition

end

function UIPop5Gift:JumpTargetGift(giftPos)
    if self._uiGiftList1 then
        local list = self._uiGiftList1:GetList()
        if (not list) then
            return
        end
        list:ScrollTo(giftPos)
    end
    if self._uiGiftList2 then
        local list = self._uiGiftList2:GetList()
        if (not list) then
            return
        end
        list:ScrollTo(giftPos)
    end
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIPop5Gift