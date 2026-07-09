---
--- Created by LCM.
--- DateTime: 2024/3/30 16:42:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIIntegralSow:LWnd
local UIIntegralSow = LxWndClass("UIIntegralSow", LWnd)
local typeRectTransform = typeof(UnityEngine.RectTransform)
local Tweening = DG.Tweening

UIIntegralSow.TYPE_INTEGRAL_CALL = 1                ---- 积分召唤
UIIntegralSow.TYPE_INTEGRAL_GET = 2                ---- 魔轮召唤

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIIntegralSow:UIIntegralSow()
    self._changeHeadKey = "_changeHeadKey"


end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIIntegralSow:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIIntegralSow:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIIntegralSow:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isJapaness  =gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshView()
    self:InitRuleMoreList()
end

function UIIntegralSow:RefreshIntegralGetBtnStatas()
    local list = self:GetIntegralCanGetRewardList()
    local isCanGet = list and #list > 0
    --local btnImg = isCanGet and "callhero_btn_6" or "callhero_btn_7"

    --self:SetWndEasyImage(self.mIntegralGetBtn, btnImg)

    local isForeign = self._isForeign
    if isForeign then
        local btnTextId = isCanGet and 27864 or 27863
        self:SetWndText(self.mIntegralGetBtnText, ccClientText(btnTextId))
    else
        local btnImgIcon = isCanGet and "callhero_txt_9" or "callhero_txt_11"
        self:SetWndEasyImage(self.mIntegralGetBtnIcon, btnImgIcon)
    end

    CS.ShowObject(self.mIntegralGetBtnText, isForeign)
    CS.ShowObject(self.mIntegralGetBtnIcon, not isForeign)
end

function UIIntegralSow:GetRandomSuspendTime()
    local times = { 3.5, 4, 3, 3.8, 5, 4.5, 3.2, 4.2, 3.4, 4.8 }
    local random = math.random(1, #times)
    return times[random]
end

function UIIntegralSow:OnMagicLuckyReceiveResp(pb)
    self:DisposePercentage(pb.luckyCount, self.mIntegralGetSlider)
    self:DisposeLuckyReceive(pb.luckyReceive)
    self:RefreshIntegralGet()
end

function UIIntegralSow:OnClickIntegralCallTipBtnFunc()
    GF.OpenWnd("UIYellHRew", { callRefId = ModelCallHero.CALL_TYPE_INTEGRAL, viewType = 2 })
end

function UIIntegralSow:OnDrawIntegralGetCell(list, item, itemdata, itempos)
    local ScheduleNumTrans = self:FindWndTrans(item, "ScheduleNum")
    local RewardDivTrans = self:FindWndTrans(item, "RewardDiv")
    local BgTrans = self:FindWndTrans(RewardDivTrans, "Bg")
    local ArrowImgTrans = self:FindWndTrans(RewardDivTrans, "ArrowImg")
    local IconTrans = self:FindWndTrans(BgTrans, "Icon")
    local MaskTrans = self:FindWndTrans(BgTrans, "Mask")
    local redPointTrans = self:FindWndTrans(BgTrans, "redPoint")

    local grad = itemdata.grad
    self:SetWndText(ScheduleNumTrans, grad)

    local first = self:GetGradReward(itemdata.gradReward)
    if first then
        local itemId = first.itemId
        local icon = gModelItem:GetItemIconByRefId(itemId)
        self:SetWndEasyImage(IconTrans, icon)
    end
    local itemBg2 = itemdata.itemBg2
    self:SetWndEasyImage(BgTrans, itemBg2)

    self:SetWndEasyImage(ArrowImgTrans, itemdata.itemArrow)

    local isFull = self._lucky >= grad
    if isFull then
        local itemBg1 = itemdata.itemBg1
        self:SetWndEasyImage(MaskTrans, itemBg1)
    end
    CS.ShowObject(MaskTrans, isFull)

    local luckyReceiveList = self._luckyReceiveList or {}
    local isGet = isFull and not luckyReceiveList[itemdata.refId] or false
    CS.ShowObject(redPointTrans, isGet)

    local isGray = luckyReceiveList[itemdata.refId]
    self:SetWndImageGray(IconTrans, isGray)

    local BtnTrans = self:FindWndTrans(BgTrans, "Btn")
    self:SetWndClick(BtnTrans, function()
        self:OnClickItemFunc(itemdata)
    end)
end

function UIIntegralSow:DisposeLuckyReceive(luckyReceive)
    self._luckyReceiveList = {}
    for i, v in ipairs(luckyReceive) do
        self._luckyReceiveList[v] = v
    end
end

function UIIntegralSow:OnDrawRuleMoreNewCell(list, item, itemdata, itempos)
    local StarDesc = self:FindWndTrans(item, "TopDiv/StarDesc")
    local InRuleList = self:FindWndTrans(item, "InRuleList")
    self:SetWndText(StarDesc, itemdata.showKindStr)
    self:CreateInRuleList(InRuleList, itemdata.jackpotList)
end

function UIIntegralSow:InitIntegralGetList()
    local list = self:GetIntegralGetList()
    local uiIntegralGetList = self._uiIntegralGetList
    if uiIntegralGetList then
        uiIntegralGetList:RefreshList(list)
    else
        uiIntegralGetList = self:GetUIScroll("uiIntegralGetList")
        self._uiIntegralGetList = uiIntegralGetList
        uiIntegralGetList:Create(self.mIntegralGetList, list, function(...)
            self:OnDrawIntegralGetCell(...)
        end)
    end
end

function UIIntegralSow:RunHeroBgTransAni(list)
    local aniKey
    for i, trans in ipairs(list) do
        aniKey = trans:GetInstanceID()
        local formPos = trans.localPosition
        local toPos = formPos:Clone()
        toPos.y = toPos.y + 30
        local time = self:GetRandomSuspendTime()
        self:TweenSeq_Suspend(aniKey, trans, formPos, toPos, time, nil, Tweening.Ease.InOutFlash, true)
    end
end

function UIIntegralSow:OnTimer(key)
    if key == self._changeHeadKey then
    end
end

function UIIntegralSow:RefreshHeroIcon()
    local heroBgTransInfoList = self._heroBgTransInfoList or {}
    local showHeroHeadList = gModelCallHero:GetIntegralCallHeroShowNewList(self._showHeroHeadList, #heroBgTransInfoList)

    self._showHeroHeadList = {}
    for i, v in ipairs(showHeroHeadList) do
        self._showHeroHeadList[v] = v
    end

    for i, v in ipairs(heroBgTransInfoList) do
        local effRef
        local selRefId = showHeroHeadList[i]
        if selRefId then
            effRef = gModelHero:GetHeroShowRefByRefId(selRefId)
        end
        local isSel = effRef ~= nil
        if isSel then
            --local heroRoundIcon = effRef.heroRoundIcon
            --self:SetWndEasyImage(v.iconTrans,heroRoundIcon)
        end
        CS.ShowObject(v.bgTrans, isSel)
    end
end

function UIIntegralSow:OnCallHeroResp(pb)
    self:RefreshIntegralCall()
end

function UIIntegralSow:OnClickIntegralGetBtnFunc()
    local refIdList = self:GetIntegralCanGetRewardList()
    if not refIdList then
        return
    end
    if #refIdList < 1 then
        local scoreStr
        local getRewardType = self._getRewardType
        if getRewardType == ModelCallHero.LUCKY then
            scoreStr = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelLuckNum")
        else
            scoreStr = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighLuckNum")
        end
        if scoreStr then
            local reward = self:GetGradReward(scoreStr)
            if reward then
                local rewardId = reward.itemId
                local payName = gModelItem:GetNameByRefId(rewardId)
                local str = string.replace(ccClientText(27806), payName)
                GF.ShowMessage(str)
            end
        end
        return
    end
    gModelCallHero:OnMagicLuckyReceiveReq(refIdList)
end

function UIIntegralSow:GetIntegralCallIconTrans(trans)
    local IconTrans = self:FindWndTrans(trans, "Icon")
    local MaskTrans = self:FindWndTrans(trans, "Mask")

    return {
        bgTrans = trans,
        iconTrans = IconTrans,
        maskTrans = MaskTrans,
    }
end

function UIIntegralSow:GetCallRefidRuleList()
    local list = {}
    local callRefId = ModelCallHero.CALL_TYPE_INTEGRAL
    if callRefId then
        for k, v in pairs(GameTable.SummonTextRef) do
            if callRefId == v.callRefId then
                list = self:GetCommonHeroList(v)
                break
            end
        end
    end
    return list
end

function UIIntegralSow:CreateCommonHero(item, itemdata)
    local IconTrans = self:FindWndTrans(item, "CommonUI/Icon")
    local ProbabilityTxtTrans = self:FindWndTrans(item, "ProbabilityTxt")

    local reward = itemdata.rewardList
    local itemType, itemId, itemNum = reward.itemType, reward.itemId, reward.itemNum
    local InstanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemType, itemId, itemNum)
    baseClass:EnableShowNum(itemNum > 0)
    baseClass:SetNoShowLv(true)
    baseClass:DoApply()

    self:SetIconClickScale(IconTrans, true)

    self:SetWndClick(IconTrans, function()
        if self._callRefId == ModelCallHero.CALL_TYPE_PREPARE then
            -- local heroRef = gModelHero:GetHeroRef(itemId)
            -- local heroStar = heroRef.initStar
            -- GF.OpenWndTop("UINewSagaStarPre", {
            --     refId = itemId,
            --     nextStar = heroStar,
            --     showType = 2,
            --     hideAwaken = true
            -- })
            -- return
        end

        if itemType == 2 then
            gModelGeneral:OpenHeroSimpleTip(itemId, true)
        elseif itemType == 3 then
            gModelGeneral:OpenEquipInfoTip(itemId, nil, nil, true)
        else
            gModelGeneral:ShowCommonItemTipWnd(reward)
        end
    end)

    local show = itemdata.show
    if show then
        local probability = itemdata.probability
        local str
        if probability then
            --保留5位小数
            str = (math.floor(probability * 10000000) / 10000000) * 100 .. "%"
        else
            str = itemdata.probabilityStr
        end
        self:SetWndText(ProbabilityTxtTrans, str)
    end
    CS.ShowObject(ProbabilityTxtTrans, show)
end

------------------------- List -------------------------

--region 新增英雄展示数据 --------------------------------------------------------------------------------
--创建列表
function UIIntegralSow:InitRuleMoreList()
    CS.ShowObject(self.mRuleMoreList, true)

    local list = self:GetRuleMoreList()

    if gLGameLanguage:IsKoreaRegion() then
        local allProbability = 0
        for k, v in ipairs(list) do
            allProbability = allProbability + v.probability
        end
        self._allProbability = allProbability
    end

    local uiRuleMoreList = self._uiRuleMoreList
    if uiRuleMoreList then
        uiRuleMoreList:RefreshList(list)
    else
        uiRuleMoreList = self:GetUIScroll("uiRuleMoreList")
        self._uiRuleMoreList = uiRuleMoreList
        --- ItemTemplate11
        --uiRuleMoreList:Create(self.mRuleMoreList,list,function(...) self:OnDrawRuleMoreCell(...) end,UIItemList.WRAP)
        uiRuleMoreList:Create(self.mRuleMoreList, list, function(...)
            self:OnDrawRuleMoreNewCell(...)
        end)
    end
    uiRuleMoreList:EnableScroll(true)
end

function UIIntegralSow:RefreshIntegralCallSlider()
    local integralNeedRefId = self._integralNeedRefId
    local integralNeedNum = self._integralNeedNum
    if not integralNeedRefId or not integralNeedNum then
        return
    end
    local haveNum = gModelItem:GetNumByRefId(integralNeedRefId)
    local percentage = haveNum / integralNeedNum
    LxUiHelper.SetProgress(self.mJinDuTiao, percentage)

    local haveNum = gModelItem:GetNumByRefId(integralNeedRefId)
    local percentage = haveNum / integralNeedNum
    local color = haveNum >= integralNeedNum and "lightGreen_new" or "red"
    local haveStr = LUtil.FormatColorStr(haveNum, color)

    local str = string.format("%s/%s", haveStr, integralNeedNum)
    self:SetWndText(self.mIntegralCallNum, str)

    local itemIcon = gModelItem:GetItemIconByRefId(integralNeedRefId)
    if LxUiHelper.IsImgPathValid(itemIcon) then
        self:SetWndEasyImage(self.mIntegralCallItemIcon, itemIcon)
        CS.ShowObject(self.mIntegralCallItemIcon, true)
    end

    self:ChangeSlider(self.mIntegralCallSlider, percentage)
end

function UIIntegralSow:GetCommonRewardList(str)
    return LxDataHelper.ParseItem_3(str)
end

function UIIntegralSow:GetCommonHeroList(itemdata)
    if not itemdata then
        return {}
    end

    local callRefId = itemdata.callRefId
    local callRef = gModelCallHero:GetCallRefByRefId(callRefId)
    if not callRef then
        return {}
    end

    local list = {}
    local qualityList = {}
    local tQ
    local quality = string.split(callRef.quality, ",") or {}
    for i, v in ipairs(quality) do
        v = string.split(v, "=")
        tQ = tonumber(v[1])
        qualityList[tQ] = tQ
    end
    local keyDataMap = {}
    local showKind
    local jackpotId = itemdata.jackpotId
    for k, v in pairs(GameTable.SummonJackpotRef) do


        showKind = v.showKind
        if v.jackpotId == jackpotId and showKind and showKind > 0 then
            local keyDatas = keyDataMap[showKind]
            if not keyDatas then
                keyDatas = {}
                keyDataMap[showKind] = keyDatas
            end
            table.insert(keyDatas, {
                callRefId = callRefId,
                sort = v.sort,
                refId = k,
                rewardList = self:GetCommonRewardList(v.reward),
                probability = v.probabilityShow,
                show = v.show == 1,
            })
        end
    end
    for k, v in pairs(keyDataMap) do
        table.sort(v, function(a, b)
            local sortA, sortB = a.sort, b.sort
            if sortA ~= sortB then
                return sortA > sortB
            end
            return a.refId > b.refId
        end)
        table.insert(list, {
            showKind = k,
            showKindStr = ccClientText(k),
            jackpotList = v
        })
    end
    table.sort(list, function(a, b)
        return a.showKind < b.showKind
    end)
    return list
end

function UIIntegralSow:SetTransInfo(trans, itemdata)

end

function UIIntegralSow:InitIntegralGetData()
    self._getRewardType = self:GetWndArg("getRewardType")
    self._page = self:GetWndArg("page")
    self._subPage = self:GetWndArg("subPage")

    self._lucky = 0
end

function UIIntegralSow:ShowIntegralCallHead()
    self:TimerStop(self._changeHeadKey)
end

function UIIntegralSow:InitData()
    local viewType = self:GetWndArg("viewType")
    self._viewType = viewType

    self._isForeign = gLGameLanguage:IsForeignRegion()

    if viewType == UIIntegralSow.TYPE_INTEGRAL_CALL then
        self:SetWndText(self.mIntegralGetLuckyDesc, ccClientText(14607))

        self:InitIntegralCallData()
    elseif viewType == UIIntegralSow.TYPE_INTEGRAL_GET then
        local magicType = self:GetWndArg("magicType")
        local fixedCfg
        if magicType == ModelCallHero.LUCKY then
            fixedCfg = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelLuckNum")
        else
            fixedCfg = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighLuckNum")
        end
        local reward = self:GetGradReward(fixedCfg)
        if reward then
            local rewardId = reward.itemId
            local payName = gModelItem:GetNameByRefId(rewardId)
            self:SetWndText(self.mIntegralGetLuckyDesc, payName)
        end

        self:InitIntegralGetData()
    end

    --設置文本
    self:SetWndText(self.mTitle, ccClientText(27865))  --[27865]	[必出五星少女]
end

function UIIntegralSow:GetIntegralCanGetRewardList()
    local lucky = self._lucky
    if not lucky then
        return
    end
    local list = self:GetIntegralGetList()
    local len = #list
    if len <= 0 then
        return
    end
    local luckyReceiveList = self._luckyReceiveList
    local refIdList = {}
    local refId
    for i, v in ipairs(list) do
        refId = v.refId
        if lucky >= v.grad and not luckyReceiveList[refId] then
            table.insert(refIdList, refId)
        end
    end
    return refIdList
end

function UIIntegralSow:RefreshIntegralGet(pb)
    CS.ShowObject(self.mIntegralGetView, true)
    self:RefreshIntegralGetBtnStatas()
    self:InitIntegralGetList()
end

function UIIntegralSow:OnClickIntegralGetTipBtnFunc()
end

function UIIntegralSow:OnClickIntegralCallBtnFunc()
    local curVip = gModelPlayer:GetVipLevel()
    if curVip < self._integralNeedVip then

        local para = {
            refId = 50111,
            func = function()
                local callName = gModelCallHero:GetCallWndName()
                GF.CloseWndByName(callName)
                self:WndClose()
                local wndInst = GF.FindFirstWndByName("UIHuiYPay")
                if wndInst then
                    return
                end
                GF.OpenWnd("UIHuiYPay", { page = 1 })
            end,
        }
        gModelGeneral:OpenUIOrdinTips(para)
        return
    end
    gModelCallHero:OnCallHeroReq(0, 1, self._integralNeedRefId)
end

------------------------- List -------------------------
function UIIntegralSow:GetIntegralGetList()
    local list = {}
    local getRewardType = self._getRewardType
    if getRewardType == ModelCallHero.LUCKY then
        -- 幸运魔轮
        list = gModelCallHero:GetLuckMagicWheelLuckyRef()
    elseif getRewardType == ModelCallHero.MIRACLE then
        -- 奇迹魔轮
        list = gModelCallHero:GetMiracleMagicWheelLuckyRef()
    end
    return list
end

function UIIntegralSow:CreateInRuleList(listTrans, list)
    local key = listTrans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(listTrans, list, function(...)
            self:OnDrawRuleMoreCell(...)
        end)
    end
end

function UIIntegralSow:OnMagicWheelInfoResp(pb)
    self:DisposePercentage(pb.lucky, self.mIntegralGetSlider)
    self:DisposeLuckyReceive(pb.luckyReceive)
    self:RefreshIntegralGet()
end

function UIIntegralSow:RefreshView()
    local viewType = self._viewType
    if viewType == UIIntegralSow.TYPE_INTEGRAL_CALL then
        --self:RefreshHeroIcon()
        self:RefreshIntegralCall()
        self:ShowIntegralCallHead()
    elseif viewType == UIIntegralSow.TYPE_INTEGRAL_GET then
        gModelCallHero:CallOpt(self._page, self._subPage)
        self:RefreshIntegralGet()
    end
end

function UIIntegralSow:DisposePercentage(lucky, trans)
    local list = self:GetIntegralGetList()
    local len = #list
    local lastRef = list[len]
    local percentage = 0
    if lastRef then
        local grad = lastRef.grad
        percentage = lucky / grad
    end
    self._lucky = lucky
    self:SetWndText(self.mIntegralGetLuckyNum, lucky)

    local newPer = percentage
    if percentage < 1 then
        local sliderTrans = trans:GetComponent(typeRectTransform)
        local sizeDelta = sliderTrans.sizeDelta
        local width = sizeDelta.x
        local onePos = 1 / len
        local interval = onePos * width
        local tGrad
        local index = 0
        local beforeGrad = 0
        for i, v in ipairs(list) do
            tGrad = v.grad
            if lucky >= tGrad then
                index = index + 1
                beforeGrad = tGrad
            end
        end
        local nextIndex = index + 1
        if nextIndex > len then
            nextIndex = len
        end
        local nextGrad = list[nextIndex].grad
        local fullGrad = nextGrad - beforeGrad
        newPer = onePos * index + ((lucky - beforeGrad) / fullGrad * onePos)
    end
    self:ChangeSlider(trans, newPer)
end

function UIIntegralSow:GetGradReward(str)
    str = str or ""
    local itemList = LUtil.ConvertCommonItemStrToList(str)
    return itemList[1]
end

function UIIntegralSow:InitMsg()
    -- 魔轮信息返回
    self:WndNetMsgRecv(LProtoIds.CallHeroResp, function(pb, ret)
        self:OnCallHeroResp(pb)
    end)

    -- 魔轮信息返回
    self:WndNetMsgRecv(LProtoIds.MagicWheelInfoResp, function(pb, ret)
        self:OnMagicWheelInfoResp(pb)
    end)

    -- 魔轮幸运奖励领取返回
    self:WndNetMsgRecv(LProtoIds.MagicLuckyReceiveResp, function(pb, ret)
        self:OnMagicLuckyReceiveResp(pb)
    end)
end

function UIIntegralSow:OnDrawRuleMoreCell(list, item, itemdata, itempos)
    self:CreateCommonHero(item, itemdata)
end

function UIIntegralSow:GetRuleMoreList()
    local list = {}

    list = self:GetCallRefidRuleList()

    return list
end

function UIIntegralSow:ChangeSlider(trans, percentage)
    LxUiHelper.SetProgress(trans, percentage)
end

function UIIntegralSow:OnClickItemFunc(itemdata)
    local first = self:GetGradReward(itemdata.gradReward)
    if not first then
        return
    end
    gModelGeneral:ShowCommonItemTipWnd(first)
end

function UIIntegralSow:InitIntegralCallData()
    local heroBgTransList = {
        self.mHeroBg1, self.mHeroBg2, self.mHeroBg3, self.mHeroBg4, self.mHeroBg5
    }

    local heroBgTransInfoList = {}
    for i, v in ipairs(heroBgTransList) do
        local transInfo = self:GetIntegralCallIconTrans(v)
        table.insert(heroBgTransInfoList, transInfo)
    end
    self._heroBgTransInfoList = heroBgTransInfoList

    self._integralNeedVip = GameTable.SummonConfigRef["integralNeedVip"]

    self._showHeroHeadList = {}

    local integralNeedItem = GameTable.SummonConfigRef["integralNeedItem"]
    integralNeedItem = string.split(integralNeedItem, "=")
    self._integralNeedRefId = tonumber(integralNeedItem[2])
    self._integralNeedNum = tonumber(integralNeedItem[3])

    local isShowCallText = self._isForeign and not gLGameLanguage:IsJapanVersion()
    isShowCallText = true
    if isShowCallText then
        self:SetWndText(self.mIntegralCallText, ccClientText(27863))
    end
    CS.ShowObject(self.mIntegralCallIcon, not isShowCallText)
    CS.ShowObject(self.mIntegralCallText, isShowCallText)

    self:RunHeroBgTransAni(heroBgTransList)
end

function UIIntegralSow:InitEvent()
    self:SetWndClick(self.mIntegralCallBtn, function()
        self:OnClickIntegralCallBtnFunc()
    end)
    self:SetWndClick(self.mIntegralCallTipBtn, function()
        self:OnClickIntegralCallTipBtnFunc()
    end)
    self:SetWndClick(self.mIntegralGetBtn, function()
        self:OnClickIntegralGetBtnFunc()
    end)
    self:SetWndClick(self.mIntegralGetTipBtn, function()
        self:OnClickIntegralGetTipBtnFunc()
    end)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIIntegralSow:RefreshIntegralCall()
    CS.ShowObject(self.mIntegralCallView, true)

    local needVipStr = string.replace(ccClientText(27846), self._integralNeedVip)
    self:SetWndText(self.mIntegralCallLimit, needVipStr)

    self:SetWndText(self.mIntegralCallDesc, ccClientText(27847))
    if self._isEnus then
        self:InitTextLineWithLanguage(self.mIntegralCallDesc, -10)
    else
        self:InitTextLineWithLanguage(self.mIntegralCallDesc, -30)
    end

    if self._isJapaness then
        self:SetAnchorPos(self.mIntegralCallDesc,Vector2.New(0,395))
    end

    self:RefreshIntegralCallSlider()
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIIntegralSow


