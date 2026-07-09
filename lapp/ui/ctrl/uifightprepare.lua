---
--- Created by Administrator.
--- DateTime: 2023/10/29 9:33:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFightPrepare:LWnd
local UIFightPrepare = LxWndClass("UIFightPrepare", LWnd)

local YXTouchManager = CS.YXTouchManager

UIFightPrepare.NORMAL = 1                --普通布阵
UIFightPrepare.MULTIPLE_SET = 2        --伙伴布阵
UIFightPrepare.MULTI_TEAM_SET = 3            --段位赛布阵

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFightPrepare:UIFightPrepare()
    self._bottomUIOrgPos = nil

    ---@type table<number,CommonIcon>
    self._commonIconList = {}

    self:SetHideHurdle()
    self:SetHideTop()
    self:SetHideBottom()
    FireEvent(EventNames.ON_CHAT_SHOW, false)
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFightPrepare:OnWndClose()

    self._needClose = false

    FireEvent(EventNames.BATTLE_MAP_OFFSET, 0)
    FireEvent(EventNames.ON_CHAT_SHOW, true)
    FireEvent(EventNames.BATTLE_MAP_BG_OFFSET)

    if self._uiHeroScrollList then
        self._uiHeroScrollList:OnWndClose()
        self._uiHeroScrollList = nil
    end

    if self._commonIconList then
        self:ClearCommonIconList(self._commonIconList)
        self._commonIconList = nil
    end

    self:ReleaseTouchEvent()

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFightPrepare:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFightPrepare:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    self:InitUIShow(false)

    self:InitUIEvent()
    self:InitEvent()
    self:SetWndPara()
    self:OnBadgeGameStar()
    self:InitRaceTypeList()
    self:InitCareerTypeList()
    --援军阵型
    if self._wndType == UIFightPrepare.NORMAL then
        self:InitReliefTroop()
    end
    self:InitFormationList()

    self:SetStaticContent()

    if self._wndType == UIFightPrepare.NORMAL then
        self:ShowNormalWnd()
    else
        self:ShowOnlySetWnd()
    end

    local exceptWnds = {
        ["UIFightPrepare"] = true,
        ["UIGuePost"] = true,
    }
    gLGameUI:CloseAllButExcept(exceptWnds)

    self:InitTexts()
    self:RefreshNameToggle()
    self:RefreshBtnShow()
    self:RefreshBtnTipShow()
    --self:RefreshGuildBraveShow()
end

-- function UIFightPrepare:OnClickSetPasv()
-- if gModelFormation:CheckTreasureNotUse(self._combatType,true) then
-- 	return
-- end

-- local para =
-- {
-- 	wndType = 3,
-- 	-- treasureSkilIds = table.clone(self._pasvSkillList),
-- 	combatType = self._combatType,
-- 	func = function(list)
-- 		if self:IsWndClosed() then
-- 			return
-- 		end
-- 		self._pasvSkillList = list
-- 		self:RefreshPasvShow()
-- 	end
-- }

-- GF.OpenWnd("UISelFightTsure",para)
-- end
-----------------------上阵宠物按钮--------------------------
-- function UIFightPrepare:RefreshPetTreaBtnShow()
-- 	local isTraining = self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING
-- 	local isOpenPet = self:IsPetPartOpen()  and not isTraining
-- 	CS.ShowObject(self.mPetTrea, isOpenPet)
-- 	if(not isOpenPet)then
-- 		return
-- 	end

-- 	local dataList = {}
-- 	local petFights,petHelps = {},{}
-- 	local curPetFights = self:GetCurPetFights()
-- 	local curPetHelps = self:GetCurPetHelps()
-- 	for i, v in pairs(curPetFights) do
-- 		petFights[i] = v
-- 	end
-- 	for i, v in pairs(curPetHelps) do
-- 		petHelps[i] = v
-- 	end
-- 	local emptyCnt = 0
-- 	for i = 1,4 do
-- 		local petId = 0
-- 		if(i<3)then
-- 			petId = petFights[i]
-- 		else
-- 			petId = petHelps[i-2]
-- 		end
-- 		emptyCnt = (not petId or petId == 0 or petId == "0") and emptyCnt + 1 or emptyCnt
-- 		table.insert(dataList,{
-- 			petId = petId,
-- 			index = i,
-- 		})
-- 	end
-- 	local rpTrans = self:FindWndTrans(self.mPetTrea,"redPoint")
-- 	local showPR= emptyCnt>0 and self:CheckShowPetTreaPR(dataList)
-- 	CS.ShowObject(rpTrans,showPR)
-- 	local root = self:FindWndTrans(self.mPetTrea,"PetList")
-- 	self:CreateUIScrollImpl("PetTrea",root,dataList,function (...) self:OnDrawPetTreaCell(...) end)
-- end
-- function UIFightPrepare:CheckShowPetTreaPR(curList)
-- 	if(not curList or #curList == 0)then
-- 		return
-- 	end
-- 	local curDict = {}
-- 	local petDict = gModelPetSpace:GetPetBagDict()
-- 	for i, v in ipairs(curList) do
-- 		if(v.petId and v.petId~=0 and v.petId~="0")then
-- 			local refId = petDict[v.petId] and petDict[v.petId].refId or nil
-- 			if(refId)then
-- 				curDict[refId] = true
-- 			end
-- 		end
-- 	end
-- 	if(self:IsMultiTeam())then
-- 		local multiPetList = self:GetMultiTeamRecordPetList()
-- 		if(multiPetList)then
-- 			for i, v in pairs(multiPetList) do
-- 				local data = petDict[v.id]
-- 				if(data and data.refId)then
-- 					curDict[data.refId] = true
-- 				end
-- 			end
-- 		end
-- 	end
-- 	for i = 1, 4 do
-- 		local funcIdPre = 3600300
-- 		local funcOpenId = funcIdPre..tostring(i)
-- 		local isOpen = gModelFunctionOpen:CheckIsOpened(tonumber(funcOpenId))
-- 		if(isOpen and (not curList[i] or not curList[i].petId or curList[i].petId==0 or curList[i].petId=="0"))then
-- 			for j, v in pairs(petDict) do
-- 				local petId = v.id
-- 				if(petId and petId~=0 and petId~="0" and not curDict[v.refId])then
-- 					return true
-- 				end
-- 			end
-- 		end
-- 	end
-- end
-- function UIFightPrepare:OnDrawPetTreaCell(list,item,itemdata,itempos)
-- 	local iconBg = self:FindWndTrans(item,"IconBg")
-- 	local icon = self:FindWndTrans(iconBg,"Icon")
-- 	local addImg = self:FindWndTrans(item,"AddImg")
-- 	local lockImg = self:FindWndTrans(item,"LockImg")
-- 	local hasPet = itemdata.petId~=nil and itemdata.petId~=0 and itemdata.petId~="0"
-- 	local funcIdPre = 3600300
-- 	local funcOpenId = funcIdPre..tostring(itempos)
-- 	local isOpen = gModelFunctionOpen:CheckIsOpened(tonumber(funcOpenId))
-- 	CS.ShowObject(iconBg,hasPet and isOpen)
-- 	CS.ShowObject(lockImg,not isOpen)
-- 	CS.ShowObject(addImg,not hasPet and isOpen)
-- 	if(not hasPet)then
-- 		return
-- 	end
-- 	local petDict = gModelPetSpace:GetPetBagDict()
-- 	local petData = petDict[itemdata.petId]
-- 	if(petData)then
-- 		local petRefId = petData.refId
-- 		local ref = gModelPetSpace:GetPetConfigByTypeAndKey(ModelPetSpace.MagicPetRef, petRefId)
-- 		local star = petData.star or 0
-- 		local starId = (ref.initStar* 100) + star
-- 		local starRef = gModelPetSpace:GetPetConfigByTypeAndKey(ModelPetSpace.MagicPetStarRef, starId)
-- 		local petEffectRef = gModelPetSpace:GetPetConfigByTypeAndKey(ModelPetSpace.PetEffectRef ,starRef.effectId)
-- 		local showQua = ref.quality
-- 		local quaData = gModelPetSpace:GetQualityData(showQua)
-- 		self:SetWndEasyImage(icon,petEffectRef.icon)
-- 		self:SetWndEasyImage(iconBg,quaData.headBg)
-- 	end
-- end
-- function UIFightPrepare:OnClickSetPet()
-- 	local curPetFights = self:GetCurPetFights()
-- 	local curPetHelps = self:GetCurPetHelps()
-- 	local otherTeamPetList = self:GetMultiTeamRecordPetList()
-- 	--local curTeamIdx = self._teamIndex
-- 	local para =
-- 	{
-- 		wndType = 4,
-- 		petFights = table.clone(curPetFights),
-- 		petHelps = table.clone(curPetHelps),
-- 		combatType = self._combatType,
-- 		func = function(fights,helps)
-- 			if self:IsWndClosed() then
-- 				return
-- 			end
-- 			self._petFights = fights
-- 			self._petHelps = helps
-- 			self:RefreshPetTreaBtnShow()

-- 			self:RefreshChangePart()
-- 		end,
-- 		otherTeamPetList = otherTeamPetList,
-- 		--curTeamIdx = curTeamIdx
-- 	}
-- 	GF.OpenWnd("WndSeleBattlePet",para)
-- end
-- function UIFightPrepare:GetMultiTeamRecordPetList()
-- 	if(not self:IsMultiTeam())then
-- 		return
-- 	end
-- 	local rec = self._multiTeamRecord
-- 	if(not rec)then
-- 		return
-- 	end
-- 	local curTeamIndex = self._teamIndex
-- 	local petFightRecord = rec.petFightsRecord
-- 	local petHelpsRecord = rec.petHelpsRecord
-- 	local recordList = {}
-- 	for i, v in pairs(petFightRecord) do
-- 		if(i~=curTeamIndex)then
-- 			local petFights = v or {}
-- 			for j, k in ipairs(petFights) do
-- 				local data = {
-- 					index = i,
-- 					id = k
-- 				}
-- 				table.insert(recordList,data)
-- 			end
-- 		end
-- 	end
-- 	for i, v in pairs(petHelpsRecord) do
-- 		if(i~=curTeamIndex)then
-- 			local petHelps = v or {}
-- 			for j, k in ipairs(petHelps) do
-- 				local data = {
-- 					index = i,
-- 					id = k
-- 				}
-- 				table.insert(recordList,data)
-- 			end
-- 		end
-- 	end
-- 	return recordList
-- end
function UIFightPrepare:GetCurPetFights()
    return self._petFights or {}
end

function UIFightPrepare:OnClickTeamItem(teamIndex)
    if self._teamIndex == teamIndex then
        return
    end

    local hasUnSave = self:CheckHasUnSaved()
    local changeFunc = function()
        if self:IsWndClosed() then
            return
        end
        self:OnSelectTeamIndex(teamIndex)

    end
    if hasUnSave then
        local confirmFun = function()
            self:GotoChallenge(changeFunc)
        end

        local para = {
            refId = 10007,
            func = confirmFun,
            leftFunc = changeFunc,
        }
        gModelGeneral:OpenUIOrdinTips(para)
        return
    end

    changeFunc()
end
function UIFightPrepare:GetCurPetHelps()
    return self._petHelps or {}
end

function UIFightPrepare:RefreshHeroLockState()
    self:RefreshOnFormationRefId()

    local list = self._uiHeroScrollList
    if list then
        list:DrawAllItems()
    end
end

function UIFightPrepare:GetHeroList()
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
            local bAdd_1 = false
            local bAdd_2 =false
            if ref then
                local race = ref.raceType
                local career = ref.careerType
                bAdd_1 = self._careerType == 0 or career == self._careerType
                bAdd_2 = self._heroType == 0 or race == self._heroType
                bAdd = bAdd_1 and bAdd_2
            end

            if bAdd and combatHeroList[id] then
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

function UIFightPrepare:OnClickFormationConfirm()
    self:OnSelectFormationType(self._curSelectFormationType)
    CS.ShowObject(self.mFormationBg, false)
    self._showFormation = false
end

function UIFightPrepare:OnDrawPasv(list, item, itemdata, itempos)
    local Icon = self:FindWndTrans(item, "Icon")
    local AddImg = self:FindWndTrans(item, "AddImg")
    local LockImg = self:FindWndTrans(item, "LockImg")

    local refId = itemdata.refId
    local index = itemdata.index

    -- local isOpen = self:CheckTreaPosOpen(2,index)
    local isopen = false

    local isHaveSkill = refId ~= 0
    -- if isHaveSkill then
    -- 	local iconPath
    -- if self._isUsePlayerTreasureInfo then
    -- 	iconPath = gModelTreasure:GetMyTreasureIconBySkillRefId(refId)
    -- else
    -- 	iconPath = gModelTreasure:GetTreasureSkillIconBySkillRefId(refId)
    -- end
    -- 	self:SetWndEasyImage(Icon,iconPath)
    -- end

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

function UIFightPrepare:InitSimulationUI()
    CS.ShowObject(self.mSimulation, true)

    self:SetWndClick(self.mSimulationA, function()
        self:ChangeSimulationSelectSide(1)
    end)
    self:SetWndClick(self.mSimulationB, function()
        self:ChangeSimulationSelectSide(2)
    end)
    self:SetWndTabText(self.mSimulationA, ccClientText(44900))    --[44900] [單 體]
    self:SetWndTabText(self.mSimulationB, ccClientText(44901))      --[44901] [群 體]

    local bLeft = self._battleData.targetId == 1
    self:SetWndTabStatus(self.mSimulationA, bLeft and 0 or 1)
    self:SetWndTabStatus(self.mSimulationB, bLeft and 1 or 0)

    CS.ShowObject(self.mPresetFormationBtn, false)
end

function UIFightPrepare:RefreshEndlessHeroPower(root)
    local power = 0
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local heroData = self:GetEndelssHeroById(k)
        power = power + heroData.fightPower
    end

    -- 【C宠物系统】删掉宠物系统相关
    -- power = power + self:GetPetsPower()


    local powerStr = LUtil.FormatPowerShowStr(power)
    self:SetWndText(root, powerStr)
end
function UIFightPrepare:InitTexts()
    self:SetTextTile(self.mReturnBtn, ccClientText(30205))
    self:SetWndText(self.mTxtDraconicTips, ccClientText(41084))
    self:SetWndText(self.mTxtDivineTips, ccClientText(46100) .. "：")
end

function UIFightPrepare:ShowSelfBuffStatus()
    --local refIdList = {}
    --local monMap = self._isReliefTroop and self._reliefTroopData.monMap or {}
    ----local isBossTowerCombat = gModelBossTower:IsBossTowerCombat(self._combatType)
    --for k,v in pairs(self._selectHeroTable.indexToId) do
    --	if not monMap[v] then
    --		local data = gModelBattle:GetHeroData(self._combatType,v)
    --		if data then
    --			table.insert(refIdList,{id=data.refId,isMon = data.isMonster})
    --		end
    --
    --		--if isBossTowerCombat then
    --		--	local heroRefId = gModelBossTower:GetBossTowerHeroTypeByRefId(tonumber(v))
    --		--	table.insert(refIdList,{id=heroRefId})
    --		--else
    --		--	local refId = gModelBattle:GetHeroRefId(self._combatType,v)
    --		--	table.insert(refIdList,{id=refId})
    --		--end
    --	else
    --		table.insert(refIdList,{id=v, isMon=true})
    --	end
    --end

    local refIdList = self:GetSelectBuffWndDataList()

    self:ShowBuffStatus(self:IsArrayingTeamLeft(), refIdList)
end

function UIFightPrepare:GetMeLibraryPower(power)
    if power then
        self._totalPower = power
        self:RefreshMePower()
    end
    local totalPower = self._totalPower or 0
    return totalPower
end

function UIFightPrepare:OnClickLibraryHero(heroPara)
    local heroId = heroPara.id
    local selectTable = self._selectHeroTable
    local leftPos = selectTable.idToIndex[heroId]
    local isSelect = leftPos ~= nil
    local targetId = self._battleData.targetId
    local bHaveEmpty, emptyPos
    local bLineUp = true
    if isSelect then
        local posList = gModelCareSchool:GetCheckPosListByRefId(targetId)
        if table.keysize(posList) > 0 and posList[leftPos] then
            GF.ShowMessage(ccClientText(20915))
            return
        end
        bLineUp = false
        self:HeroDown(heroId, leftPos)
        emptyPos = leftPos
    else
        bHaveEmpty, emptyPos = self:GetEmptyPos()
        local cnt = selectTable.cnt
        if not bHaveEmpty or cnt >= self._heroMax then
            local str = string.replace(ccClientText(20912), self._heroMax)--上阵人数已达上限
            GF.ShowMessage(str)
            return
        end
        local _fList = gModelCareSchool:GetFormationListByRefId(targetId)
        local num = table.keysize(_fList)
        if emptyPos > num then
            local str = string.replace(ccClientText(20912), num)--上阵人数已达上限
            GF.ShowMessage(str)
            return
        end
        self:HeroUp(heroId, emptyPos)
    end
    FireEvent(EventNames.Scene_Hero_GoTo, heroId, emptyPos, bLineUp)
end

function UIFightPrepare:OnClickSyn()
    local matrix = gModelFormation:GetFormationPosByRefId(self._formationType)
    local grids = {}
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local grid = matrix[v]
        local data = {}
        data.id = k
        data.grid = grid
        table.insert(grids, data)
    end

    if #grids == 0 then
        GF.ShowMessage(ccClientText(10127))
        return
    end

    table.sort(grids, function(grid1, grid2)
        return grid1.grid < grid2.grid
    end)
    local formationData = {}
    --formationData.combatType = self._combatType
    formationData.teamIndex = self._teamIndex or 0
    formationData.formationRefId = self._formationType
    formationData.grids = grids
    formationData.draconicStarRefIds = self._treasureSkilIds
    formationData.treasureSkilIds = self._treasureSkilIds
    formationData.divineWeaponStarRefIds = self._divineWeaponStarRefIds
    formationData.formationSetType = 1
    formationData.tactics = self._strategyId
    formationData.formationType = self._combatType
    -- formationData.treasurePassiveSkill = self._pasvSkillList
    local combatType = self._combatType

    local wndType = 1
    local dataList = nil
    if self._wndType == UIFightPrepare.MULTIPLE_SET then
        dataList = gModelFormation:GetCombatTypeList(nil, nil, { [combatType] = true })
        GF.OpenWnd("UIFoionSyc", { dataList = dataList, formationData = formationData, wndType = wndType })
    elseif self._wndType == UIFightPrepare.MULTI_TEAM_SET then
        wndType = 2
        dataList = {}
        for k, v in pairs(self._combatDataList) do
            if v.combatType ~= self._combatType then
                local ref = gModelBattle:GetCombatPlayCampRefByRefId(v.combatType)
                local data = {
                    refId = ref.refId,
                    name = ref.name
                }

                table.insert(dataList, data)
            end
        end

        table.sort(dataList, function(a, b)
            return a.refId < b.refId
        end)

        local formationMap = {}

        for k = 0, self._teamCount - 1 do
            local tempData = nil
            if k == self._teamIndex then
                tempData = formationData
            else
                tempData = gModelFormation:GetFormation(combatType, k)
                if not tempData then
                    tempData = {}
                    tempData.teamIndex = k
                    tempData.grids = {}
                    -- tempData.treasureSkilIds = {}
                    tempData.formationRefId = 1
                    tempData.tactics = 0
                    tempData.formationType = combatType
                end

                --tempData.combatType = tempData.formationType
            end

            formationMap[k] = tempData
        end

        GF.OpenWnd("UIFoionSyc", { dataList = dataList, formationMap = formationMap, wndType = wndType, teamCnt = self._teamCount })

    end


end

function UIFightPrepare:OnDrawSkillIconCell(list, item, itemdata, itempos)
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

function UIFightPrepare:ShowNormalWnd()
    CS.ShowObject(self.mBloodRoot, true)
    CS.ShowObject(self.mArenaOpt, true)
    CS.ShowObject(self.mBattleBtn, false)
    CS.ShowObject(self.mSetRoot, false)
    CS.ShowObject(self.mBtnShare, false)
    CS.ShowObject(self.mTeamSwitch, false)
    CS.ShowObject(self.mTeamMirror, false)
    CS.ShowObject(self.mSimulation, false)

    local isMirror = false
    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_SIMULATION or self._combatType == LCombatTypeConst.COMBAT_TACTICAL_SIMULATION_2 then
        local targetId = self._battleData.targetId
        local monster = gModelCareSchool:GetSimulationBattleData(targetId)

        if monster == 0 then
            isMirror = true
        else
            self:InitSimulationUI()
        end


    elseif self._combatType == LCombatTypeConst.COMBAT_MAIN then
        local battleNode = gModelInstance:GetBattleNode()
        if gModelPlot:IsStoryInstance(battleNode) then
            gModelHero:OnHeroListReq()
        end
    end

    local showBottom = true

    if isMirror then
        self:InitMirrorBattleUI()
        local formation = gModelCareSchool:GetMirrorFormationData(2) or {}
        local _selectHeroTable = {}
        local formationRefId = formation.formationRefId or 0
        if formationRefId == 0 then
            formationRefId = 1
        end
        for k, v in pairs(formation.grids or {}) do
            local heroId = v.id
            local serData = gModelHero:GetHeroById(heroId)
            local isExist = serData ~= nil
            if isExist then
                local index = gModelFormation:GetIndexByPos(formationRefId, v.grid)
                _selectHeroTable[heroId] = index
            end
        end
        local totalPower = 0
        local refIdList = {}
        for k, v in pairs(_selectHeroTable) do
            local power = self:GetPower(k)
            totalPower = totalPower + power
            local heroSeverData = gModelHero:GetHeroServerDataById(k)
            if heroSeverData then
                table.insert(refIdList, { id = heroSeverData.refId })
            end
        end
        local str = LUtil.FormatPowerShowStr(totalPower)
        self:SetWndText(self.mOtherFightNum, str)
        self:ShowBuffStatus(false, refIdList)
    elseif not self._dontReqFormationTypes[self._combatType] then
        showBottom = false
        -- self._isUsePlayerTreasureInfo = true
        self:RefreshHeroFormation()
    elseif self._combatType == LCombatTypeConst.COMBAT_TEST_BATTLE then
        -- self._isUsePlayerTreasureInfo = true
        self:InitTestBattleUI()
    end

    if showBottom then
        self:ShowBottomPart()
    end

    if self._showMonsterType[self._combatType] then
        self:ShowMonsterBuffStatus()
    elseif self._combatType == LCombatTypeConst.COMBAT_WONDERLAND then
        self:ShowWonderBossBuffStatus()
        -- elseif self._combatType == LCombatTypeConst.COMBAT_DESIRETRAIL then
        --     self:ShowDesireTrailBossBuffStatus()
    elseif gModelBattle:IsTimeCorridorCombat(self._combatType) then
        self:ShowTimeCorridorBossBuffStatus()
    elseif self._combatType == LCombatTypeConst.COMBAT_INVASION then
        self:ShowInvasionBuffStatus()
    elseif self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_DREAMTRIP then
        self:ShowActivityDreamTripBuffStatus()
    end

    self:ShowOtherTypeWnd()

    local monsterRefId = gModelBattle:GetMonsterId(self._combatType, self._battleData)
    if monsterRefId > 0 then
        -- 【G公共支持】删除本命英雄功能
        -- if(self._combatType == LCombatTypeConst.COMBAT_TYPE_34)
        -- or self._combatType == LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER
        -- or self._combatType == LCombatTypeConst.COMBAT_NEW_HERO_THEME_B_CHAPTER
        -- or self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY then

        -- local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterRefId)
        -- local targetPower = monsterFormationRef.monsterPower
        -- self:SetEnemyPower(targetPower or 0)
        if not self:CheckIsSpecialCombat() then
            gModelFormation:OnMonsterPowerReq({ monsterRefId })
        else
            local combatExtraData = self._battleData
            local monsterIdList = combatExtraData and combatExtraData.bossIdList or {}
            local monsterPowerList = combatExtraData and combatExtraData.powerList or {}
            self:SetEnemyPower(combatExtraData.monsterPower or 0)
            FireEvent(EventNames.REFRESH_MONSTER_SHOW, combatExtraData.formation, monsterIdList, monsterPowerList)
        end
        -- local dataList = gModelBattle:FormatMonsterTreasures(monsterRefId)
        -- if #dataList>0 then
        -- 	self:ShowMonsterTreasure(dataList)
        -- end
    end

    -- if self._battleData.treasureIds then
    -- 	self:ShowMonsterTreasure(self._battleData.treasureIds)
    -- end

    local showRetBtn = true
    if self._combatType == LCombatTypeConst.COMBAT_MAIN then
        local battleNode = gModelInstance:GetBattleNode()
        showRetBtn = not gModelPlot:IsStoryInstance(battleNode)
    end

    CS.ShowObject(self.mReturnBtn, showRetBtn)

    self:ModifyTopUIPos()

    -- 【G公共支持】删除本命英雄功能
    -- if self._combatType == LCombatTypeConst.COMBAT_TYPE_34 then
    -- 	self:InitMirrorBattleUIForNaturalPartner()
    -- end
end

function UIFightPrepare:OnDrawCombatGroup(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local AniRootOff = self:FindWndTrans(AniRoot, "off")
    local AniRootOn = self:FindWndTrans(AniRoot, "on")
    local AniRootUIText = self:FindWndTrans(AniRoot, "UIText")
    local AniRootRedPoint = self:FindWndTrans(AniRoot, "redPoint")

    local isSelect = itemdata.index == self._selectGroup
    CS.ShowObject(AniRootOff, not isSelect)
    CS.ShowObject(AniRootOn, isSelect)
    local color = "white"
    if isSelect then
        color = "black"
    end
    self:SetWndText(AniRootUIText, LUtil.FormatColorStr(itemdata.round, color))

    self:SetWndClick(AniRoot, function()
        self:OnClickCombatGroup(itemdata)
    end)

    local showRed = self._redRoundMap and self._redRoundMap[itempos]
    CS.ShowObject(AniRootRedPoint, showRed)

end

function UIFightPrepare:RefreshFormationDivineSkill()
    local list = {}
    local divineStarRefIds = self._divineWeaponStarRefIds
    if not divineStarRefIds then
        divineStarRefIds = {}
        self._divineWeaponStarRefIds = divineStarRefIds
    end
    for i = 1, 4 do
        local data = divineStarRefIds[i] or 0
        table.insert(list, {
            refId = data,
            index = i,
        })
    end
    local root = self:FindWndTrans(self.mFormationDivineSkill, "skillList")
    self:CreateUIScrollImpl("DivineSkill", root, list, function(...)
        self:OnDrawDivineSkillIcon(...)
    end)
end

function UIFightPrepare:CheckShowFormationGuide()

    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        return
    end

    if gModelGuide:IsInGuide() then
        return
    end

    local myLv = gModelPlayer:GetPlayerLv()
    if myLv >= 62 then
        return
    end
    local dataList = gModelFormation:GetFormationCfgList()
    local maxRefId = 0
    local ref = nil
    for k, v in ipairs(dataList) do
        if myLv >= v.needLv then
            if maxRefId < v.refId then
                maxRefId = v.refId
                ref = v
            end
        end
    end

    local isFinish = gModelGuide:IsFormationGuideFinish(maxRefId)
    if isFinish then
        return
    end

    local str = string.replace(ccClientText(22307), ccLngText(ref.name))

    local para = {
        info = str,
        clickFunc = function()
            gModelGuide:RecordFormationGuide(maxRefId)
            self:PlayShowFormation()
        end
    }

    GF.OpenWnd("UIGueTip", { wndType = 2, targetTran = self.mFormationBtn, para = para })
end

function UIFightPrepare:InitMirrorHeroFormation()
    self:ClearSelectTable()

    local bLeft = self:IsArrayingTeamLeft()
    self:SetWndTabStatus(self.mBtnTeamMirrorA, bLeft and 0 or 1)
    self:SetWndTabStatus(self.mBtnTeamMirrorB, bLeft and 1 or 0)
    local formation = gModelCareSchool:GetMirrorFormationData(self._teamSide) or {}
    local formationRefId = formation.formationRefId or 0
    if formationRefId == 0 then
        formationRefId = 1
    end
    for k, v in pairs(formation.grids or {}) do
        local heroId = v.id
        local serData = gModelHero:GetHeroById(heroId)
        local isExist = serData ~= nil
        if isExist then
            local index = gModelFormation:GetIndexByPos(formationRefId, v.grid)
            self._selectHeroTable.idToIndex[heroId] = index
            self._selectHeroTable.indexToId[index] = heroId
            self._emptyPos[index] = false
        end
    end

    self:RefreshHeroCnt(self._selectHeroTable)
    -- self._artifact = formation.artifactId or 0【G公共支持】删除神器功能相关数据
    self._treasureSkilIds = formation.treasureSkilIds -- formation.treasureSkilIds
    self._divineWeaponStarRefIds = formation.divineWeaponStarRefIds
    -- self._pasvSkillList = formation.treasurePassiveSkill
    self._petFights = formation.petFights
    self._petHelps = formation.petHelps

    self:RefreshFormationSkillShow()
    self:RefreshFormationDivineSkill()
    self:RefreshPasvShow()
    -- 【C宠物系统】删掉宠物系统相关
    -- self:RefreshPetTreaBtnShow()
    self:FormationSelEvent(formationRefId)

    self:RecordOldFormation()
    self:RefreshChangePart()
    self:ShowHeroList()
end

function UIFightPrepare:GetCurFormationData()
    local matrix = gModelFormation:GetFormationPosByRefId(self._formationType)
    local grids = {}
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local index = v
        if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
            local targetId = self._battleData.targetId
            local _fList = gModelCareSchool:GetFormationStationPos(targetId)
            index = _fList[v]
        end
        local grid = matrix[index]
        local data = {}
        data.id = k
        data.grid = grid
        table.insert(grids, data)
    end
    -- local artifactId = self._artifact【G公共支持】删除神器功能相关数据
    local treasureSkilIds = self._treasureSkilIds
    local divineWeaponStarRefIds = self._divineWeaponStarRefIds

    local data = {
        formationRefId = self._formationType,
        -- artifactId = artifactId,【G公共支持】删除神器功能相关数据
        treasureSkilIds = treasureSkilIds,
        grids = grids,
        -- treasurePassiveSkill = self._pasvSkillList,
        petFights = self:GetCurPetFights(),
        petHelps = self:GetCurPetHelps(),
        divineWeaponStarRefIds = divineWeaponStarRefIds,
    }

    return data
end

function UIFightPrepare:ShowOnlySetPower()
    local power, percent = self:GetCommonMePower()
    local text = self:FindWndTrans(self.mOwnPower, "power")

    local str = LUtil.FormatPowerShowStr(power)
    self:SetWndText(text, str)
    local percentStr = ""
    if percent then
        percentStr = string.format("(+%0.2f%%)", percent * 100)
        percentStr = LUtil.FormatColorStr(percentStr, "lightGreen")
        percentStr = LUtil.FormatSizeStr(percentStr, 16)
    end
    local percentText = self:FindWndTrans(text, "percentAdd")
    self:SetWndText(percentText, percentStr)
end
function UIFightPrepare:OnDrawCareerTypeCell(list, item, itemdata, itempos)
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

function UIFightPrepare:ShowDesireTrailBossBuffStatus()
    local bossList = self._bossList or {}
    local isHero = true
    local refIdList = {}

    for k, v in pairs(bossList) do
        if v.heroType == ModelDesireTrail.HeroType.ENEMY_MONSTER then
            isHero = false
        end
        table.insert(refIdList, { id = v.refId, isMon = not isHero })
    end
    self._enemyList = refIdList
    self._isHeroEnemy = isHero
    self:ShowBuffStatus(false, refIdList)
end

function UIFightPrepare:OnDrawTimeCorridorHero(list, item, itemdata, itempos)
    --
    --local hero = self:FindWndTrans(item,"Hero")
    --local heroTrans = self:FindWndTrans(hero,"HeroIcon")
    --local deadTag = self:FindWndTrans(item,"deadTag")
    --local hireTag = self:FindWndTrans(item,"hireTag")
    --local BarBgTrans = self:FindWndTrans(item,"BarBg")
    --local lvTxtTrans = self:FindWndTrans(item,"lvTxt")
    --local BoolBarTrans
    --if BarBgTrans then
    --	CS.ShowObject(BarBgTrans,true)
    --	BoolBarTrans = self:FindWndTrans(BarBgTrans,"BoolBar")
    --end
    --
    --local instanceId = item:GetInstanceID()
    --local heroIcon = self:GetCommonIcon(instanceId)
    --heroIcon:Create(heroTrans)
    --
    --local id,refId,star,level,grade,fightPower = itemdata.id,itemdata.refId,itemdata.star,itemdata.lvl,itemdata.grade,itemdata.power
    --local skin = itemdata.skin
    --local isResonance = itemdata.resonance or 0
    --local treeInfo = itemdata.treeInfo
    --local pos = self._selectHeroTable.idToIndex[id]
    --local isSelect = pos~=nil
    --
    --local isLock = self:IsHeroForbidSingle(id,refId)
    --local otherMappingIsSel = self:ShowMappingHeroLock(id)
    --isLock = isLock or otherMappingIsSel
    --
    --if lvTxtTrans then
    --	self:SetWndText(lvTxtTrans,level)
    --	local lvColor = LUtil.GetResonanceColor(isResonance)
    --	self:SetXUITextTransColor(lvTxtTrans,lvColor)
    --end
    --
    --local herodata = {}
    --herodata.trans = heroTrans
    --herodata.id = id
    --herodata.refId = refId
    --herodata.star = star
    --herodata.level = level
    --herodata.showLock = isLock
    --herodata.skin = skin
    --herodata.selected = isSelect
    --herodata.isResonance = isResonance
    --herodata.canUse = gModelTimeCorridor:IsHeroCanUse(refId)
    --herodata.showName = self._showName
    --herodata.treeInfo = treeInfo
    --herodata.form = itemdata.form
    --
    --heroIcon:SetHeroDataSet(herodata)
    --heroIcon:SetNoShowLv(true)
    --heroIcon:SetShowLvMask(1)
    --if not herodata.canUse then
    --	heroIcon:ShowLock(true)
    --end
    --heroIcon:DoApply()
    --
    --local isHire = itemdata.heroType == ModelWonderland.HIRE_HERO
    --local heroType = isHire and 4 or 1
    --self:SetWndClick(heroTrans,function()
    --	if(otherMappingIsSel)then
    --		GF.ShowMessage(ccClientText(38422))
    --	else
    --		self:OnSelectTimeCorridorHero(herodata)
    --	end
    --end)
    --
    --self:SetIconClickScale(heroTrans,true)
    --self:SetWndLongClick(heroTrans,function()
    --	local checkpointType = 1
    --	if self._combatType == LCombatTypeConst.COMBAT_TIME_CORRIDOR_TIME then
    --		checkpointType = 2
    --	elseif self._combatType == LCombatTypeConst.COMBAT_TIME_CORRIDOR_THEATER then
    --		checkpointType = 3
    --	end
    --
    --	local data = {
    --		id = id,
    --		refId = refId,
    --		level = level,
    --		star = star,
    --		grade = grade,
    --		fightPower = fightPower,
    --		--isWonderHero = isHire,
    --		heroType = heroType,
    --		isResonance = isResonance,
    --		skin = skin,
    --		other = checkpointType,
    --		treeInfo = treeInfo,
    --	}
    --	gModelHero:ReqShowHeroTip("",data)
    --end,0.8,false)
    --
    --local curHp = itemdata.curHp
    --local isDead = curHp<=0
    --CS.ShowObject(deadTag,isDead)
    --
    --if BoolBarTrans then
    --	local maxHp = itemdata.maxHp
    --	local curVal = curHp / maxHp
    --	LxUiHelper.SetProgress(BoolBarTrans,curVal)
    --end
    --
    --CS.ShowObject(hireTag,isHire)
end

function UIFightPrepare:InitCareerTypeList()
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

function UIFightPrepare:ReleaseTouchEvent()
    if gLGameTouch then
        gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_UI)
    end
end

function UIFightPrepare:OnTryTcpReconnect()
    if self._wndType == UIFightPrepare.NORMAL then
        self:ShowNormalWnd()
    else
        self:ShowOnlySetWnd()
    end
    local sid = self._sid
    local combatType = self._combatType
    -- if combatType and sid and gModelBossTower:IsBossTowerCombat(combatType) then
    -- 	gModelBossTower:OnBossTowerInsInfoReq(sid)
    -- 	gModelBossTower:OnBossTowerDataInfoReq(sid)
    -- end
end

function UIFightPrepare:OnSetFormationMultipleResp(pb)
    local teamIndexSet = pb.teamIndexSet

    local isRefresh = false
    for k, v in ipairs(teamIndexSet) do
        local type = v.formationType
        if type == self._combatType then
            for k1, v1 in ipairs(v.teamIndex) do
                if self._teamIndex == v1 then
                    isRefresh = true
                    break
                end
            end
        end
    end

    if isRefresh then
        self:RecordOldFormation()
    end
end

function UIFightPrepare:OnClickCombatType(refId)
    if self._curSelectType == refId then
        return
    end

    local hasUnSave = self:CheckHasUnSaved()
    local changeFunc = function()
        if self:IsWndClosed() then
            return
        end

        self._curSelectType = refId

        local list = self:FindUIScroll("combatList")
        if list then
            list:DrawAllItems(false)
        end

        local str = ccClientText(16618)
        local ref = gModelFormation:GetCombatGameRef(refId)
        local name = ccLngText(ref.name)
        GF.ShowMessage(string.replace(str, name))

        self:OnSelectCombatType(refId)

    end
    if hasUnSave then
        local confirmFun = function()
            self:GotoChallenge(changeFunc)
        end

        local para = {
            refId = 10007,
            func = confirmFun,
            leftFunc = changeFunc,
        }
        gModelGeneral:OpenUIOrdinTips(para)
        return
    end

    changeFunc()
end

function UIFightPrepare:ReturnWarTemple()
    local returnFunc = self._returnFunc
    if returnFunc then
        returnFunc()
    else
        GF.OpenWnd("UIWarTemple")
        -- GF.OpenWnd("UIWarTempleFightList")
    end
end

function UIFightPrepare:RefreshFormationInfoRecord()
    if not self._multiTeamRecord then
        return
    end

    local teamIndex = self._teamIndex
    -- if self.treasureSkilIds then
    -- 	local tRecord = {}
    -- 	for k1,v1 in ipairs(self._treasureSkilIds) do
    -- 		tRecord[k1] = v1
    -- 	end

    -- 	self._multiTeamRecord.treasureIdRecord[teamIndex] = tRecord
    -- end

    if self._strategyId then
        self._multiTeamRecord.tacticsRecord[teamIndex] = self._strategyId

    end
end

function UIFightPrepare:ShowReliefTroopHeroList()
    local dataList = {}
    local reliefTroopData = self._reliefTroopData

    local bHasIn = {}
    for i, v in ipairs(reliefTroopData.heroList) do
        local heroId = v.id
        local race = v.race
        if self._heroType == 0 or self._heroType == race then
            if not self._raceKeyList or self._raceKeyList[race] then
                bHasIn[heroId] = true
                table.insert(dataList, { id = heroId, isMon = false, isFixed = v.isFixed })
            end
        end
    end

    for i, v in ipairs(reliefTroopData.monList) do
        local monRefId = v.refId
        local race = v.race
        if self._heroType == 0 or self._heroType == race then
            if not self._raceKeyList or self._raceKeyList[race] then
                table.insert(dataList, { id = monRefId, isMon = true, isFixed = v.isFixed })
            end
        end
    end

    for k, v in ipairs(reliefTroopData.freeTroopList or {}) do
        local monRefId = v.refId
        local race = v.race
        if self._heroType == 0 or self._heroType == race then
            if not self._raceKeyList or self._raceKeyList[race] then
                table.insert(dataList, { id = monRefId, isMon = true, isFixed = v.isFixed })
            end
        end
    end

    if reliefTroopData.selfHero then
        local heroList = gModelHero:GetHeroSortList()
        if heroList then
            for k, v in pairs(heroList) do
                local refId = v:GetRefId()
                local heroId = v:GetId()
                local race = gModelHero:GetHeroRace(refId)
                if self._heroType == 0 or self._heroType == race then
                    if (not self._raceKeyList or self._raceKeyList[race]) and not bHasIn[heroId] then
                        if self._isShowTryHero or not v:IsTryHero() then
                            table.insert(dataList, { id = heroId, isMon = false, isFixed = false })
                        end
                    end
                end
            end
        end
    end

    local uiList = self._uiHeroScrollList
    if not uiList then
        uiList = self:GenerateUIHeroScrollList(function(...)
            self:OnDrawReliefTroopHeroCell(...)
        end)
    end
    uiList:RemoveAll()

    local cnt = #dataList
    for i = 1, cnt do
        local tmpdata = dataList[i]
        uiList:AddData(tmpdata.id, tmpdata)
    end
    uiList:RefreshList()
end

function UIFightPrepare:ModifyTopUIPos()
    --local isBossFight = self._combatType == LCombatTypeConst.COMBAT_INVASION_BOSS
    local isBossFight = false

    local pos = isBossFight and Vector3.New(0, 0, 0) or Vector3.New(0, -46, 0)

    self.mBloodRoot.localPosition = pos

    -- 调整为一直显示
    CS.ShowObject(self.mOtherFight, not isBossFight)
    CS.ShowObject(self.mOtherBloodDownDi, not isBossFight)
    CS.ShowObject(self.mOtherName, not isBossFight)

    local scale = isBossFight and Vector3.New(0.9, 0.9, 0.9) or Vector3.one
    local rightSkillPos = isBossFight and Vector3.New(-6, 0, 0) or Vector3.New(-30, -24, 0)

    self.mRightSkill.localPosition = rightSkillPos
    self.mRightSkill.localScale = scale
end

function UIFightPrepare:GetSwapList(dataList)
    local swapTransList = self._swapTransList
    if not swapTransList then
        swapTransList = {}
        self._swapTransList = swapTransList
    end
    local swapLen = #swapTransList
    if swapLen > 0 then
        return
    end

    self._dragItemDataList = {}
    self._dragOriginPos = {}
    self._dragIndexList = {}

    local ItemRoot = self:FindWndTrans(self.mSwapCombatList, "ItemRoot")
    local keyName = "_dragItem_"
    local trans
    for i = 1, 5 do
        trans = self:FindWndTrans(ItemRoot, "SwapCombat" .. i)
        local data = dataList[i]
        local isHaveData = data ~= nil
        if trans and isHaveData then
            table.insert(self._dragIndexList, i)

            table.insert(swapTransList, trans)

            local dragKey = keyName .. i
            local vector3List = trans:GetLocalCorners()
            local vecMin = vector3List[0]
            local vecMax = vector3List[2]
            local minX = vecMin.x
            local minY = vecMin.y
            local maxX = vecMax.x
            local maxY = vecMax.y
            local centerX = (vecMax.x + vecMin.x) / 2
            local centerY = (vecMax.y + vecMin.y) / 2
            local width = vecMax.x - vecMin.x
            local height = vecMax.y - vecMin.y
            local midW = width / 2
            local midH = height / 2

            self._dragItemDataList[dragKey] = {
                key = dragKey,
                keyIndex = i,
                index = i,
                constIndex = i,
                item = trans,
                minX = minX,
                minY = minY,
                maxX = maxX,
                maxY = maxY,
                centerX = centerX,
                centerY = centerY,
                width = width,
                height = height,
                midW = midW,
                midH = midH,
            }
            table.insert(self._dragOriginPos, trans.localPosition)

            self:InternalUIDragSetItem(dragKey, trans, CS.YXUIDrag.DragMode.DragNothing)
        end
        CS.ShowObject(trans, isHaveData)
    end

    self._swapTransList = swapTransList

    local len = #self._dragOriginPos
    local top = self._dragOriginPos[1]
    local bottom = self._dragOriginPos[len]
    local firstName, lastName = keyName .. "1", keyName .. len
    local itemTopData = self._dragItemDataList[firstName]
    local itemBottomData = self._dragItemDataList[lastName]

    self._dragOriginLimitMinY = bottom.y + itemBottomData.minY
    self._dragOriginLimitMaxY = top.y + itemTopData.maxY
end

function UIFightPrepare:InitReliefTroopBattleUI(formation)
    self:InitReliefTroopFormation(formation)
    if self._wndType == UIFightPrepare.NORMAL then
        self:SetPlayerName()
    end
    self:ShowBottomPart()
    FireEvent(EventNames.REFRESH_MY_HERO_SHOW)
end

function UIFightPrepare:ReqBossTowerPower()
    -- if gModelBossTower:IsBossTowerCombat(self._combatType) then
    -- 	local selectTable = self._selectHeroTable
    -- 	local teamIndex = self._teamIndex or 0
    -- 	local dataList = {
    -- 		[teamIndex] = {
    -- 			arrayId = self._formationType,
    -- 			combatType = self._combatType,
    -- 			idToIndex = selectTable.idToIndex,
    -- 			-- treasureIdList = {},
    -- 		}
    -- 	}
    -- 	gModelBossTower:OnBossTowerFormationPowerReq(self._sid,dataList)
    -- end
end

function UIFightPrepare:ReturnCrossWar()
    local returnFunc = self._returnFunc
    if returnFunc then
        returnFunc()
    else
        GF.ChangeMap("LCityMap")
        GF.OpenWndBottom("UIOutts", { childIndex = 2 })
        GF.OpenWnd("UIKuafuWar")
        GF.CloseWndByName("UIFightPrepare")
    end
end

function UIFightPrepare:IsMultiTeam()
    return self._wndType == UIFightPrepare.MULTI_TEAM_SET
end

function UIFightPrepare:ReturnType47()
    local returnFunc = self._returnFunc
    if returnFunc then
        returnFunc()
    end
end

function UIFightPrepare:GetPower(heroId)
    local power = 0
    local heroSeverData = gModelHero:GetHeroServerDataById(heroId)
    if not heroSeverData then
        return power
    end
    power = heroSeverData.fightPower
    return power
end

function UIFightPrepare:BackGuildBrave()
    --返回公会副本
    self:WndClose()

    FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.CITY)
    GF.OpenWndBottom("UIGdBraveWin")
    GF.ChangeMap("LCityMap")
end

function UIFightPrepare:GetMultiTacticsRecord(exceptTeam)
    local record = {}
    for k, v in pairs(self._multiTeamRecord.tacticsRecord) do
        if not exceptTeam or exceptTeam ~= k then
            record[v] = true
        end
    end

    return record
end
-- 【G公共支持】删除本命英雄功能
-- function UIFightPrepare:ReturnNaturalPartner()
-- 	self:WndClose()
-- 	local combatExtraData = self._battleData
-- 	GF.ChangeMap("LCityMap")
-- 	GF.OpenWnd("WndNaturalPartner")
-- end
function UIFightPrepare:ReturnBadgeGame()
    self:WndClose()
    local combatExtraData = self._battleData
    GF.ChangeMap("LCityMap")
    GF.OpenWnd("UIBrandGameWin", { combatExtraData = combatExtraData, name = "UISubBrandGame" })
end

-- 返回主城
function UIFightPrepare:BackMainMap()
    self:WndClose()

    gModelGeneral:RecoverGameState()
end

------------------------------------------------------------------
function UIFightPrepare:ShowOtherTypeWnd()
    local combatType = self._combatType
    CS.ShowObject(self.mArenaOpt, false)
    local fightText = self:FindWndTrans(self.mFightBtn, "FightTxt")
    local str = nil
    if combatType == LCombatTypeConst.COMBAT_ARENA_DEFEND or combatType == LCombatTypeConst.COMBAT_ARENA_PEAK_ATTACK then
        str = ccClientText(10353)
    elseif combatType == LCombatTypeConst.COMBAT_GUILD_WAR then
        if self._guildMeleeState then
            str = ccClientText(17904)
        else
            str = ccClientText(10353)
        end
    elseif combatType == LCombatTypeConst.COMBAT_CROSS_SERVER_LADDER or combatType == LCombatTypeConst.COMBAT_CROSS_SERVER_CHAMPION then
        if self._isSetFormation then
            str = ccClientText(10353)
        else
            str = ccClientText(10130)
        end
    else
        str = ccClientText(10130)
    end
    self:SetWndText(fightText, str)

    local ShowBattleBtn = false
    local battleBtnStr
    if combatType == LCombatTypeConst.COMBAT_CROSS_SERVER_LADDER then
        if self._isSetFormation then
            CS.ShowObject(self.mOther, false)
        else
            CS.ShowObject(self.mArenaOpt, false)
            if self._playerId then
                gModelGeneral:PlayerShowReq(self._playerId, LCombatTypeConst.COMBAT_CROSS_SERVER_LADDER, LPlayerShowConst.CROSS_SERVER)
            end
        end
    elseif combatType == LCombatTypeConst.COMBAT_CROSS_SERVER_CHAMPION then
        if self._isSetFormation then
            CS.ShowObject(self.mOther, false)
        end
    elseif combatType == LCombatTypeConst.COMBAT_ARENA_DEFEND then
        CS.ShowObject(self.mOther, false)
    elseif combatType == LCombatTypeConst.COMBAT_GUILD_WAR then
        CS.ShowObject(self.mOther, false)
    elseif combatType == LCombatTypeConst.COMBAT_ARENA_ATTACK then
        CS.ShowObject(self.mArenaOpt, true)
        local isSkip = gModelArena:GetIsSkipChecked()
        local text = self:FindWndTrans(self.mArenaSkip, "Label")
        self:SetWndText(text, ccClientText(10341))
        self:SetWndToggleValue(self.mArenaSkip, isSkip)
        self:SetWndToggleDelegate(self.mArenaSkip, function(value)
            local isSuc = gModelArena:SetIsSkipChecked(value, true)
            if not isSuc then
                self:SetWndToggleValue(self.mArenaSkip, not value)
            end
        end)
        if self._playerId then
            gModelGeneral:PlayerShowReq(self._playerId, LCombatTypeConst.COMBAT_ARENA_DEFEND, LPlayerShowConst.ARENA_SYSTEM)
        end
    elseif combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE then
        if self._playerId then
            gModelGeneral:PlayerShowReq(self._playerId, LCombatTypeConst.COMBAT_WAR_TEMPLE_DEF, LPlayerShowConst.ARENA_SYSTEM)
        end
    elseif combatType == LCombatTypeConst.COMBAT_ARENA_PEAK_ATTACK then
        CS.ShowObject(self.mOther, false)

    elseif combatType == LCombatTypeConst.COMBAT_PK then
        if self._playerId then
            gModelGeneral:PlayerShowReq(self._playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.ARENA_SYSTEM)
        else
            local prepareData = self._battleData.prepareData
            if prepareData then
                self:SetEnemyCombatData(prepareData)
            end
        end
    elseif combatType == LCombatTypeConst.COMBAT_WONDERLAND or gModelBattle:IsTimeCorridorCombat(combatType) then
        self:SetEnemyPower(self._power)

    elseif combatType == LCombatTypeConst.COMBAT_DESIRETRAIL then
        self:SetEnemyPower(self._power)
    elseif self._channgleBossTypes[combatType] then

        if not combatType == LCombatTypeConst.COMBAT_FAIRYLAND_BOSS then
            ShowBattleBtn = true
            battleBtnStr = ccClientText(18754)
        end
    elseif combatType == LCombatTypeConst.COMBAT_INVASION then
        self:SetEnemyPower(self._power)
        -- elseif combatType == gModelBossTower:GetBossTowerConfigRefByKey("compareFightType") then
        -- 	self:SetEnemyPower(self._battleData.power)
        -- 	self:SetBossEnemyCombatData(self._battleData.prepareData)
    elseif self:CheckIsSpecialCombat() then
        local prepareData = self._battleData.prepareData
        if prepareData then
            self:SetEnemyCombatData(prepareData)
        end
    elseif combatType == LCombatTypeConst.COMBAT_BADGE_GAME then
        self:SetEnemyPower(self._power)
    elseif combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        self:SetEnemyPower(self._power)
    elseif gModelBattle:IsPetDreamLandCombat(combatType) then
        local power = 0
        ---@type StructCombatHeroData
        local combatHeroData = self._battleData.combatHeroData
        if combatHeroData then
            local formationRefId = combatHeroData._formationRefId
            local heros = combatHeroData:GetHeros()
            local grids = combatHeroData:GetGrids()
            local prefabNameList = {}
            for i, v in ipairs(heros) do
                local index = gModelFormation:GetIndexByPos(formationRefId, grids[i])
                local refId = v.refId
                local skin = v.skin
                local prefabName, needFlip = gModelHero:GetHeroDisplay(refId, v.star, skin, true, v.form)
                power = power + v.fightPower
                table.insert(prefabNameList, {
                    pos = index,
                    prefabName = prefabName,
                    bottomImg = gModelHero:GetHeroBottomImgByRefId(refId),
                    race = gModelHero:GetHeroRace(refId),
                    lv = v.lv,
                    isResonance = v.isResonance,
                    skin = skin,
                    needFlip = needFlip,
                })
            end
            local combat = {
                matrixRefId = formationRefId,
                prefabNameList = prefabNameList,
            }
            self:SetEnemyCombatData(combat)
        end
        self._power = power
        self:SetEnemyPower(self._power)

    elseif self._battleData.isUseCombatHeroData then
        local power, combat = self:ParseCombatHeroData(self._battleData.combatHeroData)
        self:SetEnemyCombatData(combat)

        if self._battleData.isHavePowerData then
            power = self._battleData.powerData
        end
        self._power = power
        self:SetEnemyPower(self._power)
    elseif combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
        if self._playerId then
            gModelGeneral:PlayerShowReq(self._playerId, LCombatTypeConst.COMBAT_CROSS_WAR, LPlayerShowConst.ARENA_SYSTEM)
        end
    end

    CS.ShowObject(self.mBattleBtn, ShowBattleBtn)
    if ShowBattleBtn and battleBtnStr ~= nil then
        self:SetWndText(self.mBattleTxt, battleBtnStr)
    end
end

function UIFightPrepare:OnAwake()
    LWnd.OnAwake(self)
    self._delayFinishEvent = true
end

function UIFightPrepare:InitSwapList(dataList)
    self:GetSwapList(dataList)
    self._swapDataList = dataList
    self:RefreshTeamItemShow()
end
function UIFightPrepare:PlayRaceBtnAni()
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

function UIFightPrepare:GetBossTowerHeroList()
    local dataList = {}
    -- local bossTowerList = gModelBossTower:GetBossTowerHeroListByKey(self._sid) or {}
    -- for i,v in pairs(bossTowerList) do
    -- 	local isIns = self._heroType == 0
    -- 	if not isIns then
    -- 		local heroRefId = gModelBossTower:GetBossTowerHeroAttrByRefId(v.refId)
    -- 		local race = gModelHero:GetMonsterRace(heroRefId)
    -- 		isIns = self._heroType == race
    -- 	end
    -- 	if isIns then
    -- 		table.insert(dataList,v)
    -- 	end
    -- end
    -- dataList = gModelBossTower:GetSortHeroBagList(dataList)
    return dataList
end

function UIFightPrepare:RecordOldFormation(isFake)

    if isFake then
        self._oldFomationRefId = 1
        self._oldFormation = {
            cnt = 0,
            indexToId = {},
            idToIndex = {},
        }
        -- self._oldTreasureSkilIds = {}
        self._oldStrategyId = 0
        self._oldPasvList = {}
        self._oldPetFights = {}
        self._oldPetHelps = {}
    else
        self._oldFomationRefId = self._formationType
        self._oldFormation = table.clone(self._selectHeroTable)
        self._oldTreasureSkilIds = {}
        for k, v in pairs(self._treasureSkilIds) do
            self._oldTreasureSkilIds[k] = v
        end
        self._oldDivineWeaponStarRefIds = {}
        for k, v in pairs(self._divineWeaponStarRefIds) do
            self._oldDivineWeaponStarRefIds[k] = v
        end

        self._oldStrategyId = self._strategyId
        self._oldPasvList = {}
        for k, v in ipairs(self._pasvSkillList) do
            self._oldPasvList[k] = v
        end

        local curPetFights = self:GetCurPetFights()
        local curPetHelps = self:GetCurPetHelps()
        self._oldPetFights = {}
        for k, v in pairs(curPetFights) do
            self._oldPetFights[k] = v
        end
        self._oldPetHelps = {}
        for k, v in pairs(curPetHelps) do
            self._oldPetHelps[k] = v
        end
    end
end

function UIFightPrepare:OnClickCareerTypeFunc(refId)
    if self._careerType == refId then
        return
    end
    self._careerType = refId
    --self:RefreshBtnEvent()
    --self:RefreshMultiTeamHeroList()
    self:ShowHeroList()
    local uiCareerTypeList = self._uiCareerTypeList
    if not uiCareerTypeList then
        return
    end
    local uiList = uiCareerTypeList:GetList()
    uiList:RefreshList()
end

-- function UIFightPrepare:BackCrossServerChampion()
-- 	self:WndClose()

-- 	GF.ChangeMap("LCityMap")

-- 	gModelCrossServer:OpenUIring()
-- 	GF.OpenWndBottom("WndCrossServerChampion")

-- end

function UIFightPrepare:ReturnGuildMelee()
    self:WndClose()

    GF.ChangeMap("LCityMap")
    GF.OpenWndBottom("UIGdWar2Win", { page = 2 })
end

function UIFightPrepare:CloseFormationBg()
    CS.ShowObject(self.mFormationBg, false)
    self._showFormation = false
    self._curSelectFormationType = self._formationType
end

function UIFightPrepare:ReturnSimulation()
    gModelCareSchool:ClearMirrorData()

    self:WndClose()
    --gModelFunctionOpen:Jump(19100000)
    GF.OpenWndBottom("UIOutts", { childIndex = 2 })
    GF.OpenWndBottom("UICareColleWin")
    GF.ChangeMap("LCityMap")
end
function UIFightPrepare:GetCareerTypeList()
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

function UIFightPrepare:RefreshOnFormationRefId()
    local refIdRecord = {}
    local bReliefTroop = self._isReliefTroop
    local monMap = bReliefTroop and self._reliefTroopData.monMap or {}
    local monToHeroRefId = bReliefTroop and self._reliefTroopData.monToHeroRefId or {}

    local idRecord = {}
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local heroId = k
        if bReliefTroop and monMap[heroId] then
            local refId = monToHeroRefId[heroId]
            if refId and refId > 0 then
                refIdRecord[refId] = true
                idRecord[heroId] = true
            end
        else
            local herodata = gModelBattle:GetHeroData(self._combatType, heroId)
            if herodata and herodata.refId then
                refIdRecord[herodata.refId] = true
                idRecord[heroId] = true
            end
        end
    end

    self._refIdOnFormation = refIdRecord

    if self:IsMultiTeam() then
        if not self._multiTeamRecord then
            self._multiTeamRecord = {
                heroRefIdRecord = {},
                heroIdRecord = {}
            }
        end
        local teamIndex = self._teamIndex
        self._multiTeamRecord.heroRefIdRecord[teamIndex] = refIdRecord
        self._multiTeamRecord.heroIdRecord[teamIndex] = idRecord
    end

end
-- 【G公共支持】删除跨服天梯和跨服周冠玩法
-- function UIFightPrepare:BackCrossServerLadder()
-- 	self:WndClose()

-- 	GF.ChangeMap("LCityMap")

-- 	ModelCrossServer:OpenUIring()
-- 	GF.OpenWndBottom("WndCrossServerLadder")

-- end

function UIFightPrepare:ReturnInvasion(isBoss)
    gLGameUI:CloseAllButExcept({ ["UIInvoss"] = true })
    gModelInvasion:EnterMap(isBoss)


end

-- 活动
function UIFightPrepare:BackActivity()
    local combatExtraData = self._battleData
    local page, subPage = gModelActivity:GetActivityPosBySid(combatExtraData.sid)
    self:WndClose()

    FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.ACTIVITY)
    GF.OpenWndBottom("UIAct", { page = page, subPage = subPage })
    GF.ChangeMap("LCityMap")
end

function UIFightPrepare:RefreshBtnShow()
    local combatType = self._combatType

    local showSynBtn = false
    if self._wndType == UIFightPrepare.MULTIPLE_SET then
        showSynBtn = true
        if self._hideSynBtn[combatType] then
            showSynBtn = false
        end
    elseif self._wndType == UIFightPrepare.MULTI_TEAM_SET then
        if self._combatDataList and #self._combatDataList > 1 then
            showSynBtn = true
        end
    end

    CS.ShowObject(self.mSynBtn, showSynBtn)

    local showOneKey = true
    if self._hideOneKeyBtn[combatType] or self._isReliefTroop then
        showOneKey = false
    end

    CS.ShowObject(self.mGoOnBtn, showOneKey)
end

function UIFightPrepare:ResetIsShowTryHero()
    if not self._combatType then
        self._isShowTryHero = false
        return
    end

    self._isShowTryHero = gModelBattle:CheckCombatPlayCampShowHeroFree(self._combatType)--self._curSelectType)
end

-- 仙境迷踪，boss挑战
function UIFightPrepare:BackFairylandBoss()
    local combatExtraData = self._battleData
    self:WndClose()

    local sid, bossRefId = combatExtraData.sid, combatExtraData.bossRefId
    FireEvent(EventNames.CHANGE_MAIN_BTN, 1)
    GF.OpenWndBottom("UIFlandBoss", { sid = sid, bossRefId = bossRefId, })
    GF.ChangeMap("LCityMap")
end

function UIFightPrepare:InitEvent()
    self:WndEventRecv(EventNames.ON_CHANGE_PREPARE_MONSTER, function(...)
        local monsterRefId = gModelBattle:GetMonsterId(self._combatType, self._battleData)
        local otherName = gModelBattle:GetOtherName(self._battleData)
        self._battleData.otherName = otherName
        local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterRefId)
        local targetPower = monsterFormationRef.monsterPower
        self:SetEnemyPower(targetPower or 0)
        -- local dataList = gModelBattle:FormatMonsterTreasures(monsterRefId)
        -- if #dataList>0 then
        -- 	self:ShowMonsterTreasure(dataList)
        -- end
        self:SetPlayerName()
    end)

    self:WndEventRecv(EventNames.ON_HERO_LIST_CHANGE, function()
        self:ShowHeroList()
    end)

    self:WndNetMsgRecv(LProtoIds.WonderlandHeroOpsResp, function()
        self:ShowHeroList()
    end)

    self:WndNetMsgRecv(LProtoIds.SetFormationResp, function(pb)
        self:OnSetFormationResp(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.SetFormationMultipleResp, function(...)
        self:OnSetFormationMultipleResp(...)
    end)

    self:WndNetMsgRecv(LProtoIds.DreamTripMonsterInfoResp, function(pb)
        self:OnDreamTripMonsterInfoResp(pb)
    end)

    self:WndEventRecv(EventNames.ON_GET_FORMATION_RET, function(type, teamIndex)
        self:OnGetFormationRet(type, teamIndex)
    end)

    local pbId = LProtoHelper.GetProtoId("GetFormationResp")
    self:WndEventRecv(EventNames.NET_ERROR_CODE, function(msgId, error, args, errorStr)
        if pbId == msgId then
            self:ShowBottomPart()
        end
    end)
    self:WndEventRecv(EventNames.ON_GET_FORMATION_LIST_RET, function()
        self:OnFormationDataRet()
    end)

    -- self:WndNetMsgRecv(LProtoIds.BossTowerDataInfoResp, function(pb)
    -- if not gModelBossTower:IsBossTowerCombat(self._combatType) then
    -- 	return
    -- end
    -- self:RefreshHeroFormation()
    -- end)

    self:WndNetMsgRecv(LProtoIds.MonsterPowerResp, function(pb)
        local powerData = pb.powerData
        local data = powerData[1]
        local emptyLineup = gModelCareSchool:GetCollegeConfigRefByKey("emptyLineup")
        local power = LUtil.ToInteger(tonumber(data.power))
        if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING and emptyLineup == data.monsterId then
            self:GetMeLibraryPower(power)
        else
            self:SetEnemyPower(power)
        end
    end)

    self:WndNetMsgRecv(LProtoIds.FormationExchangeResp, function(pb)
        local formationType = pb.formationType
        local targetType = pb.targetType
        if targetType == formationType and targetType == self._combatType then
            self:RefreshMultiTeamData()
            self:RefreshOnFormationRefId()
            self:RefreshFormationInfoRecord()
        end
    end)

    self:WndEventRecv(EventNames.ON_GUILD_BRAVE_CHANGE, function()
        GF.ShowMessage(ccClientText(14130))
        self:BackGuildBrave()
    end)
    self:WndEventRecv(EventNames.ON_ENDLESS_BUFF_RETURN, function()
        self:OnClickReturn()
    end)

    self:WndNetMsgRecv(LProtoIds.HeroPowerRefreshStateResp, function()
        self:RefreshChangePart()
    end)

    -- self:WndNetMsgRecv(LProtoIds.BossTowerFormationPowerResp, function(pb)
    -- 	local activity = self._sid
    -- 	if not activity then return end
    -- 	if activity ~= pb.sid then return end
    -- 	local power = tonumber(pb.power)
    -- 	local str = LUtil.FormatPowerShowStr(power)
    -- 	self:SetWndText(self.mMeFightNum,str)
    -- end)

    self:RegisterRedPointFunc(ModelRedPoint.SIMU_GROUP_FORMATION, function()
        self:RefreshGroupCombatRed()
    end)

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

function UIFightPrepare:InitLibraryScrollView()
    local targetId = self._battleData.targetId
    if not self._isOne then
        local heroDataList = gModelCareSchool:GetInitFromation(targetId, self._formationGrid)
        local cnt = 0
        local idToIndex = {}
        local indexToId = {}
        for i, v in pairs(heroDataList) do
            cnt = cnt + 1
            idToIndex[v.heroId] = v.pos
            indexToId[v.pos] = v.heroId
            self._emptyPos[v.pos] = false
        end
        self._selectHeroTable.cnt = cnt
        self._selectHeroTable.idToIndex = idToIndex
        self._selectHeroTable.indexToId = indexToId
        self._isOne = true
    end
    local ref = gModelCareSchool:GetCollegeLibraryCheckpointRefByRefId(targetId)
    local hero = string.split(ref.hero, ",")
    local dataList = {}
    local heroType = self._heroType
    local careerType = self._careerType
    for i, v in ipairs(hero) do
        local monsterRef = gModelHero:GetMonsterAttrByRefId(tonumber(v))
        --local refId = monsterRef.effectId
        local heroId = monsterRef.refId
        local race = monsterRef.raceType
        if heroType == 0 or heroType == race then
            if careerType == 0 or careerType == monsterRef.careerType then
                if not self._raceKeyList or self._raceKeyList[race] then
                    table.insert(dataList, heroId)
                end
            end
        end
    end

    local uiList = self._uiHeroScrollList
    if not uiList then
        uiList = self:GenerateUIHeroScrollList(function(...)
            self:OnDrawLibraryHeroCell(...)
        end)
    end
    uiList:RemoveAll()
    local cnt = #dataList

    for i = 1, cnt do
        local heroId = dataList[i]
        uiList:AddData(heroId, heroId)
    end
    uiList:RefreshList()
    local bEmpty = cnt < 1
    if bEmpty then
        self:CreateEmptyShow(1004)
    end
    CS.ShowObject(self.mNoRecord, bEmpty)
    self:ReqPower()
end

function UIFightPrepare:GetSelectBuffWndDataList()
    local refIdList = {}
    local monMap = self._isReliefTroop and self._reliefTroopData.monMap or {}
    for k, v in pairs(self._selectHeroTable.indexToId) do
        if monMap[v] then
            table.insert(refIdList, { id = v, isMon = true })
        else
            local data = gModelBattle:GetHeroData(self._combatType, v)
            if data then
                table.insert(refIdList, { id = data.refId, isMon = data.isMonster })
            end
            --local refId = gModelBattle:GetHeroRefId(self._combatType,v)
            --table.insert(refIdList,{id = refId})
        end
    end
    return refIdList
end

function UIFightPrepare:InitMirrorBattleUI()
    CS.ShowObject(self.mTeamMirror, true)
    self:SetWndClick(self.mBtnTeamMirrorA, function()
        self:ChangeSelectSide(1)
    end)
    self:SetWndClick(self.mBtnTeamMirrorB, function()
        self:ChangeSelectSide(2)
    end)
    self:SetWndTabText(self.mBtnTeamMirrorA, ccClientText(20908))
    self:SetWndTabText(self.mBtnTeamMirrorB, ccClientText(20909))

    local playerName = gModelPlayer:GetPlayerName()
    self._battleData.meName = playerName
    self._battleData.otherName = playerName
    self:SetPlayerName()

    self:InitMirrorHeroFormation()
end

function UIFightPrepare:GetOldAndNewIndex(curData, curPos)
    local curIndexPos = self._dragOriginPos[curData.index]
    local curOriginPosY = curIndexPos.y + curData.centerY
    local centerY = curData.centerY + curPos.y
    local swapIndex = nil
    local bMoveUp = true
    for k, v in pairs(self._dragIndexList) do
        if k ~= curData.index then
            local originPos = self._dragOriginPos[k]
            local dragKey = "_dragItem_" .. v
            local dragItemData = self._dragItemDataList[dragKey]
            local itemcenterY = dragItemData.centerY + originPos.y
            local itemmidH = dragItemData.midH
            local odis = centerY - itemcenterY
            local dis = odis
            if dis < 0 then
                dis = -dis
            end
            if dis < itemmidH then
                bMoveUp = curOriginPosY >= itemcenterY
                swapIndex = k
                break
            end
        end
    end
    if not swapIndex then
        return
    end

    local min = bMoveUp and (curData.index + 1) or (curData.index - 1)
    local max = bMoveUp and swapIndex or swapIndex

    local delta = bMoveUp and -1 or 1

    local newIndex
    local oldIndex
    for k = min, max, -delta do
        local keyIndex = self._dragIndexList[k]
        local dragKey = "_dragItem_" .. keyIndex
        local dragItemData = self._dragItemDataList[dragKey]
        newIndex = k + delta
        oldIndex = dragItemData.index
    end
end

function UIFightPrepare:GetSelectReliefMonCount()
    if not self._isReliefTroop then
        return 0
    end
    local monMap = self._reliefTroopData.monMap
    local cnt = 0
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local id = k
        if not monMap[id] then
            cnt = cnt + 1
        end
    end
    return cnt
end

function UIFightPrepare:InitTouchEvent()
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

function UIFightPrepare:IsHeroForbidSingle(heroId, refId, showTip)
    local curRecord = self._selectHeroTable.idToIndex
    local isOn = curRecord and curRecord[heroId]
    local isRefIdRepeat = self._refIdOnFormation and self._refIdOnFormation[refId]

    local isTest = self._combatType == LCombatTypeConst.COMBAT_TEST_BATTLE

    if not isTest and not isOn and isRefIdRepeat then
        if showTip then
            GF.ShowMessage(ccClientText(10123))
        end
        return true
    end
    local isForbid = gModelFormation:CheckLinkForbid(self._combatType, heroId, curRecord, nil, showTip)
    return isForbid
end

------------------------------------------------------------------

function UIFightPrepare:InitFormationList()
    self._formationUIList = {}
    local _combatType = self._combatType
    local dataList = {}
    local method = self._battleData.method
    CS.ShowObject(self.mVs, _combatType ~= LCombatTypeConst.COMBAT_GUILD_WAR)

    local isOpenPresetFormation = gModelFunctionOpen:CheckIsShow(16002020)
    if isOpenPresetFormation then
        isOpenPresetFormation = self._noPresetFormation[_combatType]
    end
    CS.ShowObject(self.mPresetFormationBtn, isOpenPresetFormation)

    local isOpenSkill = gModelFunctionOpen:CheckIsOpened(gModelDraconic.FuncIdEnum.Main)
    local isOpenDivine = gModelFunctionOpen:CheckIsOpened(36000000)

    if _combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        isOpenSkill = true
        isOpenDivine = true

        if gLGameLanguage:IsForeignRegion() then
            isOpenDivine = gModelFunctionOpen:CheckAreaOpen(36000000)
        end
    end
    -- local hideTrea = self._noNeedAskTreasure[_combatType]
    CS.ShowObject(self.mFormationSkillBtn, isOpenSkill)
    CS.ShowObject(self.mFormationDivineSkill, isOpenDivine)

    self:SetWndText(self.mFormationTitle, ccClientText(11003))
    self:SetWndButtonText(self.mBtnConfirmFormation, ccClientText(10102))
    self:SetWndClick(self.mBtnConfirmFormation, function()
        self:OnClickFormationConfirm()
    end)
    self:SetWndClick(self.mCloseFormationBg, function()
        self:CloseFormationBg()
    end)
    self:SetWndClick(self.mFormationBg, function()
        self:CloseFormationBg()
    end)
    self:SetWndClick(self.mFormationPanel, function()
    end)

    -- local isActive = self:IsPasvPartActive()
    -- CS.ShowObject(self.mPasvTrea,isActive)

    local isOpenPet = self:IsPetPartOpen()
    CS.ShowObject(self.mPetTrea, false) -- 要求先隐藏2024-3-21

    if _combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        local targetId = self._battleData.targetId
        self._skillPosList = {}
        -- self._treasureSkillList = {}
        local ref = gModelCareSchool:GetCollegeLibraryCheckpointRefByRefId(targetId)
        -- local treasurePos = string.split(ref.treasurePos,",")
        -- for i, v in ipairs(treasurePos) do
        -- 	self._skillPosList[tonumber(v)] = true
        -- end
        -- local treasure = string.split(ref.treasure,",")
        -- for i, v in ipairs(treasure) do
        -- 	local skill = string.split(v,"=")
        -- 	table.insert(self._treasureSkillList,tonumber(skill[1]))
        -- end
        local brieflyTips = ref.brieflyTips
        self._formationType = ref.defaultStation
        local station = string.split(ref.station, ",")
        local list = {}
        for i, v in ipairs(station) do
            list[tonumber(v)] = v
        end
        dataList = gModelFormation:GetFormationCfgList(list)
        self._heroMax = ref.heroNumMax

        local libraryList = gModelCareSchool:GetLibraryDoList()

        local isTips = ref and ref.Tips ~= ""
        if not libraryList[targetId] and isTips then
            self:OnClickBtnTip()
        end
        CS.ShowObject(self.mBtnTips, false)
        if brieflyTips > 0 then
            local tipsRef = gModelCareSchool:GetCollegeLibraryTxtRefByRefId(brieflyTips)
            method = ccLngText(tipsRef.text)
        end
        --self:SetWndClick(self.mBtnTips,function ()
        --	self:OnClickBtnTip()
        --end)
    else
        dataList = gModelFormation:GetFormationCfgList()
    end

    if not (string.isempty(method) or method == "0") then
        CS.ShowObject(self.mTipsBg, true)
        local str = string.gsub(method, "\\n", "\n")
        self:SetWndText(self.mTipsText, str)
    end

    self._curSelectFormationType = self._formationType
    local itemList = self:GetUIScroll("formationList")
    itemList:Create(self.mFormationList, dataList, function(...)
        self:OnDrawFormation(...)
    end)
end

-- 新伙伴主题，回到章节界面
function UIFightPrepare:BackActivityNewHeroTheme(actMode)
    local combatExtraData = self._battleData
    self:WndClose()

    local sid, chapterEntryId = combatExtraData.sid, combatExtraData.chapterEntryId
    FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.CITY)

    local wndName
    -- if actMode == ModelActivity.NEW_HERO_THEME_A then
    -- 	wndName = "UIActNewHeroTheme"
    -- if actMode == ModelActivity.NEW_HERO_THEME_B then
    -- 	wndName = "UIActNewHeroThemeB"
    if actMode == ModelActivity.MODEL_ACTIVITY_TYPE_132 then
        wndName = "UIActPtCopy"
    end

    if wndName then
        GF.OpenWnd(wndName, { sid = sid, page = 2, })
        -- GF.OpenWnd("UIActNewHeroThemeStory",
        -- 		{sid = sid, entryId = chapterEntryId, activityMode = actMode})
    end

    GF.ChangeMap("LCityMap")
end

function UIFightPrepare:OnDrawEndlessHero(list, item, itemdata, itempos)
    local heroTrans = self:FindWndTrans(item, "Hero/HeroIcon")
    local hireTag = self:FindWndTrans(item, "hireTag")
    local lvTxtTrans = self:FindWndTrans(item, "lvTxt")

    local id, refId, star, level, grade, fightPower = itemdata.id, itemdata.refId, itemdata.star, itemdata.lv, itemdata.grade, itemdata.fightPower
    local skin = itemdata.skin
    local isResonance = itemdata.isResonance or 0
    local treeInfo = itemdata.treeInfo
    local pos = self._selectHeroTable.idToIndex[id]
    local isSelect = pos ~= nil
    local isLock = self:IsHeroForbidSingle(id, refId)
    local otherMappingIsSel = self:ShowMappingHeroLock(id)
    isLock = isLock or otherMappingIsSel

    if lvTxtTrans then
        self:SetWndText(lvTxtTrans, level)
        local lvColor, lvMat = LUtil.GetResonanceColor(isResonance)
        self:SetXUITextTransColor(lvTxtTrans, lvColor)
        if lvMat then
            self:SetWndTextMat(lvTxtTrans, lvMat)
        end
    end

    local instanceId = item:GetInstanceID()
    local heroIcon = self:GetCommonIcon(instanceId)
    heroIcon:Create(heroTrans)

    local herodata = {}
    herodata.trans = heroTrans
    herodata.id = id
    herodata.refId = refId
    herodata.star = star
    herodata.level = level
    herodata.showLock = isLock
    herodata.skin = skin
    herodata.selected = isSelect
    herodata.showName = self._showName
    herodata.showType = self._showType
    herodata.treeInfo = treeInfo
    herodata.form = itemdata.form

    heroIcon:SetHeroDataSet(herodata)
    heroIcon:SetNoShowLv(true)
    heroIcon:SetShowLvMask(1)
    heroIcon:DoApply()

    local isHire = (itemdata.heroType and itemdata.heroType == 2) and true or false
    self:SetWndClick(heroTrans, function()
        if (otherMappingIsSel) then
            GF.ShowMessage(ccClientText(38422))
        else
            self:OnSelectWonderHero(herodata)
        end
    end)
    self:SetIconClickScale(heroTrans, true)
    self:SetWndLongClick(heroTrans, function()
        gModelHero:FindHeroPowStateById(id)
        local data = {
            id = id,
            refId = refId,
            level = level,
            star = star,
            grade = grade,
            fightPower = fightPower,
            isResonance = isResonance,
            skin = skin,
            isEndlesHero = itemdata.playerId and itemdata.playerId ~= gModelPlayer:GetPlayerId(),
            treeInfo = treeInfo,
        }
        gModelHero:ReqShowHeroTip(itemdata.playerId, data)
    end, 0.8, false)

    CS.ShowObject(hireTag, isHire)
end

function UIFightPrepare:UIDragOnEnd(dragKey, eventData)
    if self._dragItemData and self._dragItemData.key == dragKey then
        local dragItemData = self._dragItemData
        local item = dragItemData.item
        local tween = dragItemData.tween
        if tween then
            tween:Kill(false)
        end
        local originPos = self._dragOriginPos[dragItemData.index]
        tween = item:DOLocalMoveY(originPos.y, 0.15)
        tween:OnComplete(function()
            local dragItemData = self._dragItemDataList[dragKey]
            if dragItemData then
                dragItemData.tween = nil
            end
        end)
        dragItemData.tween = tween
        tween:PlayForward()
    end
    self._dragItemData = nil
end

function UIFightPrepare:OnDrawSkill(list, item, itemdata, itempos)
    local iconBg = self:FindWndTrans(item, "iconBg")
    local icon = self:FindWndTrans(item, "icon")
    local mask = self:FindWndTrans(item, "mask")
    local maskImage = self:FindWndTrans(mask, "Image")
    local lock = self:FindWndTrans(item, "lock")
    local UIText = self:FindWndTrans(item, "UIText")

    local isLock = itemdata.state == 0
    CS.ShowObject(UIText, false)
    CS.ShowObject(icon, not itemdata.isEmpty and not isLock)
    CS.ShowObject(lock, isLock)
    if itemdata.isEmpty or isLock then
        return
    end
    -- local skillId = itemdata.skillId

    -- local info = gModelTreasure:GetSkillInfo(skillId)
    local has = false

    -- if info then
    -- 	has = true
    -- 	self:SetWndEasyImage(iconBg,info.iconBg)

    -- local iconPath = gModelTreasure:GetTreasureIconByRefId(info.refId, itemdata.exhibitionInfo and itemdata.exhibitionInfo.skin or nil)
    -- self:SetWndEasyImage(icon,iconPath)
    -- end

    CS.ShowObject(mask, false)
    CS.ShowObject(icon, has)

    -- local clickFunc = function()
    -- 	gModelGeneral:OpenOnlyTreasureTip({treasureData = itemdata.exhibitionInfo})
    -- end
    if itemdata.exhibitionInfo and has then
        -- self:SetWndClick(item,clickFunc)
    else
        self:SetWndClick(item, nil)
    end

end

function UIFightPrepare:OnDrawMultiTeamHero(list, item, itemdata, itempos)
    local hero = self:FindWndTrans(item, "Hero")
    local heroTrans = self:FindWndTrans(hero, "HeroIcon")
    local lvTxtTrans = self:FindWndTrans(item, "lvTxt")

    local instanceId = item:GetInstanceID()
    local heroIcon = self:GetCommonIcon(instanceId)
    heroIcon:Create(heroTrans)

    local id, refId, star, level, grade, fightPower = itemdata.id, itemdata.refId, itemdata.star, itemdata.lv, itemdata.grade, itemdata.fightPower
    local skin = itemdata.skin
    local isResonance = itemdata.isResonance or 0
    local treeInfo = itemdata.treeInfo
    local selState = self:GetMultiHeroSelectState(id)

    local showLock = self:IsHeroForbid(id, refId)

    self:SetWndText(lvTxtTrans, level)
    local lvColor, lvMat = LUtil.GetResonanceColor(isResonance)
    self:SetXUITextTransColor(lvTxtTrans, lvColor)
    if lvMat then
        self:SetWndTextMat(lvTxtTrans, lvMat)
    end

    local isSelect = selState == 1
    -- local isHighStageRace = gModelHighStageRace:IsHighStageRace(self._combatType)
    local lockHeroList
    -- if(isHighStageRace)then
    -- 	lockHeroList = gModelHighStageRace:GetLockHeroList()
    -- end
    if (lockHeroList and lockHeroList[refId]) then
        showLock = true
        isSelect = false
    end
    local otherMappingId = gModelResonance:GetMappingOtherId(itemdata.id)
    local otherMappingIsSel = false
    if (otherMappingId) then
        local otherMappingSelState = self:GetMultiHeroSelectState(otherMappingId)
        otherMappingIsSel = otherMappingSelState ~= 0
    end
    if (otherMappingIsSel) then
        showLock = true
        isSelect = false
    end
    local herodata = {}
    herodata.trans = heroTrans
    herodata.id = id
    herodata.refId = refId
    herodata.star = star
    herodata.level = level
    herodata.showLock = showLock
    herodata.skin = skin
    herodata.selected = isSelect
    herodata.isResonance = isResonance
    herodata.showName = self._showName
    herodata.showType = self._showType
    herodata.endTime = itemdata.endTime
    herodata.isTry = itemdata.isTry
    herodata.treeInfo = treeInfo
    herodata.showTire = self:IsShowTire()

    heroIcon:SetHeroDataSet(herodata)
    heroIcon:SetNoShowLv(true)
    heroIcon:SetShowLvMask(1)
    heroIcon:DoApply()

    self:SetWndClick(heroTrans, function()
        if (otherMappingIsSel) then
            GF.ShowMessage(ccClientText(38422))
        else
            self:OnClickMultiTeamHero(itemdata)
        end
    end)

    self:SetIconClickScale(heroTrans, true)
    self:SetWndLongClick(heroTrans, function()
        local data = {
            id = id,
            refId = refId,
            level = level,
            star = star,
            grade = grade,
            fightPower = fightPower,
            isResonance = isResonance,
            skin = skin,
            treeInfo = treeInfo,
        }
        gModelHero:ReqShowHeroTip("", data)
    end, 0.8, false)
end

function UIFightPrepare:FormationReliefTroopData(combatData)
    if not self._isReliefTroop then
        return
    end
    local grids = combatData.grids
    local gridsHero = {}
    local gridsMon = {}
    local teamIndex = self._teamIndex or 0
    local monMap = self._reliefTroopData.monMap
    for k, v in ipairs(grids) do
        if monMap[v.id] then
            table.insert(gridsMon, v)
        else
            table.insert(gridsHero, v)
        end
    end

    if #gridsHero > 0 then
        combatData.formationA = {
            combatType = combatData.combatType,
            formationRefId = combatData.formationRefId,
            grids = gridsHero,
            teamIndex = teamIndex,
            -- artifact = 0,【G公共支持】删除神器功能相关数据
            -- treasureSkilIds = {},
        }
    end

    combatData.relFormation = {
        combatType = combatData.combatType,
        formationRefId = combatData.formationRefId,
        grids = gridsMon,
        teamIndex = teamIndex,
        -- artifact = 0,【G公共支持】删除神器功能相关数据
        -- treasureSkilIds = combatData.treasureSkilIds,
    }

end

function UIFightPrepare:OnSwap(oldIndex, newIndex)
    self._oldIndex = oldIndex
    self._newIndex = newIndex

    local oldNum = oldIndex - 1
    local isOldSameCurSel = oldNum == self._teamIndex

    local newNum = newIndex - 1
    local isNewSameCurSel = newNum == self._teamIndex

    gModelFormation:OnFormationExchangeReq(self._combatType, newNum, self._combatType, oldNum)

    local teamIndex
    if isOldSameCurSel then
        teamIndex = newNum
    elseif isNewSameCurSel then
        teamIndex = oldNum
    end

    if teamIndex then
        self._teamIndex = teamIndex
        self._curSelectType = teamIndex
    end

    local tList = {}
    for i, v in ipairs(self._swapDataList) do
        local teamIndex = v.teamIndex
        if teamIndex == oldNum then
            table.insert(tList, {
                teamIndex = newNum,
                name = string.replace(ccClientText(21817), newNum + 1),
                index = i,
            })
        elseif teamIndex == newNum then
            table.insert(tList, {
                teamIndex = oldNum,
                name = string.replace(ccClientText(21817), oldNum + 1),
                index = i,
            })
        else
            table.insert(tList, {
                teamIndex = teamIndex,
                name = string.replace(ccClientText(21817), teamIndex + 1),
                index = i,
            })
        end
    end

    table.sort(tList, function(a, b)
        return a.index < b.index
    end)
    local list = {}
    for i, v in ipairs(tList) do
        table.insert(list, {
            teamIndex = v.teamIndex,
            name = v.name,
        })
    end
    self:InitSwapList(list)
end

function UIFightPrepare:Examine()
    if self._showFormation then
        self:PlayShowFormation()
    end
end

function UIFightPrepare:RefreshBtnTipShow()
    local isShow = false
    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        local targetId = self._battleData.targetId
        local ref = gModelCareSchool:GetCollegeLibraryCheckpointRefByRefId(targetId)
        isShow = ref and not string.isempty(ref.Tips)
    elseif self._combatType == LCombatTypeConst.COMBAT_GUILD_BRAVE then
        isShow = false
    elseif self._combatType == LCombatTypeConst.COMBAT_TYPE_32 then
        isShow = false
    elseif self._combatType == LCombatTypeConst.COMBAT_CRUSADE_AGAINST then
        isShow = false
    else
        isShow = gModelFunctionOpen:CheckIsShow(16002040)
    end

    if self._wndType == UIFightPrepare.NORMAL then
        if self._combatType == LCombatTypeConst.COMBAT_MAIN then
            local hideInstanceId = gModelInstance:GetInstancePara("heachingHidden")

            local battleNode = gModelInstance:GetBattleNode()

            if battleNode >= hideInstanceId then
                isShow = false
            else
                isShow = true
            end
        else
            isShow = false
        end
    else
        isShow = false
    end

    CS.ShowObject(self.mBtnTips, isShow)
end

function UIFightPrepare:BackTowerDifficulty()
    gLFightManager:PrepareGoToBattle(self._combatType, { isBattleShow = true })
    self:WndClose()
end

function UIFightPrepare:ReturnFDTGame()
    local returnFunc = self._returnFunc
    if returnFunc then
        returnFunc()
    else
        gModelFastDreamTrip:EnterNormalDreamTripMap()
    end
end

function UIFightPrepare:OnDrawLibraryHeroCell(list, item, itemdata, itempos)
    if not self._commonIconList then
        return
    end
    local instanceId = item:GetInstanceID()
    local hero = CS.FindTrans(item, "Hero")
    local heroTrans = CS.FindTrans(hero, "HeroIcon")

    local heroId = itemdata
    local pos = self._selectHeroTable.idToIndex[heroId]
    local isSelect = pos ~= nil

    local monsterRef = gModelHero:GetMonsterAttrByRefId(heroId)

    local isResonance = 0
    local star, lv = monsterRef.starLv, monsterRef.lv

    local otherMappingIsSel = self:ShowMappingHeroLock(heroId)
    local showLock = otherMappingIsSel

    local heroPara = {
        id = heroId,
        refId = heroId,
        star = star,
        level = lv,
        trans = heroTrans,
        selected = isSelect,
        showLock = showLock,
        isResonance = 0,
        skin = 0,
        isMon = true,
        showName = self._showName,
        showType = self._showType,
    }

    local iconCls = self:GetCommonIcon(instanceId)
    iconCls:Create(heroTrans)

    iconCls:SetHeroDataSet(heroPara)
    iconCls:SetNoShowLv(true)
    iconCls:SetShowLvMask(1)
    iconCls:DoApply()

    local lvTxtTrans = self:FindWndTrans(item, "lvTxt")
    if lvTxtTrans then
        self:SetWndText(lvTxtTrans, lv)
        local lvColor, lvMat = LUtil.GetResonanceColor(isResonance)
        self:SetXUITextTransColor(lvTxtTrans, lvColor)
        if lvMat then
            self:SetWndTextMat(lvTxtTrans, lvMat)
        end
    end

    self:SetIconClickScale(heroTrans, true)

    self:SetWndClick(heroTrans, function()
        if (otherMappingIsSel) then
            GF.ShowMessage(ccClientText(38422))
        else
            self:OnClickLibraryHero(heroPara)
        end
    end)

    self:SetWndLongClick(heroTrans, function()
        self:OnLongClickLibraryHero(heroPara)
    end, 0.7, true)
end

function UIFightPrepare:StartTestBattle()
    local monsterA = self._battleData.monsterA
    if not monsterA then
        local cnt = self._selectHeroTable.cnt
        if cnt <= 0 then
            GF.ShowMessage(ccClientText(10127))
            return
        end
    end

    self:SendNetMessage(self._combatType)
end

function UIFightPrepare:HeroUp(heroId, heroIndex, isMon)
    if not heroId then
        return
    end
    if not isMon then
        gModelHero:FindHeroPowStateById(heroId)
    end
    local emptyPos = self._emptyPos
    local selectTable = self._selectHeroTable
    selectTable.indexToId[heroIndex] = heroId
    selectTable.idToIndex[heroId] = heroIndex
    emptyPos[heroIndex] = false
    self:RefreshHeroCnt(selectTable)
    self:RefreshHeroLockState()
    self:RefreshChangePart()
end

function UIFightPrepare:UIDragOnBegin(dragKey, eventData)
    self._dragItemData = nil

    local itemData = self._dragItemDataList[dragKey]
    if not itemData then
        return
    end

    local item = itemData.item
    self._dragItemData = itemData
    item:SetAsLastSibling()
    local camera = eventData.pressEventCamera
    local pos = camera:ScreenToWorldPoint(eventData.position)
    pos = item.parent:InverseTransformPoint(pos)
    self._dragOffsetPosY = item.localPosition.y - pos.y
end

function UIFightPrepare:RefreshTeamItemShow()
    if not self._swapTransList or not self._swapDataList then
        return
    end
    local dataList = self._swapDataList
    for i, v in ipairs(self._swapTransList) do
        local data = dataList[i]
        local isShow = data ~= nil
        if isShow then
            self:OnDrawTeamItem(v, data)
        end
        CS.ShowObject(v, isShow)
    end
end

function UIFightPrepare:SetEnemyPower(power)
    local str = LUtil.FormatPowerShowStr(power)
    self:SetWndText(self.mOtherFightNum, str)
end

function UIFightPrepare:ReturnWonderland()

    if gModelWonderland:IsInMap() then
        GF.OpenWndBottom("UIEden", { isFromBattle = true })
    else
        GF.OpenWndBottom("UIEdenFront")
    end

    gModelWonderland:EnterWonderMap()
end

function UIFightPrepare:InitData()
    self._bottomUIOrgPos = self.mMainBattleBot.anchoredPosition
    self._showRaceBtnList = false
    self._raceType = self:GetWndArg("raceType") or 0              -- 种猪
    self._careerType = self:GetWndArg("careerType") or 0            -- 职业
    self._heroType = 0            -- 英雄种类 0:所有种族
    self._emptyPos = { true, true, true, true, true, true }       -- 空位置

    self._chooseItem = 0
    self._heroMax = LCombatFormationConst.FIGURE_MAX
    self._mapOffset = -2.1            -- 场景摄像机偏移位置
    self._curFightPower = 0                -- 当前战斗力


    --神器特效缩放大小
    -- 【G公共支持】删除神器功能相关数据
    -- self._artifact= 0
    self._clickBattleKey = "clickBattleCountDownKey"
    self._clickBattleCD = 1 -- 战斗开始间隔时间
    self._isClickBattle = true
    self._isSetFormation = false

    self._selectHeroTable = {
        cnt = 0,
        idToIndex = {},
        indexToId = {},
    }

    self._showFormation = false
    self._needClose = false

    self._teamSide = 1 --编辑左边队伍, 2 编辑右边队伍

    self._combatType = LCombatTypeConst.COMBAT_MAIN
    self._formationType = 1     -- 当前阵型类型
    self._enemyList = nil                                                               -- 敌方英雄数据
    self._isHeroEnemy = true

    self._teamIndex = 0

    self._pageFunList = {
        [1] = {
            hideFun = function()
                self:HideHeroPage()
            end,
            showFun = function()
                self:ShowHeroPage()
            end
        },

    }

    self._channgleBossTypes = {
        [LCombatTypeConst.COMBAT_FAIRYLAND_BOSS] = true,
        [LCombatTypeConst.COMBAT_HALLOWEEN_BOSS] = true,
        [LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS] = true,
    }

    self._dontReqFormationTypes = {
        [LCombatTypeConst.COMBAT_BATTLE_VIDEO] = true,
        [LCombatTypeConst.COMBAT_TEST_BATTLE] = true,
    }

    --self._isSwapListType = {
    --	[LCombatTypeConst.COMBAT_CROSSGRADING_RANK] = true,
    --}

    --显示怪物阵容buff
    self._showMonsterType = {
        [LCombatTypeConst.COMBAT_MAIN] = true,
        [LCombatTypeConst.COMBAT_DUNGEON_DAILY] = true,
        [LCombatTypeConst.COMBAT_TOWER_BATTLE] = true,
        [LCombatTypeConst.COMBAT_TOWER_WATER] = true,
        [LCombatTypeConst.COMBAT_TOWER_FIRE] = true,
        [LCombatTypeConst.COMBAT_TOWER_WIND] = true,
        [LCombatTypeConst.COMBAT_TOWER_LIGHT_DARK] = true,
        [LCombatTypeConst.COMBAT_GUILD_BRAVE] = true,
        [LCombatTypeConst.COMBAT_ACTIVITY] = true,
        [LCombatTypeConst.COMBAT_FAIRYLAND_BOSS] = true,
        [LCombatTypeConst.COMBAT_HALLOWEEN_BOSS] = true,
        [LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS] = true,
        [LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER] = true,
        -- [LCombatTypeConst.COMBAT_NEW_HERO_THEME_B_CHAPTER] = true,
        [LCombatTypeConst.COMBAT_ENDLES] = true,
        [LCombatTypeConst.COMBAT_ENDLES_WATER] = true,
        [LCombatTypeConst.COMBAT_ENDLES_FIRE] = true,
        [LCombatTypeConst.COMBAT_ENDLES_WIND] = true,
        [LCombatTypeConst.COMBAT_ENDLES_LIGHT_DARK] = true,
        [LCombatTypeConst.COMBAT_INVASION_BOSS] = true,
        [LCombatTypeConst.COMBAT_TYPE_23] = true,
        [LCombatTypeConst.COMBAT_TYPE_32] = true,
    }

    self._returnFuncList = {
        [LCombatTypeConst.COMBAT_MAIN] = function()
            return self:BackBtIdle()
        end,
        [LCombatTypeConst.COMBAT_ARENA_DEFEND] = function()
            return self:BackArenaRank()
        end,
        [LCombatTypeConst.COMBAT_ARENA_ATTACK] = function()
            return self:BackArenaRank()
        end,
        [LCombatTypeConst.COMBAT_ARENA_PEAK_ATTACK] = function()
            return self:BackArenaPeak()
        end,
        [LCombatTypeConst.COMBAT_TOWER_BATTLE] = function()
            return self:BackTower()
        end,
        [LCombatTypeConst.COMBAT_TOWER_WATER] = function()
            return self:BackTower()
        end,
        [LCombatTypeConst.COMBAT_TOWER_FIRE] = function()
            return self:BackTower()
        end,
        [LCombatTypeConst.COMBAT_TOWER_WIND] = function()
            return self:BackTower()
        end,
        [LCombatTypeConst.COMBAT_TOWER_LIGHT_DARK] = function()
            return self:BackTower()
        end,
        [LCombatTypeConst.COMBAT_TYPE_75] = function()
            return self:BackTowerDifficulty()
        end,
        [LCombatTypeConst.COMBAT_GUILD_BRAVE] = function()
            return self:BackGuildBrave()
        end,
        -- [LCombatTypeConst.COMBAT_TYPE_32] = function () return self:BackGuildBoss() end,
        [LCombatTypeConst.COMBAT_DUNGEON_DAILY] = function()
            return self:BackDungeonDetail()
        end,
        [LCombatTypeConst.COMBAT_WONDERLAND] = function()
            return self:ReturnWonderland()
        end,
        [LCombatTypeConst.COMBAT_DESIRETRAIL] = function()
            return self:ReturnDesireTrail()
        end,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_STATIC] = function()
            return self:ReturnTimeCorridor()
        end,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_TIME] = function()
            return self:ReturnTimeCorridor()
        end,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_THEATER] = function()
            return self:ReturnTimeCorridor()
        end,
        [LCombatTypeConst.COMBAT_ACTIVITY] = function()
            return self:BackActivity()
        end,
        [LCombatTypeConst.COMBAT_FAIRYLAND_BOSS] = function()
            return self:BackFairylandBoss()
        end,
        -- [LCombatTypeConst.COMBAT_HALLOWEEN_BOSS] = function () return self:BackHalloweenBoss() end,
        [LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS] = function()
            return self:BackSweetCountryBoss()
        end,
        -- [LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER] = function () return self:BackActivityNewHeroTheme(ModelActivity.NEW_HERO_THEME_A) end,
        -- [LCombatTypeConst.COMBAT_NEW_HERO_THEME_B_CHAPTER] = function () return self:BackActivityNewHeroTheme(ModelActivity.NEW_HERO_THEME_B) end,
        [LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY] = function()
            return self:BackActivityNewHeroTheme(ModelActivity.MODEL_ACTIVITY_TYPE_132)
        end,
        [LCombatTypeConst.COMBAT_PK] = function()
            return self:BackMainMap()
        end,
        [LCombatTypeConst.COMBAT_ENDLES] = function()
            return self:ReturnEndles(1)
        end,
        [LCombatTypeConst.COMBAT_ENDLES_WATER] = function()
            return self:ReturnEndles(2)
        end,
        [LCombatTypeConst.COMBAT_ENDLES_FIRE] = function()
            return self:ReturnEndles(2)
        end,
        [LCombatTypeConst.COMBAT_ENDLES_WIND] = function()
            return self:ReturnEndles(2)
        end,
        [LCombatTypeConst.COMBAT_ENDLES_LIGHT_DARK] = function()
            return self:ReturnEndles(2)
        end,
        -- [LCombatTypeConst.COMBAT_CROSS_SERVER_LADDER] = function () return self:BackCrossServerLadder() end,
        -- [LCombatTypeConst.COMBAT_CROSS_SERVER_CHAMPION] = function () return self:BackCrossServerChampion() end,
        [LCombatTypeConst.COMBAT_GUILD_WAR] = function()
            return self:ReturnGuildMelee()
        end,
        [LCombatTypeConst.COMBAT_INVASION] = function()
            return self:ReturnInvasion()
        end,
        [LCombatTypeConst.COMBAT_INVASION_BOSS] = function()
            return self:ReturnInvasion(true)
        end,
        [LCombatTypeConst.COMBAT_TACTICAL_TRAINING] = function()
            return self:ReturnTraining()
        end,
        [LCombatTypeConst.COMBAT_TACTICAL_SIMULATION] = function()
            return self:ReturnSimulation()
        end,
        [LCombatTypeConst.COMBAT_TACTICAL_SIMULATION_2] = function()
            return self:ReturnSimulation()
        end,
        [LCombatTypeConst.COMBAT_TYPE_23] = function()
            return self:Return23()
        end,
        [LCombatTypeConst.COMBAT_ACTIVITY_DREAMTRIP] = function()
            return self:ReturnActivityDreamTrip()
        end,
        [LCombatTypeConst.COMBAT_CRUSADE_AGAINST] = function()
            return self:ReturnCrusadeAgainst()
        end,
        [LCombatTypeConst.COMBAT_BADGE_GAME] = function()
            return self:ReturnBadgeGame()
        end,
        [LCombatTypeConst.COMBAT_ACTIVITY_155] = function()
            return self:ReturnActivity155()
        end,
        [LCombatTypeConst.COMBAT_DREAMTRIP] = function()
            return self:ReturnFDTGame()
        end,
        [LCombatTypeConst.COMBAT_WAR_TEMPLE] = function()
            return self:ReturnWarTemple()
        end,
        [LCombatTypeConst.COMBAT_CROSS_WAR] = function()
            return self:ReturnCrossWar()
        end,
        [LCombatTypeConst.COMBAT_TYPE_41] = function()
            return self:ReturnPetDreamLand()
        end,
        [LCombatTypeConst.COMBAT_TYPE_42] = function()
            return self:ReturnPetDreamLand()
        end,
        [LCombatTypeConst.COMBAT_TYPE_44] = function()
            return gModelBattle:GetReturnFun(LCombatTypeConst.COMBAT_TYPE_44)()
        end,
        [LCombatTypeConst.COMBAT_TYPE_47] = function()
            return self:ReturnType47()
        end,


        -- [LCombatTypeConst.COMBAT_TYPE_34] = function () return self:ReturnNaturalPartner() end,【G公共支持】删除本命英雄功能
    }

    -- local compareFightType = gModelBossTower:GetBossTowerConfigRefByKey("compareFightType")
    -- self._returnFuncList[compareFightType] = function()
    -- 	local func = gModelBattle:GetReturnFun(compareFightType)
    -- 	if func then
    -- 		func({sid = self._sid})
    -- 	end
    -- end

    self._swapTransList = {}

    self._formationIconList = {
        [1] = "formation_icon_1",
        [2] = "formation_icon_2",
        [3] = "formation_icon_3",
        [4] = "formation_icon_4",
        [5] = "formation_icon_5",
        [6] = "formation_icon_6",

    }


    --不需要弹等级限制
    self._noCheckCombatTypes = {
        [LCombatTypeConst.COMBAT_TACTICAL_TRAINING] = true,
        [LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER] = true,
        -- [LCombatTypeConst.COMBAT_NEW_HERO_THEME_B_CHAPTER] = true,
        [LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY] = true,
        --[compareFightType] = true,
    }

    --不用弹宝物提示弹窗
    -- self._noNeedAskTreasure = {

    -- }

    --不显示编队按钮
    self._noPresetFormation = {
        [LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER] = true,
        -- [LCombatTypeConst.COMBAT_NEW_HERO_THEME_B_CHAPTER] = true,
        -- [LCombatTypeConst.COMBAT_TYPE_23] = true,

        [LCombatTypeConst.COMBAT_TACTICAL_TRAINING] = false,
        [LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY] = true,
        --[LCombatTypeConst.COMBAT_TACTICAL_SIMULATION] = true,
    }
    self._hideSynBtn = {
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_STATIC] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_TIME] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_THEATER] = true,
        [LCombatTypeConst.COMBAT_WONDERLAND] = true,
        [LCombatTypeConst.COMBAT_DESIRETRAIL] = true,
        [LCombatTypeConst.COMBAT_INVASION] = true,
        [LCombatTypeConst.COMBAT_INVASION_BOSS] = true,
    }
    self._hideOneKeyBtn = {
        [LCombatTypeConst.COMBAT_TACTICAL_TRAINING] = true,
        [LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_STATIC] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_TIME] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_THEATER] = true,
        [LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY] = true,
        [LCombatTypeConst.COMBAT_ACTIVITY_155] = true,
        [LCombatTypeConst.COMBAT_CRUSADE_AGAINST] = true,
    }

    self._hideShareBtn = {
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_STATIC] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_TIME] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_THEATER] = true,
        [LCombatTypeConst.COMBAT_WONDERLAND] = true,
        [LCombatTypeConst.COMBAT_DESIRETRAIL] = true,
    }

    self._simulateFightType = {
        [LCombatTypeConst.COMBAT_TYPE_25] = true,
        [LCombatTypeConst.COMBAT_TYPE_251] = true,
        [LCombatTypeConst.COMBAT_TYPE_252] = true,
    }

    self._specialCombatTypeList = {
        [LCombatTypeConst.COMBAT_ACTIVITY_DREAMTRIP] = {
            getFormationType = LCombatTypeConst.COMBAT_MAIN,
            formationData = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_MAIN),
            getMonsterReq = function(targetId)
                gModelDreamTrip:OnDreamTripMonsterInfoReq(targetId, self._sid)
            end
        },
        [LCombatTypeConst.COMBAT_ACTIVITY_155] = {
            getFormationType = LCombatTypeConst.COMBAT_MAIN,
            formationData = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_MAIN),
        },
        -- [LCombatTypeConst.COMBAT_DESIRETRAIL] = {
        --     getFormationType = LCombatTypeConst.COMBAT_DESIRETRAIL,
        --     formationData = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_DESIRETRAIL),
        -- },

        -- 【G公共支持】删除本命英雄功能
        -- [LCombatTypeConst.COMBAT_TYPE_34] = {
        -- 	getFormationType = LCombatTypeConst.COMBAT_TYPE_34,
        -- 	formationData = gModelNaturalPartner:GemGetDestinyHeroGetFormation(),
        -- },
    }
end

function UIFightPrepare:OnDrawHeroCell(list, item, itemdata, itempos)
    local instanceId = item:GetInstanceID()
    local hero = CS.FindTrans(item, "Hero")
    local heroTrans = CS.FindTrans(hero, "HeroIcon")

    local heroId = itemdata
    local pos = self._selectHeroTable.idToIndex[heroId]
    local isSelect = pos ~= nil

    local heroSeverData = gModelHero:GetHeroServerDataById(heroId)
    if not heroSeverData then
        return
    end
    local refId = heroSeverData.refId
    local isResonance = heroSeverData.isResonance
    local star, lv = heroSeverData.star, heroSeverData.lv
    local skin = heroSeverData.skin
    local treeInfo = heroSeverData.treeInfo
    local endTime = heroSeverData.endTime
    local isTry = heroSeverData.isTry
    local showLock = self:IsHeroForbidSingle(heroId, refId)

    local otherMappingIsSel = self:ShowMappingHeroLock(heroId)
    if (otherMappingIsSel) then
        showLock = true
        isSelect = false
    end

    local heroPara = {
        id = heroId,
        refId = refId,
        star = star,
        level = lv,
        trans = heroTrans,
        selected = isSelect,
        showLock = showLock,
        isResonance = isResonance,
        skin = skin,
        showName = self._showName,
        showType = self._showType,
        treeInfo = treeInfo,
        endTime = endTime,
        isTry = isTry,
    }

    local iconCls = self:GetCommonIcon(instanceId)

    iconCls:Create(heroTrans)
    iconCls:SetHeroDataSet(heroPara)
    iconCls:SetNoShowLv(true)
    iconCls:SetShowLvMask(1)
    iconCls:DoApply()

    local lvTxtTrans = self:FindWndTrans(item, "lvTxt")
    if lvTxtTrans then
        self:SetWndText(lvTxtTrans, lv)
        local lvColor, lvMat = LUtil.GetResonanceColor(isResonance)
        self:SetXUITextTransColor(lvTxtTrans, lvColor)
        if lvMat then
            self:SetWndTextMat(lvTxtTrans, lvMat)
        end
    end

    self:SetIconClickScale(heroTrans, true)

    self:SetWndClick(heroTrans, function()
        if (otherMappingIsSel) then
            GF.ShowMessage(ccClientText(38422))
        else
            self:OnClickHero(heroId)
        end
    end)
    self:SetWndLongClick(heroTrans, function()
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

------------------------------------------------------------------
---刷新左边队伍列表信息
function UIFightPrepare:InitTeamAHeroFormation(formation, isFake)
    local formationRefId = nil
    self:ClearSelectTable()
    self._treasureSkilIds = {}
    self._strategyId = 0
    self._pasvSkillList = {}
    self._petFights = {}
    self._petHelps = {}
    local combatType = self._combatType

    if formation then
        if combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
            --当模式为教学挑战部分的时候 取消主线剧情的阵容的获取
            formationRefId = self._formationType

            self._treasureSkilIds = gModelCareSchool:GetDraconicId(self._battleData.targetId)

        else
            formationRefId = formation.formationRefId == 0 and 1 or formation.formationRefId
            -- local isBossTower = gModelBossTower:IsBossTowerCombat(combatType)
            -- if isBossTower then
            -- local grids = formation.grids or {}
            -- for i,v in pairs(grids) do
            -- 	local heroId = tonumber(v.id)
            -- 	local index = i
            -- 	self._selectHeroTable.idToIndex[heroId] = index
            -- 	self._selectHeroTable.indexToId[index] = heroId
            -- 	self._emptyPos[index] = false
            -- end
            -- else
            local heroGridData = gModelFormation:GetMapFormationData(formation)
            for k, v in pairs(heroGridData) do
                local heroId = v.heroId
                local index = v.posIndex
                self._selectHeroTable.idToIndex[heroId] = index
                self._selectHeroTable.indexToId[index] = heroId
                self._emptyPos[index] = false
            end
            -- end
            self:RefreshHeroCnt(self._selectHeroTable)
            self._treasureSkilIds = formation.treasureSkilIds
            self._divineWeaponStarRefIds = formation.divineWeaponStarRefIds
            self._strategyId = formation.tactics or 0
            -- self._pasvSkillList = formation.treasurePassiveSkill
            self._petFights = formation.petFights
            self._petHelps = formation.petHelps

        end
    else
        if combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
            formationRefId = self._formationType

            self._treasureSkilIds = gModelCareSchool:GetDraconicId(self._battleData.targetId)
            self:FormationSelEvent(formationRefId)

        else
            formationRefId = 1
        end

    end
    self:RefreshFormationSkillShow()
    self:RefreshFormationDivineSkill()
    self:RefreshPasvShow()
    -- 【C宠物系统】删掉宠物系统相关
    -- self:RefreshPetTreaBtnShow()

    printInfoN("cur formaiton id " .. formationRefId)

    self:FormationSelEvent(formationRefId)
    self:RecordOldFormation(isFake)

    if self._wndType == UIFightPrepare.NORMAL then
        self:SetPlayerName()
    elseif self:IsMultiTeam() then
        if isFake then
            local roundInfo = self._combatDataList
            local round = roundInfo and roundInfo.round or 1
            local str = string.replace(ccClientText(25323), round)
            GF.ShowMessage(str)
        end

        self:RefreshMultiTeamData()
    end

    self:RefreshStrategyBtn() --刷新战术按钮显示
    self:RefreshChangePart()
    self:ShowHeroList()
    self:OnBadgeStarCond()
end
-- function UIFightPrepare:BackGuildBoss()
-- 	self:WndClose()
-- 	FireEvent(EventNames.CHANGE_MAIN_BTN,4)
-- 	GF.OpenWndBottom("WndGuildBossWin")
-- 	GF.ChangeMap("LCityMap")
-- end

function UIFightPrepare:BackDungeonDetail()
    GF.OpenWndBottom("UIDungeonDTDDetailOld")
    GF.ChangeMap("LCityMap")
    self:WndClose()
end

function UIFightPrepare:ShowMappingHeroLock(heroId)
    local otherMappingId = gModelResonance:GetMappingOtherId(heroId)
    local otherMappingIsSel = false
    if (otherMappingId) then
        local otherMappingSelPos = self._selectHeroTable.idToIndex[otherMappingId]
        otherMappingIsSel = otherMappingSelPos ~= nil
    end
    return otherMappingIsSel
end

function UIFightPrepare:ShowWonderHeroList()
    local uiList = self._uiHeroScrollList
    if not uiList then
        uiList = self:GenerateUIHeroScrollList(function(...)
            self:OnDrawWonderHero(...)
        end)
    end

    local heroList = gModelWonderland:GetHeroListInBattle()
    heroList = self:FilterHeroList(heroList)

    uiList:RemoveAll()
    local cnt = #heroList
    for i = 1, cnt do
        local itemData = heroList[i]
        uiList:AddData(itemData.id, itemData)
    end
    uiList:RefreshList()

    local bool = cnt < 1
    CS.ShowObject(self.mNoRecord, bool)
    if bool then
        local emptyRefId = 10008
        self:CreateEmptyShow(emptyRefId)
        local pos = self.mNoRecord.localPosition
        self.mNoRecord.localPosition = Vector3(pos.x, 66, pos.z)
    end
end

function UIFightPrepare:GetEndelssHeroById(id)
    local combatType = self._combatType
    return gModelEndles:GetEndlessHeroData(combatType, id)
end

function UIFightPrepare:ShowEndelssHeroList()
    local uiList = self._uiHeroScrollList
    if not uiList then
        uiList = self:GenerateUIHeroScrollList(function(...)
            self:OnDrawEndlessHero(...)
        end)
    end

    local heroDataList = self:InitEndlessHeroList(self._heroType)
    uiList:RemoveAll()
    local cnt = #heroDataList
    for i = 1, cnt do
        local itemData = heroDataList[i]
        if itemData then
            uiList:AddData(itemData.id, itemData)
        end
    end

    local bool = cnt < 1
    CS.ShowObject(self.mNoRecord, bool)
    if bool then
        local emptyRefId = 17001
        if self._showCombatSpiritHeroStatus and self._heroType == ModelSpiritHero.SPIRITHERO_RACE then
            emptyRefId = 10011
        end
        self:CreateEmptyShow(emptyRefId)
    end


    --[[	for i=1,cnt do
		local itemData = heroDataList[i]
		local race = gModelHero:GetHeroRace(itemData.refId)
		if self._heroType == 0 or self._heroType == race then
			if self._isShowTryHero or not itemData.isTry then
				uiList:AddData(itemData.id,itemData)
			end
		end
	end]]
    uiList:RefreshList()
end

---初始测试战斗队伍信息
function UIFightPrepare:InitTestHeroFormation()
    self:ClearSelectTable()

    local bLeft = self:IsArrayingTeamLeft()
    CS.ShowObject(self.mBtnTeamSwitchA, not bLeft)
    CS.ShowObject(self.mBtnTeamSwitchB, bLeft)

    local formation = LFightTest.GetFormationData(self._teamSide) or {}
    local formationRefId = formation.formationRefId or 0
    if formationRefId == 0 then
        formationRefId = 1
    end
    for k, v in pairs(formation.grids or {}) do
        local heroId = v.id
        local serData = gModelHero:GetHeroById(heroId)
        local isExist = serData ~= nil
        if isExist then
            local index = gModelFormation:GetIndexByPos(formationRefId, v.grid)
            self._selectHeroTable.idToIndex[heroId] = index
            self._selectHeroTable.indexToId[index] = heroId
            self._emptyPos[index] = false
        end
    end

    self:RefreshHeroCnt(self._selectHeroTable)
    -- self._artifact = formation.artifactId or 0【G公共支持】删除神器功能相关数据
    self._treasureSkilIds = formation.treasureSkilIds
    self._divineWeaponStarRefIds = formation.divineWeaponStarRefIds
    -- self._pasvSkillList = formation.treasurePassiveSkill or {}
    self._petFights = formation.petFights
    self._petHelps = formation.petHelps

    self:RefreshFormationSkillShow()
    self:RefreshFormationDivineSkill()
    self:RefreshPasvShow()
    -- 【C宠物系统】删掉宠物系统相关
    -- self:RefreshPetTreaBtnShow()


    self:FormationSelEvent(formationRefId)

    self:RecordOldFormation()
    self:RefreshChangePart()
    self:ShowHeroList()

end
function UIFightPrepare:ShowTimeCorridorHeroList()
    --local uiList = self._uiHeroScrollList
    --if not uiList then
    --	uiList = self:GenerateUIHeroScrollList(function (...) self:OnDrawTimeCorridorHero(...) end)
    --end
    --
    --local heroList = gModelTimeCorridor:GetHeroListInBattle()
    --heroList = self:FilterHeroList(heroList)
    --
    --uiList:RemoveAll()
    --local cnt = #heroList
    --for i=1,cnt do
    --	local itemData = heroList[i]
    --	uiList:AddData(itemData.id,itemData)
    --end
    --uiList:RefreshList()
end

function UIFightPrepare:OnDrawTeamItem(item, itemdata)

    local BtnTab3 = self:FindWndTrans(item, "BtnTab10")

    local teamIndex = itemdata.teamIndex

    local isSelect = teamIndex == self._teamIndex
    local bgState = isSelect and LWnd.StateOn or LWnd.StateOff

    self:SetWndTabStatus(BtnTab3, bgState)

    self:SetWndTabText(BtnTab3, itemdata.name)

    self:SetWndClick(item, function()
        self:OnClickTeamItem(teamIndex)
    end, LSoundConst.CLICK_PAGE_COMMON)
end
function UIFightPrepare:ScoreWordListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local raceIcon = self:FindWndTrans(root, "RaceIcon")
    local jobIcon = self:FindWndTrans(root, "JobIcon")
    local heroIcon = self:FindWndTrans(root, "HeroIcon")
    local numText = self:FindWndTrans(root, "NumText")

    --local InstanceID = item:GetInstanceID()
    local scoreWordId = tonumber(itemdata)
    local ref = gModelGuildBoss:GetNewGuildDungeonBonusRefByRefId(scoreWordId)
    local type, para, bonus = ref.type, string.split(ref.para, "="), ref.bonus
    local type1List, type2List, type3List = self.type1List, self.type2List, self.type3List

    local desStr = ""
    CS.ShowObject(raceIcon, type == 1)
    CS.ShowObject(jobIcon, type == 2)
    CS.ShowObject(heroIcon, type == 3)
    CS.ShowObject(numText, type ~= 3)

    local value = tonumber(para[1])
    local num = tonumber(para[2])
    if type == 1 then
        local curNum = type1List[value] or 0
        local raceRef = gModelHero:GetHeroRaceRefByRefId(value)
        desStr = string.replace(ccClientText(32748), curNum, num)
        local bool = curNum >= num
        desStr = LUtil.FormatColorStr(desStr, bool and "lightGreen" or "lightRed")
        self:SetWndEasyImage(raceIcon, raceRef.icon)
    elseif type == 2 then
        local curNum = type2List[value] or 0
        local careerRef = gModelHero:GetCareerRefByRefId(value)
        desStr = string.replace(ccClientText(32748), curNum, num)
        local bool = curNum >= num
        desStr = LUtil.FormatColorStr(desStr, bool and "lightGreen" or "lightRed")
        self:SetWndEasyImage(jobIcon, careerRef.jobIcon)
    elseif type == 3 then
        local curNum = type3List[value] or 0
        local effRef = gModelHero:GetHeroShowRefByRefId(value, num)
        desStr = string.replace(ccClientText(32748), curNum, num)
        local bool = curNum >= num
        desStr = LUtil.FormatColorStr(desStr, bool and "lightGreen" or "lightRed")
        self:SetWndEasyImage(heroIcon, effRef.icon)
    end
    self:SetWndText(numText, desStr)
end

function UIFightPrepare:ShowTimeCorridorBossBuffStatus()
    local bossList = self._bossList
    local isHero = true
    local refIdList = {}
    for k, v in pairs(bossList) do
        if v.heroType == ModelWonderland.ENEMY_MONSTER then
            isHero = false
        end
        table.insert(refIdList, { id = v.refId, isMon = not isHero })
    end
    self._enemyList = refIdList
    self._isHeroEnemy = isHero
    self:ShowBuffStatus(false, refIdList)
end

function UIFightPrepare:SaveMirrorBattleTeamFormation(side)
    local data = self:GetCurFormationData()
    gModelCareSchool:SaveMirrorFormation(side, data)
end

function UIFightPrepare:RefreshStrategyBtn()
    local item = self.mBtnStrategy
    local bg = self:FindWndTrans(item, "bg")
    local bgIcon = self:FindWndTrans(bg, "Icon")
    local Image = self:FindWndTrans(item, "Image")
    local UIText = self:FindWndTrans(item, "UIText")

    local show = self._simulateFightType[self._combatType]
    CS.ShowObject(self.mBtnStrategy, show)
    if not show then
        return
    end

    local curStrategyId = self._strategyId or 0
    local ref = gModelSimuFight:GetSimulateGameSkill(curStrategyId)
    local isShowTac = false
    local text = ccClientText(25262)-- "战术"
    if ref then
        isShowTac = true
        self:SetWndEasyImage(bgIcon, ref.icon)
        text = ccLngText(ref.name)
    end
    self:SetWndText(UIText, text)
    CS.ShowObject(bg, isShowTac)
    CS.ShowObject(Image, not isShowTac)
end

function UIFightPrepare:IsShowTire()
    -- 【G公共支持】删除暗黑战争相关数据
    -- return self._combatType == LCombatTypeConst.COMBAT_DARK_WAR
    return false
end

function UIFightPrepare:OnSelectTeamIndex(teamIndex)
    self._teamIndex = teamIndex
    self._isDataReceived = false
    FireEvent(EventNames.ON_CHANGE_BATTLE_TEAM, teamIndex)
    self:RefreshTeamItemShow()
    self:RefreshHeroFormation()
end

function UIFightPrepare:InitBossTowerHeroList()
    -- local dataList = self:GetBossTowerHeroList()
    -- local uiList = self._uiHeroScrollList
    -- if not uiList then
    -- 	uiList = self:GenerateUIHeroScrollList(function (...) self:OnDrawBossTowerHeroCell(...) end)
    -- end
    -- uiList:RemoveAll()
    -- local cnt = #dataList
    -- local bool = cnt <= 0
    -- CS.ShowObject(self.mNoRecord,bool)
    -- if(bool)then
    -- 	self:CreateEmptyShow(17001)
    -- end
    -- for i=1,cnt do
    -- 	local heroId = dataList[i]
    -- 	uiList:AddData(heroId,heroId)
    -- end
    -- uiList:RefreshList()
end

-- 【C宠物系统】删掉宠物系统相关
-- function UIFightPrepare:GetPetsPower()
-- 	local totalPower = 0
-- 	if self._petHelps then
-- 		for k,v in pairs(self._petHelps) do
-- 			if tonumber(v)> 0 then
-- 				local power = gModelPetSpace:GetPetScore(v)
-- 				totalPower = totalPower + power
-- 			end

-- 		end
-- 	end

-- 	if self._petFights then
-- 		for k,v in pairs(self._petFights) do
-- 			if tonumber(v)> 0 then
-- 				local power = gModelPetSpace:GetPetScore(v)
-- 				totalPower = totalPower + power
-- 			end
-- 		end
-- 	end

-- 	return totalPower
-- end

function UIFightPrepare:GetCommonMePower()

    -- 【C宠物系统】删掉宠物系统相关
    -- local petPower = self:GetPetsPower()
    if self._combatType == LCombatTypeConst.COMBAT_WONDERLAND then
        -- 爱欲小径 走通用
        local idList = {}
        for k, v in pairs(self._selectHeroTable.idToIndex) do
            table.insert(idList, k)
        end
        local power, percent = gModelWonderland:GetFormationPower(idList)
        -- power = power + petPower
        return power, percent
        --elseif gModelBattle:IsTimeCorridorCombat(self._combatType) then
        --	local idList = {}
        --	for k,v in pairs(self._selectHeroTable.idToIndex) do
        --		table.insert(idList,k)
        --	end
        --	local power,percent = gModelTimeCorridor:GetFormationPower(idList)
        --	-- power = power + petPower
        --
        --	return power,percent
    elseif (gModelBattle:IsEndlessCombat(self._combatType)) then
        local power = 0
        for k, v in pairs(self._selectHeroTable.idToIndex) do
            local heroData = self:GetEndelssHeroById(k)
            power = power + heroData.fightPower
        end
        -- power = power + petPower

        return power
    else
        local power = self:GetMePower()

        return power
    end
end

-- 显示可选择的阵型
function UIFightPrepare:PlayShowFormation()
    --if self._isReliefTroop and self._combatType~=LCombatTypeConst.COMBAT_TYPE_34 then
    if self._isReliefTroop then
        GF.ShowMessage(ccClientText(10158))
        return
    end
    self._showFormation = not self._showFormation
    CS.ShowObject(self.mFormationBg, self._showFormation)
    if self._showFormation then
        self._curSelectFormationType = self._formationType
        local itemList = self:GetUIScroll("formationList")
        itemList:DrawAllItems()
    end
end

-- 【G公共支持】删除本命英雄功能
--本命英雄功能使用 点击敌方按钮打开阵容选择列表
-- function UIFightPrepare:InitMirrorBattleUIForNaturalPartner()
-- 	CS.ShowObject(self.mTeamMirror,true)
-- 	self:SetWndClick(self.mBtnTeamMirrorB, function ()
-- 		GF.OpenWnd("WndNaturalPartnerBattleSelectPop")
-- 	end)
-- 	self:SetWndTabText(self.mBtnTeamMirrorA,ccClientText(20908))
-- 	self:SetWndTabText(self.mBtnTeamMirrorB,ccClientText(20909))
-- end

function UIFightPrepare:InitTestBattleUI()
    local isMonsterTest = self._battleData.monsterB ~= nil
    CS.ShowObject(self.mTeamSwitch, not isMonsterTest)

    self:SetWndClick(self.mBtnTeamSwitchA, function()
        self:SwitchTestBattleArrayingFormation()
    end)
    self:SetWndClick(self.mBtnTeamSwitchB, function()
        self:SwitchTestBattleArrayingFormation()
    end)

    local playerName = gModelPlayer:GetPlayerName()
    self._battleData.meName = playerName
    self._battleData.otherName = playerName
    self:SetPlayerName()

    local monsterA = self._battleData.monsterA
    if monsterA then
        local refIdList = {}
        local tempList = gModelHero:GetMonsterList(monsterA) or {}
        for k, v in pairs(tempList) do
            table.insert(refIdList, { id = v, isMon = true })
        end
        self:ShowBuffStatus(true, refIdList)
        self:SetEnemyPower(0)
    else
        self:InitTestHeroFormation()
    end

    local monsterB = self._battleData.monsterB
    if monsterB then
        local refIdList = {}
        local tempList = gModelHero:GetMonsterList(monsterB) or {}
        for k, v in pairs(tempList) do
            table.insert(refIdList, { id = v, isMon = true })
        end
        self:ShowBuffStatus(false, refIdList)
        self:SetEnemyPower(0)
    else
        local formation = LFightTest.GetFormationData(2) or {}
        local otherPower = 0
        local refIdList = {}
        for k, v in pairs(formation.grids or {}) do
            local heroId = v.id
            local serData = gModelHero:GetHeroById(heroId)
            local isExist = serData ~= nil
            if isExist then
                otherPower = otherPower + (serData:GetPower() or 0)
                table.insert(refIdList, { id = serData:GetRefId() })
            end
        end
        self:ShowBuffStatus(false, refIdList)
        self:SetEnemyPower(otherPower)
    end


end

function UIFightPrepare:RefreshMultiTeamData()
    local combatType = self._combatType

    local formationList = {}

    --if self:IsUseFirst() then
    --	local oldFormationList = gModelFormation:GetFormationList(combatType) or {}
    --	for k= 0 ,self._teamCount-1 do
    --		local formation = oldFormationList[k]
    --		if not formation or not formation.grids or #formation.grids == 0 then
    --			formation = self:GetCacheFormationData(k)
    --		end
    --		if formation then
    --			table.insert(formationList,formation)
    --		end
    --	end
    --else
    formationList = gModelFormation:GetFormationList(combatType)
    --end


    local heroRefIdRecord = {}
    local treasureIdRecord = {}
    local heroIdRecord = {}
    local divineRefIdRecord = {}
    local tacticsRecord = {}
    local petFightsRecord = {}
    local petHelpsRecord = {}
    if formationList then
        for k, v in pairs(formationList) do
            local teamIndex = v.teamIndex
            if teamIndex < self._teamCount then
                local record = {}
                local idRecord = {}
                local tRecord = {}
                local dRecord = {}
                if v.grids then
                    for k1, v1 in ipairs(v.grids) do
                        local refId = gModelHero:GetRefIdById(v1.id)
                        if refId then
                            record[refId] = true--英雄refid
                            idRecord[v1.id] = true--英雄id
                        end
                    end
                end

                if v.treasureSkilIds then
                    for k1, v1 in ipairs(v.treasureSkilIds) do
                        tRecord[k1] = v1--龍紋
                    end
                end
                if v.divineWeaponStarRefIds then
                    for k1, v1 in ipairs(v.divineWeaponStarRefIds) do
                        dRecord[k1] = v1--龍紋
                    end
                end

                heroRefIdRecord[teamIndex] = record
                heroIdRecord[teamIndex] = idRecord
                treasureIdRecord[teamIndex] = tRecord
                divineRefIdRecord[teamIndex] = dRecord
                tacticsRecord[teamIndex] = v.tactics
                petFightsRecord[teamIndex] = v.petFights
                petHelpsRecord[teamIndex] = v.petHelps
            end
        end
    end

    self._multiTeamRecord = {
        heroRefIdRecord = heroRefIdRecord, --英雄refid
        treasureIdRecord = treasureIdRecord, ----龍紋
        heroIdRecord = heroIdRecord, --英雄id
        divineRefIdRecord = divineRefIdRecord, --聖武
        tacticsRecord = tacticsRecord,
        petFightsRecord = petFightsRecord,
        petHelpsRecord = petHelpsRecord,
    }
end

-- 前往战斗更换战斗界面底部栏
function UIFightPrepare:GotoChallenge(changeFunc)
    local cnt = self._selectHeroTable.cnt
    if cnt <= 0 then
        GF.ShowMessage(ccClientText(10127))

        if changeFunc then
            changeFunc()
        end
        return
    end

    local combatType = self._combatType or LCombatTypeConst.COMBAT_MAIN
    if self._wndType == UIFightPrepare.NORMAL and combatType == LCombatTypeConst.COMBAT_MAIN then
        local reliefMonCount = self:GetSelectReliefMonCount()
        if cnt == reliefMonCount then
            GF.ShowMessage(ccClientText(10180))
            if changeFunc then
                changeFunc()
            end
            return
        end
    end
    if combatType == LCombatTypeConst.COMBAT_GUILD_WAR and self._guildMeleeState then
        local bool = gModelGuildMelee:GetIsBoolApply()
        if not bool then
            return
        end
    end

    local needAskPasv = false
    local needAsk = false
    -- if not gModelFormation:CheckTreasureNotUse(combatType) then
    -- 	needAsk = self:NeedAskTreasure()
    -- 	needAskPasv = self:NeedAskPasv()
    -- end

    -- 【C宠物系统】删掉宠物系统相关
    -- local needAskPet = false
    -- if(combatType~=LCombatTypeConst.COMBAT_TACTICAL_TRAINING)then
    -- 	needAskPet = self:NeedAskPet()
    -- end

    if self._wndType == UIFightPrepare.NORMAL then
        local func = function()
            local func1 = function()
                if self:IsWndClosed() then
                    return
                end
                self:SendNetMessage(combatType)
            end

            if needAskPasv then
                gModelGeneral:OpenUIOrdinTips({ refId = 52003, func = func1 })
                return
            end

            if combatType == LCombatTypeConst.COMBAT_WONDERLAND and cnt < self._heroMax then
                gModelGeneral:OpenUIOrdinTips({ refId = 70010, func = func1 })
                return
            end

            -- if combatType == LCombatTypeConst.COMBAT_DESIRETRAIL and cnt < self._heroMax then
            --     gModelGeneral:OpenUIOrdinTips({ refId = 70010, func = func1 })
            --     return
            -- end

            func1()
        end

        if needAsk then
            gModelGeneral:OpenUIOrdinTips({ refId = 52001, func = func })
            return
        end

        -- 【C宠物系统】删掉宠物系统相关
        -- if(needAskPet)then
        -- 	gModelGeneral:OpenUIOrdinTips({refId = 380005,func = func})
        -- 	return
        -- end

        func()

    else

        local func = function()
            local func1 = function()
                local func2 = function()
                    if self:IsWndClosed() then
                        return
                    end
                    self:OnlySetFormation()
                    if changeFunc then
                        changeFunc()
                    end
                end
                -- 【C宠物系统】删掉宠物系统相关
                -- if(needAskPet)then
                -- 	gModelGeneral:OpenUIOrdinTips({refId = 380005,func = func2,leftFunc = changeFunc})
                -- 	return
                -- end
                func2()
            end

            if needAskPasv then
                gModelGeneral:OpenUIOrdinTips({ refId = 52004, func = func1, leftFunc = changeFunc })
                return
            end

            func1()
        end

        if needAsk then
            gModelGeneral:OpenUIOrdinTips({ refId = 52002, func = func, leftFunc = changeFunc })
            return
        end

        func()

    end

end

function UIFightPrepare:ReturnEndles(page)

    GF.OpenWndBottom("UIUendWin", { page = page })
    GF.ChangeMap("LCityMap")
    self:WndClose()
end

function UIFightPrepare:RefreshTestBattleOtherPower()
    if self:IsArrayingTeamLeft() then
        return
    end
    local otherPower = self:GetMePower()

    local str = LUtil.FormatPowerShowStr(otherPower)
    --local str = LUtil.FormatPowerShowStr(otherPower)
    self:SetWndText(self.mOtherFightNum, str)
end

function UIFightPrepare:GetSpecialCombatFormationType()
    local specialInfo = self:GetSpecialCombatInfo()
    if not specialInfo then
        return
    end
    return specialInfo.getFormationType
end

function UIFightPrepare:OnGetFormationRet(type, teamIndex)
    if self._isDataReceived then
        return
    end

    local combatType = self._combatType
    if self:CheckIsSpecialCombat() then
        local getFormationType = self:GetSpecialCombatFormationType()
        if getFormationType and getFormationType ~= type then
            return
        end
    else
        if self._dontReqFormationTypes[combatType] or type ~= combatType then
            return
        end
    end

    self._isDataReceived = true

    self:RefreshOnFormationRefId()

    local isMulti = self:IsMultiTeam()
    if isMulti then
        if self._selNextTeamIndex then
            self._selNextTeamIndex = false
            local nextIndex = self:FindAnotherEmptyTeam()
            if nextIndex and nextIndex ~= self._teamIndex then
                self:OnSelectTeamIndex(nextIndex)
            end
        else
            self:OnFormationDataRet()
        end
    else
        self:OnFormationDataRet()
    end
end

function UIFightPrepare:ClickReliefTroopMon(data)
    local heroId = data.heroId
    local checkRefId = data.checkRefId
    if self:IsHeroForbidSingle(heroId, checkRefId, true) then
        return
    end
    local refId = data.refId
    local skin = data.skin
    local isMonster = data.isMonster

    local selectTable = self._selectHeroTable
    local leftPos = selectTable.idToIndex[heroId]
    local isSelect = leftPos ~= nil

    local bHaveEmpty, emptyPos
    local bLineUp = true
    if isSelect then
        local fixedInFormation = self._reliefTroopData.fixedInFormation or {}
        if fixedInFormation[heroId] then
            GF.ShowMessage(ccClientText(10156))
            return
        end
        bLineUp = false
        self:HeroDown(heroId, leftPos, true)
        emptyPos = leftPos
    else
        bHaveEmpty, emptyPos = self:GetEmptyPos()
        local cnt = selectTable.cnt
        if not bHaveEmpty or cnt >= self._heroMax then
            local str = ccClientText(16605)--上阵人数已达上限
            GF.ShowMessage(str)
            return
        end
        gModelHero:PlayHeroRoleSound(refId, skin, isMonster)
        self:HeroUp(heroId, emptyPos, isMonster)
    end

    FireEvent(EventNames.Scene_Hero_GoTo, heroId, emptyPos, bLineUp, isMonster)
end

function UIFightPrepare:ShowOnlySetBuff()
    local refIdList = self:GetSelectBuffWndDataList()
    --for k,v in pairs(self._selectHeroTable.indexToId) do
    --	local refId = gModelBattle:GetHeroRefId(self._combatType,v)
    --	--local refId =  gModelHero:GetRefIdById(v)
    --	table.insert(refIdList,{id=refId})
    --end

    local buffIcon, buffEff = gModelFormation:GetBuffInfo(refIdList)
    if buffIcon then
        self:SetWndEasyImage(self.mSelfBuff, buffIcon)
    end

    CS.ShowObject(self.mSelfBuff, not string.isempty(buffIcon))
    local key = "selfBuff"
    self:DestroyWndEffectByKey(key)
    if buffEff then
        self:CreateWndEffect(self.mSelfBuff, buffEff, key, 150, false, false)
    end
end

function UIFightPrepare:IsPetPartOpen()
    local isOpen = gModelFunctionOpen:CheckIsShow(36003000)
    return isOpen
end

function UIFightPrepare:UIDragOnDrag(dragKey, eventData)
    if self._dragItemData and self._dragItemData.key == dragKey then
        local trans = self._dragItemData.item
        local camera = eventData.pressEventCamera
        local pos = camera:ScreenToWorldPoint(eventData.position)
        pos = trans.parent:InverseTransformPoint(pos)
        pos.y = pos.y + self._dragOffsetPosY

        local min = pos.y + self._dragItemData.minY
        local max = self._dragItemData.maxY + pos.y

        if min < self._dragOriginLimitMinY then
            pos.y = self._dragOriginLimitMinY - self._dragItemData.minY
        elseif max > self._dragOriginLimitMaxY then
            pos.y = self._dragOriginLimitMaxY - self._dragItemData.maxY
        end

        local transPos = trans.localPosition
        local curPos = Vector3.New(transPos.x, pos.y, transPos.z)
        trans.localPosition = curPos
        self:CheckDragItemSwap(self._dragItemData, curPos)
    end
end

function UIFightPrepare:OnSelectTimeCorridorHero(herodata)

    local clickHeroRefId = herodata.refId
    if not herodata.canUse then
        return
    end
    local heroId = herodata.id

    if self:IsHeroForbidSingle(heroId, clickHeroRefId, true) then
        return
    end

    local isSelect = false
    local selectTable = self._selectHeroTable
    local leftPos = selectTable.idToIndex[heroId]
    if leftPos then
        isSelect = true
    end

    local bHaveEmpty, emptyPos
    local bLineUp = true
    if isSelect then
        bLineUp = false
        self:HeroDown(heroId, leftPos)
        emptyPos = leftPos

    else
        bHaveEmpty, emptyPos = self:GetEmptyPos()
        local cnt = selectTable.cnt
        if not bHaveEmpty or cnt >= self._heroMax then
            local str = ccClientText(16605) --上阵人数已达上限
            GF.ShowMessage(str)
            return
        end

        local serData = gModelBattle:GetHeroData(self._combatType, heroId)
        if serData then
            gModelHero:PlayHeroRoleSound(serData.refId, serData.skin)
        end
        self:HeroUp(heroId, emptyPos)
    end

    FireEvent(EventNames.Scene_Hero_GoTo, heroId, emptyPos, bLineUp, false)
end

function UIFightPrepare:OnTimer(key)


    if key == self._clickBattleKey then
        self._isClickBattle = true
    end
end

function UIFightPrepare:ReqPower()
    local emptyLineup = gModelCareSchool:GetCollegeConfigRefByKey("emptyLineup")
    local matrix = gModelFormation:GetFormationPosByRefId(self._formationType)
    local grids = {}
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local grid = matrix[v]
        local data = {}
        data.id = k
        data.grid = grid
        table.insert(grids, data)
    end
    -- local artifactId = self._artifact【G公共支持】删除神器功能相关数据
    local treasureSkilIds = self._treasureSkilIds
    local divineWeaponStarRefIds = self._divineWeaponStarRefIds

    local data = {
        formationRefId = self._formationType,
        -- artifactId = artifactId,【G公共支持】删除神器功能相关数据
        treasureSkilIds = treasureSkilIds,
        divineWeaponStarRefIds = divineWeaponStarRefIds,
        grids = grids,
    }

    gModelFormation:OnMonsterPowerReq({ emptyLineup }, { data }, self._combatType)
end

function UIFightPrepare:SetBossEnemyCombatData(prepareData)
    self:ShowEnemyBuffStatus(prepareData)
    -- self:ShowEnemyTreasure(prepareData)
    FireEvent(EventNames.REFRESH_ENEMY_BOSSTOWERHERO_SHOW, prepareData)
end

function UIFightPrepare:OnDrawFormation(list, item, itemdata, itempos)
    local formation = self:FindWndTrans(item, "formation")
    local formationIcon = self:FindWndTrans(formation, "icon")
    local formationName = self:FindWndTrans(formation, "name")
    local formationSelect = self:FindWndTrans(formation, "select")
    local formationLock = self:FindWndTrans(formation, "lock")
    local formationCur = self:FindWndTrans(formation, "cur")
    local formaitionCurStr = self:FindWndTrans(formationCur, "UIText")

    self:SetWndText(formaitionCurStr, ccClientText(11002))

    -- local isBossTower = gModelBossTower:IsBossTowerCombat(self._combatType)

    local refId = itemdata.refId
    local nameCfg = ccLngText(itemdata.name)
    self:SetWndText(formationName, nameCfg)
    if gLGameLanguage:IsVieVersion() then
        self:InitTextLineWithLanguage(formationName, 8)
    else
        self:InitTextLineWithLanguage(formationName, -30)
    end

    self:InitTextSizeWithLanguage(formationName, -4)
    local needLv = itemdata.needLv
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

-- function UIFightPrepare:NeedAskTreasure()
-- 	if self._noNeedAskTreasure[self._combatType] then
-- 		return false
-- 	end
-- 	local upSkillNum = 0
-- 	local idRecord = {}
-- 	for k,v in pairs(self._treasureSkilIds or {}) do
-- 		if v ~= 0 then
-- 			upSkillNum = upSkillNum + 1
-- 			idRecord[v] = true
-- 		end
-- 	end

-- 	local canUpNum = 0
-- 	if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
-- 		for i, v in pairs(self._skillPosList) do
-- 			canUpNum = canUpNum + 1
-- 		end
-- 		local skillNum = #self._treasureSkillList
-- 		if skillNum < canUpNum then
-- 			canUpNum = skillNum
-- 		end
-- 	else
-- 		canUpNum = gModelTreasure:CanUpSkillNum()
-- 	end

-- 	canUpNum = canUpNum - upSkillNum  ---有几个空位

-- 	if self:IsMultiTeam() then
-- 		local otherRecord = self:GetMultiTreasureRecord(self._teamIndex)
-- 		for k,v in pairs(otherRecord) do
-- 			idRecord[k] = true
-- 		end
-- 	end

-- 	local canUpTreasureList = gModelTreasure:GetActiveSkillList(idRecord)
-- 	local canLen = #canUpTreasureList ---还剩几个宝物

-- 	canUpNum = math.min(canUpNum,canLen)
-- 	if canUpNum <= 0  then
-- 		return false
-- 	end

-- 	return true
-- end

function UIFightPrepare:IsPasvPartActive()
    -- if self._noNeedAskTreasure[self._combatType] then
    -- 	return false
    -- end

    local isOpen = gModelFunctionOpen:CheckIsShow(17404100)
    if not isOpen then
        return false

    end
    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        return false
    end

    return true
end
function UIFightPrepare:ShowWonderBossBuffStatus()
    local bossList = self._bossList
    local isHero = true
    local refIdList = {}

    for k, v in pairs(bossList) do
        if v.heroType == ModelWonderland.ENEMY_MONSTER then
            isHero = false
        end
        table.insert(refIdList, { id = v.refId, isMon = not isHero })
    end
    self._enemyList = refIdList
    self._isHeroEnemy = isHero
    self:ShowBuffStatus(false, refIdList)
end

--function UIFightPrepare:IsUseFirst()
--	local para = self:GetWndArg("para")
--	local isUseFirst = para and para.isUseFirst or false
--	return isUseFirst
--end

--function UIFightPrepare:GetCacheFormationData(teamIndex)
--	local isUseFirst = self:IsUseFirst()
--	if not isUseFirst then
--		return
--	end
--
--	local combatType = self._combatDataList[1].combatType
--	local formationData = gModelFormation:GetFormation(combatType,teamIndex)
--	return formationData
--end

function UIFightPrepare:GetSpecialCombatInfo()
    local specialCombatTypeList = self._specialCombatTypeList or {}
    local combatType = self._combatType
    return combatType and specialCombatTypeList[combatType]
end

function UIFightPrepare:IsHeroForbid(heroId, refId, showTip)
    if not self._multiTeamRecord then
        return false
    end

    local multiRecord = self._multiTeamRecord

    local selState, teamIndex = self:GetMultiHeroSelectState(heroId)
    if selState == 2 then
        if showTip then
            local str = string.replace(ccClientText(21833), teamIndex + 1)
            GF.ShowMessage(str)
        end
        return true
    end

    if selState == 0 then
        local refIdRecord = multiRecord.heroRefIdRecord[self._teamIndex]
        local isRepeatRefId = refIdRecord and refIdRecord[refId]
        if isRepeatRefId then
            if showTip then
                GF.ShowMessage(ccClientText(10123))
            end
            return true
        end
    end

    local curRecord = multiRecord.heroIdRecord[self._teamIndex]
    local extraRecord = self:GetMultiHeroIdRecord(self._teamIndex)
    local isForbid = gModelFormation:CheckLinkForbid(self._combatType, heroId, curRecord, extraRecord, showTip)
    return isForbid
end

function UIFightPrepare:OnClickReturn()

    local wndType = self._wndType
    if wndType == UIFightPrepare.NORMAL then
        local retFun = self._returnFuncList[self._combatType]
        if retFun then
            retFun()
        else
            self:BackBtIdle()
        end
    else

        local hasUnSave = self:CheckHasUnSaved()
        local closeFun = function()
            self:OnClickCloseFunc()
        end
        if hasUnSave then
            local confirmFun = function()
                self:GotoChallenge()
            end

            local para = {
                refId = 10007,
                func = confirmFun,
                leftFunc = closeFun,
            }
            gModelGeneral:OpenUIOrdinTips(para)
            return
        end

        closeFun()
    end
end

function UIFightPrepare:OnSetFormationResp(pb)
    local teamIndexSet = pb.teamIndexSet
    local first = teamIndexSet[1]
    local formationType = first.formationType

    if self._wndType == UIFightPrepare.NORMAL then
        if formationType == LCombatTypeConst.COMBAT_CROSS_SERVER_LADDER then
            if self._isSetFormation then
                -- self:BackCrossServerLadder()
            end
        elseif formationType == LCombatTypeConst.COMBAT_GUILD_WAR then
            if self._guildMeleeState then
                gModelGuildMelee:OnGuildMeleeSignUpReq()
            else
                GF.ShowMessage(ccClientText(10346))
            end
            self:ReturnGuildMelee()
        end
    else
        if self._combatType == formationType then
            self:RecordOldFormation()
        end

        local para = self:GetWndArg("para")
        local saveCallback = para and para.saveCallback
        if saveCallback then
            saveCallback()
        end

        if self._retAfterSet then
            if self._returnFunc then
                self._returnFunc()
            end
        end
    end
    if self:IsMultiTeam() then
        self:RefreshMultiTeamData()
        self:ShowHeroList()
    end
end

function UIFightPrepare:SetEnemyCombatData(enemyHeroData)
    self:ShowEnemyBuffStatus(enemyHeroData)
    if enemyHeroData.power then
        self:SetEnemyPower(enemyHeroData.power)
    end

    -- self:ShowEnemyTreasure(enemyHeroData)

    FireEvent(EventNames.REFRESH_ENEMY_HERO_SHOW, enemyHeroData)
end

function UIFightPrepare:ShowSingleTeamSet()
    self:SetWndText(self.mSetDesText, ccClientText(10161))
    self:SetWndText(self.mNameText, gModelPlayer:GetPlayerName())
    local fightText = self:FindWndTrans(self.mFightBtn, "FightTxt")
    local str = ccClientText(10353)
    self:SetWndText(fightText, str)

    local dataList = gModelFormation:GetCombatTypeList(self._typeRecord)

    local combatTypeNum = #dataList
    if combatTypeNum <= 0 then
        self:ShowBottomPart()
        return
    end

    local pos = 1
    local curSelType = self._setTargetType or dataList[1].refId
    local showTypeList = true
    if self._setTargetType then
        showTypeList = false
        for k, v in ipairs(dataList) do
            if self._setTargetType == v.refId then
                showTypeList = true
                pos = k
                break
            end
        end
    end

    self._needClose = combatTypeNum <= 1

    self._curSelectType = curSelType

    self._fightTypeItems = {}
    self:InitCombatList(dataList, pos)

    self:OnSelectCombatType(curSelType)

    CS.ShowObject(self.mCombatList, true)
    CS.ShowObject(self.mSwapCombatList, false)
    CS.ShowObject(self.mTypePart, showTypeList)
end

-- function UIFightPrepare:NeedAskPasv()
-- 	if not self:IsPasvPartActive() then
-- 		return
-- 	end

-- local upSkillNum = 0
-- local idRecord = {}
-- for k,v in pairs(self._pasvSkillList or {}) do
-- 	if v ~= 0 then
-- 		upSkillNum = upSkillNum + 1
-- 		idRecord[v] = true
-- 	end
-- end

-- local canUpNum = gModelTreasure:GetPasvUnLockNum()

-- canUpNum = canUpNum - upSkillNum  ---有几个空位



-- local canUpTreasureList = gModelTreasure:GetPasvSkillList(idRecord)
-- local canLen = #canUpTreasureList ---还剩几个宝物

-- canUpNum = math.min(canUpNum,canLen)
-- 	if canUpNum <= 0  then
-- 		return false
-- 	end

-- 	return true
-- end

-- 【C宠物系统】删掉宠物系统相关
-- function UIFightPrepare:NeedAskPet()
-- 	local listLen = 0
-- 	local petRefIds = {}
-- 	local petDict = gModelPetSpace:GetPetBagDict()
-- 	local curPetFights = self:GetCurPetFights()
-- 	local curPetHelps = self:GetCurPetHelps()
-- 	local openPetPosCnt = 0
-- 	for i = 1, 4 do
-- 		local funcIdPre = 3600300
-- 		local funcOpenId = funcIdPre..tostring(i)
-- 		local isOpen = gModelFunctionOpen:CheckIsOpened(tonumber(funcOpenId))
-- 		if(isOpen)then
-- 			openPetPosCnt = openPetPosCnt + 1
-- 		end
-- 	end
-- 	for i, v in pairs(curPetFights) do
-- 		if(v~=0 and v~= "0")then
-- 			listLen = listLen + 1
-- 			petRefIds[petDict[v].refId] = true
-- 		end
-- 	end
-- 	for i, v in pairs(curPetHelps) do
-- 		if(v~=0 and v~= "0")then
-- 			if(petDict[v])then
-- 				listLen = listLen + 1
-- 				petRefIds[petDict[v].refId] = true
-- 			end
-- 		end
-- 	end
-- 	if(self:IsMultiTeam())then
-- 		local multiPetList = self:GetMultiTeamRecordPetList()
-- 		for i, v in pairs(multiPetList) do
-- 			local petData = petDict[v.id]
-- 			if(petData)then
-- 				petRefIds[petData.refId] = true
-- 			end
-- 		end
-- 	end
-- 	if(listLen == openPetPosCnt)then
-- 		return false
-- 	else
-- 		for i, v in pairs(petDict) do
-- 			if(not petRefIds[v.refId])then
-- 				return true
-- 			end
-- 		end
-- 	end
-- end

function UIFightPrepare:RefreshFormationSkillShow()
    local list = {}
    local treasureSkilIds = self._treasureSkilIds
    if not treasureSkilIds then
        treasureSkilIds = {}
        self._treasureSkilIds = treasureSkilIds
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

function UIFightPrepare:ChangeSimulationSelectSide(side)
    if self._simulationSide == side then
        return
    end
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TACTICAL_SIMULATION, { targetId = side })
    --self._battleData.targetId = side
    --self._simulationSide = side
    --self:ShowNormalWnd()
end

function UIFightPrepare:SendNetMessage(combatType)
    if combatType == LCombatTypeConst.COMBAT_TEST_BATTLE then
        self:SaveTestBattleTeamFormation(true)
        --测试战斗直接发送
        local monsterA = self._battleData.monsterA
        local monsterB = self._battleData.monsterB
        local combatData = {
            combatType = combatType,
            formationA = LFightTest.GetFormationData(1),
            formationB = LFightTest.GetFormationData(2),
            monsterIdA = monsterA,
            monsterIdB = monsterB
        }
        gModelBattle:StartTestBattle(combatData)
        return
    elseif combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        local formationData = self:GetCurFormationData()
        formationData.draconicStarRefIds = self._treasureSkilIds
        local combatData = {
            combatType = combatType,
            formationA = formationData,
            targetId = self._battleData.targetId,
            --meName = self._meName,
            --otherName = self._otherName,
        }
        gModelBattle:StartAfterSetFormation(combatData)
        return
    elseif (combatType == LCombatTypeConst.COMBAT_TACTICAL_SIMULATION or self._combatType == LCombatTypeConst.COMBAT_TACTICAL_SIMULATION_2) and self._battleData.targetId == 3 then
        self:SaveMirrorBattleTeamFormation(self._teamSide)
        local formationDataA = gModelCareSchool:GetMirrorFormationData(1)
        local formationDataB = gModelCareSchool:GetMirrorFormationData(2)
        if not formationDataA or #formationDataA.grids < 1 then
            GF.ShowMessage(ccClientText(20913))
            return
        elseif not formationDataB or #formationDataB.grids < 1 then
            GF.ShowMessage(ccClientText(20914))
            return
        end

        --这里是 192   那么就去取一次龙纹 看下这里龙纹的设置就可以了

        local combatData = {
            combatType = combatType,
            formationA = formationDataA,
            formationB = formationDataB,
            targetId = self._battleData.targetId,
            --meName = self._meName,
            --otherName = self._otherName,
        }
        gModelBattle:StartAfterSetFormation(combatData)
        return
    end

    -- local isBossTowerCombat = combatType == gModelBossTower:GetBossTowerConfigRefByKey("compareFightType")
    local matrix = gModelFormation:GetFormationPosByRefId(self._formationType)
    local grids = {}
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local grid = matrix[v]
        local data = {}
        -- if isBossTowerCombat then
        -- 	k = tostring(k)
        -- end
        data.id = k
        data.grid = grid
        table.insert(grids, data)
    end

    local targetId = nil
    local sid = nil
    local pageId = nil
    local entryId = nil
    local rewardBoxData = nil
    local chapterEntryId = nil
    local battleRefId = self._battleRefId
    local x
    local y
    local url
    -- local bossTowerPkType

    local fightType
    local dreamLandId
    local formationRefId = self._formationType
    local skipBattle = false
    if combatType == LCombatTypeConst.COMBAT_DUNGEON_DAILY then
        targetId = self._dungeonId
    elseif combatType == LCombatTypeConst.COMBAT_TYPE_23 then
        targetId = self._dungeonId
    elseif combatType == LCombatTypeConst.COMBAT_ARENA_ATTACK then
        targetId = self._playerId
        skipBattle = gModelArena:GetIsSkipChecked()
    elseif combatType == LCombatTypeConst.COMBAT_ACTIVITY then
        targetId = self._monsterId
    elseif self._channgleBossTypes[combatType] then
        targetId = self._monsterId
        sid = self._sid
        pageId = self._pageId
        entryId = self._entryId
        rewardBoxData = self._rewardBoxData
    elseif combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        sid = self._sid
        pageId = self._pageId
        entryId = self._entryId
    elseif combatType == LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER
            or combatType == LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY then
        targetId = self._monsterId
        sid = self._sid
        pageId = self._pageId
        entryId = self._entryId
        chapterEntryId = self._chapterEntryId
    elseif combatType == LCombatTypeConst.COMBAT_CROSS_SERVER_LADDER then
        targetId = self._playerId
        -- 跨服天梯打排名，不打玩家，又改为传玩家了
        --targetId = self._rank
    elseif gModelBattle:IsTimeCorridorCombat(combatType) then
        targetId = self._mapType
        battleRefId = self._eventId
    elseif combatType == LCombatTypeConst.COMBAT_INVASION then
        x = self._battleData.x
        y = self._battleData.y
    elseif combatType == LCombatTypeConst.COMBAT_TACTICAL_SIMULATION or self._combatType == LCombatTypeConst.COMBAT_TACTICAL_SIMULATION_2 then
        targetId = self._battleData.targetId
    elseif combatType == LCombatTypeConst.COMBAT_MAIN then
        local battleNode = gModelInstance:GetBattleNode()
        if gModelPlot:IsStoryInstance(battleNode) then
            gModelFormation:ModifyStoryFormation(grids, self._formationType)
        end
    elseif combatType == LCombatTypeConst.COMBAT_PK then
        url = self._battleData.url
    elseif combatType == LCombatTypeConst.COMBAT_BADGE_GAME then
        battleRefId = self._battleData.refId
    elseif combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        battleRefId = self._battleData.refId
        -- elseif isBossTowerCombat then
        -- 	bossTowerPkType = self._battleData.bossTowerPkType
        -- 	targetId = self._battleData.targetId
    elseif self:CheckIsSpecialCombat() then
        targetId = self._battleData.targetId
        skipBattle = self._battleData.skipBattle
    elseif combatType == LCombatTypeConst.COMBAT_DREAMTRIP then
        targetId = self._battleData.targetId
        skipBattle = self._battleData.skipBattle
    elseif combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE then
        targetId = self._battleData.targetId
    elseif combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
        targetId = self._battleData.targetId
    elseif combatType == LCombatTypeConst.COMBAT_CRUSADE_AGAINST then
        targetId = self._battleData.targetId
        local checkpointRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(targetId)
        if checkpointRef then
            local selectHeroTable = self._selectHeroTable
            local cnt = selectHeroTable.cnt
            if cnt ~= checkpointRef.num then
                GF.ShowMessage(string.replace(ccClientText(46506), checkpointRef.num))
                return
            end
            if not string.isempty(checkpointRef.formation) then
                local formation = string.split(checkpointRef.formation, "=")
                local formationType, formationLimit, formationNum, formationName = tonumber(formation[2]), tonumber(formation[3]), 0, ""
                if formation[1] == "1" then
                    local raceRef = gModelHero:GetHeroRaceRefByRefId(formationType)
                    for i, v in pairs(selectHeroTable.idToIndex) do
                        local heroSeverData = gModelHero:GetHeroServerDataById(i)
                        local refId = heroSeverData.refId
                        local heroRef = gModelHero:GetHeroRef(refId)
                        if heroRef.raceType == formationType then
                            formationNum = formationNum + 1
                        end
                    end
                    formationName = ccLngText(raceRef.name)
                elseif formation[1] == "2" then
                    local careerRef = gModelHero:GetCareerRefByRefId(formationType)
                    for i, v in pairs(selectHeroTable.idToIndex) do
                        local heroSeverData = gModelHero:GetHeroServerDataById(i)
                        local refId = heroSeverData.refId
                        local heroRef = gModelHero:GetHeroRef(refId)
                        if heroRef.careerType == formationType then
                            formationNum = formationNum + 1
                        end
                    end
                    formationName = ccLngText(careerRef.name)
                end
                if formationNum < formationLimit then
                    GF.ShowMessage(string.replace(ccClientText(46507), formationLimit, formationName))
                    return
                end
            end
        end
    elseif gModelBattle:IsPetDreamLandCombat(combatType) then
        fightType = self._battleData.fightType
        dreamLandId = self._battleData.dreamLandId
        targetId = self._battleData.targetId
        skipBattle = self._battleData.skipBattle
    elseif combatType == LCombatTypeConst.COMBAT_TYPE_44 then
        targetId = self._battleData.targetId
        battleRefId = self._battleData.battleRefId

        -- otherName = self._battleData.otherName
        -- eventRefId = self._battleData.eventRefId
    elseif combatType == LCombatTypeConst.COMBAT_TYPE_47 then
        battleRefId = self._battleData.refId
    end

    if combatType == LCombatTypeConst.COMBAT_DESIRETRAIL then
        x = self._battleData.x
        y = self._battleData.y
        skipBattle = self._battleData.skipBattle
    end

    table.sort(grids, function(grid1, grid2)
        return grid1.grid < grid2.grid
    end)

    local eventRefId = self._battleData.eventRefId
    local endFunc = self._battleData.endFunc

    local combatData = {
        ---一个类型可能只是保存战斗阵型,也可以是战斗
        isSetFormation = self._isSetFormation,
        ---阵型设置相关数据
        combatType = combatType,
        formationRefId = formationRefId,
        grids = grids,
        -- artifact = self._artifact,【G公共支持】删除神器功能相关数据
        teamIndex = nil,
        treasureSkilIds = self._treasureSkilIds,
        divineWeaponStarRefIds = self._divineWeaponStarRefIds, -----------------未改-------
        -- treasurePassiveSkill = self._pasvSkillList,
        -- petFights = self:GetCurPetFights(),
        -- petHelps = self:GetCurPetHelps(),
        ---通用战斗请求相关数据

        targetId = targetId,
        skipBattle = skipBattle,
        battleName = self._battleName,
        battleRefId = battleRefId,
        pageId = pageId,
        entryId = entryId,
        x = x,
        y = y,
        eventRefId = eventRefId,

        ---PK请求相关数据
        serverId = self._serverId,
        playerId = self._playerId,
        url = url,
        ---界面显示相关

        isBattleToBackground = false,
        dungeonId = self._dungeonId,
        map = self._map,
        mapRefId = self._mapRefId,
        sid = self._battleData.sid,

        rewardBoxData = rewardBoxData or {},
        chapterEntryId = chapterEntryId or nil,
        fromPrepare = true,

        endFunc = endFunc,
        rank = self._battleData.rank,
        -- bossTowerPkType = bossTowerPkType,
        fightType = fightType,
        dreamLandId = dreamLandId,
        conditionList = self._conditionList
    }

    if self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        combatData.otherName = self._otherName
    end

    if self._isReliefTroop then
        self:FormationReliefTroopData(combatData)
        -- 【G公共支持】删除本命英雄功能
        -- if(LCombatTypeConst.COMBAT_TYPE_34 == combatType and combatData.relFormation)then
        -- 	gModelNaturalPartner:OnDestinyHeroSetFormationReq(combatData.relFormation)
        -- end
        gModelBattle:StartAfterSetFormation(combatData)
    else
        gModelBattle:StartBattleReq(combatData)
    end
    self._isBattleStart = true
end

function UIFightPrepare:OnDrawDivineSkillIcon(list, item, itemdata, itempos)
    local Icon = self:FindWndTrans(item, "Icon")
    local AddImg = self:FindWndTrans(item, "AddImg")
    local LockImg = self:FindWndTrans(item, "LockImg")

    local starRefId = itemdata.refId
    --local showLock = false
    local index = itemdata.index
    local design = nil

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

------------------------------------------------------------------
function UIFightPrepare:IsArrayingTeamLeft()
    return self._teamSide ~= 2
end
function UIFightPrepare:OnBadgeStarCond()
    if self._combatType ~= LCombatTypeConst.COMBAT_BADGE_GAME and self._combatType ~= LCombatTypeConst.COMBAT_ACTIVITY_155 then
        return
    end
    local func = function(raceType, careerType)
        --获取数量
        local num = 0
        local heroIds = self._selectHeroTable.indexToId
        local heroData = nil
        for k, refId in pairs(heroIds or {}) do
            heroData = gModelHero:GetHeroById(refId)
            if (raceType == 0 or (heroData and gModelHero:GetHeroRace(heroData._refId) == raceType))
                    and (careerType == 0 or (heroData and gModelHero:GetHeroCareerType(heroData._refId) == careerType)) then
                num = num + 1
            end
        end
        return num
    end
    -- public_icon_right_2 -public_false_01
    local condRefId = -1
    if self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        for k, v in ipairs(self._conditionList) do
            local ref = GameTable.BadgeGameCondRef[v]
            if ref.type == 4 then
                condRefId = v
                break
            end
        end
    else
        local barrierRef = GameTable.BadgeGameBarrierRef[self._battleData.refId]
        if barrierRef then
            condRefId = barrierRef.starCond2
        end
    end

    local condRef = GameTable.BadgeGameCondRef[condRefId]
    if condRef then
        -- CS.ShowObject(self.mTxtBadgeCond.gameObject,self._combatType == LCombatTypeConst.COMBAT_BADGE_GAME and condRef.type == 4)
        if condRef.type ~= 4 then
            return
        end
        local condStr = string.split(condRef.value, ";")
        local races
        local careers
        local relation--关系
        local condNum = nil --条件数量
        local isOk = false
        local okNum = 0
        for indx, value in ipairs(condStr) do
            local conds = string.split(value, "=")
            races = string.split(conds[1], "|")
            careers = string.split(conds[2], "|")
            relation = tonumber(conds[3])
            condNum = tonumber(conds[4])
            local curNum = 0
            for k, raceType in ipairs(races) do
                for k, careerType in ipairs(careers) do
                    curNum = curNum + func(tonumber(raceType), tonumber(careerType))
                end
            end
            if relation == 1 then
                -- >=
                if curNum >= condNum then
                    okNum = okNum + 1
                end
            else
                -- <=
                if curNum <= condNum then
                    okNum = okNum + 1
                end
            end
        end
        isOk = okNum >= (#condStr)
        local color = isOk and "139057ff" or "C81212ff"
        self:SetXUITextTransColor(self.mTxtStar3, color)
        CS.ShowObject(self.mImgStar3, isOk)
        CS.ShowObject(self.mImgStar3_0, not isOk)
        self._conditionIsOk = isOk
    end
end
function UIFightPrepare:BackSweetCountryBoss()
    local combatExtraData = self._battleData
    self:WndClose()

    local sid, bossRefId = combatExtraData.sid, combatExtraData.bossRefId
    FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.CITY)
    -- GF.OpenWnd("WndSweetCountryChildMag2",{sid = sid, page = 2})
    GF.ChangeMap("LCityMap")
end

function UIFightPrepare:OnClickShare()
    local _curSelectType = self._curSelectType
    --local _curSelectType = self._teamIndex
    --阵容类型|阵容下标

    local combatType = self._combatType
    local index = combatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK and self._teamIndex or 0
    --local combatName = ccLngText(GameTable.BattleGameRef[combatType].name)
    local _shareData = combatType .. ";" .. combatType .. "|" .. index
    local data = {
        root = self.mBtnShare,
        shareType = ModelChat.CHATSHARE_23,
        shareData = _shareData
    }
    gModelGeneral:OpenShareTip(data)
end

------------------------------------------------------------------
function UIFightPrepare:GenerateUIHeroScrollList(func)
    local list = self._uiHeroScrollList
    if not list then
        list = UIListWrap:New()
        self._uiHeroScrollList = list
        list:Create(self, self.mHeroList)
        list:SetFuncOnItemDraw(func)
    end
    return list
end

-- 【C宠物系统】删掉宠物系统相关
-- function UIFightPrepare:OnOneKeySetPetTrea()
-- 	local petList = gModelPetSpace:GetPetDictByType(0,1)
-- 	self._petFights = {}
-- 	self._petHelps = {}
-- 	local setCnt = 1
-- 	for i, v in ipairs(petList) do
-- 		if(petList[i])then
-- 			local id = petList[i].id
-- 			local refId = petList[i].refId
-- 			local canSet = self:CheckPetSetFunc(refId,id)
-- 			if(canSet)then
-- 				if(setCnt<3)then
-- 					local funcIdPre = 3600300
-- 					local funcOpenId = funcIdPre..tostring(setCnt)
-- 					local isOpen = gModelFunctionOpen:CheckIsOpened(tonumber(funcOpenId))
-- 					if(isOpen)then
-- 						self._petFights[setCnt] = id
-- 						setCnt = setCnt + 1
-- 					end
-- 				else
-- 					local funcIdPre = 3600300
-- 					local funcOpenId = funcIdPre..tostring(setCnt)
-- 					local isOpen = gModelFunctionOpen:CheckIsOpened(tonumber(funcOpenId))
-- 					if(isOpen)then
-- 						self._petHelps[setCnt-2] =id
-- 						setCnt = setCnt + 1
-- 					end
-- 				end
-- 			end
-- 			if(setCnt>=4)then
-- 				break
-- 			end
-- 		end
-- 	end
-- end
-- function UIFightPrepare:CheckPetSetFunc(refId,id)
-- 	local petDict = gModelPetSpace:GetPetBagDict()
-- 	if(self:IsMultiTeam())then
-- 		local multiPetList = self:GetMultiTeamRecordPetList()
-- 		for i, v in pairs(multiPetList) do
-- 			local petData = petDict[v.id]
-- 			local isSameRefId = false
-- 			if(petData and petData.refId == refId)then
-- 				isSameRefId = true
-- 			end
-- 			if(v.index ~= self._teamIndex and (v.id == id or isSameRefId))then
-- 				return false
-- 			end
-- 		end
-- 	end
-- 	for i = 1, 2 do
-- 		local fPetData = petDict[self._petFights[i]]
-- 		local hPetData = petDict[self._petHelps[i]]
-- 		if((fPetData and refId == fPetData.refId) or (hPetData and refId == hPetData.refId))then
-- 			return false
-- 		end
-- 	end
-- 	return true
-- end

function UIFightPrepare:ClearSelectTable()
    self._selectHeroTable.cnt = 0
    self._selectHeroTable.idToIndex = {}
    self._selectHeroTable.indexToId = {}
    self._emptyPos = { true, true, true, true, true, true }
end

function UIFightPrepare:ShowOnlySetPart()
    self:ShowOnlySetPower()
    self:ShowOnlySetBuff()
    self:RefreshFormationTag()
end
function UIFightPrepare:ReturnCrusadeAgainst()
    self:WndClose()
    local combatExtraData = self._battleData
    GF.ChangeMap("LCityMap")
    GF.OpenWndBottom("UIDreamKillWin", { bossRefId = combatExtraData.bossRefId })
end

function UIFightPrepare:RefreshPasvShow()
    local dataList = {}
    local pasvList = self._pasvSkillList or {}
    self._pasvSkillList = pasvList
    for i = 1, 3 do
        local skillRefId = pasvList[i] or 0
        table.insert(dataList, {
            refId = skillRefId,
            index = i,
        })
    end
    local root = self:FindWndTrans(self.mPasvTrea, "skillList")
    self:CreateUIScrollImpl("pasvTrea", root, dataList, function(...)
        self:OnDrawPasv(...)
    end)
end

function UIFightPrepare:OnClickMultiTeamHero(herodata)
    local heroId = herodata.id
    local selState, teamIndex = self:GetMultiHeroSelectState(heroId)

    local curRefId = herodata.refId
    if self:IsHeroForbid(heroId, curRefId, true) then
        return
    end

    local isSelect = selState == 1
    local leftPos = self._selectHeroTable.idToIndex[heroId]

    local bHaveEmpty, emptyPos
    local bLineUp = true

    if isSelect then
        bLineUp = false
        self:HeroDown(heroId, leftPos)
        emptyPos = leftPos
    else
        -- local isHighStageRace = gModelHighStageRace:IsHighStageRace(self._combatType)
        -- local lockHeroList = gModelHighStageRace:GetLockHeroList()
        -- if(isHighStageRace and lockHeroList and lockHeroList[curRefId])then
        -- 	return
        -- end

        local selectTable = self._selectHeroTable
        bHaveEmpty, emptyPos = self:GetEmptyPos()
        local cnt = selectTable.cnt
        if not bHaveEmpty or cnt >= self._heroMax then
            local str = ccClientText(16605) --上阵人数已达上限
            GF.ShowMessage(str)
            return
        end

        gModelHero:PlayHeroRoleSound(curRefId, herodata.skin)

        self:HeroUp(heroId, emptyPos)
    end

    FireEvent(EventNames.Scene_Hero_GoTo, heroId, emptyPos, bLineUp, false)
end

function UIFightPrepare:RefreshChangePart()
    if self._wndType == UIFightPrepare.NORMAL then
        self:ShowNormalPart()
    else
        self:ShowOnlySetPart()
    end

    CS.ShowObject(self.mGuildBraveMag, false)

    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        self:ReqPower()
        -- elseif self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("compareFightType") then
        -- 	self:ReqBossTowerPower()
    elseif self._combatType == LCombatTypeConst.COMBAT_GUILD_BRAVE then
        self:RefreshGuildBraveShow()
    elseif self._combatType == LCombatTypeConst.COMBAT_CRUSADE_AGAINST then
        self:RefreshCrusadeAgainst()
        -- 【G公共支持】删除本命英雄功能
        -- elseif(self._combatType == LCombatTypeConst.COMBAT_TYPE_34 )then
        -- 	local monsterId = gModelNaturalPartner:GetCurSeleMonsterFormationId()
        -- 	local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterId)
        -- 	local targetPower = monsterFormationRef.monsterPower
        -- 	self:SetEnemyPower(targetPower)
    end
end

function UIFightPrepare:ShowMonsterBuffStatus()
    local monsterId = gModelBattle:GetMonsterId(self._combatType, self._battleData)
    local monsterRefId = nil
    if monsterId > 0 then
        monsterRefId = monsterId
    end
    local refIdList = {}
    if monsterRefId then
        local tempList = gModelHero:GetMonsterList(monsterRefId)
        for k, v in pairs(tempList) do
            table.insert(refIdList, { id = v, isMon = true })
        end
    end
    self._enemyList = refIdList
    self._isHeroEnemy = false

    self:ShowBuffStatus(false, refIdList)
end

function UIFightPrepare:OnSelectWonderHero(herodata)
    local curRefId = herodata.refId
    local heroId = herodata.id

    if self:IsHeroForbidSingle(heroId, curRefId, true) then
        return
    end

    local isSelect = false
    local selectTable = self._selectHeroTable
    local leftPos = selectTable.idToIndex[heroId]
    if leftPos then
        isSelect = true
    end

    local bHaveEmpty, emptyPos
    local bLineUp = true
    if isSelect then
        bLineUp = false
        self:HeroDown(heroId, leftPos)
        emptyPos = leftPos
    else
        bHaveEmpty, emptyPos = self:GetEmptyPos()
        local cnt = selectTable.cnt
        if not bHaveEmpty or cnt >= self._heroMax then
            local str = ccClientText(16605) --上阵人数已达上限
            GF.ShowMessage(str)
            return
        end

        local serData = gModelBattle:GetHeroData(self._combatType, heroId)
        if serData then
            gModelHero:PlayHeroRoleSound(serData.refId, serData.skin)
        end
        self:HeroUp(heroId, emptyPos)
    end

    FireEvent(EventNames.Scene_Hero_GoTo, heroId, emptyPos, bLineUp, false)
end

function UIFightPrepare:InitRaceTypeList()
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
            return self._heroType == raceType
        end,
    }
    self:GetUIHeroRaceList(data)
end

function UIFightPrepare:OnSelectCombatType(refId)
    self._combatType = refId

    self:ResetIsShowTryHero()
    self:RefreshNameToggle()

    self._isDataReceived = false
    FireEvent(EventNames.ON_CHANGE_BATTLE_TYPE, refId)
    self:RefreshHeroFormation()
end

function UIFightPrepare:CheckHasUnSaved()
    local oldTreasureSkilIds = self._oldTreasureSkilIds or {}
    local treasureSkilIds = self._treasureSkilIds or {}

    local oldDivineWeaponStarRefIds = self._oldDivineWeaponStarRefIds
    local divineWeaponStarRefIds = self._divineWeaponStarRefIds or {}

    local isEqual = gModelGeneral:CheckTreaListEqual(oldTreasureSkilIds, treasureSkilIds)
    if not isEqual then
        return true
    end
    local isEqual = gModelGeneral:CheckTreaListEqual(oldDivineWeaponStarRefIds, divineWeaponStarRefIds)
    if not isEqual then
        return true
    end

    local oldPasvList = self._oldPasvList or {}
    local pasvList = self._pasvSkillList or {}

    isEqual = gModelGeneral:CheckTreaListEqual(oldPasvList, pasvList)
    if not isEqual then
        return true
    end

    local oldPetFights = self._oldPetFights or {}
    local curPetFights = self:GetCurPetFights()
    isEqual = gModelGeneral:CheckTreaListEqual(oldPetFights, curPetFights)
    if not isEqual then
        return true
    end
    local oldPettHelps = self._oldPetHelps or {}
    local curPetHelps = self:GetCurPetHelps()
    isEqual = gModelGeneral:CheckTreaListEqual(oldPettHelps, curPetHelps)
    if not isEqual then
        return true
    end

    if self._formationType ~= self._oldFomationRefId then
        return true
    end

    if self._selectHeroTable.cnt ~= self._oldFormation.cnt then
        return true
    end

    for k, v in pairs(self._selectHeroTable.indexToId) do
        local heroId = self._oldFormation.indexToId[k]
        if heroId ~= v then
            return true
        end
    end

    if self._strategyId ~= self._oldStrategyId then
        return true
    end

    return false
end

function UIFightPrepare:RefreshWonderHeroPower(root)
    local idList = {}
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        table.insert(idList, k)
    end

    local power, percent = gModelWonderland:GetFormationPower(idList)
    -- 【C宠物系统】删掉宠物系统相关
    -- power = power + self:GetPetsPower()
    local powerStr = LUtil.FormatPowerShowStr(power)
    self:SetWndText(root, powerStr)
    local percentStr = ""
    if percent > 0 then
        percentStr = string.format("(+%0.2f%%)", percent * 100)
        percentStr = LUtil.FormatColorStr(percentStr, "green")
        percentStr = LUtil.FormatSizeStr(percentStr, 16)
    end

    self:SetWndText(self.mAddPercent, percentStr)
end

function UIFightPrepare:RefreshGuildBraveShow()
    local info = gModelGuildBoss:GetGuildBraveInfo()
    if not info then
        return
    end
    if string.isempty(info.scoreWord) then
        return
    end

    CS.ShowObject(self.mGuildBraveMag, true)
    local scoreWord = string.split(info.scoreWord, "|")
    local type1List, type2List, type3List = {}, {}, {}
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local heroSeverData = gModelHero:GetHeroServerDataById(k)
        local refId = heroSeverData.refId
        local star = heroSeverData.star

        local heroRef = gModelHero:GetHeroRef(refId)
        local raceType = heroRef.raceType
        local careerType = heroRef.careerType

        local raceNum = type1List[raceType] or 0
        local careerNum = type2List[careerType] or 0
        type1List[raceType] = raceNum + 1
        type2List[careerType] = careerNum + 1
        type3List[refId] = star
    end
    self.type1List, self.type2List, self.type3List = type1List, type2List, type3List

    local addTypeList = {
        [1] = type1List,
        [2] = type2List,
        [3] = type3List,
    }
    local addNum = 0
    for i, v in ipairs(scoreWord) do
        local scoreWordId = tonumber(v)
        local scoreWordEef = gModelGuildBoss:GetNewGuildDungeonBonusRefByRefId(scoreWordId)
        if scoreWordEef then
            local type, para, bonus = scoreWordEef.type, string.split(scoreWordEef.para, "="), scoreWordEef.bonus

            local getTypeList = addTypeList[type]
            local typeNum = para[1]
            local num = para[2]
            local curNum = getTypeList[tonumber(typeNum)] or 0
            if curNum >= tonumber(num) then
                addNum = addNum + bonus
            end
        end
    end
    self:SetWndText(self.mGuildBraveNumText, (addNum * 100) .. "%")

    local addUiList = self._addUiList
    if addUiList then
        addUiList:RefreshList(scoreWord)
        addUiList:DrawAllItems()
    else
        addUiList = self:GetUIScroll("mGuildBraveAddSuper")
        addUiList:Create(self.mGuildBraveAddSuper, scoreWord, function(...)
            self:ScoreWordListItem(...)
        end, UIItemList.SUPER)
        self._addUiList = addUiList
    end
end

-- 获取空位置
function UIFightPrepare:GetEmptyPos()
    for k, v in ipairs(self._emptyPos) do
        if v then
            return true, k
        end
    end
    return false, nil
end

function UIFightPrepare:RefreshRoundInfo()

    local show = self._combatDataList and #self._combatDataList > 1
    CS.ShowObject(self.mRoundInfo, show)
    if not show then
        return
    end
    local itemdata = self._combatDataList[self._selectGroup]
    if not itemdata then
        return
    end

    local strFormat = ccClientText(25319)--"小组赛第%s轮"
    local str = string.replace(strFormat, itemdata.round)
    self:SetWndText(self.mRoundInfo, str)
end

function UIFightPrepare:OnClickCombatGroup(itemdata)
    if self._selectGroup == itemdata.index then
        return
    end

    self._selectGroup = itemdata.index

    local list = self:FindUIScroll("combatGroupList")
    if list then
        list:DrawAllItems(false)
    end

    self:RefreshRoundInfo()

    self:OnChangeGroup(itemdata)
end


-- 阵型设置
function UIFightPrepare:FormationSelEvent(refId)
    --if refId~=1 and self._combatType == LCombatTypeConst.COMBAT_ON_HOOK_DEFEND then return end
    --if self._formationType ==i then return end
    if refId ~= 4 then
        printInfoN2("BatchTask", "Finished Task !!!");
    end
    printInfoN2("checkFormation --- ", "refId--" .. refId);
    if not self._noCheckCombatTypes[self._combatType] then
        local myLv = gModelPlayer:GetPlayerLv()
        local needLv = gModelFormation:GetTacticalNeedLv(refId)
        if myLv < needLv then
            local tacticalName = gModelFormation:GetPositionNameById(refId)
            local str = string.replace(ccClientText(17805), needLv, tacticalName)
            GF.ShowMessage(str)
            return
        end
    end

    local item = self._formationUIList[self._formationType]
    local select = self:FindWndTrans(item, "formation/select")
    local name = self:FindWndTrans(item, "formation/name")
    -- self:SetXUITextbSelect2(name, { "734f22", "5f6d7b" }, false)
    CS.ShowObject(select, false)
    self._formationType = refId
    item = self._formationUIList[self._formationType]
    select = self:FindWndTrans(item, "formation/select")
    name = self:FindWndTrans(item, "formation/name")
    -- self:SetXUITextbSelect2(name, { "734f22", "5f6d7b" }, true)
    CS.ShowObject(select, true)

    FireEvent(EventNames.Change_Hero_Matrix, self._formationType)
    local formationName = gModelFormation:GetPositionNameById(refId)
    self:SetWndText(self.mFormationBtnName, formationName)
    self:InitTextLineWithLanguage(self.mFormationBtnName, -30)

    -- 按钮换图
    local iconPath = self._formationIconList[refId]
    local imageTran = self:FindWndTrans(self.mFormationBtn, "Image")
    self:SetWndEasyImage(imageTran, iconPath)

end

function UIFightPrepare:ShowBuffWnd()
    GF.OpenWnd("UIBf", { refIdList = self:GetSelectBuffWndDataList() })
end

function UIFightPrepare:OnClickCloseFunc()

    if self._returnFunc then
        self._returnFunc()
    else
        GF.ChangeMap("LCityMap")
        GF.OpenWndBottom("UISaga")
    end

    self:WndClose()
end

function UIFightPrepare:GetMeReliefTroopPower()
    local totalPower = 0
    local monPowerMap = self._reliefTroopData.monPowerMap
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local power = monPowerMap[k] or 0
        if power == 0 then
            power = self:GetPower(k)

        end

        totalPower = totalPower + power
    end

    -- 【C宠物系统】删掉宠物系统相关
    -- totalPower = totalPower + self:GetPetsPower()
    return totalPower
end

function UIFightPrepare:OnClickCrossGradingType(refId)
    if self._curSelectType == refId then
        return
    end

    local hasUnSave = self:CheckHasUnSaved()
    local changeFunc = function()
        if self:IsWndClosed() then
            return
        end

        local item = self._fightTypeItems[self._curSelectType]
        if item then
            local BtnTab3 = self:FindWndTrans(item, "BtnTab10")
            self:SetWndTabStatus(BtnTab3, LWnd.StateOff)
        end
        item = self._fightTypeItems[refId]
        if item then
            local BtnTab3 = self:FindWndTrans(item, "BtnTab10")
            self:SetWndTabStatus(BtnTab3, LWnd.StateOn)
        end

        self._curSelectType = refId

        self:SelectCombatTypeFunc(refId)

    end
    if hasUnSave then
        local confirmFun = function()
            self:GotoChallenge(changeFunc)
        end

        local para = {
            refId = 10007,
            func = confirmFun,
            leftFunc = changeFunc,
        }
        gModelGeneral:OpenUIOrdinTips(para)
        return
    end

    changeFunc()
end

function UIFightPrepare:OnClickBossTowerHero(herodata)
    -- local isSelect = false
    -- local heroId = herodata.refId
    -- local selectTable = self._selectHeroTable
    -- local leftPos = selectTable.idToIndex[heroId]
    -- if leftPos then
    -- 	isSelect = true
    -- end
    -- local heroRefId = herodata.heroRefId
    -- local bHaveEmpty,emptyPos
    -- local bLineUp = true
    -- if isSelect then
    -- 	bLineUp = false
    -- 	self:HeroDown(heroId,leftPos)
    -- 	emptyPos = leftPos
    -- else
    -- 	local haveSameName = self._refIdOnFormation[heroRefId]
    -- 	if haveSameName then
    -- 		GF.ShowMessage(ccClientText(10123))
    -- 		return
    -- 	end
    -- 	bHaveEmpty, emptyPos = self:GetEmptyPos()
    -- 	local cnt = selectTable.cnt
    -- 	if not bHaveEmpty or cnt >= self._heroMax then
    -- 		local str = ccClientText(16605) --上阵人数已达上限
    -- 		GF.ShowMessage(str)
    -- 		return
    -- 	end
    -- 	gModelHero:PlayHeroRoleSound(herodata.monsterRefId,0,true)
    -- 	self:HeroUp(heroId,emptyPos)
    -- end
    -- FireEvent(EventNames.Scene_Hero_GoTo, heroId, emptyPos, bLineUp, false,{
    -- 	level = herodata.breakLv
    -- })
end

function UIFightPrepare:ReqFormationData()
    -- local isBossTowerCombat = gModelBossTower:IsBossTowerCombat(self._combatType)
    -- if isBossTowerCombat then
    -- 	local teamIndexSetList = {}
    -- 	local data =
    -- 	{
    -- 		formationType = self._combatType,
    -- 		teamIndex = 0,
    -- 	}
    -- 	table.insert(teamIndexSetList,data)
    -- 	gModelBossTower:OnBossTowerGetFormationReq(self._sid,teamIndexSetList)
    -- else
    if self:IsMultiTeam() then
        --local isUseFirst = self:IsUseFirst()
        local dataList = {}
        if self._combatDataList then
            for k, v in ipairs(self._combatDataList) do
                table.insert(dataList, v.combatType)
            end
        else
            table.insert(dataList, self._combatType)
        end

        gModelFormation:OnGetFormationListReq(dataList)
    else
        if self:CheckIsSpecialCombat() then
            local getFormationType = self:GetSpecialCombatFormationType()
            if getFormationType then
                gModelFormation:OnGetFormationReq(getFormationType, self._teamIndex)
            end
        else
            gModelFormation:OnGetFormationReq(self._combatType, self._teamIndex)
        end
    end
    -- end
end

function UIFightPrepare:OnDrawReliefTroopHeroCell(list, item, itemdata, itempos)
    local heroId = itemdata.id
    local refId

    local pos = self._selectHeroTable.idToIndex[heroId]
    local isSelect = pos ~= nil
    local isMon = itemdata.isMon
    local isResonance = 0
    local star, lv = 0, 0
    local skin = 0
    local fightPower = 0
    local grade = 0

    local checkRefId = nil
    if isMon then
        local monsterRef = gModelHero:GetMonsterAttrByRefId(heroId)
        star, lv = monsterRef.starLv, monsterRef.lv
        refId = monsterRef.refId
        checkRefId = monsterRef.heroId
    else
        local heroData = gModelHero:GetHeroById(heroId)
        if not heroData then
            return
        end
        refId = heroData:GetRefId()
        isResonance = heroData:GetResonanceStatus()
        star, lv = heroData:GetStar(), heroData:GetLv()
        skin = heroData:GetSkin()
        fightPower = heroData:GetPower()
        grade = heroData:GetGrade()
        checkRefId = refId
    end
    local otherMappingIsSel = self:ShowMappingHeroLock(heroId)
    local isLock = self:IsHeroForbidSingle(heroId, checkRefId)
    isLock = isLock or otherMappingIsSel
    local heroPara = {
        id = heroId,
        refId = refId,
        star = star,
        level = lv,
        selected = isSelect,
        showLock = isLock,
        isResonance = isResonance,
        skin = skin,
        isMon = isMon,
        showName = self._showName,
        showType = self._showType,
    }

    local instanceId = item:GetInstanceID()
    local hero = CS.FindTrans(item, "Hero")
    local heroTrans = CS.FindTrans(hero, "HeroIcon")

    local iconCls = self:GetCommonIcon(instanceId)
    iconCls:Create(heroTrans)

    iconCls:SetHeroDataSet(heroPara)
    iconCls:SetNoShowLv(true)
    iconCls:SetShowLvMask(1)
    iconCls:DoApply()

    local lvTxtTrans = self:FindWndTrans(item, "lvTxt")
    if lvTxtTrans then
        self:SetWndText(lvTxtTrans, lv)
        local lvColor, lvMat = LUtil.GetResonanceColor(isResonance)
        self:SetXUITextTransColor(lvTxtTrans, lvColor)
        if lvMat then
            self:SetWndTextMat(lvTxtTrans, lvMat)
        end
    end

    local showHireTag = true
    if self._combatType == LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER
            or self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY then
        showHireTag = false
    end

    local hireTag = self:FindWndTrans(item, "hireTag")
    CS.ShowObject(hireTag, isMon and showHireTag)

    self:SetIconClickScale(heroTrans, true)
    local data = {
        heroId = heroId,
        refId = refId,
        isMonster = isMon,
        checkRefId = checkRefId,
        skin = skin,
    }
    self:SetWndClick(heroTrans, function()
        if (otherMappingIsSel) then
            GF.ShowMessage(ccClientText(38422))
        else
            self:ClickReliefTroopMon(data)
        end
    end)
    self:SetWndLongClick(heroTrans, function()
        if not isMon then
            gModelHero:FindHeroPowStateById(heroId)
            local data = {
                id = heroId,
                refId = refId,
                level = lv,
                star = star,
                grade = grade,
                fightPower = fightPower,
                isResonance = isResonance,
                skin = skin,
            }
            gModelHero:ReqShowHeroTip("", data)
        end
    end, 0.8, false)
end

function UIFightPrepare:ReturnTimeCorridor()

end
function UIFightPrepare:OnClickOpenDivineSkillSet()
    local idRecord = {}
    if self:IsMultiTeam() then
        for k, v in pairs(self._multiTeamRecord.divineRefIdRecord) do
            if k ~= self._teamIndex then
                for k1, v1 in pairs(v) do
                    idRecord[v1] = k + 1
                end
            end
        end
    end

    local para = {
        divineStarRefIds = table.clone(self._divineWeaponStarRefIds),
        combatType = self._combatType,
        targetId = self._battleData.targetId,
        idRecord = idRecord,
        func = function(list)
            if self:IsWndClosed() then
                return
            end
            self._divineWeaponStarRefIds = list
            self:RefreshFormationDivineSkill()
        end
    }

    GF.OpenWnd("UISelFightGodWeapon", para)
end

function UIFightPrepare:OnFormationDataRet()

    local formationData = nil
    local combatType = self._combatType
    local teamIndex = self._teamIndex
    --local isUseFirst = self:IsUseFirst()
    --local isFake = false
    --if isUseFirst then
    --	formationData = gModelFormation:GetFormation(combatType,teamIndex)
    --local data = self._combatDataList[1]
    --if not formationData and data.combatType ~= combatType then
    --	formationData = self:GetCacheFormationData(teamIndex)
    --	if formationData then
    --		isFake = true
    --	end
    --end
    --local isFake = combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING
    local isFake = false
    --else
    -- local isBossTowerCombat = gModelBossTower:IsBossTowerCombat(combatType)
    -- if isBossTowerCombat then
    -- 	formationData = gModelBossTower:GetFormationTeamIndex(self._sid,combatType,teamIndex)
    -- else
    if self:CheckIsSpecialCombat() then
        formationData = self:GetSpecialCombatFormationData()
    else
        formationData = gModelFormation:GetFormation(combatType, teamIndex)
    end
    -- end
    --end
    self:InitHeroFormation(formationData, isFake)

end

function UIFightPrepare:GetMultiTreasureRecord(exceptTeam)
    local record = {}
    for k, v in pairs(self._multiTeamRecord.treasureIdRecord) do
        for k1, v1 in pairs(v) do
            if not exceptTeam or exceptTeam ~= k then
                if v1 > 0 then
                    record[v1] = k
                end
            end
        end
    end

    return record
end

--
function UIFightPrepare:ReturnActivity155()
    self:WndClose()
    GF.ChangeMap("LCityMap")
    GF.OpenWnd("UIActDamselTrial", { sid = self._sid })
end

function UIFightPrepare:RefreshTimeHero()
    --if not gModelBattle:IsTimeCorridorCombat(self._combatType) then
    --	return
    --end
    --
    --local idToIndex = {}
    --local indexToId = {}
    --local cnt = 0
    --for k,v in pairs(self._selectHeroTable.idToIndex) do
    --	local heroData = gModelTimeCorridor:GetHeroData(k)
    --	if heroData then
    --		idToIndex[k] = v
    --		indexToId[v] = k
    --		cnt = cnt + 1
    --	end
    --end
    --
    --self._selectHeroTable.idToIndex = idToIndex
    --self._selectHeroTable.indexToId = indexToId
    --self._selectHeroTable.cnt = cnt
    --
    --self:ShowHeroList()
    --
    --FireEvent(EventNames.REFRESH_FORMATION_SHOW,self._selectHeroTable.idToIndex)
end

function UIFightPrepare:OnDrawWonderHero(list, item, itemdata, itempos)
    local hero = self:FindWndTrans(item, "Hero")
    local heroTrans = self:FindWndTrans(hero, "HeroIcon")
    local deadTag = self:FindWndTrans(item, "deadTag")
    local hireTag = self:FindWndTrans(item, "hireTag")
    local BarBgTrans = self:FindWndTrans(item, "BarBg")
    local lvTxtTrans = self:FindWndTrans(item, "lvTxt")
    local BoolBarTrans
    if BarBgTrans then
        CS.ShowObject(BarBgTrans, true)
        BoolBarTrans = self:FindWndTrans(BarBgTrans, "BoolBar")
    end

    local instanceId = item:GetInstanceID()
    --local commonIconList = self._commonIconList
    local heroIcon = self:GetCommonIcon(instanceId) -- commonIconList[instanceId]
    heroIcon:Create(heroTrans)
    --if not heroIcon then
    --	heroIcon = CommonIcon:New()
    --	commonIconList[instanceId] = heroIcon
    --
    --end

    local id, refId, star, level, grade, fightPower = itemdata.id, itemdata.refId, itemdata.star, itemdata.lvl, itemdata.grade, itemdata.power
    local skin = itemdata.skin
    local isResonance = itemdata.resonance or 0
    local pos = self._selectHeroTable.idToIndex[id]
    local isSelect = pos ~= nil
    local isRefIdOn = self._refIdOnFormation[refId] or false

    if lvTxtTrans then
        self:SetWndText(lvTxtTrans, level)
        local lvColor, lvMat = LUtil.GetResonanceColor(isResonance)
        self:SetXUITextTransColor(lvTxtTrans, lvColor)
        if lvMat then
            self:SetWndTextMat(lvTxtTrans, lvMat)
        end
    end

    local otherMappingIsSel = self:ShowMappingHeroLock(id)
    local herodata = {}
    herodata.trans = heroTrans
    herodata.id = id
    herodata.refId = refId
    herodata.star = star
    herodata.level = level
    herodata.showLock = (not isSelect and isRefIdOn) or otherMappingIsSel

    herodata.skin = skin
    herodata.selected = isSelect
    herodata.isResonance = isResonance
    herodata.showName = self._showName
    herodata.showType = self._showType
    herodata.form = itemdata.form or 0

    local treeInfo = gModelHero:GetHeroTreeInfo(id)
    herodata.treeInfo = treeInfo

    heroIcon:SetHeroDataSet(herodata)
    heroIcon:SetNoShowLv(true)
    heroIcon:SetShowLvMask(1)
    heroIcon:DoApply()

    local isHire = itemdata.heroType == ModelWonderland.HIRE_HERO
    local heroType = isHire and 2 or 1
    self:SetWndClick(heroTrans, function()
        if (otherMappingIsSel) then
            GF.ShowMessage(ccClientText(38422))
        else
            self:OnSelectWonderHero(herodata)
        end
    end)

    self:SetIconClickScale(heroTrans, true)
    self:SetWndLongClick(heroTrans, function()
        local data = {
            id = id,
            refId = refId,
            level = level,
            star = star,
            grade = grade,
            fightPower = fightPower,
            --isWonderHero = isHire,
            heroType = heroType,
            isResonance = isResonance,
            skin = skin,
            treeInfo = treeInfo
        }
        gModelHero:ReqShowHeroTip("", data)
    end, 0.8, false)

    local curHp = itemdata.curHp
    local isDead = curHp <= 0
    CS.ShowObject(deadTag, isDead)

    if BoolBarTrans then
        local maxHp = itemdata.maxHp
        local curVal = curHp / maxHp
        LxUiHelper.SetProgress(BoolBarTrans, curVal)
    end

    CS.ShowObject(hireTag, isHire)
end

function UIFightPrepare:OnlySetFormation()
    local combatType = self._combatType or LCombatTypeConst.COMBAT_MAIN
    local formationRefId = self._formationType
    -- local artifact = self._artifact【G公共支持】删除神器功能相关数据
    local treasureSkilIds = self._treasureSkilIds
    local strategyId = self._strategyId
    local divineWeaponStarRefIds = self._divineWeaponStarRefIds
    self:RecordOldFormation()

    -- local isBossTowerCombat = gModelBossTower:IsBossTowerCombat(self._combatType)
    -- if isBossTowerCombat then
    -- 	local teamIndex = self._teamIndex or 0
    -- 	local dataList = {
    -- 		[teamIndex] = {
    -- 			arrayId = self._formationType,
    -- 			combatType = self._combatType,
    -- 			idToIndex = self._selectHeroTable and self._selectHeroTable.idToIndex or {},
    -- 			-- treasureIdList = {},
    -- 		}
    -- 	}
    -- 	gModelBossTower:OnSetFormationDataList(dataList,self:GetBossTowerSid(),1)
    -- else
    local getCombatType
    if self:CheckIsSpecialCombat() then
        getCombatType = self:GetSpecialCombatFormationType()
    else
        getCombatType = combatType
    end
    if getCombatType then
        -- local curPetFights = self:GetCurPetFights()
        -- local curPetHelps = self:GetCurPetHelps()
        local data = self:FormatFormationData(getCombatType, self._selectHeroTable, formationRefId, artifact, treasureSkilIds, strategyId, self._pasvSkillList, divineWeaponStarRefIds, curPetFights, curPetHelps)
        gModelFormation:OnlySetFormationReq(data)
    end
    -- end
    local isMulti = self:IsMultiTeam()

    if isMulti then
        self._selNextTeamIndex = true
    end
end

function UIFightPrepare:RefreshNameToggle()
    self._showName = false
    self._showType = self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155

    local isForeign = gLGameLanguage:IsForeignRegion()
    local showToggle = not isForeign and gModelBattle:IsShowNameToggle(self._combatType)
    CS.ShowObject(self.mNameToggle, showToggle)
    self:SetWndToggleValue(self.mNameToggle, false)
end

function UIFightPrepare:RefreshHeroCnt(selectTable)
    local cnt = 0
    for k, v in pairs(selectTable.idToIndex) do
        cnt = cnt + 1
    end
    selectTable.cnt = cnt

    self:SetWndText(self.mTxtFormationNum, ccClientText(11001, self._selectHeroTable.cnt, self._heroMax))
end

function UIFightPrepare:RefreshGroupRedData()
    local redRoundMap = {}
    local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_GROUP_FORMATION)
    if showRed then
        local redPointData = gModelRedPoint:GetRedPointNetData(ModelRedPoint.SIMU_GROUP_FORMATION)
        if redPointData then
            local info = redPointData.defaultInfo
            local tempStrs = string.split(info, "=")
            local roundStr = tempStrs[1]
            local numList = LxDataHelper.ParseNumber_Sign(roundStr, '|')
            for k, v in ipairs(numList) do
                redRoundMap[v] = true
            end
        end
    end

    self._redRoundMap = redRoundMap
end

function UIFightPrepare:BackTower()
    local towerType = gModelTower:GetTowerTypeByCombatTyep(self._combatType)
    self:WndClose()
    FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.OUTSKIRTS)
    GF.OpenWndBottom("UITaWin", { towerType = towerType })
    GF.ChangeMap("LCityMap")
end

function UIFightPrepare:HeroDown(heroId, heroIndex)
    if not heroId then
        return
    end
    local emptyPos = self._emptyPos
    local selectTable = self._selectHeroTable

    selectTable.indexToId[heroIndex] = nil
    selectTable.idToIndex[heroId] = nil
    emptyPos[heroIndex] = true
    self:RefreshHeroCnt(selectTable)
    self:RefreshHeroLockState()
    self:RefreshChangePart()
    self:OnBadgeStarCond()
end

function UIFightPrepare:InitUIEvent()

    self:SetWndClick(self.mReturnBtn, function()
        self:OnClickReturn()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mFightBtn, function()
        if self._isClickBattle then
            --  防止多次请求战斗
            self._isClickBattle = false
            self:TimerStart(self._clickBattleKey, self._clickBattleCD, false, -1)

            self:OnClickFightBtn()
        end
    end, LSoundConst.CLICK_FIGHT)
    self:SetWndClick(self.mBattleBtn, function()
        if self._combatType == LCombatTypeConst.COMBAT_ACTIVITY then
            local combatExtraData = self._battleData
            local sid, monsterId = combatExtraData.sid, combatExtraData.monsterId
            GF.OpenWnd("UITaVdoPop", { sid = sid, passId = monsterId, openType = 2 })
            return
        elseif self._channgleBossTypes[self._combatType] then
            -- local combatExtraData = self._battleData
            -- local sid, method, skill = combatExtraData.sid,combatExtraData.method, combatExtraData.skill

            -- GF.OpenWnd("UIFlandBossStrategy",{
            -- 	sid = sid,
            -- 	desc = method,
            -- 	skill = skill
            -- })
            return
        end

        local towerBttleFloor = gModelTower:GetBattleFloor()
        if (gModelTower:GetIsTowerTypeByCombatType(self._combatType) and towerBttleFloor) then
            local towerType = gModelTower:GetTowerTypeByCombatTyep(self._combatType)
            GF.OpenWnd("UITaVdoPop", { refId = towerBttleFloor, towerType = towerType, openType = 1 })
            return
        end

        GF.OpenWnd("UIPkCastWin", {
            battleNode = gModelInstance:GetBattleNode(),
            extraData = self._battleData
        })
    end, LSoundConst.CLICK_BUTTON_COMMON)


    --一键上阵
    self:SetWndClick(self.mGoOnBtn, function()
        --GF.ShowMessage("点击一键上阵")
        self:OneKeyUp()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    --编队
    self:SetWndClick(self.mPresetFormationBtn, function()
        GF.ShowMessage(ccClientText(10717))
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mFormationBtn, function()
        self:PlayShowFormation()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mFormationSkillBtn, function()
        self:OnClickOpenTreasureSet()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mFormationDivineSkill, function()
        self:OnClickOpenDivineSkillSet()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mMeBuffBg, function()
        local refIdList
        if self._combatType == LCombatTypeConst.COMBAT_TEST_BATTLE then
            refIdList = self:GetTestBattleHeroIdList(true)
        else
            refIdList = self:GetSelectBuffWndDataList()
        end
        GF.OpenWnd("UIBf", { refIdList = refIdList })

    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mOtherBuffBg, function()
        self:OnClickOtherBuff()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    local isOpenCard = gModelFunctionOpen:CheckIsOpened(28000000, false)
    CS.ShowObject(self.mBtnCard, isOpenCard)
    CS.ShowObject(self.mBtnCard2, isOpenCard)
    if isOpenCard then
        self:SetWndClick(self.mBtnCard, function()
            GF.OpenWnd("UISorceryCardSpeedSet")
        end)
        self:SetWndClick(self.mBtnCard2, function()
            GF.OpenWnd("UISorceryCardSpeedSet")
        end)
    end
    -- 英雄下阵
    self:WndEventRecv(EventNames.Scene_Hero_Down, function(pos)
        self:OnSceneHeroDown(pos)
    end)
    -- 英雄交换数据
    self:WndEventRecv(EventNames.Swap_Hero_Info, function(...)
        self:OnHeroSwap(...)
    end)

    self:WndEventRecv(EventNames.ON_ENEMY_DATA_RET, function(enemyHeroData)
        self:SetEnemyCombatData(enemyHeroData)
    end)

    self:SetWndClick(self.mBuffbg, function()
        self:ShowBuffWnd()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mSynBtn, function()
        self:OnClickSyn() --布阵同步
    end)

    self:WndEventRecv(EventNames.ON_PLAYER_LEVEL_CHANGE, function()
        --self:CheckShowFormationGuide()
    end)

    self:SetWndToggleDelegate(self.mNameToggle, function(value)

        self._showName = value
        self._showType = self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155

        if self._uiHeroScrollList then
            self._uiHeroScrollList:DrawAllItems()
        end
    end)
    self:SetWndClick(self.mBtnShare, function()
        self:OnClickShare()
    end)

    self:SetWndClick(self.mBtnStrategy, function()
        self:OnClickStrategy()
    end)

    self:WndEventRecv(EventNames.ON_TIME_HERO_CHANGE, function()
        self:RefreshTimeHero()
    end)

    self:SetWndClick(self.mBtnTips, function()
        self:OnClickBtnTip()
    end)

    -- self:SetWndClick(self.mPasvTrea,function ()
    -- 	self:OnClickSetPasv()
    -- end)

    -- self:SetWndClick(self.mPetTrea,function ()
    -- 	self:OnClickSetPet()
    -- end)

    self:InitTouchEvent()
end

function UIFightPrepare:OnClickHero(heroId)
    local heroData = gModelHero:GetHeroServerDataById(heroId)
    if not heroData then
        return
    end

    local refId = heroData.refId

    if self:IsHeroForbidSingle(heroId, refId, true) then
        return
    end

    local selectTable = self._selectHeroTable
    local leftPos = selectTable.idToIndex[heroId]
    local isSelect = leftPos ~= nil

    local bHaveEmpty, emptyPos
    local bLineUp = true
    if isSelect then
        bLineUp = false
        self:HeroDown(heroId, leftPos)
        emptyPos = leftPos
    else
        bHaveEmpty, emptyPos = self:GetEmptyPos()
        local cnt = selectTable.cnt
        if not bHaveEmpty or cnt >= self._heroMax then
            local str = ccClientText(16605)--上阵人数已达上限
            GF.ShowMessage(str)
            return
        end
        local serData = gModelBattle:GetHeroData(self._combatType, heroId)
        if serData then
            gModelHero:PlayHeroRoleSound(serData.refId, serData.skin)
        end
        self:HeroUp(heroId, emptyPos)
    end

    FireEvent(EventNames.Scene_Hero_GoTo, heroId, emptyPos, bLineUp)
    self:OnBadgeStarCond()
end

function UIFightPrepare:FormatFormationData(combatType, selectTable, formationRefId, artifact, treasureSkilIds, strategyId, pasvList, divineWeaponStarRefIds)
    local matrix = gModelFormation:GetFormationPosByRefId(formationRefId)
    local grids = {}
    for k, v in pairs(selectTable.idToIndex) do
        local grid = matrix[v]
        local data = {}
        data.id = k
        data.grid = grid
        table.insert(grids, data)
    end
    table.sort(grids, function(grid1, grid2)
        return grid1.grid < grid2.grid
    end)
    local teamIndex = self._teamIndex or 0
    local data = {
        combatType = combatType,
        formationRefId = formationRefId,
        grids = grids,
        teamIndex = teamIndex,
        -- artifact = artifact,【G公共支持】删除神器功能相关数据
        treasureSkilIds = treasureSkilIds,
        tactics = strategyId,
        divineWeaponStarRefIds = divineWeaponStarRefIds,
        -- treasurePassiveSkill = pasvList,
        -- 【C宠物系统】删掉宠物系统相关
        -- petFights = petFights,
        -- petHelps = petHelps
    }

    return data
end

function UIFightPrepare:OnClickFightBtn()
    if self._combatType == LCombatTypeConst.COMBAT_TEST_BATTLE then
        self:StartTestBattle()
    elseif self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        if self._conditionIsOk == false then
            gModelGeneral:OpenUIOrdinTips({
                refId = 470001,
                func = function()
                    self:GotoChallenge()
                end,
            })
        else
            self:GotoChallenge()
        end
    else
        self:GotoChallenge()
    end
end

function UIFightPrepare:CreateEmptyShow(refId)
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
    -- if gModelBossTower:IsBossTowerCombat(self._combatType) then
    -- 	local showBtn = not gModelBossTower:IsBossTowerCombat(self._combatType)
    -- 	CS.ShowObject(self.mEmptyBtn,showBtn)
    -- end
end

---测试战斗队伍编辑改变

function UIFightPrepare:SwitchTestBattleArrayingFormation()
    self:SaveTestBattleTeamFormation(true)

    local teamSide = self._teamSide
    local newTeamSide = 1
    if teamSide == 1 then
        newTeamSide = 2
    end
    self._teamSide = newTeamSide
    FireEvent(EventNames.SCENE_ARRAYING_FORMATION_CHANGE, self._teamSide)
    self:InitTestHeroFormation()
end


-- 英雄列表
function UIFightPrepare:InitScrollView()
    local dataList = {}

    --[[	local heroList = gModelHero:GetHeroSortList()
	if heroList then
		for k,v in pairs(heroList) do
			local refId = v:GetRefId()
			local heroId = v:GetId()
			local race = gModelHero:GetHeroRace(refId)
			if self._heroType == 0 or self._heroType == race then
				if not self._raceKeyList or self._raceKeyList[race] then
					if self._isShowTryHero or  not v:IsTryHero() then
						table.insert(dataList,heroId)
					end
				end
			end
		end
	end]]

    local heroList = gModelHero:GetLimitRaceHeroList({
        curRaceType = self._heroType,
        raceKeyList = self._raceKeyList,
        isShowTryHero = self._isShowTryHero,
        combatType = self._combatType,
        careerType = self._careerType
    })
    for i, v in ipairs(heroList) do
        table.insert(dataList, v:GetId())
    end

    local uiList = self._uiHeroScrollList
    if not uiList then
        uiList = self:GenerateUIHeroScrollList(function(...)
            self:OnDrawHeroCell(...)
        end)
    end
    uiList:RemoveAll()
    local cnt = #dataList
    local bool = cnt <= 0
    CS.ShowObject(self.mNoRecord, bool)
    if (bool) then
        local emptyRefId = 17001
        if self._showCombatSpiritHeroStatus and self._heroType == ModelSpiritHero.SPIRITHERO_RACE then
            emptyRefId = 10011
        end
        self:CreateEmptyShow(emptyRefId)
    end
    for i = 1, cnt do
        local heroId = dataList[i]
        uiList:AddData(heroId, heroId)
    end
    uiList:RefreshList()
    if self:CheckIsSpecialCombat() then
        self:GetSpecialMonsterPower()
    end
end

function UIFightPrepare:OnClickOtherBuff()
    local refIdList
    if self._combatType == LCombatTypeConst.COMBAT_TEST_BATTLE then
        refIdList = self:GetTestBattleHeroIdList(false)
    elseif self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then

    else
        refIdList = self._enemyList
    end
    GF.OpenWnd("UIBf", { refIdList = refIdList, isHero = self._isHeroEnemy })


end
---初始化援军阵型
function UIFightPrepare:InitReliefTroopFormation(formation)
    self:ClearSelectTable()
    local reliefTroopData = self._reliefTroopData
    local formationRefId = reliefTroopData.formation or 0
    if formationRefId == 0 then
        formationRefId = 1
    end

    for k, v in ipairs(reliefTroopData.monList or {}) do
        local heroId = v.refId
        local index = v.index
        self._selectHeroTable.idToIndex[heroId] = index
        self._selectHeroTable.indexToId[index] = heroId
        self._emptyPos[index] = false
    end
    -- 【G公共支持】删除本命英雄功能
    -- if(self._combatType == LCombatTypeConst.COMBAT_TYPE_34 and formation)then
    -- 	for k,v in ipairs(formation.grids or {}) do
    -- 		local heroId = tonumber(v.id)
    -- 		local index = v.grid
    -- 		local matrixRefId = formation.formationRefId
    -- 		local posIndex = gModelFormation:GetIndexByPos(matrixRefId,index)
    -- 		if(self._selectHeroTable.idToIndex[heroId])then
    -- 			self._selectHeroTable.indexToId[self._selectHeroTable.idToIndex[heroId]] = nil
    -- 			self._emptyPos[self._selectHeroTable.idToIndex[heroId]] = true
    -- 		end
    -- 		self._selectHeroTable.idToIndex[heroId] = posIndex
    -- 		self._selectHeroTable.indexToId[posIndex] = heroId
    -- 		self._emptyPos[posIndex] = false
    -- 	end
    -- end

    for k, v in ipairs(reliefTroopData.heroList or {}) do
        local heroId = v.id
        local index = v.index
        self._selectHeroTable.idToIndex[heroId] = index
        self._selectHeroTable.indexToId[index] = heroId
        self._emptyPos[index] = false
    end

    self:RefreshHeroCnt(self._selectHeroTable)
    -- self._artifact = 0【G公共支持】删除神器功能相关数据

    self._treasureSkilIds = {}
    if formation then
        for k, v in ipairs(formation._treasureSkilIds or {}) do
            table.insert(self._treasureSkilIds, v)
        end
    end
    self._divineWeaponStarRefIds = {}
    if formation then
        for k, v in ipairs(formation.divineWeaponStarRefIds or {}) do
            table.insert(self._divineWeaponStarRefIds, v)
        end
    end

    self:RefreshFormationSkillShow()
    self:RefreshFormationDivineSkill()
    self:RefreshPasvShow()
    -- 【C宠物系统】删掉宠物系统相关
    -- self:RefreshPetTreaBtnShow()


    self:FormationSelEvent(formationRefId)

    self:RecordOldFormation()
    self:RefreshChangePart()
    self:ShowHeroList()
end
function UIFightPrepare:CrusadeAgainstListItem(list, item, itemdata, itempos)
    local text = self:FindWndTrans(item, "UIText")
    local type = itemdata.type
    local value = itemdata.value
    local selectHeroTable = self._selectHeroTable
    local str = ""
    if type == 1 then
        local cnt = selectHeroTable.cnt
        local num = value
        local numStr = string.format("%s/%s", cnt, num)
        numStr = LUtil.FormatColorStr(numStr, cnt == num and "green" or "lightRed")
        str = string.replace(ccClientText(32309), numStr)
    elseif type == 2 then
        local formation = string.split(value, "=")
        local formationType, formationLimit, formationNum, formationName = tonumber(formation[2]), tonumber(formation[3]), 0, ""
        if formation[1] == "1" then
            local raceRef = gModelHero:GetHeroRaceRefByRefId(formationType)
            for i, v in pairs(selectHeroTable.idToIndex) do
                local heroSeverData = gModelHero:GetHeroServerDataById(i)
                local refId = heroSeverData.refId
                local heroRef = gModelHero:GetHeroRef(refId)
                if heroRef.raceType == formationType then
                    formationNum = formationNum + 1
                end
            end
            formationName = ccLngText(raceRef.name)
        elseif formation[1] == "2" then
            local careerRef = gModelHero:GetCareerRefByRefId(formationType)
            for i, v in pairs(selectHeroTable.idToIndex) do
                local heroSeverData = gModelHero:GetHeroServerDataById(i)
                local refId = heroSeverData.refId
                local heroRef = gModelHero:GetHeroRef(refId)
                if heroRef.careerType == formationType then
                    formationNum = formationNum + 1
                end
            end
            formationName = ccLngText(careerRef.name)
        end
        local numStr = string.format("%s/%s", formationNum, formationLimit)
        numStr = LUtil.FormatColorStr(numStr, formationNum >= formationLimit and "green" or "lightRed")
        str = string.replace(ccClientText(32337), numStr, formationName)
    elseif type == 3 then
        local requirement = string.split(value, "=")
        if requirement[1] == "1" then
            str = string.replace(ccClientText(32311), requirement[2])
        elseif requirement[1] == "2" then
            str = string.replace(ccClientText(32334), requirement[2])
        elseif requirement[1] == "3" then
            str = string.replace(ccClientText(32335), requirement[2])
        end
    end
    self:SetWndText(text, str)
    self:InitTextLineWithLanguage(text, -30)
    self:InitTextModeWithLanguage(text)
end

function UIFightPrepare:ShowPetDreamLandTeamSet()
    self._fightTypeItems = {}
    self:SetWndText(self.mNameText, gModelPlayer:GetPlayerName())
    local fightText = self:FindWndTrans(self.mFightBtn, "FightTxt")
    local str = ccClientText(10353)
    self:SetWndText(fightText, str)
    self._teamCount = 2
    local dataList = {}
    table.insert(dataList, {
        teamIndex = 0,
        refId = LCombatTypeConst.COMBAT_TYPE_41,
        nameStr = ccClientText(43392),
    })
    table.insert(dataList, {
        teamIndex = 1,
        refId = LCombatTypeConst.COMBAT_TYPE_42,
        nameStr = ccClientText(43393),
    })
    local combatTypeNum = #dataList
    if combatTypeNum <= 0 then
        self:ShowBottomPart()
        return
    end
    self._needClose = combatTypeNum <= 1

    local curSelType = dataList[1].refId
    self._curSelectType = curSelType
    self:InitCombatList(dataList)

    self:OnSelectCombatType(curSelType)

    CS.ShowObject(self.mCombatList, true)
    CS.ShowObject(self.mSwapCombatList, false)
    CS.ShowObject(self.mTypePart, true)
end

function UIFightPrepare:GetNoShowRaceList()
    local heroRaceRefIdList = {}
    heroRaceRefIdList[UIHeroRaceList.ALL_RACE_REFID] = UIHeroRaceList.ALL_RACE_REFID
    for k, v in pairs(GameTable.CharacterRaceRef) do
        heroRaceRefIdList[k] = k
    end

    local list = {}
    if self._race then
        local _race = self._race
        local _raceArr = string.split(_race, ";")
        local keyList = {}
        for i, v in ipairs(_raceArr) do
            keyList[tonumber(v)] = v
        end
        self._raceKeyList = keyList
        for k, v in pairs(heroRaceRefIdList) do
            if not keyList[k] and k ~= UIHeroRaceList.ALL_RACE_REFID then
                list[k] = k
            end
        end
    end
    local isEndless = gModelBattle:IsEndlessCombat(self._battleData.combatType)
    if (isEndless) then
        local specialType = gModelEndles:GetEndlessTypeByCombatType(self._battleData.combatType)

        local raceRecord = gModelEndles:GetRaceRecord(specialType)
        if specialType == 1 then
            self._heroType = 0
        end
        self._raceKeyList = raceRecord
        --local race = gModelEndles:GetIsRace(specialType,0)
        --self._heroType = race

        --local tRace
        for k, v in pairs(heroRaceRefIdList) do
            if not raceRecord[k] then
                if k ~= UIHeroRaceList.ALL_RACE_REFID then
                    list[k] = k
                end
            else
                if not self._heroType then
                    self._heroType = k
                end
            end

            --tRace = gModelEndles:GetIsRace(specialType,k)
            --if tRace ~= k then
            --	list[k] = k
            --end
        end
        self:InitEndlessHeroList()
    end

    if self._combatType and self._raceKeyList then
        self._showCombatSpiritHeroStatus = gModelFormation:CheckCombatShowSpiritHero(self._combatType)
        if self._showCombatSpiritHeroStatus then
            if list[ModelSpiritHero.SPIRITHERO_RACE] then
                list[ModelSpiritHero.SPIRITHERO_RACE] = nil
            end
            self._raceKeyList[ModelSpiritHero.SPIRITHERO_RACE] = tostring(ModelSpiritHero.SPIRITHERO_RACE)
        end
    end

    return list
end

function UIFightPrepare:BackArenaPeak()
    self:WndClose()

    GF.ChangeMap("LCityMap")
    GF.OpenWndBottom("UIringPk")
end

function UIFightPrepare:RefreshMePower(root)
    root = root or self.mMeFightNum
    if self._combatType == LCombatTypeConst.COMBAT_WONDERLAND then
        -- 爱欲小径 走通用
        self:RefreshWonderHeroPower(root)
    elseif gModelBattle:IsTimeCorridorCombat(self._combatType) then
        self:RefreshTimeCorridorHeroPower(root)
    elseif (gModelBattle:IsEndlessCombat(self._combatType)) then
        self:RefreshEndlessHeroPower(root)
    elseif self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        local mePower = self:GetMeLibraryPower()
        local str = LUtil.FormatPowerShowStr(mePower)
        self:SetWndText(root, str)
    else
        local mePower = nil
        if self._isReliefTroop then
            mePower = self:GetMeReliefTroopPower()
        else
            mePower = self:GetMePower()
        end

        local str = LUtil.FormatPowerShowStr(mePower)

        self:SetWndText(root, str)
    end
end

function UIFightPrepare:ReturnActivityDreamTrip()
    local combatExtraData = self._battleData
    if combatExtraData then
        local returnFunc = combatExtraData.returnFunc
        if returnFunc then
            returnFunc()
        end
    end

    self:WndClose()
end

function UIFightPrepare:RefreshTimeCorridorFormation()
    --local isNeedReset = false
    --local combatType = self._combatType
    --local heroGridData = gModelFormation:GetHeroFormationData(combatType)
    --for k,v in pairs(heroGridData) do
    --	local heroId = v.heroId
    --	local heroData = gModelTimeCorridor:GetHeroData(heroId)
    --	if heroData and not gModelTimeCorridor:IsHeroCanUse(heroData.refId) then
    --		isNeedReset = true
    --		break
    --	end
    --end
    --
    --if isNeedReset then
    --	self:OneKeyUp()
    --else
    --	FireEvent(EventNames.REFRESH_MY_HERO_SHOW)
    --end
end

function UIFightPrepare:ShowNormalPart()
    self:ShowSelfBuffStatus()
    if self:IsArrayingTeamLeft() then
        self:RefreshMePower()
    else
        self:RefreshTestBattleOtherPower()
    end
end

function UIFightPrepare:OnTryTcpLost()
    self:ShowBottomPart()
end

function UIFightPrepare:ShowBottomPart()
    FireEvent(EventNames.BATTLE_MAP_OFFSET, self._mapOffset, 0.4, true)
    FireEvent(EventNames.BATTLE_MAP_BG_OFFSET, 1.28)
    self:InitUIShow(true, 0.4)
end

function UIFightPrepare:OneKeyUp()
    if self._isReliefTroop then
        return
    end
    self:ClearSelectTable()
    local selectTable = self._selectHeroTable
    local specialType = gModelEndles:GetEndlessTypeByCombatType(self._combatType)

    -- local isBossTowerCombat = gModelBossTower:IsBossTowerCombat(self._combatType)
    local indexToHeroIdList = {}
    -- if isBossTowerCombat then
    -- 	indexToHeroIdList = gModelFormation:GetBossTowerOneKeyUpFormation(self._formationType,self._raceKeyList,self._sid)
    -- else
    if self:IsMultiTeam() then
        local idRecord = self:GetMultiHeroIdRecord(self._teamIndex)
        -- local isHighStageRace = gModelHighStageRace:IsHighStageRace(self._combatType)
        local lockHeroList
        -- if(isHighStageRace)then
        -- 	lockHeroList = gModelHighStageRace:GetLockHeroList()
        -- end
        indexToHeroIdList = gModelFormation:GetMultiOneKey(self._formationType, self._raceKeyList, idRecord, nil, lockHeroList)
    else
        indexToHeroIdList = gModelFormation:GetOneKeyUpFormation(self._combatType, self._formationType, specialType, self._raceKeyList, self._battleData)
    end
    -- end

    for k, v in pairs(indexToHeroIdList) do
        selectTable.idToIndex[v] = k
        selectTable.indexToId[k] = v
        self._emptyPos[k] = false
    end

    self:RefreshHeroCnt(selectTable)

    if selectTable.cnt == 0 then
        local str = ccClientText(10918) --"当前无伙伴可上阵"
        GF.ShowMessage(str)
    end

    local isNotUseTreasure = gModelFormation:CheckTreasureNotUse(self._combatType)
    local list = {}
    if not isNotUseTreasure then
        local idRecord = {}
        if self:IsMultiTeam() then
            idRecord = self:GetMultiTreasureRecord(self._teamIndex)
        end
        list = gModelDraconic:GetOneKeyFormationRefIdList(idRecord)
    end
    self._treasureSkilIds = list

    local isNotUseDivine = gModelFormation:CheckDivineNotUse(self._combatType)
    local divineList
    if not isNotUseDivine then
        local idRecord = {}
        if self:IsMultiTeam() then
            idRecord = self:GetMultiDivineRecord(self._teamIndex)
        end
        divineList = gModelDivineWeapon:GetOneKeyFormationRefIdList(idRecord)
    end
    self._divineWeaponStarRefIds = divineList

    self:RefreshFormationSkillShow()
    self:RefreshFormationDivineSkill()

    -- list = {}
    -- if not isNotUseTreasure then
    -- 	list = gModelFormation:OneKeyPasvTrea()
    -- end

    self._pasvSkillList = list
    --todo 被动技能一键上阵
    self:RefreshPasvShow()

    -- 【C宠物系统】删掉宠物系统相关
    --宠物一键上阵
    -- self:OnOneKeySetPetTrea()
    -- self:RefreshPetTreaBtnShow()

    self:RefreshHeroLockState()

    self:RefreshChangePart()

    self:OnBadgeStarCond()

    FireEvent(EventNames.ONE_KEY_FORMATION, selectTable.idToIndex, self._sid)
end

function UIFightPrepare:BackArenaRank()
    self:WndClose()

    GF.ChangeMap("LCityMap")
    GF.OpenWndBottom("UIringRk")

    --gModelGeneral:OpenPopWnd()
end
function UIFightPrepare:RefreshCrusadeAgainst()
    local battleData = self._battleData
    local targetId = battleData.targetId
    if not targetId then
        return
    end
    local ref = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(targetId)
    local list = {}
    if not string.isempty(ref.num) then
        table.insert(list, { type = 1, value = ref.num })
    end
    if not string.isempty(ref.formation) then
        table.insert(list, { type = 2, value = ref.formation })
    end
    if not string.isempty(ref.requirement) then
        table.insert(list, { type = 3, value = ref.requirement })
    end
    CS.ShowObject(self.mCrusadeAgainstMag, #list > 0)
    local againstUiList = self._againstUiList
    if againstUiList then
        againstUiList:RefreshList(list)
    else
        againstUiList = self:GetUIScroll("mCrusadeAgainstScroll")
        againstUiList:Create(self.mCrusadeAgainstScroll, list, function(...)
            self:CrusadeAgainstListItem(...)
        end)
        self._againstUiList = againstUiList
    end
end

function UIFightPrepare:OnDrawBossTowerHeroCell(list, item, itemdata, itempos)
    -- local hero = self:FindWndTrans(item,"Hero")
    -- local heroTrans = self:FindWndTrans(hero,"HeroIcon")
    -- local lvTxtTrans = self:FindWndTrans(item,"lvTxt")

    -- local refId = itemdata.refId
    -- local bossTowerRef = gModelBossTower:GetBossTowerHeroRefByRefId(refId)
    -- local heroType = bossTowerRef.type
    -- local monsterRefId = bossTowerRef and bossTowerRef.attr
    -- local monsterRef = gModelHero:GetMonsterAttrByRefId(monsterRefId)

    -- local pos = self._selectHeroTable.idToIndex[refId]
    -- local isSelect = pos~=nil
    -- local isRefIdOn = self._refIdOnFormation[heroType] or false

    -- local showLock = not isSelect and isRefIdOn
    -- local breakLv = itemdata.breakLv

    -- local InstanceID = item:GetInstanceID()
    -- local baseClass = self:GetCommonIcon(InstanceID)
    -- baseClass:Create(heroTrans)
    -- local heroData = {
    -- 	refId = heroType,
    -- 	star = monsterRef and monsterRef.starLv,
    -- 	level = breakLv,
    -- 	showLock = showLock,
    -- 	selected = isSelect,
    -- }
    -- baseClass:SetHeroDataSet(heroData)
    -- baseClass:DoApply()
    -- self:SetIconClickScale(heroTrans,true)
    -- self:SetWndClick(heroTrans,function()
    -- 	local theroData = {
    -- 		refId = refId,
    -- 		heroRefId = heroType,
    -- 		monsterRefId = monsterRefId,
    -- 		breakLv = breakLv,
    -- 	}
    -- 	self:OnClickBossTowerHero(theroData)
    -- end)
    -- self:SetWndText(lvTxtTrans,breakLv)
end

function UIFightPrepare:BackBtIdle()
    self:WndClose()
    FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.ADVENTURE)
    GF.ChangeMap("LFightIdleMap")
    --GF.OpenWndBottom("UIMinFight")
end

function UIFightPrepare:TypeBtnEvent(index, btnTrans)
    if self._raceKeyList and index ~= 0 and not self._raceKeyList[index] then
        --GF.ShowMessage(ccClientText(12155))
        return
    end
    --local isEndless = gModelBattle:IsEndlessCombat(self._battleData.combatType)
    --if(isEndless)then
    --	local specialType = gModelEndles:GetEndlessTypeByCombatType(self._battleData.combatType)
    --	local raceRecord = gModelEndles:GetRaceRecord(specialType)
    --	if not raceRecord
    --	local race = gModelEndles:GetIsRace(specialType,index)
    --	if(race ~= index)then
    --		return
    --	end
    --end
    self._heroType = index
    self:ShowHeroList()
end

function UIFightPrepare:ReturnPetDreamLand()
    local returnFunc = self._battleData and self._battleData.returnFunc
    if returnFunc then
        returnFunc()
    else
        self:BackBtIdle()
    end
end

function UIFightPrepare:ShowHeroList()

    if self._isBattleStart then
        return
    end

    self:RefreshOnFormationRefId()

    if self._isReliefTroop then
        self:ShowReliefTroopHeroList()
    elseif self._combatType == LCombatTypeConst.COMBAT_WONDERLAND then
        -- 爱欲小径 走通用
        self:ShowWonderHeroList()
    elseif gModelBattle:IsTimeCorridorCombat(self._combatType) then
        self:ShowTimeCorridorHeroList()
    elseif gModelBattle:IsEndlessCombat(self._combatType) then
        self:ShowEndelssHeroList()
    elseif self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        self:InitLibraryScrollView()
        -- elseif self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("compareFightType") then
        -- 	self:InitBossTowerHeroList()
    else
        if self:IsMultiTeam() then
            self:RefreshMultiTeamHeroList()
        else
            self:InitScrollView()
        end
    end
end

function UIFightPrepare:ShowCombatGroupList()
    local show = self._combatDataList and #self._combatDataList > 1
    CS.ShowObject(self.mGroupBtnRoot, show)
    if not show then
        return
    end

    local para = self:GetWndArg("para")

    self._selectGroup = para.groupIndex

    self:RefreshRoundInfo()

    self:RefreshGroupRedData()

    local list = self:FindUIScroll("combatGroupList")
    if not list then
        list = self:GetUIScroll("combatGroupList")
        list:Create(self.mGroupList, self._combatDataList, function(...)
            self:OnDrawCombatGroup(...)
        end)
    else
        list:RefreshList(self._combatDataList)
    end
end

function UIFightPrepare:CheckIsSpecialCombat()
    local specialInfo = self:GetSpecialCombatInfo()
    if specialInfo then
        return true
    end
    return false
end
function UIFightPrepare:RefreshTimeCorridorHeroPower(root)
    --local idList = {}
    --for k,v in pairs(self._selectHeroTable.idToIndex) do
    --	table.insert(idList,k)
    --end

    --local power,percent = gModelTimeCorridor:GetFormationPower(idList)
    -- 【C宠物系统】删掉宠物系统相关
    -- power = power + self:GetPetsPower()

    --local powerStr =LUtil.FormatPowerShowStr(power)
    --self:SetWndText(root,powerStr)
    --local percentStr = ""
    --if percent>0 then
    --	percentStr = string.format("(+%0.2f%%)",percent*100)
    --	percentStr = LUtil.FormatColorStr(percentStr,"lightGreen")
    --	percentStr = LUtil.FormatSizeStr(percentStr,16)
    --end
    --self:SetWndText(self.mAddPercent,percentStr)
end
function UIFightPrepare:GetMultiDivineRecord(exceptTeam)
    local record = {}
    for k, v in pairs(self._multiTeamRecord.divineRefIdRecord) do
        for k1, v1 in pairs(v) do
            if not exceptTeam or exceptTeam ~= k then
                if v1 > 0 then
                    record[v1] = k
                end
            end
        end
    end

    return record
end

--万圣节boss挑战
function UIFightPrepare:BackHalloweenBoss()
    -- local combatExtraData = self._battleData
    -- self:WndClose()

    -- local sid, bossRefId = combatExtraData.sid, combatExtraData.bossRefId
    -- FireEvent(EventNames.CHANGE_MAIN_BTN,1)
    -- GF.OpenWnd("UIActHalloweenMag",{sid = sid, page = ModelActivity.HALLOWEEN_PAGE_3})
    -- GF.ChangeMap("LCityMap")
end

function UIFightPrepare:GetTestBattleHeroIdList(isLeft)
    local nowArrayingLeft = self:IsArrayingTeamLeft()
    local heroList = {}
    if (nowArrayingLeft and isLeft) or (not nowArrayingLeft and not isLeft) then
        for k, v in pairs(self._selectHeroTable.indexToId) do
            local heroData = gModelHero:GetHeroById(v)
            table.insert(heroList, { id = heroData:GetRefId() })
        end
    else
        local formation = LFightTest.GetFormationData(isLeft and 1 or 2) or {}
        for k, v in pairs(formation.grids or {}) do
            local heroData = gModelHero:GetHeroById(v.id)
            table.insert(heroList, { id = heroData:GetRefId() })
        end
    end

    return heroList
end

function UIFightPrepare:ShowEnemyBuffStatus(enemydata)
    local refIdList = {}
    local tempList = enemydata.prefabNameList
    for k, v in pairs(tempList) do
        table.insert(refIdList, { id = v.refId })
    end
    self._enemyList = refIdList
    self._isHeroEnemy = true
    self:ShowBuffStatus(false, refIdList)
end

function UIFightPrepare:SetPlayerName()
    local meName = self._battleData.meName or gModelPlayer:GetPlayerName()
    self:SetWndText(self.mMeName, meName)
    local otherName = gModelBattle:GetOtherName(self._battleData)
    otherName = self._battleData.otherName or otherName
    if otherName then
        self:SetWndText(self.mOtherName, otherName)
    end

    self._meName = meName
    self._otherName = otherName

    self._battleData.meName = meName
    self._battleData.otherName = otherName

    self:InitTextSizeWithLanguage(self.mMeName, -2)
    self:InitTextSizeWithLanguage(self.mOtherName, -2)

end

function UIFightPrepare:RefreshHeroFormation()
    local hasData, formationData, isFake = self:CheckHasFormationData()

    if hasData then
        self:InitHeroFormation(formationData, isFake)
    else
        self:ReqFormationData()
    end
end

function UIFightPrepare:ShowOnlySetWnd()
    CS.ShowObject(self.mBloodRoot, false)
    CS.ShowObject(self.mArenaOpt, false)
    CS.ShowObject(self.mBattleBtn, false)
    CS.ShowObject(self.mSetRoot, true)
    CS.ShowObject(self.mBg, false)

    local showShareBtn = true
    if self._hideShareBtn[self._combatType] then
        showShareBtn = false
    end
    CS.ShowObject(self.mBtnShare, showShareBtn)

    self._isUsePlayerTreasureInfo = true

    if self:IsMultiTeam() then
        self:ShowMultiTeamSet()
    elseif gModelBattle:IsPetDreamLandCombat(self._combatType) then
        self:ShowPetDreamLandTeamSet()
    else
        self:ShowSingleTeamSet()
    end
end

function UIFightPrepare:OnLongClickLibraryHero(heroPara)
    if not gLGameLanguage:IsJapanRegion() then
        return
    end

    local heroId = heroPara.id
    gModelGeneral:OpenHeroShareWnd({ refId = heroId, wndType = 4 })
end

function UIFightPrepare:InitReliefTroop()
    self._isReliefTroop, self._reliefTroopData = gModelBattle:GetReliefTroopData(self._combatType, self._battleData)
    --if self._isReliefTroop and self._combatType~=LCombatTypeConst.COMBAT_TYPE_34 then
    -- if self._isReliefTroop then
    -- 	self._noNeedAskTreasure[self._combatType] = not self._reliefTroopData.treasure
    -- end
end

function UIFightPrepare:ShowInvasionBuffStatus()
    local bossList = self._bossList
    local isMonster = self._battleData.monster == 1
    local refIdList = {}

    for k, v in pairs(bossList) do
        table.insert(refIdList, { id = v.refId, isMon = isMonster })
    end
    self._enemyList = refIdList
    self._isHeroEnemy = not isMonster
    self:ShowBuffStatus(false, refIdList)
end

function UIFightPrepare:CheckHasFormationData()
    local formationData = nil
    local hasData = false

    local isFake = false
    local combatType = self._combatType
    local teamIndex = self._teamIndex
    --local isUseFirst = self:IsUseFirst()
    --if isUseFirst then
    --	local lackData = false
    --	for k,v in ipairs(self._combatDataList) do
    --		local tempData = gModelFormation:GetFormation(v.combatType,teamIndex)
    --		if not tempData then
    --			lackData = true
    --			break
    --		end
    --	end
    --	hasData = not lackData
    --
    --	if hasData then
    --		formationData = gModelFormation:GetFormation(combatType,teamIndex)
    --
    --		if not formationData or not formationData.grids or #formationData.grids == 0 then
    --			local first = self._combatDataList[1]
    --			if first and first.combatType ~= combatType then
    --				formationData = self:GetCacheFormationData(teamIndex)
    --				isFake = true
    --			end
    --		end
    --	end
    --else
    -- local isBossTowerCombat = gModelBossTower:IsBossTowerCombat(combatType)
    -- if isBossTowerCombat then
    -- 	formationData = gModelBossTower:GetFormationTeamIndex(self._sid,combatType,teamIndex)
    -- else
    if self:CheckIsSpecialCombat(combatType) then
        formationData = self:GetSpecialCombatFormationData()
    else
        formationData = gModelFormation:GetFormation(combatType, teamIndex)

        if formationData == nil and combatType == LCombatTypeConst.COMBAT_DESIRETRAIL and teamIndex == 0 then
            formationData = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_MAIN, teamIndex)
        end
    end
    -- end
    hasData = formationData ~= nil
    --end

    return hasData, formationData, isFake
end

function UIFightPrepare:ParseCombatHeroData(combatHeroData)
    local power = 0

    local formationRefId = combatHeroData._formationRefId
    local heros = combatHeroData:GetHeros()
    local grids = combatHeroData:GetGrids()
    local prefabNameList = {}
    for i, v in ipairs(heros) do
        local index = gModelFormation:GetIndexByPos(formationRefId, grids[i])
        local refId = v.refId
        local skin = v.skin
        local prefabName, needFlip = gModelHero:GetHeroDisplay(refId, v.star, skin, true, v.form)
        power = v.fightPower
        table.insert(prefabNameList, {
            pos = index,
            prefabName = prefabName,
            bottomImg = gModelHero:GetHeroBottomImgByRefId(refId),
            race = gModelHero:GetHeroRace(refId),
            lv = v.lv,
            isResonance = v.isResonance,
            skin = skin,
            needFlip = needFlip,
        })
    end

    local combat = {
        matrixRefId = formationRefId,
        prefabNameList = prefabNameList,
    }

    return power, combat
end

function UIFightPrepare:ChangeSelectSide(side)
    if self._teamSide == side then
        return
    end

    self:SaveMirrorBattleTeamFormation(self._teamSide)

    self._teamSide = side

    FireEvent(EventNames.SCENE_ARRAYING_FORMATION_CHANGE, self._teamSide)
    self:InitMirrorHeroFormation()
end

function UIFightPrepare:SetStaticContent()
    local addLine = -30
    if gLGameLanguage:IsGermanVersion() then
        addLine = -50
    elseif gLGameLanguage:IsFrenchVersion() then
        addLine = -60
    elseif gLGameLanguage:IsVieVersion() then
        addLine = 0
    end

    self:SetWndText(self.mBattleTxt, ccClientText(16601))
    local str = ccClientText(22300)  -- "布阵同步"
    if gLGameLanguage:IsVieVersion() then
        self:SetTextTile(self.mSynBtn, str, 0)
    else
        self:SetTextTile(self.mSynBtn, str, -30)
    end
    str = ccClientText(22308) --"显示名称"
    if self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        str = ccClientText(22319)
    end
    self:SetTextTile(self.mNameToggle, str)

    self:SetTextTile(self.mGoOnBtn, ccClientText(16602), addLine)

    self:SetTextTile(self.mFormationSkillBtn, ccClientText(41066), -30)
    self:SetTextTile(self.mPasvTrea, ccClientText(32600), -30)

    self:SetTextTile(self.mPetTrea, ccClientText(37977))

    self:SetTextTile(self.mPresetFormationBtn, ccClientText(16603), addLine)
    self:SetWndText(self.mShareText, ccClientText(17979))
    str = ccClientText(25262) --"战术"
    self:SetTextTile(self.mBtnStrategy, str)

    self:InitTextLineWithLanguage(self.mSetDesText, -40)
    self:InitTextSizeWithLanguage(self.mSetDesText, -2)

    self:SetWndText(self.mBtnTipsText, ccClientText(20911))
    self:SetWndText(self.mGuildBraveAddText, ccClientText(32747))
    self:InitTextLineWithLanguage(self.mGuildBraveAddText, -30)
    self:SetWndText(self.mCardText, ccClientText(29526))
    self:SetWndText(self.mCardText2, ccClientText(29526))

    if gLGameLanguage:IsJapanVersion() then
        self:InitTextSizeWithLanguage(self.mGuildBraveAddText, -4)
        self:SetAnchorPos(self.mGuildBraveAddText, Vector2.New(-24.1, 5))
    end
end

function UIFightPrepare:GetPlayModuleBelong()
    local wndType = self:GetWndArg("wndType") or UIFightPrepare.NORMAL
    local playModule = LPlayModuleConst.NONE
    if wndType == UIFightPrepare.MULTIPLE_SET then
        local para = self:GetWndArg("para")
        playModule = para.playModule or LPlayModuleConst.NONE
    elseif wndType == UIFightPrepare.NORMAL then
        local combatType = self:GetWndArg("combatType")
        playModule = gLFightManager:GetPlayModuleByCombat(combatType)
    end

    return playModule
end

function UIFightPrepare:InitEndlessHeroList(heroType)
    local specialType = gModelEndles:GetEndlessTypeByCombatType(self._combatType)
    local _heroList = gModelEndles:GetPrepareEndelssHeroList(specialType, self._combatType, heroType)
    return _heroList
end

function UIFightPrepare:RefreshGroupCombatRed()

    self:RefreshGroupRedData()

    local list = self:FindUIScroll("combatGroupList")
    if list then
        list:DrawAllItems(false)
    end
end

-- function UIFightPrepare:ShowEnemyTreasure(herodata)
-- 	local skillList = {}
-- 	for k,v in ipairs(herodata.combatTreasures) do
-- 		local index = v.index
-- 		if v.skillRefId and v.skillRefId > 0 then
-- 			local data =
-- 			{
-- 				skillId = v.skillRefId,
-- 				exhibitionInfo = v.info
-- 			}
-- 			skillList[index] = data
-- 		end

-- 	end
-- 	local dataList = {}
-- 	local show = false
-- 	--local playerLv = herodata.playerInfo._grade
-- 	for k = 1, 4 do
-- 		local data = skillList[k]
-- 		if not data then
-- 			data =
-- 			{
-- 				isEmpty = true,
-- 			}
-- 		else
-- 			show = true
-- 		end

-- 		--local isUnlock = gModelTreasure:IsTreasurePosUnlock(k,playerLv)
-- 		data.state = 1
-- 		table.insert(dataList,data)
-- 	end
-- 	CS.ShowObject(self.mRightSkill,show)
-- 	self:RefreshSkillList(self.mRightSkillList,dataList,"rightSkillList")
-- end

-- function UIFightPrepare:ShowMonsterTreasure(treasureList)
-- 	if not treasureList then
-- 		return
-- 	end
-- 	local skillList = {}
-- 	for k,v in pairs(treasureList) do
-- 		local index = v.index
-- 		if v.skillId> 0 then
-- 			local data =
-- 			{
-- 				skillId = v.skillId
-- 			}
-- 			skillList[index] = data
-- 		end

-- 	end
-- 	local dataList = {}
-- 	local show = false
-- 	for k = 1, 4 do
-- 		local data = skillList[k]
-- 		if not data then
-- 			data =
-- 			{
-- 				isEmpty = true,
-- 			}
-- 		else
-- 			show = true
-- 		end

-- 		data.state = 1
-- 		table.insert(dataList,data)
-- 	end
-- 	CS.ShowObject(self.mRightSkill,show)
-- 	self:RefreshSkillList(self.mRightSkillList,dataList,"rightSkillList")

-- end

function UIFightPrepare:RefreshSkillList(root, dataList, key)

    local list = self:GetUIScroll(key)
    list:Create(root, dataList, function(...)
        self:OnDrawSkill(...)
    end)
end

function UIFightPrepare:OnDrawCombatType(list, item, itemdata, itempos)
    self:SetCombatItemInfo(item, itemdata)
end

-----------------------------------------------------------------
--参数初始化
function UIFightPrepare:InitWndPara()
    local combatExtraData = self._battleData
    if combatExtraData then
        self._serverId = combatExtraData.serverId
        self._playerId = combatExtraData.playerId
        self._rank = combatExtraData.rank
        self._dungeonId = combatExtraData.dungeonId
        self._monsterId = combatExtraData.monsterId
        self._bossList = combatExtraData.bossList
        self._power = combatExtraData.power
        self._otherName = combatExtraData.otherName
        self._rightHead = combatExtraData.otherPlayerHead
        self._rightLevel = combatExtraData.otherLevel
        self._mapName = combatExtraData.mapName --返回的主场景map名
        self._sid = combatExtraData.sid
        self._pageId = combatExtraData.pageId
        self._entryId = combatExtraData.entryId
        self._passId = combatExtraData.passId
        self._battleName = combatExtraData.battleName
        self._battleRefId = combatExtraData.battleRefId
        self._map = combatExtraData.map
        self._guildMeleeState = combatExtraData.guildMeleeState
        self._mapRefId = combatExtraData.mapRefId

        -- 时光之巅使用
        self._mapType = combatExtraData.mapType
        self._eventId = combatExtraData.eventId

        -- 仙境迷宫，boss挑战用
        self._rewardBoxData = combatExtraData.rewardBoxData

        --新伙伴主题，剧情副本用
        self._chapterEntryId = combatExtraData.chapterEntryId

        -- 活动少女试炼
        self._conditionList = combatExtraData.conditionList
    end
end

function UIFightPrepare:ShowBuffStatus(isLeft, refIdList)
    local trans = nil
    local bgTran = nil
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
        self:CreateWndEffect(effRoot, buffEff, buffStatusEffKey, 150, false, false)
    end

end

function UIFightPrepare:ReturnTraining()
    self:WndClose()
    local refId = gModelCareSchool:GetOpentTabIndex()

    GF.OpenWndBottom("UIOutts", { childIndex = 2 })
    GF.OpenWndBottom("UICareColleChapter", { tabRefId = refId })
    GF.ChangeMap("LCityMap")
end

function UIFightPrepare:OnSceneHeroDown(index)
    --self:Examine()

    local selectTable = self._selectHeroTable
    local heroId = selectTable.indexToId[index]

    self:HeroDown(heroId, index)

    self:ShowSelfBuffStatus()
end

function UIFightPrepare:InitHeroFormation(formation, isFake)

    if self._isReliefTroop then
        self:InitReliefTroopBattleUI(formation)
        --if(self._combatType == LCombatTypeConst.COMBAT_TYPE_34)then
        --	FireEvent(EventNames.REFRESH_MY_HERO_SHOW,formation)
        --end
        return
    end

    self:InitTeamAHeroFormation(formation, isFake)

    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        local selectTable = self._selectHeroTable
        self:RefreshHeroCnt(selectTable)
    end

    if gModelBattle:IsTimeCorridorCombat(self._combatType) then
        self:RefreshTimeCorridorFormation()
        -- elseif gModelBossTower:IsBossTowerCombat(self._combatType) then
        -- 	FireEvent(EventNames.REFRESH_LEFT_TEMP_HERO,self._selectHeroTable,self._sid)
    else
        if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING and nil == formation then

        else
            FireEvent(EventNames.REFRESH_MY_HERO_SHOW, formation)
        end
    end

    self:ShowBottomPart()
end

function UIFightPrepare:OnClickBtnTip()
    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        local targetId = self._battleData.targetId
        local ref = gModelCareSchool:GetCollegeLibraryCheckpointRefByRefId(targetId)
        local tips = string.split(ref.Tips, "=")
        local tipslist = {}
        local tipsStrs = string.split(tips[1], ",")
        for i, v in ipairs(tipsStrs) do
            table.insert(tipslist, tonumber(v))
        end
        GF.OpenWnd("UIGuePost", { refId = tonumber(tips[2]), refIdList = tipslist, notTriggerGuide = true })
    elseif self._combatType == LCombatTypeConst.COMBAT_MAIN then
        local heachingId = gModelInstance:GetInstancePara("heachingId")
        local tipsStrs = string.split(heachingId, ",")
        local tipslist = {}
        for i, v in ipairs(tipsStrs) do
            table.insert(tipslist, tonumber(v))
        end
        GF.OpenWnd("UIGuePost", { refId = tonumber(tipsStrs[2]), refIdList = tipslist, notTriggerGuide = true })
    else
        GF.OpenWnd("UIGuePost", { wndType = 2, notTriggerGuide = true })


    end
end

--- state 0 无记录，1 当前阵容上阵，2 其他阵容上阵
function UIFightPrepare:GetMultiHeroSelectState(heroId)
    if not self._multiTeamRecord then
        return 0
    end

    for k, v in pairs(self._multiTeamRecord.heroIdRecord) do
        if v[heroId] then
            if self._teamIndex == k then
                return 1, k
            else
                return 2, k
            end
        end
    end

    return 0

end

function UIFightPrepare:InitCombatList(dataList, pos)
    local uiList = self:FindUIScroll("combatList")
    if not uiList then
        uiList = self:GetUIScroll("combatList")
        uiList:Create(self.mCombatList, dataList, function(...)
            self:OnDrawCombatType(...)
        end, UIItemList.SUPER)
    else
        uiList:RefreshList(dataList)
    end
    if pos then
        uiList:MoveToPos(pos)
    else
        uiList:DrawAllItems(false)
    end

end

function UIFightPrepare:ShowActivityDreamTripBuffStatus()
    local monsterId = self._battleData.bossId
    local refIdList = {}
    if monsterId then
        local tempList = gModelHero:GetMonsterList(monsterId)
        for k, v in pairs(tempList) do
            table.insert(refIdList, { id = v, isMon = true })
        end
    end
    self._enemyList = refIdList
    self._isHeroEnemy = false

    self:ShowBuffStatus(false, refIdList)

end

function UIFightPrepare:GetSpecialCombatFormationData()
    local specialInfo = self:GetSpecialCombatInfo()
    if not specialInfo then
        return
    end
    return specialInfo.formationData
end

function UIFightPrepare:GetMePower()
    local totalPower = 0
    for k, v in pairs(self._selectHeroTable.idToIndex) do
        local power = self:GetPower(k)
        totalPower = totalPower + power
    end

    -- 【C宠物系统】删掉宠物系统相关
    -- totalPower = totalPower + self:GetPetsPower()

    return totalPower
end

function UIFightPrepare:OnClickStrategy()
    local refIdList = gModelSimuFight:GetTacticalList()
    local refIdRecord = self:GetMultiTacticsRecord(self._teamIndex)
    local para = {
        refIdList = refIdList,
        refIdRecord = refIdRecord,
        curStrategy = self._strategyId,
        saveFunc = function(refId)
            if self:IsWndClosed() then
                return
            end
            self._strategyId = refId
            self:RefreshStrategyBtn()
        end
    }
    GF.OpenWnd("UIhjics", para)
end

function UIFightPrepare:GetHeroStatus(id)
    local showRedPoint = false
    showRedPoint = gModelHero:GetHeroUpStatus(id)
    return showRedPoint
end

function UIFightPrepare:OnClickOpenTreasureSet()
    -- if gModelFormation:CheckTreasureNotUse(self._combatType,true) then
    -- 	return
    -- end

    local idRecord = {}
    if self:IsMultiTeam() then
        for k, v in pairs(self._multiTeamRecord.treasureIdRecord) do
            if k ~= self._teamIndex then
                for k1, v1 in pairs(v) do
                    idRecord[v1] = k + 1
                end
            end
        end
    end

    local para = {
        treasureSkilIds = table.clone(self._treasureSkilIds),
        combatType = self._combatType,
        targetId = self._battleData.targetId,
        idRecord = idRecord,
        func = function(list)
            if self:IsWndClosed() then
                return
            end
            self._treasureSkilIds = list
            self:RefreshFormationSkillShow()
        end
    }

    GF.OpenWnd("UISelFightTsure", para)
end

function UIFightPrepare:CheckDragItemSwap(curData, curPos)
    local curIndexPos = self._dragOriginPos[curData.index]
    local curOriginPosY = curIndexPos.y + curData.centerY
    local centerY = curData.centerY + curPos.y
    local swapIndex = nil
    local bMoveUp = true
    for k, v in pairs(self._dragIndexList) do
        if k ~= curData.index then
            local originPos = self._dragOriginPos[k]
            local dragKey = "_dragItem_" .. v
            local dragItemData = self._dragItemDataList[dragKey]
            local itemcenterY = dragItemData.centerY + originPos.y
            local itemmidH = dragItemData.midH
            local odis = centerY - itemcenterY
            local dis = odis
            if dis < 0 then
                dis = -dis
            end
            if dis < itemmidH then
                bMoveUp = curOriginPosY >= itemcenterY
                swapIndex = k
                break
            end
        end
    end
    if not swapIndex then
        return
    end

    local min = bMoveUp and (curData.index + 1) or (curData.index - 1)
    local max = bMoveUp and swapIndex or swapIndex

    local delta = bMoveUp and -1 or 1

    for k = min, max, -delta do
        local keyIndex = self._dragIndexList[k]
        local dragKey = "_dragItem_" .. keyIndex
        local dragItemData = self._dragItemDataList[dragKey]
        local newIndex = k + delta
        local oldIndex = dragItemData.index
        dragItemData.index = newIndex
        local item = dragItemData.item
        local tween = dragItemData.tween
        if tween then
            tween:Kill(false)
        end
        local originPos = self._dragOriginPos[newIndex]
        tween = item:DOLocalMoveY(originPos.y, 0.2)
        tween:OnComplete(function()
            local _dragItemData = self._dragItemDataList[dragKey]
            if _dragItemData then
                _dragItemData.tween = nil
            end
        end)
        dragItemData.tween = tween
        tween:PlayForward()
        self:OnSwap(oldIndex, newIndex)
    end
    table.remove(self._dragIndexList, curData.index)
    curData.index = swapIndex
    table.insert(self._dragIndexList, swapIndex, curData.keyIndex)
end

function UIFightPrepare:OnDreamTripMonsterInfoResp(pb)
    if pb.activityId ~= self._sid then
        return
    end
    if pb.eventId ~= self._battleData.targetId then
        return
    end
    local monster = pb.monster
    local power = 0
    for i, v in ipairs(monster) do
        power = power + v.power
    end
    self:SetEnemyPower(power)
end

function UIFightPrepare:ReturnDesireTrail()
    gModelGeneral:DesireTrailEntrance()
end

function UIFightPrepare:Return23()
    self:WndClose()
    -- GF.OpenWnd("UIBackin", { page = 5 })
    GF.OpenWnd("UIRegressionMinWin", { funcType = 4 })
    GF.ChangeMap("LCityMap")
end

function UIFightPrepare:SetCombatItemInfo(item, itemdata)
    local BtnTab3 = self:FindWndTrans(item, "BtnTab10")
    local tag = self:FindWndTrans(item, "tag")

    local refId = itemdata.refId

    local isSelect = refId == self._curSelectType
    local bgState = isSelect and LWnd.StateOn or LWnd.StateOff

    self:SetWndTabStatus(BtnTab3, bgState)

    local nameCfg = ""
    if itemdata.nameStr then
        nameCfg = itemdata.nameStr
    else
        nameCfg = ccLngText(itemdata.name)
    end

    local addSize = 0
    local addLine = 0
    if gLGameLanguage:IsGermanVersion() then
        addSize = -7
        addLine = -10
    elseif gLGameLanguage:IsJapanRegion() then
        addSize = -4
        addLine = -20
    end

    self:SetWndTabText(BtnTab3, nameCfg, addSize, addLine)

    local showTag = self._typeRecord[refId] or false
    CS.ShowObject(tag, showTag)
    self._fightTypeItems[refId] = item
    self:SetWndClick(item, function()
        self:OnClickCombatType(refId)
    end, LSoundConst.CLICK_PAGE_COMMON)
end

function UIFightPrepare:ShowMultiTeamSet()

    self:SetWndText(self.mSetDesText, ccClientText(21847))
    self:SetWndText(self.mNameText, gModelPlayer:GetPlayerName())
    local fightText = self:FindWndTrans(self.mFightBtn, "FightTxt")
    local str = ccClientText(10353)
    self:SetWndText(fightText, str)

    local dataList = {}
    local teamCount = self._teamCount
    for i = 1, teamCount do
        local data = {
            teamIndex = i - 1,
            name = string.replace(ccClientText(21817), i)
        }
        table.insert(dataList, data)
    end

    self:ShowCombatGroupList()

    local combatTypeNum = #dataList
    if combatTypeNum <= 0 then
        self:ShowBottomPart()
        return
    end

    self._needClose = combatTypeNum <= 1

    if self._selTeamIndex then
        self._teamIndex = self._selTeamIndex
    else
        self._teamIndex = dataList[1].teamIndex
    end

    self:InitSwapList(dataList)

    self:OnSelectTeamIndex(self._teamIndex)

    CS.ShowObject(self.mCombatList, false)
    CS.ShowObject(self.mSwapCombatList, true)
    CS.ShowObject(self.mTypePart, true)
end

function UIFightPrepare:RefreshFormationTag()
    if self._wndType ~= UIFightPrepare.MULTIPLE_SET then
        return
    end
    if not self._removeTarget then
        return
    end
    if not self._fightTypeItems then
        return
    end
    local item = nil
    for k, v in pairs(self._fightTypeItems) do
        if self._curSelectType == k then
            item = v
            break
        end
    end
    if not item then
        return
    end

    local isOn = self._selectHeroTable.idToIndex[self._removeTarget] ~= nil
    local tag = self:FindWndTrans(item, "tag")
    CS.ShowObject(tag, isOn)
end

function UIFightPrepare:OnSelectFormationType(refId)
    if self._formationType == refId then
        return
    end
    self:FormationSelEvent(refId)
end

function UIFightPrepare:InitUIShow(bShow, aniTime)
    local offsetY = -500
    local bottomTrans = self.mMainBattleBot

    aniTime = aniTime or 0
    local bottomPos = self._bottomUIOrgPos:Clone()
    if not bShow then
        bottomPos.y = bottomPos.y + offsetY
    end

    if aniTime > 0 then
        local seq = self:GetSeqCom():CreateSeq("moveTween")

        local tween = bottomTrans:DOAnchorPos(bottomPos, aniTime)
        seq:Append(tween)

        local outPos = Vector3.New(-656, self.mMe.localPosition.y, 0)
        self.mMe.localPosition = outPos
        tween = self.mMe:DOLocalMoveX(-156, aniTime)
        seq:Join(tween)

        outPos = Vector3.New(656, self.mOther.localPosition.y, 0)
        self.mOther.localPosition = outPos
        tween = self.mOther:DOLocalMoveX(156, aniTime)
        seq:Join(tween)

        seq:OnComplete(function()
            self:GetSeqCom():DeleteSeq("moveTween")
            local wndName = self:GetWndName()
            self:SendGuideReadyEvent(wndName)
            --self:CheckShowFormationGuide()
        end)
        --seq:SetLoops(-1)
        seq:PlayForward()

    else
        bottomTrans.anchoredPosition = bottomPos
        self.mMe.localPosition = Vector3.New(-156, self.mMe.localPosition.y, 0)
        self.mOther.localPosition = Vector3.New(156, self.mOther.localPosition.y, 0)
    end

    if self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        local size = Vector2.New(26, 26)
        for i = 1, 3 do
            local trans = self["mImgStar" .. i .. "_0"]
            self:SetWndEasyImage(trans, "public_false_01")
            trans.sizeDelta = size
            trans = self["mImgStar" .. i]
            trans.sizeDelta = size
            self:SetWndEasyImage(trans, "public_icon_right_2")
        end
    end
end

----------------------------------------------
---奇境探险
function UIFightPrepare:FilterHeroList(heroList)
    if self._heroType == 0 then
        return heroList
    end

    local heroType = self._heroType
    local list = {}
    for k, v in ipairs(heroList) do
        local race = nil
        local refId = v.refId
        local cfg = gModelHero:GetHeroRef(refId)
        if cfg then
            race = cfg.raceType
        end
        if race and race == heroType then
            if self._isShowTryHero or not (v.isTry or v._isTry) then
                table.insert(list, v)
            end
        end
    end
    return list
end

function UIFightPrepare:GetMultiHeroIdRecord(exceptTeam)
    local record = {}

    for k, v in pairs(self._multiTeamRecord.heroIdRecord) do
        for k1, v1 in pairs(v) do
            if not exceptTeam or exceptTeam ~= k then
                record[k1] = true
            end
        end
    end

    return record
end

function UIFightPrepare:SaveTestBattleTeamFormation(bSaveLocal)
    local matrix = gModelFormation:GetFormationPosByRefId(self._formationType)
    local grids = {}
    for k, v in pairs(self._selectHeroTable.idToIndex) do

        local herodata = gModelHero:GetHeroById(k)
        if herodata then
            local grid = matrix[v]
            local data = {}
            data.id = k
            data.grid = grid
            table.insert(grids, data)
        end
    end
    -- local artifactId = self._artifact【G公共支持】删除神器功能相关数据
    local treasureSkilIds = self._treasureSkilIds

    local data = {
        formationRefId = self._formationType,
        -- artifactId = artifactId,【G公共支持】删除神器功能相关数据
        treasureSkilIds = treasureSkilIds,
        divineWeaponStarRefIds = self._divineWeaponStarRefIds, -----------------未改-------
        -- treasurePassiveSkill = self._pasvSkillList,
        grids = grids,
        petFights = self:GetCurPetFights(),
        petHelps = self:GetCurPetHelps(),
    }

    LFightTest.SetFormationData(data, self._teamSide)
    if bSaveLocal then
        LFightTest.SaveFormations()
    end
end

function UIFightPrepare:OnHeroSwap(index1, index2)
    --self:Examine()
    local selectTable = self._selectHeroTable
    local heroId1 = selectTable.indexToId[index1]
    local heroId2 = selectTable.indexToId[index2]
    self:HeroDown(heroId1, index1)
    self:HeroDown(heroId2, index1)
    self:HeroUp(heroId1, index2)
    self:HeroUp(heroId2, index1)
end

function UIFightPrepare:FindAnotherEmptyTeam()
    if not self:IsMultiTeam() then
        return 0
    end

    local teamCnt = self._teamCount
    for k = 0, teamCnt - 1 do
        local idRecord = self._multiTeamRecord.heroIdRecord[k]
        if table.isempty(idRecord) and k ~= self._teamIndex then
            return k
        end
    end

    return self._teamIndex
end

function UIFightPrepare:OnChangeGroup(itemdata)
    local hasUnSave = self:CheckHasUnSaved()
    local changeFunc = function()
        if self:IsWndClosed() then
            return
        end

        self._combatType = itemdata.combatType
        self._teamIndex = 0
        self._isDataReceived = false
        FireEvent(EventNames.ON_CHANGE_BATTLE_TYPE, itemdata.combatType)
        FireEvent(EventNames.ON_CHANGE_BATTLE_TEAM, 0)
        self:RefreshTeamItemShow()
        self:RefreshHeroFormation()

    end
    if hasUnSave then
        local confirmFun = function()
            self:GotoChallenge(changeFunc)
        end

        local para = {
            refId = 10007,
            func = confirmFun,
            leftFunc = changeFunc,
        }
        gModelGeneral:OpenUIOrdinTips(para)
        return
    end

    changeFunc()
end
function UIFightPrepare:OnBadgeGameStar()
    local conditionList = {}
    if self._combatType == LCombatTypeConst.COMBAT_BADGE_GAME then
        local ref = GameTable.BadgeGameBarrierRef[self._battleData.refId]
        conditionList[1] = ref.starCond1
        conditionList[2] = ref.starCond2

        local starInfo = ModelBadgeGame.StarImgMap[ref.type]
        if starInfo then
            local actStar,noActStar = starInfo.Act,starInfo.NoAct
            self:SetWndEasyImage(self.mImgStar1,actStar)
            self:SetWndEasyImage(self.mImgStar2,actStar)
            self:SetWndEasyImage(self.mImgStar3,actStar)

            self:SetWndEasyImage(self.mImgStar1_0,noActStar)
            self:SetWndEasyImage(self.mImgStar2_0,noActStar)
            self:SetWndEasyImage(self.mImgStar3_0,noActStar)
        end
    elseif self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        conditionList = self._conditionList
    end

    CS.ShowObject(self.mObjStar, #conditionList > 0)
    if #conditionList > 0 then

        local isOk = false
        local color = isOk and "139057ff" or "C81212ff"
        CS.ShowObject(self.mImgStar1, isOk)
        CS.ShowObject(self.mImgStar1_0, not isOk)
        self:SetWndText(self.mTxtStar1, ccClientText(40226))
        self:SetXUITextTransColor(self.mTxtStar1, color)

        local condRefId = conditionList[1]
        local condRef = GameTable.BadgeGameCondRef[condRefId]
        isOk = false
        color = isOk and "139057ff" or "C81212ff"
        CS.ShowObject(self.mImgStar2, isOk)
        CS.ShowObject(self.mImgStar2_0, not isOk)
        self:SetWndText(self.mTxtStar2, ccLngText(condRef.text))
        self:SetXUITextTransColor(self.mTxtStar2, color)

        local condRefId2 = conditionList[2]
        if condRefId2 then
            condRef = GameTable.BadgeGameCondRef[condRefId2]
            self:SetWndText(self.mTxtStar3, ccLngText(condRef.text))
            if condRef.type ~= 4 then
                isOk = false
                color = isOk and "139057ff" or "C81212ff"
                CS.ShowObject(self.mImgStar3, isOk)
                CS.ShowObject(self.mImgStar3_0, not isOk)
                self:SetXUITextTransColor(self.mTxtStar3, color)
            end
        end
        CS.ShowObject(self.mTxtStar3, condRefId2 ~= nil)
    end
end

function UIFightPrepare:GetSpecialMonsterPower()
    local specialInfo = self:GetSpecialCombatInfo()
    if not specialInfo then
        return
    end
    local getMonsterReq = specialInfo.getMonsterReq
    if getMonsterReq then
        getMonsterReq(self._battleData.targetId)
    end
end

function UIFightPrepare:GetFilterHeroList()
    local heroList = gModelHero:GetHeroSortList()
    local dataList = {}
    if heroList then
        for k, v in pairs(heroList) do
            local refId = v:GetRefId()
            local race = gModelHero:GetHeroRace(refId)
            if self._heroType == 0 or self._heroType == race then
                if not self._raceKeyList or self._raceKeyList[race] then
                    if self._isShowTryHero or not v:IsTryHero() then
                        local heroData = v:GetServerData()
                        table.insert(dataList, heroData)
                    end
                end
            end
        end
    end
    return dataList
end

function UIFightPrepare:RefreshMultiTeamHeroList()
    --local dataList = self:GetFilterHeroList()
    local dataList = self:GetHeroList()
    local uiList = self._uiHeroScrollList
    if not uiList then
        uiList = self:GenerateUIHeroScrollList(function(...)
            self:OnDrawMultiTeamHero(...)
        end)
    end
    uiList:RemoveAll()
    local cnt = #dataList
    local isEmpty = cnt <= 0
    CS.ShowObject(self.mNoRecord, isEmpty)
    if isEmpty then
        self:CreateEmptyShow(17001)
    end
    for i = 1, cnt do
        local data = dataList[i]
        uiList:AddData(i, data)
    end
    uiList:RefreshList()

end

function UIFightPrepare:SetWndPara()
    self._wndType = self:GetWndArg("wndType") or UIFightPrepare.NORMAL

    local para = self:GetWndArg("para")
    if para then
        self._returnFunc = para.returnFunc
        self._typeRecord = para.typeRecord or {} --阵型最后一个英雄下阵
        self._removeTarget = para.removeTarget

        self._setTargetType = para.setTargetType

        self._retAfterSet = para.retAfterSet
        self._teamCount = para.teamCount

        self._selTeamIndex = para.teamIndex

        self._combatDataList = para.combatDataList
    else
        self._returnFunc = nil
        self._typeRecord = {} --阵型最后一个英雄下阵
    end

    local extraData = self:GetWndArg("extraData") or {}
    if extraData.returnFunc then
        self._returnFunc = extraData.returnFunc
    end
    self._combatType = self:GetWndArg("combatType")
    self:ResetIsShowTryHero()
    self._battleData = extraData
    self._isSetFormation = extraData.isSetFormation or false

    if self._wndType == UIFightPrepare.NORMAL then
        self:InitWndPara()
    end
    self._race = extraData.race
    ---  种族按钮屏蔽操作移动到这个函数 GetNoShowRaceList

    self._showCombatSpiritHeroStatus = false
end

------------------------------------------------------------------
-- function UIFightPrepare:CheckTreaPosOpen(type,index)
-- 	local design = nil
-- 	if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
-- 		design = self._skillPosList
-- 	end

-- 	return gModelTreasure:CheckTreaPosOpen(type,index,design)
-- end


------------------------------------------------------------------
return UIFightPrepare