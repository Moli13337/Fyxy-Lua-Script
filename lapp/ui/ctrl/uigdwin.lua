---
--- Created by BY.
--- DateTime: 2023/10/21 20:20:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdWin:LWnd
local UIGdWin = LxWndClass("UIGdWin", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdWin:UIGdWin()
    self._chatAniKey = "_chatAniKey"
    local lime = gModelChat:GetChatConfigRefByKey("floatWindowAutoFold")
    self._chatInitTime = lime
    self._chatCutTimeKey = "_chatCutTimeKey"
    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdWin:OnWndClose()
    self:ClearCommonIconList(self._uiHyperList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdWin:OnCreate()
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    self._BotBtnData = {
        [1] = { name = ccClientText(12619), Image = "guild_btn_2", openWin = "UIGdMagPop", redPointId = 12105000 },
        [2] = { name = ccClientText(12620), Image = "guild_btn_1", openWin = "UIDian", winData = { shopId = 2002 } },
        [3] = { name = ccClientText(12621), Image = "guild_btn_4", openWin = "UIGdLogPop" },
        [4] = { name = ccClientText(12622), Image = "guild_btn_3", openWin = "UIGdMemberPop" }
    }
    self._BotBtnRedPoint = {}

    self._InfoBtnRedPoint = {
        { trans = self.mBattleBtn },
        { trans = self.mBossBtn },
        { trans = self.mSkillBtn },
        { trans = self.mDonateBtn },
        { trans = self.mCopyBtn },
        { trans = self.mBargainBtn, redPointId = 12109000 },
        { trans = self.mEmptyIslandBtn }
    }
    self._curSelBotBtn = 0

    self._uiHyperList = {}

    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isCanShowAirPop = true
    self._isJapaness  =gLGameLanguage:IsJapanVersion()
    if self._isEnus   then
        self.mPowerText.localPosition = Vector3.New(180, self.mPowerText.localPosition.y, 0)
        self._isCanShowAirPop = false
    end

    if self._isJapaness then
        self.mPowerText.localPosition = Vector3.New(0, self.mPowerText.localPosition.y, 0)
    end 
    
    self:InitEvent()
    self:InitMessage()
    self:InitText()
    self:InitTabList()
    self:InitEffect()
    self:InitCommand()
    self:UpdateRedPoint()
    self:UpdateBargain()
    self:UpdateBattle()
    self:UpdateShow(true)
    self:UpdateGuildHolyBattle()
    if not gModelFunctionOpen:CheckIsShow(ModelFunctionOpen.GUILDBATTLE) then
        CS.ShowObject(self.mBattleBtn, false)
    end

    if not gModelFunctionOpen:CheckIsShow(ModelFunctionOpen.GUILDTRBOSS) then
        CS.ShowObject(self.mBossBtn, false)
    end

    --刷新下聊天窗的部分
    self:InitSizeDelta()
    self:SetChatAirPop()
    self:SetChatAirPopDrag()

    --开始聊天的倒计时  
    self._chatStarCutTime = 0
    self:TimerStop(self._chatCutTimeKey)
    self:TimerStart(self._chatCutTimeKey, 1, false, -1)
    
    CS.ShowObject(self.mChatAirPopOptBtn,false)
end

function UIGdWin:RefreshData()
    local guildInfo = gModelGuild:GetGuildInfo()
    local memberlist = gModelGuild:GetGuildMemberList()
    local chairman = guildInfo.chairman
    self:SetWndText(self.mNameText, guildInfo.guildName)
    self:SetWndText(self.mPresidentText, string.replace(ccClientText(12573), chairman._name))
    -- self:SetWndText(self.mPowerText,LUtil.FormatCoversionHurtNumSpriteText(tonumber(guildInfo.power),false, nil, 20))
    self:SetWndText(self.mPowerText, string.replace(ccClientText(12614), LUtil.NumberCoversion(guildInfo.power)))
    self:SetWndText(self.mLvText, string.replace(ccClientText(12575), guildInfo.level))
    self:SetWndText(self.mNumText,
            string.replace(ccClientText(12574), guildInfo.count, gModelGuild:GetGuildNumByLv(guildInfo.level)))

    local str = ccLngText(guildInfo.announcement)
    self:SetWndText(self.mDesText, string.replace(ccClientText(12581), str))
    local nexExp = gModelGuild:GetGuildExpByLv(guildInfo.level)
    local barStr = guildInfo.exp .. "/<#ffffff>" .. nexExp .. "</color>"
    if nexExp == -1 then
        barStr = ccClientText(12611)
    end
    self:SetWndText(self.mBarText, barStr)
    self.mExpBar.maxValue = gModelGuild:GetGuildExpByLv(guildInfo.level)
    self.mExpBar.value = guildInfo.exp

    local selfInfo = gModelGuild:GetSelfGuildInfo()
    CS.ShowObject(self.mReDesBtn, selfInfo.position < 3)

    local bgRef = gModelGuild:GetGuildFlagRefByRefId(guildInfo.flagBgId)
    local iconRef = gModelGuild:GetGuildFlagRefByRefId(guildInfo.flagId)
    if bgRef then
        self:SetWndEasyImage(self.mFlagBg, bgRef.res)
    end
    if iconRef then
        self:SetWndEasyImage(self.mFlagIcon, iconRef.res)
    end
end

function UIGdWin:OnClickHelp()
    GF.OpenWnd("UIBzTips", { refId = 40 })
end

function UIGdWin:OnClickBattle()
    local info = gModelGuildMelee:GetGuildMeleeInfo()
    local page = 1
    if info and info.state == ModelGuildMelee.STATE_Melee then
        page = 3
    end
    GF.OpenWndBottom("UIGdWar2Win", { page = page })
end

function UIGdWin:UpdateBattle()
    self.meleeInfo = gModelGuildMelee:GetGuildMeleeInfo()
    self.battleTimeObj = self:FindWndTrans(self.mBattleBtn, "TimeObj")
    self.battleTimeText = self:FindWndTrans(self.battleTimeObj, "TimeText")

    --获取其他的部分
    self.battleAirPopDesDIV = self:FindWndTrans(self.mBattleBtn, "AirPopDesDIV")

    self:TimerStop("battleRunTime")
    if not self.meleeInfo then
        CS.ShowObject(self.battleTimeObj, false)
        return
    end
    if self.meleeInfo.state == 5 then
        local desStr = ccClientText(17935)
        self:SetWndText(self.battleTimeText, desStr)
        CS.ShowObject(self.battleTimeObj, true)
    else
        self:TimerStart("battleRunTime", 1, false, -1)
        self:SetBattleTime()
    end

    --设置下
    local _meleeInfo = gModelGuildMelee:GetGuildMeleeInfo()
    CS.ShowObject(self.battleAirPopDesDIV, false)
    if _meleeInfo then
        local isApply = _meleeInfo.state >= ModelGuildMelee.STATE_APPLY and _meleeInfo.signUpPlayerState == 1
        CS.ShowObject(self.battleAirPopDesDIV, (not isApply) and self.meleeInfo.state >= 3)
        local strTran = self:FindWndTrans(self.battleAirPopDesDIV, "AirPopDesText")
        local showStr = ccClientText(44082)
        self:SetWndText(strTran, showStr)
    end
end

function UIGdWin:CheckBargainOpen()
    local sysTime = LUtil.FormatInTheDayTime(GetTimestamp())
    local s = string.split(sysTime, ":")
    local sysTick = (s[1] * 60 * 60) + (s[2] * 60) + s[3]
    local isOpen = false
    local time = 0
    if sysTick >= self.bargainStartTime then
        isOpen = true
    elseif sysTick < self.bargainStartTime then
        isOpen = false
        time = self.bargainStartTime - sysTick
    end
    return isOpen, ccClientText(12646, LUtil.FormatTimeStr1(math.ceil(time)))
end

function UIGdWin:UpdateBargainShow()
    local isOpen, timeStr = self:CheckBargainOpen()
    CS.ShowObject(self.bargainTimeObj, not isOpen)
    self:SetWndText(self.bargainTimeText, timeStr)


end
function UIGdWin:InitEffect()
    self._jianzhurukouEffect = {}
    local battleRoot = CS.FindTrans(self.mBattleBtn, "OpenEffect")
    local bargainRoot = CS.FindTrans(self.mBargainBtn, "OpenEffect")
    self._jianzhurukouEffect["BattleBtn"] = self:CreateWndEffect(battleRoot, "fx_jianzhurukou", "BattleBtn", 100, nil, nil, 1, nil, nil, true)
    self._jianzhurukouEffect["BattleBtn"]:SetVisible(false)
    self._jianzhurukouEffect["BargainBtn"] = self:CreateWndEffect(bargainRoot, "fx_jianzhurukou", "BargainBtn", 100, nil, nil, 1, nil, nil, true)
    self._jianzhurukouEffect["BargainBtn"]:SetVisible(false)

    local holybattleRoot = CS.FindTrans(self.mEmptyIslandBtn, "OpenEffect")
    self._jianzhurukouEffect["EmptyIslandBtn"] = self:CreateWndEffect(holybattleRoot, "fx_jianzhurukou", "EmptyIslandBtn", 100, nil, nil, 1, nil, nil, true)
    self._jianzhurukouEffect["EmptyIslandBtn"]:SetVisible(false)

    self:CreateWndEffect(self.mWinEff, "fx_longqituan", "fx_longqituan", 100, false, false)
end

function UIGdWin:InitSizeDelta()
    local width, height
    local bWidth, bHeight
    local btnRect = self.mChatBtn:GetComponent(typeofRectTransform)
    if btnRect then
        bWidth, bHeight = btnRect.sizeDelta.x / 2, btnRect.sizeDelta.y / 2 + 10
    end
    local rect = self.mScope:GetComponent(typeofRectTransform)
    if rect then
        width, height = rect.rect.width / 2, rect.rect.height / 2
    end
    self._maxX = (width or 320) - bWidth
    self._maxY = (height or 438) - bHeight
    self._btnX = self.mChatBtnRoot.localPosition.x
end

function UIGdWin:UpdateGuildHolyBattle()
    local stage = gModelGuildHolyBattle:GetStage()
    self._jianzhurukouEffect["EmptyIslandBtn"]:SetVisible(false)

    self.emptyIslandBtn = self:FindWndTrans(self.mEmptyIslandBtn, "TimeObj")
    self.emptyTimeText = self:FindWndTrans(self.emptyIslandBtn, "TimeText")

    --获取其他的部分
    self.emptyIslandAirPopDesDIV = self:FindWndTrans(self.mEmptyIslandBtn, "AirPopDesDIV")
    local strTran = self:FindWndTrans(self.emptyIslandAirPopDesDIV, "AirPopDesText")
    CS.ShowObject(self.emptyIslandAirPopDesDIV, false)

    local showEff = true
    if stage == 1 then
        self:SetWndText(self.emptyTimeText, ccClientText(44002))    --[44002] [匹配中...]
        showEff = false
    elseif stage == 2 then
        self:SetWndText(self.emptyTimeText, ccClientText(44003))    --[44003] [战备中...]
    elseif stage == 3 then
        self:SetWndText(self.emptyTimeText, ccClientText(44004))    --[44004] [战斗中...]
        --获取下战斗的次数
        local challengTime, isShow = gModelGuildHolyBattle:GetChallengeCount()
        local times = 0

        if not isShow then
            times = 0
        else
            times = gModelGuildHolyBattle:GetTotalCount() - challengTime
        end

        if times > 0 then
            local _isPlayerPartIn = gModelGuildHolyBattle:CheckPlayerPartInState()
            if _isPlayerPartIn then
                CS.ShowObject(self.emptyIslandAirPopDesDIV, true and self._isCanShowAirPop)
                local showStr = ccClientText(44084)
                self:SetWndText(strTran, showStr)
            else
                CS.ShowObject(self.emptyIslandAirPopDesDIV, false)
            end
        end

    elseif stage == 4 then
        self:SetWndText(self.emptyTimeText, ccClientText(44005))    --[44005] [結算中...]
    elseif stage == 5 then
        self:SetWndText(self.emptyTimeText, ccClientText(44060))    --[44060] [已經結束...]
        local isShowRed = gModelGuildHolyBattle:CheckRedpointTreasure()
        if isShowRed then
            --宝箱红点 有的话就显示
            CS.ShowObject(self.emptyIslandAirPopDesDIV, true and self._isCanShowAirPop)
            local showStr = ccClientText(44083)
            self:SetWndText(strTran, showStr)
        end
    else
        stage = gModelGuildHolyPeak:GetStage()
        local b = stage ~= ModelGuildHolyPeak.STAGE_0 and stage ~= ModelGuildHolyPeak.STAGE_12
        if b then
            self:SetWndText(self.emptyTimeText, gModelGuildHolyPeak:GetOutStageText())
        else
            --五个状态之外 判断开启时间
            self:SetGuildHolyBattleTime()
            showEff = false
        end
    end

    CS.ShowObject(self.emptyIslandBtn, stage ~= 0 and stage ~= 12)
    self._jianzhurukouEffect["EmptyIslandBtn"]:SetVisible(showEff)
end

function UIGdWin:SetBattleTime()
    if not self.meleeInfo then
        CS.ShowObject(self.battleTimeObj, false)
        return
    end

    self._jianzhurukouEffect["BattleBtn"]:SetVisible(false)

    local state = self.meleeInfo.state
    local startTime = tonumber(self.meleeInfo.startTime) / 1000
    local sevenTime = GetTimestamp()
    local timespan = math.ceil(startTime - sevenTime)
    if timespan < 0 then
        self:TimerStop("battleRunTime")
        CS.ShowObject(self.battleTimeObj, false)
        return
    end
    local desStr, timeStr = "", ""
    if state == 1 or state == 2 then
        desStr = ccClientText(17901)
        timeStr = string.replace(ccClientText(17965), LUtil.FormatTimeStr1(timespan))
    elseif state == 3 then
        desStr = string.replace(ccClientText(17937), LUtil.FormatTimeStr1(timespan))
        self._jianzhurukouEffect["BattleBtn"]:SetVisible(true)
    elseif state == 4 then
        desStr = string.replace(ccClientText(17906), LUtil.FormatTimeStr1(timespan))
        self._jianzhurukouEffect["BattleBtn"]:SetVisible(true)
    elseif state == 5 then
        desStr = ccClientText(17935)
    end
    self:SetWndText(self.battleTimeText, desStr .. timeStr)
    CS.ShowObject(self.battleTimeObj, true)
end

function UIGdWin:ClickBotBtn(index)
    if index == 1 then
        local pos = gModelGuild:GetGuildPosition()
        if pos ~= 1 and pos ~= 2 then
            GF.ShowMessage(ccClientText(12651))
            return
        end
    end
    GF.OpenWnd(self._BotBtnData[index].openWin, self._BotBtnData[index].winData or {})
end

function UIGdWin:OnClickSkill()
    GF.OpenWndBottom("UIGdJNPop")
end

function UIGdWin:InitText()
    self:SetWndText(self:FindWndTrans(self.mBattleBtn, "Text"), ccClientText(12615))
    self:SetWndText(self:FindWndTrans(self.mBossBtn, "Text"), ccClientText(12617))
    self:SetWndText(self:FindWndTrans(self.mSkillBtn, "Text"), ccClientText(12616))
    self:SetWndText(self:FindWndTrans(self.mDonateBtn, "Text"), ccClientText(12451))
    self:SetWndText(self:FindWndTrans(self.mCopyBtn, "Text"), ccClientText(12453))
    self:SetWndText(self:FindWndTrans(self.mBargainBtn, "Text"), ccClientText(12618))
    self:SetWndText(self:FindWndTrans(self.mEmptyIslandBtn, "Text"), ccClientText(12643))
    self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
    self:SetWndText(self:FindWndTrans(self.mRankBtn, "Text"), ccClientText(10360))
end

function UIGdWin:OnDrawTab(list, item, itemData, index)
    self:SetWndTabText(item, itemData.name)
    self:SetWndEasyImage(self:FindWndTrans(item, "Off"), itemData.Image)
    self:SetWndEasyImage(self:FindWndTrans(item, "On"), itemData.Image)
    self:SetWndTabStatus(item, 1)
    self.tabBtn[index] = item
    self._BotBtnRedPoint[index] = self:FindWndTrans(item, "redPoint")
    self:SetWndClick(item, function(...)
        self:ClickBotBtn(index)
    end)
end

function UIGdWin:OnClickDonate()
    GF.OpenWndBottom("UIGdDonatePop")
end

function UIGdWin:OnClickCopy()
    local isFight = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_GUILD_BRAVE)
    if isFight then
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_GUILD_BRAVE, {})
        self:WndClose()
    else
        GF.OpenWndBottom("UIGdBraveWin")
    end
end

function UIGdWin:OnClickReDes(isAuto)
    GF.OpenWnd("UIGdHeaderPop", { isAuto = isAuto })
end

function UIGdWin:UpdateBargain()
    if gModelFunctionOpen:CheckIsOpened(12109000, true) then
        self.bargainTimeObj = self:FindWndTrans(self.mBargainBtn, "TimeObj")
        self.bargainTimeText = self:FindWndTrans(self.bargainTimeObj, "TimeText")
        self.bargainAirPopDesDIV = self:FindWndTrans(self.mBargainBtn, "AirPopDesDIV")
        local time = gModelGuild:GetGuildConfigRefByKey("guildBargainOpenTime")
        local s = string.split(time, ",")
        self.bargainStartTime = tonumber(s[1]) * 60 * 60
        self.bargainEndTime = tonumber(s[2]) * 60 * 60

        local isOpen = self:CheckBargainOpen()
        if isOpen then
            gModelGuild:OnGuildBargainInfoReq()
        end

        if gLGameLanguage:IsVieVersion() then
            self:SetAnchorPos(self.bargainTimeObj,Vector2.New(30,-34))
        end

        self:UpdateBargainShow()
        self:TimerStart("bargainRunTime", 1, true)
    end
end

function UIGdWin:MsgListItem(list, item, itemdata, itempos)
    local InstanceID = item:GetInstanceID()
    local image = self:FindWndTrans(item, "Image")
    local msgText = self:FindWndTrans(item, "MsgText")
    local faceImg = self:FindWndTrans(item, "FaceImg")
    local faceSpine = self:FindWndTrans(item, "FaceSpine")

    CS.ShowObject(faceImg, false)
    CS.ShowObject(faceSpine, false)
    local ref = gModelChat:GetChatChannelRefByChannelId(itemdata.channel)
    local playerName = itemdata.playerName
    if itemdata.sex == 1 then
        playerName = LUtil.FormatColorStr(playerName, "blue")
    elseif itemdata.sex == 0 then
        playerName = LUtil.FormatColorStr(playerName, "purple")
    end
    local msgPot = string.replace(ccClientText(11150), ccLngText(ref.channel), playerName)

    self:SetWndText(self.mTestText2, msgPot)

    self:SetWndClick(image, function()
        self:OnClickChatAirBg()
    end)

    local msg = itemdata:GetMsg()
    if (itemdata.type == ModelChat.MSGTYPE_GUILDNOTICE or itemdata.channel == ModelChat.CHANNEL_SYSTEM or itemdata.type == ModelChat.MSGTYPE_NOTICE) then
        msg = gModelChat:SetChatSkipFun(msgText, InstanceID, itemdata, msg, self._uiHyperList, "")
    else
        msg = self:SetATPlayerName(msg, itemdata.atPlayerName)
        local faceId = LUtil.ChatInfoGetDaFace(msg)
        if (faceId > 0) then
            --大表情改成显示替代的文字
            self:SetWndText(msgText, msgPot .. ccClientText(11163))
            LxUiHelper.SetSizeWithCurAnchor(item, 1, 23)
            return
        end
        msg = LUtil.GetFaceStr(msg, 18)
        local isShare, shareInfo = gModelChat:SetShareType(itemdata, msg)
        if isShare then
            msg = gModelChat:OnAddHyper(msgText, InstanceID, shareInfo, self._uiHyperList, function()
                self:OnClickChatAirBg()
            end)
        else
            msg = shareInfo
        end
    end
    local msgStr = msgPot .. " " .. msg
    -- self:SetWndText(self.mTestText, msgStr)
    -- local uiText = LxUiHelper.FindXTextCtrl(self.mTestText)
    -- local height = uiText.preferredHeight
    self:SetWndText(msgText, msgStr)
    local height = 23
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)

    --文本
    local floatWindowWordsMax = gModelChat:GetChatConfigRefByKey("floatWindowWordsMax")
    floatWindowWordsMax = checknumber(floatWindowWordsMax)
    if floatWindowWordsMax > 0 then
        LxUiHelper.SetSizeWithCurAnchor(msgText, 0, floatWindowWordsMax)
    end
end

function UIGdWin:OnClickChatAirBg()
    local open, msg = gModelFunctionOpen:CheckIsOpened(11700000)
    if open then
        GF.OpenWnd("UISayPop")
    else
        if msg then
            GF.ShowMessage(msg)
        end
    end
end
function UIGdWin:InitMessage()
    self:WndNetMsgRecv(LProtoIds.GuildInfoResp, function()
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildInfoChangeResp, function()
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.QuitGuildResp, function()
        self:WndClose()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMemberListResp, function()
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildLogListResp, function()
        self:RefreshLog()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildLookNoticeResp, function(pb)
        --公会是否观看过公告请求返回
        local lookState = pb.lookState
        if lookState ~= 0 then
            return
        end

        local inGuide = gModelGuide:IsInGuide()
        if inGuide then
            return
        end

        self:OnClickReDes(true)
    end)
    self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE, function()
        self:UpdateRedPoint()
    end)
    self:WndEventRecv(EventNames.SHOW_MAIN_ACTSCROLL, function(isShow)
        self:UpdateShow(isShow)
    end)
    self:WndEventRecv(EventNames.ON_CHAT_TA_SHOW, function(bool)
        self._isShowAir = bool
        CS.ShowObject(self.mChatAirShow, bool)
    end)
    self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp, function()
        self:UpdateMsg()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeStateResp, function(pb)
        self:UpdateBattle()
    end)

    self:WndEventRecv("OnGuildBargainInfoResp", function()
        self:UpdateBargainEff()
    end)
    self:WndEventRecv("OnGuildBargainItemUpdateResp", function()
        self:UpdateBargainEff()
    end)
    self:WndEventRecv("OnGuildBargainBuyResp", function()
        self:UpdateBargainEff()
    end)
    self:WndEventRecv("OnGuildBargainResp", function()
        self:UpdateBargainEff()
    end)
    self:WndEventRecv("OnGuildSetFlagResp", function()
        self:RefreshData()
    end)

    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.StageDataChange, function()
        self:UpdateGuildHolyBattle()
    end)
    self:WndEventRecv("GuildPinnacleStageResp", function()
        self:UpdateGuildHolyBattle()
    end)
    --红点信息
    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:UpdateGuildHolyBattle() end)


    --自己的挑战信息
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.ChallengeDataChange, function()
        local times = gModelGuildHolyBattle:GetTotalCount() - gModelGuildHolyBattle:GetChallengeCount()
        local strTran = self:FindWndTrans(self.emptyIslandAirPopDesDIV, "AirPopDesText")
        if times > 0 then
            local _isPlayerPartIn = gModelGuildHolyBattle:CheckPlayerPartInState()
            if _isPlayerPartIn then
                CS.ShowObject(self.emptyIslandAirPopDesDIV, true  and self._isCanShowAirPop)
                local showStr = ccClientText(44084)
                self:SetWndText(strTran, showStr)
            else
                CS.ShowObject(self.emptyIslandAirPopDesDIV, false)
            end
        end
    end)

    self:WndEventRecv(EventNames.ON_CHAT_CHANGE_CHATAIRPOP_SET, function()
        self:SetChatAirPopDrag()
    end)

end

function UIGdWin:RefreshLog()
    local list = gModelGuild:GetGuildLogByType(1)
    if #list <= 0 then
        return
    end
    local logList = list[1].list
    table.sort(logList, function(a, b)
        return a.time > b.time
    end)
    local logDes = gModelGuild:GetGuildLogDesByLog(logList[1])
    local str = logDes.name .. logDes.time .. logDes.str
    self:SetWndText(self.mLogText, str)
    self:InitTextLineWithLanguage(self.mLogText, -30)
    self:InitTextSizeWithLanguage(self.mLogText, -2)
    self:SetWndText(self.mLogTesxText, str)
    local isE = self.mLogTesxText_1.preferredHeight < 30
    if isE then
        local log = logList[2]
        if not log then
            local logs = list[2]
            if not logs then
                return
            end
            local loglist = logs.list
            table.sort(loglist, function(a, b)
                return a.time > b.time
            end)
            log = loglist[1]
        end
        local logDes2 = gModelGuild:GetGuildLogDesByLog(log)
        local str2 = logDes2.name .. logDes2.time .. logDes2.str
        str = str .. "\n" .. str2
        self:SetWndText(self.mLogText, str)
    end
end

function UIGdWin:InitTabList()
    self.tabBtn = {}
    self.tabList = self:GetUIScroll("TabScroll")
    self.tabList:Create(self.mTabScroll, self._BotBtnData, function(...)
        self:OnDrawTab(...)
    end)
end

function UIGdWin:IsOpent()
    self._isShowAir = true
    local isAir = false
    local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)

    if sensitive then
        local _bool = gModelFunctionOpen:CheckIsOpened(11700010, false)
        if _bool then
            isAir = gModelChat:GetChatSetValue(7)
        end
    end
    CS.ShowObject(self.mChatAirPop, not isAir)
    CS.ShowObject(self.mChatBtn, not isAir)
end
function UIGdWin:OnChatAirPopOptBtnClick()
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq(self._chatAniKey)

    self._isPlayChatAni = true
    local chatPlayDelayTime = 0.5
    local chatPlayTime = 0.3

    if self.mChatAirPop.localScale.x > 0 then
        seq:Insert(0, self.mChatAirPop:DOScale(Vector3.one * 0, chatPlayTime))
        self:SetWndEasyImage(self.mChatAirPopOptBtn, "chat_icon_11_1")
    else
        seq:Insert(0, self.mChatAirPop:DOScale(Vector3.one, chatPlayTime))
        self:SetWndEasyImage(self.mChatAirPopOptBtn, "chat_icon_11")
    end

    seq:InsertCallback(chatPlayDelayTime, function()
        self._isPlayChatAni = false
    end)

    seq:OnComplete(function()
        seqCom:DeleteSeq(self._chatAniKey)
    end)
    seq:PlayForward()
end

function UIGdWin:OnClickReName()
    GF.OpenWnd("UIGdReNamePop")
end

function UIGdWin:OnClickRank()
    GF.OpenWndBottom("UIRkPop",{refId = 5})
end

function UIGdWin:SetDragItemPos(trans, eventData)
    local camera = eventData.pressEventCamera
    local pos = camera:ScreenToWorldPoint(eventData.position)
    pos = trans.parent:InverseTransformPoint(pos)

    local transPos = trans.localPosition

    local x = Mathf.Clamp(pos.x, -self._maxX, self._maxX)
    local y = Mathf.Clamp(pos.y, -self._maxY, self._maxY)

    trans.localPosition = Vector3.New(x, y, transPos.z)
end

function UIGdWin:UpdateBargainEff()
    local isOpen = self:CheckBargainOpen()
    if not isOpen then
        self._jianzhurukouEffect["BargainBtn"]:SetVisible(false)
        return
    end
    local isBargain = gModelGuild:GetIsBargain()
    local isBuy = gModelGuild:GetIsBuyBargain()
    local _, dialoguePrice, _, bargainPrice = gModelGuild:GetBargainItemInfo()
    local isHalf = (dialoguePrice - bargainPrice) / dialoguePrice <= 0.5
    if not isBargain or (not isBuy and isHalf) then
        self._jianzhurukouEffect["BargainBtn"]:SetVisible(true)
    else
        self._jianzhurukouEffect["BargainBtn"]:SetVisible(false)
    end

    --这里控制下显示
    if isOpen then
        local isBargain = gModelGuild:GetIsBargain()
        local isBuy = gModelGuild:GetIsBuyBargain()
        CS.ShowObject(self.bargainAirPopDesDIV, false)

        local strTran = self:FindWndTrans(self.bargainAirPopDesDIV, "AirPopDesText")

        local showStr = ccClientText(44080)

        if not isBargain then
            --尚未砍价
            self:SetWndText(strTran, showStr)
            LxTimer.DelayFrameCall(function()
                CS.ShowObject(self.bargainAirPopDesDIV, true and self._isCanShowAirPop)
                UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.bargainAirPopDesDIV)
            end, 1)
            return
        end

        --砍价了 未购买 判断是否小于负数
        if not isBuy then
            --没有购买
            local itemList, dialoguePrice, dialogueItem, bargainPrice = gModelGuild:GetBargainItemInfo()
            local nowMoney = dialoguePrice - bargainPrice

            if nowMoney < 0 then
                showStr = ccClientText(44081)
                self:SetWndText(strTran, showStr)
                LxTimer.DelayFrameCall(function()
                    CS.ShowObject(self.bargainAirPopDesDIV, true and self._isCanShowAirPop)
                    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.bargainAirPopDesDIV)
                end, 1)
            end
        end
    end
end

function UIGdWin:SetChatAirPopDrag()
    local canDrag = gModelChat:GetChatSetValue(7)
    self:UIDragSetItem("UIGdWinchatBtn", "AniRoot/ChatBtnRoot", CS.YXUIDrag.DragMode.DragOrigin, canDrag)

    if self.mChatAirPop.localScale.x > 0 then
        if canDrag then
            self:OnChatAirPopOptBtnClick()
        end
    else
        --如果是小于0 没法滑动就展开
        if not canDrag then
            self:OnChatAirPopOptBtnClick()
        end
    end
end

function UIGdWin:OnClickBargain()
    if gModelFunctionOpen:CheckIsOpened(12109000, true) then
        local isOpen = self:CheckBargainOpen()
        if isOpen then
            GF.OpenWnd("UIGdBargain")
        else
            GF.ShowMessage(ccClientText(12647))
        end
    end
end

function UIGdWin:UpdateShow(isShow)
    if not isShow and isShow ~= nil then
        CS.ShowObject(self.mChatAirPop, isShow and gModelFunctionOpen:CheckIsShow(11700000))
        CS.ShowObject(self.mChatBtn, isShow and gModelFunctionOpen:CheckIsShow(11700000))
        return
    end
    self:IsOpent()
end

function UIGdWin:SetGuildHolyBattleTime()
    local startTime = gModelGuildHolyBattle:GetStarTime()
    local sevenTime = GetTimestamp()
    local timespan = math.ceil(startTime - sevenTime)
    local desStr = string.replace(ccClientText(44065), LUtil.FormatTimeStr1(timespan))

    self:SetWndText(self.emptyTimeText, desStr)

    if timespan <= 0 then
        self:TimerStop("guildHolyTime")
        CS.ShowObject(self.emptyIslandBtn, false)
        return
    end
end
function UIGdWin:UIDragOnEnd(dragKey, eventData)
    if dragKey == "wndMainCitychatBtn" then
        local trans = self.mChatBtnRoot
        local camera = eventData.pressEventCamera
        local pos = camera:ScreenToWorldPoint(eventData.position)
        pos = trans.parent:InverseTransformPoint(pos)
        local posY = self.mChatBtnRoot.anchoredPosition.y

        self:SetAnchorPos(self.mChatBtnRoot, Vector2.New(-289.5318, posY))
    end
end
function UIGdWin:UIDragOnDrag(dragKey, eventData)
    local canDrag = gModelChat:GetChatSetValue(7)
    if dragKey == "UIGdWinchatBtn" then
        if canDrag then
            self:SetDragItemPos(self.mChatBtnRoot, eventData)
        end
    end
end

function UIGdWin:UpdateRedPoint()
    for i, v in ipairs(self._BotBtnRedPoint) do
        local redPointId = self._BotBtnData[i].redPointId
        if redPointId then
            CS.ShowObject(v, gModelRedPoint:CheckShowRedPoint(redPointId))
        end
    end
    for _, v in ipairs(self._InfoBtnRedPoint) do
        local redPointId = v.redPointId
        if redPointId then
            CS.ShowObject(self:FindWndTrans(v.trans, "redPoint"), gModelRedPoint:CheckShowRedPoint(redPointId))
        end
    end
end

function UIGdWin:OnClickEmptyIsland()
    if self._isEnus and not (gLGameLanguage:IsJapanRegion()) then
         if gModelGuildHolyBattle:CheckIsOpen() then
                    GF.OpenWndBottom("UIGdHoFightPrepare")
         end
    else
        GF.OpenWnd("UIGdHoFightSelect")
    end
end

function UIGdWin:UpdateMsg()
    if not self._isShowAir then
        return
    end
    local list = gModelChat:GetAir2ChannelSingleMsg()
    local msgList = self._msgUiList
    if msgList then
        msgList:RefreshList(list)
        msgList:DrawAllItems()
    else
        msgList = self:GetUIScroll("mAirMsgSuper")
        msgList:Create(self.mAirMsgSuper, list, function(...)
            self:MsgListItem(...)
        end, UIItemList.SUPER)
        self._msgUiList = msgList
    end
    msgList:MoveToPos(1)

    self._chatStarCutTime = self._chatInitTime
    if self.mChatAirPop.localScale.x > 0 then
    else
        local isAir = gModelChat:GetChatSetValue(7)
        self:OnChatAirPopOptBtnClick()
    end
end

function UIGdWin:InitCommand()
    local memberList = gModelGuild:GetGuildMemberList()
    local guildLogList = gModelGuild:GetGuildLogList()
    if (#memberList <= 0) then
        local guildInfo = gModelGuild:GetGuildInfo()
        gModelGuild:OnGuildMemberListReq(guildInfo.guildId)
    else
        self:RefreshData()
    end
    if (#guildLogList <= 0) then
        gModelGuild:OnGuildLogListReq(1)
    else
        self:RefreshLog()
    end
    local info = gModelGuildMelee:GetGuildMeleeInfo()
    if not info then
        gModelGuildMelee:OnGuildMeleeStateReq()
    end
    gModelGuild:OnGuildLookNoticeReq()

    self:IsOpent()
    self:UpdateMsg()

    if gLGameLanguage:IsJapanVersion() then
        local typeRectTransform = typeof(UnityEngine.RectTransform)
        local rectTran = self.mExpBar:GetComponent(typeRectTransform)
        self:SetAnchorPos(rectTran,Vector2.New(100,505.6))
    end
end

function UIGdWin:InitEvent()
    self:SetWndClick(self.mBattleBtn, function()
        self:OnClickBattle()
    end)
    self:SetWndClick(self.mSkillBtn, function()
        self:OnClickSkill()
    end)
    self:SetWndClick(self.mDonateBtn, function()
        self:OnClickDonate()
    end)
    self:SetWndClick(self.mCopyBtn, function()
        self:OnClickCopy()
    end)
    self:SetWndClick(self.mReDesBtn, function()
        self:OnClickReDes()
    end)
    self:SetWndClick(self.mReDesImage, function()
        self:OnClickReDes()
    end)
    self:SetWndClick(self.mBtnHelp, function()
        self:OnClickHelp()
    end)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBargainBtn, function()
        self:OnClickBargain()
    end)
    self:SetWndClick(self.mEmptyIslandBtn, function()
        self:OnClickEmptyIsland()
    end)
    self:SetWndClick(self.mChatBtn, function()
        self:OnClickChatAirBg()
    end)
    self:SetWndClick(self.mChatAirBg, function()
        self:OnClickChatAirBg()
    end)
    self:SetWndClick(self.mRankBtn, function()
        self:OnClickRank()
    end)

    self:SetWndClick(self.mChatAirPopOptBtn, function()
        if not self._isPlayChatAni then
            self:OnChatAirPopOptBtnClick()
        end
    end)
end
function UIGdWin:SetChatAirPop()
    --配置  gModelChat:GetChatConfigRefByKey(key)  floatWindowWordsMax


    --气泡框
    local floatWindowLength = gModelChat:GetChatConfigRefByKey("floatWindowLength")
    floatWindowLength = checknumber(floatWindowLength)
    if floatWindowLength > 0 then
        LxUiHelper.SetSizeWithCurAnchor(self.mChatAirBg, 0, floatWindowLength)
    end
end

function UIGdWin:SetATPlayerName(msg, name)
    local str = msg
    local text = string.match(msg, "%@" .. name)
    if (text) then
        str = string.gsub(str, text, "<u>" .. text .. "</u>", 1)
    end
    return str
end

function UIGdWin:OnTimer(key)
    if key == "bargainRunTime" then
        self:UpdateBargainShow()
    end
    if key == "battleRunTime" then
        self:SetBattleTime()
    end

    if key == "guildHolyTime" then
        self:SetGuildHolyBattleTime()
    end

    if key == self._chatCutTimeKey then
        self._chatStarCutTime = self._chatStarCutTime - 1
        local isAir = gModelChat:GetChatSetValue(7)
        if self._chatStarCutTime <= 0 and isAir then
            if self.mChatAirPop.localScale.x > 0 then
                self:OnChatAirPopOptBtnClick()
            end
        end
    end
end

------------------------------------------------------------------
return UIGdWin