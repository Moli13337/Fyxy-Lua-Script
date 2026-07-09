---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFightDetails:LWnd
local UIFightDetails = LxWndClass("UIFightDetails", LWnd)

UIFightDetails.SHOWTYPE_NORNAL = 0   --单个战报
UIFightDetails.SHOWTYPE_SHOWLIST = 1 --多个战报
UIFightDetails.SHOWTYPE_DETAIL = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFightDetails:UIFightDetails()
    ---@type table<number,CommonIcon>
    self._uiIconClsList = {}
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFightDetails:OnWndClose()
    self:ClearCommonIconList(self._uiIconClsList)
    gModelWndPop:CheckPopWnd()
    if self._extraData then
        local isVideoAlive = gModelBattle:IsVideoAlive()

        local isFromBack = self:GetWndArg("isFromBack")
        local closeFunc = self._extraData.closeFunc
        if closeFunc and not isVideoAlive and not isFromBack then
            closeFunc(self._combatType, self._extraData)
        end
    end
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFightDetails:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFightDetails:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEmptyList()
    self:InitText()
    self:InitEvent()
    -- 血条动画时间
    self._speed = 0.5
    self._me = {}
    self._other = {}
    self._teamProgress = {}
    self._isForeign = gLGameLanguage:IsForeignVersion()
    self:OnWndRefresh()
end

function UIFightDetails:SetHeroList(root, index)
    local isLeft = index == 1
    local temaData
    if isLeft then
        temaData = self._battleDetailData.formationA
    else
        temaData = self._battleDetailData.formationB
    end
    local playerData = isLeft and self._battleDetailData.formationAOtherData or
            self._battleDetailData.formationBOtherData
    local playerExtraData = isLeft and self._me or self._other
    local mvpRefId = playerData.mvpHeroRefId

    for i = 0, LCombatFormationConst.FIGURE_MAX - 1 do
        local heroBattleData = self:FindWndTrans(root, "HeroBattleData" .. i)
        local heroData = temaData[i + 1]
        if heroData then
            local isHaveData = heroData.refId ~= nil
            if isHaveData then
                local isMvp = tonumber(mvpRefId) == tonumber(heroData.refId) and true or false
                local heroPos = CS.FindTrans(heroBattleData, "HeroPos")
                local heroTrans = CS.FindTrans(heroPos, "HeroIcon")
                local mvp = CS.FindTrans(heroPos, "Mvp")

                local instanceId = heroTrans:GetInstanceID()
                local baseClass = self._uiIconClsList[instanceId]
                if not baseClass then
                    baseClass = CommonIcon:New()
                    self._uiIconClsList[instanceId] = baseClass
                    baseClass:Create(heroTrans)
                end
                local data = {
                    playerId = playerData.playerId,
                    id = heroData.id,
                    refId = heroData.refId,
                    star = heroData.star,
                    level = heroData.level,
                    trans = heroTrans,
                    isMon = heroData.isMon,
                    fightPower = heroData.fightPower,
                    grade = heroData.grade,
                    isResonance = heroData.resonance,
                    skin = heroData.skinId,
                    treeInfo = heroData.treeInfo,
                    form = heroData.form,
                }

                local quality = heroData.quality
                if quality and quality > 0 then
                    data.quality = quality
                end

                baseClass:SetHeroDataSet(data)
                baseClass:DoApply()

                local progressList = self:GetProgressList(heroBattleData, index .. i, heroData, index)
                table.insert(self._teamProgress, progressList)

                local serverId = playerExtraData.serverId

                self:SetIconClickScale(heroTrans, true)
                self:SetWndClick(heroTrans, function()
                    local showTip = true
                    if not isLeft then
                        showTip = gModelBattle:CheckShowEnemyTip(self._combatType)
                    end
                    if showTip then
                        gModelHero:ReqShowHeroTip(tostring(data.playerId), data, nil, nil, true, serverId)
                    else
                        GF.ShowMessage(ccClientText(16905))
                    end
                end)
                CS.ShowObject(mvp, isMvp)
            end
            CS.ShowObject(heroBattleData, isHaveData)
        else
            CS.ShowObject(heroBattleData, false)
        end
    end
end

function UIFightDetails:OnWndRefresh()
    local showType = self:GetWndArg("showType") or UIFightDetails.SHOWTYPE_NORNAL
    self._showType = showType

    if showType == UIFightDetails.SHOWTYPE_NORNAL then
        self:SetWndVisible(false)
        local reportInfo = self:GetWndArg("reportInfo")

        local reqInfo = {
            reportId = reportInfo.reportId,
            serverId = reportInfo.serverId,
            callback = function(reportTable)
                if self:IsWndClosed() then
                    return
                end

                self:SetWndVisible(true)
                local reportData = LFightReportData:New()
                reportData:CreateNoRound(reportTable)

                self._battleDetailData = gLFightManager:FormatBattleDetailData(reportData)
                self:InitNormalData()
                self:InitTeamShow()
            end,
            failCall = function()
                GF.CloseWndByName("UIFightDetails")
            end
        }

        self:GetReportTable(reqInfo)
    elseif showType == UIFightDetails.SHOWTYPE_SHOWLIST then
        self:InitListData()
        self:InitBtnList()
    elseif showType == UIFightDetails.SHOWTYPE_DETAIL then
        self._battleDetailData = self:GetWndArg("battleDetailData")
        self:InitNormalData()
        self:InitTeamShow()
    end
end

function UIFightDetails:InitEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:Exit()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBgImage, function()
        self:Exit()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnPlayBack, function()
        self:ShowBattlePlayBack()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mBtnShare, function()
        self:OnClickShare()
    end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UIFightDetails:InitEmptyList()
    local noRecord2 = self:FindWndTrans(self.mTeam1, "noRecord2")
    local EmptyIcon = self:FindWndTrans(noRecord2, "EmptyIcon")
    local EmptyTextBg = self:FindWndTrans(noRecord2, "EmptyTextBg")
    local EmptyText = self:FindWndTrans(noRecord2, "EmptyText")
    local data = {
        refId = 9009,
        IntroTran = EmptyText,
        TextBgTran = EmptyTextBg,
        IconTran = EmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty1")
    emptyList:RefreshUI(data)

    noRecord2 = self:FindWndTrans(self.mTeam2, "noRecord2")
    EmptyIcon = self:FindWndTrans(noRecord2, "EmptyIcon")
    EmptyTextBg = self:FindWndTrans(noRecord2, "EmptyTextBg")
    EmptyText = self:FindWndTrans(noRecord2, "EmptyText")
    data = {
        refId = 9009,
        IntroTran = EmptyText,
        TextBgTran = EmptyTextBg,
        IconTran = EmptyIcon,
    }
    emptyList = self:GetCommonEmptyList("_empty2")
    emptyList:RefreshUI(data)
end

function UIFightDetails:SetType(root, index)
    local damage = self:FindWndTrans(root, "Damage")
    local damageText = self:FindWndTrans(damage, "DamageText")
    local beDamage = self:FindWndTrans(root, "BeDamage")
    local beDamageText = self:FindWndTrans(beDamage, "BeDamageText")
    local treat = self:FindWndTrans(root, "Treat")
    local treatText = self:FindWndTrans(treat, "TreatText")

    self:SetWndText(damageText, ccClientText(16901))
    self:SetWndText(beDamageText, ccClientText(16902))
    self:SetWndText(treatText, ccClientText(16903))

    if self._isEnus then
        self:SetAnchorPos(damage,Vector2.New(-147,3))
        self:SetAnchorPos(beDamage,Vector2.New(-3,3))
        self:SetAnchorPos(treat,Vector2.New(130,3))
    end

end

function UIFightDetails:InitBtnList()
    local list = {}
    local _winnerNumber = self._winnerNumber or {}
    local btnDataList = self._btnDataList or {}
    for i, v in ipairs(btnDataList) do
        table.insert(list, {
            reportId = v,
            index = i,
            win = _winnerNumber[i],
        })
    end

    if not self._selReportId then
        local extraData = self:GetWndArg("extraData")
        local reportId
        if extraData and extraData.reportIdIndex then
            reportId = extraData.reportIdIndex
        else
            local firstReport = list[1]
            reportId = firstReport and firstReport.reportId
        end
        if reportId then
            self:OnClickTabBtn(reportId)
        end
    end

    if #list > 1 then
        CS.ShowObject(self.mBtnList, true)
    else
        CS.ShowObject(self.mBtnList, false)
        return
    end

    local uiBtnList = self._uiBtnList
    if uiBtnList then
        uiBtnList:RefreshData(list)
    else
        uiBtnList = self:GetUIScroll("uiBtnList")
        self._uiBtnList = uiBtnList
        uiBtnList:Create(self.mBtnList, list, function(...)
            self:OnDrawBtnCell(...)
        end, UIItemList.WRAP)
    end
end

function UIFightDetails:SetTeamData(root, index)
    if not root then
        return
    end

    if not self._extraData then
        CS.ShowObject(root, false)
    end

    local Player = self:FindWndTrans(root, "Player")
    self:SetPlayer(Player, index)

    local Type = self:FindWndTrans(root, "Type")
    self:SetType(Type, index)

    local HeroList = self:FindWndTrans(root, "HeroList")
    self:SetHeroList(HeroList, index)

    local isLeft = index == 1
    local temaData
    local hurtCount = 0
    if isLeft then
        temaData = self._battleDetailData.formationA
        hurtCount = self._battleDetailData.hurtCountA
    else
        temaData = self._battleDetailData.formationB
        hurtCount = self._battleDetailData.hurtCountB
    end
    local haveNum = 0
    for i, v in pairs(temaData) do
        if v.refId then
            haveNum = haveNum + 1
        end
    end
    local showNoRecord = haveNum <= 0
    local noRecord2 = self:FindWndTrans(root, "noRecord2")
    CS.ShowObject(noRecord2, showNoRecord)

    self:SetTactics(self.mTeam1, self._battleDetailData.formationAOtherData)
    self:SetTactics(self.mTeam2, self._battleDetailData.formationBOtherData)
    local hurtCountText = self:FindWndTrans(root, "ContainerRoot/HurtCountText")
    self:SetWndText(hurtCountText, string.replace(ccClientText(16907), hurtCount))
    if self.jpj then
        self:InitTextCharacterWithLanguage(hurtCountText,-5)
    end
    CS.ShowObject(hurtCountText, true)
end

function UIFightDetails:InitTeamShow()
    print("389183190238901"   ..debug.traceback())
    self:StopTween()

    local tween = DG.Tweening.DOTween.Sequence()
    self._bloodTweem = tween

    self:SetTeamData(self.mTeam1, 1)
    self:SetTeamData(self.mTeam2, 2)
    CS.ShowObject(self.mTeam1, true)
    CS.ShowObject(self.mTeam2, true)
    tween:Play()
end

function UIFightDetails:GetUIProgressByTrans(trans, key, value, count)
    local textTrans = CS.FindTrans(trans, "XUIText")
    self:SetWndText(textTrans, LUtil.NumberCoversion(value))
    local bg = CS.FindTrans(trans, "Bg")
    local image = CS.FindTrans(bg, "Image")
    return self:UIProgressFind(image, key, 0)
end

function UIFightDetails:InitText()
    self:SetWndButtonText(self.mBtnPlayBack, ccClientText(16900))
    self:SetWndText(self.mTitleText, ccClientText(10911))
    self:SetWndButtonText(self.mBtnShare, ccClientText(16906))
end

function UIFightDetails:GetProgressList(trans, key, heroData, index)
    local damage = "Damage"
    local beDamage = "BeDamage"
    local treat = "Treat"
    local progress, teamDetails
    local progressList = {}
    local damageCount, beDamageCount, treatCount
    local tween = self._bloodTweem

    local settlementReport = self._battleDetailData.settlementReport

    damageCount = index == 1 and settlementReport.hurtCountA or settlementReport.hurtCountB
    beDamageCount = index == 1 and settlementReport.injuredCountA or settlementReport.injuredCountB
    treatCount = index == 1 and settlementReport.treatCountA or settlementReport.treatCountB
    teamDetails = index == 1 and settlementReport.detailsA or settlementReport.detailsB

    local damageTrans = CS.FindTrans(trans, damage)
    local hurt = teamDetails[heroData.refId].hurt
    local progress1 = self:GetUIProgressByTrans(damageTrans, key .. damage, hurt, damageCount)
    if damageCount > 0 then
        local rate1 = hurt / damageCount
        tween:Join(YXTween.TweenFloat(0, rate1, self._speed, function(t)
            progress1:SetUIProgress(t)
        end))
        table.insert(progressList, progress1)
    end

    local beDamageTrans = CS.FindTrans(trans, beDamage)
    local injured = teamDetails[heroData.refId].injured
    local progress2 = self:GetUIProgressByTrans(beDamageTrans, key .. beDamage, injured, beDamageCount)
    if beDamageCount > 0 then
        local rate2 = injured / beDamageCount
        tween:Join(YXTween.TweenFloat(0, rate2, self._speed, function(t)
            progress2:SetUIProgress(t)
        end))
        table.insert(progressList, progress2)
    end

    local treatTrans = CS.FindTrans(trans, treat)
    local treat = teamDetails[heroData.refId].treat
    local progress3 = self:GetUIProgressByTrans(treatTrans, key .. treat, treat, treatCount)
    if treatCount > 0 then
        local rate3 = treat / treatCount
        tween:Join(YXTween.TweenFloat(0, rate3, self._speed, function(t)
            progress3:SetUIProgress(t)
        end))
        table.insert(progressList, progress3)
    end
    return progressList
end

function UIFightDetails:SetTactics(root, data)
    local item = self:FindWndTrans(root, "ContainerRoot/tactics")
    local scale = self:FindWndTrans(item, "scale")
    local scaleBg = self:FindWndTrans(scale, "bg")
    local scaleIcon = self:FindWndTrans(scale, "icon")

    local isShow = false
    local tacticId = data.tacticsId
    local ref = gModelSimuFight:GetSimulateGameSkill(tacticId)
    if ref then
        isShow = true
        self:SetWndEasyImage(scaleIcon, ref.icon)
    end

    self:SetIconClickScale(item, true)

    CS.ShowObject(item, isShow)

    self:SetWndClick(item, function()
        local skillid = tonumber(ref.skill)
        if not skillid then
            return
        end
        gModelGeneral:OpenSkillWnd({ curSkillId = skillid, wndType = 2 })

        --GF.OpenWnd("UINewJNTip",{curSkillId = skillid,wndType = 2})
    end)
end

function UIFightDetails:SetPlayer(root, index)
    local fail = self:FindWndTrans(root, "Fail")
    local win = self:FindWndTrans(root, "Win")
    local playerName = self:FindWndTrans(root, "PlayerName")

    local _battleDetailData = self._battleDetailData
    local settlementReport = _battleDetailData.settlementReport
    local formationNameA = _battleDetailData.formationAOtherData.formationName
    local formationNameB = _battleDetailData.formationBOtherData.formationName
    local isWin = settlementReport.winner == index
    CS.ShowObject(fail, not isWin)
    CS.ShowObject(win, isWin)

    local isLeft = index == 1
    local formationName = isLeft and formationNameA or formationNameB
    if string.isempty(formationName) then
        local playerInfo = isLeft and self._me or self._other
        if playerInfo then
            formationName = playerInfo.name
        end
    end
    formationName = ccLngText(formationName)
    local nameStr = LUtil.FormatColorStr(formationName, isWin and "yellow_2" or "white")
    self:SetWndText(playerName, nameStr)
    local pos = self._isForeign and Vector2.New(0, 151.5) or Vector2.New(-49.5, 151.5)
    self:SetAnchorPos(playerName, pos)
    if self.jpj then
        self:SetAnchorPos(playerName, Vector2.New(-75, 151.5))
        self:InitTextSizeWithLanguage(playerName,-2)
        self:InitTextCharacterWithLanguage(playerName,-5)
    end
end

function UIFightDetails:OnDrawBtnCell(list, item, itemdata, itempos)
    local BtnTab1 = self:FindWndTrans(item, "BtnTab1")
    local win = self:FindWndTrans(item, "Image/Win")
    local reportId = itemdata.reportId
    local _win = itemdata.win or 0
    self:SetWndEasyImage(win, _win == 1 and "trial2_txt_2" or "trial2_txt_1",nil ,true)

    local btnStr = string.replace(ccClientText(21817), itemdata.index)
    self:SetWndTabText(BtnTab1, btnStr)

    local status = self._selReportId == reportId and LWnd.StateOn or LWnd.StateOff
    self:SetWndTabStatus(BtnTab1, status)

    self:SetWndClick(BtnTab1, function()
        self:OnClickTabBtn(reportId)
    end)
end

function UIFightDetails:OnClickShare()
    local shareType = ModelChat.CHATSHARE_17
    local shareData = {
        reportId = self._reportId,
        serverId = self._serverId or gLGameLogin:GetActualServerId(),
        battleName = self._battleName,
    }
    if self._refId == 3 then
        shareType = ModelChat.CHATSHARE_21
    else
        shareType = ModelChat.CHATSHARE_17
        shareData.hurt = self._hurt
    end
    local jsonStr = JSON.encode(shareData)
    local data = {
        root = self.mBtnShare,
        shareType = shareType,
        shareData = jsonStr
    }
    gModelGeneral:OpenShareTip(data)
end

function UIFightDetails:InitListData()
    local extraData = self:GetWndArg("extraData")
    self._extraData = extraData
    self._combatType = extraData.combatType
    --local combatResult = extraData.combatResult
    --if combatResult then
    self._winnerNumber = extraData.winnerNumber
    --end
    self._btnDataList = extraData.reportId

    self._serverId = extraData.serverId
    self._reportUrl = extraData.reportUrl

    self._me.name = extraData.meName or gModelPlayer:GetPlayerName()
    self._other.name = extraData.otherName or ""

    self._teamProgress = {}
    if LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS == self._combatType then
        CS.ShowObject(self.mBtnPlayBack, false)
    end
end

--[[
	detailData =
	{

		combatType,
		formationA,
		formationB,
		formationAOtherData,
		formationBOtherData,
		settlementReport,
		reportTableID,
		extraData,
	}
]]

function UIFightDetails:InitNormalData()
    --local battleDetailData = self:GetWndArg("battleDetailData")
    --
    --self._battleDetailData = battleDetailData
    local battleDetailData = self._battleDetailData

    self._extraData = self:GetWndArg("extraData") or {}
    self._combatType = battleDetailData.combatType
    self._reportId = battleDetailData.reportTableID
    self._isShare = self._extraData.isShare
    self._battleName = self._extraData.battleName
    self._hurt = self._extraData.hurt
    self._refId = self._extraData.refId
    CS.ShowObject(self.mBtnShare, self._isShare)

    local meName = battleDetailData.formationAOtherData.formationName
    if string.isempty(meName) then
        meName = self._extraData.meName or gModelPlayer:GetPlayerName()
    end

    local otherName = battleDetailData.formationBOtherData.formationName
    if string.isempty(otherName) then
        otherName = self._extraData.otherName or ""
    end

    self._me.name = meName
    self._other.name = otherName
    self._me.serverId = battleDetailData.formationAOtherData.serverId
    self._other.serverId = battleDetailData.formationBOtherData.serverId
    if LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS == self._combatType then
        CS.ShowObject(self.mBtnPlayBack, false)
    end
end

function UIFightDetails:ShowBattlePlayBack()
    local showType = self._showType
    if showType == UIFightDetails.SHOWTYPE_NORNAL then
        self:BattlePlayback()
    else
        self:BattleListMorePlayBack()
    end
end

function UIFightDetails:CloseResultWnd()
    -- if (gModelHighStageRace:IsHighStageRace(self._combatType)) then
    -- 	local resultWndIns = GF.FindFirstWndByName("WndHighStageRaceBattleResult")
    -- 	local wndTrans = resultWndIns:GetWndTrans()
    -- 	CS.ShowObject(wndTrans, false)
    -- else
    GF.CloseWndByName("UIOrdinResult")
    GF.CloseWndByName("UIringFightResult")
    GF.CloseWndByName("WndCrossServerBattleResult")
    -- end
end

function UIFightDetails:BattleListMorePlayBack()
    local extraData = self._extraData
    if not extraData then
        return
    end
    local battleDetailData = self._battleDetailData
    if not battleDetailData then
        return
    end
    local reportTableID = battleDetailData.reportTableID

    extraData.reportIdIndex = reportTableID
    local closeFunc = extraData.closeAfterVideo
    local showType = self._showType
    if not closeFunc then
        closeFunc = function(combatType)
            local isVideoAlive = gModelBattle:IsVideoAlive()
            if not isVideoAlive then
                local returnFun = gModelBattle:GetReturnFun(combatType)
                if returnFun then
                    returnFun(extraData)
                end
            end
        end
    end
    extraData.closeFunc = closeFunc
    extraData.battleEndfun = function(changeBot)
        -- if (gModelHighStageRace:IsHighStageRace()) then
        -- 	local resultWndIns = GF.FindFirstWndByName("WndHighStageRaceBattleResult")
        -- 	local wndTrans = resultWndIns:GetWndTrans()
        -- 	CS.ShowObject(wndTrans, true)
        -- 	GF.OpenWnd('UIFightDetails', { showType = 1, extraData = extraData, isFromBack = true })
        -- else
        -- gLFightManager:ShowCrossGradingBattleDetail(extraData, changeBot)
        -- GF.OpenWnd('UIFightDetails', { showType = showType, extraData = extraData, isFromBack = changeBot })
        GF.OpenWnd('UIFightDetails', { showType = showType, battleDetailData = battleDetailData, extraData = extraData, isFromBack = changeBot })
        -- end
    end
    self._isToVideo = true
    gLFightManager:OnPlayBattleVideo(reportTableID, extraData, LCombatTypeConst.COMBAT_BATTLE_VIDEO)
    self:CloseResultWnd()
end

-- 播放战斗
function UIFightDetails:BattlePlayback()
    self._isToVideo = true
    local extraData = self._extraData
    extraData.offlineTime = 0
    extraData.isBattleToBackground = false
    extraData.isNew = true
    extraData.dungeonId = extraData.dungeonId
    extraData.videoType = extraData.videoType
    extraData.sid = extraData.sid
    extraData.params = extraData.params
    local combatType = self._combatType

    extraData.combatType = combatType
    local battleDetailData = self._battleDetailData
    local showType = self._showType
    local reportInfo = self:GetWndArg("reportInfo")

    local closeFunc = extraData.closeAfterVideo
    if not closeFunc then
        closeFunc = function(combatType, combatResult)
            local isVideoAlive = gModelBattle:IsVideoAlive()
            if not isVideoAlive then
                local returnFun = gModelBattle:GetReturnFun(combatType)
                if returnFun then
                    returnFun(combatResult, extraData.sid)
                end
            end
        end
    end

    extraData.closeFunc = closeFunc

    if not extraData.battleMapName then
        local battleMapName = gModelBattle:GetBattleMapRes({ combatType = combatType, dungeonId = extraData.dungeonId })
        extraData.battleMapName = battleMapName
    end

    extraData.battleEndfun = function(changeBot)
        -- gLFightManager:ShowBattleDetailByDetail(battleDetailData, extraData, changeBot)
        GF.OpenWnd('UIFightDetails', { showType = showType, reportInfo = reportInfo, battleDetailData = battleDetailData, extraData = extraData, isFromBack = changeBot })
    end

    local playExtraFun = extraData.playExtraFun
    if playExtraFun then
        playExtraFun()
    end

    -- 清理所有界面
    local reportId = self._battleDetailData.reportTableID
    gLFightManager:OnPlayBattleVideo(reportId, extraData, LCombatTypeConst.COMBAT_BATTLE_VIDEO)

    self:CloseResultWnd()

    if combatType == LCombatTypeConst.COMBAT_PK then
        gModelGeneral:RecordGameState()
    end
end

function UIFightDetails:Exit()
    for i, v in ipairs(self._teamProgress) do
        for j, k in ipairs(v) do
            k:CleanUp()
        end
    end
    self._teamProgress = nil
    self:StopTween()
    self:WndClose()
end

function UIFightDetails:OnClickTabBtn(reportId)
    if not reportId then
        return
    end
    if self._selReportId == reportId then
        return
    end
    self._selReportId = reportId

    local reportInfo = {
        reportId = reportId,
        callback = function(reportTable)
            local reportData = LFightReportData:New()
            reportData:CreateNoRound(reportTable)
            local battleDetailData = gLFightManager:FormatBattleDetailData(reportData)
            self._battleDetailData = battleDetailData
            self:InitTeamShow()
            self:InitBtnList()
        end,
        serverId = self._serverId,
        reportUrl = self._reportUrl,
    }
    self:GetReportTable(reportInfo)
end

function UIFightDetails:StopTween()
    local seq = self._bloodTweem
    if seq then
        seq:Kill(false)
        self._bloodTweem = nil
    end
end

------------------------------------------------------------------
return UIFightDetails