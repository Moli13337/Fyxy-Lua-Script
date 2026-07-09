---
--- Created by Administrator.
--- DateTime: 2023/10/23 18:24:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringPkGuess:LWnd
local UIringPkGuess = LxWndClass("UIringPkGuess", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringPkGuess:UIringPkGuess()

	---@type table<number,CommonIcon>
	self._iconHeroClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringPkGuess:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringPkGuess:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringPkGuess:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self:InitData()

	self:InitView()
	self:InitEvent()
	self:InitUIEvent()

	self:ShowBarrage()
	self:RefreshMiniNum()

	self:SetWndText(self.mMineTitle, ccClientText(21300))
	self:InitTextSizeWithLanguage(self.mMineTitle,-2)
	self:InitTextLineWithLanguage(self.mMineTitle,-30)


	CS.ShowObject(self.mGuessTag, false)
end
function UIringPkGuess:InitUIEvent()
	self:SetWndClick(self.mCloseBtn,function () self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgBtn,function () self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
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

	self:SetWndClick(self.mPlayerReportBtn,function () self:OnClickReport() end)
	self:SetWndClick(self.mMiniBg, function() self:OnClickMiniNumBg() end)

	local text = self:FindWndTrans(self.mPlayerReportBtn,"text")
	local str =ccClientText(11844)
	self:SetWndText(text,str)

	self:ResetInputValue()
end

function UIringPkGuess:SetGuessInfo()
	local guessInfo = self._guessInfo
	if not guessInfo then
		return
	end
	local leftText = self:FindWndTrans(self.mLeftOddsInfo, "text")
	local leftNum = self:FindWndTrans(self.mLeftOddsInfo, "num")
	local rightText = self:FindWndTrans(self.mRightOddsInfo, "text")
	local rightNum = self:FindWndTrans(self.mRightOddsInfo, "num")

	-- self:SetWndText(leftText, ccClientText(11845))
	-- self:SetWndText(rightText, ccClientText(11845))

	local leftStr = ""
	local rightStr = ""
	local guessCoin = guessInfo.guessCoin
	if guessCoin > 0 then
		if self._leftPlayerId == guessInfo.targetId then
			leftStr = string.replace(ccClientText(11891), guessCoin, self._leftOdds)
			rightStr = string.replace(ccClientText(11899), self._rightOdds, 0)
		else
			leftStr = string.replace(ccClientText(11891), 0, self._leftOdds)
			rightStr = string.replace(ccClientText(11899), self._rightOdds, guessCoin)
		end
	else
		leftStr =string.replace(ccClientText(11891), self._leftInputCoin, self._leftOdds)
		rightStr =string.replace(ccClientText(11899), self._rightInputCoin, self._rightOdds)
	end

	-- self:SetWndText(leftNum, leftStr)
	-- self:SetWndText(rightNum, rightStr)

	self:SetWndText(leftText, ccClientText(11845) .. leftStr)
	self:SetWndText(rightText, ccClientText(11845) .. rightStr)

	-- self:InitTextSizeWithLanguage(leftNum,-4)
	-- self:InitTextSizeWithLanguage(rightNum,-4)
	self:InitTextSizeWithLanguage(leftText,-4)
	self:InitTextSizeWithLanguage(rightText,-4)

end
function UIringPkGuess:InitEvent()
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE,function () self:OnStateUpdate() end)
	self:WndEventRecv(EventNames.On_Item_Change,function () self:UpdateGuessItemNum() end)
	self:WndEventRecv("PinnaclePaceGuessResp",function (...) self:OnGuessUpdate(...) end)

	self:WndNetMsgRecv(LProtoIds.PinnaclePaceGuessMessageResp,function (...) self:OnGuessMessageUpdate(...) end)
	self:WndNetMsgRecv(LProtoIds.TreasureInfoResp, function() self:RefreshMiniNum() end)
end
function UIringPkGuess:OnGuessMessageUpdate(pbData)
	local unOpen = not pbData or  pbData.type ~= 2 or pbData.combat.combatType == 0
	if unOpen then
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
function UIringPkGuess:OnTimer(key)

	if self._countDownKey == key then
		self:SetStateTime()
	end
end

function UIringPkGuess:RefreshMiniNum()
	-- local isTreasureActive 	= gModelGeneral:IsGuessTreasureSkillActive()
	local isTreasureActive 	= false
	local isPrivilegeActive = gModelGeneral:IsGuessPrivilegeActive()
	local isActive			= isTreasureActive or isPrivilegeActive
	CS.ShowObject(self.mMiniEffectRoot, isActive)
	if not isActive then return end

	--do return end
	-- 缺个特效名,但策划说暂不用特效试试
	--self:CreateWndEffect(self.mMiniEffectRoot,self._miniNumBgEffectName,self._miniNumBgEffectName,100,false,false)
end
function UIringPkGuess:OnClickReport()
	self:Watch()
end
function UIringPkGuess:OnPlayEnd(pagePara)
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIringPk",{page=pagePara.page,para =pagePara.para})
end

function UIringPkGuess:SetPlayer(playerNode, playerTeam, playerData, heroData, playerType)
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
	-- CS.ShowObject(winIcon,not isNoPlayer)

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
function UIringPkGuess:SetInputBtn(btnTrans, type)

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
function UIringPkGuess:SetHero(item, hero, playerId)
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

function UIringPkGuess:UpdateGuessItemNum()
	self:SetWndText(self:FindWndTrans(self.mCanUseNode, "num"), gModelItem:GetNumByRefId(112001))
end
function UIringPkGuess:OnClickAdd(type)
	if type == 1 then
		self._leftInputCoin = self._leftInputCoin + 10
		self._rightInputCoin = 0
	else
		self._leftInputCoin = 0
		self._rightInputCoin = self._rightInputCoin + 10
	end

	self:ResetInputValue()
end

function UIringPkGuess:ShowBettingView(pbData)
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
function UIringPkGuess:SetStateTime()
	local endTime = gModelArena:GetNextCombatStateTime()

	local timeLeft =math.floor(endTime - GetTimestamp())
	local timeStr = nil
	local combatState = gModelArena:GetPeakCombatState()

	local tips2Txt = self._tips2Txts[combatState] or ""
	if timeLeft > 0 then
		timeStr = tips2Txt .. "：" .. LUtil.FormatColorStr(LUtil.FormatTimespanNumber(timeLeft), "red")
	else
		timeStr = tips2Txt
	end

	if timeLeft <=0 then
		self:TimerStop()
	end
	self:SetWndText(self.mStageTips2, timeStr)
	-- self:SetXUITextText(self.mStageTips2, timeStr)
end
function UIringPkGuess:ShowSkillList(skillListNode, skillInfos, playerType)
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

	-- skillInfos = skillInfos or {}

	-- local dataList = {}
	-- for i, v in ipairs(skillInfos) do
	-- 	if v > 0 then
	-- 		dataList[i] = v
	-- 	end
	-- end

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
function UIringPkGuess:ResetInputValue()
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
function UIringPkGuess:ShowBarrage(isBack)
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
function UIringPkGuess:OnDrawSkill(list,item,itemdata,itempos)
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
	-- 	-- GF.OpenWnd("UIDraconicUpStar", { refId = itemdata.ref.refId, starNum = itemdata.upRef.rankNow, tips = true})
	-- end)
end

function UIringPkGuess:OnClickMiniNumBg()
	GF.OpenWnd("UIGuernPop")
end
function UIringPkGuess:InitData()

	self._oddsSliderKey ="_oddsSliderKey"
	self._betSliderKey = "_betSliderKey"
	self._miniNumBgEffectName = "fx_ui_qiandao_lingqutishi"
	self._uiheadList = {}
	self._leftInputCoin = 0
	self._rightInputCoin = 0

	self._countDownKey = "_countDownKey"

	self._tips2Txts = {
		[1] = ccClientText(17548),
		[2] = ccClientText(17549),
		[3] = ccClientText(17550),
		[4] = ccClientText(17551)
	}
end

function UIringPkGuess:SetIcons()
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

function UIringPkGuess:CheckShowPlay()
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
function UIringPkGuess:OnGuessUpdate(pb)
	gModelArena:PinnaclePaceGuessMessageReq(2)
end
function UIringPkGuess:InitView()

	local str =ccClientText(11817)-- "竞猜"
	self:SetWndText(self.mTitle, str)
	self:SetIcons()

	self:TimerStop(self._countDownKey)
	self:TimerStart(self._countDownKey, 1, false, -1)
	self:SetStateTime()

	-- self:SetWndVisible(false)

	gModelArena:PinnaclePaceGuessMessageReq(2)
end
function UIringPkGuess:OnStateUpdate()

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
	else
		self._qotoWatch = false
	end


end

function UIringPkGuess:Watch()
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
		gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)
		GF.CloseWndByName("UIringPk")
	end



	return true
end
function UIringPkGuess:OnClickClose()
	self:WndClose()
end
function UIringPkGuess:OnClickReduce(type)
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

function UIringPkGuess:SetGuessIcon(tran)
	local item = gModelArena:GetArenaPeakRef("guessCoin")
	local itemId = string.split(item, "=")[2]
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(tran,iconPath)
end
function UIringPkGuess:SetFormation(playerTeam, playerData, heroData, playerType)
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
			itemNew.transform.localScale = Vector3.New(0.66, 0.66, 0)
			CS.ShowObject(itemNew, true)
			self:SetHero(itemNew.transform, heros[i], playerId)
		end
	end

	self:ShowSkillList(skillList, heroData.draconicStarRefIds, playerType)
end
function UIringPkGuess:ShowPlayerView(combatData)
	self:SetPlayer(self.mPlayer1, self.mPlayerTeam1, combatData.attack, combatData.attackHeros, 1)
	self:SetPlayer(self.mPlayer2, self.mPlayerTeam2, combatData.defense, combatData.defenseHeros, 2)

	local showPlay = self:CheckShowPlay()
	CS.ShowObject(self.mPlayerReportBtn, showPlay)
end
function UIringPkGuess:OnClickGuess(type)
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




------------------------------------------------------------------
return UIringPkGuess


