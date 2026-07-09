---
--- Created by Administrator.
--- DateTime: 2024/4/12 15:19:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBargain:LWnd
local UIGdBargain = LxWndClass("UIGdBargain", LWnd)
local Tweening = DG.Tweening

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBargain:UIGdBargain()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBargain:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBargain:OnCreate()
    LWnd.OnCreate(self)

    self.commonUIList = {}
    self.itemTweenKey = "itemTweenKey_"
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBargain:OnStart()
    LWnd.OnStart(self)
    self:UpdateTime()
    local isOpen = self:CheckBargainOpen()
    if not isOpen then
        self:WndClose()
        GF.ShowMessage(ccClientText(12654))
        return
    end

    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self.jpj = gLGameLanguage:IsJapanVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isEnus then
        self.mTimeObjBg.sizeDelta = Vector2(self.mTimeObjBg.rect.width + 100, self.mTimeObjBg.rect.height)
        CS.ShowObject(self.mOriginalObj, false)
        CS.ShowObject(self.mOriginalObj_En,true)
        
        self:SetAnchorPos(self.mLeft,Vector2.New(40,0))
    else
        CS.ShowObject(self.mOriginalObj, true)
        CS.ShowObject(self.mOriginalObj_En,false)
    end

    self:InitEvent()
    self:InitText()
    self:InitSpine()

    self:SendMsg()

    self:CreateWndEffect(self.mBlackboardEff, "fx_kanjia_3", "fx_kanjia_3", 100, false, false)
    self:TimerStart("BlackboardEffTime", 1, true)


end

function UIGdBargain:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBargainBtn, function()
        self:ClickBargainBtn()
    end)
    self:SetWndClick(self.mBuyBtn, function()
        self:ClickBuyBtn()
    end)
    self:SetWndClick(self.mUnBargainBtn, function()
        GF.OpenWnd("UIGdUnBargainMember")
    end)
    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 159 })
    end)

    self:WndEventRecv("OnGuildBargainInfoResp", function()
        self:UpdataBargainInfo()
        self:UpdateBtnState()
    end)
    self:WndEventRecv("OnGuildBargainItemUpdateResp", function()
        self:UpdataBargainInfo()
    end)
    self:WndEventRecv("OnGuildBargainBuyResp", function()
        self:UpdateBtnState()
    end)
    self:WndEventRecv("OnGuildBargainResp", function()
        self:UpdataBargainInfo()
        self:UpdateBtnState()
        self:TimerStart("waitEffTimer_2", 0.6, true)
    end)
end

function UIGdBargain:DrawBargainItem(_, item, data)
    local aniRoot = self:FindWndTrans(item, "AniRoot")
    local nameText = self:FindWndTrans(aniRoot, "NameText")
    local text1 = self:FindWndTrans(aniRoot, "Text1")
    local text1_enus = self:FindWndTrans(aniRoot, "Text1_enus")
    local text2 = self:FindWndTrans(aniRoot, "Text2")
    local icon = self:FindWndTrans(aniRoot, "Icon")
    local isBuy = self:FindWndTrans(aniRoot, "IsBuy")

    self:SetWndText(nameText, data.info.name)

    if CS.IsWebGL() and gLGameLanguage:IsJapanRegion() then
        LxUiHelper.SetSizeWithCurAnchor(nameText,0,200)
        LxUiHelper.SetSizeWithCurAnchor(nameText,0,40)
        self:SetAnchorPos(nameText,Vector2.New(-250,-1.9))
        if string.isempty(data.info.name) then return end
    end
    if self._isEnus or self._isVie then
        self:SetWndText(text1_enus, ccClientText(12631))
        CS.ShowObject(text1_enus, true)
        CS.ShowObject(text1, false)
    else
        CS.ShowObject(text1_enus, false)
        CS.ShowObject(text1, true)
        self:SetWndText(text1, ccClientText(12631))
    end
    if self._isVie then
        self:SetAnchorPos(text1_enus,Vector2.New(0,-2.1))
        self:SetAnchorPos(text2,Vector2.New(170,-0.9))
        self:SetAnchorPos(icon,Vector2.New(90,0))
    end

    if self.jpj then
        text1.sizeDelta=Vector2.New(210,40)
    end
    self:SetWndText(text2, data.bargainPrice)
    local image = gModelItem:GetItemImgByRefId(self.dialogueItem)
    self:SetWndEasyImage(icon, image)

    if data.info.playerId == gModelPlayer:GetPlayerId() then
        CS.ShowObject(isBuy, gModelGuild:GetIsBuyBargain() == 1)
    else
        CS.ShowObject(isBuy, data.isBuy == 1)
    end

    self:SetWndClick(
            aniRoot,
            function()
                gModelGeneral:PlayerShowReq(
                        data.info.playerId,
                        LCombatTypeConst.COMBAT_MAIN,
                        LPlayerShowConst.OTHER_SYSTEM
                )
            end
    )
end

function UIGdBargain:UpdataBargainList()
    local list = gModelGuild:GetBargainMemberInfo()
    CS.ShowObject(self.mNoRecord2, #list == 0)
    if not self.bargainList then
        self.bargainList = self:GetUIScroll("mBargainList")
        self.bargainList:Create(self.mBargainList, list, function(...)
            self:DrawBargainItem(...)
        end, UIItemList.SUPER)
    else
        self.bargainList:ResetList(list)
        self.bargainList:DrawAllItems()
    end
end

function UIGdBargain:OnTimer(key)
    if key == "BlackboardEffTime" then
        CS.ShowObject(self.mMoneyObj, true)
        CS.ShowObject(self.mBlackboardEff, false)
        self:TimerStop(key)
    end
    if key == "waitEffTimer_1" then
        self:SetWndText(self.mNowText, self.nowMoney)
        self:TimerStop(key)
    end
    if key == "waitEffTimer_2" then
        local list = gModelGuild:GetBargainMemberInfo()
        for i = 1, #list do
            local playerId = gModelPlayer:GetPlayerId()
            if playerId == list[i].info.playerId then
                gModelGeneral:OpenUIOrdinTips({
                    refId = 100026,
                    para = { list[i].bargainPrice },
                    func = function()
                        gModelGuild:OnGuildBargainInviteReq()
                    end
                })
            end
        end
        self:TimerStop(key)
    end
    if key == "bargainRunTime" then
        local _, timeStr = self:CheckBargainOpen()
        self:SetWndText(self.TimeText, timeStr)
    end
end

function UIGdBargain:DrawShopItem(_, item, data, pos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local iconEff = self:FindWndTrans(AniRoot, "IconEff")
    local icon = self:FindWndTrans(AniRoot, "Icon")
    local Text = self:FindWndTrans(AniRoot, "MoneyBg/Text")

    local Image = gModelGeneral:GetCommonItemImgRef(data)
    self:SetWndEasyImage(icon, Image)
    self:SetWndText(Text, LUtil.NumberCoversion(data.itemNum))
    self:SetWndClick(icon, function()
        gModelGeneral:ShowCommonItemTipWnd(data)
    end)

    local startPos = icon.localPosition
    local endPos = startPos + Vector3.New(0, 5, 0)
    self:TweenSeq_Suspend(self.itemTweenKey .. pos, icon, startPos, endPos, 1.5, nil, Tweening.Ease.InOutFlash, true)
    self:CreateWndEffect(iconEff, "fx_kanjia_1", "fx_kanjia_1" .. pos, 100, false, false)
end

function UIGdBargain:UpdateBtnState()
    local isBargain = gModelGuild:GetIsBargain()
    local isBuy = gModelGuild:GetIsBuyBargain()
    CS.ShowObject(self.mBargainBtn, not isBargain and not isBuy)
    CS.ShowObject(self.mBuyBtn, isBargain and not isBuy)
    CS.ShowObject(self.mIsBuy, isBargain and isBuy)
end

function UIGdBargain:InitText()
    self:SetWndText(self.mTitle, ccClientText(12627))
    self:SetWndText(self.mOriginalText1, ccClientText(12628))
    self:SetWndText(self.mOriginalText1_En, ccClientText(12628))
    self:SetWndButtonText(self.mBargainBtn, ccClientText(12629))
    self:SetWndButtonText(self.mBuyBtn, ccClientText(12634))
    local cfg = gModelGeneral:GetEmptyCfg(4006)
    self:SetWndText(self.mEmptyText, ccLngText(cfg.text))

    local selfInfo = gModelGuild:GetSelfGuildInfo()
    CS.ShowObject(self.mUnBargainBtn, selfInfo.position == 1 or selfInfo.position == 2)
end

function UIGdBargain:InitSpine()
    local ref = gModelHero:GetShowEffectById(270102)
    self:CreateWndSpine(self.mSpine, "LH_Mao01_zhcn", "heroDrawing", false)
end

function UIGdBargain:CheckBargainOpen()
    local sysTime = LUtil.FormatInTheDayTime(GetTimestamp())
    local s = string.split(sysTime, ":")
    local sysTick = (s[1] * 60 * 60) + (s[2] * 60) + s[3]
    local isOpen = false
    local str = ""
    if sysTick >= self.bargainStartTime then
        isOpen = true
        str = ccClientText(12644, LUtil.FormatTimespanNumber(self.bargainEndTime - sysTick))
    elseif sysTick < self.bargainStartTime then
        isOpen = false
        str = ccClientText(12645)
    end
    return isOpen, str
end

function UIGdBargain:ShowNowEff()
    if not self.nowEff then
        self.nowEff = self:CreateWndEffect(self.mNowEff, "fx_kanjia_2", "fx_kanjia_2", 100, false, false)
    else
        CS.ShowObject(self.mNowEff, false)
        CS.ShowObject(self.mNowEff, true)
    end
end

function UIGdBargain:UpdateTime()
    self.TimeText = self:FindWndTrans(self.mTimeObj, "Text")
    local time = gModelGuild:GetGuildConfigRefByKey("guildBargainOpenTime")
    local s = string.split(time, ",")
    self.bargainStartTime = tonumber(s[1]) * 60 * 60
    self.bargainEndTime = tonumber(s[2]) * 60 * 60
    local _, timeStr = self:CheckBargainOpen()
    self:SetWndText(self.TimeText, timeStr)
    self:TimerStart("bargainRunTime", 1, true)
end

function UIGdBargain:GetTalkText(n)
    local info = gModelGuild:GetGuildConfigRefByKey("guildBargainTalk")
    local s = string.split(info, ",")
    if n == 1 then
        return ccClientText(tonumber(string.split(s[1], "=")[2]))
    end
    if n <= 0 then
        return ccClientText(tonumber(string.split(s[#s], "=")[2]))
    end
    for i = 1, #s do
        local lvl = string.split(s[i], "=")
        if n < tonumber(lvl[1]) then
            if s[i + 1] then
                local nextLvl = string.split(s[i + 1], "=")
                if n >= tonumber(nextLvl[1]) then
                    return ccClientText(tonumber(nextLvl[2]))
                end
            else
                return ccClientText(tonumber(lvl[2]))
            end
        end
    end
end

function UIGdBargain:SendMsg()
    gModelGuild:OnGuildMemberListReq(gModelGuild:GetGuildInfo().guildId)
    gModelGuild:OnGuildBargainInfoReq()
end

function UIGdBargain:ClickBargainBtn()
    local isOpen, str = self:CheckBargainOpen()
    if isOpen then
        gModelGuild:OnGuildBargainReq()
    else
        GF.ShowMessage(str)
    end
end

function UIGdBargain:ClickBuyBtn()
    local isOpen, str = self:CheckBargainOpen()
    if isOpen then
        if gModelGeneral:CheckItemEnough(self.dialogueItem, self.nowMoney, true, self:GetWndName()) then
            if self.nowMoney > 0 then
                gModelGeneral:OpenUIOrdinTips({
                    refId = 100027,
                    func = function()
                        gModelGuild:OnGuildBargainBuyReq()
                    end,
                    leftFunc = function()
                        gModelGuild:OnGuildBargainInviteReq()
                    end
                })
                return
            else
                gModelGuild:OnGuildBargainBuyReq()
            end
        else
            GF.ShowMessage(ccLngText(GameTable.PlayerItemRef[self.dialogueItem].name) .. ccClientText(18719))
        end
    else
        GF.ShowMessage(str)
    end
end

function UIGdBargain:UpdateItemList(itemList)
    if not self.itemList then
        self.itemList = self:GetUIScroll("mShopItemList")
        self.itemList:Create(self.mShopItemList, itemList, function(...)
            self:DrawShopItem(...)
        end, UIItemList.SUPER_GRID)
    else
        self.itemList:RefreshList(itemList)
        self.itemList:DrawAllItems()
    end
end

function UIGdBargain:UpdataBargainInfo()
    local itemList, dialoguePrice, dialogueItem, bargainPrice = gModelGuild:GetBargainItemInfo()
    self.dialogueItem = dialogueItem
    local oldMoney = self.nowMoney
    self.nowMoney = dialoguePrice - bargainPrice
    if oldMoney ~= dialoguePrice - bargainPrice then
        self:TimerStart("waitEffTimer_1", 0.5, true)
        self:ShowNowEff()
    else
        self:SetWndText(self.mNowText, self.nowMoney)
    end
    self:SetWndText(self.mDialogueText, self:GetTalkText(self.nowMoney / dialoguePrice))
    if gLGameLanguage:IsJapanVersion() then
        self:InitTextSizeWithLanguage(self.mDialogueText,-3)
        LxUiHelper.SetSizeWithCurAnchor(self.mDialogueText,0,280)
    end

    self:SetWndText(self.mOriginalText2, dialoguePrice)
    self:SetWndText(self.mOriginalText2_En, dialoguePrice)
    local image = gModelItem:GetItemImgByRefId(dialogueItem)
    self:SetWndEasyImage(self.mOriginalIcon, image)
    self:SetWndEasyImage(self.mOriginalIcon_En, image)
    self:SetWndEasyImage(self.mBargainIcon, image)
    local num, money = gModelGuild:GetBargainNumAndMoney()
    local member = #gModelGuild:GetGuildMemberList()
    self:SetWndText(self.mBargainText, string.replace(ccClientText(12630), num, member))
    self:SetWndText(self.mBargainText2, money)
    self:UpdateItemList(itemList)
    self:UpdataBargainList()

    CS.ShowObject(self.mBuyRedPoint, self.nowMoney == 0)
end
------------------------------------------------------------------
return UIGdBargain