---
--- Created by Ease.
--- DateTime: 2023/10/3 14:30:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMultiTeamFightPop:LWnd
local UIMultiTeamFightPop = LxWndClass("UIMultiTeamFightPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMultiTeamFightPop:UIMultiTeamFightPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMultiTeamFightPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMultiTeamFightPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMultiTeamFightPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
end

function UIMultiTeamFightPop:SetBotTeamBtnList()
	self.botBtnTeamList = {}
	local selectTeamBtnList = self.mSelectTeamBtnList
	local battleNode = gModelInstance:GetBattleNode()
	local missRef = gModelInstance:GetMissionCfg(battleNode)
	if(string.isempty(missRef.monsterMore))then
		self:WndClose()
		return
	end
	self.monsterFormationIdArr = string.split(missRef.monsterMore,",")
	local botTeamList = self:GetUIScroll("botTeamList")
	botTeamList:Create(selectTeamBtnList,self.monsterFormationIdArr,function (...)
		self:OnDrawBotTeamBtn(...)
	end)
	self:SetEnemyTeamBtn(self._curSeleEnemyBtnIndex)
end
function UIMultiTeamFightPop:SetEnemyList()
	local monsterFormationIdArr = self.monsterFormationIdArr
	local monsterFormationIdStr = monsterFormationIdArr[self._curSeleEnemyBtnIndex]
	local monsterDataList = {}
	if(monsterFormationIdStr)then
		local monsterFormationId = tonumber(monsterFormationIdStr)
		--local formationRef = gModelHero:GetMonsterFormationRefByRefId(monsterFormationId)
		monsterDataList = gModelHero:GetMonsterList(monsterFormationId)

		gModelFormation:OnMonsterPowerReq({monsterFormationId})
		--self:ShowMonsterPower(formationRef.monsterPower)--monsterPower
	end
	local monsterList = self:GetUIScroll("uiList")
	monsterList:Create(self.mHeroList,monsterDataList,function (...)
		self:OnDrawMonster(...)
	end)
end

function UIMultiTeamFightPop:SetSkipBtn(btnType)
	local diffLvl = gModelInstance:GetMainFightLevelOfDifficulty()
	local isSkip = gModelInstance:GetMainFightDiffLvlSkip(diffLvl,btnType)
	local btnTrans = btnType == 1 and self.mSkipEmbattle or self.mSkipBattle
	local isSkipBool = gModelInstance:SetMainFightDiffLvlSkip(diffLvl,isSkip,btnType)
	if(isSkipBool)then
		self:SetWndToggleValue(btnTrans,isSkip)
	end
	self.showSkipTips = true
	self:SetWndToggleDelegate(btnTrans,function (value)
		local isSkipBool = gModelInstance:SetMainFightDiffLvlSkip(diffLvl,value,btnType,self.showSkipTips)
		if(btnType == 2 and value == true and isSkipBool)then
			self.showSkipTips = nil
			self:SetWndToggleValue(self.mSkipEmbattle,true)
			self.showSkipTips = true
		end
		if(not isSkipBool)then
			self:SetWndToggleValue(btnTrans,not value)
		end
	end)
end

function UIMultiTeamFightPop:OnClickBattleBtn()
	local diffLvl = gModelInstance:GetMainFightLevelOfDifficulty()
	local comBatTypeIndex = diffLvl == 2 and LCombatTypeConst.COMBAT_TYPE_30 or LCombatTypeConst.COMBAT_TYPE_31
	local skipEmbattle = gModelInstance:GetMainFightDiffLvlSkip(diffLvl,1)
	local skipBattle = gModelInstance:GetMainFightDiffLvlSkip(diffLvl,2)
	if(skipEmbattle)then
		local formationList = gModelFormation:GetFormationList(comBatTypeIndex)
		if(not formationList)then
			if(not self.formationReqFlag)then
				gModelFormation:OnGetFormationListReq({comBatTypeIndex})
				self.formationReqFlag = true
			else
				local emptyList = {}
				for i, v in pairs(self.monsterFormationIdArr) do
					table.insert(emptyList,i)
				end
				self:ShowEmBattleWndTips(1,emptyList,skipBattle,comBatTypeIndex)
			end
			return
		else
			self.formationReqFlag = nil
		end
		local formationDataList = self:GetFormationDataList(formationList)
		local hasEmptyTeamData,loseHeroTeamData = self:CheckEmptyFormationList(formationDataList,#self.monsterFormationIdArr)
		if(hasEmptyTeamData and #hasEmptyTeamData>0)then
			self:ShowEmBattleWndTips(1,hasEmptyTeamData,skipBattle,comBatTypeIndex)
		elseif(loseHeroTeamData and #loseHeroTeamData>0)then
			self:ShowEmBattleWndTips(2,loseHeroTeamData,skipBattle,comBatTypeIndex)
		else
			self:DOBattleBySkipValue(skipBattle,skipEmbattle,comBatTypeIndex)
		end
	else
		self:DOBattleBySkipValue(skipBattle,skipEmbattle,comBatTypeIndex)
	end
end
function UIMultiTeamFightPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.CombatResultSureResp,function (pb)
		if(	gModelInstance:CheckCombatTypeIsDiffMainFight(pb.combatType))then
			self:InitData()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.MonsterPowerResp,function (pb)
		local powerData = pb.powerData
		local data = powerData[1]
		local power =LUtil.ToInteger(tonumber(data.power))
		self:ShowMonsterPower(power)
	end)
	self:WndNetMsgRecv(LProtoIds.GetFormationListResp,function (pb)
		if(self.formationReqFlag)then
			self:OnClickBattleBtn()
		end
	end)
	--local pbId = LProtoHelper.GetProtoId("GetFormationListResp")
	--self:WndEventRecv(EventNames.NET_ERROR_CODE,function(msgId, error, args ,errorStr)
	--	if pbId == msgId then
	--		self:OnClickBattleBtn()
	--	end
	--end)
end
function UIMultiTeamFightPop:InitBtnEvent()
	self:SetWndClick(self.mHelpBtn, function()
		self:OnClickHelpBtn()
	end) --帮助按钮
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBg, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBattleBtn, function()
		local callFunc = function()
			self:OnClickBattleBtn()
		end
		gModelInstance:CheckShowExploreTip(30008,callFunc)
	end)
	self:SetWndClick(self.mVideoBtn, function()
		local diffLvl = gModelInstance:GetMainFightLevelOfDifficulty()
		local comBatTypeIndex = diffLvl == 2 and LCombatTypeConst.COMBAT_TYPE_30 or LCombatTypeConst.COMBAT_TYPE_31
		local data = {
			combatType = comBatTypeIndex
		}
		GF.OpenWnd("UIDiffLvlFightRecordPop",data)
	end)
end
function UIMultiTeamFightPop:OnDrawBotTeamBtn(list, item,itemdata,itempos)
	local showBtnIndex = itempos == 1 and 1 or itempos == #self.monsterFormationIdArr and 3 or 2
	local btnTrans = self:FindWndTrans(item,"Btn"..showBtnIndex)
	CS.ShowObject(btnTrans,true)
	table.insert(self.botBtnTeamList,{btnTrans=btnTrans,itempos = itempos})
	self:SetWndClick(btnTrans, function()
		self:SetEnemyTeamBtn(itempos)
	end)
end
function UIMultiTeamFightPop:CheckEmptyFormationList(formationDataList,targetCnt)
	local emptyList = {}
	local notFullList = {}
	for i = 0, targetCnt - 1 do
		if(not formationDataList[i] or #formationDataList[i]==0)then
			table.insert(emptyList,i+1)
		else
			local grids = #formationDataList[i]
			if(not grids or grids < 5)then
				table.insert(notFullList,i+1)
			end
		end
	end
	return  emptyList,notFullList
end
function UIMultiTeamFightPop:DOBattleBySkipValue(skipBattle,skipEmbattle,comBatTypeIndex)
	if(skipBattle and skipEmbattle)then
		self:DOSkipBattleAndEmBattle(comBatTypeIndex)
	elseif(skipEmbattle)then
		self:DOSkipEmBattle(comBatTypeIndex,skipBattle)
	else
		gLFightManager:PrepareGoToBattle(comBatTypeIndex, {curTeam = 0,skipBattle = skipBattle})
	end
end
function UIMultiTeamFightPop:DOSkipEmBattle(comBatTypeIndex,skipBattle)
	local combatData = { combatType = comBatTypeIndex, skipBattle = skipBattle}
	gModelBattle:StartAfterSetFormation(combatData)
end
function UIMultiTeamFightPop:SetEnemyTeamBtn(clickIndex)
	for i = 1, #self.botBtnTeamList do
		local btnTrans = self.botBtnTeamList[i].btnTrans
		local isClickBtn = i == clickIndex
		local iconBgPath = isClickBtn and "warorder_bg_di_2" or "warorder_bg_di_1"
		local iconTrans = self:FindWndTrans(btnTrans,"Icon")
		self:SetWndEasyImage(iconTrans,iconBgPath)
		local txtTrans = self:FindWndTrans(btnTrans,"Txt")
		local txtStr = ccClientText(16332 + i)
		local txtColor = isClickBtn and "#734f22" or "#e5e5e5"
		self:SetWndText(txtTrans,string.format("<color=%s>%s</color>",txtColor,txtStr))
	end
	self._curSeleEnemyBtnIndex = clickIndex
	self:SetEnemyList()
end
function UIMultiTeamFightPop:SetLittleItem(list,item,itemdata,itempos)
	local iconRoot = self:FindWndTrans(item, "IconRoot")
	local icon = self:FindWndTrans(iconRoot, "Icon")
	local rewardData = itemdata
	local InstanceID = icon:GetInstanceID()
	local baseClass = self._uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[InstanceID] = baseClass
		baseClass:Create(icon)
		self:SetIconClickScale(icon, true)
	end
	baseClass:SetCommonReward(rewardData.itemType, rewardData.itemId, rewardData.itemNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetWndClick(icon, function()
		gModelGeneral:OpenItemInfoTip(rewardData.itemId, rewardData.itemNum, nil, nil, nil, nil, nil, nil, nil, nil, function()
		end, nil, 1)
	end, LSoundConst.CLICK_CLOSE_COMMON)
end
function UIMultiTeamFightPop:OnDrawMonster(list, item,itemdata,itempos)
	local blood = self:FindWndTrans(item,"blood")
	local deadTag = self:FindWndTrans(item,"deadTag")
	local deadTagDeadText = self:FindWndTrans(deadTag,"deadText")
	local hireTag = self:FindWndTrans(item,"hireTag")

	local monsterAttrRef = gModelHero:GetMonsterAttrByRefId(itemdata)
	local herodata = {}
	herodata.id = monsterAttrRef.heroId
	herodata.refId = monsterAttrRef.refId
	herodata.star = monsterAttrRef.starLv
	herodata.level = monsterAttrRef.lv
	herodata.isMon = true
	--herodata.monsterAddCost = monsterAttrRef.monsterAddCost
	local value =1
	LxUiHelper.SetProgress(blood,value)

	local heroTrans = self:FindWndTrans(item,"HeroIcon")

	local instanceId = item:GetInstanceID()
	local heroIconCls = self._commonIconTbl[instanceId]
	if not heroIconCls then
		heroIconCls = CommonIcon:New()
		self._commonIconTbl[instanceId] = heroIconCls
		heroIconCls:Create(heroTrans)
	end
	heroIconCls:SetHeroDataSet(herodata)
	heroIconCls:DoApply()

	self:SetWndClick(item,function ()
		local str = ccClientText(16905)
		GF.ShowMessage(str)
	end)
	local isDead = false
	CS.ShowObject(deadTag,isDead)
	--local isHire = itemdata.heroType ==ModelWonderland.HIRE_HERO
	CS.ShowObject(hireTag,false)

	self:SetWndText(deadTagDeadText,ccClientText(19133))
end
function UIMultiTeamFightPop:ShowEmBattleWndTips(tipsType,dataList,skipBattle,comBatTypeIndex)
	local tipsIndex= tipsType == 1 and 80015 or 80016
	local strList = {}
	for i, v in pairs(dataList) do
		local str = string.replace(ccClientText(21817),v)
		table.insert(strList,str)
	end
	local paraStr = table.concat(strList,",")
	local para = {
		refId = tipsIndex, para = { paraStr } ,
		func = function()
			self:DOBattleBySkipValue(skipBattle,false,comBatTypeIndex)
		end,
		leftFunc = function()
			if(tipsType == 2)then
				self:DOBattleBySkipValue(skipBattle,true,comBatTypeIndex)
			end
		end
	}
	gModelGeneral:OpenUIOrdinTips(para)
end
function UIMultiTeamFightPop:DOSkipBattleAndEmBattle(comBatTypeIndex)
	local combatData = { combatType = comBatTypeIndex, skipBattle = true}
	gModelBattle:OnCombatReq(combatData)
end

function UIMultiTeamFightPop:ShowMonsterPower(power)
	local num = gModelPower:GetMainCityPower()
	local playerPower = tonumber(num)
	local targetPower = tonumber(power)
	local color = playerPower>=targetPower and "#30e055" or "#c81212"
	local str = LUtil.FormatColorStr(LUtil.PowerNumberCoversion(power),color)
	self:SetWndText(self.mPowerText,str)
end

function UIMultiTeamFightPop:DefultUI()
	local curDiffLvl = gModelInstance:GetMainFightLevelOfDifficulty()
	--local patternCfg = gModelInstance:GetInstancePattern(curDiffLvl)
	--local chapterData = gModelInstance:GetInstanceChapterRefByRefId(self._curChatper)
	local curMissionCfg= gModelInstance:GetCurMissionCfg(curDiffLvl)
	local chatperName = curMissionCfg.nameWorld
	--local titleStr = string.replace(ccClientText(16327),ccLngText(patternCfg.name),ccLngText(chatperName))
	local titleStr = ccLngText(chatperName)
	self:SetWndText(self.mTitleTxt,titleStr)
	self:SetWndText(self.mRewardDescTxt,ccClientText(16328))
	local battleFormationGroupTxt = self:FindWndTrans(self.mBattleFormationGroup,"TitleTxt")
	self:SetWndText(battleFormationGroupTxt,ccClientText(16329))
	local skipEmbattleTxt = self:FindWndTrans(self.mSkipEmbattle,"Label")
	self:SetWndText(skipEmbattleTxt,ccClientText(16330))
	local skipBattleTxt = self:FindWndTrans(self.mSkipBattle,"Label")
	self:SetWndText(skipBattleTxt,ccClientText(16331))
	local battleBtnTxt = self:FindWndTrans(self.mBattleBtn,"Text")
	self:SetWndText(battleBtnTxt,ccClientText(16332))
	local videoBtnTxt = self:FindWndTrans(self.mVideoBtn,"Txt")
	self:SetWndText(videoBtnTxt,ccClientText(16339))
end
function UIMultiTeamFightPop:InitEvent()

end
function UIMultiTeamFightPop:SetRewardList()
	local battleNode = gModelInstance:GetBattleNode()
	--local missionData = gModelInstance:GetMissionCfg(battleNode)
	--local rewardStr = missionData.winReward
	--local rewardList = LxDataHelper.ParseItem(rewardStr)
	local showRewards = gModelInstance:GetShowReward(battleNode)
	if not showRewards then
		showRewards ={}
	end
	local uiRewardList = self:GetUIScroll("RewardList")
	uiRewardList:Create(self.mRewardScroll,showRewards,function (...)
		self:SetLittleItem(...)
	end)
	uiRewardList:EnableScroll(true,true)
end
function UIMultiTeamFightPop:GetFormationDataList(formationList)
	local formationGridList = {}
	if(not formationList)then
		return
	end
	for i, v in pairs(formationList) do
		local grids = v.grids
		if(grids)then
			local arrayId = v.formationRefId
			for j,k in ipairs(v.grids) do
				local pos = gModelFormation:GetIndexByPos(arrayId,k.grid)
				formationGridList[i] = formationGridList[i] or {}
				table.insert(formationGridList[i] , pos)
			end
		end
	end
	return formationGridList
end

function UIMultiTeamFightPop:InitData()
	self._curChatper = gModelInstance:GetChapterId()
	self._uiCommonList = {}
	self._curSeleEnemyBtnIndex = 1
	self._commonIconTbl = {}
	self.botBtnTeamList = {}
	self:DefultUI()
	for i = 1, 2 do
		self:SetSkipBtn(i)
	end
	self:SetRewardList()
	self:SetBotTeamBtnList()
end
------------------------------------------------------------------
return UIMultiTeamFightPop


