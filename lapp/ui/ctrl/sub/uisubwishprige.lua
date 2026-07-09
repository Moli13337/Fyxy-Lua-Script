---
--- Created by BY.
--- DateTime: 2023/10/11 17:12:42
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubWishPrige:LChildWnd
local UISubWishPrige = LxWndClass("UISubWishPrige", LChildWnd)

local Tweening = DG.Tweening
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubWishPrige:UISubWishPrige()
    self._uiCommonList = {}
    self._timeKey = "timeKey"
    self._timeTextList = {}

    self._timeLimitKey = "timeLimitKey"
    self._timeLimitTextList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubWishPrige:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubWishPrige:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubWishPrige:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UISubWishPrige:InitGiftInfo(item, data, giftRef, showBubble)
    local Subscription = self:FindWndTrans(item, "Subscription")
    local BtnItemBuy = self:FindWndTrans(item, "BtnItemBuy")
    local BtnItemBuyText = self:FindWndTrans(BtnItemBuy, "Text")
    local BtnSubscription = self:FindWndTrans(item, "BtnSubscription")

    local ref = data.ref
    CS.ShowObject(item, true)
    self:SetWndEasyImage(Subscription, ref.moreText1, nil, true)
    local refId = ref.refId
    local isFree = self._freePrivilegeIdList[refId] or false

    local isUseItemBuy = not isFree and string.find(ref.expend, "=")
    CS.ShowObject(BtnItemBuy, isUseItemBuy)
    CS.ShowObject(BtnSubscription, not isUseItemBuy)
    if isFree then
        self:SetWndButtonText(BtnSubscription, ccClientText(11932))
        self:SetWndClick(BtnSubscription, function()
            self:OnClickOpenPop(giftRef)
        end)
    elseif isUseItemBuy then
        local ItemIconTrans = self:FindWndTrans(BtnItemBuyText, "ItemIcon")
        local payInfo = string.split(ref.expend, "=")
        if #payInfo >= 3 then
            local itemId = tonumber(payInfo[2])
            local icon = itemId and gModelItem:GetItemIconByRefId(itemId)
            if icon then
                self:SetWndEasyImage(ItemIconTrans, icon)
            end
        end
        self:SetWndText(BtnItemBuyText, payInfo[3] or "")
        self:SetWndClick(BtnItemBuy, function()
            self:OnClickOpenPop(giftRef)
        end)
    else
        local expendId = tonumber(ref.expend)
        local valueShow = gModelPay:GetShowByWelfareId(expendId)

        self:SetWndButtonText(BtnSubscription, valueShow)
        self:SetWndClick(BtnSubscription, function()
            self:OnClickOpenPop(giftRef)
        end)
    end

    --【T特权商城】删掉无用的参数和特权
    --if showBubble then
    --    local btnStr = ccLngText(gModelNormalActivity:GetBIActivityConfigRefByKey("returnBtnText"))
    --    self:SetWndButtonText(BtnSubscription,btnStr)
    --end


    local instanceId = item:GetInstanceID()
    self._timeLimitTextList[instanceId] = nil
    local TimeLimit = self:FindWndTrans(item,"TimeLimit")
    if TimeLimit then
        CS.ShowObject(TimeLimit, false)
        local giftRefId = giftRef and giftRef.refId
        if giftRefId and giftRefId > 0 then
            if gModelNormalActivity:CheckInCreateRoleTime(giftRefId) == 0 then
                local Desc = self:FindWndTrans(TimeLimit,"Desc")
                self:SetWndText(Desc,ccClientText(14220))

                local TimeTxt = self:FindWndTrans(TimeLimit,"TimeTxt")
                local endTime = gModelNormalActivity:GetPrivilegeGiftExtraEndTime(giftRefId)
                local timeLimitTextData = {
                    endTime = endTime,
                    timeTxt = TimeTxt,
                    root = TimeLimit,
                    endCDFunc = function()
                        if not self:IsWndValid() then return end
                        local _uiList = self._uiList
                        if _uiList then
                            _uiList:DrawAllItems()
                        end
                    end
                }
                self._timeLimitTextList[instanceId] = timeLimitTextData
                self:SetTimeLimitTxtCD(timeLimitTextData)

                if not self:IsTimerExist(self._timeLimitKey) then
                    self:TimerStart(self._timeLimitKey, 1, false, -1)
                end
            end
        end
    end
end

function UISubWishPrige:RefreshData()
    local list = gModelNormalActivity:GetBIActivityPrivilegeGiftRef()
    local infos = gModelNormalActivity:GetPrivilegeGiftList()
    local gifs = {}
    local giftLimitTops = {}
    for i, v in ipairs(infos) do
        local unlockTime = v.unlockTime and tonumber(v.unlockTime) or 0
        if v.endTime == -1 or v.endTime > GetTimestamp() then
            local ref = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(v.refId)
            if ref then
                gifs[ref.type] = true
            end
        end
        if unlockTime > 0 then
            local ref = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(v.refId)
            giftLimitTops[ref.type] = unlockTime
        end
    end
    table.sort(list, function(a, b)
        local aisBuy = gifs[a.refId] and 1 or 0
        local bisBuy = gifs[b.refId] and 1 or 0
        if aisBuy ~= bisBuy then
            return aisBuy < bisBuy
        end
        local aUnlockTime = giftLimitTops[a.refId] or 0
        local aLimitTop = a.limitTop
        local aIsLimitTop = 0
        if aUnlockTime > 0 and aLimitTop > 0 then
            local toTime = LUtil.GetNextDayTimes(aUnlockTime, aLimitTop)
            aIsLimitTop = GetTimestamp() <= toTime and 1 or 0
        end
        local bUnlockTime = giftLimitTops[b.refId] or 0
        local bLimitTop = b.limitTop
        local bIsLimitTop = 0
        if bUnlockTime > 0 and bLimitTop > 0 then
            local toTime = LUtil.GetNextDayTimes(bUnlockTime, bLimitTop)
            bIsLimitTop = GetTimestamp() <= toTime and 1 or 0
        end
        if aIsLimitTop ~= bIsLimitTop then
            return aIsLimitTop > bIsLimitTop
        end
        return a.sort < b.sort
    end)

    self._freePrivilegeIdList = gModelNormalActivity:GetFreePrivilegeIdList() or {}

    self:InitTabImg()
    local _uiList = self._uiList
    if _uiList then
        _uiList:RefreshList(list)
    else
        _uiList = self:GetUIScroll("cell")
        _uiList:Create(self.mCellSuperList, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
        self._uiList = _uiList
    end
    if self._index then
        local UISuperList = _uiList:GetList()
        UISuperList:MoveToPos(self._index)
    end
end

function UISubWishPrige:InitEvent()
    self:SetWndClick(self.mIconImage, function(...)
        self:OnClickIconImage()
    end)
    self:SetWndClick(self.mBuyTipsBtn, function(...)
        self:OnClickByTips()
    end)
end

function UISubWishPrige:InitTabImg()
    self._tabImgList = gModelNormalActivity:GetPrivilegeTabImgList()
end

function UISubWishPrige:ShowDayBoxContent()
    local itemList = gModelNormalActivity:GetPara("privilegeGiftDaily")
    GF.OpenWnd("UIringBoxDetail", { self.mDayBox, itemList })
end

function UISubWishPrige:InitMessage()
    self:WndNetMsgRecv(LProtoIds.PrivilegeGiftResp, function(pb)
        local dailyAward = pb.dailyAward or 0
        CS.ShowObject(self.mDayBox, true)
        CS.ShowObject(self.mBoxEff, dailyAward == 0)
        CS.ShowObject(self.mBoxIcon, true)
        self:SetWndEasyImage(self.mBoxIcon, dailyAward == 0 and "privilegeshop_box_icon_off" or "privilegeshop_box_icon_on")
        if dailyAward == 0 then
            self:CreateWndEffect(self.mBoxEff, "ui_fx_mengjingxueyuan_01", "ui_fx_mengjingxueyuan_01", 100)
        end
        self:SetWndClick(self.mDayBox, function(...)
            if dailyAward == 0 then
                self:OnClickDayBox()
            else
                GF.ShowMessage(ccClientText(14215))
                self:ShowDayBoxContent()
            end
        end)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.BuyPrivilegeGiftResp, function(...)
        self:RefreshData()
    end)
end

function UISubWishPrige:InitCommand()
    self._index = self:GetWndArg("index")
    --【T特权商城】删掉无用的参数和特权
    --local roleRefId = gModelNormalActivity:GetBIActivityConfigRefByKey("privilegeFrame")
    --if roleRefId then
    --    local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(roleRefId)
    --    self:SetWndEasyImage(self.mIconImage,ref.icon)
    --
    --    if gLGameLanguage:IsGermanVersion() then
    --        self:SetAnchorPos(self.mIconImage, Vector2.New(250,0))
    --    end
    --
    --    if ref.effect ~= "" then
    --        self:CreateWndEffect(self.mIconEff,ref.effect,"roleEff",100)
    --    end
    --end
    local textImage = gModelNormalActivity:GetBIActivityConfigRefByKey("textImage")
    if LxUiHelper.IsImgPathValid(textImage) then
        self:SetWndEasyImage(self.mTextImage, textImage, function()
            CS.ShowObject(self.mTextImage, true)
        end, true)
    end

    --local text = ccClientText(156)
    --if not string.isempty(text) then
    --    self._helpTipsContent = text
    --    self:SetWndText(self.mBuyTipsText, text)
    --    CS.ShowObject(self.mBuyTipsText, true)
    --    --CS.ShowObject(self.mBuyTipsBtn, true)
    --end

    gModelNormalActivity:OnPrivilegeGiftReq()

    self:SetWndText(self.mTipsText, ccClientText(14214))
    self:SetWndText(self.mTipsText_2, ccClientText(14218))
end

function UISubWishPrige:OnClickIconImage()
    --【T特权商城】删掉无用的参数和特权
    --local itemRefId = gModelNormalActivity:GetBIActivityConfigRefByKey("privilegeFrameItem")
    --local items = LxDataHelper.ParseItem(itemRefId)
    --gModelGeneral:ShowCommonItemTipWnd(items[1])
end

function UISubWishPrige:ListItem(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local AniRootImage = self:FindWndTrans(AniRoot, "Image")
    local TitleImg = self:FindWndTrans(AniRoot, "TitleImg")

    local AniRootTitlebg = self:FindWndTrans(AniRoot, "titlebg")
    local titlebgTitle = self:FindWndTrans(AniRootTitlebg, "title")

    local AniRootIconBg = self:FindWndTrans(AniRoot, "iconBg")
    local IconBgIcon = self:FindWndTrans(AniRootIconBg, "Icon")
    local AniRootDesBg = self:FindWndTrans(AniRoot, "desBg")
    local desBgDes = self:FindWndTrans(AniRootDesBg, "des")
    local AniRootRewardPart1 = self:FindWndTrans(AniRoot, "rewardPart1")
    local rewardPart1ItemBg = self:FindWndTrans(AniRootRewardPart1, "ItemBg")

    local rewardPart1RewardList = self:FindWndTrans(AniRootRewardPart1, "RewardList")
    local AniRootRewardPart2 = self:FindWndTrans(AniRoot, "rewardPart2")
    local rewardPart2Reward1 = self:FindWndTrans(AniRootRewardPart2, "reward1")
    local reward1RIntro = self:FindWndTrans(rewardPart2Reward1, "rIntro")
    local reward1RewardList = self:FindWndTrans(rewardPart2Reward1, "RewardList")
    local reward1ItemBg = self:FindWndTrans(rewardPart2Reward1, "ItemBg")

    local rewardPart2Reward2 = self:FindWndTrans(AniRootRewardPart2, "reward2")
    local reward2RIntro = self:FindWndTrans(rewardPart2Reward2, "rIntro")
    local reward2RewardList = self:FindWndTrans(rewardPart2Reward2, "RewardList")
    local reward2ItemBg = self:FindWndTrans(rewardPart2Reward2, "ItemBg")

    local AniRootBottom = self:FindWndTrans(AniRoot, "bottom")
    local bottomBtnMag = self:FindWndTrans(AniRootBottom, "BtnMag")
    local BtnMagBtn1 = self:FindWndTrans(bottomBtnMag, "Btn1")

    local BtnMagBtn2 = self:FindWndTrans(bottomBtnMag, "Btn2")

    local bottomTag = self:FindWndTrans(AniRootBottom, "tag")
    local bottomTag2 = self:FindWndTrans(AniRootBottom, "tag2")

    local bottomTimeText = self:FindWndTrans(AniRootBottom, "TimeText")
    local bottomTimeText2 = self:FindWndTrans(AniRootBottom, "TimeText2")
    local bottomTimeText2_Bg = self:FindWndTrans(AniRootBottom, "TimeText2_Bg")
    local bottomBubbleRoot = self:FindWndTrans(AniRootBottom, "bubbleRoot")

    local giftName = ccLngText(itemdata.name)
    self:SetWndText(titlebgTitle, giftName)
    self:InitTextLineWithLanguage(titlebgTitle, -50)
    self:InitTextSizeWithLanguage(titlebgTitle, -6)
    self:SetWndText(desBgDes, ccLngText(itemdata.description2))
    self:InitTextLineWithLanguage(desBgDes, -30,false)
    self:InitTextSizeWithLanguage(desBgDes, -4)
    self:SetWndEasyImage(IconBgIcon, itemdata.icon, nil, true)
    local image = self:FindWndTrans(rewardPart1ItemBg, 'icon')
    self:SetWndEasyImage(image, itemdata.iconSmall, nil, true)
    image = self:FindWndTrans(reward1ItemBg, 'icon')
    self:SetWndEasyImage(image, itemdata.iconSmall, nil, true)
    image = self:FindWndTrans(reward2ItemBg, 'icon')
    self:SetWndEasyImage(image, itemdata.iconSmall, nil, true)
    self:SetWndEasyImage(AniRootImage, itemdata.namePng)

    if itemdata.nameTitle then
        self:SetWndEasyImage(TitleImg, itemdata.nameTitle, function()
            CS.ShowObject(TitleImg, true)
        end, true)
    end

    local infos = gModelNormalActivity:GetPrivilegeGiftList()
    local gifts = {}
    local isActive = false
    local activeInfo = nil

    for i, v in ipairs(infos) do
        local ref = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(v.refId)
        if ref and ref.type == itemdata.refId then
            local giftData = { ref = ref, info = v }
            table.insert(gifts, giftData)
            if not isActive then
                isActive = gModelNormalActivity:IsPrivilegeActive(v.refId)
                activeInfo = giftData
            end
        end
    end
    local isNotAct = not isActive
    CS.ShowObject(BtnMagBtn1, isNotAct)
    CS.ShowObject(BtnMagBtn2, isNotAct)
    CS.ShowObject(bottomTag, isActive)
    CS.ShowObject(bottomTag2, isActive)
    CS.ShowObject(bottomTimeText, isActive)
    CS.ShowObject(bottomTimeText2, isActive)
    CS.ShowObject(bottomTimeText2_Bg, isActive)

    local showBubble = false

    if isNotAct then
        local btnList = {
            [1] = BtnMagBtn1,
            [2] = BtnMagBtn2,
        }

        for k, v in ipairs(btnList) do
            CS.ShowObject(v, false)
        end

        local showPos = 1
        local cnt = #gifts

        for k, v in ipairs(gifts) do
            self:InitGiftInfo(btnList[k], v, itemdata, false)
        end


    else
        local instanceId = bottomTimeText:GetInstanceID()
        self._timeTextList[instanceId] = nil
        local endTime = activeInfo.info.endTime
        if endTime == -1 then
            self:SetWndEasyImage(bottomTag, "privilegeshop_txt_4", nil, true)
            --self:SetWndText(bottomTimeText, ccLngText(activeInfo.ref.moreText1))
            self:SetWndText(bottomTimeText2, "")
            CS.ShowObject(bottomTimeText2_Bg, false)
        else
            local refId = activeInfo.info.refId
            self:SetCountdown(bottomTimeText2, refId)

            self._timeTextList[instanceId] = { refId = refId, timeText = bottomTimeText2 }

            if not self:IsTimerExist(self._timeKey) then
                self:TimerStart(self._timeKey, 1, false, -1)
            end
            self:SetWndText(bottomTimeText, "")
            CS.ShowObject(bottomTag, false)
        end
    end

    local instanceId = bottomBubbleRoot:GetInstanceID()
    local seqCom = self:GetSeqCom()
    seqCom:DeleteSeq(instanceId)

    CS.ShowObject(bottomBubbleRoot, showBubble)

    local showList = gModelNormalActivity:GetAllRewardShow(itemdata.refId) or {}

    local cnt = #showList
    local showMore = cnt > 1
    local size = showMore and 418 or 302

    LxUiHelper.SetSizeWithCurAnchor(item, 1, size)
    local anchorPos = showMore and Vector2.New(0, 28) or Vector2.New(0, -22)
    self:SetAnchorPos(AniRootIconBg, anchorPos)
    CS.ShowObject(AniRootRewardPart1, not showMore)
    CS.ShowObject(AniRootRewardPart2, showMore)

    local showList1 = showList[1] or {}
    local showList2 = showList[2] or {}

    if showMore then
        local str = gifts[1] and ccLngText(gifts[1].ref.moreText1)
        self:SetWndText(reward1RIntro, str)
        str = gifts[2] and ccLngText(gifts[2].ref.moreText1)
        self:SetWndText(reward2RIntro, str)

        local uiList = self:CreateUIScrollImpl(nil, reward1RewardList, showList1, function(...)
            self:RewardListItem(...)
        end)
        uiList:EnableScroll(false, true)


        local uiList2 = self:CreateUIScrollImpl(nil, reward2RewardList, showList2, function(...)
            self:RewardListItem(...)
        end)
        uiList2:EnableScroll(false, true)
    else
        local uiList = self:CreateUIScrollImpl(nil, rewardPart1RewardList, showList1, function(...)
            self:RewardListItem(...)
        end)
        uiList:EnableScroll(false, true)
    end

    self:SetWndClick(IconBgIcon, function()
        self:OnClickOpenPop(itemdata)
    end)
    self:SetWndClick(rewardPart1ItemBg, function()
        self:OnClickOpenPop(itemdata)
    end)
    self:SetWndClick(reward1ItemBg, function()
        self:OnClickOpenPop(itemdata)
    end)
    self:SetWndClick(reward2ItemBg, function()
        self:OnClickOpenPop(itemdata)
    end)

    self:SetWndClick(AniRootDesBg, function()
        self:OnClickOpenPop_New(itemdata)
        --GF.OpenWnd("UIBzTips", { title = ccLngText(itemdata.name), text = ccLngText(itemdata.description2) })
    end)

    self:SetWndClick(desBgDes, function()
        self:OnClickOpenPop_New(itemdata)
        --GF.OpenWnd("UIBzTips", { title = ccLngText(itemdata.name), text = ccLngText(itemdata.description2) })
    end)

    self:SetWndClick(item, function()
        self:OnClickOpenPop_New(itemdata)
        --GF.OpenWnd("UIBzTips", { title = ccLngText(itemdata.name), text = ccLngText(itemdata.description2) })
    end)
end

function UISubWishPrige:OnClickOpenPop(itemdata)
    local infos = gModelNormalActivity:GetPrivilegeGiftList()
    local buyRefid = itemdata.refId
    for i, v in ipairs(infos) do
        local ref = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(v.refId)
        if ref and ref.type == itemdata.refId then

            buyRefid = v.refId

            break
        end
    end

    gModelNormalActivity:BuyPrivi(buyRefid)

end

function UISubWishPrige:RewardListItem(list, item, itemdata, itempos)
    local itemRoot = self:FindWndTrans(item, "itemRoot")
    local itemRootIcon = self:FindWndTrans(itemRoot, "Icon")
    local itemRootItemTab = self:FindWndTrans(itemRoot, "ItemTab")

    local descript = itemdata.descript
    local isShowTab = descript ~= 0
    CS.ShowObject(itemRootItemTab, isShowTab)

    if isShowTab then
        local tabImg = self._tabImgList[descript] or self._tabImgList[3]
        self:SetWndEasyImage(itemRootItemTab, tabImg)
    end
    self:CreateCommonIconImpl(itemRootIcon, itemdata)
end

function UISubWishPrige:OnClickOpenPop_New(ref)
    GF.OpenWnd("UIWishPrigeBuyPop", { ref = ref })
end

function UISubWishPrige:OnClickBuyGift(ref, giftName)
    local isUseItemBuy = string.find(ref.expend, "=")

    if isUseItemBuy then
        -- 钻石购买
        local item = LxDataHelper.ParseItem_3(ref.expend)
        local dia = gModelItem:GetNumByRefId(item.itemId)
        local value = item.itemNum
        local func = function()
            if dia >= value then
                gModelNormalActivity:OnBuyPrivilegeGiftReq(ref.refId)
            else
                gModelGeneral:OpenGetWayWnd({ itemId = item.itemId })
            end
        end
        GF.OpenWnd("UIOrdinTip", { refId = 110002, func = func, para = { value, giftName } })
    else
        -- 付费购买
        gModelPay:GiftPayCtrl(ref.refId, tonumber(ref.expend), ModelPay.PAY_TYPE_GIFT, ModelPay.PAY_GIFT_PRIVILEGE)
    end
end

function UISubWishPrige:SetTimeLimitTxtCD(timeLimitTextData)
    local endTime,timeTxt,root = timeLimitTextData.endTime,timeLimitTextData.timeTxt,timeLimitTextData.root
    local time = GetTimestamp()
    local timespan = endTime - time
    local showRoot = timespan > 0
    local timeStr = ""
    if showRoot then
        timeStr = LUtil.GetFormatCDTime(timespan)
    else
        local endCDFunc = timeLimitTextData.endCDFunc
        if endCDFunc then
            endCDFunc()
        end
    end
    self:SetWndText(timeTxt,timeStr)
    CS.ShowObject(root,showRoot)
end

function UISubWishPrige:SetTime()
    for i, v in pairs(self._timeTextList) do
        self:SetCountdown(v.timeText, v.refId)
    end

    for k,v in pairs(self._timeLimitTextList) do
        self:SetTimeLimitTxtCD(v)
    end
end

function UISubWishPrige:OnClickDayBox()
    gModelNormalActivity:OnReceiveDailyAwardReq()
end

function UISubWishPrige:OnTimer(key)
    self:SetTime()
end

function UISubWishPrige:OnClickByTips()
    if not self._helpTipsContent then return end

    local title = ccClientText(112)
    GF.OpenWnd("UIBzTips", { title = title, text = self._helpTipsContent })
end

function UISubWishPrige:SetCountdown(tran, refId)
    local time = GetTimestamp()
    local info = gModelNormalActivity:GetPrivilegeGiftListByRefId(refId)
    local endTime = info.endTime
    local timespan = endTime - time
    if (timespan > 0) then
        local timeStr = LUtil.FormatTimespanCn(timespan)

        self:SetWndText(tran, string.replace(ccClientText(14219), timeStr))
    end
end
------------------------------------------------------------------
return UISubWishPrige


