---
--- Created by Administrator.
--- DateTime: 2023/10/10 11:11:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkGuessForeign:LWnd
local UIPkGuessForeign = LxWndClass("UIPkGuessForeign", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

UIPkGuessForeign.ROW_GUESS_MAX_NUM = 2
UIPkGuessForeign.TYPE_BETTING_CAN_BET = 0 --投注期间，可投注
UIPkGuessForeign.TYPE_BETTING_HAD_BET = 1 --投注期间，已投注
UIPkGuessForeign.TYPE_PREPARE_HAD_BET = 2 --比赛期间，已投注，未出结果
UIPkGuessForeign.TYPE_PREPARE_NO_BET = 3 --比赛期间，未投注，未出结果
UIPkGuessForeign.TYPE_END_HAD_BET = 4 --已出结果，已投注
UIPkGuessForeign.TYPE_END_NO_BET = 5 --已出结果，未投注

UIPkGuessForeign.GUESS_NO_RESULT = 0 --竞猜未结算
UIPkGuessForeign.GUESS_RESULT_YES = 1 --竞猜正确,已结算
UIPkGuessForeign.GUESS_RESULT_NO = 2 --竞猜错误,已结算
UIPkGuessForeign.GUESS_RESULT_NO_BET = 3 --竞猜未投注,已结算
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkGuessForeign:UIPkGuessForeign()
	self._countDownKey = "_countDownKey"
	self._logSlideTimeKey = "_logSlideTimeKey"
	self._moveKey = "moveKey"
	self._logCellH = 40
	self._moveSpeed = 0.5
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkGuessForeign:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	self:ClearGuessInfo()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkGuessForeign:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkGuessForeign:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:InitView()
	self:InitStaticContent()
end

--######################################################################################################################
--## View ##############################################################################################################
--######################################################################################################################
function UIPkGuessForeign:RefreshGuessCoin()
	local globalGuessCoin = self:GetGlobalGuessCoin()
	local itemData = LxDataHelper.ParseItem_3(globalGuessCoin)
	local itemId   = itemData.itemId
	if not itemId then return end

	self._coinItemId = itemId
	local itemIcon = gModelItem:GetItemIconByRefId(itemId)
	self._globalGuessCoinIcon = itemIcon
	if LxUiHelper.IsImgPathValid(itemIcon) then
		self:SetWndEasyImage(self.mItemIcon, itemIcon, function()
			CS.ShowObject(self.mItemIcon, true)
		end)
	end

	self:RefreshGuessCoinNum()
end

function UIPkGuessForeign:OnDrawGuessListCell(list,item,itemdata,itempos)
	for i = 1, UIPkGuessForeign.ROW_GUESS_MAX_NUM do
		local guessItemTrans = self:FindWndTrans(item, "List/Guess"..i)
		if CS.IsValidObject(guessItemTrans) then
			local data = itemdata[i]
			CS.ShowObject(guessItemTrans, data ~= nil)
			if data then
				self:OnDrawGuessCell(guessItemTrans, data, i)
			end
		else
			printInfoNR("Guess"..i.." is not find, itempos = "..itempos)
		end
	end
end

function UIPkGuessForeign:RefreshGuessCoinNum()
	if not self._coinItemId then return end
	local haveItemNum = gModelItem:GetNumByRefId(self._coinItemId)
	self:SetWndText(self.mItemNumText, haveItemNum)
end

function UIPkGuessForeign:ClearGuessInfo()
	self:ClearCommonIconList(self._guessInfos)
	self._guessInfos = {}
end

function UIPkGuessForeign:OnClickBet(isYes,playerInfo)
	-- local bettingType = isYes and 1 or 2
	-- local noticeType = self._noticeType
	local playerId = playerInfo.playerId
	-- local playerName = playerInfo.name
	-- GF.OpenWnd("UIPkGuessBet", {
	-- 	noticeType = noticeType,
	-- 	betType = bettingType,
	-- 	playerId = playerId,
	-- 	playerName = playerName,
	-- 	wndRefId = 150007
	-- })
	GF.OpenWnd("UIPkGuessBet", { targetId = playerId })
end

function UIPkGuessForeign:InitEvent()
	self:WndEventRecv(EventNames.On_Item_Change,function () self:RefreshGuessCoinNum() end)
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE,function () self:OnStateUpdate() end)
	self:WndNetMsgRecv(LProtoIds.PinnacleGuessHistoryResp,function (...) self:OnPinnacleGuessHistoryResp(...) end)
	self:WndNetMsgRecv(LProtoIds.PinnaclePaceGuessResp,function (...) self:OnPinnaclePaceGuessResp(...) end)
end

function UIPkGuessForeign:GetShiftGuessInfoList()
	local infoList = self._guessInfos
	local guessNum = #infoList
	local rowNum = math.ceil(guessNum / 2)
	local list = {}
	for i = 1, rowNum do
		local haveTwoData = i % 2 == 0
		local curRowDataNum = haveTwoData and 2 or 1
		local tempIndex = i % 3 - 1
		local data = {}
		for k = 1, curRowDataNum do
			local guessKey = k + tempIndex
			table.insert(data, infoList[guessKey])
		end
		table.insert(list, data)
	end

	return list
end

--######################################################################################################################
--## Tween #############################################################################################################
--######################################################################################################################
function UIPkGuessForeign:MovePage(moveY,moveTime)
	local logCellList = self._logCellList
	if not logCellList then
		return
	end

	local seqTween
	self:TweenSeqKill(self._moveKey)

	local list = self._guessInfoList
	local index = self._logIndex + 1
	if index > #list then
		index = 1
	end
	self._logIndex = index
	local log = list[index]
	local cellMaxNum = #logCellList
	self:SetLogItem(logCellList[cellMaxNum],log)

	if not seqTween then
		seqTween = self:TweenSeqCreate(self._moveKey,function(seq)
			for i, v in ipairs(logCellList) do
				CS.ShowObject(v,true)
				local vec = Vector2.New(v.localPosition.x,v.localPosition.y + moveY)
				local tweener = v:DOLocalMove(vec,moveTime)
				seq:Join(tweener)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._moveKey)
		local transList = {}
		local oneTrans = logCellList[1]
		for i = 1, 4 do
			transList[i] = logCellList[i+1]
		end
		transList[5] = oneTrans
		self._logCellList = transList
		local endTrans = self._logCellList[4]
		self._logCellList[5].localPosition = Vector2.New(endTrans.localPosition.x,endTrans.localPosition.y - self._logCellH)
	end)
end

function UIPkGuessForeign:GetGuessConditionAndOdds(noticeType, refId)
	-- local ref = gModelArena:GetArenaGuessConditionRef(refId)
	-- if not ref then
	-- 	printInfoNR("GameTable.ArenaGuessConditionRef[key] is not find, key = "..refId)
		return "", 0, 0
	-- end

	-- return ccLngText(ref.des), ref.conditionOdds1, ref.conditionOdds2
end

--######################################################################################################################
--## Time ##############################################################################################################
--######################################################################################################################
function UIPkGuessForeign:SetStateTime()
	local timeLeft = self:GetTimeLeft()
	local timeStr = nil
	if timeLeft > 0 and self._combatState == ModelArena.PEAK_BATTLE_STATE_BETTING then
		timeStr = LUtil.FormatTimespanNumber(timeLeft)
		timeStr = LUtil.FormatColorStr(timeStr,"lightGreen")
		timeStr = string.replace(ccClientText(11833), timeStr)
	else
		timeStr = ccClientText(27402)
		timeStr = LUtil.FormatColorStr(timeStr,"lightRed")
		self:TimerStop()
	end

	self:SetWndText(self.mTimeText, timeStr)
end

function UIPkGuessForeign:OnClickClose()
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIringPk", {jumpPeakStagePage = true})
	self:WndClose()
end

function UIPkGuessForeign:OnPinnaclePaceGuessResp(pbData)
	if self._noticeType ~= ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then
		return
	end
	self:OnGuessHistoryReq()
end

--######################################################################################################################
--## Common ############################################################################################################
--######################################################################################################################
function UIPkGuessForeign:OnStateUpdate()
	self._combatState = self:GetPeakCombatState()
	self:TimerStop(self._countDownKey)
	self:TimerStart(self._countDownKey, 1, false, -1)
	self:SetStateTime()

	self:OnGuessHistoryReq()
end

function UIPkGuessForeign:InitView()
	self:TimerStop(self._countDownKey)
	self:TimerStart(self._countDownKey, 1, false, -1)
	self:SetStateTime()
	self:RefreshGuessCoin()
	self:SetWndVisible(false)
	self:ShowBarrage(self._isBarrageShow)
	self:OnGuessHistoryReq()
	gModelArena:PinnaclePaceStateReq()
end

function UIPkGuessForeign:OnClickRecord()
	GF.OpenWnd("UIPkGuessRecord", {noticeType = self._noticeType})
end

function UIPkGuessForeign:GetFakeGuessInfo()
	local name = gModelPlayer:GetFakeReName(false)
	local targetNameIndex = math.random(1,#self._guessInfos)
	local guessInfo = self._guessInfos[targetNameIndex]
	local targetInfo = guessInfo:GetTargetInfo()
	local targetServerData = targetInfo:GetServerData()

	local globalGuessCoinMax = self._globalGuessCoinMax
	if not globalGuessCoinMax then
		globalGuessCoinMax = gModelArena:GetArenaPara("globalGuessCoinMax") / 10
		self._globalGuessCoinMax = globalGuessCoinMax
	end

	local data = {
		name = name,
		targetName = targetServerData.name,
		itemNum = math.random(1,globalGuessCoinMax) * 10,
	}

	return data
end

function UIPkGuessForeign:AddFakeGuessInfoList()
	math.randomseed(tostring(os.time()):reverse():sub(1, 7))
	local needFakeNum = 6 - #self._guessInfoList
	for i = 1, needFakeNum do
		table.insert(self._guessInfoList, self:GetFakeGuessInfo())
	end
end

function UIPkGuessForeign:OnClickBarrageInput()
	local para = {channel = ModelChat.CHANNEL_PEAK,isShow = self._isBarrageShow}
	gModelChat:OnClickOpentBarrageWin(para)
end

function UIPkGuessForeign:OnPinnacleGuessHistoryResp(pbData)
	if self._noticeType ~= ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then return end
	if pbData.type ~= 0 then return end

	--竞猜历史请求返回(巅峰赛)
	self:SetWndVisible(true)

	self:RefreshArenaGuessData(pbData)
	self:RefreshNotice()
	self:RefreshGuessList()
end

function UIPkGuessForeign:GetPeakState()
	return gModelArena:GetPeakState()
end

function UIPkGuessForeign:SetTransYesOrNo(trans, obbs,playerInfo, isYesTrans)
	local text = self:FindWndTrans(trans, "TextContent/Text")
	local btn  = self:FindWndTrans(trans, "Btn")

	local colorKey = isYesTrans and "green" or "red"
	local obbsStr = LUtil.FormatColorStr(obbs,colorKey)
	local str  = string.replace(ccClientText(27404), obbsStr)
	self:SetWndText(text, str)
	str = isYesTrans and ccClientText(27405) or ccClientText(27406)
	self:SetWndButtonText(btn, str)
	self:SetWndClick(btn, function()
		self:OnClickBet(isYesTrans, playerInfo)
	end)
end

function UIPkGuessForeign:OnClickBackPlay(guessInfo)
	local reportId= guessInfo:GetReportId()
	if string.isempty(reportId) then return end

	local noticeType = self._noticeType
	local targetInfo = guessInfo:GetTargetInfo()
	local targetServerData = targetInfo:GetServerData()
	local playerId = targetServerData.playerId
	local name = targetServerData.name
	local serverId =targetServerData.serverId

	local wndName = "UIringPk"
	local wnd = GF.FindFirstWndByName(wndName)
	local pagePara = wnd:GetPagePara()

	local videoType = self._videoTypeList[noticeType]

	local combatExtraDatas = {
		battleEndfun = function()
			self:OnPlayEnd(pagePara)
		end,
		canSkip = true,
		meName = name,
		otherName = "",
		videoType = videoType,
		serverId = serverId,
	}
	gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)
end

function UIPkGuessForeign:OnClickDetails(playerInfo)
	GF.OpenWnd("UIPkPerDetails",{noticeType = self._noticeType, playerInfo = playerInfo})
end

--######################################################################################################################
--## NoticeScroll ######################################################################################################
--######################################################################################################################
function UIPkGuessForeign:RefreshNotice()
	local list = self._guessInfoList
	local len = #list
	local isShow = len > 0
	CS.ShowObject(self.mLogSuper,isShow)
	if not isShow then return end

	local logCellList = self._logCellList
	if not logCellList then
		logCellList = {}
		for i = 1, 5 do
			local cell = CS.FindTrans(self.mLogSuper,"LogCell"..i)
			table.insert(logCellList,cell)
		end
		self._logCellList = logCellList
	end

	local logIndex = 0
	local cellLen = #logCellList

	for i = 1, cellLen do
		local log = list[i]
		local v = logCellList[i]
		if log and v then
			self:SetLogItem(v, log, i)
			logIndex = i
			CS.ShowObject(v,true)
		elseif v then
			CS.ShowObject(v,false)
		end
	end

	self._logIndex = logIndex
	if logIndex > 4 then
		if not self:IsTimerExist(self._logSlideTimeKey)then
			local globalGuessRoll = self:GetGlobalGuessRoll()
			self:TimerStart(self._logSlideTimeKey,globalGuessRoll,false,-1)
		end
	end
end

function UIPkGuessForeign:SetLogItem(item, itemdata, itempos)
	local contentTrans = self:FindWndTrans(item, "Content")
	local text = self:FindWndTrans(contentTrans,"UIText")
	local text2 = self:FindWndTrans(contentTrans,"UIText2")
	local itemImg = self:FindWndTrans(contentTrans, "ItemImg")
	local itemNum = self:FindWndTrans(contentTrans, "ItemNum")
	local playerName = itemdata.name
	local targetName = itemdata.targetName
	local itemNumStr = itemdata.itemNum

	local str = string.replace(ccClientText(27420),playerName,targetName)
	self:SetWndText(text,str)
	self:SetWndText(text2, self._logText2Str)
	self:SetWndEasyImage(itemImg, self._globalGuessCoinIcon)
	self:SetWndText(itemNum, itemNumStr)
end

--######################################################################################################################
--## Server ############################################################################################################
--######################################################################################################################
function UIPkGuessForeign:OnGuessHistoryReq()
	gModelArena:OnPinnacleGuessHistoryReq(0)
end

function UIPkGuessForeign:OnClickHelp()
	GF.OpenWndUp("UIBzTips",{refId = 137})
end

function UIPkGuessForeign:OnTimer(key)
	if self._countDownKey == key then
		self:SetStateTime()
	elseif self._logSlideTimeKey == key then
		self:MovePage(self._logCellH,self._moveSpeed)
	end
end

function UIPkGuessForeign:InitData()
	--self._noticeType = self:GetWndArg("noticeType") or ModelGeneral.NOTICE_ARENAPEAK_FOREIGN
	self._noticeType = ModelGeneral.NOTICE_ARENAPEAK_FOREIGN

	self._uiheadList = {}
	self._guessInfos = {}
	self._guessInfoList ={}

	self._tapImgPathList = {
		[UIPkGuessForeign.GUESS_RESULT_YES] = "actionarena_txt_9",
		[UIPkGuessForeign.GUESS_RESULT_NO] = "actionarena_txt_12",
		[UIPkGuessForeign.GUESS_RESULT_NO_BET] = "actionarena_txt_10",
	}

	self._maskImgPathList = {
		[UIPkGuessForeign.GUESS_RESULT_YES] = "actionarena_txt_9",
		[UIPkGuessForeign.GUESS_RESULT_NO] = "actionarena_txt_12",
		[UIPkGuessForeign.GUESS_RESULT_NO_BET] = "actionarena_txt_10",
	}

	self._videoTypeList = {
		[ModelGeneral.NOTICE_ARENAPEAK_FOREIGN] = LVideoTypeConst.PEAK,
		[ModelGeneral.NOTICE_CHAMPION_FOREIGN] = LVideoTypeConst.CHAMPION,
	}

	self._peakState = self:GetPeakState()
	self._combatState = self:GetPeakCombatState()

	local noticeType = self._noticeType
	local titleStr
	if noticeType == ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then
		titleStr = ccClientText(27400)
	else
		titleStr = ccClientText(27401)
	end
	self._titleStr = titleStr
	self._logText2Str = ccClientText(27427)

	local channel = ModelChat.CHANNEL_PEAK
	self._isBarrageShow = gModelChat:GetBarrageIsShow(channel)
end

function UIPkGuessForeign:OnPlayEnd(pagePara)
	GF.ChangeMap("LCityMap")

	GF.OpenWndBottom("UIringPk",{page=pagePara.page,para =pagePara.para})
	GF.OpenWnd("UIPkGuessForeign")
end

function UIPkGuessForeign:GetTimeLeft()
	local endTime = gModelArena:GetNextCombatStateTime()
	return math.floor(endTime - GetTimestamp())
end

function UIPkGuessForeign:OnDrawGuessCell(item,itemdata, guessIndex)
	local contentTrans = self:FindWndTrans(item, "Content")
	local nameText = self:FindWndTrans(contentTrans,"NameText")
	local headIcon = self:FindWndTrans(contentTrans,"HeadIcon")
	local btnDetails = self:FindWndTrans(contentTrans, "BtnDetails")
	local desc = self:FindWndTrans(contentTrans, "Desc")
	local tagImg = self:FindWndTrans(contentTrans, "TagImg")
	local yesTrans = self:FindWndTrans(contentTrans, "Bottom/Yes")
	local noTrans = self:FindWndTrans(contentTrans, "Bottom/No")
	local resultTrans = self:FindWndTrans(contentTrans, "Bottom/Result")

	local guessInfo = itemdata
	local targetInfo = guessInfo:GetTargetInfo()
	local targetServerData = targetInfo:GetServerData()
	local guessCondition = guessInfo:GetGuessCondition()
	local playerId = targetServerData.playerId
	local name = targetServerData.name
	local serverId =targetServerData.serverId
	local serverName = gLGameLogin:GetServerShotNameById(serverId)
	local descStr, obbs1, obbs2 = self:GetGuessConditionAndOdds(self._noticeType, guessCondition)
	local nameStr = string.replace(ccClientText(27421), serverName, name)
	self:SetWndText(nameText, nameStr)
	self:SetWndText(desc, descStr)

	local playerInfo = {
		trans = headIcon,
		playerId = playerId,
		name = name,
		icon = targetServerData.head,
		headFrame = targetServerData.headFrame or 20001,
		level = targetServerData.grade,
		power = targetServerData.power,
		figure = targetServerData.figure,
	}
	local uiheadlist = self._uiheadList
	local InstanceID = headIcon:GetInstanceID()
	local headIconClass = uiheadlist[InstanceID]
	if not headIconClass then
		headIconClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = headIconClass
	end
	headIconClass:SetHeadData(playerInfo)
	headIconClass:RefreshUI()

	self:SetWndClick(headIcon, function(...)
		self:OnClickHeroIcon(playerId)
	end)

	self:SetWndClick(btnDetails, function()
		self:OnClickDetails(playerInfo)
	end)

	local combatState = self._combatState
	local resultObbs   = guessInfo:GetOdds()
	local guessCoin = guessInfo:GetGuessCoin()
	local isBet = guessCoin > 0
	local guessState
	if combatState == ModelArena.PEAK_BATTLE_STATE_BETTING then
		guessState = isBet and UIPkGuessForeign.TYPE_BETTING_HAD_BET or UIPkGuessForeign.TYPE_BETTING_CAN_BET
	else
		if resultObbs == UIPkGuessForeign.GUESS_NO_RESULT then
			guessState = isBet and UIPkGuessForeign.TYPE_PREPARE_HAD_BET or UIPkGuessForeign.TYPE_PREPARE_NO_BET
		else
			guessState = isBet and UIPkGuessForeign.TYPE_END_HAD_BET or UIPkGuessForeign.TYPE_END_NO_BET
		end
	end

	local showYes = guessState == UIPkGuessForeign.TYPE_BETTING_CAN_BET
	local showNo = guessState == UIPkGuessForeign.TYPE_BETTING_CAN_BET
	local showResult = guessState ~= UIPkGuessForeign.TYPE_BETTING_CAN_BET
	local showTag = guessState == UIPkGuessForeign.TYPE_END_HAD_BET or guessState == UIPkGuessForeign.TYPE_END_NO_BET

	if showYes then
		self:SetTransYesOrNo(yesTrans, obbs1,playerInfo, true)
	end
	CS.ShowObject(yesTrans, showYes)

	if showNo then
		self:SetTransYesOrNo(noTrans, obbs2,playerInfo, false)
	end
	CS.ShowObject(noTrans, showNo)

	if showResult then
		self:SetTransResult(resultTrans, guessInfo, guessState, guessIndex)
	end
	CS.ShowObject(resultTrans, showResult)

	if showTag then
		local tagImgPath = self._tapImgPathList[resultObbs]
		if LxUiHelper.IsImgPathValid(tagImgPath) then
			self:SetWndEasyImage(tagImg, tagImgPath)
		end
	end
	CS.ShowObject(tagImg, showTag)
end

function UIPkGuessForeign:OnClickHeroIcon(playerId)
	gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
end

function UIPkGuessForeign:RefreshGuessList()
	self._peakState = self:GetPeakState()
	self._combatState = self:GetPeakCombatState()
	local list = self:GetShiftGuessInfoList()
	local uiGuessList = self._uiGuessList
	if uiGuessList then
		uiGuessList:RefreshData(list)
	else
		uiGuessList = self:GetUIScroll("uiGuessList")
		self._uiGuessList = uiGuessList
		uiGuessList:Create(self.mGuessList,list,function(...) self:OnDrawGuessListCell(...) end,UIItemList.WRAP, false)
		uiGuessList:EnableLoadAnimation(true, 0.03, 1, 2)
		local uiList = uiGuessList:GetList()
		uiList:RefreshList(UIListWrap.RefreshMode.Solid)
	end
end

function UIPkGuessForeign:ShowBarrage(bool)
	-- if(bool)then
	-- 	gModelGeneral:OpenBarrage({channel = ModelChat.CHANNEL_PEAK})
	-- else
	-- 	GF.CloseWndByName("UIBulletSay")
	-- end
end

function UIPkGuessForeign:GetGlobalGuessCoin()
	return gModelArena:GetArenaPara("globalGuessCoin")
end

function UIPkGuessForeign:SetItemAlpha(item,alpha)
	if not item then
		return
	end
	local text = self:FindWndTrans(item,"UIText")
	local canvasGroup = text:GetComponent(typeofCanvasGroup)
	if canvasGroup then
		canvasGroup.alpha = alpha
	end
end

function UIPkGuessForeign:OnClickShare(shareBtn, guessIndex, guessInfo)
	local targetInfo = guessInfo:GetTargetInfo()
	local targetServerData = targetInfo:GetServerData()

	local noticeType = self._noticeType
	local titleStr = self._titleStr
	local shareData = {
		noticeType = noticeType,
		titleStr = titleStr,
		targetName = targetServerData.name,
	}

	local jsonStr = JSON.encode(shareData)

	local data = {
		root = shareBtn,
		showRight = guessIndex == 1,
		shareType = ModelChat.CHATSHARE_FOREIGN_PEAK_GUESS,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end

function UIPkGuessForeign:RefreshArenaGuessData(pbData)
	self:ClearGuessInfo()
	for k,v in ipairs(pbData.infos) do
		local arenaCombatInfo = StructArenaGuessInfo:New()
		arenaCombatInfo:CreateByPb(v)
		table.insert(self._guessInfos, arenaCombatInfo)
	end

	self._guessInfoList ={}
	for k,v in ipairs(pbData.guessInfos) do
		local guessInfo = string.split(v, '|')
		local data = {
			name = guessInfo[1],
			targetName = guessInfo[2],
			itemNum = guessInfo[3],
		}

		table.insert(self._guessInfoList, data)
	end

	if #self._guessInfoList < 6 then
		--轮播数据不够时，做假数据
		self:AddFakeGuessInfoList()
	end
end

function UIPkGuessForeign:GetPeakCombatState()
	return gModelArena:GetPeakCombatState()
end

function UIPkGuessForeign:InitMsg()
	self:SetWndClick(self.mBtnHelp,function() self:OnClickHelp() end, LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mBtnClose,function () self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnRecord, function() self:OnClickRecord() end, LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mBarrageInputBtn,function () self:OnClickBarrageInput() end)
end

function UIPkGuessForeign:GetGlobalGuessRoll()
	return gModelArena:GetArenaPara("globalGuessRoll")
end

function UIPkGuessForeign:SetTransResult(trans, guessInfo, guessState, guessIndex)
	local btn = self:FindWndTrans(trans, "Btn")
    local btnMask = self:FindWndTrans(trans, "BtnMask")
	local maskImg = self:FindWndTrans(trans, "MaskImg")
    local textContent = self:FindWndTrans(trans, "TextContent")
    local text2 = self:FindWndTrans(textContent, "Text2")
    local iconTrans = self:FindWndTrans(textContent, "Icon")
	local text1 = self:FindWndTrans(textContent, "Text")
	local btnShare = self:FindWndTrans(trans, "BtnShare")
	local btnPlay = self:FindWndTrans(trans, "BtnPlay")


	local resultObbs   = guessInfo:GetOdds()

	local showBtn = false --guessState == UIPkGuessForeign.TYPE_BETTING_HAD_BET
	local showBtnMask = guessState == UIPkGuessForeign.TYPE_BETTING_HAD_BET
			or guessState == UIPkGuessForeign.TYPE_PREPARE_HAD_BET
	local showNoBetImg = guessState == UIPkGuessForeign.TYPE_PREPARE_NO_BET
	local showBetCoin = guessState == UIPkGuessForeign.TYPE_BETTING_HAD_BET
			or guessState == UIPkGuessForeign.TYPE_PREPARE_HAD_BET
			or guessState == UIPkGuessForeign.TYPE_END_HAD_BET
	local showText1 = showBetCoin
	local showText2 = guessState == UIPkGuessForeign.TYPE_END_HAD_BET
	local showShare = guessState == UIPkGuessForeign.TYPE_BETTING_HAD_BET
			or guessState == UIPkGuessForeign.TYPE_PREPARE_HAD_BET
	local showPlay  = guessState == UIPkGuessForeign.TYPE_END_HAD_BET
			or guessState == UIPkGuessForeign.TYPE_END_NO_BET
	local showTextContent = showText1 or showText2

	if showBtn then
		self:SetWndButtonText(btn, ccClientText(27407))
		self:SetWndButtonGray(btn, true)
	end
	CS.ShowObject(btn, showBtn)

	if showBtnMask then
		local maskImgPath = "actionarena_txt_7"
		if LxUiHelper.IsImgPathValid(maskImgPath) then
			local btnMaskImg = self:FindWndTrans(btnMask, "BtnMaskImg")
			self:SetWndEasyImage(btnMaskImg, maskImgPath,nil, true)
		end
	end
	CS.ShowObject(btnMask, showBtnMask)

	if showNoBetImg then
		local imgPath = "actionarena_txt_8"
		if LxUiHelper.IsImgPathValid(imgPath) then
			self:SetWndEasyImage(maskImg, imgPath,nil, true)
		end
	end
	CS.ShowObject(maskImg, showNoBetImg)

	if showBetCoin then
		local iconImg = self:FindWndTrans(iconTrans, "IconImg")
		self:SetWndEasyImage(iconImg, self._globalGuessCoinIcon)
	end
	CS.ShowObject(iconTrans, showBetCoin)

	local colorKey
	if resultObbs == UIPkGuessForeign.GUESS_RESULT_YES then
		colorKey = "green"
	elseif resultObbs == UIPkGuessForeign.GUESS_RESULT_NO then
		colorKey = "red"
	end

	if showText1 then
		local betCoinNum
		if resultObbs == UIPkGuessForeign.GUESS_RESULT_YES then
			betCoinNum = guessInfo:GetResult()
		else
			betCoinNum = guessInfo:GetGuessCoin() - guessInfo:GetBuffBack()
		end
		local textStr1 = colorKey and LUtil.FormatColorStr(betCoinNum,colorKey) or betCoinNum
		self:SetWndText(text1, textStr1)
	end
	CS.ShowObject(text1, showBetCoin)

	if showText2 then
		local textStr2 = resultObbs == UIPkGuessForeign.GUESS_RESULT_YES and ccClientText(27410) or ccClientText(27411)
		if colorKey then
			textStr2 = LUtil.FormatColorStr(textStr2,colorKey)
		end
		self:SetWndText(text2, textStr2)
	end
	CS.ShowObject(text2, showText2)

	if showShare then
		local shareTxt = self:FindWndTrans(btnShare, "Text")
		self:SetWndText(shareTxt, ccClientText(27409))
		self:SetWndClick(btnShare, function()
			self:OnClickShare(btnShare, guessIndex, guessInfo)
		end)
	end
	CS.ShowObject(btnShare, showShare)

	if showPlay then
		local playText = self:FindWndTrans(btnPlay, "Text")
		self:SetWndText(playText, ccClientText(27412))
		self:SetWndClick(btnPlay, function()
			self:OnClickBackPlay(guessInfo)
		end)
	end
	CS.ShowObject(btnPlay, showPlay)

	CS.ShowObject(textContent, showTextContent)
end

function UIPkGuessForeign:InitStaticContent()
	self:SetWndText(self.mTitleText, self._titleStr)
	self:SetWndText(self.mRecordText, ccClientText(27403))
	CS.ShowObject(self.mTop, true)

	local barrageText = CS.FindTrans(self.mBarrageInputBtn,"UIText")
	self:SetWndText(barrageText,ccClientText(10145))
end

------------------------------------------------------------------
return UIPkGuessForeign


