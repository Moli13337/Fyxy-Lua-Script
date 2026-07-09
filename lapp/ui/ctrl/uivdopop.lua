---
--- Created by Administrator.
--- DateTime: 2023/10/21 17:37:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIVdoPop:LWnd
local UIVdoPop = LxWndClass("UIVdoPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIVdoPop:UIVdoPop()
    self._iconHeroClsList = {}
    self._uiheadList = {}

    self._winIconPath = "bestronger_txt_1"
    self._failIconPath = "bestronger_txt_2"
    self._emptySkillBgPath = "public_skill_bg"
    self._waitEndPassTimeKey = "waitEndPassTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIVdoPop:OnWndClose()
    self:ClearCommonIconList(self._iconHeroClsList)
    self:ClearCommonIconList(self._uiheadList)
    self._winIconList = {}
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIVdoPop:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIVdoPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self.jpj = gLGameLanguage:IsJapanVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitData()
    self:InitCommand()
    self:InitStaticData()
end

function UIVdoPop:OnClickPlayBackBtn()
    local extraData = {}
    local videoInfo = self._videoInfo
    local reportId = videoInfo:GetReportId() or self._otherReportId
    local combatType = videoInfo:GetCombatType()
    local attackPlayer
    local defensePlayer
    local serverId
    local moreTeam = self._moreTeam

    reportId = string.split(reportId, "|")
    local selectIndex = self._selectIndex or 1

    local reportSize = #reportId
    selectIndex = selectIndex <= reportSize and selectIndex or reportSize

    reportId = reportId[selectIndex]

    if self._openEnum == ModelVideoCenter.OpenEnumVideoCenter
            or self._openEnum == ModelVideoCenter.OpenEnumVideoCenterShare then
        local tabPage = self._tabPage
        local typeRefId = self._typeRefId
        local isShare = self._openEnum == ModelVideoCenter.OpenEnumVideoCenterShare
        local videoIndex = videoInfo:GetVideoIndex()
        attackPlayer = videoInfo:GetAttackPlayer()
        defensePlayer = videoInfo:GetDefensePlayer()
        serverId = videoInfo:GetServerId()

        extraData.meName = attackPlayer:GetPlayerName()
        extraData.otherName = defensePlayer:GetPlayerName()
        extraData.videoType = gModelBattle:GetVideoTypeCostByCombatType(combatType)
        extraData.battleEndfun = function()
            self:OnVideoCenterPlayEnd(videoInfo, tabPage, typeRefId, isShare, moreTeam)
        end

        gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaBackPlay, videoIndex)

        --数数打点
        if not (tabPage or typeRefId) then
            gModelVideoCenter:OnVideoTAClientEventReq(nil, reportId)
        else
            gModelVideoCenter:OnVideoTAClientEventReq("录像馆_播放", reportId, tabPage, typeRefId)
        end
    elseif self._openEnum == ModelVideoCenter.OpenEnumArena then
        local combatExtraDatas = self._combatExtraDatas
        attackPlayer = videoInfo:GetAttack()
        defensePlayer = videoInfo:GetDefense()
        -- serverId 			= gLGameLogin:GetActualServerId()
        serverId = videoInfo:GetServerId()

        extraData.meName = attackPlayer:GetName()
        extraData.otherName = defensePlayer:GetName()
        extraData.videoType = combatExtraDatas.videoType
        extraData.battleEndfun = combatExtraDatas.battleEndfun
        extraData.canSkip = combatExtraDatas.canSkip

    elseif self._openEnum == ModelVideoCenter.OpenEnumChampion then
        local combatExtraDatas = self._combatExtraDatas
        attackPlayer = videoInfo:GetAttack()
        defensePlayer = videoInfo:GetDefense()
        serverId = videoInfo:GetServerId()

        extraData.meName = attackPlayer:GetName()
        extraData.otherName = defensePlayer:GetName()
        extraData.videoType = combatExtraDatas.videoType
        extraData.battleEndfun = combatExtraDatas.battleEndfun
        extraData.canSkip = combatExtraDatas.canSkip
        extraData.round = combatExtraDatas.round

        if combatExtraDatas.playExtraFun then
            combatExtraDatas.playExtraFun()
        end
    end

    extraData.combatType = combatType
    extraData.serverId = serverId
    extraData.mePlayerServerId = attackPlayer:GetServerId()
    extraData.otherPlayerServerId = defensePlayer:GetServerId()

    extraData.offlineTime = 0
    extraData.isBattleToBackground = false
    extraData.isNew = true
    extraData.dungeonId = nil--extraData.dungeonId

    if not extraData.battleMapName then
        local battleMapName = gModelBattle:GetBattleMapRes({ combatType = combatType, dungeonId = extraData.dungeonId })
        extraData.battleMapName = battleMapName
    end

    gLFightManager:OnPlayBattleVideo(reportId, extraData, LCombatTypeConst.COMBAT_BATTLE_VIDEO)

    -- 清理所有界面
    --gLGameUI:CloseAllButExcept({["UIFight"]= true})
end

function UIVdoPop:SetSkillList(playerNode, skillInfos, playerType)
    skillInfos = skillInfos or {}

    local dataList = {}
    for i = 1, 4 do
        if skillInfos[i] and skillInfos[i] > 0 then
            dataList[i] = skillInfos[i]
        end
    end

    local skillList = {}
    local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
    local DraconicRef = GameTable.DraconicRef

    local startI = playerType == 1 and 4 or 1
    local endI = playerType == 1 and 1 or 4
    local add = playerType == 1 and -1 or 1
    for k = startI, endI, add do
        local data = dataList[k]
        if not data then
            data = { ref = nil, upRef = nil }
        else
            local upRef = DraconicSuitRankRef[data]
            local ref = DraconicRef[upRef.type]
            data = { ref = ref, upRef = upRef }
        end
        table.insert(skillList, data)
    end

    local skillListTrans = self:FindWndTrans(playerNode, "skillList")

    local listName = "skillList" .. playerType
    local list = self:GetUIScroll(listName)
    list:Create(skillListTrans, skillList, function(...)
        self:OnDrawSkill(...)
    end)
end


--构建多个队伍的信息
function UIVdoPop:CreateMoreTeamInfo()

    -- reportList
    local otherReport = self._videoInfo:GetOtherReport()

    if not otherReport then
        return
    end

    CS.ShowObject(self.mDataBtn, false)

    local reportIdList = otherReport.reportIdList
    local winnerNumber = otherReport.winnerNumber
    local serverId = otherReport.serverId
    local reportList = {}
    CS.ShowObject(self.mBottom, #reportIdList > 1)
    for i, v in ipairs(reportIdList or {}) do
        local winNum = winnerNumber[i] or ModelCrossGrading.DEFEND_TYPE --winNum  获胜方 1 -- 攻击  2 -- 防守

        table.insert(reportList, {
            reportId = v,
            index = i,
            winNum = winNum,
            serverId = serverId,
        })
    end

    self:InitReportList(reportList)
end

function UIVdoPop:SetHero(item, hero, playerId, isMonster, serverId)
    local heroRoot = self:FindWndTrans(item, "HeroIcon")
    local instance = item:GetInstanceID()
    local id, refId, star, level, grade, fightPower = hero.id, hero.refId, hero.star, hero.lv, hero.grade, hero.fightPower
    local petIds = hero.petIds
    if not level then
        level = hero.level
    end
    local heroData = {
        id = id,
        refId = refId,
        star = star,
        level = level,
        skin = hero.skin,
        isResonance = hero.isResonance,
        petIds = petIds,
    }

    local heroIcon = self._iconHeroClsList[instance]
    if not heroIcon then
        heroIcon = CommonIcon:New()
        self._iconHeroClsList[instance] = heroIcon
        heroIcon:Create(heroRoot)
        self:SetIconClickScale(heroRoot, true)
    end
    heroIcon:SetHeroDataSet(heroData)
    heroIcon:DoApply()

    self:SetWndClick(heroRoot, function()
        if isMonster then
            return
        end

        local data = {
            id = id,
            refId = refId,
            level = level,
            star = star,
            grade = grade,
            fightPower = fightPower,
            isResonance = hero.isResonance,
            skin = hero.skin,
            petIds = petIds,
        }
        gModelHero:ReqShowHeroTip(playerId, data, nil, nil, nil, serverId)
    end)
end

function UIVdoPop:InitMessage()

end

function UIVdoPop:SetTeamNode(playerNode, combatHeroData, playerId, serverId)
    local heroList = self:FindWndTrans(playerNode, "heroList")
    local itemTemp = self.mHeroTemplate

    local _heros = {}
    local isMonster = false
    if combatHeroData then
        local heros = combatHeroData._heros
        local grids = combatHeroData._grids
        for i, v in ipairs(heros) do
            local pos = grids[i]
            _heros[pos] = v
        end
        isMonster = combatHeroData:CheckIsMonster()
    end
    local gridMax = LCombatFormationConst.GRID_MAX
    for i = 1, gridMax do
        local root = self:FindWndTrans(heroList, tostring(i))
        LxResUtil.DestroyChild(root)
        local heroData = _heros[i]
        if heroData then
            local itemNew = LxResUtil.NewObject(itemTemp.gameObject)
            itemNew.transform:SetParent(root, false)
            itemNew.transform.localPosition = Vector3.zero
            CS.ShowObject(itemNew, true)
            self:SetHero(itemNew.transform, heroData, playerId, isMonster, serverId)
        end
    end
end

function UIVdoPop:OnTimer(key)
    if key == self._waitEndPassTimeKey then
        for k, v in ipairs(self._winIconList) do
            CS.ShowObject(v, true)
        end
        self._isCombatEnd = true
    end
end

function UIVdoPop:InitEvent()
    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mDataBtn, function(...)
        self:OnClickDataBtn()
    end)
    self:SetWndClick(self.mPlayBackBtn, function(...)
        self:OnClickPlayBackBtn()
    end)
end

function UIVdoPop:ClickNumBtn(index)
    --拿数据 设置
    local reportData = self._teamInfo[index]

    if not reportData then
        return
    end

    --设置选中状态
    for i = 1, 3 do
        local tran = self._bottomBtn[i]

        local selectTran = CS.FindTrans(tran, "Select")
        local unSelectTran = CS.FindTrans(tran, "UnSelect")

        if i == index then
            CS.ShowObject(selectTran, true)
            CS.ShowObject(unSelectTran, false)
        else
            CS.ShowObject(selectTran, false)
            CS.ShowObject(unSelectTran, true)
        end
    end

    --设置队伍  A  和 B
    self._otherReportId = reportData.id
    local attackCombatHeroData = reportData.formationA

    local defenseCombatHeroData = reportData.formationB
    local gridMax = LCombatFormationConst.GRID_MAX
    local heroList = self:FindWndTrans(self.mPlayerTeam1, "heroList")
    for i = 1, gridMax do
        local root = self:FindWndTrans(heroList, tostring(i))
        LxResUtil.DestroyChild(root)
    end
    heroList = self:FindWndTrans(self.mPlayerTeam2, "heroList")
    for i = 1, gridMax do
        local root = self:FindWndTrans(heroList, tostring(i))
        LxResUtil.DestroyChild(root)
    end


    --
    self:SetBattleShow(self.mPlayerTeam1, attackCombatHeroData, attackCombatHeroData.playerId, false, attackCombatHeroData.serverId)
    self:SetBattleShow(self.mPlayerTeam2, defenseCombatHeroData, defenseCombatHeroData.playerId, false, defenseCombatHeroData.serverId)
    --self:SetTeamNode(self.mPlayerTeam1, attackCombatHeroData, attackCombatHeroData.playerId, attackCombatHeroData.serverId)
    --self:SetTeamNode(self.mPlayerTeam2, defenseCombatHeroData, defenseCombatHeroData.playerId,  defenseCombatHeroData.serverId)

    --获取技能的数据
    local combatUnitsList = attackCombatHeroData.combatUnits[1] or {}
    local campSkillIdList = combatUnitsList.data or {}
    local attackSkillList = campSkillIdList.skillList or {}
    local treasureList = { }
    for k = 1, 4 do
        local data = attackSkillList[k]
        if not data then
            data = {
                isEmpty = true
            }
        end
        table.insert(treasureList, data)
    end
    self:InitTreasureList(self.mPlayerTeam1, treasureList)

    combatUnitsList = defenseCombatHeroData.combatUnits[1] or {}
    campSkillIdList = combatUnitsList.data or {}
    local defendSkillList = campSkillIdList.skillList or {}
    treasureList = { }
    for k = 1, 4 do
        local data = defendSkillList[k]
        if not data or data.skillRefId == 0 then
            data = {
                isEmpty = true
            }
        end
        table.insert(treasureList, data)
    end
    self:InitTreasureList(self.mPlayerTeam2, treasureList)
    self._selectIndex = index
end

function UIVdoPop:OnDrawSkill(list, item, itemdata, itempos)
    local DraconicSkill = self:FindWndTrans(item, "DraconicSkill")
    local icon = self:FindWndTrans(DraconicSkill, "icon")
    CS.ShowObject(icon, itemdata.ref ~= nil)
    if itemdata.ref then
        local param = {
            showName = true,
            showType = true,
            showStar = true,
            upRefId = itemdata.upRef.refId,
        }
        gModelDraconic:DrawSkillItem(self, DraconicSkill, param)
    end
    self:SetWndClick(item, function()
        if itemdata.ref then
            GF.OpenWnd("UIDraconicUpStar", { refId = itemdata.ref.refId, starNum = itemdata.upRef.rankNow, tips = true })
        end
    end)


end

function UIVdoPop:InitBottomBtnState()
    for i = 1, 3 do
        if not self._teamInfo[i] then
            CS.ShowObject(self._bottomBtn[i], false)
        else
            CS.ShowObject(self._bottomBtn[i], true)

            local selectTxt = CS.FindTrans(self._bottomBtn[i], "Select/UIText")
            local unSelectTxt = CS.FindTrans(self._bottomBtn[i], "UnSelect/UIText")

            self:SetWndText(selectTxt, i)
            self:SetWndText(unSelectTxt, i)

            self:SetWndClick(self._bottomBtn[i], function()
                self:ClickNumBtn(i)
            end)
        end
    end
    --默认选择第一个
    self:ClickNumBtn(1)
end

function UIVdoPop:InitCommand()
    local videoInfo = self._videoInfo
    if not videoInfo then
        printInfoNR("self._videoInfo is a nil")
        return
    end

    local attackPlayerData
    local defensePlayerData
    local winner
    local attackCombatHeroData
    local attackPlayerId
    local attackPlayerServerId
    local attackPlayerSkillInfo
    local attackPlayerDraconic
    local defenseCombatHeroData
    local defensePlayerId
    local defensePlayerServerId
    local defensePlayerSkillInfo
    local defensePlayerDraconic
    if self._openEnum == ModelVideoCenter.OpenEnumVideoCenter
            or self._openEnum == ModelVideoCenter.OpenEnumVideoCenterShare then
        attackPlayerData = videoInfo:GetAttackPlayer()
        defensePlayerData = videoInfo:GetDefensePlayer()
        winner = videoInfo:GetWinner()
        attackCombatHeroData = attackPlayerData:GetFormation()
        attackPlayerId = attackPlayerData:GetPlayerId()
        attackPlayerServerId = attackPlayerData:GetServerId()
        -- attackPlayerSkillInfo 		= attackCombatHeroData:GetSkillInfo()
        attackPlayerDraconic = attackCombatHeroData._draconicList
        defenseCombatHeroData = defensePlayerData:GetFormation()
        defensePlayerId = defensePlayerData:GetPlayerId()
        defensePlayerServerId = defensePlayerData:GetServerId()
        -- defensePlayerSkillInfo 		= defenseCombatHeroData:GetSkillInfo()
        defensePlayerDraconic = defenseCombatHeroData._draconicList
    elseif self._openEnum == ModelVideoCenter.OpenEnumArena
            or self._openEnum == ModelVideoCenter.OpenEnumChampion then
        attackPlayerData = videoInfo:GetAttack()
        defensePlayerData = videoInfo:GetDefense()
        winner = videoInfo:GetWinner()
        attackCombatHeroData = videoInfo:GetAttackHeros()
        attackPlayerId = attackPlayerData:GetPlayerId()
        attackPlayerServerId = attackPlayerData:GetServerId()
        -- attackPlayerSkillInfo 		= attackCombatHeroData:GetSkillInfo()
        attackPlayerDraconic = attackCombatHeroData._draconicList
        defenseCombatHeroData = videoInfo:GetDefenseHeros()
        defensePlayerId = defensePlayerData:GetPlayerId()
        defensePlayerServerId = defensePlayerData:GetServerId()
        -- defensePlayerSkillInfo 		= defenseCombatHeroData:GetSkillInfo()
        defensePlayerDraconic = defenseCombatHeroData._draconicList
    end

    self:SetPlayerNode(self.mPlayer1, attackPlayerData, winner == 1)
    self:SetPlayerNode(self.mPlayer2, defensePlayerData, winner == 2)
    self:SetTeamNode(self.mPlayerTeam1, attackCombatHeroData, attackPlayerId, attackPlayerServerId)
    self:SetTeamNode(self.mPlayerTeam2, defenseCombatHeroData, defensePlayerId, defensePlayerServerId)
    self:SetSkillList(self.mPlayerTeam1, attackPlayerDraconic, ModelVideoCenter.AttackPlayer)
    self:SetSkillList(self.mPlayerTeam2, defensePlayerDraconic, ModelVideoCenter.DefensePlayer)

    --加多一个参数 判断是否是多队伍 多队伍的信息要从另外的地方构建
    if self._moreTeam then
        --构建多个队伍的信息
        self:CreateMoreTeamInfo()
    end

    if not self._isCombatEnd then
        self:TimerStart(self._waitEndPassTimeKey, self._waitEndPassTime, false, 1)
    end
end

function UIVdoPop:InitData()
    self._videoInfo = self:GetWndArg("videoInfo")
    self._openEnum = self:GetWndArg("openEnum")
    self._tabPage = self:GetWndArg("tabPage")
    self._typeRefId = self:GetWndArg("typeRefId")
    self._combatExtraDatas = self:GetWndArg("combatExtraDatas")
    self._moreTeam = self:GetWndArg("moreTeam")

    self._isCombatEnd = true
    if self._combatExtraDatas then
        self._waitEndPassTime = self._combatExtraDatas.waitEndPassTime or 0
        self._isCombatEnd = self._waitEndPassTime <= 0
    end

    self._winIconList = {}

    self._teamInfo = {}

    self._bottomBtn = {
        self.mButton_1,
        self.mButton_2,
        self.mButton_3,
    }
end

function UIVdoPop:SetHeroInfo(trans, data, playerId, isMonster, serverId)
    local itemTemp = self.mHeroTemplate

    if data then
        local itemNew = LxResUtil.NewObject(itemTemp.gameObject)
        itemNew.transform:SetParent(trans, false)
        itemNew.transform.localPosition = Vector3.zero
        CS.ShowObject(itemNew, true)
        self:SetHero(itemNew.transform, data.heroData, playerId, isMonster, serverId)
    end
end

function UIVdoPop:InitReportList(reportList)
    --初始化完之后 调用一次构建
    self._count = #reportList
    self._collectReportId = nil
    for k, report in ipairs(reportList) do
        local reportInfo = {
            reportId = report.reportId,
            serverId = report.serverId,
            callback = function(reportTable)

                local reportTable = reportTable
                --构建index的缓存
                local reportData = LFightReportData:New()
                reportData:CreateNoRound(reportTable)

                if not self._teamInfo then
                    self._teamInfo = {}
                end
                self._teamInfo[report.index] = reportData

                self._count = self._count - 1
                if self._count <= 0 then
                    self:InitBottomBtnState()
                end
            end,
        }
        self._collectReportId = report.reportId
        self:GetReportTable(reportInfo)
    end


end

function UIVdoPop:InitStaticData()
    local openEnum = self._openEnum
    local titleStr
    local playBackStr

    if openEnum == ModelVideoCenter.OpenEnumVideoCenter
            or openEnum == ModelVideoCenter.OpenEnumVideoCenterShare then
        titleStr = ccClientText(21514)
        playBackStr = ccClientText(21515)
    elseif openEnum == ModelVideoCenter.OpenEnumArena
            or openEnum == ModelVideoCenter.OpenEnumChampion then
        titleStr = ccClientText(21535)
        playBackStr = ccClientText(21536)
    end

    self:SetWndText(self.mLblBiaoti, titleStr)
    self:SetWndText(self.mDataText, ccClientText(21509))
    self:SetWndText(self.mPlayBackText, playBackStr)
    if self.jpj then
        self:InitTextSizeWithLanguage(self.mPlayBackText,-4)
        self:InitTextCharacterWithLanguage(self.mPlayBackText,-5)
    end
end

function UIVdoPop:OnVideoCenterPlayEnd(videoInfo, tabPage, typeRefId, isShare, moreTeam)
    GF.ChangeMap("LCityMap")
    if not isShare then
        local id = videoInfo:GetId()
        GF.OpenWndBottom("UIVdoCenter", { tabPage = tabPage, typeRefId = typeRefId, videoId = id })
        GF.OpenWnd("UIVdoPop", { videoInfo = videoInfo, openEnum = ModelVideoCenter.OpenEnumVideoCenter,
                                    tabPage = tabPage, typeRefId = typeRefId, moreTeam = moreTeam })
    else
        local channel = gModelChat:GetVideoCenterPlayChannel()
        gModelChat:OnClickOpenChat({ channel = tonumber(channel) })
    end
end

function UIVdoPop:SetPlayerNode(playerTrans, playerData, isWin)
    if CS.IsNullObject(playerTrans) or not playerData then
        return
    end

    local nameText = self:FindWndTrans(playerTrans, "name")
    local headIcon = self:FindWndTrans(playerTrans, "HeadIcon")
    local leve = self:FindWndTrans(playerTrans, "HeadIcon/lvBg/level")
    local winIcon = self:FindWndTrans(playerTrans, "winIcon")
    local powerText = self:FindWndTrans(playerTrans, "PowerBg/PowerText")

    if self._isVie then
        self:SetAnchorPos(leve,Vector2.New(0,-8))
    end

    local InstanceID = headIcon:GetInstanceID()
    local playerId = playerData:GetPlayerId()
    local power = playerData:GetPower()
    local isMonster = false
    local playerName
    local playerIcon
    local playerHeadFrame
    local playerLevel
    if self._openEnum == ModelVideoCenter.OpenEnumVideoCenter
            or self._openEnum == ModelVideoCenter.OpenEnumVideoCenterShare then
        playerName = playerData:GetPlayerName()
        isMonster = playerData:CheckIsMonster()
        playerIcon = playerData:GetPlayerHead()
        playerHeadFrame = playerData:GetPlayerFrame()
        playerLevel = playerData:GetPlayerLevel()
    elseif self._openEnum == ModelVideoCenter.OpenEnumArena
            or self._openEnum == ModelVideoCenter.OpenEnumChampion then
        playerName = playerData:GetName()
        isMonster = false
        playerIcon = playerData:GetHead()
        playerHeadFrame = playerData:GetHeadFrame()
        playerLevel = playerData:GetGrade()
    end

    self:SetWndText(nameText, playerName)
    local powerStr = LUtil.PowerNumberCoversion(power)
    self:SetWndText(powerText, powerStr)

    CS.ShowObject(winIcon, self._isCombatEnd)
    if isWin then
        self:SetWndEasyImage(winIcon, self._winIconPath)
    else
        self:SetWndEasyImage(winIcon, self._failIconPath)
    end
    table.insert(self._winIconList, winIcon)

    -- headIcon
    local playerInfo = {
        trans = headIcon,
        playerId = isMonster and InstanceID or playerId,
        name = playerName,
        icon = playerIcon,
        headFrame = playerHeadFrame or 20001,
        level = playerLevel,
        noLv = false
    }
    local uiheadlist = self._uiheadList
    local headIconClass = uiheadlist[InstanceID]
    if not headIconClass then
        headIconClass = HeadIcon:New(self)
        uiheadlist[InstanceID] = headIconClass
    end
    headIconClass:SetHeadData(playerInfo)
    headIconClass:RefreshUI()

    self:SetWndClick(headIcon, function(...)
        if isMonster then
            return
        end
        gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
    end)
end

function UIVdoPop:OnClickDataBtn()
    if not self._isCombatEnd then
        GF.ShowMessage(ccClientText(21537))
        return
    end

    local extraData = {}
    local videoInfo = self._videoInfo
    local reportId = videoInfo:GetReportId()
    local combatType = videoInfo:GetCombatType()
    --local attackPlayer
    --local defensePlayer
    local serverId

    if self._openEnum == ModelVideoCenter.OpenEnumVideoCenter
            or self._openEnum == ModelVideoCenter.OpenEnumVideoCenterShare then
        local tabPage = self._tabPage
        local typeRefId = self._typeRefId
        local isShare = self._openEnum == ModelVideoCenter.OpenEnumVideoCenterShare
        local videoIndex = videoInfo:GetVideoIndex()
        --attackPlayer  		= videoInfo:GetAttackPlayer()
        --defensePlayer 		= videoInfo:GetDefensePlayer()
        serverId = videoInfo:GetServerId()

        --extraData.meName 	= attackPlayer:GetPlayerName()
        --extraData.otherName = defensePlayer:GetPlayerName()
        extraData.videoType = gModelBattle:GetVideoTypeCostByCombatType(combatType)
        extraData.playExtraFun = function()
            if not (tabPage or typeRefId) then
                gModelVideoCenter:OnVideoTAClientEventReq(nil, reportId)
            else
                gModelVideoCenter:OnVideoTAClientEventReq("录像馆_播放", reportId, tabPage, typeRefId)
            end
            gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaBackPlay, videoIndex)
        end

        extraData.closeAfterVideo = function()
            self:OnVideoCenterPlayEnd(videoInfo, tabPage, typeRefId, isShare, self._moreTeam)
        end

    elseif self._openEnum == ModelVideoCenter.OpenEnumArena then
        local combatExtraDatas = self._combatExtraDatas
        --attackPlayer  		= videoInfo:GetAttack()
        --defensePlayer 		= videoInfo:GetDefense()
        -- serverId 			= gLGameLogin:GetActualServerId()
        serverId = videoInfo:GetServerId()

        --extraData.meName 	= attackPlayer:GetName()
        --extraData.otherName = defensePlayer:GetName()
        extraData.videoType = combatExtraDatas.videoType
        extraData.closeAfterVideo = combatExtraDatas.battleEndfun
        extraData.canSkip = combatExtraDatas.canSkip
    elseif self._openEnum == ModelVideoCenter.OpenEnumChampion then
        local combatExtraDatas = self._combatExtraDatas
        --attackPlayer  		= videoInfo:GetAttack()
        --defensePlayer 		= videoInfo:GetDefense()
        serverId = videoInfo:GetServerId()

        --extraData.meName 	= attackPlayer:GetName()
        --extraData.otherName = defensePlayer:GetName()
        extraData.videoType = combatExtraDatas.videoType
        extraData.battleEndfun = combatExtraDatas.battleEndfun
        extraData.canSkip = combatExtraDatas.canSkip
        extraData.round = combatExtraDatas.round
        extraData.playExtraFun = combatExtraDatas.playExtraFun
    end

    extraData.combatType = combatType
    extraData.serverId = serverId
    --extraData.mePlayerServerId = attackPlayer:GetServerId()
    --extraData.otherPlayerServerId = defensePlayer:GetServerId()

    gLFightManager:OnOpenBattleDetails(reportId, extraData, serverId)
end

function UIVdoPop:SetBattleShow(trans, formation, playerId, isMonster, serverId)
    local heroList = {}
    local grids = formation.grids
    for i, v in ipairs(grids) do
        local index = v.index
        heroList[index] = {
            heroData = v,
            playerId = playerId,
            serverId = serverId,
        }
    end

    local heroTrans = CS.FindTrans(trans, "heroList")
    self:SetHeroListInfo(heroTrans, heroList, playerId, isMonster, serverId)
end

function UIVdoPop:InitTreasureList(trans, list)
    local TreasureList = CS.FindTrans(trans, "TreasureList")
    local skillList = CS.FindTrans(trans, "skillList")
    CS.ShowObject(skillList, false)

    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(TreasureList, list, function(...)
            self:OnDrawTreasureCell(...)
        end)
    end
end

function UIVdoPop:OnDrawTreasureCell(list, item, itemdata, itempos)
    local EmptyBg = self:FindWndTrans(item, "EmptyBg")
    local IconBg = self:FindWndTrans(item, "IconBg")
    local Icon = self:FindWndTrans(IconBg, "Icon")
    local isEmpty = itemdata.isEmpty
    local notEmpty = not isEmpty
    CS.ShowObject(EmptyBg, isEmpty)
    CS.ShowObject(IconBg, notEmpty)
    if notEmpty then
        local skillRefId = itemdata.skillRefId
        local info = gModelSkill:GetSkillRef(skillRefId)
        local has = false
        if info then
            has = true
            self:SetWndEasyImage(IconBg, info.iconBg, nil, true)

            --local iconPath = gModelTreasure:GetTreasureIconByRefId(info.refId, itemdata.exhibitionInfo and itemdata.exhibitionInfo.skin or nil)
            local iconPath = info.icon
            self:SetWndEasyImage(Icon, iconPath, nil, true)
        end
        CS.ShowObject(IconBg, has)

        self:SetWndClick(item, function()
            --gModelGeneral:ShowTacticTips(skillRefId)
            local ref, upRef = gModelDraconic:GetDraconicRefBySkillId(skillRefId)
            GF.OpenWnd("UIDraconicUpStar", { refId = upRef.type, starNum = upRef.rankNow, tips = true })
            --
            --gModelGeneral:OpenSkillWnd({curSkillId = skillRefId,wndType = 2})
            --gModelGeneral:OpenOnlyTreasureTip({ treasureData = itemdata.exhibitionInfo })
        end)
    end
end

function UIVdoPop:SetHeroListInfo(trans, heroGridList, playerId, isMonster, serverId)
    local girds = {
        --7,4,1,8,5,2,9,6,3
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10
    }
    for i, v in ipairs(girds) do
        local transName = tostring(v)
        local heroTrans = self:FindWndTrans(trans, transName)
        if heroTrans then
            self:SetHeroInfo(heroTrans, heroGridList[i], playerId, isMonster, serverId)
        end
    end
end

------------------------------------------------------------------
return UIVdoPop


