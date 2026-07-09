---
--- Created by BY.
--- DateTime: 2023/10/27 16:54:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPop2Gift:LWnd
local UIPop2Gift = LxWndClass("UIPop2Gift", LWnd)
local typeof = typeof
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeUIText = typeof(CS.YXUIText)
local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
------------------------------------------------------------------

local adMethodId = ModelAds.TYPE_ADS_401
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPop2Gift:UIPop2Gift()
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
function UIPop2Gift:OnWndClose()
    FireEvent(EventNames.ON_MAIN_GIFT_SHOW, false)
    self:StopDelayTimer()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPop2Gift:OnCreate()
    LWnd.OnCreate(self)
    FireEvent(EventNames.ON_MAIN_GIFT_SHOW, true)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPop2Gift:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()


    self.jpj = gLGameLanguage:IsJapanVersion()
    self._recordSpinePox = self.mSpPos.anchoredPosition

    self._isVie =gLGameLanguage:IsVieVersion()
    if self._isVie then
        self:InitTextCharacterWithLanguage(self.mRateText,0)
    end
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()

    gModelWndPop:RemovePopWnd("UIPop2Gift")
    
    if gLGameLanguage:IsJapanVersion() then 
        self:InitTextSizeWithLanguage(self.mInfoUIText,-2)
        self:InitTextLineWithLanguage(self.mInfoUIText,-10)
        self:InitTextCharacterWithLanguage(self.mInfoUIText,-10)
    end 
end

function UIPop2Gift:StartDelayTimer(ResultNode, normalized)
    if not ResultNode then
        return
    end
    local resultNode = ResultNode:GetComponent(typeOfScrollRect)
    if self._delayUpdateScrollTimer then
        return
    end
    self._delayUpdateScrollTimer = LxTimer.DelayFrameCall(function()
        if normalized then
            resultNode.verticalNormalizedPosition = normalized
        end
        self._delayUpdateScrollTimer = nil
    end, 1)
end

function UIPop2Gift:GiftListItem(list, item, itemdata, itempos)
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
    local giftName = giftData.isActivity and ref.giftName or ccLngText(ref.giftName)
    self:SetWndText(nameText, giftName)
    self:SetWndText(SelNameText, giftName)
    self:SetWndText(rateText, ref.discount .. "%+")

    if self.jpj then
        self:InitTextSizeWithLanguage(nameText,-4)
        self:InitTextSizeWithLanguage(SelNameText,-4)
        LxUiHelper.SetSizeWithCurAnchor(nameText,0,100)
        LxUiHelper.SetSizeWithCurAnchor(SelNameText,0,100)
        self.mGiftBg.sizeDelta = Vector2.New(639.4999,150)
        self:SetAnchorPos(self.mGiftBg,Vector2.New(0,-450))

        local layout =CS.FindTrans(self.mRoot1,"layout")

        self:SetAnchorPos(layout,Vector2.New(-155,351))
    end

    local list = gModelPopupGift:GetGiftArrByRefId(ref.refId, ref.sid)
    local isShowEff = false
    --for i, v in ipairs(list) do
    --	if v.buyType == 1 then
    --		isShowEff = true
    --		break
    --	end
    --end
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

    if self._isEnus then
        self:InitTextLineWithLanguage(SelNameText,-20)
        self:InitTextLineWithLanguage(nameText,-20)
    end
end

function UIPop2Gift:OnSelectIndex(itempos, needJump)

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

function UIPop2Gift:RefreshUIByActivityPageResp()
    if (self._activityPageKeyList[self._curSid]) then
        local pageData = self._activityPageKeyList[self._curSid][1]
        if (not pageData) then
            return
        end
        local entryData = pageData.entry[self._curRefId]
        local marketData = entryData.MarketData
        local personal = marketData.personal
        local personalGoal = marketData.personalGoal
        local hasBuyTime = personalGoal == -1 and -1 or personalGoal - personal
        self:SetBuyLimitTxt(hasBuyTime)
        local customGift = marketData.customGift
        if (customGift) then
            self:SetGiftRoot()
        end
    end
end

function UIPop2Gift:ShowRewardList(ref, root)
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

    local giftData = gModelPopupGift:GetGiftByRefId(ref.refId, ref.sid)

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

    local minRoot = CS.FindTrans(root, "ItemScroll_3")
    local moreRoot_1 = CS.FindTrans(root, "ItemScroll_1")
    local moreRoot_2 = CS.FindTrans(root, "ItemScroll_2")
    CS.ShowObject(minRoot, true)
    CS.ShowObject(moreRoot_1, true)
    CS.ShowObject(moreRoot_2, true)

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

function UIPop2Gift:OnClickClose()
    local gift = self:GetCurActiveGift()
    if gift then
        local giftGroupCount = gift.ref.giftGroupCount
        local attr1 = gModelPopupGift:FormatPopGiftStr(gift, giftGroupCount)
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "close", attr1)
    end
    --FireEvent(EventNames.REFRESH_ACTIVITY_POPGIFT_DATA)
    self:WndClose()
end

function UIPop2Gift:SetGiftRoot()
    CS.ShowObject(self.mRoot1, true)
    CS.ShowObject(self.mIcePart, false)
    self:TimerStop(self._iceCountDown)

    local list = gModelPopupGift:GetGiftArrByRefId(self._curRefId, self._curSid)
    if (self._curSid) then
        self:ActivitySandNewGift(list)
    end
    local curMaxGiftLv = -1

    local curSelect = -1

    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    for i, v in ipairs(list) do
        local _gift = gModelPopupGift:GetGiftByRefId(v.refId, v.sid) --取最新的数据
        if _gift then
            local _refGiftGroupCount = _gift.ref.giftGroupCount
            if _refGiftGroupCount == 0 then
                _refGiftGroupCount = 1
            end
            curMaxGiftLv = math.max(_refGiftGroupCount, curMaxGiftLv)
        end

        if v.refId == self._curRefId then
            curSelect = i
        end
    end

    self._curMaxGiftLv = curMaxGiftLv

    self._tabTransList = {}

    self._giftArrList = list
    local tabScroll = self:FindWndTrans(self.mRoot1, "TabScroll")
    local TabScrollBg = self:FindWndTrans(self.mRoot1, "TabScrollBg")
    local isMoreType = #list > 1
    CS.ShowObject(tabScroll, isMoreType)
    CS.ShowObject(TabScrollBg, isMoreType)

    if #list > 1 then
        local _uitabList = self:FindUIScroll("tabScroll1")

        if _uitabList then
            _uitabList:RefreshList(list)
        else
            _uitabList = self:GetUIScroll("tabScroll1")
            _uitabList:Create(tabScroll, list, function(...)
                self:TabListItem(...)
            end)
        end
    end
    local _tabPos = curSelect == -1 and 1 or curSelect
    --printInfoN(string.format("tabpos %s", curSelect))
    self:OnClickTab(_tabPos)
end
function UIPop2Gift:InitGiftList()
    local list = self._dataList
    if (#list < 1) then
        self:WndClose()
        return false
    end
    CS.ShowObject(self.mGiftScroll1, false)
    CS.ShowObject(self.mGiftScroll2, false)
    CS.ShowObject(self.mLeftBtn, false)
    CS.ShowObject(self.mRightBtn, false)

    self._giftTransList = {}
    CS.ShowObject(self.mGiftBg, #list > 1)

    if (#list <= 4) then
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

        _uiGiftList2:MoveToPos(self._index)
    end
end

function UIPop2Gift:SetTime()
    local _gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
    local _desTrans = self.mCutDownTime
    if not _desTrans or not _gift then
        if (self._curSid and self._curRefId) then
            self:OnClickClose()
        end
        return
    end
    local time = GetTimestamp()
    local endTime = _gift.endTime / 1000
    local timespan = endTime - time
    if (timespan <= 0) then
        self:TimerStop(self._timeKey)
        if (_gift.isActivity) then
            self:OnClickClose()
        end
        return
    end
    local ref = _gift.ref
    local timeStr = LUtil.FormatTimespanNumber(timespan)

    local description = ccClientText(45301)
    local str = string.replace(description, timeStr)

    --if not self.mCutDownTimeDiv.gameObject.activeSelf then
    --    CS.ShowObject(self.mCutDownTimeDiv, true)
    --end

    --self:SetWndText(self.mIntro, str)
    self:SetWndText(self.mCutDownTime, str)
    --self:UpdateResultText(desText, _desTrans, str)
    self:UpdateResultText(self.mCutDownTime, self.mCutDownTimeDiv, str)
end

function UIPop2Gift:UpdateResultText(ResultText, ResultNode, text, normalized)
    self:SetWndText(ResultText, text)
    self:StartDelayTimer(ResultNode, normalized)
end

function UIPop2Gift:OnActivityPageResp(pb, ret)
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

function UIPop2Gift:StopDelayTimer()
    if self._delayUpdateScrollTimer then
        LxTimer.DelayTimeStop(self._delayUpdateScrollTimer)
        self._delayUpdateScrollTimer = nil
    end
end

function UIPop2Gift:OnPopupDataListChange()
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
            end
        end
    end
    local dataList, index = gModelPopupGift:GetPopGiftShowList(curId, 0)
    self._dataList = dataList
    index = index or 1
    self._index = index
    self:InitGiftList()

    local needJump = #dataList > 5
    self:OnSelectIndex(index, needJump)
    self:RefreshTopContent()
end

function UIPop2Gift:JumpTargetGift(giftPos)
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
function UIPop2Gift:CheckCurActGiftIsSoleOut()
    if (self._curSid) then
        local pageData = self._activityPageKeyList[self._curSid][1]
        local entryData = pageData.entry[self._curRefId]
        local marketData = entryData.MarketData
        local personal = marketData.personal
        local personalGoal = marketData.personalGoal
        local hasBuyTime = personalGoal == -1 and -1 or personalGoal - personal
        return hasBuyTime ~= -1 and hasBuyTime <= 0
    end
end

function UIPop2Gift:OnClickTab(itempos)
    if self._tabIndex > 0 then
        local trans = self._tabTransList[self._tabIndex]
        self:ChangeGiftImage(trans, false)
    end
    local trans = self._tabTransList[itempos]
    self:ChangeGiftImage(trans, true)
    self._tabIndex = itempos

    if (self._curSid and (not self._giftArrList or not self._giftArrList[itempos])) then
        self:OnClickClose()
        return
    end

    local ref = self._giftArrList[itempos]

    self._curRefId = ref.refId
    self._curSid = ref.sid
    self._curGiftGroup = ref.giftGroup

    self:TimerStop(self._timeKey)

    if (not ref) then
        self:OnClickClose()
        return
    end

    if (ref.isActivity) then
        local isSoldGroupOver = self:CheckSoleGroupOver(ref.giftGroup, ref.sid)
        if (isSoldGroupOver) then
            self:OnClickClose()
            return
        end
    end

    self:SetGiftInfo(self.mRoot1, ref)

    if not self._giftTransList then
        return
    end
    local trans = self._giftTransList[self._giftIndex]
    if not CS.IsValidObject(trans) then
        return
    end

    local rateText = self:FindWndTrans(trans, "Root/RateBg/RateText")
    if (ref) then
        self:SetWndText(rateText, ref.discount .. "%+")
    end
end

function UIPop2Gift:CheckSoleGroupOver(giftGroup, sid)
    if (not self._activityPageKeyList) then
        return
    end
    local giftGroupList = gModelPopupGift:GetActivityGiftArrListByGroup(sid, giftGroup)
    if (giftGroupList) then
        if (not self._activityPageKeyList[sid]) then
            return
        end
        local pageData = self._activityPageKeyList[sid][1]
        local buyCnt = 0
        local giftCnt = 0
        for i, v in pairs(giftGroupList) do
            giftCnt = giftCnt + 1
            local entryData = pageData.entry[v.refId]
            local marketData = entryData.MarketData
            local personal = marketData.personal
            local personalGoal = marketData.personalGoal
            if (personalGoal ~= -1 and personalGoal - personal == 0) then
                buyCnt = buyCnt + 1
            end
        end
        return buyCnt == giftCnt
    end
end

function UIPop2Gift:OnDrawItem(list, item, itemdata, itempos)
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

function UIPop2Gift:ShowIcePart()
    CS.ShowObject(self.mRoot1, false)
    self:TimerStop(self._timeKey)
    CS.ShowObject(self.mIcePart, true)

    local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)

    self:TimerStop(self._iceCountDown)
    self:TimerStart(self._iceCountDown, 1, false, -1)
    self:SetIceCountDown()

    local spPos = self:FindWndTrans(self.mIcePart, "spPos")
    local giftRef = gift.ref
    self:ShowRewardList(giftRef, self.mItemList)

    self:SetSpine(giftRef.showHero, giftRef.showXY, spPos)

    self:SetPayBtn(self.mPayBtn, gift.ref)
    local refId = gift.ref.refId
    local wndName = self:GetWndName()

    self:SetWndClick(self.mPayBtn, function()
        local customReward = self._curSid and "" or nil
        if (self._curSid and self._activityPageKeyList) then
            customReward = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
        end
        gModelPopupGift:BuyGift(refId, wndName, self._curSid, customReward)
    end)

end

function UIPop2Gift:InitMessage()
    self:WndNetMsgRecv(LProtoIds.PopupGiftNowListResp, function(...)
        self:OnPopupDataListChange()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:OnActivityPageResp(...)
    end)
end

function UIPop2Gift:CheckActivityIsBuy(sid, entryId)
    local apList = self._activityPageKeyList
    if (apList and apList[sid]) then
        local page = apList[sid][1]
        if (page and page.entry[entryId]) then
            local entryData = page.entry[entryId]
            if (entryData) then
                local marketData = entryData.MarketData
                local personal = marketData.personal
                local personalGoal = marketData.personalGoal
                local lastBuyTime = personalGoal - personal
                return lastBuyTime == 0
            end
        end
        return
    end
end

function UIPop2Gift:GetCurActiveGift()
    local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
    if not gift then
        gift = self._curActiveGift
    end

    return gift
end

function UIPop2Gift:JumpTargetGiftDelay(giftPos)
    if not self._uiGiftList2 then
        local list = self._uiGiftList2:GetList()
        if (not list) then
            return
        end
        list:DelayScrollTo(giftPos, UIListEasy.SCROLL_CENTER)
    end
end
function UIPop2Gift:OpenCustomWnd(index)
    local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)

    if not gift then
        local str = ccClientTextccClientText(14911)-- "当前礼包不可购买")
        GF.ShowMessage(str)
        return
    end
    local ref = gift.ref
    if string.isempty(ref.rewardFree) then
        return
    end

    local marketData = {
        customList = ref.rewardFree,
        customGift = gift.reward
    }
    if (self._curSid and ref.isActivity) then
        marketData.customGift = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
    end
    local giftData = {
        marketData = marketData
    }
    local isSoleOut = self:CheckCurActGiftIsSoleOut()
    if (isSoleOut) then
        local targetGiftArr = string.split(marketData.customGift, ",")
        local tmpGiftDataArr = string.split(targetGiftArr[1], "=")
        local data = { itemId = tonumber(tmpGiftDataArr[2]), itemType = tonumber(tmpGiftDataArr[1]), itemNum = tonumber(tmpGiftDataArr[3]) }
        gModelGeneral:ShowCommonItemTipWnd(data)
        return
    end
    local giftName = ref.isActivity and ref.giftName or ccLngText(ref.giftName)
    local windType = ref.isActivity and 1 or 2
    local para = {
        wndType = windType,
        id = gift.id,
        itemIndex = index,
        giftData = giftData,

        title = giftName,

        sid = ref.sid,
        pageId = ref.pageId,
        entryId = ref.refId
    }

    printInfoN("refId " .. ref.refId)
    GF.OpenWnd("UICumSelectNew", para)
end

--点击购买
function UIPop2Gift:OnClickPay()
    local wndName = self:GetWndName()
    local customReward = self._curSid and "" or nil
    if (self._curSid and self._activityPageKeyList) then
        customReward = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
    end
    gModelPopupGift:BuyGift(self._curRefId, wndName, self._curSid, customReward)
end

function UIPop2Gift:GetCanBuyRefId()
    local checkRefId = -1
    for k, v in ipairs(self._giftArrList) do
        local guyGift = gModelPopupGift:GetGiftByRefId(v.refId, v.sid)

        if guyGift then
            if checkRefId > v.refId or checkRefId == -1 then
                checkRefId = v.refId
            end
        end
    end

    return checkRefId

end
--活动新触发标记
function UIPop2Gift:ActivitySandNewGift(giftList)
    local giftIdList = ""
    for i, v in pairs(giftList) do
        giftIdList = giftIdList == "" and tostring(v.refId) or giftIdList .. "," .. v.refId
    end
    gModelActivity:OnActivitySpecialOpReq(self._curSid, 1, self._curRefId, nil, giftIdList, ModelActivity.POPUP_NEW_GIFT)
end

function UIPop2Gift:ChangeGiftImage(trans, bool, isGift)
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


    if self._isEnus then
        self:InitTextLineWithLanguage(SelNameText,-20)
        self:InitTextLineWithLanguage(nameText,-20)
    end

    --if Image and isGift then
    --	local rotation = bool and Quaternion.Euler(0, 0, 0) or Quaternion.Euler(0, 0, 90)
    --	Image.localRotation = rotation
    --
    --	local scale = bool and Vector3(1, 1, 1) or Vector3(0.8, 0.8, 0.8)
    --	RootTrans.localScale = scale
    --end

    CS.ShowObject(selImage, bool)
    CS.ShowObject(nameText, not bool)
    CS.ShowObject(SelNameText, bool)
end

function UIPop2Gift:RefreshTopContent()
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

    local type = gift.isActivity and 2 or gift.ref.giftType
    if type == 1 then
        self:ShowIcePart()
    else
        self:SetGiftRoot()
    end
end

function UIPop2Gift:TabListItem(list, item, itemdata, itempos)
    self._tabTransList[itempos] = item
    local InstanceID = item:GetInstanceID()
    self:ChangeGiftImage(item, false)
    local text = self:FindWndTrans(item, "NameText")
    local SelNameText = self:FindWndTrans(item, "SelNameText")
    local eff = self:FindWndTrans(item, "Eff")
    local giftGradeName = itemdata.isActivity and  ccLngText(itemdata.giftGradeName)  or ccLngText(itemdata.giftGradeName)
    local str = string.replace(ccClientText(14908), giftGradeName)
    self:SetWndText(text, str)
    self:SetWndText(SelNameText, str)
    local isShowEff = itemdata.buyType == 1
    isShowEff = false
    CS.ShowObject(eff, isShowEff)
    if isShowEff then
        self:CreateWndEffect(eff, "fx_zuanshilibao", InstanceID, 100, false, false)
    end

    self:SetWndClick(item, function()
        local gift = self:GetCurActiveGift()
        local giftGroupCount = itemdata.giftGroupCount
        local attr1 = gModelPopupGift:FormatPopGiftStr(gift, giftGroupCount)
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "gift_detail_select", attr1)

        self:OnClickTab(itempos)
    end)
end

--设置形象
function UIPop2Gift:SetSpine(showHero, showXY, spPos)
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

    self:CreateWndSpine(spPos, spine, key, false, function(dpSpine)
        local dpTrans = dpSpine:GetDisplayTrans()
        dpTrans.anchorMin = Vector2.New(0.5, 0.5)
        dpTrans.anchorMax = Vector2.New(0.5, 0.5)
        self:SetAnchorPos(spPos, Vector2(x, y))
    end)
    self._oldKey = key
    self._oldSpine = spine
end

function UIPop2Gift:InitCommand()
    local curId = self:GetWndArg("id")
    local index = self:GetWndArg("index")
    local dataList = self:GetWndArg("dataList")

    if not dataList then
        dataList, index = gModelPopupGift:GetPopGiftShowList(curId, 0)
    end
    self._index = index or 1
    self._dataList = dataList
    self:InitGiftList()

    local needJump = #dataList > 5

    self:OnClickGift(self._index, needJump)
end

function UIPop2Gift:SetGiftInfo(root, ref)
    local heroSpine = self:FindWndTrans(root, "HeroSpine")
    local heroNameText = self:FindWndTrans(root, "DesImage/HeroNameText")

    --local rateText = self:FindWndTrans(root,"RateText")
    --local enrateText = self:FindWndTrans(root,"enRateText")
    local itemScroll = self:FindWndTrans(root, "ItemScroll")
    local payBtn = self:FindWndTrans(root, "PayBtn")
    local payText1 = self:FindWndTrans(root, "PayBtn/TextMg/PayText1")
    local payIcon = self:FindWndTrans(root, "PayBtn/TextMg/PayIcon")
    local payText2 = self:FindWndTrans(root, "PayBtn/TextMg/PayText2")
    local cutBtn = self:FindWndTrans(root, "CutBtn")
    local cutText = self:FindWndTrans(root, "CutBtn/CutText")
    local payMask = self:FindWndTrans(root, "PayMask")
    local buyLimitTxt = self:FindWndTrans(root, "BuyLimitTxt")

    --CS.ShowObject(self.mCutDownTimeDiv, false)

    self.buyLimitTxt = buyLimitTxt
    self.payBtn = payBtn
    self.payMask = payMask
    CS.ShowObject(payIcon, false)
    CS.ShowObject(payMask, false)
    self:SetWndText(payText1, "")
    self:SetWndText(payText2, "")
    -- CS.ShowObject(cutBtn, true)
    if (not ref) then
        self:OnClickClose()
        return
    end
    self:SetSpine(ref.showHero, ref.showXY)

    local desStr = ""
    local butStr = ""
    local cutStr = ""

    local guyGift = gModelPopupGift:GetGiftByRefId(ref.refId, ref.sid)
    --self._guyGift = guyGift

    CS.ShowObject(payBtn, true)

    local curMaxGiftLv = self._curMaxGiftLv

    local isCountDown = false

    local rId = guyGift and guyGift.ref.refId or nil
    local giftList = rId and gModelPopupGift:GetGiftArrByRefId(rId, self._curSid) or nil
    local isBuyPrior, pGift, pIndex
    if (giftList and guyGift.isActivity and #giftList > 1) then
        if (ref.activateType == 0) then
            isBuyPrior, pGift, pIndex = self:CheckActivityIsBuyPrior(giftList, guyGift.ref.refId)
        end
        isBuyPrior = isBuyPrior or self:CheckActivityIsBuy(ref.sid, ref.refId)
    end
    local showActSoldOutTxt = false
    local showBuyLimitTxt = guyGift and guyGift.isActivity and not isBuyPrior
    CS.ShowObject(self.buyLimitTxt,showBuyLimitTxt)

    local payIconPath
    local showPayIcon = false
    local isSoldOut = false
    if guyGift and not isBuyPrior then
        --后端有发礼包
        if (buyLimitTxt and guyGift.isActivity and self._activityPageKeyList and self._activityPageKeyList[self._curSid]) then
            local pageData = self._activityPageKeyList[self._curSid][1]
            local entryData = pageData.entry[self._curRefId]
            local marketData = entryData.MarketData
            local personal = marketData.personal
            local personalGoal = marketData.personalGoal
            local hasBuyTime = personalGoal == -1 and -1 or personalGoal - personal
            self:SetBuyLimitTxt(hasBuyTime)
            showActSoldOutTxt = true
        end

        self._desTrans = resultNode
        CS.ShowObject(cutBtn, false)
        local payStr = ""
        if (ref.buyType == ModelPopupGift.BUYTYPE_JEWEL or ref.buyType == ModelPopupGift.BUYTYPE_CURRENCY) then
            showPayIcon = true
            local item = LxDataHelper.ParseItem_3(ref.expend)
            payIconPath = gModelItem:GetItemIconByRefId(item.itemId)
            payStr = item.itemNum
        elseif (ref.buyType == ModelPopupGift.BUYTYPE_MONEY) then
            payStr = gModelPay:GetShowByWelfareId(tonumber(ref.expend))
        elseif (ref.buyType == ModelPopupGift.BUYTYPE_FREE) then
            payStr = ccClientText(14903)
        end
        butStr = guyGift.isActivity and ref.buyBtnTxt or ccLngText(ref.buyBtnTxt)
        self:SetWndText(payText2, payStr)
        isCountDown = true
        self:SetTime()
        self:TimerStart(self._timeKey, 1, false, -1)
        CS.ShowObject(self.mCutDownTimeDiv, true)
    else
        if (ref.isActivity) then
            isSoldOut = self:CheckActivityIsBuy(ref.sid, ref.refId)
        else
            if ref.activateType == 1 then
                isSoldOut = true
            else
                isSoldOut = ref.giftGroupCount < curMaxGiftLv or curMaxGiftLv == -1
            end
        end

        local isLimitBuy = checknumber(ref.giftLinkType) == 1

        if not isLimitBuy then
            --不是限制购买 且没有数据 --则售卖完了
            isSoldOut = true
        end

        if isSoldOut then
            --前一档礼包
            CS.ShowObject(cutBtn, false)
            CS.ShowObject(payBtn, false)
            self:SetWndText(self.mPayMaskText, ccClientText(45302))
            CS.ShowObject(self.mCutDownTimeDiv, false)
            desStr = ref.isActivity and ref.descriptionSaleOut or ccLngText(ref.descriptionSaleOut)

            --后端有发礼包
            if (buyLimitTxt and guyGift and guyGift.isActivity and self._activityPageKeyList and self._activityPageKeyList[self._curSid]) then
                local pageData = self._activityPageKeyList[self._curSid][1]
                local entryData = pageData.entry[self._curRefId]
                local marketData = entryData.MarketData
                local personal = marketData.personal
                local personalGoal = marketData.personalGoal
                local hasBuyTime = personalGoal == -1 and -1 or personalGoal - personal
                self:SetBuyLimitTxt(hasBuyTime)
                showActSoldOutTxt = true
                CS.ShowObject(self.mBuyLimitTxt, true)
            else
                local str = ref.limit > 0 and ccClientText(45303) or ccClientText(45304)
                local curCanBuy = 0
                str = string.replace(str, curCanBuy)
                self:SetWndText(self.mBuyLimitTxt, str)
            end
        else
            desStr = ref.isActivity and ref.descriptionNo or ccLngText(ref.descriptionNo)
            local currBuyGift = self._giftArrList[curMaxGiftLv]
            local giftGradeName = ref.isActivity and pGift.giftGradeName or ccLngText(currBuyGift.giftGradeName)
            butStr = string.replace(ccClientText(14910), giftGradeName)
            cutStr = string.replace(ccClientText(14909), giftGradeName)
        end
    end

    CS.ShowObject(payMask, isSoldOut)

    local showAd = false
    if not isSoldOut and self:GetWndAdBtnShowStatus({
        adMethodId = adMethodId,
        refId = rId,
        giftRefId = ref.refId,
        giftSid = ref.sid,
        checkHasCount = true,
    }) then
        showAd = true
        showPayIcon = true
        payIconPath = "adShop_btn_1"
        self:SetWndText(payText2, ccClientText(47103))
    end
    if showPayIcon and payIconPath then
        self:SetWndEasyImage(payIcon, payIconPath,function()
            CS.ShowObject(payIcon,true)
        end)
    end

    self:SetWndText(payText1, butStr)

    self:SetWndText(cutText, cutStr)

    local rateStr = LUtil.FormatHurtNumSpriteText(ref.discount)
    self:SetWndText(self.mRateText, rateStr)
    --设置描述的信息
    --local desStr = ref.isActivity and ref.description or ccLngText(ref.description)
    if string.isempty(desStr) then
        desStr = ref.isActivity and ref.description or ccLngText(ref.description)
    end
    self:SetWndText(self.mInfoUIText, ccLngText(desStr))

    local space = -12
    local size = 66
    local padding = { x = -6, y = -6 }

    if gLGameLanguage:IsEnglishVersion() then
        space = -12
        padding = { x = 8, y = 8 }
    elseif gLGameLanguage:IsJapanVersion() then

    elseif gLGameLanguage:IsForeignVersion() then
        space = 0
        padding = { x = 0, y = 4 }
    end

    local parent = self.mRateText.parent
    local layoutGroup = self:FindCommonComponent(parent, typeHorizontalLayoutGroup)
    layoutGroup.padding.left = padding.x
    layoutGroup.padding.right = padding.y
    local textCom = self:FindCommonComponent(self.mRateText, typeUIText)
    textCom.fontSize = size
    textCom.characterSpacing = space

    self:ShowRewardList(ref, itemScroll)

    --设置下状态  4000001
    if guyGift then
        local curCanBuy = guyGift.ref.limit > 0 and guyGift.ref.limit or guyGift.ref.lifetimeLimit

        curCanBuy = curCanBuy - guyGift.buyNum
        if curCanBuy > 0 then
            if not showActSoldOutTxt then
                local str = guyGift.ref.limit > 0 and ccClientText(45303) or ccClientText(45304)
                str = string.replace(str, curCanBuy)
                self:SetWndText(self.mBuyLimitTxt, str)
                CS.ShowObject(self.mBuyLimitTxt, true)
            end
        else
            CS.ShowObject(self.mBuyLimitTxt, false)
        end
    else
        if not showActSoldOutTxt then
            local curCanBuy = ref.limit > 0 and ref.limit or ref.lifetimeLimit
            local str = ref.limit > 0 and ccClientText(45303) or ccClientText(45304)

            if payMask.gameObject.activeSelf then
                curCanBuy = 0
            end

            str = string.replace(str, curCanBuy)
            self:SetWndText(self.mBuyLimitTxt, str)
            CS.ShowObject(self.mBuyLimitTxt, true)
        end
    end

    --获取当前组可以购买的最小的group数据
    local canBuyRefId = self:GetCanBuyRefId()
    local isCanBuy = false
    --是否需要限制购买
    local isLimitBuy = checknumber(ref.giftLinkType) == 1

    --或者对应的id 部分和设置
    if canBuyRefId == ref.refId or (not isLimitBuy) then
        isCanBuy = true

    elseif canBuyRefId > ref.refId then
        --当前的是售卖完 -- 这里不处理  旧有的处理 已经处理

    elseif canBuyRefId < ref.refId then
        --下一档
        desStr = ccLngText(ref.descriptionNo)
        local TextMg = self:FindWndTrans(self.mPayBtn, "TextMg")
        local TextMgPayText2 = self:FindWndTrans(TextMg, "PayText2")
        local lastKey = ref.giftGroupCount - 1
        local lastRef = self._giftArrList[lastKey]

        if lastRef then
            desStr = string.replace(ccClientText(14910), ccLngText(lastRef.giftGradeName))
        end

        self:SetWndText(TextMgPayText2, desStr)
        self:SetWndText(payText1, "")

    end

    self:SetWndClick(cutBtn, function()
        if (ref.isActivity) then
            self:OnClickTab(pIndex)
        else
            self:OnClickTab(curMaxGiftLv)
        end
    end)

    if showAd then
        self:SetWndAdBtnInfo(payBtn,{
            adMethodId = adMethodId,
            refId = rId,
            giftRefId = ref.refId,
            giftSid = ref.sid,
            checkHasCount = true,
            wndId = 490005,
        })
    else
        self:SetWndClick(payBtn, function()
            if not isCanBuy then
                GF.ShowMessage(desStr)
                return
            end
            if guyGift and not pGift then
                self:OnClickPay()
            else
                if (ref.isActivity) then
                    self:OnClickTab(pIndex)
                else
                    self:OnClickTab(curMaxGiftLv)
                end
            end

        end)
    end
end

function UIPop2Gift:SetPayBtn(item, ref)
    local TextMg = self:FindWndTrans(item, "TextMg")
    local TextMgPayText1 = self:FindWndTrans(TextMg, "PayText1")
    local TextMgPayIcon = self:FindWndTrans(TextMg, "PayIcon")
    local TextMgPayText2 = self:FindWndTrans(TextMg, "PayText2")

    CS.ShowObject(TextMgPayIcon, false)

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

    local canBuyRefId = self:GetCanBuyRefId()

    if canBuyRefId == ref.refId then

    elseif canBuyRefId > ref.refId then
        --当前的是售卖完 -- 这里不处理  旧有的处理 已经处理

    elseif canBuyRefId < ref.refId then
        --下一档
        payStr = gModelPay:GetShowByWelfareId(tonumber(ref.expend))
        self:SetWndText(TextMgPayText2, payStr)
    end


end

function UIPop2Gift:SetBuyLimitTxt(hasBuyTime)
    if (not self.buyLimitTxt) then
        return
    end
--[[    local limitColor = hasBuyTime > 0 and "<#139057>" or "<#c81212>"
    local buyLimitStr = hasBuyTime == -1 and "" or string.format("%s%s%s%s", ccClientText(31700), limitColor, tostring(hasBuyTime), "</color>")]]


    local buyLimitStr = hasBuyTime == -1 and "" or string.format("%s%s", ccClientText(31700), tostring(hasBuyTime))

    --self:SetWndText(self.buyLimitTxt, buyLimitStr)
    CS.ShowObject(self.payMask, hasBuyTime == 0 and hasBuyTime ~= -1)
    CS.ShowObject(self.payBtn, hasBuyTime ~= 0)
    self:SetWndText(self.mBuyLimitTxt, buyLimitStr)
end

function UIPop2Gift:SetIceCountDown()
    local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
    local ref = gift.ref
    local endTime = gift.isActivity and gift.endTime or gift.endTime / 1000
    local timespan = math.ceil(endTime - GetTimestamp())
    if timespan > 0 then
        local timeStr = LUtil.FormatTimespanNumber(timespan)
        local description = ref.isActivity and ref.description or ccLngText(ref.description)
        local str = string.replace(description, timeStr)
        self:SetWndText(self.mIntro, str)
    else
        self:TimerStop(self._iceCountDown)
        if (gift.isActivity) then
            self:OnClickClose()
        end
    end

end

function UIPop2Gift:OnTimer(key)
    if (key == self._timeKey) then
        self:SetTime()
    elseif key == self._iceCountDown then
        self:SetIceCountDown()
    end
end

function UIPop2Gift:InitEvent()
    self:SetWndClick(self.mCloseBtn, function(...)
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBtnClose, function()
        self:OnClickClose()
    end)

    self.mIntro.sizeDelta = Vector2(480, 55)
end

--检查活动弹框是否购买前置礼包
function UIPop2Gift:CheckActivityIsBuyPrior(giftList, curRefId)
    if (not self._activityPageKeyList) then
        return
    end
    for i, v in pairs(giftList) do
        local priorRefId = giftList[i].refId
        if (not self._activityPageKeyList[self._curSid]) then
            return
        end
        local pageData = self._activityPageKeyList[self._curSid][1]
        local entryData = pageData.entry[priorRefId]
        local marketData = entryData.MarketData
        local personal = marketData.personal
        if (personal == 0 and priorRefId < curRefId) then
            return true, giftList[i], i
        end
    end
end

function UIPop2Gift:OnClickGift(itempos, needJump)
    self._curRefId = nil
    self:OnSelectIndex(itempos, needJump)
    self:RefreshTopContent()
    self:ChackHadActivityItem()
end

function UIPop2Gift:ChackHadActivityItem()
    if (self._dataList and self._dataList[self._index] and self._dataList[self._index][1]) then
        local curData = self._dataList[self._index][1]
        if (curData.isActivity) then
            gModelActivity:OnActivityPageReq(curData.sid)
        end
    end
end
------------------------------------------------------------------
return UIPop2Gift