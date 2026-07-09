---
--- Created by Administrator.
--- DateTime: 2023/10/20 14:14:59
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSuBreak:LChildWnd
local UISubSuBreak = LxWndClass("UISubSuBreak", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSuBreak:UISubSuBreak()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSuBreak:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSuBreak:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSuBreak:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitEvent()
	self:InitUIEvent()
	self:SetStaticContent()

    self:OnWndRefresh()

end

function UISubSuBreak:OnClickShare()

	if not self._playerData or not self._playerData.isIn then
		local str = ccClientText(25176) --"暂无成绩"
		GF.ShowMessage(str)
		return
	end

	local jsonStr = JSON.encode(self._playerData)
	local data =
	{
		root = self.mBtnShare,
		shareData = jsonStr,
		shareType = ModelChat.CHATSHARE_26
	}

	gModelGeneral:OpenShareTip(data)
end

function UISubSuBreak:OnDrawReport(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootBgImage = self:FindWndTrans(AniRoot,"BgImage")
	local AniRootTitle = self:FindWndTrans(AniRoot,"title")
	local AniRootTag = self:FindWndTrans(AniRoot,"tag")
	local AniRootScore = self:FindWndTrans(AniRoot,"score")
	local AniRootDetailPart = self:FindWndTrans(AniRoot,"detailPart")
	local detailPartName = self:FindWndTrans(AniRootDetailPart,"name")
	local detailPartReportBtn = self:FindWndTrans(AniRootDetailPart,"ReportBtn")
	local ReportBtnImage = self:FindWndTrans(detailPartReportBtn,"Image")
	local ReportBtnUIText = self:FindWndTrans(detailPartReportBtn,"UIText")
	local detailPartHeadRoot = self:FindWndTrans(AniRootDetailPart,"headRoot")
	local detailPartPower = self:FindWndTrans(AniRootDetailPart,"power")
	local AniRootEmptyTip = self:FindWndTrans(AniRoot,"emptyTip")
	local AniRootLine = self:FindWndTrans(AniRoot,"line")



	local isEmpty = itemdata:IsEmptyReport()

	CS.ShowObject(AniRootEmptyTip,isEmpty)
	CS.ShowObject(AniRootDetailPart,not isEmpty)

	local isWin = itemdata:IsWin()
	local iconpath = isWin and "settlement_txt_4" or "settlement_txt_5"

	self:SetWndEasyImage(AniRootTag,iconpath)

	local roundStr = string.replace(ccClientText(25197),(itemdata.round -1)%24 + 1)

	self:SetWndText(AniRootTitle,roundStr)

	local scoreChange = itemdata:GetScoreChange()
	local str = ""
	if scoreChange > 0 then
		str = string.replace(ccClientText(25198),scoreChange)
	elseif scoreChange <0 then
		str = string.replace(ccClientText(25199),math.abs(scoreChange))
	end
	self:SetWndText(AniRootScore,str)
	self:SetWndText(AniRootEmptyTip,ccClientText(25251))
	if isEmpty then
		return
	end

	local otherPlayer = itemdata:GetOtherPlayerInfo()
	local name = string.replace(ccClientText(25192),otherPlayer.serverName,otherPlayer.name)
	self:SetWndText(detailPartName,name)
	local powerStr = string.replace(ccClientText(25283),LUtil.NumberCoversion(otherPlayer.power))
	self:SetWndText(detailPartPower,powerStr)

	self:SetWndText(ReportBtnUIText,ccClientText(25114))

	local headTran = self:FindWndTrans(detailPartHeadRoot,"HeadIcon")
	local playerInfo =
	{
		trans = headTran,
		icon = otherPlayer.head,
		headFrame = otherPlayer.headFrame,
		level = otherPlayer.grade,
		func = function()
			gModelGeneral:PlayerShowReq(otherPlayer.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)


	self:SetWndClick(detailPartReportBtn,function () self:OpenReportDetail(itemdata) end)


end



function UISubSuBreak:ShowGameCountDown()

	local curState = gModelSimuFight:GetState()
	local isEnd = curState > ModelSimuFight.SCHEDULE_BREAKOUT

	if isEnd then
		local str =ccClientText(25139) -- "已结束"
		self:SetWndText(self.mTimeinfo,str)
		return false
	end

	if curState < ModelSimuFight.SCHEDULE_BREAKOUT then
		local str =ccClientText(25273) --"该赛程未开启"
		self:SetWndText(self.mTimeinfo,str)
		return false
	end

	local round = gModelSimuFight:GetRound()


	local timeLeft = gModelSimuFight:GetNextStageTime() - GetTimestamp()
	if timeLeft>= 0 then
		local str = gModelSimuFight:GetTimeShowFormat()
		local roundStr = string.replace(ccClientText(25321),round)
		local timeStr =roundStr..string.replace(str,LUtil.FormatTimespanNumber(timeLeft))
		self:SetWndText(self.mTimeinfo,timeStr)
		return true
	else
		self:SetWndText(self.mTimeinfo,ccClientText(25139))
		return false
	end


end


function UISubSuBreak:OnClickTopGroup(group)
	if self._curGroup == group then
		return
	end

	self._curGroup = group

	self:ReqBreakData()
	--self:RefreshContent()

end

function UISubSuBreak:RefreshGroupTypeBtnShow()
	local item = self.mBtnGroupType
	local btnOne = self:FindWndTrans(item,"btnOne")
	local btnTwo = self:FindWndTrans(item,"btnTwo")
	CS.ShowObject(btnOne,self._curGroup ==1)
	CS.ShowObject(btnTwo,self._curGroup ==2)
end

function UISubSuBreak:ShowBreakContent()

	local str =ccClientText(25274) --"赛程结束时，积分自动转化为“圣殿水晶”"
	if gModelSimuFight:GetState() > ModelSimuFight.SCHEDULE_GROUP_BATTLE then
		str = ccClientText(25275) --"积分已自动转化为“圣殿水晶”"
	end

	self:SetWndText(self.mIntro,str)

	self:InitTextLineWithLanguage(self.mIntro,-40)

	if not self._breakInfo then
		return
	end

	self:ShowRoundSelections()


	local isEmpty = self._breakInfo.rank < 0

	local tempStr = string.split(self._breakInfo.battle,"_")

	local winCnt = tempStr[1] and tonumber(tempStr[1]) or 0
	local totalCnt = tempStr[2] and tonumber(tempStr[2]) or 0
	local failCnt = totalCnt - winCnt
	local playerData =
	{
		isIn = not isEmpty,
		score = self._breakInfo.score,
		rank = self._breakInfo.rank,
		winCnt = winCnt,
		failCnt = failCnt,
	}

	local power =gModelPlayer:GetPlayerFightPower()
	local head = gModelPlayer:GetPlayerHead()
	local headFrame = gModelPlayer:GetPlayerHeadFrame()
	local level = gModelPlayer:GetPlayerLv()
	local name = gModelPlayer:GetPlayerName()
	local serverId = gModelPlayer:GetServerId()
	local serverName = gLGameLogin:GetServerShotNameById(serverId)

	playerData.power = math.floor(power)
	playerData.head = head
	playerData.headFrame = headFrame
	playerData.level = level
	playerData.name = name
	playerData.serverName = serverName
	playerData.playerId = gModelPlayer:GetPlayerId()
	self._playerData = playerData


	self:RefreshBtnFormationShow()
	self:ShowMyScore(playerData)


	self:RefreshReportShow()

	self:TimerStop(self._reportRefresh)

	local state = gModelSimuFight:GetState()
	if state ~= ModelSimuFight.SCHEDULE_BREAKOUT then
		return
	end
	self:TimerStart(self._reportRefresh,60,false,-1)

end

function UISubSuBreak:OnClickFormation()
    gModelSimuFight:OpenSetFormation()
end

function UISubSuBreak:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 108})
end

function UISubSuBreak:OnSimulateGroupInfoResp(pb)
	if pb.type ~= 0 then
		return
	end

	if self._curGroup == 0 then
		self._curGroup = pb.groupType
	end

	if self._curGroup ~= pb.groupType then
		return
	end

	if self._curRound ~= pb.round then
		return
	end

	self._breakInfo = pb

	self:ShowBreakContent()

	self:RefreshGroupTypeBtnShow()
end

function UISubSuBreak:OnClickTab(index)
	if self._curRound == index then
		return
	end

	self._curRound = index


	self:ReqBreakData()


end

function UISubSuBreak:ShowTimeContent()
	self:TimerStop(self._countDownKey)
	if self:ShowGameCountDown() then
		self:TimerStart(self._countDownKey,1,false,-1)
	end
end

function UISubSuBreak:RefreshBtnFormationShow()
	local isShow = true
	if not gModelSimuFight:IsInStage(ModelSimuFight.SCHEDULE_BREAKOUT,ModelSimuFight.BATTLE_READY) then
		isShow = false
	end

	if not self._playerData or not self._playerData.isIn then
		isShow = false
	end

	CS.ShowObject(self.mBtnFormation,isShow)
end

function UISubSuBreak:OnDrawTab(list,item,itemdata,itempos)
	local BtnTab = self:FindWndTrans(item,"BtnTab")

	self:SetWndTabText(BtnTab,itemdata.name, -4, -30)
	local isSel = itemdata.index == self._curRound

	local state = isSel and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(BtnTab,state)

	self:SetWndClick(BtnTab,function ()
		self:OnClickTab(itemdata.index)
	end)



end

function UISubSuBreak:ShowRoundSelections()
	local tabList = self:FindUIScroll("tabList")
	if not tabList then
		tabList = self:GetUIScroll("tabList")
		tabList:Create(self.mTabList,self._tabDataList,function (...) self:OnDrawTab(...)  end)
	else
		tabList:DrawAllItems(false)
	end
end

function UISubSuBreak:OpenReportDetail(itemdata)
    GF.OpenWnd("UIFightRecordMulti",{battleInfo = itemdata})
end

function UISubSuBreak:OnTimer(key)
	if self._countDownKey == key then
		self:ShowGameCountDown()
	elseif key == self._reportRefresh then
		self:RefreshReportShow()
	end
end



function UISubSuBreak:SetStaticContent()
	--local str = "巅峰组"
	--self:SetWndButtonText(self.mPeakBtn,str)
	--str = "精英组"
	--self:SetWndButtonText(self.mEliteBtn,str)
	local str = ccClientText(46009) --"布阵"
	self:SetTextTile(self.mBtnFormation,str)
	str = ccClientText(25148) --"分享"
	self:SetTextTile(self.mBtnShare,str)
	str = ccClientText(25126) --"排名"
	self:SetTextTile(self.mBtnRank,str)

	str = ccClientText(25187)--"我的成绩"
	self:SetWndText(self.mTitleText,str)

	str = ccClientText(25176)--"暂无成绩"
	self:SetWndText(self.mEmptyIntro,str)

	local uiText = self:FindWndTrans(self.mBtnFormation,"UIText")
	self:InitTextLineWithLanguage(uiText,-30)
	uiText = self:FindWndTrans(self.mBtnRank,"UIText")
	self:InitTextLineWithLanguage(uiText,-30)

    self._curGroup = 0
    self._curRound = 1

	self:ShowRoundSelections()

	local data = {
		refId = 25004,
		IntroTran = self:FindWndTrans(self.mEmptyList,"EmptyText"),--self.mEmptyText,
		TextBgTran = self:FindWndTrans(self.mEmptyList,"EmptyTextBg"),-- self.mEmptyTextBg,
		IconTran = self:FindWndTrans(self.mEmptyList,"EmptyIcon"), --self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("emptyList")
	emptyList:RefreshUI(data)


	local data = {
		refId = 25003,
		IntroTran = self:FindWndTrans(self.mNoReport,"EmptyText"),--self.mEmptyText,
		TextBgTran = self:FindWndTrans(self.mNoReport,"EmptyTextBg"),-- self.mEmptyTextBg,
		IconTran = self:FindWndTrans(self.mNoReport,"EmptyIcon"), --self.mEmptyIcon,
	}
	local emptyReport = self:GetCommonEmptyList("emptyReport")
	emptyReport:RefreshUI(data)

	self:InitGroupTypeBtn()

	self:InitTextLineWithLanguage(self.mIntro,-40)

    CS.ShowObject(self.mMyReportImage, not gLGameLanguage:IsForeignRegion())
end

function UISubSuBreak:InitUIEvent()
	self:SetWndClick(self.mPeakBtn,function () self:OnClickTopGroup(1) end)
	self:SetWndClick(self.mEliteBtn,function () self:OnClickTopGroup(2) end)

	self:SetWndClick(self.mBtnFormation,function () self:OnClickFormation() end)
	self:SetWndClick(self.mBtnShare,function () self:OnClickShare() end)
	self:SetWndClick(self.mBtnRank,function () self:OnClickRank() end)

	self:SetWndClick(self.mBtnHelp,function () self:OnClickHelp()	end)
end

function UISubSuBreak:OnStateUpdate()
	self:ShowTimeContent()

	self:ReqBreakData()
end



function UISubSuBreak:ShowMyScore(playerData)

	local state = gModelSimuFight:GetState()

	local isStart = state >= ModelSimuFight.SCHEDULE_BREAKOUT
	local show = playerData.isIn and isStart
	CS.ShowObject(self.mDetails,show)
	CS.ShowObject(self.mMyScore,show)
	CS.ShowObject(self.mEmptyList,not show)

	if not show then
		return
	end

	local headTran = self:FindWndTrans(self.mHeadRoot,"HeadIcon")
	local playerInfo =
	{
		trans = headTran,
		icon = playerData.head,
		headFrame = playerData.headFrame,
		level = playerData.level,
		func = function()
			gModelGeneral:PlayerShowReq(playerData.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)


	local nameStr = string.replace(ccClientText(25192),playerData.serverName,playerData.name)
	self:SetWndText(self.mName,nameStr)
	local powerStr = string.replace(ccClientText(25193),LUtil.GetPowerNumberCoversion(playerData.power))
	self:SetWndText(self.mPower,powerStr)
	local achieve = string.replace(ccClientText(25194),playerData.winCnt,playerData.failCnt)
	self:SetWndText(self.mWinFail,achieve)

	local str = string.replace(ccClientText(25195),playerData.score)
	self:SetWndText(self.mScore,str)

	str = string.replace(ccClientText(25196),playerData.rank)
	self:SetWndText(self.mRank,str)


end

function UISubSuBreak:RefreshReportShow()

	if not self._playerData then
		return
	end

	if not self._breakInfo then
		return
	end

	local playerData = self._playerData
	local state = gModelSimuFight:GetState()
	local isStart = state >= ModelSimuFight.SCHEDULE_BREAKOUT
	local show = playerData.isIn and isStart

	local reportDataList = {}

	for k,v in ipairs(self._breakInfo.infos) do
		local isEnd = gModelSimuFight:CheckIsBattleStart(v)
		if isEnd then
			local data = StructSimulateBattleInfo:New()
			data:CreateByPb(v)

			table.insert(reportDataList,data)
		end
	end

	table.sort(reportDataList,function (a,b)
		return a.startTime > b.startTime
	end)

	local isReportEmpty = #reportDataList ==0
	CS.ShowObject(self.mNoReport,isReportEmpty and show)
	CS.ShowObject(self.mReportList,not isReportEmpty and show)
	if isReportEmpty then
		return
	end

	local uiList = self:FindUIScroll("reportList")
	if not uiList then
		uiList= self:GetUIScroll("reportList")
		uiList:Create(self.mReportList,reportDataList,function (...) self:OnDrawReport(...) end,UIItemList.SUPER)
	else
		uiList:RefreshList(reportDataList)
	end

	uiList:DrawAllItems()

end

function UISubSuBreak:ChangeToOther()
	if self._curGroup == 1 then
		self._curGroup = 2
	else
		self._curGroup = 1
	end

	self:ReqBreakData()

	self:RefreshGroupTypeBtnShow()
end

function UISubSuBreak:InitGroupTypeBtn()
	local item = self.mBtnGroupType
	local textOne = self:FindWndTrans(item,"textOne")
	local textTwo = self:FindWndTrans(item,"textTwo")
	local btnOne = self:FindWndTrans(item,"btnOne")
	local btnOneTextOne = self:FindWndTrans(btnOne,"textOne")
	local btnTwo = self:FindWndTrans(item,"btnTwo")
	local btnTwoTextTwo = self:FindWndTrans(btnTwo,"textTwo")

	local name1 =ccLngText(gModelSimuFight:GetPara("groupName1"))
	local name2 =ccLngText(gModelSimuFight:GetPara("groupName2"))


	self:SetWndText(textOne,name1)
	self:SetWndText(btnOneTextOne,name1)
	self:SetWndText(textTwo,name2)
	self:SetWndText(btnTwoTextTwo,name2)

	self:SetWndClick(item,function ()
		self:ChangeToOther()
	end)
	self:SetWndClick(btnOne,function () end)
	self:SetWndClick(btnTwo,function () end)

	self:RefreshGroupTypeBtnShow()

end

function UISubSuBreak:ReqBreakData()
	local type = 0
	local group = 0
	local round = self._curRound
	local groupType = self._curGroup
	gModelSimuFight:OnSimulateGroupInfoReq(type,group,round,groupType)
end

function UISubSuBreak:GetPara()
	return {groupType = self._curGroup,round = self._curRound}
end

function UISubSuBreak:OnClickRank()
	GF.OpenWnd("UIRkPop",{refId =ModelRank.RANK_1800,sid = self._curGroup})
end


function UISubSuBreak:InitData()
	self._tabDataList =
	{
		[1] =
		{
			index = 1,
			name = ccClientText(25115),--"第一轮",
		},
		[2] =
		{
			index = 2,
			name = ccClientText(25116),--"第二轮",
		},
		[3] =
		{
			index = 3,
			name = ccClientText(25117) ,--"第三轮",
		},
	}

    self._countDownKey = "_countDownKey"

	self._reportRefresh = "_reportRefresh"
end

function UISubSuBreak:OnWndRefresh()

	local round = 1
	local curSchedule = gModelSimuFight:GetState()
	if curSchedule == ModelSimuFight.SCHEDULE_BREAKOUT then
		round = gModelSimuFight:GetRound()
	end


	self._curGroup = self:GetWndArg("groupType") or 0
    self._curRound = self:GetWndArg("round") or round
	self:ShowTimeContent()
    self:ReqBreakData()

end

function UISubSuBreak:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateGroupInfoResp,function (...)
		self:OnSimulateGroupInfoResp(...)
	end)

	self:WndEventRecv(EventNames.SIMULATE_STATE_CHANGE,function ()
		self:OnStateUpdate()
	end)
end

------------------------------------------------------------------
return UISubSuBreak


