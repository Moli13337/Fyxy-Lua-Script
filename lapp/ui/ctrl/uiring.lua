---
--- Created by luofuwen.
--- DateTime: 2023/10/26 16:01:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIring:LWnd
local UIring = LxWndClass("UIring", LWnd)
------------------------------------------------------------------

UIring.CROSS_LADDER = 201
UIring.CROSS_CHAMPION = 202
UIring.ARENA_RANK = 203
UIring.ARENA_PEAK = 204
UIring.CROSS_GRADING = 205
UIring.SIMULATE = 206
-- UIring.HIGH_STAGE_RACE = 207


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIring:UIring()
	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIring:OnWndClose()
	LUtil.ClearHashTable(self._uiItemList)
	self._uiItemList = nil

	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIring:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

	self._seqCom = SequenceCom:New()
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIring:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	CS.ShowObject(self.mWorldBtn,false)
	self:InitData()
	self:InitView()
	self:InitBtnEvent()
	self:InitMsgEvent()

end
function UIring:OnDrawModuleCell(list, item, itemdata, itempos)
	local refId = itemdata.refId

	self._moduleList[refId] = {item = item,itemdata = itemdata}

	local redTran = self:FindWndTrans(item,"AniRoot/redPoint")

	self:RegisterFuncItemRed(itemdata.functionId,redTran)

	if refId == UIring.CROSS_LADDER then
		-- self:SetLadderItem(item, itemdata)
	elseif refId == UIring.CROSS_CHAMPION then
		-- self:SetChampionItem(item, itemdata)
	elseif refId == UIring.ARENA_RANK then
		self:SetRankItem(item, itemdata)
	elseif refId == UIring.ARENA_PEAK then
		self:SetPeakItem(item, itemdata)
	elseif refId == UIring.CROSS_GRADING then
		self:SetCrossGradingItem(item,itemdata)
	elseif refId == UIring.SIMULATE then
		self:SetSimulateItem(item,itemdata)
	-- elseif refId == UIring.HIGH_STAGE_RACE then
	-- 	self:SetHighStageRaceItem(item,itemdata)
	else
		self:SetCommonItem(item, itemdata, true)
	end
end

function UIring:OnTimer(key)
	local timerItem = self._timerTransMap[key]
	if timerItem then
		local seasonEndTime = timerItem.time
		local nowTime = GetTimestamp()
		local timespan= seasonEndTime-nowTime

		local timeStr = nil
		if timerItem.formatFun then
			timeStr = timerItem.formatFun(timespan)
		else
			timeStr = LUtil.FormatTimespanCn(timespan)
		end
		timeStr = LUtil.FormatColorStr(timeStr,"lightGreen")
		timeStr = timerItem.title..timeStr
		local trans = timerItem.trans
		self:SetWndText(trans,timeStr)
		if timespan <= 0 then
			self:TimerStop(key)
		end
	end
end

function UIring:RefreshFightEffect()
	if not self._moduleList then
		return
	end

	for k,v in pairs(self._moduleList) do
		local itemdata = v.itemdata
		local combatCfg = itemdata.combatType
		local inFight = self:IsInFight(combatCfg)
		local showFight = inFight
		local item = v.item
		local mask = self:FindWndTrans(item,"AniRoot/mask")
		CS.ShowObject(mask,showFight)
		if showFight then
			self:CreateFightingEffect(mask)
		end
	end
end
-- 【G公共支持】删除跨服天梯和跨服周冠玩法
-- function UIring:SetLadderItem(item, itemdata)
	-- self:SetCommonItem(item, itemdata, true)

	-- local openId = itemdata.functionId
	-- local bOpenPlay = gModelFunctionOpen:CheckIsOpened(openId,false)



	-- if gModelCrossServer:IsLadderOpen() and bOpenPlay then
	-- 	local effNode = self:FindWndTrans(item,"AniRoot/eff")
	-- 	self:CreateWndEffect(effNode, "fx_jjc_gongnengkaiqi", "fx_jjc_gongnengkaiqi_ladder", Vector3.New(95,100,100), false, false)
	-- else
		-- self:DestroyWndEffectByKey("fx_jjc_gongnengkaiqi_ladder")
	-- end

-- end

-- function UIring:SetChampionItem(item, itemdata)

	-- self:SetCommonItem(item, itemdata, true)

	-- local openId = itemdata.functionId
	-- local bOpenPlay = gModelFunctionOpen:CheckIsOpened(openId,false)

	-- if gModelCrossServer:IsChampOpen() and bOpenPlay then
	-- 	local effNode = self:FindWndTrans(item,"AniRoot/eff")
	-- 	self:CreateWndEffect(effNode, "fx_jjc_gongnengkaiqi", "fx_jjc_gongnengkaiqi_champ", Vector3.New(95,100,100), false, false)
	-- else
	-- 	self:DestroyWndEffectByKey("fx_jjc_gongnengkaiqi_champ")
	-- end
-- end

function UIring:OnClickModuleCell(moduleRef)
	local openId = moduleRef.functionId
	local refId = moduleRef.refId
	local bOpen = gModelFunctionOpen:CheckIsOpened(openId,true)
	if not bOpen then
		return
	end

	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_PLAY,refId)

	local combatTypeCfg = moduleRef.combatType
	local inFight,combatType = self:IsInFight(combatTypeCfg)
	if inFight then
		gLFightManager:PrepareGoToBattle(combatType,{})
		return
	end

	if refId == UIring.CROSS_LADDER then
		GF.OpenWndBottom("WndCrossServerLadder")
	elseif refId == UIring.CROSS_CHAMPION then
		GF.OpenWndBottom("WndCrossServerChampion", {pageIndex = -1, groupIndex = 1})
	elseif refId == UIring.ARENA_RANK then
		GF.OpenWndBottom("UIringRk")
	elseif refId == UIring.ARENA_PEAK then
		GF.OpenWndBottom("UIringPk")
	elseif refId == UIring.CROSS_GRADING then
		GF.OpenWndBottom("UIKuafuGradMin",{isFromJump = true})
	elseif refId == UIring.SIMULATE then
		GF.OpenWnd("UISuMin")
	-- elseif refId == UIring.HIGH_STAGE_RACE then 移除高阶段位赛
	-- 	local pbCrossGradingHighInfo = gModelHighStageRace:GetCrossGradingHighInfo()
	-- 	if(pbCrossGradingHighInfo)then
	-- 		GF.OpenWndBottom("WndHighStageRaceMain")
	-- 	end
	else
		GF.ShowMessage(ccClientText(18219))
	end

end

function UIring:CreateFightingEffect(root)
	local instanceId = root:GetInstanceID()
	self:DestroyWndSpineByKey(instanceId)
	self:DestroyWndEffectByKey(instanceId)
	local isForeign = gLGameLanguage:IsForeignRegion()
	if isForeign then
		local root_3 = self:FindWndTrans(root,"eff_3")
		self:CreateWndSpine(root_3,'Heiyinghandouzhong',instanceId)
	else
		local root_1 = self:FindWndTrans(root,"eff_1")
		local root_2 = self:FindWndTrans(root,"eff_2")
		self:CreateWndSpine(root_1,'jian',instanceId)
		self:CreateWndEffect(root_2,"fx_fighting_text",instanceId,100,false,true)
	end
end

function UIring:InitMsgEvent()
	self:WndNetMsgRecv(LProtoIds.PlayerArenaResp, function(...) self:RefreshItem(UIring.ARENA_RANK) end)
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE, function() self:RefreshItem(UIring.ARENA_PEAK) end)
	self:WndEventRecv(EventNames.ON_POWER_CHANGE, function (...)  self:OnPowerChange(...) end)

	self:WndNetMsgRecv(LProtoIds.GetFormationResp,function (pb)
		if pb.type ==LCombatTypeConst.COMBAT_ARENA_DEFEND  then
			self:RefreshItem(UIring.ARENA_RANK)
		end
	end)

	self:WndEventRecv(EventNames.ON_BATTLE_END,function ()
		self:RefreshFightEffect()
	end)


	gModelArena:ShowPersonalPeakAccount()
	gModelArena:OnPlayerArenaReq(true)
	gModelArena:PinnaclePaceStateReq()
end

function UIring:IsInFight(combatCfg)
	local inFight = false
	local combatTypeArr = string.split(combatCfg,",")
	local combatType = nil
	for i, v in ipairs(combatTypeArr) do
		combatType = tonumber(v)
		inFight = gLFightManager:IsCombatTypeInFight(combatType)
		if inFight then
			break
		end
	end
	return inFight,combatType
end

function UIring:SetPeakItem(item, itemdata)
	self:SetCommonItem(item, itemdata, false)

	local dateInfo = self:FindWndTrans(item,"AniRoot/dateInfo")
	local timeInfo = self:FindWndTrans(item,"AniRoot/timeInfo")
	local openInfo = self:FindWndTrans(item,"AniRoot/openInfo")

	local curTime = GetTimestamp()
	local state = gModelArena:GetPeakState()
	-- local combatState = gModelArena:GetPeakCombatState()【G公共支持】删除跨服天梯和跨服周冠玩法
	local timeLeftStr = ""
	local stageStr =""
	self:TimerStop(self._peakTimerKey)

	-- local isShowForeignGuess = self._isShowForeignGuess【G公共支持】删除跨服天梯和跨服周冠玩法
	local peakStateBefore = state ==ModelArena.PEAK_STATE_BEFORE
	-- if isShowForeignGuess then--【G公共支持】删除跨服天梯和跨服周冠玩法
	-- 	--海外巅峰赛，竞猜阶段，算是前端做的赛前
	-- 	peakStateBefore = peakStateBefore or combatState == ModelArena.PEAK_BATTLE_STATE_BETTING
	-- end

	if peakStateBefore then
		local stageStrKey, timeLeftStrKey = 11810, 10303
		local peakStartTime = gModelArena:GetPeakStartTime()

		-- 【G公共支持】删除跨服天梯和跨服周冠玩法
		-- if isShowForeignGuess then
		-- 	if state ==ModelArena.PEAK_STATE_BEFORE then
		-- 		stageStrKey, timeLeftStrKey = 27425, 27426
		-- 	elseif combatState == ModelArena.PEAK_BATTLE_STATE_BETTING then
		-- 		peakStartTime = gModelArena:GetNextCombatStateTime()
		-- 	end
		-- end

		local peakDate= LUtil.OSDate("*t",peakStartTime)
		local timeStr = string.format("%d%s%d%s%d:%02d%s",peakDate["month"],ccClientText(11808),
				peakDate["day"],ccClientText(11807),peakDate["hour"],peakDate["min"],ccClientText(11809))
		stageStr = ccClientText(stageStrKey)..LUtil.FormatColorStr(timeStr,"lightGreen") --赛程

		local timeLeft= peakStartTime - curTime
		if timeLeft> 0 then
			timeStr = LUtil.FormatTimespanCn(timeLeft)
			timeLeftStr = ccClientText(timeLeftStrKey)..LUtil.FormatColorStr(timeStr,"lightGreen")
		end
		self._timerTransMap[self._peakTimerKey] = {time = peakStartTime, trans=timeInfo, title = ccClientText(timeLeftStrKey), formatFun = LUtil.FormatTimespanCn}
		self:TimerStart(self._peakTimerKey,1,false,-1)
	elseif state ==ModelArena.PEAK_STATE_STARTED then
		local stateStr = gModelArena:GetPeakRoundStr(gModelArena:GetPeakRound())
		local peakStageStr = stateStr..ccClientText(11811)
		stageStr =ccClientText(11810).. LUtil.FormatColorStr(peakStageStr,"lightGreen") --赛程：
		local peakEndTime = gModelArena:GetPeakEndTime()
		local timeLeft = peakEndTime - curTime
		if timeLeft<0 then
			timeLeft= 0
		end
		local timeStr = LUtil.FormatTimespanNumber(timeLeft)
		timeLeftStr =  ccClientText(10303)..LUtil.FormatColorStr(timeStr,"lightGreen")

		self._timerTransMap[self._peakTimerKey] = {time = peakEndTime, trans=timeInfo, title = ccClientText(10303), formatFun = LUtil.FormatTimespanNumber}

		self:TimerStart(self._peakTimerKey,1,false,-1)
	elseif state ==ModelArena.PEAK_STATE_END then
		stageStr= ccClientText(11810)..LUtil.FormatColorStr(ccClientText(11812),"lightGreen")
		local championName = gModelArena:GetPeakChampionName()
		championName = LUtil.FormatColorStr(championName,"yellow_2")
		timeLeftStr =ccClientText(11813)..championName
	end
	self:SetWndText(dateInfo,stageStr)
	self:SetWndText(timeInfo,timeLeftStr)

	local openId = itemdata.functionId
	local bOpen = gModelFunctionOpen:CheckIsOpened(openId,false)
	if  bOpen then
		local peakRank = gModelArena:GetPeakRank()
		local pealMaxRank = gModelArena:GetPeakMaxRank()
		local rankStr =tostring(peakRank)
		if peakRank==0 then
			rankStr =ccClientText(11876)
		end
		local rankStr = LUtil.FormatColorStr(rankStr,"yellow_2")
		rankStr = tostring(pealMaxRank)
		if pealMaxRank ==0 then
			rankStr =ccClientText(11876)
		end
		rankStr = LUtil.FormatColorStr(rankStr,"yellow_2")
		self:SetWndText(openInfo,ccClientText(10307)..peakRank.."  "..ccClientText(11814)..rankStr) --历史最高
		local isGaming = state ==ModelArena.PEAK_STATE_STARTED and not peakStateBefore

		if isGaming then
			local effNode = self:FindWndTrans(item,"AniRoot/eff")
			self:CreateWndEffect(effNode, "fx_jjc_gongnengkaiqi", "fx_jjc_gongnengkaiqi_peak", Vector3.New(95,100,100), false, false)
		else
			self:DestroyWndEffectByKey("fx_jjc_gongnengkaiqi_peak")
		end

	else
		self:DestroyWndEffectByKey("fx_jjc_gongnengkaiqi_peak")
	end

end
function UIring:OnPowerChange(type,key,power)
	if type ~= 1 or tonumber(key)~=LCombatTypeConst.COMBAT_ARENA_DEFEND then
		return
	end

	local itemInfo = self._moduleList[UIring.ARENA_RANK]
	if not itemInfo then
		return
	end

	local item = itemInfo.item
	if CS.IsNullObject(item) then
		return
	end

	local openInfo = self:FindWndTrans(item,"AniRoot/openInfo")

	-- 防守战力
	local defendForce =gModelPower:GetFormationPower(LCombatTypeConst.COMBAT_ARENA_DEFEND)
	defendForce = LUtil.PowerNumberCoversion(defendForce)
	defendForce = LUtil.FormatColorStr(defendForce,"yellow_2")
	-- 我的排名
	local rank =gModelArena:GetRank()
	local rankStr = tostring(rank)
	if rank <= 0 then
		rankStr = ccClientText(11876)
	end
	rankStr = LUtil.FormatColorStr(rankStr,"yellow_2")
	self:SetWndText(openInfo,ccClientText(10307)..rankStr..'  '..ccClientText(10308)..defendForce)
end

function UIring:SetSimulateItem(item,itemdata)
	self:SetCommonItem(item, itemdata, true)
end
function UIring:SetCommonItem(item, moduleRef, bShowReward)
	if CS.IsNullObject(item) or not moduleRef then
		return
	end

	local moduleTrans = self:FindWndTrans(item,"AniRoot")
	local bg = self:FindWndTrans(moduleTrans,"bg")
	local titleImg = self:FindWndTrans(moduleTrans,"titleImg")
	local dateInfo = self:FindWndTrans(moduleTrans,"dateInfo")
	local timeInfo = self:FindWndTrans(moduleTrans,"timeInfo")
	local openInfo = self:FindWndTrans(moduleTrans,"openInfo")
	local rewardList = self:FindWndTrans(moduleTrans,"rewardList")
	local icon = self:FindWndTrans(moduleTrans,"icon")
	local lock = self:FindWndTrans(moduleTrans,"lock")
	local lockText = self:FindWndTrans(lock,"lockTxt")
	local mask = self:FindWndTrans(moduleTrans,"mask")
	local fightEff = self:FindWndTrans(mask,"fightingEff")

	local Special = self:FindWndTrans(moduleTrans,"Special")
	local seasonEn = self:FindWndTrans(moduleTrans,"seasonEn")

	CS.ShowObject(Special,false)
	CS.ShowObject(seasonEn,false)

	if bShowReward then
		CS.ShowObject(rewardList, true)
		CS.ShowObject(dateInfo, false)
		CS.ShowObject(timeInfo, false)
		local rewardItems = LxDataHelper.ParseItem(moduleRef.reward)

		local instanceId = rewardList:GetInstanceID()
		local uiItemList = self:FindUIScroll(instanceId)
		if not uiItemList then
			uiItemList = self:GetUIScroll(instanceId)
			uiItemList:Create(rewardList,rewardItems,function (...) self:OnDrawItemCell(...) end)
		else
			uiItemList:RefreshList(rewardItems)
		end
	else
		CS.ShowObject(rewardList, false)
		CS.ShowObject(dateInfo, true)
		CS.ShowObject(timeInfo, true)
	end

	self:SetWndClick(moduleTrans, function()
		self:OnClickModuleCell(moduleRef)
	end, LSoundConst.CLICK_BUTTON_COMMON)

	local openId = moduleRef.functionId
	local bOpen, msg = gModelFunctionOpen:CheckIsOpened(openId,false)
	if bOpen then
		self:SetWndText(openInfo, ccLngText(moduleRef.desc))
	else
		self:SetWndText(lockText, msg)
	end
	CS.ShowObject(lock, not bOpen)
	CS.ShowObject(openInfo, bOpen)

	self:InitTextSizeWithLanguage(openInfo,-2)
	self:InitTextLineWithLanguage(openInfo,-10)

	self:SetWndEasyImage(bg, moduleRef.bg)
	self:SetWndEasyImage(icon, moduleRef.icon, nil, true)
	self:SetWndEasyImage(titleImg, moduleRef.titleIcon, nil, true)



end
--移除高阶段位赛
-- function UIring:SetHighStageRaceItem(item,itemdata)
-- 	self:SetCommonItem(item, itemdata, true)
-- 	local Special = self:FindWndTrans(item,"AniRoot/Special")
-- 	local firstTxt = self:FindWndTrans(Special,"firstTxt")
-- 	local openInfo = self:FindWndTrans(item,"AniRoot/openInfo")
-- 	local pbCrossGradingHighInfo = gModelHighStageRace:GetCrossGradingHighInfo()
-- 	local seasonId = pbCrossGradingHighInfo and pbCrossGradingHighInfo.seasonId or nil
-- 	local state = pbCrossGradingHighInfo and pbCrossGradingHighInfo.state or 0
-- 	local isOpen = state ~= 0
-- 	CS.ShowObject(Special,seasonId and seasonId~=0)
-- 	local cfg = gModelHighStageRace:GeConfigByType(ModelHighStageRace.Main)
-- 	local startHour = cfg.serverOpenTimes
-- 	local timeStr = startHour<10 and "0"..startHour..":00" or startHour..":00"
-- 	local openStr
-- 	local rankMatchLevel =pbCrossGradingHighInfo and pbCrossGradingHighInfo.rankMatchLevel or 0--玩家当前段位赛段位
-- 	local isEnoughLvl = rankMatchLevel >= cfg.choseGrading
-- 	local joinGradeName  = gModelHighStageRace:GetCrossGradingName(cfg.choseGrading)
-- 	local fStr = string.replace(ccClientText(21855),seasonId)
-- 	self:SetWndText(firstTxt,fStr)
-- 	if(isOpen)then
-- 		local joinState = pbCrossGradingHighInfo.joinState
-- 		if(state == 1)then
-- 			openStr = ccClientText(37700)
-- 		else
-- 			if(joinState)then
-- 				local lvl =pbCrossGradingHighInfo.level
-- 				local gradeCfg = lvl and gModelHighStageRace:GetConfigByTypeAndKey(ModelHighStageRace.Interval,lvl) or nil
-- 				local rank = pbCrossGradingHighInfo.rank
-- 				local nameStr = gradeCfg and ccLngText(gradeCfg.name) or ccClientText(37749)
-- 				nameStr = string.replace(ccClientText(37703),nameStr)
-- 				local rankStr = (rank and rank~=0) and string.replace(ccClientText(37767),rank) or ""
-- 				openStr = nameStr.." "..rankStr
-- 			else
-- 				openStr = not isEnoughLvl and string.replace(ccClientText(37701),joinGradeName) or string.replace(ccClientText(37702),timeStr)
-- 			end
-- 		end
-- 	else
-- 		openStr = not isEnoughLvl and string.replace(ccClientText(37701),joinGradeName) or string.replace(ccClientText(37702),timeStr)
-- 	end
-- 	self:SetWndText(openInfo,openStr)
-- end

function UIring:OnDrawItemCell(list, item, itemdata, pos, fromHeadTail)
	local refId = itemdata.itemId
	local itemRef = GameTable.PlayerItemRef[refId]
	local itype = itemdata.itemType
	--local isShowEff = itemdata.isShowEff
	-- LItemTypeConst.TYPE_ITEM = 1 	-- 道具
	-- LItemTypeConst.TYPE_HERO = 2 	-- 英雄
	-- LItemTypeConst.TYPE_EQUIP = 3 	-- 装备
	-- LItemTypeConst.TYPE_RUNE = 4 	-- 符文

	local uiIconRoot = CS.FindTrans(item,"IconRoot")

	if uiIconRoot then
		local uiItemList = self._uiItemList
		local InstanceID = item:GetInstanceID()
		local baseClass = uiItemList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiItemList[InstanceID] = baseClass
			baseClass:Create(CS.FindTrans(uiIconRoot,"Icon"))
		end

		local effRoot = CS.FindTrans(item,"Eff")
		if effRoot then
			LxResUtil.DestroyChildImmediate(effRoot)
			if itemRef and itype == LItemTypeConst.TYPE_ITEM then
				local bgEff = itemRef.bgEff or nil
				if not string.isempty(bgEff) then
					local effKey = InstanceID
					self:CreateWndEffect(effRoot,bgEff,effKey,68,false,false)
				end
			end
		end

		baseClass:SetCommonReward(itype, refId, -1)
		if itype == LItemTypeConst.TYPE_EQUIP then
			baseClass:EnableShowNum(true)
		end

		self:SetWndClick(uiIconRoot,function()
			local data = {
				itemType = itype,
				itemId = refId,
				itemNum = -1
			}
			gModelGeneral:ShowCommonItemTipWnd(data)
		end)

		baseClass:DoApply()
	end
end


function UIring:SetRankItem(item, itemdata)
	self:SetCommonItem(item, itemdata, false)

	local dateInfo = self:FindWndTrans(item,"AniRoot/dateInfo")
	local timeInfo = self:FindWndTrans(item,"AniRoot/timeInfo")
	local openInfo = self:FindWndTrans(item,"AniRoot/openInfo")

	local seasonEndTime = gModelArena:GetRankSeasonTime()
	local openTime = gModelArena:GetServerOpenTime()

	local seasonStartTime = seasonEndTime-7*24*60*60
	seasonStartTime = math.max(openTime,seasonStartTime)

	local startDate = LUtil.OSDate("*t",seasonStartTime)
	local endDate = LUtil.OSDate("*t",seasonEndTime-1)

	if startDate and endDate then
		local timeStr= string.format("%02d.%02d-%02d.%02d",startDate["month"],startDate["day"],endDate["month"],endDate["day"])
		timeStr = LUtil.FormatColorStr(timeStr,"lightGreen")
		self:SetWndText(dateInfo, ccClientText(10302)..timeStr)
	end

	local openId = itemdata.functionId
	local bOpen = gModelFunctionOpen:CheckIsOpened(openId,false)
	if  bOpen then
		-- 防守战力
		local defendForce =gModelPower:GetFormationPower(LCombatTypeConst.COMBAT_ARENA_DEFEND)
		defendForce = LUtil.PowerNumberCoversion(defendForce)
		defendForce = LUtil.FormatColorStr(defendForce,"yellow_2")
		--self:SetWndText(self.mDefendForce,ccClientText(10308)..defendForce)
		-- 我的排名
		local rank =gModelArena:GetRank()
		local rankStr = tostring(rank)
		if rank <= 0 then
			rankStr = ccClientText(11876)
		end
		rankStr = LUtil.FormatColorStr(rankStr,"yellow_2")
		self:SetWndText(openInfo,ccClientText(10307)..rankStr..'  '..ccClientText(10308)..defendForce)
	end
	-- 剩余时间
	local seasonEndTime = gModelArena:GetRankSeasonTime()
	local nowTime = GetTimestamp()
	local timespan= seasonEndTime-nowTime

	local timeStr = LUtil.FormatTimespanCn(timespan)
	timeStr = LUtil.FormatColorStr(timeStr,"lightGreen")
	timeStr = ccClientText(10303)..timeStr
	self:SetWndText(timeInfo,timeStr)

	self._timerTransMap[self._rankTimerKey] = {time = seasonEndTime, trans=timeInfo, title = ccClientText(10303)}
	self:TimerStop(self._rankTimerKey)
	if timespan < 0 then
		local seq = self._seqCom:CreateSeq("delayReq")
		seq:AppendInterval(1)
		seq:OnComplete(function ()
			gModelArena:OnPlayerArenaReq(true)
		end)
		seq:PlayForward()

		printErrorN("arena season end")


	else
		self:TimerStart(self._rankTimerKey,1,false,-1)
	end

end

function UIring:InitView()
	self:SetWndText(self.mTitle,ccClientText(10300))
	self:InitTextLineWithLanguage(self.mTitle, -30)
	self:InitTextSizeWithLanguage(self.mTitle, -2)

	local list = self:GetUIScroll("uiList")
	list:Create(self.mItemList, self._moduleDataList, function (...) self:OnDrawModuleCell(...) end, UIItemList.NORMAL,false)
	local uiList = list:GetList()
	--uiList:EnableLoadAnimation(true, 0, 1)
	uiList:EnableScroll(true,false)
	uiList:RefreshList()


	self:RefreshFightEffect()

end

function UIring:IsCombatType(combatTypeCfg, combatType)
	local bCombatType = false
	local combatTypeList = LxDataHelper.ParseNumber_Sign(combatTypeCfg, ',')
	for _,v in ipairs(combatTypeList) do
		if combatType == v then
			bCombatType = true
			break
		end
	end
	return bCombatType
end

function UIring:InitBtnEvent()
	self:SetWndClick(self.mBackBtn, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mWorldBtn, function() GF.OpenWndBottom("WndCrossServerWorld") end, LSoundConst.CLICK_BUTTON_COMMON)
	--local text = self:FindWndTrans(self.mWorldBtn,"text")
	--self:SetWndText(text,ccClientText(17501))

	self:SetWndButtonText(self.mWorldBtn,ccClientText(17501))


end

function UIring:SetCrossGradingItem(item,itemdata)

	self:SetCommonItem(item, itemdata, true)

	local Special = self:FindWndTrans(item,"AniRoot/Special")

	local firstTxt = self:FindWndTrans(Special,"firstTxt")
	local seasonId = gModelCrossGrading:GetSeasonId()
	if not seasonId or seasonId <= 0 then
		seasonId = 1
	end
	local str = string.replace(ccClientText(21855),seasonId)
	self:SetWndText(firstTxt,str)

	local seasonEn = self:FindWndTrans(item,"AniRoot/seasonEn")
	self:SetTextTile(seasonEn,str)
	--local isForeign = gLGameLanguage:IsForeignVersion()
	local isForeign = (gLGameLanguage:IsForeignVersion() and (not gLGameLanguage:IsHmtRegion()))
	CS.ShowObject(Special,not isForeign)
	CS.ShowObject(seasonEn,isForeign)

	local offset= Vector3.zero
	if gLGameLanguage:IsFrenchVersion() then
		offset = Vector3.New(40,0,0)
	end

	seasonEn.localPosition = seasonEn.localPosition + offset
end
------------------------------------------------------------------
-- 分类型设置Item
function UIring:RefreshItem(itemType)
	local itemInfo = self._moduleList[itemType]
	if not itemInfo then
		return
	end
	local item = itemInfo.item
	local itemdata = itemInfo.itemdata
	if not CS.IsValidObject(item) then
		return
	end

	self:OnDrawModuleCell(nil,item,itemdata)
end


function UIring:InitData()
	self._uiItemList = {}
	self._uiRewardList = {}

	self._moduleList = {}
	self._moduleDataList = {}
	self._moduleDataMap = {}
	for k,v in pairs(GameTable.DailyGamePlayRef) do
		if v.type == 2 then
			local isShow = gModelFunctionOpen:CheckIsShow(v.functionId)
			if isShow then
				table.insert(self._moduleDataList,v)
				self._moduleDataMap[v.refId] = v
			end
		end
    end

	table.sort( self._moduleDataList,function (a,b)
		return a.sort < b.sort
	end)

	self._rankTimerKey = "rankTimerKey"
	self._peakTimerKey = "peakTimerKey"

	self._timerTransMap = {}
	-- self._isShowForeignGuess = gModelCrossServer:CheckUseGuessForeign()
end


------------------------------------------------------------------
return UIring


