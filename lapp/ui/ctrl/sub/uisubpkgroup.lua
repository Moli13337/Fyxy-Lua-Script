---
--- Created by Administrator.
--- DateTime: 2023/10/23 16:25:53
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkGroup:LChildWnd
local UISubPkGroup = LxWndClass("UISubPkGroup", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkGroup:UISubPkGroup()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkGroup:OnWndClose()
	LxTimer.DelayTimeStop(self._delayShowResultTimer)
	if self._delayReqGuessMsg then
		LxTimer.DelayTimeStop(self._delayReqGuessMsg)
	end

	if self._uiGroupList then
		self._uiGroupList:OnWndClose()
	end

	if self._uiPlayerList then
		self._uiPlayerList:OnWndClose()
	end

	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkGroup:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkGroup:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()


	self:InitData()
	self:InitView()
	self:InitEvent()
end
function UISubPkGroup:OnPlayerItemDraw(list, item, playerInfo, itempos)
	local state = gModelArena:GetPeakCombatState()

	local sel = self:FindWndTrans(item,"sel")
	local name = self:FindWndTrans(item,"name")
	local guess = self:FindWndTrans(item,"guess")
	local score = self:FindWndTrans(item,"score")
	local scoreEn = self:FindWndTrans(item,"scoreEn")
	local rankIcon = self:FindWndTrans(item,"rankIcon")
	local headRoot = self:FindWndTrans(item,"head")
	local headIcon = self:FindWndTrans(headRoot,"HeadIcon")

	self:SetWndText(name, playerInfo.name)

	local isForeign = self._isForeign
	local str = playerInfo.score

	CS.ShowObject(scoreEn, isForeign)
	CS.ShowObject(score, not isForeign)
	if isForeign then
		self:SetWndText(scoreEn, str)
	else
		self:SetWndText(score, str)
	end

	-- if state == 3 then
	-- 	if playerInfo.playerId == self._leftPlayerId or playerInfo.playerId == self._rightPlayerId then
	-- 		CS.ShowObject(guess, true)
	-- 	else
	-- 		CS.ShowObject(guess, false)
	-- 	end
	-- else
	-- 	CS.ShowObject(guess, false)
	-- end

	-- if playerInfo.playerId == gLGameLogin:GetPlayerId() then
	-- 	CS.ShowObject(sel, true)
	-- elseif state == 3 then
	-- 	if playerInfo.playerId == self._leftPlayerId or playerInfo.playerId == self._rightPlayerId then
	-- 		CS.ShowObject(sel, true)
	-- 	else
	-- 		CS.ShowObject(sel, false)
	-- 	end
	-- else
	-- 	CS.ShowObject(sel, false)
	-- end

	local iconName = self._rankIcons[itempos]
	if iconName then
		CS.ShowObject(rankIcon, true)
		self:SetWndEasyImage(rankIcon, iconName)
	else
		CS.ShowObject(rankIcon, false)
	end

	-- headIcon
	local playerInfo = {
		trans = headIcon,
		playerId = playerInfo.playerId,
		name = playerInfo.name,
		icon = playerInfo.head,
		headFrame = playerInfo.headFrame or 20001,
		level = playerInfo.grade,
		noLv = true
	}
	self:SetWndClick(headIcon, function(...)
		gModelGeneral:PlayerShowReq(playerInfo.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)

	self:SetWndClick(item, function(...)
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
end

function UISubPkGroup:OnSelGroupIndex(groupIdx)
	if not groupIdx or groupIdx < 1 or groupIdx > 32 then
		printErrorN(string.format("OnSelGroupIndex %s",groupIdx))
		return
	end
	--local oldGroupIdx = self._groupInfoIndex
	self._groupInfoIndex = groupIdx
	--if oldGroupIdx then
	--	self._uiGroupList:DrawItemByKey(oldGroupIdx)
	--end
	--self._uiGroupList:DrawItemByKey(groupIdx)

	if self._uiGroupList then
		self._uiGroupList:DrawAllItems()
	end
	gModelArena:SetGroupInfoIndex(groupIdx)

	--local groupInfo = gModelArena:GetGroupInfo(groupIdx)
	--if groupInfo then
	--	self:RefreshPlayerList()
	--else
	gModelArena:OnPinnaclePaceGroupInfoReq(groupIdx)
	--end
end
function UISubPkGroup:OnPlayEnd(pagePara)
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIringPk",{page=pagePara.page,para =pagePara.para})
end
function UISubPkGroup:InitEvent()
	self:SetWndClick(self.mChangeBtn, function () self:OnClickChangeBtn() end,LSoundConst.CLICK_BUTTON_COMMON)

	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE, function ()
		local groupIdx = self._groupInfoIndex or 1
		gModelArena:OnPinnaclePaceGroupInfoReq(groupIdx)
	end)
	self:WndEventRecv(EventNames.ON_PEAK_GROUP_MESSAGE, function (group) self:OnUpdateGroupInfo(group) end)
end

function UISubPkGroup:InitView()
	local str =ccClientText(11896) --"每小组前两名进入32强赛"
	self:SetWndText(self.mInfo,str)

	self:SetWndText(self.mChangeTxt, ccClientText(17585))

	-- 初始化列表
	local uiList = self._uiPlayerList
	if(not uiList) then
		uiList = UIListWrap:New()
		uiList:Create(self, self.mPlayerList)
		uiList:SetFuncOnItemDraw(function(...) self:OnPlayerItemDraw(...) end)
		self._uiPlayerList = uiList
	end
	local uiGroupList = self._uiGroupList
	if(not uiGroupList) then
		uiGroupList = UIListEasy:New()
		uiGroupList:Create(self, self.mGroupList)
		uiGroupList:SetFuncOnItemDraw(function(...) self:OnGroupItemDraw(...) end)
		self._uiGroupList = uiGroupList
		uiGroupList:EnableScroll(true,false)
	end

	self:RefreshGroupList()
	self._groupInfoIndex = math.max(gModelArena:GetSelfGroupId(), 1)
	self:OnSelGroupIndex(self._groupInfoIndex)
	if self._groupInfoIndex > 5 then
		self:RefreshGroupList(self._groupInfoIndex)
	end

	local myGroupIndex = gModelArena:GetSelfGroupId()
	if myGroupIndex and myGroupIndex >= 1 then
		CS.ShowObject(self.mChangeBtn,true)
	end

end

function UISubPkGroup:OnGroupItemDraw(list, item, groupIdx, itempos)
	self:SetWndClick(item,function (...)
		self:OnSelGroupIndex(groupIdx)
	end)
	local state = gModelArena:GetPeakCombatState()
	local sel = self:FindWndTrans(item,"sel")
	local name = self:FindWndTrans(item,"name")
	local guess = self:FindWndTrans(item,"guess")
	local selfNode = self:FindWndTrans(item,"self")
	local selfText = self:FindWndTrans(selfNode,"selfText")

	local str = ccClientText(11897)
	self:SetWndText(name, string.replace(str, LStringUtil.NumberToCN(groupIdx)))
	str = ccClientText(11898)
	self:SetWndText(selfText, str)

	CS.ShowObject(sel, groupIdx == self._groupInfoIndex)
	-- CS.ShowObject(guess, groupIdx == gModelArena:GetGuessGroupId() and state == 3)
	CS.ShowObject(selfNode, groupIdx == gModelArena:GetSelfGroupId())
end
function UISubPkGroup:InitData()
	self._groupInfoIndex = gModelArena:GetGroupInfoIndex()
	self._groupGuessIndex = gModelArena:GetGuessGroupId()

	if self._groupInfoIndex < 1 then
		self._groupInfoIndex = 1
	end
	self._wndType = 2

	self._uiheadList = {}

	self._leftPlayerId = -1
	self._rightPlayerId = -1

	self._rankIcons = {
		[1] = "public_num_1",
		[2] = "public_num_2",
	}

	self._isForeign = gLGameLanguage:IsForeignRegion()

	self:InitTextLineWithLanguage(self.mInfo,-40)

end


function UISubPkGroup:RefreshPlayerList()
	local uiList = self._uiPlayerList
	if not uiList then
		return
	end
	local groupInfo = gModelArena:GetGroupInfo(self._groupInfoIndex)
	if not groupInfo then
		printErrorN(string.format("RefreshPlayerList %s",self._groupInfoIndex ))
		return
	end
	table.sort(groupInfo, function(a, b)
		if a.score == b.score  then
			return a.playerId > b.playerId
		else
			return a.score > b.score
		end

	end)
	uiList:RemoveAll()
	for i,playerData in ipairs(groupInfo) do
		uiList:AddData(i, playerData)
	end
	uiList:RefreshSimpleList()
end

function UISubPkGroup:IsTempReport(reportId)
	if not reportId or not self._leftPlayerId or not self._rightPlayerId then
		return true
	end
	local tempReportId1 = self._leftPlayerId.."_"..self._rightPlayerId
	local tempReportId2 = self._rightPlayerId.."_"..self._leftPlayerId
	if reportId == tempReportId1 or reportId == tempReportId2 then
		return true
	end
	return false
end
function UISubPkGroup:OnClickChangeBtn()

	local myGroupId = gModelArena:GetSelfGroupId()
	if myGroupId > 0 then
		if  myGroupId ~= self._groupInfoIndex then
			self:OnSelGroupIndex(myGroupId)
			self:RefreshGroupList(myGroupId)
		else
			local group = Mathf.Clamp(myGroupId,1,16)
			if self._uiGroupList then
				self._uiGroupList:DelayScrollTo(group,UIListEasy.SCROLL_TOP)
			end
		end
	end

end
function UISubPkGroup:RefreshGroupList(groupIdx)
	local uiGroupList = self._uiGroupList
	if not uiGroupList then
		return
	end

	uiGroupList:RemoveAllData()
	for i = 1, 32 do
		uiGroupList:AddData(i, i)
	end

	uiGroupList:RefreshList()

	if not groupIdx then
		return
	end

	if groupIdx < 1 then
		groupIdx = 1
	elseif groupIdx > 32 then
		groupIdx = 32
	end

	printInfoN("groupIdx "..groupIdx)
	uiGroupList:DelayScrollTo(groupIdx,UIListEasy.SCROLL_TOP)
end

function UISubPkGroup:Watch()
	if self:IsTempReport(self._reportId) then
		--self._delayReqGuessMsg = LxTimer.DelayTimeCall(function()
		--	if self._wndType then
		--		gModelArena:WeekChampGuessMessageReq(self._wndType)
		--	end
		--	self._delayReqGuessMsg = nil
		--end, 1)

		return false
	end

	local reportId = self._reportId
	local round =self._round
	if reportId then
		local canSkip = gModelArena:GetCombatIsEnd(round)
		local wnd = GF.FindFirstWndByName("UIringPk")
		local pagePara = wnd:GetPagePara()
		local combatExtraDatas = {
			battleEndfun = function() self:OnPlayEnd(pagePara)  end,
			canSkip = canSkip,
			meName = self._leftName,
			otherName = self._rightName,
			videoType = LVideoTypeConst.PEAK,

		}
		gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)
	end

	return true
end

--function UISubPkGroup:OnGuessMessageUpdate()
--	local pbData = gModelArena:GetGuessMessage()
--	local type = pbData.type
--	if not self._wndType or type ~= self._wndType then
--		return
--	end
--
--	if self._delayReqGuessMsg then
--		LxTimer.DelayTimeStop(self._delayReqGuessMsg)
--	end
--
--	local state = gModelArena:GetPeakCombatState()
--
--	self._guessMessage = pbData
--	local combatData = pbData.combat
--	self._serverId = combatData.serverId
--	self._reportId = combatData.reportId
--	self._round = combatData.round
--	self._leftName = combatData.attack.name
--	self._rightName = combatData.defense.name
--	self._leftPlayerId = combatData.attack.playerId
--	self._rightPlayerId = combatData.defense.playerId
--	self._winner = combatData.winner
--
--	local groupGuessIndex = self._groupGuessIndex
--	if groupGuessIndex then
--		self._uiGroupList:DrawItemByKey(groupGuessIndex)
--	end
--
--	---- 1.未开启，2.准备/布阵阶段 3.竞猜阶段，4.战斗阶段
--	--if state == 3 then
--	--	if self._groupInfoIndex >= 1 and self._groupInfoIndex <= 32 then
--	--		gModelArena:OnPinnaclePaceGroupInfoReq(self._groupInfoIndex)
--	--	end
--	--	return
--	--end
--	self:OnSelGroupIndex(self._groupInfoIndex)
--
--	---- 延迟60秒显示战斗结果
--	--local passTime = 999
--	---- 1.未开启，2.准备/布阵阶段 3.竞猜阶段，4.战斗阶段
--	--if state == 4 then
--	--	local totalTime = CrossChampConfigRef["combatTime"] or 0
--	--	passTime = totalTime - gModelArena:GetNextStateTime()
--	--	if passTime > 0 and passTime < 60 then
--	--		self._winner = 0
--	--		self._delayShowResultTimer = LxTimer.DelayTimeCall(function()
--	--			self._delayShowResultTimer = nil
--	--			self:OnGuessMessageUpdate()
--	--		end, 61 - passTime)
--	--	end
--	--end
--
--	local curRound = gModelArena:GetPeakRound()
--	if curRound == self._round then
--		local isWatched = gModelArena:CheckWatched(self._reportId)
--		if not isWatched then
--			self:Watch()
--			gModelArena:RecordWatched(self._reportId)
--		end
--	end
--end
function UISubPkGroup:OnUpdateGroupInfo(group)
	local myGroupIndex = gModelArena:GetSelfGroupId()
	if not myGroupIndex then
		printErrorN("myGroupIndex is nil ")
		return
	end
	CS.ShowObject(self.mChangeBtn, myGroupIndex > 0)

	self._groupGuessIndex = gModelArena:GetGuessGroupId()
	if self._uiGroupList then
		self._uiGroupList:DrawAllItems()
	end

	self._groupInfoIndex = group
	gModelArena:SetGroupInfoIndex(group)
	self:RefreshPlayerList()


end



------------------------------------------------------------------
return UISubPkGroup


