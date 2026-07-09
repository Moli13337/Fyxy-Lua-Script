---
--- Created by Administrator.
--- DateTime: 2024/4/26 18:01:04
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkGuess:LChildWnd
local UISubPkGuess = LxWndClass("UISubPkGuess", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkGuess:UISubPkGuess()
	---@type table<number,CommonIcon>
	self._iconHeroClsList = {}
	self.showEnj = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkGuess:OnWndClose()
	self:TimerStop("unOpenRunTime")
	if self.timer then
		LxTimer.DelayTimeStop(self.timer)
		self.timer = nil
	end
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkGuess:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkGuess:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()

	self:InitData()

	self:InitView()
	self:InitEvent()
	self:InitUIEvent()

	-- self:ShowBarrage()
	self:UpdateGuessList()
	self:InitEnjList()

	CS.ShowObject(self.mGuessTag, false)
end
function UISubPkGuess:SetStateTime()
	local endTime = gModelArena:GetNextCombatStateTime()

	local timeLeft =math.floor(endTime - GetTimestamp())
	local timeStr = nil
	local combatState = gModelArena:GetPeakCombatState()

	local tips2Txt = self._tips2Txts[combatState] or ""
	if timeLeft > 0 then
		timeStr = tips2Txt .. LUtil.FormatColorStr(LUtil.FormatTimespanToMin2New(timeLeft), "lightGreen")
	else
		timeStr = tips2Txt
	end

	if timeLeft <=0 then
		self:TimerStop(self._countDownKey)
	end
	self:SetXUITextText(self.mStageTips2, timeStr)
end

function UISubPkGuess:CheckShowPlay()
	local combatState=gModelArena:GetPeakCombatState()
	local isEnd = gModelArena:GetCombatIsEnd(self._round)
	if not isEnd then
		if combatState== ModelArena.PEAK_BATTLE_STATE_PREPARE or
				combatState== ModelArena.PEAK_BATTLE_STATE_BETTING then
			return false
		end
	end

	return true
end

function UISubPkGuess:SetGuessInfo()
	local guessInfo = self._guessInfo
	if not guessInfo then
		return
	end
	local leftText = self:FindWndTrans(self.mLeftOddsInfo, "text")
	local leftNum = self:FindWndTrans(self.mLeftOddsInfo, "num")
	local rightText = self:FindWndTrans(self.mRightOddsInfo, "text")
	local rightNum = self:FindWndTrans(self.mRightOddsInfo, "num")

	self:SetWndText(leftText, ccClientText(11845))
	self:SetWndText(rightText, ccClientText(11845))

	local leftStr = ""
	local rightStr = ""
	local guessCoin = guessInfo.guessCoin
	if guessCoin > 0 then
		if self._leftPlayerId == guessInfo.targetId then
			leftStr = string.replace(ccClientText(11891), guessCoin, self._leftOdds)
			rightStr = string.replace(ccClientText(11899), 0, self._rightOdds)
		else
			leftStr = string.replace(ccClientText(11891), 0, self._leftOdds)
			rightStr = string.replace(ccClientText(11899), guessCoin, self._rightOdds)
		end
	else
		leftStr =string.replace(ccClientText(11891), self._leftInputCoin, self._leftOdds)
		rightStr =string.replace(ccClientText(11899), self._rightInputCoin, self._rightOdds)
	end

	self:SetWndText(leftNum, leftStr)
	self:SetWndText(rightNum, rightStr)

	self:InitTextSizeWithLanguage(leftNum,-4)
	self:InitTextSizeWithLanguage(rightNum,-4)
	self:InitTextSizeWithLanguage(leftText,-4)
	self:InitTextSizeWithLanguage(rightText,-4)

end
function UISubPkGuess:OnGuessMessageUpdate(pbData)
	local notData = not pbData or pbData.combat.combatType == 0
	-- local nowW = tonumber(os.date("%w", GetTimestamp()))
	-- local startDay = gModelArena:GetArenaPeakRef("openDays") - 1
	local openState = gModelArena:GetPeakState()
	-- local readyTime = gModelArena:GetArenaPeakRef("readyTime")

	local showUnopen = false


	if notData or openState == 1 then
		showUnopen = true
	end
	-- if not isOpenState then
	-- 	if nowW ~= startDay then
	-- 		showUnopen = true
	-- 	else
	-- 		local startTime = gModelArena:GetArenaPeakRef("champStartTime")
	-- 		local timeInfo = string.split(startTime, ":")
	-- 		local statTime = (timeInfo[1] * 60 * 60) + (timeInfo[2] * 60) + timeInfo[3] + readyTime
	-- 		local nowTime = GetTimestamp()
	-- 		local nowH = tonumber(os.date("%H", nowTime))
	-- 		local nowM = tonumber(os.date("%M", nowTime))
	-- 		local nowS = tonumber(os.date("%S", nowTime))
	-- 		local nowTick = (nowH * 60 * 60) + (nowM * 60) + nowS
	-- 		if statTime > nowTick then
	-- 			showUnopen = true
	-- 		end
	-- 	end
	-- end
	if showUnopen then
		self:ShowUnOpen()
	end
	CS.ShowObject(self.mNoRecord2, showUnopen)
	CS.ShowObject(self.mOpenObj, not showUnopen)
	if notData then
		return
	end

	-- self:SetWndVisible(true)


	local combatData = pbData.combat
	self._serverId = combatData.serverId
	self._reportId = combatData.reportId
	self._round = combatData.round
	self._leftName = combatData.attack.name
	self._rightName = combatData.defense.name
	self._leftPlayerId = combatData.attack.playerId
	self._rightPlayerId = combatData.defense.playerId
	self._winner = combatData.winner
	self.arenaCombatInfo = StructCombatResultInfo:New()
	self.arenaCombatInfo:CreateByPb(combatData)


	self:ShowPlayerView(combatData)
	self:ShowBettingView(pbData)

	self._canWatch = true

	if self._qotoWatch then
		local curRound = gModelArena:GetPeakRound()
		if curRound == self._round then
			local isWatched = gModelArena:CheckWatched(self._reportId)
			if not isWatched then
				self:Watch()
				gModelArena:RecordWatched(self._reportId)
			end
		end
	end

end
function UISubPkGuess:InitData()

	self._oddsSliderKey ="_oddsSliderKey"
	self._betSliderKey = "_betSliderKey"
	self._miniNumBgEffectName = "fx_ui_qiandao_lingqutishi"
	self._uiheadList = {}
	self._leftInputCoin = 0
	self._rightInputCoin = 0

	self._countDownKey = "_countDownKey"

	self._tips2Txts = {
		ccClientText(17548),
		ccClientText(11824),
		ccClientText(11825),
		ccClientText(11826),
	}
end
function UISubPkGuess:ResetInputValue()
	local guessCoinMax = gModelArena:GetArenaPeakRef("guessCoinMax")

	local guessCoin = gModelArena:GetGuessCoin() or 0
	local max = math.min(guessCoin,guessCoinMax)
	self._leftInputCoin = math.range(self._leftInputCoin,0,max)
	self._rightInputCoin = math.range(self._rightInputCoin,0,max)
	local leftText = self:FindWndTrans(self.mLeftOdds,"value")
	self:SetWndText(leftText, self._leftInputCoin)

	local rightText = self:FindWndTrans(self.mRightOdds,"value")
	self:SetWndText(rightText, self._rightInputCoin)

	self:SetGuessInfo()
end

function UISubPkGuess:OnDrawSkill(list, item, itemdata, itempos)
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

	-- CS.ShowObject(icon, not itemdata == 0)
	-- if itemdata == 0 then
	-- 	self:SetWndClick(item, function() end)
	-- 	return
	-- end
	-- local skillRefId = itemdata.refId
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
	-- 		-- GF.OpenWnd("UIDraconicUpStar", { refId = ref.type })
	-- 		GF.OpenWnd("UIDraconicUpStar", { refId = skillRefId, starNum = itemdata.starRefId, tips = true})
	-- 	end
	-- end)
end

function UISubPkGuess:Watch()
	if string.isempty(self._reportId) then
		return
	end
	local tempReportId1 = self._leftPlayerId.."_"..self._rightPlayerId
	local tempReportId2 = self._rightPlayerId.."_"..self._leftPlayerId
	if self._reportId == tempReportId1 or self._reportId == tempReportId2 then
		return false
	end

	local reportId= self._reportId
	local round = self._round
	if reportId then

		local canSkip = gModelArena:GetCombatIsEnd(round)
		local wnd = GF.FindFirstWndByName("UIringPk")
		local pagePara = {}
		if wnd then
			pagePara = wnd:GetPagePara()
		end
		local combatExtraDatas = {
			battleEndfun = function() self:OnPlayEnd(pagePara)  end,
			canSkip = canSkip,
			meName = self._leftName,
			otherName =self._rightName,
			videoType = LVideoTypeConst.PEAK,
		}
		-- gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)
		GF.OpenWnd("UIVdoPop",
				{videoInfo = self.arenaCombatInfo, openEnum = ModelVideoCenter.OpenEnumArena, combatExtraDatas = combatExtraDatas})
		-- GF.CloseWndByName("UIringPk")
	end
	return true
end

function UISubPkGuess:SetIcons()
	local leftIcon = self:FindWndTrans(self.mLeftOddsInfo, "icon")
	self:SetGuessIcon(leftIcon)
	local rightIcon = self:FindWndTrans(self.mRightOddsInfo, "icon")
	self:SetGuessIcon(rightIcon)
	local readyGetIcon = self:FindWndTrans(self.mReadyGet, "icon")
	self:SetGuessIcon(readyGetIcon)

	local icon = self:FindWndTrans(self.mLeftOdds,"icon")
	self:SetGuessIcon(icon)
	icon = self:FindWndTrans(self.mRightOdds,"icon")
	self:SetGuessIcon(icon)
end
function UISubPkGuess:OnClickReport()
	self:Watch()
end
-- function UISubPkGuess:OnClickClose()
-- 	self:WndClose()
-- end

function UISubPkGuess:UpdateGuessList(pb)
	-- local list = gModelArena:GetGuessDesList()
	-- if not self.guessList then
	-- 	local list = gModelChat:GetTypeInfo(20)
	-- 	self.guessList = self:GetUIScroll("descList")
	-- 	self.guessList:Create(self.mGuessList, list, function(...) self:DrawItem(...) end)
	-- 	self.guessList:EnableScroll(true)
	-- else
	-- 	for _, v in ipairs(pb.msgs) do
	-- 		if v.channel == 20 then
	-- 			self.guessList._uiList:AddData(v)
	-- 		end
	-- 	end
	-- 	self.guessList._uiList:ResetList()
	-- 	-- self.guessList:DrawAllItems()
	-- end
	-- self.timer = LxTimer.DelayTimeCall(function()
	-- 	if self.guessList then
	-- 		self.guessList:MoveToPos(#list)
	-- 		self.timer = nil
	-- 	end
	-- end, 0.1)


	--------------------------------------------------------
	if not self.notFirst then
		self.notFirst = true
		local list = gModelChat:GetTypeInfo(20)
		local start = math.max(1, #list - 50 + 1)
		for i = start, #list do
			local item = CS.FindTrans(self.mItemPool, "ItemTemplate")
			self:DrawItem(nil, item, list[i])
			LxUnity.SetParentTrans(item, self.mItemRoot)
		end
	else
		if not pb then return end
		for _, v in ipairs(pb.msgs) do
			if v.channel == 20 then
				local item = CS.FindTrans(self.mItemPool, "ItemTemplate")
				if item == nil then
					item = CS.FindTrans(self.mItemRoot, "ItemTemplate")
					LxUnity.SetParentTrans(item, self.mItemPool)
				end
				self:DrawItem(nil, item, v)
				LxUnity.SetParentTrans(item, self.mItemRoot)
			end
		end
	end
	self.timer = LxTimer.DelayTimeCall(function()
		if self.mItemRoot then
			if not self.seqCom then
				self.seqCom = self:GetSeqCom()
			end
			self.seqCom:DeleteSeq("delayFreeze")
			local seq = self.seqCom:CreateSeq("delayFreeze")
			local y = self.mItemRoot.rect.height - 264
			local pos = Vector2.New(0, y)
			local downTweener = self.mItemRoot:DOLocalMove(pos, 0.3):SetEase(DG.Tweening.Ease.Linear)
			seq:Insert(0, downTweener)
			seq:PlayForward()
			self.timer = nil
		end
	end, 0.3)
end

function UISubPkGuess:ShowUnOpen()
	local isFirstRound = gModelArena:GetPeakRound() == 1
	local isFightCombatState = gModelArena:GetPeakCombatState() == 2
	if isFirstRound and isFightCombatState then
		local time = gModelArena:GetNextCombatStateTime()
		self.leftTime = time - GetTimestamp()
		self:SetWndText(self.mUnOpenTime, LUtil.FormatTimespanDetail(self.leftTime))
		self:TimerStart("unOpenRunTime", 1, false)
	else
		self.leftTime = gModelArena:GetPeakOpenTime(true)
		self:SetWndText(self.mUnOpenTime, LUtil.FormatTimespanDetail(self.leftTime))
		if self.leftTime > 0 then
			self:TimerStart("unOpenRunTime", 1, false)
		else
			self:SetWndText(self.mUnOpenTime, ccClientText(43312))
		end
	end
end
function UISubPkGuess:OnPlayEnd(pagePara)
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIringPk",{page=pagePara.page,para =pagePara.para})
end
function UISubPkGuess:InitEvent()
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE,function () self:OnStateUpdate() end)
	self:WndEventRecv(EventNames.On_Item_Change,function () self:UpdateGuessItemNum() end)

	self:WndNetMsgRecv(LProtoIds.PinnaclePaceGuessMessageResp,function (...) self:OnGuessMessageUpdate(...) end)
	self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp, function(pb)
        self:UpdateGuessList(pb)
    end)
	self:WndEventRecv("PinnaclePaceGuessResp",function (...) self:OnGuessUpdate(...) end)
	self:WndEventRecv("PinnaclePaceGuessAnnouncementResp",function (...) self:UpdateGuessList(...) end)
end

function UISubPkGuess:ClickSendBtn()
	local msg = self.mChatInput.text
	local bool = gModelChat:GetIfSend(20, msg)
	if not bool then
		return
	else
		local info = gModelChat:GetChatRestrict(cmd)
		if info.bool then
			self:SetWndTextInput(self.mInputChat, info.str)
			CS.ShowObject(self.mChatInput, false)
			CS.ShowObject(self.mChatInput, true)
			return
		end
	end
	gModelChat:OnChatMsgReq(20, ModelChat.MSGTYPE_NORMAL, msg)
    self:SetWndTextInput(self.mChatInput, "")
end
function UISubPkGuess:OnStateUpdate()

	local state = gModelArena:GetPeakState()
	if state == ModelArena.PEAK_STATE_BEFORE or state == ModelArena.PEAK_STATE_END then
		return
	end
	self._canWatch = false

	self:TimerStop(self._countDownKey)
	self:TimerStart(self._countDownKey, 1, false, -1)
	self:SetStateTime()

	gModelArena:PinnaclePaceGuessMessageReq(2)

	local combatState = gModelArena:GetPeakCombatState()
	if combatState == ModelArena.PEAK_BATTLE_STATE_FIGHTING then
		self._qotoWatch = true
		-- gModelArena:ClearGuessDesList()
		-- self:UpdateGuessList()
	else
		self._qotoWatch = false
	end


end
function UISubPkGuess:ShowSkillList(skillListNode, skillInfos, playerType)
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
			data = {ref = nil, upRef = nil}
		else
			local upRef = DraconicSuitRankRef[data]
			local ref = DraconicRef[upRef.type]
			data = {ref = ref, upRef = upRef}
		end
		table.insert(skillList, data)
	end

	-- if playerType == 1 then
	-- 	for k = 4, 1, -1 do
	-- 		local data = dataList[k]
	-- 		if not data then
	-- 			data = {ref = nil, upRef = nil}
	-- 		else
	-- 			local upRef = DraconicSuitRankRef[data]
	-- 			local ref = DraconicRef[upRef.type]
	-- 			data = {ref = ref, upRef = upRef}
	-- 		end
	-- 		table.insert(skillList, data)
	-- 	end
	-- else
	-- 	for k = 1, 4 do
	-- 		local data = dataList[k]
	-- 		if not data then
	-- 			data = {ref = nil, upRef = nil}
	-- 		else
	-- 			local upRef = DraconicSuitRankRef[data]
	-- 			local ref = DraconicRef[upRef.type]
	-- 			data = {ref = ref, upRef = upRef}
	-- 		end
	-- 		table.insert(skillList, data)
	-- 	end
	-- end

	local listName = "skillList" .. playerType

	local list = self:GetUIScroll(listName)
	list:Create(skillListNode, skillList, function(...) self:OnDrawSkill(...) end)
end
function UISubPkGuess:ShowPlayerView(combatData)
	self:SetPlayer(self.mPlayer1, self.mPlayerTeam1, combatData.attack, combatData.attackHeros, 1)
	self:SetPlayer(self.mPlayer2, self.mPlayerTeam2, combatData.defense, combatData.defenseHeros, 2)

	local showPlay = self:CheckShowPlay()
	CS.ShowObject(self.mPlayerReportBtn, showPlay)
end

function UISubPkGuess:DrawItem(_, item, data)
	if not data then return end
	local text = self:FindWndTrans(item, "DescTxt")
	local id = tonumber(data.atPlayerId)
	local s = ""
	if id and id ~= 0 then
		s = ccLngText(gModelChat:GetMailNoticesRefByRefId(id).content)
		if id == 105 then
			local s1, s2, s3 = "", "", ""
			local info = JSON.decode(data.msg)
			if info then
				s1 = gLGameLogin:GetServerShotNameById(tonumber(info.a1))
				s2 = info.a2
				s3 = info.a3
				s = string.replace(s, s1, s2, s3)
			end
		end
	else
		data.msg = LUtil.ChatInfoFaceBinToDec(data.msg)
		s = data.playerName .. "：" .. LUtil.GetFaceStr(data.msg, 25)
	end
	self:SetWndText(text, s)
end
function UISubPkGuess:OnGuessUpdate(pb)
	gModelArena:PinnaclePaceGuessMessageReq(2)
end
function UISubPkGuess:SetInputBtn(btnTrans, type)

	self:SetWndClick(btnTrans,function()
		local tab = {}
		tab.inputTran = btnTrans
		tab.minNum = 0
		tab.maxNum = gModelArena:GetGuessCoin()
		if type == 1 then
			tab.defaultNum = tonumber(self._leftInputCoin)
		else
			tab.defaultNum = tonumber(self._rightInputCoin)
		end
		tab.inputFunc = function(numStr,cmd)
			if self:IsWndClosed() then
				return
			end
			local num = tonumber(numStr)
			if num then
				if cmd == "C" then
					self._leftInputCoin = 0
					self._rightInputCoin = 0
				elseif cmd == "D" then

				else
					if type == 1 then
						self._leftInputCoin = num
						self._rightInputCoin = 0
					else
						self._leftInputCoin = 0
						self._rightInputCoin = num
					end
				end
				self:ResetInputValue()
			end
		end
		GF.OpenWndUp("UINuoardUI",tab)
	end)
end
function UISubPkGuess:InitView()

	local str =ccClientText(11817)-- "竞猜"
	self:SetWndText(self.mTitle, str)
	self:SetWndText(self.mUnOpenTitle, ccClientText(11863))
	self:SetIcons()

	self:TimerStop(self._countDownKey)
	self:TimerStart(self._countDownKey, 1, false, -1)
	self:SetStateTime()

	-- self:SetWndVisible(false)

	gModelArena:PinnaclePaceGuessMessageReq(2)
end
function UISubPkGuess:OnClickGuess(type)
	local targetId = type == 1 and self._leftPlayerId or self._rightPlayerId
	GF.OpenWnd("UIPkGuessBet", { targetId = targetId })
	-- local combatState = gModelArena:GetPeakCombatState()
	-- if combatState < ModelArena.PEAK_BATTLE_STATE_BETTING then
	-- 	GF.ShowMessage(ccClientText(17539))
	-- 	return
	-- end

	-- local targetId = 0
	-- local guessCoin = 0
	-- if type == 1 then
	-- 	guessCoin = self._leftInputCoin
	-- 	targetId = self._leftPlayerId
	-- else
	-- 	guessCoin = self._rightInputCoin
	-- 	targetId = self._rightPlayerId
	-- end

	-- if guessCoin <= 0 then
	-- 	GF.ShowMessage(ccClientText(11887))
	-- 	return
	-- end
	-- CS.ShowObject(self.mGuessNode, false)
	-- gModelArena:PinnaclePaceGuessReq(targetId, guessCoin)
end
function UISubPkGuess:SetHero(item, hero, playerId)
	local id ,refId,star,level,grade,fightPower = hero.id,hero.refId,hero.star,hero.level,hero.grade,hero.fightPower
	local heroData = {
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
	heroIcon:SetHeroDataSet(heroData)
	heroIcon:DoApply()

	self:SetWndClick(heroRoot, function()
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
		gModelHero:ReqShowHeroTip(playerId,data,nil,nil,nil,self._serverId)
	end)
end
function UISubPkGuess:OnClickReduce(type)
	if type == 1 then
		self._leftInputCoin = self._leftInputCoin - 10
		self._rightInputCoin = 0
		if self._leftInputCoin < 0 then
			self._leftInputCoin = 0
		end
	else
		self._leftInputCoin = 0
		self._rightInputCoin = self._rightInputCoin - 10
		if self._rightInputCoin < 0 then
			self._rightInputCoin = 0
		end
	end
	self:ResetInputValue()
end
function UISubPkGuess:SetFormation(playerTeam, playerData, heroData, playerType)
	local heroList = self:FindWndTrans(playerTeam, "heroList")

	if not playerData or not heroData then
		local gridMax = LCombatFormationConst.GRID_MAX
		for i = 1,gridMax do
			local root = self:FindWndTrans(heroList, tostring(i))
			LxResUtil.DestroyChild(root)
		end

		return
	end

	local skillList = self:FindWndTrans(playerTeam, "skillList")

	local playerId = playerData.playerId
	local heros = {}
	for k,v in ipairs(heroData.heros) do
		local grid = heroData.grids[k]
		heros[grid] = v
	end

	local itemTemp = self.mHeroTemplate
	local gridMax = LCombatFormationConst.GRID_MAX
	for i = 1,gridMax do
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

function UISubPkGuess:InitEnjList()
	local DrawEnj = function(_, item, data)
		local img = CS.FindTrans(item, "Image")
		self:SetWndEasyImage(img, data.faceIcon)
		self:SetWndClick(img, function()
			self:SetWndTextInput(self.mChatInput, self.mChatInput.text .. data.faceinstead)
		end)
	end

	local list = gModelChat:GetEmojiByType(1)
	local enjList = self:GetUIScroll("enjList")
	enjList:Create(self.mEnjList, list, function(...) DrawEnj(...) end, UIItemList.SUPER_GRID)
end

function UISubPkGuess:SetGuessIcon(tran)
	local item = gModelArena:GetArenaPeakRef("guessCoin")
	local itemId = string.split(item, "=")[2]
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(tran,iconPath)
end
function UISubPkGuess:OnClickAdd(type)
	if type == 1 then
		self._leftInputCoin = self._leftInputCoin + 10
		self._rightInputCoin = 0
	else
		self._leftInputCoin = 0
		self._rightInputCoin = self._rightInputCoin + 10
	end

	self:ResetInputValue()
end
function UISubPkGuess:OnTimer(key)

	if self._countDownKey == key then
		self:SetStateTime()
	end
	if key == "unOpenRunTime" then
		self.leftTime = self.leftTime - 1
		if self.leftTime > 0 then
			self:SetWndText(self.mUnOpenTime, LUtil.FormatTimespanDetail(self.leftTime))
		else
			self:TimerStop("unOpenRunTime")
			gModelArena:PinnaclePaceGuessMessageReq(2)
		end
	end
end

function UISubPkGuess:UpdateGuessItemNum()
	self:SetWndText(self:FindWndTrans(self.mCanUseNode, "num"), gModelItem:GetNumByRefId(112001))
end

function UISubPkGuess:ShowBettingView(pbData)
	-- bar
	local oddsSlider = self:UIProgressFind(self.mOddsSlider, self._oddsSliderKey, 0)
	local oddsCost = gModelArena:GetArenaPeakRef("oddsCost")
	self._leftOdds = pbData.leftOdds
	self._rightOdds = pbData.rightOdds
	local oddsValue = (self._rightOdds-self._leftOdds)/oddsCost
	local value = 0.5 + oddsValue * 0.5 * 0.75
	value = value > 0 and value or 0
	value = value <= 1 and value or 1
	oddsSlider:SetUIProgress(value)
	oddsSlider:SetInteractable(false)

	local canUseText = self:FindWndTrans(self.mCanUseNode, "text")
	local canUseIcon = self:FindWndTrans(self.mCanUseNode, "icon")
	local canUseNum = self:FindWndTrans(self.mCanUseNode, "num")
	self:SetWndText(canUseNum, pbData.guessCoin)
	self:SetWndText(canUseText, ccClientText(17564))
	self:InitTextSizeWithLanguage(canUseText,-4)

	self:SetGuessIcon(canUseIcon)

	local guessInfo = pbData.infos
	local combatState = gModelArena:GetPeakCombatState()
	if combatState == 4  then
		CS.ShowObject(self.mPlayerReportBtn, true)
	else
		CS.ShowObject(self.mPlayerReportBtn, false)
	end

	if self._isEnus then
		canUseText.localPosition  = Vector3.New(-5,0,0)
	end

	-- if guessInfo.targetId == self._rightPlayerId then
	-- 	CS.ShowObject(self.mLeftOddsInfo, false)
	-- 	CS.ShowObject(self.mRightOddsInfo, true)
	-- elseif guessInfo.targetId == self._leftPlayerId then
	-- 	CS.ShowObject(self.mLeftOddsInfo, true)
	-- 	CS.ShowObject(self.mRightOddsInfo, false)
	-- else
		CS.ShowObject(self.mLeftOddsInfo, true)
		CS.ShowObject(self.mRightOddsInfo, true)
	-- end

	if combatState == 3 and guessInfo.guessCoin == 0 then
		CS.ShowObject(self.mGuessNode, true)
		CS.ShowObject(self.mAfterGuessNode, false)
	else
		CS.ShowObject(self.mGuessNode, false)
		CS.ShowObject(self.mAfterGuessNode, true)

		if guessInfo.guessCoin > 0 then
			CS.ShowObject(self.mReadyGet, true)
			local getNum = self._leftOdds * guessInfo.guessCoin
			local pos = self.mGuessTag.localPosition
			local readyPos = self.mReadyGet.localPosition
			pos.x = -150
			readyPos.x = 60
			if guessInfo.targetId == self._rightPlayerId then
				pos.x = 150
				readyPos.x = -60
				getNum = self._rightOdds * guessInfo.guessCoin
			end
			local readyGetText = self:FindWndTrans(self.mReadyGet, "text")


			local readyGetNun = self:FindWndTrans(self.mReadyGet, "num")
			self:SetWndText(readyGetText, ccClientText(17565))

			self:SetWndText(readyGetNun, math.round(getNum))
			self.mGuessTag.localPosition = pos
			if gLGameLanguage:IsForeignVersion() then
				self.mReadyGet.localPosition = readyPos
			end
			self:SetWndEasyImage(self.mGuessTag, "actionarena_txt_5")
		else
			CS.ShowObject(self.mReadyGet, false)
			local pos = self.mGuessTag.localPosition
			pos.x = 0
			self.mGuessTag.localPosition = pos
			self:SetWndEasyImage(self.mGuessTag, "actionarena_txt_11")
		end
	end

	self._guessInfo = guessInfo
	self:SetGuessInfo()
end
function UISubPkGuess:InitUIEvent()
	-- self:SetWndClick(self.mCloseBtn,function () self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	-- self:SetWndClick(self.mBgBtn,function () self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	local leftBtn = self:FindWndTrans(self.mLeftOdds,"btn")
	local leftBg = self:FindWndTrans(self.mLeftOdds,"valueBg")
	--local leftValue = self:FindWndTrans(self.mLeftOdds,"value")
	local leftAddBtn = self:FindWndTrans(self.mLeftOdds,"add")
	local leftReduceBtn = self:FindWndTrans(self.mLeftOdds,"reduce")
	self:SetWndClick(leftBtn, function ()self:OnClickGuess(1) end)
	self:SetWndButtonText(leftBtn, ccClientText(17562),nil,-6)
	self:SetInputBtn(leftBg, 1)
	self:SetWndClick(leftAddBtn, function ()self:OnClickAdd(1) end)
	self:SetWndClick(leftReduceBtn, function ()self:OnClickReduce(1) end)

	self:SetWndClick(self.mEnjBtn, function() self:ClickEnjBtn() end)
	self:SetWndClick(self.mEnjClose, function() self:ClickEnjBtn() end)
	self:SetWndButtonText(self.mSendBtn, ccClientText(12433))

	local rightBtn = self:FindWndTrans(self.mRightOdds,"btn")
	local rightBg = self:FindWndTrans(self.mRightOdds,"valueBg")
	--local rightValue = self:FindWndTrans(self.mRightOdds,"value")
	local rightAddBtn = self:FindWndTrans(self.mRightOdds,"add")
	local rightReduceBtn = self:FindWndTrans(self.mRightOdds,"reduce")
	self:SetWndClick(rightBtn, function ()self:OnClickGuess(2) end)
	self:SetWndButtonText(rightBtn, ccClientText(17562),nil,-6)
	self:SetInputBtn(rightBg, 2)
	self:SetWndClick(rightAddBtn, function ()self:OnClickAdd(2) end)
	self:SetWndClick(rightReduceBtn, function ()self:OnClickReduce(2) end)
	self:SetWndClick(self.mSendBtn, function()
		self:ClickSendBtn()
	end)

	self:SetWndClick(self.mPlayerReportBtn,function () self:OnClickReport() end)

	local text = self:FindWndTrans(self.mPlayerReportBtn,"text")
	local str =ccClientText(11844)
	self:SetWndText(text,str)

	local cfg = gModelGeneral:GetEmptyCfg(5006)
	local text = self:FindWndTrans(self.mNoRecord2,"EmptyText")
	self:SetWndText(text, ccLngText(cfg.text))

	self:SetWndText(CS.FindTrans(self.mChatInput,"TextArea/Placeholder"), ccClientText(11133))

	self:ResetInputValue()
end

function UISubPkGuess:SetPlayer(playerNode, playerTeam, playerData, heroData, playerType)
	if CS.IsNullObject(playerNode) or CS.IsNullObject(playerTeam) then
		return
	end
	local name = self:FindWndTrans(playerNode,"name")
	local serverText = self:FindWndTrans(playerNode,"serverText")
	local headIcon = self:FindWndTrans(playerNode,"HeadIcon")
	local powerText = self:FindWndTrans(playerNode,"PowerBg/PowerText")
	local winIcon = self:FindWndTrans(playerNode,"winIcon")

	local isNoPlayer = string.isempty(playerData.name)
	CS.ShowObject(name,not isNoPlayer)
	CS.ShowObject(headIcon,not isNoPlayer)
	CS.ShowObject(powerText,not isNoPlayer)
	CS.ShowObject(winIcon,not isNoPlayer)

	if isNoPlayer then
		self:SetFormation(playerTeam, nil, nil)
		return
	end

	self:SetWndText(name,playerData.name)
	self:SetWndText(serverText,playerData.serverName)
	self:SetWndText(powerText, LUtil.PowerNumberCoversion(playerData.power))

	-- local isEnd = gModelArena:GetCombatIsEnd(self._round)
	-- if self._winner > 0 and isEnd then
	-- 	CS.ShowObject(winIcon,  true)
	-- 	if playerType == self._winner then
	-- 		self:SetWndEasyImage(winIcon, "settlement_txt_2")
	-- 	else
	-- 		self:SetWndEasyImage(winIcon, "settlement_txt_3")
	-- 	end
	-- else
		CS.ShowObject(winIcon,  false)
	-- end

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
	self:SetIconClickScale(headIcon, false)

	self:SetFormation(playerTeam, playerData, heroData, playerType)
end
function UISubPkGuess:ShowBarrage(isBack)
	-- local channel = ModelChat.CHANNEL_PEAK
	-- local isBarrageShow = gModelChat:GetBarrageIsShow(channel)
	-- GF.CloseWndByName("UIBulletSay")
	-- if(isBarrageShow)then
	-- 	if isBack then
	-- 		gModelGeneral:OpenBarrage({channel = ModelChat.CHANNEL_PEAK})
	-- 	else
	-- 		gModelGeneral:OpenBarrage({channel = ModelChat.CHANNEL_PEAK})
	-- 	end
	-- end
end

function UISubPkGuess:ClickEnjBtn()
	self.showEnj = not self.showEnj
	CS.ShowObject(self.mEnjObj, self.showEnj)
	local res = self.showEnj and "chat_btn_jian" or "chat_btn_jia"
	self:SetWndEasyImage(self.mEnjBtn, res)
end



------------------------------------------------------------------
return UISubPkGuess