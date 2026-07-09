---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkGame:LChildWnd
local UISubPkGame = LxWndClass("UISubPkGame", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkGame:UISubPkGame()
	---@type table<number,CommonIcon>
	self._iconHeroClsList = {} -- 英雄格子
	self._combatStateStrList =
	{
		ccClientText(11824),
		ccClientText(11825),
		ccClientText(11826),
	}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkGame:OnWndClose()
	self:ClearCommonIconList(self._iconHeroClsList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkGame:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkGame:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()

	self:InitData()
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE,function()
		self:OnPeakStateChanged()
		self:SetStateCountdown()
		self:TimerStop("combatStateCountDownRunTime")
		self:TimerStart("combatStateCountDownRunTime", 1, false, -1)
	end)
	self:WndNetMsgRecv(LProtoIds.PinnaclePaceGuessMessageResp,function (...) self:OnPinnaclePaceGuessMessageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.GetFormationShowResp,function (...) self:GetFormationShowResp(...) end)

	gModelArena:PinnaclePaceGuessMessageReq(1)


	self:SetStateCountdown()
	local combatState = gModelArena:GetPeakCombatState()
	if combatState >= ModelArena.PEAK_BATTLE_STATE_UNSTART then
		local endTime = gModelArena:GetNextCombatStateTime()
		local timeLeft = math.ceil(endTime - GetTimestamp())
		if timeLeft > 0 then
			self:TimerStart("combatStateCountDownRunTime", 1, false, -1)
		end
	end
end


function UISubPkGame:CheckShowVsMyGame()
	local combatState=gModelArena:GetPeakCombatState()
	local isEnd = gModelArena:GetCombatIsEnd(self._round)
	if not isEnd then
		if combatState== ModelArena.PEAK_BATTLE_STATE_PREPARE or
				combatState== ModelArena.PEAK_BATTLE_STATE_BETTING then
			return true
		end
	end

	return false
end


function UISubPkGame:Watch()
	local reportId = self._reportId

	gModelArena:RecordWatched(reportId)
	local round =self._round
	if reportId and self._canWatch then
		local canSkip = gModelArena:GetCombatIsEnd(round)
		local wnd = GF.FindFirstWndByName("UIringPk")
		local pagePara = wnd:GetPagePara()
		local combatExtraDatas = {
			battleEndfun = function() self:OnPlayEnd(pagePara)  end,
			canSkip = canSkip,
			meName = self._leftName,
			otherName = self._rightName,
			videoType = LVideoTypeConst.PEAK,
			serverId = self._serverId
		}
		gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)
		--GF.CloseWndByName("UIringPk")
	end
end

function UISubPkGame:OnPeakStateChanged()

	local state = gModelArena:GetPeakState()
	if state == ModelArena.PEAK_STATE_BEFORE or state == ModelArena.PEAK_STATE_END then
		--self:WndClose()
		return
	end
	self._canWatch = false
	gModelArena:PinnaclePaceGuessMessageReq(1)


    local combatState = gModelArena:GetPeakCombatState()
    if combatState == ModelArena.PEAK_BATTLE_STATE_FIGHTING then
        self._qotoWatch = true
    else
        self._qotoWatch = false
    end


end


function UISubPkGame:OnPinnaclePaceGuessMessageResp(pb)

	if pb.type~= 1 then
		return
	end
	self._reportId = pb.combat.reportId
	self._serverId = pb.combat.serverId
	self._round = pb.combat.round
	self:ShowPlayerContent(pb.combat)
	self:ShowMidContent()
	self._canWatch = true

    if self._qotoWatch then
		local curRound = gModelArena:GetPeakRound()
		if curRound == self._round then
			local isWatched = gModelArena:CheckWatched(self._reportId)
			if not isWatched then
				self:Watch()

			end
		end
    end


end



function UISubPkGame:ShowMidContent()
	local showVs = nil
		showVs = self:CheckShowVsMyGame()
	if not showVs then
		local text = self:FindWndTrans(self.mPlayerReportBtn,"text")
		self:SetWndText(text,ccClientText(11844))

		self:SetWndClick(self.mPlayerReportBtn,function ()

			self:Watch()
		end)
	end
	-- CS.ShowObject(self.mVs,showVs)
	CS.ShowObject(self.mPlayerReportBtn,not showVs)

end

function UISubPkGame:ShowSkillList(skillListNode, skillInfos, playerType)
	skillInfos = skillInfos or {}

	local dataList = {}
	-- for i, v in ipairs(skillInfos) do
	-- 	if v.starRefId > 0 then
	-- 		dataList[i] = v.starRefId
	-- 	end
	-- end
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
			data = {ref = nil, upRef = nil}
		else
			local upRef = DraconicSuitRankRef[data]
			local ref = DraconicRef[upRef.type]
			data = {ref = ref, upRef = upRef}
		end
		table.insert(skillList, data)
	end

	-- local skillList = {}
	-- if playerType == 1 then
	-- 	for k = 4, 1, -1 do
	-- 		local data = dataList[k]
	-- 		if not data then
	-- 			data = 0
	-- 		end
	-- 		table.insert(skillList, data)
	-- 	end
	-- else
	-- 	for k = 1, 4 do
	-- 		local data = dataList[k]
	-- 		if not data then
	-- 			data = 0
	-- 		end
	-- 		table.insert(skillList, data)
	-- 	end
	-- end

	local listName = "skillList" .. playerType

	local list = self:GetUIScroll(listName)
	list:Create(skillListNode, skillList, function(...) self:OnDrawSkill(...) end)
end

function UISubPkGame:ShowExtraInfo()
	local winner = 0
	if self._round and gModelArena:GetCombatIsEnd(self._round) then
		winner = self._winner or 0
	end

	CS.ShowObject(self.mAttWinIcon,winner==1)
	CS.ShowObject(self.mDefWinIcon,winner==2)
end

function UISubPkGame:OnDrawSkill(list,item,itemdata,itempos)
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
			GF.OpenWnd("UIDraconicUpStar", { refId = itemdata.ref.refId, starNum = itemdata.upRef.rankNow, tips = true})
		end
    end)

	-- local icon = self:FindWndTrans(item, "icon")

	-- CS.ShowObject(icon, not itemdata == 0)
	-- if itemdata == 0 then
	-- 	self:SetWndClick(item, function() end)
	-- 	return
	-- end
	-- local skillRefId = itemdata
	-- local ref = GameTable.DraconicSuitRankRef[skillRefId]
	-- if ref then
	-- 	local draconicRef = gModelDraconic:GetDraconicRef(ref.type)
	-- 	local iconPath = draconicRef.skillIcon
	-- 	self:SetWndEasyImage(icon, iconPath, function()
	-- 		CS.ShowObject(icon, true)
	-- 	end)
	-- else
	-- 	CS.ShowObject(icon, false)
	-- end

	-- self:SetWndClick(item, function()
	-- 	if ref then
	-- 		GF.OpenWnd("UIDraconicUpStar", { refId = ref.type })
	-- 	end
	-- end)
end

function UISubPkGame:SetStateCountdown()
	local state = gModelArena:GetPeakState()
	local combatState = gModelArena:GetPeakCombatState()
	local combatStr = ""
	if state == ModelArena.PEAK_STATE_STARTED then
		if combatState > ModelArena.PEAK_BATTLE_STATE_UNSTART then
			combatStr = self._combatStateStrList[combatState - 1]
			local endTime = gModelArena:GetNextCombatStateTime()
			local timeLeft = math.ceil(endTime - GetTimestamp())
			if timeLeft < 0 then
				timeLeft = 0
			end

			local timeStr = LUtil.FormatTimespanToMin2New(timeLeft)
			combatStr = combatStr .. LUtil.FormatColorStr(timeStr, "lightGreen")
			if timeLeft == 0 then
				self:TimerStop("combatStateCountDownRunTime")
				gModelArena:PinnaclePaceGuessMessageReq(1)
			end
		end
	end
	local isEmpty = string.isempty(combatStr)
	CS.ShowObject(self.mStateObj, not isEmpty)
	if isEmpty then
		return
	end
	self:SetWndText(self.mStateText, combatStr)
end

function UISubPkGame:OnTimer(key)
	if "combatStateCountDownRunTime" == key then
		self:SetStateCountdown()
	end
end

function UISubPkGame:GetFormationShowResp(pb)
	self._winner = 0
	local selfData = {
		name = gModelPlayer:GetPlayerName(),
		serverName = gModelPlayer:GetServerName(),
		power = pb.heroData.power,
		playerId = gModelPlayer:GetPlayerId(),
		head = gModelPlayer:GetPlayerHead(),
		headFrame = gModelPlayer:GetPlayerHeadFrame(),
		grade = gModelPlayer:GetGradeLevel()
	}
	self:SetPlayer(self.mPlayer1, self.mPlayerTeam1, selfData, pb.heroData, 1)
	self:SetPlayer(self.mPlayer2, self.mPlayerTeam2, nil, nil, 2)
	CS.ShowObject(self.mMatchBtn, true)
	CS.ShowObject(self.mPlayerReportBtn, false)
end

function UISubPkGame:SetFormation(playerTeam, playerData, heroData, playerType)
	local heroList = self:FindWndTrans(playerTeam, "heroList")
	local noPlayer = self:FindWndTrans(playerTeam, "noPlayer")
	local noPlayerText = self:FindWndTrans(noPlayer, "Text")
	local skillList = self:FindWndTrans(playerTeam, "skillList")

	if not playerData or not heroData then
		local gridMax = LCombatFormationConst.GRID_MAX
		for i=1,gridMax do
			local root = self:FindWndTrans(heroList, tostring(i))
			LxResUtil.DestroyChild(root)
		end

		self:ShowSkillList(skillList, {}, playerType)
		self:SetWndText(noPlayerText, ccClientText(11835))
		CS.ShowObject(heroList, false)
		CS.ShowObject(noPlayer, true)
		return
	end
	CS.ShowObject(heroList, true)
	CS.ShowObject(noPlayer, false)



	local playerId = playerData.playerId
	local heros = {}
	for k,v in ipairs(heroData.heros) do
		local grid = heroData.grids[k]
		heros[grid] = v
	end

	local itemTemp = self.mHeroTemplate
	local gridMax = LCombatFormationConst.GRID_MAX
	for i=1,gridMax do
		local root = self:FindWndTrans(heroList, tostring(i))
		LxResUtil.DestroyChild(root)
		if heros[i] then
			local itemNew = LxResUtil.NewObject(itemTemp.gameObject)
			itemNew.transform:SetParent(root, false)
			itemNew.transform.localPosition = Vector3.zero
			CS.ShowObject(itemNew, true)
			self:SetHero(itemNew.transform, heros[i], playerId)
		end
	end

	self:ShowSkillList(skillList, heroData.draconicStarRefIds, playerType)
end

function UISubPkGame:OnPlayEnd(pagePara)
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIringPk",{page=pagePara.page,para =pagePara.para})
end

function UISubPkGame:InitData()
	self._uiheadList = {}
end


function UISubPkGame:ShowPlayerContent(combatData)
	self._winner = combatData.winner

	if string.isempty(combatData.attack.name) then
		-- gModelFormation:OnGetFormationReq(LCombatTypeConst.COMBAT_ARENA_PEAK_ATTACK)
		gModelPlayer:OnGetFormationShowReq(gModelPlayer:GetPlayerId(), LCombatTypeConst.COMBAT_ARENA_PEAK_ATTACK)
		return
	end
	CS.ShowObject(self.mMatchBtn, false)
	self:SetPlayer(self.mPlayer1, self.mPlayerTeam1, combatData.attack, combatData.attackHeros, 1)
	self:SetPlayer(self.mPlayer2, self.mPlayerTeam2, combatData.defense, combatData.defenseHeros, 2)
end

function UISubPkGame:SetHero(item, hero, playerId)
	local id ,refId,star,level,grade,fightPower = hero.id,hero.refId,hero.star,hero.level,hero.grade,hero.fightPower
	local herodata = {
		id = id,
		refId = refId,
		star = star,
		level = level,
		skin = hero.skin,
		isResonance = hero.isResonance
	}

	local heroRoot = self:FindWndTrans(item,"HeroIcon")
	local instanceId = item:GetInstanceID()
	local heroIcon = self._iconHeroClsList[instanceId]
	if not heroIcon then
		heroIcon = CommonIcon:New()
		self._iconHeroClsList[instanceId] = heroIcon
		heroIcon:Create(heroRoot)
		self:SetIconClickScale(heroRoot, true)
	end
	heroIcon:SetHeroDataSet(herodata)
	heroIcon:DoApply()

	self:SetWndClick(heroRoot,function()
		local data = {
			id = id,
			refId = refId,
			level = level,
			star = star,
			grade = grade,
			fightPower = fightPower,
			isResonance = hero.isResonance,
			skin = hero.skin,
		}
		gModelHero:ReqShowHeroTip(playerId,data)
	end)
end

function UISubPkGame:SetStaticContent()
	local str = ccClientText(11895)
	self:SetWndText(self.mInfo,str)
	self:InitTextLineWithLanguage(self.mInfo,-40)

	local text = self:FindWndTrans(self.mMatchBtn,"text")
	self:SetWndText(text,ccClientText(11836))
end



function UISubPkGame:SetPlayer(playerNode, playerTeam, playerData, heroData, playerType)
	if CS.IsNullObject(playerNode) or CS.IsNullObject(playerTeam) then
		return
	end
	local name = self:FindWndTrans(playerNode,"name")
	local serverText = self:FindWndTrans(playerNode,"serverText")
	local headIcon = self:FindWndTrans(playerNode,"HeadIcon")
	local powerText = self:FindWndTrans(playerNode,"PowerBg/PowerText")
	local winIcon = self:FindWndTrans(playerNode,"winIcon")

	local isNoPlayer = playerData == nil or string.isempty(playerData.name)
	-- CS.ShowObject(name,not isNoPlayer)
	-- CS.ShowObject(headIcon,not isNoPlayer)
	-- CS.ShowObject(powerText,not isNoPlayer)
	CS.ShowObject(winIcon,not isNoPlayer)

	if isNoPlayer then
		self:SetFormation(playerTeam, nil, nil, playerType)
		self:SetWndText(name,ccClientText(11834))
		self:SetWndText(serverText,ccClientText(11834))
		self:SetWndText(powerText, ccClientText(11834))
		return
	end

	self:SetWndText(name,playerData.name)
	self:SetWndText(serverText,playerData.serverName)

	if playerType == 1 then
		self._leftName = playerData.name
	else
		self._rightName = playerData.name
	end
	self:SetWndText(powerText, LUtil.PowerNumberCoversion(playerData.power))

	local winner = 0
	if self._round and gModelArena:GetCombatIsEnd(self._round) and self._winner ~= 0 then
		winner = self._winner or 0

		if playerType == winner then
			self:SetWndEasyImage(winIcon, "settlement_txt_2")
		else
			self:SetWndEasyImage(winIcon, "settlement_txt_3")
		end
	else
		CS.ShowObject(winIcon,  false)
	end
	-- headIcon
	local playerInfo = {
		trans = headIcon,
		playerId = playerData.playerId,
		name = playerData.name,
		icon = playerData.head,
		headFrame = playerData.headFrame or 20001,
		level = playerData.grade,
		noLv = true
	}
	self:SetWndClick(headIcon, function(...)
		gModelGeneral:PlayerShowReq(playerInfo.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)
	local uiheadlist = self._uiheadList
	local InstanceID = headIcon:GetInstanceID()
	local headIconClass = uiheadlist[InstanceID]
	if not headIconClass then
		headIconClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = headIconClass
	end
	headIconClass:SetHeadData(playerInfo)
	headIconClass:RefreshUI()

	self:SetFormation(playerTeam, playerData, heroData, playerType)
end





------------------------------------------------------------------
return UISubPkGame


