---
--- Created by Administrator.
--- DateTime: 2023/10/1 14:53:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMultiFightPre:LWnd
local UIMultiFightPre = LxWndClass("UIMultiFightPre", LWnd)

local YXTouchManager = CS.YXTouchManager

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMultiFightPre:UIMultiFightPre()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMultiFightPre:OnWndClose()

    FireEvent(EventNames.BATTLE_MAP_OFFSET, 0)
    self:ReleaseTouchEvent()

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMultiFightPre:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMultiFightPre:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:SetStaticContent()
    self:InitMultiTeamPart()
    self:InitEvent()
    self:InitUIEvent()
    self:InitTouchEvent()

    self._isUsePlayerTreasureInfo = true
    local isOpenDivine = gModelFunctionOpen:CheckAreaOpen(36000000)
    CS.ShowObject(self.mFormationDivineSkill,isOpenDivine)
    self:InitUIShow(false)

    local exceptWnds = {
        ["UIMultiFightPre"] = true,
        ["UIGuePost"] = true,
    }
    gLGameUI:CloseAllButExcept(exceptWnds)

    self:RefreshBtnTipShow()

    self:OnWndRefresh()
end

function UIMultiFightPre:GetCurTreasureList()
    local operData = self._multiTeamOperData[self._curTeam]
    return operData.treasureIdList
end

function UIMultiFightPre:OnClickCareerTypeFunc(refId)
    if self._careerType == refId then
        return
    end
    self._careerType = refId
    --self:RefreshBtnEvent()
    --self:RefreshMultiTeamHeroList()
    self:RefreshMultiHeroList()
    local uiCareerTypeList = self._uiCareerTypeList
    if not uiCareerTypeList then
        return
    end
    local uiList = uiCareerTypeList:GetList()
    uiList:RefreshList()
end

function UIMultiFightPre:GetBossTowerSid()
    -- local extraData = self:GetBattleExtraData()
    -- if extraData then
    -- 	return extraData.sid
    -- end
end
function UIMultiFightPre:OnClickDivineSet()
    if gModelFormation:CheckDivineNotUse(self._combatType, true) then
        return
    end

    local teamIndex = self._curTeam

    local operData = self._multiTeamOperData[teamIndex]
    local divineWeaponStarRefIds = {}
    for k, v in pairs(operData.divineWeaponStarIdList) do
        divineWeaponStarRefIds[k] = v
    end

    local idRecord = {}
    for k, v in pairs(self._multiTeamOperData) do
        if k ~= self._curTeam then
            for k1, v1 in pairs(v.divineWeaponStarIdList) do
                idRecord[v1] = k + 1
            end
        end
    end

    local para = {
        wndType = 2,
        combatType = self._combatType,
        divineStarRefIds = divineWeaponStarRefIds,
        teamIndex = teamIndex,
        func = function(list)
            FireEvent(EventNames.REFRESH_CUR_TEAM_DIVINE, list, teamIndex)
        end,
        idRecord = idRecord,
    }

    GF.OpenWnd("UISelFightGodWeapon", para)

end

function UIMultiFightPre:GetNoShowRaceList()
    local list = {}
    return list
end

function UIMultiFightPre:ShowRightPart()
    local monsterId = self:GetRightMonster()
    if not monsterId then
        return
    end

    local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterId)
    if monsterFormationRef then
        local otherName
        -- if self:IsBossTowerCombat() then
        -- 	local bossId = self:GetBossTowerBossId()
        -- 	local monsterIndex = self._curTeam + 1
        -- 	otherName = gModelBattle:GetOtherName({combatType = self._combatType,monsterIndex = monsterIndex,bossId = bossId,})
        -- else
        otherName = gModelBattle:GetOtherName({ combatType = self._combatType })
        -- end
        self:SetWndText(self.mOtherName, otherName)
        gModelFormation:OnMonsterPowerReq({ monsterId })
    end
    --移除高阶段位赛
    -- if(gModelHighStageRace:IsHighStageRace(self._combatType))then
    -- 	local otherName = self._extraData.otherName
    -- 	if(self._combatType == LCombatTypeConst.COMBAT_TYPE_36)then
    -- 		local pbCrossGradingHighInfo = gModelHighStageRace:GetCrossGradingHighInfo()
    -- 		local level = pbCrossGradingHighInfo.level
    -- 		local intervalCfg = gModelHighStageRace:GetConfigByTypeAndKey(ModelHighStageRace.Interval,level)
    -- 		local monster = intervalCfg.monster
    -- 		local monsterFormationIdArr = string.split(monster,",")
    -- 		local monsterId = monsterFormationIdArr[1]
    -- 		local showMonsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterId)
    -- 		otherName = ccLngText(showMonsterFormationRef.name)
    -- 	end
    -- 	self:SetWndText(self.mOtherName,otherName)
    -- end

    local refIdList = self:GetRightRefIdList(false)
    self:ShowBuffStatus(false, refIdList)

    -- self:ShowRightTreasure()
end

---0 未上阵，1 本队上阵，2 别队上阵
function UIMultiFightPre:IsMultiHeroSelect(heroId)
    if not self._multiTeamOperData then
        return 0
    end

    for k, v in pairs(self._multiTeamOperData) do
        local idToIndex = v.idToIndex
        if not idToIndex then
            break
        end
        if idToIndex[heroId] then
            if self._curTeam == k then
                return 1, k
            else
                return 2, k
            end
        end
    end

    return 0

end

function UIMultiFightPre:IsCloseBattle()
    -- local skipBattle = self:GetBossTowerSkipBattle()
    -- if not skipBattle then return end
    -- local combatType = self._combatType
    -- if combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerFightType") then
    -- 	FireEvent(EventNames.CHANGE_MAIN_BTN,1)
    -- 	self:WndClose()
    -- 	GF.ChangeMap("LCityMap")

    -- end
end

function UIMultiFightPre:RefreshOperData(operData)
    local isBossTower = false
    local indexToId = {}
    local cnt = 0
    for k, v in pairs(operData.idToIndex) do
        local key = isBossTower and tonumber(v) or v
        indexToId[key] = isBossTower and tonumber(k) or k
        cnt = cnt + 1
    end

    operData.indexToId = indexToId
    operData.cnt = cnt

    self:RefreshTeamBtnShow()
end

function UIMultiFightPre:SetEnemyCombatData(enemyHeroData)
    self:ShowEnemyBuffStatus(enemyHeroData)
    if enemyHeroData.power then
        self:SetEnemyPower(enemyHeroData.power)
    end

    self:ShowEnemyTreasure(enemyHeroData)

    FireEvent(EventNames.REFRESH_ENEMY_HERO_SHOW, enemyHeroData)
end

function UIMultiFightPre:RefreshRightPower(monsterId, power)
    local curmonsterId = self:GetRightMonster()
    if curmonsterId ~= monsterId then
        return
    end

    local str = LUtil.FormatPowerShowStr(power)
    self:SetWndText(self.mOtherFightNum, str)
end

function UIMultiFightPre:InitEvent()
    self:WndEventRecv(EventNames.Scene_Hero_Down, function(...)
        self:SceneHeroDownMulti(...)
    end)
    self:WndEventRecv(EventNames.Swap_Hero_Info, function(...)
        self:SceneHeroSwapMulti(...)
    end)
    self:WndEventRecv(EventNames.ON_GET_FORMATION_LIST_RET, function(...)
        self:OnMultiFormationDataRet()
    end)

    local pbId = LProtoHelper.GetProtoId("GetFormationListResp")
    self:WndEventRecv(EventNames.NET_ERROR_CODE, function(msgId, error, args, errorStr)
        if pbId == msgId then
            self:OnMultiFormationDataRet()
        end
    end)

    self:WndEventRecv(EventNames.ON_BATTLE_FORMATION_END, function(newIndex, oldIndex)
        self:OnExchangeTeam(newIndex, oldIndex)
    end)

    self:WndNetMsgRecv(LProtoIds.MonsterPowerResp, function(pb)
        local powerData = pb.powerData
        local data = powerData[1]
        self:RefreshRightPower(data.monsterId, data.power)
    end)
    self:WndNetMsgRecv(LProtoIds.GetFormationShowResp, function(pb)
        local targetId = self._extraData.playerId
        if pb.targetId ~= targetId or (pb.teamIndex ~= self._curTeam) then
            return
        end
        local power = pb.heroData.power or 0
        power = tonumber(power)
        local heroData = pb.heroData
        local combatHeroData = gModelGeneral:SetCombatHeroData(heroData)
        local heroData = {}
        heroData.playerId = pb.playerId
        -- heroData.artifactId = pb.artifactId【G公共支持】删除神器功能相关数据
        heroData.power = power
        local formationRefId = combatHeroData._formationRefId
        local heros = combatHeroData._heros
        local grids = combatHeroData._grids
        heroData.matrixRefId = formationRefId
        heroData.combatTreasures = combatHeroData:GetSkillInfo()
        local prefabNameList = {}
        for k, v in ipairs(heros) do
            local grid = grids[k]
            local pos = gModelFormation:GetIndexByPos(formationRefId, grid)
            local refId = v.refId
            local star = v.star
            local skin = v.skin
            local prefabName, needFlip = gModelHero:GetHeroDisplay(refId, star, skin, true, v.form)

            local bottomImg = gModelHero:GetHeroBottomImgByRefId(refId)
            local race = gModelHero:GetHeroRace(refId)
            local data = {
                prefabName = prefabName,
                bottomImg = bottomImg,
                refId = refId,
                lv = v.lv,
                pos = pos,
                race = race,
                isResonance = v.isResonance,
                skin = v.skin,
                needFlip = needFlip,
                star = star
            }
            prefabNameList[pos] = data
        end
        heroData.prefabNameList = prefabNameList
        self._emenyHeroDataList[pb.teamIndex] = heroData
        if (pb.teamIndex == self._curTeam) then
            self:SetEnemyCombatData(heroData)
        end
    end)

    -- self:WndNetMsgRecv(LProtoIds.BossTowerFormationPowerResp, function(pb)
    -- 	local activity = self:GetBossTowerSid()
    -- 	if not activity then return end
    -- 	if activity ~= pb.sid then return end
    -- 	local power = pb.power
    -- 	self:RefreshBossTowerPower(power)
    -- end)

    -- self:WndNetMsgRecv(LProtoIds.BossTowerDataInfoResp, function(pb)
    -- 	local isBossTower = self:IsBossTowerCombat()
    -- 	if not isBossTower then return end
    -- 	self:RefreshMultiHeroList()
    -- end)

    self:WndEventRecv(EventNames.ON_HERO_LIST_CHANGE, function()
        self:RefreshMultiHeroList()
    end)

    self:WndEventRecv(EventNames.REFRESH_OTHER_TEAM_HERO, function(...)
        self:OnOtherTeamHeroChange(...)
    end)
    self:WndEventRecv(EventNames.REFRESH_OTHER_TEAM_TREA, function(...)
        self:OnOtherTeamTreaChange(...)
    end)
    self:WndEventRecv(EventNames.REFRESH_OTHER_TEAM_DIVINE, function(...)
        self:OnOtherTeamDivineChange(...)
    end)

    self:WndEventRecv(EventNames.REFRESH_CUR_TEAM_TREA, function(...)
        self:OnCurTeamTreaChange(...)
    end)
    self:WndEventRecv(EventNames.REFRESH_CUR_TEAM_DIVINE, function(...)
        self:OnCurTeamDivineChange(...)
    end)

end

function UIMultiFightPre:OnDrawDivineIconCell(list, item, itemdata, itempos)
    local Icon = self:FindWndTrans(item, "Icon")
    local AddImg = self:FindWndTrans(item, "AddImg")
    local LockImg = self:FindWndTrans(item, "LockImg")

    local starRefId = itemdata.refId
    local index = itemdata.index

    local isOpen = false
    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        isOpen = starRefId ~= 0
    else
        isOpen = gModelDivineWeapon:IsSkillOpenByPos(index)

    end

    local isHaveSkill = starRefId ~= 0
    if isHaveSkill then
        local skillid = GameTable.DivineWeaponStarRef[starRefId].skillId
        local skillCfg = GameTable.SnakeSkillRef[skillid]
        self:SetWndEasyImage(Icon, skillCfg.icon)
    end

    if not isOpen then
        CS.ShowObject(Icon, false)
        CS.ShowObject(AddImg, false)
        CS.ShowObject(LockImg, true)
    else
        CS.ShowObject(Icon, isHaveSkill)
        CS.ShowObject(AddImg, not isHaveSkill)
        CS.ShowObject(LockImg, false)
    end

end

function UIMultiFightPre:GetBossTowerBossId()
    -- local extraData = self:GetBattleExtraData()
    -- if extraData then
    -- 	return extraData.bossId
    -- end
end

function UIMultiFightPre:OneKeyUp()

    local operData = self._multiTeamOperData[self._curTeam]
    operData.idToIndex = {}
    operData.treasureIdList = {}
    operData.divineWeaponStarIdList = {}
    -- operData.petFights={}
    -- operData.petHelps={}


    local arrayId = self:GetCurArrayId()

    local idRecord = {}
    local treasureRecord = {}
    local divineRecord = {}

    -- local isBossTower = self:IsBossTowerCombat()

    local isNotUseTreasure = gModelFormation:CheckTreasureNotUse(self._combatType)
    local isNotUseDivine = gModelFormation:CheckDivineNotUse(self._combatType)

    for k, v in pairs(self._multiTeamOperData) do
        for k1, v1 in pairs(v.idToIndex) do
            idRecord[k1] = true
        end

        if not isNotUseTreasure then
            for k1, v1 in pairs(v.treasureIdList) do
                if v1 > 0 then
                    treasureRecord[v1] = true
                end
            end
        end
        if not isNotUseDivine then
            for k1, v1 in pairs(v.divineWeaponStarIdList) do
                if v1 > 0 then
                    divineRecord[v1] = true
                end
            end
        end
    end

    local indexToId
    -- if isBossTower then
    -- 	indexToId = gModelFormation:GetBossTowerMultiOneKey(arrayId,nil,idRecord,nil,self:GetBossTowerSid())
    -- else
    -- local isHighStageRace = gModelHighStageRace:IsHighStageRace(self._combatType)
    -- local lockHeroList
    -- if(isHighStageRace)then
    -- 	lockHeroList = gModelHighStageRace:GetLockHeroList(self._combatType)
    -- end
    indexToId = gModelFormation:GetMultiOneKey(arrayId, nil, idRecord, nil, lockHeroList)
    -- end

    --indexToId = gModelResonance:GetMappingOneKeyList2(indexToId)
    local tmpIndexToId = {}
    for i, v in pairs(indexToId) do
        local otherMappingId = gModelResonance:GetMappingOtherId(v)
        local otherMappingIsSel = false
        if (otherMappingId) then
            local otherMappingSelState, otherMappingTeamIndex = self:IsMultiHeroSelect(otherMappingId)
            otherMappingIsSel = otherMappingSelState ~= 0
        end
        if (not otherMappingIsSel) then
            tmpIndexToId[i] = v
        end
    end
    indexToId = tmpIndexToId

    for k, v in pairs(indexToId) do
        operData.idToIndex[v] = k
    end

    self:RefreshOperData(operData)
    self:RefreshRefIdRecord()

    if operData.cnt == 0 then
        local str = ccClientText(10918) --"当前无伙伴可上阵"
        GF.ShowMessage(str)
    end

    local treasureList = {}
    local pasvList = {}
    if not isNotUseTreasure then
        --treasureList = gModelFormation:OneKeyTreasure(treasureRecord)
        --pasvList = gModelFormation:OneKeyPasvTrea()



        treasureList = gModelDraconic:GetOneKeyFormationRefIdList(treasureRecord)
    end
    local divineList = {}
    if not isNotUseDivine then
        divineList = gModelDivineWeapon:GetOneKeyFormationRefIdList(divineRecord)
    end

    -- 【C宠物系统】删掉宠物系统相关
    -- local petFights,petHelps = self:GetOneKeySetPet()

    operData.treasureIdList = treasureList
    operData.divineWeaponStarIdList = divineList
    operData.pasvList = pasvList
    -- operData.petFights = petFights
    -- operData.petHelps = petHelps


    self:RefreshPasvShow()
    self:RefreshTreasureShow()
    self:RefreshDivineWeaponShow()
    -- self:RefreshPetTreaBtnShow()

    self:RefreshMultiHeroList()
    self:ShowRefIdRelaPart()
    FireEvent(EventNames.ONE_KEY_FORMATION, operData.idToIndex, self:GetBossTowerSid())
end
function UIMultiFightPre:RefreshTeamSel()
    self:RefreshTeamBtnShow()

    self:RefreshGoToBtn()
end

function UIMultiFightPre:GetCurArrayId()
    local operData = self._multiTeamOperData[self._curTeam]
    local arrayId = operData.arrayId or 1
    if arrayId == 0 then
        arrayId = 1
    end

    return arrayId
end

function UIMultiFightPre:SetCurArrayId(arrayId)
    local operData = self._multiTeamOperData[self._curTeam]
    operData.arrayId = arrayId
end

function UIMultiFightPre:RefreshTreasureShow()
    local list = {}
    local treasureSkilIds = self:GetCurTreasureList()

    if not treasureSkilIds then
        treasureSkilIds = {}
    end

    for i = 1, 4 do
        local data = treasureSkilIds[i] or 0
        table.insert(list, {
            refId = data,
            index = i,
        })
    end

    local root = self:FindWndTrans(self.mFormationSkillBtn, "skillList")
    self:CreateUIScrollImpl("activeTrea", root, list, function(...)
        self:OnDrawSkillIconCell(...)
    end)
end

function UIMultiFightPre:SceneHeroSwapMulti(index1, index2)
    local operData = self._multiTeamOperData[self._curTeam]
    local heroId1 = operData.indexToId[index1]
    local heroId2 = operData.indexToId[index2]

    if heroId1 then
        operData.idToIndex[heroId1] = index2
    end

    if heroId2 then
        operData.idToIndex[heroId2] = index1
    end

    self:RefreshOperData(operData)
    self:RefreshRefIdRecord()

    self:RefreshMultiShow()
end

function UIMultiFightPre:OnClickRightBuffBg()
    local refIdList = self:GetRightRefIdList()
    GF.OpenWnd("UIBf", { refIdList = refIdList })
end

function UIMultiFightPre:OnExchangeTeam(newIndex, oldIndex)
    local dataOne = self._multiTeamOperData[newIndex]
    local dataTwo = self._multiTeamOperData[oldIndex]
    self._multiTeamOperData[newIndex] = dataTwo
    self._multiTeamOperData[oldIndex] = dataOne

    if newIndex ~= self._curTeam and oldIndex ~= self._curTeam then
        return
    end

    self:RefreshMultiHeroList()
    self:RefreshCurArrayShow()

    self:RefreshTreasureShow()
    self:RefreshDivineWeaponShow()
    self:RefreshPasvShow()
    -- 【C宠物系统】删掉宠物系统相关
    -- self:RefreshPetTreaBtnShow()

    self:RefreshArrayList()
    self:ShowRefIdRelaPart()
    local operdata = self._multiTeamOperData[self._curTeam]
    FireEvent(EventNames.REFRESH_LEFT_TEMP_HERO, operdata, self:GetBossTowerSid())
end
function UIMultiFightPre:IsMainLineCombat()
    return gModelInstance:IsMainLineCombat(self._combatType)
end

function UIMultiFightPre:InitUIEvent()
    self:SetWndClick(self.mMeBuffBg, function()
        self:OnClickLeftBuffBg()
    end)
    self:SetWndClick(self.mOtherBuffBg, function()
        self:OnClickRightBuffBg()
    end)

    self:SetWndClick(self.mBuffbg, function()
        self:OnClickLeftBuffBg()
    end)
    self:SetWndClick(self.mReturnBtn, function()
        self:OnClickReturn()
    end)

    self:SetWndClick(self.mFormationBtn, function()
        self:PlayShowFormation()
    end)
    self:SetWndClick(self.mFormationSkillBtn, function()
        --self:OnClickOpenTreasureSet()
        self:OnClickTreaSet()

    end)
    self:SetWndClick(self.mFormationDivineSkill, function()
        self:OnClickDivineSet()
    end)
    self:SetWndClick(self.mGoOnBtn, function()
        self:OneKeyUp()
    end)

    self:SetWndClick(self.mBossTowerBtn, function()
        self:OnClickBossTowerBtn()
    end)

    self:SetWndClick(self.mFightBtn, function()
        self:OnClickGotoBtn()
    end)

    self:SetWndClick(self.mBtnExchange, function()
        local targetName = self._extraData and self._extraData.otherName or ""
        GF.OpenWnd("UIAdjstFonPop", {
            combatType = self._combatType,
            fomationList = self._multiTeamOperData,
            bossId = self:GetBossTowerBossId(),
            sid = self:GetBossTowerSid(),
            targetName = targetName,
            emenyHeroDataList = self._emenyHeroDataList,
            extraData = self._extraData,
            teamCnt = self._teamCnt
        })
    end)

    self:SetWndClick(self.mBtnTips, function()
        GF.OpenWnd("UIGuePost", { wndType = 2, notTriggerGuide = true })
    end)

    self:SetWndClick(self.mPasvTrea, function()--divineWeaponStarRefIds
        self:OnClickSetPasv()
    end)

    self:SetWndClick(self.mCloseFormationBg, function()
        self:CloseFormationBg()
    end)
    self:SetWndClick(self.mFormationBg, function()
        self:CloseFormationBg()
    end)

    self:SetWndClick(self.mBtnConfirmFormation, function()
        self:OnClickFormationConfirm()
    end)

    local isOpenCard = gModelFunctionOpen:CheckIsOpened(28000000, false)
    CS.ShowObject(self.mBtnCard, isOpenCard)
    if isOpenCard then
        self:SetWndClick(self.mBtnCard, function()
            GF.OpenWnd("UISorceryCardSpeedSet")
        end)
    end

    self:SetWndClick(self.mUnfoldBtn, function()
        -- 展开按钮
        if not self._showRaceBtnList then
            self._showRaceBtnList = true
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mPackBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mShowAllBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
end

function UIMultiFightPre:OnDrawBossTowerHeroCell(list, item, itemdata, itempos)
    -- local AniRoot = self:FindWndTrans(item,"AniRoot")
    -- local AniRootHero = self:FindWndTrans(AniRoot,"Hero")
    -- local HeroIcon = self:FindWndTrans(AniRootHero,"icon")
    -- local HeroMask = self:FindWndTrans(AniRootHero,"mask")
    -- local maskTips = self:FindWndTrans(HeroMask,"tips")


    -- local heroId = itemdata.heroId

    -- local selState,teamIndex = self:IsMultiHeroSelect(heroId)
    -- local showMask = selState == 2
    -- CS.ShowObject(HeroMask,showMask)
    -- local showLock = false
    -- if showMask then
    -- 	local str = string.replace(ccClientText(21817),teamIndex+1)
    -- 	self:SetWndText(maskTips,str)
    -- else
    -- 	showLock = self:IsHeroForbid(heroId,itemdata.refId)
    -- end
    -- local otherMappingId = gModelResonance:GetMappingOtherId(heroId)
    -- local otherMappingIsSel = false
    -- if(otherMappingId)then
    -- 	local otherMappingSelState,otherMappingTeamIndex = self:IsMultiHeroSelect(otherMappingId)
    -- 	otherMappingIsSel = otherMappingSelState ~= 0 and otherMappingTeamIndex == self._curTeam
    -- end
    -- if(otherMappingIsSel)then
    -- 	showLock = true
    -- end
    -- local InstanceID = item:GetInstanceID()
    -- local baseClass = self:GetCommonIcon(InstanceID)
    -- baseClass:Create(HeroIcon)
    -- local heroData =
    -- {
    -- 	refId = itemdata.refId,
    -- 	star = itemdata.star,
    -- 	level = itemdata.breakLv,
    -- 	showLock= showLock,
    -- 	selected= selState == 1,
    -- }
    -- baseClass:SetHeroDataSet(heroData)
    -- baseClass:DoApply()
    -- self:SetIconClickScale(AniRoot,true)
    -- self:SetWndClick(AniRoot,function()
    -- 	if(otherMappingIsSel)then
    -- 		GF.ShowMessage(ccClientText(38422))
    -- 	else
    -- 		self:OnClickBossTowerHero(heroId)
    -- 	end
    -- end)
end

function UIMultiFightPre:CheckOnReturnSave()
    for k, v in pairs(self._multiTeamOperData) do
        local oldData = self._oldOperData[k]
        if self:HasUnSave(oldData, v) then
            return true
        end
    end

    return false
end

function UIMultiFightPre:InitTouchEvent()
    local op = LGameTouch.TOUCH_UI
    local wndName = self:GetWndName()
    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_START, function(screenPos)
        local touchObject = YXTouchManager.EventSystemRaycastGameObject(screenPos)
        if touchObject then
            local path = LxUiHelper.GetRelativePath(wndName, touchObject.transform)
            if string.find(path, "FormationBtn") or string.find(path, "FormationBg") then
            else
                self:Examine()
            end
        else
            self:Examine()
        end
    end)
end

function UIMultiFightPre:RefreshTeamBtnShow()
    if not self._teamRootList then
        return
    end
    for k, v in ipairs(self._teamRootList) do
        CS.ShowObject(v, true)
        local isSelect = self._curTeam == k - 1

        local off = self:FindWndTrans(v, "off")
        local on = self:FindWndTrans(v, "on")
        local num = self:FindWndTrans(v, "num")
        local offNumImg = self:FindWndTrans(off, "num_img")
        local onNumImg = self:FindWndTrans(on, "num_img")
        CS.ShowObject(off, not isSelect)
        CS.ShowObject(on, isSelect)

        local isEmpty = false
        local operData = self._multiTeamOperData and self._multiTeamOperData[k - 1]
        if operData then
            isEmpty = operData.cnt == 0
        end

        local color = "yellow_2"
        if isSelect then
            color = "black"
        elseif isEmpty then
            color = "lightBlue"
        end

        local str = LUtil.FormatColorStr(self._teamNumStr[k], color)

        self:SetWndEasyImage(offNumImg, self._teamNumOff[k])
        self:SetWndEasyImage(onNumImg, self._teamNumOn[k])
        self:SetWndText(num, str)


    end

    local teamIndex = self._curTeam

    local operData = self._multiTeamOperData[teamIndex]

    if operData then
        self:SetWndText(self.mTxtFormationNum, ccClientText(11001, operData.cnt, self._heroMax))
    else
        self:SetWndText(self.mTxtFormationNum, ccClientText(11001, 0, self._heroMax))
    end


end

function UIMultiFightPre:GetRightRefIdList()
    local monsterId = self:GetRightMonster()
    local refIdList = {}
    local tempList = gModelHero:GetMonsterList(monsterId) or {}
    for k, v in pairs(tempList) do
        table.insert(refIdList, { id = v, isMon = true })
    end

    return refIdList
end

function UIMultiFightPre:ModifyTopUIPos()
    local isBossFight = false

    local pos = isBossFight and Vector3.New(0, 0, 0) or Vector3.New(0, -46, 0)

    self.mBloodRoot.localPosition = pos

    CS.ShowObject(self.mOtherFight, not isBossFight)
    CS.ShowObject(self.mOtherBloodDownDi, not isBossFight)
    CS.ShowObject(self.mOtherName, not isBossFight)

    local scale = isBossFight and Vector3.New(0.9, 0.9, 0.9) or Vector3.one
    local rightSkillPos = isBossFight and Vector3.New(-6, 0, 0) or Vector3.New(-30, -24, 0)

    self.mRightSkill.localPosition = rightSkillPos
    self.mRightSkill.localScale = scale
end

function UIMultiFightPre:OnClickTreaSet()
    if gModelFormation:CheckTreasureNotUse(self._combatType, true) then
        return
    end

    local teamIndex = self._curTeam

    local operData = self._multiTeamOperData[teamIndex]
    local treasureSkilIds = {}
    for k, v in pairs(operData.treasureIdList) do
        treasureSkilIds[k] = v
    end

    local idRecord = {}
    for k, v in pairs(self._multiTeamOperData) do
        if k ~= self._curTeam then
            for k1, v1 in pairs(v.treasureIdList) do
                idRecord[v1] = k + 1
            end
        end
    end

    local para = {
        wndType = 2,
        combatType = self._combatType,
        treasureSkilIds = treasureSkilIds,
        teamIndex = teamIndex,
        func = function(list)
            FireEvent(EventNames.REFRESH_CUR_TEAM_TREA, list, teamIndex)
        end,
        idRecord = idRecord,
    }

    GF.OpenWnd("UISelFightTsure", para)

end

function UIMultiFightPre:SetCurTreasureList(list)
    local operData = self._multiTeamOperData[self._curTeam]
    operData.treasureIdList = list
end

function UIMultiFightPre:OnClickFormationConfirm()
    self:OnSelectFormationType(self._curSelectFormationType)
    CS.ShowObject(self.mFormationBg, false)
    self._showFormation = false
end

function UIMultiFightPre:OnCurTeamTreaChange(list, teamIndex)
    if not self._multiTeamOperData then
        return
    end

    local operData = self._multiTeamOperData[teamIndex]
    if not operData then
        return
    end
    operData.treasureIdList = list
    self:RefreshTreasureShow()
end

function UIMultiFightPre:InitRaceTypeList()
    local noShowRaceList = self:GetNoShowRaceList()
    local data = {
        wndClass = self,
        listTrans = self.mHeroRaceList,
        showType = UIHeroRaceList.TYPE_NORMAL,
        showListBg = true,
        noShowRaceList = noShowRaceList,
        callbackFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            self:TypeBtnEvent(raceType)
        end,
        checkSelFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            return self._raceType == raceType
        end,
    }
    self:GetUIHeroRaceList(data)
end

function UIMultiFightPre:CloseFormationBg()
    CS.ShowObject(self.mFormationBg, false)
    self._showFormation = false
    self._curSelectFormationType = self._formationType
end

function UIMultiFightPre:OnWndRefresh()

    self:InitWndPara()

    self:InitRaceTypeList()
    self:InitCareerTypeList()
    self:ModifyTopUIPos()

    -- 全部隐藏
    for k, v in ipairs(self._teamBtnList) do
        CS.ShowObject(v, false)
    end


    --控件 是一定使用前后两个

    local _combatType = self._combatType
    local teamCnt
    -- if self:IsBossTowerCombat() then
    -- 	local bossId = self:GetBossTowerBossId()
    -- 	teamCnt = gModelBossTower:GetBossTowerTeamCount(bossId,_combatType)
    -- 	printInfoNR("teamCnt = " .. teamCnt)
    if self:IsMainLineCombat() then
        local btnTrans = self.mBtnSkip
        CS.ShowObject(self.mSkipObj, true)
        local diffLvl = gModelInstance:GetMainFightLevelOfDifficulty()
        local isSkip = gModelInstance:GetMainFightDiffLvlSkip(diffLvl, 2)
        self:SetWndToggleValue(btnTrans, isSkip)
        self:SetWndToggleDelegate(btnTrans, function(value)
            local isSkipBool = gModelInstance:SetMainFightDiffLvlSkip(diffLvl, value, 2, true)
            if isSkipBool then
                self._extraData.skipBattle = value
            elseif value then
                self:SetWndToggleValue(btnTrans, not value)
            end
        end)
        local monsterArr = gModelInstance:GetBattlePreMonsterArrByCombatType(_combatType)
        teamCnt = #monsterArr
        if teamCnt < 2 then
            printErrorN("队伍少于两队")
            return
        end
        -- elseif self:IsHighStageRace() then
        -- 	local highInfo = gModelHighStageRace:GetCrossGradingHighInfo()
        -- 	local lvl = highInfo.level
        -- 	lvl = (not lvl or lvl == 0) and 1 or lvl
        -- 	local cfg = gModelHighStageRace:GetConfigByTypeAndKey(ModelHighStageRace.Interval,lvl)
        -- 	if(self._combatType == LCombatTypeConst.COMBAT_TYPE_36)then
        -- 		local monsterListArr = string.split(cfg.monster,"|")
        -- 		local monsterListIndex = highInfo.voteType == 1 and 2 or 1
        -- 		local monsterArr = string.split(monsterListArr[monsterListIndex],",")
        -- 		teamCnt = #monsterArr
        -- 	else
        -- 		teamCnt = gModelHighStageRace:GetTeamCntByVoteType(cfg.team)
        -- 	end
    else
        teamCnt = gModelTower:GetHardTeamCnt()
        if teamCnt < 2 then
            printErrorN("队伍少于两队")
            return
        end
    end

    local oneTeam = teamCnt == 1
    CS.ShowObject(self.mMultiRoot, not oneTeam)

    self._teamCnt = teamCnt

    local teamRootList = {}
    for k = 1, teamCnt - 1 do
        table.insert(teamRootList, self._teamBtnList[k])
    end

    table.insert(teamRootList, self._teamBtnList[5])

    self._teamRootList = teamRootList

    for k, v in ipairs(teamRootList) do
        CS.ShowObject(v, true)
        self:SetWndClick(v, function()
            self:OnClickTeam(k - 1)
        end)
    end

    self:RefreshTeamSel()

    self:ShowTeamFormation()

    self:SetBattleName()
    self:ShowRightPart()




    -- if(self._combatType == LCombatTypeConst.COMBAT_TYPE_37)then
    -- 	local targetId = self._extraData.playerId
    -- 	--gModelPlayer:OnGetFormationShowReq(targetId,self._combatType,self._curTeam)
    -- 	for i = 1, self._teamCnt do
    -- 		gModelPlayer:OnGetFormationShowReq(targetId,LCombatTypeConst.COMBAT_TYPE_35,i-1)
    -- 	end
    -- end
end
-- function UIMultiFightPre:IsHighStageRace()
-- 	return gModelHighStageRace:IsHighStageRace(self._combatType)
-- end

function UIMultiFightPre:GetCombatHeroList()
    local dataList = {}
    -- local sid = self:GetBossTowerSid()
    -- if sid then
    -- 	if self:IsBossTowerCombat() then
    -- 		local bossTowerList = gModelBossTower:GetBossTowerHeroListByKey(sid) or {}
    -- 		for i,v in pairs(bossTowerList) do
    -- 			local ref = gModelBossTower:GetBossTowerHeroRefByRefId(v.refId)
    -- 			local monsterRefId = ref.attr
    -- 			local monsterRef = gModelHero:GetMonsterAttrByRefId(monsterRefId)
    -- 			local race = gModelHero:GetMonsterRace(monsterRefId)
    -- 			local isIns = self._raceType == 0 or self._raceType == race

    -- 			if isIns then
    -- 				local data =
    -- 				{
    -- 					heroId = v.refId,
    -- 					monsterRefId = ref.attr,
    -- 					star = monsterRef.starLv,
    -- 					power = monsterRef.monsterPower,
    -- 					refId = ref.type,
    -- 					breakLv = v.breakLv,
    -- 				}

    -- 				table.insert(dataList,data)
    -- 			end
    -- 		end
    -- 		table.sort(dataList,function (hero1,hero2)
    -- 			local starLv1,starLv2 = hero1.star,hero2.star
    -- 			if starLv1 ~= starLv2 then
    -- 				return starLv1 > starLv2
    -- 			end
    -- 			local power1,power2 = hero1.power,hero2.power
    -- 			if power1 ~= power2 then
    -- 				return power1 > power2
    -- 			end
    -- 			local refId1,refId2 = hero1.refId,hero2.refId
    -- 			return refId1 > refId2
    -- 		end)
    -- 	end
    -- else
    --dataList = self:GetFilterHeroList(self._raceType)
    -- end
    dataList =  self:GetHeroList()
    return dataList
end

function UIMultiFightPre:RefreshPasvShow()

end
-- function UIMultiFightPre:ReturnHightStageRace()
-- 	self:WndClose()
-- 	FireEvent(EventNames.CHANGE_MAIN_BTN,1)
-- 	GF.ChangeMap("LCityMap")
-- 	GF.OpenWndBottom("UIring")
-- 	GF.OpenWndBottom("WndHighStageRaceMain")
-- end

function UIMultiFightPre:SetBattleName()
    local playerName = gModelPlayer:GetPlayerName()

    self:SetWndText(self.mMeName, playerName)
end

function UIMultiFightPre:InitUIShow(bShow, aniTime)
    local offsetY = -500
    local bottomTrans = self.mMainBattleBot

    if not self._bottomUIOrgPos then
        self._bottomUIOrgPos = bottomTrans.localPosition
    end
    aniTime = aniTime or 0
    local bottomPos = self._bottomUIOrgPos:Clone()
    if not bShow then
        bottomPos.y = bottomPos.y + offsetY
        FireEvent(EventNames.BATTLE_MAP_OFFSET, 0)
        return
    else
        FireEvent(EventNames.BATTLE_MAP_OFFSET, self._mapOffset, 0.4, true)
    end

    if aniTime > 0 then
        local seqCom = self:GetSeqCom()
        local seq = seqCom:CreateSeq("moveTween")
        local tween = bottomTrans:DOLocalMove(bottomPos, aniTime)
        seq:Append(tween)
        local outPos = Vector3.New(-656, self.mMe.localPosition.y, 0)
        self.mMe.localPosition = outPos
        tween = self.mMe:DOLocalMoveX(-156, aniTime)
        seq:Join(tween)
        local outPos = Vector3.New(656, self.mOther.localPosition.y, 0)
        self.mOther.localPosition = outPos
        tween = self.mOther:DOLocalMoveX(156, aniTime)
        seq:Join(tween)
        self.mMultiRoot.localScale = Vector3.zero
        tween = self.mMultiRoot:DOScale(Vector3.one, aniTime)
        seq:Join(tween)
        seq:OnComplete(function()
            seqCom:DeleteSeq("moveTween")
            local wndName = self:GetWndName()
            self:SendGuideReadyEvent(wndName)

            --self:CheckShowFormationGuide()
        end)
        seq:PlayForward()
    else
        bottomTrans.localPosition = bottomPos
        self.mMe.localPosition = Vector3.New(-156, self.mMe.localPosition.y, 0)
        self.mOther.localPosition = Vector3.New(156, self.mOther.localPosition.y, 0)
    end
end

function UIMultiFightPre:ShowTipWnd(heroId, teamIndex)
    local para = {
        refId = 10033,
        para = { teamIndex + 1 },
        func = function()
            FireEvent(EventNames.REFRESH_OTHER_TEAM_HERO, heroId, teamIndex)
        end
    }

    gModelGeneral:OpenUIOrdinTips(para)
end
function UIMultiFightPre:OnCurTeamDivineChange(list, teamIndex)
    if not self._multiTeamOperData then
        return
    end

    local operData = self._multiTeamOperData[teamIndex]
    if not operData then
        return
    end
    operData.divineWeaponStarIdList = list
    self:RefreshDivineWeaponShow()
end
function UIMultiFightPre:OnDrawCareerTypeCell(list, item, itemdata, itempos)
    local RaceIconTrans = self:FindWndTrans(item, "RaceIcon")
    local SelImgTrans = self:FindWndTrans(item, "SelImg")
    local icon = itemdata.icon
    local refId = itemdata.refId
    local show = icon ~= nil
    local isSel = false
    if show then
        isSel = self._careerType == refId
        self:SetWndEasyImage(RaceIconTrans, icon)
    end
    CS.ShowObject(RaceIconTrans, show)
    CS.ShowObject(SelImgTrans, isSel)
    self:SetWndClick(RaceIconTrans, function()
        self:OnClickCareerTypeFunc(refId)
    end, LSoundConst.CLICK_PAGE_COMMON)
end

function UIMultiFightPre:SetCurPasvList(list)
    local operData = self._multiTeamOperData[self._curTeam]
    operData.pasvList = list
end
function UIMultiFightPre:OnOtherTeamDivineChange(treaId, teamIndex)
    if not self._multiTeamOperData then
        return
    end

    teamIndex = teamIndex - 1
    local operData = self._multiTeamOperData[teamIndex]
    if not operData then
        return
    end

    local divineList = {}
    for k, v in pairs(operData.divineWeaponStarIdList) do
        if v == treaId then
            divineList[k] = 0
        else
            divineList[k] = v
        end
    end

    operData.divineWeaponStarIdList = divineList

end
function UIMultiFightPre:GetHeroList()
    local record = gModelFormation:GetOnFormationHeros(LCombatTypeConst.COMBAT_MAIN)
    local heroList = gModelHero:GetHeroSortList(record, nil, true)

    local showRedPoint = false
    local combatHeroList = gModelFormation:GetHeroFormationData(LCombatTypeConst.COMBAT_MAIN)
    self._combatHeroList = combatHeroList

    local allListData = {}
    self._allHeroDataList = allListData
    local combatHero = {}
    local combatHeroRef = {}
    --gModelHero:ClearHeroBagData()

    local heroNum = 0
    if heroList then
        --local heroIdx = 1
        for k, v in ipairs(heroList) do
            local refId = v:GetRefId()
            local id = v:GetId()
            local ref = gModelHero:GetHeroRef(refId)
            local bAdd = false

            if ref then
                local race = ref.raceType
                local career = ref.careerType
                bAdd = (self._careerType == 0 or career == self._careerType) and (self._raceType == 0 or race == self._raceType)
            end

            if combatHeroList[id] then
                if not showRedPoint then
                    showRedPoint = self:GetHeroStatus(id)
                end

                bAdd = false
                local hero = v:GetServerData()
                table.insert(combatHero, hero)
                table.insert(combatHeroRef, ref)
            end

            if bAdd then
                local hero = v:GetServerData()
                --gModelHero:SetHeroBagData(id,heroIdx)
                --hero.index = heroIdx
                table.insert(allListData, hero)
                --heroIdx = heroIdx + 1
            end
        end
        --showRedPoint = showRedPoint or gModelRedPoint:CheckShowRedPoint(ModelRedPoint.MAINCITY_HERO_PET)
        --CS.ShowObject(self._funcBtnRedPointList[1], showRedPoint)
        --heroNum = heroIdx - 1
        --gModelHero:SetLastNum(heroNum)
    end
    self._heroNum = heroNum

    table.sort(combatHero, function(a, b)
        return a.fightPower < b.fightPower
    end)

    for k, v in ipairs(combatHero) do
        local refId = v.refId
        local ref = gModelHero:GetHeroRef(refId)

        local race = ref.raceType
        local career = ref.careerType
        local bAdd = false

        bAdd = (self._careerType == 0 or career == self._careerType) and (self._raceType == 0 or race == self._raceType)

        if bAdd then
            table.insert(allListData, 1, v)
        end
    end

    return allListData
end

function UIMultiFightPre:OnClickMultiHero(heroId)
    local clickHeroData = gModelHero:GetHeroServerDataById(heroId)
    if not clickHeroData then
        return
    end
    local refId = clickHeroData.refId

    local operData = self._multiTeamOperData[self._curTeam]

    local index = operData.idToIndex[heroId]
    local isSelect = index ~= nil

    local bHaveEmpty, operIndex
    if isSelect then
        self:MultiHeroDown(heroId)
        operIndex = index

        FireEvent(EventNames.Scene_Hero_GoTo, heroId, operIndex, false)
    else
        -- local isHighStageRace = gModelHighStageRace:IsHighStageRace(self._combatType)
        -- if(isHighStageRace)then
        -- 	local lockHeroList = gModelHighStageRace:GetLockHeroList(self._combatType)
        -- 	if(isHighStageRace and lockHeroList and lockHeroList[refId])then
        -- 		return
        -- 	end
        -- end
        for k = 1, self._heroMax do
            if not operData.indexToId[k] then
                bHaveEmpty = true
                operIndex = k
                break
            end
        end

        local cnt = operData.cnt
        if not bHaveEmpty or cnt >= self._heroMax then
            local str = ccClientText(16605)--上阵人数已达上限
            GF.ShowMessage(str)
            return
        end

        if self:IsHeroForbid(heroId, refId, true) then
            return
        end

        gModelHero:PlayHeroRoleSound(refId, clickHeroData.skin)

        self:MultiHeroUp(heroId, operIndex)
        FireEvent(EventNames.Scene_Hero_GoTo, heroId, operIndex, true)
    end
end

function UIMultiFightPre:GetBossTowerTeamSetList()
    -- local bossId = self:GetBossTowerBossId()
    -- if not bossId then return end
    -- local monster = gModelBossTower:GetBossTowerCombatMonsterListByRefId(bossId,self._combatType)
    local teamIndexSetList = {}
    -- for i,v in ipairs(monster) do
    -- 	table.insert(teamIndexSetList,{
    -- 		formationType = self._combatType,
    -- 		teamIndex = i - 1,
    -- 	})
    -- end
    return teamIndexSetList
end

function UIMultiFightPre:GetExtraHeroRecord(exceptTeam)
    if not self._multiTeamOperData then
        return {}
    end

    local record = {}
    for k, v in pairs(self._multiTeamOperData) do
        if k ~= exceptTeam then
            for k1, v1 in pairs(v.idToIndex) do
                record[k1] = true
            end
        end
    end

    return record
end

function UIMultiFightPre:GetMultiRefIdList()
    local operData = self._multiTeamOperData[self._curTeam]
    local refIdList = {}
    -- if self:IsBossTowerCombat() then
    -- 	for k,v in pairs(operData.idToIndex) do
    -- 		local heroRefId = gModelBossTower:GetBossTowerHeroTypeByRefId(tonumber(k))
    -- 		table.insert(refIdList,{id = heroRefId})
    -- 	end
    -- else
    for k, v in pairs(operData.idToIndex) do
        local heroData = gModelHero:GetHeroServerDataById(k)
        local refId = heroData.refId
        table.insert(refIdList, { id = refId })
    end
    -- end
    return refIdList
end

function UIMultiFightPre:GetRightMonster()
    local combatType = self._combatType
    -- local bossId = self:GetBossTowerBossId()
    local monsterId = nil
    -- if self:IsBossTowerCombat() then
    -- 	local monsterIndex = self._curTeam + 1
    -- 	monsterId = gModelBattle:GetMonsterId(combatType,{
    -- 		monsterIndex = monsterIndex,
    -- 		bossId = bossId,
    -- 	})
    if combatType == LCombatTypeConst.COMBAT_TYPE_75 then
        monsterId = gModelBattle:GetMonsterId(combatType, {
            curTeam = self._curTeam,
        })
    elseif self:IsMainLineCombat() then
        monsterId = gModelBattle:GetMonsterId(combatType, {
            curTeam = self._curTeam,
        })
        -- elseif self:IsHighStageRace() then
        -- 	monsterId = gModelBattle:GetMonsterId(combatType,{
        -- 		curTeam = self._curTeam,
        -- 	})
    end
    return monsterId
end
function UIMultiFightPre:ReturnMainHero()
    self:WndClose()
    FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.ADVENTURE)
    GF.ChangeMap("LFightIdleMap")
end

function UIMultiFightPre:InitWndPara()
    self._combatType = self:GetWndArg("combatType")
    local extraData = self:GetWndArg("extraData")

    self._extraData = extraData
    self._curTeam = extraData.curTeam or 0

    printInfoN("cur team " .. self._curTeam)

    self._raceType = self:GetWndArg("raceType") or 0              -- 种猪
    self._careerType = self:GetWndArg("careerType") or 0            -- 职业
    self._heroMax = LCombatFormationConst.FIGURE_MAX
    self._emenyHeroDataList = {}
end

function UIMultiFightPre:OnDrawMuitlHeroCell(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local AniRootHero = self:FindWndTrans(AniRoot, "Hero")
    local HeroIcon = self:FindWndTrans(AniRootHero, "icon")
    local HeroMask = self:FindWndTrans(AniRootHero, "mask")
    local maskTips = self:FindWndTrans(HeroMask, "tips")
    local AniRootLvTxt = self:FindWndTrans(AniRoot, "lvTxt")

    local instanceId = item:GetInstanceID()

    local heroId = itemdata.id
    local heroSeverData = gModelHero:GetHeroServerDataById(heroId)
    if not heroSeverData then
        return
    end
    local refId = heroSeverData.refId
    local isResonance = heroSeverData.isResonance
    local star = heroSeverData.star
    local lv = heroSeverData.lv
    local skin = heroSeverData.skin

    local selState, teamIndex = self:IsMultiHeroSelect(heroId)
    local showMask = selState == 2
    CS.ShowObject(HeroMask, showMask)
    local showLock = false
    if showMask then
        local str = string.replace(ccClientText(21817), teamIndex + 1)
        self:SetWndText(maskTips, str)
    else
        showLock = self:IsHeroForbid(heroId, refId)
    end
    -- local isHighStageRace = gModelHighStageRace:IsHighStageRace(self._combatType)
    -- if(isHighStageRace)then
    -- 	local lockHeroList = gModelHighStageRace:GetLockHeroList(self._combatType)
    -- 	if(isHighStageRace and lockHeroList and lockHeroList[refId])then
    -- 		showMask = false
    -- 		CS.ShowObject(HeroMask,showMask)
    -- 		showLock = true
    -- 	end
    -- end
    local otherMappingId = gModelResonance:GetMappingOtherId(heroId)
    local otherMappingIsSel = false
    if (otherMappingId) then
        local otherMappingSelState, otherMappingTeamIndex = self:IsMultiHeroSelect(otherMappingId)
        otherMappingIsSel = otherMappingSelState ~= 0-- and otherMappingTeamIndex == self._curTeam
    end
    if (otherMappingIsSel) then
        showMask = false
        CS.ShowObject(HeroMask, showMask)
        showLock = true
    end

    local heroPara = {
        id = heroId,
        refId = refId,
        star = star,
        level = lv,
        trans = HeroIcon,
        selected = selState == 1,
        showLock = showLock,
        isResonance = isResonance,
        skin = skin,
    }

    local iconCls = self:GetCommonIcon(instanceId)

    iconCls:Create(HeroIcon)
    iconCls:SetHeroDataSet(heroPara)
    iconCls:SetNoShowLv(true)
    iconCls:SetShowLvMask(1)
    iconCls:DoApply()

    self:SetWndText(AniRootLvTxt, lv)
    local lvColor, lvMat = LUtil.GetResonanceColor(isResonance)
    self:SetXUITextTransColor(AniRootLvTxt, lvColor)
    if lvMat then
        self:SetWndTextMat(AniRootLvTxt, lvMat)
    end

    self:SetIconClickScale(AniRoot, true)

    self:SetWndClick(AniRoot, function()
        if (otherMappingIsSel) then
            GF.ShowMessage(ccClientText(38422))
        else
            self:OnClickMultiHero(heroId)
        end
    end)
    self:SetWndLongClick(AniRoot, function()
        gModelHero:FindHeroPowStateById(heroId)
        local data = {
            id = heroId,
            refId = refId,
            level = lv,
            star = star,
            grade = heroSeverData.grade,
            fightPower = heroSeverData.fightPower,
            isResonance = heroSeverData.isResonance,
            skin = skin,
        }
        gModelHero:ReqShowHeroTip("", data)
    end, 0.8, false)
end

function UIMultiFightPre:OnClickBossTowerBtn()

end

function UIMultiFightPre:GetBattleExtraData()
    return self._extraData
end

function UIMultiFightPre:MultiHeroDown(heroId)
    local operData = self._multiTeamOperData[self._curTeam]

    operData.idToIndex[heroId] = nil
    self:RefreshOperData(operData)
    self:RefreshRefIdRecord()

    self:RefreshMultiShow()
end

function UIMultiFightPre:CreateEmptyShow(refId)
    local data = {
        refId = refId,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
        GetBtnText = self.mEmptyBtnText,
        GetBtn = self.mEmptyBtn
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
    -- local showBtn = not self:IsBossTowerCombat()
    -- CS.ShowObject(self.mEmptyBtn,showBtn)
end

function UIMultiFightPre:ShowTeamFormation()
    -- local isBossTower = self:IsBossTowerCombat()
    local formationList
    -- if isBossTower then
    -- 	formationList = gModelBossTower:GetFormationList(self:GetBossTowerSid(),self._combatType)
    -- else
    formationList = gModelFormation:GetFormationList(self._combatType)
    -- end
    if not formationList then
        -- if isBossTower then
        -- 	local teamIndexSetList = self:GetBossTowerTeamSetList()
        -- 	if teamIndexSetList then
        -- 		gModelBossTower:OnBossTowerGetFormationReq(self:GetBossTowerSid(),teamIndexSetList)
        -- 	end
        -- else
        gModelFormation:OnGetFormationListReq({ self._combatType })
        -- end
    else
        self:OnMultiFormationDataRet(formationList)
    end
end

function UIMultiFightPre:RefreshBossTowerPower(power)
    -- power = tonumber(power)
    -- local str = LUtil.FormatPowerShowStr(power)
    -- self:SetWndText(self.mMeFightNum,str)
end

function UIMultiFightPre:OnSelectFormationType(refId)
    local curArrayId = self:GetCurArrayId()
    if curArrayId == refId then
        return
    end
    local isBossTowerCombat = false
    local myLv = gModelPlayer:GetPlayerLv()
    local needLv = gModelFormation:GetTacticalNeedLv(refId)
    if not isBossTowerCombat and myLv < needLv then
        local tacticalName = gModelFormation:GetPositionNameById(refId)
        local str = string.replace(ccClientText(17805), needLv, tacticalName)
        GF.ShowMessage(str)
        return
    end

    self:SetCurArrayId(refId)

    local itemList = self:FindUIScroll("formationList")
    if itemList then
        itemList:DrawAllItems(false)
    end

    FireEvent(EventNames.Change_Hero_Matrix, refId)

    self:RefreshCurArrayShow()
end

function UIMultiFightPre:HasUnSave(oldData, newData)
    local oldTreasureSkilIds = oldData.treasureIdList or {}
    local treasureSkilIds = newData.treasureIdList or {}

    local olddivineWeaponStarIdList = oldData.divineWeaponStarIdList
    local divineWeaponStarIdList = newData.divineWeaponStarIdList or {}

    local isEqual = gModelGeneral:CheckTreaListEqual(oldTreasureSkilIds, treasureSkilIds)
    if not isEqual then
        return true
    end

    local oldPasv = oldData.pasvList or {}
    local curPasv = newData.pasvList or {}

    local isEqual = gModelGeneral:CheckTreaListEqual(oldPasv, curPasv)
    if not isEqual then
        return true
    end

    isEqual = gModelGeneral:CheckTreaListEqual(olddivineWeaponStarIdList, divineWeaponStarIdList)
    if not isEqual then
        return true
    end

    if oldData.arrayId ~= newData.arrayId then
        return true
    end

    if oldData.cnt ~= newData.cnt then
        return true
    end

    for k, v in pairs(newData.indexToId) do
        local heroId = oldData.indexToId[k]
        if heroId ~= v then
            return true
        end
    end

    return false

end

function UIMultiFightPre:OnOtherTeamHeroChange(heroId, teamIndex)
    if not self._multiTeamOperData then
        return
    end

    local operData = self._multiTeamOperData[teamIndex]
    if not operData then
        return
    end

    operData.idToIndex[heroId] = nil

    self:RefreshOperData(operData)
    self:RefreshRefIdRecord()
    self:RefreshMultiShow()

    -- if self:IsBossTowerCombat() then
    -- 	self:OnClickBossTowerHero(heroId)
    -- else
    self:OnClickMultiHero(heroId)
    -- end
end

function UIMultiFightPre:RefreshCurArrayShow()
    local curArrayId = self:GetCurArrayId()

    local formationName = gModelFormation:GetPositionNameById(curArrayId)
    self:SetWndText(self.mFormationBtnName, formationName)

    -- 按钮换图
    local iconPath = self._formationIconList[curArrayId]
    local imageTran = self:FindWndTrans(self.mFormationBtn, "Image")
    self:SetWndEasyImage(imageTran, iconPath)

    self._curSelectFormationType = curArrayId
end
function UIMultiFightPre:SetEnemyPower(power)
    local str = LUtil.FormatPowerShowStr(power)
    self:SetWndText(self.mOtherFightNum, str)
end

function UIMultiFightPre:OnClickTeam(teamIndex)
    if self._curTeam == teamIndex then
        return
    end

    self._curTeam = teamIndex
    self:RefreshTeamSel()

    self:RefreshMultiHeroList()
    self:RefreshCurArrayShow()
    self:RefreshTreasureShow()
    self:RefreshDivineWeaponShow()
    self:RefreshPasvShow()
    -- 【C宠物系统】删掉宠物系统相关
    -- self:RefreshPetTreaBtnShow()

    self:ShowRefIdRelaPart()

    self:ShowRightPart()
    -- if(self._combatType == LCombatTypeConst.COMBAT_TYPE_37)then
    -- 	local targetId = self._extraData.playerId
    -- 	gModelPlayer:OnGetFormationShowReq(targetId,LCombatTypeConst.COMBAT_TYPE_35,self._curTeam)
    -- end
    FireEvent(EventNames.ON_CHANGE_PREPARE_INDEX, teamIndex)
    local operdata = self._multiTeamOperData[self._curTeam]
    FireEvent(EventNames.REFRESH_LEFT_TEMP_HERO, operdata, self:GetBossTowerSid())
end

function UIMultiFightPre:OnMultiFormationDataRet()
    self._multiTeamOperData = {}

    local combatType = self._combatType

    local isBossTower = false
    -- local isHighStageRace = gModelHighStageRace:IsHighStageRace(combatType)

    local formationList
    -- if isBossTower then
    -- 	formationList = gModelBossTower:GetFormationList(self:GetBossTowerSid(),combatType)
    -- elseif(isHighStageRace)then
    -- 	formationList = gModelHighStageRace:GetFormationList(combatType)
    -- else
    formationList = gModelFormation:GetFormationList(combatType)
    -- end

    if formationList then
        for k, v in pairs(formationList) do
            local teamIndex = v.teamIndex
            local idToIndex = {}
            local arrayId = v.formationRefId
            if v.grids then
                for k1, v1 in ipairs(v.grids) do
                    local pos = gModelFormation:GetIndexByPos(arrayId, v1.grid)
                    local tId = isBossTower and tonumber(v1.id) or v1.id
                    idToIndex[tId] = pos
                end
            end

            local treasureList = {}
            if v.treasureSkilIds then
                for k1, v1 in ipairs(v.treasureSkilIds) do
                    treasureList[k1] = v1
                end
            end
            local divineWeaponList = {}
            if v.divineWeaponStarRefIds then
                for k1, v1 in ipairs(v.divineWeaponStarRefIds) do
                    divineWeaponList[k1] = v1
                end
            end

            local pasvList = {}
            if v.treasurePassiveSkill then
                for k1, v1 in ipairs(v.treasurePassiveSkill) do
                    pasvList[k1] = v1
                end
            end

            -- 【C宠物系统】删掉宠物系统相关
            -- local petFights = {}
            -- if v.petFights then
            -- 	for k1,v1 in ipairs(v.petFights) do
            -- 		petFights[k1] = v1
            -- 	end
            -- end

            -- local petHelps = {}
            -- if v.petHelps then
            -- 	for k1,v1 in ipairs(v.petHelps) do
            -- 		petHelps[k1] = v1
            -- 	end
            -- end

            local operData = {
                combatType = self._combatType,
                idToIndex = idToIndex,
                arrayId = v.formationRefId,
                treasureIdList = treasureList,
                divineWeaponStarIdList = divineWeaponList,
                pasvList = pasvList,
                -- 【C宠物系统】删掉宠物系统相关
                -- petFights = petFights,
                -- petHelps = petHelps,
            }

            self:RefreshOperData(operData)
            self._multiTeamOperData[teamIndex] = operData
        end
    end

    local cnt = self._teamCnt
    for k = 0, cnt - 1 do
        local data = self._multiTeamOperData[k]
        if not data then
            data = {}
            self._multiTeamOperData[k] = data

            data.combatType = self._combatType
            data.idToIndex = {}
            data.arrayId = 1
            data.treasureIdList = {}
            data.divineWeaponStarIdList = {}
            data.pasvList = {}
            -- 【C宠物系统】删掉宠物系统相关
            -- data.petFights = {}
            -- data.petHelps = {}
        end

        self:RefreshOperData(data)
    end
    self:RefreshRefIdRecord()

    self._oldOperData = table.clone(self._multiTeamOperData)

    self:RefreshMultiHeroList()
    self:RefreshCurArrayShow()
    self:RefreshTreasureShow()
    self:RefreshDivineWeaponShow()
    self:RefreshPasvShow()
    -- 【C宠物系统】删掉宠物系统相关
    -- self:RefreshPetTreaBtnShow()

    self:RefreshArrayList()
    self:ShowRefIdRelaPart()

    local operdata = self._multiTeamOperData[self._curTeam]
    FireEvent(EventNames.REFRESH_LEFT_TEMP_HERO, operdata, self:GetBossTowerSid())

    self:InitUIShow(true, 0.4)
end

function UIMultiFightPre:RefreshDivineWeaponShow()
    local list = {}
    local divineWeaponStarIds = self:GetCurDivineStarIdList()

    if not divineWeaponStarIds then
        divineWeaponStarIds = {}
    end

    for i = 1, 4 do
        local data = divineWeaponStarIds[i] or 0
        table.insert(list, {
            refId = data,
            index = i,
        })
    end

    local root = self:FindWndTrans(self.mFormationDivineSkill, "skillList")
    self:CreateUIScrollImpl("activeDivine", root, list, function(...)
        self:OnDrawDivineIconCell(...)
    end)
end

function UIMultiFightPre:OnClickBossTowerHero(heroId)
end

function UIMultiFightPre:OnClickSetPasv()
    if gModelFormation:CheckTreasureNotUse(self._combatType, true) then
        return
    end
    local pasvList = self:GetCurPasvList()

    local para = {
        wndType = 3,
        treasureSkilIds = table.clone(pasvList),
        combatType = self._combatType,
        func = function(list)
            if self:IsWndClosed() then
                return
            end
            self:SetCurPasvList(list)
            self:RefreshPasvShow()
        end
    }

    GF.OpenWnd("UISelFightTsure", para)
end
function UIMultiFightPre:InitCareerTypeList()
    local list = self:GetCareerTypeList()
    local uiCareerTypeList = self._uiCareerTypeList
    if uiCareerTypeList then
        uiCareerTypeList:RefreshList(list)
    else
        uiCareerTypeList = self:GetUIScroll("uiCareerTypeList")
        self._uiCareerTypeList = uiCareerTypeList
        uiCareerTypeList:Create(self.mCareerTypeList, list, function(...)
            self:OnDrawCareerTypeCell(...)
        end)
    end
end

function UIMultiFightPre:MultiHeroUp(heroId, index)
    local operData = self._multiTeamOperData[self._curTeam]

    operData.idToIndex[heroId] = index
    self:RefreshOperData(operData)
    self:RefreshRefIdRecord()

    self:RefreshMultiShow()
end

function UIMultiFightPre:CheckTreaPosOpen(type, index)

    return false
end
function UIMultiFightPre:ShowEnemyBuffStatus(enemydata)
    local refIdList = {}
    local tempList = enemydata.prefabNameList
    for k, v in pairs(tempList) do
        table.insert(refIdList, { id = v.refId })
    end
    self._enemyList = refIdList
    self._isHeroEnemy = true
    self:ShowBuffStatus(false, refIdList)
end

function UIMultiFightPre:ShowBuffStatus(isLeft, refIdList)
    local trans = nil
    local effRoot = nil
    if isLeft then
        trans = self.mMeBuff
        effRoot = self.mMeEff
    else
        trans = self.mOtherBuff
        effRoot = self.mOtherEff
    end

    local buffIcon, buffEff, isActive = gModelFormation:GetBuffInfo(refIdList)
    local showIcon = false
    if buffIcon then
        self:SetWndEasyImage(trans, buffIcon)
        showIcon = true
    end

    CS.ShowObject(trans, showIcon)

    local buffStatusEffKey = isLeft and "selfBuff" or "otherBuff"
    self:DestroyWndEffectByKey(buffStatusEffKey)
    if buffEff then
        self:CreateWndEffect(effRoot, buffEff, buffStatusEffKey, 75, false, false)
    end
end

function UIMultiFightPre:RefreshGoToBtn()
    local str = ccClientText(24400) --"下一队"
    if self._teamCnt == self._curTeam + 1 then
        str = ccClientText(24401) --"挑战"
    end

    self:SetWndText(self.mFightTxt, str)
    --self:SetTextTile(self.mFightBtn,str)
end

function UIMultiFightPre:CheckHasHero(idRecord, refIdRecord)
    local heroList = gModelHero:GetHeroList()
    for k, v in pairs(heroList) do
        local id = v:GetId()
        local refId = v:GetRefId()
        if not idRecord[id] and not refIdRecord[refId] then
            return true
        end
    end
end
function UIMultiFightPre:GetCareerTypeList()
    local list = {}
    table.insert(list, {
        refId = UIHeroRaceList.ALL_RACE_REFID,
        icon = "public_race_0",
    })
    for k, v in pairs(GameTable.CharacterCareerRef) do
        table.insert(list, {
            refId = k,
            icon = v.jobIcon
        })
    end
    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    local listLen = #list
    local allRaceNum = gModelHero:GetAllRaceNum()
    local loseNum = allRaceNum - listLen
    if loseNum > 0 then
        for i = 1, loseNum do
            table.insert(list, {
                show = false,
            })
        end
    end

    return list
end

function UIMultiFightPre:RefreshBtnTipShow()
    local isShow = gModelFunctionOpen:CheckIsShow(16002040)
    CS.ShowObject(self.mBtnTips, false)
end

function UIMultiFightPre:OnClickGotoBtn()
    -- if self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerFightType") then
    --     local status = gModelBossTower:GetChallengeStatus(true)
    --     if not status then
    --         return
    --     end
    -- end


    local maxIndex = self._teamCnt - 1
    local curTeam = self._curTeam
    if curTeam < maxIndex then
        local nextIndex = self._curTeam + 1
        self:OnClickTeam(nextIndex)
    else

        local challengeFunc = function()
            local combatData = {
                formationList = self._multiTeamOperData,
                combatType = self._combatType,
                sid = self:GetBossTowerSid(),
                bossTowerBossId = self:GetBossTowerBossId(),
                skipBattle = self:GetBossTowerSkipBattle(),
            }
            gModelBattle:StartBattleReq(combatData)
            self:IsCloseBattle()
        end

        --todo  检查是否全部已布阵
        local readyCode, teamList = self:IsReady()
        if readyCode == 0 then
            challengeFunc()
            return
        end


        -- local isBossTower = gModelBossTower:IsBossTowerCombat(self._combatType)
        -- if readyCode == -1 and isBossTower then
        -- 	GF.ShowMessage(ccClientText(10127))
        -- 	return
        -- end


        local para = nil

        local strList = {}
        local firstIndex = teamList[1]
        for k, v in ipairs(teamList) do
            local str = string.replace(ccClientText(21817), v + 1)
            table.insert(strList, str)
        end

        local paraStr = table.concat(strList, ",")

        if readyCode == -1 then
            para = {
                refId = 80015,
                para = { paraStr },
                func = function()
                    if not self:IsWndClosed() then
                        self:OnClickTeam(firstIndex)
                    end
                end,

            }
        elseif readyCode == -2 then
            local wndId = isBossTower and 110064 or 80016
            para = {
                refId = wndId,
                para = { paraStr },
                func = function()
                    if not self:IsWndClosed() then
                        self:OnClickTeam(firstIndex)
                    end
                end,
                leftFunc = challengeFunc
            }
        end
        if not para then
            return
        end

        gModelGeneral:OpenUIOrdinTips(para)


    end
end

function UIMultiFightPre:OnClickReturn()

    local returnFunc = self._returnFuncMap[self._combatType]
    if not returnFunc then
        return
    end

    if self:CheckOnReturnSave() then
        local para = {
            refId = 80019,
            func = function()
                self:SaveFormation()
                returnFunc()
            end,
            leftFunc = returnFunc
        }

        gModelGeneral:OpenUIOrdinTips(para)
    else
        returnFunc()
    end


end

function UIMultiFightPre:OnDrawFormation(list, item, itemdata, itempos)
    local formation = self:FindWndTrans(item, "formation")
    local formationIcon = self:FindWndTrans(formation, "icon")
    local formationName = self:FindWndTrans(formation, "name")
    local formationSelect = self:FindWndTrans(formation, "select")
    local formationLock = self:FindWndTrans(formation, "lock")
    local formationCur = self:FindWndTrans(formation, "cur")

    self:SetWndText(formationCur, ccClientText(11002))

    -- local isBossTower = gModelBossTower:IsBossTowerCombat(self._combatType)

    local refId = itemdata.refId
    local nameCfg = ccLngText(itemdata.name)
    self:SetWndText(formationName, nameCfg)
    self:InitTextLineWithLanguage(formationName, -30)
    self:InitTextSizeWithLanguage(formationName, -4)
    local needLv = itemdata.needLv or 0
    local myLv = gModelPlayer:GetPlayerLv()
    local isGray = false
    -- if isBossTower then
    if self._combatType ~= LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        if myLv < needLv then
            isGray = true
        end
    end

    CS.ShowObject(formationLock, isGray)

    local iconPath = self._formationIconList[refId]
    if iconPath then
        self:SetWndEasyImage(formationIcon, iconPath)
    end

    CS.ShowObject(formationCur, self._formationType == refId)
    CS.ShowObject(formationSelect, self._curSelectFormationType == refId)

    if nil == self._formationUIList then
        self._formationUIList = {}
    end

    self._formationUIList[refId] = item
    self:SetWndClick(formation, function()
        if self._curSelectFormationType == refId then
            return
        end
        self._curSelectFormationType = refId

        local itemList = self:GetUIScroll("formationList")
        itemList:DrawAllItems()

    end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UIMultiFightPre:OnDrawSkillIconCell(list, item, itemdata, itempos)
    local Icon = self:FindWndTrans(item, "Icon")
    local AddImg = self:FindWndTrans(item, "AddImg")
    local LockImg = self:FindWndTrans(item, "LockImg")

    local refId = itemdata.refId
    --local showLock = false
    local index = itemdata.index
    local design = nil

    local isOpen = false
    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        isOpen = refId ~= 0
    else
        isOpen = gModelDraconic:IsSkillOpenByPos(index)

    end

    local isHaveSkill = refId ~= 0
    if isHaveSkill then
        local upRef = GameTable.DraconicSuitRankRef[refId]
        local ref = GameTable.DraconicRef[upRef.type]
        self:SetWndEasyImage(Icon, ref.skillIcon)
    end

    if not isOpen then
        CS.ShowObject(Icon, false)
        CS.ShowObject(AddImg, false)
        CS.ShowObject(LockImg, true)
    else
        CS.ShowObject(Icon, isHaveSkill)
        CS.ShowObject(AddImg, not isHaveSkill)
        CS.ShowObject(LockImg, false)
    end

end

function UIMultiFightPre:TypeBtnEvent(index, btnTrans)
    --CS.SetParentTrans(self.mBtnSelImg,btnTrans)
    self._raceType = index
    self:RefreshMultiHeroList()
end

function UIMultiFightPre:OnDrawPasv(list, item, itemdata, itempos)

end

function UIMultiFightPre:RefreshMultiShow()
    local list = self:FindUIScroll("multiHeroList")
    if list then
        list:DrawAllItems(false)
    end

    self:ShowRefIdRelaPart()

end

function UIMultiFightPre:ReturnTowerHard()
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TYPE_75, { isBattleShow = true })
    self:WndClose()
end

function UIMultiFightPre:GetCurPasvList()
    local operData = self._multiTeamOperData[self._curTeam]
    return operData.pasvList or {}
end

function UIMultiFightPre:RefreshArrayList()

    local isBossTowerCombat = false
    local isNotUseTreasure = gModelFormation:CheckTreasureNotUse(self._combatType)
    local isOpenSkill = gModelFunctionOpen:CheckIsShow(17404000)
    if isOpenSkill and isBossTowerCombat then
        if isNotUseTreasure then
            isOpenSkill = false
        end
    end
    CS.ShowObject(self.mFormationSkillBtn, isOpenSkill)

    local isOpen = gModelFunctionOpen:CheckIsShow(17404100)
    if isOpen and isBossTowerCombat then
        if isNotUseTreasure then
            isOpen = false
        end
    end
    CS.ShowObject(self.mPasvTrea, isOpen)

    -- 【C宠物系统】删掉宠物系统相关
    -- local isOpenPet = gModelFunctionOpen:CheckIsShow(36003000)
    -- CS.ShowObject(self.mPetTrea,isOpenPet)

    local cfgList = gModelFormation:GetFormationCfgList()

    local dataList = {}
    local myLv = gModelPlayer:GetPlayerLv()
    for k, v in ipairs(cfgList) do
        local isLock = not isBossTowerCombat and v.needLv > myLv or false
        local data = {
            refId = v.refId,
            name = ccLngText(v.name),
            isLock = isLock,
            image = self._formationIconList[v.refId],
        }

        table.insert(dataList, data)
    end

    local itemList = self:FindUIScroll("formationList")
    if not itemList then
        itemList = self:GetUIScroll("formationList")
        itemList:Create(self.mFormationList, dataList, function(...)
            self:OnDrawFormation(...)
        end)
    else
        itemList:RefreshList(dataList)
    end
end

---------------------------------------
---多队伍布阵
-----------------------------------
function UIMultiFightPre:InitMultiTeamPart()
    self._teamBtnList = {
        [1] = self.mTeam_1,
        [2] = self.mTeam_2,
        [3] = self.mTeam_3,
        [4] = self.mTeam_4,
        [5] = self.mTeam_5,
    }

    --self._teamNumImg =
    --{
    --	[1] = "trial2_num_1",
    --	[2] = "trial2_num_2",
    --	[3] = "trial2_num_3",
    --	[4] = "trial2_num_4",
    --	[5] = "trial2_num_5",
    --}

    self._formationIconList = {
        [1] = "formation_icon_1",
        [2] = "formation_icon_2",
        [3] = "formation_icon_3",
        [4] = "formation_icon_4",
        [5] = "formation_icon_5",
        [6] = "formation_icon_6",
    }

    self._teamNumStr = {
        [1] = "I",
        [2] = "II",
        [3] = "III",
        [4] = "IV",
        [5] = "V",
    }
    self._teamNumOff = {
        [1] = "trial2_num_1",
        [2] = "trial2_num_2",
        [3] = "trial2_num_3",
        [4] = "trial2_num_4",
        [5] = "trial2_num_5",
    }
    self._teamNumOn = {
        [1] = "trial1_num_1",
        [2] = "trial1_num_2",
        [3] = "trial1_num_3",
        [4] = "trial1_num_4",
        [5] = "trial1_num_5",
    }

    self._mapOffset = -1.4                -- 场景摄像机偏移位置

    self._multiTeamOperData = {}

    self._returnFuncMap = {
        [LCombatTypeConst.COMBAT_TYPE_75] = function()
            self:ReturnTowerHard()
        end,
        [LCombatTypeConst.COMBAT_TYPE_30] = function()
            self:ReturnMainBrave()
        end,
        [LCombatTypeConst.COMBAT_TYPE_31] = function()
            self:ReturnMainHero()
        end,
        -- [LCombatTypeConst.COMBAT_TYPE_35] = function() self:ReturnHightStageRace() end,
        -- [LCombatTypeConst.COMBAT_TYPE_36] = function() self:ReturnHightStageRace() end,
        -- [LCombatTypeConst.COMBAT_TYPE_37] = function() self:ReturnHightStageRace() end,
    }


    -- local towerBossFightType = gModelBossTower:GetBossTowerConfigRefByKey("towerBossFightType")
    -- local towerFightType = gModelBossTower:GetBossTowerConfigRefByKey("towerFightType")
    -- local compareFightType = gModelBossTower:GetBossTowerConfigRefByKey("compareFightType")

    -- local activityFunc = function()
    -- 	local para = self:GetBattleExtraData()
    -- 	if para then
    -- 		local returnFunc = para.returnFunc
    -- 		if returnFunc then returnFunc() end
    -- 	end
    -- 	self:WndClose()
    -- end

    -- self._returnFuncMap[towerBossFightType] = function() activityFunc() end
    -- self._returnFuncMap[towerFightType] = function() activityFunc() end
    -- self._returnFuncMap[compareFightType] = function() activityFunc() end
end
function UIMultiFightPre:ReturnMainBrave()
    self:WndClose()
    FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.ADVENTURE)
    GF.ChangeMap("LFightIdleMap")
end

function UIMultiFightPre:IsHeroForbid(heroId, refId, showTip)

    if not self._multiTeamOperData then
        return false
    end

    local selState, teamIndex = self:IsMultiHeroSelect(heroId)
    if selState == 2 then
        if showTip then
            self:ShowTipWnd(heroId, teamIndex)
        end
        return true
    end

    if selState == 0 then
        local refIdRecord = self._heroRefIdRecord and self._heroRefIdRecord[self._curTeam]
        local isRepeatRefId = refIdRecord and refIdRecord[refId]
        if isRepeatRefId then
            if showTip then
                GF.ShowMessage(ccClientText(10123))
            end
            return true
        end
    end

    local operdata = self._multiTeamOperData[self._curTeam] or {}
    local curRecord = operdata.idToIndex or {}
    local extraRecord = self:GetExtraHeroRecord(self._curTeam)
    local isForbid = gModelFormation:CheckLinkForbid(self._combatType, heroId, curRecord, extraRecord, showTip)
    return isForbid
end

---code 1:阵型为空
function UIMultiFightPre:IsReady()
    local _combatType = self._combatType
    local teamCnt
    -- if self:IsBossTowerCombat() then
    -- 	local bossId = self:GetBossTowerBossId()
    -- 	teamCnt = gModelBossTower:GetBossTowerTeamCount(bossId,_combatType)
    if self:IsMainLineCombat() then
        local monsterArr = gModelInstance:GetBattlePreMonsterArrByCombatType(_combatType)
        teamCnt = #monsterArr
        -- elseif self:IsHighStageRace() then
        -- 	teamCnt = self._teamCnt
    else
        teamCnt = gModelTower:GetHardTeamCnt()
    end

    local idRecord = {}
    for k, v in pairs(self._multiTeamOperData) do
        for k1, v1 in pairs(v.idToIndex) do
            idRecord[k1] = true
        end
    end

    local emptyTeamList = {}
    for k = 0, teamCnt - 1 do
        local operData = self._multiTeamOperData[k]
        if operData.cnt == 0 then
            table.insert(emptyTeamList, k)
        end
    end

    if #emptyTeamList > 0 then
        return -1, emptyTeamList
    end

    local notFullList = {}
    for k = 0, teamCnt - 1 do
        local operData = self._multiTeamOperData[k]
        if operData.cnt < self._heroMax then
            local refIdRecrod = self._heroRefIdRecord[k]
            local hasHero = self:CheckHasHero(idRecord, refIdRecrod)
            if hasHero then
                table.insert(notFullList, k)
            end
        end
    end

    if #notFullList > 0 then
        return -2, notFullList
    end

    return 0
end

function UIMultiFightPre:ShowRefIdRelaPart()
    local operData = self._multiTeamOperData[self._curTeam]
    local fightPower = 0

    -- if self:IsBossTowerCombat() then
    -- 	for k,v in pairs(operData.idToIndex) do
    -- 		local data = self._heroDataMap[v]
    -- 		local power = data and data.power or 0 -- gModelHero:GetMonsterPowerByRefId(k)
    -- 		fightPower = fightPower + power
    -- 	end
    -- 	local dataList = self:GetMultiTeamList(self._curTeam)
    -- 	gModelBossTower:OnBossTowerFormationPowerReq(self:GetBossTowerSid(),dataList)
    -- else
    for k, v in pairs(operData.idToIndex) do
        local heroData = gModelHero:GetHeroServerDataById(k)
        local power = heroData.fightPower
        fightPower = fightPower + power
    end
    -- end

    local refIdList = self:GetMultiRefIdList(true)
    self:ShowBuffStatus(true, refIdList)

    local str = LUtil.FormatPowerShowStr(fightPower)
    self:SetWndText(self.mMeFightNum, str)
end

function UIMultiFightPre:GetHeroStatus(id)
    local showRedPoint = false
    showRedPoint = gModelHero:GetHeroUpStatus(id)
    return showRedPoint
end
function UIMultiFightPre:RefreshMultiHeroList()
    local dataList = self:GetCombatHeroList()
    local onDrawHeroFunc

    -- if self:IsBossTowerCombat() then
    -- 	onDrawHeroFunc = function(...)
    -- 		self:OnDrawBossTowerHeroCell(...)
    -- 	end

    -- 	local dataMap = {}
    -- 	for k,v in ipairs(dataList) do
    -- 		dataMap[v.heroId] = v
    -- 	end

    -- 	self._heroDataMap = dataMap
    -- else
    onDrawHeroFunc = function(...)
        self:OnDrawMuitlHeroCell(...)
    end
    -- end

    local cnt = #dataList
    local isEmpty = cnt <= 0
    CS.ShowObject(self.mNoRecord, isEmpty)
    CS.ShowObject(self.mHeroList, not isEmpty)
    if isEmpty then
        self:CreateEmptyShow(17001)
        return
    end

    local uiList = self:FindUIScroll("multiHeroList")
    if not uiList then
        uiList = self:GetUIScroll("multiHeroList")
        uiList:Create(self.mHeroList, dataList, function(...)
            onDrawHeroFunc(...)
        end, UIItemList.WRAP)
    else
        uiList:RefreshList(dataList)
    end

end

function UIMultiFightPre:SceneHeroDownMulti(index)
    local operData = self._multiTeamOperData[self._curTeam]
    if not operData then
        return
    end

    local heroId = operData.indexToId[index]
    if not heroId then
        return
    end

    self:MultiHeroDown(heroId)
end
function UIMultiFightPre:ShowEnemyTreasure(herodata)
    local skillList = {}
    for k, v in ipairs(herodata.combatTreasures) do
        local index = v.index
        if v.skillRefId and v.skillRefId > 0 then
            local data = {
                skillId = v.skillRefId,
                exhibitionInfo = v.info
            }
            skillList[index] = data
        end

    end
    local dataList = {}
    local show = false
    --local playerLv = herodata.playerInfo._grade
    for k = 1, 4 do
        local data = skillList[k]
        if not data then
            data = {
                isEmpty = true,
            }
        else
            show = true
        end

        data.state = 1
        table.insert(dataList, data)
    end
    CS.ShowObject(self.mRightSkill, show)
    self:RefreshSkillList(self.mRightSkillList, dataList, "rightSkillList")
end

function UIMultiFightPre:SaveFormation()
    local reqIndex = gModelFormation:IncreaseFormationReqIndex()
    local dataList = self:GetMultiTeamList()
    --todo OnSetFormationReq 只传非空阵型
    -- if self:IsBossTowerCombat() then
    -- 	gModelBossTower:OnSetFormationDataList(dataList,self:GetBossTowerSid(),1)
    -- else
    gModelFormation:SetFormationMultipleReq(dataList, 1, reqIndex)
    -- end

end

function UIMultiFightPre:IsBossTowerCombat()
    -- return gModelBossTower:IsBossTowerCombat(self._combatType)
end

function UIMultiFightPre:GetMultiTeamList(curTeam)
    local dataList = {}
    for k, v in pairs(self._multiTeamOperData) do
        if curTeam then
            if curTeam == k then
                dataList[k] = v
            end
        else
            dataList[k] = v
        end
    end
    return dataList
end

function UIMultiFightPre:Examine()
    if self._showFormation then
        self:PlayShowFormation()
    end
end

function UIMultiFightPre:GetFilterHeroList(heroRace, heroRaceLimit)
    local heroList = gModelHero:GetHeroSortList()
    local dataList = {}
    if heroList then
        for k, v in pairs(heroList) do
            local refId = v:GetRefId()
            local heroId = v:GetId()
            local race = gModelHero:GetHeroRace(refId)
            if heroRace == 0 or heroRace == race then
                if not heroRaceLimit or heroRaceLimit[race] then
                    table.insert(dataList, heroId)
                end
            end
        end
    end

    return dataList
end

function UIMultiFightPre:OnClickLeftBuffBg()
    local refIdList = self:GetMultiRefIdList()
    GF.OpenWnd("UIBf", { refIdList = refIdList })
end

function UIMultiFightPre:OnOtherTeamTreaChange(treaId, teamIndex)
    if not self._multiTeamOperData then
        return
    end

    teamIndex = teamIndex - 1
    local operData = self._multiTeamOperData[teamIndex]
    if not operData then
        return
    end

    local treasureList = {}
    for k, v in pairs(operData.treasureIdList) do
        if v == treaId then
            treasureList[k] = 0
        else
            treasureList[k] = v
        end
    end

    operData.treasureIdList = treasureList


end

-- 显示可选择的阵型
function UIMultiFightPre:PlayShowFormation()
    self._showFormation = not self._showFormation
    CS.ShowObject(self.mFormationBg, self._showFormation)
    if self._showFormation then
        self:RefreshArrayList()
    end
end

function UIMultiFightPre:RefreshSkillList(root, dataList, key)

    local list = self:GetUIScroll(key)
    list:Create(root, dataList, function(...)
        self:OnDrawSkill(...)
    end)
end

function UIMultiFightPre:OnTryTcpReconnect()
    self:ShowTeamFormation()
    -- if self:IsBossTowerCombat() then
    -- 	local sid = self:GetBossTowerSid()
    -- 	if sid then
    -- 		gModelBossTower:OnBossTowerInsInfoReq(sid)
    -- 		gModelBossTower:OnBossTowerDataInfoReq(sid)
    -- 	end
    -- end
end
function UIMultiFightPre:GetCurDivineStarIdList()
    local operData = self._multiTeamOperData[self._curTeam]
    return operData.divineWeaponStarIdList
end

function UIMultiFightPre:OnDrawSkill(list, item, itemdata, itempos)


end
function UIMultiFightPre:PlayRaceBtnAni()
    local isShow = self._showRaceBtnList
    CS.ShowObject(self.mLine1, not isShow)
    CS.ShowObject(self.mLine2, isShow)
    CS.ShowObject(self.mUnfoldBtn, not isShow)
    CS.ShowObject(self.mDi, not isShow)
    CS.ShowObject(self.mDi1, isShow)

    --local sizeY = isShow and -215 or -150
    --local size = Vector2.New(self.mHeroShenList.sizeDelta.x, sizeY)
    --self.mHeroShenList.sizeDelta = size
    --
    --local posY = isShow and 60 or 27.5
    --self.mHeroShenList.localPosition = Vector3(self.mHeroShenList.localPosition.x, posY, 0)
end

function UIMultiFightPre:GetBossTowerSkipBattle()
    -- local extraData = self:GetBattleExtraData()
    -- if extraData then
    -- 	return extraData.skipBattle or false
    -- end
end

function UIMultiFightPre:RefreshRefIdRecord()
    local heroRefIdRecord = {}
    self._heroRefIdRecord = heroRefIdRecord

    -- if self:IsBossTowerCombat() then
    -- 	for k,v in pairs(self._multiTeamOperData) do
    -- 		local refIdRecord = {}
    -- 		for k1,v1 in pairs(v.idToIndex) do
    -- 			refIdRecord[k1] = true
    -- 		end
    -- 		heroRefIdRecord[k] = refIdRecord
    -- 	end
    -- else
    for k, v in pairs(self._multiTeamOperData) do
        local refIdRecord = {}
        for k1, v1 in pairs(v.idToIndex) do
            local heroData = gModelHero:GetHeroServerDataById(k1)
            local refId = heroData.refId
            refIdRecord[refId] = true
        end

        heroRefIdRecord[k] = refIdRecord
    end
    -- end
end

function UIMultiFightPre:SetStaticContent()
    --self:SetTextTile(self.mFormationSkillBtn, ccClientText(19049))

    self:SetTextTile(self.mFormationSkillBtn, ccClientText(41066), -30)
    self:SetTextTile(self.mGoOnBtn, ccClientText(16602))
    self:SetTextTile(self.mBossTowerBtn, ccClientText(23707))
    self:SetWndText(self.mBtnTipsText, ccClientText(20911))

    self:SetWndText(self.mSkipText, ccClientText(10341))
    self:SetWndText(self.mCardText, ccClientText(29526))
    -- self:SetTextTile(self.mPetTrea,ccClientText(37977))

    self:SetTextTile(self.mReturnBtn, ccClientText(15710))

    self:SetWndButtonText(self.mBtnConfirmFormation, ccClientText(10102))

    self:SetWndText(self.mFormationTitle, ccClientText(11003))

    self:SetWndText(self.mTxtDraconicTips, ccClientText(41084))
    self:SetWndText(self.mTxtDivineTips, ccClientText(46100) .. "：")
end

function UIMultiFightPre:ReleaseTouchEvent()
    if gLGameTouch then
        gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_UI)
    end
end
------------------------------------------------------------------
return UIMultiFightPre