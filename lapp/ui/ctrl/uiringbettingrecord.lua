---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringBettingRecord:LWnd
local UIringBettingRecord = LxWndClass("UIringBettingRecord", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringBettingRecord:UIringBettingRecord()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringBettingRecord:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringBettingRecord:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringBettingRecord:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	self:InitList()
	self:SetStaticContent()
	self:WndNetMsgRecv(LProtoIds.PinnaclePaceGuessListResp, function(pb) self:OnPinnaclePaceGuessListResp(pb) end)
	gModelArena:PinnaclePaceGuessListReq(2)

	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
end

function UIringBettingRecord:SetPlayer(item, itemdata)
	local name = self:FindWndTrans(item, "name")
	local headIcon = self:FindWndTrans(item, "HeadIcon")
	local tag = self:FindWndTrans(item, "tag")
	local resultTag = self:FindWndTrans(item, "resultTag")
	local power = self:FindWndTrans(item, "power")

	self:SetWndText(name, itemdata.name)
	self:SetWndText(power, string.replace(ccClientText(17509), LUtil.PowerNumberCoversion(itemdata.power)))



	CS.ShowObject(tag, itemdata.isBet)
	if itemdata.battleResult == 0 then
		CS.ShowObject(resultTag, false)
	elseif itemdata.battleResult == 1 then
		CS.ShowObject(resultTag, true)
		self:SetWndEasyImage(resultTag, "kf_ladder_txt_3")
	elseif itemdata.battleResult == 2 then
		CS.ShowObject(resultTag, true)
		self:SetWndEasyImage(resultTag, "kf_ladder_txt_4")
	end

	-- headIcon
	local playerInfo = {
		trans = headIcon,
		playerId = itemdata.playerId,
		name = itemdata.name,
		icon = itemdata.head,
		headFrame = itemdata.headFrame or 20001,
		level = itemdata.grade
	}
	self:SetWndClick(headIcon, function(...)
		gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
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
end

function UIringBettingRecord:OnPlayEnd(pagePara, itempos)
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIringPk", { page = pagePara.page, para = pagePara.para })
	GF.OpenWnd("UIringBettingRecord", { itempos = itempos })
end

function UIringBettingRecord:InitScrollView(recordList)
	local itempos = self:GetWndArg("itempos") or 1

	if #recordList == 0 then
		CS.ShowObject(self.mNoRecord, true)
		CS.ShowObject(self.mRecordList, false)
		return
	end
	CS.ShowObject(self.mNoRecord, false)
	CS.ShowObject(self.mRecordList, true)

	local uiList = self:GetUIScroll("recordList")
	uiList:Create(self.mRecordList, recordList, function(...) self:OnDrawItem(...) end, UIItemList.SUPER)

	if itempos <= #recordList then
		uiList:MoveToPos(itempos)
	end
end

function UIringBettingRecord:Watch(itemdata, itempos)
	if not itemdata.canWatch then
		GF.ShowMessage(ccClientText(11882))
		return
	end
	local reportId = itemdata.reportId
	local round = itemdata.round
	if reportId then
		local canSkip = gModelArena:GetCombatIsEnd(round)
		local wnd = GF.FindFirstWndByName("UIringPk")
		local pagePara = wnd:GetPagePara()

		local state = gModelArena:GetPeakCombatState()
		local curRound = gModelArena:GetPeakRound()
		local passTime
		if state == ModelArena.PEAK_BATTLE_STATE_FIGHTING and curRound == round then
			passTime = math.ceil(gModelArena:GetNextCombatStateTime() - GetTimestamp()) + 1
		end
		local combatExtraDatas = {
			battleEndfun = function() self:OnPlayEnd(pagePara, itempos) end,
			canSkip = canSkip,
			--meName = itemdata.left.name,
			--otherName =itemdata.right.name,
			videoType = LVideoTypeConst.PEAK,
			waitEndPassTime = passTime or 0,
		}


		local videoPopPara =
		{
			videoInfo = itemdata.arenaCombatInfo,
			openEnum = ModelVideoCenter.OpenEnumArena,
			combatExtraDatas = combatExtraDatas
		}

		GF.OpenWnd("UIVdoPop", videoPopPara)

		--gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)
	end
end

function UIringBettingRecord:OnPinnaclePaceGuessListResp(pb)
	--local pb = gModelCrossServer:GetGuessRecordData()
	local guessInfos = {}
	for k, v in ipairs(pb.infos) do
		guessInfos[v.round] = v
	end

	local recordList = {}
	--local curStage = 0
	--local needTitle = {
	--	[1]=true,
	--	[2]=true,
	--	[3]=true
	--}

	local cnt = #pb.combatInfos
	for k = cnt, 1, -1 do
		local v = pb.combatInfos[k]
		local data = {}
		data.left = {}
		data.left.playerId = v.attack.playerId
		data.left.head = v.attack.head
		data.left.grade = v.attack.grade
		data.left.name = v.attack.name
		data.left.headFrame = v.attack.headFrame
		data.left.power = v.attack.power

		data.right = {}
		data.right.playerId = v.defense.playerId
		data.right.head = v.defense.head
		data.right.grade = v.defense.grade
		data.right.name = v.defense.name
		data.right.headFrame = v.defense.headFrame
		data.right.power = v.defense.power

		-- local isEnd = gModelArena:GetCombatIsEnd(v.round)
		-- local canWatch = self:CheckCanWatch(v.round)
		local canWatch = true

		local isEndRound = v.round < gModelArena:GetPeakRound() or gModelArena:GetPeakState() == 3
		if v.winner ~= 0 and isEndRound then
			-- local winner = isEnd and v.winner or 0
			local winner = v.winner
			if winner == 0 then
				data.left.battleResult = 0
				data.right.battleResult = 0
			elseif winner == 1 then
				data.left.battleResult = 1
				data.right.battleResult = 2
			elseif winner == 2 then
				data.left.battleResult = 2
				data.right.battleResult = 1
			end
			data.round = v.round
			data.guessResult = 0
			local guessInfo = guessInfos[v.round]
			if guessInfo then
				if guessInfo.targetId == v.attack.playerId then
					data.left.isBet = true
					if winner == 1 then
						data.guessResult = 1
					elseif winner == 2 then
						data.guessResult = 2
					end
				else
					data.right.isBet = true
					if winner == 2 then
						data.guessResult = 1
					elseif winner == 1 then
						data.guessResult = 2
					end
				end
				data.guessCoin = guessInfo.guessCoin
				data.gain = guessInfo.result
				data.buffBack = guessInfo.buffBack
			else
				data.guessCoin = 0
			end
			data.reportId = v.reportId
			data.serverId = v.serverId

			data.canWatch = canWatch

			local arenaCombatInfo = StructCombatResultInfo:New()
			arenaCombatInfo:CreateByPb(v)
			data.arenaCombatInfo = arenaCombatInfo

			table.insert(recordList, data)
		end
	end

	self:InitScrollView(recordList)
end

function UIringBettingRecord:InitList()
	-- local str = ccClientText(11866)
	-- self._roundStrList =
	-- {
	-- 	string.replace(str, ccClientText(11860)),
	-- 	string.replace(str, ccClientText(11861)),
	-- 	string.replace(str, ccClientText(11862)),
	-- 	string.replace(str, ccClientText(11863)),
	-- 	string.replace(str, ccClientText(11864)),
	-- 	string.replace(str, ccClientText(11865)),
	-- }
end

function UIringBettingRecord:SetItem(item, itemdata, itempos)
	local recordItem = self:FindWndTrans(item, "recordItem")
	local left = self:FindWndTrans(recordItem, "left")
	local right = self:FindWndTrans(recordItem, "right")
	local round = self:FindWndTrans(recordItem, "round")
	local result = self:FindWndTrans(recordItem, "result")
	local icon = self:FindWndTrans(result, "icon")
	local num = self:FindWndTrans(result, "num")
	local midBtn = self:FindWndTrans(recordItem, "midBtn")
	local midBtnText = self:FindWndTrans(midBtn, "text")
	local betInfo = self:FindWndTrans(recordItem, "betInfo")


	if self._isEnus then
		result.localPosition = Vector3.New(-30,54.7,0)
	end

	local item = gModelArena:GetArenaPeakRef("guessCoin")
	local itemId = string.split(item, "=")[2]
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(icon, iconPath)

	self:SetPlayer(left, itemdata.left)
	self:SetPlayer(right, itemdata.right)
	-- local stage = self:GetStageByRound(itemdata.round)
	local str = nil
	-- if stage == 1 then
	-- 	str = self._stageStrList[stage] .. self._roundStrList[itemdata.round]
	-- else
	str = gModelArena:GetPeakRoundStr(itemdata.round)
	-- end
	self:SetWndText(round, str)
	local resultStr = nil
	local betInfoStr = nil
	local showIcon = true
	local guessCoin = itemdata.guessCoin
	if guessCoin == 0 then
		betInfoStr = ccClientText(11867)
		showIcon = false
	else
		if itemdata.guessResult == 0 then
			resultStr = ccClientText(11868)
			self:SetWndText(num, guessCoin)
		elseif itemdata.guessResult == 1 then
			resultStr = ccClientText(11869)
			self:SetWndText(num, LUtil.FormatColorStr(itemdata.gain, "green"))
		elseif itemdata.guessResult == 2 then
			resultStr = ccClientText(11870)
			local resultCoin = guessCoin - itemdata.buffBack
			self:SetWndText(num, LUtil.FormatColorStr(resultCoin, "red"))
		end
	end
	if betInfoStr then
		self:SetWndText(betInfo, betInfoStr)
	end
	if resultStr then
		self:SetWndText(result, resultStr)
	end
	CS.ShowObject(betInfo, not showIcon)
	CS.ShowObject(result, showIcon)
	self:SetWndText(midBtnText, ccClientText(11844))
	self:SetWndClick(midBtn, function() self:Watch(itemdata, itempos) end)
end

function UIringBettingRecord:OnDrawItem(list, item, itemdata, itempos)
	self:SetItem(item, itemdata, itempos)
end

function UIringBettingRecord:SetStaticContent()
	local emptyList = self:GetCommonEmptyList("_empty")
	local data = {
		refId = 5004,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	emptyList:RefreshUI(data)

	self:SetWndText(self.mTitle, ccClientText(11823))
end

function UIringBettingRecord:CheckCanWatch(round)
	local isEnd = gModelArena:GetCombatIsEnd(round)
	if not isEnd then
		local curCombatState = gModelArena:GetPeakCombatState()
		if curCombatState <= ModelArena.PEAK_BATTLE_STATE_BETTING then
			return false
		end
	end

	return true
end

------------------------------------------------------------------
return UIringBettingRecord