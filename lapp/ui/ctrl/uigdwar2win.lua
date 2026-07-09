---
--- Created by BY.
--- DateTime: 2023/10/5 20:43:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdWar2Win:LWnd
local UIGdWar2Win = LxWndClass("UIGdWar2Win", LWnd)

local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
------------------------------------------------------------------

local calcHpInfoFunc = function(heros)
    if not heros then return 0,0 end
    local maxHp,hp = 0,0
    for i, v in pairs(heros) do
        maxHp = maxHp + v.maxHp
        hp = hp + v.hp
    end
    return maxHp,hp
end

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdWar2Win:UIGdWar2Win()
    gModelGuildMelee:OnGuildMeleeStateReq()

    self._meleeTime = "meleeTime"        --倒计时
    self._uiheadList = {}
    self._tabList = {}
    self._reachTail = true    --是否锁定
    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdWar2Win:OnWndClose()
    self:ClearCommonIconList(self._uiheadList)
    self:IsShowBarrage(false)
    if self._uiIconEasyList then
        self._uiIconEasyList:Destroy()
        self._uiIconEasyList = nil
    end
    self:ClearDelayDrawTimer()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdWar2Win:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdWar2Win:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._reqIdxMap = {}

    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()

    gModelGuildMelee:OnGuildMeleeOpenEffectsReq()
    local inGuide = gModelGuide:IsInGuide()
    if inGuide then
        return
    end

    local call = gModelGuildMelee:GetEffectWndCall()
    if call then
        call()
    end
end

function UIGdWar2Win:OnDrawItemType4(item,itemdata,itempos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            rankText = self:FindWndTrans(item, "RankText"),
            rankIcon = self:FindWndTrans(item, "RankIcon"),
            timeText = self:FindWndTrans(item, "TimeText"),
            desText = self:FindWndTrans(item, "DesText"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end

    CS.ShowObject(itemCache.rankText, false)

    local rankIcon = itemCache.rankIcon
    self:SetWndEasyImage(rankIcon, "public_num_1")
    CS.ShowObject(rankIcon,true)

    local name1, seven1
    if itemdata.win == 1 then
        name1, seven1 = itemdata.guildNameA, gModelFriend:GetSevenName(itemdata.serverIdA)
    else
        name1, seven1 = itemdata.guildNameB, gModelFriend:GetSevenName(itemdata.serverIdB)
    end
    self:SetWndText(itemCache.desText, string.replace(ccClientText(17950), name1, seven1))

    local time = checknumber(itemdata.time) / 1000
    self:SetWndText(itemCache.timeText, LUtil.OSDate(ccClientText(17939), math.ceil(time)))

    CS.ShowObject(item, true)
end

function UIGdWar2Win:OnClickBarrage(isOne)
    self._isBarrageShow = not self._isBarrageShow
    self:IsShowBarrage(self._isBarrageShow)
    CS.ShowObject(self.mBarrageMask, not self._isBarrageShow)
    if (not isOne) then
        gModelChat:SetBarrageSav(ModelChat.CHANNEL_WAR, self._isBarrageShow)
    end
end

----设置形象
--function UIGdWar2Win:SetSpine(paintTans,ref,key)
--	if not ref then
--		return
--	end
--	if self:FindWndSpineByKey(key) then
--		return
--	end
--	local paintFlip = ref.paintFlip2 == 1
--	local paintMultiple = ref.paintMultiple2
--	self:CreateWndSpine(paintTans,ref.spine,key,false,function(dpSpine)
--		dpSpine:SetScale(paintMultiple)
--		dpSpine:SetFlipX(paintFlip)
--		local dpTrans = dpSpine:GetDisplayTrans()
--		dpTrans.anchorMin = Vector2.New(0.5,0.5)
--		dpTrans.anchorMax = Vector2.New(0.5,0.5)
--	end)
--end
--空列表
function UIGdWar2Win:CreateEmptyShow(trans, refId)
    local icon = CS.FindTrans(trans, "EmptyIcon")
    local bg = CS.FindTrans(trans, "EmptyTextBg")
    local text = CS.FindTrans(trans, "EmptyText")
    self:InitTextLineWithLanguage(text, -30)
    local data = {
        refId = refId,
        IconTran = icon,
        TextBgTran = bg,
        IntroTran = text,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UIGdWar2Win:TabListItem(list, item, itemdata, itempos)
    local btnTab1 = CS.FindTrans(item, "BtnTab1")
    self._tabList[itemdata.type] = btnTab1
    self:SetWndTabText(btnTab1, itemdata.name)
    self:SetWndTabStatus(btnTab1, 1)
    self:SetWndClick(btnTab1, function()
        self:OnClickTab(itemdata.type)
    end)
end

function UIGdWar2Win:OnClickLook(itemdata, itempos)
    --GF.OpenWnd("UIConoryPop",{StructGuildMeleeReportInfo = itemdata})

    GF.OpenWnd("UIWahjop", { combatData = itemdata, wndType = 2, wndPara = { page = 3, subPage = self._subPage, itempos = itempos } })
end


function UIGdWar2Win:OnDrawItemType2(item,itemdata,itempos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        local Image1 = self:FindWndTrans(item,"Image1")
        local lookBtn = self:FindWndTrans(item, "LookBtn")
        itemCache = {
            image1 = Image1,
            image2 = self:FindWndTrans(Image1, "Image2"),
            image3 = self:FindWndTrans(Image1, "Image3"),
            timeText = self:FindWndTrans(item, "TimeText"),
            playerA = self:FindWndTrans(item, "PlayerA"),
            playerB = self:FindWndTrans(item, "PlayerB"),
            lookBtn = lookBtn,
            lookText = self:FindWndTrans(lookBtn, "UIText")
        }
        self:SetComponentCache(instanceID, itemCache)
    end

    self:SetWndText(itemCache.timeText, LUtil.FormatTimeStr(itemdata.time, "%H:%M"))

    local combatHeroDataA = itemdata.combatHeroDataA
    local maxHpA, hpA = calcHpInfoFunc(combatHeroDataA._heros)

    local combatHeroDataB = itemdata.combatHeroDataB
    local maxHpB, hpB = calcHpInfoFunc(combatHeroDataB._heros)

    local playerIdA = itemdata.playerIdA
    local guildIdA = itemdata.guildIdA

    local playerIdB = itemdata.playerIdB
    local guildIdB = itemdata.guildIdB

    local guild = gModelPlayer:GetGuildId()
    local playerId = gModelPlayer:GetPlayerId()
    local isMyGuild = guildIdA == guild or guildIdB == guild
    local isMy = playerIdA == playerId or playerIdB == playerId

    local img1, img2, img3 = "guildwar_cell_1", "guildwar_star_1", "guildwar_bg_di_1"
    if isMy then
        img1, img2, img3 = "guildwar_cell_2", "guildwar_star_2", "guildwar_bg_di_2"
    elseif isMyGuild then
        img1, img2, img3 = "guildwar_cell_3", "guildwar_star_3", "guildwar_bg_di_3"
    end

    self:SetWndEasyImage(itemCache.image1, img1)
    self:SetWndEasyImage(itemCache.image2, img2)
    self:SetWndEasyImage(itemCache.image3, img3)

    local seq = itemdata.seq
    self:OnSetPlayerABInfo(itemCache.playerA, {
        winCount = itemdata.winCount,
        serverId = itemdata.serverIdA,
        playerId = playerIdA,
        name = itemdata.playerNameA,
        icon = itemdata.headA,
        headFrame = itemdata.headFrameA,
        level = itemdata.playerLevelA,
        win = itemdata.win == 1,
        guildId = guildIdA,
        guildName = itemdata.guildNameA,
        power = itemdata.powerA,
        maxHp = maxHpA,
        hp = hpA,
        guildMeleeBuffList = itemdata.guildMeleeBuffListA,
    }, seq)

    self:OnSetPlayerABInfo(itemCache.playerB, {
        winCount = itemdata.winCount,
        serverId = itemdata.serverIdB,
        playerId = playerIdB,
        name = itemdata.playerNameB,
        icon = itemdata.headB,
        headFrame = itemdata.headFrameB,
        level = itemdata.playerLevelB,
        win = itemdata.win == 2,
        guildId = guildIdB,
        guildName = itemdata.guildNameB,
        power = itemdata.powerB,
        maxHp = maxHpB,
        hp = hpB,
        guildMeleeBuffList = itemdata.guildMeleeBuffListB,
    }, seq)

    local lookText = itemCache.lookText
    self:SetWndText(lookText, ccClientText(17930))
    self:InitTextLineWithLanguage(lookText, -30)
    self:InitTextSizeWithLanguage(lookText, -2)

    self:SetWndClick(itemCache.lookBtn, function()
        self:OnClickLook(itemdata, itempos)
    end)

    CS.ShowObject(item, true)
end

-- function UIGdWar2Win:OnClickBarrageInput()
-- 	local para = {channel = ModelChat.CHANNEL_WAR,isShow = self._isBarrageShow}
-- 	gModelChat:OnClickOpentBarrageWin(para)
-- end

function UIGdWar2Win:OnClickRank()
    -- GF.OpenWndBottom("UIRkPop",{refId = ModelRank.RANK_MELEE})
    GF.OpenWndBottom("UIGdRk", { refId = ModelRank.RANK_MELEE })
    --GF.OpenWndBottom("UIGdWarRk")

end

--布阵
function UIGdWar2Win:OnClickFormation()
    local _meleeInfo = self._meleeInfo
    if _meleeInfo.state == ModelGuildMelee.STATE_PREPARE or _meleeInfo.state == ModelGuildMelee.STATE_Melee then
        GF.ShowMessage(ccClientText(17954))
        return
    end
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_GUILD_WAR)
end

function UIGdWar2Win:OnClickClose()
    if self._page == 1 then
        if not self:WndCloseAndBack() then
            GF.OpenWnd("UIGdWin")
        end
    else
        self._page = 1
        self:RefreshMar()
    end
end

function UIGdWar2Win:OnClickCondition()
    self._page = 2
    self._subPage = 1
    self:RefreshMar()
end

--帮助
function UIGdWar2Win:OnClickHelp()
    GF.OpenWnd("UIBzTips", { refId = 56 })
end

function UIGdWar2Win:GetLogList()
    local _subPage = self._subPage
    return gModelGuildMelee:GetReportListByType(_subPage, true)
end

function UIGdWar2Win:OnDrawItemType3(item,itemdata,itempos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            rankText = self:FindWndTrans(item, "RankText"),
            rankIcon = self:FindWndTrans(item, "RankIcon"),
            timeText = self:FindWndTrans(item, "TimeText"),
            desText = self:FindWndTrans(item, "DesText"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end

    local guildNameA = itemdata.guildNameA
    local serverIdA = itemdata.serverIdA
    local serverNameA = gModelFriend:GetSevenName(serverIdA)

    local guildNameB = itemdata.guildNameB
    local serverNameB = gModelFriend:GetSevenName(itemdata.serverIdB)

    local oust = itemdata.oust
    local time = checknumber(itemdata.time) / 1000
    local name1, seven1, name2, seven2
    if itemdata.win == 1 then
        name1, seven1, name2, seven2 = guildNameB, serverNameB, guildNameA, serverNameA
    else
        name1, seven1, name2, seven2 = guildNameA, serverNameA, guildNameB, serverNameB
    end
    local formatStr = ccClientText(17939)
    local showRankTxt = oust > 3
    local showRankIcon = oust <= 3
    local rankText = itemCache.rankText
    local rankIcon = itemCache.rankIcon
    if rankText then
        self:SetWndText(rankText, string.replace(ccClientText(17984), oust))
    elseif rankIcon then
        self:SetWndEasyImage(rankIcon, "public_num_" .. oust)
    end
    CS.ShowObject(rankText, showRankTxt)
    CS.ShowObject(rankIcon, showRankIcon)

    self:SetWndText(itemCache.timeText, LUtil.OSDate(formatStr, math.ceil(time)))

    local desText = itemCache.desText
    self:SetWndText(desText, string.replace(ccClientText(17923), name1, seven1, name2, seven2, oust))
    local addLine = self._isEnus and 20 or -20
    self:InitTextLineWithLanguage(desText, addLine)
    CS.ShowObject(item, true)
end

function UIGdWar2Win:RefreshApplyBtnState()
    local _meleeInfo = self._meleeInfo
    if not _meleeInfo then
        return
    end
    local isApply = _meleeInfo.state >= ModelGuildMelee.STATE_APPLY and _meleeInfo.signUpPlayerState == 1
    CS.ShowObject(self.mApplyBtn1, not isApply)
    CS.ShowObject(self.mApplyBtn2, isApply)
    self:SetWndButtonGray(self.mApplyBtn1, _meleeInfo.state ~= 3)
    self:SetWndButtonGray(self.mApplyBtn2, _meleeInfo.state ~= 3)
    self:SetWndButtonGray(self.mFormationBtn, self._meleeInfo.state == 4 or self._meleeInfo.state == 5)
end

function UIGdWar2Win:InitCommand()
    self._page = self:GetWndArg("page") or 1
    self._subPage = self:GetWndArg("subPage") or 1
    self._itempos = self:GetWndArg("itempos")

    self:SetWndText(self.mTitleText, ccClientText(17900))
    self:SetWndText(self.mAwardText, ccClientText(17902))
    self:SetWndText(self.mRankBtnText, ccClientText(17951))
    self:SetWndText(self.mAwardBtnText, ccClientText(17952))
    self:SetWndText(self.mShopBtnText, ccClientText(17953))
    -- self:SetWndText(self.mBarrageText,ccClientText(10145))
    self:SetWndText(self.mLblBiaoti, ccClientText(17977))
    self:SetWndText(self.mLblBiaoti_enus, ccClientText(17977))

    self:SetWndButtonText(self.mBtnCondition, ccClientText(17975))
    --self:SetWndButtonText(self.mBtnReport,ccClientText(17976))
    self:SetWndText(self.mBtnReportText, ccClientText(17976))
    self:SetWndButtonText(self.mApplyBtn1, ccClientText(17904))
    self:SetWndButtonText(self.mApplyBtn2, ccClientText(17945))
    self:SetWndButtonText(self.mFormationBtn, ccClientText(17903))
    self:SetWndText(self.mGroupingBtnText, ccClientText(17982))
    self:SetWndText(self:FindWndTrans(self.mCloseBtn, "Text"), ccClientText(41102))
    self:SetWndText(self.mLogTitle, ccClientText(17993))
    self:SetWndText(self.mAppleTitle, ccClientText(17924))
    --弹幕
    self._isBarrageShow = gModelChat:GetBarrageIsShow(ModelChat.CHANNEL_WAR)
    self._isBarrageShow = not self._isBarrageShow
    self:OnClickBarrage(true)

    self._rankList = {
        self.mRank1,
        self.mRank2,
        self.mRank3,
    }
    gModelGuildMelee:OnGuildMeleeEndTopInfoHistoryReq()
    self:RefreshInfo()
    self:RefreshMar()

    if gLGameLanguage:IsForeignRegion() then
        local group = self.mBottom:GetComponent(typeHorizontalLayoutGroup)
        if group then
            group.spacing = 50
        end
    end

    CS.ShowObject(self.mTitleBg, not self._isEnus)
    CS.ShowObject(self.mTitleBg_enus, self._isEnus)

    CS.ShowObject(self.mGroupingBtn, #gModelGuildMelee:GetServers() > 1)
end

function UIGdWar2Win:SetRankInfo(item, itemdata)
    --local playIcon = CS.FindTrans(item,"Mask/PlayIcon")
    local flagBg = CS.FindTrans(item, "FlagBg")
    local flagIcon = CS.FindTrans(item, "FlagBg/FlagIcon")
    local lvText = CS.FindTrans(item, "FlagBg/LvBg/LvText")
    local serveText = CS.FindTrans(item, "ServeText")
    local nameText = CS.FindTrans(item, "NameText")
    local guildText = CS.FindTrans(item, "GuildText")
    local powerBg = CS.FindTrans(item, "Bg")
    local powerText = CS.FindTrans(item, "Bg/PowerText")

    local _server, _name, _guildName, _power = "", ccClientText(11736), "", ""
    --CS.ShowObject(playIcon,itemdata)
    CS.ShowObject(flagBg, false)
    CS.ShowObject(powerBg, itemdata)
    if itemdata then
        local serverName = gModelFriend:GetSevenName(itemdata.serverId)
        local ref = gModelRank:GetRankingRefData(ModelRank.RANK_MELEE)
        local desStr = string.replace(ccLngText(ref.descriptionDetail), itemdata.signUpCount)
        _server = serverName
        _name = itemdata.guildName
        _guildName = desStr
        _power = LUtil.NumberCoversion(itemdata.powerCount)
        --local raleRef = gModelPlayer:GetRoleAdventureImage(itemdata.chairmanFigure)
        --local key = itemdata.chairmanId
        --self:SetSpine(playIcon,raleRef,key)
        self:SetWndClick(item, function()
            self:OnClickOpentGuild(itemdata.guildId, itemdata.serverId)
        end)

        local bgRef = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagBgId)
        local iconRef = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagId)
        if bgRef then
            self:SetWndEasyImage(flagBg, bgRef.res)
            CS.ShowObject(flagBg, true)
        end
        if iconRef then
            self:SetWndEasyImage(flagIcon, iconRef.res)
        end
        self:SetWndText(lvText, string.replace(ccClientText(17992), itemdata.level))
    end
    self:SetWndText(serveText, _server)
    self:SetWndText(nameText, _name)
    self:SetWndText(guildText, _guildName)
    self:SetWndText(powerText, _power)
    if self.jpj then
        LxUiHelper.SetSizeWithCurAnchor(nameText, 0, 140)
        local textTran = LxUiHelper.FindXTextCtrl(nameText)
        textTran.enableWordWrapping = true
    end
end
----------------------------------------------倒计时--------------------------------------
function UIGdWar2Win:OnTimer(key)
    if (self._meleeTime == key) then
        self:SetTime()
    end
end

function UIGdWar2Win:InitMessage()
    self:WndEventRecv(EventNames.ON_CHAT_BARRAGE_WIN, function()
        self:OnClickBarrage()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeStateResp, function(pb)
        self:RefreshInfo()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeEndTopInfoHistoryResp, function(...)
        self:RefreshRank()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeSignUpInfoListResp, function(...)
        self:RefreshApply()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeMemberSignUpInfoListResp, function(...)
        self:RefreshApply()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeSignUpCancelResp, function(...)
        self:RefreshApply()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeMemberSignUpCancelResp, function(...)
        self:RefreshApply()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeSignUpResp, function(...)
        self:RefreshApplyBtnState()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeEndTopInfoResp, function(...)
        gModelGuildMelee:OnGuildMeleeEndTopInfoHistoryReq()
    end)
    self:WndEventRecv(EventNames.ON_GUILD_MELEE_REPORT, function()
        self:RefreshLog()
        if GF.FindFirstWndByName("UIConoryPop") then
            return
        end
        local _continuousWin = gModelGuildMelee:GetContinuousWin()
        if not _continuousWin then
            return
        end
        GF.OpenWnd("UIConoryPop", { StructGuildMeleeReportInfo = _continuousWin })
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeOpenEffectsResp, function(pb)
        local openEffects = pb.openEffects
        if openEffects == 1 then
            local inGuide = gModelGuide:IsInGuide()
            if inGuide then
                local func = nil
                func = function()
                    GF.OpenWnd("UIGdMeleeEffPop")
                end
                gModelGuildMelee:DelayEffectWnd(func)
            else
                GF.OpenWnd("UIGdMeleeEffPop")
            end

        end
    end)
end
--报名
function UIGdWar2Win:OnClickApply()
    local bool = gModelGuildMelee:GetIsBoolApply()
    if not bool then
        return
    end
    if self._meleeInfo.signUpPlayerState == 1 then
        GF.OpenWnd("UIOrdinTip", { refId = 100102, func = function(...)
            local bool = gModelGuildMelee:GetIsBoolApply()
            if not bool then
                return
            end
            gModelGuildMelee:OnGuildMeleeSignUpReq()
        end })
    else
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_GUILD_WAR, { guildMeleeState = true })
    end
end

function UIGdWar2Win:RefreshApply()
    if self._page ~= 2 then
        return
    end
    local _subPage = self._subPage
    local list = {}
    if _subPage == 1 then
        list = gModelGuildMelee:GetSignUpListByType(ModelGuildMelee.SIGNUP_GUILD, true)
        table.sort(list, function(a, b)
            if a.powerCount ~= b.powerCount then
                return a.powerCount > b.powerCount
            end
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.seq < b.seq
        end)
    else
        list = gModelGuildMelee:GetSignUpListByType(ModelGuildMelee.SIGNUP_MEMBER, true)
        table.sort(list, function(a, b)
            if a.power ~= b.power then
                return a.power > b.power
            end
            return a.seq < b.seq
        end)
    end

    local _uiApplyList = self._uiApplyList
    if (_uiApplyList) then
        _uiApplyList:RefreshList(list)
        _uiApplyList:DrawAllItems()
    else
        _uiApplyList = self:GetUIScroll("applyCell")
        _uiApplyList:Create(self.mApplyScroll, list, function(...)
            self:ApplyListItem(...)
        end, UIItemList.SUPER)
        _uiApplyList:EnableScroll(true, false)
        self._uiApplyList = _uiApplyList
    end
    local _uiList = _uiApplyList:GetList()
    _uiList:SetFuncOnItemReachTail(function(bool)
        if bool then
            if _subPage == 1 then
                local signUplist = gModelGuildMelee:GetSignUpListByType(ModelGuildMelee.SIGNUP_GUILD, true)
                local len = #signUplist
                if not self._oldLen or self._oldLen ~= len then
                    gModelGuildMelee:OnGuildMeleeSignUpInfoListTestReq()
                end
                self._oldLen = len
            end
        end
    end)

    local nameStr, lvStr, numStr, powerStr, tipsStr, noRecordId
    if (_subPage == 1) then
        -- nameStr,lvStr,numStr,powerStr,tipsStr =
        -- ccClientText(17914),ccClientText(17993),ccClientText(17916),ccClientText(17917),ccClientText(17970)
        nameStr, lvStr, numStr, powerStr, tipsStr = ccClientText(17914), ccClientText(17915), ccClientText(17916), ccClientText(17917), ccClientText(17970)
        noRecordId = 4102
        tipsStr = string.replace(tipsStr, gModelGuild:GetGuildConfigRefByKey("battleStartCondition"))
    else
        -- nameStr,lvStr,numStr,powerStr,tipsStr =
        -- ccClientText(17911),ccClientText(17910),ccClientText(17994),ccClientText(17913),ccClientText(17978)
        nameStr, lvStr, numStr, powerStr, tipsStr = ccClientText(17910), ccClientText(17911), ccClientText(17912), ccClientText(17913), ccClientText(17978)
        noRecordId = 4103
        local num = #list
        local powers = 0
        for i, v in ipairs(list) do
            powers = powers + v.power
        end
        local lv = gModelGuild:GetGuildLevel()
        local lvRef = gModelGuild:GetGuildLevelRefByRefId(lv)
        powers = LUtil.PowerNumberCoversion(powers)
        tipsStr = string.replace(tipsStr, num, lvRef.number, powers)
    end
    self:SetWndText(self.mText1, nameStr)
    self:SetWndText(self.mText2, lvStr)
    self:SetWndText(self.mText3, numStr)
    self:SetWndText(self.mText4, powerStr)
    self:SetWndText(self.mTipsText, tipsStr)
    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(self.mTipsText, -4)
        self:InitTextLineWithLanguage(self.mTipsText, -10)

    elseif gLGameLanguage:IsVieVersion() then
        self:InitTextLineWithLanguage(self.mTipsText, 30)
        self:SetAnchorPos(self.mTipsText, Vector2.New(130, 10))
    end

    local isShowNoRecord = #list <= 0
    CS.ShowObject(self.mApplyNoRecord, isShowNoRecord)
    if isShowNoRecord then
        self:CreateEmptyShow(self.mApplyNoRecord, noRecordId)
    end
    self:RefreshApplyBtnState()
end

function UIGdWar2Win:RefreshRank()
    local ranks = gModelGuildMelee:GetInfoHistorys()
    for i, v in ipairs(self._rankList) do
        self:SetRankInfo(v, ranks[i])
    end
    local info = self._meleeInfo
    if not info then
        return
    end
    local items = gModelGuild:GetGuildConfigRefByKey("battleShowReward")
    local itemList = LxDataHelper.ParseItem(items)
    --for i, v in ipairs(itemList) do
    --	v.itemNum = -1
    --end
    local uiIconEasyList = self._uiIconEasyList
    if not uiIconEasyList then
        uiIconEasyList = UIIconEasyList:New()
        self._uiIconEasyList = uiIconEasyList
    end
    uiIconEasyList:Create(self, self.mAwardScroll)
    uiIconEasyList:SetShowNum(false)
    uiIconEasyList:EnableScroll(true, true)
    uiIconEasyList:RefreshList(itemList)

    local openDay = gLGameLogin:GetServerOpenDay()
    local firDay = gModelGuild:GetGuildConfigRefByKey("battleStartFirDay")
    local dayStr = ccClientText(17972)
    if openDay <= firDay then
        dayStr = ccClientText(17974)
    end
    self:SetWndText(self.mOpentText, dayStr)
end

function UIGdWar2Win:InitEvent()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mCloseBtn, function(...)
        self:OnClickClose()
    end)
    self:SetWndClick(self.mHelpBtn, function(...)
        self:OnClickHelp()
    end)
    -- self:SetWndClick(self.mBarrageBtn,function () self:OnClickBarrageInput() end)
    self:SetWndClick(self.mBtnCondition, function()
        self:OnClickCondition()
    end)
    self:SetWndClick(self.mBtnReport, function()
        self:OnClickReport()
    end)
    self:SetWndClick(self.mRankBtn, function()
        self:OnClickRank()
    end)
    self:SetWndClick(self.mAwardBtn, function()
        self:OnClickRankAward()
    end)
    self:SetWndClick(self.mShopBtn, function()
        self:OnClickShop()
    end)
    self:SetWndClick(self.mFormationBtn, function()
        self:OnClickFormation()
    end)
    self:SetWndClick(self.mApplyBtn1, function()
        self:OnClickApply()
    end)
    self:SetWndClick(self.mApplyBtn2, function()
        self:OnClickApply()
    end)
    self:SetWndClick(self.mGroupingBtn, function()
        self:OnClickGrouping()
    end)
end

function UIGdWar2Win:RefreshTabList(list)
    local _uiTabList = self._uiTabList
    if (_uiTabList) then
        _uiTabList:RefreshList(list)
    else
        _uiTabList = self:GetUIScroll("tabCell")
        _uiTabList:Create(self.mTabScroll, list, function(...)
            self:TabListItem(...)
        end)
        self._uiTabList = _uiTabList
    end
    local tabI = self._subPage or 1
    self:OnClickTab(tabI)
end

function UIGdWar2Win:ClearDelayDrawTimer()
    if self._delayDrawTimer then
        LxTimer.DelayTimeStop(self._delayDrawTimer)
        self._delayDrawTimer = nil
    end
end

function UIGdWar2Win:OnClickOpentGuild(_guildId, _serverId)
    gModelGuild:OnGuildMemberListReq(_guildId, _serverId)
end

function UIGdWar2Win:OnClickTab(type)
    if self._subPage then
        self:SetWndTabStatus(self._tabList[self._subPage], 1)
    end
    self._subPage = type
    self:SetWndTabStatus(self._tabList[self._subPage], 0)
    if self._page == 2 then
        self:RefreshApply()
    elseif self._page == 3 then
        if self._oneLog then
            gModelGuildMelee:OnClickReportReq()
            self._oneLog = true
        end
        self:RefreshLog()
    end
end

function UIGdWar2Win:OnClickPlayer(playerId)
    if not playerId then return end
    gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
end

function UIGdWar2Win:OnSetPlayerABInfo(trans, info, seq)
    local instanceID = trans:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        local Buff = self:FindWndTrans(trans,"Buff")
        itemCache = {
            resultIcon = self:FindWndTrans(trans, "ResultIcon"),
            resultText = self:FindWndTrans(trans, "ResultText"),
            guildText = self:FindWndTrans(trans, "GuildText"),
            nameText = self:FindWndTrans(trans, "NameText"),
            serverText = self:FindWndTrans(trans, "ServerText"),
            headIcon = self:FindWndTrans(trans, "HeadIcon"),
            powerText = self:FindWndTrans(trans, "PowerBg/PowerText"),
            barTrans = self:FindWndTrans(trans, "Bar_1"),
            buff = Buff,
            buffText = self:FindWndTrans(Buff, "BuffText"),
            buffLvText = self:FindWndTrans(Buff, "BuffLvText"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end


    local bar_1 = self:FindWndSlider(itemCache.barTrans)
    bar_1.maxValue = info.maxHp
    bar_1.value = info.hp

    local guildBuff = info.guildMeleeBuffList[1]

    local buff = itemCache.buff
    CS.ShowObject(buff, guildBuff ~= nil)

    if guildBuff then
        local ref = gModelGuildMelee:GetGuildBattleBuffRefByRefId(guildBuff)
        self:SetWndText(itemCache.buffText, ccLngText(ref.name))
        self:SetWndText(itemCache.buffLvText, ref.lv)

        self:SetWndClick(buff, function()
            --GF.OpenWnd("UINewJNTip",{curSkillId = ref.addAttrSkill,wndType = 2})
            gModelGeneral:OpenSkillWnd({ curSkillId = ref.addAttrSkill, wndType = 2 })
        end)
    end

    self:SetWndText(itemCache.guildText, info.guildName)
    self:SetWndText(itemCache.nameText, info.name)
    self:SetWndText(itemCache.serverText, gModelFriend:GetSevenName(info.serverId))
    self:SetWndText(itemCache.powerText, LUtil.NumberCoversion(info.power))

    local showResultTxt = false

    local win = info.win
    local showResultIcon = win
    local resultText = itemCache.resultText
    if win and info.winCount > 1 then
        showResultTxt = true
        showResultIcon = false
        local winCount = LUtil.FormatHurtNumSpriteText(info.winCount)
        self:SetWndText(resultText, winCount)
        self:InitTextSizeWithLanguage(resultText, 20)
    end
    CS.ShowObject(resultText, showResultTxt)
    CS.ShowObject(itemCache.resultIcon, showResultIcon)


    local headIcon = itemCache.headIcon
    local InstanceID = trans:GetInstanceID()
    local uiheadlist = self._uiheadList
    local baseClass = uiheadlist[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        uiheadlist[InstanceID] = baseClass
    end
    info.trans = headIcon
    baseClass:SetHeadData(info)
    self:SetWndClick(headIcon, function(...) self:OnClickPlayer(info.playerId) end)
end

function UIGdWar2Win:RefreshLog()
    if self._page ~= 3 then return end

    local list = self:GetLogList()
    self._logList = list

    if #list < 1 then return end

    ---@type UIItemList
    local uiLogList = self._uiLogList
    if uiLogList then
        uiLogList:RefreshList(list)
    else
        uiLogList = self:GetUIScroll("LogCell")
        self._uiLogList = uiLogList
        uiLogList:Create(self.mLogSuper, list, function(...) self:LogListItem(...) end, UIItemList.SUPER)

        local uiList = uiLogList:GetList()
        uiList:SetFuncOnItemReachHead(function(bool)
            if not bool then return end
            self:ReqLogMsg(self._logList[1])
        end)

        uiList:SetFuncOnItemReachTail(function(bool)
            self._reachTail = bool    --是否锁定
        end)
    end

    local seq = self._seq
    local _oldSeq = self._oldSeq
    if seq and (not _oldSeq or _oldSeq ~= seq) then
        for i, v in ipairs(list) do
            if v.seq == seq then
                self._itempos = i
                print(i)
                self._oldSeq = seq
                break
            end
        end
    end

    local _itempos = self._itempos or #list
    if self._reachTail or self._itempos then
        if self._itempos then
            _itempos = _itempos + 2
        end
        uiLogList:MoveToPos(_itempos)
    else
        local uiList = uiLogList:GetList()
        uiList:DrawAllItems()
    end
    self._itempos = nil

    local isShowNoRecord = #list <= 0
    CS.ShowObject(self.mLogNoRecord, isShowNoRecord)
    if isShowNoRecord then
        self:CreateEmptyShow(self.mLogNoRecord, 4104)
    end
end

function UIGdWar2Win:OnClickRankAward()
    local rewardList = gModelGuildMelee:GetGuildBattleRewardRefByType(1)
    local rewardList2 = gModelGuildMelee:GetGuildBattleRewardRefByType(2)

    -- GF.OpenWndBottom("UIRkPop",{refId = ModelRank.RANK_MELEE,rewardList = rewardList,rewardList2 = rewardList2})
    GF.OpenWndBottom("UIGdRk", { refId = ModelRank.RANK_MELEE, rewardList = rewardList, rewardList2 = rewardList2 })
    --GF.OpenWndBottom("UIGdWarAward")
end
--[[
function UIGdWar2Win:RefreshLog()
    if self._page ~= 3 then return end

    local list = self:GetLogList()
    local logLen = #list
    self._logList = list
    self._logLen = logLen

    if logLen > 0 then
        ---@type UIItemList
        local uiLogList = self._uiLogList
        if uiLogList then
            uiLogList:RefreshList(list)

            local uiList = uiLogList:GetList()
            uiList:DrawAllItems()
        else
            uiLogList = self:GetUIScroll("uiLogList")
            self._uiLogList = uiLogList
            uiLogList:Create(self.mLogSuper, list, function(...) self:LogListItem(...) end, UIItemList.SUPER)
        end

        local seq = self._seq
        local _oldSeq = self._oldSeq
        if seq and (not _oldSeq or _oldSeq ~= seq) then
            for i, v in ipairs(list) do
                if v.seq == seq then
                    self._itempos = i
                    self._oldSeq = seq
                    break
                end
            end
        end

        local _itempos = self._itempos or logLen
        if self._reachTail or self._itempos then
            uiLogList:MoveToPos(_itempos)
        end
        self._itempos = nil
    end

    local isShowNoRecord = logLen <= 0
    CS.ShowObject(self.mLogNoRecord, isShowNoRecord)
    if isShowNoRecord then
        self:CreateEmptyShow(self.mLogNoRecord, 4104)
    end
end]]

function UIGdWar2Win:CheckIsReqLog(itempos)
    LogError(itempos)
    if itempos < self._logLen then return end
    if self._reqIdxMap[itempos] then return end

    LogError("请求数据：" .. itempos)
    self._reqIdxMap[itempos] = true
    self:ReqLogMsg(self._logList[1])
end

function UIGdWar2Win:SetTime()
    local info = self._meleeInfo
    if not info then
        return
    end
    local state = info.state
    local startTime = tonumber(info.startTime) / 1000
    local sevenTime = GetTimestamp()
    local timespan = math.ceil(startTime - sevenTime)
    if timespan < 0 then
        self:TimerStop(self._meleeTime)
        return
    end
    local desStr, timeStr
    if state == 1 or state == 2 then
        desStr = ccClientText(17901)
        timeStr = string.replace(ccClientText(17965), LUtil.FormatTimeStr1(timespan))
    elseif state == 3 then
        local signUpGuildCount = info.signUpGuildCount
        desStr = string.replace(ccClientText(17937), LUtil.FormatTimeStr1(timespan))
        timeStr = string.replace(ccClientText(17907), signUpGuildCount)
    elseif state == 4 then
        local signUpGuildCount = info.signUpGuildCount
        desStr = string.replace(ccClientText(17906), LUtil.FormatTimeStr1(timespan))
        timeStr = string.replace(ccClientText(17907), signUpGuildCount)
    end
    self:SetWndText(self.mTimeDesText, desStr)
    self:SetWndText(self.mTimeText, timeStr)
end

function UIGdWar2Win:OnClickApplyGuildCell(guildId, sevenId)
    gModelGuild:OnGuildMemberListReq(guildId, sevenId)
end

function UIGdWar2Win:RefreshInfo()
    self._meleeInfo = gModelGuildMelee:GetGuildMeleeInfo()
    local info = self._meleeInfo
    self:TimerStop(self._meleeTime)
    if not info then
        return
    end
    local state = info.state
    if state == 5 then
        local remainGuildCount = info.remainGuildCount
        local desStr = ccClientText(17935)
        local timeStr = string.replace(ccClientText(17936), remainGuildCount)
        self:SetWndText(self.mTimeDesText, desStr)
        self:SetWndText(self.mTimeText, timeStr)
    else
        self:TimerStart(self._meleeTime, 1, false, -1)
        self:SetTime()
    end
    self:RefreshApplyBtnState()
end

function UIGdWar2Win:RefreshMar()
    CS.ShowObject(self.mRankMar, false)
    CS.ShowObject(self.mApplyMar, false)
    CS.ShowObject(self.mLogMar, false)
    CS.ShowObject(self.mTabScroll, true)
    if self._page == 1 then
        CS.ShowObject(self.mRankMar, true)
        CS.ShowObject(self.mTabScroll, false)
        self:RefreshRank()
    elseif self._page == 2 then
        CS.ShowObject(self.mApplyMar, true)
        local list = {
            { name = ccClientText(17908), type = 1 },
            { name = ccClientText(17909), type = 2 }
        }
        self:RefreshTabList(list)
    else
        CS.ShowObject(self.mLogMar, true)
        local list = {
            { name = ccClientText(17919), type = 1 },
            { name = ccClientText(17920), type = 2 },
            { name = ccClientText(17921), type = 3 }
        }
        self:RefreshTabList(list)
    end
end

function UIGdWar2Win:OnDrawItemType1(item,itemdata,itempos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            tipsText = self:FindWndTrans(item, "TipsText"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end
    self:SetWndText(itemCache.tipsText, string.replace(ccClientText(17922), itemdata.round))
    CS.ShowObject(item, true)
end

function UIGdWar2Win:OnClickGrouping()
    local list = gModelGuildMelee:GetServers()
    if #list <= 0 then
        GF.ShowMessage(ccClientText(17983))
        return
    end
    GF.OpenWnd("UIKfSyerGroupingPop")
end

function UIGdWar2Win:LogListItem(list, item, itemdata, itempos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            root1 = self:FindWndTrans(item, "Root1"),
            root2 = self:FindWndTrans(item, "Root2"),
            root3 = self:FindWndTrans(item, "Root3"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end
    local root1 = itemCache.root1
    local root2 = itemCache.root2
    local root3 = itemCache.root3
    CS.ShowObject(root1, false)
    CS.ShowObject(root2, false)
    CS.ShowObject(root3, false)

    local type = itemdata.type
    local height = 50
    if type == 1 then
        height = 50
        self:OnDrawItemType1(root1,itemdata,itempos)
    elseif type == 2 then
        height = 159
        self:OnDrawItemType2(root2,itemdata,itempos)
    elseif type == 3 then
        height = 110
        self:OnDrawItemType3(root3,itemdata,itempos)
    elseif type == 4 then
        height = 116
        self:OnDrawItemType4(root3,itemdata,itempos)
    end

    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UIGdWar2Win:OnClickShop()
    local functionId = gModelGuild:GetGuildConfigRefByKey("battleShopJump")
    gModelFunctionOpen:Jump(functionId, self:GetWndName())
end

function UIGdWar2Win:OnClickReport()
    self._page = 3
    self._subPage = 1
    self:RefreshMar()
end

function UIGdWar2Win:ApplyListItem(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "Root")
    -- local headIcon = CS.FindTrans(item,"Root/HeadIcon")
    local flagBg = CS.FindTrans(item, "Root/FlagBg")
    -- local flagIcon = CS.FindTrans(item,"Root/FlagBg/FlagIcon")
    local text1 = CS.FindTrans(item, "Root/Text1")
    local text2 = CS.FindTrans(item, "Root/Text2")
    local text3 = CS.FindTrans(item, "Root/Text3")
    local powerText = CS.FindTrans(item, "Root/PowerText")

    CS.ShowObject(flagBg, false)
    local type = itemdata.type
    local name, lv, num, power
    --local color = "<color=#139057>%s</color>"
    if (type == ModelGuildMelee.SIGNUP_GUILD) then
        local severName = gModelFriend:GetSevenName(itemdata.serverId)
        -- name,lv,num,power = itemdata.guildName.."\n"..string.replace(ccClientText(17992),itemdata.level),severName,itemdata.signUpCount,itemdata.powerCount
        --num = string.replace(color,num)

        name = itemdata.guildName .. string.replace("[#a1#]", severName)
        lv = itemdata.level
        num = itemdata.signUpCount
        power = itemdata.powerCount
    elseif (type == ModelGuildMelee.SIGNUP_MEMBER) then
        local timeData = {
            _playerState = itemdata.playerState,
            _lastLogoutTime = itemdata.lastLogoutTime * 1000
        }
        local time = gModelFriend:GetLastLogoutTime(timeData)
        -- name = itemdata.name
        -- lv,num,power = itemdata.time,time,itemdata.power
        -- local formatStr = ccClientText(17938)
        -- lv = LUtil.OSDate(formatStr,tonumber(lv)/1000)
        --lv = string.replace(color,lv)
        name = "       " .. LUtil.OSDate(ccClientText(17938), tonumber(itemdata.time) / 1000)
        lv = "<#139057>" .. itemdata.name .. "</color>"
        num = "<#734f22>" .. itemdata.level .. "</color>"
        power = itemdata.power
    end
    self:SetWndText(text1, name)
    self:SetWndText(text2, lv)
    self:SetWndText(text3, num)
    self:SetWndText(powerText, LUtil.PowerNumberCoversion(power))
    self:SetWndClick(root, function()
        if (type == ModelGuildMelee.SIGNUP_GUILD) then
            self:OnClickApplyGuildCell(itemdata.guildId, itemdata.serverId)
        elseif (type == ModelGuildMelee.SIGNUP_MEMBER) then
            self:OnClickPlayer(itemdata.playerId)
        end
    end)

    -- CS.ShowObject(headIcon,type == ModelGuildMelee.SIGNUP_MEMBER)
    -- if(type == ModelGuildMelee.SIGNUP_GUILD)then
    -- 	local bgRef = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagBgId)
    -- 	local iconRef = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagId)
    -- 	if bgRef then
    -- 		self:SetWndEasyImage(flagBg,bgRef.res)
    -- 		CS.ShowObject(flagBg,true)
    -- 	end
    -- 	if iconRef then
    -- 		self:SetWndEasyImage(flagIcon,iconRef.res)
    -- 	end
    -- elseif(type == ModelGuildMelee.SIGNUP_MEMBER)then
    -- 	local playerData = {
    -- 		trans = headIcon,
    -- 		icon = itemdata.head,
    -- 		headFrame = itemdata.headFrame,
    -- 		level = itemdata.level
    -- 	}
    -- 	local uiheadlist = self._uiheadList
    -- 	local InstanceID = item:GetInstanceID()
    -- 	local baseClass = uiheadlist[InstanceID]
    -- 	if not baseClass then
    -- 		baseClass = HeadIcon:New(self)
    -- 		uiheadlist[InstanceID] = baseClass
    -- 	end
    -- 	baseClass:SetHeadData(playerData)
    -- 	baseClass:RefreshUI()
    -- end
end

function UIGdWar2Win:IsShowBarrage(bool)
    if (bool) then
        local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
        if not sensitive then
            return
        end
        gModelGeneral:OpenBarrage({ channel = ModelChat.CHANNEL_WAR })
    else
        GF.CloseWndByName("UIBulletSay")
    end
end

function UIGdWar2Win:ReqLogMsg(itemdata)
    if not itemdata then return end

    local seq = itemdata.seq
    if not seq or seq <= 1 then return end

    if self._seq and self._seq == seq then return end

    self._seq = seq
    gModelGuildMelee:OnGuildMeleeReportInfoListReq(seq, 1)
end
------------------------------------------------------------------
return UIGdWar2Win