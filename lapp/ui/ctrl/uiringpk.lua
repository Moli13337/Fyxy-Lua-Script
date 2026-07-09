---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringPk:LWnd
local UIringPk = LxWndClass("UIringPk", LWnd)
local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)


UIringPk.PAGE_MY_GAME = 1
UIringPk.PAGE_GROUP = 2
UIringPk.PAGE_32 = 3
UIringPk.PAGE_FINAL = 4


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringPk:UIringPk()
	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringPk:OnWndClose()
	--self:ModifyMainUI(1)
	-- self:ShowBarrage(false)

	self:OnClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringPk:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringPk:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self._curPageIndex = -1
	gModelArena:PinnaclePaceStateReq()
	self:InitList()
	self:InitUIEvent()
	self:InitEvent()
	self:InitTabList()
	self._isShowForeignGuess = false
	self:SetBtnList()
	self:RefreshState()
	local page = self:GetWndArg("page")
	self._para = self:GetWndArg("para")
	self._jumpPeakStagePage = self:GetWndArg("jumpPeakStagePage") or false

	if self._jumpPeakStagePage and not self._para then
		self:CheckChangePage()
		self._jumpPeakStagePage = false
	else
		if not page then
			page = 3
		end
		self:OpenPage(page)
	end

	self:InitCommand()

	self:ShowActivityPrivilege()
	self:RefreshForeign()
end

function UIringPk:InitCommand()
	self:SetTitle()
end

function UIringPk:IsCanOpenGuessPop()
	if self._isShowForeignGuess then
		local haveGuessInfo = not table.isempty(self._guessInfos)
		local peakState = gModelArena:GetPeakState()
		return peakState ~= ModelArena.PEAK_STATE_BEFORE and haveGuessInfo
	else
		return gModelArena:IsGuessStart()
	end
end

function UIringPk:SetBottomBtn(index, isSelect)
	-- local state = isSelect and LWnd.StateOn or LWnd.StateOff
	-- local btn = self._bottomBtnList[index]
	-- self:SetWndTabStatus(btn, state)
end

function UIringPk:OpenSchedule()
	self:SetBottomBtn(3, true)
	self:CreateChildWnd(self.mChildRoot, "UISubPkAllSchedule")
	self.cueOpenChild = "Schedule"
	CS.ShowObject(self.mRecordBtn, false)
	CS.ShowObject(self.mCombatStateBg, false)
	CS.ShowObject(self.mBtnList, true)
end

function UIringPk:OnClickPlayRecord()
	GF.OpenWnd("UIringPkRecord")
end

-- function UIringPk:OpenGroupPage()
-- 	self:SetBottomBtn(2, true)
-- 	self:ShowBettingRecordBtn()
-- 	self:CreateChildWnd(self.mChildRoot, "UISubPkGroup")
-- end

-- function UIringPk:OpenSchedule32()
-- 	self:SetBottomBtn(3, true)
-- 	self:ShowBettingRecordBtn()

-- 	self:CreateChildWnd(self.mChildRoot, "UISubPkSchedule", { groupIndex = self._para })
-- end

-- function UIringPk:OpenFinalSchedule()
-- 	self:SetBottomBtn(4, true)
-- 	self:ShowBettingRecordBtn()

-- 	self:CreateChildWnd(self.mChildRoot, "UISubPkFinal")
-- end

function UIringPk:HidePageByIndex(index)
	self:SetBottomBtn(index, false)
	self:CloseAllChild()
end

function UIringPk:OnDrawTab(_, item, data, index)
	self:SetWndTabText(item, data.name)
	self:SetWndTabStatus(item, index == self._curPageIndex and 0 or 1)
	if data.icon then
		local On = self:FindWndTrans(item,"On")
		local Off = self:FindWndTrans(item,"Off")
		self:SetWndEasyImage(On, data.icon)
		self:SetWndEasyImage(Off, data.icon)
	end
	self:SetWndClick(item, function()
		if data.func then
			data.func()
		end
	end)
end

function UIringPk:CheckShowGuessWnd()
	local curCombatState = gModelArena:GetPeakCombatState()
	if not self._curCombatState then
		self._curCombatState = curCombatState
		return
	end
	if self._curCombatState == curCombatState then
		return
	end

	if curCombatState ~= ModelArena.PEAK_BATTLE_STATE_BETTING then
		return
	end
	local includeWnd = {
		["UIringPk"] = true,
	}

	if not gLGameUI:IsCurMainClean(includeWnd) then
		return
	end


	GF.OpenWnd("UIringPkGuess")
end

function UIringPk:OnPinnaclePaceStateResp()
	self:RefreshState()
end

function UIringPk:InitList()
	local b1 = self:FindWndTrans(self.mBtnList, "button_1")
	local b2 = self:FindWndTrans(self.mBtnList, "button_2")

	self._btnList = {
		b1,
		b2,
	}
	-- local bb1 = self:FindWndTrans(self.mBottomBtnList, "BtnTab_1")
	-- local bb2 = self:FindWndTrans(self.mBottomBtnList, "BtnTab_2")
	-- local bb3 = self:FindWndTrans(self.mBottomBtnList, "BtnTab_3")
	-- local bb4 = self:FindWndTrans(self.mBottomBtnList, "BtnTab_4")
	-- self._bottomBtnList = {
	-- 	bb1,
	-- 	bb2,
	-- 	bb3,
	-- 	bb4,
	-- }
	-- self._bottomBtnParaList =
	-- {
	-- 	-- { ccClientText(11816), function() self:OpenPage(1) end },
	-- 	-- { ccClientText(17533), function() self:OpenPage(2) end },
	-- 	-- { ccClientText(11801), function() self:OpenPage(3) end },
	-- 	-- { ccClientText(17535), function() self:OpenPage(4) end },

	-- 	{ ccClientText(11860), function() self:OpenPage(1) end },
	-- 	{ ccClientText(11861), function() self:OpenPage(2) end },
	-- 	{ ccClientText(11862), function() self:OpenPage(3) end },
	-- }

	self.tabBtnData = {
		{
			name = ccClientText(11862),
			icon = "actionarena_vs",
			func = function()
				self:OpenPage(1)
			end
		},
		{
			name = ccClientText(11861),
			icon = "actionarena_guess2",
			func = function()
				self:OpenPage(2)
			end
		},
		{
			name = ccClientText(11860),
			icon = "actionarena_ting",
			func = function()
				self:OpenPage(3)
			end
		},
	}

	self._pageFuncs =
	{
		-- [1] =
		-- {
		-- 	pageOpen = function() self:OpenPageMyPlay() end,
		-- },
		-- [2] =
		-- {
		-- 	pageOpen = function() self:OpenGroupPage() end,
		-- },
		-- [3] =
		-- {
		-- 	pageOpen = function() self:OpenSchedule32() end,
		-- },
		-- [4] =
		-- {
		-- 	pageOpen = function() self:OpenFinalSchedule() end,
		-- },
		{ pageOpen = function() self:OpenSchedule() end },
		{ pageOpen = function() self:OpenGuess() end },
		{ pageOpen = function() self:OpenPageMyPlay() end },
	}

	self._btnDataList =
	{
		{ ccClientText(10372), function() self:OnClickRank(1) end }, --排行奖励
		{ ccClientText(10362), function() self:OnClickArenaShop() end }, --商店
	}

	self._titleStrList =
	{
		ccClientText(11816),
		ccClientText(17533),
		ccClientText(11801),
		ccClientText(17535),
	}

	self._combatStateStrList =
	{
		ccClientText(11824),
		ccClientText(11825),
		ccClientText(11826),
	}

	self._combatStateCountDown = "_combatStateCountDown"
	self._countDownKey = "_countDownKey"

	self._stageBelongPage =
	{
		[0] = 1,
		[ModelArena.PEAK_STAGE_SELECTION] = 2,
		[ModelArena.PEAK_STAGE_32] = 3,
		[ModelArena.PEAK_STAGE_16] = 3,
		[ModelArena.PEAK_STAGE_8] = 3,
		[ModelArena.PEAK_STAGE_SEMIFINAL] = 4,
		[ModelArena.PEAK_STAGE_FINAL] = 4,
	}
end

--------------------------
---page
function UIringPk:OpenPageMyPlay()
	self:SetBottomBtn(1, true)
	self:ShowGameRecordBtn()
	self:ShowMyPlayContent()
	self.cueOpenChild = "MyPlay"
	-- CS.ShowObject(self.mCombatStateBg, true)
	CS.ShowObject(self.mBtnList, true)
end

function UIringPk:ShowBettingOrDefendBtn()
	local showEff = false
	local isShowDefend = false
	if self._curPageIndex == 3 then
		isShowDefend = true
		showEff = gModelArena:CanChangeFormation()

		self:SetWndButtonGray(self.mDefendBtn, false)
		self:SetWndButtonText(self.mDefendBtn, ccClientText(11827)) --我的布阵
		self:SetWndClick(self.mDefendBtn, function() self:OnClickTipDefence() end)
		-- else
		-- 	local isOpenGuess = self:IsCanOpenGuessPop()
		-- 	isShowDefend = not self._isShowForeignGuess
		-- 	local str = ccClientText(17543) --"我要竞猜"
		-- 	if isShowDefend then
		-- 		self:SetWndButtonGray(self.mDefendBtn, not isOpenGuess)
		-- 		local combatState = gModelArena:GetPeakCombatState()
		-- 		showEff = combatState == ModelArena.PEAK_BATTLE_STATE_BETTING
		-- 		self:SetWndButtonText(self.mDefendBtn, str)
		-- 		self:SetWndClick(self.mDefendBtn, function() self:ShowBettingPop() end)
		-- 	else
		-- 		self:SetWndButtonGray(self.mDefendBtnEn, not isOpenGuess)
		-- 		local grayTrans = CS.FindTrans(self.mDefendBtnEn, "Gray")
		-- 		self:SetWndImageGray(grayTrans, not isOpenGuess)
		-- 		self:SetWndButtonText(self.mDefendBtnEn, str, nil, 0, -30)
		-- 		self:SetWndClick(self.mDefendBtnEn, function() self:ShowBettingPop() end)
		-- 	end
	end

	CS.ShowObject(self.mDefendBtn, isShowDefend)
	-- CS.ShowObject(self.mDefendBtnEn, not isShowDefend)

	if isShowDefend then
		if not showEff then
			self:DestroyWndEffectByKey("fx_shouchong_anniu_zhong")
		else
			self:CreateWndEffect(self.mDefendBtn, "fx_shouchong_anniu_zhong", "fx_shouchong_anniu_zhong", 100)
		end
	end
end

function UIringPk:InitUIEvent()
	self:SetWndClick(self.mCloseBtn, function()
        local backFunc = self:GetWndArg("backFunc")
        if not self:WndCloseAndBack() then
            if backFunc then
                backFunc()
                -- 【G公共支持】删除跨服天梯和跨服周冠玩法
                -- else
                -- 	if not isFromJump then
                -- 		gModelCrossServer:OpenUIring()
                -- 	end
            end
        else
            GF.OpenWndBottom("UIOutts", { childIndex = 2 })
        end
	end)

	-- local addSize = -2
	-- local addLine = -30
	-- if gLGameLanguage:IsThaiVersion() then
	-- 	addSize = -4
	-- 	addLine = -50
	-- end

	-- for i = 1, #self._bottomBtnList do
	-- 	local btn = self._bottomBtnList[i]
	-- 	local para = self._bottomBtnParaList[i]
	-- 	self:SetWndTabText(btn, para[1], addSize, addLine)
	-- 	self:SetWndClick(btn, para[2])
	-- end

	self:SetWndClick(self.mHelpBtn, function() self:ShowHelp() end)
end

function UIringPk:ShowBettingPop()
	local isOpen = self:IsCanOpenGuessPop()
	if isOpen then
		if self._isShowForeignGuess then
			GF.OpenWnd("UIPkGuessForeign", { noticeType = ModelGeneral.NOTICE_ARENAPEAK_FOREIGN })
		else
			GF.OpenWnd("UIringPkGuess")
		end
	else
		GF.ShowMessage(ccClientText(17539))
	end
end

function UIringPk:OpenPage(pageIndex)
	if self._curPageIndex == pageIndex then
		return
	end
	local oldPageIndex = self._curPageIndex
	self._curPageIndex = pageIndex
	if self.tabList then
		self.tabList:DrawAllItems()
	end
	if oldPageIndex == -1 then
		for k, v in ipairs(self._pageFuncs) do
			self:HidePageByIndex(k)
		end
	else
		self:HidePageByIndex(oldPageIndex)
	end


	local pageOpenFunc = self._pageFuncs[pageIndex].pageOpen
	if pageOpenFunc then
		pageOpenFunc()
	end

	self:ShowBettingOrDefendBtn()
end

function UIringPk:GetPagePara()
	local data =
	{
		page = self._curPageIndex,
		para = self._pagePara,
	}

	return data
end

function UIringPk:OnTimer(key)
	if self._combatStateCountDown == key then
		self:SetStateCountdown()
	end
end

function UIringPk:SetTitle()
	self:SetWndText(self.mTitle, ccClientText(11806))
	self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
end

function UIringPk:OnClickArenaShop()
	GF.OpenWndBottom("UIDian", { shopId = 2007 })
end

function UIringPk:InitTabList()
	if self.tabList then
		self.tabList:DrawAllItems()
	else
		self.tabList = self:GetUIScroll("TabScroll")
		self.tabList:Create(self.mTabScroll, self.tabBtnData, function(...) self:OnDrawTab(...) end)
	end
end

function UIringPk:OnClickBettingRecord()
	GF.OpenWnd("UIringBettingRecord")
end

function UIringPk:ShowBettingRecordBtn()
	local isShowForeignGuess = self._isShowForeignGuess
	--海外不显示 竞猜记录按钮，转移到海外竞猜界面中显示
	CS.ShowObject(self.mRecordBtn, not isShowForeignGuess)
	if isShowForeignGuess then
		return
	end

	local str = ccClientText(11823) -- "竞猜记录")
	local text = self:FindWndTrans(self.mRecordBtn, "text")
	self:SetWndText(text, str)
	self:SetWndClick(self.mRecordBtn, function() self:OnClickBettingRecord() end)
end
function UIringPk:ShowActivityPrivilege()
	local goldPrivileNum = 0
	local earningsPrivile = 0
	local dataList = gModelActivity:GetActPrivilegeList("privilegeShow6")
	for k, v in ipairs(dataList) do
		local ref = gModelGeneral:GetSysEffectRef(v)
		local effectValue = ref.effectValue
		goldPrivileNum = goldPrivileNum + tonumber(effectValue)
	end

	dataList = gModelActivity:GetActPrivilegeList("privilegeShow7")
	for k, v in ipairs(dataList) do
		local ref = gModelGeneral:GetSysEffectRef(v)
		local effectValue = ref.effectValue
		earningsPrivile = earningsPrivile + tonumber(effectValue)
	end

	if goldPrivileNum > 0 or earningsPrivile > 0 then
		local tipStr = ""
		local textStr = ""
		if goldPrivileNum > 0 then
			tipStr = string.replace(ccClientText(10375), goldPrivileNum)
			textStr = string.replace(ccClientText(10378), goldPrivileNum)
		end
		if earningsPrivile > 0 then
			if string.isempty(tipStr) then
				tipStr = string.replace(ccClientText(10376), earningsPrivile * 100)
			else
				tipStr = tipStr .. "\n" .. string.replace(ccClientText(10376), earningsPrivile * 100)
			end
			if string.isempty(textStr) then
				textStr = string.replace(ccClientText(10379), earningsPrivile * 100)
			else
				textStr = textStr .. "," .. string.replace(ccClientText(10379), earningsPrivile * 100)
			end
		end
		textStr = string.replace(ccClientText(10377), textStr)

		self:SetWndText(self.mPrivileText, textStr)
		CS.ShowObject(self.mPrivileText, true)

		local para = {
			title = ccClientText(10381),
			desc = tipStr,
			icon = "activity_spring3_icon_2",
		}
		local priviCom = self:GetActivityPrivilegeCom()
		priviCom:Create(self.mBtnPrivile, para, self)
	end
end

function UIringPk:OnClickRank(page)
	local rewardList = gModelArena:GetPeakRewardConfig()
	local dataList = {}
	for k, v in pairs(rewardList) do
		local itemdata = {}
		itemdata.index = k
		local cfg = gModelArena:GetRankArenaPeakAwardRefT(v.refId)
		local rankT = cfg.rankT
		itemdata.rank = { rankT.left, rankT.right }
		itemdata.reward = cfg.rewardT
		table.insert(dataList, itemdata)
	end
	table.sort(dataList, function(a, b) return a.index < b.index end)

	GF.OpenWndBottom("UIRkPop", { refId = ModelRank.RANK_HIGH_CHAMPION, page = page, rewardList = dataList })
end

function UIringPk:ShowMyPlayContent()
	local state = gModelArena:GetPeakState()
	local isIn = gModelArena:GetIsInCircle()

	local isPeakStateStared = state == ModelArena.PEAK_STATE_STARTED
	-- local isFirstRound = gModelArena:GetPeakRound() == 1
	-- local isFight = gModelArena:GetPeakCombatState() == 4
	-- if self._isShowForeignGuess then
	-- 	local combatState = gModelArena:GetPeakCombatState()
	-- 	isPeakStateStared = isPeakStateStared and combatState ~= ModelArena.PEAK_BATTLE_STATE_BETTING
	-- end

	local createChildName
	if isPeakStateStared and isIn  then
		createChildName = "UISubPkGame"
		-- if isFirstRound then
		-- 	createChildName = isFight and "UISubPkGame" or "UISubPkWait"
		-- end
	else
		createChildName = "UISubPkWait"
	end

	local childList = self:GetChildList()
	local haveChild = false
	for k, v in pairs(childList) do
		if k == createChildName then
			haveChild = true
			break
		end
	end

	if not haveChild then
		self:CloseAllChild()
		self:CreateChildWnd(self.mChildRoot, createChildName)
	end
end

function UIringPk:RefreshState()
	local state = gModelArena:GetPeakState()
	local stage = gModelArena:GetPeakStage()
	local combatState = gModelArena:GetPeakCombatState()
	local stageStr = nil
	local roundStr = nil

	-- if self._oldState and self._oldState ~= state then
	-- 	local pageIndex = self._curPageIndex
	-- 	local pageFun = self._pageFuncs[pageIndex]
	-- 	if pageFun then
	-- 		pageFun.pageOpen()
	-- 	end
	-- end
	-- self._oldState = state

	if state == ModelArena.PEAK_STATE_BEFORE then
		stageStr = ccClientText(11821)
		roundStr = ""
	elseif state == ModelArena.PEAK_STATE_STARTED then
		stageStr = gModelArena:GetPeakRoundStr(gModelArena:GetPeakRound())
		local postFix = ""
		-- local isInStage = gModelArena:IsInStageShow()
		if not gModelArena:IsInStageShow() then
			postFix = LUtil.FormatColorStr(string.replace(ccClientText(11875), stageStr), "#68e6ac")
		end
		-- if stage == ModelArena.PEAK_STAGE_SELECTION then
		-- 	local round = gModelArena:GetPeakRound()
		-- 	-- local totalRound = gModelArena:GetArenaPara("Round")
		-- 	stageStr = stageStr .. string.replace(ccClientText(11829), round)
		-- end

		stageStr = stageStr .. postFix

		-- self:CheckShowGuessWnd()

		-- if self._isShowForeignGuess and self._oldCombatState and self._oldCombatState ~= combatState then
		-- 	local pageIndex = self._curPageIndex
		-- 	local pageFun = self._pageFuncs[pageIndex]
		-- 	if pageFun then
		-- 		pageFun.pageOpen()
		-- 	end
		-- end
	elseif state == ModelArena.PEAK_STATE_END then
		stageStr = ccClientText(11830)
		stageStr = LUtil.FormatColorStr(stageStr, "#68e6ac")
	end
	self:SetWndText(self.mStage, stageStr)

	-- self:SetStateCountdown()
	-- if combatState >= ModelArena.PEAK_BATTLE_STATE_UNSTART then
	-- 	local endTime = gModelArena:GetNextCombatStateTime()
	-- 	local timeLeft = math.ceil(endTime - GetTimestamp())
	-- 	if timeLeft > 0 then
	-- 		self:TimerStop(self._combatStateCountDown)
	-- 		self:TimerStart(self._combatStateCountDown, 1, false, -1)
	-- 	end
	-- end
	self._oldCombatState = combatState

	self:CheckChangePage()

	self:ShowBettingOrDefendBtn()

	if self._isShowForeignGuess and state ~= ModelArena.PEAK_STATE_BEFORE then
		gModelArena:OnPinnacleGuessHistoryReq(0)
	end
end

function UIringPk:OnClickTipDefence()
	if not gModelArena:CanChangeFormation() then
		GF.ShowMessage(ccClientText(11881))
		return
	end

	local para = {
		setTargetType = LCombatTypeConst.COMBAT_ARENA_PEAK_ATTACK,
		returnFunc = function()
			FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.CITY)
			GF.ChangeMap("LCityMap")
			GF.OpenWndBottom("UIringPk")
		end,
		retAfterSet = true,
	}
	gModelFormation:OpenSetFormationWnd(para)

	self:WndClose()
end

------------------------------------
---page

function UIringPk:SetBtnList()
	for i = 1, #self._btnList do
		local tran = self._btnList[i]
		local para = self._btnDataList[i]
		local text = self:FindWndTrans(tran, "text")
		if para then
			CS.ShowObject(tran, true)
			self:SetWndText(text, para[1])
			self:SetWndClick(tran, para[2], LSoundConst.CLICK_BUTTON_COMMON)
		else
			CS.ShowObject(tran, false)
		end
	end
end

function UIringPk:OnPinnacleGuessHistoryResp(pbData)
	if pbData.type ~= 0 then return end

	self._guessInfos = {}
	for k, v in ipairs(pbData.infos) do
		table.insert(self._guessInfos, true)
	end

	self:IsCanOpenGuessPop()
end

function UIringPk:OnClose()
	if self._curPageIndex then
		self:HidePageByIndex(self._curPageIndex)
	end
end

function UIringPk:CheckChangePage()
	-- local state = gModelArena:GetPeakState()
	-- local curStage = nil
	-- if state == ModelArena.PEAK_STATE_BEFORE then
	-- 	curStage = 0
	-- else
	-- 	curStage = gModelArena:GetPeakStage()
	-- end

	-- local page = self._stageBelongPage[curStage] or 1
	-- if not self._curBelongPage and not self._jumpPeakStagePage then
	-- 	self._curBelongPage = page
	-- 	return
	-- end

	-- if self._curBelongPage == page and not self._jumpPeakStagePage then
	-- 	return
	-- end

	-- self._curBelongPage = page
	-- self:OpenPage(page)
end

function UIringPk:ShowHelp()
	local temp = tostring(gModelArena:GetArenaPara("GameDay"))
	local strs = string.split(temp, ";")
	local str1 = strs[1]
	local str2 = strs[2]
	-- local str3 = tostring(gModelArena:GetArenaPara("PlayerNum"))
	local str3 = ""
	-- local str4 = tostring(gModelArena:GetArenaPara("RankDeadLine"))
	local str4 = ""
	-- local str5 = tostring(gModelArena:GetArenaPara("GameTime"))
	local str5 = ""
	local str6 = tostring(gModelArena:GetArenaPara("Round"))
	-- local str7 = tostring(gModelArena:GetArenaPara("SummitScoreWin"))
	local str7 = ""
	-- local str8 = tostring(gModelArena:GetArenaPara("GuessCoin"))
	local str8 = ""

	local para = {
		str1, str2, str3, str4, str5, str6, str7, str8
	}
	GF.OpenWnd("UIBzTips", { refId = 9, para = para })
end

function UIringPk:OnClickPeakReward()
	self:OnClickRank(2)
end
function UIringPk:RefreshForeign()
	if self._isVie then
		self:InitTextSizeWithLanguage(self.mTitle,-4)
		local text = self:FindWndTrans(self.mRecordBtn, "text")
		self:InitTextLineWithLanguage(text,40)
	end
end

function UIringPk:SetStateCountdown()
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
				self:TimerStop(self._combatStateCountDown)
			end
		end
	end
	local isEmpty = string.isempty(combatStr)
	CS.ShowObject(self.mCombatState, not isEmpty)
	CS.ShowObject(self.mCombatStateBg, not isEmpty and self.cueOpenChild == "MyPlay")
	if isEmpty then
		return
	end
	self:SetWndText(self.mCombatState, combatStr)
end

function UIringPk:OpenGuess()
	self:SetBottomBtn(2, true)
	self:ShowBettingRecordBtn()
	self:CreateChildWnd(self.mChildRoot, "UISubPkGuess")
	self.cueOpenChild = "Guess"
	CS.ShowObject(self.mCombatStateBg, false)
	CS.ShowObject(self.mBtnList, false)
end

function UIringPk:ShowGameRecordBtn()
	local str = ccClientText(11820) --"比赛记录"
	local text = self:FindWndTrans(self.mRecordBtn, "text")
	self:SetWndText(text, str)
	self:SetWndClick(self.mRecordBtn, function() self:OnClickPlayRecord() end)
	CS.ShowObject(self.mRecordBtn, true)
end

function UIringPk:SavePagePara(para)
	self._pagePara = para
end

function UIringPk:InitEvent()
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE, function() self:RefreshState() end)
	self:WndNetMsgRecv(LProtoIds.PinnacleGuessHistoryResp, function(...) self:OnPinnacleGuessHistoryResp(...) end)
end

------------------------------------------------------------------
return UIringPk