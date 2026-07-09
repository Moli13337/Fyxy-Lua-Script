---
--- Created by Administrator.
--- DateTime: 2023/10/13 21:24:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIQuk:LWnd
local UIQuk = LxWndClass("UIQuk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIQuk:UIQuk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIQuk:OnWndClose()
    --self:ClearTimer()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIQuk:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIQuk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitData()
    self:InitStaticContent()
    self:InitIosShowUI()
    self:InitEvent()
    self:InitMsg()
    self:Refresh()
    self:SetUPAddNum()
    self:ShowPrivi()
end

function UIQuk:Refresh()
    local freeTimeNum = self:GetFreeNum()
    --local showFree = freeTimeNum>0
    --CS.ShowObject(self.mTipText,showFree)
    --if showFree then
    --	local tipText = ccClientText(10771)
    --	self:SetWndText(self.mTipText,tipText)
    --end
    local btnStr = ccClientText(10766)
    self:SetWndButtonText(self.mGoToBtn, btnStr)

    local color = "red"
    local hasFree = freeTimeNum > 0
    if hasFree then
        color = "green"
    end
    local str = ccClientText(10759)
    local txt = string.replace(str, LUtil.FormatColorStr(freeTimeNum, color))
    local isActive = gModelInstance:GetIsPrivilege()

    if not self._isForeign then
        txt = isActive and txt .. ccClientText(19913) or txt
    end
    self:SetWndText(self.mFreeTimeTxt, txt)

    str = ccClientText(10760)
    color = "red"
    local num = self:GetCostNum()
    local hasCost = num > 0
    if hasCost then
        color = "green"
    end
    txt = string.replace(str, LUtil.FormatColorStr(num, color))
    if not self._isForeign then
        txt = isActive and txt .. ccClientText(19914) or txt
    end
    self:SetWndText(self.mPayTimeTxt, txt)

    if hasFree then
        local str = ccClientText(10771)
        local color = 'green'
        self:SetWndText(self.mPayNum, LUtil.FormatColorStr(str, color))
        CS.ShowObject(self.mItemIcon, false)
        CS.ShowObject(self.mPayNum, true)

    elseif hasCost then
        local cost = gModelInstance:GetCurQuickCostConfig()
        if cost and cost ~= 0 then
            local itemId, itemNum = cost.itemId, cost.itemNum
            local icon = gModelItem:GetItemIconByRefId(itemId)
            local haveNum = gModelItem:GetNumByRefId(itemId)
            local _color = "green"
            if haveNum < itemNum then
                _color = "red"
            end
            self:SetWndEasyImage(self.mItemIcon, icon)
            self:SetWndText(self.mPayNum, cost.itemNum)
        end
        CS.ShowObject(self.mItemIcon, true)
        CS.ShowObject(self.mPayNum, true)
    else
        CS.ShowObject(self.mItemIcon, false)
        CS.ShowObject(self.mPayNum, false)
    end

    local quickBaseTime = gModelInstance:GetInstancePara("QuickAwardTime")
    --local vipLv = gModelPlayer:GetVipLevel()
    --local extraTime = gModelVip:GetOnHookTime()local extraTime = gModelVip:GetOnHookTime()
    local str = ccClientText(10758)
    str = string.replace(str, quickBaseTime)
    self:SetWndText(self.mDescTxt, str)

    if gLGameLanguage:IsJapanRegion() then
        local isGray = not (hasCost or hasFree)
        self:SetWndButtonGray(self.mGoToBtn, isGray)
    end
end

function UIQuk:Jump(funcId, func)
    local funcId = funcId
    local isOpen = gModelFunctionOpen:CheckIsOpened(funcId, true)
    if not isOpen then
        return
    end
    gModelFunctionOpen:Jump(funcId, nil, func)
end

function UIQuk:OnClickQuickGet()
    if not gModelInstance:IsQuickOpened(true) then
        return
    end
    local wndName = self:GetWndName()
    local times = gModelInstance:GetQuickCostTimesLeft()
    if times <= 0 then
        local isActive = gModelInstance:GetIsPrivilege()
        if not isActive then
            local wndId = 30004
            local func = function()
                self:OpenTipWnd()
            end
            gModelGeneral:OpenUIOrdinTips({ refId = wndId, func = func })
        else
            GF.ShowMessage(ccClientText(12808))
        end
        return
    end

    local fun2 = function()
        local cost = gModelInstance:GetCurQuickCostConfig()
        if cost then
            if cost == 0 then
                --gModelOutfit:ShowMaxOutfitTips(nil,function()
                gModelInstance:QuickHang(wndName)
                --end)
            else
                local isActive = gModelInstance:GetIsPrivilege()
                local curCostNum = cost.itemNum
                local curCostId = cost.itemId
                if not isActive then
                    local wndId = 30003
                    local rightFun = function()
                        local own = gModelItem:GetNumByRefId(curCostId)
                        if own < curCostNum then
                            gModelGeneral:OpenGetWayWnd({ itemId = curCostId, srcWnd = wndName })
                            return
                        end
                        --gModelOutfit:ShowMaxOutfitTips(nil,function()
                        gModelInstance:QuickHang(wndName)
                        --end)
                    end
                    local leftFun = function()
                        --self:OpenTipWnd()
                        self:WndClose()
                        self:Jump(10401111, function()
                            self:Jump(10401111)
                        end)
                    end
                    gModelGeneral:OpenUIOrdinTips({ refId = wndId, func = rightFun, leftFunc = leftFun,
                                                      para = { curCostNum }, consume = { curCostNum, curCostId } })
                else
                    local wndId = 30005
                    local rightFun = function()
                        --gModelOutfit:ShowMaxOutfitTips(nil,function()
                        gModelInstance:QuickHang(wndName)
                        --end)
                    end
                    gModelGeneral:OpenUIOrdinTips({ refId = wndId, func = rightFun, para = { curCostNum }, consume = { curCostNum, curCostId } })
                end
            end
        end
    end

    local node = gModelInstance._battleNode
    local battleNum = gModelInstance:GetBattleNum(1)
    battleNum = node == -1 and battleNum + 1 or battleNum
    local stage = gModelInstance:GetMissionRefIdByNum(battleNum)
    local cfg = GameTable.MainInstanceMissionRef[stage]
    if cfg then
        local limitLvl = cfg.openLevelLimit
        local selfLvl = gModelPlayer:GetPlayerLv()
        if selfLvl >= limitLvl then
            gModelGeneral:OpenUIOrdinTips({ refId = 30011, func = fun2 })
        else
            fun2()
        end
    else
        fun2()
    end

end

function UIQuk:GetCostNum()
    local quickCostString = gModelInstance:GetQuickCostStringT()
    local quickCost = gModelInstance:GetQuickCost()
    local num = table.keysize(quickCostString) - quickCost
    num = num <= 0 and 0 or num
    return num
end

function UIQuk:InitIosShowUI()
    if PRODUCT_G_VER == 2 or PRODUCT_G_VER == 3 then
        --CS.ShowObject(self.mPriviBg.parent, false)
    end
end

function UIQuk:OpenTipWnd()
    local funcId = 10401111
    local isOpen = gModelFunctionOpen:CheckIsOpened(funcId, true)
    if not isOpen then
        return
    end

    gModelFunctionOpen:Jump(funcId)
    self:WndClose()


end

function UIQuk:RewardListItem(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local AniRootItem = self:FindWndTrans(AniRoot, "item")
    local itemIcon = self:FindWndTrans(AniRootItem, "icon")
    local AniRootTag = self:FindWndTrans(AniRoot, "tag")

    local isShowTab = itemdata.descript ~= 0
    CS.ShowObject(AniRootTag, isShowTab)

    if isShowTab then
        local tabImg = ""
        if itemdata.descript == 1 then
            tabImg = self._tabImgList[1]
        elseif itemdata.descript == 2 then
            tabImg = self._tabImgList[2]
        else
            tabImg = self._tabImgList[3]
        end
        self:SetWndEasyImage(AniRootTag, tabImg)
    end
    self:CreateCommonIconImpl(itemIcon, itemdata)
end

function UIQuk:RefreshPriviIntro()
    local needCd = false
    local isActive = gModelNormalActivity:IsPrivilegeTypeActive(ModelActivity.PRIVILEGE_QUICK)
    if isActive then
        local endTime = gModelNormalActivity:GetPriviEndTimeByType(ModelActivity.PRIVILEGE_QUICK)
        local showStr = nil
        if endTime == 0 then
            showStr = ccClientText(10770)
        else
            local timeLast = endTime - GetTimestamp()
            if timeLast < 0 then
                self:TimerStop(self._timerKey)
                showStr = ccClientText(10764)
            else
                showStr = LUtil.FormatTimespanCn(timeLast)

                needCd = true
            end
        end
        self:SetWndText(self.mActiveIntro, showStr)
    end

    CS.ShowObject(self.mActiveIntro, isActive)
    CS.ShowObject(self.mPriviBuy, not isActive)

    return needCd
end

function UIQuk:CheckCanQuickGet(needTips)
    if not gModelInstance:IsQuickOpened(true) then
        return
    end
    local wndName = self:GetWndName()
    local times = gModelInstance:GetQuickCostTimesLeft()
    if times <= 0 then
        if not needTips then
            return false
        end

        local isActive = gModelInstance:GetIsPrivilege()
        if not isActive then
            local wndId = 30004
            local func = function()
                self:OpenTipWnd()
            end
            gModelGeneral:OpenUIOrdinTips({ refId = wndId, func = func })
        else
            GF.ShowMessage(ccClientText(12808))
        end
        return false
    end

    local cost = gModelInstance:GetCurQuickCostConfig()
    if cost then
        if cost == 0 then
            --gModelOutfit:ShowMaxOutfitTips(nil,function()
            gModelInstance:QuickHang(wndName)
            --end)
        else
            local isActive = gModelInstance:GetIsPrivilege()
            local curCostNum = cost.itemNum
            local curCostId = cost.itemId
            if not isActive then
                local wndId = 30003
                local rightFun = function()
                    local own = gModelItem:GetNumByRefId(curCostId)
                    if own < curCostNum then
                        gModelGeneral:OpenGetWayWnd({ itemId = curCostId, srcWnd = wndName })
                        return
                    end
                    --gModelOutfit:ShowMaxOutfitTips(nil,function()
                    gModelInstance:QuickHang(wndName)
                    --end)
                end
                local leftFun = function()
                    --self:OpenTipWnd()
                    self:WndClose()
                    self:Jump(10401111, function()
                        self:Jump(10401111)
                    end)
                end
                gModelGeneral:OpenUIOrdinTips({ refId = wndId, func = rightFun, leftFunc = leftFun,
                                                  para = { curCostNum }, consume = { curCostNum, curCostId } })
            else
                local wndId = 30005
                local rightFun = function()
                    --gModelOutfit:ShowMaxOutfitTips(nil,function()
                    gModelInstance:QuickHang(wndName)
                    --end)
                end
                gModelGeneral:OpenUIOrdinTips({ refId = wndId, func = rightFun, para = { curCostNum }, consume = { curCostNum, curCostId } })
            end
        end
    end
end

function UIQuk:ShowPrivi()
    local needCd = self:RefreshPriviIntro()
    if needCd then
        self:TimerStart(self._timerKey, 1, false, -1)
    end

    local str = ccClientText(12332) --"订阅奖励"
    self:SetWndText(self.mText_2, str)

    local giftRef = gModelNormalActivity:GetBIActivityPrivilegeGiftRefByRefId(ModelActivity.PRIVILEGE_QUICK)
    self:SetWndEasyImage(self.mPriviImg, giftRef.icon)

    self:SetWndText(self.mText_1, ccLngText(giftRef.name))
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mText_1)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mImage_text)
    local intro = gModelNormalActivity:GetPriviRewardDesc(ModelActivity.PRIVILEGE_QUICK)
    local strs = string.split(intro, '|')
    local tempStrs = {}
    for k, v in ipairs(strs) do
        local temp = string.format("%s.%s<br>", k, v)
        table.insert(tempStrs, temp)
    end

    local str = table.concat(tempStrs)
    self:SetWndText(self.mPriviIntro, str)

    if  self._isEnus or self._isVie then
        self:InitTextLineWithLanguage(self.mPriviIntro, -10)
    else
        self:InitTextLineWithLanguage(self.mPriviIntro, -30)
    end

    local itemList = gModelNormalActivity:GetPrivilegeRewardShow(ModelActivity.PRIVILEGE_QUICK) or {}

    local uiList = self:FindUIScroll("priviRewardList")
    if uiList then
        uiList:RefreshList(itemList)
    else
        uiList = self:GetUIScroll("priviRewardList")
        uiList:Create(self.mPriviReward, itemList, function(...)
            self:RewardListItem(...)
        end)
    end
    local priviDataList = gModelNormalActivity:GetPriviIdListByType(ModelActivity.PRIVILEGE_QUICK)
    local dataId = priviDataList[1]
    local giftData = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(dataId)
    local expend = giftData.expend
    local iconTran = self:FindWndTrans(self.mPriviBuy, "Light/Image")
    local textTran = self:FindWndTrans(self.mPriviBuy, "Light/Text")
    local isItemCost = string.find(expend, "=")
    if isItemCost then
        local itemCost = LxDataHelper.ParseItem_3(expend)
        local iconRes = gModelItem:GetItemImgByRefId(itemCost.refId)

        self:SetWndEasyImage(iconTran, iconRes)
        self:SetWndText(textTran, itemCost.itemNum)
    else
        local expendId = tonumber(expend)
        local valueShow = gModelPay:GetShowByWelfareId(expendId)
        self:SetWndText(textTran, valueShow)
    end

    CS.ShowObject(iconTran, isItemCost)

    self:SetWndClick(self.mPriviBuy, function()
        self:BuyPrivi()
    end)

    if self._isVie then
        self:SetAnchorPos(self.mScrollRect,Vector2.New(110,59))
    end
end

function UIQuk:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function()
        self:WndCloseAndBack()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mGoToBtn, function()
        self:OnClickQuickGet()
    end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UIQuk:InitStaticContent()
    self:SetWndText(self.mTitle, ccClientText(10765))

    self._tabImgList = {
        gModelNormalActivity:GetBIActivityConfigRefByKey("textImage1"),
        gModelNormalActivity:GetBIActivityConfigRefByKey("textImage2"),
        gModelNormalActivity:GetBIActivityConfigRefByKey("textImage3"),
    }

end

function UIQuk:InitData()
    self._timerKey = "_timerKey"
    self._isForeign = gLGameLanguage:IsForeignVersion()
    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie =gLGameLanguage:IsVieVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
end

function UIQuk:BuyPrivi()
    local priviDataList = gModelNormalActivity:GetPriviIdListByType(ModelActivity.PRIVILEGE_QUICK)
    local refId = priviDataList[1]
    gModelNormalActivity:BuyPrivi(refId)
end

function UIQuk:InitMsg()
    self:WndNetMsgRecv(LProtoIds.QuickCombatResp, function()
        self:Refresh()
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerInstanceResp, function()
        self:Refresh()
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function(pb)
        gModelInstance:OnPlayerInstanceReq()
    end)

    self:WndEventRecv(EventNames.PRIVILEGE_REFRESH, function(refId)
        self:Refresh()
        if not refId or refId == ModelActivity.PRIVILEGE_QUICK then
            local needCd = self:RefreshPriviIntro()
            if needCd then
                self:TimerStart(self._timerKey, 1, false, -1)
            end
        end
    end)
end

function UIQuk:SetUPAddNum()
    local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.COMMONRANK)

    local isEnd = false
    for i, v in ipairs(dataList) do
        if isEnd then
            break
        end
        local moreInfo = JSON.decode(v.moreInfo)
        local instancePayCount = moreInfo["instancePayCount"]
        if instancePayCount then
            isEnd = v.status ~= 1 and v.endTime - GetTimestamp() < 0
            if isEnd then
                printInfoNR("sid = " .. v.sid .. ",status = " .. v.status .. ",instancePayCount = " .. instancePayCount)
                printInfoNR("结束时间 = " .. v.endTime .. ",系统时间 = " .. GetTimestamp())
            end
        end
    end
    if isEnd then
        return
    end

    local instanceFreeCount = 0
    local instancePayCount = 0
    local isNewYear, activitys = gModelActivity:GetPrivilegeShow1(2)
    if isNewYear then
        for i, v in ipairs(activitys) do
            local activity = v
            local moreInfo = JSON.decode(activity.moreInfo)
            local privilegeShow2 = moreInfo.privilegeShow2
            local privilegeShow3 = moreInfo.privilegeShow3
            local privilegeShow2Arr = string.split(privilegeShow2, "|")
            for i, v in ipairs(privilegeShow2Arr) do
                local ref = gModelGeneral:GetSysEffectRef(tonumber(v))
                local effectValue = ref.effectValue
                instanceFreeCount = instanceFreeCount + tonumber(effectValue)
            end
            local privilegeShow3Arr = string.split(privilegeShow3, "|")
            for i, v in ipairs(privilegeShow3Arr) do
                local ref = gModelGeneral:GetSysEffectRef(tonumber(v))
                local effectValue = ref.effectValue
                instancePayCount = instancePayCount + tonumber(effectValue)
            end
        end
    end

    for i, data in ipairs(dataList) do
        local dataTable = JSON.decode(data.moreInfo)
        instanceFreeCount = instanceFreeCount + tonumber(dataTable.instanceFreeCount or 0)
        local instancePayCountList = string.split(dataTable.instancePayCount, ";") or {}
        instancePayCount = instancePayCount + #instancePayCountList
    end

    self:SetUPNum(self.mFreeUPAdd, tonumber(instanceFreeCount))

    self:SetUPNum(self.mBuyUPAdd, tonumber(instancePayCount))

end

function UIQuk:SetUPNum(trans, num)
    local layoutGroup
    if trans and num and num > 0 then
        local BG = CS.FindTrans(trans, "BG")
        local AddNum = CS.FindTrans(BG, "AddNum")
        self:SetWndText(AddNum, string.format("+%s", num))
        layoutGroup = BG:GetComponent("HorizontalLayoutGroup")
        CS.ShowObject(trans, true)
    else
        if trans then
            CS.ShowObject(trans, false)
        end
    end
    if nil == layoutGroup then
        local BG = CS.FindTrans(trans, "BG")
        layoutGroup = BG:GetComponent("HorizontalLayoutGroup")
    end
    if self._isVie then
        local padding = layoutGroup.padding
        padding.left = 55
        layoutGroup.padding = padding
    end
    if self.jpj then
        local padding = layoutGroup.padding
        padding.left = 60
        layoutGroup.padding = padding
        self:SetAnchorPos(self.mBuyUPAdd,Vector2.New(150,40))
    end
end

function UIQuk:GetFreeNum()
    local freeTimeNum = gModelInstance:GetFreeQuick() - gModelInstance:GetQuickFreeCount()
    freeTimeNum = freeTimeNum <= 0 and 0 or freeTimeNum
    return freeTimeNum
end

function UIQuk:OnTimer(key)
    if key == self._timerKey then
        self:RefreshPriviIntro()
    end
end

------------------------------------------------------------------
return UIQuk


