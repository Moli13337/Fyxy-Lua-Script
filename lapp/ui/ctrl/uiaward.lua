---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAward:LWnd
local UIAward = LxWndClass("UIAward", LWnd)
local Tweening = DG.Tweening

UIAward.USE_ITEM_UPHEROINFO = "704"
UIAward.UP_OUTFIT_RETURNITEM = "44010"
--UIAward.TREASURE_ADD_MARK = "TREASURE_ADD_MARK"
UIAward.DREAMTRIP_REWARD = "com.ct1.protobuf.DreamTripProto"
UIAward.ACTIVITY_DREAMTRIP_REWARD = "com.ct1.protobuf.ActivityProto"
UIAward.ACTIVITY_DREAMTRIP_SKILLBOSS = 2166
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAward:UIAward()
    ---@type table<number,CommonIcon>
    self._uicommonList = {}

    self._uiList = nil
    self._waitCloseTimeKey = "_waitCloseTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAward:OnWndClose()
    --self:ClearTween()
    if self._uicommonList then
        local iconList = self._uicommonList
        for k, v in pairs(iconList) do
            v:Destroy()
            iconList[k] = nil
        end
        self._uicommonList = nil
    end

    local parameters = self._parameters
    if parameters then
        local portId = parameters[1]
        if portId == UIAward.USE_ITEM_UPHEROINFO then
            gModelHero:SelItemUpHeroIdList()
        end
    end

    if self._ways then
        if self._ways == 2115 then
            FireEvent(EventNames.ON_ACTIVITY_INVITE_OPENWND)
        elseif self._ways == UIAward.ACTIVITY_DREAMTRIP_SKILLBOSS then
            FireEvent(EventNames.ON_DREAMTRIP_SKILLBOSSCLEAR)
        elseif self._ways == 1401 then
            local recordItemList = self:GetWndArg("recordItemList") or {}
            FireEvent(EventNames.ON_DREAMTRIP_SHOWGET, {
                rewardList = recordItemList
            })
        elseif self._ways == 4112 then
            FireEvent(EventNames.BADGE_SHOW_REWARD,0)
        end
    end

    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end
    --gModelGeneral:OpenPopWnd()
    if self._callBackFunc then
        self._callBackFunc()
    end
    --gModelPlayer:GetUpVipFunc()

    --FireEvent(EventNames.CHECK_WAIT_GUIDE)
    FireEvent(EventNames.CLOSE_REWARD_WND)

    if LOG_INFO_ENABLED then
        print("wndReward close")
    end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAward:OnCreate()
    LWnd.OnCreate(self)

    self._seqCom = SequenceCom:New()
    self._curItemTweenList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAward:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitData()
    self:InitEvent()

    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_EQUIP_COMMON)
    self:SetGetText()
    self:StartTween()
end
function UIAward:InitText()
    --if self._title then
    --	self:SetWndTitleByTitle(self.mTitle,self._title)
    --else
    --	self:SetWndTitleByTextId(self.mTitle,self._titleId)
    --end
    self:SetWndText(self.mCloseTip, ccClientText(10103))

    if self._btnTextList then
        for i, text in ipairs(self._btnTextList) do
            local str = "Btn" .. i
            local root = self:FindWndTrans(self.mBtnList, str)
            local textTrans = self:FindWndTrans(root, "Text")
            self:SetWndText(textTrans, text)
        end
    end
end

function UIAward:OnTimer(key)
    if key == self._waitCloseTimeKey then
        self._waitClose = false
        self:SetCloseTipTransShow(true)
    end
end

function UIAward:OnClickEmpty()
    if self._waitClose then
        return
    end
    if self._isCreateAni then
        return
    end

    if not self._seqCom then
        return
    end

    local seq = self._seqCom:FindSeq(self._startTweenKey)
    if seq then
        self._seqCom:DeleteSeq(self._startTweenKey)
        local contentTrans = self.mContent
        contentTrans.localRotation = Quaternion.Euler(0, 0, 0)
        self:RefreshUI()
    else
        self:WndClose()
    end
end

function UIAward:TweenItemScale(item, itempos, isNeedPlayAni)
    local nowTime = Time.time
    local timePast = nowTime - self._startTime
    local delay = itempos * self._iconPlayTime

    if timePast > delay or self._cancelItemTween then
        item.transform.localScale = Vector3.one
        return
    end
    local curDelay = delay - timePast
    local instanceId = item:GetInstanceID()
    item.transform.localScale = Vector3.zero
    --printInfoN(string.format("create item pos %s instanceId %s delay %s",itempos,instanceId,curDelay))
    local seq = self._seqCom:CreateSeq(instanceId)

    local tween = item:DOScale(Vector3.one, self._iconPlayTime)
    seq:AppendInterval(curDelay)
    if itempos > 8 and itempos % 4 == 1 then
        seq:AppendCallback(function()
            self:MoveContent()
        end)
    end

    seq:Append(tween)
    seq:OnComplete(function()
        self._seqCom:DeleteSeq(instanceId)
        self._curItemTweenList[instanceId] = nil
    end)
    seq:OnKill(function()
        item.transform.localScale = Vector3.one
    end)
    seq:PlayForward()

    self._curItemTweenList[instanceId] = true


end
function UIAward:SetWndRefId(refId)
    self._refId = refId
end

function UIAward:RefreshUI()
    self:InitText()

    self:ShowList()

    self:ShowFixedIntro()

    self:ShowCostInfo()
end

function UIAward:OpenDetailTip(itemdata)
    gModelGeneral:ShowRewardDetailTip(itemdata)
end

function UIAward:OnDrawDetailItem(item, itemdata, itempos, isNeedPlayAni)
    local uicommonlist = self._uicommonList
    local instanceID = item:GetInstanceID()
    local baseClass = uicommonlist[instanceID]
    local uiCommonTrans = CS.FindTrans(item, "CommonUI")

    if not baseClass then
        baseClass = CommonIcon:New()
        uicommonlist[instanceID] = baseClass
        baseClass:Create(CS.FindTrans(uiCommonTrans, "Icon"))
    end

    baseClass:SetRewardDetailItem(itemdata)

    baseClass:DoApply()

    self:SetIconClickScale(item, true)

    local uiNameTrans = CS.FindTrans(uiCommonTrans, "UIName")
    --local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
    if uiNameTrans then
        --local itemname,itemcolor = baseClass:GetName()
        --self:SetXUITextText(uiNameText, itemname or "")
        --if itemcolor then
        --	self:SetXUITextColor(uiNameText, itemcolor)
        --end
        local itemName = gModelGeneral:GetCommonItemColorNameNoNum(itemdata)
        self:SetWndText(uiNameTrans, itemName)
        self:InitTextShowWithLanguage(uiNameTrans)
    end

    self:TweenItemScale(uiCommonTrans, itempos, isNeedPlayAni)
end


--function UIAward :ShowLostTip()
--	local showTip = false
--	local tipContent = nil
--	local para = self._parameters
--	if para and para[1] then
--		local str = para[1]
--		--print("lospara "..str)
--		local s,e,cap1,cap2 = string.find(str,"(%w+):(%w+)")
--		if cap1 and cap2 then
--			if cap1 == "isLose" then
--				showTip = true
--				local isLos = false
--				if cap2 == "true" then
--					isLos = true
--				end
--				tipContent = gModelExplore:GetLosDes(isLos)
--			end
--		end
--	end
--
--	CS.ShowObject(self.mLoseInfo,showTip)
--	if showTip then
--		self:SetWndText(self.mLoseInfo,tipContent)
--	end
--end

function UIAward:StartTween()
    --self:ClearTween()

    self._isCreateAni = true
    local contentTrans = self.mContent
    contentTrans.localRotation = Quaternion.Euler(90, 0, 0)

    local seq = self._seqCom:CreateSeq(self._startTweenKey)

    local duration = 0.4
    local rotateTween = contentTrans:DORotate(Vector3.New(0, 0, 0), duration)
    seq:Append(rotateTween)
    seq:InsertCallback(0.1, function()
        self:RefreshUI()
    end)
    seq:OnComplete(function()
        --self._seq = nil
        self._seqCom:DeleteSeq(self._startTweenKey)
        self._isCreateAni = false
    end)
    seq:PlayForward()

end

function UIAward:ClearBaseClassListAni()
    if self._playAni then
        local list = self._uicommonList
        if not table.isempty(list) then
            for k, v in pairs(list) do
                v:KillAni()
            end
            self._playAni = false
        end
    end
end

function UIAward:OnRewardItemReturn(list, item, itemdata, itempos)
    local instanceId = item:GetInstanceID()
    self._seqCom:DeleteSeq(instanceId)

    self._curItemTweenList[instanceId] = nil
end

function UIAward:OnStartDrag()
    if table.isempty(self._curItemTweenList) then
        return
    end

    self._cancelItemTween = true

    self._seqCom:DeleteSeq("moveContent")
    for k, v in pairs(self._curItemTweenList) do
        self._seqCom:DeleteSeq(k)
    end
    self._curItemTweenList = {}

    local uiList = self._itemSuperList
    local list = uiList:GetList()
    local seq = self._seqCom:CreateSeq("moveContent")
    local duration = 0.2
    local curPos = list:GetContentPosition()
    local endPos = Vector2.zero
    local tween = YXTween.TweenFloat(0, 1, duration, function(t)
        local pos = Vector2.Lerp(curPos, endPos, t)
        list:SetContentPosition(pos)
    end)

    seq:Append(tween)
    seq:PlayForward()

end

function UIAward:OpenUpStarWnd(refId, func)
    local newHero = {}
    table.insert(newHero, { refId = refId })
    gModelGeneral:ShowUpHero(newHero, func)
    --GF.OpenWndTop("UIUpStarSagaSow",{refId = refId,func = func})
end

function UIAward:uilist_2_onDraw(list, item, itemdata, itempos, fromHeadTail)
    local itype = itemdata.itype
    local isId = itemdata.isId
    local refId
    local id
    if isId then
        refId = itemdata.itemId
        id = refId
    else
        refId = tonumber(itemdata.itemId)
    end
    local num = itemdata.count
    local index = itemdata.index

    local setRefId = refId
    if itype == 4 then
        setRefId = nil
        local serverData = gModelRune:GetServerDataById(refId)
        if serverData then
            setRefId = serverData.refId
        end
    end

    local isNeedPlayAni = itemdata.isNeedPlayAni
    itemdata.isNeedPlayAni = false

    if self._detail then
        self:OnDrawDetailItem(item, itemdata, itempos, true)
    else
        self:OnDrawCommonItem(item, itype, id, setRefId, num, itempos, isNeedPlayAni)
    end

    self:SetWndClick(item, function()
        if self._detail then
            self:OpenDetailTip(itemdata)
        else
            self._funcList[itype](refId, num, id, itemdata)
        end
    end)
end
function UIAward:SetListData(itemList)
    self._itemList = itemList
end

function UIAward:InitData()
    self._refId = self:GetWndArg("refId")
    self._itemList = self:GetWndArg("itemList")
    self._title = self:GetWndArg("title")
    self._titleId = self:GetWndArg("titleId")
    self._delay = self:GetWndArg("delay")
    self._sceneId = self:GetWndArg("sceneId")
    self._parameters = self:GetWndArg("parameters")
    self._ways = self:GetWndArg("ways")
    self._waitCloseTime = self:GetWndArg("waitCloseTime")
    self._func = self:GetWndArg("func")
    self._btnTextList = self:GetWndArg("btnTextList")

    self._heroMapList = self:GetWndArg("heroMapList")

    local detail = self:GetWndArg("detail")
    self._detail = detail
    local effect = self:GetWndArg("effect")

    self._callBackFunc = self:GetWndArg("callBackFunc")

    self._isCreateAni = false

    self._uicommonList = {}
    self._playAni = true
    self._iconPlayTime = 0.1
    -- self._playTime = self._playTime
    local itemFunc = function(refId, num)
        --GF.OpenWndUp("UIInip",{refId = refId,showNum = num})
        local type = gModelItem:GetType(refId)
        if type == gModelItem.TTEM_TYPE_DRACONIC_ITEM or type == gModelItem.TTEM_TYPE_DRACONIC then
            num = nil
        end
        gModelGeneral:OpenItemInfoTip(refId, num)
    end
    local heroFunc = function(refId, num, id)
        if id then
            local serverData = gModelHero:GetHeroServerDataById(id)
            refId = serverData.refId
        end
        gModelGeneral:OpenHeroSimpleTip(refId)
    end
    local equipFunc = function(refId)
        GF.OpenWndUp("UIEqInfo", { refId = refId, OpenWay = false, noShowBtn = true })
    end
    local petEquipFunc = function(refId)
        gModelGeneral:OpenEquipInfoTip(refId, nil, nil, true,nil,nil,nil,LItemTypeConst.TYPE_PET_EQUIP)
    end
    local runeFunc = function(id)
        local serverData = gModelRune:GetServerDataById(id)
        if serverData then
            local data = { runeData = serverData }
            gModelGeneral:OpenRuneInfoTip(data)
        end
    end
    local outfitFunc = function(refId)
        local curSerData = {
            refId = refId,
            star = 0,
            heroRefId = 0,
            starExp = 0,
            heroId = "0",
            -- score = gModelOutfit:GetOutfitBaseScoreByRefId(refId),
            score = 0,
            nextHeroRefId = 0,
            _type = LItemTypeConst.TYPE_OUTFIT,
        }
        gModelGeneral:OpenOutfitInfoTip({ curSerData = curSerData, outfitType = 2 }, true)
    end

    local golemFunc = function(refId, num, id, data)
        gModelGeneral:ShowCommonItemTipWnd(data)
    end

    self._funcList = {
        itemFunc,
        heroFunc,
        equipFunc,
        runeFunc,
        outfitFunc,
        golemFunc,
        petEquipFunc,
    }

    local isShow = self._func and true or false
    CS.ShowObject(self.mCloseTip, not isShow)
    CS.ShowObject(self.mBtnList, isShow)

    local effectName = "fx_ui_gongxihuode"
    self:CreateWndEffect(self.mTitle, effectName, effectName, 100)
    self:CreateWndEffect(self.mRewardBg, effect, effect, 100)

    self._startTweenKey = "_startTweenKey"

    self:SetCloseTipTransShow(not self._waitCloseTime)
    if self._waitCloseTime then
        self._waitClose = true
        self:TimerStart(self._waitCloseTimeKey, self._waitCloseTime, true, 1)
    end
end

function UIAward:SetCloseTipTransShow(isShow)
    local isFuncShow = self._func and true or false

    CS.ShowObject(self.mCloseTip, not isFuncShow and isShow)
end
------------------------------------------------------------------
--- 列表
------------------------------------------------------------------
function UIAward:GetUseItemList()
    local list = {}
    local haveList = false
    local parameters = self._parameters
    if parameters then
        local portId = parameters[1]
        if portId == UIAward.USE_ITEM_UPHEROINFO then
            local selHeroList, useItemType = gModelHero:GetSelItemUpHeroIdList()
            if table.isempty(selHeroList) then
                haveList = false
                list = {}
            else
                for k, v in pairs(selHeroList) do
                    table.insert(list, v)
                end
                haveList = true
            end
        elseif portId == UIAward.UP_OUTFIT_RETURNITEM then
            self:SetWndText(self.mParameterTxt, ccClientText(18375))
            --elseif portId == UIAward.TREASURE_ADD_MARK then
        elseif portId == UIAward.DREAMTRIP_REWARD then
            gLGpManager:FindFastDreamTripGp():SetFSMGetEffState()
            self._callBackFunc = function()
                FireEvent(EventNames.ON_DREAMTRIP_SHOWGET)
            end
        elseif portId == UIAward.ACTIVITY_DREAMTRIP_REWARD then
            self._callBackFunc = function()
                local wnd = GF.FindFirstWndByName("UIOrdinResult")
                if not wnd then
                    gModelActivityDreamTrip:CheckSpeedUpCallBackFunc()
                end
            end
        elseif (portId == "SKIN_BOOK") then
            local showStr = string.replace(ccClientText(30211), parameters[2], parameters[3])
            self:SetWndText(self.mParameterTxt, showStr)
        end
    end
    return haveList, list
end

function UIAward:InitMinScrollRect()
    self._startTime = Time.time
    local haveList, selHeroList = self:GetUseItemList()
    local itemRoot = self.mItemRoot
    local itemList = {}
    local itemData = self._itemList
    local selHeroIndex = 1
    for i = 1, #itemData do
        local item = CS.FindTrans(itemRoot, "Item" .. i)
        if item then
            itemList[i] = item
            CS.ShowObject(item, true)

            local shardIconRoot = self:FindWndTrans(item, "ShardIconRoot")
            CS.ShowObject(shardIconRoot, false)

            local data = itemData[i]
            local refId = data.itemId
            local itype = data.itype
            local count = data.count
            local id

            if haveList and itype == 2 then
                id = selHeroList[selHeroIndex] or nil
                selHeroIndex = selHeroIndex + 1
            end

            local setRefId = refId
            if itype == 4 then
                setRefId = nil
                local serverData = gModelRune:GetServerDataById(refId)
                if serverData then
                    setRefId = serverData.refId
                end
            end

            if self._detail then
                self:OnDrawDetailItem(item, data, i, true)
            else
                self:OnDrawCommonItem(item, itype, id, setRefId, count, i, true)
            end

            self:SetWndClick(item, function()
                if self._detail then
                    self:OpenDetailTip(data)
                else
                    self._funcList[itype](refId, count, id, data)
                end
            end)
        end
    end
end

function UIAward:ShowCostInfo()
    CS.ShowObject(self.mCostItem, false)
    local costItem = self:GetWndArg("costItem")
    if not costItem then
        return
    end

    --调整按钮位置
    local pos = self.mBtnList.anchoredPosition
    self:SetAnchorPos(self.mBtnList, Vector2.New(pos.x,pos.y-40))

    CS.ShowObject(self.mCostItem, true)

    local iconTran = CS.FindTrans(self.mCostItem, "Icon")
    local numTran = CS.FindTrans(self.mCostItem, "Num")
    local haveNum = gModelItem:GetNumByRefId(costItem.itemId)
    local costNum = costItem.itemNum

    local icon = gModelItem:GetItemIconByRefId(costItem.itemId)
    self:SetWndEasyImage(iconTran, icon)

    local strcolor = haveNum >= costNum and "#68e6ac" or "#ff7676"
    local shotStr = string.format("<color=%s>%s/%s</color>", strcolor, LUtil.NumberCoversion(haveNum), costNum)
    self:SetWndText(numTran, shotStr)


end

function UIAward:ShowFixedIntro()
    local fixedReward = self:GetWndArg("fixedReward")
    if not fixedReward then
        return
    end

    local rewardStr = string.format("%s%s", fixedReward.itemNum, gModelGeneral:GetCommonItemName(fixedReward))
    local str = string.replace(ccClientText(14619), rewardStr)

    self:SetWndText(self.mFixedIntro, str)
    self:InitTextLineWithLanguage(self.mFixedIntro, -30)

end

function UIAward:ShowList()
    local itemList = self._itemList or {}
    local len = #itemList
    if len <= 4 then
        CS.ShowObject(self.mMinList, true)
        self:InitMinScrollRect()
    else
        self._playAni = false
        CS.ShowObject(self.mMaxList, true)
        self:InitScrollRect()
    end
end

function UIAward:InitEvent()

    self:SetWndClick(self.mMaskBg, function()
        self:OnClickEmpty()
    end)
    self:SetWndClick(self.mRewardBg, function()
        self:OnClickEmpty()
    end)
    self:SetWndClick(self.mContent, function()
        self:OnClickEmpty()
    end)

    self:SetWndClick(self.mBtn1, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtn2, function()
        if self._func then
            self._func()
        end
        self:WndClose()
    end)

    self:SetWndClick(self.mCloseTip, function()
        self:WndClose()
    end)

end

function UIAward:MoveContent()

    if self._cancelItemTween then
        return
    end

    local list = self._itemSuperList:GetList()
    if not list then
        return
    end

    local viewSize = self.mMaxList.rect.size
    local contentSize = list:GetContentSize()
    local itemSize = Vector2.New(140, 140)

    local moveLen = contentSize.y - viewSize.y
    if moveLen <= 0 then
        return
    end
    local disY = -itemSize.y / moveLen

    local dis = Vector2.New(0, disY)
    local duration = 0.4
    local seq = self._seqCom:CreateSeq("moveContent")

    local curPos = list:GetContentPosition()
    local endPos = curPos + dis
    endPos.y = math.max(0, endPos.y)
    local tween = YXTween.TweenFloat(0, 1, duration, function(t)
        local pos = Vector2.Lerp(curPos, endPos, t)
        list:SetContentPosition(pos)
    end)

    seq:Append(tween)

    seq:PlayForward()
end

function UIAward:SetGetText()
    local ways = self._ways
    if not ways then
        return
    end
    local textStr = ""
    if ways == 251 then
        textStr = ccClientText(10169)
    end
    self:SetWndText(self.mParameterTxt, textStr)
end

function UIAward:OnDrawCommonItem(item, itype, id, refId, num, itempos, isNeedPlayAni)
    local uicommonlist = self._uicommonList
    local instanceID = item:GetInstanceID()
    local baseClass = uicommonlist[instanceID]

    local uiCommonTrans = CS.FindTrans(item, "CommonUI")

    if not baseClass then
        baseClass = CommonIcon:New()
        uicommonlist[instanceID] = baseClass
        baseClass:Create(CS.FindTrans(uiCommonTrans, "Icon"))
    end

    if itype == LItemTypeConst.TYPE_HERO and id then
        baseClass:SetHeroPlayer(id)
    else
        baseClass:SetCommonReward(itype, refId, num)
    end

    if itype == LItemTypeConst.TYPE_EQUIP then
        self:SetWndClick(CS.FindTrans(uiCommonTrans, "Icon"), function()
            if itype == LItemTypeConst.TYPE_EQUIP then
                gModelGeneral:OpenEquipInfoTip(refId, nil, nil, true)
            end
        end)
    end

    baseClass:EnableShowNum(true)

    baseClass:DoApply()

    local uiNameTrans = CS.FindTrans(uiCommonTrans, "UIName")
    --local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
    if uiNameTrans then
        local itemName = gModelGeneral:GetCommonItemColorNameNoNum({ itemType = itype, itemId = refId })
        --local itemname,itemcolor = baseClass:GetName()
        --self:SetXUITextText(uiNameText, itemname or "")
        --if itemcolor then
        --	self:SetXUITextColor(uiNameText, itemcolor)
        --end
        self:SetWndText(uiNameTrans, itemName)
        self:InitTextShowWithLanguage(uiNameTrans)
    end

    self:TweenItemScale(uiCommonTrans, itempos, isNeedPlayAni)
end

function UIAward:InitScrollRect()
    self._startTime = Time.time
    local dataList = {}
    local haveList, selHeroList = self:GetUseItemList()
    local list = self._itemList or {}
    local selHeroIndex = 1
    for i = 1, #list do
        local data = list[i]
        data.index = i
        data.isNeedPlayAni = true
        if data.itype == 2 and haveList then
            local id = selHeroList[selHeroIndex]
            if id then
                data.itemId = id
                data.isId = true
            end
            selHeroIndex = selHeroIndex + 1
        end

        table.insert(dataList, data)
    end
    local uiList = self._itemSuperList
    if not uiList then
        uiList = self:GetUIScroll("itemList")
        self._itemSuperList = uiList
        uiList:Create(self.mMaxList, dataList, function(...)
            self:uilist_2_onDraw(...)
        end, UIItemList.SUPER_GRID, false)
        local list = uiList:GetList()
        list:SetFuncOnItemReturn(function(...)
            self:OnRewardItemReturn(...)
        end)
        list:SetOnStartDrag(function()
            self:OnStartDrag()
        end)
    else
        uiList:RefreshData(dataList, true)
    end

    local list = uiList:GetList()
    list:RefreshList()

end
------------------------------------------------------------------
return UIAward