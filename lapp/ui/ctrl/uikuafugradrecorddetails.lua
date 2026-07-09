---
--- Created by LCM.
--- DateTime: 2024/3/16 16:28:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuGradRecordDetails:LWnd
local UIKuafuGradRecordDetails = LxWndClass("UIKuafuGradRecordDetails", LWnd)

UIKuafuGradRecordDetails.FORMATION_INFO = {
    --7,4,1,8,5,2,9,6,3
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10
}
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuGradRecordDetails:UIKuafuGradRecordDetails()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuGradRecordDetails:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuGradRecordDetails:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuGradRecordDetails:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:SetWndText(self.mLblBiaoti, ccClientText(21816))
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshView()
end

function UIKuafuGradRecordDetails:SetBattleShow(trans, formation)
    if not formation then
        return
    end
    local TreasureList = self:FindWndTrans(trans, "TreasureList")
    local HeroSortDiv = self:FindWndTrans(trans, "Bg/HeroSortDiv")

    local combatUnits = formation.combatUnits or {}
    local combatUnitsList = combatUnits[1] or {}
    local campSkillIdList = combatUnitsList.data or {}
    local skillList = campSkillIdList.skillList or {}

    local dataList = {}
    for _, v in ipairs(skillList) do
        if v.skillRefId > 0 then
            dataList[v.index] = v
        end
    end

    local treasureList = {}
    for k = 1, 4 do
        local data = dataList[k]
        if not data then
            data = {
                isEmpty = true
            }
        end
        table.insert(treasureList, data)
    end
    self:InitTreasureList(TreasureList, treasureList)

    local playerId = formation.playerId
    local serverId = playerId == self._attackPlayerId and self._attackServerId or self._defenseServerId
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
    self:SetHeroListInfo(HeroSortDiv, heroList)
end

function UIKuafuGradRecordDetails:InitMsg()
    --[[	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
        end)]]
end

function UIKuafuGradRecordDetails:OnDrawDisRecordCell(list, item, itemdata, itempos)
    local SimpleInfo = self:FindWndTrans(item, "SimpleInfo")
    local GroupTxt = self:FindWndTrans(SimpleInfo, "GroupTxt")
    local ZKBtn = self:FindWndTrans(SimpleInfo, "ZKBtn")
    local SQBtn = self:FindWndTrans(SimpleInfo, "SQBtn")
    local Image = self:FindWndTrans(SimpleInfo, "Image")
    local DetailInfo = self:FindWndTrans(item, "DetailInfo")
    local AttackPowerDiv = self:FindWndTrans(DetailInfo, "AttackPowerDiv")
    local DefensePowerDiv = self:FindWndTrans(DetailInfo, "DefensePowerDiv")

    local isLeft = self._isLeft or false

    local reportPowerTransList = self._reportPowerTransList
    if not reportPowerTransList then
        reportPowerTransList = {}
        self._reportPowerTransList = reportPowerTransList
    end

    local index = itemdata.index
    local reportId = itemdata.reportId

    local reportPowerTrans = reportPowerTransList[reportId]
    if not reportPowerTrans then
        reportPowerTrans = {}
        reportPowerTransList[reportId] = reportPowerTrans
    end



    local groupStr = string.replace(ccClientText(21817), itemdata.index)
    self:SetWndText(GroupTxt, groupStr)

    local isAttackWin = itemdata.winner
    if AttackPowerDiv then
        local WinImg = self:FindWndTrans(AttackPowerDiv, "WinImg")
        local FailImg = self:FindWndTrans(AttackPowerDiv, "FailImg")
        local textTrans = self:FindWndTrans(AttackPowerDiv, "PowerShow/TextDiv/text")
        --[[		local powerStr = LUtil.PowerNumberCoversion(itemdata.attackPower)
                self:SetWndText(textTrans,powerStr)]]

        reportPowerTrans.attackPowerTrans = textTrans

        CS.ShowObject(WinImg, isAttackWin)
        CS.ShowObject(FailImg, not isAttackWin)
    end

    if DefensePowerDiv then
        local WinImg = self:FindWndTrans(DefensePowerDiv, "WinImg")
        local FailImg = self:FindWndTrans(DefensePowerDiv, "FailImg")
        local textTrans = self:FindWndTrans(DefensePowerDiv, "PowerShow/TextDiv/text")
        --[[		local powerStr = LUtil.PowerNumberCoversion(itemdata.defensePower)
                self:SetWndText(textTrans,powerStr)]]

        reportPowerTrans.defensePowerTrans = textTrans

        CS.ShowObject(WinImg, not isAttackWin)
        CS.ShowObject(FailImg, isAttackWin)
    end

    self:SetWndClick(ZKBtn, function()
        self:HideZB(index, ZKBtn, SQBtn, DetailInfo)
    end)
    self:SetWndClick(SQBtn, function()
        self:ShowZB(index, ZKBtn, SQBtn, DetailInfo, itemdata)
    end)

    local isShow = self._reportShowIndexList[index]
    if isShow == nil then
        isShow = false
        self._reportShowIndexList[index] = isShow
    end

    if isShow then
        self:ShowZB(index, ZKBtn, SQBtn, DetailInfo, itemdata, true)
    end

    self:SetWndClick(Image, function()
        local faceShow = not self._reportShowIndexList[index]
        if faceShow then
            self:ShowZB(index, ZKBtn, SQBtn, DetailInfo, itemdata)
        else
            self:HideZB(index, ZKBtn, SQBtn, DetailInfo)
        end
    end)

    CS.ShowObject(ZKBtn, isShow)
    CS.ShowObject(SQBtn, not isShow)


end

function UIKuafuGradRecordDetails:SetBattleInfo(trans, data, playerInfo, isAttack)
    if not trans or not CS.IsValidObject(trans) then
        return
    end
    if not data then
        return
    end
    if not playerInfo then
        return
    end

    local Head = self:FindWndTrans(trans, "Head")
    local HeadIconTrans = self:FindWndTrans(Head, "HeadIcon")
    local PlayerName = self:FindWndTrans(trans, "PlayerName")
    local Power = self:FindWndTrans(trans, "Power")
    local RankImg = self:FindWndTrans(trans, "RankImg")
    local ScoreName = self:FindWndTrans(trans, "ScoreName")

    local score, rank
    local crossGradingInfo = self._crossGradingInfo
    local pname
    if crossGradingInfo then
        pname = playerInfo:GetPlayerName()
        score = self._isLeft and crossGradingInfo.scoreA or crossGradingInfo.scoreB
        rank = self._isLeft and crossGradingInfo.nowScoreA or crossGradingInfo.nowScoreB
    else
        pname = playerInfo:GetName()
        score = playerInfo:GetScore()
        rank = playerInfo:GetRank()
    end
    self:SetWndText(PlayerName, pname)

    --移除高阶段位赛
    -- if(gModelHighStageRace:IsHighStageRace(self._combatType))then
    -- 	local lvl = isAttack and self._report.rankA or self._report.rankB
    -- 	local crossGradingHighRef = gModelHighStageRace:GetConfigByTypeAndKey(ModelHighStageRace.Interval,tonumber(lvl))
    -- 	if crossGradingHighRef then
    -- 		local icon = crossGradingHighRef.icon
    -- 		self:SetWndEasyImage(RankImg,icon,nil,true)
    -- 		local name = ccLngText(crossGradingHighRef.name)
    -- 		self:SetWndText(ScoreName,name)
    -- 	end
    -- else
    local crossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(score, rank)
    if crossGradingRef then
        local icon = crossGradingRef.icon
        self:SetWndEasyImage(RankImg, icon, nil, true)
        local name = ccLngText(crossGradingRef.name)
        self:SetWndText(ScoreName, name)
    end
    -- end

    local power = LUtil.PowerNumberCoversion(playerInfo:GetPower())
    self:SetWndText(Power, power)

    local InstanceID = trans:GetInstanceID()
    local playerIcon, playerHeadFrame, playerLevel

    if crossGradingInfo then
        playerIcon = playerInfo:GetPlayerHead()
        playerHeadFrame = playerInfo:GetPlayerFrame()
        playerLevel = playerInfo:GetPlayerLevel()
    else
        playerIcon = playerInfo:GetHead()
        playerHeadFrame = playerInfo:GetHeadFrame()
        playerLevel = playerInfo:GetGrade()
    end
    local headData = {
        trans = HeadIconTrans,
        icon = playerIcon,
        headFrame = playerHeadFrame,
        name = pname,
        level = playerLevel,
    }
    local baseClass = self:GetHeadIcon(InstanceID)
    baseClass:SetHeadData(headData)
end

function UIKuafuGradRecordDetails:ShowZB(index, ZKBtnTrans, SQBtnTrans, DetailInfo, itemdata, init)
    local newStatus
    if not init then
        newStatus = self:GetReportStatus(index)
        CS.ShowObject(ZKBtnTrans, newStatus)
        CS.ShowObject(SQBtnTrans, not newStatus)
    else
        newStatus = init
    end

    CS.ShowObject(DetailInfo, newStatus)
    if newStatus then
        local reportId = itemdata.reportId
        local AttackDiv = self:FindWndTrans(DetailInfo, "AttackDiv")
        local DefenseDiv = self:FindWndTrans(DetailInfo, "DefenseDiv")
        local VedioBtn = self:FindWndTrans(DetailInfo, "VedioBtn")
        local VedioName = self:FindWndTrans(VedioBtn, "VedioName")
        self:SetWndText(VedioName, ccClientText(17001))
        local reportInfo = {
            reportId = reportId,
            serverId = itemdata.serverId,
            callback = function(reportTable)
                self:SetBattleData(AttackDiv, DefenseDiv, reportTable, reportId)

                self:SetWndClick(VedioBtn, function()
                    local report = self._report
                    local viewType = self._viewType
                    local returnCallFunc = self._returnCallFunc
                    local func = returnCallFunc or function()
                        GF.OpenWndBottom("UIKuafuGradRecord", { viewType = viewType })
                    end
                    local crossGradingInfo = self._crossGradingInfo
                    local combatType = self._combatType--LCombatTypeConst.COMBAT_CROSSGRADING_RANK
                    local battleEndfun = function()
                        if not crossGradingInfo then
                            local returnFunc = gModelBattle:GetReturnFun(combatType)
                            if returnFunc then
                                returnFunc()
                            end
                        end
                        if func then
                            func()
                        end
                        local para = {
                            report = report,
                            crossGradingInfo = crossGradingInfo,
                            viewType = viewType,
                            returnCallFunc = returnCallFunc,
                            combatType = combatType,
                        }
                        GF.OpenWnd("UIKuafuGradRecordDetails", para)
                    end
                    local combatExtraData = {}
                    --combatExtraData.meName = self._attackName
                    --combatExtraData.otherName = self._defenseName
                    combatExtraData.isNew = true
                    combatExtraData.skip = true
                    combatExtraData.combatType = combatType
                    combatExtraData.serverId = self._serverId
                    combatExtraData.battleEndfun = battleEndfun
                    combatExtraData.videoType = LVideoTypeConst.CROSS_GRADING

                    gModelGeneral:RecordGameState()
                    gLFightManager:OnPlayBattleVideo(reportId, combatExtraData)

                end)
            end
        }
        self:GetReportTable(reportInfo)
    end
    local uiRecordList = self._uiRecordList
    if uiRecordList then
        uiRecordList:MoveToPos(index)
    end
end

function UIKuafuGradRecordDetails:SetDivInfo(trans, itemdata, divType)
    local WinImg = self:FindWndTrans(trans, "WinImg")
    local FailImg = self:FindWndTrans(trans, "FailImg")

    local PowerTxt = self:FindWndTrans(trans, "PowerShow/TextDiv/text")

    local TreasureList = self:FindWndTrans(trans, "TreasureList")
    local treasureList = {}
    self:InitTreasureList(TreasureList, treasureList)

    local HeroSortDiv = self:FindWndTrans(trans, "Bg/HeroSortDiv")
    local heroGridList = {}
    self:SetHeroListInfo(HeroSortDiv, heroGridList)

    local VedioBtn = self:FindWndTrans(trans, "VedioBtn")
    self:SetWndClick(VedioBtn, function()
        self:ClickVideoFunc()
    end)
end
----------------------------------------------- 旧界面方法 -----------------------------------------------
function UIKuafuGradRecordDetails:OnDrawRecordCell(list, item, itemdata, itempos)
    local AttackDiv = self:FindWndTrans(item, "AttackDiv")
    self:SetDivInfo(AttackDiv, itemdata, ModelCrossGrading.ATTACK_TYPE)

    local DefenseDiv = self:FindWndTrans(item, "DefenseDiv")
    self:SetDivInfo(DefenseDiv, itemdata, ModelCrossGrading.DEFEND_TYPE)
end

function UIKuafuGradRecordDetails:InitTreasureList(trans, list)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawTreasureCell(...)
        end)
    end
end

function UIKuafuGradRecordDetails:SetHeroListInfo(trans, heroGridList)
    for i, v in ipairs(UIKuafuGradRecordDetails.FORMATION_INFO) do
        local transName = "pos" .. v
        local heroTrans = self:FindWndTrans(trans, transName)
        if heroTrans then
            self:SetHeroInfo(heroTrans, heroGridList[i])
        end
    end
end

function UIKuafuGradRecordDetails:RefreshReportInfo()
    local report = self._report
    if not report then
        return
    end
    local isLeft = self._isLeft or false
    local crossGradingInfo = self._crossGradingInfo
    local attack = isLeft and report.attack or report.defense
    local defense = isLeft and report.defense or report.attack
    if crossGradingInfo then
        attack = isLeft and crossGradingInfo:GetAttackPlayer() or crossGradingInfo:GetDefensePlayer()
        defense = isLeft and crossGradingInfo:GetDefensePlayer() or crossGradingInfo:GetAttackPlayer()
    end

    self:SetBattleInfo(self.mAttackDiv, report, attack, true)
    self:SetBattleInfo(self.mDefenseDiv, report, defense, false)

    local reportShowIndexList = self._reportShowIndexList
    local isFull = not reportShowIndexList
    if isFull then
        reportShowIndexList = {}
        self._reportShowIndexList = reportShowIndexList
    end
    local reportPowerTransList = self._reportPowerTransList
    if not reportPowerTransList then
        reportPowerTransList = {}
        self._reportPowerTransList = reportPowerTransList
    end

    local serverId = report.serverId
    local attackPower = attack:GetPower()
    local defensePower = defense:GetPower()
    local reportList = {}
    local winnerNumber = report.winnerNumber
    for i, v in ipairs(report.reportIdList or {}) do
        local winNum = winnerNumber[i] or ModelCrossGrading.DEFEND_TYPE
        local isShow = i == 1 and true or false

        if isFull then
            self._reportShowIndexList[i] = isShow
        end

        local win
        if self._isLeft then
            win = winNum == ModelCrossGrading.ATTACK_TYPE and true or false
        else
            win = winNum == ModelCrossGrading.DEFEND_TYPE and true or false
        end

        table.insert(reportList, {
            reportId = v,
            index = i,
            winner = win,
            attackPower = attackPower,
            defensePower = defensePower,
            serverId = serverId,
        })
    end
    self:InitRecordList(reportList)
end

function UIKuafuGradRecordDetails:SetBattleData(attackDiv, defenseDiv, reportTable, reportId)
    local isLeft = self._isLeft

    local reportData = LFightReportData:New()
    reportData:CreateNoRound(reportTable)

    local formationA = isLeft and reportData.formationA or reportData.formationB
    local powerA = LUtil.PowerNumberCoversion(formationA.power)
    self:SetBattleShow(attackDiv, formationA)

    local formationB = isLeft and reportData.formationB or reportData.formationA
    local powerB = LUtil.PowerNumberCoversion(formationB.power)
    self:SetBattleShow(defenseDiv, formationB)

    local reportPowerTransList = self._reportPowerTransList
    if not reportPowerTransList then
        return
    end
    local reportPowerTrans = reportPowerTransList[reportId]
    if not reportPowerTrans then
        return
    end

    local attackPowerTrans = reportPowerTrans.attackPowerTrans
    if not attackPowerTrans or not CS.IsValidObject(attackPowerTrans) then
        return
    end
    self:SetWndText(attackPowerTrans, powerA)

    local defensePowerTrans = reportPowerTrans.defensePowerTrans
    if not defensePowerTrans or not CS.IsValidObject(defensePowerTrans) then
        return
    end
    self:SetWndText(defensePowerTrans, powerB)
end

function UIKuafuGradRecordDetails:RefreshView()
    local report = self._report
    if not report then
        return
    end
    self:RefreshReportInfo()
end

function UIKuafuGradRecordDetails:SetHeroInfo(trans, data)
    local CommonUI = self:FindWndTrans(trans, "CommonUI")
    local Icon = self:FindWndTrans(CommonUI, "Icon")

    local showIcon = data ~= nil
    if showIcon then
        local playerId = data.playerId
        local serHeroData = data.heroData

        local id = serHeroData.id
        local refId = serHeroData.refId
        local star = serHeroData.star
        local level = serHeroData.level
        local resonance = serHeroData.resonance
        local skin = serHeroData.skinId
        local power = serHeroData.fightPower
        local grade = serHeroData.grade

        local instance = Icon:GetInstanceID()
        local baseClass = self:GetCommonIcon(instance)
        baseClass:Create(Icon)
        local heroData = {}
        heroData.trans = Icon
        heroData.id = id
        heroData.refId = refId
        heroData.star = star
        heroData.level = level
        heroData.isResonance = resonance
        heroData.skin = skin
        heroData.power = power,
        baseClass:SetHeroDataSet(heroData)
        baseClass:DoApply()

        self:SetWndClick(CommonUI, function()
            local heroInfo = {
                id = id,
                refId = refId,
                level = level,
                star = star,
                grade = grade,
                fightPower = power,
                isResonance = resonance,
                skin = skin,
            }
            gModelHero:ReqShowHeroTipEx({ playerId = playerId, heroData = heroInfo, serverId = data.serverId })
            --gModelHero:ReqShowHeroTip(playerId,heroInfo)
        end)
    end
    CS.ShowObject(Icon, showIcon)
end

function UIKuafuGradRecordDetails:GetReportStatus(index)
    local reportShowIndexList = self._reportShowIndexList
    if not reportShowIndexList then
        reportShowIndexList = {}
        self._reportShowIndexList = reportShowIndexList
    end

    local curStatus = reportShowIndexList[index] or false
    local newStatus = not curStatus
    reportShowIndexList[index] = newStatus

    return newStatus
end
----------------------------------------------- 旧界面方法 -----------------------------------------------

function UIKuafuGradRecordDetails:ClickVideoFunc()

end

function UIKuafuGradRecordDetails:InitRecordList(list)
    list = list or {}
    local uiRecordList = self._uiRecordList
    if uiRecordList then
        uiRecordList:RefreshList(list)
    else
        uiRecordList = self:GetUIScroll("uiRecordList")
        self._uiRecordList = uiRecordList
        --uiRecordList:Create(self.mRecordList,list,function(...) self:OnDrawRecordCell(...) end,UIItemList.WRAP)
        uiRecordList:Create(self.mRecordList, list, function(...)
            self:OnDrawDisRecordCell(...)
        end)
        uiRecordList:EnableScroll(true)
    end
end

function UIKuafuGradRecordDetails:InitData()
    local report = self:GetWndArg("report")
    self._report = report

    self._viewType = self:GetWndArg("viewType")

    self._returnCallFunc = self:GetWndArg("returnCallFunc")

    self._crossGradingInfo = self:GetWndArg("crossGradingInfo")
    self._combatType = self:GetWndArg("combatType")
    if (self._crossGradingInfo and self._crossGradingInfo._combatType) then
        self._combatType = self._crossGradingInfo._combatType
    end
    local attackName, defenseName = "", ""
    local attackPlayerId, defensePlayerId = "", ""
    local attackServerId, defenseServerId
    if report then
        local crossGradingInfo = self._crossGradingInfo
        local attack = report.attack
        local defense = report.defense
        if crossGradingInfo then
            attack = crossGradingInfo:GetAttackPlayer()
            defense = crossGradingInfo:GetDefensePlayer()

            attackName = attack:GetPlayerFrame()
            defenseName = defense:GetPlayerFrame()
            attackPlayerId = attack:GetPlayerId()
            defensePlayerId = defense:GetPlayerId()
            attackServerId = attack:GetServerId()
            defenseServerId = defense:GetServerId()
        else
            attackName = attack:GetName()
            defenseName = defense:GetName()
            attackPlayerId = attack:GetPlayerId()
            defensePlayerId = defense:GetPlayerId()
            attackServerId = attack:GetServerId()
            defenseServerId = defense:GetServerId()
        end

        local myPlayerId = gModelPlayer:GetPlayerId()
        self._isLeft = attackPlayerId == myPlayerId

        self._serverId = report.serverId
    end
    self._attackName = attackName
    self._defenseName = defenseName

    self._attackPlayerId = attackPlayerId
    self._defensePlayerId = defensePlayerId

    self._attackServerId = attackServerId
    self._defenseServerId = defenseServerId

end

function UIKuafuGradRecordDetails:HideZB(index, ZKBtnTrans, SQBtnTrans, DetailInfo)
    local newStatus = self:GetReportStatus(index)
    CS.ShowObject(ZKBtnTrans, newStatus)
    CS.ShowObject(SQBtnTrans, not newStatus)
    CS.ShowObject(DetailInfo, newStatus)
end

function UIKuafuGradRecordDetails:OnDrawTreasureCell(list, item, itemdata, itempos)
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
            --gModelGeneral:OpenOnlyTreasureTip({ treasureData = itemdata.exhibitionInfo })
            local ref, upRef = gModelDraconic:GetDraconicRefBySkillId(skillRefId)
            GF.OpenWnd("UIDraconicUpStar", { refId = upRef.type, starNum = upRef.rankNow, tips = true })
        end)
    end
end

function UIKuafuGradRecordDetails:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end
------------------------------------------------------------------
return UIKuafuGradRecordDetails


